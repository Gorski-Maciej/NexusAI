# core/circuit_breaker.py
import time
from enum import Enum
from typing import Any, Callable
from loguru import logger

__all__ = ["CircuitBreaker", "CircuitState"]

class CircuitState(Enum):
    CLOSED = "Działa"  # Wszystko OK
    OPEN = "Rozłączony"  # Błędy - nie wysyłaj zapytań
    HALF_OPEN = "Testowy"  # Próba powrotu


class CircuitBreaker:
    """Implementacja wzorca Circuit Breaker chroniąca przed awariami kaskadowymi."""

    def __init__(self, failure_threshold: int = 5, recovery_timeout: int = 60) -> None:
        self.state = CircuitState.CLOSED
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.failures = 0
        self.last_failure_time = 0.0

    def allow_request(self) -> bool:
        """Zwraca True jeśli obwód pozwala na wykonanie zapytania."""
        if self.state == CircuitState.OPEN:
            if time.time() - self.last_failure_time > self.recovery_timeout:
                self.state = CircuitState.HALF_OPEN
                return True
            return False
        return True

    def record_success(self) -> None:
        """Rejestruje udane zapytanie — resetuje licznik błędów."""
        self.failures = 0
        self.state = CircuitState.CLOSED

    def record_failure(self, _error: str = "") -> None:
        """Rejestruje nieudane zapytanie — otwiera obwód po przekroczeniu progu."""
        self.failures += 1
        self.last_failure_time = time.time()
        if self.failures >= self.failure_threshold:
            self.state = CircuitState.OPEN
            logger.error(
                f"[Circuit Breaker] Obwód OTWARTY! Ruch zatrzymany na {self.recovery_timeout}s. "
                f"Błędy: {self.failures}/{self.failure_threshold}"
            )

    async def call(self, func: Callable[..., Any], *args: Any, **kwargs: Any) -> Any:
        """Wywołuje funkcję async z ochroną Circuit Breaker."""
        if not self.allow_request():
            raise Exception("Usługa niedostępna (Circuit Breaker OPEN)")

        try:
            result = await func(*args, **kwargs)
            self.record_success()
            return result
        except Exception as e:
            self.record_failure(str(e))
            raise
