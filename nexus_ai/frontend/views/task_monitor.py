"""
task_monitor.py — Background Task Monitor panel for NexusAI Flet UI.

Shows real-time status of all background tasks:
  - Active tasks with individual progress bars
  - Queued tasks awaiting processing
  - Recently completed tasks
  - Failed tasks with error details
"""

from __future__ import annotations

import asyncio
import time
from typing import Any

import flet as ft
import pendulum
from structlog import get_logger
from ui.state import app_state

logger = get_logger("nexus.frontend.task_monitor")

# ── Task data types ─────────────────────────────────────────────────────────

TASK_STATUS_COLORS = {
    "QUEUED": ft.colors.GREY_500,
    "PROCESSING": ft.colors.BLUE_400,
    "COMPLETED": ft.colors.GREEN_400,
    "FAILED": ft.colors.RED_400,
    "CANCELLED": ft.colors.ORANGE_400,
    "APPROVED": ft.colors.GREEN_600,
    "REJECTED": ft.colors.RED_600,
    "PENDING_REVIEW": ft.colors.ORANGE_400,
}

TASK_ICONS = {
    "process_invoice_ocr": ft.icons.DOCUMENT_SCAN,
    "process_invoice_task": ft.icons.DOCUMENT_SCAN,
    "analytics_run": ft.icons.ANALYTICS,
    "rules_check": ft.icons.GAVEL,
    "decision_evaluate": ft.icons.PSYCHOLOGY,
    "default": ft.icons.TASK_ALT,
}

# Mapowanie stage → status z wiadomości WebSocket
_STAGE_TO_STATUS = {
    "initializing": "PROCESSING",
    "downloading": "PROCESSING",
    "extracting": "PROCESSING",
    "processing": "PROCESSING",
    "analysing": "PROCESSING",
    "analyzing": "PROCESSING",
    "classifying": "PROCESSING",
    "evaluating": "PROCESSING",
    "completed": "COMPLETED",
    "done": "COMPLETED",
    "error": "FAILED",
    "failed": "FAILED",
    "cancelled": "CANCELLED",
}


# ── Task item widget ────────────────────────────────────────────────────────

class TaskItem(ft.Container):
    """Single task row with icon, name, progress bar, and status."""

    def __init__(self, task_data: dict[str, Any]):
        self.task_id = task_data.get("task_id", "")
        self.task_name = task_data.get("task_name", "unknown")
        self._status = task_data.get("status", "QUEUED")
        self.progress = float(task_data.get("progress", 0.0))
        self.error = task_data.get("error_message", "")
        self.created_at = task_data.get("created_at", "")

        icon_name = TASK_ICONS.get(self.task_name, TASK_ICONS["default"])
        status_color = TASK_STATUS_COLORS.get(self._status, ft.colors.GREY_500)
        display_name = self._format_task_name(self.task_name)

        # Store references to mutable widgets for later updates
        self.status_text = ft.Text(
            self._status_label(),
            size=11,
            color=status_color,
            weight=ft.FontWeight.BOLD,
        )

        self.progress_bar = ft.ProgressBar(
            value=self._progress_value(),
            width=200,
            bar_height=4,
            color=status_color,
            bgcolor=ft.colors.GREY_800,
        )

        self.progress_pct = ft.Text(
            self._progress_pct_value(),
            size=11,
            color=ft.colors.GREY_400,
        )

        self.time_text = ft.Text(
            self._format_time(self.created_at),
            size=10,
            color=ft.colors.GREY_600,
        )

        super().__init__(
            content=ft.Column([
                ft.Row([
                    ft.Icon(icon_name, size=20, color=status_color),
                    ft.Column([
                        ft.Text(display_name, size=13,
                                weight=ft.FontWeight.BOLD, color=ft.colors.GREY_100),
                        ft.Row([
                            self.progress_bar,
                            ft.Container(width=8),
                            self.progress_pct,
                        ], alignment=ft.MainAxisAlignment.START),
                    ], expand=True, spacing=4),
                    ft.Column([
                        self.status_text,
                        self.time_text,
                    ], horizontal_alignment=ft.CrossAxisAlignment.END, spacing=2),
                ], alignment=ft.MainAxisAlignment.START, spacing=12),
            ]),
            padding=ft.padding.all(12),
            bgcolor=ft.colors.with_opacity(0.05, ft.colors.WHITE),
            border_radius=8,
            border=ft.border.all(
                1, ft.colors.with_opacity(0.1, ft.colors.WHITE)
            ),
            animate=ft.animation.Animation(300, ft.AnimationCurve.EASE_OUT),
        )

    @property
    def status(self) -> str:
        return self._status

    @status.setter
    def status(self, value: str) -> None:
        self._status = value

    def _progress_value(self) -> float:
        """Calculate progress bar value based on status."""
        if self._status in ("PROCESSING", "QUEUED"):
            return max(0.05, self.progress)
        elif self._status == "COMPLETED":
            return 1.0
        return 0.0

    def _progress_pct_value(self) -> str:
        """Get progress percentage text."""
        if self._status in ("PROCESSING", "QUEUED"):
            return f"{int(self.progress * 100)}%"
        elif self._status == "COMPLETED":
            return "100%"
        elif self._status == "FAILED":
            return "✗"
        return "—"

    def update_progress(self, progress: float, status: str) -> None:
        """Update the task's progress and status display."""
        self.progress = progress
        self._status = status
        status_color = TASK_STATUS_COLORS.get(status, ft.colors.GREY_500)

        # Update stored widget references directly (no recreation)
        self.status_text.value = self._status_label()
        self.status_text.color = status_color

        self.progress_bar.value = self._progress_value()
        self.progress_bar.color = status_color

        self.progress_pct.value = self._progress_pct_value()

        self.update()

    @staticmethod
    def _format_task_name(name: str) -> str:
        """Convert task name to user-friendly display name."""
        names = {
            "process_invoice_ocr": "Invoice OCR Processing",
            "process_invoice_task": "Invoice Processing",
            "analytics_run": "Analytics & Anomaly Detection",
            "rules_check": "Rules & Compliance Check",
            "decision_evaluate": "Final Decision Evaluation",
            "run_daily_dunning_check": "Daily Dunning Check",
            "execute_monthly_depreciation": "Monthly Depreciation",
            "scheduled_backup_task": "Scheduled Backup",
            "relay_outbox_events": "Outbox Event Relay",
        }
        return names.get(name, name.replace("_", " ").title())

    def _status_label(self) -> str:
        """Get human-readable status label (instance method using self._status)."""
        labels = {
            "QUEUED": "Queued",
            "PROCESSING": "Processing",
            "COMPLETED": "Completed",
            "FAILED": "Failed",
            "CANCELLED": "Cancelled",
            "APPROVED": "Approved",
            "REJECTED": "Rejected",
            "PENDING_REVIEW": "Pending Review",
        }
        return labels.get(self._status, "Unknown")

    @staticmethod
    def _format_time(time_str: str) -> str:
        """Format timestamp for display."""
        if not time_str:
            return ""
        try:
            dt = pendulum.parse(time_str.replace("Z", "+00:00"))
            return dt.format("HH:mm")
        except (ValueError, AttributeError):
            return time_str[:5] if len(time_str) >= 5 else ""


# ── Task Monitor Panel ──────────────────────────────────────────────────────

class TaskMonitorPanel:
    """Full task monitoring panel for the main UI."""

    def __init__(self, page: ft.Page, api_client=None):
        self.page = page
        self._api_client = api_client
        self.active_tasks: dict[str, TaskItem] = {}

        # ── Filter tabs ──────────────────────────────────────────────────
        self.filter_tabs = ft.Tabs(
            selected_index=0,
            animation_duration=300,
            tabs=[
                ft.Tab(text="Active", icon=ft.icons.PLAY_CIRCLE_OUTLINE),
                ft.Tab(text="Completed", icon=ft.icons.CHECK_CIRCLE_OUTLINE),
                ft.Tab(text="Failed", icon=ft.icons.ERROR_OUTLINE),
                ft.Tab(text="All", icon=ft.icons.LIST_ALT),
            ],
            on_change=lambda e: self._apply_filter(),
        )

        # ── Task list ────────────────────────────────────────────────────
        self.task_list = ft.ListView(
            expand=True,
            spacing=8,
            padding=ft.padding.all(16),
            auto_scroll=False,
        )

        # ── Empty state ──────────────────────────────────────────────────
        self.empty_state = ft.Container(
            content=ft.Column([
                ft.Icon(ft.icons.TASK_ALT, size=64, color=ft.colors.GREY_700),
                ft.Container(height=12),
                ft.Text("No Tasks", size=18,
                        weight=ft.FontWeight.BOLD, color=ft.colors.GREY_500),
                ft.Text(
                    "Background tasks will appear here when processing starts.",
                    size=13, color=ft.colors.GREY_600, text_align=ft.TextAlign.CENTER,
                ),
            ], horizontal_alignment=ft.CrossAxisAlignment.CENTER),
            alignment=ft.alignment.center,
            expand=True,
        )

        # ── Summary bar ──────────────────────────────────────────────────
        self.active_count = ft.Text("0", size=20,
                                    weight=ft.FontWeight.BOLD, color=ft.colors.BLUE_400)
        self.completed_count = ft.Text("0", size=20,
                                       weight=ft.FontWeight.BOLD, color=ft.colors.GREEN_400)
        self.failed_count = ft.Text("0", size=20,
                                    weight=ft.FontWeight.BOLD, color=ft.colors.RED_400)

        self.summary_bar = ft.Container(
            content=ft.Row([
                self._summary_item("Active", self.active_count, ft.colors.BLUE_400),
                ft.VerticalDivider(width=1, color=ft.colors.GREY_800),
                self._summary_item("Completed", self.completed_count, ft.colors.GREEN_400),
                ft.VerticalDivider(width=1, color=ft.colors.GREY_800),
                self._summary_item("Failed", self.failed_count, ft.colors.RED_400),
            ], alignment=ft.MainAxisAlignment.SPACE_EVENLY),
            bgcolor=ft.colors.with_opacity(0.03, ft.colors.WHITE),
            padding=ft.padding.all(16),
            border_radius=8,
        )

        # ── Auto-refresh + WebSocket ────────────────────────────────────
        self._auto_refresh = False
        self._refresh_task: asyncio.Task | None = None
        self._last_ws_update = 0.0  # timestamp ostatniego zdarzenia z WebSocket
        self._fallback_interval = 30  # sekundy między fallback pollingiem przy WS
        self._poll_interval = 5  # sekundy między pollingiem bez WS

        # Subskrybuj zdarzenia WebSocket z app_state
        app_state.subscribe("progress_update", self._on_progress_update)

    def _summary_item(self, label: str, count_text: ft.Text, color: str) -> ft.Column:
        return ft.Column([
            count_text,
            ft.Text(label, size=12, color=ft.colors.GREY_500),
        ], horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=2)

    def build(self) -> ft.Container:
        """Build and return the task monitor container."""
        return ft.Container(
            content=ft.Column([
                ft.Row([
                    ft.Text("Background Tasks", size=20,
                            weight=ft.FontWeight.BOLD, color=ft.colors.GREY_100),
                    ft.Container(expand=True),
                    ft.IconButton(
                        icon=ft.icons.REFRESH,
                        tooltip="Refresh",
                        on_click=lambda _: self.page.run_task(self.refresh()),
                        icon_size=20,
                    ),
                    ft.Switch(
                        value=False,
                        label="Auto-refresh",
                        on_change=self._on_auto_refresh,
                    ),
                ], alignment=ft.MainAxisAlignment.START),
                ft.Container(height=8),
                self.summary_bar,
                ft.Container(height=8),
                self.filter_tabs,
                ft.Container(
                    content=ft.Stack([
                        self.task_list,
                        self.empty_state,
                    ], expand=True),
                    expand=True,
                ),
            ]),
            expand=True,
            padding=ft.padding.all(20),
        )

    def _apply_filter(self) -> None:
        """Apply current filter to the task list."""
        tab = self.filter_tabs.selected_index
        visible = []
        for task_id, item in self.active_tasks.items():
            if tab == 0 and item.status == "PROCESSING":
                visible.append(item)
            elif tab == 1 and item.status == "COMPLETED":
                visible.append(item)
            elif tab == 2 and item.status == "FAILED":
                visible.append(item)
            elif tab == 3:
                visible.append(item)

        self.task_list.controls.clear()
        if visible:
            for item in visible:
                self.task_list.controls.append(item)
            self.empty_state.visible = False
        else:
            self.empty_state.visible = True

        self.task_list.update()

    def _on_auto_refresh(self, e: ft.ControlEvent) -> None:
        """Toggle auto-refresh."""
        self._auto_refresh = e.control.value
        if self._auto_refresh:
            self._start_auto_refresh()
        else:
            self._stop_auto_refresh()

    def _start_auto_refresh(self) -> None:
        """Start fallback polling loop.

        Gdy WebSocket jest aktywny (ostatnie zdarzenie < 30s temu),
        polling jest rzadszy (30s). Gdy WebSocket jest martwy,
        polling wraca do 5s jako fallback.
        """
        if self._refresh_task and not self._refresh_task.done():
            return

        async def _loop():
            while self._auto_refresh:
                # WebSocket jest żywy → polling co 30s (fallback)
                age = time.time() - self._last_ws_update
                if age < self._fallback_interval:
                    interval = self._fallback_interval
                else:
                    # WebSocket nie odpowiada → polling co 5s
                    interval = self._poll_interval
                    logger.warning(
                        "WebSocket cichy od %.0fs — fallback do HTTP polling", age
                    )

                await self._fetch_tasks()
                await asyncio.sleep(interval)
        self._refresh_task = asyncio.create_task(_loop())

    def _stop_auto_refresh(self) -> None:
        """Stop auto-refresh loop."""
        if self._refresh_task and not self._refresh_task.done():
            self._refresh_task.cancel()
            self._refresh_task = None

    async def refresh(self) -> None:
        """Manually refresh task list."""
        await self._fetch_tasks()

    async def _fetch_tasks(self) -> None:
        """Fetch tasks from the API."""
        if not self._api_client:
            return
        try:
            response = await self._api_client.get("/tasks?limit=50")
            if response:
                tasks = response if isinstance(response, list) else response.get("tasks", [])
                self._update_from_api(tasks)
        except Exception:
            pass  # API not available yet

    def _update_from_api(self, tasks: list[dict]) -> None:
        """Update task list from API data."""
        current_ids = set()
        for task_data in tasks:
            task_id = task_data.get("task_id", "")
            if not task_id:
                continue
            current_ids.add(task_id)

            if task_id in self.active_tasks:
                self.active_tasks[task_id].update_progress(
                    float(task_data.get("progress", 0.0)),
                    task_data.get("status", "QUEUED"),
                )
            else:
                item = TaskItem(task_data)
                self.active_tasks[task_id] = item
                self.task_list.controls.append(item)

        # Update summary
        statuses = [t.status for t in self.active_tasks.values()]
        self.active_count.value = str(sum(1 for s in statuses if s == "PROCESSING"))
        self.completed_count.value = str(sum(1 for s in statuses if s == "COMPLETED"))
        self.failed_count.value = str(sum(1 for s in statuses if s == "FAILED"))

        # Update empty state
        self.empty_state.visible = len(self.active_tasks) == 0

        # Apply current filter
        self._apply_filter()

    def add_task(self, task_id: str, task_name: str, status: str = "QUEUED",
                 progress: float = 0.0, error: str = "") -> None:
        """Add a new task to the monitor (for local/event-driven updates)."""
        task_data = {
            "task_id": task_id,
            "task_name": task_name,
            "status": status,
            "progress": progress,
            "error_message": error,
            "created_at": pendulum.now().isoformat(),
        }

        if task_id in self.active_tasks:
            self.active_tasks[task_id].update_progress(progress, status)
        else:
            item = TaskItem(task_data)
            self.active_tasks[task_id] = item
            self.task_list.controls.append(item)

        self._update_summary()

    def _on_progress_update(self, data: Any) -> None:
        """Handle WebSocket progress update events from app_state."""
        now = time.time()
        self._last_ws_update = now

        if not isinstance(data, dict):
            return

        task_id = data.get("task_id", "")
        if not task_id:
            return

        # Mapuj pola z wiadomości WebSocket
        # percent (0-100) → progress (0.0-1.0)
        raw_pct = data.get("percent")
        if raw_pct is not None:
            try:
                ws_progress = float(raw_pct) / 100.0
            except (ValueError, TypeError):
                ws_progress = 0.0
        else:
            ws_progress = 0.0

        # stage → status
        stage = str(data.get("stage", "")).lower()
        ws_status = _STAGE_TO_STATUS.get(stage, "PROCESSING")

        task_name = data.get("task_name", "")

        if task_id in self.active_tasks:
            self.active_tasks[task_id].update_progress(ws_progress, ws_status)
        else:
            # Nowe zadanie z WebSocket — dodaj do listy
            # Użyj task_name z wiadomości lub task_id jako fallback
            self.add_task(
                task_id=task_id,
                task_name=task_name if task_name else task_id,
                status=ws_status,
                progress=ws_progress,
            )

        # Zaktualizuj widok filtrów + podsumowanie
        self._update_summary()
        self._apply_filter()

    def update_task(self, task_id: str, progress: float, status: str) -> None:
        """Update an existing task's progress."""
        if task_id in self.active_tasks:
            self.active_tasks[task_id].update_progress(progress, status)
            self._update_summary()

    def _update_summary(self) -> None:
        """Update the summary bar counts."""
        statuses = [t.status for t in self.active_tasks.values()]
        self.active_count.value = str(sum(1 for s in statuses if s == "PROCESSING"))
        self.completed_count.value = str(sum(1 for s in statuses if s == "COMPLETED"))
        self.failed_count.value = str(sum(1 for s in statuses if s == "FAILED"))

        self.active_count.update()
        self.completed_count.update()
        self.failed_count.update()
        self.empty_state.visible = len(self.active_tasks) == 0
        self.empty_state.update()
