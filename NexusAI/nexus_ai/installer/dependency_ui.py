"""
dependency_ui.py — Flet-based UI for downloading system dependencies (NATS, TigerBeetle).

Shows a splash window with overall progress, per-binary status, and error handling.
"""

from __future__ import annotations

import os
import sys

import anyio
from pathlib import Path

import flet as ft
from structlog import get_logger

from nexus_ai.installer.dependency_downloader import (
    check_dependencies,
    download_all_dependencies,
)

logger = get_logger("nexus.installer.dependency_ui")


class DependencyInstallState:
    """Shared state for dependency installation UI."""

    def __init__(self):
        self.cancel_event = anyio.Event()
        self.is_downloading = False
        self.is_complete = False
        self.current_binary = ""
        self.overall_progress = 0.0
        self.status = "idle"
        self.results: list[tuple[str, bool]] = []
        self.bin_dir: Path | None = None


class DependencyInstallApp:
    """Flet UI for system dependency installation."""

    def __init__(self, state: DependencyInstallState):
        self.state = state
        # Store references to mutable widgets
        self._nats_status_text: ft.Text | None = None
        self._nats_icon: ft.Text | None = None
        self._tb_status_text: ft.Text | None = None
        self._tb_icon: ft.Text | None = None

    def build(self, page: ft.Page) -> None:
        self.page = page
        page.title = "NexusAI — Environment Setup"
        page.theme_mode = ft.ThemeMode.DARK
        page.bgcolor = "#1a1a2e"
        page.padding = 40
        page.window_width = 580
        page.window_height = 480
        page.window_resizable = False
        page.window_center()
        page.window_always_on_top = True
        page.window_prevent_close = True
        page.on_window_event = self._on_window_event

        # Header
        header = ft.Container(
            content=ft.Column(
                [
                    ft.Text(
                        "NexusAI — Environment Setup",
                        size=24,
                        weight=ft.FontWeight.BOLD,
                        color="#00b4d8",
                    ),
                    ft.Text(
                        "Downloading and configuring system components.\n"
                        "This is a one-time setup for background services.",
                        size=13,
                        color="#a0a0b0",
                    ),
                ]
            ),
            margin=ft.margin.only(bottom=20),
        )

        # Overall progress
        self.progress_bar = ft.ProgressBar(
            value=0.0,
            width=500,
            bar_height=8,
            color="#00b4d8",
            bgcolor="#0f3460",
        )
        self.progress_text = ft.Text(
            "Preparing...",
            size=14,
            color="#e0e0e0",
            weight=ft.FontWeight.BOLD,
        )

        progress_section = ft.Container(
            content=ft.Column(
                [
                    ft.Text(
                        "System Components", size=16, weight=ft.FontWeight.BOLD, color="#e0e0e0"
                    ),
                    ft.Container(height=8),
                    self.progress_bar,
                    ft.Container(height=6),
                    self.progress_text,
                ]
            ),
            bgcolor="#16213e",
            border_radius=12,
            padding=20,
            margin=ft.margin.only(bottom=16),
        )

        # Status log
        self.status_log = ft.Text(
            "Initializing...",
            size=12,
            color="#707080",
            italic=True,
        )

        # Binary status cards
        self._binary_status_card("NATS Server", "Message broker", "⏳")
        self._binary_status_card("TigerBeetle", "Accounting ledger", "⏳")

        binaries_section = ft.Container(
            content=ft.Column(
                [
                    self.nats_status,
                    ft.Container(height=8),
                    self.tb_status,
                ]
            ),
            bgcolor="#16213e",
            border_radius=12,
            padding=16,
            margin=ft.margin.only(bottom=16),
        )

        # Buttons
        self.cancel_btn = ft.ElevatedButton(
            "Cancel",
            icon=ft.icons.CANCEL_OUTLINED,
            color="#ef476f",
            bgcolor="#16213e",
            on_click=self._on_cancel,
            width=140,
            height=40,
        )
        self.continue_btn = ft.ElevatedButton(
            "Continue to NexusAI",
            icon=ft.icons.CHECK_CIRCLE_OUTLINE,
            color="#06d6a0",
            bgcolor="#16213e",
            on_click=self._on_continue,
            visible=False,
            width=200,
            height=40,
        )

        page.add(
            ft.Container(
                content=ft.Column(
                    [
                        header,
                        progress_section,
                        binaries_section,
                        self.status_log,
                        ft.Container(height=16),
                        ft.Row(
                            [self.cancel_btn, self.continue_btn],
                            alignment=ft.MainAxisAlignment.CENTER,
                            spacing=16,
                        ),
                    ],
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                ),
                expand=True,
            )
        )

        page.run_task(self._start_setup)

    def _binary_status_card(self, name: str, description: str, icon: str) -> ft.Container:
        # Create the status text widget once and store reference
        status_text = ft.Text("Pending", size=12, color="#707080", italic=True)
        icon_text = ft.Text(icon, size=24)

        # Store references based on binary name
        if "NATS" in name:
            self._nats_status_text = status_text
            self._nats_icon = icon_text
        else:
            self._tb_status_text = status_text
            self._tb_icon = icon_text

        return ft.Container(
            content=ft.Row(
                [
                    icon_text,
                    ft.Column(
                        [
                            ft.Text(name, size=14, weight=ft.FontWeight.BOLD, color="#e0e0e0"),
                            ft.Text(description, size=11, color="#707080"),
                        ],
                        spacing=2,
                        expand=True,
                    ),
                    status_text,
                ],
                alignment=ft.MainAxisAlignment.START,
                spacing=12,
            ),
            padding=12,
        )

    def _update_binary_status(self, name: str, status: str, progress: float = 0):
        """Update the visual state of a binary in the list (no widget recreation)."""
        icons = {
            "downloading": "⬇️",
            "extracting": "📦",
            "done": "✅",
            "error": "❌",
            "pending": "⏳",
        }
        status_texts = {
            "downloading": "Downloading...",
            "extracting": "Extracting...",
            "done": "Ready",
            "error": "Failed",
            "pending": "Pending",
        }
        colors = {
            "downloading": "#ffd166",
            "extracting": "#ffd166",
            "done": "#06d6a0",
            "error": "#ef476f",
            "pending": "#707080",
        }

        # Use stored widget references instead of navigating the tree
        is_nats = "NATS" in name
        status_text = self._nats_status_text if is_nats else self._tb_status_text
        icon_text = self._nats_icon if is_nats else self._tb_icon

        icon = icons.get(status, "⏳")
        label = status_texts.get(status, status)
        color = colors.get(status, "#707080")

        if icon_text:
            icon_text.value = icon
        if status_text:
            status_text.value = label
            status_text.color = color

        self.page.update()

    def _on_window_event(self, e: ft.WindowEvent) -> None:
        if e.type == "close" and self.state.is_downloading:
            self.state.cancel_event.set()
        elif e.type == "close":
            self.page.window_destroy()

    def _on_cancel(self, e: ft.ControlEvent) -> None:
        self.state.cancel_event.set()
        self.cancel_btn.text = "Cancelling..."
        self.cancel_btn.disabled = True
        self.status_log.value = "Cancelling setup..."
        self.status_log.color = "#ffd166"
        self.page.update()

    def _on_continue(self, e: ft.ControlEvent) -> None:
        self.page.window_destroy()

    async def _start_setup(self) -> None:
        """Start the dependency download process."""
        # Determine bin directory
        if getattr(sys, "frozen", False):
            app_data = Path(os.environ.get("APPDATA", Path.home() / "AppData" / "Roaming"))
            self.state.bin_dir = app_data / "NexusAI" / "bin"
        else:
            self.state.bin_dir = Path("bin") / "deps"

        self.state.bin_dir.mkdir(parents=True, exist_ok=True)

        # Check if already installed
        check = check_dependencies(self.state.bin_dir)
        if check["all_installed"]:
            self.status_log.value = "✓ All system components are ready"
            self.status_log.color = "#06d6a0"
            self.progress_bar.value = 1.0
            self.progress_text.value = "100% — All ready"
            self._update_binary_status("NATS Server", "done")
            self._update_binary_status("TigerBeetle", "done")
            self.state.is_complete = True
            self.cancel_btn.visible = False
            self.continue_btn.visible = True
            self.page.update()
            return

        # Start downloading
        self.state.is_downloading = True
        self.status_log.value = "Downloading system components..."
        self.page.update()

        results = await download_all_dependencies(
            self.state.bin_dir,
            progress_cb=self._on_progress,
            cancel_event=self.state.cancel_event,
        )
        self.state.results = results
        self.state.is_downloading = False

        # Check results
        success = all(s for _, s in results)
        if self.state.cancel_event.is_set():
            self.status_log.value = "Setup cancelled. Will retry on next launch."
            self.status_log.color = "#ffd166"
            self.progress_text.value = "Cancelled"
            self.cancel_btn.visible = False
            self.continue_btn.visible = True
            self.continue_btn.text = "Exit Setup"
        elif success:
            self.status_log.value = "✓ All system components downloaded and ready!"
            self.status_log.color = "#06d6a0"
            self.progress_bar.value = 1.0
            self.progress_text.value = "100% — Complete!"
            self.state.is_complete = True
            self.cancel_btn.visible = False
            self.continue_btn.visible = True
        else:
            failed = [n for n, s in results if not s]
            self.status_log.value = f"⚠ Failed: {', '.join(failed)}"
            self.status_log.color = "#ef476f"
            self.cancel_btn.visible = False
            self.continue_btn.visible = True
            self.continue_btn.text = "Continue (Limited)"

        self.page.update()

    def _on_progress(
        self,
        *,
        current_binary,
        downloaded_bytes,
        total_bytes,
        speed_bps,
        overall_progress,
        status,
    ):
        s = self.state
        s.current_binary = current_binary
        s.overall_progress = overall_progress
        s.status = status

        # Update UI
        self.progress_bar.value = overall_progress
        pct = min(int(overall_progress * 100), 100)
        self.progress_text.value = f"{pct}% — {current_binary}"

        self._update_binary_status(current_binary, status)

        if status == "downloading":
            self.status_log.value = f"⬇️ Downloading {current_binary}..."
        elif status == "extracting":
            self.status_log.value = f"📦 Extracting {current_binary}..."
        elif status == "done":
            self.status_log.value = f"✅ {current_binary} ready"
        elif status == "error":
            self.status_log.value = f"❌ Failed to download {current_binary}"

        self.page.update()


def run_dependency_ui() -> bool:
    """Run the dependency installation UI.

    Returns True if all dependencies installed successfully (or were already present).
    """
    state = DependencyInstallState()
    app = DependencyInstallApp(state)

    try:
        ft.app(target=app.build)
    except Exception as e:
        logger.error("Dependency UI error: %s", e)
        return False

    success = all(s for _, s in state.results) if state.results else state.is_complete
    return success
