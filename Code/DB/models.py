from sqlalchemy import Column, Integer, String, Boolean, Float, DateTime, ForeignKey, Text
from sqlalchemy.orm import declarative_base
from sqlalchemy.sql import func
from datetime import datetime
import uuid

Base = declarative_base()

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    invoice_id = Column(String, ForeignKey("invoices.id"), index=True)

    # Kto dokonał zmiany (np. "System/OCR" lub "Księgowa_Kasia")
    user_id = Column(String, default="System")

    # Co zmieniono (np. "amount_net")
    field_changed = Column(String)

    # Historia (przechowywana jako tekst, nawet dla liczb)
    old_value = Column(Text, nullable=True)
    new_value = Column(Text)

    timestamp = Column(DateTime, default=datetime.utcnow)

class OutboxEvent(Base):
    __tablename__ = "outbox_events"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    event_type = Column(String, nullable=False)
    aggregate_id = Column(String, nullable=False)
    payload = Column(Text, nullable=False)
    status = Column(String, default="PENDING")
    processed = Column(Boolean, default=False)
    created_at = Column(DateTime, default=func.now())


class SecurityAlert(Base):
    __tablename__ = "security_alerts"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    actor = Column(String, nullable=False)
    operation = Column(String, nullable=False)
    details = Column(Text, nullable=False)
    created_at = Column(DateTime, default=func.now())
