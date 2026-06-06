# core/broker.py
from taskiq import TaskiqEvents
from taskiq_nats import NatsBroker

from core.config import AppConfig

config = AppConfig()

# NATS Dead Letter Queue subject
DEAD_LETTER_SUBJECT = "nats.deadletter"

# Inicjalizujemy broker NATS z limitem współbieżności (Rozwiązanie 29).
broker = NatsBroker(
    servers=["nats://127.0.0.1:4222"],
    queue="nexus_tasks",
    subject="nexus.tasks",
    max_reconnect_attempts=0,
    connect_timeout=2,
)

@broker.on_event(TaskiqEvents.WORKER_STARTUP)
async def startup(state):
    """Logika uruchamiana przy starcie workera."""
    print("[Worker] Łączenie z systemami...")
    state.ocr_processor = None
    print("[Worker] Gotowy do przetwarzania faktur (lazy loading modeli).")

@broker.on_event(TaskiqEvents.WORKER_SHUTDOWN)
async def shutdown(state):
    """Sprzątanie przy wyłączaniu."""
    print("[Worker] Zamykanie zasobów...")
