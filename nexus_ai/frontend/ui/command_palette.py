"""command_palette.py -- Command Palette Ctrl+K (v7.0 Rec #5: Innowacja 2).

  Globalna paleta komend (jak VS Code) aktywowana przez Ctrl+K.
  Umożliwia błyskawiczną nawigację i wykonywanie akcji bez myszki.

  - ft.AlertDialog z SearchBar dla fuzzy search komend
  - Komendy generowane z SHORTCUT_ACTIONS + dodatkowe akcje systemowe
  - Obsługa klawiszy strzałek do nawigacji, Enter do wykonania
  - page.pubsub dla komunikacji z innymi komponentami
"""

from __future__ import annotations

import flet as ft
from structlog import get_logger

logger = get_logger("nexus.ui.command_palette")


# ── Command definitions ────────────────────────────────────────────────────

COMMANDS: list[dict] = [
    # Document actions
    {
        "id": "approve_invoice",
        "label": "Zatwierdź fakturę",
        "icon": ft.icons.CHECK_CIRCLE_OUTLINE,
        "category": "Dokumenty",
        "action": "navigate",
        "route": "/invoices",
        "shortcut": "Ctrl+A",
        "description": "Przejdź do listy faktur i zatwierdź",
    },
    {
        "id": "new_invoice",
        "label": "Nowa faktura",
        "icon": ft.icons.ADD,
        "category": "Dokumenty",
        "action": "navigate",
        "route": "/upload",
        "shortcut": "Ctrl+N",
        "description": "Dodaj nową fakturę do systemu",
    },
    {
        "id": "search_invoice",
        "label": "Szukaj faktury",
        "icon": ft.icons.SEARCH,
        "category": "Dokumenty",
        "action": "navigate",
        "route": "/invoices",
        "shortcut": "Ctrl+F",
        "description": "Wyszukaj fakturę po numerze lub NIP",
    },

    # Reports
    {
        "id": "vat_report",
        "label": "Raport VAT",
        "icon": ft.icons.ASSESSMENT,
        "category": "Raporty",
        "action": "navigate",
        "route": "/dashboard?tab=vat",
        "description": "Wygeneruj raport VAT",
    },
    {
        "id": "finance_report",
        "label": "Raport finansowy",
        "icon": ft.icons.ACCOUNT_BALANCE,
        "category": "Raporty",
        "action": "navigate",
        "route": "/dashboard?tab=finance",
        "description": "Przejdź do analizy finansowej",
    },
    {
        "id": "export_data",
        "label": "Eksportuj dane",
        "icon": ft.icons.FILE_DOWNLOAD,
        "category": "Raporty",
        "action": "publish",
        "topic": "shortcut_export",
        "shortcut": "Ctrl+E",
        "description": "Eksportuj dane do CSV/PDF",
    },

    # System
    {
        "id": "settings",
        "label": "Ustawienia",
        "icon": ft.icons.SETTINGS,
        "category": "System",
        "action": "navigate",
        "route": "/settings",
        "description": "Otwórz ustawienia aplikacji",
    },
    {
        "id": "toggle_theme",
        "label": "Przełącz motyw",
        "icon": ft.icons.DARK_MODE,
        "category": "System",
        "action": "publish",
        "topic": "shortcut_toggle_theme",
        "description": "Przełącz między jasnym a ciemnym motywem",
    },
    {
        "id": "refresh_data",
        "label": "Odśwież dane",
        "icon": ft.icons.REFRESH,
        "category": "System",
        "action": "publish",
        "topic": "trigger_refresh",
        "shortcut": "F5",
        "description": "Odśwież wszystkie dane z API",
    },
    {
        "id": "fullscreen",
        "label": "Pełny ekran",
        "icon": ft.icons.FULLSCREEN,
        "category": "System",
        "action": "publish",
        "topic": "shortcut_fullscreen",
        "shortcut": "F11",
        "description": "Przełącz tryb pełnoekranowy",
    },

    # AI / Decisions
    {
        "id": "decision_feed",
        "label": "Centrum decyzji",
        "icon": ft.icons.INBOX,
        "category": "AI",
        "action": "navigate",
        "route": "/decisions",
        "description": "Otwórz feed decyzyjny 1-Click CFO",
    },
    {
        "id": "daily_briefing",
        "label": "Podsumowanie dnia",
        "icon": ft.icons.TODAY,
        "category": "AI",
        "action": "navigate",
        "route": "/briefing",
        "description": "Poranne podsumowanie decyzji",
    },
    {
        "id": "task_monitor",
        "label": "Monitor zadań",
        "icon": ft.icons.TASK_ALT,
        "category": "AI",
        "action": "navigate",
        "route": "/tasks",
        "description": "Monitor zadań asynchronicznych AI",
    },

    # Partner
    {
        "id": "partner_hub",
        "label": "Panel partnera",
        "icon": ft.icons.PEOPLE,
        "category": "Partner",
        "action": "navigate",
        "route": "/partner",
        "description": "Panel biura rachunkowego",
    },

    # Help
    {
        "id": "help",
        "label": "Pomoc",
        "icon": ft.icons.HELP,
        "category": "Pomoc",
        "action": "navigate",
        "route": "/help",
        "shortcut": "F1",
        "description": "Otwórz pomoc i dokumentację",
    },
    {
        "id": "keyboard_shortcuts",
        "label": "Skróty klawiszowe",
        "icon": ft.icons.KEYBOARD,
        "category": "Pomoc",
        "action": "show_shortcuts",
        "description": "Pokaż wszystkie skróty klawiszowe",
    },
]


# ── Command Palette Component ───────────────────────────────────────────────


def build_command_palette(page: ft.Page) -> ft.AlertDialog:
    """Tworzy Command Palette (Ctrl+K) — modal z wyszukiwarką komend.

    Args:
        page: Flet Page instance

    Returns:
        ft.AlertDialog gotowy do pokazania przez page.dialog
    """

    search_value = ""
    selected_index = 0

    def get_filtered() -> list[dict]:
        if not search_value:
            return COMMANDS
        query = search_value.lower().strip()
        return [
            c for c in COMMANDS
            if query in c["label"].lower()
            or query in c.get("description", "").lower()
            or query in c.get("category", "").lower()
        ]

    # ── Build UI components ───────────────────────────────────────────

    results_list = ft.ListView(
        spacing=2,
        height=320,
        padding=ft.padding.all(4),
    )

    search_bar = ft.TextField(
        hint_text="Wpisz komendę... (np. 'raport VAT', 'zatwierdź')",
        border=ft.InputBorder.UNDERLINE,
        text_size=15,
        autofocus=True,
        prefix_icon=ft.Icon(ft.icons.KEYBOARD_COMMAND_KEY, size=18, color=ft.colors.GREY_400),
        content_padding=ft.padding.only(left=8, right=8, top=12, bottom=12),
    )

    category_text = ft.Text("", size=11, color=ft.colors.GREY_500)
    footer_text = ft.Text(
        "↑↓ nawiguj  ↵ wykonaj  Esc zamknij",
        size=11,
        color=ft.colors.GREY_600,
    )

    dialog = ft.AlertDialog(
        title=ft.Container(
            content=ft.Column([
                ft.Text("Paleta komend", size=18, weight=ft.FontWeight.BOLD),
                ft.Container(height=8),
                search_bar,
            ]),
            padding=ft.padding.all(0),
        ),
        content=ft.Column(
            [
                ft.Container(height=8),
                category_text,
                ft.Container(height=4),
                results_list,
                ft.Container(height=8),
                ft.Divider(height=1, color=ft.colors.GREY_800),
                ft.Container(height=4),
                footer_text,
            ],
            tight=True,
            width=500,
        ),
        actions=[],
        shape=ft.RoundedRectangleBorder(radius=16),
        inset_padding=ft.padding.symmetric(horizontal=40, vertical=24),
    )

    # ── Render results ────────────────────────────────────────────────

    def render_results():
        filtered = get_filtered()
        results_list.controls.clear()

        if not filtered:
            results_list.controls.append(
                ft.Container(
                    content=ft.Text(
                        f"Brak wyników dla '{search_value}'",
                        size=13, color=ft.colors.GREY_500,
                        text_align=ft.TextAlign.CENTER,
                    ),
                    padding=ft.padding.all(20),
                )
            )
            return

        current_category = None
        for i, cmd in enumerate(filtered):
            # Category header
            cat = cmd.get("category", "")
            if cat != current_category:
                current_category = cat
                category_text.value = cat
                results_list.controls.append(
                    ft.Container(
                        content=ft.Text(cat, size=11, weight=ft.FontWeight.BOLD,
                                        color=ft.colors.GREY_400),
                        padding=ft.padding.only(left=12, top=8, bottom=4),
                    )
                )

            # Command row
            is_selected = i == selected_index
            bg = ft.colors.BLUE_700 if is_selected else ft.colors.TRANSPARENT
            icon_color = ft.colors.WHITE if is_selected else ft.colors.GREY_400

            shortcut_text = f"  {cmd['shortcut']}" if cmd.get("shortcut") else ""

            results_list.controls.append(
                ft.Container(
                    content=ft.Row(
                        [
                            ft.Icon(cmd["icon"], size=18, color=icon_color),
                            ft.Text(cmd["label"], size=14, color=ft.colors.WHITE if is_selected else ft.colors.GREY_200),
                            ft.Container(expand=True),
                            ft.Text(shortcut_text, size=11, color=ft.colors.GREY_500),
                        ],
                        spacing=10,
                    ),
                    padding=ft.padding.symmetric(horizontal=12, vertical=10),
                    border_radius=8,
                    bgcolor=bg,
                    on_click=lambda _, c=cmd: execute_command(c),
                )
            )

    # ── Execute command ────────────────────────────────────────────────

    def execute_command(cmd: dict):
        action = cmd.get("action", "")
        dialog.open = False
        page.update()

        try:
            if action == "navigate":
                route = cmd.get("route", "/")
                page.go(route)
            elif action == "publish":
                topic = cmd.get("topic", "")
                if topic:
                    page.pubsub.send_all_on_topic(topic, True)
            elif action == "show_shortcuts":
                _show_shortcuts_dialog(page)
        except Exception as exc:
            logger.warning("Command execution failed: %s", exc)

    # ── Search handler ─────────────────────────────────────────────────

    def on_search_change(e: ft.ControlEvent):
        nonlocal search_value, selected_index
        search_value = e.control.value or ""
        selected_index = 0
        render_results()
        page.update()

    # ── Keyboard handler ───────────────────────────────────────────────

    # v7.0: Zapisz i przywróć handler klawiatury (nie nadpisuj na stałe)
    _saved_keyboard_handler = None
    try:
        _saved_keyboard_handler = page.on_keyboard_event
    except Exception:
        pass

    async def on_keyboard(e: ft.KeyboardEvent):
        nonlocal selected_index
        filtered = get_filtered()

        if e.key == "Arrow Down":
            selected_index = min(selected_index + 1, len(filtered) - 1) if filtered else 0
            render_results()
            page.update()
        elif e.key == "Arrow Up":
            selected_index = max(selected_index - 1, 0) if filtered else 0
            render_results()
            page.update()
        elif e.key == "Enter" and filtered:
            execute_command(filtered[selected_index])
        elif e.key == "Escape":
            dialog.open = False
            # v7.0: Przywróć oryginalny handler
            try:
                page.on_keyboard_event = _saved_keyboard_handler
            except Exception:
                pass
            page.update()

    search_bar.on_change = on_search_change
    page.on_keyboard_event = on_keyboard

    render_results()
    return dialog


# ── Show shortcuts dialog ──────────────────────────────────────────────────


def _show_shortcuts_dialog(page: ft.Page):
    """Pokaż dialog ze wszystkimi skrótami klawiszowymi."""

    rows = []
    for cmd in COMMANDS:
        if cmd.get("shortcut"):
            rows.append(
                ft.DataRow(cells=[
                    ft.DataCell(ft.Text(cmd.get("shortcut", ""), weight=ft.FontWeight.BOLD, color=ft.colors.BLUE_200)),
                    ft.DataCell(ft.Text(cmd["label"], size=13)),
                    ft.DataCell(ft.Text(cmd.get("category", ""), size=12, color=ft.colors.GREY_500)),
                ])
            )

    dialog = ft.AlertDialog(
        title=ft.Text("Skróty klawiszowe", size=18, weight=ft.FontWeight.BOLD),
        content=ft.Container(
            content=ft.DataTable(
                columns=[
                    ft.DataColumn(ft.Text("Skrót")),
                    ft.DataColumn(ft.Text("Akcja")),
                    ft.DataColumn(ft.Text("Kategoria")),
                ],
                rows=rows,
            ),
            height=400,
        ),
        actions=[ft.TextButton("Zamknij", on_click=lambda e: _close_dialog(page, dialog))],
    )

    page.dialog = dialog
    dialog.open = True
    page.update()


def _close_dialog(page: ft.Page, dialog: ft.AlertDialog):
    dialog.open = False
    page.update()


# ── Subscribe to Ctrl+K shortcut ────────────────────────────────────────────


def subscribe_command_palette(page: ft.Page):
    """Subskrybuj zdarzenie shortcut_command_palette z shortcuts.py.

    Wywołaj w NexusRootUI po inicjalizacji page.
    """

    async def _show_palette(_):
        dialog = build_command_palette(page)
        page.dialog = dialog
        dialog.open = True
        page.update()

    # Nasłuchuj na topic z shortcuts.py (Ctrl+K)
    page.pubsub.subscribe_topic("shortcut_command_palette", _show_palette)
    logger.debug("[CMD] Command palette subscriber registered")
