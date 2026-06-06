import asyncio
import logging
import os
import secrets
import socket
import subprocess
import sys
from datetime import datetime
from pathlib import Path

import flet as ft

# --- KONFIGURACJA OFFLINE AI ---
if getattr(sys, 'frozen', False):
    base_path = Path(sys._MEIPASS)
else:
    base_path = Path(__file__).parent

models_cache_dir = base_path / "models"
os.environ["HF_HOME"] = str(models_cache_dir)
os.environ["TRANSFORMERS_OFFLINE"] = "1"

# --- LOGOWANIE ---
log_dir = Path("logs")
log_dir.mkdir(exist_ok=True)
log_file = log_dir / f"nexus_{datetime.now().strftime('%Y%m%d')}.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[logging.StreamHandler(), logging.FileHandler(log_file, encoding="utf-8")]
)
logger = logging.getLogger("nexus.main")

# --- IMPORTY WEWNĘTRZNE ---
from core.config import AppConfig  # noqa: E402
from scripts.doctor import run_diagnostics  # noqa: E402
from scripts.setup_env import bootstrap_system  # noqa: E402


def get_free_port() -> int:
    """Dynamicznie znajduje wolny port na localhost."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('', 0))
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

    async def start_nats(self):
        """Uruchamia lokalny serwer NATS z JetStream."""
        nats_bin = "nats-server.exe" if os.name == "nt" else "nats-server"
        nats_path = self.config.base_dir / nats_bin
        if nats_path.exists():
            logger.info("Uruchamianie NATS JetStream...")
            self.nats_process = subprocess.Popen(
                [str(nats_path), "-p", "4222", "-js"],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )
            await asyncio.sleep(2)
        else:
            logger.error("Nie znaleziono binarki NATS!")

    async def start_worker(self):
        """Uruchamia proces Taskiq worker (OCR/AI)."""
        logger.info("Uruchamianie Workera AI...")
        cmd = [sys.executable, "-m", "taskiq", "worker", "worker:broker", "--fs-startup"]
        self.worker_process = subprocess.Popen(cmd)

    async def start_backend_api(self, port: int):
        """Uruchamia serwer API (Litestar + Granian) jako proces."""
        backend_env = os.environ.copy()
        backend_env["NEXUS_PORT"] = str(port)
        backend_env["NEXUS_TOKEN"] = self.bootstrap_token
        backend_env["PYTHONPATH"] = str(Path.cwd())

        # Granian zamiast Uvicorn
        logger.info(f"Inicjalizacja API (Granian) na http://127.0.0.1:{port}")
        self.api_process = subprocess.Popen(
            [sys.executable, "-c",
             f"import granian; granian.Granian('api.app:create_app', host='127.0.0.1', port={port}).serve()"],
            env=backend_env,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        await asyncio.sleep(2)

    def cleanup(self):
        """Krytyczne sprzątanie procesów."""
        logger.info("Zamykanie komponentów Nexus AI...")
        if self.worker_process:
            self.worker_process.terminate()
        if self.nats_process:
            self.nats_process.terminate()
        if self.api_process:
            self.api_process.terminate()
        logger.info("System zamknięty pomyślnie.")


async def main_ui(page: ft.Page, orchestrator: NexusOrchestrator, port: int):
    """Główny punkt wejścia dla interfejsu graficznego ze Splash Screenem."""
    page.title = "Nexus AI - System Księgowy"
    page.window_width = 450
    page.window_height = 600
    page.window_resizable = False
    page.theme_mode = ft.ThemeMode.DARK
    page.window_always_on_top = True

    status_text = ft.Text("Przygotowywanie systemów...", size=14, italic=True)
    pb = ft.ProgressBar(width=350, color="blue", bgcolor="#1e1e1e")

    page.add(
        ft.Container(
            content=ft.Column([
                ft.Image(src="assets/logo_splash.png", width=150),
                ft.Divider(height=40, color="transparent"),
                status_text, pb
            ], horizontal_alignment=ft.CrossAxisAlignment.CENTER),
            expand=True, alignment=ft.alignment.center
        )
    )
    page.update()

    status_text.value = "Krok 1/4: Sprawdzanie bazy danych..."
    page.update()
    await bootstrap_system()
    run_diagnostics()

    status_text.value = "Krok 2/4: Uruchamianie magistrali danych..."
    page.update()
    await orchestrator.start_nats()

    status_text.value = "Krok 3/4: Budzenie silników AI..."
    page.update()
    await orchestrator.start_worker()
    await orchestrator.start_backend_api(port)

    status_text.value = "Krok 4/4: Synchronizacja interfejsu..."
    page.update()
    await asyncio.sleep(1.5)

    asyncio.create_task(_check_updates_on_startup(page))

    page.clean()
    page.window_always_on_top = False
    page.window_resizable = True
    page.window_width = 1280
    page.window_height = 850

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
        models_dir = Path("models")
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
        await ft.app_async(
            target=lambda page: main_ui(page, orchestrator, backend_port)
        )
    except Exception as e:
        logger.critical(f"BŁĄD KRYTYCZNY STARTU: {e}")
    finally:
        orchestrator.cleanup()


if __name__ == "__main__":
    if os.name == "nt":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    try:
        asyncio.run(start_app())
    except KeyboardInterrupt:
        pass
