"""Autopilot API endpoints — decision history, trust scores, and user actions."""

from __future__ import annotations

from typing import Any

from litestar import Controller, get, post
from litestar.background_tasks import BackgroundTask
from litestar.connection import Request
from litestar.response import Response as LitestarResponse

from nexus_ai.api.background_tasks import emit_decision_and_notification_bg
from nexus_ai.api.dto import (
    AutopilotActionDTO,
    AutopilotDecisionDTO,
    AutopilotDecisionsDTO,
    AutopilotEvalTriggerDTO as AutopilotEvalTriggerResponseDTO,
    AutopilotStatsDTO,
    AutopilotTriggerDTO,
    AutopilotTrustScoreDTO,
    TAG_SYSTEM,
)
from nexus_ai.core.config import AppConfig
from nexus_ai.services.decision_logger import DecisionLogger
from nexus_ai.services.notification_service import NotificationService
from structlog import get_logger as _get_logger

logger = _get_logger("nexus.api.autopilot")


class AutopilotController(Controller):
    """Autopilot — endpoints for viewing and managing AI decisions.

    Provides:
      - Decision history and details
      - Trust score trends per contractor
      - Accept / reject actions for pending decisions
      - Autopilot statistics and health
    """

    path = "/autopilot"
    tags = [TAG_SYSTEM]

    @get(
        "/decisions",
        return_dto=AutopilotDecisionsDTO,
        summary="List autopilot decisions",
        description="Returns recent Autopilot decisions with cursor pagination (Rozwiązanie 32). Includes decision, trust score, level, and timestamp.",
        operation_id="listAutopilotDecisions",
    )
    async def list_decisions(
        self,
        config: AppConfig,
        request: Request,
        limit: int = 50,
        cursor: str | None = None,
    ) -> dict:
        """Return the most recent Autopilot decisions with cursor pagination (Rozwiązanie 32).

        Query params:
          - limit (int, default 50, max 200): max number of decisions to return.
          - cursor (str, optional): token paginacji z poprzedniej odpowiedzi.

        Returns dict with items, next_cursor, has_more.
        Each item: invoice_id, decision, trust_score, level, pattern, timestamp.

        Uses DecisionLogger.get_decision_summary() which queries DuckDB (not SQLite)
        and supports keyset cursor pagination on (timestamp, invoice_id).
        """
        try:
            from api.services import CursorPagination
            from db.analytics import DuckDBManager
            from services.decision_logger import DecisionLogger

            safe_limit = max(1, min(int(limit), 200))
            mgr = DuckDBManager(
                db_path=config.duckdb_path,
                sqlite_path=config.sqlite_path,
                read_only=True,
            )
            try:
                logger = DecisionLogger(mgr)
                # get_decision_summary queries DuckDB with cursor pagination
                items = await logger.get_decision_summary(
                    limit=safe_limit + 1,  # +1 dla detection has_more
                )

                if not items:
                    return {"items": [], "next_cursor": None, "has_more": False}

                has_more = len(items) > safe_limit
                if has_more:
                    items = items[:safe_limit]

                next_cursor = CursorPagination.build_next_cursor(
                    items, date_key="timestamp", id_key="invoice_id"
                )

                # Serializuj Struct items do dict (DTO wymaga dict/serializable)
                return {
                    "items": [
                        {
                            "invoice_id": item.invoice_id,
                            "decision": item.decision,
                            "trust_score": item.trust_score,
                            "level": item.level,
                            "pattern": item.pattern,
                            "timestamp": item.timestamp,
                        }
                        for item in items
                    ],
                    "next_cursor": next_cursor,
                    "has_more": has_more,
                }
            finally:
                mgr.close()
        except Exception:
            return {"items": [], "next_cursor": None, "has_more": False}

    @get(
        "/decisions/{invoice_id:str}",
        return_dto=AutopilotDecisionDTO,
        summary="Get decision detail",
        description="Returns full decision details for a specific invoice, including alpha/beta/gamma verdicts and trust components.",
        operation_id="getAutopilotDecisionDetail",
    )
    async def get_decision_detail(
        self,
        invoice_id: str,
        config: AppConfig,
    ) -> dict[str, Any]:
        """Return full decision details for a specific invoice.

        Includes alpha/beta/gamma verdicts, trust components,
        decision pattern, and PLE context.
        Returns 404-like empty dict if not found.
        """
        try:
            from db.analytics import DuckDBManager

            mgr = DuckDBManager(
                db_path=config.duckdb_path,
                sqlite_path=config.sqlite_path,
                read_only=True,
            )
            try:
                logger = DecisionLogger(mgr)
                decisions = await logger.get_decisions_for_invoice(invoice_id)
                if decisions:
                    return decisions[0]
                return {"error": "not_found", "invoice_id": invoice_id}
            finally:
                mgr.close()
        except Exception:
            return {"error": "query_failed", "invoice_id": invoice_id}

    @post(
        "/decisions/{invoice_id:str}/accept",
        return_dto=AutopilotActionDTO,
        summary="Accept a decision",
        description="Accepts a pending Autopilot decision, updates invoice status to APPROVED with optimistic locking.",
        operation_id="acceptAutopilotDecision",
    )
    async def accept_decision(
        self,
        invoice_id: str,
        config: AppConfig,
        request: Request,
    ) -> dict[str, Any]:
        """Accept (approve) a pending Autopilot decision.

        Records user correction (accepted) in DecisionLogger,
        updates invoice status to APPROVED, and sends notification.
        """
        try:
            from sqlalchemy import text

            from db.analytics import DuckDBManager
            from db.database import create_oltp_engine, create_session_factory

            # 1. Record user correction in DecisionLogger
            mgr = DuckDBManager(
                db_path=config.duckdb_path,
                sqlite_path=config.sqlite_path,
            )
            try:
                logger = DecisionLogger(mgr)
                await logger.record_user_correction(invoice_id, "ACCEPTED")
            finally:
                mgr.close()

            # 2. Update invoice status to APPROVED with optimistic locking
            engine = create_oltp_engine(config)
            session_factory = create_session_factory(engine)
            try:
                async with session_factory() as session:
                    # Najpierw pobierz aktualną wersję
                    from sqlalchemy import select as sa_select

                    from nexus_ai.db.models import Invoice

                    result = await session.execute(
                        sa_select(Invoice.version_id).where(Invoice.id == invoice_id)
                    )
                    row = result.scalar_one_or_none()
                    if row is None:
                        return {
                            "result": "ERROR",
                            "invoice_id": invoice_id,
                            "error": "Invoice not found",
                        }

                    # Aktualizuj z weryfikacją wersji (optimistic locking)
                    result = await session.execute(
                        text(
                            "UPDATE invoices SET status = 'APPROVED', updated_at = CURRENT_TIMESTAMP, "
                            "version_id = version_id + 1 WHERE id = :id AND version_id = :version"
                        ),
                        {"id": invoice_id, "version": row},
                    )
                    if result.rowcount == 0:
                        return {
                            "result": "CONFLICT",
                            "invoice_id": invoice_id,
                            "error": "Conflict: invoice was modified by another user",
                        }
                    await session.commit()
            finally:
                await engine.dispose()

            # ── Background tasks (fire-and-forget) ─────────────────────
            event_emitter = getattr(request.app.state, "event_emitter", None)
            notif_db = config.base_dir / "app_data" / "notifications.sqlite"
            service = NotificationService(notif_db)
            user_id = str(getattr(request.user, "id", "system"))

            background_tasks = BackgroundTask(
                emit_decision_and_notification_bg,
                event_emitter=event_emitter,
                notification_service=service,
                invoice_id=invoice_id,
                original_decision="AUTO_POST",
                user_decision="ACCEPTED",
                user_id=user_id,
                metadata={"source": "autopilot", "action": "accept"},
                notification_title="Decyzja zaakceptowana ✅",
            )

            return LitestarResponse(
                content={"result": "OK", "invoice_id": invoice_id, "action": "ACCEPTED"},
                background=background_tasks if event_emitter else None,
            )

        except Exception as exc:
            return {"result": "ERROR", "invoice_id": invoice_id, "error": str(exc)}

    @post(
        "/decisions/{invoice_id:str}/reject",
        return_dto=AutopilotActionDTO,
        summary="Reject a decision",
        description="Rejects a pending Autopilot decision, updates invoice status to REJECTED with optimistic locking.",
        operation_id="rejectAutopilotDecision",
    )
    async def reject_decision(
        self,
        invoice_id: str,
        config: AppConfig,
        request: Request,
    ) -> dict[str, Any]:
        """Reject (block) a pending Autopilot decision.

        Records user correction (rejected) in DecisionLogger,
        updates invoice status to REJECTED, and sends notification.
        """
        try:
            from sqlalchemy import text

            from db.analytics import DuckDBManager
            from db.database import create_oltp_engine, create_session_factory

            # 1. Record user correction
            mgr = DuckDBManager(
                db_path=config.duckdb_path,
                sqlite_path=config.sqlite_path,
            )
            try:
                logger = DecisionLogger(mgr)
                await logger.record_user_correction(invoice_id, "REJECTED")
            finally:
                mgr.close()

            # 2. Update invoice status with optimistic locking
            engine = create_oltp_engine(config)
            session_factory = create_session_factory(engine)
            try:
                async with session_factory() as session:
                    # Najpierw pobierz aktualną wersję
                    from sqlalchemy import select as sa_select

                    from nexus_ai.db.models import Invoice

                    result = await session.execute(
                        sa_select(Invoice.version_id).where(Invoice.id == invoice_id)
                    )
                    row = result.scalar_one_or_none()
                    if row is None:
                        return {
                            "result": "ERROR",
                            "invoice_id": invoice_id,
                            "error": "Invoice not found",
                        }

                    # Aktualizuj z weryfikacją wersji (optimistic locking)
                    result = await session.execute(
                        text(
                            "UPDATE invoices SET status = 'REJECTED', updated_at = CURRENT_TIMESTAMP, "
                            "version_id = version_id + 1 WHERE id = :id AND version_id = :version"
                        ),
                        {"id": invoice_id, "version": row},
                    )
                    if result.rowcount == 0:
                        return {
                            "result": "CONFLICT",
                            "invoice_id": invoice_id,
                            "error": "Conflict: invoice was modified by another user",
                        }
                    await session.commit()
            finally:
                await engine.dispose()

            # ── Background tasks (fire-and-forget) ─────────────────────
            event_emitter = getattr(request.app.state, "event_emitter", None)
            notif_db = config.base_dir / "app_data" / "notifications.sqlite"
            service = NotificationService(notif_db)
            user_id = str(getattr(request.user, "id", "system"))

            background_tasks = BackgroundTask(
                emit_decision_and_notification_bg,
                event_emitter=event_emitter,
                notification_service=service,
                invoice_id=invoice_id,
                original_decision="AUTO_POST",
                user_decision="REJECTED",
                user_id=user_id,
                metadata={"source": "autopilot", "action": "reject"},
                notification_title="Decyzja odrzucona ❌",
            )

            return LitestarResponse(
                content={"result": "OK", "invoice_id": invoice_id, "action": "REJECTED"},
                background=background_tasks if event_emitter else None,
            )

        except Exception as exc:
            return {"result": "ERROR", "invoice_id": invoice_id, "error": str(exc)}

    @get(
        "/trust-score/{contractor_nip:str}",
        return_dto=AutopilotTrustScoreDTO,
        summary="Get trust score trend",
        description="Returns trust score trend for a specific contractor (NIP) over the specified lookback window.",
        operation_id="getTrustScoreTrend",
    )
    async def get_trust_score_trend(
        self,
        contractor_nip: str,
        config: AppConfig,
        days: int = 30,
    ) -> dict[str, Any]:
        """Return trust score trend for a specific contractor (NIP).

        Query params:
          - days (int, default 30): lookback window in days.

        Returns avg/min/max trust score, trend direction,
        component averages, and decision breakdown.
        """
        try:
            from db.analytics import DuckDBManager

            mgr = DuckDBManager(
                db_path=config.duckdb_path,
                sqlite_path=config.sqlite_path,
                read_only=True,
            )
            try:
                logger = DecisionLogger(mgr)
                return await logger.get_trust_score_trend(
                    contractor_nip=contractor_nip,
                    days=days,
                )
            finally:
                mgr.close()
        except Exception:
            return {"known": False, "records": 0, "avg_trust": 0.0}

    @get(
        "/stats",
        return_dto=AutopilotStatsDTO,
        summary="Get autopilot statistics",
        description="Returns overall Autopilot statistics including decision count, correction rate, and type breakdown.",
        operation_id="getAutopilotStats",
    )
    async def get_autopilot_stats(
        self,
        config: AppConfig,
    ) -> dict[str, Any]:
        """Return overall Autopilot statistics.

        Includes:
          - total_decisions: total decisions made
          - decisions_by_type: breakdown by decision type
          - correction_rate: user correction rate
          - level_breakdown: breakdown by decision level
          - total_corrected: total corrected decisions

        All data comes from DecisionLogger (decisions table).
        """
        try:
            from db.analytics import DuckDBManager

            mgr = DuckDBManager(
                db_path=config.duckdb_path,
                sqlite_path=config.sqlite_path,
                read_only=True,
            )
            try:
                logger = DecisionLogger(mgr)
                return await logger.get_user_correction_stats()
            finally:
                mgr.close()
        except Exception:
            return {
                "total_decisions": 0,
                "total_corrected": 0,
                "correction_rate": 0.0,
                "decision_breakdown": {},
                "level_breakdown": {},
                "correction_breakdown": [],
            }

    @post(
        "/evaluate",
        dto=AutopilotTriggerDTO,
        return_dto=AutopilotEvalTriggerResponseDTO,
        summary="Trigger evaluation",
        description="Manually triggers Autopilot evaluation for an invoice via NATS task queue.",
        operation_id="triggerAutopilotEvaluation",
    )
    async def trigger_evaluation(
        self,
        config: AppConfig,
        request: Request,
    ) -> dict[str, Any]:
        """Manually trigger Autopilot evaluation for an invoice.

        Request body:
          {
            "invoice_id": "...",
            "extracted_data": { ... }
          }

        Triggers the decision_evaluate NATS task.
        """
        from litestar.exceptions import ClientException

        body: dict[str, Any] | None = None
        try:
            body = await request.json()
        except Exception:
            raise ClientException("Invalid JSON body")

        if not body or "invoice_id" not in body:
            raise ClientException("Missing invoice_id in request body")

        invoice_id = body["invoice_id"]
        extracted_data = body.get("extracted_data", {})

        try:
            from api.tasks import broker

            await broker.kick(
                "decision_evaluate",
                invoice_id=invoice_id,
                extracted_data=extracted_data,
            )
            return {
                "result": "OK",
                "invoice_id": invoice_id,
                "message": "Decision evaluation triggered",
            }
        except Exception as exc:
            return {
                "result": "ERROR",
                "invoice_id": invoice_id,
                "error": str(exc),
            }


