"""
EventEmitter — dynamic dispatch dla emisji eventów przez broker.kick().

Zastępuje deprecated klasę EventEmitter (500 linii boilerplate'u)
jedną funkcją emit_event() z dynamicznym mapowaniem na taski taskiq.

Usage:
    # Zamiast 20 metod na klasie:
    await emit_event("decision_made", invoice_id=..., decision=...)
    await emit_event("invoice_created", invoice_id=..., number=...)
"""

from __future__ import annotations

from typing import Any

from structlog import get_logger

from nexus_ai.core.broker import broker

logger = get_logger("nexus.events.emitter")

# Task name prefix — wszystkie eventy używają event_emit_* tasków
_TASK_PREFIX = "event_emit_"


async def emit_event(event_type: str, **kwargs: Any) -> str:
    """Wyemituj event przez broker.kick() z dynamicznym mapowaniem.

    Args:
        event_type: Typ eventu (np. "decision_made", "invoice_created").
            Automatycznie mapowany na task: event_emit_<event_type>.
        **kwargs: Parametry przekazywane do taska.

    Returns:
        ID zadania (task_id) z brokera.

    Przykład:
        await emit_event("decision_made", invoice_id="123", decision="APPROVE")
        # → broker.kick("event_emit_decision_made", invoice_id="123", decision="APPROVE")
    """
    task_name = f"{_TASK_PREFIX}{event_type}"
    return await broker.kick(task_name, **kwargs)


# ── Backward compatibility ──────────────────────────────────────────────
# Poniższe nazwy są zachowane dla kompatybilności wstecznej z kodem
# który importuje get_event_emitter(). Nowy kod powinien używać:
#   from nexus_ai.events.event_emitter import emit_event

_DEPRECATED_WARNING = "EventEmitter jest deprecated. Użyj: await emit_event('event_type', **kwargs)"


class EventEmitter:
    """[DEPRECATED] Zachowany dla kompatybilności wstecznej.

    Wszystkie metody delegują do emit_event() przez __getattr__.
    """

    def __getattr__(self, name: str) -> Any:
        if name.startswith("emit_"):
            event_type = name.removeprefix("emit_")
            logger.warning(_DEPRECATED_WARNING)

            async def _dynamic_dispatch(**kwargs: Any) -> str:
                return await emit_event(event_type, **kwargs)

            return _dynamic_dispatch
        raise AttributeError(f"EventEmitter has no attribute {name!r}")


_default_emitter: EventEmitter | None = None


def get_event_emitter(*args: Any, **kwargs: Any) -> EventEmitter:
    """[DEPRECATED] Zwraca instancję EventEmitter (backward compat).

    Nowy kod powinien używać: await emit_event('event_type', **kwargs)
    """
    logger.warning(_DEPRECATED_WARNING)
    global _default_emitter
    if _default_emitter is None:
        _default_emitter = EventEmitter()
    return _default_emitter
