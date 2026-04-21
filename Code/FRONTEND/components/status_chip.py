# frontend/components/status_chip.py
import flet as ft

def StatusChip(status: str):
    colors = {
        "NEW": ft.colors.BLUE,
        "PROCESSING": ft.colors.ORANGE,
        "APPROVED": ft.colors.GREEN,
        "MANUAL_REVIEW": ft.colors.RED,
    }

    return ft.Chip(
        label=ft.Text(status, color=ft.colors.WHITE),
        bgcolor=colors.get(status, ft.colors.GREY),
    )
