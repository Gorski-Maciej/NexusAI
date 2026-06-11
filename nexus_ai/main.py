"""NexusAI — Central Application Entry Point

Zastępuje: Uvicorn → Granian (Rust ASGI server, 25-40% mniej RAM)

Usage:
    python main.py --mode api         # Start only the API server
    python main.py --mode worker      # Start only the Taskiq worker
    python main.py --mode all         # Start API + Worker (in-process)
    python main.py --mode bootstrap   # Initialize database and exit
    python main.py --help             # Show all options
"""

from __future__ import annotations

import argparse
import os
import signal
import sys

import anyio
from pathlib import Path

# ── Project root (directory containing nexus_ai/) ──
_PROJECT_ROOT = Path(__file__).resolve().parent

# ── Logging setup ──
from nexus_ai.core.logger import get_logger, setup_logger  # noqa: E402

setup_logger(app_name="NexusAI")
logger = get_logger("nexus.main")

# ── Global shutdown event ──
_shutdown_event = anyio.Event()


def _handle_signal(sig: int, _frame) -> None:
    logger.info("Received signal %s. Initiating graceful shutdown...", sig)
    _shutdown_event.set()


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="NexusAI — AI-Powered Accounting System",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Examples:
  python main.py --mode api
  python main.py --mode worker
  python main.py --mode all --bootstrap
  python main.py --mode doctor
  python main.py --migrate           # Run Alembic migrations
  python main.py --load-fixtures     # Load demo data
        """,
    )
    parser.add_argument(
        "--mode", type=str, default="api",
        choices=["api", "worker", "all", "bootstrap", "doctor"],
        help="Startup mode (default: api)",
    )
    parser.add_argument("--bootstrap", action="store_true", help="Run bootstrap initialization")
    parser.add_argument("--skip-seed", action="store_true", help="Skip seed data during bootstrap")
    parser.add_argument("--force-bootstrap", action="store_true", help="Force re-run bootstrap")
    parser.add_argument("--migrate", action="store_true", help="Run Alembic migrations and exit")
    parser.add_argument("--load-fixtures", action="store_true", help="Load demo/seed data and exit")
    parser.add_argument("--fetch-models", action="store_true", help="Download AI models and exit")
    parser.add_argument("--compute-checksums", action="store_true", help="Compute SHA-256 checksums for models")
    parser.add_argument("--check-models", action="store_true", help="Check AI model presence")
    parser.add_argument("--check-updates", action="store_true", help="Check for updates")
    parser.add_argument("--host", type=str, default="127.0.0.1", help="API bind address")
    parser.add_argument("--port", type=int, default=8000, help="API port")
    parser.add_argument("--workers", type=int, default=1, help="Number of workers")
    parser.add_argument(
        "--watch", action="store_true",
        help="Watch config/protocol files for changes and log auto-reload events",
    )
    parser.add_argument(
        "--watch-interval", type=int, default=None,
        help="Poll interval in seconds for --watch (default: 5 for protocols, 5 for config)",
    )
    return parser


def _set_env_from_args(args: argparse.Namespace) -> None:
    os.environ.setdefault("NEXUS_HOST", args.host)
    os.environ.setdefault("NEXUS_PORT", str(args.port))
    if getattr(args, "watch", False):
        os.environ["NEXUS_WATCH_MODE"] = "1"
        interval = str(args.watch_interval or 5)
        os.environ["NEXUS_WATCH_INTERVAL"] = interval


def setup_watch_mode(args: argparse.Namespace) -> None:
    """Włącz auto-reload dla wszystkich loaderów i loguj zmiany.

    Gdy --watch jest aktywne:
      1. ProtocolLoader z auto_reload=True (poll co watch_interval)
      2. ConfigLoader z auto_reload=True (poll co watch_interval)
      3. Callbacki logujące każdą zmianę pliku

    Callbacki są rejestrowane przed startem serwera, więc logują
    również pierwsze załadowanie plików.

    Args:
        args: Sparsowane argumenty CLI (muszą zawierać watch/watch_interval).
    """
    if not getattr(args, "watch", False):
        return

    raw_interval = getattr(args, "watch_interval", None)
    interval = (
        raw_interval
        if raw_interval is not None
        else int(os.getenv("NEXUS_WATCH_INTERVAL", "5"))
    )
    # auto_reload=0 / auto_reload=False is disabled — ale --watch wymaga enabled
    if not interval:
        interval = 5

    from nexus_ai.core.protocol_loader import get_protocol_loader
    from nexus_ai.core.config import get_config_loader

    logger.info(
        "=" * 56
    )
    logger.info("WATCH MODE ENABLED (poll every %ds)", interval)
    logger.info("Watching: protocols.toml, config/*.toml")
    logger.info(
        "=" * 56
    )

    # --- ProtocolLoader z auto-reload ---
    protocol_loader = get_protocol_loader(auto_reload=interval)

    def _on_protocols_changed(version: str | None) -> None:
        if version:
            logger.info(
                "🔄 [WATCH] protocols.toml → version=%s (auto-reloaded)",
                version,
            )
        else:
            logger.info("🔄 [WATCH] protocols.toml → changed (auto-reloaded)")

    protocol_loader.on_change(_on_protocols_changed)

    # --- ConfigLoader z auto-reload ---
    config_loader = get_config_loader(auto_reload=interval)

    def _on_config_changed() -> None:
        env = os.getenv("NEXUS_ENV", "dev")
        logger.info(
            "🔄 [WATCH] config/%s.toml → changed (auto-reloaded)",
            env,
        )

    config_loader.on_change(_on_config_changed)


async def _run_bootstrap(args: argparse.Namespace | None = None) -> None:
    from nexus_ai.scripts.bootstrap import run_bootstrap
    logger.info(">>> Bootstrap: Running comprehensive initialization...")
    steps = None
    if args:
        step_list = []
        if getattr(args, "skip_seed", False):
            step_list = ["validate_config", "check_dependencies", "check_ai_models",
                        "create_directories", "run_migrations", "initialize_olap",
                        "verify_nats", "verify_tigerbeetle"]
        if step_list:
            steps = step_list
    report = await run_bootstrap(steps=steps)
    if report.overall_status == "error":
        logger.error("Bootstrap completed with ERRORS.")
    else:
        logger.info(">>> Bootstrap complete.")


def _start_api_server_sync(host: str, port: int) -> None:
    """Start the Litestar API server via Granian (Rust ASGI) — synchronicznie.

    Granian.serve() blokuje wątek, więc uruchamiamy w ``anyio.to_thread.run_sync()``
    z async wrappera ponizej.
    """
    import granian

    log_level = os.getenv("NEXUS_LOG_LEVEL", "info").lower()

    if host == "unix":
        socket_path = os.getenv("NEXUS_UNIX_SOCKET", "/tmp/nexus-api.sock")
        server = granian.Granian(
            "nexus_ai.api.app:create_app",
            unix_socket=socket_path,
            log_level=log_level,
        )
    else:
        server = granian.Granian(
            "nexus_ai.api.app:create_app",
            host=host,
            port=port,
            log_level=log_level,
        )
    server.serve()


async def _start_api_server(host: str, port: int) -> None:
    """Start the API server via Granian w wątku tła."""
    logger.info(">>> Starting API server on %s:%s (Granian)", host, port)

    if sys.platform != "win32":
        for sig in (signal.SIGINT, signal.SIGTERM):
            signal.signal(sig, _handle_signal)

    async def _wait_and_shutdown():
        await _shutdown_event.wait()
        logger.info("Shutdown requested... (Granian will exit on next request)")

    async with anyio.create_task_group() as tg:
        tg.start_soon(_wait_and_shutdown)
        # Uruchom blokujący Granian.serve() w wątku tła
        await anyio.to_thread.run_sync(_start_api_server_sync, host, port)
        tg.cancel_scope.cancel()


async def _start_worker() -> None:
    from nexus_ai.core.config import AppConfig
    AppConfig()
    logger.info(">>> Starting Taskiq worker...")

    cmd = [sys.executable, "-m", "nexus_ai.luz.worker"]
    worker_proc = await anyio.open_process(
        cmd, cwd=_PROJECT_ROOT,
        stdout=anyio.abc.ProcessPipe.PIPE, stderr=anyio.abc.ProcessPipe.PIPE,
    )
    logger.info("Worker started (PID: %s)", worker_proc.pid)

    async def _read_stream(stream, label: str):
        while True:
            line = await stream.readline()
            if not line:
                break
            print(f"[{label}] {line.decode().rstrip()}")

    async with anyio.create_task_group() as tg:
        tg.start_soon(_read_stream, worker_proc.stdout, "worker")
        tg.start_soon(_read_stream, worker_proc.stderr, "worker:err")

    async with anyio.create_task_group() as tg:
        tg.start_soon(_shutdown_event.wait)
        tg.start_soon(worker_proc.wait)

    logger.info("Stopping worker (PID: %s)...", worker_proc.pid)
    worker_proc.terminate()
    try:
        with anyio.fail_after(10.0):
            await worker_proc.wait()
    except TimeoutError:
        worker_proc.kill()
        await worker_proc.wait()


async def _start_all(args: argparse.Namespace) -> None:
    logger.info(">>> Starting NexusAI in 'all' mode...")
    if args.bootstrap:
        await _run_bootstrap(args)
    if sys.platform != "win32":
        for sig in (signal.SIGINT, signal.SIGTERM):
            signal.signal(sig, _handle_signal)

    async with anyio.create_task_group() as tg:
        tg.start_soon(_start_api_server, args.host, args.port)
        tg.start_soon(_start_worker)

    # Oryginalna logika została zastąpiona przez anyio task group
    # Task group zakończy się gdy pierwsze zadanie się zakończy
    _shutdown_event.set()
    logger.info("All services stopped.")


async def _start_api(args: argparse.Namespace) -> None:
    if args.bootstrap:
        await _run_bootstrap(args)
    if sys.platform != "win32":
        for sig in (signal.SIGINT, signal.SIGTERM):
            signal.signal(sig, _handle_signal)
    await _start_api_server(args.host, args.port)


async def _start_worker_only(args: argparse.Namespace) -> None:
    if args.bootstrap:
        await _run_bootstrap(args)
    if sys.platform != "win32":
        for sig in (signal.SIGINT, signal.SIGTERM):
            signal.signal(sig, _handle_signal)
    await _start_worker()


def _run_alembic_migrations() -> int:
    try:
        from alembic import command
        from nexus_ai.core.alembic_utils import get_alembic_config
        alembic_cfg = get_alembic_config()
        if alembic_cfg is None:
            logger.error("[MIGRATE] Cannot get Alembic config (pyproject.toml missing or [tool.alembic] not found)")
            return 1
        logger.info("[MIGRATE] Running: alembic upgrade head (config from pyproject.toml [tool.alembic])")
        command.upgrade(alembic_cfg, "head")
        logger.info("[MIGRATE] All migrations applied.")
        return 0
    except Exception as exc:
        logger.error("[MIGRATE] Migration failed: %s", exc, exc_info=True)
        return 1




async def _run_load_fixtures() -> int:
    try:
        from nexus_ai.core.config import AppConfig
        from nexus_ai.scripts.seed_data import seed_all
        config = AppConfig()
        result = await seed_all(config)
        total = sum(result.values())
        logger.info("[FIXTURES] Seed data loaded: %d entities.", total)
        return 0
    except Exception as exc:
        logger.error("[FIXTURES] Failed: %s", exc, exc_info=True)
        return 1


def main(argv: list[str] | None = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)
    _set_env_from_args(args)

    if args.migrate:
        return _run_alembic_migrations()
    if args.load_fixtures:
        return anyio.run(_run_load_fixtures)
    if args.compute_checksums:
        logger.info("--compute-checksums: use python -m nexus_ai.scripts.download_models --verify-only")
        return 0
    if args.check_models:
        return 0
    if args.check_updates:
        return 0
    if args.fetch_models:
        logger.info("--fetch-models: użyj python -m nexus_ai.scripts.download_models --surya")
        return 0

    # Włącz watch mode jeśli --watch
    setup_watch_mode(args)

    logger.info("NexusAI starting — mode=%s host=%s port=%s", args.mode, args.host, args.port)

    try:
        if args.mode == "bootstrap":
            anyio.run(_run_bootstrap, args)
        elif args.mode == "doctor":
            anyio.run(_run_doctor)
        elif args.mode == "api":
            anyio.run(_start_api, args)
        elif args.mode == "worker":
            anyio.run(_start_worker_only, args)
        elif args.mode == "all":
            anyio.run(_start_all, args)
        else:
            parser.print_help()
            return 1
    except KeyboardInterrupt:
        logger.info("Interrupted by user.")
    except Exception as exc:
        logger.critical("Fatal error: %s", exc, exc_info=True)
        return 1

    logger.info("NexusAI stopped.")
    return 0


async def _run_doctor() -> None:
    try:
        from nexus_ai.scripts.doctor import run_diagnostics
    except ImportError:
        logger.error("Doctor script not found")
        return
    await run_diagnostics()


if __name__ == "__main__":
    raise SystemExit(main())
