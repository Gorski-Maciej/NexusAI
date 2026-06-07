"""Admin endpoints for managing failed tasks (DLQ) and system configuration.

Endpoints:
- GET    /api/admin/failed-tasks          — List failed tasks (paginated, filterable)
- POST   /api/admin/failed-tasks/{id}/retry  — Retry a specific failed task
- DELETE /api/admin/failed-tasks/{id}        — Delete a failed task entry
- POST   /api/admin/failed-tasks/retry-all   — Retry all unresolved failed tasks
"""
from __future__ import annotations

from structlog import get_logger
import uuid
import pendulum

import msgspec
from litestar import Controller, delete, get, post, put
from litestar.connection import Request
from litestar.exceptions import NotFoundException, ValidationException
from litestar.response import Response
from sqlalchemy import text

from nexus_ai.api.rbac import admin_only_guard, requires_permission
from nexus_ai.core.config import AppConfig
from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_dumps_bytes


class ChangeRoleRequest(msgspec.Struct):
    role: str


class RiskThresholdCreate(msgspec.Struct):
    """Request body for creating a new risk threshold rule."""
    condition: dict
    output: dict
    valid_from: str = "2024-01-01"
    valid_to: str | None = None
    priority: int = 100


logger = get_logger("nexus.api.admin")


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
            now = pendulum.now("UTC").isoformat()

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
            now = pendulum.now("UTC").isoformat()
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
            now = pendulum.now("UTC").isoformat()
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
                    "old_val": msgspec_dumps({"role": old_role, "changed_by": actor_name}),
                    "new_val": msgspec_dumps({"role": new_role}),
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

    # ── Risk Thresholds admin endpoints (Part V) ────────────────────────

    @get("/risk-thresholds", guards=[requires_permission("admin:risk-thresholds")])
    async def list_risk_thresholds(self, request: Request) -> dict:
        """List all active risk threshold rules."""
        import duckdb

        from services.risk_guard import RiskGuard

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            guard = RiskGuard(conn)
            rules = guard.list_thresholds()
            return {"rules": rules, "total": len(rules)}
        finally:
            conn.close()

    @post("/risk-thresholds", guards=[requires_permission("admin:risk-thresholds")])
    async def create_risk_threshold(self, data: RiskThresholdCreate, request: Request) -> dict:
        """Create a new risk threshold rule (append-only, never update).

        Body:
            condition: dict (e.g. {"tax_form": "CIT_STANDARD"})
            output: dict (e.g. {"required_ml_confidence": 0.98, "action_if_below": "BLOCK_AND_ALERT"})
            valid_from: str (YYYY-MM-DD, default "2024-01-01")
            valid_to: str | None
            priority: int (default 100, lower = higher priority)
        """
        import duckdb

        from services.risk_guard import RiskGuard

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            guard = RiskGuard(conn)
            rule_id = guard.add_threshold(
                condition=data.condition,
                output=data.output,
                valid_from=data.valid_from,
                valid_to=data.valid_to,
                priority=data.priority,
                created_by=getattr(request.user, "username", "admin") if hasattr(request, "user") else "admin",
            )
            logger.info("[ADMIN] Risk threshold created id=%s by=%s", rule_id, getattr(request.user, "username", "admin"))

            # TODO: Publish NATS event risk.thresholds.updated for hot-reload
            try:
                import nats
                nc = await nats.connect(AppConfig().nats_url)
                await nc.publish(
                    "risk.thresholds.updated",
                    msgspec_dumps_bytes({"rule_id": rule_id, "action": "created"}),
                )
                await nc.close()
            except Exception as pub_err:
                logger.warning("[ADMIN] Failed to publish NATS event: %s", pub_err)

            return {"status": "ok", "rule_id": rule_id}
        finally:
            conn.close()

    @get("/system/health")
    async def system_health(self, request: Request) -> dict:
        """Comprehensive system health check."""

        health = {
            "status": "ok",
            "timestamp": pendulum.now("UTC").isoformat(),
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

    @put("/risk-thresholds/{rule_id:str}/deprecate", guards=[requires_permission("admin:risk-thresholds")])
    async def deprecate_risk_threshold(self, rule_id: str, request: Request) -> dict:
        """Deactivate a risk threshold rule by setting valid_to = today.

        This is a soft-delete: the rule remains in the database but
        is no longer active.
        """
        import duckdb

        from services.risk_guard import RiskGuard

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            guard = RiskGuard(conn)
            username = getattr(request.user, "username", "admin") if hasattr(request, "user") else "admin"
            ok = guard.deprecate_threshold(rule_id, created_by=username)
            if not ok:
                raise NotFoundException(
                    detail=f"Risk threshold rule not found or already deprecated: {rule_id}"
                )
            logger.info("[ADMIN] Risk threshold deprecated id=%s by=%s", rule_id, username)

            # Publish NATS event for hot-reload
            try:
                import nats
                nc = await nats.connect(AppConfig().nats_url)
                await nc.publish(
                    "risk.thresholds.updated",
                    msgspec_dumps_bytes({"rule_id": rule_id, "action": "deprecated"}),
                )
                await nc.close()
            except Exception as pub_err:
                logger.warning("[ADMIN] Failed to publish NATS event: %s", pub_err)

            return {"status": "ok", "rule_id": rule_id, "action": "deprecated"}
        finally:
            conn.close()

    @get("/risk-thresholds/history", guards=[requires_permission("admin:risk-thresholds")])
    async def list_risk_thresholds_history(self, request: Request) -> dict:
        """History of all risk threshold rules (append-only — full version history).

        Since the table is append-only, all entries represent the full
        history of changes. The response includes active and deprecated rules.
        """
        import duckdb

        from services.risk_guard import RiskGuard

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            guard = RiskGuard(conn)
            rules = guard.list_thresholds_history()
            return {"rules": rules, "total": len(rules)}
        finally:
            conn.close()

    # ── Billing Rules admin endpoints ───────────────────────────────────

    @get("/billing-rules", guards=[requires_permission("admin:billing-rules")])
    async def list_billing_rules(self, request: Request) -> dict:
        """List all active billing rules."""
        import duckdb

        from services.billing_estimator import BillingEstimator

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            estimator = BillingEstimator(conn)
            rules = estimator.list_rules(active_only=True)
            return {"rules": rules, "total": len(rules)}
        finally:
            conn.close()

    @post("/billing-rules", guards=[requires_permission("admin:billing-rules")])
    async def create_billing_rule(self, request: Request) -> dict:
        """Create a new billing rule (append-only, never update)."""
        import duckdb

        from services.billing_estimator import BillingEstimator

        body = await request.json()
        condition = body.get("condition", {})
        price = body.get("price", {})
        valid_from = body.get("valid_from", "2024-01-01")
        valid_to = body.get("valid_to")
        priority = body.get("priority", 100)

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            estimator = BillingEstimator(conn)
            rule_id = estimator.add_rule(
                condition=condition,
                price=price,
                valid_from=valid_from,
                valid_to=valid_to,
                priority=priority,
            )
            logger.info("[ADMIN] Billing rule created id=%s", rule_id)

            # NATS hot-reload
            try:
                import nats
                nc = await nats.connect(AppConfig().nats_url)
                await nc.publish(
                    "billing.rules.updated",
                    msgspec_dumps_bytes({"rule_id": rule_id, "action": "created"}),
                )
                await nc.close()
            except Exception as pub_err:
                logger.warning("[ADMIN] Failed to publish NATS event: %s", pub_err)

            return {"status": "ok", "rule_id": rule_id}
        finally:
            conn.close()

    @post("/billing-rules/{rule_id:str}/deprecate", guards=[requires_permission("admin:billing-rules")])
    async def deprecate_billing_rule(self, rule_id: str, request: Request) -> dict:
        """Deactivate a billing rule."""
        import duckdb

        from services.billing_estimator import BillingEstimator

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            estimator = BillingEstimator(conn)
            ok = estimator.deprecate_rule(rule_id)
            if not ok:
                raise NotFoundException(detail=f"Billing rule not found: {rule_id}")
            logger.info("[ADMIN] Billing rule deprecated id=%s", rule_id)

            # NATS hot-reload event
            try:
                import nats
                nc = await nats.connect(AppConfig().nats_url)
                await nc.publish(
                    "billing.rules.updated",
                    msgspec_dumps_bytes({"rule_id": rule_id, "action": "deprecated"}),
                )
                await nc.close()
            except Exception as pub_err:
                logger.warning("[ADMIN] Failed to publish NATS event: %s", pub_err)

            return {"status": "ok", "rule_id": rule_id, "action": "deprecated"}
        finally:
            conn.close()

    @get("/billing-rules/history", guards=[requires_permission("admin:billing-rules")])
    async def list_billing_rules_history(self, request: Request) -> dict:
        """History of all billing rules (append-only, full version history)."""
        import duckdb

        from services.billing_estimator import BillingEstimator

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            estimator = BillingEstimator(conn)
            rules = estimator.list_rules(active_only=False)
            return {"rules": rules, "total": len(rules)}
        finally:
            conn.close()

    # ── Replay Engine admin endpoint ────────────────────────────────────

    @post("/audit/replay/{transaction_id:str}", guards=[requires_permission("admin:audit")])
    async def replay_decision(self, transaction_id: str, request: Request) -> dict:
        """Replay a historical tax decision and compare verdicts.

        Returns the original verdict, replayed verdict, and match status.
        """
        import duckdb

        from services.replay_engine import ReplayEngine

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            engine = ReplayEngine(conn)
            result = engine.replay(transaction_id)
            return {
                "transaction_id": result.transaction_id,
                "match": result.match,
                "original_verdict": result.original_verdict,
                "replayed_verdict": result.replayed_verdict,
                "differences": result.differences,
                "error": result.error or None,
            }
        finally:
            conn.close()

    @post("/audit/replay-batch", guards=[requires_permission("admin:audit")])
    async def replay_batch(self, request: Request) -> dict:
        """Replay all decisions in a date range.

        Body:
            period_start: str (YYYY-MM-DD)
            period_end: str (YYYY-MM-DD)
            limit: int (default 1000)
        """
        import duckdb

        from services.replay_engine import ReplayEngine

        body = await request.json()
        period_start = body.get("period_start", "2024-01-01")
        period_end = body.get("period_end", pendulum.now("UTC").format("YYYY-MM-DD"))
        limit = body.get("limit", 1000)

        from datetime import date
        try:
            start = date.fromisoformat(period_start)
            end = date.fromisoformat(period_end)
        except (ValueError, TypeError):
            return {"error": "Invalid date format. Use YYYY-MM-DD."}

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            engine = ReplayEngine(conn)
            results = engine.replay_batch(start, end, limit=int(limit))
            matches = sum(1 for r in results if r.match)
            return {
                "total": len(results),
                "matches": matches,
                "mismatches": len(results) - matches,
                "results": [
                    {
                        "transaction_id": r.transaction_id,
                        "match": r.match,
                        "error": r.error or None,
                        "differences": r.differences,
                    }
                    for r in results
                ],
            }
        finally:
            conn.close()

    # ── Rules admin endpoints ───────────────────────────────────────────

    @get("/rules", guards=[requires_permission("admin:rules")])
    async def list_rules(self, request: Request) -> dict:
        """List all tax rules with optional filtering."""
        import duckdb

        from services.rule_store import RuleStore

        active_only = request.query_params.get("active_only", "false").lower() in ("true", "1")
        limit = int(request.query_params.get("limit", "100"))
        offset = int(request.query_params.get("offset", "0"))
        date_filter = request.query_params.get("date")

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            store = RuleStore(conn)
            store.ensure_schema()
            rules = store.list_rules(
                active_only=active_only,
                limit=limit,
                offset=offset,
                date_filter=date_filter,
            )
            total = store.count_rules(active_only=active_only)
            return {"rules": rules, "total": total, "limit": limit, "offset": offset}
        finally:
            conn.close()

    @post("/rules", guards=[requires_permission("admin:rules")])
    async def create_rule(self, request: Request) -> dict:
        """Create a new tax rule (append-only, never update)."""
        import duckdb

        from services.rule_store import RuleStore

        body = await request.json()
        condition_sql = body.get("condition_sql")
        if not condition_sql:
            raise ValidationException(detail="condition_sql is required")

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            store = RuleStore(conn)
            store.ensure_schema()
            username = getattr(request.user, "username", "admin") if hasattr(request, "user") else "admin"
            rule_id = store.add_rule(
                condition_sql=condition_sql,
                action=body.get("action", {}),
                valid_from=body.get("valid_from", "2024-01-01"),
                valid_to=body.get("valid_to"),
                priority=body.get("priority", 100),
                description_template=body.get("description_template"),
                created_by=username,
            )
            logger.info("[ADMIN] Tax rule created id=%s by=%s", rule_id, username)

            # NATS hot-reload event
            try:
                import nats
                nc = await nats.connect(AppConfig().nats_url)
                await nc.publish(
                    "tax.rules.updated",
                    msgspec_dumps_bytes({"rule_id": rule_id, "action": "created"}),
                )
                await nc.close()
            except Exception as pub_err:
                logger.warning("[ADMIN] Failed to publish NATS event: %s", pub_err)

            return {"status": "ok", "rule_id": rule_id}
        finally:
            conn.close()

    @post("/rules/{rule_id:str}/close", guards=[requires_permission("admin:rules")])
    async def close_rule(self, rule_id: str, request: Request) -> dict:
        """Close a tax rule (set valid_to to today)."""
        import duckdb

        from services.rule_store import RuleStore

        body = await request.json() if request.content_length else {}
        valid_to = body.get("valid_to")

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            store = RuleStore(conn)
            store.ensure_schema()
            username = getattr(request.user, "username", "admin") if hasattr(request, "user") else "admin"
            ok = store.close_rule(rule_id, valid_to=valid_to, closed_by=username)
            if not ok:
                raise NotFoundException(detail=f"Rule not found or already closed: {rule_id}")
            logger.info("[ADMIN] Tax rule closed id=%s by=%s", rule_id, username)

            # NATS hot-reload event
            try:
                import nats
                nc = await nats.connect(AppConfig().nats_url)
                await nc.publish(
                    "tax.rules.updated",
                    msgspec_dumps_bytes({"rule_id": rule_id, "action": "closed"}),
                )
                await nc.close()
            except Exception as pub_err:
                logger.warning("[ADMIN] Failed to publish NATS event: %s", pub_err)

            return {"status": "ok", "rule_id": rule_id, "action": "closed"}
        finally:
            conn.close()

    @get("/rules/{rule_id:str}", guards=[requires_permission("admin:rules")])
    async def get_rule(self, rule_id: str, request: Request) -> dict:
        """Get a single tax rule by ID."""
        import duckdb

        from services.rule_store import RuleStore

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            store = RuleStore(conn)
            store.ensure_schema()
            rule = store.get_rule(rule_id)
            if not rule:
                raise NotFoundException(detail=f"Rule not found: {rule_id}")
            return rule
        finally:
            conn.close()

    @get("/rules/changelog", guards=[requires_permission("admin:rules")])
    async def list_rule_changes(self, request: Request) -> dict:
        """Get rule change log."""
        import duckdb

        from services.rule_store import RuleStore

        rule_id = request.query_params.get("rule_id")
        limit = int(request.query_params.get("limit", "50"))

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            store = RuleStore(conn)
            store.ensure_schema()
            changes = store.get_change_log(rule_id=rule_id, limit=limit)
            return {"changes": changes, "total": len(changes)}
        finally:
            conn.close()

    # ── Ledger Validation Rules admin endpoints ────────────────────────

    @get("/ledger-rules", guards=[requires_permission("admin:ledger")])
    async def list_ledger_rules(self, request: Request) -> dict:
        """List all ledger validation rules."""
        import duckdb

        from services.pre_ledger_validator import PreLedgerValidator

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            validator = PreLedgerValidator(conn)
            rules = validator.list_rules()
            return {"rules": rules, "total": len(rules)}
        finally:
            conn.close()

    @post("/ledger-rules", guards=[requires_permission("admin:ledger")])
    async def create_ledger_rule(self, request: Request) -> dict:
        """Create a new ledger validation rule (append-only).

        Body:
            transaction_type: str (EXPENSE, REVENUE, CORRECTION)
            debit_account_id: int
            credit_account_id: int
            amount_sign: str (POSITIVE, NEGATIVE, ANY) — default POSITIVE
            priority: int — default 100
        """
        import duckdb

        from services.pre_ledger_validator import PreLedgerValidator

        body = await request.json()
        transaction_type = body.get("transaction_type", "EXPENSE").upper()
        debit_account_id = int(body["debit_account_id"])
        credit_account_id = int(body["credit_account_id"])

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            validator = PreLedgerValidator(conn)
            username = getattr(request.user, "username", "admin") if hasattr(request, "user") else "admin"
            rule_id = validator.add_rule(
                transaction_type=transaction_type,
                debit_account_id=debit_account_id,
                credit_account_id=credit_account_id,
                amount_sign=body.get("amount_sign", "POSITIVE"),
                priority=body.get("priority", 100),
                valid_from=body.get("valid_from", "2024-01-01"),
                valid_to=body.get("valid_to"),
                created_by=username,
            )
            logger.info("[ADMIN] Ledger rule created id=%s type=%s by=%s",
                        rule_id, transaction_type, username)

            # NATS hot-reload event
            try:
                import nats
                nc = await nats.connect(AppConfig().nats_url)
                await nc.publish(
                    "ledger.rules.updated",
                    msgspec_dumps_bytes({"rule_id": rule_id, "action": "created"}),
                )
                await nc.close()
            except Exception as pub_err:
                logger.warning("[ADMIN] Failed to publish NATS event: %s", pub_err)

            return {"status": "ok", "rule_id": rule_id}
        finally:
            conn.close()

    @delete("/ledger-rules/{rule_id:str}", guards=[requires_permission("admin:ledger")])
    async def delete_ledger_rule(self, rule_id: str, request: Request) -> dict:
        """Deactivate a ledger validation rule (soft-delete via valid_to)."""
        import duckdb

        from services.pre_ledger_validator import PreLedgerValidator

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            validator = PreLedgerValidator(conn)
            validator.delete_rule(rule_id)

            # NATS hot-reload event
            try:
                import nats
                nc = await nats.connect(AppConfig().nats_url)
                await nc.publish(
                    "ledger.rules.updated",
                    msgspec_dumps_bytes({"rule_id": rule_id, "action": "deprecated"}),
                )
                await nc.close()
            except Exception as pub_err:
                logger.warning("[ADMIN] Failed to publish NATS event: %s", pub_err)

            return {"status": "ok", "rule_id": rule_id, "action": "deprecated"}
        finally:
            conn.close()

    # ── Fallback Events admin endpoints ─────────────────────────────────

    @get("/fallback-events", guards=[requires_permission("admin:fallback")])
    async def list_fallback_events(self, request: Request) -> dict:
        """List fallback events (no-matching-rule incidents)."""
        import duckdb

        from services.fallback_handler import FallbackHandler

        status_filter = request.query_params.get("status")
        limit = int(request.query_params.get("limit", "50"))
        offset = int(request.query_params.get("offset", "0"))

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            handler = FallbackHandler(conn)
            events = handler.list_events(
                status_filter=status_filter if status_filter else None,
                limit=limit,
                offset=offset,
            )
            pending = handler.count_pending()
            return {"events": events, "total": len(events), "pending": pending}
        finally:
            conn.close()

    @post("/fallback-events/{event_id:str}/resolve", guards=[requires_permission("admin:fallback")])
    async def resolve_fallback_event(self, event_id: str, request: Request) -> dict:
        """Resolve a fallback event."""
        import duckdb

        from services.fallback_handler import FallbackHandler

        body = await request.json() if request.content_length else {}
        resolution_note = body.get("resolution_note", "Resolved via admin panel")

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            handler = FallbackHandler(conn)
            username = getattr(request.user, "username", "admin") if hasattr(request, "user") else "admin"
            ok = handler.resolve(event_id, resolution_note=resolution_note, assigned_to=username)
            if not ok:
                raise NotFoundException(detail=f"Fallback event not found or already resolved: {event_id}")
            return {"status": "ok", "event_id": event_id, "action": "resolved"}
        finally:
            conn.close()

    # ── Integrity Verification admin endpoint ─────────────────────────

    @post("/audit/verify-integrity", guards=[requires_permission("admin:audit")])
    async def verify_integrity(self, request: Request) -> dict:
        """Verify integrity of the decision trace hash chain.

        Runs full verification of all decision_traces entries.
        If violations are found, they are persisted to integrity_violations
        and the system may be locked.

        Body (optional):
            handle_violation: bool (default True) — auto-persist violation
            system_lock: bool (default False) — lock system on violation
            incremental: bool (default False) — incremental verification
        """
        import duckdb

        from services.integrity_verifier import IntegrityVerifier

        body = await request.json() if request.content_length else {}
        handle_violation = body.get("handle_violation", True)
        system_lock = body.get("system_lock", False)
        incremental = body.get("incremental", False)

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            verifier = IntegrityVerifier(conn)

            if incremental:
                report = verifier.verify_incremental()
            else:
                report = verifier.verify_all()

            result = {
                "status": report.status,
                "total_records": report.total_records,
                "verified_at": report.verified_at,
                "violations": [],
                "violation_id": None,
                "system_locked": False,
                "checkpoint": None,
            }

            if report.status == "violation" and report.violations:
                # Limit violations in response to first 10
                result["violations"] = report.violations[:10]
                result["first_inconsistent_trace"] = report.first_inconsistent_trace

                if handle_violation:
                    violation_id = verifier.handle_violation(report)
                    result["violation_id"] = violation_id
                    logger.critical(
                        "[ADMIN] Integrity violation detected id=%s trace=%s",
                        violation_id, report.first_inconsistent_trace,
                    )

                    if system_lock:
                        verifier.system_lock(lock=True)
                        result["system_locked"] = True

            # Include checkpoint info
            cp = verifier.get_latest_checkpoint()
            if cp:
                result["checkpoint"] = cp

            return result
        finally:
            conn.close()

    @post("/fallback-events/{event_id:str}/ignore", guards=[requires_permission("admin:fallback")])
    async def ignore_fallback_event(self, event_id: str, request: Request) -> dict:
        """Ignore a fallback event."""
        import duckdb

        from services.fallback_handler import FallbackHandler

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            handler = FallbackHandler(conn)
            ok = handler.ignore(event_id)
            if not ok:
                raise NotFoundException(detail=f"Fallback event not found or already resolved: {event_id}")
            return {"status": "ok", "event_id": event_id, "action": "ignored"}
        finally:
            conn.close()

    # ── Hot-Reload Health endpoint ───────────────────────────────────────

    @get("/hot-reload/health", guards=[requires_permission("admin:hot-reload")])
    async def hot_reload_health(self, request: Request) -> dict:
        """Show NATS hot-reload listener status and per-subject event counts.

        Returns:
            status: "connected" | "disconnected"
            nats_url: Configured NATS URL
            subscriptions: List of subscribed rule topics
            events_total: Total events received since startup
            events_per_subject: Per-subject event counts
            last_event_at: Per-subject last event timestamp (ISO)
            uptime_seconds: Seconds since listener started

        The listener is created during API startup (on_startup).
        If NATS was unavailable at startup, status will be "disconnected".
        """
        listener = getattr(request.app.state, "hot_reload_listener", None)
        if listener is None:
            return {
                "status": "not_initialized",
                "nats_url": "",
                "subscriptions": [],
                "events_total": 0,
                "events_per_subject": {},
                "last_event_at": None,
                "uptime_seconds": 0.0,
                "message": "HotReloadListener was not initialized during API startup",
            }

        health = listener.health()
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
        now = pendulum.now("UTC").isoformat()
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
