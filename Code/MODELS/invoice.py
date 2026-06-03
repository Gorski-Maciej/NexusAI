from sqlalchemy import String, DateTime, ForeignKey, Date, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.ext.hybrid import hybrid_property
from datetime import datetime, timezone, date
from db.database import Base
from db.mixins import SoftDeleteMixin
from decimal import Decimal
from services.currency_converter import Money, MoneyType
import uuid


class Invoice(SoftDeleteMixin, Base):
    __tablename__ = "invoices"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    number: Mapped[str | None] = mapped_column(String, index=True)

    # Finanse — kolumny DECIMAL w DB (nazwy: "amount_net", "amount_gross")
    # Python widzi kwoty jako Money przez @hybrid_property poniżej
    _amount_net_raw: Mapped[Decimal] = mapped_column("amount_net", MoneyType(12, 2), default=Decimal("0.0"))
    _amount_gross_raw: Mapped[Decimal] = mapped_column("amount_gross", MoneyType(12, 2), default=Decimal("0.0"))
    currency: Mapped[str] = mapped_column(String(3), default="PLN")
    issue_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    # Powiązania i statusy
    contractor_nip: Mapped[str | None] = mapped_column(String(10), index=True)
    contractor_id: Mapped[str | None] = mapped_column(String, ForeignKey("contractors.id"), nullable=True)
    status: Mapped[str] = mapped_column(String, default="NEW") # NEW, PROCESSING, APPROVED, ERROR

    # Pliki i Audyt
    file_path: Mapped[str] = mapped_column(String)
    tenant_id: Mapped[str] = mapped_column(String, default="default", index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    created_by: Mapped[str] = mapped_column(String, default="worker:taskiq")
    updated_by: Mapped[str] = mapped_column(String, default="worker:taskiq")

    # Retencja danych (Rozwiązanie 27: RODO)
    deletion_date: Mapped[datetime | None] = mapped_column(DateTime, nullable=True, doc="Data fizycznego usunięcia (po retencji)")
    retention_period_years: Mapped[int] = mapped_column(Integer, default=5, nullable=False, doc="Okres retencji w latach (domyślnie 5)")

    # Optimistic locking against concurrent edits (Rozwiązanie 23).
    version_id: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    __mapper_args__ = {"version_id_col": version_id}

    # Relacje
    contractor: Mapped["Contractor"] = relationship("Contractor", back_populates="invoices")

    # ── Money hybrid properties ─────────────────────────────────────────
    # amount_net / amount_gross zwracają Money (Fowler's Money z py-moneyed)
    # DB przechowuje DECIMAL w kolumnach "amount_net" / "amount_gross"
    # Użycie @hybrid_property pozwala na użycie w zapytaniach SQLAlchemy
    # (np. select(Invoice).where(Invoice.amount_net == Money("100", "PLN")))

    @hybrid_property
    def amount_net(self) -> Money:
        """Net amount jako Money (py-moneyed)."""
        return Money(str(self._amount_net_raw), self.currency)

    @amount_net.setter
    def amount_net(self, value: Money | Decimal | str | float) -> None:
        if isinstance(value, Money):
            self._amount_net_raw = Decimal(str(value.amount))
            self.currency = value.currency_code
        else:
            self._amount_net_raw = Decimal(str(value))

    @amount_net.expression
    def amount_net(cls) -> MoneyType:
        """SQL expression: zwraca kolumnę amount_net dla zapytań."""
        return cls._amount_net_raw

    @hybrid_property
    def amount_gross(self) -> Money:
        """Gross amount jako Money (py-moneyed)."""
        return Money(str(self._amount_gross_raw), self.currency)

    @amount_gross.setter
    def amount_gross(self, value: Money | Decimal | str | float) -> None:
        if isinstance(value, Money):
            self._amount_gross_raw = Decimal(str(value.amount))
            self.currency = value.currency_code
        else:
            self._amount_gross_raw = Decimal(str(value))

    @amount_gross.expression
    def amount_gross(cls) -> MoneyType:
        """SQL expression: zwraca kolumnę amount_gross dla zapytań."""
        return cls._amount_gross_raw

    def __repr__(self) -> str:
        return f"<Invoice(number={self.number}, status={self.status})>"


class ActiveLearningPattern(Base):
    """Przechowuje wzorce poprawek użytkownika dla konkretnych NIP-ów."""
    __tablename__ = "active_learning_patterns"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    contractor_nip: Mapped[str] = mapped_column(String(10), index=True)
    # correction_payload przechowuje JSON z polami, które AI zwykle myli dla tego NIPu
    correction_payload: Mapped[str] = mapped_column(String)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
