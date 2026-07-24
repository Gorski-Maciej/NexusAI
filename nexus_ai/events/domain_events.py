"""Domain events -- msgspec-based with Tagged Unions and __init_subclass__ auto-registration."""

from __future__ import annotations

import uuid
from decimal import Decimal
from typing import Any, ClassVar

import msgspec
import pendulum


class DomainEvent(msgspec.Struct, kw_only=True, frozen=True, tag_field="event_type"):
    """Base domain event with Tagged Unions -- explicit _event_tag + __init_subclass__ auto-registration.

    INNOWACJA #6 v7.0: Business Event Versioning.
    Każdy domain event ma wersję schematu (event_schema_version).
    Event store przechowuje wszystkie wersje. Projekcje obsługują upcasting (v1 → v2).
    """

    event_id: str = msgspec.field(default_factory=lambda: uuid.uuid4().hex)
    timestamp: str = msgspec.field(default_factory=lambda: pendulum.now("UTC").isoformat())
    aggregate_id: str = ""
    aggregate_type: str = ""
    version: int = 0
    event_schema_version: int = 1  # INNOWACJA #6 v7.0: Business Event Versioning
    metadata: dict[str, Any] = msgspec.field(default_factory=dict)

    _event_tag: ClassVar[str] = ""
    _event_description: ClassVar[str] = ""
    _registry: ClassVar[dict[str, tuple[type[DomainEvent], str]]] = {}

    def __init_subclass__(cls, **kwargs: Any) -> None:
        super().__init_subclass__(**kwargs)
        if cls._event_tag:
            cls._registry[cls._event_tag] = (cls, cls._event_description)


class InvoiceCreated(DomainEvent, tag="invoice.created"):
    _event_tag = "invoice.created"
    _event_description = "Faktura utworzona w systemie (po OCR)"
    aggregate_type: str = "invoice"
    number: str = ""
    contractor_nip: str = ""
    contractor_name: str = ""
    amount_net: Decimal = Decimal("0.00")
    amount_gross: Decimal = Decimal("0.00")
    currency: str = "PLN"
    category: str = ""
    issue_date: str = ""
    file_path: str = ""


class InvoiceSubmitted(DomainEvent, tag="invoice.submitted"):
    _event_tag = "invoice.submitted"
    _event_description = "Faktura przesłana do decyzji (DecisionEngine)"
    aggregate_type: str = "invoice"
    amount_gross: Decimal = Decimal("0.00")
    contractor_nip: str = ""


class InvoiceApproved(DomainEvent, tag="invoice.approved"):
    _event_tag = "invoice.approved"
    _event_description = "Faktura zatwierdzona (auto-post lub manualnie)"
    aggregate_type: str = "invoice"
    approved_by: str = "system"
    trust_score: float = 0.0
    decision_level: str = "auto"


class InvoiceRejected(DomainEvent, tag="invoice.rejected"):
    _event_tag = "invoice.rejected"
    _event_description = "Faktura odrzucona (manualnie)"
    aggregate_type: str = "invoice"
    rejected_by: str = ""
    reason: str = ""


class InvoiceBlocked(DomainEvent, tag="invoice.blocked"):
    _event_tag = "invoice.blocked"
    _event_description = "Faktura zablokowana (RiskGuard / anomalia)"
    aggregate_type: str = "invoice"
    blocked_by: str = "risk_guard"
    reason: str = ""
    risk_score: float = 0.0


class InvoicePaid(DomainEvent, tag="invoice.paid"):
    _event_tag = "invoice.paid"
    _event_description = "Faktura opłacona (przez TigerBeetle)"
    aggregate_type: str = "invoice"
    amount_gross: Decimal = Decimal("0.00")
    paid_at: str = ""
    transaction_id: str = ""


class DecisionMade(DomainEvent, tag="decision.made"):
    _event_tag = "decision.made"
    _event_description = "Decyzja podjęta przez system (DecisionEngine)"
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
    _event_tag = "decision.overridden"
    _event_description = "Decyzja nadpisana przez użytkownika"
    aggregate_type: str = "decision"
    invoice_id: str = ""
    original_decision: str = ""
    user_decision: str = ""
    user_id: str = ""


class OutboxEventEmitted(DomainEvent, tag="outbox.emitted"):
    _event_tag = "outbox.emitted"
    _event_description = "Zdarzenie outbox wyemitowane"
    aggregate_type: str = "outbox"
    outbox_event_type: str = ""
    payload_json: str = ""


class NotificationSent(DomainEvent, tag="notification.sent"):
    _event_tag = "notification.sent"
    _event_description = "Powiadomienie wysłane do użytkownika"
    aggregate_type: str = "notification"
    user_id: str = ""
    notification_type: str = "info"
    title: str = ""
    channels: list[str] = []


# ── Serialization helpers ─────────────────────────────────────────────

def domain_event_from_dict(data: dict[str, Any]) -> DomainEvent:
    return msgspec.convert(data, DomainEvent, strict=False)


def encode_event(event: DomainEvent) -> bytes:
    return msgspec.msgpack.encode(event)


def decode_event(data: bytes) -> DomainEvent:
    return msgspec.msgpack.decode(data, type=DomainEvent)


# ── INNOWACJA #6 v7.0: Business Event Versioning / Upcasting ─────────────

# Registry dla upcasterów: mapowanie (event_type, from_version) → upcast funkcja
_upcast_registry: dict[tuple[str, int], Any] = {}


def register_upcaster(
    event_type: str,
    from_version: int,
    upcast_fn: Any,
) -> None:
    """Zarejestruj funkcję upcastingu dla konkretnego typu eventu i wersji.

    Args:
        event_type: Typ eventu (np. "invoice.created").
        from_version: Wersja źródłowa schematu.
        upcast_fn: Funkcja (dict) → dict przekształcająca starą wersję w nową.
    """
    _upcast_registry[(event_type, from_version)] = upcast_fn


def upcast_event(event_dict: dict[str, Any], target_version: int = 1) -> dict[str, Any]:
    """Upcastuj event do docelowej wersji.

    Iteruje przez zarejestrowane upcastery aż osiągnie target_version.
    Jeśli brak upcastera — zwraca bez zmian.
    """
    event_type = event_dict.get("event_type", "")
    current = event_dict.get("event_schema_version", 1)
    while current < target_version:
        upcaster = _upcast_registry.get((event_type, current))
        if upcaster is None:
            break
        event_dict = upcaster(event_dict)
        current += 1
        event_dict["event_schema_version"] = current
    return event_dict


# ── JSON Schema (auto from registry via __init_subclass__) ────────────

_SCHEMAS_CACHE: dict[str, dict[str, Any]] | None = None


def _build_all_schemas() -> dict[str, dict[str, Any]]:
    schemas: dict[str, dict[str, Any]] = {}
    for event_type, (event_class, description) in DomainEvent._registry.items():
        try:
            schema = msgspec.json.schema(event_class)
            schema["description"] = description
            schema["$id"] = f"https://nexusai.app/schemas/events/{event_type}.json"
            schema["$schema"] = "https://json-schema.org/draft/2020-12/schema"
            schemas[event_type] = schema
        except Exception as exc:
            schemas[event_type] = dict(title=event_class.__name__, type="object", description=str(exc))
    return schemas


def get_schema(event_type: str) -> dict[str, Any] | None:
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
    return {et: dict(title=cls.__name__, description=desc, event_type=et)
            for et, (cls, desc) in DomainEvent._registry.items()}


def get_schema_summary() -> dict[str, Any]:
    schemas = get_all_schemas()
    base_schema = msgspec.json.schema(DomainEvent)
    base_schema.setdefault("title", "DomainEvent")
    base_schema["available_event_types"] = list(DomainEvent._registry.keys())
    return {
        "total_events": len(schemas),
        "event_types": list(schemas.keys()),
        "schemas": schemas,
        "base_schema": base_schema,
        "generated_at": pendulum.now("UTC").isoformat(),
    }


class DomainEventSchemaRegistry:
    __slots__ = ()
    def get_schema(self, event_type: str) -> dict[str, Any] | None:
        return get_schema(event_type)

    def get_all(self) -> dict[str, dict[str, Any]]:
        return get_all_schemas()

    def refresh(self) -> None:
        global _SCHEMAS_CACHE
        _SCHEMAS_CACHE = None
