"""Admin endpoints for managing failed tasks (DLQ) and system configuration.

Endpoints:
- GET    /api/admin/failed-tasks          — List failed tasks (paginated, filterable)
- POST   /api/admin/failed-tasks/{id}/retry  — Retry a specific failed task
- DELETE /api/admin/failed-tasks/{id}        — Delete a failed task entry
- POST   /api/admin/failed-tasks/retry-all   — Retry all unresolved failed tasks
"""
from __future__ import annotations

import json
import logging
import uuid
from datetime import datetime, timezone

from litestar import Controller, get, post, put, delete
from litestar.connection import Request
from litestar.exceptions import NotFoundException, NotAuthorizedException, ValidationException
from litestar.response import Response
from sqlalchemy import text

from api.rbac import requires_permission, admin_only_guard

import msgspec


class ChangeRoleRequest(msgspec.Struct):
    role: str

logger = logging.getLogger("nexus.api.admin")


class AdminController(Controller):
    path = "/api/admin"
    guards = [admin_only_guard]

    @get("/failed-tasks", guards=[requires_permission("admin:failed-tasks")])
    async def list_failed_tasks(self, request: Request) -> dict:
        """List all failed tasks (paginated, with filtering)."""
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
            total = count_row or 0

            # Fetch rows
            rows = (
                await conn.execute(
                    text(
                        f"""SELECT ft.id, ft.task_name, ft.task_id, ft.error_type,
                                  ft.error_message, ft.retry_count, ft.max_retries,
                                  ft.resolved, ft.resolved_at, ft.resolved_by,
                                  ft.resolution_note, ft.failed_at, ft.created_at
                           FROM failed_tasks ft
                           WHERE {where_sql}
                           ORDER BY ft.failed_at DESC
                           LIMIT :limit OFFSET :offset"""
                    ),
                    {**params, "limit": limit, "offset": offset},
                )
            ).mappings().all()

        tasks = [dict(r) for r in rows]
        return {
            "tasks": tasks,
            "total": total,
            "limit": limit,
            "offset": offset,
        }

    @post("/failed-tasks/{task_id:str}/retry", guards=[requires_permission("admin:failed-tasks")])
    async def retry_failed_task(self, task_id: str, request: Request) -> Response[dict]:
        """Reset a failed task so it can be retried."""
        async with request.app.state.db_engine.connect() as conn:
            row = (
                await conn.execute(
                    text(
                        "SELECT id, task_name, payload, retry_count FROM failed_tasks WHERE id = :id AND resolved = 0"
                    ),
                    {"id": task_id},
                )
            ).mappings().first()

            if not row:
                raise NotFoundException(detail=f"Failed task not found or already resolved: {task_id}")

            # Reset the task - mark as resolved so it can be re-queued
            user = getattr(request, "user", None)
            username = getattr(user, "username", "system") if user else "system"
            now = datetime.now(timezone.utc).isoformat()

            await conn.execute(
                text(
                    """UPDATE failed_tasks
                       SET resolved = 1, resolved_at = :now, resolved_by = :by,
                           resolution_note = 'Queued for retry'
                       WHERE id = :id"""
                ),
                {"id": task_id, "now": now, "by": username},
            )

            # Re-publish the task to the message queue if it was a known task type
            task_name = row["task_name"]
            payload = row["payload"]
            try:
                await _republish_task(request, task_name, payload)
                logger.info("Task %s (%s) re-queued for retry by %s", task_id, task_name, username)
            except Exception as exc:
                logger.warning("Could not republish task %s: %s", task_id, exc)

            await conn.commit()

        return Response(
            content={"status": "ok", "message": f"Task {task_id} queued for retry"},
            status_code=200,
        )

    @delete("/failed-tasks/{task_id:str}", status_code=200, guards=[requires_permission("admin:failed-tasks")])
    async def delete_failed_task(self, task_id: str, request: Request) -> Response[dict]:
        """Permanently delete a failed task entry."""
        async with request.app.state.db_engine.connect() as conn:
            row = (
                await conn.execute(
                    text("SELECT id FROM failed_tasks WHERE id = :id"),
                    {"id": task_id},
                )
            ).scalar()

            if not row:
                raise NotFoundException(detail=f"Failed task not found: {task_id}")

            await conn.execute(
                text("DELETE FROM failed_tasks WHERE id = :id"),
                {"id": task_id},
            )
            await conn.commit()

        logger.info("Failed task %s deleted by admin", task_id)
        return Response(
            content={"status": "ok", "message": f"Task {task_id} deleted"},
            status_code=200,
        )

    @post("/failed-tasks/retry-all", guards=[requires_permission("admin:failed-tasks")])
    async def retry_all_failed_tasks(self, request: Request) -> dict:
        """Retry all unresolved failed tasks."""
        async with request.app.state.db_engine.connect() as conn:
            rows = (
                await conn.execute(
                    text("SELECT id, task_name, payload FROM failed_tasks WHERE resolved = 0")
                )
            ).mappings().all()

            user = getattr(request, "user", None)
            username = getattr(user, "username", "system") if user else "system"
            now = datetime.now(timezone.utc).isoformat()
            retried = 0

            for row in rows:
                task_id = row["id"]
                task_name = row["task_name"]
                payload = row["payload"]

                await conn.execute(
                    text(
                        """UPDATE failed_tasks
                           SET resolved = 1, resolved_at = :now, resolved_by = :by,
                               resolution_note = 'Queued for retry (bulk)'
                           WHERE id = :id"""
                    ),
                    {"id": task_id, "now": now, "by": username},
                )

                try:
                    await _republish_task(request, task_name, payload)
                    retried += 1
                except Exception:
                    logger.warning("Could not republish task %s during bulk retry", task_id)

            await conn.commit()

        logger.info("Bulk retry: %d tasks re-queued by %s", retried, username)
        return {"status": "ok", "retried": retried}

    @put("/users/{user_id:str}/role", guards=[requires_permission("user:edit")])
    async def change_user_role(self, user_id: str, data: ChangeRoleRequest, request: Request) -> Response[dict]:
        """Change a user's role. Only admin can change roles."""
        valid_roles = {"admin", "accountant", "auditor", "viewer"}
        new_role = data.role.strip().lower()

        if new_role not in valid_roles:
            raise ValidationException(
                detail=f"Invalid role: {new_role}. Valid roles: {', '.join(sorted(valid_roles))}"
            )

        actor = getattr(request, "user", None)
        actor_name = getattr(actor, "username", "system") if actor else "system"

        async with request.app.state.db_engine.begin() as conn:
            # Check user exists
            user_row = (
                await conn.execute(
                    text("SELECT id, username, role FROM users WHERE id = :id LIMIT 1"),
                    {"id": user_id},
                )
            ).mappings().first()

            if not user_row:
                raise NotFoundException(detail=f"User not found: {user_id}")

            old_role = user_row["role"]
            username = user_row["username"]

            # Update the user's role field
            now = datetime.now(timezone.utc).isoformat()
            await conn.execute(
                text("UPDATE users SET role = :role, updated_at = :now WHERE id = :id"),
                {"role": new_role, "now": now, "id": user_id},
            )

            # Re-assign user_roles: remove old role mappings, add new one
            role_row = (
                await conn.execute(
                    text("SELECT id, name FROM roles WHERE name = :name LIMIT 1"),
                    {"name": new_role},
                )
            ).mappings().first()

            if role_row:
                # Remove all existing role assignments
                await conn.execute(
                    text("DELETE FROM user_roles WHERE user_id = :uid"),
                    {"uid": user_id},
                )
                # Add new role assignment
                await conn.execute(
                    text(
                        "INSERT INTO user_roles (id, user_id, role_id) VALUES (:id, :uid, :rid)"
                    ),
                    {"id": str(uuid.uuid4()), "uid": user_id, "rid": role_row["id"]},
                )

            # Log to audit (inside the same transaction)
            await conn.execute(
                text(
                    """INSERT INTO audit_logs (id, user_id, action, old_value, new_value, timestamp, created_at)
                       VALUES (:id, :uid, 'ROLE_CHANGE', :old_val, :new_val, :now, :now)"""
                ),
                {
                    "id": str(uuid.uuid4()),
                    "uid": user_id,
                    "old_val": json.dumps({"role": old_role, "changed_by": actor_name}),
                    "new_val": json.dumps({"role": new_role}),
                    "now": now,
                },
            )

        # Transaction auto-committed by begin() context manager

        logger.info(
            "Role changed for user '%s' (%s): %s -> %s by %s",
            username, user_id, old_role, new_role,
            actor_name,
        )

        return Response(
            content={
                "status": "ok",
                "message": f"Role changed from '{old_role}' to '{new_role}' for user {username}",
                "user_id": user_id,
                "old_role": old_role,
                "new_role": new_role,
            },
            status_code=200,
        )

    @get("/system/health")
    async def system_health(self, request: Request) -> dict:
        """Comprehensive system health check."""
        import time

        health = {
            "status": "ok",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }

        # Check database
        try:
            async with request.app.state.db_engine.connect() as conn:
                await conn.execute(text("SELECT 1"))
            health["database"] = "connected"
        except Exception as e:
            health["database"] = f"error: {e}"
            health["status"] = "degraded"

        # Check failed tasks count
        try:
            async with request.app.state.db_engine.connect() as conn:
                count = (
                    await conn.execute(
                        text("SELECT COUNT(*) FROM failed_tasks WHERE resolved = 0")
                    )
                ).scalar()
            health["failed_tasks_unresolved"] = count or 0
        except Exception:
            pass

        return health


# ── Helpers ──────────────────────────────────────────────────────────────────


async def _republish_task(request: Request, task_name: str, payload: str) -> None:
    """Re-publish a task to the appropriate queue for retry.

    This is a simplified implementation. In production, this would
    send the task back to NATS/Taskiq for reprocessing.
    """
    # Store a new outbox event for the retry
    async with request.app.state.db_engine.connect() as conn:
        event_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()
        await conn.execute(
            text(
                """INSERT INTO outbox_events (id, event_type, aggregate_id, payload, status, processed, created_at)
                   VALUES (:id, :event_type, :aggregate_id, :payload, 'PENDING', 0, :created_at)"""
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
