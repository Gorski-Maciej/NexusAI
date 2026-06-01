"""
NexusAI — Central Application Entry Point
==========================================

Usage:
    python main.py --mode api         # Start only the API server
    python main.py --mode worker      # Start only the Taskiq worker
    python main.py --mode all         # Start API + Worker (in-process)
    python main.py --mode bootstrap   # Initialize database and exit
    python main.py --help             # Show all options    Examples:
    # Start API server with custom host/port
    python main.py --mode api --host 0.0.0.0 --port 8080

    # Full startup with bootstrap + API + worker
    python main.py --mode all --bootstrap

    # Run diagnostics and exit
    python main.py --mode doctor

    # Compute SHA-256 checksums for downloaded models
    python main.py --compute-checksums
"""

from __future__ import annotations

import argparse
import asyncio
import os
import signal
import subprocess
import sys
from pathlib import Path

# ── Ensure Code/ is on sys.path so imports like `api.server` work ──
_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_CODE_DIR = str(_PROJECT_ROOT / "Code")
if _CODE_DIR not in sys.path:
    sys.path.insert(0, _CODE_DIR)

# ── Logging setup (deferred — use core.logger not logging.basicConfig) ──────
from core.logger import setup_logger, get_logger
setup_logger(app_name="NexusAI")
logger = get_logger("nexus.main")

# ── Global shutdown event ────────────────────────────────────────────────────
_shutdown_event = asyncio.Event()


def _handle_signal(sig: int, _frame) -> None:
    """Handle SIGINT/SIGTERM for graceful shutdown."""
    logger.info("Received signal %s. Initiating graceful shutdown...", sig)
    _shutdown_event.set()


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="NexusAI — AI-Powered Accounting System",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python main.py --mode api
  python main.py --mode worker
  python main.py --mode all --bootstrap
  python main.py --mode doctor
  python main.py --migrate           # Run Alembic migrations
  python main.py --load-fixtures     # Load demo data
        """,
    )
    parser.add_argument(
        "--mode",
        type=str,
        default="api",
        choices=["api", "worker", "all", "bootstrap", "doctor"],
        help="Startup mode (default: api)",
    )
    parser.add_argument(
        "--bootstrap",
        action="store_true",
        help="Run bootstrap initialization before starting services",
    )
    parser.add_argument(
        "--skip-seed",
        action="store_true",
        help="Skip seed data loading during bootstrap",
    )
    parser.add_argument(
        "--skip-models",
        action="store_true",
        help="Skip AI model checks during bootstrap",
    )
    parser.add_argument(
        "--force-bootstrap",
        action="store_true",
        help="Force re-run bootstrap even if already initialized",
    )
    parser.add_argument(
        "--migrate",
        action="store_true",
        help="Run Alembic database migrations and exit",
    )
    parser.add_argument(
        "--load-fixtures",
        action="store_true",
        help="Load demo/seed data into the database and exit",
    )
    parser.add_argument(
        "--fetch-models",
        action="store_true",
        help="Download AI models (GGUF) with integrity verification and exit",
    )
    parser.add_argument(
        "--compute-checksums",
        action="store_true",
        help="Compute SHA-256 checksums for downloaded models and print ready-to-use MODEL_MANIFEST entries",
    )
    parser.add_argument(
        "--check-models",
        action="store_true",
        help="Check AI model presence and open download UI if missing (first-run setup)",
    )
    parser.add_argument(
        "--check-updates",
        action="store_true",
        help="Check for available updates and display update dialog if found",
    )
    parser.add_argument(
        "--host",
        type=str,
        default="127.0.0.1",
        help="API server bind address (default: 127.0.0.1)",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=8000,
        help="API server port (default: 8000)",
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=1,
        help="Number of worker processes (default: 1)",
    )
    return parser


def _set_env_from_args(args: argparse.Namespace) -> None:
    """Propagate CLI args to environment variables for downstream consumers."""
    os.environ.setdefault("NEXUS_HOST", args.host)
    os.environ.setdefault("NEXUS_PORT", str(args.port))


async def _run_bootstrap(args: argparse.Namespace | None = None) -> None:
    """Run comprehensive multi-step bootstrap."""
    from SKRIPTS.bootstrap import run_bootstrap

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
        logger.error("Bootstrap completed with ERRORS. Check logs above.")
    else:
        logger.info(">>> Bootstrap complete. System is ready.")


async def _run_doctor() -> None:
    """Run system diagnostics and report status."""
    try:
        from SKRIPTS.doctor import run_diagnostics
    except ImportError:
        try:
            from Code.SKRIPTS.doctor import run_diagnostics
        except ImportError:
            logger.error("Doctor script not found at Code/SKRIPTS/doctor.py")
            return

    logger.info(">>> Running system diagnostics...")
    run_diagnostics()
    logger.info(">>> Diagnostics complete.")


async def _start_api_server(host: str, port: int) -> None:
    """Start the Litestar API server via Uvicorn."""
    import uvicorn
    from api.app import create_app

    logger.info(">>> Starting API server on %s:%s", host, port)

    app = create_app()
    log_level = os.getenv("NEXUS_LOG_LEVEL", "info").lower()
    config = uvicorn.Config(
        app,
        host=host,
        port=port,
        loop="asyncio",
        log_level=log_level,
        access_log=True,
    )
    server = uvicorn.Server(config)

    # Handle shutdown signals
    if sys.platform != "win32":
        for sig in (signal.SIGINT, signal.SIGTERM):
            signal.signal(sig, _handle_signal)

    async def _wait_and_shutdown():
        await _shutdown_event.wait()
        logger.info("Shutdown requested, stopping API server...")
        server.should_exit = True

    shutdown_task = asyncio.create_task(_wait_and_shutdown())
    await server.serve()
    shutdown_task.cancel()


async def _start_worker() -> None:
    """Start the Taskiq worker as a subprocess."""
    from core.config import AppConfig

    config = AppConfig()
    logger.info(">>> Starting Taskiq worker...")

    # The worker module is at Code/luz/worker.py, run via `python -m luz.worker`
    # cwd is set to Code/ so the module is found under the Code/luz/ directory.
    cmd = [sys.executable, "-m", "luz.worker"]

    _CODE_DIR_PATH = _PROJECT_ROOT / "Code"
    worker_proc = await asyncio.create_subprocess_exec(
        *cmd,
        cwd=_CODE_DIR_PATH,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    logger.info("Worker started (PID: %s)", worker_proc.pid)

    # Read stdout/stderr in background
    async def _read_stream(stream, label: str):
        while True:
            line = await stream.readline()
            if not line:
                break
            print(f"[{label}] {line.decode().rstrip()}")

    stdout_task = asyncio.create_task(_read_stream(worker_proc.stdout, "worker"))
    stderr_task = asyncio.create_task(_read_stream(worker_proc.stderr, "worker:err"))

    # Wait for shutdown or worker exit
    await asyncio.wait(
        [
            asyncio.create_task(_shutdown_event.wait()),
            asyncio.create_task(worker_proc.wait()),
        ],
        return_when=asyncio.FIRST_COMPLETED,
    )

    # Graceful shutdown
    logger.info("Stopping worker (PID: %s)...", worker_proc.pid)
    worker_proc.terminate()
    try:
        await asyncio.wait_for(worker_proc.wait(), timeout=10.0)
        logger.info("Worker stopped.")
    except asyncio.TimeoutError:
        logger.warning("Worker did not stop in time, sending SIGKILL...")
        worker_proc.kill()
        await worker_proc.wait()

    stdout_task.cancel()
    stderr_task.cancel()


async def _start_all(args: argparse.Namespace) -> None:
    """Start API server and worker concurrently."""
    logger.info(">>> Starting NexusAI in 'all' mode...")

    if args.bootstrap:
        await _run_bootstrap(args)

    # Set up signal handling
    if sys.platform != "win32":
        for sig in (signal.SIGINT, signal.SIGTERM):
            signal.signal(sig, _handle_signal)

    api_task = asyncio.create_task(_start_api_server(args.host, args.port))
    worker_task = asyncio.create_task(_start_worker())

    await asyncio.wait(
        [api_task, worker_task],
        return_when=asyncio.FIRST_COMPLETED,
    )

    logger.info("Shutting down all services...")
    _shutdown_event.set()

    # Cancel remaining tasks
    for task in [api_task, worker_task]:
        if not task.done():
            task.cancel()
            try:
                await task
            except asyncio.CancelledError:
                pass

    logger.info("All services stopped.")


async def _start_api(args: argparse.Namespace) -> None:
    """Start only the API server."""
    if args.bootstrap:
        await _run_bootstrap(args)

    # Set up signal handling
    if sys.platform != "win32":
        for sig in (signal.SIGINT, signal.SIGTERM):
            signal.signal(sig, _handle_signal)

    await _start_api_server(args.host, args.port)


async def _start_worker_only(args: argparse.Namespace) -> None:
    """Start only the Taskiq worker."""
    if args.bootstrap:
        await _run_bootstrap(args)

    # Set up signal handling
    if sys.platform != "win32":
        for sig in (signal.SIGINT, signal.SIGTERM):
            signal.signal(sig, _handle_signal)

    await _start_worker()


def _run_alembic_migrations() -> int:
    """
    Run Alembic database migrations (``alembic upgrade head``).

    Uses the standard ``alembic.command`` API for reliability.
    Returns 0 on success, 1 on failure.
    """
    try:
        from alembic.config import Config
        from alembic import command

        ini_path = _PROJECT_ROOT / "alembic.ini"
        if not ini_path.exists():
            logger.error(
                "[MIGRATE] alembic.ini not found at %s. "
                "Run 'alembic init migrations' first.", ini_path
            )
            return 1

        logger.info("[MIGRATE] Running: alembic upgrade head")

        alembic_cfg = Config(str(ini_path))
        command.upgrade(alembic_cfg, "head")

        logger.info("[MIGRATE] All migrations applied successfully.")
        return 0
    except ImportError:
        logger.error(
            "[MIGRATE] Alembic is not installed. Install it with: pip install alembic"
        )
        return 1
    except Exception as exc:
        logger.error("[MIGRATE] Migration failed: %s", exc, exc_info=True)
        return 1


def _run_fetch_models() -> None:
    """Download AI models with SHA-256 integrity verification."""
    try:
        from SKRIPTS.download_models import download_all_models
    except ImportError:
        logger.error("download_models script not found at Code/SKRIPTS/download_models.py")
        return

    logger.info(">>> Downloading AI models...")
    statuses = download_all_models()

    ok = sum(1 for s in statuses.values() if s in ("ok", "downloaded"))
    failed = sum(1 for s in statuses.values() if s in ("error", "mismatch"))
    logger.info(">>> Models: %d ok, %d failed.", ok, failed)


def _run_compute_checksums() -> None:
    """Compute SHA-256 checksums for downloaded models and print ready-to-use entries."""
    try:
        from SKRIPTS.download_models import _compute_checksums
    except ImportError:
        try:
            from Code.SKRIPTS.download_models import _compute_checksums
        except ImportError:
            logger.error("download_models script not found at Code/SKRIPTS/download_models.py")
            return

    logger.info(">>> Computing SHA-256 checksums for downloaded models...")
    _compute_checksums()


async def _run_load_fixtures() -> int:
    """
    Load seed/demo data into the database.

    Returns 0 on success, 1 on failure.
    """
    try:
        from core.config import AppConfig
        from SKRIPTS.seed_data import seed_all

        logger.info("[FIXTURES] Loading seed data...")
        config = AppConfig()
        result = await seed_all(config)

        total = sum(result.values())
        logger.info("[FIXTURES] Seed data loaded: %d total entities created.", total)
        for entity, count in result.items():
            logger.info("  %-20s : %d", entity, count)

        return 0
    except ImportError as exc:
        logger.error(
            "[FIXTURES] Could not import seed_data module: %s. "
            "Make sure Code/ is on sys.path.", exc
        )
        return 1
    except Exception as exc:
        logger.error("[FIXTURES] Seed data loading failed: %s", exc, exc_info=True)
        return 1


def _run_check_models() -> None:
    """Check AI models and open first-run download UI if needed."""
    try:
        from installer.download_progress_ui import check_and_download_if_needed

        logger.info(">>> Checking AI model presence...")
        ready = check_and_download_if_needed()
        if ready:
            logger.info(">>> All AI models are ready.")
        else:
            logger.warning(">>> Some models could not be downloaded. The app may have limited functionality.")
    except ImportError:
        logger.warning("installer module not available — skipping model check")


def _run_check_updates() -> None:
    """Check for application updates and display result."""
    import asyncio

    async def _check():
        try:
            from installer.updater import check_for_updates, CURRENT_VERSION

            logger.info(">>> Checking for updates (current: %s)...", CURRENT_VERSION)
            result = await check_for_updates()

            if result.error:
                logger.warning(">>> Update check failed: %s", result.error)
                print(f"Update check failed: {result.error}")
                return

            if result.update_available:
                info = result.info
                print(f">>> Update available: v{result.latest_version}")
                print(f"    Current version: v{result.current_version}")
                print(f"    Release date: {info.release_date if info else 'N/A'}")
                print(f"    Download size: {info.download_size_mb if info else '?'} MB")
                if info and info.critical:
                    print(f"    ⚠ CRITICAL UPDATE — Recommended to install immediately")
                print(f"    Download URL: {info.download_url if info else 'N/A'}")
                if info and info.release_notes:
                    print(f"\n    Release notes:")
                    for line in info.release_notes.split('\n'):
                        print(f"      {line}")
            else:
                print(f">>> No updates available. Running latest version (v{result.latest_version}).")
        except ImportError:
            logger.warning("updater module not available — skipping update check")
        except Exception as exc:
            logger.warning("Update check failed: %s", exc)

    asyncio.run(_check())

def main(argv: list[str] | None = None) -> int:
    """
    NexusAI central entry point.

    Parses CLI arguments, configures the environment, and launches
    the requested components (API server, worker, or both).

    Additional commands:
        python main.py --migrate          # Alembic database migrations
        python main.py --load-fixtures    # Load demo/seed data
    """
    parser = _build_parser()
    args = parser.parse_args(argv)

    _set_env_from_args(args)

    # ── Handle standalone commands first ──────────────────────────────────

    if args.migrate:
        logger.info(">>> Running Alembic database migrations...")
        exit_code = _run_alembic_migrations()
        if exit_code == 0:
            logger.info(">>> Migrations completed successfully.")
        else:
            logger.error(">>> Migrations failed with exit code %d.", exit_code)
        return exit_code

    if args.load_fixtures:
        logger.info(">>> Loading seed/demo data...")
        exit_code = asyncio.run(_run_load_fixtures())
        if exit_code == 0:
            logger.info(">>> Seed data loaded successfully.")
        else:
            logger.error(">>> Seed data loading failed.")
        return exit_code

    if args.compute_checksums:
        logger.info(">>> Computing model checksums...")
        _run_compute_checksums()
        return 0

    if args.check_models:
        logger.info(">>> Checking AI models for first-run...")
        # Non-GUI check: just log what's missing and exit
        _run_check_models()
        return 0

    if args.check_updates:
        logger.info(">>> Checking for updates...")
        _run_check_updates()
        return 0

    if args.fetch_models:
        logger.info(">>> Fetching AI models...")
        _run_fetch_models()
        return 0

    # ── Standard startup modes ────────────────────────────────────────────

    logger.info(
        "NexusAI starting — mode=%s host=%s port=%s",
        args.mode,
        args.host,
        args.port,
    )

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


if __name__ == "__main__":
    raise SystemExit(main())
