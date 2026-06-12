import os

import anyio
import shutil
import threading
from pathlib import Path

import pendulum
from litestar import Litestar
from structlog import get_logger

from nexus_ai.api.shared_image_buffer import SharedImageBuffer
from nexus_ai.core.background_task_manager import BackgroundTaskManager
from nexus_ai.core.broker import broker
from nexus_ai.core.saga import PersistedSagaStore
from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.db.database import consolidate_database, create_oltp_engine, create_session_factory
from nexus_ai.core.config import AppConfig
from nexus_ai.services.hot_reload import HotReloadListener
from nexus_ai.services.migration_sanity import (
    run_migration_sanity_checks,
    verify_migration_checksums,
    verify_migration_integrity,
)
from nexus_ai.events.event_emitter import EventEmitter
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
        logger.info(
            "[METRICS] System metrics updater started via BackgroundTaskManager (30s interval)"
        )
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


# ── Seed data helper ────────────────────────────────────────────────────────


async def _seed_data(engine, config: AppConfig) -> None:
    """Seed data after Alembic migrations have created all tables.

    All tables and columns are created by Alembic migrations (0001-0003).
    This function only seeds runtime data:
    - RBAC: roles, permissions, admin user, mappings (via seed_rbac)
    """
    from scripts.seed_data import seed_rbac

    logger.info("[SEED] Tables created by Alembic migrations — seeding RBAC")

    try:
        rbac_counts = await seed_rbac(engine)
        logger.info(
            "[SEED] RBAC seeded: %d roles, %d permissions, %d mappings, admin user",
            rbac_counts.get("roles", 0),
            rbac_counts.get("permissions", 0),
            rbac_counts.get("role_permissions", 0),
        )
    except Exception as exc:
        logger.warning("[SEED] RBAC seed failed (non-fatal): %s", exc)


def make_on_startup(engine, session_factory):
    """Factory: zwraca funkcję ``on_startup`` z pre-created engine i session_factory.

    Engine i session_factory są tworzone w ``create_app()`` i przekazywane
    do ``SQLAlchemyPlugin``. Ta funkcja tworzy closure, który:
      1. Używa przekazanego engine (zamiast tworzyć nowy)
      2. Rejestruje engine/session_factory w ``app.state``
      3. Uruchamia migracje Alembic, seed danych, broker, itd.

    Zgodnie z aa3fvcx.txt: SQLAlchemyPlugin zastępuje manualny
    ``provide_db_session`` z dependencies.py.
    """

    async def _on_startup(app: Litestar) -> None:
        """Inicjalizacja ciężkich zasobów przy starcie API.

        Fazowanie startu:
          0. Config + ML cache
          1. Metryki OTel (sync + background task)
          2. Database engine + core services (pre-created przez SQLAlchemyPlugin)
          3. Alembic migrations + seed danych
          4. Broker, DuckDB warm-up, auto-seed
          5. OutboxRelay, HotReloadListener

        Engine i session_factory są współdzielone z SQLAlchemyPlugin.
        """

        config = app.dependencies["config"]()

        # ── Phase 0: Config + ML cache ───────────────────────────────
        app.state.ml_cache_env = _configure_ml_cache_directories(config.base_dir)

        # ── Phase 1: OpenTelemetry metrics ───────────────────────────
        try:
            _init_otel_metrics_sync()
            await _start_metrics_background_task(app)
        except Exception as exc:
            logger.warning("[STARTUP] OTel metrics init failed (non-fatal): %s", exc)

        # ── Phase 2: Database engine + core services ─────────────────
        # Engine i session_factory są pre-created przez SQLAlchemyPlugin w create_app()
        try:
            app.state.db_engine = engine
            app.state.db_session_factory = session_factory
            app.state.shared_image_buffer = SharedImageBuffer(max_items=128)
            app.state.bg_tasks = BackgroundTaskManager()
            app.state.saga_store = PersistedSagaStore(engine)
            await app.state.saga_store.ensure_schema()

            # Inicjalizuj EventEmitter dla event-driven architecture
            from nexus_ai.events.event_store import EventStore
            from nexus_ai.events.jetstream_bus import JetStreamEventBus

            event_store = EventStore(
                db_path=str(config.base_dir / "app_data" / "events.db")
            )
            try:
                jetstream = JetStreamEventBus(nats_servers=config.nats_url)
                await jetstream.connect()
            except Exception:
                jetstream = None
                logger.warning("[STARTUP] JetStream unavailable — events stored locally")

            app.state.event_emitter = EventEmitter(
                event_store=event_store,
                jetstream=jetstream,
            )
            logger.info("[STARTUP] Database engine ready (SQLAlchemyPlugin)")
        except Exception as exc:
            logger.critical("[STARTUP] Database engine init FAILED: %s", exc)
            if config.environment in {"stage", "prod"}:
                raise

        # ── Phase 3: Alembic migrations + seed data ──────────────────
        if engine is not None:
            try:
                from alembic import command
                from nexus_ai.core.alembic_utils import get_alembic_config

                alembic_cfg = get_alembic_config()
                if alembic_cfg is not None:
                    command.upgrade(alembic_cfg, "head")
                    logger.info("[STARTUP] Alembic migrations applied (head)")
                else:
                    logger.warning("[STARTUP] Alembic config not found — skipping migrations")
            except Exception as exc:
                logger.critical("[STARTUP] Alembic migrations FAILED: %s", exc)
                if config.environment in {"stage", "prod"}:
                    raise

            try:
                await _seed_data(engine, config)
            except Exception as exc:
                logger.critical("[STARTUP] Seed data FAILED: %s", exc)
                if config.environment in {"stage", "prod"}:
                    raise

            try:
                sanity = await run_migration_sanity_checks(engine)
                integrity = await verify_migration_integrity(engine, config.migration_baseline_path)
                checksums = await verify_migration_checksums(
                    engine, config.migration_checksum_baseline_path
                )
                logger.info("Migration sanity checks: %s", sanity)
                logger.info("Migration integrity checks: %s", integrity)
                logger.info("Migration checksum checks: %s", checksums)
                if (
                    integrity.get("status") == "integrity_warning"
                    or checksums.get("status") == "integrity_warning"
                ) and config.environment in {"stage", "prod"}:
                    raise RuntimeError(
                        f"Migration integrity warning in {config.environment}: rowcount={integrity.get('issues', [])}, checksum={checksums.get('issues', [])}"
                    )
            except Exception as exc:
                logger.warning("Migration sanity checks failed: %s", exc)
                if config.environment in {"stage", "prod"}:
                    raise

        # ── Phase 4: Broker, warm-up, auto-seed ─────────────────────
        if not broker.is_worker_process:
            try:
                with anyio.fail_after(5.0):
                    await broker.startup()
            except Exception as exc:
                logger.warning("NATS broker unavailable — task queue disabled: %s", exc)

        try:
            duckdb_manager = DuckDBManager(
                db_path=config.duckdb_path, sqlite_path=config.sqlite_path
            )
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
                    logger.info(
                        "Seed data loaded: %d entities. .seeded marker written.",
                        sum(seed_result.values()),
                    )
            except Exception as exc:
                logger.warning("Auto-seed failed (non-blocking): %s", exc)
        else:
            logger.info(".seeded marker found — skipping auto-seed.")

        # ── Phase 5: OutboxRelay + HotReloadListener ────────────────
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

    return _on_startup


async def on_shutdown(app: Litestar) -> None:
    """Bezpieczne zamykanie i konsolidacja danych."""
    logger.info(">>> Nexus API: Rozpoczynanie procedury zamykania...")

    # 0. Cancel all background tasks via BackgroundTaskManager
    bg_tasks = getattr(app.state, "bg_tasks", None)
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
