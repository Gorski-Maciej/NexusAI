import logging
import os
import shutil
from pathlib import Path
from litestar import Litestar
from sqlalchemy import text
from db.database import create_oltp_engine, consolidate_database, create_session_factory
from core.broker import broker
from api.auth_service import hash_password
from api.shared_image_buffer import SharedImageBuffer
from db.analytics import DuckDBManager
from services.migration_sanity import run_migration_sanity_checks, verify_migration_integrity, verify_migration_checksums
from core.secrets import LocalSecretsCache, OfflineFirstSecretResolver
from core.saga import PersistedSagaStore

logger = logging.getLogger("nexus.api.state")


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

async def on_startup(app: Litestar) -> None:
    """Inicjalizacja ciężkich zasobów przy starcie API."""
    config = app.dependencies["config"]()
    app.state.ml_cache_env = _configure_ml_cache_directories(config.base_dir)

    # Inicjalizacja silnika bazy danych w stanie aplikacji
    engine = create_oltp_engine(config)
    app.state.db_engine = engine
    app.state.db_session_factory = create_session_factory(engine)
    app.state.shared_image_buffer = SharedImageBuffer(max_items=128)
    app.state.saga_store = PersistedSagaStore(engine)
    await app.state.saga_store.ensure_schema()
    admin_username = os.getenv("NEXUS_ADMIN_USERNAME", "admin")
    admin_password = _resolve_startup_secret(config, key_name="admin_password", env_var="NEXUS_ADMIN_PASSWORD", default_value="admin")
    admin_password_hash = hash_password(admin_password)
    async with engine.begin() as conn:
        await conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS users (
                    id TEXT PRIMARY KEY,
                    username TEXT UNIQUE NOT NULL,
                    password_hash TEXT NOT NULL,
                    role TEXT NOT NULL DEFAULT 'worker',
                    tenant_id TEXT NOT NULL DEFAULT 'default',
                    is_active BOOLEAN NOT NULL DEFAULT 1,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
        )
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
        try:
            await conn.execute(text("ALTER TABLE invoices ADD COLUMN is_deleted BOOLEAN NOT NULL DEFAULT 0"))
        except Exception:
            pass
        try:
            await conn.execute(text("ALTER TABLE invoices ADD COLUMN deleted_at TIMESTAMP NULL"))
        except Exception:
            pass
        try:
            await conn.execute(text("ALTER TABLE invoices ADD COLUMN tenant_id TEXT NOT NULL DEFAULT 'default'"))
        except Exception:
            pass

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
                "role": "owner",
                "tenant_id": "default",
                "is_active": True,
            },
        )

        # --- Indeksy SQLite dla wydajności (Rozwiązanie 14) ---
        await conn.execute(
            text(
                "CREATE INDEX IF NOT EXISTS idx_outbox_pending ON outbox_events(status, processed, retry_count, created_at)"
            )
        )
        await conn.execute(
            text(
                "CREATE INDEX IF NOT EXISTS idx_invoices_tenant_status ON invoices(tenant_id, status)"
            )
        )
        await conn.execute(
            text(
                "CREATE INDEX IF NOT EXISTS idx_invoices_updated_at ON invoices(updated_at)"
            )
        )

        # --- Tabela idempotentności processed_events dla outbox (Rozwiązanie 11) ---
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
        await conn.execute(
            text(
                "CREATE UNIQUE INDEX IF NOT EXISTS idx_processed_events_business_key ON processed_events(event_type, aggregate_id)"
            )
        )

        # Dodaj kolumnę processing_started_at jeśli nie istnieje
        try:
            await conn.execute(text("ALTER TABLE outbox_events ADD COLUMN processing_started_at TIMESTAMP NULL"))
        except Exception:
            pass

        # --- Tabela task_status dla monitorowania postępu zadań (Rozwiązanie 17) ---
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
        await conn.execute(
            text(
                "CREATE INDEX IF NOT EXISTS idx_task_status_user ON task_status(user_id)"
            )
        )
        await conn.execute(
            text(
                "CREATE INDEX IF NOT EXISTS idx_task_status_status ON task_status(status)"
            )
        )

        # --- Tabela refresh_tokens dla mechanizmu odświeżania JWT (Rozwiązanie 16) ---
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
        await conn.execute(
            text(
                "CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id)"
            )
        )
        await conn.execute(
            text(
                "CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expires ON refresh_tokens(expires_at)"
            )
        )

        # ANALYZE dla optymalizacji zapytań (Rozwiązanie 14)
        await conn.execute(text("ANALYZE;"))
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

    # Połączenie z brokerem Taskiq (NATS)
    if not broker.is_worker_process:
        await broker.startup()

    # Warm-up analytics materialization to reduce cold-start dashboard latency.
    try:
        duckdb_manager = DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path)
        duckdb_manager.refresh_materialized_cashflow()
        duckdb_manager.close()
    except Exception as exc:
        logger.warning("DuckDB warm-up refresh failed: %s", exc)

    logger.info(">>> Nexus API: Wszystkie systemy gotowe.")

async def on_shutdown(app: Litestar) -> None:
    """Bezpieczne zamykanie i konsolidacja danych."""
    logger.info(">>> Nexus API: Rozpoczynanie procedury zamykania...")

    engine = app.state.db_engine

    # 1. Najpierw zamykamy broker
    if not broker.is_worker_process:
        await broker.shutdown()

    # 2. Zamykamy wszystkie aktywne sesje i zwalniamy połączenia
    # Session factory zostanie zamknięta przez dispose() engine'u.
    # Wszystkie sesje pozyskane przez provide_db_session są zarządzane
    # przez async with session.begin() i powinny być już zamknięte.
    # Dodatkowo wywołujemy dispose(), by zamknąć pulę połączeń.

    # 3. Dopiero po zamknięciu połączeń wykonujemy konsolidację WAL
    await consolidate_database(engine)

    # 4. Zwolnienie zasobów engine'u
    await engine.dispose()

    # 5. Czyszczenie cache ML
    for cache_dir in (app.state.ml_cache_env or {}).values():
        try:
            shutil.rmtree(cache_dir, ignore_errors=True)
        except Exception:
            pass
