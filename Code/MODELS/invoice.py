from sqlalchemy import String, Decimal, DateTime, ForeignKey, Date
from sqlalchemy.orm import Mapped, mapped_column, relationship
from datetime import datetime, timezone, date
from db.database import Base
from db.mixins import SoftDeleteMixin
from decimal import Decimal
import uuid

class Invoice(SoftDeleteMixin, Base):
    __tablename__ = "invoices"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    number: Mapped[str | None] = mapped_column(String, index=True)

    # Finanse
    amount_net: Mapped[Decimal] = mapped_column(Decimal(12, 2), default=Decimal("0.0"))
    amount_gross: Mapped[Decimal] = mapped_column(Decimal(12, 2), default=Decimal("0.0"))
    currency: Mapped[str] = mapped_column(String(3), default="PLN")
    issue_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    # Powiązania i statusy
    contractor_nip: Mapped[str | None] = mapped_column(String(10), index=True)
    contractor_id: Mapped[str | None] = mapped_column(String, ForeignKey("contractors.id"), nullable=True)
    status: Mapped[str] = mapped_column(String, default="NEW") # NEW, PROCESSING, APPROVED, ERROR

    # Pliki i Audyt
    file_path: Mapped[str] = mapped_column(String)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    created_by: Mapped[str] = mapped_column(String, default="worker:taskiq")
    updated_by: Mapped[str] = mapped_column(String, default="worker:taskiq")

    # Relacje
    contractor: Mapped["Contractor"] = relationship("Contractor", back_populates="invoices")

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
