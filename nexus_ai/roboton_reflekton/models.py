"""
SQLModel definitions for Roboton/Reflekton — autonomiczny podsystem księgowy.

Zastępuje: SQLAlchemy DeclarativeBase + Mapped/mapped_column (stary styl)
Nowy:     SQLModel Field-based — jedna definicja dla bazy i API

Zgodnie z aa3fvcx.txt:
- SQLModel łączy SQLAlchemy + Pydantic w jednej klasie
- Idealna integracja z Litestar i msgspec
"""
from __future__ import annotations

import uuid
import pendulum
from datetime import datetime
from decimal import Decimal
from enum import StrEnum as BaseStrEnum

from sqlalchemy import JSON, Boolean, Column, DateTime, ForeignKey, Integer, Numeric, String, UniqueConstraint
from sqlalchemy import Enum as SAEnum
from sqlalchemy.dialects.postgresql import JSONB, UUID

from sqlmodel import Field, Relationship, SQLModel


class StrEnum(BaseStrEnum):
    """String enum base class using Python 3.11+ enum.StrEnum."""
    pass


class LegalForm(StrEnum):
    JDG = "jdg"
    CIVIL_PARTNERSHIP = "civil_partnership"
    SP_ZOO = "sp_zoo"
    PSA = "psa"


class TaxForm(StrEnum):
    LUMP_SUM = "lump_sum"
    SCALE = "scale"
    LINEAR = "linear"
    CIT_STANDARD = "cit_standard"
    CIT_ESTONIAN = "cit_estonian"


class TransferStatus(StrEnum):
    PENDING = "pending"
    POSTED = "posted"
    REJECTED = "rejected"


class FinancialPeriodStatus(StrEnum):
    OPEN = "open"
    SOFT_CLOSED = "soft_closed"
    HARD_CLOSED = "hard_closed"


# ── Eksport Base dla kompatybilności z ewentualnymi zewnętrznymi migracjami ──
Base = SQLModel


class CompanyProfile(SQLModel, table=True):
    """Profil firmy — dane rejestrowe, polityka KSeF, mapowanie księgowe."""
    __tablename__ = "company_profiles"  # type: ignore[assignment]

    id: uuid.UUID = Field(sa_column=Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4))
    name: str = Field(sa_type=String(255), nullable=False)
    nip: str = Field(sa_type=String(10), unique=True, nullable=False)
    legal_form: LegalForm = Field(sa_type=SAEnum(LegalForm, name="legal_form_enum"), nullable=False)
    ksef_active: bool = Field(sa_type=Boolean, default=True, nullable=False)
    ksef_token: str | None = Field(sa_type=String(512), default=None)
    vat_active: bool = Field(sa_type=Boolean, default=True, nullable=False)
    vat_proportion: Decimal = Field(sa_type=Numeric(5, 4), default=Decimal("1.0"), nullable=False)
    tigerbeetle_ledger_map: dict[str, int] = Field(sa_type=JSONB, default_factory=dict, nullable=False)
    company_policy: dict = Field(sa_type=JSON, default_factory=dict, nullable=False)
    created_at: datetime = Field(sa_type=DateTime(timezone=True), default_factory=lambda: pendulum.now("UTC"), nullable=False)

    # NOTE: Relationship fields without type annotations.
    # sqlmodel 0.0.38 doesn't resolve string annotations via get_type_hints(),
    # so forward references (CompanyPartner, TaxPolicy) would cause
    # TypeError: issubclass() arg 1 must be a class in get_sqlalchemy_type.
    # We use model_config.ignored_types to tell Pydantic to skip these.
    partners: list[CompanyPartner] = Relationship(back_populates="company")
    tax_policy: TaxPolicy | None = Relationship(back_populates="company")


class CompanyPartner(SQLModel, table=True):
    """Wspólnicy spółki — dla JDG lista może być pusta."""
    __tablename__ = "company_partners"  # type: ignore[assignment]

    id: uuid.UUID = Field(sa_column=Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4))
    company_id: uuid.UUID = Field(
        sa_column=Column(UUID(as_uuid=True), ForeignKey("company_profiles.id", ondelete="CASCADE"), nullable=False)
    )
    full_name: str = Field(sa_type=String(255), nullable=False)
    tax_id: str = Field(sa_type=String(10), nullable=False)
    share_ratio: Decimal = Field(sa_type=Numeric(5, 4), nullable=False)

    company: CompanyProfile = Relationship(back_populates="partners")


class TaxPolicy(SQLModel, table=True):
    """Polityka podatkowa firmy — forma opodatkowania, cykl VAT."""
    __tablename__ = "tax_policies"  # type: ignore[assignment]
    __table_args__ = (UniqueConstraint("company_id", name="uq_tax_policy_company"),)

    id: uuid.UUID = Field(sa_column=Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4))
    company_id: uuid.UUID = Field(
        sa_column=Column(UUID(as_uuid=True), ForeignKey("company_profiles.id", ondelete="CASCADE"), nullable=False)
    )
    tax_form: TaxForm = Field(sa_type=SAEnum(TaxForm, name="tax_form_enum"), nullable=False)
    pit_costs_enabled: bool = Field(sa_type=Boolean, default=True, nullable=False)
    requires_full_ledger: bool = Field(sa_type=Boolean, default=False, nullable=False)
    vat_settlement_cycle: str = Field(sa_type=String(32), default="monthly", nullable=False)
    effective_from: datetime = Field(sa_type=DateTime(timezone=True), default_factory=lambda: pendulum.now("UTC"), nullable=False)

    company: CompanyProfile = Relationship(back_populates="tax_policy")


class LedgerTransfer(SQLModel, table=True):
    """Transakcja księgowa w TigerBeetle — podwójny zapis."""
    __tablename__ = "ledger_transfers"  # type: ignore[assignment]

    id: uuid.UUID = Field(sa_column=Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4))
    company_id: uuid.UUID = Field(
        sa_column=Column(UUID(as_uuid=True), ForeignKey("company_profiles.id", ondelete="CASCADE"), nullable=False)
    )
    source_account: int = Field(sa_type=Integer, nullable=False)
    target_account: int = Field(sa_type=Integer, nullable=False)
    amount_minor: int = Field(sa_type=Integer, nullable=False)
    currency: str = Field(sa_type=String(3), default="PLN", nullable=False)
    source_document_id: uuid.UUID = Field(sa_type=UUID(as_uuid=True), nullable=False)
    status: TransferStatus = Field(sa_type=SAEnum(TransferStatus, name="transfer_status_enum"), default=TransferStatus.PENDING, nullable=False)
    meta: dict = Field(sa_type=JSON, default_factory=dict, nullable=False)
    created_at: datetime = Field(sa_type=DateTime(timezone=True), default_factory=lambda: pendulum.now("UTC"), nullable=False)


class FinancialPeriod(SQLModel, table=True):
    """Okres finansowy — otwarty, miękko zamknięty, twardo zamknięty."""
    __tablename__ = "financial_periods"  # type: ignore[assignment]

    period_id: str = Field(sa_type=String(7), primary_key=True)
    company_id: uuid.UUID = Field(
        sa_column=Column(UUID(as_uuid=True), ForeignKey("company_profiles.id", ondelete="CASCADE"), primary_key=True, nullable=False)
    )
    status: FinancialPeriodStatus = Field(
        sa_type=SAEnum(FinancialPeriodStatus, name="financial_period_status_enum"),
        default=FinancialPeriodStatus.OPEN,
        nullable=False,
    )
    closed_at: datetime | None = Field(sa_type=DateTime(timezone=True), default=None)
    vat_declaration_id: str | None = Field(sa_type=String(128), default=None)
