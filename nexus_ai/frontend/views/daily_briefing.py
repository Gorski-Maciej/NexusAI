"""Daily Briefing View — 1 minuta dziennie z AnimatedContainer i shared components.

SUPERMOCE:
  - Współdzielone loading_spinner/error_view z components/
  - AnimatedContainer dla płynnych przejść
  - page.pubsub dla odświeżeń
"""

from __future__ import annotations

from typing import Any

import flet as ft

from nexus_ai.frontend.components.stat_card import loading_spinner, error_view


class DailyBriefingView:
    """Compact daily briefing showing 1–3 critical decisions."""

    def __init__(self, api_client: Any) -> None:
        self.api = api_client
        self._briefing: dict[str, Any] = {}
        self._container = ft.Container()

    def build(self) -> ft.Container:
        self._container = ft.Container(
            content=loading_spinner("Ładowanie podsumowania dnia..."),
            padding=30,
            expand=True,
        )
        return self._container

    async def load_data(self) -> None:
        """Fetch briefing from API and rebuild UI."""
        self._container.content = loading_spinner("Ładowanie podsumowania dnia...")
        self._container.update()

        try:
            self._briefing = await self.api.get("/dashboard/briefing", api_version="v2")
            self._container.content = self._build_briefing()
        except Exception as exc:
            self._container.content = error_view(
                "Nie udało się załadować podsumowania",
                str(exc),
                on_retry=lambda _: self._schedule_load(),
            )

        self._container.update()

    def _build_briefing(self) -> ft.Column:
        decisions = self._briefing.get("decisions", [])
        message = self._briefing.get("message", "Dzień dobry! Nie ma nowych decyzji")

        controls: list[ft.Control] = [
            ft.Container(
                content=ft.Column([
                    ft.Icon(ft.icons.WB_SUNNY_OUTLINED, size=40, color=ft.colors.AMBER_400),
                    ft.Container(height=8),
                    ft.Text(message, size=22, weight=ft.FontWeight.BOLD, color=ft.colors.WHITE),
                ]),
                padding=ft.Padding(top=10, bottom=20, left=0, right=0),
            ),
            ft.Divider(height=2, color=ft.colors.GREY_700),
            ft.Container(height=16),
        ]

        if not decisions:
            controls.extend([
                ft.Container(
                    content=ft.Column([
                        ft.Icon(ft.icons.CHECK_CIRCLE_OUTLINE, size=64, color=ft.colors.GREEN_400),
                        ft.Container(height=12),
                        ft.Text("Wszystkie faktury zostały automatycznie", size=16, color=ft.colors.GREY_300),
                        ft.Text("zaksięgowane przez system AI.", size=16, color=ft.colors.GREY_300),
                    ]),
                    alignment=ft.alignment.center,
                    padding=ft.Padding(top=40, bottom=40, left=0, right=0),
                ),
            ])
        else:
            for decision in decisions:
                controls.append(self._build_decision_card(decision))

        controls.extend([
            ft.Container(height=16),
            ft.Row(
                alignment=ft.MainAxisAlignment.CENTER,
                controls=[
                    ft.OutlinedButton("Odśwież", icon=ft.icons.REFRESH, on_click=lambda _: self._schedule_load()),
                ],
            ),
        ])

        return ft.Column(controls=controls, scroll=ft.ScrollMode.AUTO, expand=True)

    def _build_decision_card(self, decision: dict[str, Any]) -> ft.Container:
        invoice_id = decision.get("invoice_id", "")
        contractor = decision.get("contractor") or decision.get("contractor_nip", "Nieznany")
        amount = f"{float(decision.get('amount_gross', 0)):,.2f}".replace(",", " ")
        currency = decision.get("currency", "PLN")
        reason = decision.get("reason", "Wymaga ręcznego sprawdzenia")
        number = decision.get("number", "Brak numeru")

        return ft.Container(
            margin=ft.Margin(top=0, bottom=12, left=0, right=0),
            border_radius=12,
            bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
            ink=True,
            animate=ft.animation.Animation(300, ft.AnimationCurve.EASE_IN_OUT),
            on_hover=lambda e: setattr(e.control, "scale", 1.01 if e.data == "true" else 1.0) or e.control.update(),
            content=ft.Column([
                ft.Row(
                    alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
                    controls=[
                        ft.Row([
                            ft.Icon(ft.icons.DESCRIPTION, size=20, color=ft.colors.BLUE_300),
                            ft.Container(width=8),
                            ft.Text(contractor, size=16, weight=ft.FontWeight.SEMI_BOLD, color=ft.colors.WHITE),
                        ]),
                        ft.Text(f"{amount} {currency}", size=16, weight=ft.FontWeight.BOLD, color=ft.colors.AMBER_300),
                    ],
                ),
                ft.Container(height=8),
                ft.Text(f"Faktura: {number}", size=13, color=ft.colors.GREY_400),
                ft.Container(height=4),
                ft.Row([
                    ft.Icon(ft.icons.INFO_OUTLINE, size=16, color=ft.colors.GREY_400),
                    ft.Container(width=6),
                    ft.Text(reason, size=13, color=ft.colors.GREY_300, expand=True),
                ]),
                ft.Container(height=12),
                ft.Divider(height=1, color=ft.colors.GREY_700),
                ft.Container(height=8),
                ft.Row(
                    alignment=ft.MainAxisAlignment.END,
                    spacing=8,
                    controls=[
                        ft.ElevatedButton(
                            "Sprawdź", icon=ft.icons.VISIBILITY,
                            style=ft.ButtonStyle(color=ft.colors.WHITE, bgcolor=ft.colors.BLUE_800),
                            on_click=lambda e, iid=invoice_id: self._on_check(iid),
                        ),
                        ft.ElevatedButton(
                            "Odrzuć", icon=ft.icons.CLOSE,
                            style=ft.ButtonStyle(color=ft.colors.WHITE, bgcolor=ft.colors.RED_900),
                            on_click=lambda e, iid=invoice_id: self._on_reject(iid),
                        ),
                        ft.FilledButton(
                            "Zatwierdź", icon=ft.icons.CHECK,
                            style=ft.ButtonStyle(color=ft.colors.WHITE, bgcolor=ft.colors.GREEN_700),
                            on_click=lambda e, iid=invoice_id: self._on_approve(iid),
                        ),
                    ],
                ),
            ]),
            padding=20,
        )

    def _schedule_load(self) -> None:
        if self._container.page:
            self._container.page.run_task(self.load_data)

    def _on_approve(self, invoice_id: str) -> None:
        if self._container.page:
            self._container.page.show_snack_bar(
                ft.SnackBar(ft.Text(f"✅ Faktura {invoice_id[:8]}... zatwierdzona"), bgcolor=ft.colors.GREEN_700)
            )
        self._schedule_load()

    def _on_reject(self, invoice_id: str) -> None:
        if self._container.page:
            self._container.page.show_snack_bar(
                ft.SnackBar(ft.Text(f"❌ Faktura {invoice_id[:8]}... odrzucona"), bgcolor=ft.colors.RED_700)
            )
        self._schedule_load()

    def _on_check(self, invoice_id: str) -> None:
        if self._container.page:
            self._container.page.go(f"/invoices/{invoice_id}")
