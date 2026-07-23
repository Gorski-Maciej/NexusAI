"""contextual_help.py -- Contextual Help Tooltips (v7.0 Rec #11: Innowacja 5).

  Każdy kluczowy element UI ma przycisk "?" który pokazuje tooltip z wyjaśnieniem:
  - Co to robi
  - Dlaczego agent to sugeruje
  - Link do odpowiednich przepisów / dokumentacji

  - HelpRegistry: rejestr wszystkich kontekstowych pomocy
  - contextual_help_button(): przycisk "?" z tooltipem
  - explain_decision(): wyjaśnienie decyzji AI
"""

from __future__ import annotations

import flet as ft
from structlog import get_logger

logger = get_logger("nexus.ui.help")


# ── Help Registry ────────────────────────────────────────────────────────────


class HelpRegistry:
    """Rejestr kontekstowych pomocy dla elementów UI."""

    _entries: dict[str, dict] = {
        "dashboard_kpi": {
            "title": "Karty KPI",
            "what": "Podsumowanie najważniejszych wskaźników finansowych w czasie rzeczywistym.",
            "why": "Pokazują stan finansów firmy na pierwszy rzut oka — bez potrzeby przeglądania raportów.",
            "link": "/docs/dashboard",
        },
        "decision_feed": {
            "title": "Feed Decyzyjny",
            "what": "Strumień kart decyzyjnych — każda karta to jedna decyzja księgowa do zatwierdzenia.",
            "why": "Agent AI wykonał 95% pracy. Ty tylko podejmujesz ostateczną decyzję jednym kliknięciem.",
            "link": "/docs/decision-feed",
        },
        "trust_score": {
            "title": "Trust Score",
            "what": "Ocena pewności agenta AI co do poprawności decyzji (0-100%).",
            "why": "Im wyższy Trust Score, tym bardziej agent jest pewny. Powyżej 92% — decyzje są podejmowane automatycznie.",
            "link": "/docs/trust-score",
        },
        "financial_impact": {
            "title": "Financial Impact",
            "what": "Rzeczywisty wpływ finansowy każdej opcji decyzyjnej na Twój portfel.",
            "why": "Zamiast parametrów technicznych (VAT 23%, amortyzacja liniowa), widzisz KONKRETNĄ kwotę w PLN.",
            "link": "/docs/financial-impact",
        },
        "invoice_list": {
            "title": "Lista Faktur",
            "what": "Pełna lista faktur z filtrami statusu i wyszukiwarką.",
            "why": "Statusy pokazują etap przetwarzania: zielony = zaksięgowano, pomarańczowy = w trakcie, czerwony = błąd.",
            "link": "/docs/invoices",
        },
        "vat_chart": {
            "title": "Wykres VAT",
            "what": "Struktura podatku VAT z podziałem na stawki (23%, 8%, 5%, 0%).",
            "why": "Pomaga zrozumieć strukturę podatkową firmy i planować zobowiązania wobec US.",
            "link": "/docs/vat",
        },
        "cashflow_chart": {
            "title": "Prognoza Przepływów",
            "what": "Prognoza przepływów pieniężnych na podstawie historycznych danych i zaplanowanych płatności.",
            "why": "Pomaga uniknąć zatorów płatniczych — widzisz z wyprzedzeniem, kiedy może zabraknąć gotówki.",
            "link": "/docs/cashflow",
        },
        "supplier_chart": {
            "title": "Top Dostawcy",
            "what": "Ranking 5 największych dostawców według sumy wydatków.",
            "why": "Pomaga zidentyfikować kluczowych dostawców i negocjować lepsze warunki.",
            "link": "/docs/suppliers",
        },
        "auto_post": {
            "title": "Auto-Księgowanie",
            "what": "Tryb automatycznego księgowania faktur (Trust Score >= 92%).",
            "why": "Agent automatycznie księguje faktury, co do których ma bardzo wysoką pewność. Ty oszczędzasz czas.",
            "link": "/docs/auto-post",
        },
        "theme_switcher": {
            "title": "Motyw",
            "what": "Przełącznik między jasnym a ciemnym motywem (lub automatycznym).",
            "why": "Ciemny motyw jest domyślny dla komfortu oczu. Jasny może być lepszy w dobrze oświetlonym biurze.",
            "link": "/docs/theme",
        },
        "command_palette": {
            "title": "Paleta Komend",
            "what": "Globalna wyszukiwarka komend (Ctrl+K) — jak w VS Code.",
            "why": "Pozwala błyskawicznie wykonywać akcje bez odrywania rąk od klawiatury.",
            "link": "/docs/shortcuts",
        },
        "notification_center": {
            "title": "Centrum Powiadomień",
            "what": "Zbiorcze centrum wszystkich powiadomień systemowych.",
            "why": "Zamiast przelotnych komunikatów, wszystkie alerty w jednym miejscu z możliwością działania.",
            "link": "/docs/notifications",
        },
    }

    @classmethod
    def get(cls, key: str) -> dict | None:
        return cls._entries.get(key)

    @classmethod
    def register(cls, key: str, entry: dict):
        cls._entries[key] = entry


# ── Contextual Help Button ──────────────────────────────────────────────────


def contextual_help_button(
    help_key: str,
    page: ft.Page | None = None,
    size: int = 16,
    icon: str = ft.icons.HELP_OUTLINE,
) -> ft.IconButton:
    """Przycisk '?' z tooltipem kontekstowym.

    Args:
        help_key: Klucz w HelpRegistry (np. "trust_score", "decision_feed")
        page: Opcjonalna instancja Page do pokazania dialogu
        size: Rozmiar ikony
        icon: Ikona przycisku (domyślnie HELP_OUTLINE)

    Returns:
        ft.IconButton z tooltipem i handlerem kliknięcia
    """
    entry = HelpRegistry.get(help_key)
    if not entry:
        logger.debug("No help entry for key: %s", help_key)
        return ft.IconButton(
            icon=icon,
            icon_size=size,
            tooltip="Brak pomocy kontekstowej",
        )

    tooltip_text = entry.get("what", "")

    def show_help(e):
        if page:
            dialog = _build_help_dialog(entry)
            page.dialog = dialog
            dialog.open = True
            page.update()

    return ft.IconButton(
        icon=icon,
        icon_size=size,
        tooltip=f"{entry.get('title', 'Pomoc')}: {tooltip_text[:80]}...",
        on_click=show_help if page else None,
        style=ft.ButtonStyle(
            color=ft.colors.GREY_500,
            overlay_color=ft.colors.with_opacity(0.1, ft.colors.BLUE_400),
        ),
    )


def _build_help_dialog(entry: dict) -> ft.AlertDialog:
    """Zbuduj dialog z kontekstową pomocą."""

    return ft.AlertDialog(
        title=ft.Row(
            [
                ft.Icon(ft.icons.HELP_OUTLINE, color=ft.colors.BLUE_400, size=24),
                ft.Text(
                    entry.get("title", "Pomoc"),
                    size=18,
                    weight=ft.FontWeight.BOLD,
                ),
            ],
        ),
        content=ft.Column(
            [
                ft.Container(height=8),
                ft.Text("📋 Co to robi?", size=14, weight=ft.FontWeight.BOLD, color=ft.colors.GREY_200),
                ft.Text(entry.get("what", ""), size=13, color=ft.colors.GREY_400),
                ft.Container(height=12),
                ft.Text("💡 Dlaczego?", size=14, weight=ft.FontWeight.BOLD, color=ft.colors.GREY_200),
                ft.Text(entry.get("why", ""), size=13, color=ft.colors.GREY_400),
            ],
            tight=True,
            width=420,
        ),
        actions=[
            ft.TextButton(
                "📖 Dokumentacja",
                url=entry.get("link", "#"),
                style=ft.ButtonStyle(color=ft.colors.BLUE_400),
            ) if entry.get("link") else ft.Container(),
            ft.TextButton("Zamknij"),
        ],
        shape=ft.RoundedRectangleBorder(radius=12),
    )
