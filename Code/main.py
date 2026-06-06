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
import asyncio
import os
import signal
import subprocess
import sys
from pathlib import Path

# ── Ensure Code/ is on sys.path ──
_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_CODE_DIR = str(_PROJECT_ROOT / "Code")
if _CODE_DIR not in sys.path:
    sys.path.insert(0, _CODE_DIR)

# ── Logging setup ──
from core.logger import get_logger, setup_logger  # noqa: E402

setup_logger(app_name="NexusAI")
logger = get_logger("nexus.main")

# ── Global shutdown event ──
_shutdown_event = asyncio.Event()


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
    parser.add_argument("--skip-models", action="store_true", help="Skip AI model checks")
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
    return parser


def _set_env_from_args(args: argparse.Namespace) -> None:
    os.environ.setdefault("NEXUS_HOST", args.host)
    os.environ.setdefault("NEXUS_PORT", str(args.port))


async def _run_bootstrap(args: argparse.Namespace | None = None) -> None:
    from scripts.bootstrap import run_bootstrap
    logger.info(">>> Bootstrap: Running comprehensive initialization...")
    steps = None
    if args:
        step_list = []
        if getattr(args, "skip_seed", False):
            step_list = ["validate_config", "check_dependencies", "check_ai_models",
                        "create_directories", "run_migrations", "initialize_olap",
                        "verify_nats", "verify_tigerbeetle"]
        if getattr(args, "skip_models", False):
            step_list = ["validate_config", "check_dependencies",
                        "create_directories", "run_migrations", "initialize_olap",
                        "seed_data", "verify_nats", "verify_tigerbeetle"]
        if step_list:
            steps = step_list
    report = await run_bootstrap(steps=steps)
    if report.overall_status == "error":
        logger.error("Bootstrap completed with ERRORS.")
    else:
        logger.info(">>> Bootstrap complete.")


def _start_api_server_sync(host: str, port: int) -> None:
    """Start the Litestar API server via Granian (Rust ASGI) — synchronicznie.

    Granian.serve() blokuje wątek, więc uruchamiamy w ``asyncio.to_thread``
    z async wrappera poniżej.
    """
    import granian

    log_level = os.getenv("NEXUS_LOG_LEVEL", "info").lower()

    if host == "unix":
        socket_path = os.getenv("NEXUS_UNIX_SOCKET", "/tmp/nexus-api.sock")
        server = granian.Granian(
            "api.app:create_app",
            unix_socket=socket_path,
            log_level=log_level,
        )
    else:
        server = granian.Granian(
            "api.app:create_app",
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

    shutdown_task = asyncio.create_task(_wait_and_shutdown())

    # Uruchom blokujący Granian.serve() w wątku tła
    loop = asyncio.get_running_loop()
    await loop.run_in_executor(None, _start_api_server_sync, host, port)

    shutdown_task.cancel()


async def _start_worker() -> None:
    from core.config import AppConfig
    AppConfig()
    logger.info(">>> Starting Taskiq worker...")

    cmd = [sys.executable, "-m", "luz.worker"]
    _CODE_DIR_PATH = _PROJECT_ROOT  # noqa: N806 / "Code"
    worker_proc = await asyncio.create_subprocess_exec(
        *cmd, cwd=_CODE_DIR_PATH,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    logger.info("Worker started (PID: %s)", worker_proc.pid)

    async def _read_stream(stream, label: str):
        while True:
            line = await stream.readline()
            if not line:
                break
            print(f"[{label}] {line.decode().rstrip()}")

    stdout_task = asyncio.create_task(_read_stream(worker_proc.stdout, "worker"))
    stderr_task = asyncio.create_task(_read_stream(worker_proc.stderr, "worker:err"))

    await asyncio.wait(
        [asyncio.create_task(_shutdown_event.wait()), asyncio.create_task(worker_proc.wait())],
        return_when=asyncio.FIRST_COMPLETED,
    )

    logger.info("Stopping worker (PID: %s)...", worker_proc.pid)
    worker_proc.terminate()
    try:
        await asyncio.wait_for(worker_proc.wait(), timeout=10.0)
    except TimeoutError:
        worker_proc.kill()
        await worker_proc.wait()

    stdout_task.cancel()
    stderr_task.cancel()


async def _start_all(args: argparse.Namespace) -> None:
    logger.info(">>> Starting NexusAI in 'all' mode...")
    if args.bootstrap:
        await _run_bootstrap(args)
    if sys.platform != "win32":
        for sig in (signal.SIGINT, signal.SIGTERM):
            signal.signal(sig, _handle_signal)

    api_task = asyncio.create_task(_start_api_server(args.host, args.port))
    worker_task = asyncio.create_task(_start_worker())

    await asyncio.wait([api_task, worker_task], return_when=asyncio.FIRST_COMPLETED)
    logger.info("Shutting down all services...")
    _shutdown_event.set()

    for task in [api_task, worker_task]:
        if not task.done():
            task.cancel()
            try:
                await task
            except asyncio.CancelledError:
                pass
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
        from alembic.config import Config
        ini_path = _PROJECT_ROOT / "alembic.ini"
        if not ini_path.exists():
            logger.error("[MIGRATE] alembic.ini not found at %s.", ini_path)
            return 1
        logger.info("[MIGRATE] Running: alembic upgrade head")
        alembic_cfg = Config(str(ini_path))
        command.upgrade(alembic_cfg, "head")
        logger.info("[MIGRATE] All migrations applied.")
        return 0
    except Exception as exc:
        logger.error("[MIGRATE] Migration failed: %s", exc, exc_info=True)
        return 1


def _run_fetch_models() -> None:
    try:
        from scripts.download_models import download_all_models
    except ImportError:
        logger.error("download_models script not found")
        return
    statuses = download_all_models()
    ok = sum(1 for s in statuses.values() if s in ("ok", "downloaded"))
    failed = sum(1 for s in statuses.values() if s in ("error", "mismatch"))
    logger.info(">>> Models: %d ok, %d failed.", ok, failed)


def _run_compute_checksums() -> None:
    try:
        from scripts.download_models import _compute_checksums
    except ImportError:
        try:
            from Code.SKRIPTS.download_models import _compute_checksums
        except ImportError:
            logger.error("download_models script not found")
            return
    _compute_checksums()


async def _run_load_fixtures() -> int:
    try:
        from core.config import AppConfig
        from scripts.seed_data import seed_all
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
        return asyncio.run(_run_load_fixtures())
    if args.compute_checksums:
        _run_compute_checksums()
        return 0
    if args.check_models:
        return 0
    if args.check_updates:
        return 0
    if args.fetch_models:
        _run_fetch_models()
        return 0

    logger.info("NexusAI starting — mode=%s host=%s port=%s", args.mode, args.host, args.port)

    try:
        if args.mode == "bootstrap":
            asyncio.run(_run_bootstrap(args))
        elif args.mode == "doctor":
            asyncio.run(_run_doctor())
        elif args.mode == "api":
            asyncio.run(_start_api(args))
        elif args.mode == "worker":
            asyncio.run(_start_worker_only(args))
        elif args.mode == "all":
            asyncio.run(_start_all(args))
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
        from scripts.doctor import run_diagnostics
    except ImportError:
        try:
            from Code.SKRIPTS.doctor import run_diagnostics
        except ImportError:
            logger.error("Doctor script not found")
            return
    run_diagnostics()


if __name__ == "__main__":
    raise SystemExit(main())
