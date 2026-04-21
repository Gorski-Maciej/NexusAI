# frontend/router.py
import flet as ft
from frontend.views.dashboard_view import DashboardView
from frontend.views.invoice_list_view import InvoiceListView

class NexusRouter:
    def __init__(self, page: ft.Page, api_client):
        self.page = page
        self.api = api_client
        self.routes = {
            "/": DashboardView(api_client),
            "/invoices": InvoiceListView(api_client),
        }

    def handle_route_change(self, route_event):
        self.page.views.clear()

        # Wybieramy widok na podstawie ścieżki
        view_handler = self.routes.get(self.page.route, self.routes["/"])

        self.page.views.append(
            ft.View(
                route=self.page.route,
                controls=[
                    self._build_app_bar(),
                    view_handler.build(), # Każdy widok ma metodę build()
                ],
                drawer=self._build_drawer()
            )
        )
        self.page.update()

    def _build_app_bar(self):
        return ft.AppBar(title=ft.Text("Nexus AI"))

    def _build_drawer(self):
        return ft.NavigationDrawer(
            controls=[
                ft.NavigationDrawerDestination(label="Dashboard", icon=ft.icons.DASHBOARD),
                ft.NavigationDrawerDestination(label="Faktury", icon=ft.icons.DOCUMENT_SCAN),
            ]
        )

    def _view_pop(self, view_event: ft.ViewPopEvent):
        """Obsługa przycisku Wstecz."""
        self.page.views.pop()
        top_view = self.page.views[-1]
        self.page.go(top_view.route)

    def _not_found_view(self) -> ft.View:
        return ft.View(
            "/404",
            [
                ft.AppBar(title=ft.Text("Błąd 404")),
                ft.Text("Nie znaleziono żądanej strony.", size=30, color="red")
            ]
        )
