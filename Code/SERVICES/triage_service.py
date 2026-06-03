from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.invoice import Invoice
from services.currency_converter import Money

TRIAGE_CONFIDENCE_THRESHOLD = 0.85


@dataclass(slots=True)
class TriageDecision:
    send_to_review: bool
    reason: str | None = None


def should_triage_document(*, confidence_score: float, amount_net: Money, amount_vat: Money, amount_gross: Money) -> TriageDecision:
    """Core triage rule used by workers before posting accounting effects."""
    if confidence_score < TRIAGE_CONFIDENCE_THRESHOLD:
        return TriageDecision(send_to_review=True, reason="LOW_CONFIDENCE")

    # Extract Decimal amounts from Money objects (or handle direct Decimal values)
    net = amount_net.amount if hasattr(amount_net, 'amount') else Decimal(str(amount_net))
    vat = amount_vat.amount if hasattr(amount_vat, 'amount') else Decimal(str(amount_vat))
    gross = amount_gross.amount if hasattr(amount_gross, 'amount') else Decimal(str(amount_gross))

    if (net + vat).quantize(Decimal("0.01")) != gross.quantize(Decimal("0.01")):
        return TriageDecision(send_to_review=True, reason="MATH_MISMATCH")

    return TriageDecision(send_to_review=False)


async def list_pending_triage_items(session: AsyncSession, *, tenant_id: str) -> list[Invoice]:
    stmt = select(Invoice).where(Invoice.status == "PENDING_REVIEW", Invoice.tenant_id == tenant_id).order_by(Invoice.created_at.desc())
    result = await session.execute(stmt)
    return list(result.scalars().all())


async def resolve_triage_item(
    session: AsyncSession,
    *,
    invoice_id: str,
    corrected_data: dict[str, Any],
    action: str,
    updated_by: str,
    tenant_id: str,
    expected_version: int | None = None,  # Optimistic locking (Rozwiązanie 23)
) -> Invoice:
    invoice = await session.get(Invoice, invoice_id)
    if invoice is None:
        raise ValueError(f"Invoice {invoice_id} not found")
    if str(invoice.tenant_id) != str(tenant_id):
        raise ValueError("Cross-tenant access denied")

    # Sprawdź zgodność wersji (optimistic locking)
    if expected_version is not None and invoice.version_id != expected_version:
        raise ValueError(
            f"Conflict: invoice {invoice_id} version mismatch. "
            f"Expected {expected_version}, current {invoice.version_id}"
        )

    if number := corrected_data.get("number"):
        invoice.number = str(number)
    if contractor_nip := corrected_data.get("contractor_nip"):
        invoice.contractor_nip = str(contractor_nip)
    if amount_net_val := corrected_data.get("amount_net"):
        if isinstance(amount_net_val, Money):
            invoice.amount_net = amount_net_val
        else:
            invoice.amount_net = Money(str(amount_net_val), "PLN")
    if amount_gross_val := corrected_data.get("amount_gross"):
        if isinstance(amount_gross_val, Money):
            invoice.amount_gross = amount_gross_val
        else:
            invoice.amount_gross = Money(str(amount_gross_val), "PLN")

    if action == "confirm_post":
        invoice.status = "APPROVED"
    elif action == "void_reject":
        invoice.status = "REJECTED"
    else:
        raise ValueError("Unsupported triage action")

    invoice.updated_by = updated_by

    await session.commit()
    await session.refresh(invoice)
    return invoice
