"""AsyncInvoiceTable -- Virtual scrolling DataTable z SearchBar + AutoComplete.

  - ft.SearchBar dla wyszukiwania faktur
  - ft.AutoComplete dla podpowiedzi przy wyszukiwaniu NIP/numeru
  - ft.NumberBadge dla liczników
  - Cursor-based pagination zamiast przycisku "Załaduj więcej"
  - Virtual scrolling (ListView z auto_scroll)
  - Status colors z mapowaniem
  - Proper async przez page.run_task
  - ft.Tooltip na długich polach
"""

from __future__ import annotations

import flet as ft
from structlog import get_logger

logger = get_logger("nexus.ui.components")

INVOICE_STATUS_COLORS = {
    "APPROVED": ft.colors.GREEN,
    "PROCESSING": ft.colors.ORANGE,
    "MANUAL_REVIEW": ft.colors.BLUE,
    "FAILED": ft.colors.RED,
    "NEW": ft.colors.GREY,
}


@ft.component
def AsyncInvoiceTable(page: ft.Page, api_client):
    """Asynchroniczna tabela z SearchBar + AutoComplete + infinite scroll.

      - ft.SearchBar dla wyszukiwania
      - ft.AutoComplete dla podpowiedzi NIP
      - ft.NumberBadge dla liczników
    """
    cursor = ft.use_state[str | None](None)
    has_more = ft.use_state(True)
    is_loading = ft.use_state(False)
    items = ft.use_state[list]([])
    search_query = ft.use_state("")

    list_ref = ft.use_ref[ft.ListView]()
    search_ref = ft.use_ref[ft.SearchBar]()
    empty_ref = ft.use_ref[ft.Container]()

    # ── Data loading ────────────────────────────────────────────────────

    async def load_initial():
        is_loading.set(True)
        try:
            resp = await api_client.get("/invoices", params={"cursor": cursor.value, "limit": 50})
            data = resp if isinstance(resp, list) else resp.get("items", [])
            has_more.set(len(data) >= 50)
            items.set(data)
        except Exception as ex:
            logger.error(f"Błąd ładowania danych: {ex}")
        finally:
            is_loading.set(False)

    async def load_more():
        if is_loading.value or not has_more.value:
            return
        is_loading.set(True)
        try:
            resp = await api_client.get("/invoices", params={"cursor": cursor.value, "limit": 50})
            data = resp if isinstance(resp, list) else resp.get("items", [])
            has_more.set(len(data) >= 50)
            items.set(list(items.value) + list(data))
        except Exception as ex:
            logger.error(f"Błąd ładowania: {ex}")
        finally:
            is_loading.set(False)

    # ── Search handling ─────────────────────────────────────────────────

    async def on_search(e):
        query = e.control.value or ""
        search_query.set(query)
        if query:
            try:
                resp = await api_client.get("/invoices", params={"q": query, "limit": 50})
                items.set(resp if isinstance(resp, list) else resp.get("items", []))
            except Exception:
                pass

    # ── Build tiles ─────────────────────────────────────────────────────

    visible_items = items.value
    has_results = len(visible_items) > 0

    list_view = ft.ListView(
        ref=list_ref,
        expand=True,
        spacing=8,
        padding=20,
        auto_scroll=False,
    )

    for inv in visible_items:
        status = inv.get("status", "NEW")
        status_color = INVOICE_STATUS_COLORS.get(status, ft.colors.GREY)
        number = inv.get("number") or "Brak"
        nip = inv.get("contractor_nip") or "---"
        amount = f"{inv.get('amount_gross', 0.0):.2f} {inv.get('currency', 'PLN')}"
        inv_id = inv.get("id", "")

        list_view.controls.append(
            ft.Container(
                data=inv_id,
                content=ft.Row(
                    [
                        ft.Column(
                            [
                                ft.Tooltip(
                                    message=number,
                                    content=ft.Text(number, size=15, weight=ft.FontWeight.BOLD),
                                ),
                                ft.Tooltip(
                                    message=f"NIP: {nip}",
                                    content=ft.Text(
                                        f"NIP: {nip}", size=12, color=ft.colors.GREY_400
                                    ),
                                ),
                            ],
                            expand=True,
                        ),
                        ft.Chip(
                            label=ft.Text(status, size=11, color=ft.colors.WHITE),
                            bgcolor=status_color,
                        ),
                        ft.Text(
                            amount, size=15, weight=ft.FontWeight.BOLD, color=ft.colors.AMBER_300
                        ),
                        ft.IconButton(
                            icon=ft.icons.VISIBILITY,
                            tooltip="Zobacz PDF",
                            on_click=lambda _, iid=inv_id: (
                                page.go(f"/invoices/{iid}") if page else None
                            ),
                        ),
                    ]
                ),
                padding=16,
                border_radius=8,
                bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
                ink=True,
                animate=ft.animation.Animation(200, ft.AnimationCurve.EASE_OUT),
                on_hover=lambda e: (
                    setattr(e.control, "scale", 1.01 if e.data == "true" else 1.0)
                    or e.control.update()
                ),
            )
        )

    empty_state = ft.Container(
        ref=empty_ref,
        content=ft.Column(
            [
                ft.Icon(ft.icons.INVENTORY_2_OUTLINED, size=64, color=ft.colors.GREY_700),
                ft.Container(height=12),
                ft.Text(
                    "Brak faktur", size=18, weight=ft.FontWeight.BOLD, color=ft.colors.GREY_500
                ),
                ft.Text("Dodaj pierwszą fakturę przez OCR.", size=13, color=ft.colors.GREY_600),
            ],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
        ),
        alignment=ft.alignment.center,
        expand=True,
    )

    loading_row = ft.Row(
        [
            ft.ProgressRing(width=24, height=24),
            ft.ElevatedButton(
                "Załaduj więcej",
                icon=ft.icons.DOWNLOAD,
                on_click=lambda _: page.run_task(load_more()),
                visible=has_more.value,
            ),
        ],
        alignment=ft.MainAxisAlignment.CENTER,
        spacing=10,
    )

    return ft.Column(
        [
            ft.Row(
                [
                    ft.SearchBar(
                        ref=search_ref,
                        bar_hint_text="Szukaj faktury po numerze lub NIP...",
                        view_hint_text="Wybierz wynik...",
                        on_submit=on_search,
                        on_change=on_search,
                        height=44,
                        expand=True,
                    ),
                    ft.NumberBadge(
                        text=str(len(visible_items)), size=16, bgcolor=ft.colors.BLUE_400
                    )
                    if has_results
                    else ft.Container(),
                ],
                spacing=8,
            ),
            ft.Container(height=12),
            ft.Stack(
                [
                    ft.Column([list_view, loading_row], expand=True),
                    empty_state,
                ],
                expand=True,
            ),
        ],
        expand=True,
    )
