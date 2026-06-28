import os

import anyio
import shutil
import threading
from pathlib import Path

import pendulum
from litestar import Litestar
from structlog import get_logger

from nexus_ai.api.shared_image_buffer import SharedImageBuffer
from nexus_ai.core.background_task_manager import BackgroundTaskManager, TaskMetadata
from nexus_ai.core.broker import broker
from nexus_ai.core.cache.http_client import warm_http_cache
from nexus_ai.core.di import dispose_all_engines
from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.db.database import consolidate_database, create_oltp_engine, create_session_factory
from nexus_ai.core.config import AppConfig
from nexus_ai.api.routes.ws import start_unix_progress_server, stop_unix_progress_server
from nexus_ai.services.hot_reload import HotReloadListener
from nexus_ai.services.migration_sanity import (
    run_migration_sanity_checks,
    verify_migration_checksums,
    verify_migration_integrity,
)

# ── SUPERMOC: OTel graceful shutdown przez otel_config ─────────────────────
# Rejestruje atexit handler do flushowania pozostaych spanów/metryk/logów
_OTEL_SHUTDOWN_REGISTERED = False


def _ensure_otel_shutdown_registered() -> None:
    """SUPERMOC: Rejestruje atexit shutdown dla OTel providerów.

    Zapewnia, że TracerProvider.shutdown() i MeterProvider.shutdown()
    są wywoływane przy wyjściu z aplikacji.
    """
    global _OTEL_SHUTDOWN_REGISTERED
    if _OTEL_SHUTDOWN_REGISTERED:
        return
    try:
        from nexus_ai.core.otel_config import register_otel_shutdown
        from opentelemetry import trace, metrics

        tracer_provider = trace.get_tracer_provider()
        meter_provider = metrics.get_meter_provider()
        if hasattr(tracer_provider, "shutdown"):
            register_otel_shutdown(
                tracer_provider=tracer_provider,
                meter_provider=meter_provider if hasattr(meter_provider, "shutdown") else None,
            )
            _OTEL_SHUTDOWN_REGISTERED = True
            logger.debug("[STARTUP] OTel graceful shutdown registered")
    except Exception as exc:
        logger.debug("[STARTUP] OTel shutdown registration skipped: %s", exc)


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

    SUPERMOCE psutil:
      - Process.oneshot() — batch syscalls dla procesu
      - SystemMonitor.collect_all() — pełne metryki systemowe co 30s
      - memory_full_info() → USS/PSS
      - cpu_percent(percpu=True) — per-core gauge
      - dysk I/O, sieć I/O, sensory temperatury

    Rejestruje task w ``app.state.bg_tasks`` zamiast manualnego
    ``anyio.ensure_backend().create_task()`` — task jest automatycznie
    anulowany przez ``cancel_all()`` podczas shutdownu.
    """
    try:
        from nexus_ai.core.monitor import process_monitor, system_monitor

        async def _update_system_metrics() -> None:
            """Periodically update all system-level gauges via OTel.

            Co 30s kolekcjonuje:
              - Proces: RSS, USS, CPU%, thready, FD
              - System: CPU per-core, RAM %, swap, dysk, sieć, temperatura
              - mimalloc leak detection
            """
            from nexus_ai.api.telemetry_metrics import (
                record_mimalloc_stats,
                set_memory_usage,
            )

            while True:
                try:
                    # SUPERMOC: oneshot() — batch syscalls
                    # ObservableGauge w telemetry_metrics.py zastąpił ręczne set()
                    # CPU, RAM, DISK, TEMP są teraz odczytywane automatycznie przez SDK
                    proc_metrics = process_monitor.collect_metrics()
                    set_memory_usage(proc_metrics.rss_mb)

                    # SUPERMOC: pełne metryki systemowe (logowane, nie gauge)
                    # gauge'e są obsługiwane przez ObservableGauge w init_metrics()
                    sys_metrics = system_monitor.collect_all()

                    # Loguj co 5 minut dla AUDIT
                    import time as _time

                    if int(_time.time()) % 300 < 30:  # co ~5min
                        logger.bind(level="AUDIT").info(
                            "[SYSTEM-METRICS] RSS=%.1fMB USS=%.1fMB CPU=%.1f%% "
                            "RAM=%.1f%% DISK=%.1f%% SWAP=%.1f%% TEMP=%.1f°C "
                            "NET_IN=%.1fMB NET_OUT=%.1fMB",
                            proc_metrics.rss_mb,
                            proc_metrics.uss_mb or 0.0,
                            proc_metrics.cpu_percent,
                            sys_metrics.ram_percent,
                            sys_metrics.disk_percent,
                            sys_metrics.swap_percent,
                            sys_metrics.cpu_temp_celsius or 0.0,
                            sys_metrics.net_bytes_recv_mb,
                            sys_metrics.net_bytes_sent_mb,
                        )
                except Exception:
                    pass

                # Co 30s sprawdź czy mimalloc nie ma wycieku
                try:
                    record_mimalloc_stats()
                except Exception:
                    pass

                await anyio.sleep(30)

        await app.state.bg_tasks.start_task(
            "metrics_updater",
            _update_system_metrics,
            metadata=TaskMetadata(
                description="System metrics gauge + mimalloc leak detection (30s interval)",
            ),
        )
        logger.info(
            "[METRICS] System metrics updater + mimalloc leak detection started (30s interval)"
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
    """Seed data after native SQL migrations have created all tables.

    All tables and columns are created by native SQL migrations (001-004).
    This function only seeds runtime data:
    - RBAC: roles, permissions, admin user, mappings (via seed_rbac)
    """
    from scripts.seed_data import seed_rbac

    logger.info("[SEED] Tables created by native SQL migrations — seeding RBAC")

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
            0. Config + ML cache + pendulum locale
            1. Metryki OTel (sync + background task)
            2. Database engine + core services (pre-created przez SQLAlchemyPlugin)      3. Native SQLite migrations + seed danych
        4. Broker, DuckDB warm-up, auto-seed
        5. HotReloadListener

          Engine i session_factory są współdzielone z SQLAlchemyPlugin.
        """

        config = app.dependencies["config"]()

        # ── SUPERMOC pendulum: Ustaw polską lokalizację dla całej aplikacji ──
        # diff_for_humans(), format(), day_of_week itp. będą po polsku.
        try:
            pendulum.set_locale("pl")
        except Exception:
            pass  # locale 'pl' może nie być zainstalowana w niektórych środowiskach

        # ── Phase 0: Config + ML cache ───────────────────────────────
        app.state.ml_cache_env = _configure_ml_cache_directories(config.base_dir)

        # ── Phase 0.5: mimalloc bridge + metrics ──────────────────────
        try:
            from nexus_ai.core.mimalloc_bridge import (
                MIOption,
                is_active as _mi_active,
                option_set as _mi_set,
            )

            if _mi_active():
                logger.info("[MIMALLOC] mimalloc ACTIVE — Microsoft allocator engaged")
                # Ustaw optymalne opcje w runtime (nadpisanie env varów)
                _mi_set(MIOption.LARGE_OS_PAGES, 1)  # Huge OS pages
                _mi_set(MIOption.ALLOW_LARGE_OS_PAGES, 1)  # Allow large pages
                _mi_set(MIOption.SHOW_STATS, 0)  # Stats off by default
                _mi_set(MIOption.EAGER_COMMIT, 1)  # Eager commit
            else:
                logger.warning("[MIMALLOC] mimalloc NOT active — using system allocator")
        except Exception as exc:
            logger.debug("[MIMALLOC] Bridge check failed: %s", exc)

        # ── Phase 1: OpenTelemetry metrics ───────────────────────────
        try:
            _init_otel_metrics_sync()
            # Rejestruj metryki mimalloc po inicjalizacji OTel
            from nexus_ai.api.telemetry_metrics import record_mimalloc_stats

            record_mimalloc_stats()
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

            # Taskiq event handlers są rejestrowane przez import nexus_ai.events.taskiq_events
            # Event emisja odbywa się przez broker.kick("event_emit_*", ...)
            logger.info("[STARTUP] Database engine ready (SQLAlchemyPlugin)")
        except Exception as exc:
            logger.critical("[STARTUP] Database engine init FAILED: %s", exc)
            if config.environment in {"stage", "prod"}:
                raise

        # ── Phase 3: Native SQLite migrations + seed data ──────────────
        if engine is not None:
            try:
                from migrations.run_migrations import (
                    get_current_version,
                    run_migrations,
                )

                db_path = str(config.sqlite_path)
                sqlcipher_key = os.getenv(config.sqlcipher_key_env, "").strip() or None

                # Sprawdź czy migracje są potrzebne
                current_ver = get_current_version(db_path)
                latest_file = "004_supermoces.sql"

                if current_ver is None or current_ver < latest_file:
                    logger.info(
                        "[STARTUP] Migration needed: %s -> %s",
                        current_ver or "(fresh DB)",
                        latest_file,
                    )
                    result = run_migrations(
                        db_path=db_path,
                        sqlcipher_key=sqlcipher_key,
                    )
                    logger.info(
                        "[STARTUP] Native migrations applied: %d files",
                        len(result["applied"]),
                    )
                else:
                    logger.info(
                        "[STARTUP] Database already at latest version (%s)",
                        current_ver,
                    )
            except Exception as exc:
                logger.critical("[STARTUP] Native migrations FAILED: %s", exc)
                if config.environment in {"stage", "prod"}:
                    raise

            try:
                await _seed_data(engine, config)
            except Exception as exc:
                logger.critical("[STARTUP] Seed data FAILED: %s", exc)
                if config.environment in {"stage", "prod"}:
                    raise

            try:
                # run_migration_sanity_checks and related functions are sync
                # Wrap in anyio.to_thread.run_sync for free-threaded safety
                sanity = await anyio.to_thread.run_sync(
                    run_migration_sanity_checks,
                    engine,
                    str(config.sqlite_path),
                )
                integrity = await anyio.to_thread.run_sync(
                    verify_migration_integrity,
                    engine,
                    config.migration_baseline_path,
                )
                checksums = await anyio.to_thread.run_sync(
                    verify_migration_checksums,
                    engine,
                    config.migration_checksum_baseline_path,
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
        # SUPERMOC HISHEL: Warm HTTP cache przy starcie API
        try:
            await warm_http_cache()
            logger.info("[HTTP-CACHE-WARM] Cache warmed at API startup")
        except Exception as exc:
            logger.debug("[HTTP-CACHE-WARM] Cache warming skipped (non-fatal): %s", exc)

        if not broker.is_worker_process:
            try:
                with anyio.fail_after(5.0):
                    await broker.startup()
                logger.info(
                    "[STARTUP] Taskiq broker started with middleware: metrics, pii-scan, tracing | "
                    "Result backend: SQLite"
                )
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

        # ── Phase 5: HotReloadListener ────────────────
        try:
            listener = HotReloadListener(nats_url=config.nats_url)
            await listener.start()
            app.state.hot_reload_listener = listener
            logger.info("[HOT-RELOAD] Listener started (nats_url=%s)", config.nats_url)
        except Exception as exc:
            logger.warning("[HOT-RELOAD] Failed to start listener: %s", exc)
            app.state.hot_reload_listener = None

        # ── Phase 6: Unix socket progress server ────────────────────
        try:
            await start_unix_progress_server()
        except Exception as exc:
            logger.warning("[UNIX-SOCKET] Failed to start progress server: %s", exc)

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

    # 3. Dispose DI engine cache (TaskiqDepends cached engines)
    try:
        await dispose_all_engines()
        logger.info("[SHUTDOWN] DI engines disposed")
    except Exception as exc:
        logger.warning("[SHUTDOWN] DI engine dispose error: %s", exc)

    # 3.5. Zamknij serwer socket UNIX
    try:
        await stop_unix_progress_server()
    except Exception as exc:
        logger.warning("[SHUTDOWN] Unix socket server stop error: %s", exc)

    # 4. Konsolidacja WAL + zwolnienie zasobów engine'u
    if engine is not None:
        await consolidate_database(engine)
        await engine.dispose()

    # 4. Czyszczenie cache ML
    for cache_dir in (app.state.ml_cache_env or {}).values():
        try:
            shutil.rmtree(cache_dir, ignore_errors=True)
        except Exception:
            pass
