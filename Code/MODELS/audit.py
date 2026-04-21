from sqlalchemy import String, ForeignKey, DateTime
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime, timezone
from db.database import Base
import uuid

class AuditLog(Base):
    """Przechowuje historię modyfikacji dokumentów (kto, co i kiedy zmienił)."""
    __tablename__ = "audit_logs"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    invoice_id: Mapped[str] = mapped_column(String, ForeignKey("invoices.id"), index=True)

    # Kto dokonał zmiany (np. "System/OCR", "Księgowa_Kasia" lub "Auto-Correction")
    user_id: Mapped[str] = mapped_column(String, default="System")

    # Rodzaj akcji, np. "STATUS_CHANGED", "AMOUNT_CORRECTED", "OCR_PROCESSED"
    action: Mapped[str] = mapped_column(String, nullable=False)

    # Szczegóły zmiany (opcjonalne, przydatne przy ręcznych korektach)
    old_value: Mapped[str | None] = mapped_column(String, nullable=True)
    new_value: Mapped[str | None] = mapped_column(String, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
