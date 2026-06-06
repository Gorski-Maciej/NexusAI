# ui/state.py
from collections.abc import Callable
from typing import Any


class AppState:
    """Globalny magazyn stanu aplikacji (odpowiednik Redux/Provider)."""

    def __init__(self):
        self._state: dict[str, Any] = {
            "current_user": None,
            "theme": "dark",
            "active_tasks": []
        }
        # Event Bus: { event_name: [list_of_callbacks] }
        self._listeners: dict[str, list[Callable]] = {}

    def get(self, key: str, default: Any = None) -> Any:
        return self._state.get(key, default)

    def set(self, key: str, value: Any, notify: bool = True):
        self._state[key] = value
        if notify:
            self.emit(f"{key}_changed", value)

    def subscribe(self, event_name: str, callback: Callable):
        """Rejestruje komponent UI do nasłuchiwania zmian."""
        if event_name not in self._listeners:
            self._listeners[event_name] = []
        self._listeners[event_name].append(callback)

    def emit(self, event_name: str, data: Any = None):
        if event_name in self._listeners:
            for callback in self._listeners[event_name]:
                callback(data)

app_state = AppState()
