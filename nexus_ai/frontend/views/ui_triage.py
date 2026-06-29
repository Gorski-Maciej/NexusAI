"""Triage View — @ft.component + Canvas bbox + Keyboard shortcuts.

  - @ft.component + use_state() zamiast statycznej funkcji
  - ft.Canvas z CanvasPath dla rysowania bounding boxów
  - ft.KeyboardEvent dla skrótów (Enter=Confirm, Esc=Reject)
  - ft.AnimatedContainer dla płynnych przejść
  - ft.Ref<T> typowane referencje
  - page.run_task dla async confirm/reject
  - Współdzielone komponenty z components/stat_card.py
"""

from __future__ import annotations

from typing import Any, Callable
from collections.abc import Callable

import flet as ft
from structlog import get_logger

logger = get_logger("nexus.ui.triage")


@ft.component
def TriageSplitScreen(
    page: ft.Page,
    image_path: str,
    extracted_data: dict[str, Any],
    highlighted_fields: set[str] | None = None,
    bboxes: list[dict[str, float]] | None = None,
    on_confirm: Callable | None = None,
    on_reject: Callable | None = None,
):
    """Core split-screen triage view with Canvas bounding-box overlay.

      - @ft.component + use_state() zamiast funkcji
      - ft.Canvas z CanvasPath dla bbox
      - ft.KeyboardEvent dla Enter/Escape
      - ft.AnimatedContainer dla płynnych przejść
    """
    highlight = ft.use_state(highlighted_fields or set())
    form_data = ft.use_state(extracted_data)

    canvas_ref = ft.use_ref[ft.Canvas]()

    # ── Canvas drawing ─────────────────────────────────────────────────

    def draw_bboxes(e: ft.CanvasDrawEvent):
        """Draw bounding boxes on the invoice image using CanvasPath.

          - ft.Canvas.draw_path z CanvasPath
          - ft.Paint dla kolorów i stylów
        """
        canvas = e.canvas
        bbox_list = bboxes or []

        for bbox in bbox_list:
            x = bbox.get("x", 0)
            y = bbox.get("y", 0)
            w = bbox.get("w", 100)
            h = bbox.get("h", 30)
            field_name = bbox.get("field", "")

            # Kolor zależny od pewności
            is_low_confidence = field_name in highlight.value
            color = ft.colors.RED_500 if is_low_confidence else ft.colors.GREEN_500
            alpha = 0.4 if is_low_confidence else 0.2

            canvas.draw_path(
                ft.CanvasPath().create_rect(x, y, w, h),
                paint=ft.Paint(
                    color=color,
                    stroke_width=3,
                    style=ft.PaintingStyle.STROKE,
                ),
            )
            # Semi-transparent fill
            canvas.draw_path(
                ft.CanvasPath().create_rect(x, y, w, h),
                paint=ft.Paint(
                    color=ft.colors.with_opacity(alpha, color),
                    style=ft.PaintingStyle.FILL,
                ),
            )

    # ── Handlery ────────────────────────────────────────────────────────

    async def handle_confirm(e=None):
        """Handle confirm action."""
        if on_confirm:
            await on_confirm(page)
        page.show_snack_bar(
            ft.SnackBar(ft.Text("✅ Dokument zatwierdzony"), bgcolor=ft.colors.GREEN_700)
        )

    async def handle_reject(e=None):
        """Handle reject action."""
        if on_reject:
            await on_reject(page)
        page.show_snack_bar(
            ft.SnackBar(ft.Text("❌ Dokument odrzucony"), bgcolor=ft.colors.RED_700)
        )

    async def on_keyboard(e: ft.KeyboardEvent):
        if e.key == "Enter" and not e.ctrl:
            await handle_confirm()
        elif e.key == "Escape":
            await handle_reject()

    page.on_keyboard_event = on_keyboard

    # ── Build ───────────────────────────────────────────────────────────

    image_panel = ft.Container(
        expand=2,
        padding=12,
        content=ft.Stack(
            [
                ft.Image(src=image_path, fit=ft.ImageFit.CONTAIN, expand=True),
                ft.Canvas(
                    ref=canvas_ref,
                    on_draw=draw_bboxes,
                    expand=True,
                ),
            ]
        ),
    )

    # Form fields z kolorowaniem pól o niskiej pewności
    form_controls = []
    for key, value in form_data.value.items():
        is_highlighted = key in highlight.value
        form_controls.append(
            ft.TextField(
                label=key,
                value="" if value is None else str(value),
                bgcolor=ft.colors.YELLOW_900 if is_highlighted else None,
                border_color=ft.colors.ORANGE_400 if is_highlighted else None,
                suffix=ft.Tooltip(
                    message="Niska pewność OCR" if is_highlighted else "Pole zweryfikowane",
                    content=ft.Icon(
                        ft.icons.WARNING_AMBER if is_highlighted else ft.icons.CHECK_CIRCLE,
                        size=16,
                        color=ft.colors.ORANGE_400 if is_highlighted else ft.colors.GREEN_400,
                    ),
                ),
            )
        )

    action_bar = ft.Row(
        [
            ft.FilledButton(
                "Confirm & Post Ledger",
                icon=ft.icons.CHECK_CIRCLE,
                on_click=handle_confirm,
                style=ft.ButtonStyle(bgcolor=ft.colors.GREEN_700),
            ),
            ft.OutlinedButton(
                "Void / Reject",
                icon=ft.icons.CANCEL,
                on_click=handle_reject,
                style=ft.ButtonStyle(color=ft.colors.RED_400),
            ),
        ],
        spacing=12,
    )

    form_panel = ft.Container(
        expand=3,
        padding=12,
        content=ft.Column(
            [
                ft.Text("Review Queue / Triage", size=22, weight=ft.FontWeight.BOLD),
                ft.Text(
                    "AI flagged this document for review. Verify highlighted fields.",
                    size=13,
                    color=ft.colors.GREY_400,
                ),
                ft.Container(height=8),
                *form_controls,
                ft.Container(height=12),
                action_bar,
                ft.Container(height=8),
                ft.Text("💡 Enter = Confirm | Esc = Reject", size=11, color=ft.colors.GREY_500),
            ],
            scroll=ft.ScrollMode.AUTO,
        ),
    )

    return ft.Row(
        controls=[image_panel, ft.VerticalDivider(width=1), form_panel],
        expand=True,
    )
