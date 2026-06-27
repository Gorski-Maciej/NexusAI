import logging
import os
import secrets
import socket
import sys

import anyio
from pathlib import Path as _SyncPath

import anyio

import flet as ft
import pendulum
from structlog import get_logger

# --- KONFIGURACJA OFFLINE AI ---
if getattr(sys, "frozen", False):
    base_path = _SyncPath(sys._MEIPASS)
else:
    base_path = _SyncPath(__file__).parent

models_cache_dir = base_path / "models"
os.environ["HF_HOME"] = str(models_cache_dir)

# --- LOGOWANIE ---
log_dir = _SyncPath("logs")
log_dir.mkdir(exist_ok=True)
log_file = log_dir / f"nexus_{pendulum.now().format('YYYYMMDD')}.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[logging.StreamHandler(), logging.FileHandler(log_file, encoding="utf-8")],
)
logger = get_logger("nexus.main")

# --- IMPORTY WEWNĘTRZNE ---
from nexus_ai.core.config import AppConfig  # noqa: E402
from nexus_ai.scripts.setup_env import bootstrap_system  # noqa: E402


def get_free_port() -> int:
    """Dynamicznie znajduje wolny port na localhost."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("", 0))
        return s.getsockname()[1]


def is_already_running(port=47999):
    """Single Instance Lock."""
    try:
        lock_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        lock_socket.bind(("127.0.0.1", port))
        globals()["_lock_socket"] = lock_socket
        return False
    except OSError:
        return True


class NexusOrchestrator:
    """Zarządza NATS, Workerem i API (Granian), gwarantując restart i poprawne zamknięcie."""

    def __init__(self):
        self.config = AppConfig()
        self.nats_process = None
        self.worker_process = None
        self.api_process = None
        self.bootstrap_token = secrets.token_urlsafe(32)
        self._subprocess_env = self._build_subprocess_env()

    @staticmethod
    def _build_subprocess_env() -> dict[str, str]:
        env = os.environ.copy()
        ld_preload = env.get("LD_PRELOAD", "")
        if "libmimalloc" not in ld_preload:
            cands = [
                "/usr/lib/libmimalloc.so",
                "/usr/lib/x86_64-linux-gnu/libmimalloc.so",
                "/usr/lib/aarch64-linux-gnu/libmimalloc.so",
                "/usr/local/lib/libmimalloc.so",
            ]
            conda_prefix = os.environ.get("CONDA_PREFIX", "")
            if conda_prefix:
                cands.insert(0, f"{conda_prefix}/lib/libmimalloc.so")
            for candidate in cands:
                if os.path.exists(candidate):
                    if ld_preload:
                        env["LD_PRELOAD"] = f"{candidate}:{ld_preload}"
                    else:
                        env["LD_PRELOAD"] = candidate
                    break
        env.setdefault("MIMALLOC_LARGE_OS_PAGES", "1")
        env.setdefault("MIMALLOC_RESERVE_HUGE_OS_PAGES", "1")
        env.setdefault("MIMALLOC_EAGER_COMMIT_DELAY", "0")
        env.setdefault("MIMALLOC_PAGE_RESET", "0")
        return env

    async def start_nats(self):
        nats_bin = "nats-server.exe" if os.name == "nt" else "nats-server"
        nats_path = self.config.base_dir / nats_bin
        if nats_path.exists():
            logger.info("Uruchamianie NATS JetStream z mimalloc...")
            self.nats_process = await anyio.Process(
                [str(nats_path), "-p", "4222", "-js"],
                stdout=anyio.ProcessPipe.DEVNULL,
                stderr=anyio.ProcessPipe.DEVNULL,
                env=self._subprocess_env,
            ).__aenter__()
            await anyio.sleep(2)
        else:
            logger.error("Nie znaleziono binarki NATS!")

    async def start_worker(self):
        logger.info("Uruchamianie Workera AI...")
        cmd = [
    sys.executable, "-m", "taskiq", "worker",
    "worker:broker",
    "--fs-startup",
    "--workers", os.getenv("NEXUS_WORKER_PROCESSES", "2"),
    "--max-async-tasks", os.getenv("NEXUS_WORKER_MAX_ASYNC", "10"),
    "--max-prefetch", os.getenv("NEXUS_WORKER_PREFETCH", "3"),
    "--ack-type", "when_executed",
    "--log-level", os.getenv("NEXUS_LOG_LEVEL", "info"),
]
        self.worker_process = await anyio.Process(
            cmd, env=self._subprocess_env
        ).__aenter__()

    async def start_backend_api(self, port: int):
        backend_env = os.environ.copy()
        backend_env["NEXUS_PORT"] = str(port)
        backend_env["NEXUS_TOKEN"] = self.bootstrap_token
        project_root = _SyncPath(__file__).resolve().parent.parent.parent
        backend_env["PYTHONPATH"] = str(project_root)

        logger.info(f"Inicjalizacja API (Granian) na http://127.0.0.1:{port}")
        logger.info(
            "[GRANIAN] Superpowers: backpressure=100, backlog=2048, "
            "HTTP/2=auto, metrics=true, loop=auto, respawn=true"
        )
        self.api_process = await anyio.Process(
            [
                sys.executable,
                "-c",
                "from nexus_ai.api.server import run_backend; run_backend()",
            ],
            env=backend_env,
            stdout=anyio.ProcessPipe.PIPE,
            stderr=anyio.ProcessPipe.PIPE,
        ).__aenter__()
        await anyio.sleep(2)

    def cleanup(self):
        logger.info("Zamykanie komponentów Nexus AI...")
        for proc in [self.api_process, self.worker_process, self.nats_process]:
            if proc is not None and proc.returncode is None:
                logger.debug("Wysyłanie SIGTERM do procesu PID=%d", proc.pid)
                proc.terminate()
        import time as _sync_time
        _sync_time.sleep(0.5)
        for proc in [self.api_process, self.worker_process, self.nats_process]:
            if proc is not None and proc.returncode is None:
                try:
                    proc.kill()
                except ProcessLookupError:
                    pass
        logger.info("System zamknięty pomyślnie.")


async def main_ui(page: ft.Page, orchestrator: NexusOrchestrator, port: int):
    """Główny punkt wejścia dla interfejsu graficznego z progress dialog (zamiast splash page)."""
    page.title = "Nexus AI - System Księgowy"
    page.theme_mode = ft.ThemeMode.DARK

    # SUPERMOC: AlertDialog zamiast page.clean() — płynniejsze przejście
    splash = ft.AlertDialog(
        modal=True,
        content=ft.Column(
            [
                ft.Image(src="assets/logo_splash.png", width=150, height=150),
                ft.Divider(height=20, color="transparent"),
                ft.ProgressBar(width=300, color="blue", bgcolor="#1e1e1e"),
            ],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            width=350,
        ),
    )
    page.dialog = splash
    splash.open = True
    page.update()

    # SUPERMOC: SafeArea — obsługa notchy na urządzeniach mobilnych
    page.add(ft.SafeArea(ft.Container()))

    status_text = ft.Text("Przygotowywanie systemów...", size=14, italic=True)

    status_text.value = "Krok 1/4: Sprawdzanie bazy danych..."
    page.update()
    await bootstrap_system()
    await nexus_ai.scripts.doctor.run_diagnostics()

    status_text.value = "Krok 2/4: Uruchamianie magistrali danych..."
    page.update()
    await orchestrator.start_nats()

    status_text.value = "Krok 3/4: Budzenie silników AI..."
    page.update()
    await orchestrator.start_worker()
    await orchestrator.start_backend_api(port)

    status_text.value = "Krok 4/4: Synchronizacja interfejsu..."
    page.update()
    await anyio.sleep(1.5)

    async with anyio.create_task_group() as tg:
        tg.start_soon(_check_updates_on_startup, page)

    # Zamknij splash
    splash.open = False
    page.window_width = 1280
    page.window_height = 850
    page.window_resizable = True

    page.session.set("api_port", port)
    page.session.set("api_token", orchestrator.bootstrap_token)

    from ui.root import NexusRootUI

    app_ui = NexusRootUI(page, orchestrator)
    await app_ui.build()
    page.update()


async def _check_system_dependencies() -> bool:
    try:
        from installer.dependency_ui import run_dependency_ui
        return run_dependency_ui()
    except Exception:
        return True


async def _check_models_on_startup() -> bool:
    try:
        from installer.download_progress_ui import check_and_download_if_needed
        models_dir = _SyncPath("models")
        return check_and_download_if_needed(models_dir)
    except Exception:
        return True


async def _check_updates_on_startup(page: ft.Page | None = None):
    try:
        from installer.updater import check_for_updates
        result = await check_for_updates()
        if result.update_available and result.info:
            logger.info("[Updater] Update available: v%s", result.latest_version)
    except Exception:
        pass


async def start_app():
    if is_already_running():
        print("Nexus AI już działa.")
        sys.exit(1)

    await _check_system_dependencies()
    await _check_models_on_startup()

    orchestrator = NexusOrchestrator()
    backend_port = get_free_port()

    try:
        await ft.app_async(target=lambda page: main_ui(page, orchestrator, backend_port))
    except Exception as e:
        logger.critical(f"BŁĄD KRYTYCZNY STARTU: {e}")
    finally:
        from loguru import logger as _loguru_logger
        _loguru_logger.complete()
        orchestrator.cleanup()


if __name__ == "__main__":
    try:
        anyio.run(start_app)
    except KeyboardInterrupt:
        pass
