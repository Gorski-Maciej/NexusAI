from __future__ import annotations

import flet as ft


def build_triage_split_screen(
    image_path: str,
    extracted_data: dict[str, object],
    highlighted_fields: set[str],
    on_confirm,
    on_reject,
) -> ft.Row:
    """Core split-screen triage view with bounding-box placeholder overlay."""
    bbox_overlay = ft.Container(
        width=180,
        height=40,
        left=120,
        top=140,
        border=ft.border.all(3, ft.colors.RED_500),
        border_radius=6,
        bgcolor=ft.colors.with_opacity(0.08, ft.colors.RED_500),
    )

    image_panel = ft.Container(
        expand=2,
        padding=12,
        content=ft.Stack([
            ft.Image(src=image_path, fit=ft.ImageFit.CONTAIN, expand=True),
            bbox_overlay,
        ]),
    )

    form_controls: list[ft.Control] = []
    for key, value in extracted_data.items():
        field_bg = ft.colors.YELLOW_100 if key in highlighted_fields else None
        form_controls.append(
            ft.TextField(
                label=key,
                value="" if value is None else str(value),
                bgcolor=field_bg,
            )
        )

    action_bar = ft.Row(
        controls=[
            ft.FilledButton("Confirm & Post Ledger", icon=ft.icons.CHECK_CIRCLE, on_click=on_confirm),
            ft.OutlinedButton("Void / Reject", icon=ft.icons.CANCEL, on_click=on_reject),
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

    return ft.Row(controls=[image_panel, ft.VerticalDivider(width=1), form_panel], expand=True)
