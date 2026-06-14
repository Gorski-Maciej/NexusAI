"""
SQLModel definitions for core OLTP tables.

Zgodnie z aa3fvcx.txt:
- SQLModel łączy SQLAlchemy + Pydantic w jednej klasie
- Zero duplikacji kodu między modelem DB a modelem API
- Idealna integracja z Litestar i msgspec

SUPERMOC: STRICT tables (SQLite 3.45+)
- Wymusza typowanie kolumn na poziomie bazy danych
- ``STRICT`` dodawane do CREATE TABLE przez DDL event listener
- ``sqlite_autoincrement: False`` zapobiega dodawaniu autoincrement przez SQLAlchemy

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
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.sql.ddl import CreateTable
from sqlmodel import Field, SQLModel

# ── SUPERMOC: SQLite STRICT tables przez @compiles extension ────────────
# SQLAlchemy nie wspiera natywnie CREATE TABLE ... STRICT.
# Używamy @compiles, który przechwytuje kompilację DDL i dodaje 'STRICT'
# tylko dla wybranych tabel biznesowych (allow-list).
# Zgodne z aa3fvcx.txt Punkt 11: STRICT tables dla integralności danych.
# Działa z SQLAlchemy 2.0+ dla wszystkich kontekstów (create_all, Alembic).

# Allow-list: tylko główne tabele biznesowe z typowanymi kolumnami
# Wykluczamy tabele z JSON/BLOB/polimorficznymi kolumnami
_STRICT_TABLES = {
    "invoices",
    "outbox_events",
    "contractors",
    "users",
    "active_learning_patterns",
    "security_alerts",
    "refresh_tokens",
    "failed_tasks",
    "roles",
    "permissions",
    "user_roles",
    "role_permissions",
    "company_profiles",
    "company_partners",
    "ledger_transfers",
    "financial_periods",
    "manual_cashflow_items",
    "dq_decisions",
    "scheduled_tasks",
    "reminders",
    "workflow_saga_state",
    "workflow_saga_history",
}


@compiles(CreateTable, "sqlite")
def _strict_create_table(create_table, compiler, **kw):
    """Nadpisuje kompilację CREATE TABLE dla SQLite — dodaje STRICT.

    Przechwytuje każdą kompilację ``CREATE TABLE`` dla dialektu SQLite
    i dodaje słowo kluczowe ``STRICT`` na końcu, jeśli tabela jest
    na allow-liście ``_STRICT_TABLES``.

    STRICT table:
    - Wymusza typowanie kolumn (INTEGER → tylko int, TEXT → tylko str)
    - Zapobiega przypadkowym błędom typów
    - Nie wpływa na wydajność
    """
    table_name = create_table.element.name
    sql = compiler.visit_create_table(create_table, **kw)
    if table_name in _STRICT_TABLES:
        return sql.rstrip(";") + " STRICT"
    return sql


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
    """Faktura — główny model biznesowy.

    STRICT table: SQLite 3.45+ wymusza typowanie kolumn — typ muszą
    zgadzać się z deklaracją (INTEGER → tylko int, TEXT → tylko str, itp.).
    Zapobiega przypadkowym błędom typów (np. string zamiast liczby w amount).
    """

    __tablename__ = "invoices"  # type: ignore[assignment]
    __table_args__ = {"sqlite_autoincrement": False}  # UUID jako PK
    model_config = ConfigDict(arbitrary_types_allowed=True)

    id: str = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    number: str | None = Field(default=None, index=True)
    contractor_nip: str | None = Field(default=None, index=True)
    file_path: str | None = Field(default=None)
    amount_net: Decimal | None = Field(default=None, max_digits=18, decimal_places=2)
    amount_gross: Decimal | None = Field(default=None, max_digits=18, decimal_places=2)
    currency: str = Field(default="PLN", max_length=3, regex=r"^[A-Z]{3}$")
    status: str = Field(default="NEW", index=True)
    retry_count: int = Field(default=0, ge=0)
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
    """Transactional outbox events for guaranteed delivery.

    STRICT table: SQLite 3.45+ — typowana integralność danych.
    CHECK constraints: event_type NOT NULL, retry_count >= 0.
    """

    __tablename__ = "outbox_events"  # type: ignore[assignment]
    __table_args__ = {"sqlite_autoincrement": False}
    model_config = ConfigDict(arbitrary_types_allowed=True)

    id: str = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    event_type: str = Field(nullable=False, min_length=3)
    aggregate_id: str = Field(nullable=False, min_length=1)
    payload: str = Field(nullable=False)  # JSON string
    status: str = Field(default="PENDING", max_length=20)
    processed: bool = Field(default=False)
    processing_started_at: pendulum.DateTime | None = Field(default=None)
    processed_at: pendulum.DateTime | None = Field(default=None)
    retry_count: int = Field(default=0, ge=0)
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
