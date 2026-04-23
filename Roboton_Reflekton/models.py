from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal
from enum import StrEnum

from sqlalchemy import JSON, Boolean, DateTime, Enum, ForeignKey, Numeric, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
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


class CompanyProfile(Base):
    __tablename__ = "company_profiles"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    nip: Mapped[str] = mapped_column(String(10), unique=True, nullable=False)
    legal_form: Mapped[LegalForm] = mapped_column(Enum(LegalForm, name="legal_form_enum"), nullable=False)
    ksef_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    ksef_token: Mapped[str | None] = mapped_column(String(512), nullable=True)
    vat_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    vat_proportion: Mapped[Decimal] = mapped_column(Numeric(5, 4), default=Decimal("1.0"), nullable=False)
    tigerbeetle_ledger_map: Mapped[dict[str, int]] = mapped_column(JSONB, default=dict, nullable=False)
    company_policy: Mapped[dict] = mapped_column(JSON, default=dict, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

    partners: Mapped[list[CompanyPartner]] = relationship(back_populates="company", cascade="all, delete-orphan")
    tax_policy: Mapped[TaxPolicy | None] = relationship(back_populates="company", uselist=False, cascade="all, delete-orphan")


class CompanyPartner(Base):
    __tablename__ = "company_partners"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    company_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("company_profiles.id", ondelete="CASCADE"), nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    tax_id: Mapped[str] = mapped_column(String(10), nullable=False)
    share_ratio: Mapped[Decimal] = mapped_column(Numeric(5, 4), nullable=False)

    company: Mapped[CompanyProfile] = relationship(back_populates="partners")


class TaxPolicy(Base):
    __tablename__ = "tax_policies"
    __table_args__ = (UniqueConstraint("company_id", name="uq_tax_policy_company"),)

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    company_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("company_profiles.id", ondelete="CASCADE"), nullable=False)
    tax_form: Mapped[TaxForm] = mapped_column(Enum(TaxForm, name="tax_form_enum"), nullable=False)
    pit_costs_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    requires_full_ledger: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    vat_settlement_cycle: Mapped[str] = mapped_column(String(32), default="monthly", nullable=False)
    effective_from: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

    company: Mapped[CompanyProfile] = relationship(back_populates="tax_policy")


class LedgerTransfer(Base):
    __tablename__ = "ledger_transfers"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    company_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("company_profiles.id", ondelete="CASCADE"), nullable=False)
    source_account: Mapped[int] = mapped_column(nullable=False)
    target_account: Mapped[int] = mapped_column(nullable=False)
    amount_minor: Mapped[int] = mapped_column(nullable=False)
    currency: Mapped[str] = mapped_column(String(3), default="PLN", nullable=False)
    source_document_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    status: Mapped[TransferStatus] = mapped_column(Enum(TransferStatus, name="transfer_status_enum"), default=TransferStatus.PENDING, nullable=False)
    meta: Mapped[dict] = mapped_column(JSON, default=dict, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)
