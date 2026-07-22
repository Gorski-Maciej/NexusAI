"""Admin endpoints for managing failed tasks (DLQ) and system configuration.

Endpoints:
- GET    /api/admin/failed-tasks          -- List failed tasks (paginated, filterable)
- POST   /api/admin/failed-tasks/{id}/retry  -- Retry a specific failed task
- DELETE /api/admin/failed-tasks/{id}        -- Delete a failed task entry
- POST   /api/admin/failed-tasks/retry-all   -- Retry all unresolved failed tasks
"""

from __future__ import annotations

import uuid

import msgspec
import pendulum
from litestar import Controller, delete, get, post, put
from litestar.connection import Request
from litestar.exceptions import NotFoundException, ValidationException
from litestar.response import Response
from sqlalchemy.ext.asyncio import AsyncEngine
from sqlmodel import text
from structlog import get_logger

from nexus_ai.api.dto import (
    TAG_ADMIN,
    ActionResponseDTO,
    ChangeRoleDTO,
    ChangeRoleResponseDTO,
    FailedTaskListDTO,
    FallbackListDTO,
    GenericDictDTO,
    HealthResponseDTO,
    HotReloadHealthDTO,
    IdResponseDTO,
    IntegrityVerifyDTO,
    PaginatedRuleListDTO,
    ReplayBatchDTO,
    ReplayDecisionDTO,
    RetryAllResponseDTO,
    RiskThresholdDTO,
    RuleChangelogDTO,
    RuleListResponseDTO,
    StatusResponseDTO,
)
from nexus_ai.api.rbac import admin_only_guard, requires_permission, log_rbac_change
from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.services.admin_services import (
    BillingRuleService as BillingRuleAdminSvc,
)
from nexus_ai.services.admin_services import (
    FailedTaskService as FailedTaskAdminSvc,
)
from nexus_ai.services.admin_services import (
    FallbackEventService as FallbackEventAdminSvc,
)
from nexus_ai.services.admin_services import (
    IntegrityService as IntegrityAdminSvc,
)
from nexus_ai.services.admin_services import (
    LedgerRuleService as LedgerRuleAdminSvc,
)
from nexus_ai.services.admin_services import (
    ReplayService as ReplayAdminSvc,
)
from nexus_ai.services.admin_services import (
    RiskThresholdService as RiskThresholdAdminSvc,
)
from nexus_ai.services.admin_services import (
    TaxRuleService as TaxRuleAdminSvc,
)


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
    """Panel administracyjny -- zarządzanie użytkownikami, regułami, DLQ."""

    path = "/admin"
    guards = (admin_only_guard,)
    tags = (TAG_ADMIN,)

    @get(
        "/failed-tasks",
        guards=[requires_permission("admin:failed-tasks")],
        return_dto=FailedTaskListDTO,
        summary="List failed tasks",
        description="List all failed tasks with pagination and filtering by resolved status and task name.",
        operation_id="listFailedTasks",
    )
    async def list_failed_tasks(self, request: Request, db_engine: AsyncEngine) -> dict:
        resolved_raw = request.query_params.get("resolved")
        resolved_filter: bool | None = (
            resolved_raw.lower() in ("true", "1", "yes") if resolved_raw is not None else None
        )
        return await FailedTaskAdminSvc.list_failed_tasks(
            db_engine=db_engine,
            resolved_filter=resolved_filter,
            task_name_filter=request.query_params.get("task_name"),
            limit=int(request.query_params.get("limit", "50")),
            offset=int(request.query_params.get("offset", "0")),
        )

    @post(
        "/failed-tasks/{task_id:str}/retry",
        guards=[requires_permission("admin:failed-tasks")],
        return_dto=StatusResponseDTO,
        summary="Retry failed task",
        description="Reset a failed task and re-queue it for retry.",
        operation_id="retryFailedTask",
    )
    async def retry_failed_task(
        self, task_id: str, request: Request, db_engine: AsyncEngine
    ) -> Response[dict]:
        user = getattr(request, "user", None)
        username = getattr(user, "username", "system") if user else "system"
        ok = await FailedTaskAdminSvc.retry_task(db_engine, task_id, username=username)
        if not ok:
            raise NotFoundException(
                detail=f"Failed task not found or already resolved: {task_id}"
            )
        logger.info("Task %s re-queued for retry by %s", task_id, username)
        return Response(
            content={"status": "ok", "message": f"Task {task_id} queued for retry"},
            status_code=200,
        )

    @delete(
        "/failed-tasks/{task_id:str}",
        status_code=200,
        guards=[requires_permission("admin:failed-tasks")],
        return_dto=StatusResponseDTO,
        summary="Delete failed task",
        description="Permanently delete a failed task entry.",
        operation_id="deleteFailedTask",
    )
    async def delete_failed_task(
        self, task_id: str, request: Request, db_engine: AsyncEngine
    ) -> Response[dict]:
        ok = await FailedTaskAdminSvc.delete_task(db_engine, task_id)
        if not ok:
            raise NotFoundException(detail=f"Failed task not found: {task_id}")
        logger.info("Failed task %s deleted by admin", task_id)
        return Response(
            content={"status": "ok", "message": f"Task {task_id} deleted"},
            status_code=200,
        )

    @post(
        "/failed-tasks/retry-all",
        guards=[requires_permission("admin:failed-tasks")],
        return_dto=RetryAllResponseDTO,
        summary="Retry all failed tasks",
        description="Retry all unresolved failed tasks in bulk.",
        operation_id="retryAllFailedTasks",
    )
    async def retry_all_failed_tasks(self, request: Request, db_engine: AsyncEngine) -> dict:
        user = getattr(request, "user", None)
        username = getattr(user, "username", "system") if user else "system"
        retried = await FailedTaskAdminSvc.retry_all(db_engine, username=username)
        logger.info("Bulk retry: %d tasks re-queued by %s", retried, username)
        return {"status": "ok", "retried": retried}

    @put(
        "/users/{user_id:str}/role",
        guards=[requires_permission("user:edit")],
        dto=ChangeRoleDTO,
        return_dto=ChangeRoleResponseDTO,
        summary="Change user role",
        description="Change a user's role. Valid roles: admin, accountant, auditor, viewer.",
        operation_id="changeUserRole",
    )
    async def change_user_role(
        self, user_id: str, data: ChangeRoleRequest, request: Request, db_engine: AsyncEngine
    ) -> Response[dict]:
        valid_roles = {"admin", "accountant", "auditor", "viewer"}
        new_role = data.role.strip().lower()

        if new_role not in valid_roles:
            raise ValidationException(
                detail=f"Invalid role: {new_role}. Valid roles: {', '.join(sorted(valid_roles))}"
            )

        actor = getattr(request, "user", None)
        actor_name = getattr(actor, "username", "system") if actor else "system"

        async with db_engine.begin() as conn:
            # Check user exists
            user_row = (
                (
                    await conn.execute(
                        text("SELECT id, username, role FROM users WHERE id = :id LIMIT 1"),
                        {"id": user_id},
                    )
                )
                .mappings()
                .first()
            )

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
                (
                    await conn.execute(
                        text("SELECT id, name FROM roles WHERE name = :name LIMIT 1"),
                        {"name": new_role},
                    )
                )
                .mappings()
                .first()
            )

            if role_row:
                # Remove all existing role assignments
                await conn.execute(
                    text("DELETE FROM user_roles WHERE user_id = :uid"),
                    {"uid": user_id},
                )
                # Add new role assignment
                await conn.execute(
                    text("INSERT INTO user_roles (id, user_id, role_id) VALUES (:id, :uid, :rid)"),
                    {"id": uuid.uuid4().hex, "uid": user_id, "rid": role_row["id"]},
                )

            # Log to RBAC audit (v7.0 Security Audit)
            log_rbac_change(
                user_id=user_id,
                changed_by=actor_name,
                old_role=old_role,
                new_role=new_role,
                reason=f"Role changed by admin {actor_name}",
            )

            # Log to database audit (inside the same transaction)
            await conn.execute(
                text(
                    """INSERT INTO audit_logs (id, user_id, action, old_value, new_value, timestamp, created_at)
                       VALUES (:id, :uid, 'ROLE_CHANGE', :old_val, :new_val, :now, :now)"""
                ),
                {
                    "id": uuid.uuid4().hex,
                    "uid": user_id,
                    "old_val": msgspec_dumps({"role": old_role, "changed_by": actor_name}),
                    "new_val": msgspec_dumps({"role": new_role}),
                    "now": now,
                },
            )

        # Transaction auto-committed by begin() context manager

        logger.info(
            "Role changed for user '%s' (%s): %s -> %s by %s",
            username,
            user_id,
            old_role,
            new_role,
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

    # ── Risk Thresholds admin endpoints ────────────────────────────────

    @get(
        "/risk-thresholds",
        guards=[requires_permission("admin:risk-thresholds")],
        return_dto=RuleListResponseDTO,
        summary="List risk thresholds",
        description="List all active risk threshold rules.",
        operation_id="listRiskThresholds",
    )
    async def list_risk_thresholds(self, request: Request) -> dict:
        """List all active risk threshold rules."""
        rules = RiskThresholdAdminSvc.list()
        return {"rules": rules, "total": len(rules)}

    @post(
        "/risk-thresholds",
        guards=[requires_permission("admin:risk-thresholds")],
        dto=RiskThresholdDTO,
        return_dto=IdResponseDTO,
        summary="Create risk threshold",
        description="Create a new risk threshold rule (append-only, never update). Requires condition and output dicts.",
        operation_id="createRiskThreshold",
    )
    async def create_risk_threshold(self, data: RiskThresholdCreate, request: Request) -> dict:
        username = getattr(request.user, "username", "admin") if hasattr(request, "user") else "admin"
        rule_id = RiskThresholdAdminSvc.create(
            condition=data.condition,
            output=data.output,
            valid_from=data.valid_from,
            valid_to=data.valid_to,
            priority=data.priority,
            created_by=username,
        )
        logger.info("[ADMIN] Risk threshold created id=%s by=%s", rule_id, username)
        RiskThresholdAdminSvc.publish(rule_id, "created")
        return {"status": "ok", "rule_id": rule_id}

    @get(
        "/system/health",
        return_dto=HealthResponseDTO,
        summary="System health check",
        description="Comprehensive system health check including database, failed tasks, and system status.",
        operation_id="adminSystemHealth",
    )
    async def system_health(self, request: Request, db_engine: AsyncEngine) -> dict:

        health = {
            "status": "ok",
            "timestamp": pendulum.now("UTC").isoformat(),
        }

        # Check database
        try:
            async with db_engine.connect() as conn:
                await conn.execute(text("SELECT 1"))
            health["database"] = "connected"
        except Exception as e:
            health["database"] = f"error: {e}"
            health["status"] = "degraded"

        # Check failed tasks count
        try:
            async with db_engine.connect() as conn:
                count = (
                    await conn.execute(text("SELECT COUNT(*) FROM failed_tasks WHERE resolved = 0"))
                ).scalar()
            health["failed_tasks_unresolved"] = count or 0
        except Exception as exc:
            logger.debug("Failed to query failed_tasks count: %s", exc)

        return health

    @put(
        "/risk-thresholds/{rule_id:str}/deprecate",
        guards=[requires_permission("admin:risk-thresholds")],
        return_dto=ActionResponseDTO,
        summary="Deprecate risk threshold",
        description="Deactivate a risk threshold rule by setting valid_to = today.",
        operation_id="deprecateRiskThreshold",
    )
    async def deprecate_risk_threshold(self, rule_id: str, request: Request) -> dict:
        username = getattr(request.user, "username", "admin") if hasattr(request, "user") else "admin"
        ok = RiskThresholdAdminSvc.deprecate(rule_id, created_by=username)
        if not ok:
            raise NotFoundException(
                detail=f"Risk threshold rule not found or already deprecated: {rule_id}"
            )
        logger.info("[ADMIN] Risk threshold deprecated id=%s by=%s", rule_id, username)
        RiskThresholdAdminSvc.publish(rule_id, "deprecated")
        return {"status": "ok", "rule_id": rule_id, "action": "deprecated"}

    @get(
        "/risk-thresholds/history",
        guards=[requires_permission("admin:risk-thresholds")],
        return_dto=RuleListResponseDTO,
        summary="List risk thresholds history",
        description="Full version history of all risk threshold rules (append-only).",
        operation_id="listRiskThresholdsHistory",
    )
    async def list_risk_thresholds_history(self, request: Request) -> dict:
        rules = RiskThresholdAdminSvc.history()
        return {"rules": rules, "total": len(rules)}

    # ── Billing Rules admin endpoints ───────────────────────────────────

    @get(
        "/billing-rules",
        guards=[requires_permission("admin:billing-rules")],
        return_dto=RuleListResponseDTO,
        summary="List billing rules",
        description="List all active billing rules.",
        operation_id="listBillingRules",
    )
    async def list_billing_rules(self, request: Request) -> dict:
        rules = BillingRuleAdminSvc.list(active_only=True)
        return {"rules": rules, "total": len(rules)}

    @post(
        "/billing-rules",
        guards=[requires_permission("admin:billing-rules")],
        return_dto=IdResponseDTO,
        summary="Create billing rule",
        description="Create a new billing rule (append-only, never update).",
        operation_id="createBillingRule",
    )
    async def create_billing_rule(self, request: Request) -> dict:
        body = await request.json()
        rule_id = BillingRuleAdminSvc.create(
            condition=body.get("condition", {}),
            price=body.get("price", {}),
            valid_from=body.get("valid_from", "2024-01-01"),
            valid_to=body.get("valid_to"),
            priority=body.get("priority", 100),
        )
        logger.info("[ADMIN] Billing rule created id=%s", rule_id)
        BillingRuleAdminSvc.publish(rule_id, "created")
        return {"status": "ok", "rule_id": rule_id}

    @post(
        "/billing-rules/{rule_id:str}/deprecate",
        guards=[requires_permission("admin:billing-rules")],
        return_dto=ActionResponseDTO,
        summary="Deprecate billing rule",
        description="Deactivate a billing rule.",
        operation_id="deprecateBillingRule",
    )
    async def deprecate_billing_rule(self, rule_id: str, request: Request) -> dict:
        ok = BillingRuleAdminSvc.deprecate(rule_id)
        if not ok:
            raise NotFoundException(detail=f"Billing rule not found: {rule_id}")
        logger.info("[ADMIN] Billing rule deprecated id=%s", rule_id)
        BillingRuleAdminSvc.publish(rule_id, "deprecated")
        return {"status": "ok", "rule_id": rule_id, "action": "deprecated"}

    @get(
        "/billing-rules/history",
        guards=[requires_permission("admin:billing-rules")],
        return_dto=RuleListResponseDTO,
        summary="List billing rules history",
        description="Full version history of all billing rules (append-only).",
        operation_id="listBillingRulesHistory",
    )
    async def list_billing_rules_history(self, request: Request) -> dict:
        rules = BillingRuleAdminSvc.list(active_only=False)
        return {"rules": rules, "total": len(rules)}

    # ── Replay Engine admin endpoint ────────────────────────────────────

    @post(
        "/audit/replay/{transaction_id:str}",
        guards=[requires_permission("admin:audit")],
        return_dto=ReplayDecisionDTO,
        summary="Replay decision",
        description="Replay a historical tax decision and compare verdicts.",
        operation_id="replayDecision",
    )
    async def replay_decision(self, transaction_id: str, request: Request) -> dict:
        return ReplayAdminSvc.replay(transaction_id)

    @post(
        "/audit/replay-batch",
        guards=[requires_permission("admin:audit")],
        return_dto=ReplayBatchDTO,
        summary="Replay batch decisions",
        description="Replay all decisions in a date range.",
        operation_id="replayBatch",
    )
    async def replay_batch(self, request: Request) -> dict:
        body = await request.json()
        return ReplayAdminSvc.replay_batch(
            period_start=body.get("period_start", "2024-01-01"),
            period_end=body.get("period_end", pendulum.now("UTC").format("YYYY-MM-DD")),
            limit=int(body.get("limit", 1000)),
        )

    # ── Rules admin endpoints ───────────────────────────────────────────

    @get(
        "/rules",
        guards=[requires_permission("admin:rules")],
        return_dto=PaginatedRuleListDTO,
        summary="List tax rules",
        description="List all tax rules with optional filtering.",
        operation_id="listTaxRules",
    )
    async def list_rules(self, request: Request) -> dict:
        active_only = request.query_params.get("active_only", "false").lower() in ("true", "1")
        limit = int(request.query_params.get("limit", "100"))
        offset = int(request.query_params.get("offset", "0"))
        rules, total = TaxRuleAdminSvc.list(
            active_only=active_only,
            limit=limit,
            offset=offset,
            date_filter=request.query_params.get("date"),
        )
        return {"rules": rules, "total": total, "limit": limit, "offset": offset}

    @post(
        "/rules",
        guards=[requires_permission("admin:rules")],
        return_dto=IdResponseDTO,
        summary="Create tax rule",
        description="Create a new tax rule (append-only, never update). Requires condition_sql.",
        operation_id="createTaxRule",
    )
    async def create_rule(self, request: Request) -> dict:
        body = await request.json()
        condition_sql = body.get("condition_sql")
        if not condition_sql:
            raise ValidationException(detail="condition_sql is required")

        username = getattr(request.user, "username", "admin") if hasattr(request, "user") else "admin"
        rule_id = TaxRuleAdminSvc.create(
            condition_sql=condition_sql,
            action=body.get("action", {}),
            valid_from=body.get("valid_from", "2024-01-01"),
            valid_to=body.get("valid_to"),
            priority=body.get("priority", 100),
            description_template=body.get("description_template"),
            created_by=username,
        )
        logger.info("[ADMIN] Tax rule created id=%s by=%s", rule_id, username)
        TaxRuleAdminSvc.publish(rule_id, "created")
        return {"status": "ok", "rule_id": rule_id}

    @post(
        "/rules/{rule_id:str}/close",
        guards=[requires_permission("admin:rules")],
        return_dto=ActionResponseDTO,
        summary="Close tax rule",
        description="Close a tax rule (set valid_to to today).",
        operation_id="closeTaxRule",
    )
    async def close_rule(self, rule_id: str, request: Request) -> dict:
        body = await request.json() if request.content_length else {}
        username = getattr(request.user, "username", "admin") if hasattr(request, "user") else "admin"
        ok = TaxRuleAdminSvc.close(
            rule_id,
            valid_to=body.get("valid_to"),
            closed_by=username,
        )
        if not ok:
            raise NotFoundException(detail=f"Rule not found or already closed: {rule_id}")
        logger.info("[ADMIN] Tax rule closed id=%s by=%s", rule_id, username)
        TaxRuleAdminSvc.publish(rule_id, "closed")
        return {"status": "ok", "rule_id": rule_id, "action": "closed"}

    @get(
        "/rules/{rule_id:str}",
        guards=[requires_permission("admin:rules")],
        return_dto=GenericDictDTO,
        summary="Get tax rule",
        description="Get a single tax rule by ID.",
        operation_id="getTaxRule",
    )
    async def get_rule(self, rule_id: str, request: Request) -> dict:
        rule = TaxRuleAdminSvc.get(rule_id)
        if not rule:
            raise NotFoundException(detail=f"Rule not found: {rule_id}")
        return rule

    @get(
        "/rules/changelog",
        guards=[requires_permission("admin:rules")],
        return_dto=RuleChangelogDTO,
        summary="List rule changes",
        description="Get tax rule change log.",
        operation_id="listRuleChanges",
    )
    async def list_rule_changes(self, request: Request) -> dict:
        changes = TaxRuleAdminSvc.changelog(
            rule_id=request.query_params.get("rule_id"),
            limit=int(request.query_params.get("limit", "50")),
        )
        return {"changes": changes, "total": len(changes)}

    # ── Ledger Validation Rules admin endpoints ────────────────────────

    @get(
        "/ledger-rules",
        guards=[requires_permission("admin:ledger")],
        return_dto=RuleListResponseDTO,
        summary="List ledger rules",
        description="List all ledger validation rules.",
        operation_id="listLedgerRules",
    )
    async def list_ledger_rules(self, request: Request) -> dict:
        """List all ledger validation rules."""
        rules = LedgerRuleAdminSvc.list()
        return {"rules": rules, "total": len(rules)}

    @post(
        "/ledger-rules",
        guards=[requires_permission("admin:ledger")],
        return_dto=IdResponseDTO,
        summary="Create ledger rule",
        description="Create a new ledger validation rule (append-only).",
        operation_id="createLedgerRule",
    )
    async def create_ledger_rule(self, request: Request) -> dict:
        """Create a new ledger validation rule (append-only)."""
        body = await request.json()
        username = getattr(request.user, "username", "admin") if hasattr(request, "user") else "admin"

        rule_id = LedgerRuleAdminSvc.create(
            transaction_type=body.get("transaction_type", "EXPENSE"),
            debit_account_id=int(body["debit_account_id"]),
            credit_account_id=int(body["credit_account_id"]),
            amount_sign=body.get("amount_sign", "POSITIVE"),
            priority=body.get("priority", 100),
            valid_from=body.get("valid_from", "2024-01-01"),
            valid_to=body.get("valid_to"),
            created_by=username,
        )
        logger.info("[ADMIN] Ledger rule created id=%s by=%s", rule_id, username)
        LedgerRuleAdminSvc.publish(rule_id, "created")
        return {"status": "ok", "rule_id": rule_id}

    @delete(
        "/ledger-rules/{rule_id:str}",
        guards=[requires_permission("admin:ledger")],
        return_dto=ActionResponseDTO,
        summary="Delete ledger rule",
        description="Deactivate a ledger validation rule (soft-delete via valid_to).",
        operation_id="deleteLedgerRule",
    )
    async def delete_ledger_rule(self, rule_id: str, request: Request) -> dict:
        """Deactivate a ledger validation rule (soft-delete via valid_to)."""
        LedgerRuleAdminSvc.delete(rule_id)
        LedgerRuleAdminSvc.publish(rule_id, "deprecated")
        return {"status": "ok", "rule_id": rule_id, "action": "deprecated"}

    # ── Fallback Events admin endpoints ─────────────────────────────────

    @get(
        "/fallback-events",
        guards=[requires_permission("admin:fallback")],
        return_dto=FallbackListDTO,
        summary="List fallback events",
        description="List fallback events (no-matching-rule incidents).",
        operation_id="listFallbackEvents",
    )
    async def list_fallback_events(self, request: Request) -> dict:
        """List fallback events (no-matching-rule incidents)."""
        status_filter = request.query_params.get("status")
        limit = int(request.query_params.get("limit", "50"))
        offset = int(request.query_params.get("offset", "0"))
        events, pending = FallbackEventAdminSvc.list(
            status_filter=status_filter or None,
            limit=limit,
            offset=offset,
        )
        return {"events": events, "total": len(events), "pending": pending}

    @post(
        "/fallback-events/{event_id:str}/resolve",
        guards=[requires_permission("admin:fallback")],
        return_dto=ActionResponseDTO,
        summary="Resolve fallback event",
        description="Resolve a fallback event.",
        operation_id="resolveFallbackEvent",
    )
    async def resolve_fallback_event(self, event_id: str, request: Request) -> dict:
        """Resolve a fallback event."""
        body = await request.json() if request.content_length else {}
        username = getattr(request.user, "username", "admin") if hasattr(request, "user") else "admin"

        ok = FallbackEventAdminSvc.resolve(
            event_id,
            resolution_note=body.get("resolution_note", "Resolved via admin panel"),
            assigned_to=username,
        )
        if not ok:
            raise NotFoundException(
                detail=f"Fallback event not found or already resolved: {event_id}"
            )
        return {"status": "ok", "event_id": event_id, "action": "resolved"}

    # ── Integrity Verification admin endpoint ─────────────────────────

    @post(
        "/audit/verify-integrity",
        guards=[requires_permission("admin:audit")],
        return_dto=IntegrityVerifyDTO,
        summary="Verify integrity",
        description="Verify integrity of the decision trace hash chain.",
        operation_id="verifyIntegrity",
    )
    async def verify_integrity(self, request: Request) -> dict:
        """Verify integrity of the decision trace hash chain.

        Runs full verification of all decision_traces entries.
        If violations are found, they are persisted to integrity_violations
        and the system may be locked.

        Body (optional):
            handle_violation: bool (default True) -- auto-persist violation
            system_lock: bool (default False) -- lock system on violation
            incremental: bool (default False) -- incremental verification
        """
        body = await request.json() if request.content_length else {}

        result = IntegrityAdminSvc.verify(
            handle_violation=body.get("handle_violation", True),
            system_lock=body.get("system_lock", False),
            incremental=body.get("incremental", False),
        )

        if result.get("violations"):
            logger.critical(
                "[ADMIN] Integrity violation detected id=%s trace=%s",
                result.get("violation_id"),
                result.get("first_inconsistent_trace"),
            )

        return result

    @post(
        "/fallback-events/{event_id:str}/ignore",
        guards=[requires_permission("admin:fallback")],
        return_dto=ActionResponseDTO,
        summary="Ignore fallback event",
        description="Ignore a fallback event without resolving.",
        operation_id="ignoreFallbackEvent",
    )
    async def ignore_fallback_event(self, event_id: str, request: Request) -> dict:
        """Ignore a fallback event."""
        ok = FallbackEventAdminSvc.ignore(event_id)
        if not ok:
            raise NotFoundException(
                detail=f"Fallback event not found or already resolved: {event_id}"
            )
        return {"status": "ok", "event_id": event_id, "action": "ignored"}

    # ── Hot-Reload Health endpoint ───────────────────────────────────────

    @get(
        "/hot-reload/health",
        guards=[requires_permission("admin:hot-reload")],
        return_dto=HotReloadHealthDTO,
        summary="Hot-reload health",
        description="Show NATS hot-reload listener status and per-subject event counts.",
        operation_id="getHotReloadHealth",
    )
    async def hot_reload_health(self, request: Request) -> dict:
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


async def _republish_task(db_engine, task_name: str, payload: str) -> None:
    """Re-publish a task to the appropriate queue for retry.

    This is a simplified implementation. In production, this would
    send the task back to NATS/Taskiq for reprocessing.
    """
    # Store a new outbox event for the retry
    async with db_engine.connect() as conn:
        event_id = uuid.uuid4().hex
        now = pendulum.now("UTC").isoformat()
        await conn.execute(
            text(
                """INSERT INTO outbox_events (id, event_type, aggregate_id, payload, status, processed, created_at)
                   VALUES (:id, :event_type, :aggregate_id, :payload, 'PENDING', 0, :created_at)"""
            ),
            {
                "id": event_id,
                "event_type": f"retry:{task_name}",
                "aggregate_id": uuid.uuid4().hex,
                "payload": payload,
                "created_at": now,
            },
        )
        await conn.commit()
