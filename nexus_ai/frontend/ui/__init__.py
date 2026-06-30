"""NexusAI Flet UI package -- wszystkie supermoce Flet 0.28+.

  - @ft.component + use_state() zamiast klas imperatywnych
  - page.pubsub zamiast AppState
  - page.run_task zamiast anyio.create_task_group
  - ft.Shimmer dla loading skeleton
  - ft.NumberBadge dla metryk
  - ft.Ref<T> typowane referencje
"""

from nexus_ai.frontend.ui.data_table import AsyncInvoiceTable
from nexus_ai.frontend.ui.root import NexusRootUI
from nexus_ai.frontend.ui.shortcuts import init_keyboard_handler
from nexus_ai.frontend.ui.state import emit, init_page, subscribe, unsubscribe
from nexus_ai.frontend.ui.storage import LocalStorage, UserPreferences
from nexus_ai.frontend.ui.theme import ThemeManager
from nexus_ai.frontend.ui.utils import Debouncer

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
