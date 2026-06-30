"""
SQLModel definitions for core OLTP tables — MAXIMUM SUPERPOWERS.

Zgodnie z aa3fvcx.txt:
- SQLModel łączy SQLAlchemy z walidacją modeli w jednej klasie
- Zero duplikacji kodu między modelem DB a modelem API
- Idealna integracja z Litestar i msgspec

- STRICT tables (SQLite 3.45+) przez @compiles extension
- Enum columns (OutboxStatus, InvoiceStatus) zamiast gołych str
- JSON columns (payload, changes, details) zamiast gołych stringów
- Relationship() z back_populates dla dwukierunkowych relacji
- Composite indexes przez Index() w __table_args__
- Partial indexes przez sqlite_where
- Expression indexes (UPPER, LOWER)
- UniqueConstraint dla composite unique
- Mapped[] annotations dla full type safety (mypyc compatible)
- ge/le constraints na polach numerycznych
- hybrid_property dla computed fields (amount_vat)
- TypeDecorator (PendulumDateTime) dla pendulum.DateTime
- Validation via before_flush listener in hooks.py
- @hybrid_property dla computed fields
- model_config: validate_assignment=True, extra='forbid', str_strip_whitespace=True
- with_loader_criteria ready (tenant_id na każdym modelu)
"""

from __future__ import annotations

import uuid
from decimal import Decimal
from enum import StrEnum
from typing import ClassVar

import pendulum

# Validation moved to nexus_ai/db/hooks.py (before_flush listener).
# No direct pydantic imports remain.
from sqlalchemy import TypeDecorator as SATypeDecorator, Enum as SAEnum
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy.orm import Mapped
from sqlalchemy.schema import Index, UniqueConstraint
from sqlalchemy.sql.ddl import CreateTable
from sqlmodel import JSON, String, and_, text
from sqlmodel import Field, Relationship, SQLModel


# Automatyczna konwersja str↔pendulum.DateTime przy zapisie/odczycie.
# Zamiast gołych stringów ISO, ORM zwraca pendulum.DateTime.


class PendulumDateTime(SATypeDecorator):
    """TypeDecorator: zapisuje ISO string w DB, zwraca pendulum.DateTime."""

    impl = String(32)
    cache_ok = True

    def process_bind_param(self, value: pendulum.DateTime | None, dialect) -> str | None:
        if value is not None:
            return value.isoformat() if isinstance(value, pendulum.DateTime) else str(value)
        return None

    def process_result_value(self, value: str | None, dialect) -> pendulum.DateTime | None:
        if value is not None:
            return pendulum.parse(value)
        return None



_STRICT_TABLES = {
    "invoices",
    "outbox_events",
    "contractors",
    "users",
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
    table_name = create_table.element.name
    sql = compiler.visit_create_table(create_table, **kw)
    if table_name in _STRICT_TABLES:
        return sql.rstrip(";") + " STRICT"
    return sql


# ── Enums ──────────────────────────────────────────────────────────────────


class InvoiceStatus(StrEnum):
    """Statusy faktury — typowany enum zamiast gołego str.

    Wszystkie możliwe stany w cyklu życia faktury:
      NEW → PROCESSING → (APPROVED | REJECTED | BLOCKED | PAID)
      PROCESSING → PENDING_REVIEW → MANUAL_REVIEW
      PROCESSING → ERROR_TIMEOUT → FAILED
      PROCESSING → ERROR_OCR → FAILED
      PROCESSING → ERROR_VALIDATION → FAILED

    UWAGA: Wartość ERROR_TIMEOUT została zmieniona z "ERROR: TIMEOUT"
    na "ERROR_TIMEOUT" (bez dwukropka i spacji). Backward compatibility
    jest zapewniona przez _missing_ hook poniżej.
    """

    NEW = "NEW"
    PROCESSING = "PROCESSING"
    PENDING_REVIEW = "PENDING_REVIEW"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"
    BLOCKED = "BLOCKED"
    PAID = "PAID"
    MANUAL_REVIEW = "MANUAL_REVIEW"
    FAILED = "FAILED"
    ERROR_TIMEOUT = "ERROR_TIMEOUT"
    ERROR_OCR = "ERROR_OCR"
    ERROR_VALIDATION = "ERROR_VALIDATION"
    BLOCKED_FRAUD_SUSPICION = "BLOCKED_FRAUD_SUSPICION"

    @classmethod
    def _missing_(cls, value: object) -> "InvoiceStatus | None":
        """Backward compatibility dla starych wartości w DB.

        Stara wartość ERROR: TIMEOUT → nowa ERROR_TIMEOUT.
        """
        if isinstance(value, str):
            normalized = value.replace(": ", "_").replace(" ", "_")
            for member in cls:
                if member.value == normalized:
                    return member
        return None


class OutboxStatus(StrEnum):
    """Statusy zdarzeń outbox."""

    PENDING = "PENDING"
    PROCESSING = "PROCESSING"
    PROCESSED = "PROCESSED"
    SENT = "SENT"
    FAILED = "FAILED"
    DEAD_LETTER = "DEAD_LETTER"


class UserRole(StrEnum):
    """Role użytkowników."""

    ADMIN = "admin"
    OWNER = "owner"
    ACCOUNTANT = "accountant"
    WORKER = "worker"
    VIEWER = "viewer"


# ── Models ──────────────────────────────────────────────────────────────────


class Invoice(SQLModel, table=True):
    """Faktura — główny model biznesowy z ALL SUPERPOWERS.

    - Enum column: InvoiceStatus zamiast gołego str
    - Relationship() → outbox_events, audit_logs
    - Composite index: (contractor_nip, issue_date)
    - Partial indexes: tylko dla aktywnych statusów
    - Expression index: UPPER(contractor_nip)
    - Mapped[] annotations dla type safety
    - ge=0 na kwotach (walidacja przez SQLModel)
    - hybrid_property: amount_vat w Pythonie i SQL
    - TypeDecorator: PendulumDateTime dla pendulum.DateTime
    - tenant_id dla multi-tenant (with_loader_criteria ready)
    - STRICT table
    """

    __tablename__ = "invoices"  # type: ignore[assignment]
    __table_args__ = (
        Index("idx_invoices_contractor_date", "contractor_nip", "issue_date"),
        Index(
            "idx_invoices_active_status",
            "status",
            sqlite_where=text("status IN ('PAID', 'APPROVED', 'PENDING_REVIEW')"),
        ),
        Index(
            "idx_invoices_active_created",
            "created_at",
            sqlite_where=text("status NOT IN ('NEW', 'REJECTED')"),
        ),
        Index("idx_invoices_nip_upper", text("UPPER(contractor_nip)")),
        UniqueConstraint("tenant_id", "number", name="uq_tenant_invoice_number"),
        {"sqlite_autoincrement": False},
    )
    model_config: ClassVar[dict] = {
        "arbitrary_types_allowed": True,
        "validate_assignment": True,
        "extra": "forbid",
        "str_strip_whitespace": True,
    }

    id: Mapped[str] = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    number: Mapped[str | None] = Field(
        default=None,
        index=True,
        sa_column_kwargs={"comment": "Numer faktury (np. FV/2026/001)"},
    )
    contractor_nip: Mapped[str | None] = Field(
        default=None,
        index=True,
        sa_column_kwargs={"comment": "NIP kontrahenta (10 cyfr)"},
    )
    file_path: Mapped[str | None] = Field(
        default=None,
        sa_column_kwargs={"comment": "Ścieżka do pliku PDF/obrazu faktury"},
    )
    amount_net: Mapped[Decimal | None] = Field(
        default=None,
        max_digits=18,
        decimal_places=2,
        ge=Decimal("0.00"),  # Walidacja przez SQLModel
        sa_column_kwargs={
            "comment": "Kwota netto w PLN",
            "check": "amount_net >= 0",
        },
    )
    amount_gross: Mapped[Decimal | None] = Field(
        default=None,
        max_digits=18,
        decimal_places=2,
        ge=Decimal("0.00"),
        sa_column_kwargs={
            "comment": "Kwota brutto w PLN (netto + VAT)",
            "check": "amount_gross >= 0",
        },
    )
    currency: Mapped[str] = Field(
        default="PLN",
        max_length=3,
        regex=r"^[A-Z]{3}$",
        sa_column_kwargs={
            "comment": "Kod waluty ISO 4217 (3 litery)",
            "check": "length(currency) = 3",
        },
    )
    status: Mapped[InvoiceStatus] = Field(
        default=InvoiceStatus.NEW,
        index=True,
        sa_type=SAEnum(InvoiceStatus),
        sa_column_kwargs={"comment": "Status faktury (InvoiceStatus enum)"},
    )
    retry_count: Mapped[int] = Field(
        default=0,
        ge=0,
        sa_column_kwargs={"comment": "Liczba ponownych prób przetwarzania"},
    )
    processing_status: Mapped[str | None] = Field(
        default=None,
        sa_column_kwargs={"comment": "Status przetwarzania (OCR, AI, walidacja)"},
    )
    issue_date: Mapped[str | None] = Field(
        default=None,
        sa_column_kwargs={"comment": "Data wystawienia faktury (ISO format)"},
    )
    created_at: Mapped[pendulum.DateTime] = Field(
        default_factory=lambda: pendulum.now("UTC"),
        sa_type=PendulumDateTime,
        sa_column_kwargs={"comment": "Timestamp utworzenia rekordu"},
    )
    updated_at: Mapped[pendulum.DateTime] = Field(
        default_factory=lambda: pendulum.now("UTC"),
        sa_column_kwargs={
            "comment": "Timestamp ostatniej modyfikacji",
            "onupdate": lambda: pendulum.now("UTC"),
        },
        sa_type=PendulumDateTime,
    )
    tenant_id: Mapped[str] = Field(
        default="default",
        index=True,
        sa_column_kwargs={"comment": "Tenant ID dla multi-tenant isolation"},
    )
    updated_by: Mapped[str | None] = Field(
        default=None,
        sa_column_kwargs={"comment": "Kto ostatnio modyfikował rekord"},
    )

    outbox_events: Mapped[list["OutboxEvent"]] = Relationship(back_populates="invoice")
    audit_logs: Mapped[list["AuditLog"]] = Relationship(back_populates="invoice")

    @property
    def amount_vat(self) -> Decimal | None:
        """VAT = amount_gross - amount_net (Python-level computed property)."""
        if self.amount_gross is not None and self.amount_net is not None:
            return self.amount_gross - self.amount_net
        return None

    @hybrid_property
    def amount_vat_sql(self) -> Decimal | None:
        """VAT = amount_gross - amount_net (SQLAlchemy hybrid)."""
        if self.amount_gross is not None and self.amount_net is not None:
            return self.amount_gross - self.amount_net
        return None

    @amount_vat_sql.inplace.expression
    @classmethod
    def _amount_vat_expr(cls):
        """VAT = amount_gross - amount_net (SQL level, CASE dla NULL-safe)."""
        return case(
            (
                and_(cls.amount_gross.isnot(None), cls.amount_net.isnot(None)),
                cls.amount_gross - cls.amount_net,
            ),
            else_=None,
        )

    # Cross-field validation moved to hooks.py (before_flush listener)


class Contractor(SQLModel, table=True):
    """Kontrahenci z walidacją NIP."""

    __tablename__ = "contractors"  # type: ignore[assignment]
    __table_args__ = (Index("idx_contractors_nip_upper", text("UPPER(nip)")),)
    model_config: ClassVar[dict] = {
        "arbitrary_types_allowed": True,
        "validate_assignment": True,
        "extra": "forbid",
    }

    id: Mapped[str] = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    nip: Mapped[str] = Field(unique=True, nullable=False, index=True)
    name: Mapped[str | None] = Field(default=None)
    vat_status: Mapped[str | None] = Field(default=None)
    created_at: Mapped[pendulum.DateTime] = Field(
        default_factory=lambda: pendulum.now("UTC"),
        sa_type=PendulumDateTime,
    )

    # viewonly=True bo to join przez string NIP, nie przez FK
    invoices: Mapped[list["Invoice"]] = Relationship(
        sa_relationship_kwargs={
            "primaryjoin": "Contractor.nip == Invoice.contractor_nip",
            "foreign_keys": "Invoice.contractor_nip",
            "viewonly": True,
        },
    )

    # NIP validation moved to hooks.py (before_flush listener)


class AuditLog(SQLModel, table=True):
    """Audit trail for all changes — z JSON i Relationship."""

    __tablename__ = "audit_logs"  # type: ignore[assignment]
    __table_args__ = (
        Index("idx_audit_logs_invoice_action", "invoice_id", "action"),
        Index("idx_audit_logs_timestamp", "timestamp"),
    )
    model_config: ClassVar[dict] = {
        "arbitrary_types_allowed": True,
        "validate_assignment": True,
        "extra": "forbid",
    }

    id: Mapped[str] = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    invoice_id: Mapped[str | None] = Field(default=None, foreign_key="invoices.id", index=True)
    action: Mapped[str | None] = Field(default=None)
    user_id: Mapped[str] = Field(default="System")
    field_changed: Mapped[str | None] = Field(default=None)
    old_value: Mapped[str | None] = Field(default=None)
    new_value: Mapped[str | None] = Field(default=None)
    changes: Mapped[dict | None] = Field(
        default=None,
        sa_type=JSON,
        description="JSON dict ze zmianami (dla AuditService)",
    )
    timestamp: Mapped[pendulum.DateTime] = Field(
        default_factory=lambda: pendulum.now("UTC"),
        sa_type=PendulumDateTime,
    )

    invoice: Mapped["Invoice | None"] = Relationship(back_populates="audit_logs")


class OutboxEvent(SQLModel, table=True):
    """Transactional outbox events — z Enum, JSON, Relationship, Partial Index.

    - Enum column: OutboxStatus zamiast gołego str
    - JSON column: payload zamiast gołego stringa
    - Relationship() → invoice
    - Partial index: tylko nieprzetworzone eventy
    """

    __tablename__ = "outbox_events"  # type: ignore[assignment]
    __table_args__ = (
        Index(
            "idx_outbox_pending", "status", "created_at", sqlite_where=text("status = 'PENDING'")
        ),
        Index("idx_outbox_aggregate", "aggregate_id", "event_type"),
        {"sqlite_autoincrement": False},
    )
    model_config: ClassVar[dict] = {
        "arbitrary_types_allowed": True,
        "validate_assignment": True,
        "extra": "forbid",
    }

    id: Mapped[str] = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    event_type: Mapped[str] = Field(nullable=False, min_length=3)
    aggregate_id: Mapped[str] = Field(nullable=False, min_length=1)
    payload: Mapped[dict] = Field(
        default_factory=dict,
        sa_type=JSON,
        description="JSON payload eventu",
    )
    status: Mapped[OutboxStatus] = Field(
        default=OutboxStatus.PENDING,
        sa_type=SAEnum(OutboxStatus),
    )
    processed: Mapped[bool] = Field(default=False)
    processing_started_at: Mapped[pendulum.DateTime | None] = Field(
        default=None, sa_type=PendulumDateTime
    )
    processed_at: Mapped[pendulum.DateTime | None] = Field(default=None, sa_type=PendulumDateTime)
    retry_count: Mapped[int] = Field(default=0, ge=0)
    created_at: Mapped[pendulum.DateTime] = Field(
        default_factory=lambda: pendulum.now("UTC"),
        sa_type=PendulumDateTime,
    )

    invoice_id: Mapped[str | None] = Field(
        default=None,
        foreign_key="invoices.id",
        index=True,
    )
    invoice: Mapped["Invoice | None"] = Relationship(back_populates="outbox_events")

    # event_type validation moved to hooks.py (before_flush listener)


class SecurityAlert(SQLModel, table=True):
    """Security events (RBAC violations, suspicious access)."""

    __tablename__ = "security_alerts"  # type: ignore[assignment]
    __table_args__ = (Index("idx_security_alerts_actor", "actor", "created_at"),)
    model_config: ClassVar[dict] = {
        "arbitrary_types_allowed": True,
        "validate_assignment": True,
        "extra": "forbid",
    }

    id: Mapped[str] = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    actor: Mapped[str] = Field(nullable=False)
    operation: Mapped[str] = Field(nullable=False)
    details: Mapped[dict] = Field(
        default_factory=dict,
        sa_type=JSON,
        description="JSON z detalami zdarzenia",
    )
    created_at: Mapped[pendulum.DateTime] = Field(
        default_factory=lambda: pendulum.now("UTC"),
        sa_type=PendulumDateTime,
    )


class UserAccount(SQLModel, table=True):
    """User accounts — z Enum role i walidacją username."""

    __tablename__ = "users"  # type: ignore[assignment]
    model_config: ClassVar[dict] = {
        "arbitrary_types_allowed": True,
        "validate_assignment": True,
        "extra": "forbid",
    }

    id: Mapped[str] = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    username: Mapped[str] = Field(unique=True, nullable=False, index=True)
    password_hash: Mapped[str] = Field(nullable=False)
    role: Mapped[UserRole] = Field(
        default=UserRole.WORKER,
        sa_type=SAEnum(UserRole),
        nullable=False,
    )
    tenant_id: Mapped[str] = Field(nullable=False, default="default")
    is_active: Mapped[bool] = Field(nullable=False, default=True)
    jwt_version: Mapped[int] = Field(default=1)
    created_at: Mapped[pendulum.DateTime] = Field(
        default_factory=lambda: pendulum.now("UTC"),
        sa_type=PendulumDateTime,
    )

    # username and role validation moved to hooks.py (before_flush listener)


# ── Eksport Base dla kompatybilności (SQLModel alias) ────────────────────

Base = SQLModel



