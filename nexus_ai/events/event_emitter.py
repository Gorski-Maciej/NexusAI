"""
[DEPRECATED] EventEmitter — zastąpiony przez events/taskiq_events.py + broker.kick().

SUPERMOC TASKIQ:
  - Zamiast EventEmitter.emit_*() używaj broker.kick("event_emit_*", ...)
  - Deterministic task_id przez broker._task_id_generator — JetStream deduplikacja
  - Pełna kompatybilność: ta klasa deleguje do broker.kick() z tym samym API

Usage (NOWY SPOSÓB):
    from nexus_ai.core.broker import broker

    await broker.kick(
        "event_emit_decision_made",
        invoice_id=invoice_id,
        decision=verdict.decision,
        ...
    )

Usage (STARY SPOSÓB — deprecated):
    emitter = get_event_emitter()
    await emitter.emit_decision_made(invoice_id=..., decision=...)
"""

from __future__ import annotations

import warnings
from typing import Any

from structlog import get_logger

from nexus_ai.core.broker import broker

logger = get_logger("nexus.events.emitter")

# ── Task name map ─────────────────────────────────────────────────────────
# Mapuje metody EventEmitter na nazwy zadań w taskiq_events.py

_TASK_MAP: dict[str, str] = {
    "emit_decision_made": "event_emit_decision_made",
    "emit_decision_overridden": "event_emit_decision_overridden",
    "emit_invoice_created": "event_emit_invoice_created",
    "emit_invoice_submitted": "event_emit_invoice_submitted",
    "emit_invoice_approved": "event_emit_invoice_approved",
    "emit_invoice_rejected": "event_emit_invoice_rejected",
    "emit_invoice_blocked": "event_emit_invoice_blocked",
    "emit_invoice_paid": "event_emit_invoice_paid",
    "emit_notification_sent": "event_emit_notification_sent",
}


class EventEmitter:
    """[DEPRECATED] Deleguje emisję eventów do broker.kick().

    UWAGA: Ta klasa jest deprecated. Zamiast niej używaj bezpośrednio:
        await broker.kick("event_emit_decision_made", ...)

    Klasa zachowana dla kompatybilności wstecznej podczas migracji.
    Wszystkie metody delegują do broker.kick() z deterministycznym task_id.
    """

    def __init__(self, *args: Any, **kwargs: Any) -> None:
        warnings.warn(
            "EventEmitter jest deprecated. Użyj broker.kick('event_emit_*', ...) zamiast EventEmitter.",
            DeprecationWarning,
            stacklevel=2,
        )
        # Ignorujemy parametry — delegujemy do broker.kick
        super().__init__()

    # ── Decision events ────────────────────────────────────────────────

    async def emit_decision_made(
        self,
        invoice_id: str,
        decision: str,
        trust_score: float = 0.0,
        ai_confidence: float = 0.0,
        alpha_vote: str = "",
        beta_vote: str = "",
        gamma_vote: str = "",
        decision_pattern: str = "",
        reasoning: str = "",
        metadata: dict[str, Any] | None = None,
    ) -> str:
        """[DEPRECATED] Deleguje do broker.kick("event_emit_decision_made", ...)."""
        return await broker.kick(
            "event_emit_decision_made",
            invoice_id=invoice_id,
            decision=decision,
            trust_score=trust_score,
            ai_confidence=ai_confidence,
            alpha_vote=alpha_vote,
            beta_vote=beta_vote,
            gamma_vote=gamma_vote,
            decision_pattern=decision_pattern,
            reasoning=reasoning,
            metadata=metadata,
        )

    async def emit_decision_overridden(
        self,
        invoice_id: str,
        original_decision: str,
        user_decision: str,
        user_id: str,
        metadata: dict[str, Any] | None = None,
    ) -> str:
        """[DEPRECATED] Deleguje do broker.kick("event_emit_decision_overridden", ...)."""
        return await broker.kick(
            "event_emit_decision_overridden",
            invoice_id=invoice_id,
            original_decision=original_decision,
            user_decision=user_decision,
            user_id=user_id,
            metadata=metadata,
        )

    # ── Invoice events ─────────────────────────────────────────────────

    async def emit_invoice_created(
        self,
        invoice_id: str,
        number: str = "",
        contractor_nip: str = "",
        contractor_name: str = "",
        amount_net: float = 0.0,
        amount_gross: float = 0.0,
        currency: str = "PLN",
        category: str = "",
        issue_date: str = "",
        file_path: str = "",
        metadata: dict[str, Any] | None = None,
    ) -> str:
        """[DEPRECATED] Deleguje do broker.kick("event_emit_invoice_created", ...)."""
        return await broker.kick(
            "event_emit_invoice_created",
            invoice_id=invoice_id,
            number=number,
            contractor_nip=contractor_nip,
            contractor_name=contractor_name,
            amount_net=amount_net,
            amount_gross=amount_gross,
            currency=currency,
            category=category,
            issue_date=issue_date,
            file_path=file_path,
            metadata=metadata,
        )

    async def emit_invoice_submitted(
        self,
        invoice_id: str,
        amount_gross: float = 0.0,
        contractor_nip: str = "",
        metadata: dict[str, Any] | None = None,
    ) -> str:
        """[DEPRECATED] Deleguje do broker.kick("event_emit_invoice_submitted", ...)."""
        return await broker.kick(
            "event_emit_invoice_submitted",
            invoice_id=invoice_id,
            amount_gross=amount_gross,
            contractor_nip=contractor_nip,
            metadata=metadata,
        )

    async def emit_invoice_approved(
        self,
        invoice_id: str,
        approved_by: str = "system",
        trust_score: float = 0.0,
        decision_level: str = "auto",
        metadata: dict[str, Any] | None = None,
    ) -> str:
        """[DEPRECATED] Deleguje do broker.kick("event_emit_invoice_approved", ...)."""
        return await broker.kick(
            "event_emit_invoice_approved",
            invoice_id=invoice_id,
            approved_by=approved_by,
            trust_score=trust_score,
            decision_level=decision_level,
            metadata=metadata,
        )

    async def emit_invoice_rejected(
        self,
        invoice_id: str,
        rejected_by: str = "system",
        reason: str = "",
        metadata: dict[str, Any] | None = None,
    ) -> str:
        """[DEPRECATED] Deleguje do broker.kick("event_emit_invoice_rejected", ...)."""
        return await broker.kick(
            "event_emit_invoice_rejected",
            invoice_id=invoice_id,
            rejected_by=rejected_by,
            reason=reason,
            metadata=metadata,
        )

    async def emit_invoice_blocked(
        self,
        invoice_id: str,
        blocked_by: str = "risk_guard",
        reason: str = "",
        risk_score: float = 0.0,
        metadata: dict[str, Any] | None = None,
    ) -> str:
        """[DEPRECATED] Deleguje do broker.kick("event_emit_invoice_blocked", ...)."""
        return await broker.kick(
            "event_emit_invoice_blocked",
            invoice_id=invoice_id,
            blocked_by=blocked_by,
            reason=reason,
            risk_score=risk_score,
            metadata=metadata,
        )

    async def emit_invoice_paid(
        self,
        invoice_id: str,
        amount_gross: float = 0.0,
        paid_at: str = "",
        transaction_id: str = "",
        metadata: dict[str, Any] | None = None,
    ) -> str:
        """[DEPRECATED] Deleguje do broker.kick("event_emit_invoice_paid", ...)."""
        if not paid_at:
            import pendulum
            paid_at = pendulum.now("UTC").isoformat()
        return await broker.kick(
            "event_emit_invoice_paid",
            invoice_id=invoice_id,
            amount_gross=amount_gross,
            paid_at=paid_at,
            transaction_id=transaction_id,
            metadata=metadata,
        )

    # ── Notification events ───────────────────────────────────────────

    async def emit_notification_sent(
        self,
        user_id: str,
        notification_type: str = "info",
        title: str = "",
        channels: list[str] | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> str:
        """[DEPRECATED] Deleguje do broker.kick("event_emit_notification_sent", ...)."""
        return await broker.kick(
            "event_emit_notification_sent",
            user_id=user_id,
            notification_type=notification_type,
            title=title,
            channels=channels or [],
            metadata=metadata,
        )


# ── Global singleton (deprecated) ─────────────────────────────────────────

_default_emitter: EventEmitter | None = None


def get_event_emitter(
    event_store: Any = None,
    jetstream: Any = None,
) -> EventEmitter:
    """[DEPRECATED] Zwraca globalną instancję EventEmitter (singleton).

    UWAGA: Ta funkcja jest deprecated. Użyj bezpośrednio:
        await broker.kick("event_emit_*", ...)

    Zwraca wspóldzieloną instancję EventEmitter która deleguje do broker.kick().
    Parametry ``event_store`` i ``jetstream`` są ignorowane —
    EventEmitter nie zarządza już bezpośrednio EventStore/JetStream.
    """
    global _default_emitter
    if _default_emitter is None:
        _default_emitter = EventEmitter()
    return _default_emitter
