"""
NexusAI Event Sourcing — Event-Driven Architecture on NATS JetStream.

Pakiet implementuje pełny Event Sourcing zgodnie z Fazą 3 audytu:
  - Domenowe eventy (msgspec.Struct) z silnym typowaniem
  - Append-only Event Store (SQLite) z snapshotami
  - NATS JetStream pub/sub dla gwarantowanej dostawy
  - CQRS Projections z checkpointami do odtwarzania stanu

Architektura:
    ┌─────────────┐     ┌──────────────┐     ┌──────────────┐
    │  Serwis     │────▶│  EventStore  │────▶│   JetStream  │
    │ (Invoice)   │     │  (append)    │     │   (publish)  │
    └─────────────┘     └──────────────┘     └──────┬───────┘
                                                    │
                                           ┌────────▼───────┐
                                           │   Projections  │
                                           │ (CQRS read)    │
                                           └────────────────┘

Usage:
    from nexus_ai.events import EventStore, JetStreamEventBus, InvoiceCreated

    store = EventStore(sqlite_path="app_data/events.db")
    bus = JetStreamEventBus(nats_servers="nats://localhost:4222")

    event = InvoiceCreated(
        aggregate_id="inv-123",
        version=1,
        number="FV/2026/001",
        amount_gross=12300.00,
    )
    await store.append_events("invoice", "inv-123", [event], expected_version=0)
    await bus.publish(event)
"""

from __future__ import annotations

from nexus_ai.events.domain_events import (
    DomainEvent,
    InvoiceCreated,
    InvoiceSubmitted,
    InvoiceApproved,
    InvoiceRejected,
    InvoiceBlocked,
    InvoicePaid,
    DecisionMade,
    DecisionOverridden,
    NotificationSent,
    OutboxEventEmitted,
    domain_event_from_dict,
)

from nexus_ai.events.event_store import EventStore

from nexus_ai.events.jetstream_bus import JetStreamEventBus, JetStreamConsumer

from nexus_ai.events.projections import (
    Projection,
    InvoiceProjection,
    DecisionProjection,
)

from nexus_ai.events.projection_worker import ProjectionWorker

from nexus_ai.events.event_schema import (
    DomainEventSchemaRegistry,
    get_all_event_schemas,
    get_event_schema_by_type,
    get_event_type_map,
    get_event_schema_summary,
)

__all__ = [
    # Domain events
    "DomainEvent",
    "NotificationSent",
    "InvoiceCreated",
    "InvoiceSubmitted",
    "InvoiceApproved",
    "InvoiceRejected",
    "InvoiceBlocked",
    "InvoicePaid",
    "DecisionMade",
    "DecisionOverridden",
    "OutboxEventEmitted",
    "domain_event_from_dict",
    # Event store
    "EventStore",
    # JetStream
    "JetStreamEventBus",
    "JetStreamConsumer",
    # Projections
    "Projection",
    "InvoiceProjection",
    "DecisionProjection",
    # Projection Worker
    "ProjectionWorker",
    # Event Schema
    "DomainEventSchemaRegistry",
    "get_all_event_schemas",
    "get_event_schema_by_type",
    "get_event_type_map",
    "get_event_schema_summary",
]
