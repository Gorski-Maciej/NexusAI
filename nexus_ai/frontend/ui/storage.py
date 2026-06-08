# ui/storage.py
import flet as ft
from structlog import get_logger

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads

logger = get_logger("nexus.ui.storage")

class LocalStorage:
    """Zarządza trwałymi danymi po stronie klienta (odpowiednik LocalStorage w przeglądarkach)."""

    def __init__(self, page: ft.Page):
        self.page = page

    def set_token(self, token: str):
        self.page.client_storage.set("nexus_auth_token", token)

    def get_token(self) -> str | None:
        return self.page.client_storage.get("nexus_auth_token")

    def clear_session(self):
        self.page.client_storage.remove("nexus_auth_token")
        self.page.client_storage.remove("nexus_user_prefs")

    def save_preferences(self, prefs: dict):
        self.page.client_storage.set("nexus_user_prefs", msgspec_dumps(prefs))

    def load_preferences(self) -> dict:
        data = self.page.client_storage.get("nexus_user_prefs")
        return msgspec_loads(data) if data else {"theme": "dark", "compact_mode": False}
