# core/bus.py
from collections.abc import Callable
from typing import Any

import anyio


class EventBus:
    """Lokalna szyna zdarzeń dla komunikacji między modułami."""

    def __init__(self):
        self._subscribers: dict[str, list[Callable]] = {}

    def subscribe(self, event_type: str, callback: Callable):
        if event_type not in self._subscribers:
            self._subscribers[event_type] = []
        self._subscribers[event_type].append(callback)

    async def emit(self, event_type: str, data: Any = None):
        """Rozsyła zdarzenie asynchronicznie do wszystkich subskrybentów."""
        if event_type in self._subscribers:
            async with anyio.create_task_group() as tg:
                for callback in self._subscribers[event_type]:
                    tg.start_soon(callback, data)


# Globalny singleton
bus = EventBus()
