# frontend/app.py (Fragment)
import anyio

import flet as ft

from nexus_ai.core.updater import check_for_updates, download_and_apply_update


def main_ui(page: ft.Page):
    # ... Inicjalizacja Twojego UI ...

    def on_update_click(e):
        # Pokazujemy pasek ładowania
        page.snack_bar = ft.SnackBar(ft.Text("Pobieranie i instalowanie aktualizacji..."))
        page.snack_bar.open = True
        page.update()

        # Pobieranie (w prawdziwym UI zrób to asynchronicznie)
        anyio.run(download_and_apply_update(e.control.data))

        page.dialog = ft.AlertDialog(
            title=ft.Text("Zakończono"),
            content=ft.Text("Aktualizacja gotowa. Uruchom program ponownie."),
        )
        page.dialog.open = True
        page.update()

    async def init_updater():
        update_info = await check_for_updates()
        if update_info["update_available"]:
            # Wyświetlamy banner we Flecie
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
