"""taskiq_events.py — Generic Taskiq handlers for domain event emission.

Consolidated from 11 separate @broker.task handlers into 2 generic handlers:
  1. emit_event — generic event emitter using DomainEvent._registry + match/case
  2. emit_domain_event — fallback for custom event types

Uses DomainEvent._registry (auto-populated by __init_subclass__) for type dispatch.
"""

from __future__ import annotations

import hashlib
from typing import Any

from structlog import get_logger

from nexus_ai.core.broker import broker
from nexus_ai.events import (
    DomainEvent,
    EventStore,
    InvoiceApproved,
    InvoiceBlocked,
    InvoiceCreated,
    InvoicePaid,
    InvoiceRejected,
    InvoiceSubmitted,
    JetStreamEventBus,
)
from nexus_ai.events.domain_events import (
    DecisionMade,
    DecisionOverridden,
    NotificationSent,
    OutboxEventEmitted,
)

logger = get_logger("nexus.events.tasks")

_event_store: EventStore | None = None
_jetstream: JetStreamEventBus | None = None


def _get_event_store() -> EventStore:
    global _event_store
    if _event_store is None:
        from nexus_ai.core.config import AppConfig
        config = AppConfig()
        _event_store = EventStore(db_path=str(config.base_dir / "app_data" / "events.db"))
    return _event_store


async def _get_jetstream() -> JetStreamEventBus | None:
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
        _jetstream = None
    return _jetstream


async def _next_version(aggregate_type: str, aggregate_id: str) -> int:
    store = _get_event_store()
    return (await store.get_version(aggregate_type=aggregate_type, aggregate_id=aggregate_id)) + 1


async def _emit_event(aggregate_type: str, aggregate_id: str, event: DomainEvent) -> str:
    try:
        store = _get_event_store()
        await store.append_events(aggregate_type=aggregate_type, aggregate_id=aggregate_id, events=[event])
        logger.info("[EVENT-TASKS] Appended %s:%s version=%d", event.event_type, event.aggregate_id, event.version)
        if (jetstream := await _get_jetstream()) is not None:
            if not await jetstream.publish(event):
                logger.warning("[EVENT-TASKS] JetStream publish failed for %s:%s", event.event_type, event.aggregate_id)
        else:
            logger.debug("[EVENT-TASKS] No JetStream — event %s:%s stored locally", event.event_type, event.aggregate_id)
        return event.event_id
    except Exception as exc:
        logger.error("[EVENT-TASKS] Failed to emit %s:%s: %s", event.event_type, event.aggregate_id, exc)
        raise


# ── Event constructors registry — maps event_type -> (aggregate_type, constructor) ──

_EVENT_BUILDERS: dict[str, tuple[str, type[DomainEvent], set[str]]] = {
    "decision.made": ("decision", DecisionMade, {"invoice_id", "decision", "trust_score", "ai_confidence", "alpha_vote", "beta_vote", "gamma_vote", "decision_pattern", "reasoning"}),
    "decision.overridden": ("decision", DecisionOverridden, {"invoice_id", "original_decision", "user_decision", "user_id"}),
    "invoice.created": ("invoice", InvoiceCreated, {"number", "contractor_nip", "contractor_name", "amount_net", "amount_gross", "currency", "category", "issue_date", "file_path"}),
    "invoice.submitted": ("invoice", InvoiceSubmitted, {"amount_gross", "contractor_nip"}),
    "invoice.approved": ("invoice", InvoiceApproved, {"approved_by", "trust_score", "decision_level"}),
    "invoice.rejected": ("invoice", InvoiceRejected, {"rejected_by", "reason"}),
    "invoice.blocked": ("invoice", InvoiceBlocked, {"blocked_by", "reason", "risk_score"}),
    "invoice.paid": ("invoice", InvoicePaid, {"amount_gross", "paid_at", "transaction_id"}),
    "notification.sent": ("notification", NotificationSent, {"user_id", "notification_type", "title", "channels"}),
    "outbox.emitted": ("outbox", OutboxEventEmitted, {"outbox_event_type", "payload_json"}),
}


@broker.task(
    task_name="event_emit",
    labels=dict(service="events", operation="emit", criticality="high"),
    timeout=30.0,
)
async def emit_event_task(event_type: str, aggregate_id: str, **fields: Any) -> str:
    """Generic event emitter — dispatches via _EVENT_BUILDERS registry.

    Usage:
        await emit_event_task("invoice.created", invoice_id, number="FV/001", ...)
        await emit_event_task("decision.made", f"decision:{invoice_id}", decision="APPROVE", ...)
    """
    builder = _EVENT_BUILDERS.get(event_type)
    if builder is None:
        raise ValueError(f"Unknown event type: {event_type}. Available: {list(_EVENT_BUILDERS.keys())}")

    agg_type, event_cls, _ = builder
    version = await _next_version(agg_type, aggregate_id)
    # Filter fields to only what the event class accepts
    event_fields = {k: v for k, v in fields.items() if k in event_cls.__struct_fields__}
    event = event_cls(aggregate_id=aggregate_id, version=version, metadata=fields.get("metadata", {}), **event_fields)
    return await _emit_event(agg_type, aggregate_id, event)


@broker.task(
    task_name="event_emit_custom",
    labels=dict(service="events", operation="emit", event_type="custom", criticality="low"),
    timeout=30.0,
)
async def emit_domain_event_task(event_type: str, aggregate_id: str, aggregate_type: str = "custom", version: int = 1, data: dict[str, Any] | None = None, metadata: dict[str, Any] | None = None) -> str:
    """Fallback for custom event types not in _EVENT_BUILDERS."""
    store = _get_event_store()
    current = await store.get_version(aggregate_type=aggregate_type, aggregate_id=aggregate_id)
    combined = dict(metadata) if metadata else {}
    if data:
        combined["data"] = data
    event = DomainEvent(event_type=event_type, aggregate_id=aggregate_id, aggregate_type=aggregate_type, version=current + 1, metadata=combined)
    return await _emit_event(aggregate_type, aggregate_id, event)


def make_event_task_id(task_name: str, **kwargs: Any) -> str:
    content = f"{task_name}:{sorted(kwargs.items())}"
    return hashlib.sha256(content.encode()).hexdigest()[:32]
