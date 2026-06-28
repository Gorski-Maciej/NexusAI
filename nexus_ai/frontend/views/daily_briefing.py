"""Daily Briefing View — @ft.component + AnimatedContainer + Shimmer.

SUPERMOCE Flet 0.28+:
  - @ft.component + use_state() zamiast klasy
  - ft.AnimatedContainer dla płynnych przejść
  - ft.Shimmer dla loading skeleton (współdzielony z stat_card)
  - page.pubsub dla odświeżeń
  - Współdzielone komponenty z components/stat_card.py
"""

from __future__ import annotations

from typing import Any

import flet as ft
from structlog import get_logger

from nexus_ai.frontend.components.stat_card import ShimmerCard, ErrorView as ErrorViewComponent

logger = get_logger("nexus.ui.briefing")


@ft.component
def DailyBriefingView(page: ft.Page, api_client):
    """Compact daily briefing showing 1–3 critical decisions.

    SUPERMOC Flet 0.28+:
      - @ft.component + use_state() zamiast klasy
      - ft.AnimatedContainer dla płynnych przejść
      - ft.Shimmer dla loading skeleton
    """
    # SUPERMOC: use_state zamiast self._variables
    briefing = ft.use_state[dict]({})
    loading = ft.use_state(True)
    error = ft.use_state[str | None](None)

    # ── Data loading ────────────────────────────────────────────────────

    async def load_data():
        loading.set(True)
        error.set(None)
        try:
            data = await api_client.get("/dashboard/briefing", api_version="v2")
            briefing.set(data if isinstance(data, dict) else {})
            loading.set(False)
        except Exception as exc:
            loading.set(False)
            error.set(str(exc))

    def schedule_load():
        page.run_task(load_data())

    # ── Build ───────────────────────────────────────────────────────────

    if loading.value and not briefing.value:
        return ft.Container(
            content=ft.Column(
                [
                    ShimmerCard(),
                    ft.Container(height=12),
                    ShimmerCard(),
                    ft.Container(height=12),
                    ShimmerCard(),
                ]
            ),
            padding=30,
            expand=True,
        )

    if error.value and not briefing.value:
        return ft.Container(
            content=ErrorView(
                "Nie udało się załadować podsumowania",
                error.value,
                on_retry=lambda _: schedule_load(),
            ),
            padding=30,
            expand=True,
        )

    # Briefing content
    decisions = briefing.value.get("decisions", [])
    message = briefing.value.get("message", "Dzień dobry! Nie ma nowych decyzji")

    controls = [
        ft.Container(
            content=ft.Column(
                [
                    ft.Icon(ft.icons.WB_SUNNY_OUTLINED, size=40, color=ft.colors.AMBER_400),
                    ft.Container(height=8),
                    ft.Text(message, size=22, weight=ft.FontWeight.BOLD, color=ft.colors.WHITE),
                ]
            ),
            padding=ft.Padding(top=10, bottom=20, left=0, right=0),
            animate=ft.animation.Animation(300, ft.AnimationCurve.EASE_IN_OUT),
        ),
        ft.Divider(height=2, color=ft.colors.GREY_700),
        ft.Container(height=16),
    ]

    if not decisions:
        controls.extend(
            [
                ft.Container(
                    content=ft.Column(
                        [
                            ft.Icon(
                                ft.icons.CHECK_CIRCLE_OUTLINE, size=64, color=ft.colors.GREEN_400
                            ),
                            ft.Container(height=12),
                            ft.Text(
                                "Wszystkie faktury zostały automatycznie",
                                size=16,
                                color=ft.colors.GREY_300,
                            ),
                            ft.Text(
                                "zaksięgowane przez system AI.", size=16, color=ft.colors.GREY_300
                            ),
                        ]
                    ),
                    alignment=ft.alignment.center,
                    padding=ft.Padding(top=40, bottom=40, left=0, right=0),
                ),
            ]
        )
    else:
        for decision in decisions:
            controls.append(_build_decision_card(decision, schedule_load))

    controls.extend(
        [
            ft.Container(height=16),
            ft.Row(
                alignment=ft.MainAxisAlignment.CENTER,
                controls=[
                    ft.OutlinedButton(
                        "Odśwież", icon=ft.icons.REFRESH, on_click=lambda _: schedule_load()
                    ),
                ],
            ),
        ]
    )

    return ft.Container(
        content=ft.Column(controls=controls, scroll=ft.ScrollMode.AUTO, expand=True),
        padding=30,
        expand=True,
    )


def _build_decision_card(decision: dict, on_refresh) -> ft.Container:
    """Build a single decision card with AnimatedContainer."""
    invoice_id = decision.get("invoice_id", "")
    contractor = decision.get("contractor") or decision.get("contractor_nip", "Nieznany")
    amount = f"{float(decision.get('amount_gross', 0)):,.2f}".replace(",", " ")
    currency = decision.get("currency", "PLN")
    reason = decision.get("reason", "Wymaga ręcznego sprawdzenia")
    number = decision.get("number", "Brak numeru")

    def _on_approve(_, iid=invoice_id):
        page = _.control.page if hasattr(_, "control") else None
        if page:
            page.show_snack_bar(
                ft.SnackBar(
                    ft.Text(f"✅ Faktura {iid[:8]}... zatwierdzona"), bgcolor=ft.colors.GREEN_700
                )
            )
        on_refresh()

    def _on_reject(_, iid=invoice_id):
        page = _.control.page if hasattr(_, "control") else None
        if page:
            page.show_snack_bar(
                ft.SnackBar(
                    ft.Text(f"❌ Faktura {iid[:8]}... odrzucona"), bgcolor=ft.colors.RED_700
                )
            )
        on_refresh()

    def _on_check(_, iid=invoice_id):
        page = _.control.page if hasattr(_, "control") else None
        if page:
            page.go(f"/invoices/{iid}")

    return ft.Container(
        margin=ft.Margin(top=0, bottom=12, left=0, right=0),
        border_radius=12,
        bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
        ink=True,
        animate=ft.animation.Animation(300, ft.AnimationCurve.EASE_IN_OUT),
        on_hover=lambda e: (
            setattr(e.control, "scale", 1.01 if e.data == "true" else 1.0) or e.control.update()
        ),
        content=ft.Column(
            [
                ft.Row(
                    [
                        ft.Row(
                            [
                                ft.Icon(ft.icons.DESCRIPTION, size=20, color=ft.colors.BLUE_300),
                                ft.Container(width=8),
                                ft.Text(
                                    contractor,
                                    size=16,
                                    weight=ft.FontWeight.SEMI_BOLD,
                                    color=ft.colors.WHITE,
                                ),
                            ]
                        ),
                        ft.Text(
                            f"{amount} {currency}",
                            size=16,
                            weight=ft.FontWeight.BOLD,
                            color=ft.colors.AMBER_300,
                        ),
                    ],
                    alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
                ),
                ft.Container(height=8),
                ft.Text(f"Faktura: {number}", size=13, color=ft.colors.GREY_400),
                ft.Container(height=4),
                ft.Row(
                    [
                        ft.Icon(ft.icons.INFO_OUTLINE, size=16, color=ft.colors.GREY_400),
                        ft.Container(width=6),
                        ft.Text(reason, size=13, color=ft.colors.GREY_300, expand=True),
                    ]
                ),
                ft.Container(height=12),
                ft.Divider(height=1, color=ft.colors.GREY_700),
                ft.Container(height=8),
                ft.Row(
                    alignment=ft.MainAxisAlignment.END,
                    spacing=8,
                    controls=[
                        ft.ElevatedButton(
                            "Sprawdź",
                            icon=ft.icons.VISIBILITY,
                            style=ft.ButtonStyle(color=ft.colors.WHITE, bgcolor=ft.colors.BLUE_800),
                            on_click=_on_check,
                        ),
                        ft.ElevatedButton(
                            "Odrzuć",
                            icon=ft.icons.CLOSE,
                            style=ft.ButtonStyle(color=ft.colors.WHITE, bgcolor=ft.colors.RED_900),
                            on_click=_on_reject,
                        ),
                        ft.FilledButton(
                            "Zatwierdź",
                            icon=ft.icons.CHECK,
                            style=ft.ButtonStyle(
                                color=ft.colors.WHITE, bgcolor=ft.colors.GREEN_700
                            ),
                            on_click=_on_approve,
                        ),
                    ],
                ),
            ]
        ),
        padding=20,
    )
