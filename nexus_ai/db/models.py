"""
SQLModel definitions for core OLTP tables.

Zastępuje: SQLAlchemy declarative_base + Column (stary styl)
Nowy:     SQLModel Field-based — jedna definicja dla bazy i API

Zgodnie z aa3fvcx.txt:
- SQLModel łączy SQLAlchemy + Pydantic w jednej klasie
- Zero duplikacji kodu między modelem DB a modelem API
- Idealna integracja z Litestar i msgspec
"""
from __future__ import annotations

import uuid
import pendulum
from typing import Optional

from sqlmodel import Field, SQLModel


# ── Eksport Base dla kompatybilności z Alembic (migrations/env.py) ──────────
# SQLModel dziedziczy po SQLAlchemy, więc metadata jest zgodna.
from sqlmodel import SQLModel as _SQLModelType
Base = _SQLModelType


class AuditLog(SQLModel, table=True):
    """Audit trail for all changes made to invoices."""
    __tablename__ = "audit_logs"  # type: ignore[assignment]

    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True)
    invoice_id: Optional[str] = Field(default=None, foreign_key="invoices.id", index=True)

    # Kto dokonał zmiany (np. "System/OCR" lub "Księgowa_Kasia")
    user_id: str = Field(default="System")

    # Co zmieniono (np. "amount_net")
    field_changed: Optional[str] = Field(default=None)

    # Historia (przechowywana jako tekst, nawet dla liczb)
    old_value: Optional[str] = Field(default=None)
    new_value: Optional[str] = Field(default=None)

    timestamp: Optional[datetime] = Field(default_factory=lambda: pendulum.now("UTC"))


class OutboxEvent(SQLModel, table=True):
    """Transactional outbox events for guaranteed delivery."""
    __tablename__ = "outbox_events"  # type: ignore[assignment]

    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True)
    event_type: str = Field(nullable=False)
    aggregate_id: str = Field(nullable=False)
    payload: str = Field(nullable=False)  # JSON string
    status: str = Field(default="PENDING")
    processed: bool = Field(default=False)
    created_at: Optional[datetime] = Field(default_factory=lambda: pendulum.now("UTC"))


class SecurityAlert(SQLModel, table=True):
    """Security events (RBAC violations, suspicious access)."""
    __tablename__ = "security_alerts"  # type: ignore[assignment]

    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True)
    actor: str = Field(nullable=False)
    operation: str = Field(nullable=False)
    details: str = Field(nullable=False)  # JSON string
    created_at: Optional[datetime] = Field(default_factory=lambda: pendulum.now("UTC"))


class UserAccount(SQLModel, table=True):
    """User accounts for authentication and authorization."""
    __tablename__ = "users"  # type: ignore[assignment]

    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True)
    username: str = Field(unique=True, nullable=False, index=True)
    password_hash: str = Field(nullable=False)
    role: str = Field(nullable=False, default="worker")
    tenant_id: str = Field(nullable=False, default="default")
    is_active: bool = Field(nullable=False, default=True)
    created_at: Optional[datetime] = Field(default_factory=lambda: pendulum.now("UTC"))
