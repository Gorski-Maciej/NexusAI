"""NexusAI Flet UI package — wszystkie supermoce Flet 0.28+.

SUPERMOCE:
  - @ft.component + use_state() zamiast klas imperatywnych
  - page.pubsub zamiast AppState
  - page.run_task zamiast anyio.create_task_group
  - ft.Shimmer dla loading skeleton
  - ft.NumberBadge dla metryk
  - ft.Ref<T> typowane referencje
"""

from nexus_ai.frontend.ui.root import NexusRootUI
from nexus_ai.frontend.ui.theme import ThemeManager
from nexus_ai.frontend.ui.state import emit, subscribe, unsubscribe, init_page
from nexus_ai.frontend.ui.utils import Debouncer
from nexus_ai.frontend.ui.shortcuts import init_keyboard_handler
from nexus_ai.frontend.ui.storage import UserPreferences, LocalStorage
from nexus_ai.frontend.ui.data_table import AsyncInvoiceTable

__all__ = [
    "NexusRootUI",
    "ThemeManager",
    "emit",
    "subscribe",
    "unsubscribe",
    "init_page",
    "Debouncer",
    "init_keyboard_handler",
    "UserPreferences",
    "LocalStorage",
    "AsyncInvoiceTable",
]
