# ui/shortcuts.py
import flet as ft

def init_keyboard_handler(page: ft.Page):
    """Mapowanie globalnych skrótów klawiszowych."""

    async def on_keyboard(e: ft.KeyboardEvent):
        # CTRL + S -> Szybki zapis aktualnego formularza
        if e.ctrl and e.key == "S":
            page.pubsub.send_all("trigger_save")

        # CTRL + N -> Nowy upload faktury
        if e.ctrl and e.key == "N":
            page.go("/upload")

        # CTRL + Q -> Zamknięcie / Logout
        if e.ctrl and e.key == "Q":
            page.window_close()

        # F5 -> Odświeżenie danych (re-fetch z API)
        if e.key == "F5":
            page.pubsub.send_all("trigger_refresh")

    page.on_keyboard_event = on_keyboard
