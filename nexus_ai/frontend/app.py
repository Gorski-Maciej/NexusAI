# frontend/app.py -- Flet updater z poprawnym async pattern
import flet as ft

from nexus_ai.core.updater import check_for_updates, download_and_apply_update


def main_ui(page: ft.Page):
    """Inicjalizacja UI z updaterem używającym page.run_task()."""

    async def on_update_click_async(e):
        """Async handler -- nie blokuje UI bo używa page.run_task wewnątrz."""
        page.snack_bar = ft.SnackBar(ft.Text("Pobieranie i instalowanie aktualizacji..."))
        page.snack_bar.open = True
        page.update()

        await download_and_apply_update(e.control.data)

        page.dialog = ft.AlertDialog(
            title=ft.Text("Zakończono"),
            content=ft.Text("Aktualizacja gotowa. Uruchom program ponownie."),
        )
        page.dialog.open = True
        page.update()

    def on_update_click(e):
        page.run_task(on_update_click_async(e))

    async def init_updater():
        update_info = await check_for_updates()
        if update_info["update_available"]:
            banner = ft.Banner(
                bgcolor=ft.colors.AMBER_100,
                leading=ft.Icon(ft.icons.WARNING_AMBER_ROUNDED, color=ft.colors.AMBER, size=40),
                content=ft.Text(f"Dostępna aktualizacja do wersji {update_info['version']}"),
                actions=[
                    ft.TextButton("Aktualizuj", data=update_info["url"], on_click=on_update_click)
                ],
            )
            page.banner = banner
            banner.open = True
            page.update()
