# core/bus.py
import asyncio
from typing import Callable, Any, Dict, List

class EventBus:
    """Lokalna szyna zdarzeń dla komunikacji między modułami."""

    def __init__(self):
        self._subscribers: Dict[str, List[Callable]] = {}

    def subscribe(self, event_type: str, callback: Callable):
        if event_type not in self._subscribers:
            self._subscribers[event_type] = []
        self._subscribers[event_type].append(callback)

    async def emit(self, event_type: str, data: Any = None):
        """Rozsyła zdarzenie asynchronicznie do wszystkich subskrybentów."""
        if event_type in self._subscribers:
            tasks = [
                asyncio.create_task(callback(data))
                for callback in self._subscribers[event_type]
            ]
            if tasks:
                await asyncio.gather(*tasks)

# Globalny singleton
bus = EventBus()
