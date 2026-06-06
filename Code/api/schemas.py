from __future__ import annotations

from datetime import datetime
from decimal import Decimal

import msgspec

from services.currency_converter import Money

# -- msgspec Structs --

class InvoiceCreate(msgspec.Struct):
    """Dane wymagane przy ręcznym tworzeniu lub uploadzie faktury.

    Uwaga: ``amount_net`` i ``amount_gross`` to ``Decimal`` (typ natywny msgspec),
    a nie ``Money`` — ponieważ to schema requestowa (dekodowana z JSON).
    Konwersja ``Decimal → Money`` następuje w kontrolerze.
    """
    number: str
    contractor_nip: str
    file_path: str = ""
    amount_net: Decimal = Decimal("0.0")
    amount_gross: Decimal = Decimal("0.0")
    currency: str = "PLN"
    issue_date: str = ""


def _validate_nip(nip: str) -> str:
    """Walidacja NIP: 10 cyfr + suma kontrolna.
    Zwraca znormalizowany NIP (tylko cyfry) lub rzuca ValueError."""
    normalized = "".join(ch for ch in str(nip) if ch.isdigit())
    if len(normalized) != 10:
        raise ValueError("NIP musi składać się z 10 cyfr.")

    weights = (6, 5, 7, 2, 3, 4, 5, 6, 7)
    checksum = sum(int(d) * w for d, w in zip(normalized[:9], weights)) % 11
    if checksum == 10 or checksum != int(normalized[9]):
        raise ValueError("Nieprawidłowy NIP (błąd sumy kontrolnej).")

    return normalized


def validate_invoice_create(payload: InvoiceCreate) -> None:
    if payload.amount_net < 0:
        raise ValueError("amount_net cannot be negative")
    if payload.amount_gross < 0:
        raise ValueError("amount_gross cannot be negative")
    if not payload.currency or len(payload.currency.strip()) != 3:
        raise ValueError("currency must be a 3-letter code")
    # Walidacja NIP przy tworzeniu faktury
    if payload.contractor_nip:
        try:
            _validate_nip(payload.contractor_nip)
        except ValueError as e:
            raise ValueError(f"contractor_nip validation failed: {e}")

class InvoiceResponse(msgspec.Struct):
    """Struktura zwracana do frontendu (response — ``Money`` serializowane przez enc_hook)."""
    id: str
    number: str | None
    amount_net: Money
    amount_gross: Money
    currency: str
    status: str # NEW, PROCESSING, APPROVED
    created_at: datetime
    version_id: int = 1  # Optimistic locking (Rozwiązanie 23)

class AnalyticsQuery(msgspec.Struct):
    start_date: str
    end_date: str
    dimension: str = "monthly"
    report_currency: str = "PLN"

class VatSummary(msgspec.Struct):
    """Zagregowane dane analityczne z DuckDB (response — ``Money`` serializowane przez enc_hook)."""
    month: str
    total_net: Money
    total_gross: Money
    currency: str


# -- API response/request structs --

class TaskResponse(msgspec.Struct):
    task_id: str
    status: str
    message: str

class InvoiceResponsePydantic(msgspec.Struct):
    id: str
    number: str | None
    contractor_nip: str | None
    amount_net: float | None
    amount_gross: float | None
    currency: str | None
    status: str
    created_at: datetime
    updated_at: datetime
    version_id: int = 1  # Optimistic locking (Rozwiązanie 23)

class DashboardSummaryResponse(msgspec.Struct):
    total_net: float
    total_gross: float
    total_documents: int


class TriageItem(msgspec.Struct):
    invoice_id: str
    image_path: str
    extracted_data: dict[str, object]
    bounding_boxes: dict[str, object]
    confidence_score: float
    reason_for_triage: str


class TriageResolutionRequest(msgspec.Struct):
    corrected_data: dict[str, object]
    action: str
    expected_version: int | None = None  # Optimistic locking (Rozwiązanie 23)


class TriageResolutionResponse(msgspec.Struct):
    invoice_id: str
    status: str
    message: str


class SagaTransitionRequest(msgspec.Struct):
    new_state: str
    expected_current_state: str | None = None
    payload: dict[str, object] = msgspec.field(default_factory=dict)


class SagaStateResponse(msgspec.Struct):
    status: str
    saga_id: str
    current_state: str
    updated_at: str
    payload: dict[str, object]
