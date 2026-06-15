from __future__ import annotations

from typing import Any, final

import anyio

from sqlalchemy import event
from sqlalchemy.orm import Session
from structlog import get_logger

from nexus_ai.core.broker import broker
from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.db.models import AuditLog, Invoice

logger = get_logger("nexus.services.audit_service")

# ── SUPERMOC: Automatyczny audit trail przez before_flush ──────────────
# Zamiast ręcznego ``AuditService.log_change()`` w każdym serwisie,
# używamy ``SessionEvents.before_flush`` do automatycznego logowania
# wszystkich zmian na modelach oznaczonych przez ``__auditable__``.
#
# To eliminuje potrzebę jawnego wywoływania log_change() w:
# - triage_service.resolve_triage_item()
# - invoice_service.update_invoice()
# - admin_service.update_user()
# itd.

# Allow-list audytowanych modeli i ich pól
_AUDITABLE_FIELDS: dict[type, set[str]] = {
    Invoice: {"status", "amount_net", "amount_gross", "contractor_nip", "number", "retry_count"},
}


def _get_audit_changes(session: Session) -> list[AuditLog]:
    """Generuj AuditLog entries z session.dirty i session.deleted.

    Dla każdego zmodyfikowanego obiektu, jeśli jego typ jest w
    ``_AUDITABLE_FIELDS`` i zmieniły się monitorowane pola,
    tworzy wpis AuditLog z różnicą (diff).

    Returns:
        Lista nowych AuditLog entries (jeszcze nie dodanych do sesji).
    """
    entries: list[AuditLog] = []

    for obj in session.dirty:
        auditable_fields = _AUDITABLE_FIELDS.get(type(obj))
        if auditable_fields is None:
            continue

        changes = {}
        for attr in auditable_fields:
            if session.is_modified(obj, include_collections=False):
                hist = session.get_attribute_history(obj, attr)
                if hist.has_changes():
                    old_val = hist.deleted[0] if hist.deleted else None
                    new_val = hist.added[0] if hist.added else None
                    changes[attr] = {
                        "from": str(old_val) if old_val is not None else None,
                        "to": str(new_val) if new_val is not None else None,
                    }

        if changes:
            target_id = str(getattr(obj, "id", ""))
            entries.append(
                AuditLog(
                    user_id="System(auto)",
                    action=f"UPDATE_{type(obj).__name__.upper()}",
                    invoice_id=target_id if hasattr(obj, "id") else None,
                    changes=msgspec_dumps(changes),
                )
            )

    for obj in session.deleted:
        auditable_fields = _AUDITABLE_FIELDS.get(type(obj))
        if auditable_fields is None:
            continue

        target_id = str(getattr(obj, "id", ""))
        entries.append(
            AuditLog(
                user_id="System(auto)",
                action=f"DELETE_{type(obj).__name__.upper()}",
                invoice_id=target_id if hasattr(obj, "id") else None,
                changes=msgspec_dumps({"deleted": str(obj)}),
            )
        )

    return entries


def register_audit_hooks() -> None:
    """Rejestruje ``before_flush`` hook do automatycznego audytu.

    Wywołaj raz przy starcie aplikacji (np. w ``on_startup``).

    SUPERMOC: ``SessionEvents.before_flush`` przechwytuje wszystkie
    zmiany przed zapisem do DB. Automatycznie tworzy AuditLog entries
    dla każdego zmodyfikowanego/usuniętego obiektu z ``_AUDITABLE_FIELDS``.
    """

    @event.listens_for(Session, "before_flush")
    def auto_audit_before_flush(session, flush_context, instances):
        """Automatycznie loguj zmiany na audytowanych modelach."""
        entries = _get_audit_changes(session)
        for entry in entries:
            session.add(entry)

    logger.info("[AUDIT] Auto-audit hooks registered via before_flush")


@final
class AuditService:
    """Service for logging changes and emitting audit events.

    Umożliwia przekazanie ``EventEmitter`` do emitowania eventów
    domenowych po każdej zarejestrowanej zmianie audytowej.
    Backward compatible — ``@staticmethod`` zachowany dla istniejących callerów.

    Event emitter jest przekazywany jako parametr do ``log_change()``
    — nie przez konstruktor — aby zachować ``@staticmethod``.

    SUPERMOC: Automatyczny audit przez ``before_flush`` hook.
    Zarejestruj przez ``register_audit_hooks()`` przy starcie aplikacji.
    Eliminuje potrzebę jawnego ``log_change()`` w serwisach.
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

        Uwaga: Automatyczny audit przez ``before_flush`` może wyeliminować
        potrzebę jawnego wywoływania tej metody. Nowy kod powinien polegać
        na auto-audit, a log_change() używać tylko dla zmian które wymagają
        ręcznego diff-a lub emisji eventów.

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

            # Fire-and-forget emisja eventu audytowego przez Taskiq
            AuditService._try_emit_event(target_id, action, user_id, len(changes))

    @staticmethod
    def _try_emit_event(
        target_id: str,
        action: str,
        user_id: str,
        change_count: int,
    ) -> None:
        """Próbuje wyemitować event audytowy fire-and-forget przez Taskiq.

        Używa ``anyio.ensure_backend().create_task()`` jeśli event loop
        jest dostępny — w przeciwnym razie cicho pomija emisję.
        """
        async def _safe_kick() -> None:
            try:
                await broker.kick("event_emit_domain_event",
                    event_type="audit.change_logged",
                    aggregate_id=target_id,
                    data={
                        "action": action,
                        "user_id": user_id,
                        "change_count": change_count,
                    },
                )
            except Exception as exc:
                logger.warning("[AUDIT] Event kick failed: %s", exc)

        try:
            anyio.ensure_backend().create_task(_safe_kick())
        except RuntimeError:
            # Brak running event loop — ciche pominięcie emisji
            logger.debug("[AUDIT] No running event loop, skipping audit event emission")
