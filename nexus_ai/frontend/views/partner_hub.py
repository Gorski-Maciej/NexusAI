"""Partner Hub View — biuro rachunkowe: lista klientów i ich faktury."""
from __future__ import annotations

from typing import Any

import flet as ft


class PartnerHubView:
    """Multi-tenant view for accounting offices to manage client invoices."""

    def __init__(self, api_client: Any) -> None:
        self.api = api_client
        self._filter_mode: str = "all"  # all | attention | ok
        self._clients: list[dict[str, Any]] = []
        self._selected_client_id: str | None = None
        self._client_invoices: list[dict[str, Any]] = []
        self._loading = True
        self._error: str | None = None
        self._container = ft.Container()
        self._filter_chips: list[ft.Chip] = []

    def build(self) -> ft.Container:
        """Build the partner hub view with loading state."""
        self._container = ft.Container(
            content=self._build_loading(),
            padding=30,
            expand=True,
        )
        return self._container

    async def load_data(self) -> None:
        """Fetch clients from api."""
        self._loading = True
        self._error = None
        self._container.content = self._build_loading()
        self._container.update()

        try:
            self._clients = await self.api.get("/partner/clients", api_version="v2")
            if not isinstance(self._clients, list):
                self._clients = []
            self._loading = False
            self._container.content = self._build_partner_view()
        except Exception as exc:
            self._loading = False
            self._error = str(exc)
            self._container.content = self._build_error()

        self._container.update()

    async def load_client_invoices(self, client_id: str) -> None:
        """Fetch invoices for a specific client."""
        self._selected_client_id = client_id
        self._loading = True
        self._container.content = self._build_loading()
        self._container.update()

        try:
            self._client_invoices = await self.api.get(
                f"/partner/clients/{client_id}/invoices", api_version="v2"
            )
            if not isinstance(self._client_invoices, list):
                self._client_invoices = []
            self._loading = False
            self._container.content = self._build_invoice_list(client_id)
        except Exception as exc:
            self._loading = False
            self._error = str(exc)
            self._container.content = self._build_error()

        self._container.update()

    def _build_loading(self) -> ft.Column:
        return ft.Column(
            alignment=ft.MainAxisAlignment.CENTER,
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            controls=[
                ft.ProgressRing(width=48, height=48, stroke_width=4),
                ft.Container(height=20),
                ft.Text("Ładowanie listy klientów...", size=16, color=ft.colors.GREY_400),
            ],
        )

    def _build_error(self) -> ft.Column:
        return ft.Column(
            alignment=ft.MainAxisAlignment.CENTER,
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            controls=[
                ft.Icon(ft.icons.ERROR_OUTLINE, size=64, color=ft.colors.RED_400),
                ft.Container(height=16),
                ft.Text("Nie udało się załadować danych", size=18, color=ft.colors.RED_400),
                ft.Container(height=8),
                ft.Text(self._error or "", size=13, color=ft.colors.GREY_500),
                ft.Container(height=24),
                ft.ElevatedButton(
                    "Spróbuj ponownie",
                    icon=ft.icons.REFRESH,
                    on_click=lambda _: self._schedule_load(),
                ),
            ],
        )

    def _build_partner_view(self) -> ft.Column:
        """Build the main partner hub layout with filters and client list."""
        filtered = self._filter_clients()

        # Filter chips
        self._filter_chips = [
            ft.Chip(
                label=ft.Text("Wszyscy", size=13),
                selected=self._filter_mode == "all",
                on_select=lambda e: self._set_filter("all"),
                bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
                selected_color=ft.colors.BLUE_400,
            ),
            ft.Chip(
                label=ft.Text("Wymagają uwagi", size=13),
                selected=self._filter_mode == "attention",
                on_select=lambda e: self._set_filter("attention"),
                bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
                selected_color=ft.colors.ORANGE_400,
            ),
            ft.Chip(
                label=ft.Text("OK", size=13),
                selected=self._filter_mode == "ok",
                on_select=lambda e: self._set_filter("ok"),
                bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
                selected_color=ft.colors.GREEN_400,
            ),
        ]

        return ft.Column([
            # Header
            ft.Row([
                ft.Icon(ft.icons.BUSINESS_CENTER, size=32, color=ft.colors.BLUE_300),
                ft.Container(width=12),
                ft.Text(
                    "Partner Hub — Biuro Rachunkowe",
                    size=24,
                    weight=ft.FontWeight.BOLD,
                    color=ft.colors.WHITE,
                ),
                ft.Container(expand=True),
                ft.OutlinedButton(
                    "Odśwież",
                    icon=ft.icons.REFRESH,
                    on_click=lambda _: self._schedule_load(),
                ),
            ]),
            ft.Container(height=16),
            # Summary bar
            self._build_summary_bar(),
            ft.Container(height=16),
            # Filters
            ft.Row(
                spacing=8,
                controls=self._filter_chips,
            ),
            ft.Container(height=16),
            ft.Divider(height=1, color=ft.colors.GREY_700),
            ft.Container(height=8),
            # Client list
            ft.Text(
                f"Klienci ({len(filtered)})",
                size=14,
                color=ft.colors.GREY_400,
            ),
            ft.Container(height=8),
        ] + [
            self._build_client_card(c) for c in filtered
        ] + [
            ft.Container(height=20),
        ], scroll=ft.ScrollMode.AUTO, expand=True)

    def _build_summary_bar(self) -> ft.Row:
        total = len(self._clients)
        attention = sum(1 for c in self._clients if c.get("status") in ("UWAGA", "PROBLEM"))
        ok_count = total - attention
        pending = sum(c.get("invoice_count", 0) for c in self._clients)

        def _stat_card(label: str, value: int, icon: str, color: str) -> ft.Container:
            return ft.Container(
                content=ft.Row([
                    ft.Icon(icon, size=20, color=color),
                    ft.Container(width=8),
                    ft.Column([
                        ft.Text(str(value), size=18, weight=ft.FontWeight.BOLD, color=ft.colors.WHITE),
                        ft.Text(label, size=11, color=ft.colors.GREY_400),
                    ]),
                ]),
                padding=12,
                border_radius=8,
                bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
                expand=True,
            )

        return ft.Row(
            spacing=12,
            controls=[
                _stat_card("Klienci", total, ft.icons.GROUPS, ft.colors.BLUE_300),
                _stat_card("Wymaga uwagi", attention, ft.icons.WARNING_AMBER, ft.colors.ORANGE_400),
                _stat_card("OK", ok_count, ft.icons.CHECK_CIRCLE, ft.colors.GREEN_400),
                _stat_card("Faktury do decyzji", pending, ft.icons.DESCRIPTION, ft.colors.PURPLE_300),
            ],
        )

    def _build_client_card(self, client: dict[str, Any]) -> ft.Container:
        status = client.get("status", "OK")
        if status == "OK":
            status_color = ft.colors.GREEN_400
            status_icon = ft.icons.CHECK_CIRCLE
        elif status == "UWAGA":
            status_color = ft.colors.ORANGE_400
            status_icon = ft.icons.WARNING_AMBER
        else:  # PROBLEM
            status_color = ft.colors.RED_400
            status_icon = ft.icons.ERROR

        name = client.get("name", "Nieznany klient")
        nip = client.get("nip", "")
        invoice_count = client.get("invoice_count", 0)
        last_activity = client.get("last_activity", "")
        client_id = client.get("id", "")

        activity_text = ""
        if last_activity:
            try:
                from datetime import datetime
                dt = pendulum.parse(last_activity.replace("Z", "+00:00"))
                activity_text = dt.format("DD.MM.YYYY HH:mm")
            except Exception:
                activity_text = last_activity[:10]

        return ft.Container(
            margin=ft.Margin(top=0, bottom=8, left=0, right=0),
            border_radius=10,
            bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
            ink=True,
            on_click=lambda e, cid=client_id: self._on_client_click(cid),
            content=ft.Row([
                ft.Container(
                    content=ft.Icon(status_icon, size=28, color=status_color),
                    padding=8,
                ),
                ft.Column([
                    ft.Row([
                        ft.Text(name, size=16, weight=ft.FontWeight.SEMI_BOLD, color=ft.colors.WHITE),
                        ft.Container(expand=True),
                        ft.Container(
                            content=ft.Text(status, size=11, color=ft.colors.WHITE),
                            padding=ft.Padding(top=4, bottom=4, left=10, right=10),
                            border_radius=12,
                            bgcolor=status_color + "33",
                        ),
                    ]),
                    ft.Container(height=4),
                    ft.Row([
                        ft.Text(f"NIP: {nip}", size=12, color=ft.colors.GREY_400),
                        ft.Container(width=16),
                        ft.Icon(ft.icons.DESCRIPTION, size=14, color=ft.colors.GREY_400),
                        ft.Container(width=4),
                        ft.Text(
                            f"{invoice_count} do decyzji",
                            size=12,
                            color=ft.colors.GREY_300,
                        ),
                        ft.Container(expand=True),
                        ft.Icon(ft.icons.SCHEDULE, size=14, color=ft.colors.GREY_500),
                        ft.Container(width=4),
                        ft.Text(activity_text, size=12, color=ft.colors.GREY_500),
                    ]),
                ], expand=True),
                ft.Container(
                    content=ft.Icon(ft.icons.CHEVRON_RIGHT, size=20, color=ft.colors.GREY_500),
                    padding=8,
                ),
            ]),
            padding=16,
        )

    def _build_invoice_list(self, client_id: str) -> ft.Column:
        """Build invoice list view for a selected client."""
        client_name = "Klient"
        for c in self._clients:
            if c.get("id") == client_id:
                client_name = c.get("name", "Klient")
                break

        controls: list[ft.Control] = [
            # Back button
            ft.Row([
                ft.IconButton(
                    icon=ft.icons.ARROW_BACK,
                    on_click=lambda _: self._back_to_clients(),
                ),
                ft.Container(width=8),
                ft.Text(
                    f"Faktury — {client_name}",
                    size=20,
                    weight=ft.FontWeight.BOLD,
                    color=ft.colors.WHITE,
                ),
            ]),
            ft.Container(height=16),
        ]

        if not self._client_invoices:
            controls.extend([
                ft.Container(
                    content=ft.Column([
                        ft.Icon(ft.icons.INVENTORY_2_OUTLINED, size=48, color=ft.colors.GREY_500),
                        ft.Container(height=12),
                        ft.Text(
                            "Brak faktur oczekujących na decyzję",
                            size=16,
                            color=ft.colors.GREY_400,
                        ),
                    ]),
                    alignment=ft.alignment.center,
                    padding=ft.Padding(top=40, bottom=40, left=0, right=0),
                ),
            ])
        else:
            for inv in self._client_invoices:
                controls.append(self._build_invoice_row(inv))

        return ft.Column(
            controls=controls,
            scroll=ft.ScrollMode.AUTO,
            expand=True,
        )

    def _build_invoice_row(self, inv: dict[str, Any]) -> ft.Container:
        contractor = inv.get("contractor", inv.get("contractor_nip", "Nieznany"))
        amount = f"{float(inv.get('amount_gross', 0)):,.2f}".replace(",", " ")
        currency = inv.get("currency", "PLN")
        number = inv.get("number", "Brak")
        confidence = float(inv.get("confidence", 0))
        status = inv.get("status", "PENDING_REVIEW")

        confidence_color = ft.colors.GREEN_400 if confidence >= 0.85 else (
            ft.colors.ORANGE_400 if confidence >= 0.5 else ft.colors.RED_400
        )

        return ft.Container(
            margin=ft.Margin(top=0, bottom=6, left=0, right=0),
            border_radius=8,
            bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
            ink=True,
            content=ft.Row([
                ft.Column([
                    ft.Row([
                        ft.Text(contractor, size=15, weight=ft.FontWeight.SEMI_BOLD, color=ft.colors.WHITE),
                        ft.Container(width=12),
                        ft.Text(f"#{number}", size=12, color=ft.colors.GREY_400),
                    ]),
                    ft.Container(height=4),
                    ft.Row([
                        ft.Container(
                            content=ft.Text(status.replace("_", " "), size=10),
                            padding=ft.Padding(top=2, bottom=2, left=8, right=8),
                            border_radius=8,
                            bgcolor=ft.colors.YELLOW_800,
                        ),
                        ft.Container(width=12),
                        ft.Text("Pewność: ", size=11, color=ft.colors.GREY_400),
                        ft.Text(
                            f"{confidence:.0%}",
                            size=11,
                            color=confidence_color,
                            weight=ft.FontWeight.BOLD,
                        ),
                    ]),
                ], expand=True),
                ft.Text(
                    f"{amount} {currency}",
                    size=15,
                    weight=ft.FontWeight.BOLD,
                    color=ft.colors.AMBER_300,
                ),
            ]),
            padding=14,
        )

    def _filter_clients(self) -> list[dict[str, Any]]:
        if self._filter_mode == "attention":
            return [c for c in self._clients if c.get("status") in ("UWAGA", "PROBLEM")]
        if self._filter_mode == "ok":
            return [c for c in self._clients if c.get("status") == "OK"]
        return self._clients

    def _set_filter(self, mode: str) -> None:
        self._filter_mode = mode
        self._container.content = self._build_partner_view()
        self._container.update()
        # Update chip selections
        for chip in self._filter_chips:
            chip.selected = (
                (mode == "all" and chip.label.value == "Wszyscy")
                or (mode == "attention" and chip.label.value == "Wymagają uwagi")
                or (mode == "ok" and chip.label.value == "OK")
            )
        self._container.update()

    def _on_client_click(self, client_id: str) -> None:
        """Navigate to client invoice list."""
        if self._container.page:
            self._container.page.run_task(self.load_client_invoices, client_id)

    def _back_to_clients(self) -> None:
        """Return to client list view."""
        self._selected_client_id = None
        self._client_invoices = []
        self._container.content = self._build_partner_view()
        self._container.update()

    def _schedule_load(self) -> None:
        if self._container.page:
            self._container.page.run_task(self.load_data)
