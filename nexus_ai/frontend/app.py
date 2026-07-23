# frontend/app.py -- Flet updater z poprawnym async pattern (v7.0.1)
# v7.0.1: Używa installer/updater.py (produkcyjny OTA) zamiast core/updater.py
import flet as ft

from nexus_ai.installer.updater import (
    check_for_updates,
    download_update,
    install_update,
    build_update_dialog,
    build_update_progress_dialog,
    CURRENT_VERSION,
)
from nexus_ai.installer.background_updater import (
    BackgroundUpdateManager,
    check_crash_on_startup,
)


def main_ui(page: ft.Page):
    """Inicjalizacja UI z produkcyjnym OTA updaterem (installer/updater).

    v7.0.1: Zastąpiono core/updater.py na installer/updater.py.
    v7.0.2: Background Update Download + Rollback Watchdog.
    Używa SHA-256 verification, HTTP Range resume, i Flet UI dialogów.
    """

    # v7.0.2: Sprawdź crash pattern przy starcie
    if check_crash_on_startup():
        import structlog as _sl2
        _sl2.get_logger("nexus.ui.startup").warning("[STARTUP] Rollback performed — restarting")
        import sys
        import os
        import platform
        if platform.system() == "Windows":
            import subprocess
            subprocess.Popen([sys.executable] + sys.argv)
            sys.exit(0)
        else:
            os.execv(sys.executable, [sys.executable] + sys.argv)
        return

    update_info_ref = None
    bg_manager: BackgroundUpdateManager | None = None

    async def on_update_click_async(e):
        """Async handler — pobiera i instaluje aktualizację z SHA-256 weryfikacją."""
        nonlocal update_info_ref
        if update_info_ref is None:
            page.snack_bar = ft.SnackBar(
                ft.Text("Brak informacji o aktualizacji. Spróbuj ponownie później.")
            )
            page.snack_bar.open = True
            page.update()
            return

        # Pokaż progress dialog
        progress_dialog, progress_bar, status_text, progress_text = build_update_progress_dialog(page)
        page.dialog = progress_dialog
        progress_dialog.open = True
        page.update()

        try:
            def progress_cb(*, downloaded_bytes, total_bytes, speed_bps, status):
                if total_bytes > 0:
                    progress_bar.value = downloaded_bytes / total_bytes
                progress_text.value = (
                    f"{downloaded_bytes / 1024 / 1024:.1f} MB / "
                    f"{total_bytes / 1024 / 1024:.1f} MB · "
                    f"{speed_bps / 1024 / 1024:.1f} MB/s"
                )
                status_text.value = status.capitalize()
                page.update()

            installer_path = await download_update(
                update_info_ref, progress_cb=progress_cb
            )

            if installer_path:
                progress_dialog.open = False
                page.update()
                await install_update(installer_path)

                page.dialog = ft.AlertDialog(
                    title=ft.Text("Aktualizacja gotowa"),
                    content=ft.Text(
                        "Aktualizacja została pobrana i zweryfikowana (SHA-256 ✓).\n"
                        "Uruchom program ponownie, aby zastosować zmiany."
                    ),
                )
                page.dialog.open = True
            else:
                progress_dialog.open = False
                page.snack_bar = ft.SnackBar(
                    ft.Text("❌ Pobieranie aktualizacji nie powiodło się. "
                            "Sprawdź połączenie internetowe.")
                )
                page.snack_bar.open = True
        except ValueError as exc:
            progress_dialog.open = False
            page.dialog = ft.AlertDialog(
                title=ft.Text("⚠️ Aktualizacja zablokowana"),
                content=ft.Text(str(exc)),
            )
            page.dialog.open = True
        except Exception as exc:
            progress_dialog.open = False
            page.snack_bar = ft.SnackBar(
                ft.Text(f"Błąd aktualizacji: {exc}")
            )
            page.snack_bar.open = True
        page.update()

    def on_update_click(e):
        page.run_task(on_update_click_async(e))

    async def on_remind_later():
        page.banner.open = False
        page.update()

    async def on_skip():
        page.banner.open = False
        page.client_storage.set("skip_version", update_info_ref.version if update_info_ref else "")
        page.update()

    async def init_updater():
        nonlocal update_info_ref, bg_manager

        # v7.0.2: Uruchom ciche pobieranie w tle
        user_id = page.client_storage.get("nexus_user_id") or ""
        bg_manager = BackgroundUpdateManager(user_id=user_id)
        page.run_task(bg_manager.start_background_check(page))

        try:
            result = await check_for_updates()
            if result.update_available and result.info:
                update_info_ref = result.info

                # Sprawdź czy użytkownik pominął tę wersję
                skip_version = page.client_storage.get("skip_version")
                if skip_version == result.info.version:
                    return

                banner = ft.Banner(
                    bgcolor=ft.colors.AMBER_100,
                    leading=ft.Icon(
                        ft.icons.WARNING_AMBER_ROUNDED,
                        color=ft.colors.AMBER, size=40,
                    ),
                    content=ft.Text(
                        f"Dostępna aktualizacja do wersji {result.info.version}\n"
                        f"(bieżąca: {result.current_version}, "
                        f"rozmiar: ~{result.info.download_size_mb} MB)"
                    ),
                    actions=[
                        ft.TextButton("Przypomnij później", on_click=lambda _: page.run_task(on_remind_later())),
                        ft.TextButton("Pomiń", on_click=lambda _: page.run_task(on_skip())),
                        ft.TextButton(
                            "Aktualizuj",
                            on_click=on_update_click,
                            style=ft.ButtonStyle(
                                color=ft.colors.WHITE,
                                bgcolor=ft.colors.BLUE_700,
                            ),
                        ),
                    ],
                )
                page.banner = banner
                banner.open = True
                page.update()
        except Exception as exc:
            import structlog
            structlog.get_logger("nexus.ui.updater").warning(
                "Update check failed: %s", exc
            )

        # v7.0.2: Sprawdź czy background download już ściągnął update
        if bg_manager:
            ready = bg_manager.check_ready_update()
            if ready:
                import structlog as _sl
                _sl.get_logger("nexus.ui.updater").info(
                    "[BG UPDATE] Ready update found at %s", ready
                )
