from sqlalchemy import String, Integer, JSON, DateTime
from sqlalchemy.orm import Mapped, mapped_column, validates
from sqlalchemy.ext.declarative import declared_attr
from datetime import datetime, timezone

# --- 1. MIXIN DLA POWTARZALNYCH PÓL (DRY) ---
class TimestampMixin:
    """Automatyzacja pól czasowych dla każdego modelu."""
    @declared_attr
    def created_at(cls) -> Mapped[datetime]:
        return mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    @declared_attr
    def updated_at(cls) -> Mapped[datetime]:
        return mapped_column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

# --- 2. DODATKI DO KLASY CONTRACTOR ---
# (Poniższe pola należy dopisać do klasy Contractor w models/contractor.py)
# Wersjonowanie w celu uniknięcia konfliktów przy edycji przez wielu użytkowników
# version_id: Mapped[int] = mapped_column(Integer, default=1)
# __mapper_args__ = {"version_id_col": version_id}

# @validates("nip")
# def validate_nip(self, key, nip):
#     # logika walidacji NIP
#     return nip
