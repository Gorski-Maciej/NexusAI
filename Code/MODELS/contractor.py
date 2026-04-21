from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from db.database import Base
import uuid

class Contractor(Base):
    __tablename__ = "contractors"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name: Mapped[str] = mapped_column(String, nullable=False)
    nip: Mapped[str] = mapped_column(String(10), unique=True, index=True, nullable=False)
    address: Mapped[str | None] = mapped_column(String, nullable=True)
    bank_account: Mapped[str | None] = mapped_column(String(26), nullable=True)

    # Relacja do faktur tego kontrahenta
    invoices: Mapped[list["Invoice"]] = relationship("Invoice", back_populates="contractor")

    def __repr__(self) -> str:
        return f"<Contractor(name={self.name}, nip={self.nip})>"
