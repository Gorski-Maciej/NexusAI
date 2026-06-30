"""Invoice List View — @ft.component + SearchBar + SegmentedButton + URL = State.

  - @ft.component + use_state() zamiast klasy imperatywnej
  - ft.SearchBar dla wyszukiwania faktur
  - ft.SegmentedButton dla filtrów statusu
  - ft.NumberBadge dla liczników
  - URL = State: filtry/search pochodzą z URL i są zsynchronizowane
  - update_url_with_filters() z router.py dla dwukierunkowej synchronizacji
  - Status colors z mapowaniem
  - page.run_task dla async load
"""

from __future__ import annotations


import flet as ft
from structlog import get_logger

from nexus_ai.frontend.router import update_url_with_filters

logger = get_logger("nexus.ui.invoices")

INVOICE_STATUS_COLORS = {
    "APPROVED": ft.colors.GREEN,
    "PROCESSING": ft.colors.ORANGE,
    "MANUAL_REVIEW": ft.colors.BLUE,
    "FAILED": ft.colors.RED,
    "NEW": ft.colors.GREY,
    "PENDING": ft.colors.AMBER,
}


@ft.component
def InvoiceListView(page: ft.Page, api_client, query_context: dict | None = None):
    """Modern invoice list view — URL = State synchronizacja filtrów.

      - @ft.component + use_state() zamiast klasy
      - ft.SearchBar z wyszukiwarką
      - ft.SegmentedButton dla filtrów statusu
      - URL = State: filtry zquery params aktualizują URL
      - ft.NumberBadge dla liczników
    """
    initial_q = (query_context or {}).get("q") or ""
    initial_status = (query_context or {}).get("status") or None

    invoices = ft.use_state[list]([])
    loading = ft.use_state(True)
    error = ft.use_state[str | None](None)
    search_query = ft.use_state(initial_q)
    selected_filter = ft.use_state[str | None](initial_status)

    search_ref = ft.use_ref[ft.SearchBar]()

    filter_segments = ft.SegmentedButton(
        selected={initial_status} if initial_status else set(),
        segments=[
            ft.Segment(value="ALL", label=ft.Text("Wszystkie")),
            ft.Segment(value="APPROVED", label=ft.Text("Zatwierdzone")),
            ft.Segment(value="PROCESSING", label=ft.Text("Przetwarzane")),
            ft.Segment(value="MANUAL_REVIEW", label=ft.Text("Do weryfikacji")),
            ft.Segment(value="FAILED", label=ft.Text("Błędy")),
        ],
        on_change=lambda e: _on_filter_change(list(e.selected)[0] if e.selected else None),
    )

    # ── URL = State: synchronizacja ────────────────────────────────────

    def _on_filter_change(new_filter: str | None):
        """Zmiana filtra → aktualizacja URL."""
        selected_filter.set(new_filter)
        update_url_with_filters(
            page,
            "/invoices",
            {
                "q": search_query.value or None if search_query.value != initial_q else None,
                "status": new_filter,
            },
        )

    def _on_search_submit(value: str):
        """Zatwierdzenie wyszukiwania → aktualizacja URL.

        nie przy każdym keystroke — zapobiega infinite re-render loop.
        """
        search_query.set(value)
        filters = {"q": value or None}
        if selected_filter.value:
            filters["status"] = selected_filter.value
        update_url_with_filters(page, "/invoices", filters)

    # ── Data loading ────────────────────────────────────────────────────

    async def load_data():
        loading.set(True)
        error.set(None)
        try:
            params = {"limit": 50}
            if search_query.value:
                params["q"] = search_query.value
            if selected_filter.value:
                params["status"] = selected_filter.value

            resp = await api_client.get("/invoices", params=params)
            data = resp if isinstance(resp, list) else resp.get("items", [])
            invoices.set(data)
            loading.set(False)
        except Exception as exc:
            loading.set(False)
            error.set(str(exc))

    # ── Filtering ───────────────────────────────────────────────────────

    def filtered_invoices() -> list:
        result = invoices.value
        query = search_query.value.lower().strip()
        sf = selected_filter.value

        if query:
            result = [
                inv
                for inv in result
                if query in (inv.number or "").lower() or query in (inv.customer_id or "").lower()
            ]

        if sf and sf != "ALL":
            result = [inv for inv in result if getattr(inv, "status", "NEW") == sf]

        return result

    # ── Build ───────────────────────────────────────────────────────────

    if loading.value and not invoices.value:
        return ft.Container(
            content=ft.Column(
                [
                    ft.Container(height=40, bgcolor=ft.colors.GREY_800, border_radius=8),
                    ft.Container(height=12),
                    ft.Container(height=60, bgcolor=ft.colors.GREY_800, border_radius=8),
                    ft.Container(height=8),
                    ft.Container(height=60, bgcolor=ft.colors.GREY_800, border_radius=8),
                    ft.Container(height=8),
                    ft.Container(height=60, bgcolor=ft.colors.GREY_800, border_radius=8),
                ]
            ),
            padding=20,
            expand=True,
        )

    if error.value:
        return ft.Container(
            content=ft.Column(
                [
                    ft.Icon(ft.icons.ERROR_OUTLINE, size=64, color=ft.colors.RED_400),
                    ft.Container(height=12),
                    ft.Text(f"Błąd: {error.value}", color=ft.colors.RED_400),
                    ft.ElevatedButton("Odśwież", on_click=lambda _: page.run_task(load_data())),
                ],
                alignment=ft.MainAxisAlignment.CENTER,
            ),
            expand=True,
        )

    filtered = filtered_invoices()

    rows = []
    for inv in filtered:
        status = getattr(inv, "status", "NEW")
        status_color = INVOICE_STATUS_COLORS.get(status, ft.colors.GREY)

        rows.append(
            ft.DataRow(
                cells=[
                    ft.DataCell(ft.Text(inv.number or "W trakcie...")),
                    ft.DataCell(ft.Text(inv.customer_id or "-")),
                    ft.DataCell(ft.Text(f"{inv.amount_gross:.2f} {inv.currency}")),
                    ft.DataCell(ft.Text(status, color=status_color, weight=ft.FontWeight.BOLD)),
                    ft.DataCell(
                        ft.Text(
                            inv.created_at.format("YYYY-MM-DD HH:mm")
                            if hasattr(inv.created_at, "format")
                            else str(inv.created_at)
                        )
                    ),
                ],
            )
        )

    return ft.Container(
        content=ft.Column(
            [
                ft.Row(
                    [
                        ft.Text("Lista Faktur", style=ft.TextThemeStyle.HEADLINE_MEDIUM),
                        ft.Container(expand=True),
                        ft.NumberBadge(
                            text=str(len(invoices.value)), size=16, bgcolor=ft.colors.BLUE_400
                        )
                        if invoices.value
                        else ft.Container(),
                        ft.Container(width=8),
                        ft.ElevatedButton("Odśwież", on_click=lambda _: page.run_task(load_data())),
                    ]
                ),
                ft.Container(height=8),
                ft.SearchBar(
                    ref=search_ref,
                    bar_hint_text="Szukaj faktury po numerze lub NIP...",
                    view_hint_text="Wybierz fakturę...",
                    value=search_query.value,
                    on_change=lambda e: search_query.set(e.control.value or ""),
                    on_submit=lambda e: _on_search_submit(e.control.value or ""),
                    height=44,
                ),
                ft.Container(height=8),
                filter_segments,
                ft.Container(height=4),
                ft.Text(f"Znaleziono: {len(filtered)} faktur", size=12, color=ft.colors.GREY_500),
                ft.Divider(),
                ft.Container(
                    content=ft.DataTable(
                        columns=[
                            ft.DataColumn(ft.Text("Numer")),
                            ft.DataColumn(ft.Text("NIP")),
                            ft.DataColumn(ft.Text("Kwota")),
                            ft.DataColumn(ft.Text("Status")),
                            ft.DataColumn(ft.Text("Data")),
                        ],
                        rows=rows,
                    ),
                    expand=True,
                    scroll=ft.ScrollMode.ADAPTIVE,
                ),
            ],
            scroll=ft.ScrollMode.ALWAYS,
            expand=True,
        ),
        padding=20,
        expand=True,
    )
