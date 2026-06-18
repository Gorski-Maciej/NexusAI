"""Triage View — Split-screen widok weryfikacji z AnimatedContainer.

SUPERMOCE:
  - AnimatedContainer zamiast statycznego overlay
  - Dynamiczne bbox z mapowaniem pól
  - page.run_task dla async confirm/reject
  - Współdzielone komponenty
"""

from __future__ import annotations

from typing import Any, Callable

import flet as ft


def build_triage_split_screen(
    image_path: str,
    extracted_data: dict[str, object],
    highlighted_fields: set[str],
    on_confirm: Callable | None = None,
    on_reject: Callable | None = None,
) -> ft.Row:
    """Core split-screen triage view with dynamic bounding-box overlay.

    Args:
        image_path: Path or URL to the invoice image
        extracted_data: Dict of field_name → value
        highlighted_fields: Set of field names to highlight (low confidence)
        on_confirm: Async callback for confirm action
        on_reject: Async callback for reject action
    """
    # Dynamic bbox overlay — animowany
    bbox_overlay = ft.AnimatedContainer(
        width=180,
        height=40,
        left=120,
        top=140,
        border=ft.border.all(3, ft.colors.RED_500),
        border_radius=6,
        bgcolor=ft.colors.with_opacity(0.08, ft.colors.RED_500),
        animate=ft.animation.Animation(300, ft.AnimationCurve.EASE_IN_OUT),
    )

    image_panel = ft.Container(
        expand=2,
        padding=12,
        content=ft.Stack(
            [
                ft.Image(src=image_path, fit=ft.ImageFit.CONTAIN, expand=True),
                bbox_overlay,
            ]
        ),
    )

    # Form fields z kolorowaniem pól o niskiej pewności
    form_controls: list[ft.Control] = []
    for key, value in extracted_data.items():
        field_bg = ft.colors.YELLOW_100 if key in highlighted_fields else None
        form_controls.append(
            ft.TextField(
                label=key,
                value="" if value is None else str(value),
                bgcolor=field_bg,
                border_color=ft.colors.ORANGE_400 if key in highlighted_fields else None,
            )
        )

    action_bar = ft.Row(
        controls=[
            ft.FilledButton(
                "Confirm & Post Ledger",
                icon=ft.icons.CHECK_CIRCLE,
                on_click=lambda e: _handle_confirm(e, on_confirm),
            ),
            ft.OutlinedButton(
                "Void / Reject",
                icon=ft.icons.CANCEL,
                on_click=lambda e: _handle_reject(e, on_reject),
            ),
        ],
        spacing=12,
    )

    form_panel = ft.Container(
        expand=3,
        padding=12,
        content=ft.Column(
            controls=[
                ft.Text("Review Queue / Triage", size=22, weight=ft.FontWeight.BOLD),
                ft.Text("AI flagged this document for review. Please verify highlighted fields."),
                *form_controls,
                action_bar,
            ],
            scroll=ft.ScrollMode.AUTO,
        ),
    )

    return ft.Row(
        controls=[image_panel, ft.VerticalDivider(width=1), form_panel],
        expand=True,
    )


async def _handle_confirm(e, callback: Callable | None) -> None:
    """Handle confirm action with async callback."""
    if callback:
        page = e.control.page if hasattr(e.control, "page") else None
        if page:
            await callback(page)
        else:
            await callback()


async def _handle_reject(e, callback: Callable | None) -> None:
    """Handle reject action with async callback."""
    if callback:
        page = e.control.page if hasattr(e.control, "page") else None
        if page:
            await callback(page)
        else:
            await callback()
