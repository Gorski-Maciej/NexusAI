from __future__ import annotations

from msgspec import Struct
from decimal import Decimal
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from nexus_ai.db.models import Invoice

TRIAGE_CONFIDENCE_THRESHOLD = 0.85


class TriageDecision(Struct):
    send_to_review: bool
    reason: str | None = None


def should_triage_document(
    *, confidence_score: float, amount_net: Decimal, amount_vat: Decimal, amount_gross: Decimal
) -> TriageDecision:
    """Core triage rule used by workers before posting accounting effects."""
    if confidence_score < TRIAGE_CONFIDENCE_THRESHOLD:
        return TriageDecision(send_to_review=True, reason="LOW_CONFIDENCE")

    if (amount_net + amount_vat).quantize(Decimal("0.01")) != amount_gross.quantize(
        Decimal("0.01")
    ):
        return TriageDecision(send_to_review=True, reason="MATH_MISMATCH")

    return TriageDecision(send_to_review=False)


def list_pending_triage_items(session: Session, *, tenant_id: str) -> list[Invoice]:
    stmt = (
        select(Invoice)
        .where(Invoice.status == "PENDING_REVIEW", Invoice.tenant_id == tenant_id)
        .order_by(Invoice.created_at.desc())
    )
    result = session.execute(stmt)
    return list(result.scalars().all())


def resolve_triage_item(
    session: Session,
    *,
    invoice_id: str,
    corrected_data: dict[str, Any],
    action: str,
    updated_by: str,
    tenant_id: str,
) -> Invoice:
    with session.begin():
        invoice = session.get(Invoice, invoice_id)
        if invoice is None:
            raise ValueError(f"Invoice {invoice_id} not found")
        if str(invoice.tenant_id) != str(tenant_id):
            raise ValueError("Cross-tenant access denied")

        if number := corrected_data.get("number"):
            invoice.number = str(number)
        if contractor_nip := corrected_data.get("contractor_nip"):
            invoice.contractor_nip = str(contractor_nip)
        if amount_net := corrected_data.get("amount_net"):
            invoice.amount_net = Decimal(str(amount_net))
        if amount_gross := corrected_data.get("amount_gross"):
            invoice.amount_gross = Decimal(str(amount_gross))

        if action == "confirm_post":
            invoice.status = "APPROVED"
        elif action == "void_reject":
            invoice.status = "REJECTED"
        else:
            raise ValueError("Unsupported triage action")

        invoice.updated_by = updated_by

    # SUPERMOC: session.refresh() po with session.begin()
    # Po wyjściu z ``with session.begin()``, sesja jest otwarta
    # (``begin()`` nie zamyka sesji, tylko kończy transakcję).
    # ``refresh()`` odświeża obiekt z bazy — działa poprawnie,
    # bo sesja nie jest zamknięta.
    # Jeśli sesja jest zamknięta (np. przez context manager),
    # użyj ``session.expire_all()`` przed odczytem.
    try:
        session.refresh(invoice)
    except Exception:
        # Jeśli sesja zamknięta, użyj expire_all jako fallback
        session.expire_all()
    return invoice
