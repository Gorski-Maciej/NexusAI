"""
SQLModel definitions for core OLTP tables.

Zgodnie z aa3fvcx.txt:
- SQLModel łączy SQLAlchemy + Pydantic w jednej klasie
- Zero duplikacji kodu między modelem DB a modelem API
- Idealna integracja z Litestar i msgspec

Ta definicja zastępuje starą strukturę rozproszonych modeli (models/invoice.py,
models/outbox.py, models/audit.py, models/contractor.py) — wszystkie modele
są teraz w jednym pliku.
"""

from __future__ import annotations

import uuid
from decimal import Decimal

import pendulum
from enum import StrEnum as BaseStrEnum

import pendulum
from pydantic import ConfigDict
from sqlmodel import Field, SQLModel

# ── Eksport Base dla kompatybilności z Alembic (migrations/env.py) ──────────
# SQLModel dziedziczy po SQLAlchemy, więc metadata jest zgodna.
from sqlmodel import SQLModel as _SQLModelType

Base = _SQLModelType


class OutboxStatus(BaseStrEnum):
    """Statusy zdarzeń outbox.

    StrEnum dziedziczy już po str, więc nie trzeba jawnie dodawać str jako bazy.
    """

    PENDING = "PENDING"
    PROCESSING = "PROCESSING"
    PROCESSED = "PROCESSED"
    SENT = "SENT"
    FAILED = "FAILED"
    DEAD_LETTER = "DEAD_LETTER"


# ── Models ──────────────────────────────────────────────────────────────────


class Invoice(SQLModel, table=True):
    """Faktura — główny model biznesowy."""

    __tablename__ = "invoices"  # type: ignore[assignment]
    model_config = ConfigDict(arbitrary_types_allowed=True)

    id: str = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    number: str | None = Field(default=None, index=True)
    contractor_nip: str | None = Field(default=None, index=True)
    file_path: str | None = Field(default=None)
    amount_net: Decimal | None = Field(default=None, max_digits=18, decimal_places=2)
    amount_gross: Decimal | None = Field(default=None, max_digits=18, decimal_places=2)
    currency: str = Field(default="PLN", max_length=3)
    status: str = Field(default="NEW", index=True)
    retry_count: int = Field(default=0)
    processing_status: str | None = Field(default=None)
    issue_date: str | None = Field(default=None)
    created_at: pendulum.DateTime = Field(default_factory=lambda: pendulum.now("UTC"))
    updated_at: pendulum.DateTime = Field(
        default_factory=lambda: pendulum.now("UTC"),
        sa_column_kwargs={"onupdate": lambda: pendulum.now("UTC")},
    )


class ActiveLearningPattern(SQLModel, table=True):
    """Wzorce aktywnego uczenia — korekty użytkownika dla AI."""

    __tablename__ = "active_learning_patterns"  # type: ignore[assignment]
    model_config = ConfigDict(arbitrary_types_allowed=True)

    id: str = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    contractor_id: str = Field(nullable=False, index=True)
    correction_payload: str = Field(nullable=False)  # JSON string
    created_at: pendulum.DateTime = Field(default_factory=lambda: pendulum.now("UTC"))


class Contractor(SQLModel, table=True):
    """Kontrahenci."""

    __tablename__ = "contractors"  # type: ignore[assignment]
    model_config = ConfigDict(arbitrary_types_allowed=True)

    id: str = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    nip: str = Field(unique=True, nullable=False, index=True)
    name: str | None = Field(default=None)
    vat_status: str | None = Field(default=None)
    created_at: pendulum.DateTime = Field(default_factory=lambda: pendulum.now("UTC"))


class AuditLog(SQLModel, table=True):
    """Audit trail for all changes made to invoices."""

    __tablename__ = "audit_logs"  # type: ignore[assignment]
    model_config = ConfigDict(arbitrary_types_allowed=True)

    id: str = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    invoice_id: str | None = Field(default=None, foreign_key="invoices.id", index=True)
    action: str | None = Field(default=None)
    user_id: str = Field(default="System")
    field_changed: str | None = Field(default=None)
    old_value: str | None = Field(default=None)
    new_value: str | None = Field(default=None)
    changes: str | None = Field(default=None)  # JSON string (dla AuditService)
    timestamp: pendulum.DateTime = Field(default_factory=lambda: pendulum.now("UTC"))


class OutboxEvent(SQLModel, table=True):
    """Transactional outbox events for guaranteed delivery."""

    __tablename__ = "outbox_events"  # type: ignore[assignment]
    model_config = ConfigDict(arbitrary_types_allowed=True)

    id: str = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    event_type: str = Field(nullable=False)
    aggregate_id: str = Field(nullable=False)
    payload: str = Field(nullable=False)  # JSON string
    status: str = Field(default="PENDING")
    processed: bool = Field(default=False)
    processing_started_at: pendulum.DateTime | None = Field(default=None)
    processed_at: pendulum.DateTime | None = Field(default=None)
    retry_count: int = Field(default=0)
    created_at: pendulum.DateTime = Field(default_factory=lambda: pendulum.now("UTC"))


class SecurityAlert(SQLModel, table=True):
    """Security events (RBAC violations, suspicious access)."""

    __tablename__ = "security_alerts"  # type: ignore[assignment]
    model_config = ConfigDict(arbitrary_types_allowed=True)

    id: str = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    actor: str = Field(nullable=False)
    operation: str = Field(nullable=False)
    details: str = Field(nullable=False)  # JSON string
    created_at: pendulum.DateTime = Field(default_factory=lambda: pendulum.now("UTC"))


class UserAccount(SQLModel, table=True):
    """User accounts for authentication and authorization."""

    __tablename__ = "users"  # type: ignore[assignment]
    model_config = ConfigDict(arbitrary_types_allowed=True)

    id: str = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    username: str = Field(unique=True, nullable=False, index=True)
    password_hash: str = Field(nullable=False)
    role: str = Field(nullable=False, default="worker")
    tenant_id: str = Field(nullable=False, default="default")
    is_active: bool = Field(nullable=False, default=True)
    jwt_version: int = Field(default=1)
    created_at: pendulum.DateTime = Field(default_factory=lambda: pendulum.now("UTC"))
