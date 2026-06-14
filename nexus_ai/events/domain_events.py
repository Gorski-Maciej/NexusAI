"""
Domain events — strongly typed, msgspec-based event classes for Event Sourcing.

Każdy event jest niezmiennym (immutable) msgspec.Struct z:
  - event_id: UUID str (unikalny identyfikator eventu)
  - aggregate_id: str (ID agregatu, np. invoice_id)
  - aggregate_type: str (np. "invoice", "decision")
  - event_type: str (np. "invoice.created")
  - version: int (numer wersji agregatu,乐观并发控制)
  - timestamp: str (ISO 8601 UTC)

Konkretne eventy dziedziczą po DomainEvent i dodają własne pola.
"""

from __future__ import annotations

import uuid
from typing import Any

import msgspec
import pendulum


# ── Base Domain Event ─────────────────────────────────────────────────────


class DomainEvent(msgspec.Struct, kw_only=True, frozen=True):
    """Bazowa klasa dla wszystkich eventów domenowych.

    Args:
        aggregate_id: ID agregatu (np. invoice_id, decision_id).
        version: Numer wersji agregatu (optimistic concurrency).
    """

    event_id: str = msgspec.field(default_factory=lambda: uuid.uuid4().hex)
    aggregate_type: str = ""
    event_type: str = ""
    timestamp: str = msgspec.field(default_factory=lambda: pendulum.now("UTC").isoformat())
    aggregate_id: str = ""
    version: int = 0
    metadata: dict[str, Any] = msgspec.field(default_factory=dict)


# ── Invoice Events ────────────────────────────────────────────────────────


class InvoiceCreated(DomainEvent):
    """Faktura została utworzona w systemie (po OCR)."""

    aggregate_type: str = "invoice"
    event_type: str = "invoice.created"

    number: str = ""
    contractor_nip: str = ""
    contractor_name: str = ""
    amount_net: float = 0.0
    amount_gross: float = 0.0
    currency: str = "PLN"
    category: str = ""
    issue_date: str = ""
    file_path: str = ""


class InvoiceSubmitted(DomainEvent):
    """Faktura została przesłana do decyzji (DecisionEngine)."""

    aggregate_type: str = "invoice"
    event_type: str = "invoice.submitted"

    amount_gross: float = 0.0
    contractor_nip: str = ""


class InvoiceApproved(DomainEvent):
    """Faktura została zatwierdzona (auto-post lub manualnie)."""

    aggregate_type: str = "invoice"
    event_type: str = "invoice.approved"

    approved_by: str = "system"  # "system" | "user:{user_id}"
    trust_score: float = 0.0
    decision_level: str = "auto"  # "auto" | "suggest" | "manual"


class InvoiceRejected(DomainEvent):
    """Faktura została odrzucona (manualnie)."""

    aggregate_type: str = "invoice"
    event_type: str = "invoice.rejected"

    rejected_by: str = ""
    reason: str = ""


class InvoiceBlocked(DomainEvent):
    """Faktura została zablokowana (RiskGuard / anomalia)."""

    aggregate_type: str = "invoice"
    event_type: str = "invoice.blocked"

    blocked_by: str = "risk_guard"
    reason: str = ""
    risk_score: float = 0.0


class InvoicePaid(DomainEvent):
    """Faktura została opłacona (przez TigerBeetle)."""

    aggregate_type: str = "invoice"
    event_type: str = "invoice.paid"

    amount_gross: float = 0.0
    paid_at: str = ""
    transaction_id: str = ""


# ── Decision Events ───────────────────────────────────────────────────────


class DecisionMade(DomainEvent):
    """Decyzja została podjęta przez system (DecisionEngine)."""

    aggregate_type: str = "decision"
    event_type: str = "decision.made"

    invoice_id: str = ""
    decision: str = ""  # "AUTO_POST" | "SUGGEST" | "ASK_USER" | "BLOCK"
    trust_score: float = 0.0
    ai_confidence: float = 0.0
    alpha_vote: str = ""
    beta_vote: str = ""
    gamma_vote: str = ""
    decision_pattern: str = ""
    reasoning: str = ""


class DecisionOverridden(DomainEvent):
    """Decyzja systemowa została nadpisana przez użytkownika."""

    aggregate_type: str = "decision"
    event_type: str = "decision.overridden"

    invoice_id: str = ""
    original_decision: str = ""
    user_decision: str = ""
    user_id: str = ""


# ── Outbox Events ─────────────────────────────────────────────────────────


class OutboxEventEmitted(DomainEvent):
    """Zdarzenie outbox zostało wyemitowane (Transactional Outbox)."""

    aggregate_type: str = "outbox"
    event_type: str = "outbox.emitted"

    outbox_event_type: str = ""
    payload_json: str = ""


class NotificationSent(DomainEvent):
    """Powiadomienie zostało wysłane do użytkownika.

    Emitowany przez NotificationService po wysłaniu powiadomienia
    przez dowolny kanał (in_app, push, email, SMS).
    """

    aggregate_type: str = "notification"
    event_type: str = "notification.sent"

    user_id: str = ""
    notification_type: str = "info"
    title: str = ""
    channels: list[str] = []


# ── Serialization helpers ─────────────────────────────────────────────────


# Rejestr typów eventów dla deserializacji
_EVENT_TYPE_REGISTRY: dict[str, type[DomainEvent]] = {
    "invoice.created": InvoiceCreated,
    "invoice.submitted": InvoiceSubmitted,
    "invoice.approved": InvoiceApproved,
    "invoice.rejected": InvoiceRejected,
    "invoice.blocked": InvoiceBlocked,
    "invoice.paid": InvoicePaid,
    "decision.made": DecisionMade,
    "decision.overridden": DecisionOverridden,
    "outbox.emitted": OutboxEventEmitted,
    "notification.sent": NotificationSent,
}


def domain_event_from_dict(data: dict[str, Any]) -> DomainEvent:
    """Deserializuj słownik na konkretny typ eventu.

    Args:
        data: Słownik z polami eventu (musi zawierać ``event_type``).

    Returns:
        Zdeserializowany event.
    """
    event_type = data.get("event_type", "")
    cls = _EVENT_TYPE_REGISTRY.get(event_type)
    if cls is None:
        raise ValueError(f"Unknown event type: {event_type}")
    return msgspec.convert(data, cls, strict=False)


def encode_event(event: DomainEvent) -> bytes:
    """Zakoduj event do JSON bytes (przez msgspec).

    Args:
        event: Event do zakodowania.

    Returns:
        Zserializowany JSON bytes.
    """
    return msgspec.json.encode(event)


def decode_event(data: bytes) -> DomainEvent:
    """Dekoduj JSON bytes na event.

    Args:
        data: JSON bytes.

    Returns:
        Zdeserializowany event.
    """
    raw = msgspec.json.decode(data)
    if isinstance(raw, dict):
        return domain_event_from_dict(raw)
    raise TypeError(f"Expected dict, got {type(raw)}")
