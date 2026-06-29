"""ui/state.py — State management przez natywny page.pubsub Flet.

  - page.pubsub.subscribe / send_all_on_topic zamiast AppState
  - Zero dodatkowych zależności
  - Automatyczne czyszczenie przy odłączeniu klienta
  - Typowane eventy przez msgspec

Usage:
    from nexus_ai.frontend.ui.state import subscribe, emit
    subscribe("progress_update", handler)
    emit("progress_update", {"task_id": "..."})
"""

from __future__ import annotations

from typing import Any
from collections.abc import Callable


_page_ref = None


def init_page(page):
    """Initialize with a Flet page reference for pubsub."""
    global _page_ref
    _page_ref = page


def subscribe(event_name: str, callback: Callable):
    """Register a UI component to listen for events via page.pubsub.

    """
    if _page_ref is not None:
        _page_ref.pubsub.subscribe(event_name, callback)


def emit(event_name: str, data: Any = None):
    """Emit event via page.pubsub.

    """
    if _page_ref is not None:
        _page_ref.pubsub.send_all_on_topic(event_name, data)


def unsubscribe(event_name: str, callback: Callable | None = None):
    """Unsubscribe from an event.

    """
    if _page_ref is not None and callback is not None:
        try:
            _page_ref.pubsub.unsubscribe(event_name, callback)
        except Exception:
            pass
