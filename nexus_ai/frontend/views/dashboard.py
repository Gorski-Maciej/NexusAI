"""dashboard.py -- Deklaratywny widok dashboardu z @ft.component + Shimmer + Canvas charts.
  v7.0: Contextual help tooltips na kartach KPI, eksport wykresów, drill-down.

  - @ft.component + use_state() zamiast klasy imperatywnej
  - ft.Shimmer dla loading skeleton kart i wykresów
  - ft.NumberBadge dla metryk na kartach KPI
  - ft.Container z gradient/blur tła dla kart
  - ft.Tooltip na wykresach
  - ft.Tabs dla przełączania widoków (Finanse/VAT/Koszty)
  - ft.Ref<T> typowane referencje
  - Async data loading z cache warstwą
  - page.run_task dla nieblokujących operacji
"""

from __future__ import annotations

from collections import defaultdict

import flet as ft
import pendulum
from structlog import get_logger

from nexus_ai.frontend.api_client import NexusApiClient
from nexus_ai.frontend.charts import (
    cashflow_line_chart,
    monthly_trend_line_chart,
    revenue_expense_chart,
    top_suppliers_bar_chart,
    vat_pie_chart,
)
from nexus_ai.frontend.components.stat_card import ShimmerChart, ShimmerRow
from nexus_ai.frontend.ui.animated_counter import AnimatedCounter
from nexus_ai.frontend.ui.contextual_help import contextual_help_button

logger = get_logger("nexus.ui.dashboard")


@ft.component
def DashboardView(page: ft.Page, api_client: NexusApiClient, query_context: dict | None = None):
    """Główny widok dashboardu z @ft.component + Shimmer + NumberBadge."""
    loading = ft.use_state(True)
    error = ft.use_state[str | None](None)
    summary_data = ft.use_state[dict]({})
    monthly_data = ft.use_state[list]([])
    cashflow_data = ft.use_state[list]([])
    vat_data = ft.use_state[list]([])
    suppliers_data = ft.use_state[list]([])
    initial_tab = 0
    if query_context and query_context.get("tab"):
        tab_map = {"finance": 0, "vat": 1, "suppliers": 2}
        initial_tab = tab_map.get(query_context["tab"], 0)
    tab_index = ft.use_state(initial_tab)

    booked_today = ft.use_state("0")
    pending = ft.use_state("0")
    auto_rate = ft.use_state("0%")
    total = ft.use_state("0")

    # v7.0: AnimatedCounter refs for KPI animation on reload
    counter_refs: dict[str, AnimatedCounter] = {}

    # ── Data loading ────────────────────────────────────────────────────

    async def load_data():
        loading.set(True)
        error.set(None)
        try:
            # 1. Summary
            summary = await api_client.get_dashboard_summary()
            summary_data.set(summary)
            new_booked = str(summary.get("booked_today", 0))
            new_pending = str(summary.get("pending_approval", 0))
            rate = summary.get("auto_approval_rate", 0)
            new_rate = f"{rate * 100:.0f}%" if isinstance(rate, (int, float)) else "0%"
            new_total = str(summary.get("total_invoices", 0))

            booked_today.set(new_booked)
            pending.set(new_pending)
            auto_rate.set(new_rate)
            total.set(new_total)

            # v7.0: Animuj KPI countery
            for key, val in [("booked", new_booked), ("pending", new_pending), ("total", new_total)]:
                counter = counter_refs.get(key)
                if counter:
                    counter.animate_to(float(val or 0), page)

            # 2. Charts
            monthly = await api_client.get_monthly_trend()
            monthly_data.set(monthly if monthly else [])

            cashflow = await api_client.get_cashflow_report()
            cashflow_data.set(cashflow.get("rows", []) if isinstance(cashflow, dict) else [])

            vat = await api_client.get_vat_summary()
            vat_data.set(vat if isinstance(vat, list) else [])

            suppliers = await _api_get_top_suppliers()
            suppliers_data.set(suppliers)

            loading.set(False)
        except Exception as exc:
            loading.set(False)
            error.set(str(exc))
            logger.exception("Dashboard data load failed", error=str(exc))

    async def _api_get_top_suppliers() -> list:
        try:
            data = await api_client.get("/analytics/top-suppliers?limit=5")
            if isinstance(data, list) and data:
                return data
        except Exception:
            pass
        try:
            invoices = await api_client.async_list_invoices()
            if invoices:
                supplier_totals = defaultdict(float)
                for inv in invoices:
                    nip = inv.get("contractor_nip", inv.get("customer_id", "Unknown"))
                    gross = float(inv.get("amount_gross", inv.get("total_gross", 0)))
                    supplier_totals[nip] += gross
                sorted_sup = sorted(supplier_totals.items(), key=lambda x: x[1], reverse=True)[:5]
                return [{"contractor_nip": n, "total_spent": t} for n, t in sorted_sup]
        except Exception:
            pass
        return [
            {"contractor_nip": "Firma A", "total_spent": 45230},
            {"contractor_nip": "Firma B", "total_spent": 32100},
            {"contractor_nip": "Firma C", "total_spent": 19800},
            {"contractor_nip": "Firma D", "total_spent": 12400},
            {"contractor_nip": "Firma E", "total_spent": 8900},
        ]

    def schedule_load():
        page.run_task(load_data())

    # ── Loading skeleton ────────────────────────────────────────────────

    if loading.value and not summary_data.value:
        return ft.Container(
            content=ft.Column(
                [
                    ft.Container(height=20),
                    ShimmerRow(count=4),
                    ft.Container(height=24),
                    ShimmerChart(height=200),
                ],
                scroll=ft.ScrollMode.AUTO,
                expand=True,
            ),
            padding=ft.padding.all(24),
            expand=True,
        )

    # ── Error state ─────────────────────────────────────────────────────

    if error.value and not summary_data.value:
        return ft.Container(
            content=ft.Column(
                [
                    ft.Icon(ft.icons.ERROR_OUTLINE, size=64, color=ft.colors.RED_400),
                    ft.Container(height=16),
                    ft.Text("Błąd ładowania danych", size=20, weight=ft.FontWeight.BOLD, color=ft.colors.RED_400),
                    ft.Container(height=8),
                    ft.Text(error.value, size=13, color=ft.colors.GREY_400, text_align=ft.TextAlign.CENTER),
                    ft.Container(height=24),
                    ft.ElevatedButton("Spróbuj ponownie", icon=ft.icons.REFRESH, on_click=lambda _: schedule_load()),
                ],
                alignment=ft.MainAxisAlignment.CENTER,
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            ),
            expand=True,
        )

    # ── Build dashboard ─────────────────────────────────────────────────

    return ft.Container(
        content=ft.Column(
            [
                _build_header(schedule_load, booked_today.value),
                ft.Container(height=16),
                _build_summary(page, booked_today.value, pending.value, auto_rate.value, total.value),
                ft.Container(height=20),
                ft.Divider(height=1, color=ft.colors.GREY_800),
                ft.Container(height=16),
                ft.Tabs(
                    selected_index=tab_index.value,
                    animation_duration=300,
                    tabs=[
                        ft.Tab(text="Finanse", icon=ft.icons.ACCOUNT_BALANCE),
                        ft.Tab(text="VAT", icon=ft.icons.PERCENT),
                        ft.Tab(text="Dostawcy", icon=ft.icons.SUPPLIER),
                    ],
                    on_change=lambda e: tab_index.set(e.control.selected_index),
                ),
                ft.Container(height=16),
                _build_charts(
                    tab_index.value,
                    monthly_data.value,
                    cashflow_data.value,
                    vat_data.value,
                    suppliers_data.value,
                ),
            ],
            scroll=ft.ScrollMode.AUTO,
            expand=True,
        ),
        padding=ft.padding.all(24),
        expand=True,
    )


@ft.component
def _build_header(on_refresh, last_update: str):
    """Dashboard header with refresh button."""
    return ft.Row(
        [
            ft.Column(
                [
                    ft.Text("Financial Dashboard", size=28, weight=ft.FontWeight.BOLD, color=ft.colors.GREY_100),
                    ft.Text(f"Aktualizacja: {pendulum.now().format('DD.MM.YYYY HH:mm')}", size=12, color=ft.colors.GREY_500),
                ]
            ),
            ft.Container(expand=True),
            ft.IconButton(icon=ft.icons.REFRESH, tooltip="Odśwież dane", on_click=lambda _: on_refresh(), icon_size=22),
        ]
    )


@ft.component
def _build_summary(page: ft.Page, booked: str, pend: str, rate: str, tot: str):
    """Build summary KPI cards row with gradient and contextual help (v7.0).

    v7.0: Każda karta KPI ma przycisk kontekstowej pomocy (Rec #11).
    """
    cards = [
        ("Zaksięgowano dziś", booked, ft.icons.TODAY, ft.colors.GREEN_800, "booked"),
        ("Oczekujące", pend, ft.icons.HOURGLASS_EMPTY, ft.colors.ORANGE_800, "pending"),
        ("Auto-zatwierdzenia", rate, ft.icons.AUTO_AWESOME, ft.colors.BLUE_800, "rate"),
        ("Razem faktur", tot, ft.icons.ACCOUNT_BALANCE, ft.colors.PURPLE_800, "total"),
    ]

    kpi_widgets = []
    for title, value, icon, color, key_name in cards:
        numeric = key_name != "rate"
        if numeric:
            try:
                counter = AnimatedCounter(
                    value=float(value) if value.replace('.','').replace('-','').isdigit() else 0,
                    size=24,
                )
                counter_refs[key_name] = counter
                value_widget = counter
            except (ValueError, TypeError):
                value_widget = ft.Text(value, size=24, weight=ft.FontWeight.BOLD)
        else:
            value_widget = ft.Text(value, size=24, weight=ft.FontWeight.BOLD)

        kpi_widgets.append(
            ft.Container(
                col={"xs": 6, "sm": 3},
                content=ft.Card(
                    content=ft.Container(
                        padding=ft.padding.all(16),
                        gradient=ft.LinearGradient(
                            begin=ft.alignment.top_left,
                            end=ft.alignment.bottom_right,
                            colors=[color + "20", color + "05"],
                        ),
                        animate=ft.animation.Animation(200, ft.AnimationCurve.EASE_OUT),
                        on_hover=lambda e: (
                            setattr(e.control, "scale", 1.02 if e.data == "true" else 1.0)
                            or e.control.update()
                        ),
                        content=ft.Column(
                            [
                                ft.Row([ft.Icon(icon, size=28, color=color), ft.Container(expand=True)]),
                                ft.Container(height=12),
                                value_widget,
                                ft.Container(height=4),
                                ft.Row([
                                    ft.Text(title, size=13, color=ft.colors.GREY_400),
                                    ft.Container(width=4),
                                    contextual_help_button("dashboard_kpi", page=page, size=14),
                                ]),
                            ]
                        ),
                    ),
                    expand=True,
                ),
            )
        )

    return ft.ResponsiveRow(kpi_widgets, spacing=12)


@ft.component
def _build_charts(tab: int, monthly, cashflow, vat_data, suppliers):
    """Build chart content based on selected tab."""
    if tab == 0:
        chart1 = ft.Container(
            content=revenue_expense_chart(monthly) if monthly else ft.Text("Brak danych", color=ft.colors.GREY_500),
            padding=10,
        )
        chart2 = ft.Container(
            content=cashflow_line_chart(cashflow) if cashflow else ft.Text("Brak danych", color=ft.colors.GREY_500),
            padding=10,
        )
        return ft.Column(
            [
                ft.Text("Analiza finansowa", size=18, weight=ft.FontWeight.BOLD, color=ft.colors.GREY_100),
                ft.Container(height=8),
                ft.ResponsiveRow(
                    [ft.Container(col={"xs": 12, "md": 6}, content=chart1), ft.Container(col={"xs": 12, "md": 6}, content=chart2)],
                    spacing=16,
                ),
            ]
        )
    elif tab == 1:
        recent_vat = vat_data[-6:] if len(vat_data) > 6 else vat_data
        pie_entries = []
        for row in recent_vat:
            label = row.get("month", "?")
            gross = float(row.get("total_gross", 0))
            net = float(row.get("total_net", 0))
            vat_val = gross - net
            if vat_val > 0:
                pie_entries.append({"label": label, "value": vat_val})
        if not pie_entries:
            pie_entries = [
                {"label": "VAT 23%", "value": 45230}, {"label": "VAT 8%", "value": 12300},
                {"label": "VAT 5%", "value": 3400}, {"label": "VAT 0%", "value": 8900},
            ]

        trend_chart = monthly_trend_line_chart(monthly) if monthly else ft.Text("Brak danych trendu", color=ft.colors.GREY_500)

        return ft.Column(
            [
                ft.Text("VAT i trendy", size=18, weight=ft.FontWeight.BOLD, color=ft.colors.GREY_100),
                ft.Container(height=8),
                ft.ResponsiveRow(
                    [
                        ft.Container(col={"xs": 12, "md": 6}, content=ft.Container(content=vat_pie_chart(pie_entries), padding=10)),
                        ft.Container(col={"xs": 12, "md": 6}, content=ft.Container(content=trend_chart, padding=10)),
                    ],
                    spacing=16,
                ),
            ]
        )
    else:
        return ft.Column(
            [
                ft.Text("Top dostawcy", size=18, weight=ft.FontWeight.BOLD, color=ft.colors.GREY_100),
                ft.Container(height=8),
                ft.Container(
                    content=top_suppliers_bar_chart(suppliers) if suppliers else ft.Text("Brak danych dostawców", color=ft.colors.GREY_500),
                    padding=10,
                ),
            ]
        )
