"""
company_formation_wizard.py — Flet UI: Kreator zakładania JDG (v7.0.1).

Raport v7.0 Pomysł #7: Automated Company Formation.
Agent AI przeprowadza przez CAŁY proces w 15 minut:
- Krok 1: Dane osobowe
- Krok 2: Kody PKD
- Krok 3: Szacunkowe przychody → automatyczna analiza
- Krok 4: Wynik: optymalna forma opodatkowania + ZUS + VAT
- Export: PDF + XML CEIDG-1
"""
from __future__ import annotations

from typing import Any

from structlog import get_logger

logger = get_logger("nexus.ui.formation")

try:
    import flet as ft
    HAS_FLET = True
except ImportError:
    HAS_FLET = False


def build_company_formation_wizard(
    current_step: int = 1,
    profile_data: dict[str, Any] | None = None,
    formation_result: dict[str, Any] | None = None,
    on_next: Any = None,
    on_prev: Any = None,
    on_finish: Any = None,
) -> Any:
    """Zbuduj kreator zakładania JDG jako ft.Container.

    Args:
        current_step: Aktualny krok (1-4)
        profile_data: Dane profilu firmy
        formation_result: Wynik analizy (dla kroku 4)
        on_next: Callback dla przycisku "Dalej"
        on_prev: Callback dla przycisku "Wstecz"
        on_finish: Callback dla przycisku "Zakończ"
    """
    if not HAS_FLET:
        return None

    profile = profile_data or {}

    steps = [
        ("1", "Dane osobowe", current_step >= 1),
        ("2", "Kody PKD", current_step >= 2),
        ("3", "Przychody", current_step >= 3),
        ("4", "Wynik", current_step >= 4),
    ]

    # Build step indicators
    step_indicators = []
    for num, label, active in steps:
        bg = ft.colors.PURPLE_700 if active else ft.colors.SURFACE_VARIANT
        color = ft.colors.WHITE if active else ft.colors.GREY_500
        step_indicators.append(
            ft.Column([
                ft.Container(
                    content=ft.Text(num, size=14, weight=ft.FontWeight.BOLD, color=color),
                    width=36, height=36,
                    border_radius=18,
                    bgcolor=bg,
                    alignment=ft.alignment.center,
                ),
                ft.Text(label, size=10, color=color),
            ], horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=4)
        )

    # Build step content
    if current_step == 1:
        content = _build_step_1(profile, on_next)
    elif current_step == 2:
        content = _build_step_2(profile, on_next, on_prev)
    elif current_step == 3:
        content = _build_step_3(profile, on_next, on_prev)
    else:
        content = _build_step_4(profile, formation_result, on_finish, on_prev)

    return ft.Container(
        content=ft.Column([
            ft.Row([
                ft.Icon(ft.icons.BUSINESS, color=ft.colors.PURPLE_400, size=24),
                ft.Text("Kreator zakładania JDG", size=20, weight=ft.FontWeight.BOLD, color=ft.colors.WHITE),
            ]),
            ft.Text(
                "Agent AI przeprowadzi Cię przez proces założenia działalności w 15 minut",
                size=13, color=ft.colors.GREY_500,
            ),
            ft.Container(height=16),
            ft.Row(step_indicators, alignment=ft.MainAxisAlignment.SPACE_AROUND),
            ft.Container(height=20),
            content,
        ], spacing=0),
        padding=ft.padding.all(24),
        border_radius=ft.border_radius.all(14),
        bgcolor="#161B22",
        border=ft.border.all(1, "#30363D"),
        expand=True,
    )


def _build_step_1(profile: dict, on_next: Any) -> Any:
    """Krok 1: Dane osobowe."""
    name_field = ft.TextField(
        label="Imię i nazwisko",
        value=profile.get("full_name", ""),
        prefix_icon=ft.icons.PERSON,
        border_radius=10,
        expand=True,
    )
    pesel_field = ft.TextField(
        label="PESEL",
        value=profile.get("pesel", ""),
        prefix_icon=ft.icons.BADGE,
        border_radius=10,
        max_length=11,
    )
    company_field = ft.TextField(
        label="Nazwa firmy (opcjonalnie)",
        value=profile.get("company_name", ""),
        prefix_icon=ft.icons.STORE,
        border_radius=10,
        expand=True,
    )
    address_field = ft.TextField(
        label="Adres",
        value=profile.get("address", ""),
        prefix_icon=ft.icons.HOME,
        border_radius=10,
        expand=True,
    )
    city_field = ft.TextField(
        label="Miasto",
        value=profile.get("city", ""),
        prefix_icon=ft.icons.LOCATION_CITY,
        border_radius=10,
    )
    postal_field = ft.TextField(
        label="Kod pocztowy",
        value=profile.get("postal_code", ""),
        prefix_icon=ft.icons.MAIL,
        border_radius=10,
        max_length=6,
    )

    return ft.Column([
        ft.Text("Krok 1/4: Dane osobowe", size=16, weight=ft.FontWeight.BOLD, color=ft.colors.WHITE),
        ft.Container(height=12),
        ft.Row([name_field, pesel_field], spacing=12),
        ft.Container(height=8),
        company_field,
        ft.Container(height=8),
        address_field,
        ft.Container(height=8),
        ft.Row([city_field, postal_field], spacing=12),
        ft.Container(height=20),
        ft.Row([
            ft.Container(expand=True),
            ft.ElevatedButton(
                "Dalej →",
                icon=ft.icons.ARROW_FORWARD,
                on_click=on_next,
                style=ft.ButtonStyle(bgcolor=ft.colors.PURPLE_700, color=ft.colors.WHITE),
            ),
        ]),
    ], spacing=0)


def _build_step_2(profile: dict, on_next: Any, on_prev: Any) -> Any:
    """Krok 2: Wybór kodów PKD."""
    selected_pkd = profile.get("pkd_codes", [])

    # Common PKD codes for JDG in Poland
    common_pkd = [
        ("62.01.Z", "Oprogramowanie"),
        ("62.02.Z", "Doradztwo IT"),
        ("70.22.Z", "Doradztwo biznesowe"),
        ("74.10.Z", "Projektowanie"),
        ("85.59.B", "Szkolenia"),
        ("41.10.Z", "Budownictwo"),
        ("49.41.Z", "Transport"),
        ("47.91.Z", "Sprzedaż internetowa"),
        ("96.09.Z", "Pozostałe usługi"),
    ]

    pkd_chips = ft.Row(
        controls=[
            ft.Chip(
                label=ft.Text(f"{code} — {name}", size=11),
                leading=ft.Icon(
                    ft.icons.CHECK_CIRCLE if code in selected_pkd else ft.icons.ADD_CIRCLE,
                    size=16,
                    color=ft.colors.PURPLE_400 if code in selected_pkd else ft.colors.GREY_500,
                ),
                bgcolor=ft.colors.PURPLE_900 if code in selected_pkd else ft.colors.SURFACE_VARIANT,
            )
            for code, name in common_pkd
        ],
        wrap=True,
        spacing=6,
    )

    custom_pkd = ft.TextField(
        label="Lub wpisz własny kod PKD (np. 62.01.Z)",
        prefix_icon=ft.icons.CODE,
        border_radius=10,
        expand=True,
    )

    return ft.Column([
        ft.Text("Krok 2/4: Kody PKD", size=16, weight=ft.FontWeight.BOLD, color=ft.colors.WHITE),
        ft.Text(
            "Wybierz główne kody PKD. Minimum 1, maksimum 10.",
            size=12, color=ft.colors.GREY_500,
        ),
        ft.Container(height=12),
        pkd_chips,
        ft.Container(height=12),
        custom_pkd,
        ft.Container(height=20),
        ft.Row([
            ft.TextButton("← Wstecz", icon=ft.icons.ARROW_BACK, on_click=on_prev),
            ft.Container(expand=True),
            ft.ElevatedButton(
                "Dalej →",
                icon=ft.icons.ARROW_FORWARD,
                on_click=on_next,
                style=ft.ButtonStyle(bgcolor=ft.colors.PURPLE_700, color=ft.colors.WHITE),
            ),
        ]),
    ], spacing=0)


def _build_step_3(profile: dict, on_next: Any, on_prev: Any) -> Any:
    """Krok 3: Szacunkowe przychody i koszty."""
    revenue_field = ft.TextField(
        label="Szacunkowy miesięczny przychód (PLN)",
        value=str(profile.get("estimated_monthly_revenue", "")),
        prefix_icon=ft.icons.TRENDING_UP,
        border_radius=10,
        keyboard_type=ft.KeyboardType.NUMBER,
        expand=True,
    )
    costs_field = ft.TextField(
        label="Szacunkowe miesięczne koszty (PLN)",
        value=str(profile.get("estimated_monthly_costs", "")),
        prefix_icon=ft.icons.TRENDING_DOWN,
        border_radius=10,
        keyboard_type=ft.KeyboardType.NUMBER,
        expand=True,
    )

    return ft.Column([
        ft.Text("Krok 3/4: Przychody i koszty", size=16, weight=ft.FontWeight.BOLD, color=ft.colors.WHITE),
        ft.Text(
            "Na podstawie tych danych AI dobierze optymalną formę opodatkowania i ZUS.",
            size=12, color=ft.colors.GREY_500,
        ),
        ft.Container(height=16),
        ft.Row([revenue_field, costs_field], spacing=12),
        ft.Container(height=12),
        ft.Container(
            content=ft.Column([
                ft.Row([
                    ft.Icon(ft.icons.LIGHTBULB, color=ft.colors.YELLOW_400, size=18),
                    ft.Text("Wskazówka", size=13, weight=ft.FontWeight.BOLD, color=ft.colors.YELLOW_400),
                ]),
                ft.Text(
                    "Przy niskich kosztach (< 30% przychodu) ryczałt jest zwykle najkorzystniejszy. "
                    "Przy wysokich kosztach (> 50%) skala podatkowa daje więcej możliwości odliczeń.",
                    size=12, color=ft.colors.GREY_400,
                ),
            ], spacing=4),
            padding=12,
            border_radius=10,
            bgcolor=ft.colors.YELLOW_900,
        ),
        ft.Container(height=20),
        ft.Row([
            ft.TextButton("← Wstecz", icon=ft.icons.ARROW_BACK, on_click=on_prev),
            ft.Container(expand=True),
            ft.ElevatedButton(
                "Analizuj →",
                icon=ft.icons.ANALYTICS,
                on_click=on_next,
                style=ft.ButtonStyle(bgcolor=ft.colors.PURPLE_700, color=ft.colors.WHITE),
            ),
        ]),
    ], spacing=0)


def _build_step_4(
    profile: dict,
    result: dict[str, Any] | None,
    on_finish: Any,
    on_prev: Any,
) -> Any:
    """Krok 4: Wynik analizy."""
    if not result:
        return ft.Column([
            ft.Text("Krok 4/4: Wynik analizy", size=16, weight=ft.FontWeight.BOLD, color=ft.colors.WHITE),
            ft.Container(height=12),
            ft.ProgressRing(color=ft.colors.PURPLE_400),
            ft.Text("Analizuję...", size=14, color=ft.colors.GREY_500),
            ft.Container(height=20),
            ft.Row([
                ft.TextButton("← Wstecz", icon=ft.icons.ARROW_BACK, on_click=on_prev),
            ]),
        ], spacing=0, horizontal_alignment=ft.CrossAxisAlignment.CENTER)

    net_income = result.get("monthly_net_income", 0)
    annual_tax = result.get("annual_tax_estimate", 0)
    monthly_zus = result.get("monthly_zus", 0)
    tax_form = result.get("profile", {}).get("tax_form", "skala_podatkowa")
    warnings = result.get("warnings", [])
    recommendations = result.get("recommendations", [])

    tax_labels = {
        "skala_podatkowa": "Skala podatkowa (12%/32%)",
        "podatek_liniowy": "Podatek liniowy (19%)",
        "ryczalt": "Ryczałt",
        "karta_podatkowa": "Karta podatkowa",
    }

    # Result cards
    result_cards = [
        _result_card(
            "💰 Miesięczny dochód netto",
            f"{net_income:,.0f} PLN",
            ft.colors.GREEN_400,
            ft.icons.ACCOUNT_BALANCE_WALLET,
        ),
        _result_card(
            "📊 Roczny podatek (szac.)",
            f"{annual_tax:,.0f} PLN",
            ft.colors.ORANGE_400,
            ft.icons.CALCULATE,
        ),
        _result_card(
            "🏥 Miesięczny ZUS",
            f"{monthly_zus:,.2f} PLN",
            ft.colors.BLUE_400,
            ft.icons.LOCAL_HOSPITAL,
        ),
        _result_card(
            "📋 Optymalna forma",
            tax_labels.get(tax_form, tax_form),
            ft.colors.PURPLE_400,
            ft.icons.ASSIGNMENT,
        ),
    ]

    # Warnings
    warning_widgets = []
    for w in warnings:
        warning_widgets.append(
            ft.Row([
                ft.Icon(ft.icons.WARNING, color=ft.colors.ORANGE_400, size=16),
                ft.Text(w, size=12, color=ft.colors.ORANGE_400),
            ], spacing=8)
        )

    # Recommendations
    rec_widgets = []
    for r in recommendations:
        rec_widgets.append(
            ft.Row([
                ft.Icon(ft.icons.CHECK_CIRCLE, color=ft.colors.GREEN_400, size=16),
                ft.Text(r, size=12, color=ft.colors.GREEN_400),
            ], spacing=8)
        )

    return ft.Column([
        ft.Text("Krok 4/4: Wynik analizy", size=16, weight=ft.FontWeight.BOLD, color=ft.colors.WHITE),
        ft.Container(height=16),
        ft.Row(result_cards[:2], spacing=12),
        ft.Container(height=8),
        ft.Row(result_cards[2:], spacing=12),
        ft.Container(height=16),
        ft.Divider(color="#30363D"),
        ft.Container(height=8),
        ft.Text("✅ Rekomendacje AI:", size=14, weight=ft.FontWeight.BOLD, color=ft.colors.GREEN_400),
        ft.Container(height=8),
        *([ft.Column(recommendation_widgets, spacing=6)] if rec_widgets else []),
        *([ft.Column(warning_widgets, spacing=6)] if warning_widgets else []),
        ft.Container(height=20),
        ft.Row([
            ft.TextButton("← Wstecz", icon=ft.icons.ARROW_BACK, on_click=on_prev),
            ft.Container(expand=True),
            ft.ElevatedButton(
                "📄 Pobierz CEIDG-1 (XML)",
                icon=ft.icons.DOWNLOAD,
                on_click=on_finish,
                style=ft.ButtonStyle(bgcolor=ft.colors.GREEN_700, color=ft.colors.WHITE),
            ),
        ]),
    ], spacing=0)


def _result_card(title: str, value: str, color: str, icon: Any) -> Any:
    """Mini-karta z pojedynczym wynikiem."""
    return ft.Container(
        content=ft.Column([
            ft.Row([
                ft.Icon(icon, color=color, size=18),
                ft.Text(title, size=10, color=ft.colors.GREY_500),
            ], spacing=6),
            ft.Text(value, size=18, weight=ft.FontWeight.BOLD, color=color),
        ], spacing=4),
        padding=ft.padding.all(14),
        border_radius=10,
        bgcolor="#21262D",
        border=ft.border.all(1, "#30363D"),
        expand=True,
    )
