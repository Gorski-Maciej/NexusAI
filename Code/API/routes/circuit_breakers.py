"""Circuit Breaker monitoring endpoint (Rozwiązanie 21)."""
from __future__ import annotations

import time
from typing import Any

from litestar import Controller, get
from litestar.connection import Request

from core.circuit_breaker import CircuitBreaker, CircuitState, get_breaker_registry


class CircuitBreakerController(Controller):
    """Circuit Breaker monitoring endpoints (Rozwiązanie 21)."""

    path = "/api/v1/system/circuit-breakers"

    @get("/")
    async def list_breakers(self, request: Request) -> dict[str, Any]:
        """Return state of all registered circuit breakers from auto-registry."""
        registry = get_breaker_registry()
        states: list[dict[str, Any]] = []
        for name, breaker in registry.items():
            remaining_cooldown = 0.0
            if breaker.state == CircuitState.OPEN:
                remaining_cooldown = max(
                    0.0, breaker.recovery_timeout - (time.time() - breaker.last_failure_time)
                )
            states.append(
                {
                    "name": name,
                    "state": breaker.state.value,
                    "failures": breaker.failures,
                    "failure_threshold": breaker.failure_threshold,
                    "recovery_timeout_s": breaker.recovery_timeout,
                    "remaining_cooldown_s": round(remaining_cooldown, 1),
                    "last_failure_at": (
                        time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(breaker.last_failure_time))
                        if breaker.last_failure_time > 0
                        else None
                    ),
                }
            )

        total = len(states)
        open_count = sum(1 for s in states if s["state"] == CircuitState.OPEN.value)
        return {
            "total": total,
            "open": open_count,
            "closed": total - open_count,
            "breakers": states,
        }
