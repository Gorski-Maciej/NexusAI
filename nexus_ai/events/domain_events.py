"""Domain events + JSON Schema — strongly typed, msgspec-based event classes.

Każdy event jest niezmiennym (immutable) msgspec.Struct z event_id, version,
timestamp i Tagged Unions (tag_field="event_type") dla automatycznej deserializacji.
JSON Schema generowane przez msgspec.json.schema() z cache'owaniem.
"""

from __future__ import annotations

import uuid
from typing import Any

import msgspec
import pendulum


# ── Base Domain Event ─────────────────────────────────────────────────────


class DomainEvent(msgspec.Struct, kw_only=True, frozen=True, tag_field="event_type"):
    """Bazowa klasa dla wszystkich eventów domenowych — z Tagged Unions.

    Używa ``tag_field=\"event_type\"`` — msgspec automatycznie wybiera
    konkretną klasę eventu na podstawie wartości pola ``event_type``
    podczas deserializacji. Zastępuje ręczny ``_EVENT_TYPE_REGISTRY``
    i funkcję ``domain_event_from_dict()``.
    """
    event_id: str = msgspec.field(default_factory=lambda: uuid.uuid4().hex)
    timestamp: str = msgspec.field(default_factory=lambda: pendulum.now("UTC").isoformat())
    aggregate_id: str = ""
    aggregate_type: str = ""
    version: int = 0
    metadata: dict[str, Any] = msgspec.field(default_factory=dict)


# ── Invoice Events ────────────────────────────────────────────────────────


class InvoiceCreated(DomainEvent, tag="invoice.created"):
    aggregate_type: str = "invoice"
    number: str = ""
    contractor_nip: str = ""
    contractor_name: str = ""
    amount_net: float = 0.0
    amount_gross: float = 0.0
    currency: str = "PLN"
    category: str = ""
    issue_date: str = ""
    file_path: str = ""


class InvoiceSubmitted(DomainEvent, tag="invoice.submitted"):
    aggregate_type: str = "invoice"
    amount_gross: float = 0.0
    contractor_nip: str = ""


class InvoiceApproved(DomainEvent, tag="invoice.approved"):
    aggregate_type: str = "invoice"
    approved_by: str = "system"
    trust_score: float = 0.0
    decision_level: str = "auto"


class InvoiceRejected(DomainEvent, tag="invoice.rejected"):
    aggregate_type: str = "invoice"
    rejected_by: str = ""
    reason: str = ""


class InvoiceBlocked(DomainEvent, tag="invoice.blocked"):
    aggregate_type: str = "invoice"
    blocked_by: str = "risk_guard"
    reason: str = ""
    risk_score: float = 0.0


class InvoicePaid(DomainEvent, tag="invoice.paid"):
    aggregate_type: str = "invoice"
    amount_gross: float = 0.0
    paid_at: str = ""
    transaction_id: str = ""


# ── Decision Events ───────────────────────────────────────────────────────


class DecisionMade(DomainEvent, tag="decision.made"):
    aggregate_type: str = "decision"
    invoice_id: str = ""
    decision: str = ""
    trust_score: float = 0.0
    ai_confidence: float = 0.0
    alpha_vote: str = ""
    beta_vote: str = ""
    gamma_vote: str = ""
    decision_pattern: str = ""
    reasoning: str = ""


class DecisionOverridden(DomainEvent, tag="decision.overridden"):
    aggregate_type: str = "decision"
    invoice_id: str = ""
    original_decision: str = ""
    user_decision: str = ""
    user_id: str = ""


# ── Outbox & Notification Events ─────────────────────────────────────────


class OutboxEventEmitted(DomainEvent, tag="outbox.emitted"):
    aggregate_type: str = "outbox"
    outbox_event_type: str = ""
    payload_json: str = ""


class NotificationSent(DomainEvent, tag="notification.sent"):
    aggregate_type: str = "notification"
    user_id: str = ""
    notification_type: str = "info"
    title: str = ""
    channels: list[str] = []


# ── Event Registry (for schema generation) ────────────────────────────────

EventRegistryEntry = tuple[str, type[DomainEvent], str]

EVENT_REGISTRY: list[EventRegistryEntry] = [
    ("invoice.created", InvoiceCreated, "Faktura utworzona w systemie (po OCR)"),
    ("invoice.submitted", InvoiceSubmitted, "Faktura przesłana do decyzji (DecisionEngine)"),
    ("invoice.approved", InvoiceApproved, "Faktura zatwierdzona (auto-post lub manualnie)"),
    ("invoice.rejected", InvoiceRejected, "Faktura odrzucona (manualnie)"),
    ("invoice.blocked", InvoiceBlocked, "Faktura zablokowana (RiskGuard / anomalia)"),
    ("invoice.paid", InvoicePaid, "Faktura opłacona (przez TigerBeetle)"),
    ("decision.made", DecisionMade, "Decyzja podjęta przez system (DecisionEngine)"),
    ("decision.overridden", DecisionOverridden, "Decyzja nadpisana przez użytkownika"),
    ("outbox.emitted", OutboxEventEmitted, "Zdarzenie outbox wyemitowane"),
    ("notification.sent", NotificationSent, "Powiadomienie wysłane do użytkownika"),
]


# ── Serialization helpers (Tagged Unions) ────────────────────────────────


def domain_event_from_dict(data: dict[str, Any]) -> DomainEvent:
    """Deserializuj słownik na event przez Tagged Unions. Backward compat."""
    return msgspec.convert(data, DomainEvent, strict=False)


def encode_event(event: DomainEvent) -> bytes:
    """Zakoduj event do msgpack bytes."""
    return msgspec.msgpack.encode(event)


def decode_event(data: bytes) -> DomainEvent:
    """Dekoduj msgpack bytes na event przez Tagged Unions."""
    return msgspec.msgpack.decode(data, type=DomainEvent)


# ── JSON Schema Generation (merged from event_schema.py) ──────────────────

_SCHEMAS_CACHE: dict[str, dict[str, Any]] | None = None
_MAP_CACHE: dict[str, dict[str, Any]] | None = None


def _build_all_schemas() -> dict[str, dict[str, Any]]:
    schemas: dict[str, dict[str, Any]] = {}
    for event_type, event_class, description in EVENT_REGISTRY:
        try:
            schema = msgspec.json.schema(event_class)
            schema["description"] = description
            schema["event_type"] = event_type
            schema["$id"] = f"https://nexusai.app/schemas/events/{event_type}.json"
            schema["$schema"] = "https://json-schema.org/draft/2020-12/schema"
            schemas[event_type] = schema
        except Exception as exc:
            schemas[event_type] = dict(title=event_class.__name__, type="object",
                                       description=f"{description} (schema gen failed: {exc})",
                                       event_type=event_type)
    return schemas


def get_schema(event_type: str) -> dict[str, Any] | None:
    """Zwraca JSON Schema dla konkretnego eventu (cached)."""
    global _SCHEMAS_CACHE
    if _SCHEMAS_CACHE is None:
        _SCHEMAS_CACHE = _build_all_schemas()
    return _SCHEMAS_CACHE.get(event_type)


def get_all_schemas() -> dict[str, dict[str, Any]]:
    global _SCHEMAS_CACHE
    if _SCHEMAS_CACHE is None:
        _SCHEMAS_CACHE = _build_all_schemas()
    return dict(_SCHEMAS_CACHE)


def get_event_type_map() -> dict[str, dict[str, Any]]:
    global _MAP_CACHE
    if _MAP_CACHE is None:
        _MAP_CACHE = {et: dict(title=cls.__name__, description=desc, event_type=et)
                      for et, cls, desc in EVENT_REGISTRY}
    return dict(_MAP_CACHE)


def get_schema_summary() -> dict[str, Any]:
    schemas = get_all_schemas()
    base_schema = msgspec.json.schema(DomainEvent)
    base_schema.setdefault("title", "DomainEvent")
    base_schema["available_event_types"] = [e[0] for e in EVENT_REGISTRY]
    return {"total_events": len(schemas), "event_types": list(schemas.keys()),
            "schemas": schemas, "base_schema": base_schema,
            "generated_at": pendulum.now("UTC").isoformat()}


class DomainEventSchemaRegistry:
    """Rejestr JSON Schema dla DI. Deleguje do global cache."""
    def get_schema(self, event_type: str) -> dict[str, Any] | None:
        return get_schema(event_type)
    def get_all(self) -> dict[str, dict[str, Any]]:
        return get_all_schemas()
    def refresh(self) -> None:
        global _SCHEMAS_CACHE, _MAP_CACHE
        _SCHEMAS_CACHE = _MAP_CACHE = None
