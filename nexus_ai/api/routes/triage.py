from __future__ import annotations


import anyio

from litestar import Controller, get, post
from litestar.background_tasks import BackgroundTask
from litestar.connection import Request
from litestar.exceptions import ClientException
from litestar.response import Response as LitestarResponse
from sqlmodel import Session
from structlog import get_logger

from nexus_ai.api.dto import (
    TAG_TRIAGE,
    TriageItemDTO,
    TriageResolutionDTO,
    TriageResponseDTO,
)
from nexus_ai.api.rbac import get_current_role, owner_only_guard
from nexus_ai.api.schemas import TriageItem, TriageResolutionRequest, TriageResolutionResponse
from nexus_ai.services.triage_service import list_pending_triage_items, resolve_triage_item
from nexus_ai.api.background_tasks import emit_decision_overridden_bg

logger = get_logger("nexus.api.triage")


class TriageController(Controller):
    """Triage — przegląd i korekta faktur przed księgowaniem."""

    path = "/triage"
    tags = [TAG_TRIAGE]

    @get(
        "/pending",
        return_dto=TriageItemDTO,
        summary="List pending triage items",
        description=(
            "Returns a list of invoices requiring manual review before posting. "
            "Items are flagged by the RiskGuard or Autopilot with low confidence scores. "
            "Includes extracted data fields and bounding boxes for UI rendering."
        ),
        operation_id="listPendingTriage",
    )
    def get_pending(self, db_session: Session, request: Request) -> list[TriageItem]:
        tenant_id = str(getattr(request.user, "tenant_id", "default") or "default")
        pending = list_pending_triage_items(db_session, tenant_id=tenant_id)
        return [
            TriageItem(
                invoice_id=item.id,
                image_path=item.file_path,
                extracted_data={
                    "number": item.number,
                    "contractor_nip": item.contractor_nip,
                    "amount_net": float(item.amount_net),
                    "amount_gross": float(item.amount_gross),
                },
                bounding_boxes={},
                confidence_score=0.0,
                reason_for_triage="PENDING_REVIEW",
            )
            for item in pending
        ]

    @post(
        "/resolve/{invoice_id:str}",
        guards=[owner_only_guard],
        dto=TriageResolutionDTO,
        return_dto=TriageResponseDTO,
        summary="Resolve a triage item",
        description=(
            "Accepts a corrected invoice or rejects it. "
            "When ``action=confirm_post``, the corrected data is saved and the invoice "
            "is queued for posting. When ``action=void``, the invoice is rejected. "
            "Uses optimistic locking via ``expected_version`` (Rozwiązanie 23)."
        ),
        operation_id="resolveTriageItem",
    )
    async def resolve(
        self,
        invoice_id: str,
        data: TriageResolutionRequest,
        db_session: Session,
        request: Request,
    ) -> TriageResolutionResponse:
        try:
            role_ctx = get_current_role(request)
            invoice = await anyio.to_thread.run_sync(
                lambda: resolve_triage_item(
                    db_session,
                    invoice_id=invoice_id,
                    corrected_data=data.corrected_data,
                    action=data.action,
                    updated_by=role_ctx.actor,
                    tenant_id=str(getattr(request.user, "tenant_id", "default") or "default"),
                    expected_version=data.expected_version,
                )
            )
        except ValueError as exc:
            detail = str(exc)
            status_code = 409 if "version mismatch" in detail else 400
            raise ClientException(status_code=status_code, detail=detail) from exc

        if data.action == "confirm_post":
            message = "Corrected invoice approved; pending ledger entry can be posted"
        else:
            message = "Invoice was voided/rejected from triage"

        # ── Emit DecisionOverridden event (fire-and-forget via BackgroundTask) ──
        user_decision = "CONFIRM_POST" if data.action == "confirm_post" else "VOID"

        return LitestarResponse(
            content=TriageResolutionResponse(
                invoice_id=invoice.id, status=invoice.status, message=message
            ),
            background=BackgroundTask(
                emit_decision_overridden_bg,
                invoice_id=invoice_id,
                original_decision="SUGGEST",
                user_decision=user_decision,
                user_id=str(getattr(request.user, "id", "system")),
                metadata={
                    "source": "triage",
                    "action": data.action,
                },
            ),
        )
