# core/events.py
from enum import StrEnum


class NexusEvent(StrEnum):
    """Centralny rejestr wszystkich zdarzeń przesyłanych przez NATS / Taskiq."""

    # Zdarzenia wejściowe (Kolejka zadań)
    INVOICE_UPLOADED = "task.invoice.uploaded"
    DOCUMENT_REJECTED = "task.document.rejected"
    RUN_SYNC_OLAP = "task.sync.olap"

    # Zdarzenia wyjściowe (Websocket / UI Updates)
    OCR_STARTED = "event.ocr.started"
    OCR_COMPLETED = "event.ocr.completed"
    OCR_FAILED = "event.ocr.failed"

    # Powiadomienia systemowe
    SYSTEM_UPDATE_AVAILABLE = "event.system.update_available"
    SYSTEM_BACKUP_COMPLETED = "event.system.backup_completed"
