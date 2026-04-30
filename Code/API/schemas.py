from __future__ import annotations
import msgspec
from pydantic import BaseModel, ConfigDict
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

class VatSummary(msgspec.Struct):
    """Zagregowane dane analityczne z DuckDB."""
    month: str
    total_net: Decimal
    total_gross: Decimal
    currency: str


# -- Pydantic Models --

class TaskResponse(BaseModel):
    task_id: str
    status: str
    message: str

class InvoiceResponsePydantic(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    number: str | None
    contractor_nip: str | None
    amount_net: float | None
    amount_gross: float | None
    currency: str | None
    status: str
    created_at: datetime
    updated_at: datetime

class DashboardSummaryResponse(BaseModel):
    total_net: float
    total_gross: float
    total_documents: int


class TriageItem(BaseModel):
    invoice_id: str
    image_path: str
    extracted_data: dict[str, object]
    bounding_boxes: dict[str, object]
    confidence_score: float
    reason_for_triage: str


class TriageResolutionRequest(BaseModel):
    corrected_data: dict[str, object]
    action: str


class TriageResolutionResponse(BaseModel):
    invoice_id: str
    status: str
    message: str
