from __future__ import annotations

from datetime import datetime, timezone
import uuid

from sqlalchemy import DateTime, Integer, String
from sqlalchemy.ext.declarative import declared_attr
from sqlalchemy.orm import Mapped, mapped_column, relationship, validates

from db.database import Base


class TimestampMixin:
    """Reusable timestamp fields for SQLAlchemy models."""

    @declared_attr
    def created_at(cls) -> Mapped[datetime]:
        return mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    @declared_attr
    def updated_at(cls) -> Mapped[datetime]:
        return mapped_column(
            DateTime,
            default=lambda: datetime.now(timezone.utc),
            onupdate=lambda: datetime.now(timezone.utc),
        )


class Contractor(TimestampMixin, Base):
    __tablename__ = "contractors"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name: Mapped[str] = mapped_column(String, nullable=False)
    nip: Mapped[str] = mapped_column(String(10), unique=True, index=True, nullable=False)
    address: Mapped[str | None] = mapped_column(String, nullable=True)
    bank_account: Mapped[str | None] = mapped_column(String(26), nullable=True)

    # Optimistic locking against concurrent edits.
    version_id: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    __mapper_args__ = {"version_id_col": version_id}

    invoices: Mapped[list["Invoice"]] = relationship("Invoice", back_populates="contractor")

    @validates("nip")
    def validate_nip(self, _key: str, nip: str) -> str:
        normalized = "".join(ch for ch in str(nip) if ch.isdigit())
        if len(normalized) != 10:
            raise ValueError("NIP musi składać się z 10 cyfr.")

        weights = (6, 5, 7, 2, 3, 4, 5, 6, 7)
        checksum = sum(int(d) * w for d, w in zip(normalized[:9], weights)) % 11
        if checksum == 10 or checksum != int(normalized[9]):
            raise ValueError("Nieprawidłowy NIP (błąd sumy kontrolnej).")

        return normalized

    def __repr__(self) -> str:
        return f"<Contractor(name={self.name}, nip={self.nip})>"
