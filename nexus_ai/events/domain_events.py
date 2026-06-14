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


class DomainEvent(msgspec.Struct, kw_only=True, frozen=True, tag_field="event_type"):
    """Bazowa klasa dla wszystkich eventów domenowych — z Tagged Unions.

    Używa ``tag_field="event_type"`` — msgspec automatycznie wybiera
    konkretną klasę eventu na podstawie wartości pola ``event_type``
    podczas deserializacji. Zastępuje ręczny ``_EVENT_TYPE_REGISTRY``
    i funkcję ``domain_event_from_dict()``.

    Args:
        aggregate_id: ID agregatu (np. invoice_id, decision_id).
        version: Numer wersji agregatu (optimistic concurrency).
    """

    event_id: str = msgspec.field(default_factory=lambda: uuid.uuid4().hex)
    aggregate_type: str = ""
    # event_type: Pole GENEROWANE AUTOMATYCZNIE przez tag_field="event_type"
    # msgspec tworzy je na podstawie tag="..." na każdej podklasie
    timestamp: str = msgspec.field(default_factory=lambda: pendulum.now("UTC").isoformat())
    aggregate_id: str = ""
    version: int = 0
    metadata: dict[str, Any] = msgspec.field(default_factory=dict)


# ── Invoice Events ────────────────────────────────────────────────────────


class InvoiceCreated(DomainEvent, tag="invoice.created"):
    """Faktura została utworzona w systemie (po OCR)."""

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
    """Faktura została przesłana do decyzji (DecisionEngine)."""

    aggregate_type: str = "invoice"

    amount_gross: float = 0.0
    contractor_nip: str = ""


class InvoiceApproved(DomainEvent, tag="invoice.approved"):
    """Faktura została zatwierdzona (auto-post lub manualnie)."""

    aggregate_type: str = "invoice"

    approved_by: str = "system"  # "system" | "user:{user_id}"
    trust_score: float = 0.0
    decision_level: str = "auto"  # "auto" | "suggest" | "manual"


class InvoiceRejected(DomainEvent, tag="invoice.rejected"):
    """Faktura została odrzucona (manualnie)."""

    aggregate_type: str = "invoice"

    rejected_by: str = ""
    reason: str = ""


class InvoiceBlocked(DomainEvent, tag="invoice.blocked"):
    """Faktura została zablokowana (RiskGuard / anomalia)."""

    aggregate_type: str = "invoice"
    blocked_by: str = "risk_guard"
    reason: str = ""
    risk_score: float = 0.0


class InvoicePaid(DomainEvent, tag="invoice.paid"):
    """Faktura została opłacona (przez TigerBeetle)."""

    aggregate_type: str = "invoice"

    amount_gross: float = 0.0
    paid_at: str = ""
    transaction_id: str = ""


# ── Decision Events ───────────────────────────────────────────────────────


class DecisionMade(DomainEvent, tag="decision.made"):
    """Decyzja została podjęta przez system (DecisionEngine)."""

    aggregate_type: str = "decision"

    invoice_id: str = ""
    decision: str = ""  # "AUTO_POST" | "SUGGEST" | "ASK_USER" | "BLOCK"
    trust_score: float = 0.0
    ai_confidence: float = 0.0
    alpha_vote: str = ""
    beta_vote: str = ""
    gamma_vote: str = ""
    decision_pattern: str = ""
    reasoning: str = ""


class DecisionOverridden(DomainEvent, tag="decision.overridden"):
    """Decyzja systemowa została nadpisana przez użytkownika."""

    aggregate_type: str = "decision"

    invoice_id: str = ""
    original_decision: str = ""
    user_decision: str = ""
    user_id: str = ""


# ── Outbox Events ─────────────────────────────────────────────────────────


class OutboxEventEmitted(DomainEvent, tag="outbox.emitted"):
    """Zdarzenie outbox zostało wyemitowane (Transactional Outbox)."""

    aggregate_type: str = "outbox"

    outbox_event_type: str = ""
    payload_json: str = ""


class NotificationSent(DomainEvent, tag="notification.sent"):
    """Powiadomienie zostało wysłane do użytkownika.

    Emitowany przez NotificationService po wysłaniu powiadomienia
    przez dowolny kanał (in_app, push, email, SMS).
    """

    aggregate_type: str = "notification"

    user_id: str = ""
    notification_type: str = "info"
    title: str = ""
    channels: list[str] = []


# ── Serialization helpers ─────────────────────────────────────────────────

# Tagged Unions (tag_field="event_type") automatyzują deserializację:
# msgspec sam wybiera klasę na podstawie wartości event_type w danych.
# Dzięki tag=True na każdej podklasie, nie potrzebujemy _EVENT_TYPE_REGISTRY.


def domain_event_from_dict(data: dict[str, Any]) -> DomainEvent:
    """Deserializuj słownik na event przez Tagged Unions.

    Używa ``msgspec.convert(data, DomainEvent, strict=False)`` — dzięki
    ``tag_field="event_type"`` msgspec automatycznie wybiera właściwą
    klasę. Zachowane dla kompatybilności wstecznej z event_store.py.

    Args:
        data: Słownik z polami eventu (musi zawierać ``event_type``).

    Returns:
        Odpowiednia podklasa DomainEvent.
    """
    return msgspec.convert(data, DomainEvent, strict=False)


def encode_event(event: DomainEvent) -> bytes:
    """Zakoduj event do msgpack bytes (przez msgspec).

    Używa ``msgspec.msgpack.encode`` dla 2-5× szybszej serializacji
    wewnętrznej w porównaniu do JSON. Komunikacja między komponentami
    (EventStore, JetStream, ProjectionWorker) używa msgpack.

    Args:
        event: Event do zakodowania.

    Returns:
        Zserializowane bajty (msgpack).
    """
    return msgspec.msgpack.encode(event)


def decode_event(data: bytes) -> DomainEvent:
    """Dekoduj msgpack bytes na event przez Tagged Unions.

    Używa ``msgspec.msgpack.decode(..., type=DomainEvent)`` — dzięki
    ``tag_field="event_type"`` i ``tag="..."`` na każdej podklasie,
    msgspec automatycznie wybiera właściwą klasę.

    Args:
        data: Bajty (msgpack) do dekodowania.

    Returns:
        Zdeserializowany event (odpowiednia podklasa DomainEvent).
    """
    return msgspec.msgpack.decode(data, type=DomainEvent)
