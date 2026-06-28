"""
event_schema.py — JSON Schema generation for DomainEvents (Faza 3).

Generuje JSON Schema Draft 2020-12 dla każdego eventu domenowego przy użyciu
``msgspec.json.schema()``. Schematy są cachowane (generowane raz, używane wielokrotnie).

Umożliwia:
- Automatyczną dokumentację API eventów (OpenAPI/Swagger)
- Walidację eventów po stronie klienta
- Generowanie typów TypeScript/kotlin z JSON Schema
- Debugowanie struktury eventów

Usage:
    from nexus_ai.events.event_schema import (
        get_all_event_schemas,
        get_event_schema_by_type,
        get_event_type_map,
        DomainEventSchemaRegistry,
    )

    # Pobierz schemat konkretnego eventu
    schema = get_event_schema_by_type("invoice.created")
    print(schema["title"])  # "InvoiceCreated"

    # Pobierz wszystkie schematy
    all_schemas = get_all_event_schemas()
"""

from __future__ import annotations

from typing import Any

import msgspec
import pendulum

from nexus_ai.core.msgspec_utils import msgspec_json_schema
from nexus_ai.events.domain_events import (
    DecisionMade,
    DecisionOverridden,
    DomainEvent,
    InvoiceApproved,
    InvoiceBlocked,
    InvoiceCreated,
    InvoicePaid,
    InvoiceRejected,
    InvoiceSubmitted,
    NotificationSent,
    OutboxEventEmitted,
)

# ── Rejestr eventów ──────────────────────────────────────────────────────
# Każdy wpis: (tag = event_type, class, description)

EventRegistryEntry = tuple[str, type[DomainEvent], str]

EVENT_REGISTRY: list[EventRegistryEntry] = [
    # Invoice events
    ("invoice.created", InvoiceCreated, "Faktura została utworzona w systemie (po OCR)"),
    (
        "invoice.submitted",
        InvoiceSubmitted,
        "Faktura została przesłana do decyzji (DecisionEngine)",
    ),
    ("invoice.approved", InvoiceApproved, "Faktura została zatwierdzona (auto-post lub manualnie)"),
    ("invoice.rejected", InvoiceRejected, "Faktura została odrzucona (manualnie)"),
    ("invoice.blocked", InvoiceBlocked, "Faktura została zablokowana (RiskGuard / anomalia)"),
    ("invoice.paid", InvoicePaid, "Faktura została opłacona (przez TigerBeetle)"),
    # Decision events
    ("decision.made", DecisionMade, "Decyzja została podjęta przez system (DecisionEngine)"),
    (
        "decision.overridden",
        DecisionOverridden,
        "Decyzja systemowa została nadpisana przez użytkownika",
    ),
    # Outbox events
    (
        "outbox.emitted",
        OutboxEventEmitted,
        "Zdarzenie outbox zostało wyemitowane (Transactional Outbox)",
    ),
    # Notification events
    ("notification.sent", NotificationSent, "Powiadomienie zostało wysłane do użytkownika"),
]

# ── Cache dla schematów ──────────────────────────────────────────────────

_SCHEMAS_CACHE: dict[str, dict[str, Any]] | None = None
_MAP_CACHE: dict[str, dict[str, Any]] | None = None


def _build_all_schemas() -> dict[str, dict[str, Any]]:
    """Generuj JSON Schema dla wszystkich eventów domenowych.

    Każdy schemat jest wzbogacony o:
    - ``description``: opis eventu
    - ``event_type``: tag eventu (np. ``invoice.created``)
    - ``$id``: unikalny identyfikator schematu
    - Pełna struktura pól (przez ``msgspec.json.schema()``)

    Returns:
        Słownik: event_type → JSON Schema dict
    """
    schemas: dict[str, dict[str, Any]] = {}
    for event_type, event_class, description in EVENT_REGISTRY:
        try:
            schema = msgspec_json_schema(event_class)
            # Wzbogać o metadane
            schema["description"] = description
            schema["event_type"] = event_type
            schema["$id"] = f"https://nexusai.app/schemas/events/{event_type}.json"
            schema["$schema"] = "https://json-schema.org/draft/2020-12/schema"
            schemas[event_type] = schema
        except Exception as exc:
            schemas[event_type] = {
                "title": event_class.__name__,
                "type": "object",
                "description": f"{description} (schema generation failed: {exc})",
                "event_type": event_type,
                "$id": f"https://nexusai.app/schemas/events/{event_type}.json",
            }
    return schemas


def get_all_event_schemas() -> dict[str, dict[str, Any]]:
    """Zwraca JSON Schema dla wszystkich eventów domenowych (cached)."""
    global _SCHEMAS_CACHE
    if _SCHEMAS_CACHE is None:
        _SCHEMAS_CACHE = _build_all_schemas()
    return dict(_SCHEMAS_CACHE)


def get_event_schema_by_type(event_type: str) -> dict[str, Any] | None:
    """Zwraca JSON Schema dla konkretnego eventu po jego tagu.

    Args:
        event_type: Tag eventu (np. ``invoice.created``, ``decision.made``).

    Returns:
        JSON Schema dict lub None jeśli event nieznany.

    Example:
        >>> schema = get_event_schema_by_type("invoice.created")
        >>> schema["title"]
        'InvoiceCreated'
    """
    schemas = get_all_event_schemas()
    return schemas.get(event_type)


# ── Schema dla DomainEvent (bazowy) ───────────────────────────────────────


def _get_base_schema() -> dict[str, Any]:
    """Zwraca JSON Schema dla bazowej klasy DomainEvent (tagged union).

    Dla typu z ``tag_field``, ``msgspec.json.schema()`` zwraca strukturę
    ``oneOf`` z odwołaniami do konkretnych typów. Ta funkcja normalizuje
    to do formatu z ``title`` dla łatwiejszego użytku.
    """
    schema = msgspec_json_schema(DomainEvent)
    # Dla tagged union, schema może nie mieć 'title' (ma 'oneOf' zamiast tego)
    if "title" not in schema:
        schema["title"] = "DomainEvent"
    # Dodaj listę dostępnych tagów
    if "oneOf" in schema:
        schema["available_event_types"] = [e[0] for e in EVENT_REGISTRY]
    return schema


def get_event_type_map() -> dict[str, dict[str, Any]]:
    """Zwraca mapę event_type → podstawowe metadane (bez pełnej struktury).

    Przydatne do szybkiego wyszukiwania typów eventów bez generowania
    pełnego JSON Schema (lżejsze, szybsze).

    Returns:
        Słownik: event_type → {title, description}
    """
    global _MAP_CACHE
    if _MAP_CACHE is None:
        _MAP_CACHE = {
            event_type: {
                "title": event_class.__name__,
                "description": description,
                "event_type": event_type,
            }
            for event_type, event_class, description in EVENT_REGISTRY
        }
    return dict(_MAP_CACHE)


def get_event_schema_summary() -> dict[str, Any]:
    """Zwraca podsumowanie wszystkich eventów z ich schematami.

    Returns:
        Słownik z:
        - ``total_events``: liczba eventów
        - ``event_types``: lista typów eventów
        - ``schemas``: pełne JSON Schema dla każdego eventu
        - ``base_schema``: JSON Schema dla DomainEvent (bazowy)
    """
    schemas = get_all_event_schemas()
    base_schema = _get_base_schema()

    return {
        "total_events": len(schemas),
        "event_types": list(schemas.keys()),
        "schemas": schemas,
        "base_schema": base_schema,
        "generated_at": pendulum.now("UTC").isoformat(),
    }


# ── Klasa Registry (dla DI / wstrzykiwania zależności) ───────────────────


class DomainEventSchemaRegistry:
    """Rejestr JSON Schema dla eventów domenowych — dla DI i testowania.

    Deleguje do modułowych funkcji cache'owanych — nie buduje schematów
    od nowa. Współdzieli cache z ``get_all_event_schemas()``.

    Usage:
        registry = DomainEventSchemaRegistry()
        schema = registry.get_schema("invoice.created")
        all_schemas = registry.get_all()
    """

    def get_schema(self, event_type: str) -> dict[str, Any] | None:
        """Zwraca JSON Schema dla eventu (używa global cache)."""
        return get_event_schema_by_type(event_type)

    def get_all(self) -> dict[str, dict[str, Any]]:
        """Zwraca wszystkie schematy (używa global cache)."""
        return get_all_event_schemas()

    def refresh(self) -> None:
        """Wymuś przeładowanie schematów przez reset global cache."""
        global _SCHEMAS_CACHE, _MAP_CACHE
        _SCHEMAS_CACHE = None
        _MAP_CACHE = None
