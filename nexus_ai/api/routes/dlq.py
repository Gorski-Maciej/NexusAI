"""
DLQ (Dead Letter Queue) Management API Controller
==================================================

Provides administrative endpoints for managing tasks that have been
moved to the Dead Letter Queue after exhausting their retry attempts.

Endpoints:
    GET    /api/v1/system/dlq           — List dead letter items (paginated)
    GET    /api/v1/system/dlq/stats     — DLQ statistics summary
    GET    /api/v1/system/dlq/{id}      — View details of a specific DLQ item
    POST   /api/v1/system/dlq/{id}/retry   — Retry a specific DLQ item
    POST   /api/v1/system/dlq/retry-all    — Retry all unresolved DLQ items
    DELETE /api/v1/system/dlq/{id}         — Delete/resolve a DLQ item

Usage:
    Registered in app.py under the DLQController class.
    Requires admin-level authentication.
"""

from __future__ import annotations

import uuid

import pendulum
from litestar import Controller, delete, get, post
from litestar.connection import Request
from litestar.exceptions import NotFoundException
from litestar.response import Response
from sqlalchemy import text
from structlog import get_logger

from nexus_ai.api.rbac import admin_only_guard, requires_permission
from nexus_ai.core.msgspec_utils import DecodeError, msgspec_loads

logger = get_logger("nexus.api.dlq")


class DLQController(Controller):
    """Dead Letter Queue management endpoints."""

    path = "/api/v1/system/dlq"
    guards = [admin_only_guard]
    tags = ["Admin"]

    @get("/stats", guards=[requires_permission("admin:dlq")])
    async def dlq_stats(self, request: Request) -> dict:
        """DLQ statistics: total items, unresolved, by task type."""
        async with request.app.state.db_engine.connect() as conn:
            # Total unresolved
            unresolved_row = (
                await conn.execute(
                    text("SELECT COUNT(*) FROM failed_tasks WHERE resolved = 0")
                )
            ).scalar()
            total_unresolved = int(unresolved_row or 0)

            # Total resolved
            resolved_row = (
                await conn.execute(
                    text("SELECT COUNT(*) FROM failed_tasks WHERE resolved = 1")
                )
            ).scalar()
            total_resolved = int(resolved_row or 0)

            # Breakdown by task type (unresolved)
            type_rows = (
                await conn.execute(
                    text(
                        """
                        SELECT task_name, COUNT(*) as cnt
                        FROM failed_tasks
                        WHERE resolved = 0
                        GROUP BY task_name
                        ORDER BY cnt DESC
                        """
                    )
                )
            ).all()
            breakdown = {str(r[0]): int(r[1]) for r in type_rows}

            # Dead-letter outbox events
            dl_outbox = (
                await conn.execute(
                    text("SELECT COUNT(*) FROM outbox_events WHERE status = 'DEAD_LETTER'")
                )
            ).scalar()
            dead_letter_outbox = int(dl_outbox or 0)

            # Failed outbox events
            failed_outbox = (
                await conn.execute(
                    text("SELECT COUNT(*) FROM outbox_events WHERE status = 'FAILED'")
                )
            ).scalar()
            failed_outbox_count = int(failed_outbox or 0)

            return {
                "total_unresolved": total_unresolved,
                "total_resolved": total_resolved,
                "total_all": total_unresolved + total_resolved,
                "breakdown_by_type": breakdown,
                "dead_letter_outbox_events": dead_letter_outbox,
                "failed_outbox_events": failed_outbox_count,
            }

    @get(guards=[requires_permission("admin:dlq")])
    async def list_dlq(self, request: Request) -> dict:
        """List dead letter items (paginated, filterable)."""
        resolved_filter = request.query_params.get("resolved")
        task_name_filter = request.query_params.get("task_name")
        limit = int(request.query_params.get("limit", "50"))
        offset = int(request.query_params.get("offset", "0"))

        where_clauses = ["1=1"]
        params: dict = {}

        if resolved_filter is not None:
            where_clauses.append("ft.resolved = :resolved")
            params["resolved"] = resolved_filter.lower() in ("true", "1", "yes")

        if task_name_filter:
            where_clauses.append("ft.task_name LIKE :task_name")
            params["task_name"] = f"%{task_name_filter}%"

        where_sql = " AND ".join(where_clauses)

        async with request.app.state.db_engine.connect() as conn:
            # Count total
            count_row = (
                await conn.execute(
                    text(f"SELECT COUNT(*) FROM failed_tasks ft WHERE {where_sql}"),
                    params,
                )
            ).scalar()
            total = int(count_row or 0)

            # Fetch rows
            rows = (
                await conn.execute(
                    text(
                        f"""
                        SELECT ft.id, ft.task_name, ft.task_id, ft.error_type,
                               ft.error_message, ft.retry_count, ft.max_retries,
                               ft.resolved, ft.resolved_at, ft.resolved_by,
                               ft.resolution_note, ft.failed_at, ft.created_at
                        FROM failed_tasks ft
                        WHERE {where_sql}
                        ORDER BY ft.failed_at DESC
                        LIMIT :limit OFFSET :offset
                        """
                    ),
                    {**params, "limit": limit, "offset": offset},
                )
            ).mappings().all()

        tasks = []
        for r in rows:
            d = dict(r)
            # Serialize datetime objects to ISO strings
            for key in ("failed_at", "created_at", "resolved_at"):
                if d.get(key) is not None:
                    if hasattr(d[key], "isoformat"):
                        d[key] = d[key].isoformat()
                    else:
                        d[key] = str(d[key])
            tasks.append(d)

        return {
            "items": tasks,
            "total": total,
            "limit": limit,
            "offset": offset,
        }

    @get("/{item_id:str}", guards=[requires_permission("admin:dlq")])
    async def get_dlq_item(self, item_id: str, request: Request) -> dict:
        """View details of a specific DLQ item."""
        async with request.app.state.db_engine.connect() as conn:
            row = (
                await conn.execute(
                    text(
                        """
                        SELECT id, task_name, task_id, error_type, error_message,
                               stack_trace, payload, retry_count, max_retries,
                               resolved, resolved_at, resolved_by, resolution_note,
                               failed_at, created_at
                        FROM failed_tasks
                        WHERE id = :id
                        LIMIT 1
                        """
                    ),
                    {"id": item_id},
                )
            ).mappings().first()

        if not row:
            raise NotFoundException(detail=f"DLQ item not found: {item_id}")

        result = dict(row)
        # Attempt to parse payload as JSON for display
        payload_raw = result.get("payload", "{}")
        try:
            result["payload"] = msgspec_loads(payload_raw)
        except (DecodeError, TypeError):
            pass  # Keep as string

        # Serialize datetime objects
        for key in ("failed_at", "created_at", "resolved_at"):
            if result.get(key) is not None:
                if hasattr(result[key], "isoformat"):
                    result[key] = result[key].isoformat()
                else:
                    result[key] = str(result[key])

        return result

    @post("/{item_id:str}/retry", guards=[requires_permission("admin:dlq")])
    async def retry_dlq_item(self, item_id: str, request: Request) -> Response[dict]:
        """Retry a specific DLQ item — resets it and re-queues for processing."""
        async with request.app.state.db_engine.connect() as conn:
            row = (
                await conn.execute(
                    text(
                        "SELECT id, task_name, payload FROM failed_tasks WHERE id = :id AND resolved = 0"
                    ),
                    {"id": item_id},
                )
            ).mappings().first()

            if not row:
                raise NotFoundException(
                    detail=f"Unresolved DLQ item not found: {item_id}"
                )

            user = getattr(request, "user", None)
            username = getattr(user, "username", "system") if user else "system"
            now = pendulum.now("UTC").isoformat()

            # Mark as resolved
            await conn.execute(
                text(
                    """
                    UPDATE failed_tasks
                    SET resolved = 1, resolved_at = :now, resolved_by = :by,
                        resolution_note = 'Queued for retry'
                    WHERE id = :id
                    """
                ),
                {"id": item_id, "now": now, "by": username},
            )

            # Re-publish the task as a new outbox event
            task_name = row["task_name"]
            payload = row["payload"]
            event_id = str(uuid.uuid4())
            await conn.execute(
                text(
                    """
                    INSERT INTO outbox_events (id, event_type, aggregate_id, payload, status, processed, created_at)
                    VALUES (:id, :event_type, :aggregate_id, :payload, 'PENDING', 0, :created_at)
                    """
                ),
                {
                    "id": event_id,
                    "event_type": f"retry:{task_name}",
                    "aggregate_id": str(uuid.uuid4()),
                    "payload": payload,
                    "created_at": now,
                },
            )

            await conn.commit()

        logger.info(
            "DLQ item %s (%s) queued for retry by %s (event_id=%s)",
            item_id,
            task_name,
            username,
            event_id,
        )

        return Response(
            content={
                "status": "ok",
                "message": f"Task {item_id} queued for retry",
                "event_id": event_id,
            },
            status_code=200,
        )

    @post("/retry-all", guards=[requires_permission("admin:dlq")])
    async def retry_all_dlq(self, request: Request) -> dict:
        """Retry all unresolved DLQ items."""
        async with request.app.state.db_engine.connect() as conn:
            rows = (
                await conn.execute(
                    text(
                        "SELECT id, task_name, payload FROM failed_tasks WHERE resolved = 0"
                    )
                )
            ).mappings().all()

            user = getattr(request, "user", None)
            username = getattr(user, "username", "system") if user else "system"
            now = pendulum.now("UTC").isoformat()
            retried = 0
            skipped = 0

            for row in rows:
                task_id = row["id"]
                task_name = row["task_name"]
                payload = row["payload"]

                try:
                    await conn.execute(
                        text(
                            """
                            UPDATE failed_tasks
                            SET resolved = 1, resolved_at = :now, resolved_by = :by,
                                resolution_note = 'Queued for retry (bulk)'
                            WHERE id = :id
                            """
                        ),
                        {"id": task_id, "now": now, "by": username},
                    )

                    event_id = str(uuid.uuid4())
                    await conn.execute(
                        text(
                            """
                            INSERT INTO outbox_events (id, event_type, aggregate_id, payload, status, processed, created_at)
                            VALUES (:id, :event_type, :aggregate_id, :payload, 'PENDING', 0, :created_at)
                            """
                        ),
                        {
                            "id": event_id,
                            "event_type": f"retry:{task_name}",
                            "aggregate_id": str(uuid.uuid4()),
                            "payload": payload,
                            "created_at": now,
                        },
                    )
                    retried += 1
                except Exception as exc:
                    logger.warning(
                        "Failed to retry DLQ item %s: %s", task_id, exc
                    )
                    skipped += 1

            await conn.commit()

        logger.info(
            "Bulk DLQ retry: %d re-queued, %d skipped by %s",
            retried,
            skipped,
            username,
        )

        return {
            "status": "ok",
            "retried": retried,
            "skipped": skipped,
            "total_found": len(rows),
        }

    @delete("/{item_id:str}", status_code=200, guards=[requires_permission("admin:dlq")])
    async def delete_dlq_item(self, item_id: str, request: Request) -> Response[dict]:
        """Permanently delete a DLQ item (resolve without retry)."""
        async with request.app.state.db_engine.connect() as conn:
            row = (
                await conn.execute(
                    text("SELECT id FROM failed_tasks WHERE id = :id"),
                    {"id": item_id},
                )
            ).scalar()

            if not row:
                raise NotFoundException(detail=f"DLQ item not found: {item_id}")

            user = getattr(request, "user", None)
            username = getattr(user, "username", "system") if user else "system"
            now = pendulum.now("UTC").isoformat()

            # Soft-delete: mark as resolved with a note
            await conn.execute(
                text(
                    """
                    UPDATE failed_tasks
                    SET resolved = 1, resolved_at = :now, resolved_by = :by,
                        resolution_note = 'Deleted by admin'
                    WHERE id = :id
                    """
                ),
                {"id": item_id, "now": now, "by": username},
            )
            await conn.commit()

        logger.info("DLQ item %s resolved (deleted) by %s", item_id, username)
        return Response(
            content={
                "status": "ok",
                "message": f"DLQ item {item_id} resolved",
            },
            status_code=200,
        )
