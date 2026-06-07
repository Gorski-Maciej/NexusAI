# ui/components/status_bar.py
import flet as ft


class NexusStatusBar(ft.Container):
    """Pasek dolny monitorujący stan backendu w czasie rzeczywistym."""

    def __init__(self):
        super().__init__()
        self.height = 30
        self.bgcolor = "#0D0D12"
        self.padding = ft.padding.symmetric(horizontal=15)
        self.border = ft.border.only(top=ft.BorderSide(1, ft.colors.GREY_900))

        # Wskaźniki
        self.db_led = ft.Container(width=8, height=8, border_radius=4, bgcolor=ft.colors.GREY_700)
        self.nats_led = ft.Container(width=8, height=8, border_radius=4, bgcolor=ft.colors.GREY_700)
        self.status_msg = ft.Text("Inicjalizacja systemu...", size=11, color=ft.colors.GREY_500)

        self.content = ft.Row([
            ft.Row([
                ft.Text("SQLITE", size=10, weight=ft.FontWeight.BOLD), self.db_led,
                ft.VerticalDivider(width=10),
                ft.Text("NATS/AI", size=10, weight=ft.FontWeight.BOLD), self.nats_led,
            ])
        ])

    def update_status(self, db_ok: bool, nats_ok: bool, message: str):
        self.db_led.bgcolor = ft.colors.GREEN if db_ok else ft.colors.RED
        self.nats_led.bgcolor = ft.colors.GREEN if nats_ok else ft.colors.RED
        self.status_msg.value = message
        self.update()
