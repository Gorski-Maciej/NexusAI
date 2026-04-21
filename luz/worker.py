Worker.py
import os
import sys
from pathlib import Path

# --- KONFIGURACJA OFFLINE AI ---
# Ustawiamy ścieżkę do naszego wbudowanego folderu z modelami.
# Dzięki temu Surya i SentenceTransformers nie będą szukać w internecie.
if getattr(sys, 'frozen', False):
# Jeśli aplikacja jest skompilowana jako .exe (PyInstaller)
base_path = Path(sys._MEIPASS)
else:
# Jeśli uruchamiamy z kodu źródłowego
base_path = Path(__file__).parent
models_cache_dir = base_path / "models"
os.environ["HF_HOME"] = str(models_cache_dir)
os.environ["TRANSFORMERS_OFFLINE"] = "1"  # Twarde wymuszenie trybu offline
# -------------------------------
# Dopiero tutaj reszta Twoich importów
# import flet as ft
# import subprocess
# …
# worker.py
from Code.core import broker


async def main():
    """Opcjonalny skrypt do ręcznego testowania połączenia."""


await broker.startup()
print("Worker Taskiq jest aktywny i nasłuchuje na NATS...")
# W rzeczywistości worker jest uruchamiany przez CLI: taskiq worker worker:broker
# worker.py
import asyncio
from Code.core import broker


# Krytyczne: Importujemy tasks, aby Taskiq "widział" funkcje oznaczone jako @broker.task
async def main():
    """
    Opcjonalna funkcja pomocnicza.
    Pozwala sprawdzić połączenie z brokerem przed startem właściwego workera.
    """


print("[Worker] Sprawdzanie połączenia z NATS...")
try:
    await broker.startup()
print("[Worker] Połączenie z brokerem NATS nawiązane pomyślnie.")
await broker.shutdown()
except Exception as e:
print(f"[Worker] Błąd krytyczny połączenia: {e}")
if __name__ == "__main__":
# Możemy uruchomić ten plik bezpośrednio, aby przetestować łączność
asyncio.run(main())
# worker.py
import os
import sys
import asyncio
import logging
import signal
from pathlib import Path

# --- 1. KONFIGURACJA LOGOWANIA (Krytyczne dla debugowania w tle) ---
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)
logger = logging.getLogger("nexus.worker")
# --- 2. KONFIGURACJA OFFLINE AI & ZASOBÓW (Musi być przed importami AI) ---
if getattr(sys, 'frozen', False):
# Tryb skompilowanego pliku .exe (PyInstaller)
base_path = Path(sys._MEIPASS)
else:
# Tryb deweloperski
base_path = Path(__file__).parent
models_cache_dir = base_path / "models"
os.environ["HF_HOME"] = str(models_cache_dir)
os.environ["TRANSFORMERS_OFFLINE"] = "1"
# Optymalizacja wykorzystania procesora (CPU) dla modeli AI, aby nie zawiesić komputera
os.environ["OMP_NUM_THREADS"] = "4"
os.environ["OPENBLAS_NUM_THREADS"] = "4"
os.environ["MKL_NUM_THREADS"] = "4"
# --- 3. IMPORTY APLIKACJI (Rejestracja w Taskiq) ---
# Eksponujemy obiekt `broker`, aby CLI (taskiq worker worker:broker) mogło go użyć
from Code.core import broker

# KRYTYCZNE: Bez tego importu Taskiq nie dowie się o istnieniu funkcji z @broker.task
# --- 4. OBSŁUGA ZAMYKANIA (GRACEFUL SHUTDOWN) ---
shutdown_event = asyncio.Event()


def handle_shutdown(sig, frame):
    """Przechwytuje sygnały zamknięcia (Ctrl+C), aby bezpiecznie zakończyć przetwarzanie
    faktur."""


logger.info(f"Otrzymano sygnał przerwania ({sig}). Trwa bezpieczne zamykanie
workera...
")
shutdown_event.set()
# --- 5. GŁÓWNA PĘTLA (Do testów i samodzielnego uruchamiania) ---
async

def main():
    """
    Funkcja używana WYŁĄCZNIE, gdy uruchamiasz skrypt bezpośrednio: `python
    worker.py`.
    W produkcji (przez main.py) worker jest uruchamiany komendą: `taskiq worker
    worker:broker`
    Zostawiamy to tutaj dla celów testowych i weryfikacji łączności.
    """


logger.info("Inicjalizacja środowiska Workera Nexus AI...")
# Rejestracja sygnałów dla bezpiecznego wyłączania (Unix/Mac/Cygwin)
for sig in (signal.SIGINT, signal.SIGTERM):
    try:
        signal.signal(sig, handle_shutdown)
except NotImplementedError:
pass  # Ignorowane na natywnym systemie Windows
try:
    logger.info("Nawiązywanie połączenia z brokerem NATS (localhost:4222)...")
await broker.startup()
logger.info("✅ Worker jest aktywny. Nasłuchiwanie na zadania w kolejce NATS...")
# Czekamy w nieskończoność na sygnał zamknięcia
await shutdown_event.wait()
except ConnectionError:
logger.error("❌ Błąd krytyczny: Nie można połączyć się z serwerem NATS. Upewnij
się, że
nats - server.exe
działa.
")
except Exception as e:
logger.error(f"❌ Wystąpił nieoczekiwany błąd Workera: {e}")
finally:
logger.info("Odłączanie od brokera i czyszczenie pamięci...")
await broker.shutdown()
logger.info("Worker zamknięty pomyślnie.")
if __name__ == "__main__":
# Obejście dla systemu Windows, zapobiegające błędom "Event loop is closed"
if os.name == "nt":
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
asyncio.run(main())
# worker.py (Rozszerzenie o brakujące moduły "Max")
import psutil
import gc


# --- 1. ZAAWANSOWANY MONITOR ZASOBÓW ---
class ResourceMonitor:
    """Monitoruje zużycie RAM przez modele OCR/AI i wymusza czyszczenie."""


def __init__(self, threshold_mb: int = 4000):
    self.threshold = threshold_mb


self.process = psutil.Process(os.getpid())


def check_and_cleanup(self):
    mem_info = self.process.memory_info()


current_mem = mem_info.rss / (1024 * 1024)
if current_mem > self.threshold:
    logger.warning(f"Zużycie pamięci ({current_mem:.2f} MB) przekroczyło próg.
Czyszczenie...
")
gc.collect()
# W skrajnych przypadkach można tu zaimplementować przeładowanie modelu
return True
return False


# --- 2. HOOKI ZDARZEŃ TASKIQ (Lifecycle Hooks) ---
@broker.on_event(TaskiqEvents.WORKER_STARTUP)
async def startup_event(state):
    """Wywoływane przy starcie każdego procesu roboczego."""


logger.info("Inicjalizacja struktur danych Workera...")
state.config = AppConfig()
state.monitor = ResourceMonitor(threshold_mb=6000)  # Próg 6GB dla ciężkich modeli
# Sprawdzenie dostępności GPU
import torch

gpu_available = torch.cuda.is_available()
logger.info(f"Środowisko AI: {'CUDA / GPU' if gpu_available else 'CPU Only'}")


@broker.on_event(TaskiqEvents.TASK_POST_EXECUTION)
async def post_execution_event(state, task_result):
    """Automatyczne czyszczenie po każdej przetworzonej fakturze."""


state.monitor.check_and_cleanup()
logger.debug(f"Zakończono zadanie {task_result.task_id}. Pamięć oczyszczona.")


# --- 3. DYNAMICZNA OBSŁUGA BŁĘDÓW I RETRY ---
def configure_worker_retry():
    """Konfiguruje domyślne zachowanie przy błędach OCR (np. uszkodzony PDF)."""


return {
    "max_retry": 3,
    "retry_backoff": True,
    "retry_delay": 5.0
}


# --- 4. INTEGRACJA Z SYSTEMEM PLIKÓW TYMCZASOWYCH ---
def cleanup_temp_artifacts():
    """Usuwa pozostałości po renderowaniu stron PDF do obrazów."""


temp_dir = Path(os.environ.get("TEMP", "/tmp")) / "nexus_ocr"
if temp_dir.exists():
    import shutil

shutil.rmtree(temp_dir)
logger.info("Wyczyszczono pliki tymczasowe OCR.")


# --- 5. LOGIKA URUCHOMIENIA Z PRIORYTETEM ---
async def start_dedicated_worker(queue_name: str = "high_priority"):
    """
    Pozwala na uruchomienie workera dedykowanego tylko do szybkich zadań
    (np. weryfikacja NIP) zamiast ciężkiego OCR.
    """


logger.info(f"Uruchamianie dedykowanego workera dla kolejki: {queue_name}")
# Tu logika specyficzna dla selektywnego pobierania zadań z NATS
await broker.startup()
# --- FINALNA SEKCJA REJESTRACJI ---
if __name__ == "__main__":
# Kod z poprzedniego kroku (main) pozostaje bez zmian,
# ale wywołuje powyższe funkcje pomocnicze.
# Dodatkowe zabezpieczenie: czyszczenie przy starcie
cleanup_temp_artifacts()
if os.name == "nt":
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
asyncio.run(main())
# worker.py
import os
import sys
import logging
import psutil
import gc
import torch
from pathlib import Path
from datetime import datetime, timezone

# --- 1. KONFIGURACJA ŚRODOWISKA AI (Krytyczne dla trybu Offline) ---
if getattr(sys, 'frozen', False):
    base_path = Path(sys._MEIPASS)
else:
    base_path = Path(__file__).parent
# Wymuszenie ścieżek dla wag modeli (Surya OCR / Transformers)
os.environ["HF_HOME"] = str(base_path / "models")
os.environ["TRANSFORMERS_OFFLINE"] = "1"
os.environ["TORCH_HOME"] = str(base_path / "models" / "torch")
# Optymalizacja CPU/RAM (Max Performance)
os.environ["OMP_NUM_THREADS"] = "4"
os.environ["MKL_NUM_THREADS"] = "4"
# --- 2. LOGOWANIE SYSTEMOWE ---
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s (PID:%(process)d): %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("worker_error.log", encoding="utf-8")
    ]
)
logger = logging.getLogger("nexus.worker")


# --- 3. IMPORTY RDZENIA APLIKACJI ---
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
    logger.warning(f"Alert Pamięci: {current_mem / 1024 ** 2:.1f} MB. Uruchamianie GC...")
if torch.cuda.is_available():
    torch.cuda.empty_cache()
gc.collect()
return True
return False


async def heartbeat(self):
    """Pętla raportująca, że proces roboczy żyje i nie 'zawisł' na modelu AI."""


while True:
    uptime = datetime.now(timezone.utc) - self.start_time
logger.debug(f"Heartbeat: Uptime {uptime}, RAM:
{self.process.memory_info().rss / 1024 ** 2: .1f}
MB
")
await asyncio.sleep(60)
# --- 5. HOOKI TASKIQ (Zarządzanie Cyklem Życia) ---
@ broker.on_event(TaskiqEvents.WORKER_STARTUP)
async

def startup_event(state):
    """Przygotowanie zasobów przed przyjęciem pierwszego zadania."""


logger.info(">>> Inicjalizacja silnika AI i monitoringu...")
# Pre-load silnika OCR (Singleton), aby uniknąć opóźnienia przy pierwszej fakturze
from Code.pipeline import DocumentProcessor

state.ocr_engine = DocumentProcessor()
# Inicjalizacja monitoringu
state.guard = WorkerGuard(ram_limit_gb=8.0)
state.heartbeat_task = asyncio.create_task(state.guard.heartbeat())
logger.info(f">>> Worker gotowy. OS: {platform.system()}, Urządzenie: {'CUDA' if
torch.cuda.is_available() else 'CPU'}")


@broker.on_event(TaskiqEvents.TASK_POST_EXECUTION)
async def post_task(state, task_result):
    """Zwolnienie zasobów natychmiast po przetworzeniu faktury."""


state.guard.check_resources()


@broker.on_event(TaskiqEvents.WORKER_SHUTDOWN)
async def shutdown_event(state):
    """Kulturalne zamknięcie połączeń i zwolnienie GPU."""


logger.info(">>> Zamykanie workera. Czyszczenie pamięci...")
state.heartbeat_task.cancel()
if torch.cuda.is_available():
    torch.cuda.empty_cache()
gc.collect()
# --- 6. OBSŁUGA SYGNAŁÓW (Graceful Shutdown) ---
shutdown_event = asyncio.Event()


def signal_handler(sig, frame):
    logger.info(f"Przechwycono sygnał {sig}. Kończenie zadań...")


shutdown_event.set()


# --- 7. GŁÓWNY PUNKT WEJŚCIA (Obsługa Windows/Linux) ---
async def main():


# Konfiguracja priorytetów procesu
try:
    p = psutil.Process(os.getpid())
if platform.system() == "Windows":
    p.nice(psutil.HIGH_PRIORITY_CLASS)
else:
    p.nice(-10)  # Wyższy priorytet na Linux
except Exception:
pass
# Rejestracja sygnałów (tylko systemy Unix-like)
if platform.system() != "Windows":
    for s in (signal.SIGINT, signal.SIGTERM):
        signal.signal(s, signal_handler)
logger.info("Podłączanie do brokera NATS JetStream...")
try:
    await broker.startup()
logger.info("✅ Połączono. Oczekiwanie na faktury do OCR...")
# W trybie produkcyjnym taskiq działa we własnej pętli,
# ale zostawiamy mechanizm blokujący dla ręcznego uruchamiania
await shutdown_event.wait()
except Exception as e:
logger.error(f"❌ Błąd krytyczny połączenia: {e}")
finally:
await broker.shutdown()
logger.info("Worker wyłączony.")
if __name__ == "__main__":
# Rozwiązanie problemu z pętlą zdarzeń na Windows (Taskiq/NATS)
if platform.system() == "Windows":
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
try:
    asyncio.run(main())
except KeyboardInterrupt:
    pass


# worker.py (Konfiguracja konsumenta JetStream)
async def process_messages():
    js = await nats_client.jetstream()


# Konfiguracja subskrypcji z limitem powtórzeń
sub = await js.subscribe(
    "invoices.new",
    durable="invoice_worker",
    manual_ack=True,
    config=nats.js.api.ConsumerConfig(
        max_deliver=5,  # Po 5 nieudanych próbach NATS przestanie wysyłać to zadanie
        ack_wait=60  # Czekaj 60s na potwierdzenie
    )
)
try:
    async for msg in sub.messages:
        try:
# Logika przetwarzania faktury
await handle_invoice(msg.data)
await msg.ack()
except Exception as e:
# Sprawdzamy ile razy próbowano dostarczyć tę wiadomość
delivery_count = msg.metadata.num_delivered
if delivery_count >= 5:
    logger.critical(f"Plik uszkodził workera 5 razy. Przenoszenie do DLQ:
{msg.data}
")
# Przesyłamy metadane błędu do specjalnej tabeli w SQLite
await mark_as_dead_letter(msg.data, str(e))
await msg.term()  # Ostateczne zakończenie (nie próbuj więcej)
else:
await msg.nak()  # Spróbuj ponownie za chwilę
except Exception:
pass


# worker.py
async def main():


# ... inicjalizacja NATS i DB ...
# Uruchomienie przekaźnika jako niezależnej korutyny
relay_task = asyncio.create_task(run_outbox_relay(SessionLocal, nats_client))
# ... reszta logiki workera (subskrypcje JetStream) ...
await asyncio.gather(relay_task, …)
# worker.py
import json


async def process_invoice_task(nc, invoice_id, file_path):


# Temat wiadomości: invoices.status.123
status_subject = f"invoices.status.{invoice_id}"


async def emit_status(status, message=""):
    payload = json.dumps({"status": status, "message": message})


await nc.publish(status_subject, payload.encode())
try:
    await emit_status("PROCESSING", "Uruchamianie OCR...")
# ... Logika OCR ...
await emit_status("OCR_DONE", "Tekst wyekstrahowany.")
# ... Logika Walidacji ...
await emit_status("COMPLETED", "Faktura gotowa!")
except Exception as e:
await emit_status("FAILED", f"Błąd: {str(e)}")


async def message_handler(msg):


# Wyciągamy ID z nagłówka NATS
cid = msg.headers.get("X-Correlation-ID", "unknown-worker")
# Ustawiamy kontekst w procesie Workera
token = correlation_id_ctx.set(cid)
log = get_logger()
try:
    log.info("Rozpoczęto przetwarzanie zadania z NATS")
# ... procesowanie ...
finally:
    correlation_id_ctx.reset(token)
