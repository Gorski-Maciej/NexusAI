"""
events/taskiq_events.py — Taskiq handlers for domain event emission.

SUPERMOC TASKIQ:
  - @broker.task z labels zastępuje EventEmitter
  - Deterministic task_id przez broker._task_id_generator — JetStream deduplikacja
  - Każdy event jest appendowany do EventStore + publikowany przez JetStream
  - Graceful degradation: EventStore zawsze działa, JetStream opcjonalny

Usage:
    from nexus_ai.core.broker import broker

    # Zamiast: await emitter.emit_decision_made(invoice_id=..., ...)
    await broker.kick("event_emit_decision_made", invoice_id=..., ...)
"""

from __future__ import annotations

import hashlib
from typing import Any

import pendulum
from structlog import get_logger

from nexus_ai.core.broker import broker
from nexus_ai.events import (
    DecisionMade,
    DecisionOverridden,
    DomainEvent,
    EventStore,
    InvoiceApproved,
    InvoiceBlocked,
    InvoiceCreated,
    InvoicePaid,
    InvoiceRejected,
    InvoiceSubmitted,
    JetStreamEventBus,
    NotificationSent,
    OutboxEventEmitted,
)

logger = get_logger("nexus.events.tasks")

# ── Lazy singletons for EventStore + JetStream ────────────────────────────

_event_store: EventStore | None = None
_jetstream: JetStreamEventBus | None = None


def _get_event_store() -> EventStore:
    """Lazy-init EventStore singleton."""
    global _event_store
    if _event_store is None:
        from nexus_ai.core.config import AppConfig

        config = AppConfig()
        _event_store = EventStore(
            db_path=str(config.base_dir / "app_data" / "events.db"),
        )
    return _event_store


async def _get_jetstream() -> JetStreamEventBus | None:
    """Lazy-init JetStreamEventBus singleton (graceful degradation)."""
    global _jetstream
    if _jetstream is not None:
        return _jetstream
    try:
        from nexus_ai.core.config import AppConfig

        config = AppConfig()
        bus = JetStreamEventBus(nats_servers=config.nats_url)
        await bus.connect()
        _jetstream = bus
        logger.info("[EVENT-TASKS] JetStream connected")
    except Exception as exc:
        logger.warning("[EVENT-TASKS] JetStream unavailable: %s", exc)
        _jetstream = None  # Mark as attempted
    return _jetstream


async def _next_version(aggregate_type: str, aggregate_id: str) -> int:
    """Pobierz następną wersję dla agregatu z EventStore."""
    store = _get_event_store()
    current = await store.get_version(aggregate_type=aggregate_type, aggregate_id=aggregate_id)
    return current + 1


# ── Internal emit helper ──────────────────────────────────────────────────


async def _emit_event(
    aggregate_type: str,
    aggregate_id: str,
    event: DomainEvent,
) -> str:
    """Append to EventStore + publish to JetStream.

    Returns event.event_id.
    """
    try:
        store = _get_event_store()
        await store.append_events(
            aggregate_type=aggregate_type,
            aggregate_id=aggregate_id,
            events=[event],
        )
        logger.info(
            "[EVENT-TASKS] Appended %s:%s version=%d to EventStore",
            event.event_type,
            event.aggregate_id,
            event.version,
        )

        # Publikuj przez JetStream (jeśli dostępny)
        jetstream = await _get_jetstream()
        if jetstream is not None:
            published = await jetstream.publish(event)
            if not published:
                logger.warning(
                    "[EVENT-TASKS] JetStream publish failed for %s:%s "
                    "(event stored in EventStore, will be retried)",
                    event.event_type,
                    event.aggregate_id,
                )
        else:
            logger.debug(
                "[EVENT-TASKS] No JetStream — event %s:%s stored locally",
                event.event_type,
                event.aggregate_id,
            )

        return event.event_id

    except Exception as exc:
        logger.error(
            "[EVENT-TASKS] Failed to emit %s:%s: %s",
            event.event_type,
            event.aggregate_id,
            exc,
        )
        raise


# ═══════════════════════════════════════════════════════════════════════════
# TASK HANDLERS — @broker.task dla każdego typu eventu
# ═══════════════════════════════════════════════════════════════════════════


@broker.task(
    task_name="event_emit_decision_made",
    labels={"service": "events", "operation": "emit", "event_type": "decision.made", "criticality": "high"},
    timeout=30.0,
)
async def emit_decision_made_task(
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
    """Emit DecisionMade event via EventStore + JetStream."""
    version = await _next_version("decision", invoice_id)
    event = DecisionMade(
        aggregate_id=f"decision:{invoice_id}",
        version=version,
        invoice_id=invoice_id,
        decision=decision,
        trust_score=trust_score,
        ai_confidence=ai_confidence,
        alpha_vote=alpha_vote,
        beta_vote=beta_vote,
        gamma_vote=gamma_vote,
        decision_pattern=decision_pattern,
        reasoning=reasoning,
        metadata=metadata or {},
    )
    return await _emit_event("decision", f"decision:{invoice_id}", event)


@broker.task(
    task_name="event_emit_decision_overridden",
    labels={"service": "events", "operation": "emit", "event_type": "decision.overridden", "criticality": "high"},
    timeout=30.0,
)
async def emit_decision_overridden_task(
    invoice_id: str,
    original_decision: str,
    user_decision: str,
    user_id: str,
    metadata: dict[str, Any] | None = None,
) -> str:
    """Emit DecisionOverridden event via EventStore + JetStream."""
    version = await _next_version("decision", invoice_id)
    event = DecisionOverridden(
        aggregate_id=f"decision:{invoice_id}",
        version=version,
        invoice_id=invoice_id,
        original_decision=original_decision,
        user_decision=user_decision,
        user_id=user_id,
        metadata=metadata or {},
    )
    return await _emit_event("decision", f"decision:{invoice_id}", event)


@broker.task(
    task_name="event_emit_invoice_created",
    labels={"service": "events", "operation": "emit", "event_type": "invoice.created", "criticality": "high"},
    timeout=30.0,
)
async def emit_invoice_created_task(
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
    """Emit InvoiceCreated event via EventStore + JetStream."""
    version = await _next_version("invoice", invoice_id)
    event = InvoiceCreated(
        aggregate_id=invoice_id,
        version=version,
        number=number,
        contractor_nip=contractor_nip,
        contractor_name=contractor_name,
        amount_net=amount_net,
        amount_gross=amount_gross,
        currency=currency,
        category=category,
        issue_date=issue_date,
        file_path=file_path,
        metadata=metadata or {},
    )
    return await _emit_event("invoice", invoice_id, event)


@broker.task(
    task_name="event_emit_invoice_submitted",
    labels={"service": "events", "operation": "emit", "event_type": "invoice.submitted", "criticality": "medium"},
    timeout=30.0,
)
async def emit_invoice_submitted_task(
    invoice_id: str,
    amount_gross: float = 0.0,
    contractor_nip: str = "",
    metadata: dict[str, Any] | None = None,
) -> str:
    """Emit InvoiceSubmitted event via EventStore + JetStream."""
    version = await _next_version("invoice", invoice_id)
    event = InvoiceSubmitted(
        aggregate_id=invoice_id,
        version=version,
        amount_gross=amount_gross,
        contractor_nip=contractor_nip,
        metadata=metadata or {},
    )
    return await _emit_event("invoice", invoice_id, event)


@broker.task(
    task_name="event_emit_invoice_approved",
    labels={"service": "events", "operation": "emit", "event_type": "invoice.approved", "criticality": "high"},
    timeout=30.0,
)
async def emit_invoice_approved_task(
    invoice_id: str,
    approved_by: str = "system",
    trust_score: float = 0.0,
    decision_level: str = "auto",
    metadata: dict[str, Any] | None = None,
) -> str:
    """Emit InvoiceApproved event via EventStore + JetStream."""
    version = await _next_version("invoice", invoice_id)
    event = InvoiceApproved(
        aggregate_id=invoice_id,
        version=version,
        approved_by=approved_by,
        trust_score=trust_score,
        decision_level=decision_level,
        metadata=metadata or {},
    )
    return await _emit_event("invoice", invoice_id, event)


@broker.task(
    task_name="event_emit_invoice_rejected",
    labels={"service": "events", "operation": "emit", "event_type": "invoice.rejected", "criticality": "medium"},
    timeout=30.0,
)
async def emit_invoice_rejected_task(
    invoice_id: str,
    rejected_by: str = "system",
    reason: str = "",
    metadata: dict[str, Any] | None = None,
) -> str:
    """Emit InvoiceRejected event via EventStore + JetStream."""
    version = await _next_version("invoice", invoice_id)
    event = InvoiceRejected(
        aggregate_id=invoice_id,
        version=version,
        rejected_by=rejected_by,
        reason=reason,
        metadata=metadata or {},
    )
    return await _emit_event("invoice", invoice_id, event)


@broker.task(
    task_name="event_emit_invoice_blocked",
    labels={"service": "events", "operation": "emit", "event_type": "invoice.blocked", "criticality": "high"},
    timeout=30.0,
)
async def emit_invoice_blocked_task(
    invoice_id: str,
    blocked_by: str = "risk_guard",
    reason: str = "",
    risk_score: float = 0.0,
    metadata: dict[str, Any] | None = None,
) -> str:
    """Emit InvoiceBlocked event via EventStore + JetStream."""
    version = await _next_version("invoice", invoice_id)
    event = InvoiceBlocked(
        aggregate_id=invoice_id,
        version=version,
        blocked_by=blocked_by,
        reason=reason,
        risk_score=risk_score,
        metadata=metadata or {},
    )
    return await _emit_event("invoice", invoice_id, event)


@broker.task(
    task_name="event_emit_invoice_paid",
    labels={"service": "events", "operation": "emit", "event_type": "invoice.paid", "criticality": "medium"},
    timeout=30.0,
)
async def emit_invoice_paid_task(
    invoice_id: str,
    amount_gross: float = 0.0,
    paid_at: str = "",
    transaction_id: str = "",
    metadata: dict[str, Any] | None = None,
) -> str:
    """Emit InvoicePaid event via EventStore + JetStream."""
    version = await _next_version("invoice", invoice_id)
    event = InvoicePaid(
        aggregate_id=invoice_id,
        version=version,
        amount_gross=amount_gross,
        paid_at=paid_at or pendulum.now("UTC").isoformat(),
        transaction_id=transaction_id,
        metadata=metadata or {},
    )
    return await _emit_event("invoice", invoice_id, event)


@broker.task(
    task_name="event_emit_notification_sent",
    labels={"service": "events", "operation": "emit", "event_type": "notification.sent", "criticality": "low"},
    timeout=30.0,
)
async def emit_notification_sent_task(
    user_id: str,
    notification_type: str = "info",
    title: str = "",
    channels: list[str] | None = None,
    metadata: dict[str, Any] | None = None,
) -> str:
    """Emit NotificationSent event via EventStore + JetStream."""
    aggregate_id = user_id
    version = await _next_version("notification", aggregate_id)
    event = NotificationSent(
        aggregate_id=aggregate_id,
        version=version,
        user_id=user_id,
        notification_type=notification_type,
        title=title,
        channels=channels or [],
        metadata=metadata or {},
    )
    return await _emit_event("notification", aggregate_id, event)


@broker.task(
    task_name="event_emit_outbox_emitted",
    labels={"service": "events", "operation": "emit", "event_type": "outbox.emitted", "criticality": "high"},
    timeout=30.0,
)
async def emit_outbox_emitted_task(
    aggregate_id: str,
    outbox_event_type: str,
    payload_json: str,
    metadata: dict[str, Any] | None = None,
) -> str:
    """Emit OutboxEventEmitted event via EventStore + JetStream."""
    version = await _next_version("outbox", aggregate_id)
    event = OutboxEventEmitted(
        aggregate_id=aggregate_id,
        version=version,
        outbox_event_type=outbox_event_type,
        payload_json=payload_json,
        metadata=metadata or {},
    )
    return await _emit_event("outbox", aggregate_id, event)


@broker.task(
    task_name="event_emit_domain_event",
    labels={"service": "events", "operation": "emit", "event_type": "custom", "criticality": "low"},
    timeout=30.0,
)
async def emit_domain_event_task(
    event_type: str,
    aggregate_id: str,
    aggregate_type: str = "custom",
    version: int = 1,
    data: dict[str, Any] | None = None,
    metadata: dict[str, Any] | None = None,
) -> str:
    """Emit a generic DomainEvent (for custom event types like audit.change_logged).

    Args:
        event_type: Type of the event (e.g. "audit.change_logged").
        aggregate_id: ID of the aggregate.
        aggregate_type: Type of the aggregate (default: "custom").
        version: Version number (default: 1).
        data: Event data payload.
        metadata: Additional metadata.

    Returns:
        event_id.
    """
    store = _get_event_store()
    current = await store.get_version(aggregate_type=aggregate_type, aggregate_id=aggregate_id)
    actual_version = current + 1
    # DomainEvent is frozen=True — build combined metadata before creating event
    combined_metadata = dict(metadata) if metadata else {}
    if data:
        combined_metadata["data"] = data
    event = DomainEvent(
        event_type=event_type,
        aggregate_id=aggregate_id,
        aggregate_type=aggregate_type,
        version=actual_version,
        metadata=combined_metadata,
    )
    return await _emit_event(aggregate_type, aggregate_id, event)


# ── Helper: deterministyczne task_id dla broker.kick ──────────────────────


def make_event_task_id(task_name: str, **kwargs: Any) -> str:
    """Generuj deterministyczne task_id dla event emission.

    Używa SHA-256 z task_name + sorted kwargs, identycznie jak
    _task_id_generator w broker.py. Zapewnia deduplikację przez JetStream.

    Usage:
        await broker.kick(
            "event_emit_decision_made",
            task_id=make_event_task_id("event_emit_decision_made", invoice_id=invoice_id, ...),
            invoice_id=invoice_id,
            ...
        )
    """
    content = f"{task_name}:{sorted(kwargs.items())}"
    return hashlib.sha256(content.encode()).hexdigest()[:32]
