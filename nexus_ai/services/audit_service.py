from __future__ import annotations

import asyncio
from typing import Any, final

from sqlalchemy.orm import Session
from structlog import get_logger

from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.db.models import AuditLog
from nexus_ai.events import DomainEvent, EventEmitter

logger = get_logger("nexus.services.audit_service")


@final
class AuditService:
    """Service for logging changes and emitting audit events.

    Umożliwia przekazanie ``EventEmitter`` do emitowania eventów
    domenowych po każdej zarejestrowanej zmianie audytowej.
    Backward compatible — ``@staticmethod`` zachowany dla istniejących callerów.

    Event emitter jest przekazywany jako parametr do ``log_change()``
    — nie przez konstruktor — aby zachować ``@staticmethod``.
    """

    @staticmethod
    def log_change(
        session: Session,
        user_id: str,
        action: str,
        target_id: str,
        old_data: dict[str, Any],
        new_data: dict[str, Any],
        event_emitter: EventEmitter | None = None,
    ) -> None:
        """Porównuje dane i zapisuje tylko faktyczne zmiany.

        Zachowuje backward compatibility z istniejącymi callerami
        (``AuditService.log_change(session, user_id, ...)``).
        Opcjonalnie przyjmuje ``event_emitter`` do emisji eventów.

        Args:
            session: SQLAlchemy session.
            user_id: ID użytkownika wykonującego zmianę.
            action: Typ akcji (np. 'UPDATE_INVOICE', 'ROLE_CHANGE').
            target_id: ID obiektu docelowego (np. invoice_id).
            old_data: Słownik z danymi przed zmianą.
            new_data: Słownik z danymi po zmianie.
            event_emitter: Opcjonalny EventEmitter do fire-and-forget emisji.
        """
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

            # Fire-and-forget emisja eventu audytowego
            if event_emitter is not None:
                AuditService._try_emit_event(event_emitter, target_id, action, user_id, len(changes))

    @staticmethod
    def _try_emit_event(
        emitter: EventEmitter,
        target_id: str,
        action: str,
        user_id: str,
        change_count: int,
    ) -> None:
        """Próbuje wyemitować event audytowy fire-and-forget.

        Używa ``asyncio.get_running_loop().call_soon()`` jeśli event loop
        jest dostępny — w przeciwnym razie cicho pomija emisję.
        Wyjątki z ``emit()`` są łapane i logowane jako warning.
        """
        event = DomainEvent(
            event_type="audit.change_logged",
            aggregate_id=target_id,
            version=1,
            data={
                "action": action,
                "user_id": user_id,
                "change_count": change_count,
            },
        )

        async def _safe_emit() -> None:
            try:
                await emitter.emit(event)
            except Exception as exc:
                logger.warning("[AUDIT] Event emit failed: %s", exc)

        try:
            loop = asyncio.get_running_loop()
            loop.call_soon(lambda: asyncio.ensure_future(_safe_emit()))
        except RuntimeError:
            # Brak running event loop — ciche pominięcie emisji
            logger.debug("[AUDIT] No running event loop, skipping audit event emission")
