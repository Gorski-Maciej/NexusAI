# pipeline/manager.py
from statemachine import StateMachine, State
from core.logger import logger
from core.events import NexusEvent

class DocumentPipeline(StateMachine):
    """Zarządza cyklem życia analizy dokumentu."""

    # Definicja stanów
    pending = State("Oczekiwanie", initial=True)
    processing_ocr = State("Analiza Wizualna (OCR)")
    extracting_data = State("Ekstrakcja LLM")
    validating = State("Weryfikacja Logiczna")
    completed = State("Zakończono")
    failed = State("Błąd")

    # Definicja przejść
    start = pending.to(processing_ocr)
    ocr_done = processing_ocr.to(extracting_data)
    extraction_done = extracting_data.to(validating)
    validate_success = validating.to(completed)
    error_occured = (pending | processing_ocr | extracting_data | validating).to(failed)

    def __init__(self, doc_id: str, bus_client):
        self.doc_id = doc_id
        self.bus = bus_client # NATS/Websocket client do powiadomień UI
        super().__init__()
