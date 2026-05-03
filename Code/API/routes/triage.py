from __future__ import annotations

from litestar import Controller, get, post
from litestar.connection import Request
from litestar.exceptions import ClientException
from sqlalchemy.ext.asyncio import AsyncSession

from api.rbac import get_current_role, owner_only_guard
from api.schemas import TriageItem, TriageResolutionRequest, TriageResolutionResponse
from services.triage_service import list_pending_triage_items, resolve_triage_item


class TriageController(Controller):
    path = "/api/triage"

    @get("/pending")
    async def get_pending(self, db_session: AsyncSession, request: Request) -> list[TriageItem]:
        tenant_id = str(getattr(request.user, "tenant_id", "default") or "default")
        pending = await list_pending_triage_items(db_session, tenant_id=tenant_id)
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
    async def resolve(
        self,
        invoice_id: str,
        data: TriageResolutionRequest,
        db_session: AsyncSession,
        request: Request,
    ) -> TriageResolutionResponse:
        try:
            role_ctx = get_current_role(request)
            invoice = await resolve_triage_item(
                db_session,
                invoice_id=invoice_id,
                corrected_data=data.corrected_data,
                action=data.action,
                updated_by=role_ctx.actor,
                tenant_id=str(getattr(request.user, "tenant_id", "default") or "default"),
            )
        except ValueError as exc:
            raise ClientException(status_code=400, detail=str(exc)) from exc

        if data.action == "confirm_post":
            message = "Corrected invoice approved; pending ledger entry can be posted"
        else:
            message = "Invoice was voided/rejected from triage"

        return TriageResolutionResponse(invoice_id=invoice.id, status=invoice.status, message=message)
