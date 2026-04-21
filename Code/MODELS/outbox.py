from sqlalchemy import String, DateTime, Text, Boolean
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime, timezone
from db.database import Base
import uuid

class OutboxEvent(Base):
    """
    Zdarzenia do wysłania przez NATS.
    Zapisujemy je w tej samej transakcji co fakturę, aby mieć pewność, że nic nie zginie.
    """
    __tablename__ = "outbox_events"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    event_type: Mapped[str] = mapped_column(String) # np. "invoice_created", "ocr_completed"
    payload: Mapped[str] = mapped_column(Text) # Dane zdarzenia w formacie JSON
    processed: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
    processed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    def __repr__(self) -> str:
        return f"<OutboxEvent(type={self.event_type}, processed={self.processed})>"
