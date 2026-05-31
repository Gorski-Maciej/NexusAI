# core/integrations/circuit_breaker.py
import time
from enum import Enum
from loguru import logger

class CircuitState(Enum):
    CLOSED = "Działa" # Wszystko OK
    OPEN = "Rozłączony" # Błędy - nie wysyłaj zapytań
    HALF_OPEN = "Testowy" # Próba powrotu

class CircuitBreaker:
    """Implementacja wzorca Circuit Breaker chroniąca przed awariami kaskadowymi."""

    def __init__(self, failure_threshold=5, recovery_timeout=60):
        self.state = CircuitState.CLOSED
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.failures = 0
        self.last_failure_time = 0.0

    async def call(self, func, *args, **kwargs):
        if self.state == CircuitState.OPEN:
            if time.time() - self.last_failure_time > self.recovery_timeout:
                self.state = CircuitState.HALF_OPEN
            else:
                raise Exception("KSeF API jest obecnie niedostępne (Circuit Breaker OPEN)")

        try:
            result = await func(*args, **kwargs)
            self._on_success()
            return result
        except Exception as e:
            self._on_failure()
            raise e

    def _on_success(self):
        self.failures = 0
        self.state = CircuitState.CLOSED
        
    def _on_failure(self):
        self.failures += 1
        self.last_failure_time = time.time()
        if self.failures >= self.failure_threshold:
            self.state = CircuitState.OPEN
            logger.error(f"[Circuit Breaker] Obwód OTWARTY! Ruch zatrzymany na {self.recovery_timeout}s.")
