# ui/root.py

import flet as ft
from ui.ws_client import ProgressWebSocketClient

from nexus_ai.frontend.api_client import NexusAPIClientUI


class NexusRootUI:
    """Główna klasa orkiestrująca interfejsem graficznym."""

    def __init__(self, page: ft.Page, process_manager):
        self.page = page
        self.process_manager = process_manager  # Z main.py

        port = page.session.get("api_port")
        token = page.session.get("api_token")
        base_url = f"http://127.0.0.1:{port}/api/v1" if port else "http://127.0.0.1:8000/api/v1"
        self.api = NexusAPIClientUI(base_url=base_url, token=token)

        self.ws_client = ProgressWebSocketClient()

        # Task monitor (lazy init)
        self._task_monitor = None

        # Elementy nawigacji
        self.main_content = ft.Container(expand=True, padding=20)
        self.snackbar = ft.SnackBar(content=ft.Text(""), action="OK")
        self.page.overlay.append(self.snackbar)

        # Navigation rail
        self.nav_rail = ft.NavigationRail(
            selected_index=0,
            extended=True,
            label_type=ft.NavigationRailLabelType.ALL,
            bgcolor=ft.colors.with_opacity(0.03, ft.colors.WHITE),
            destinations=[
                ft.NavigationRailDestination(
                    icon=ft.icons.DASHBOARD_OUTLINED,
                    selected_icon=ft.icons.DASHBOARD,
                    label="Dashboard",
                ),
                ft.NavigationRailDestination(
                    icon=ft.icons.DOCUMENT_SCAN_OUTLINED,
                    selected_icon=ft.icons.DOCUMENT_SCAN,
                    label="Invoices",
                ),
                ft.NavigationRailDestination(
                    icon=ft.icons.TASK_ALT_OUTLINED,
                    selected_icon=ft.icons.TASK_ALT,
                    label="Tasks",
                ),
            ],
            on_change=self._on_nav_change,
        )

        self._current_view = "dashboard"

    async def _on_nav_change(self, e: ft.ControlEvent) -> None:
        """Handle navigation rail selection."""
        index = e.control.selected_index
        views = ["dashboard", "invoices", "tasks"]
        target = views[index] if index < len(views) else "dashboard"
        await self._load_view(target)

    async def _load_view(self, view_name: str) -> None:
        """Load a specific view by name."""
        self._current_view = view_name
        if view_name == "tasks":
            await self._load_task_monitor()
        elif view_name == "dashboard":
            await self._load_dashboard()
        elif view_name == "invoices":
            await self._load_invoices()
        else:
            await self._load_dashboard()

    async def build(self):
        """Zarządza globalnym układem (Layout) i rutowaniem."""
        self.page.title = "Nexus AI Workspace"
        self.page.padding = 0
        self.page.bgcolor = "#121212"  # Ciemny motyw Enterprise

        # Build layout with navigation rail
        self.page.add(
            ft.Row([
                self.nav_rail,
                ft.VerticalDivider(width=1, color=ft.colors.GREY_800),
                self.main_content,
            ], expand=True, spacing=0)
        )

        # Załadowanie domyślnego widoku
        await self._load_dashboard()

        self.ws_client.start()

    async def _load_dashboard(self):
        try:
            summary = await self.api.get("/analytics/summary")

            self.main_content.content = ft.Column([
                ft.Text("Financial Dashboard", size=28, weight=ft.FontWeight.BOLD),
                ft.Container(height=16),
                ft.Row([
                    self._create_stat_card("Net Total", f"{summary.get('total_net', 0)} PLN"),
                    self._create_stat_card("Gross Total", f"{summary.get('total_gross', 0)} PLN"),
                    self._create_stat_card("Analyzed", str(summary.get('count', 0))),
                    self._create_stat_card("Status", "Active"),
                ]),
                ft.Container(height=24),
                ft.Text("Quick Actions", size=18, weight=ft.FontWeight.BOLD, color=ft.colors.GREY_300),
                ft.Container(height=8),
                ft.Row([
                    ft.ElevatedButton("Upload Invoice", icon=ft.icons.UPLOAD_FILE),
                    ft.ElevatedButton("View Reports", icon=ft.icons.ASSESSMENT),
                    ft.OutlinedButton("Task Monitor", icon=ft.icons.TASK_ALT,
                                      on_click=lambda _: self.page.run_task(self._load_view("tasks"))),
                ]),
            ], scroll=ft.ScrollMode.AUTO)
            self.page.update()
        except Exception as e:
            self.main_content.content = ft.Text(f"Dashboard load error: {e}", color="red")
            self.page.update()

    async def _load_invoices(self):
        """Placeholder for invoice list view."""
        self.main_content.content = ft.Column([
            ft.Text("Invoices", size=28, weight=ft.FontWeight.BOLD),
            ft.Container(height=16),
            ft.Text("Invoice management view — coming soon.", color=ft.colors.GREY_400),
        ])
        self.page.update()

    async def _load_task_monitor(self):
        """Load the background task monitor panel."""
        from frontend.views.task_monitor import TaskMonitorPanel

        if self._task_monitor is None:
            self._task_monitor = TaskMonitorPanel(self.page, api_client=self.api)

        self.main_content.content = self._task_monitor.build()
        self.page.update()

        # Trigger fetch
        await self._task_monitor.refresh()

    def _create_stat_card(self, title, value):
        return ft.Card(
            content=ft.Container(
                padding=20,
                content=ft.Column([
                    ft.Text(title, size=14, color="grey"),
                    ft.Text(value, size=24, weight="bold")
                ])
            ),
            expand=True,
        )
