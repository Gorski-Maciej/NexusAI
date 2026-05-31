# pipeline/manager.py
from core.logger import logger
from core.events import NexusEvent


class DocumentPipeline:
    """Zarządza cyklem życia analizy dokumentu (no statemachine dependency)."""

    STATES = {
        "pending": "Oczekiwanie",
        "processing_ocr": "Analiza Wizualna (OCR)",
        "extracting_data": "Ekstrakcja LLM",
        "validating": "Weryfikacja Logiczna",
        "completed": "Zakończono",
        "failed": "Błąd",
    }

    def __init__(self, doc_id: str, bus_client):
        self.doc_id = doc_id
        self.bus = bus_client  # NATS/Websocket client do powiadomień UI
        self._state = "pending"

    @property
    def current_state(self):
        return self._state

    @property
    def current_state_label(self):
        return self.STATES.get(self._state, self._state)

    def start(self):
        if self._state == "pending":
            self._state = "processing_ocr"

    def ocr_done(self):
        if self._state == "processing_ocr":
            self._state = "extracting_data"

    def extraction_done(self):
        if self._state == "extracting_data":
            self._state = "validating"

    def validate_success(self):
        if self._state == "validating":
            self._state = "completed"

    def error_occurred(self):
        if self._state in ("pending", "processing_ocr", "extracting_data", "validating"):
            self._state = "failed"
