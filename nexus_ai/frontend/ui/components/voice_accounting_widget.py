"""
voice_accounting_widget.py — Flet UI widget dla Voice-First Accounting (v7.0.1).

Zwraca natywne komponenty Flet: przycisk mikrofonu, input z przykładowymi
komendami, status nasłuchiwania. Gotowe do wstawienia w dashboard.
"""
from __future__ import annotations

from typing import Any

from structlog import get_logger

logger = get_logger("nexus.ui.voice")

# Sprawdzamy czy Flet jest dostępny
try:
    import flet as ft
    HAS_FLET = True
except ImportError:
    HAS_FLET = False


# Przykładowe komendy głosowe
VOICE_COMMAND_EXAMPLES: dict[str, str] = {
    "Pokaż VAT": "Pokaż raport VAT za bieżący miesiąc",
    "Pokaż PIT": "Pokaż podsumowanie PIT za ten rok",
    "Kalendarz": "Pokaż kalendarz podatkowy na najbliższe 30 dni",
    "Zaksięguj fakturę": 'Zaksięguj fakturę od "Nazwa firmy" na kwotę 5000 PLN',
    "Stan konta": "Pokaż aktualne saldo i cash flow",
    "Oszczędności": "Ile zaoszczędziłem dzięki AI w tym roku?",
    "Negocjuj": "Negocjuj warunki płatności dla kontrahenta XYZ",
    "Auto-post": "Pokaż statystyki auto-posta i poziom autonomii",
    "Kondycja firmy": "Jaka jest ogólna kondycja finansowa firmy?",
    "Ostatnie faktury": "Pokaż 10 ostatnich faktur",
    "Nowa firma": "Pomóż mi założyć nową działalność gospodarczą",
    "Doradź": "Jaka forma opodatkowania jest dla mnie najlepsza?",
}


def build_voice_accounting_widget_compact() -> Any:
    """Zbuduj kompaktowy przycisk mikrofonu (sam przycisk)."""
    if not HAS_FLET:
        return None
    return ft.IconButton(
        icon=ft.icons.MIC,
        tooltip="Kliknij i mów — Hej Nexus...",
        icon_color=ft.colors.PURPLE_400,
        icon_size=28,
        on_click=None,  # Obsługa w widoku nadrzędnym
    )


def build_voice_accounting_widget_full() -> list[Any]:
    """Zbuduj pełny widget Voice Accounting z inputem i przykładami."""
    if not HAS_FLET:
        return []

    voice_input = ft.TextField(
        hint_text='Np. "Pokaż VAT za czerwiec" lub "Zaksięguj fakturę na 5000 PLN"',
        prefix_icon=ft.icons.KEYBOARD_VOICE,
        border_radius=12,
        expand=True,
    )

    status_text = ft.Text(
        "🎤 Gotowy do nasłuchiwania...",
        color=ft.colors.GREY_500,
        size=12,
    )

    example_chips = ft.Row(
        controls=[
            ft.Chip(
                label=ft.Text(label, size=11),
                leading=ft.Icon(ft.icons.TOUCH_APP, size=14),
                on_click=None,  # Obsługa w widoku nadrzędnym
            )
            for label, _ in list(VOICE_COMMAND_EXAMPLES.items())[:5]
        ],
        wrap=True,
        spacing=4,
    )

    return [voice_input, status_text, example_chips]
