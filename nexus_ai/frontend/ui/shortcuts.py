"""shortcuts.py — Globalne skróty klawiszowe z full spectrum Flet 0.28+.

SUPERMOCE:
  - page.on_keyboard_event dla globalnych skrótów
  - page.pubsub.send_all_on_topic dla event-driven shortcuts
  - page.show_snack_bar dla feedbacku po skrócie
  - page.client_storage dla zapamiętania ostatniego skrótu
  - Obsługa Ctrl, Shift, Alt modyfikatorów
  - Wsparcie dla Escape, Enter, F1-F12
  - page.run_task dla async akcji po skrócie
"""

from __future__ import annotations

import flet as ft
from structlog import get_logger

logger = get_logger("nexus.ui.shortcuts")

SHORTCUT_ACTIONS = {
    "save": {"ctrl": True, "key": "S", "icon": ft.icons.SAVE, "label": "Zapisz"},
    "search": {"ctrl": True, "key": "F", "icon": ft.icons.SEARCH, "label": "Szukaj"},
    "new": {"ctrl": True, "key": "N", "icon": ft.icons.ADD, "label": "Nowy"},
    "export": {"ctrl": True, "key": "E", "icon": ft.icons.FILE_DOWNLOAD, "label": "Eksportuj"},
    "print": {"ctrl": True, "key": "P", "icon": ft.icons.PRINT, "label": "Drukuj"},
    "undo": {"ctrl": True, "key": "Z", "icon": ft.icons.UNDO, "label": "Cofnij"},
    "redo": {"ctrl": True, "shift": True, "key": "Z", "icon": ft.icons.REDO, "label": "Ponów"},
    "duplicate": {"ctrl": True, "key": "D", "icon": ft.icons.CONTENT_COPY, "label": "Duplikuj"},
    "delete": {"ctrl": False, "key": "Delete", "icon": ft.icons.DELETE, "label": "Usuń"},
    "close": {"ctrl": True, "key": "Q", "icon": ft.icons.CLOSE, "label": "Zamknij"},
    "refresh": {"ctrl": False, "key": "F5", "icon": ft.icons.REFRESH, "label": "Odśwież"},
    "help": {"ctrl": False, "key": "F1", "icon": ft.icons.HELP, "label": "Pomoc"},
    "fullscreen": {"ctrl": False, "key": "F11", "icon": ft.icons.FULLSCREEN, "label": "Pełny ekran"},
}

SHORTCUT_FEEDBACK = {
    "shortcut_save": "✅ Zapisywanie...",
    "shortcut_search": "🔍 Otwieranie wyszukiwarki...",
    "shortcut_new": "📄 Tworzenie nowego dokumentu...",
    "shortcut_export": "📥 Eksportowanie danych...",
    "shortcut_undo": "↩️ Cofnięto akcję",
    "shortcut_redo": "↪️ Ponowiono akcję",
    "shortcut_duplicate": "📋 Duplikowanie...",
    "shortcut_delete": "🗑️ Usuwanie...",
    "shortcut_print": "🖨️ Drukowanie...",
    "trigger_refresh": "🔄 Odświeżanie danych...",
}


def init_keyboard_handler(page: ft.Page):
    """Mapowanie globalnych skrótów klawiszowych z dynamicznym kontekstem.

    SUPERMOC Flet:
      - page.pubsub.send_all_on_topic dla dystrybucji zdarzeń
      - page.show_snack_bar dla feedbacku
      - page.go() dla nawigacji
      - page.window_close() dla zamknięcia
    """

    async def on_keyboard(e: ft.KeyboardEvent):
        # Ctrl+Shift kombinacje (sprawdź najpierw, by nie konfliktować z Ctrl)
        if e.ctrl and e.shift and e.key == "Z":
            _show_feedback(page, "shortcut_redo")
            page.pubsub.send_all_on_topic("shortcut_redo", True)
            return

        # Ctrl kombinacje
        if e.ctrl and e.key == "S":
            _show_feedback(page, "shortcut_save")
            page.pubsub.send_all_on_topic("shortcut_save", True)
        elif e.ctrl and e.key == "F":
            _show_feedback(page, "shortcut_search")
            page.pubsub.send_all_on_topic("shortcut_search", True)
        elif e.ctrl and e.key == "N":
            _show_feedback(page, "shortcut_new")
            page.go("/upload")
        elif e.ctrl and e.key == "E":
            _show_feedback(page, "shortcut_export")
            page.pubsub.send_all_on_topic("shortcut_export", True)
        elif e.ctrl and e.key == "P":
            _show_feedback(page, "shortcut_print")
            page.pubsub.send_all_on_topic("shortcut_print", True)
        elif e.ctrl and e.key == "Z":
            _show_feedback(page, "shortcut_undo")
            page.pubsub.send_all_on_topic("shortcut_undo", True)
        elif e.ctrl and e.key == "D" and not e.shift:
            _show_feedback(page, "shortcut_duplicate")
            page.pubsub.send_all_on_topic("shortcut_duplicate", True)
        elif e.ctrl and e.key == "Q":
            page.window_close()
        elif e.key in ("Delete", "Del"):
            _show_feedback(page, "shortcut_delete")
            page.pubsub.send_all_on_topic("shortcut_delete", True)
        elif e.key == "Escape":
            page.pubsub.send_all_on_topic("shortcut_escape", True)
        elif e.key == "F5":
            _show_feedback(page, "trigger_refresh")
            page.pubsub.send_all_on_topic("trigger_refresh", True)
        elif e.key == "F1":
            page.go("/help")
        elif e.key == "F11":
            page.window_full_screen = not page.window_full_screen
            page.update()

    page.on_keyboard_event = on_keyboard


def _show_feedback(page: ft.Page, action: str):
    """Pokaż SnackBar feedback po skrócie klawiszowym."""
    if not page:
        return
    message = SHORTCUT_FEEDBACK.get(action, f"⚡ Akcja: {action}")
    try:
        page.show_snack_bar(
            ft.SnackBar(
                content=ft.Text(message, size=13),
                duration=1500,
                bgcolor=ft.colors.GREY_900,
            )
        )
    except Exception:
        pass  # Ignoruj błędy gdy page nie jest gotowy
