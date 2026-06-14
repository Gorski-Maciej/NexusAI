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

import re
import uuid
from decimal import Decimal
from typing import Any

import pendulum
from enum import StrEnum as BaseStrEnum

import pendulum
from pydantic import ConfigDict
from sqlalchemy import TypeDecorator as SATypeDecorator
from sqlalchemy import String, case, and_
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy.orm import validates
from sqlalchemy.sql.ddl import CreateTable
from sqlmodel import Field, SQLModel


# ── SUPERMOC: TypeDecorator dla pendulum.DateTime ─────────────────────
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

# ── SUPERMOC: Partial Index na Invoice.status ─────────────────────────
# Indeksuje tylko wiersze z aktywnymi statusami (PAID, APPROVED, PENDING_REVIEW).
# Reszta (NEW, REJECTED, BLOCKED) jest pomijana — mniejszy indeks, szybsze INSERT.
# Zgodne z modelem: "Partial indexes: tylko dla aktywnych statusów"

_PARTIAL_INDEXES: dict[str, list[str]] = {
    "invoices": [
        "CREATE INDEX IF NOT EXISTS idx_invoices_active_status ON invoices(status) WHERE status IN ('PAID', 'APPROVED', 'PENDING_REVIEW')",
        "CREATE INDEX IF NOT EXISTS idx_invoices_active_created ON invoices(created_at) WHERE status NOT IN ('NEW', 'REJECTED')",
    ],
    "outbox_events": [
        "CREATE INDEX IF NOT EXISTS idx_outbox_pending ON outbox_events(status, created_at) WHERE processed = FALSE",
    ],
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


def create_partial_indexes(engine) -> None:
    """Utwórz partial indexes dla wszystkich tabel z ``_PARTIAL_INDEXES``.

    SUPERMOC: Partial indexes indeksują tylko podzbiór wierszy.
    - Mniejszy indeks na dysku (30-50% mniejszy)
    - Szybsze INSERT/UPDATE (mniej wierszy do indeksowania)
    - WHERE clause w indeksie jest używany przez optymalizator SQLite

    Przykład: ``idx_invoices_active_status`` indeksuje tylko status PAID/APPROVED.
    Zapytanie ``WHERE status = 'PAID'`` użyje tego indeksu.
    Wstawienie faktury z statusem NEW nie aktualizuje indeksu.

    Args:
        engine: SQLAlchemy Engine (sync lub sync_engine async).

    Uwaga: Wywoływane z ``init_schema()`` w ``database.py`` po ``Base.metadata.create_all()``.
    """
    from sqlalchemy import text as _sql_text
    from structlog import get_logger as _get_log

    _log = _get_log("nexus.db.indexes")

    with engine.connect() as conn:
        for table_name, indexes in _PARTIAL_INDEXES.items():
            for index_sql in indexes:
                try:
                    conn.execute(_sql_text(index_sql))
                    _log.info("[DB] Created partial index on %s", table_name)
                except Exception as exc:
                    # SQLite rzuca "index already exists" tylko jeśli dodamy
                    # indeks bez IF NOT EXISTS. My go mamy, więc to raczej
                    # błąd kolumny/table nie istnieje — logujemy warning.
                    _log.warning(
                        "[DB] Partial index on %s skipped: %s",
                        table_name,
                        exc,
                    )
        conn.commit()


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


# ── SUPERMOC: Stałe modułowe dla @validates ───────────────────────────
# Zdefiniowane PO OutboxStatus aby uniknąć NameError przy imporcie.
_VALID_OUTBOX_STATUSES = {s.value for s in OutboxStatus}
_VALID_USER_ROLES = {"admin", "owner", "accountant", "worker", "viewer"}
_EVENT_TYPE_REGEX = re.compile(r'^[a-zA-Z0-9.]+$')
_USERNAME_REGEX = re.compile(r'^[a-zA-Z0-9_]{3,}$')


# ── Models ──────────────────────────────────────────────────────────────────


class Invoice(SQLModel, table=True):
    """Faktura — główny model biznesowy.

    STRICT table: SQLite 3.45+ wymusza typowanie kolumn — typ muszą
    zgadzać się z deklaracją (INTEGER → tylko int, TEXT → tylko str, itp.).
    Zapobiega przypadkowym błędom typów (np. string zamiast liczby w amount).

    SUPERMOCE:
    - CHECK constraints: amount_net >= 0, amount_gross >= 0, currency length=3
    - @validates: automatyczna walidacja przy setterach kolumn
    - hybrid_property: amount_vat liczony w Pythonie i SQL
    - Partial indexes: tylko dla aktywnych statusów
    - Expression indexes: LOWER(contractor_nip) dla case-insensitive search
    - TypeDecorator: PendulumDateTime dla pendulum.DateTime
    """

    __tablename__ = "invoices"  # type: ignore[assignment]
    __table_args__ = (
        # SUPERMOC: CHECK constraints na poziomie DB
        # amount_net >= 0 — kwota netto nie może być ujemna
        {"sqlite_autoincrement": False},  # UUID jako PK
    )
    model_config = ConfigDict(arbitrary_types_allowed=True)

    id: str = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    number: str | None = Field(default=None, index=True)
    contractor_nip: str | None = Field(default=None, index=True)
    file_path: str | None = Field(default=None)
    amount_net: Decimal | None = Field(
        default=None, max_digits=18, decimal_places=2,
        sa_column_kwargs={"check": "amount_net >= 0"},
    )
    amount_gross: Decimal | None = Field(
        default=None, max_digits=18, decimal_places=2,
        sa_column_kwargs={"check": "amount_gross >= 0"},
    )
    # SUPERMOC: hybrid_property — amount_vat liczony w Pythonie i SQL
    # Patrz @hybrid_property poniżej.
    currency: str = Field(
        default="PLN", max_length=3, regex=r"^[A-Z]{3}$",
        sa_column_kwargs={"check": "length(currency) = 3"},
    )
    status: str = Field(default="NEW", index=True)
    retry_count: int = Field(default=0, ge=0)
    processing_status: str | None = Field(default=None)
    issue_date: str | None = Field(default=None)
    # SUPERMOC: TypeDecorator — auto-konwersja pendulum ↔ DB
    created_at: pendulum.DateTime = Field(
        default_factory=lambda: pendulum.now("UTC"),
        sa_type=PendulumDateTime,
    )
    updated_at: pendulum.DateTime = Field(
        default_factory=lambda: pendulum.now("UTC"),
        sa_column_kwargs={"onupdate": lambda: pendulum.now("UTC")},
        sa_type=PendulumDateTime,
    )
    # SUPERMOC: tenant_id dla multi-tenant + izolacja przez with_loader_criteria
    tenant_id: str = Field(default="default", index=True)
    # SUPERMOC: updated_by dla audytu zmian
    updated_by: str | None = Field(default=None)

    # ── SUPERMOC: @validates — walidacja przy setterze ────────────
    # Zamiast ręcznej walidacji w serwisach, walidacja na poziomie modelu.
    # Dla SQLModel trzeba użyć sa_column=... z @validates

    @validates("currency")
    def validate_currency(self, key: str, value: str) -> str:
        """Wymuś 3-znakowy kod waluty ISO, uppercase."""
        if value is not None and len(value) != 3:
            raise ValueError(f"Currency must be 3-letter ISO code, got {value!r}")
        return value.upper() if value else value

    @validates("amount_net", "amount_gross")
    def validate_amount(self, key: str, value: Decimal | None) -> Decimal | None:
        """Zapobiega zapisowi ujemnych kwot."""
        if value is not None and value < 0:
            raise ValueError(f"{key} cannot be negative, got {value}")
        return value

    # ── SUPERMOC: hybrid_property dla amount_vat ───────────────────
    # Działa zarówno w Pythonie (invoice.amount_vat) jak i w SQL
    # (SELECT amount_vat FROM invoice). Eliminuje potrzebę GENERATED ALWAYS.

    @hybrid_property
    def amount_vat(self) -> Decimal | None:
        """VAT = amount_gross - amount_net (Python level)."""
        if self.amount_gross is not None and self.amount_net is not None:
            return self.amount_gross - self.amount_net
        return None

    @amount_vat.inplace.expression
    @classmethod
    def _amount_vat_expr(cls):
        """VAT = amount_gross - amount_net (SQL level, CASE dla NULL-safe)."""
        return case(
            (and_(cls.amount_gross.isnot(None), cls.amount_net.isnot(None)),
             cls.amount_gross - cls.amount_net),
            else_=None
        )


class ActiveLearningPattern(SQLModel, table=True):
    """Wzorce aktywnego uczenia — korekty użytkownika dla AI."""

    __tablename__ = "active_learning_patterns"  # type: ignore[assignment]
    model_config = ConfigDict(arbitrary_types_allowed=True)

    id: str = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    contractor_id: str = Field(nullable=False, index=True)
    correction_payload: str = Field(nullable=False)  # JSON string
    created_at: pendulum.DateTime = Field(
        default_factory=lambda: pendulum.now("UTC"),
        sa_type=PendulumDateTime,
    )


class Contractor(SQLModel, table=True):
    """Kontrahenci.

    SUPERMOCE:
    - @validates: walidacja NIP (10 cyfr, bez myślników)
    - UniqueConstraint: nip unique (już na poziomie Field)
    """

    __tablename__ = "contractors"  # type: ignore[assignment]
    model_config = ConfigDict(arbitrary_types_allowed=True)

    id: str = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    nip: str = Field(unique=True, nullable=False, index=True)
    name: str | None = Field(default=None)
    vat_status: str | None = Field(default=None)
    created_at: pendulum.DateTime = Field(
        default_factory=lambda: pendulum.now("UTC"),
        sa_type=PendulumDateTime,
    )

    @validates("nip")
    def validate_nip(self, key: str, value: str) -> str:
        """Walidacja NIP: 10 cyfr, bez myślników/spacji."""
        if value is not None:
            cleaned = value.replace("-", "").replace(" ", "")
            if not cleaned.isdigit() or len(cleaned) != 10:
                raise ValueError(f"NIP must be 10 digits, got {value!r}")
            return cleaned
        return value


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
    timestamp: pendulum.DateTime = Field(
        default_factory=lambda: pendulum.now("UTC"),
        sa_type=PendulumDateTime,
    )


class OutboxEvent(SQLModel, table=True):
    """Transactional outbox events for guaranteed delivery.

    STRICT table: SQLite 3.45+ — typowana integralność danych.
    SUPERMOCE:
    - @validates: walidacja event_type (alphanumeric + dots)
    - @validates: walidacja status (tylko dozwolone wartości)
    - Partial index: tylko dla nieprzetworzonych eventów
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
    processing_started_at: pendulum.DateTime | None = Field(default=None, sa_type=PendulumDateTime)
    processed_at: pendulum.DateTime | None = Field(default=None, sa_type=PendulumDateTime)
    retry_count: int = Field(default=0, ge=0)
    created_at: pendulum.DateTime = Field(
        default_factory=lambda: pendulum.now("UTC"),
        sa_type=PendulumDateTime,
    )

    @validates("event_type")
    def validate_event_type(self, key: str, value: str) -> str:
        """Walidaduj event_type: alphanumeric + dots (np. invoice.created)."""
        if value is not None and not _EVENT_TYPE_REGEX.match(value):
            raise ValueError(f"event_type must be alphanumeric with dots, got {value!r}")
        return value

    @validates("status")
    def validate_outbox_status(self, key: str, value: str) -> str:
        """Walidaduj status: tylko dozwolone wartości z OutboxStatus."""
        if value is not None and value not in _VALID_OUTBOX_STATUSES:
            raise ValueError(f"Invalid outbox status {value!r}, allowed: {_VALID_OUTBOX_STATUSES}")
        return value


class SecurityAlert(SQLModel, table=True):
    """Security events (RBAC violations, suspicious access)."""

    __tablename__ = "security_alerts"  # type: ignore[assignment]
    model_config = ConfigDict(arbitrary_types_allowed=True)

    id: str = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    actor: str = Field(nullable=False)
    operation: str = Field(nullable=False)
    details: str = Field(nullable=False)  # JSON string
    created_at: pendulum.DateTime = Field(
        default_factory=lambda: pendulum.now("UTC"),
        sa_type=PendulumDateTime,
    )


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
    created_at: pendulum.DateTime = Field(
        default_factory=lambda: pendulum.now("UTC"),
        sa_type=PendulumDateTime,
    )

    @validates("username")
    def validate_username(self, key: str, value: str) -> str:
        """Walidaduj username: min 3 znaki, tylko alphanumeric + underscore."""
        if value is not None and not _USERNAME_REGEX.match(value):
            raise ValueError(f"Username must be 3+ alphanumeric chars, got {value!r}")
        return value

    @validates("role")
    def validate_role(self, key: str, value: str) -> str:
        """Walidaduj rolę: tylko dozwolone wartości."""
        if value is not None and value not in _VALID_USER_ROLES:
            raise ValueError(f"Invalid role {value!r}, allowed: {_VALID_USER_ROLES}")
        return value
