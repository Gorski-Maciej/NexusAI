# ui/shortcuts.py
import flet as ft

from __future__ import annotations


def init_keyboard_handler(page: ft.Page):
    """Mapowanie globalnych skrótów klawiszowych z dynamicznym kontekstem."""

    async def on_keyboard(e: ft.KeyboardEvent):
        # SUPERMOC: page.pubsub.send_all_on_topic zamiast send_all
        if e.ctrl and e.key == "S":
            page.pubsub.send_all_on_topic("shortcut_save", True)
        if e.ctrl and e.key == "F":
            page.pubsub.send_all_on_topic("shortcut_search", True)
        if e.ctrl and e.key == "N":
            page.go("/upload")
        if e.ctrl and e.key == "E":
            page.pubsub.send_all_on_topic("shortcut_export", True)
        if e.ctrl and e.key == "Q":
            page.window_close()
        if e.key in ("Delete", "Del"):
            page.pubsub.send_all_on_topic("shortcut_delete", True)
        if e.key == "F5":
            page.pubsub.send_all_on_topic("trigger_refresh", True)

    page.on_keyboard_event = on_keyboard
