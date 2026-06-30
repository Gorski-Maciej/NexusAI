"""SQLModel definitions dla TigerBeetle -- podsystem księgowy.

TRANSFORMACJA:
- LedgerTransfer -> LedgerTransferCache (TB jako source of truth)
- Cache tylko dla szybkich odczytów, TTL 5 min
- TB jest jedynym źródłem prawdy dla stanu księgi

Zgodnie z aa3fvcx.txt:
- SQLModel łączy SQLAlchemy + Pydantic w jednej klasie
- SQLite+SQLCipher -- UUID i JSON jako TEXT
- amount jako int (grosze)
"""

from __future__ import annotations

import uuid
from decimal import Decimal
from enum import StrEnum as BaseStrEnum

import pendulum
from sqlmodel import Field, SQLModel


class StrEnum(BaseStrEnum):
    """String enum base class używając Python 3.11+ enum.StrEnum."""

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
    """Status transferu -- TB jest source of truth, SQLite to cache."""

    PENDING = "pending"
    POSTED = "posted"
    REJECTED = "rejected"


class FinancialPeriodStatus(StrEnum):
    OPEN = "open"
    SOFT_CLOSED = "soft_closed"
    HARD_CLOSED = "hard_closed"


# ── Eksport Base dla kompatybilności z migracjami ──────────────
Base = SQLModel


class LedgerTransferCache(SQLModel, table=True):
    """Cache transferów księgowych (TB jako source of truth).

    TRANSFORMACJA: To już nie jest główny storage transferów.
    TB (TigerBeetle) przechowuje wszystkie transfery.
    SQLite przechowuje tylko cache dla szybkich odczytów z TTL.

    Cache jest odświeżany przez worker z get_account_transfers().
    """

    __tablename__ = "ledger_transfer_cache"  # type: ignore[assignment]

    id: str = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    tb_transfer_id: int = Field(nullable=False, index=True)
    company_id: str = Field(foreign_key="company_profiles.id", nullable=False)
    debit_account: int = Field(nullable=False)
    credit_account: int = Field(nullable=False)
    amount_minor: int = Field(nullable=False)
    currency: str = Field(default="PLN", nullable=False, max_length=3)
    source_document_id: str = Field(nullable=False, max_length=128)
    code: int = Field(default=1001, nullable=False)
    ledger: int = Field(default=700, nullable=False)
    meta: str = Field(default="{}", nullable=False)
    cached_at: pendulum.DateTime = Field(
        default_factory=lambda: pendulum.now("UTC"), nullable=False
    )


# Backward compatibility alias -- LedgerTransfer -> LedgerTransferCache
# TB jest source of truth dla księgi, SQLite to tylko cache
LedgerTransfer = LedgerTransferCache


class CompanyProfile(SQLModel, table=True):
    """Profil firmy -- dane rejestrowe, polityka KSeF, mapowanie księgowe.

    Zgodnie z aa3fvcx.txt: SQLite+SQLCipher, UUID i JSON jako TEXT.
    """

    __tablename__ = "company_profiles"  # type: ignore[assignment]

    id: str = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    name: str = Field(nullable=False, max_length=255)
    nip: str = Field(unique=True, nullable=False, max_length=10)
    legal_form: str = Field(nullable=False, max_length=32)
    ksef_active: bool = Field(default=True, nullable=False)
    ksef_token: str | None = Field(default=None, max_length=512)
    vat_active: bool = Field(default=True, nullable=False)
    vat_proportion: Decimal | None = Field(default=None, max_digits=5, decimal_places=4)
    tigerbeetle_ledger_map: str = Field(default="{}")
    company_policy: str = Field(default="{}")
    created_at: pendulum.DateTime = Field(
        default_factory=lambda: pendulum.now("UTC"), nullable=False
    )


class CompanyPartner(SQLModel, table=True):
    """Wspólnicy spółki."""

    __tablename__ = "company_partners"  # type: ignore[assignment]

    id: str = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    company_id: str = Field(foreign_key="company_profiles.id", nullable=False)
    full_name: str = Field(nullable=False, max_length=255)
    tax_id: str = Field(nullable=False, max_length=10)
    share_ratio: Decimal | None = Field(default=None, max_digits=5, decimal_places=4)


class TaxPolicy(SQLModel, table=True):
    """Polityka podatkowa firmy."""

    __tablename__ = "tax_policies"  # type: ignore[assignment]

    id: str = Field(default_factory=lambda: uuid.uuid4().hex, primary_key=True)
    company_id: str = Field(foreign_key="company_profiles.id", nullable=False, unique=True)
    tax_form: str = Field(nullable=False, max_length=32)
    pit_costs_enabled: bool = Field(default=True, nullable=False)
    requires_full_ledger: bool = Field(default=False, nullable=False)
    vat_settlement_cycle: str = Field(default="monthly", nullable=False, max_length=32)
    effective_from: pendulum.DateTime = Field(
        default_factory=lambda: pendulum.now("UTC"), nullable=False
    )


class FinancialPeriod(SQLModel, table=True):
    """Okres finansowy -- otwarty, miękko zamknięty, twardo zamknięty."""

    __tablename__ = "financial_periods"  # type: ignore[assignment]

    period_id: str = Field(primary_key=True, max_length=7)
    company_id: str = Field(foreign_key="company_profiles.id", primary_key=True, nullable=False)
    status: str = Field(default=FinancialPeriodStatus.OPEN, nullable=False, max_length=32)
    closed_at: pendulum.DateTime | None = Field(default=None)
    vat_declaration_id: str | None = Field(default=None, max_length=128)
