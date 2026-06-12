import os

import anyio
import shutil
import threading
import uuid
from pathlib import Path

import pendulum
from litestar import Litestar
from sqlalchemy import text
from structlog import get_logger

from nexus_ai.api.auth_service import hash_password
from nexus_ai.api.shared_image_buffer import SharedImageBuffer
from nexus_ai.core.background_task_manager import BackgroundTaskManager
from nexus_ai.core.broker import broker
from nexus_ai.core.saga import PersistedSagaStore
from nexus_ai.core.secrets import LocalSecretsCache, OfflineFirstSecretResolver
from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.db.database import consolidate_database, create_oltp_engine, create_session_factory
from nexus_ai.core.config import AppConfig
from nexus_ai.services.hot_reload import HotReloadListener
from nexus_ai.services.migration_sanity import (
    run_migration_sanity_checks,
    verify_migration_checksums,
    verify_migration_integrity,
)
from nexus_ai.services.outbox_relay import OutboxRelay

# ── OpenTelemetry metrics initialization ───────────────────────────────────
# Thread-safe dla free-threaded Python — używa threading.Event zamiast bool
_METRICS_INITIALIZED_EVENT = threading.Event()


def _init_otel_metrics_sync() -> None:
    """Initialize OpenTelemetry metrics (sync part — thread-safe)."""
    if _METRICS_INITIALIZED_EVENT.is_set():
        return

    from nexus_ai.api.telemetry_metrics import init_metrics

    init_metrics()
    _METRICS_INITIALIZED_EVENT.set()
    logger.info("[METRICS] OpenTelemetry metrics initialized (see /metrics endpoint)")


async def _start_metrics_background_task(app: Litestar) -> None:
    """Spawn background system metrics updater via BackgroundTaskManager.

    Rejestruje task w ``app.state.bg_tasks`` zamiast manualnego
    ``anyio.ensure_backend().create_task()`` — task jest automatycznie
    anulowany przez ``cancel_all()`` podczas shutdownu.
    """
    try:
        import psutil

        _proc = psutil.Process()

        async def _update_system_metrics() -> None:
            """Periodically update system-level gauges."""
            from nexus_ai.api.telemetry_metrics import set_memory_usage

            while True:
                try:
                    mem = _proc.memory_info().rss / (1024 * 1024)
                    set_memory_usage(mem)
                except Exception:
                    pass
                await anyio.sleep(30)

        app.state.bg_tasks.start_task(
            "metrics_updater",
            _update_system_metrics(),
            metadata={"description": "System metrics gauge (30s interval)"},
        )
        logger.info("[METRICS] System metrics updater started via BackgroundTaskManager (30s interval)")
    except ImportError:
        logger.debug("[METRICS] psutil not available — system metrics disabled")
    except Exception as exc:
        logger.debug("[METRICS] System metrics updater failed: %s", exc)



# ── SQLCipher engine helper ────────────────────────────────────────────────
def _make_engine(config: AppConfig):
    """Utwórz SQLAlchemy engine z jawnym kluczem SQLCipher."""
    sqlcipher_key = os.getenv(config.sqlcipher_key_env, "").strip()
    return create_oltp_engine(config, sqlcipher_key=sqlcipher_key or None)


logger = get_logger("nexus.api.state")


def _configure_ml_cache_directories(base_dir: Path) -> dict[str, str]:
    """
    Isolate ML framework caches in dedicated runtime directory with strict permissions.
    Returns mapping of env vars configured for cleanup on shutdown.
    """
    ml_cache_root = base_dir / "runtime_cache" / "ml"
    ml_cache_root.mkdir(parents=True, exist_ok=True)
    try:
        os.chmod(ml_cache_root, 0o700)
    except Exception:
        pass

    env_map = {
        "HF_HOME": str(ml_cache_root / "hf"),
        "TORCH_HOME": str(ml_cache_root / "torch"),
        "TRANSFORMERS_CACHE": str(ml_cache_root / "transformers"),
    }
    for _, path_value in env_map.items():
        path = Path(path_value)
        path.mkdir(parents=True, exist_ok=True)
        try:
            os.chmod(path, 0o700)
        except Exception:
            pass
    for key, value in env_map.items():
        os.environ.setdefault(key, value)
    return env_map



def _resolve_startup_secret(config, key_name: str, env_var: str, default_value: str) -> str:
    """Resolve startup secret via offline-first cache (env provider -> encrypted local cache)."""
    cache = LocalSecretsCache(cache_path=config.base_dir / "app_data" / "secrets_cache.json", ttl_hours=24)
    resolver = OfflineFirstSecretResolver(cache=cache)

    def provider() -> str | None:
        value = os.getenv(env_var, "").strip()
        return value or None

    resolved = resolver.resolve(key_name, provider)
    return resolved or default_value

# ── Schema DDL helper ──────────────────────────────────────────────────────


async def _ensure_schema_tables(engine, config: AppConfig) -> None:
    """Create all required DB tables if they don't exist.

    Extracted from on_startup Phase 2 for testability.
    Docelowo te DDL powinny być w migracjach Alembic.
    """
    admin_username = os.getenv("NEXUS_ADMIN_USERNAME", "admin")
    admin_password = _resolve_startup_secret(
        config, key_name="admin_password", env_var="NEXUS_ADMIN_PASSWORD", default_value="admin"
    )
    admin_password_hash = hash_password(admin_password)

    async with engine.begin() as conn:
        # --- Core auth tables ---
        await conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS users (
                    id TEXT PRIMARY KEY,
                    username TEXT UNIQUE NOT NULL,
                    email TEXT,
                    full_name TEXT,
                    password_hash TEXT NOT NULL,
                    role TEXT NOT NULL DEFAULT 'worker',
                    tenant_id TEXT NOT NULL DEFAULT 'default',
                    is_active BOOLEAN NOT NULL DEFAULT 1,
                    is_verified BOOLEAN NOT NULL DEFAULT 0,
                    must_change_password BOOLEAN NOT NULL DEFAULT 0,
                    jwt_version INTEGER NOT NULL DEFAULT 1,
                    last_login TIMESTAMP,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
        )
        await conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS audit_logs (
                    id TEXT PRIMARY KEY,
                    user_id TEXT,
                    invoice_id TEXT,
                    action TEXT NOT NULL,
                    old_value TEXT,
                    new_value TEXT,
                    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
        )
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id)"))
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action)"))

        # --- Email tokens ---
        await conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS email_tokens (
                    id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    token TEXT UNIQUE NOT NULL,
                    purpose TEXT NOT NULL DEFAULT 'confirm',
                    expires_at TIMESTAMP NOT NULL,
                    used BOOLEAN NOT NULL DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
        )
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_email_tokens_token ON email_tokens(token)"))
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_email_tokens_user ON email_tokens(user_id)"))

        # --- Outbox + FX rates + UI drafts ---
        await conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS outbox_events (
                    id TEXT PRIMARY KEY,
                    event_type TEXT NOT NULL,
                    aggregate_id TEXT NOT NULL,
                    payload TEXT NOT NULL,
                    status TEXT NOT NULL DEFAULT 'PENDING',
                    processed BOOLEAN NOT NULL DEFAULT 0,
                    retry_count INTEGER NOT NULL DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
        )
        await conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS fx_rates (
                    id TEXT PRIMARY KEY,
                    currency TEXT NOT NULL,
                    rate_to_pln REAL NOT NULL,
                    effective_at TIMESTAMP NOT NULL,
                    source TEXT NOT NULL DEFAULT 'manual',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
        )
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_fx_rates_currency_effective ON fx_rates(currency, effective_at)"))
        await conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS ui_drafts (
                    tenant_id TEXT NOT NULL,
                    actor_id TEXT NOT NULL,
                    draft_key TEXT NOT NULL,
                    payload_json TEXT NOT NULL,
                    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (tenant_id, actor_id, draft_key)
                )
                """
            )
        )

        # --- Migrate invoices schema (idempotent ALTER TABLE) ---
        for alter_sql in [
            "ALTER TABLE invoices ADD COLUMN is_deleted BOOLEAN NOT NULL DEFAULT 0",
            "ALTER TABLE invoices ADD COLUMN deleted_at TIMESTAMP NULL",
            "ALTER TABLE invoices ADD COLUMN tenant_id TEXT NOT NULL DEFAULT 'default'",
        ]:
            try:
                await conn.execute(text(alter_sql))
            except Exception:
                pass

        # --- Seed admin user ---
        await conn.execute(
            text(
                """
                INSERT INTO users (id, username, password_hash, role, tenant_id, is_active)
                VALUES (:id, :username, :password_hash, :role, :tenant_id, :is_active)
                ON CONFLICT(username) DO NOTHING
                """
            ),
            {
                "id": "admin",
                "username": admin_username,
                "password_hash": admin_password_hash,
                "role": "admin",
                "tenant_id": "default",
                "is_active": True,
            },
        )

        # --- Performance indexes ---
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_outbox_pending ON outbox_events(status, processed, retry_count, created_at)"))
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_invoices_tenant_status ON invoices(tenant_id, status)"))
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_invoices_updated_at ON invoices(updated_at)"))

        # --- Processed events (idempotency) ---
        await conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS processed_events (
                    id TEXT NOT NULL,
                    event_type TEXT NOT NULL,
                    aggregate_id TEXT NOT NULL,
                    payload_hash TEXT NOT NULL,
                    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(event_type, aggregate_id)
                )
                """
            )
        )
        await conn.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS idx_processed_events_business_key ON processed_events(event_type, aggregate_id)"))

        try:
            await conn.execute(text("ALTER TABLE outbox_events ADD COLUMN processing_started_at TIMESTAMP NULL"))
        except Exception:
            pass

        # --- Task status ---
        await conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS task_status (
                    task_id TEXT PRIMARY KEY,
                    task_name TEXT NOT NULL,
                    user_id TEXT,
                    status TEXT NOT NULL DEFAULT 'QUEUED',
                    progress REAL DEFAULT 0.0,
                    result TEXT,
                    error_message TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
        )
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_task_status_user ON task_status(user_id)"))
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_task_status_status ON task_status(status)"))

        # --- Refresh tokens ---
        await conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS refresh_tokens (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    token_hash TEXT UNIQUE NOT NULL,
                    expires_at TIMESTAMP NOT NULL,
                    is_revoked BOOLEAN NOT NULL DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
        )
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id)"))
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expires ON refresh_tokens(expires_at)"))

        # --- Failed tasks (DLQ) ---
        await conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS failed_tasks (
                    id TEXT PRIMARY KEY,
                    task_name TEXT NOT NULL,
                    task_id TEXT,
                    payload TEXT NOT NULL DEFAULT '{}',
                    error_type TEXT NOT NULL,
                    error_message TEXT NOT NULL,
                    stack_trace TEXT,
                    retry_count INTEGER NOT NULL DEFAULT 0,
                    max_retries INTEGER NOT NULL DEFAULT 3,
                    resolved BOOLEAN NOT NULL DEFAULT 0,
                    resolved_at TIMESTAMP,
                    resolved_by TEXT,
                    resolution_note TEXT,
                    failed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
        )
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_failed_tasks_resolved ON failed_tasks(resolved)"))
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_failed_tasks_task_name ON failed_tasks(task_name)"))

        # --- RBAC tables: roles, permissions, user_roles, role_permissions ---
        await conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS roles (
                    id TEXT PRIMARY KEY,
                    name TEXT UNIQUE NOT NULL,
                    description TEXT,
                    is_system BOOLEAN NOT NULL DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
        )
        await conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS permissions (
                    id TEXT PRIMARY KEY,
                    codename TEXT UNIQUE NOT NULL,
                    description TEXT,
                    resource TEXT NOT NULL,
                    action TEXT NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
        )
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_permissions_codename ON permissions(codename)"))
        await conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS user_roles (
                    id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                    role_id TEXT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
        )
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_user_roles_user ON user_roles(user_id)"))
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(role_id)"))
        await conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS role_permissions (
                    id TEXT PRIMARY KEY,
                    role_id TEXT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
                    permission_id TEXT NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(role_id, permission_id)
                )
                """
            )
        )
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_role_permissions_role ON role_permissions(role_id)"))

        # --- Assign admin to admin role in user_roles ---
        admin_role_row = await conn.execute(
            text("SELECT id FROM roles WHERE name = 'admin' LIMIT 1")
        )
        admin_role_data = admin_role_row.mappings().first()
        if admin_role_data:
            existing_ur = await conn.execute(
                text("SELECT id FROM user_roles WHERE user_id = :uid AND role_id = :rid LIMIT 1"),
                {"uid": "admin", "rid": admin_role_data["id"]},
            )
            if not existing_ur.scalar():
                await conn.execute(
                    text(
                        "INSERT INTO user_roles (id, user_id, role_id) "
                        "VALUES (:id, :uid, :rid) ON CONFLICT DO NOTHING"
                    ),
                    {"id": uuid.uuid4().hex, "uid": "admin", "rid": admin_role_data["id"]},
                )

        # --- Seed default roles ---
        role_ids: dict[str, str] = {}
        for role_name, role_desc in [
            ("admin", "System administrator — full access"),
            ("accountant", "Accountant — financial operations"),
            ("auditor", "Auditor — read-only audit access"),
            ("viewer", "Viewer — read-only basic access"),
        ]:
            await conn.execute(
                text(
                    "INSERT INTO roles (id, name, description, is_system) "
                    "VALUES (:id, :name, :desc, 1) ON CONFLICT(name) DO NOTHING"
                ),
                {"id": uuid.uuid4().hex, "name": role_name, "desc": role_desc},
            )
            row = await conn.execute(
                text("SELECT id FROM roles WHERE name = :name"),
                {"name": role_name},
            )
            row_data = row.mappings().first()
            if row_data:
                role_ids[role_name] = row_data["id"]

        # --- Seed permissions ---
        perm_ids: dict[str, str] = {}
        permission_registry = {
            "invoice:create": {"resource": "invoice", "action": "create", "description": "Create invoices"},
            "invoice:view": {"resource": "invoice", "action": "view", "description": "View invoices"},
            "invoice:edit": {"resource": "invoice", "action": "edit", "description": "Edit invoices"},
            "invoice:delete": {"resource": "invoice", "action": "delete", "description": "Delete invoices"},
            "invoice:approve": {"resource": "invoice", "action": "approve", "description": "Approve invoices"},
            "invoice:submit-ksef": {"resource": "invoice", "action": "submit-ksef", "description": "Submit invoices to KSeF"},
            "company:view": {"resource": "company", "action": "view", "description": "View company profiles"},
            "company:edit": {"resource": "company", "action": "edit", "description": "Edit company profiles"},
            "company:delete": {"resource": "company", "action": "delete", "description": "Delete companies"},
            "audit:view": {"resource": "audit", "action": "view", "description": "View audit logs"},
            "audit:export": {"resource": "audit", "action": "export", "description": "Export audit logs"},
            "user:view": {"resource": "user", "action": "view", "description": "View users"},
            "user:create": {"resource": "user", "action": "create", "description": "Create users"},
            "user:edit": {"resource": "user", "action": "edit", "description": "Edit users"},
            "user:delete": {"resource": "user", "action": "delete", "description": "Delete users"},
            "admin:access": {"resource": "admin", "action": "access", "description": "Access admin panel"},
            "admin:settings": {"resource": "admin", "action": "settings", "description": "Modify system settings"},
            "admin:failed-tasks": {"resource": "admin", "action": "failed-tasks", "description": "Manage failed tasks / DLQ"},
            "admin:hot-reload": {"resource": "admin", "action": "hot-reload", "description": "View hot-reload health status"},
            "finance:view": {"resource": "finance", "action": "view", "description": "View financial data"},
            "finance:reconcile": {"resource": "finance", "action": "reconcile", "description": "Reconcile accounts"},
            "finance:export": {"resource": "finance", "action": "export", "description": "Export financial reports"},
            "contractor:view": {"resource": "contractor", "action": "view", "description": "View contractors"},
            "contractor:edit": {"resource": "contractor", "action": "edit", "description": "Edit contractors"},
        }
        for codename, info in permission_registry.items():
            await conn.execute(
                text(
                    "INSERT INTO permissions (id, codename, resource, action, description) "
                    "VALUES (:id, :codename, :resource, :action, :desc) ON CONFLICT(codename) DO NOTHING"
                ),
                {
                    "id": uuid.uuid4().hex, "codename": codename,
                    "resource": info["resource"], "action": info["action"],
                    "desc": info["description"],
                },
            )
            row = await conn.execute(
                text("SELECT id FROM permissions WHERE codename = :codename"),
                {"codename": codename},
            )
            row_data = row.mappings().first()
            if row_data:
                perm_ids[codename] = row_data["id"]

        # --- Seed role-permission mappings ---
        role_perms_map = {
            "admin": list(permission_registry.keys()),
            "accountant": [
                "invoice:create", "invoice:view", "invoice:edit", "invoice:approve", "invoice:submit-ksef",
                "company:view", "company:edit",
                "audit:view",
                "finance:view", "finance:reconcile", "finance:export",
                "contractor:view", "contractor:edit",
            ],
            "auditor": [
                "invoice:view", "company:view", "audit:view", "audit:export",
                "finance:view", "contractor:view",
            ],
            "viewer": [
                "invoice:view", "company:view", "audit:view",
                "finance:view", "contractor:view",
            ],
        }
        for role_name, codenames in role_perms_map.items():
            role_id = role_ids.get(role_name)
            if not role_id:
                continue
            for codename in codenames:
                perm_id = perm_ids.get(codename)
                if not perm_id:
                    continue
                await conn.execute(
                    text(
                        "INSERT INTO role_permissions (id, role_id, permission_id) "
                        "VALUES (:id, :rid, :pid) ON CONFLICT DO NOTHING"
                    ),
                    {"id": uuid.uuid4().hex, "rid": role_id, "pid": perm_id},
                )

        await conn.execute(text("ANALYZE;"))


async def on_startup(app: Litestar) -> None:
    """Inicjalizacja ciężkich zasobów przy starcie API.

    Fazowanie startu:
      0. Config + ML cache
      1. Metryki OTel (sync + background task)
      2. Database engine + core services
      3. Schema DDL + seed danych
      4. Broker, DuckDB warm-up, auto-seed
      5. OutboxRelay, HotReloadListener

    Każda faza jest izolowana w try/except — awaria nie powoduje
    całkowitego failure startu (chyba że ``environment in {"stage", "prod"}``
    i faza krytyczna zawiedzie).
    """

    config = app.dependencies["config"]()

    # ── Phase 0: Config + ML cache ───────────────────────────────────
    app.state.ml_cache_env = _configure_ml_cache_directories(config.base_dir)

    # ── Phase 1: OpenTelemetry metrics ───────────────────────────────
    try:
        _init_otel_metrics_sync()
        await _start_metrics_background_task(app)
    except Exception as exc:
        logger.warning("[STARTUP] OTel metrics init failed (non-fatal): %s", exc)

    # ── Phase 2: Database engine + core services ─────────────────────
    engine = None
    try:
        engine = _make_engine(config)
        app.state.db_engine = engine
        app.state.db_session_factory = create_session_factory(engine)
        app.state.shared_image_buffer = SharedImageBuffer(max_items=128)
        # BackgroundTaskManager — centralna rejestracja tasków z anulowaniem na shutdown
        app.state.bg_tasks = BackgroundTaskManager()
        app.state.saga_store = PersistedSagaStore(engine)
        await app.state.saga_store.ensure_schema()
    except Exception as exc:
        logger.critical("[STARTUP] Database engine init FAILED: %s", exc)
        if config.environment in {"stage", "prod"}:
            raise
        app.state.db_engine = None
        app.state.db_session_factory = None

    # ── Phase 3: Schema DDL + seed ───────────────────────────────────
    if engine is not None:
        try:
            await _ensure_schema_tables(engine, config)
        except Exception as exc:
            logger.critical("[STARTUP] Schema init FAILED: %s", exc)
            if config.environment in {"stage", "prod"}:
                raise

        # Migration sanity checks (Phase 3b)
        try:
            sanity = await run_migration_sanity_checks(engine)
            integrity = await verify_migration_integrity(engine, config.migration_baseline_path)
            checksums = await verify_migration_checksums(engine, config.migration_checksum_baseline_path)
            logger.info("Migration sanity checks: %s", sanity)
            logger.info("Migration integrity checks: %s", integrity)
            logger.info("Migration checksum checks: %s", checksums)
            if (integrity.get("status") == "integrity_warning" or checksums.get("status") == "integrity_warning") and config.environment in {"stage", "prod"}:
                raise RuntimeError(f"Migration integrity warning in {config.environment}: rowcount={integrity.get('issues', [])}, checksum={checksums.get('issues', [])}")
        except Exception as exc:
            logger.warning("Migration sanity checks failed: %s", exc)
            if config.environment in {"stage", "prod"}:
                raise

    # ── Phase 4: Broker, warm-up, auto-seed ─────────────────────────┒
    if not broker.is_worker_process:
        try:
            with anyio.fail_after(5.0):
                await broker.startup()
        except Exception as exc:
            logger.warning("NATS broker unavailable — task queue disabled: %s", exc)

    try:
        duckdb_manager = DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path)
        duckdb_manager.refresh_materialized_cashflow()
        duckdb_manager.close()
    except Exception as exc:
        logger.warning("DuckDB warm-up refresh failed: %s", exc)

    seeded_file = config.base_dir / ".seeded"
    if not seeded_file.exists():
        logger.info("No .seeded marker found — running seed_all...")
        try:
            from scripts.seed_data import seed_all
            seed_result = await seed_all(config)
            if seed_result:
                seeded_file.write_text(pendulum.now("UTC").isoformat())
                logger.info("Seed data loaded: %d entities. .seeded marker written.", sum(seed_result.values()))
        except Exception as exc:
            logger.warning("Auto-seed failed (non-blocking): %s", exc)
    else:
        logger.info(".seeded marker found — skipping auto-seed.")

    # ── Phase 5: OutboxRelay + HotReloadListener ────────────────────
    try:
        relay = OutboxRelay(
            session_factory=app.state.db_session_factory,
            tigerbeetle=None,
            max_retries=3,
            base_delay_seconds=1.0,
        )
        app.state.outbox_relay = relay
        logger.info("[OUTBOX-RELAY] Relay initialized")
    except Exception as exc:
        logger.warning("[OUTBOX-RELAY] Failed to initialize: %s", exc)
        app.state.outbox_relay = None

    try:
        listener = HotReloadListener(nats_url=config.nats_url)
        await listener.start()
        app.state.hot_reload_listener = listener
        logger.info("[HOT-RELOAD] Listener started (nats_url=%s)", config.nats_url)
    except Exception as exc:
        logger.warning("[HOT-RELOAD] Failed to start listener: %s", exc)
        app.state.hot_reload_listener = None

    logger.info(">>> Nexus API: Wszystkie systemy gotowe.")

async def on_shutdown(app: Litestar) -> None:
    """Bezpieczne zamykanie i konsolidacja danych."""
    logger.info(">>> Nexus API: Rozpoczynanie procedury zamykania...")

    # 0. Cancel all background tasks via BackgroundTaskManager
    bg_tasks = getattr(app.state, 'bg_tasks', None)
    if bg_tasks is not None:
        await bg_tasks.cancel_all()

    engine = app.state.db_engine

    # 1. Zamknij broker (jeśli był uruchomiony)
    if not broker.is_worker_process:
        try:
            await broker.shutdown()
        except Exception:
            pass

    # 2. Zamknij Hot-Reload Listener
    try:
        listener = getattr(app.state, "hot_reload_listener", None)
        if listener is not None:
            await listener.stop()
            logger.info("[HOT-RELOAD] Listener stopped")
    except Exception as exc:
        logger.warning("[HOT-RELOAD] Error stopping listener: %s", exc)

    # 3. Konsolidacja WAL + zwolnienie zasobów engine'u
    if engine is not None:
        await consolidate_database(engine)
        await engine.dispose()

    # 4. Czyszczenie cache ML
    for cache_dir in (app.state.ml_cache_env or {}).values():
        try:
            shutil.rmtree(cache_dir, ignore_errors=True)
        except Exception:
            pass
