# worker.py
import os
import sys
import asyncio
import logging
import signal
import psutil
import gc
import torch
import platform
import shutil
from pathlib import Path
from datetime import datetime, timezone
from taskiq import TaskiqEvents

# --- 1. KONFIGURACJA ŚRODOWISKA AI (Krytyczne dla trybu Offline) ---
# Ustawiamy ścieżkę do wbudowanego folderu z modelami, aby uniknąć pobierania z sieci.
if getattr(sys, 'frozen', False):
    # Jeśli aplikacja jest skompilowana jako .exe (PyInstaller)
    base_path = Path(sys._MEIPASS)
else:
    # Jeśli uruchamiamy z kodu źródłowego
    base_path = Path(__file__).parent [cite: 7, 8, 11, 192-196]

# Wymuszenie ścieżek dla wag modeli (Surya OCR / Transformers)
models_cache_dir = base_path / "models"
os.environ["HF_HOME"] = str(models_cache_dir)
os.environ["TRANSFORMERS_OFFLINE"] = "1"
os.environ["TORCH_HOME"] = str(models_cache_dir / "torch") [cite: 13, 14, 198-200]

# Optymalizacja CPU/RAM (Max Performance)
os.environ["OMP_NUM_THREADS"] = "4"
os.environ["OPENBLAS_NUM_THREADS"] = "4"
os.environ["MKL_NUM_THREADS"] = "4" [cite: 70-72, 201-203]

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
logger = logging.getLogger("nexus.worker") [cite: 55-60, 205-213]

# --- 3. IMPORTY RDZENIA APLIKACJI ---
# Eksponujemy obiekt 'broker', aby CLI taskiq mogło go użyć.
from core.broker import broker
# KRYTYCZNE: Importujemy tasks, aby Taskiq zarejestrował funkcje z @broker.task.
import core.tasks
from core.config import AppConfig [cite: 74, 75, 215-217]

# --- 4. ZAAWANSOWANY MONITOR I WATCHDOG (Absolutny Max) ---
class WorkerGuard:
    """Zapewnia stabilność workera, zarządza pamięcią i raportuje status."""
    def __init__(self, ram_limit_gb: float = 6.0):
        self.process = psutil.Process(os.getpid())
        self.ram_limit = ram_limit_gb * 1024 * 1024 * 1024
        self.start_time = datetime.now(timezone.utc)

    def check_resources(self):
        """Wymusza czyszczenie pamięci przy wyciekach z modeli OCR."""
        current_mem = self.process.memory_info().rss
        if current_mem > self.ram_limit:
            logger.warning(f"Alert Pamięci: {current_mem/1024**2:.1f} MB. Uruchamianie GC...")
            if torch.cuda.is_available():
                torch.cuda.empty_cache()
            gc.collect()
            return True
        return False

    async def heartbeat(self):
        """Pętla raportująca, że proces roboczy żyje i nie 'zawisł' na modelu AI."""
        while True:
            uptime = datetime.now(timezone.utc) - self.start_time
            logger.debug(f"Heartbeat: Uptime {uptime}, RAM: {self.process.memory_info().rss/1024**2:.1f}MB")
            await asyncio.sleep(60) [cite: 218-236]

# --- 5. HOOKI TASKIQ (Zarządzanie Cyklem Życia) ---
@broker.on_event(TaskiqEvents.WORKER_STARTUP)
async def startup_event(state):
    """Przygotowanie zasobów przed przyjęciem pierwszego zadania."""
    logger.info(">>> Inicjalizacja silnika AI i monitoringu...")
    # Pre-load silnika OCR (Singleton), aby uniknąć opóźnienia przy pierwszej fakturze
    from pipeline.ocr import DocumentProcessor
    state.ocr_engine = DocumentProcessor()
    state.config = AppConfig()
    state.guard = WorkerGuard(ram_limit_gb=8.0)
    state.heartbeat_task = asyncio.create_task(state.guard.heartbeat())

    gpu_available = torch.cuda.is_available()
    logger.info(f">>> Worker gotowy. OS: {platform.system()}, Urządzenie: {'CUDA / GPU' if gpu_available else 'CPU Only'}") [cite: 136-143, 238-246]

@broker.on_event(TaskiqEvents.TASK_POST_EXECUTION)
async def post_task(state, task_result):
    """Zwolnienie zasobów natychmiast po przetworzeniu faktury."""
    state.guard.check_resources()
    logger.debug(f"Zakończono zadanie {task_result.task_id}. Pamięć sprawdzona.") [cite: 144-148, 247, 248]

@broker.on_event(TaskiqEvents.WORKER_SHUTDOWN)
async def shutdown_event(state):
    """Kulturalne zamknięcie połączeń i zwolnienie GPU."""
    logger.info(">>> Zamykanie workera. Czyszczenie pamięci...")
    if hasattr(state, 'heartbeat_task'):
        state.heartbeat_task.cancel()
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
    gc.collect() [cite: 249-255]

# --- 6. OBSŁUGA SYGNAŁÓW I PORZĄDKÓW ---
shutdown_event = asyncio.Event()

def handle_shutdown(sig, frame):
    """Przechwytuje sygnały zamknięcia (Ctrl+C), aby bezpiecznie zakończyć przetwarzanie."""
    logger.info(f"Otrzymano sygnał przerwania ({sig}). Trwa bezpieczne zamykanie workera...")
    shutdown_event.set() [cite: 78-81, 257-259]

def cleanup_temp_artifacts():
    """Usuwa pozostałości po renderowaniu stron PDF do obrazów."""
    temp_dir = Path(os.environ.get("TEMP", "/tmp")) / "nexus_ocr"
    if temp_dir.exists():
        shutil.rmtree(temp_dir)
        logger.info("Wyczyszczono pliki tymczasowe OCR.") [cite: 157-162, 175]

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
        except Exception as e:
            delivery_count = msg.metadata.num_delivered
            if delivery_count >= 5:
                logger.critical(f"Plik uszkodził workera 5 razy. Przenoszenie do DLQ: {msg.data}")
                # Tutaj następuje zapisanie błędu do DB
                # await mark_as_dead_letter(msg.data, str(e))
                await msg.term()
            else:
                await msg.nak() [cite: 294-310]

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
        await shutdown_event.wait()
    except Exception as e:
        logger.error(f"Błąd krytyczny połączenia: {e}")
    finally:
        logger.info("Odłączanie od brokera i czyszczenie pamięci...")
        await broker.shutdown()
        logger.info("Worker zamknięty pomyślnie.") [cite: 82-109, 260-285, 310]

if __name__ == "__main__":
    # Rozwiązanie problemu z pętlą zdarzeń na Windows (Taskiq/NATS)
    if platform.system() == "Windows":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

    cleanup_temp_artifacts()
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass [cite: 112-115, 175-178, 286-292]
