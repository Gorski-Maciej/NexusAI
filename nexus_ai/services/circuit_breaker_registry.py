"""
CircuitBreakerRegistry — per-service circuit breakers with individual thresholds.

INNOWACJA #5 z Raportu v7.0: Dla każdego external API (KSeF, GUS, NBP, Biała Lista)
osobny circuit breaker z własnymi progami i cooldown. Stamina jest za ogólna.

Każdy serwis ma:
- failure_threshold: liczba failures przed otwarciem obwodu
- cooldown_seconds: czas regeneracji
- half_open_limit: liczba prób w stanie half-open

Usage:
    registry = CircuitBreakerRegistry()
    registry.register("ksef", failure_threshold=5, cooldown_seconds=30)

    async with registry.call("ksef") as cb:
        if cb.is_open:
            raise CircuitOpenError("KSeF circuit is open")
        result = await call_ksef_api()
        cb.record_success()
"""

from __future__ import annotations

import enum
import time as _time
from collections.abc import Callable
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.services.circuit_breaker")


# ── Circuit Breaker State ─────────────────────────────────────────────────


class CircuitState(enum.StrEnum):
    CLOSED = "closed"       # Normal operation
    OPEN = "open"           # Failing, reject all calls
    HALF_OPEN = "half_open" # Testing recovery


class CircuitBreakerConfig(enum.StrEnum):
    """Pre-built configs for known external services."""

    KSEF = "ksef"           # Polish e-invoice system
    GUS_BIR = "gus_bir"    # Business registry
    NBP = "nbp"             # National Bank of Poland
    BIALA_LISTA = "biala_lista"  # VAT whitelist
    VIES = "vies"           # EU VAT validation
    INFISICAL = "infisical" # Secrets vault
    OPA = "opa"             # Policy engine


# Default configs per service (tuned for real-world behavior)
SERVICE_DEFAULTS: dict[str, dict[str, Any]] = {
    CircuitBreakerConfig.KSEF: {
        "failure_threshold": 5,
        "cooldown_seconds": 60.0,
        "half_open_limit": 2,
        "timeout_seconds": 30.0,
    },
    CircuitBreakerConfig.GUS_BIR: {
        "failure_threshold": 3,
        "cooldown_seconds": 120.0,
        "half_open_limit": 1,
        "timeout_seconds": 15.0,
    },
    CircuitBreakerConfig.NBP: {
        "failure_threshold": 3,
        "cooldown_seconds": 300.0,
        "half_open_limit": 1,
        "timeout_seconds": 10.0,
    },
    CircuitBreakerConfig.BIALA_LISTA: {
        "failure_threshold": 5,
        "cooldown_seconds": 60.0,
        "half_open_limit": 2,
        "timeout_seconds": 20.0,
    },
    CircuitBreakerConfig.VIES: {
        "failure_threshold": 3,
        "cooldown_seconds": 120.0,
        "half_open_limit": 1,
        "timeout_seconds": 15.0,
    },
    CircuitBreakerConfig.INFISICAL: {
        "failure_threshold": 2,
        "cooldown_seconds": 30.0,
        "half_open_limit": 1,
        "timeout_seconds": 5.0,
    },
    CircuitBreakerConfig.OPA: {
        "failure_threshold": 3,
        "cooldown_seconds": 10.0,
        "half_open_limit": 1,
        "timeout_seconds": 5.0,
    },
}


class CircuitOpenError(RuntimeError):
    """Raised when circuit is OPEN and call is rejected."""
    __slots__ = ("service_name",)

    def __init__(self, service_name: str) -> None:
        self.service_name = service_name
        super().__init__(f"Circuit OPEN for '{service_name}' — all calls rejected")


# ── Per-Service Circuit Breaker ───────────────────────────────────────────


class ServiceCircuitBreaker:
    """Circuit breaker dla pojedynczego serwisu zewnętrznego."""

    __slots__ = (
        "_cooldown_seconds",
        "_failure_count",
        "_failure_threshold",
        "_half_open_count",
        "_half_open_limit",
        "_last_failure_time",
        "_last_state_change",
        "_name",
        "_state",
        "_success_count",
        "_timeout_seconds",
    )

    def __init__(
        self,
        name: str,
        failure_threshold: int = 5,
        cooldown_seconds: float = 30.0,
        half_open_limit: int = 2,
        timeout_seconds: float = 30.0,
    ) -> None:
        self._name = name
        self._failure_threshold = failure_threshold
        self._cooldown_seconds = cooldown_seconds
        self._half_open_limit = half_open_limit
        self._timeout_seconds = timeout_seconds
        self._state = CircuitState.CLOSED
        self._failure_count = 0
        self._success_count = 0
        self._half_open_count = 0
        self._last_failure_time = 0.0
        self._last_state_change = _time.time()

    @property
    def is_open(self) -> bool:
        """Check if circuit is currently OPEN."""
        if self._state == CircuitState.CLOSED:
            return False
        if self._state == CircuitState.OPEN:
            # Check if cooldown expired → try HALF_OPEN
            if _time.time() - self._last_state_change >= self._cooldown_seconds:
                self._transition_to(CircuitState.HALF_OPEN)
                return False
            return True
        # HALF_OPEN → allow limited calls
        return False

    @property
    def state(self) -> CircuitState:
        return self._state

    def record_success(self) -> None:
        """Record a successful call."""
        self._success_count += 1
        if self._state == CircuitState.HALF_OPEN:
            self._half_open_count += 1
            if self._half_open_count >= self._half_open_limit:
                self._transition_to(CircuitState.CLOSED)
                logger.info("[CB:%s] Circuit CLOSED — service recovered", self._name)
        self._failure_count = 0  # Reset failure count on success

    def record_failure(self) -> None:
        """Record a failed call."""
        self._failure_count += 1
        self._last_failure_time = _time.time()

        if self._state == CircuitState.HALF_OPEN:
            # Failure in half-open → back to OPEN
            self._transition_to(CircuitState.OPEN)
            logger.warning("[CB:%s] Half-open call failed — back to OPEN", self._name)
        elif self._failure_count >= self._failure_threshold:
            self._transition_to(CircuitState.OPEN)
            logger.error(
                "[CB:%s] Circuit OPEN after %d failures (threshold: %d)",
                self._name,
                self._failure_count,
                self._failure_threshold,
            )

    def _transition_to(self, new_state: CircuitState) -> None:
        old = self._state
        self._state = new_state
        self._last_state_change = _time.time()
        self._half_open_count = 0
        logger.info(
            "[CB:%s] %s → %s (failures=%d, successes=%d)",
            self._name,
            old.value,
            new_state.value,
            self._failure_count,
            self._success_count,
        )

    def get_stats(self) -> dict[str, Any]:
        """Return current circuit breaker statistics."""
        return {
            "name": self._name,
            "state": self._state.value,
            "failure_count": self._failure_count,
            "success_count": self._success_count,
            "failure_threshold": self._failure_threshold,
            "cooldown_seconds": self._cooldown_seconds,
            "last_failure_age_seconds": _time.time() - self._last_failure_time if self._last_failure_time else -1,
            "time_in_current_state_seconds": _time.time() - self._last_state_change,
            "is_open": self.is_open,
        }


# ── Circuit Breaker Registry ──────────────────────────────────────────────


class CircuitBreakerRegistry:
    """Centralny rejestr circuit breakerów per external service.

    Usage:
        registry = CircuitBreakerRegistry()
        # Auto-register with defaults
        cb = registry.get("ksef")

        if cb.is_open:
            raise CircuitOpenError("ksef")

        try:
            result = await call_ksef_api()
            cb.record_success()
        except Exception:
            cb.record_failure()
            raise
    """

    __slots__ = ("_breakers", "_lock")

    def __init__(self) -> None:
        import threading
        self._breakers: dict[str, ServiceCircuitBreaker] = {}
        self._lock = threading.Lock()

    def register(
        self,
        name: str,
        failure_threshold: int = 5,
        cooldown_seconds: float = 30.0,
        half_open_limit: int = 2,
        timeout_seconds: float = 30.0,
    ) -> ServiceCircuitBreaker:
        """Register a new circuit breaker."""
        breaker = ServiceCircuitBreaker(
            name=name,
            failure_threshold=failure_threshold,
            cooldown_seconds=cooldown_seconds,
            half_open_limit=half_open_limit,
            timeout_seconds=timeout_seconds,
        )
        with self._lock:
            self._breakers[name] = breaker
        logger.info("[CB:REGISTRY] Registered breaker for '%s'", name)
        return breaker

    def get(self, name: str) -> ServiceCircuitBreaker:
        """Get or auto-create a circuit breaker for a service name.

        If the name matches a known config, use tuned defaults.
        Otherwise, use generic defaults.
        """
        with self._lock:
            if name in self._breakers:
                return self._breakers[name]

        # Auto-create with pre-tuned defaults
        defaults = SERVICE_DEFAULTS.get(name, {})
        breaker = ServiceCircuitBreaker(
            name=name,
            failure_threshold=defaults.get("failure_threshold", 5),
            cooldown_seconds=defaults.get("cooldown_seconds", 30.0),
            half_open_limit=defaults.get("half_open_limit", 2),
            timeout_seconds=defaults.get("timeout_seconds", 30.0),
        )
        with self._lock:
            self._breakers[name] = breaker
        logger.info("[CB:REGISTRY] Auto-created breaker for '%s'", name)
        return breaker

    def get_all_stats(self) -> dict[str, dict[str, Any]]:
        """Get stats for all registered circuit breakers."""
        return {name: breaker.get_stats() for name, breaker in self._breakers.items()}

    def reset_all(self) -> None:
        """Reset all circuit breakers to CLOSED."""
        with self._lock:
            for breaker in self._breakers.values():
                breaker._transition_to(CircuitState.CLOSED)
        logger.info("[CB:REGISTRY] All circuits reset to CLOSED")

    @property
    def open_circuits(self) -> list[str]:
        """List of currently OPEN circuit names."""
        return [name for name, breaker in self._breakers.items() if breaker.is_open]

    @property
    def count(self) -> int:
        return len(self._breakers)


# ── Context Manager ───────────────────────────────────────────────────────


class CircuitBreakerCall:
    """Context manager dla wywołań chronionych circuit breakerem.

    Usage:
        async with registry.call("ksef") as ctx:
            result = await ksef_api.submit(data)
    """
    __slots__ = ("_breaker",)

    def __init__(self, breaker: ServiceCircuitBreaker) -> None:
        self._breaker = breaker

    async def __aenter__(self) -> ServiceCircuitBreaker:
        if self._breaker.is_open:
            raise CircuitOpenError(self._breaker._name)
        return self._breaker

    async def __aexit__(self, exc_type, exc_val, exc_tb) -> bool:
        if exc_type is not None:
            self._breaker.record_failure()
        else:
            self._breaker.record_success()
        return False  # Don't suppress exceptions


# ── Global singleton ──────────────────────────────────────────────────────

_default_registry: CircuitBreakerRegistry | None = None
import threading as _threading


def get_circuit_breaker_registry() -> CircuitBreakerRegistry:
    """Get global CircuitBreakerRegistry singleton."""
    global _default_registry
    if _default_registry is None:
        _default_registry = CircuitBreakerRegistry()
    return _default_registry


__all__ = [
    "CircuitBreakerRegistry",
    "ServiceCircuitBreaker",
    "CircuitBreakerCall",
    "CircuitState",
    "CircuitOpenError",
    "CircuitBreakerConfig",
    "SERVICE_DEFAULTS",
    "get_circuit_breaker_registry",
]
