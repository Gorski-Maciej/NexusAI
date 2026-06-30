"""LocalStorage -- Type-safe client storage with msgspec validation.

  - Typowane przez msgspec.Struct dla UserPreferences
  - Walidacja przy zapisie/odczycie
  - page.client_storage dla trwałości między sesjami
"""

from __future__ import annotations

import flet as ft
from msgspec import Struct
from structlog import get_logger

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads

logger = get_logger("nexus.ui.storage")


class UserPreferences(Struct):
    """Type-safe user preferences stored in client_storage."""

    theme: str = "dark"
    compact_mode: bool = False
    language: str = "pl"
    items_per_page: int = 50


class LocalStorage:
    """Zarządza trwałymi danymi po stronie klienta (odpowiednik LocalStorage w przeglądarkach)."""

    def __init__(self, page: ft.Page):
        self.page = page

    def set_token(self, token: str) -> None:
        self.page.client_storage.set("nexus_auth_token", token)

    def get_token(self) -> str | None:
        return self.page.client_storage.get("nexus_auth_token")

    def clear_session(self) -> None:
        self.page.client_storage.remove("nexus_auth_token")
        self.page.client_storage.remove("nexus_user_prefs")

    def save_preferences(self, prefs: UserPreferences) -> None:
        """Save typed UserPreferences to client_storage."""
        self.page.client_storage.set("nexus_user_prefs", msgspec_dumps(prefs))

    def load_preferences(self) -> UserPreferences:
        """Load and validate UserPreferences from client_storage."""
        data = self.page.client_storage.get("nexus_user_prefs")
        if data:
            try:
                parsed = msgspec_loads(data)
                if isinstance(parsed, dict):
                    return UserPreferences(**parsed)
            except Exception:
                logger.warning("Failed to parse preferences, using defaults")
        return UserPreferences()
