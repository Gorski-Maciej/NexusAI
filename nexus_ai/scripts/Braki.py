# worker.py
import asyncio
import gc
from structlog import get_logger
import logging
import os
import platform
import shutil
import signal
import sys
import pendulum
from pathlib import Path

import nats
import psutil
from taskiq import TaskiqEvents

from nexus_ai.core.broker import broker
from nexus_ai.core.config import AppConfig

# --- 1. KONFIGURACJA ŚRODOWISKA AI (Krytyczne dla trybu Offline) ---
# Ustawiamy ścieżkę do wbudowanego folderu z modelami, aby uniknąć pobierania z sieci.
if getattr(sys, 'frozen', False):
    # Jeśli aplikacja jest skompilowana jako .exe (PyInstaller)
    base_path = Path(sys._MEIPASS)
else:
    # Jeśli uruchamiamy z kodu źródłowego
    base_path = Path(__file__).parent

# Ścieżka do modeli (GGUF)
models_cache_dir = base_path / "models"
os.environ["HF_HOME"] = str(models_cache_dir)

# Optymalizacja CPU/RAM (Max Performance)
os.environ["OMP_NUM_THREADS"] = "4"
os.environ["OPENBLAS_NUM_THREADS"] = "4"
os.environ["MKL_NUM_THREADS"] = "4"

# --- 2. KONFIGURACJA LOGOWANIA ---
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s (PID:%(process)d): %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("worker_error.log", encoding="utf-8")
    ]
)
logger = get_logger("nexus.worker")

# --- 3. IMPORTY RDZENIA APLIKACJI ---
# Eksponujemy obiekt 'broker', aby CLI taskiq mogło go użyć.
# KRYTYCZNE: Importujemy tasks, aby Taskiq zarejestrował funkcje z @broker.task.



# --- 4. ZAAWANSOWANY MONITOR I WATCHDOG (Absolutny Max) ---
class WorkerGuard:
    """Zapewnia stabilność workera, zarządza pamięcią i raportuje status."""
    def __init__(self, ram_limit_gb: float = 6.0):
        self.process = psutil.Process(os.getpid())
        self.ram_limit = ram_limit_gb * 1024 * 1024 * 1024
        self.start_time = pendulum.now("UTC")

    def check_resources(self):
        """Wymusza czyszczenie pamięci przy wyciekach z modeli OCR."""
        current_mem = self.process.memory_info().rss
        if current_mem > self.ram_limit:
            logger.warning(f"Alert Pamięci: {current_mem/1024**2:.1f} MB. Uruchamianie GC...")
            gc.collect()
            return True
        return False

    async def heartbeat(self):
        """Pętla raportująca, że proces roboczy żyje i nie 'zawisł' na modelu AI."""
        while True:
            uptime = pendulum.now("UTC") - self.start_time
            logger.debug(f"Heartbeat: Uptime {uptime}, RAM: {self.process.memory_info().rss/1024**2:.1f}MB")
            await asyncio.sleep(60)

# --- 5. HOOKI TASKIQ (Zarządzanie Cyklem Życia) ---
@broker.on_event(TaskiqEvents.WORKER_STARTUP)
async def startup_event(state):
    """Przygotowanie zasobów przed przyjęciem pierwszego zadania."""
    logger.info(">>> Inicjalizacja silnika AI i monitoringu...")
    # OCR engine: pipeline/ocr.py usunięty (surya/paddle/torch → LightOnOCR-1B VLM)
    state.ocr_engine = None
    state.config = AppConfig()
    state.guard = WorkerGuard(ram_limit_gb=8.0)
    state.heartbeat_task = asyncio.create_task(state.guard.heartbeat())

    logger.info(f">>> Worker gotowy. OS: {platform.system()}")

@broker.on_event(TaskiqEvents.TASK_POST_EXECUTION)
async def post_task(state, task_result):
    """Zwolnienie zasobów natychmiast po przetworzeniu faktury."""
    state.guard.check_resources()
    logger.debug(f"Zakończono zadanie {task_result.task_id}. Pamięć sprawdzona.")

@broker.on_event(TaskiqEvents.WORKER_SHUTDOWN)
async def shutdown_event(state):
    """Kulturalne zamknięcie połączeń i zwolnienie GPU."""
    logger.info(">>> Zamykanie workera. Czyszczenie pamięci...")
    if hasattr(state, 'heartbeat_task'):
        state.heartbeat_task.cancel()
    gc.collect()

# --- 6. OBSŁUGA SYGNAŁÓW I PORZĄDKÓW ---
shutdown_flag = asyncio.Event()

def handle_shutdown(sig, frame):
    """Przechwytuje sygnały zamknięcia (Ctrl+C), aby bezpiecznie zakończyć przetwarzanie."""
    logger.info(f"Otrzymano sygnał przerwania ({sig}). Trwa bezpieczne zamykanie workera...")
    shutdown_flag.set()

def cleanup_temp_artifacts():
    """Usuwa pozostałości po renderowaniu stron PDF do obrazów."""
    temp_dir = Path(os.environ.get("TEMP", "/tmp")) / "nexus_ocr"
    if temp_dir.exists():
        shutil.rmtree(temp_dir)
        logger.info("Wyczyszczono pliki tymczasowe OCR.")

# --- 7. LOGIKA KOLEJEK I PRZETWARZANIA (NATS JetStream) ---
async def process_messages(nats_client):
    """Konfiguracja konsumenta JetStream z limitem powtórzeń."""
    js = await nats_client.jetstream()
    sub = await js.subscribe(
        "invoices.new",
        durable="invoice_worker",
        manual_ack=True,
        config=nats.js.api.ConsumerConfig(
            max_deliver=5, # Po 5 nieudanych próbach NATS przestanie wysyłać to zadanie
            ack_wait=60    # Czekaj 60s na potwierdzenie
        )
    )

    async for msg in sub.messages:
        try:
            # Logika przetwarzania faktury (funkcja handle_invoice musi być zdefiniowana w systemie)
            # await handle_invoice(msg.data)
            await msg.ack()
        except Exception:
            delivery_count = msg.metadata.num_delivered
            if delivery_count >= 5:
                logger.critical(f"Plik uszkodził workera 5 razy. Przenoszenie do DLQ: {msg.data}")
                # Tutaj następuje zapisanie błędu do DB
                # await mark_as_dead_letter(msg.data, str(e))
                await msg.term()
            else:
                await msg.nak()

# --- 8. GŁÓWNY PUNKT WEJŚCIA ---
async def main():
    """Funkcja do ręcznego uruchamiania i testowania łączności."""
    # Konfiguracja priorytetów procesu
    try:
        p = psutil.Process(os.getpid())
        if platform.system() == "Windows":
            p.nice(psutil.HIGH_PRIORITY_CLASS)
        else:
            p.nice(-10) # Wyższy priorytet na Linux
    except Exception:
        pass

    # Rejestracja sygnałów (Unix/Mac)
    if platform.system() != "Windows":
        for s in (signal.SIGINT, signal.SIGTERM):
            try:
                signal.signal(s, handle_shutdown)
            except Exception:
                pass

    logger.info("Nawiązywanie połączenia z brokerem NATS (localhost:4222)...")
    try:
        await broker.startup()
        logger.info("Worker jest aktywny. Nasłuchiwanie na zadania w kolejce NATS...")

        # Uruchomienie przekaźnika Outbox jeśli wymagane
        # relay_task = asyncio.create_task(run_outbox_relay(SessionLocal, nats_client))

        # Czekamy na sygnał zamknięcia
        await shutdown_flag.wait()
    except Exception as e:
        logger.error(f"Błąd krytyczny połączenia: {e}")
    finally:
        logger.info("Odłączanie od brokera i czyszczenie pamięci...")
        await broker.shutdown()
        logger.info("Worker zamknięty pomyślnie.")

if __name__ == "__main__":
    # Rozwiązanie problemu z pętlą zdarzeń na Windows (Taskiq/NATS)
    if platform.system() == "Windows":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

    cleanup_temp_artifacts()
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
