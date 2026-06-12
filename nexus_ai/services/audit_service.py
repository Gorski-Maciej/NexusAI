from sqlalchemy.orm import Session

from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.db.models import AuditLog


class AuditService:
    @staticmethod
    def log_change(
        session: Session, user_id: str, action: str, target_id: str, old_data: dict, new_data: dict
    ):
        """Porównuje dane i zapisuje tylko faktyczne zmiany."""
        changes = {}
        for key, new_val in new_data.items():
            old_val = old_data.get(key)
            if old_val != new_val:
                changes[key] = {
                    "from": str(old_val) if old_val is not None else None,
                    "to": str(new_val),
                }

        if changes:
            entry = AuditLog(
                user_id=user_id, action=action, invoice_id=target_id, changes=msgspec_dumps(changes)
            )
            session.add(entry)
