"""Partner Hub View — @ft.component + ReorderableListView + SegmentedButton + SearchBar."""

from __future__ import annotations
from typing import Any
import flet as ft
import pendulum
from structlog import get_logger
from nexus_ai.frontend.components.stat_card import ShimmerCard

logger = get_logger("nexus.ui.partner")


@ft.component
def PartnerHubView(page: ft.Page, api_client, query_context: dict | None = None):
    clients = ft.use_state[list]([])
    client_invoices = ft.use_state[list]([])
    filter_mode = ft.use_state("all")
    selected_client_id = ft.use_state[str | None](None)
    loading = ft.use_state(True)
    error = ft.use_state[str | None](None)
    # SUPERMOC: URL = State — inicjalizuj search z query params
    initial_q = (query_context or {}).get("q") or ""
    search_query = ft.use_state(initial_q)

    search_ref = ft.use_ref[ft.SearchBar]()
    list_ref = ft.use_ref[ft.ReorderableListView]()

    filter_segments = ft.SegmentedButton(
        selected={"all"},
        segments=[
            ft.Segment(value="all", label=ft.Text("Wszyscy")),
            ft.Segment(value="attention", label=ft.Text("Wymagają uwagi")),
            ft.Segment(value="ok", label=ft.Text("OK")),
        ],
        on_change=lambda e: filter_mode.set(list(e.selected)[0] if e.selected else "all"),
    )

    async def load_data():
        loading.set(True)
        error.set(None)
        try:
            data = await api_client.get("/partner/clients", api_version="v2")
            clients.set(data if isinstance(data, list) else [])
        except Exception as exc:
            error.set(str(exc))
        finally:
            loading.set(False)

    async def load_client_invoices(client_id: str):
        selected_client_id.set(client_id)
        loading.set(True)
        try:
            data = await api_client.get(f"/partner/clients/{client_id}/invoices", api_version="v2")
            client_invoices.set(data if isinstance(data, list) else [])
        except Exception as exc:
            error.set(str(exc))
        finally:
            loading.set(False)

    def filtered_clients() -> list:
        raw = clients.value
        q = search_query.value.lower().strip()
        if q:
            raw = [
                c
                for c in raw
                if q in (c.get("name", "") or "").lower() or q in (c.get("nip", "") or "")
            ]
        if filter_mode.value == "attention":
            raw = [c for c in raw if c.get("status") in ("UWAGA", "PROBLEM")]
        elif filter_mode.value == "ok":
            raw = [c for c in raw if c.get("status") == "OK"]
        return raw

    if selected_client_id.value:
        client_name = next(
            (
                c.get("name", "Klient")
                for c in clients.value
                if c.get("id") == selected_client_id.value
            ),
            "Klient",
        )
        inv_items = (
            [_build_invoice_row(inv) for inv in client_invoices.value]
            if client_invoices.value
            else [
                ft.Container(
                    content=ft.Column(
                        [
                            ft.Icon(
                                ft.icons.INVENTORY_2_OUTLINED, size=48, color=ft.colors.GREY_500
                            ),
                            ft.Container(height=12),
                            ft.Text("Brak faktur", size=16, color=ft.colors.GREY_400),
                        ]
                    ),
                    alignment=ft.alignment.center,
                    padding=40,
                )
            ]
        )
        return ft.Column(
            [
                ft.Row(
                    [
                        ft.IconButton(
                            icon=ft.icons.ARROW_BACK,
                            on_click=lambda _: selected_client_id.set(None),
                        ),
                        ft.Container(width=8),
                        ft.Text(
                            f"Faktury — {client_name}",
                            size=20,
                            weight=ft.FontWeight.BOLD,
                            color=ft.colors.WHITE,
                        ),
                    ]
                ),
                ft.Container(height=16),
            ]
            + inv_items,
            scroll=ft.ScrollMode.AUTO,
            expand=True,
        )

    total = len(clients.value)
    attn = sum(1 for c in clients.value if c.get("status") in ("UWAGA", "PROBLEM"))
    ok = total - attn
    pending = sum(c.get("invoice_count", 0) for c in clients.value)
    filtered = filtered_clients()

    return ft.Column(
        [
            ft.Row(
                [
                    ft.Icon(ft.icons.BUSINESS_CENTER, size=32, color=ft.colors.BLUE_300),
                    ft.Container(width=12),
                    ft.Text(
                        "Partner Hub", size=24, weight=ft.FontWeight.BOLD, color=ft.colors.WHITE
                    ),
                    ft.Container(expand=True),
                    ft.OutlinedButton(
                        "Odśwież",
                        icon=ft.icons.REFRESH,
                        on_click=lambda _: page.run_task(load_data()),
                    ),
                ]
            ),
            ft.Container(height=12),
            ft.Row(
                spacing=12,
                controls=[
                    ft.Container(
                        content=ft.Row(
                            [
                                ft.NumberBadge(
                                    text=str(total), size=18, bgcolor=ft.colors.BLUE_400
                                ),
                                ft.Container(width=8),
                                ft.Text("Klienci", size=14, color=ft.colors.GREY_400),
                            ]
                        ),
                        padding=12,
                        border_radius=8,
                        bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
                        expand=True,
                    ),
                    ft.Container(
                        content=ft.Row(
                            [
                                ft.NumberBadge(
                                    text=str(attn),
                                    size=18,
                                    bgcolor=ft.colors.ORANGE_400
                                    if attn > 0
                                    else ft.colors.GREEN_400,
                                ),
                                ft.Container(width=8),
                                ft.Text(
                                    "Wymaga uwagi",
                                    size=14,
                                    color=ft.colors.ORANGE_400 if attn > 0 else ft.colors.GREEN_400,
                                ),
                            ]
                        ),
                        padding=12,
                        border_radius=8,
                        bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
                        expand=True,
                    ),
                    ft.Container(
                        content=ft.Row(
                            [
                                ft.NumberBadge(text=str(ok), size=18, bgcolor=ft.colors.GREEN_400),
                                ft.Container(width=8),
                                ft.Text("OK", size=14, color=ft.colors.GREEN_400),
                            ]
                        ),
                        padding=12,
                        border_radius=8,
                        bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
                        expand=True,
                    ),
                    ft.Container(
                        content=ft.Row(
                            [
                                ft.NumberBadge(
                                    text=str(pending), size=18, bgcolor=ft.colors.PURPLE_300
                                ),
                                ft.Container(width=8),
                                ft.Text("Do decyzji", size=14, color=ft.colors.PURPLE_300),
                            ]
                        ),
                        padding=12,
                        border_radius=8,
                        bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
                        expand=True,
                    ),
                ],
            ),
            ft.Container(height=12),
            ft.SearchBar(
                ref=search_ref,
                bar_hint_text="Szukaj klienta po nazwie lub NIP...",
                view_hint_text="Wybierz klienta...",
                on_change=lambda e: search_query.set(e.control.value or ""),
                height=44,
            ),
            ft.Container(height=8),
            filter_segments,
            ft.Container(height=8),
            ft.Divider(height=1, color=ft.colors.GREY_700),
            ft.Container(height=8),
            ft.Text(f"Klienci ({len(filtered)})", size=14, color=ft.colors.GREY_400),
            ft.Container(height=8),
            ft.ReorderableListView(
                ref=list_ref,
                controls=[_build_client_card(c) for c in filtered],
                on_reorder=lambda e: logger.info("Reordered"),
                expand=True,
            ),
        ],
        scroll=ft.ScrollMode.AUTO,
        expand=True,
    )


def _build_client_card(client: dict) -> ft.Container:
    status = client.get("status", "OK")
    sc = {"OK": ft.colors.GREEN_400, "UWAGA": ft.colors.ORANGE_400}.get(status, ft.colors.RED_400)
    si = {"OK": ft.icons.CHECK_CIRCLE, "UWAGA": ft.icons.WARNING_AMBER}.get(status, ft.icons.ERROR)
    name = client.get("name", "N/A")
    nip = client.get("nip", "")
    ic = client.get("invoice_count", 0)
    la = client.get("last_activity", "")
    at = pendulum.parse(la.replace("Z", "+00:00")).format("DD.MM.YYYY HH:mm") if la else ""
    return ft.Container(
        margin=ft.Margin(top=0, bottom=8, left=0, right=0),
        border_radius=10,
        bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
        ink=True,
        animate=ft.animation.Animation(200, ft.AnimationCurve.EASE_OUT),
        on_hover=lambda e: (
            setattr(e.control, "scale", 1.01 if e.data == "true" else 1.0) or e.control.update()
        ),
        content=ft.Row(
            [
                ft.Container(content=ft.Icon(si, size=28, color=sc), padding=8),
                ft.Column(
                    [
                        ft.Row(
                            [
                                ft.Text(
                                    name,
                                    size=16,
                                    weight=ft.FontWeight.SEMI_BOLD,
                                    color=ft.colors.WHITE,
                                ),
                                ft.Container(expand=True),
                                ft.Container(
                                    content=ft.Text(status, size=11, color=ft.colors.WHITE),
                                    padding=ft.Padding(top=4, bottom=4, left=10, right=10),
                                    border_radius=12,
                                    bgcolor=sc + "33",
                                ),
                            ]
                        ),
                        ft.Container(height=4),
                        ft.Row(
                            [
                                ft.Text(f"NIP: {nip}", size=12, color=ft.colors.GREY_400),
                                ft.Container(width=16),
                                ft.Icon(ft.icons.DESCRIPTION, size=14, color=ft.colors.GREY_400),
                                ft.Container(width=4),
                                ft.Text(f"{ic} do decyzji", size=12, color=ft.colors.GREY_300),
                                ft.Container(expand=True),
                                ft.Icon(ft.icons.SCHEDULE, size=14, color=ft.colors.GREY_500),
                                ft.Container(width=4),
                                ft.Text(at or "", size=12, color=ft.colors.GREY_500),
                            ]
                        ),
                    ],
                    expand=True,
                ),
                ft.Container(
                    content=ft.Icon(ft.icons.CHEVRON_RIGHT, size=20, color=ft.colors.GREY_500),
                    padding=8,
                ),
            ]
        ),
        padding=16,
    )


def _build_invoice_row(inv: dict) -> ft.Container:
    contractor = inv.get("contractor", inv.get("contractor_nip", "N/A"))
    amount = f"{float(inv.get('amount_gross', 0)):,.2f}".replace(",", " ")
    currency = inv.get("currency", "PLN")
    number = inv.get("number", "Brak")
    confidence = float(inv.get("confidence", 0))
    cc = (
        ft.colors.GREEN_400
        if confidence >= 0.85
        else (ft.colors.ORANGE_400 if confidence >= 0.5 else ft.colors.RED_400)
    )
    return ft.Container(
        margin=ft.Margin(top=0, bottom=6, left=0, right=0),
        border_radius=8,
        bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
        ink=True,
        animate=ft.animation.Animation(200, ft.AnimationCurve.EASE_OUT),
        on_hover=lambda e: (
            setattr(e.control, "scale", 1.01 if e.data == "true" else 1.0) or e.control.update()
        ),
        content=ft.Row(
            [
                ft.Column(
                    [
                        ft.Row(
                            [
                                ft.Text(
                                    contractor,
                                    size=15,
                                    weight=ft.FontWeight.SEMI_BOLD,
                                    color=ft.colors.WHITE,
                                ),
                                ft.Container(width=12),
                                ft.Text(f"#{number}", size=12, color=ft.colors.GREY_400),
                            ]
                        ),
                        ft.Container(height=4),
                        ft.Row(
                            [
                                ft.Container(
                                    content=ft.Text(
                                        inv.get("status", "PENDING_REVIEW").replace("_", " "),
                                        size=10,
                                    ),
                                    padding=ft.Padding(top=2, bottom=2, left=8, right=8),
                                    border_radius=8,
                                    bgcolor=ft.colors.YELLOW_800,
                                ),
                                ft.Container(width=12),
                                ft.Text("Pewność: ", size=11, color=ft.colors.GREY_400),
                                ft.Text(
                                    f"{confidence:.0%}",
                                    size=11,
                                    color=cc,
                                    weight=ft.FontWeight.BOLD,
                                ),
                            ]
                        ),
                    ],
                    expand=True,
                ),
                ft.Text(
                    f"{amount} {currency}",
                    size=15,
                    weight=ft.FontWeight.BOLD,
                    color=ft.colors.AMBER_300,
                ),
            ]
        ),
        padding=14,
    )
