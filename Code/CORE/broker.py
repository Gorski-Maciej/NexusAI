# core/broker.py
import asyncio
from taskiq_nats import NatsBroker
from nats.js import api as js_api
from taskiq import TaskiqEvents
from core.config import AppConfig

config = AppConfig()

# Inicjalizujemy broker NATS z limitem współbieżności (Rozwiązanie 29).
broker = NatsBroker(
    servers=["nats://127.0.0.1:4222"],
    queue_name="nexus_tasks",
    subject="nexus.tasks",
    stream_name="nexus_stream",
    # Ograniczenie liczby równocześnie przetwarzanych wiadomości (Rozwiązanie 29)
    consumer_config=js_api.ConsumerConfig(
        max_ack_pending=5,
        ack_wait=300,  # 5 minut na wykonanie zadania
        max_deliver=3,  # max 3 dostarczenia przed dead letter
    ),
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
