"""
download_progress_ui.py — Flet-based GUI for first-run model download.

Shows a progress window with:
  - Overall progress bar
  - Per-file progress (name, size, speed)
  - Status messages
  - Cancel button (graceful shutdown)

Opens as a standalone Flet window (not web-based).
"""

from __future__ import annotations

import asyncio
import logging
import sys
from pathlib import Path
from typing import Any

import flet as ft

from installer.models_downloader import (
    check_models_present,
    download_all_models,
    load_manifest,
)
from installer.notification_win import show_download_complete

logger = logging.getLogger("nexus.installer.ui")

# ── Color palette for dark mode ─────────────────────────────────────────────

class Colors:
    BG_DARK = "#1a1a2e"
    BG_CARD = "#16213e"
    BG_PROGRESS_TRACK = "#0f3460"
    ACCENT_BLUE = "#00b4d8"
    ACCENT_GREEN = "#06d6a0"
    ACCENT_RED = "#ef476f"
    ACCENT_ORANGE = "#ffd166"
    TEXT_PRIMARY = "#e0e0e0"
    TEXT_SECONDARY = "#a0a0b0"
    TEXT_DIM = "#707080"


# ── Download state ──────────────────────────────────────────────────────────

class DownloadState:
    """Shared state between UI and download logic."""
    def __init__(self):
        self.cancel_event = asyncio.Event()
        self.is_downloading = False
        self.is_complete = False
        self.current_file = ""
        self.downloaded_bytes = 0
        self.total_bytes = 0
        self.speed_bps = 0.0
        self.overall_progress = 0.0
        self.status_text = "Initializing..."
        self.status = "idle"  # idle, starting, downloading, completed, hash_mismatch, error
        self.error_message = ""
        self.results: list[Any] = []
        self.models_dir: Path | None = None


# ── Progress UI ─────────────────────────────────────────────────────────────

class DownloadProgressApp:
    """Flet UI for model download progress."""

    def __init__(self, state: DownloadState):
        self.state = state
        self._loop = asyncio.new_event_loop()

    def build(self, page: ft.Page) -> None:
        """Build the Flet UI layout."""
        self.page = page
        page.title = "NexusAI — First-Time Setup"
        page.theme_mode = ft.ThemeMode.DARK
        page.bgcolor = Colors.BG_DARK
        page.padding = 40
        page.window_width = 620
        page.window_height = 520
        page.window_resizable = False
        page.window_center()
        page.window_always_on_top = True

        # Prevent closing the window during download
        page.window_prevent_close = True
        page.on_window_event = self._on_window_event

        # ── Header ───────────────────────────────────────────────────────
        header = ft.Container(
            content=ft.Column([
                ft.Text(
                    "NexusAI — First-Time Setup",
                    size=26,
                    weight=ft.FontWeight.BOLD,
                    color=Colors.ACCENT_BLUE,
                ),
                ft.Text(
                    "Downloading AI models for local processing.\n"
                    "This may take a few minutes depending on your internet connection.",
                    size=13,
                    color=Colors.TEXT_SECONDARY,
                ),
            ]),
            margin=ft.margin.only(bottom=20),
        )

        # ── Overall progress ─────────────────────────────────────────────
        self.overall_progress_bar = ft.ProgressBar(
            value=0.0,
            width=540,
            bar_height=8,
            color=Colors.ACCENT_BLUE,
            bgcolor=Colors.BG_PROGRESS_TRACK,
        )
        self.overall_progress_text = ft.Text(
            "0% — Waiting to start...",
            size=14,
            color=Colors.TEXT_PRIMARY,
            weight=ft.FontWeight.BOLD,
        )

        progress_section = ft.Container(
            content=ft.Column([
                ft.Text("Overall Progress", size=16, weight=ft.FontWeight.BOLD, color=Colors.TEXT_PRIMARY),
                ft.Container(height=8),
                self.overall_progress_bar,
                ft.Container(height=6),
                self.overall_progress_text,
            ]),
            bgcolor=Colors.BG_CARD,
            border_radius=12,
            padding=20,
            margin=ft.margin.only(bottom=16),
        )

        # ── Current file progress ────────────────────────────────────────
        self.current_file_label = ft.Text(
            "Preparing...",
            size=14,
            color=Colors.TEXT_SECONDARY,
        )
        self.current_file_progress = ft.ProgressBar(
            value=0.0,
            width=540,
            bar_height=6,
            color=Colors.ACCENT_GREEN,
            bgcolor=Colors.BG_PROGRESS_TRACK,
        )
        self.current_file_speed = ft.Text(
            "",
            size=12,
            color=Colors.TEXT_DIM,
        )

        file_section = ft.Container(
            content=ft.Column([
                ft.Text("Current File", size=14, weight=ft.FontWeight.BOLD, color=Colors.TEXT_PRIMARY),
                ft.Container(height=6),
                self.current_file_label,
                ft.Container(height=4),
                self.current_file_progress,
                ft.Container(height=4),
                self.current_file_speed,
            ]),
            bgcolor=Colors.BG_CARD,
            border_radius=12,
            padding=20,
            margin=ft.margin.only(bottom=16),
        )

        # ── Status / log ─────────────────────────────────────────────────
        self.status_log = ft.Text(
            "Initializing download manager...",
            size=12,
            color=Colors.TEXT_DIM,
            italic=True,
        )

        # ── Buttons ──────────────────────────────────────────────────────
        self.cancel_button = ft.ElevatedButton(
            "Cancel",
            icon=ft.icons.CANCEL_OUTLINED,
            color=Colors.ACCENT_RED,
            bgcolor=Colors.BG_CARD,
            on_click=self._on_cancel,
            width=140,
            height=40,
        )
        self.retry_button = ft.ElevatedButton(
            "Retry",
            icon=ft.icons.REFRESH,
            color=Colors.ACCENT_ORANGE,
            bgcolor=Colors.BG_CARD,
            on_click=self._on_retry,
            visible=False,
            width=140,
            height=40,
        )
        self.finish_button = ft.ElevatedButton(
            "Continue to NexusAI",
            icon=ft.icons.CHECK_CIRCLE_OUTLINE,
            color=Colors.ACCENT_GREEN,
            bgcolor=Colors.BG_CARD,
            on_click=self._on_finish,
            visible=False,
            width=200,
            height=40,
        )
        self.minimize_button = ft.TextButton(
            "Download in background",
            on_click=self._on_minimize,
            visible=False,
        )

        button_row = ft.Row(
            [
                self.cancel_button,
                self.retry_button,
                self.finish_button,
            ],
            alignment=ft.MainAxisAlignment.CENTER,
            spacing=16,
        )

        bg_button_row = ft.Row(
            [self.minimize_button],
            alignment=ft.MainAxisAlignment.CENTER,
        )

        # ── Assemble layout ──────────────────────────────────────────────
        page.add(
            ft.Container(
                content=ft.Column(
                    [
                        header,
                        progress_section,
                        file_section,
                        self.status_log,
                        ft.Container(height=16),
                        button_row,
                        bg_button_row,
                    ],
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    scroll=ft.ScrollMode.NEVER,
                ),
                expand=True,
            )
        )

        # Start download process
        self._download_task = None
        page.run_task(self._start_download)

    def _on_window_event(self, e: ft.WindowEvent) -> None:
        """Handle window close event — prevent during download."""
        if e.type == "close" and self.state.is_downloading:
            # Show confirmation dialog
            self.page.dialog = ft.AlertDialog(
                title=ft.Text("Download in Progress"),
                content=ft.Text(
                    "Models are still downloading. "
                    "If you close now, downloads will resume next time you start NexusAI."
                ),
                actions=[
                    ft.TextButton("Continue Download", on_click=lambda _: self._close_dialog()),
                    ft.TextButton("Close Anyway", on_click=lambda _: self._force_close()),
                ],
            )
            self.page.dialog.open = True
            self.page.update()
        elif e.type == "close":
            self._force_close()

    def _close_dialog(self) -> None:
        if self.page.dialog:
            self.page.dialog.open = False
            self.page.update()

    def _force_close(self) -> None:
        self.state.cancel_event.set()
        self.page.window_destroy()

    def _on_cancel(self, e: ft.ControlEvent) -> None:
        """Cancel the download process."""
        self.state.cancel_event.set()
        self.cancel_button.text = "Cancelling..."
        self.cancel_button.disabled = True
        self.status_log.value = "Cancelling download... (will resume next time)"
        self.status_log.color = Colors.ACCENT_ORANGE
        self.page.update()

    def _on_retry(self, e: ft.ControlEvent) -> None:
        """Retry the download process."""
        self.state.cancel_event.clear()
        self.state.is_complete = False
        self.state.is_downloading = False
        self.retry_button.visible = False
        self.finish_button.visible = False
        self.cancel_button.disabled = False
        self.cancel_button.text = "Cancel"
        self.cancel_button.visible = True
        self.status_log.value = "Retrying download..."
        self.status_log.color = Colors.TEXT_DIM
        self.page.update()
        self.page.run_task(self._start_download)

    def _on_finish(self, e: ft.ControlEvent) -> None:
        """Close the download window and continue to the main app."""
        self.page.window_destroy()

    def _on_minimize(self, e: ft.ControlEvent) -> None:
        """Minimize to background — continue download silently."""
        self.page.window_minimized = True
        self.page.update()

    async def _update_ui_loop(self) -> None:
        """Periodically update UI from the download state."""
        while not self.state.is_complete and not self.state.cancel_event.is_set():
            self._sync_ui()
            await asyncio.sleep(0.2)

        # Final sync
        self._sync_ui()

    def _sync_ui(self) -> None:
        """Synchronize UI elements with current download state."""
        s = self.state

        # Overall progress
        self.overall_progress_bar.value = s.overall_progress
        pct = min(int(s.overall_progress * 100), 100)
        self.overall_progress_text.value = f"{pct}% complete"

        # Current file
        if s.current_file:
            self.current_file_label.value = s.current_file

        # Per-file progress
        if s.total_bytes > 0:
            file_pct = min(s.downloaded_bytes / max(s.total_bytes, 1), 1.0)
            self.current_file_progress.value = file_pct

            if s.speed_bps > 0:
                speed_str = self._format_speed(s.speed_bps)
                downloaded_str = self._format_size(s.downloaded_bytes)
                total_str = self._format_size(s.total_bytes)
                self.current_file_speed.value = f"{downloaded_str} / {total_str} — {speed_str}/s"
            else:
                downloaded_str = self._format_size(s.downloaded_bytes)
                total_str = self._format_size(s.total_bytes)
                self.current_file_speed.value = f"{downloaded_str} / {total_str}"

        # Status
        if s.status == "starting":
            self.status_log.value = f"Starting download of {s.current_file}..."
            self.status_log.color = Colors.TEXT_DIM
        elif s.status == "downloading":
            self.status_log.value = f"Downloading {s.current_file}..."
            self.status_log.color = Colors.TEXT_SECONDARY
        elif s.status == "completed":
            self.status_log.value = f"✓ {s.current_file} downloaded and verified"
            self.status_log.color = Colors.ACCENT_GREEN
        elif s.status == "hash_mismatch":
            self.status_log.value = f"⚠ {s.current_file} checksum mismatch — may need re-download"
            self.status_log.color = Colors.ACCENT_ORANGE
        elif s.status == "verified":
            self.status_log.value = f"✓ {s.current_file} already present, verified"
            self.status_log.color = Colors.ACCENT_GREEN

        self.page.update()

    async def _start_download(self) -> None:
        """Start the model download process."""
        # Determine models directory
        if getattr(sys, "frozen", False):
            app_data = Path(os.environ.get("APPDATA", Path.home() / "AppData" / "Roaming"))
            self.state.models_dir = app_data / "NexusAI" / "models"
        else:
            self.state.models_dir = Path("models")

        self.state.models_dir.mkdir(parents=True, exist_ok=True)

        # Check if models already present
        self.state.status_text = "Checking existing models..."
        self.status_log.value = "Checking for existing models..."
        self.page.update()

        check = check_models_present(self.state.models_dir)

        if check["all_present"]:
            self.status_log.value = "✓ All models are already downloaded and verified!"
            self.status_log.color = Colors.ACCENT_GREEN
            self.overall_progress_text.value = "100% — All models ready"
            self.overall_progress_bar.value = 1.0
            self.state.is_complete = True
            self.cancel_button.visible = False
            self.finish_button.visible = True
            self.page.update()
            return

        # Start UI update loop
        update_task = asyncio.create_task(self._update_ui_loop())

        # Start download
        self.state.is_downloading = True
        self.state.status_text = "Downloading models..."

        manifest_path = self._find_manifest()

        results = await download_all_models(
            self.state.models_dir,
            manifest_path,
            progress_cb=self._on_progress,
            cancel_event=self.state.cancel_event,
            only_required=True,
        )
        self.state.results = results
        self.state.is_downloading = False

        update_task.cancel()

        # Check results
        success_count = sum(1 for r in results if r.success)
        fail_count = sum(1 for r in results if not r.success)

        if self.state.cancel_event.is_set():
            self.status_log.value = "Download cancelled. Will resume next time."
            self.status_log.color = Colors.ACCENT_ORANGE
            self.overall_progress_text.value = "Cancelled"
            self.cancel_button.visible = False
            self.minimize_button.visible = False
            self.finish_button.visible = True
            self.finish_button.text = "Exit Setup"
        elif fail_count > 0:
            self.status_log.value = f"⚠ {fail_count} model(s) failed to download. Check your internet connection."
            self.status_log.color = Colors.ACCENT_RED
            self.cancel_button.visible = False
            self.retry_button.visible = True
            self.finish_button.visible = True
        else:
            self.status_log.value = f"✓ All {success_count} models downloaded and verified successfully!"
            self.status_log.color = Colors.ACCENT_GREEN
            self.overall_progress_text.value = "100% — Complete!"
            self.overall_progress_bar.value = 1.0
            self.state.is_complete = True
            self.cancel_button.visible = False
            self.finish_button.visible = True

            # Show Windows native notification
            if sys.platform == "win32":
                try:
                    show_download_complete(success_count, fail_count)
                except Exception as nf_err:
                    logger.debug("Windows notification failed: %s", nf_err)

        self.page.update()

    def _on_progress(
        self,
        *,
        current_file: str,
        downloaded_bytes: int,
        total_bytes: int,
        speed_bps: float,
        overall_progress: float,
        status: str,
    ) -> None:
        """Progress callback from the downloader."""
        s = self.state
        s.current_file = current_file
        s.downloaded_bytes = downloaded_bytes
        s.total_bytes = total_bytes
        s.speed_bps = speed_bps
        s.overall_progress = overall_progress
        s.status = status

    def _find_manifest(self) -> Path | None:
        """Find the models manifest JSON file."""
        candidates = [
            Path("config/models_manifest.json"),
            Path(__file__).resolve().parent.parent.parent / "config" / "models_manifest.json",
        ]
        if getattr(sys, "frozen", False):
            candidates.insert(0, Path(sys._MEIPASS) / "config" / "models_manifest.json")

        for cand in candidates:
            if cand.exists():
                return cand
        return None

    @staticmethod
    def _format_size(bytes_val: int) -> str:
        """Format bytes to human-readable string."""
        if bytes_val < 1024:
            return f"{bytes_val} B"
        elif bytes_val < 1024 * 1024:
            return f"{bytes_val / 1024:.1f} KB"
        elif bytes_val < 1024 * 1024 * 1024:
            return f"{bytes_val / (1024 * 1024):.1f} MB"
        else:
            return f"{bytes_val / (1024 * 1024 * 1024):.2f} GB"

    @staticmethod
    def _format_speed(bytes_per_sec: float) -> str:
        """Format bytes per second to human-readable string."""
        if bytes_per_sec < 1024:
            return f"{bytes_per_sec:.0f} B"
        elif bytes_per_sec < 1024 * 1024:
            return f"{bytes_per_sec / 1024:.0f} KB"
        elif bytes_per_sec < 1024 * 1024 * 1024:
            return f"{bytes_per_sec / (1024 * 1024):.1f} MB"
        else:
            return f"{bytes_per_sec / (1024 * 1024 * 1024):.2f} GB"


# ── Entry point ─────────────────────────────────────────────────────────────

def run_download_ui() -> bool:
    """Run the download progress UI as a standalone Flet app.

    Returns True if the download completed successfully (or was already complete),
    False if cancelled or failed.
    """
    state = DownloadState()
    app = DownloadProgressApp(state)

    try:
        ft.app(target=app.build)
    except Exception as e:
        logger.error("Flet UI error: %s", e)
        return False

    # Check if all required models were successfully downloaded
    success = all(r.success for r in state.results) if state.results else state.is_complete
    return success


def check_and_download_if_needed(models_dir: str | Path | None = None) -> bool:
    """Check if models are present; if not, show the download UI.

    Returns True if models are ready (already present or downloaded successfully).
    """
    if models_dir is None:
        if getattr(sys, "frozen", False):
            app_data = Path(os.environ.get("APPDATA", Path.home() / "AppData" / "Roaming"))
            models_dir = app_data / "NexusAI" / "models"
        else:
            models_dir = Path("models")

    # Find manifest
    manifest = None
    candidates = [
        Path("config/models_manifest.json"),
        Path(__file__).resolve().parent.parent.parent / "config" / "models_manifest.json",
    ]
    if getattr(sys, "frozen", False):
        candidates.insert(0, Path(sys._MEIPASS) / "config" / "models_manifest.json")
    for cand in candidates:
        if cand.exists():
            manifest = cand
            break

    # Check if models are already present
    check = check_models_present(models_dir, manifest)
    if check["all_present"]:
        logger.info("All AI models are already present and verified.")
        return True

    if check["missing"]:
        logger.info(
            "Missing %d AI model(s): %s. Opening download UI...",
            len(check["missing"]),
            ", ".join(check["missing"]),
        )
    if check["mismatched"]:
        logger.info(
            "Hash mismatch for %d model(s): %s. Re-downloading...",
            len(check["mismatched"]),
            ", ".join(check["mismatched"]),
        )

    return run_download_ui()
