"""
Events Schema API -- JSON Schema dla DomainEvents (Faza 3).

Udostępnia JSON Schema Draft 2020-12 dla wszystkich 10 eventów domenowych
przez REST API, zintegrowany z Litestar OpenAPI/Swagger.

Endpoints:
    GET /api/v2/events/schema          -- JSON Schema summary wszystkich eventów
    GET /api/v2/events/schema/{type}   -- JSON Schema konkretnego eventu

Usage:
    curl http://localhost:8000/api/v2/events/schema
    curl http://localhost:8000/api/v2/events/schema/invoice.created
"""

from __future__ import annotations

from typing import Any

from litestar import Controller, get
from litestar.response import Response

from nexus_ai.api.dto import TAG_EVENTS, GenericDictDTO
from nexus_ai.events.domain_events import (
    get_all_schemas as get_all_event_schemas,
)
from nexus_ai.events.domain_events import (
    get_schema as get_event_schema_by_type,
)
from nexus_ai.events.domain_events import (
    get_schema_summary as get_event_schema_summary,
)


class EventsSchemaController(Controller):
    """Kontroler udostępniający JSON Schema eventów domenowych.

    Generowane przez ``msgspec.json.schema()`` -- zawsze aktualne względem
    definicji klas eventów w ``domain_events.py``.
    """

    path = "/events/schema"
    tags = [TAG_EVENTS]

    @get(
        "",
        return_dto=GenericDictDTO,
        summary="Get all event schemas (summary)",
        description=(
            "Returns JSON Schema Draft 2020-12 for all 10 DomainEvents "
            "with summary metadata (total_events, event_types, base_schema). "
            "Schemas are generated from ``msgspec.json.schema()`` at first call "
            "and cached thereafter."
        ),
        operation_id="getEventSchemas",
    )
    async def get_all_schemas(self) -> dict[str, Any]:
        """Zwraca JSON Schema wszystkich eventów domenowych z podsumowaniem.

        Response zawiera:
        - ``total_events``: liczba eventów (10)
        - ``event_types``: lista typów eventów
        - ``schemas``: pełne JSON Schema dla każdego eventu
        - ``base_schema``: JSON Schema dla DomainEvent (tagged union)
        - ``generated_at``: timestamp ISO 8601
        """
        return get_event_schema_summary()

    @get(
        "/{event_type:str}",
        return_dto=GenericDictDTO,
        summary="Get event schema by type",
        description=(
            "Returns JSON Schema Draft 2020-12 for a specific DomainEvent type. "
            "Valid event types: invoice.created, invoice.submitted, "
            "invoice.approved, invoice.rejected, invoice.blocked, "
            "invoice.paid, decision.made, decision.overridden, "
            "outbox.emitted, notification.sent."
        ),
        operation_id="getEventSchemaByType",
    )
    async def get_schema_by_type(
        self, event_type: str
    ) -> dict[str, Any] | Response[dict[str, Any]]:
        """Zwraca JSON Schema dla konkretnego eventu po jego tagu.

        Args:
            event_type: Tag eventu (np. ``invoice.created``, ``decision.made``).

        Returns:
            JSON Schema dict (200) lub ``{\"status\": \"error\", \"message\": ...}`` (404)
            jeśli typ eventu jest nieznany.
        """
        schema = get_event_schema_by_type(event_type)
        if schema is None:
            return Response(
                content={
                    "status": "error",
                    "message": f"Unknown event type: {event_type!r}. "
                    f"Available types: {list(get_all_event_schemas().keys())}",
                },
                status_code=404,
            )
        return schema
