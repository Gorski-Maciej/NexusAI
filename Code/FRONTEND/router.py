# frontend/router.py
import flet as ft
from frontend.views.dashboard_view import DashboardView
from frontend.views.invoice_list_view import InvoiceListView
from frontend.views.daily_briefing import DailyBriefingView
from frontend.views.partner_hub import PartnerHubView

class NexusRouter:
    def __init__(self, page: ft.Page, api_client):
        self.page = page
        self.api = api_client
        self.routes = {
            "/": DashboardView(api_client),
            "/invoices": InvoiceListView(api_client),
            "/briefing": DailyBriefingView(api_client),
            "/partner": PartnerHubView(api_client),
        }

    def handle_route_change(self, route_event):
        self.page.views.clear()

        # Wybieramy widok na podstawie ścieżki
        view_handler = self.routes.get(self.page.route, self.routes["/"])

        view = ft.View(
            route=self.page.route,
            controls=[
                self._build_app_bar(),
                view_handler.build(), # Każdy widok ma metodę build()
            ],
            drawer=self._build_drawer()
        )
        self.page.views.append(view)
        self.page.update()

        # Trigger async data load for all views that support it
        if hasattr(view_handler, 'load_data'):
            self.page.run_task(view_handler.load_data)

    def _build_app_bar(self):
        return ft.AppBar(
            title=ft.Text("Nexus AI"),
            bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
            actions=[
                ft.IconButton(
                    icon=ft.icons.NOTIFICATIONS_OUTLINED,
                    tooltip="Powiadomienia",
                ),
            ],
        )

    def _build_drawer(self):
        return ft.NavigationDrawer(
            controls=[
                ft.Container(height=12),
                ft.NavigationDrawerDestination(
                    label="Dashboard",
                    icon=ft.icons.DASHBOARD,
                    selected_icon=ft.icons.DASHBOARD,
                ),
                ft.NavigationDrawerDestination(
                    label="1 Minuta Dziennie",
                    icon=ft.icons.WB_SUNNY_OUTLINED,
                    selected_icon=ft.icons.WB_SUNNY,
                ),
                ft.NavigationDrawerDestination(
                    label="Faktury",
                    icon=ft.icons.DOCUMENT_SCAN,
                    selected_icon=ft.icons.DOCUMENT_SCAN,
                ),
                ft.Divider(height=1, color=ft.colors.GREY_700),
                ft.NavigationDrawerDestination(
                    label="Partner Hub",
                    icon=ft.icons.BUSINESS_CENTER,
                    selected_icon=ft.icons.BUSINESS_CENTER,
                ),
                ft.Container(height=12),
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
