"""Health check endpoints."""
from __future__ import annotations

from typing import Any
from litestar import Controller, get
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


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
    async def detailed_health(self, db_session: AsyncSession) -> dict[str, Any]:
        """Detailed health status."""
        db_ok = True
        pending_outbox = 0
        failed_outbox = 0
        users_count = 0

        try:
            users_count = int((await db_session.execute(text("SELECT COUNT(*) FROM users"))).scalar_one())
            pending_outbox = int(
                (await db_session.execute(text("SELECT COUNT(*) FROM outbox_events WHERE status = 'PENDING'"))).scalar_one()
            )
            failed_outbox = int(
                (await db_session.execute(text("SELECT COUNT(*) FROM outbox_events WHERE status = 'FAILED'"))).scalar_one()
            )
        except Exception:
            db_ok = False

        return {
            "api": "OK" if db_ok else "DEGRADED",
            "version": "1.0.0",
            "database": "OK" if db_ok else "ERROR",
            "users_count": users_count,
            "pending_outbox_events": pending_outbox,
            "failed_outbox_events": failed_outbox,
        }
