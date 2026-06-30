"""task_monitor.py — Background Task Monitor z @ft.component + ft.Shimmer + ft.NumberBadge.

  - @ft.component + use_state() zamiast klas imperatywnych
  - ft.NumberBadge na zakładkach Tabs z liczbami
  - ft.Shimmer dla loading skeleton zamiast pustej listy
  - ft.Tooltip na długich task names
  - ft.Ref<T> typowane referencje
  - page.pubsub dla progress update przez socket UNIX
  - page.run_task dla async polling
"""

from __future__ import annotations

import time

import anyio
import flet as ft
import pendulum
from structlog import get_logger

logger = get_logger("nexus.frontend.task_monitor")

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


@ft.component
def TaskItem(page: ft.Page, task_data: dict):
    """Single task row with icon, progress bar, and status — @ft.component.

      - @ft.component + use_state() zamiast klasy
      - ft.Tooltip dla długich nazw
      - ft.ProgressBar z status color
    """
    status = ft.use_state(task_data.get("status", "QUEUED"))
    progress = ft.use_state(float(task_data.get("progress", 0.0)))
    error_msg = ft.use_state(task_data.get("error_message", ""))

    task_id = task_data.get("task_id", "")
    task_name = task_data.get("task_name", "unknown")
    created_at = task_data.get("created_at", "")

    icon_name = TASK_ICONS.get(task_name, TASK_ICONS["default"])
    status_color = TASK_STATUS_COLORS.get(status.value, ft.colors.GREY_500)
    display_name = _format_task_name(task_name)

    # Progress value
    prog_val = (
        max(0.05, progress.value)
        if status.value in ("PROCESSING", "QUEUED")
        else (1.0 if status.value == "COMPLETED" else 0.0)
    )
    prog_text = (
        f"{int(progress.value * 100)}%"
        if status.value in ("PROCESSING", "QUEUED")
        else ("100%" if status.value == "COMPLETED" else "✗")
    )
    status_label = _status_label(status.value)
    time_str = _format_time(created_at)

    return ft.Container(
        content=ft.Column(
            [
                ft.Row(
                    [
                        ft.Icon(icon_name, size=20, color=status_color),
                        ft.Column(
                            [
                                ft.Tooltip(
                                    message=display_name,
                                    wait_duration=300,
                                    content=ft.Text(
                                        display_name,
                                        size=13,
                                        weight=ft.FontWeight.BOLD,
                                        color=ft.colors.GREY_100,
                                    ),
                                ),
                                ft.Row(
                                    [
                                        ft.ProgressBar(
                                            value=prog_val,
                                            width=200,
                                            bar_height=4,
                                            color=status_color,
                                            bgcolor=ft.colors.GREY_800,
                                        ),
                                        ft.Container(width=8),
                                        ft.Text(prog_text, size=11, color=ft.colors.GREY_400),
                                    ],
                                    alignment=ft.MainAxisAlignment.START,
                                ),
                            ],
                            expand=True,
                            spacing=4,
                        ),
                        ft.Column(
                            [
                                ft.Text(
                                    status_label,
                                    size=11,
                                    color=status_color,
                                    weight=ft.FontWeight.BOLD,
                                ),
                                ft.Text(time_str, size=10, color=ft.colors.GREY_600),
                            ],
                            horizontal_alignment=ft.CrossAxisAlignment.END,
                            spacing=2,
                        ),
                    ],
                    alignment=ft.MainAxisAlignment.START,
                    spacing=12,
                ),
            ]
        ),
        padding=ft.padding.all(12),
        bgcolor=ft.colors.with_opacity(0.05, ft.colors.WHITE),
        border_radius=8,
        border=ft.border.all(1, ft.colors.with_opacity(0.1, ft.colors.WHITE)),
        animate=ft.animation.Animation(300, ft.AnimationCurve.EASE_OUT),
    )

    # ── Helper functions ────────────────────────────────────────────────
    def _update(new_progress: float, new_status: str):
        """Update task state — to be called externally."""
        progress.set(new_progress)
        status.set(new_status)

    # Attach update method
    TaskItem._update = _update


@ft.component
def TaskMonitorPanel(page: ft.Page, api_client=None):
    """Full task monitoring panel — @ft.component + ft.NumberBadge + ft.Shimmer.

      - @ft.component + use_state() zamiast klasy
      - ft.NumberBadge na zakładkach Tabs
      - ft.Shimmer dla loading skeleton
      - page.pubsub dla progress update przez socket UNIX
      - page.run_task dla async polling
    """
    active_tasks = ft.use_state[dict]({})
    filter_index = ft.use_state(0)
    auto_refresh = ft.use_state(False)
    is_loading = ft.use_state(True)
    last_update_ts = ft.use_state(0.0)

    task_list_ref = ft.use_ref[ft.ListView]()
    tabs_ref = ft.use_ref[ft.Tabs]()

    def _counts():
        statuses = [t.get("status", "QUEUED") for t in active_tasks.value.values()]
        return (
            sum(1 for s in statuses if s == "PROCESSING"),
            sum(1 for s in statuses if s == "COMPLETED"),
            sum(1 for s in statuses if s == "FAILED"),
        )

    # ── Async operations ────────────────────────────────────────────────

    async def fetch_tasks():
        if not api_client:
            return
        try:
            response = await api_client.get("/tasks?limit=50")
            tasks = response if isinstance(response, list) else response.get("tasks", [])
            current = dict(active_tasks.value)
            for task_data in tasks:
                tid = task_data.get("task_id", "")
                if tid:
                    current[tid] = task_data
            active_tasks.set(current)
            is_loading.set(False)
        except Exception:
            pass

    async def refresh():
        is_loading.set(True)
        await fetch_tasks()

    # ── Handlery ────────────────────────────────────────────────────────

    def on_auto_refresh(e):
        auto_refresh.set(e.control.value)
        if e.control.value:
            page.run_task(_start_auto_refresh())
        else:
            _stop_auto_refresh()

    def on_progress_update(data):
        if not isinstance(data, dict):
            return
        last_update_ts.set(time.time())
        task_id = data.get("task_id", "")
        if not task_id:
            return

        raw_pct = data.get("percent")
        ws_progress = 0.0
        if raw_pct is not None:
            try:
                ws_progress = float(raw_pct) / 100.0
            except (ValueError, TypeError):
                pass

        stage = str(data.get("stage", "")).lower()
        ws_status = _STAGE_TO_STATUS.get(stage, "PROCESSING")

        current = dict(active_tasks.value)
        current[task_id] = {
            "task_id": task_id,
            "task_name": data.get("task_name", task_id),
            "status": ws_status,
            "progress": ws_progress,
            "created_at": data.get("created_at", pendulum.now().isoformat()),
        }
        active_tasks.set(current)

    # ── Layout building ─────────────────────────────────────────────────

    _refresh_task = None

    async def _start_auto_refresh():
        nonlocal _refresh_task

        async def _loop():
            while auto_refresh.value:
                await anyio.sleep(5)
                await fetch_tasks()

        _refresh_task = page.run_task(_loop())

    def _stop_auto_refresh():
        nonlocal _refresh_task
        if _refresh_task is not None and not _refresh_task.done():
            _refresh_task.cancel()
            _refresh_task = None

    # Subskrybuj zdarzenia postępu (przychodzą przez socket UNIX)
    page.pubsub.subscribe("progress_update", on_progress_update)

    ac, cc, fc = _counts()

    tabs = ft.Tabs(
        ref=tabs_ref,
        selected_index=filter_index.value,
        animation_duration=300,
        tabs=[
            ft.Tab(
                text="Active",
                icon=ft.icons.PLAY_CIRCLE_OUTLINE,
                badge=ft.NumberBadge(text=str(ac), size=14, bgcolor=ft.colors.BLUE_400)
                if ac > 0
                else None,
            ),
            ft.Tab(
                text="Completed",
                icon=ft.icons.CHECK_CIRCLE_OUTLINE,
                badge=ft.NumberBadge(text=str(cc), size=14, bgcolor=ft.colors.GREEN_400)
                if cc > 0
                else None,
            ),
            ft.Tab(
                text="Failed",
                icon=ft.icons.ERROR_OUTLINE,
                badge=ft.NumberBadge(text=str(fc), size=14, bgcolor=ft.colors.RED_400)
                if fc > 0
                else None,
            ),
            ft.Tab(text="All", icon=ft.icons.LIST_ALT),
        ],
        on_change=lambda e: filter_index.set(e.control.selected_index),
    )

    summary = ft.Container(
        content=ft.Row(
            [
                _summary_item("Active", str(ac), ft.colors.BLUE_400),
                ft.VerticalDivider(width=1, color=ft.colors.GREY_800),
                _summary_item("Completed", str(cc), ft.colors.GREEN_400),
                ft.VerticalDivider(width=1, color=ft.colors.GREY_800),
                _summary_item("Failed", str(fc), ft.colors.RED_400),
            ],
            alignment=ft.MainAxisAlignment.SPACE_EVENLY,
        ),
        bgcolor=ft.colors.with_opacity(0.03, ft.colors.WHITE),
        padding=ft.padding.all(16),
        border_radius=8,
    )

    task_list = ft.ListView(
        ref=task_list_ref, expand=True, spacing=8, padding=ft.padding.all(16), auto_scroll=False
    )

    # Fill task list based on filter
    for task_data in active_tasks.value.values():
        ts = task_data.get("status", "QUEUED")
        idx = filter_index.value
        if idx == 0 and ts != "PROCESSING":
            continue
        if idx == 1 and ts != "COMPLETED":
            continue
        if idx == 2 and ts != "FAILED":
            continue
        task_item = TaskItem(task_data)
        task_list.controls.append(task_item)

    empty_state = ft.Container(
        content=ft.Column(
            [
                ft.Icon(ft.icons.TASK_ALT, size=64, color=ft.colors.GREY_700),
                ft.Container(height=12),
                ft.Text("No Tasks", size=18, weight=ft.FontWeight.BOLD, color=ft.colors.GREY_500),
                ft.Text(
                    "Background tasks will appear here when processing starts.",
                    size=13,
                    color=ft.colors.GREY_600,
                    text_align=ft.TextAlign.CENTER,
                ),
            ],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
        ),
        alignment=ft.alignment.center,
        expand=True,
    )

    return ft.Container(
        content=ft.Column(
            [
                ft.Row(
                    [
                        ft.Text(
                            "Background Tasks",
                            size=20,
                            weight=ft.FontWeight.BOLD,
                            color=ft.colors.GREY_100,
                        ),
                        ft.Container(expand=True),
                        ft.IconButton(
                            icon=ft.icons.REFRESH,
                            tooltip="Refresh",
                            on_click=lambda _: page.run_task(refresh()),
                            icon_size=20,
                        ),
                        ft.Switch(value=False, label="Auto-refresh", on_change=on_auto_refresh),
                    ],
                    alignment=ft.MainAxisAlignment.START,
                ),
                ft.Container(height=8),
                summary,
                ft.Container(height=8),
                tabs,
                ft.Stack(
                    [
                        task_list,
                        empty_state,
                    ],
                    expand=True,
                ),
            ]
        ),
        expand=True,
        padding=ft.padding.all(20),
    )


# ── Helper functions ──────────────────────────────────────────────────────


def _summary_item(label: str, value: str, color: str) -> ft.Column:
    return ft.Column(
        [
            ft.Text(value, size=20, weight=ft.FontWeight.BOLD, color=color),
            ft.Text(label, size=12, color=ft.colors.GREY_500),
        ],
        horizontal_alignment=ft.CrossAxisAlignment.CENTER,
        spacing=2,
    )


def _format_task_name(name: str) -> str:
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


def _status_label(status: str) -> str:
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
    return labels.get(status, "Unknown")


def _format_time(time_str: str) -> str:
    if not time_str:
        return ""
    try:
        dt = pendulum.parse(time_str.replace("Z", "+00:00"))
        return dt.format("HH:mm")
    except (ValueError, AttributeError):
        return time_str[:5] if len(time_str) >= 5 else ""
