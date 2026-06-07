from __future__ import annotations

from structlog import get_logger
import pendulum

from litestar import Controller, get, post
from litestar.connection import Request
from sqlalchemy import text

from nexus_ai.api.routes.ws import signal_cancel
from nexus_ai.core.msgspec_utils import msgspec_dumps

logger = get_logger("nexus.api.tasks.routes")


class TaskController(Controller):
    path = "/api/v1/tasks"

    @get("/{task_id:str}")
    async def get_task_status(self, task_id: str, request: Request) -> dict:
        """Zwraca status zadania z tabeli task_status (Rozwiązanie 17)."""
        engine = getattr(request.app.state, "db_engine", None)
        if not engine:
            return {"task_id": task_id, "status": "UNKNOWN", "error": "Database not available"}

        async with engine.connect() as conn:
            row = (
                await conn.execute(
                    text(
                        """
                        SELECT task_id, task_name, status, progress, result, error_message,
                               created_at, updated_at
                        FROM task_status
                        WHERE task_id = :task_id
                        LIMIT 1
                        """
                    ),
                    {"task_id": task_id},
                )
            ).mappings().first()

        if not row:
            return {"task_id": task_id, "status": "UNKNOWN", "message": "Task not found"}

        return {
            "task_id": row["task_id"],
            "task_name": row["task_name"],
            "status": row["status"],
            "progress": float(row["progress"] or 0.0),
            "result": row["result"],
            "error_message": row["error_message"],
            "created_at": row["created_at"].isoformat() if hasattr(row["created_at"], "isoformat") else str(row["created_at"]),
            "updated_at": row["updated_at"].isoformat() if hasattr(row["updated_at"], "isoformat") else str(row["updated_at"]),
        }

    @post("/{task_id:str}/cancel")
    async def cancel_task(self, task_id: str, request: Request) -> dict:
        """
        Anuluje zadanie długotrwałe.
        Rozwiązanie 17: Sygnalizuje anulowanie przez WebSocket i NATS.
        """
        # Sygnalizuj anulowanie lokalnie (przez WebSocket)
        signal_cancel(task_id)

        # Wyślij zdarzenie anulowania przez NATS
        import nats

        from core.config import AppConfig
        config = AppConfig()
        try:
            nc = await nats.connect(config.nats_url)
            await nc.publish(
                f"task.cancel.{task_id}",
                msgspec_dumps({"task_id": task_id, "cancelled_at": pendulum.now("UTC").isoformat()}).encode(),
            )
            await nc.close()
        except Exception as e:
            logger.warning("[CANCEL] Failed to publish cancel event to NATS: %s", e)

        # Zaktualizuj status w bazie
        engine = getattr(request.app.state, "db_engine", None)
        if engine:
            async with engine.connect() as conn:
                await conn.execute(
                    text(
                        """
                        UPDATE task_status
                        SET status = 'CANCELLED', updated_at = CURRENT_TIMESTAMP
                        WHERE task_id = :task_id AND status NOT IN ('COMPLETED', 'CANCELLED', 'FAILED')
                        """
                    ),
                    {"task_id": task_id},
                )
                await conn.commit()

        return {"task_id": task_id, "status": "CANCELLED", "message": "Cancellation signal sent"}
