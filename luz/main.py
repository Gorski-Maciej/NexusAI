import os
import sys
import socket
import subprocess
import time
import secrets
from pathlib import Path
import flet as ft

# --- KONFIGURACJA OFFLINE AI ---
if getattr(sys, 'frozen', False):
    # Jeśli aplikacja jest skompilowana jako .exe (PyInstaller)
    base_path = Path(sys._MEIPASS)
else:
    # Jeśli uruchamiamy z kodu źródłowego
    base_path = Path(__file__).parent

models_cache_dir = base_path / "models"
os.environ["HF_HOME"] = str(models_cache_dir)
os.environ["TRANSFORMERS_OFFLINE"] = "1" # Twarde wymuszenie trybu offline

def get_free_port() -> int:
    """Dynamicznie znajduje wolny, bezpieczny port na komputerze użytkownika."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('', 0)) # Bindowanie do portu 0 zmusza system do przydzielenia wolnego portu
        return s.getsockname()[1]

def launch_app():
    print("[Launcher] Inicjalizacja Nexus Accounting...")

    # 1. Generowanie jednorazowego tokena bezpieczeństwa (Handshake)
    bootstrap_token = secrets.token_urlsafe(32)

    # 2. Znalezienie wolnego portu
    backend_port = get_free_port()
    print(f"[Launcher] Przydzielono port: {backend_port}")

    # 3. Przygotowanie środowiska dla backendu
    backend_env = os.environ.copy()
    backend_env["NEXUS_PORT"] = str(backend_port)
    backend_env["NEXUS_TOKEN"] = bootstrap_token
    backend_env["PYTHONPATH"] = str(Path.cwd())

    # 4. Uruchomienie Serwera Litestar (przez uvicorn)
    print("[Launcher] Uruchamianie serwera API w tle...")
    backend_proc = subprocess.Popen(
        [sys.executable, "-m", "uvicorn", "api.server:app", "--port", str(backend_port)],
        env=backend_env,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )

    # Dajemy serwerowi chwilę na wstanie
    time.sleep(1.5)

    if backend_proc.poll() is not None:
        print("[Błąd] Backend nie mógł wystartować!")
        sys.exit(1)

    # 5. Uruchomienie okna interfejsu Flet
    from frontend.main_ui import main as start_ui

    def ui_wrapper(page: ft.Page):
        page.title = "Nexus Accounting"
        page.window_width = 1200
        page.window_height = 800

        # Zapisujemy dane połączeniowe w sesji
        page.session.set("api_port", backend_port)
        page.session.set("api_token", bootstrap_token)

        start_ui(page)

    try:
        print("[Launcher] Otwieranie interfejsu użytkownika...")
        ft.app(target=ui_wrapper)
    finally:
        # 6. Krytyczne sprzątanie (Graceful Shutdown)
        print("[Launcher] Zamykanie aplikacji. Ubijanie procesów w tle...")
        backend_proc.terminate()
        try:
            backend_proc.wait(timeout=3.0)
        except subprocess.TimeoutExpired:
            backend_proc.kill()
        print("[Launcher] Zakończono pomyślnie.")

if __name__ == "__main__":
    launch_app()


import os
import sys
import asyncio
import subprocess
import logging
import flet as ft
from pathlib import Path

# Importy wewnętrzne
from core.config import AppConfig
from scripts.setup_env import bootstrap_system
from scripts.doctor import run_diagnostics

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[logging.StreamHandler(), logging.FileHandler("nexus_main.log")]
)
logger = logging.getLogger("nexus.main")

class NexusOrchestrator:
    def __init__(self):
        self.config = AppConfig()
        self.worker_process = None
        self.nats_process = None

    async def start_nats(self):
        """Uruchamia lokalny serwer NATS."""
        nats_path = self.config.base_dir / ("nats-server.exe" if os.name == "nt" else "nats-server")
        if nats_path.exists():
            logger.info("Uruchamianie serwera NATS...")
            self.nats_process = subprocess.Popen(
                [str(nats_path), "-p", "4222", "-js"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            await asyncio.sleep(2)
        else:
            logger.error("Nie znaleziono binarki NATS!")

    async def start_backend_api(self):
        """Uruchamia serwer API (Litestar) w pętli zdarzeń."""
        from api.app import app
        import uvicorn
        config = uvicorn.Config(app, host="127.0.0.1", port=8000, log_level="info")
        server = uvicorn.Server(config)
        logger.info("Inicjalizacja Backend API na http://127.0.0.1:8000")
        return asyncio.create_task(server.serve())

    async def start_worker(self):
        """Uruchamia proces roboczy Taskiq (OCR/AI)."""
        logger.info("Uruchamianie Workera AI...")
        cmd = [sys.executable, "-m", "taskiq", "worker", "worker:broker", "--fs-startup"]
        self.worker_process = subprocess.Popen(cmd)

    def cleanup(self):
        logger.info("Zamykanie komponentów Nexus AI...")
        if self.worker_process: self.worker_process.terminate()
        if self.nats_process: self.nats_process.terminate()

async def main_ui(page: ft.Page):
    from ui.app import NexusUI
    page.title = "Nexus AI - Zarządzanie Fakturami"
    page.theme_mode = ft.ThemeMode.DARK
    ui = NexusUI(page)
    await ui.build()

async def start_app():
    orchestrator = NexusOrchestrator()
    print(">>> Nexus AI: Sprawdzanie integralności systemu...")
    await bootstrap_system()
    run_diagnostics()

    await orchestrator.start_nats()
    await orchestrator.start_worker()
    api_task = await orchestrator.start_backend_api()

    try:
        await ft.app_async(target=main_ui)
    except Exception as e:
        logger.error(f"Błąd krytyczny UI: {e}")
    finally:
        orchestrator.cleanup()
        api_task.cancel()

if __name__ == "__main__":
    if os.name == "nt":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    try:
        asyncio.run(start_app())
    except KeyboardInterrupt:
        pass


import os
import sys
import asyncio
import subprocess
import socket
import logging
import time
from pathlib import Path
from datetime import datetime
import flet as ft

# Importy pomocnicze
from core.config import AppConfig
from scripts.setup_env import bootstrap_system

# --- ZAAWANSOWANE LOGOWANIE ---
log_dir = Path("logs")
log_dir.mkdir(exist_ok=True)
log_file = log_dir / f"nexus_{datetime.now().strftime('%Y%m%d')}.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[logging.StreamHandler(), logging.FileHandler(log_file, encoding="utf-8")]
)
logger = logging.getLogger("nexus.main")

# --- MECHANIZM: SINGLE INSTANCE LOCK ---
def is_already_running(port=47999):
    """Zapobiega uruchomieniu wielu instancji aplikacji."""
    try:
        lock_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        lock_socket.bind(("127.0.0.1", port))
        globals()["_lock_socket"] = lock_socket
        return False
    except socket.error:
        return True

# --- ORKIESTRATOR PROCESÓW (WATCHDOG) ---
class NexusProcessManager:
    def __init__(self, config: AppConfig):
        self.config = config
        self.nats_proc = None
        self.worker_proc = None
        self._running = True

    async def start_services(self):
        # 1. NATS Server
        nats_bin = "nats-server.exe" if os.name == "nt" else "nats-server"
        nats_path = self.config.base_dir / nats_bin
        if nats_path.exists():
            self.nats_proc = subprocess.Popen(
                [str(nats_path), "-p", "4222", "-js"],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )

        # 2. Worker AI
        logger.info("Uruchamianie Workera AI...")
        cmd = [sys.executable, "-m", "taskiq", "worker", "worker:broker", "--fs-startup"]
        self.worker_proc = subprocess.Popen(cmd)

    async def watchdog(self):
        """Monitoruje zdrowie procesów i restartuje je w razie awarii."""
        while self._running:
            if self.worker_proc and self.worker_proc.poll() is not None:
                logger.warning("Worker przestał odpowiadać. Restartowanie...")
                await self.start_services()
            await asyncio.sleep(15)

    def stop_all(self):
        self._running = False
        if self.worker_proc: self.worker_proc.terminate()
        if self.nats_proc: self.nats_proc.terminate()
        logger.info("Infrastruktura: Bezpiecznie zatrzymana.")

# --- UI SPLASH SCREEN & MAIN ---
async def start_nexus_app(page: ft.Page):
    manager = NexusProcessManager(AppConfig())

    # Konfiguracja okna Splash Screen
    page.title = "Nexus AI"
    page.window_width, page.window_height = 450, 600
    page.window_center()
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
                status_text,
                pb
            ], horizontal_alignment=ft.CrossAxisAlignment.CENTER),
            expand=True, alignment=ft.alignment.center
        )
    )

    # KROKI STARTOWE
    try:
        # 1. Bootstrap
        status_text.value = "Krok 1/4: Inicjalizacja bazy danych..."
        page.update()
        await bootstrap_system()

        # 2. Start Usług
        status_text.value = "Krok 2/4: Uruchamianie silników AI..."
        page.update()
        await manager.start_services()

        # 3. Start API
        status_text.value = "Krok 3/4: Konfiguracja API..."
        page.update()
        from api.app import app
        import uvicorn
        api_config = uvicorn.Config(app, host="127.0.0.1", port=8000, log_level="error")
        api_server = uvicorn.Server(api_config)
        asyncio.create_task(api_server.serve())
        asyncio.create_task(manager.watchdog())

        # 4. Finalizacja
        status_text.value = "Krok 4/4: Synchronizacja interfejsu..."
        page.update()
        await asyncio.sleep(1.5)

        # Przejście do głównej aplikacji
        page.clean()
        page.window_always_on_top = False
        page.window_resizable = True
        page.window_width, page.window_height = 1280, 800
        page.update()

        from ui.root import NexusRootUI
        app_ui = NexusRootUI(page, manager)
        await app_ui.build()

    except Exception as e:
        logger.critical(f"BŁĄD STARTU: {e}")
        page.add(ft.Text(f"Błąd krytyczny: {e}", color="red"))
        page.update()

async def main():
    if is_already_running():
        print("Nexus AI już działa.")
        sys.exit(0)

    try:
        await ft.app_async(target=start_nexus_app, assets_dir="assets")
    except KeyboardInterrupt:
        logger.info("Przerwanie przez użytkownika.")
    finally:
        logger.info("Zwalnianie zasobów przed zamknięciem...")

if __name__ == "__main__":
    if os.name == "nt":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(main())





import os
import sys
import asyncio
import subprocess
import socket
import logging
import signal
import time
import secrets
from pathlib import Path
from datetime import datetime
import flet as ft

# --- 1. KONFIGURACJA ŚRODOWISKA OFFLINE AI (KRYTYCZNE: Przed importem modeli) ---
if getattr(sys, 'frozen', False):
    # Jeśli aplikacja jest skompilowana jako .exe (PyInstaller)
    base_path = Path(sys._MEIPASS)
else:
    # Jeśli uruchamiamy z kodu źródłowego
    base_path = Path(__file__).parent [cite: 52]

models_cache_dir = base_path / "models"
os.environ["HF_HOME"] = str(models_cache_dir)
os.environ["TRANSFORMERS_OFFLINE"] = "1"  # Twarde wymuszenie trybu offline [cite: 54, 55]

# --- 2. KONFIGURACJA LOGOWANIA ---
log_dir = Path("logs")
log_dir.mkdir(exist_ok=True)
log_file = log_dir / f"nexus_{datetime.now().strftime('%Y%m%d')}.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(log_file, encoding="utf-8")
    ]
)
logger = logging.getLogger("nexus.main") [cite: 228-233, 33]

# --- 3. IMPORTY WEWNĘTRZNE (Po konfiguracji środowiska) ---
from core.config import AppConfig
from scripts.setup_env import bootstrap_system
from scripts.doctor import run_diagnostics

# --- 4. FUNKCJE POMOCNICZE I BLOKADA INSTANCJI ---
def get_free_port() -> int:
    """Dynamicznie znajduje wolny port na localhost."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('', 0))
        return s.getsockname()[1] [cite: 71, 72, 155]

def is_already_running(port=47999):
    """Zapobiega uruchomieniu wielu instancji aplikacji (Single Instance Lock)."""
    try:
        lock_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        lock_socket.bind(("127.0.0.1", port))
        globals()["_lock_socket"] = lock_socket
        return False
    except socket.error:
        return True [cite: 28, 29]

# --- 5. ORKIESTRATOR PROCESÓW (WATCHDOG) ---
class NexusOrchestrator:
    """Zarządza NATS, Workerem i API, gwarantując ich restart i poprawne zamknięcie."""
    def __init__(self):
        self.config = AppConfig()
        self.nats_process = None
        self.worker_process = None
        self.api_task = None
        self.bootstrap_token = secrets.token_urlsafe(32) [cite: 93, 235]

    async def start_nats(self):
        """Uruchamia lokalny serwer NATS z obsługą JetStream."""
        nats_bin = "nats-server.exe" if os.name == "nt" else "nats-server"
        nats_path = self.config.base_dir / nats_bin

        if nats_path.exists():
            logger.info("Uruchamianie infrastruktury NATS JetStream...")
            self.nats_process = subprocess.Popen(
                [str(nats_path), "-p", "4222", "-js"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            await asyncio.sleep(2)
        else:
            logger.error("Nie znaleziono binarki NATS w folderze głównym!") [cite: 241-255, 34]

    async def start_worker(self):
        """Uruchamia proces roboczy Taskiq (OCR/AI)."""
        logger.info("Uruchamianie silnika AI (Worker)...")
        cmd = [sys.executable, "-m", "taskiq", "worker", "worker:broker", "--fs-startup"]
        self.worker_process = subprocess.Popen(cmd) [cite: 261-266]

    async def start_backend_api(self, port: int):
        """Uruchamia serwer API (Litestar) w pętli zdarzeń."""
        from api.app import app
        import uvicorn

        backend_env = os.environ.copy()
        backend_env["NEXUS_PORT"] = str(port)
        backend_env["NEXUS_TOKEN"] = self.bootstrap_token
        backend_env["PYTHONPATH"] = str(Path.cwd())

        config = uvicorn.Config(app, host="127.0.0.1", port=port, log_level="error")
        server = uvicorn.Server(config)
        logger.info(f"Inicjalizacja API na http://127.0.0.1:{port}")
        self.api_task = asyncio.create_task(server.serve()) [cite: 168-178, 256-260]

    def cleanup(self):
        """Krytyczne sprzątanie procesów przy wyjściu z aplikacji."""
        logger.info("Zamykanie komponentów Nexus AI...")
        if self.worker_process:
            self.worker_process.terminate()
        if self.nats_process:
            self.nats_process.terminate()
        if self.api_task:
            self.api_task.cancel()
        logger.info("System zamknięty pomyślnie.") [cite: 195-198, 267-269, 34]

# --- 6. LOGIKA INTERFEJSU (Flet) ---
async def main_ui(page: ft.Page, orchestrator: NexusOrchestrator, port: int):
    """Główny punkt wejścia dla interfejsu graficznego ze Splash Screenem."""
    page.title = "Nexus AI - System Księgowy"
    page.window_width = 450
    page.window_height = 600
    page.window_resizable = False
    page.theme_mode = ft.ThemeMode.DARK
    page.window_always_on_top = True

    # Splash Screen
    status_text = ft.Text("Przygotowywanie systemów...", size=14, italic=True)
    pb = ft.ProgressBar(width=350, color="blue", bgcolor="#1e1e1e")

    page.add(
        ft.Container(
            content=ft.Column([
                ft.Image(src="assets/logo_splash.png", width=150),
                ft.Divider(height=40, color="transparent"),
                status_text,
                pb
            ], horizontal_alignment=ft.CrossAxisAlignment.CENTER),
            expand=True, alignment=ft.alignment.center
        )
    )
    page.update()

    # Krok 1: Integralność i Bazy
    status_text.value = "Krok 1/4: Sprawdzanie bazy danych..."
    page.update()
    await bootstrap_system()
    run_diagnostics()

    # Krok 2: Infrastruktura (NATS)
    status_text.value = "Krok 2/4: Uruchamianie magistrali danych..."
    page.update()
    await orchestrator.start_nats()

    # Krok 3: Silniki AI i API
    status_text.value = "Krok 3/4: Budzenie silników AI..."
    page.update()
    await orchestrator.start_worker()
    await orchestrator.start_backend_api(port)

    # Krok 4: Finalizacja i przejście do głównego UI
    status_text.value = "Krok 4/4: Synchronizacja interfejsu..."
    page.update()
    await asyncio.sleep(1.5)

    # Przełączenie na właściwy interfejs
    page.clean()
    page.window_always_on_top = False
    page.window_resizable = True
    page.window_width = 1280
    page.window_height = 850

    # Przekazanie poświadczeń do sesji UI
    page.session.set("api_port", port)
    page.session.set("api_token", orchestrator.bootstrap_token)

    from ui.root import NexusRootUI
    app_ui = NexusRootUI(page, orchestrator)
    await app_ui.build()
    page.update() [cite: 31, 35, 36, 186-190, 274-279]

# --- 7. GŁÓWNY START SYSTEMU ---
async def start_app():
    if is_already_running():
        print("Nexus AI już działa.")
        sys.exit(1)

    orchestrator = NexusOrchestrator()
    backend_port = get_free_port()

    try:
        # Flet działa we własnej pętli zdarzeń
        await ft.app_async(
            target=lambda page: main_ui(page, orchestrator, backend_port)
        )
    except Exception as e:
        logger.critical(f"BŁĄD KRYTYCZNY STARTU: {e}")
    finally:
        orchestrator.cleanup() [cite: 281-294, 32, 33]

if __name__ == "__main__":
    if os.name == "nt":
        # Wymagane dla poprawnego działania asyncio i procesów na Windows
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy()) [cite: 298]

    try:
        asyncio.run(start_app())
    except KeyboardInterrupt:
        pass [cite: 299-301]
