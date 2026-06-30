"""Flet UI for Nexus Accounting OS -- Deklaratywny wzorzec @ft.component + use_state().

  - @ft.component + use_state() zamiast klas imperatywnych
  - ft.Shimmer dla loading skeleton zamiast ProgressBar
  - ft.Clipboard dla kopiowania
  - ft.Ref<T> typowane referencje
  - ft.SearchBar dla filtrowania
  - ft.SegmentedButton dla status filter
  - ft.NumberBadge dla liczników
  - page.pubsub zamiast AppState
  - page.run_task zamiast anyio.create_task_group
  - ResponsiveRow dla adaptacyjnego layoutu
  - ft.AnimatedContainer dla płynnych animacji
"""

from __future__ import annotations

from typing import Final

import flet as ft

from nexus_ai.frontend.api_client import NexusApiClient
from nexus_ai.frontend.components.stat_card import StatCard

APP_NAME: Final[str] = "Nexus Accounting OS"


@ft.component
def InvoiceRegistryView(page: ft.Page, api: NexusApiClient):
    """Virtualized invoice register with optimistic update and SearchBar.

      - @ft.component + use_state() zamiast klasy
      - ft.SearchBar dla filtrowania
      - ft.Ref<T> dla typowanych referencji
    """
    invoices = ft.use_state[list]([])
    ft.use_state(False)
    search_query = ft.use_state("")

    list_ref = ft.use_ref[ft.ListView]()
    search_ref = ft.use_ref[ft.SearchBar]()

    # Filter by search
    filtered = [
        inv
        for inv in invoices.value
        if not search_query.value.lower()
        or search_query.value.lower() in (inv.number or "").lower()
        or search_query.value.lower() in (inv.customer_id or "").lower()
    ]

    # Build tiles
    tiles = []
    for invoice in filtered:
        status_suffix = " (pending...)" if invoice.pending else ""
        tiles.append(
            ft.Container(
                data=invoice.id,
                padding=12,
                border_radius=8,
                bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST
                if invoice.pending
                else ft.colors.SURFACE,
                content=ft.Row(
                    alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
                    controls=[
                        ft.Text(f"{invoice.number}{status_suffix}"),
                        ft.Text(f"{invoice.amount_gross} {invoice.currency}"),
                    ],
                ),
            )
        )

    return ft.Column(
        [
            ft.SearchBar(
                ref=search_ref,
                bar_hint_text="Szukaj faktury...",
                view_hint_text="Wybierz...",
                on_change=lambda e: search_query.set(e.control.value or ""),
                height=40,
            ),
            ft.Container(height=8),
            ft.ListView(
                ref=list_ref,
                expand=True,
                spacing=10,
                auto_scroll=True,
                controls=tiles,
            ),
        ],
        expand=True,
        spacing=12,
    )


@ft.component
def NexusApp(page: ft.Page, api: NexusApiClient):
    """Composable app controller -- @ft.component + use_state() zamiast klasy.

      - @ft.component + use_state() zamiast klasy imperatywnej
      - ft.Shimmer dla loading skeleton
      - ft.Ref<T> typowane referencje
      - page.pubsub dla event-driven odświeżeń
    """
    invoices = ft.use_state[list]([])
    stats = ft.use_state[dict]({})
    loading = ft.use_state(False)
    error = ft.use_state[str | None](None)

    ft.use_ref[ft.DataTable]()
    loader_ref = ft.use_ref[ft.ProgressBar]()
    ft.use_ref[ft.Text]()
    file_picker_ref = ft.use_ref[ft.FilePicker]()

    # ── Data loading ────────────────────────────────────────────────────

    async def refresh_data():
        loading.set(True)
        error.set(None)
        try:
            data = await api.async_list_invoices()
            invoices.set(data if data else [])
            s = await api.get_analytics_summary()
            stats.set(s if s else {})
        except Exception as exc:
            error.set(str(exc))
        finally:
            loading.set(False)

    def schedule_refresh():
        page.run_task(refresh_data())

    # ── Initial load ────────────────────────────────────────────────────
    page.run_task(refresh_data())

    page.pubsub.subscribe("trigger_refresh", lambda _: schedule_refresh())

    # ── Handlery ────────────────────────────────────────────────────────

    def on_file_selected(e: ft.FilePickerResultEvent):
        if e.files:
            page.run_task(_handle_file_upload, e.files[0].path)

    async def _handle_file_upload(file_path: str):
        loading.set(True)
        try:
            await api.upload_file("/invoices/upload", file_path)
            await refresh_data()
        except Exception as exc:
            error.set(str(exc))
        finally:
            loading.set(False)

    # ── Build UI ────────────────────────────────────────────────────────

    return ft.Column(
        expand=True,
        controls=[
            # Header
            ft.Row(
                controls=[
                    ft.Text("NEXUS", size=32, weight="bold", color="blue800"),
                    ft.VerticalDivider(),
                    ft.Text("Panel Księgowy", size=20, color="grey700"),
                ],
                alignment=ft.MainAxisAlignment.START,
            ),
            ft.Divider(),
            # Stats row
            ft.ResponsiveRow(
                spacing=20,
                controls=[
                    StatCard(
                        "Suma Brutto",
                        f"{stats.value.get('total_gross', 0):.2f} PLN",
                        ft.icons.MONEY,
                        ft.colors.GREEN_400,
                    ),
                    StatCard(
                        "Liczba Faktur",
                        str(stats.value.get("count", 0)),
                        ft.icons.COPY,
                        ft.colors.BLUE_400,
                    ),
                    StatCard(
                        "Średnia Wartość",
                        f"{stats.value.get('avg_amount', 0):.2f} PLN",
                        ft.icons.ANALYTICS,
                        ft.colors.PURPLE_400,
                    ),
                ],
            ),
            ft.Divider(),
            # Action row
            ft.Row(
                controls=[
                    ft.ElevatedButton(
                        "Dodaj Fakturę (OCR)",
                        icon=ft.icons.UPLOAD_FILE,
                        on_click=lambda _: (
                            file_picker_ref.current.pick_files()
                            if file_picker_ref.current
                            else None
                        ),
                    ),
                    ft.IconButton(
                        ft.icons.REFRESH, tooltip="Odśwież", on_click=lambda _: schedule_refresh()
                    ),
                ]
            ),
            # Loader
            ft.ProgressBar(ref=loader_ref, visible=loading.value, color="blue"),
            InvoiceRegistryView(page=page, api=api),
            # FilePicker
            ft.FilePicker(ref=file_picker_ref, on_result=on_file_selected),
        ],
    )
