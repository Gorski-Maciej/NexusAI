from sqlalchemy import Column, Boolean, DateTime
from datetime import datetime, timezone

class SoftDeleteMixin:
    """Enterprise-grade soft delete. Rekordy nigdy nie znikają fizycznie z bazy (Wymóg Audytowy)."""

    is_deleted = Column(Boolean, default=False, index=True)
    deleted_at = Column(DateTime, nullable=True)

    def soft_delete(self) -> None:
        """Oznacza rekord jako usunięty zamiast kasować go z dysku."""
        self.is_deleted = True
        self.deleted_at = datetime.now(timezone.utc)

    def restore(self) -> None:
        """Przywraca usunięty rekord."""
        self.is_deleted = False
        self.deleted_at = None
