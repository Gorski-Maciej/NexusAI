"""notification_center.py -- Smart Notification Center (v7.0 Rec #12: Innowacja 6).

  Zamiast przelotnych SnackBarów, pełne centrum powiadomień:
  - Bell icon z NumberBadge (liczba nieprzeczytanych)
  - Lista powiadomień z akcjami (kliknij by sprawdzić, oznacz jako przeczytane)
  - Kategorie: anomalie, terminy, aktualizacje, system
  - page.pubsub dla odbierania powiadomień z innych komponentów
  - page.client_storage dla zapamiętania stanu
"""

from __future__ import annotations

import flet as ft
import pendulum
from structlog import get_logger

logger = get_logger("nexus.ui.notifications")

# ── Notification store ──────────────────────────────────────────────────────

_notifications: list[dict] = []
_listeners: list[callable] = []


def add_notification(
    title: str,
    body: str = "",
    category: str = "system",
    action_route: str | None = None,
    action_label: str = "Sprawdź",
    priority: str = "normal",
):
    """Dodaj powiadomienie do centrum.

    Args:
        title: Krótki tytuł powiadomienia
        body: Opcjonalna treść
        category: Kategoria (anomaly, deadline, update, system)
        action_route: Opcjonalna ścieżka nawigacji po kliknięciu
        action_label: Etykieta przycisku akcji
        priority: Priorytet (critical, high, normal, low)
    """
    notification = {
        "id": pendulum.now("UTC").format("YYYYMMDDHHmmss") + f"-{len(_notifications):04d}",
        "title": title,
        "body": body,
        "category": category,
        "action_route": action_route,
        "action_label": action_label,
        "priority": priority,
        "timestamp": pendulum.now("UTC").isoformat(),
        "read": False,
    }
    _notifications.insert(0, notification)

    # Limit to 50 notifications
    while len(_notifications) > 50:
        _notifications.pop()

    # Notify listeners
    for listener in _listeners:
        try:
            listener(notification)
        except Exception as exc:
            logger.debug("Notification listener error: %s", exc)

    logger.info(
        "[NOTIFY] New notification: %s (category=%s, priority=%s)",
        title, category, priority,
    )


def add_listener(callback):
    """Zarejestruj callback wywoływany przy nowym powiadomieniu."""
    _listeners.append(callback)


def remove_listener(callback):
    """Usuń callback."""
    if callback in _listeners:
        _listeners.remove(callback)


# ── NATS Integration (v7.0: Auto-notifications from NATS events) ────────────

_nats_subscription = None
_nats_connection = None


async def subscribe_nats_notifications():
    """Zasubskrybuj topic NATS dla automatycznych powiadomień.

    v7.0: Guard przed duplikacją — czyści poprzedni sub przed utworzeniem nowego.

    Nasłuchuje na:
    - ui.notifications.anomaly — anomalie wykryte przez agenta
    - ui.notifications.deadline — zbliżające się terminy
    - ui.notifications.update — aktualizacje systemowe
    - ui.notifications.* — wszystkie inne
    """
    global _nats_subscription, _nats_connection

    # v7.0: Cleanup poprzedniego suba (zapobiega duplikacji)
    if _nats_subscription is not None:
        try:
            await _nats_subscription.unsubscribe()
        except Exception:
            pass
        _nats_subscription = None
    if _nats_connection is not None:
        try:
            await _nats_connection.drain()
        except Exception:
            pass
        _nats_connection = None

    try:
        from nexus_ai.core.nats_utils import get_connection
        import msgspec

        nc = await get_connection(
            name="nexus-ui-notifications",
            connect_timeout=5.0,
        )
        if nc is None:
            logger.debug("[NOTIFY-NATS] NATS unavailable — auto-notifications disabled")
            return None

        _nats_connection = nc
        sub = await nc.subscribe("ui.notifications.>")
        _nats_subscription = sub
        logger.info("[NOTIFY-NATS] Subscribed to ui.notifications.>")

        async def _listen_loop():
            try:
                async for msg in sub.messages:
                    try:
                        data = msgspec.json.decode(msg.data)
                    except Exception:
                        data = {"title": "Nowe powiadomienie", "body": msg.data.decode("utf-8", errors="replace")}

                    # Mapuj topic na kategorię
                    topic = msg.subject
                    category = "system"
                    if "anomaly" in topic:
                        category = "anomaly"
                    elif "deadline" in topic:
                        category = "deadline"
                    elif "update" in topic:
                        category = "update"

                    add_notification(
                        title=data.get("title", "Nowe powiadomienie"),
                        body=data.get("body", data.get("message", "")),
                        category=category,
                        action_route=data.get("action_route"),
                        action_label=data.get("action_label", "Sprawdź"),
                        priority=data.get("priority", "normal"),
                    )
            except Exception as exc:
                logger.debug("[NOTIFY-NATS] Listener stopped: %s", exc)

        import asyncio
        asyncio.create_task(_listen_loop())
        return sub
    except Exception as exc:
        logger.debug("[NOTIFY-NATS] Subscribe failed: %s", exc)
        return None


def get_unread_count() -> int:
    """Zwróć liczbę nieprzeczytanych powiadomień."""
    return sum(1 for n in _notifications if not n["read"])


def mark_all_read():
    """Oznacz wszystkie powiadomienia jako przeczytane."""
    for n in _notifications:
        n["read"] = True


# ── Category icons and colors ────────────────────────────────────────────────

CATEGORY_META: dict[str, dict] = {
    "anomaly": {
        "icon": ft.icons.WARNING_AMBER,
        "color": ft.colors.ORANGE_400,
        "label": "Anomalia",
    },
    "deadline": {
        "icon": ft.icons.SCHEDULE,
        "color": ft.colors.RED_400,
        "label": "Termin",
    },
    "update": {
        "icon": ft.icons.SYSTEM_UPDATE_ALT,
        "color": ft.colors.BLUE_400,
        "label": "Aktualizacja",
    },
    "system": {
        "icon": ft.icons.INFO_OUTLINE,
        "color": ft.colors.GREY_400,
        "label": "System",
    },
}


# ── Notification Bell Widget ────────────────────────────────────────────────


class NotificationBell(ft.Container):
    """Dzwoneczek powiadomień z NumberBadge — widget do AppBar/Sidebar."""

    def __init__(self, page: ft.Page, **kwargs):
        super().__init__(**kwargs)
        self.page = page
        self.badge = ft.NumberBadge(
            text="0",
            size=14,
            bgcolor=ft.colors.RED_500,
            visible=False,
        )

        self.content = ft.Stack(
            [
                ft.IconButton(
                    icon=ft.icons.NOTIFICATIONS_OUTLINED,
                    selected_icon=ft.icons.NOTIFICATIONS,
                    tooltip="Centrum powiadomień",
                    on_click=lambda _: self._show_center(),
                    icon_size=22,
                ),
                ft.Container(
                    content=self.badge,
                    right=4,
                    top=4,
                ),
            ],
        )
        self.padding = ft.padding.all(0)
        self.margin = ft.padding.all(0)

        # Update on new notifications
        add_listener(lambda _: self._update_badge())

    def _update_badge(self):
        count = get_unread_count()
        self.badge.text = str(min(count, 99))
        self.badge.visible = count > 0
        try:
            self.update()
        except Exception:
            pass

    def _show_center(self):
        dialog = _build_notification_dialog(self.page)
        self.page.dialog = dialog
        dialog.open = True
        self.page.update()


# ── Notification Dialog ─────────────────────────────────────────────────────


def _build_notification_dialog(page: ft.Page) -> ft.AlertDialog:
    """Zbuduj dialog z listą powiadomień."""

    list_view = ft.ListView(spacing=4, height=400, padding=ft.padding.all(8))

    def render_list():
        list_view.controls.clear()
        if not _notifications:
            list_view.controls.append(
                ft.Container(
                    content=ft.Column(
                        [
                            ft.Icon(ft.icons.NOTIFICATIONS_OFF_OUTLINED, size=48, color=ft.colors.GREY_600),
                            ft.Container(height=8),
                            ft.Text("Brak powiadomień", size=14, color=ft.colors.GREY_500),
                            ft.Text("Wszystko w porządku! 🎉", size=12, color=ft.colors.GREY_600),
                        ],
                        horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                        alignment=ft.MainAxisAlignment.CENTER,
                    ),
                    padding=ft.padding.all(40),
                    expand=True,
                )
            )
            return

        for n in _notifications:
            meta = CATEGORY_META.get(n["category"], CATEGORY_META["system"])
            priority_bg = {
                "critical": ft.colors.RED_900,
                "high": ft.colors.ORANGE_900,
                "normal": ft.colors.TRANSPARENT,
                "low": ft.colors.TRANSPARENT,
            }.get(n["priority"], ft.colors.TRANSPARENT)

            bg = ft.colors.SURFACE_CONTAINER if n["read"] else ft.colors.SURFACE_CONTAINER_HIGHEST
            opacity = 0.7 if n["read"] else 1.0

            action_buttons = []
            if n.get("action_route"):
                action_buttons.append(
                    ft.TextButton(
                        n.get("action_label", "Sprawdź"),
                        on_click=lambda _, route=n["action_route"]: _navigate(page, dialog, route),
                        style=ft.ButtonStyle(color=ft.colors.BLUE_400),
                    )
                )

            list_view.controls.append(
                ft.Container(
                    content=ft.Row(
                        [
                            ft.Icon(meta["icon"], size=20, color=meta["color"], opacity=opacity),
                            ft.Column(
                                [
                                    ft.Text(
                                        n["title"], size=13,
                                        weight=ft.FontWeight.BOLD if not n["read"] else ft.FontWeight.NORMAL,
                                        opacity=opacity,
                                    ),
                                    ft.Text(
                                        n.get("body", ""), size=11,
                                        color=ft.colors.GREY_500,
                                        opacity=opacity,
                                        max_lines=2,
                                        overflow=ft.TextOverflow.ELLIPSIS,
                                    ) if n.get("body") else ft.Container(),
                                    ft.Text(
                                        _format_time(n["timestamp"]),
                                        size=10, color=ft.colors.GREY_600,
                                    ),
                                ],
                                spacing=2,
                                expand=True,
                            ),
                            ft.Row(action_buttons, spacing=4),
                        ],
                        spacing=10,
                        vertical_alignment=ft.CrossAxisAlignment.START,
                    ),
                    padding=ft.padding.all(12),
                    border_radius=8,
                    bgcolor=ft.colors.with_opacity(0.3, bg),
                    border=ft.border.only(left=ft.BorderSide(3, meta["color"])) if n["priority"] in ("critical", "high") else None,
                )
            )

    render_list()

    dialog = ft.AlertDialog(
        title=ft.Row(
            [
                ft.Icon(ft.icons.NOTIFICATIONS, size=24),
                ft.Text("Centrum powiadomień", size=18, weight=ft.FontWeight.BOLD),
                ft.Container(expand=True),
                ft.TextButton(
                    "Oznacz wszystkie jako przeczytane",
                    on_click=lambda _: (_mark_and_refresh(page, dialog)),
                    style=ft.ButtonStyle(color=ft.colors.BLUE_400),
                ),
            ],
        ),
        content=ft.Container(
            content=list_view,
            width=480,
        ),
        actions=[
            ft.TextButton("Zamknij", on_click=lambda e: _close_dialog(page, dialog)),
        ],
        shape=ft.RoundedRectangleBorder(radius=16),
        inset_padding=ft.padding.symmetric(horizontal=40, vertical=24),
    )

    return dialog


def _mark_and_refresh(page: ft.Page, dialog: ft.AlertDialog):
    mark_all_read()
    dialog.open = False
    page.update()


def _close_dialog(page: ft.Page, dialog: ft.AlertDialog):
    dialog.open = False
    page.update()


def _navigate(page: ft.Page, dialog: ft.AlertDialog, route: str):
    dialog.open = False
    page.update()
    page.go(route)


def _format_time(iso: str) -> str:
    try:
        dt = pendulum.parse(iso)
        now = pendulum.now("UTC")
        diff = now - dt

        if diff.in_minutes() < 1:
            return "Przed chwilą"
        if diff.in_minutes() < 60:
            return f"{diff.in_minutes()} min temu"
        if diff.in_hours() < 24:
            return f"{diff.in_hours()} godz. temu"
        if diff.in_days() < 7:
            return f"{diff.in_days()} dni temu"
        return dt.format("DD.MM.YYYY HH:mm")
    except Exception:
        return iso[:16]
