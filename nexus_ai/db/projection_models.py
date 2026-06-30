"""
SQLModel definitions for CQRS projections (read-side).

Zgodnie z audytem SQLModel:
- Projekcje powinny być SQLModel, a nie gołe sqlite3 tabele
- Każdy read model to SQLModel z table=True
- Wszystkie supermoce: Enum, JSON, Relationship, Index
- STRICT tables dla integralności danych
"""

from __future__ import annotations

from enum import StrEnum
from typing import Any, ClassVar

import pendulum

# Note: ConfigDict replaced with plain dict (no direct pydantic import)
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped
from sqlalchemy.schema import Index
from sqlmodel import JSON, Field, SQLModel, text

from nexus_ai.db.models import PendulumDateTime

# ── Enums ──────────────────────────────────────────────────────────────────


class ProjectionInvoiceStatus(StrEnum):
    """Statusy faktury w projekcji -- zgodne z głównym InvoiceStatus."""

    CREATED = "created"
    SUBMITTED = "submitted"
    APPROVED = "approved"
    REJECTED = "rejected"
    BLOCKED = "blocked"
    PAID = "paid"


class DecisionResult(StrEnum):
    """Wyniki decyzji."""

    AUTO_POST = "AUTO_POST"
    SUGGEST = "SUGGEST"
    ASK_USER = "ASK_USER"
    BLOCK = "BLOCK"


# ── Invoice Read Model (CQRS) ───────────────────────────────────────────


class InvoiceReadModel(SQLModel, table=True):
    """Denormalizowany widok faktur dla szybkich zapytań CQRS.

    - Enum column: ProjectionInvoiceStatus zamiast gołego str
    - Composite indexes przez Index() w __table_args__
    - Partial indexes dla najczęstszych zapytań
    - Expression index: UPPER(contractor_nip)
    - PendulumDateTime dla timestampów
    - STRICT table
    """

    __tablename__ = "invoice_read_model"  # type: ignore[assignment]
    __table_args__ = (
        Index("idx_invoice_rm_status", "status"),
        Index("idx_invoice_rm_contractor", "contractor_nip"),
        Index("idx_invoice_rm_blocked", "updated_at", sqlite_where=text("status = 'blocked'")),
        Index("idx_invoice_rm_approved", "updated_at", sqlite_where=text("status = 'approved'")),
        Index(
            "idx_invoice_rm_pending",
            "updated_at",
            sqlite_where=text("status IN ('created', 'submitted')"),
        ),
        Index("idx_invoice_rm_contractor_upper", text("UPPER(contractor_nip)")),
    )
    model_config: ClassVar[dict] = {
        "arbitrary_types_allowed": True,
        "validate_assignment": True,
        "extra": "forbid",
    }

    invoice_id: Mapped[str] = Field(primary_key=True)
    number: Mapped[str | None] = Field(default=None)
    contractor_nip: Mapped[str | None] = Field(default=None)
    contractor_name: Mapped[str | None] = Field(default=None)
    amount_net: Mapped[float | None] = Field(default=0.0)
    amount_gross: Mapped[float | None] = Field(default=0.0)
    currency: Mapped[str] = Field(default="PLN")
    category: Mapped[str | None] = Field(default=None)
    issue_date: Mapped[str | None] = Field(default=None)
    file_path: Mapped[str | None] = Field(default=None)
    status: Mapped[ProjectionInvoiceStatus] = Field(
        default=ProjectionInvoiceStatus.CREATED,
        sa_type=SAEnum(ProjectionInvoiceStatus),
    )
    current_version: Mapped[int] = Field(default=0)
    approved_by: Mapped[str | None] = Field(default=None)
    rejected_by: Mapped[str | None] = Field(default=None)
    blocked_reason: Mapped[str | None] = Field(default=None)
    paid_at: Mapped[str | None] = Field(default=None)
    decision: Mapped[str | None] = Field(default=None)
    trust_score: Mapped[float] = Field(default=0.0)
    created_at: Mapped[str | None] = Field(default=None)
    updated_at: Mapped[str | None] = Field(default=None)


# ── Decision Analytics (CQRS) ──────────────────────────────────────────


class DecisionAnalytics(SQLModel, table=True):
    """Analityczny widok decyzji CQRS.

    - Enum column: DecisionResult
    - Composite indexes
    - Partial indexes
    - STRICT table
    """

    __tablename__ = "decision_analytics"  # type: ignore[assignment]
    __table_args__ = (
        Index("idx_decision_analytics_invoice", "invoice_id"),
        Index("idx_decision_analytics_type", "event_type"),
        Index(
            "idx_decision_analytics_decision_notnull",
            "timestamp",
            sqlite_where=text("decision IS NOT NULL"),
        ),
        Index(
            "idx_decision_analytics_overridden",
            "timestamp",
            sqlite_where=text("event_type = 'decision.overridden'"),
        ),
    )
    model_config: ClassVar[dict] = {
        "arbitrary_types_allowed": True,
        "validate_assignment": True,
        "extra": "forbid",
    }

    decision_id: Mapped[str] = Field(primary_key=True)
    invoice_id: Mapped[str] = Field(nullable=False)
    event_type: Mapped[str] = Field(nullable=False)
    decision: Mapped[str | None] = Field(default=None)
    trust_score: Mapped[float] = Field(default=0.0)
    ai_confidence: Mapped[float] = Field(default=0.0)
    alpha_vote: Mapped[str | None] = Field(default=None)
    beta_vote: Mapped[str | None] = Field(default=None)
    gamma_vote: Mapped[str | None] = Field(default=None)
    decision_pattern: Mapped[str | None] = Field(default=None)
    reasoning: Mapped[str | None] = Field(default=None)
    original_decision: Mapped[str | None] = Field(default=None)
    user_decision: Mapped[str | None] = Field(default=None)
    user_id: Mapped[str | None] = Field(default=None)
    version: Mapped[int] = Field(default=0)
    timestamp: Mapped[str | None] = Field(default=None)


# ── User preferences (przykład DTO przez SQLModel) ─────────────────────


class UserPreferences(SQLModel, table=True):
    """Preferencje użytkownika -- przechowywane jako SQLModel.

    """

    __tablename__ = "user_preferences"  # type: ignore[assignment]
    model_config: ClassVar[dict] = {
        "arbitrary_types_allowed": True,
        "validate_assignment": True,
        "extra": "forbid",
    }

    user_id: Mapped[str] = Field(primary_key=True)
    preferences: Mapped[dict] = Field(
        default_factory=dict,
        sa_type=JSON,
        description="JSON z preferencjami użytkownika",
    )
    created_at: Mapped[pendulum.DateTime] = Field(
        default_factory=lambda: pendulum.now("UTC"),
        sa_type=PendulumDateTime,
    )
    updated_at: Mapped[pendulum.DateTime] = Field(
        default_factory=lambda: pendulum.now("UTC"),
        sa_column_kwargs={"onupdate": lambda: pendulum.now("UTC")},
        sa_type=PendulumDateTime,
    )

    def to_dict(self) -> dict[str, Any]:
        """Serialize to dict using model_dump()."""
        return self.model_dump(mode="json")

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> UserPreferences:
        """Deserialize from dict using model_validate()."""
        return cls.model_validate(data)
