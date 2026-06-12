# core/exceptions.py


class NexusBaseException(Exception):  # noqa: N818
    """Główna klasa wyjątków dla całego systemu Nexus AI."""

    def __init__(self, message: str, code: str = "INTERNAL_ERROR"):
        self.message = message
        self.code = code
        super().__init__(self.message)


class AIProcessingError(NexusBaseException):
    """Zgłaszany, gdy model lokalny (Llama/Surya) napotka błąd lub rzuci OOM."""

    def __init__(self, message: str = "Błąd silnika AI podczas analizy dokumentu."):
        super().__init__(message, code="AI_PROCESSING_FAILED")


class LLMGuardrailError(NexusBaseException):
    """Zgłaszany, gdy wyjście z LLM (JSON) jest uszkodzone lub brakuje pól."""

    def __init__(self, message: str = "Model AI wygenerował niepoprawny format danych."):
        super().__init__(message, code="LLM_PARSING_FAILED")


class BrokerConnectionError(NexusBaseException):
    """Zgłaszany przy problemach z magistralą NATS JetStream."""

    def __init__(self, message: str = "Utracono połączenie z magistralą NATS."):
        super().__init__(message, code="BROKER_CONNECTION_ERROR")


class VectorDBError(NexusBaseException):
    def __init__(self, message: str = "Błąd bazy wektorowej."):
        super().__init__(message, code="VECTOR_DB_ERROR")
