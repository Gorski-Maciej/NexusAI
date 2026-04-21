# frontend/views/dashboard.py (Fragment)
import flet as ft

def create_cashflow_chart(forecast_data):
    # Przekształcamy dane z Pandas/API na format punktów Flet
    data_points = [
        ft.LineChartDataPoint(x=i, y=row['projected_balance'])
        for i, row in enumerate(forecast_data)
    ]

    chart = ft.LineChart(
        data_series=[
            ft.LineChartData(
                data_points=data_points,
                stroke_width=4,
                color=ft.colors.GREEN_400,
                curved=True, # Gładka linia
            )
        ],
        border=ft.border.all(1, ft.colors.OUTLINE),
        tooltip_bgcolor=ft.colors.SURFACE,
    )
    return chart

class StatCard(ft.Container):
    """Karta statystyk z gradientem i ikoną."""
    def __init__(self, title: str, value: str, icon: str, color_top: str):
        super().__init__()
        self.content = ft.Column([
            ft.Icon(icon, color=ft.colors.WHITE, size=30),
            ft.Text(title, color=ft.colors.WHITE70),
            ft.Text(value, color=ft.colors.WHITE, size=24, weight=ft.FontWeight.BOLD)
        ])
        self.bgcolor = color_top
        self.padding = 20
        self.border_radius = 10

# UI Controls (fragment z innego źródła)
def build_bulk_actions(select_all_high_confidence, handle_bulk_approve):
    bulk_bar = ft.Row([
        ft.ElevatedButton("Zaznacz pewne (>95%)", on_click=select_all_high_confidence),
        ft.FilledButton("Zatwierdź zaznaczone", icon=ft.icons.DONE_ALL, on_click=handle_bulk_approve),
    ])
    return bulk_bar
