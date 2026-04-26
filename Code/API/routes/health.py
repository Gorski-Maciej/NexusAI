"""Health check endpoints."""
from __future__ import annotations

from typing import Any
from litestar import Controller, get


class HealthController(Controller):
    """Health check and status endpoints."""
    path = "/api/v1/health"

    @get("")
    async def health_check(self) -> dict[str, str]:
        """Basic health check."""
        return {"status": "OK", "version": "1.0.0"}

    @get("/live")
    async def liveness_probe(self) -> dict[str, str]:
        """Kubernetes liveness probe."""
        return {"status": "alive"}

    @get("/ready")
    async def readiness_probe(self) -> dict[str, str]:
        """Kubernetes readiness probe."""
        return {"status": "ready"}

    @get("/detailed")
    async def detailed_health(self) -> dict[str, Any]:
        """Detailed health status."""
        return {
            "api": "OK",
            "version": "1.0.0",
            "uptime_seconds": 0,
            "timestamp": "2026-04-26T20:59:00Z",
        }
