from __future__ import annotations
import msgspec
from decimal import Decimal
from datetime import datetime
from uuid import UUID
from typing import Optional

# -- msgspec Structs --

class InvoiceCreate(msgspec.Struct):
    """Dane wymagane przy ręcznym tworzeniu lub uploadzie faktury."""
    number: str
    contractor_nip: str
    file_path: str = ""
    amount_net: Decimal = Decimal("0.0")
    amount_gross: Decimal = Decimal("0.0")
    currency: str = "PLN"
    issue_date: str = ""


def validate_invoice_create(payload: InvoiceCreate) -> None:
    if payload.amount_net < 0:
        raise ValueError("amount_net cannot be negative")
    if payload.amount_gross < 0:
        raise ValueError("amount_gross cannot be negative")
    if not payload.currency or len(payload.currency.strip()) != 3:
        raise ValueError("currency must be a 3-letter code")

class InvoiceResponse(msgspec.Struct):
    """Struktura zwracana do frontendu."""
    id: str
    number: str | None
    amount_net: Decimal
    amount_gross: Decimal
    currency: str
    status: str # NEW, PROCESSING, APPROVED
    created_at: datetime

class AnalyticsQuery(msgspec.Struct):
    start_date: str
    end_date: str
    dimension: str = "monthly"
    report_currency: str = "PLN"

class VatSummary(msgspec.Struct):
    """Zagregowane dane analityczne z DuckDB."""
    month: str
    total_net: Decimal
    total_gross: Decimal
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


class TriageResolutionResponse(msgspec.Struct):
    invoice_id: str
    status: str
    message: str
