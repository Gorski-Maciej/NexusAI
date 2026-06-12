"""Resilience monitoring endpoint — managed by stamina.

Zgodnie z aa3fvcx.txt: stamina zastępuje custom CircuitBreaker.
stamina zarządza retry + circuit breaker przez dekoratory, nie przez
centralny rejestr. Ten endpoint zwraca status resilience systemu.
"""
from __future__ import annotations

from typing import Any

from litestar import Controller, get
from litestar.connection import Request

from nexus_ai.api.dto import GenericDictDTO, TAG_SYSTEM


class CircuitBreakerController(Controller):
    """Resilience monitoring — stamina zastępuje custom CircuitBreaker."""

    path = "/api/v1/system/circuit-breakers"
    tags = [TAG_SYSTEM]

    @get(
        "/",
        return_dto=GenericDictDTO,
        summary="List circuit breakers",
        description="Returns resilience status managed by stamina (async-native, anyio). stamina does not expose a central registry.",
        operation_id="listCircuitBreakers",
    )
    async def list_breakers(self, request: Request) -> dict[str, Any]:
        """
        Return resilience status.

        Obecnie wszystkie operacje retry + circuit breaker są zarządzane przez
        ``stamina`` (async-native, anyio). stamina nie udostępnia centralnego
        rejestru breakerów — każdy @stamina.retry zarządza własnym stanem.
        """
        return {
            "provider": "stamina",
            "status": "active",
            "details": "Retry + circuit breaker managed by stamina decorators",
            "note": "stamina does not expose a central breaker registry. "
                     "Each @stamina.retry decorator manages its own state internally.",
        }
