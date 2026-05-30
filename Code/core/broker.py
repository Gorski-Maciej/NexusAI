# core/broker.py
from taskiq_nats import NatsBroker
from taskiq import TaskiqEvents

# NATS Dead Letter Queue subject
DEAD_LETTER_SUBJECT = "nats.deadletter"

# Inicjalizujemy broker NATS z konfiguracją konsumenta JetStream:
# max_deliver=3 - maksymalnie 3 próby dostarczenia zadania
# ack_wait=60 - 60 sekund na potwierdzenie przetworzenia
broker = NatsBroker(
    servers=["nats://127.0.0.1:4222"],
    queue_name="nexus_tasks",
    subject="nexus.tasks",
    stream_name="nexus_stream",
    # Konfiguracja konsumenta dla wszystkich zadań
    # (każde zadanie może też mieć własną konfigurację)
    # max_deliver i ack_wait są ustawiane na poziomie konsumenta
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
