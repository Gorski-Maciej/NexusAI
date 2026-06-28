"""Emisja eventów przez broker.kick() z dynamicznym mapowaniem na taski taskiq."""

from __future__ import annotations

from typing import Any

from nexus_ai.core.broker import broker

_TASK_PREFIX = "event_emit_"


async def emit_event(event_type: str, **kwargs: Any) -> str:
    """Wyemituj event przez broker.kick() z dynamicznym mapowaniem.

    Args:
        event_type: Typ eventu (np. "decision_made", "invoice_created").
            Mapowany na task: event_emit_<event_type>.
        **kwargs: Parametry przekazywane do taska.

    Returns:
        ID zadania (task_id) z brokera.
    """
    return await broker.kick(f"{_TASK_PREFIX}{event_type}", **kwargs)
