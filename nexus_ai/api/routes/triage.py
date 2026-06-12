from __future__ import annotations

from litestar import Controller, get, post
from litestar.connection import Request
from litestar.exceptions import ClientException
from sqlalchemy.orm import Session

from nexus_ai.api.rbac import get_current_role, owner_only_guard
from nexus_ai.api.schemas import TriageItem, TriageResolutionRequest, TriageResolutionResponse
from nexus_ai.services.triage_service import list_pending_triage_items, resolve_triage_item


class TriageController(Controller):
    """Triage — przegląd i korekta faktur przed księgowaniem."""
    path = "/api/triage"
    tags = ["Triage"]


class TriageControllerV2(Controller):
    """Triage controller for /api/v2/triage (Rozwiązanie 22: wersjonowanie API)."""
    path = "/api/v2/triage"
    tags = ["Triage"]

    @get("/pending")
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

    @post("/resolve/{invoice_id:str}", guards=[owner_only_guard])
    def resolve(
        self,
        invoice_id: str,
        data: TriageResolutionRequest,
        db_session: Session,
        request: Request,
    ) -> TriageResolutionResponse:
        try:
            role_ctx = get_current_role(request)
            invoice = resolve_triage_item(
                db_session,
                invoice_id=invoice_id,
                corrected_data=data.corrected_data,
                action=data.action,
                updated_by=role_ctx.actor,
                tenant_id=str(getattr(request.user, "tenant_id", "default") or "default"),
                expected_version=data.expected_version,
            )
        except ValueError as exc:
            detail = str(exc)
            status_code = 409 if "version mismatch" in detail else 400
            raise ClientException(status_code=status_code, detail=detail) from exc

        if data.action == "confirm_post":
            message = "Corrected invoice approved; pending ledger entry can be posted"
        else:
            message = "Invoice was voided/rejected from triage"

        return TriageResolutionResponse(invoice_id=invoice.id, status=invoice.status, message=message)
