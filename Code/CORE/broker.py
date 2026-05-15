# core/broker.py
import asyncio
from taskiq_nats import NatsBroker
from taskiq import TaskiqEvents
from core.config import AppConfig

config = AppConfig()

# Inicjalizujemy broker NATS.
broker = NatsBroker(
    servers=["nats://127.0.0.1:4222"],
    queue_name="nexus_tasks",
    subject="nexus.tasks",
    stream_name="nexus_stream",
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
