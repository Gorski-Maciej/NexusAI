# ui/state.py
"""
Global state management for NexusAI Flet UI.

SUPERMOC Flet: Używa page.pubsub zamiast własnego AppState.
- Flet ma wbudowany system pubsub (page.pubsub.subscribe / send_all_on_topic)
- Zero dodatkowych zależności
- Automatyczne czyszczenie przy odłączeniu klienta

Usage:
    from ui.state import subscribe, emit
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
    """Register a UI component to listen for events via page.pubsub."""
    if _page_ref is not None:
        # SUPERMOC Flet: użyj wbudowanego pubsub
        _page_ref.pubsub.subscribe(event_name, callback)


def emit(event_name: str, data: Any = None):
    """Emit event via page.pubsub."""
    if _page_ref is not None:
        _page_ref.pubsub.send_all_on_topic(event_name, data)
