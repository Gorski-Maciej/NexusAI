"""collaboration_cursors.py — Real-Time Collaboration Cursors (v7.0 Rec #5: Innowacja 3).

  Dla biur rachunkowych: kolorowe kursory pokazujące, kto nad czym pracuje.
  NATS broadcast pozycji kursora między użytkownikami.

  - CollaborationManager: zarządza sesjami użytkowników
  - send_cursor_position(): wysyła pozycję przez NATS
  - CollaborationCursorsOverlay: widget Flet pokazujący kursory innych użytkowników
  - Każdy użytkownik ma unikalny kolor i inicjały
"""

from __future__ import annotations

from typing import Any

import flet as ft
import msgspec
import pendulum
from structlog import get_logger

logger = get_logger("nexus.ui.collaboration")

# ── Color palette for user cursors ──────────────────────────────────────────

USER_COLORS: list[str] = [
    "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
    "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F",
    "#BB8FCE", "#85C1E9", "#F8C471", "#82E0AA",
]

_cursor_store: dict[str, dict[str, Any]] = {}  # v7.0: per-instance shared cursor state


# ── Collaboration Manager ───────────────────────────────────────────────────


class CollaborationManager:
    """Zarządza kursorami innych użytkowników w czasie rzeczywistym.

    Używa NATS do broadcastu pozycji kursora.
    """

    def __init__(self, user_id: str, user_name: str, page: ft.Page):
        self.user_id = user_id
        self.user_name = user_name
        self.page = page
        self._nats_sub = None
        self._nats_nc = None
        self._active = False
        self._color = USER_COLORS[hash(user_id) % len(USER_COLORS)]

    @property
    def color(self) -> str:
        return self._color

    async def connect(self):
        """Połącz z NATS i zasubskrybuj topic kursorów."""
        try:
            from nexus_ai.core.nats_utils import get_connection

            self._nats_nc = await get_connection(
                name=f"nexus-collab-{self.user_id}",
                connect_timeout=5.0,
            )
            if self._nats_nc is None:
                logger.warning("[COLLAB] NATS unavailable — collaboration disabled")
                return

            self._nats_sub = await self._nats_nc.subscribe("ui.collaboration.cursors")
            self._active = True
            logger.info("[COLLAB] Subscribed to ui.collaboration.cursors")

            # Uruchom listener w tle
            import asyncio
            asyncio.create_task(self._listen())
        except Exception as exc:
            logger.debug("[COLLAB] Connection failed: %s", exc)

    async def _listen(self):
        """Nasłuchuj pozycji kursorów innych użytkowników."""
        try:
            async for msg in self._nats_sub.messages:
                try:
                    data = msgspec.json.decode(msg.data)
                    user_id = data.get("user_id", "")
                    if user_id != self.user_id:
                        _cursor_store[user_id] = {
                            "x": data.get("x", 0),
                            "y": data.get("y", 0),
                            "name": data.get("user_name", "?"),
                            "color": data.get("color", "#888"),
                            "updated": pendulum.now("UTC"),
                        }
                except Exception as exc:
                    logger.debug("[COLLAB] Message parse error: %s", exc)
        except Exception as exc:
            logger.debug("[COLLAB] Listener stopped: %s", exc)

    async def send_position(self, x: float, y: float):
        """Wyślij pozycję kursora przez NATS."""
        if not self._active or not self._nats_nc:
            return

        try:
            await self._nats_nc.publish(
                "ui.collaboration.cursors",
                msgspec.json.encode({
                    "user_id": self.user_id,
                    "user_name": self.user_name,
                    "color": self._color,
                    "x": x,
                    "y": y,
                    "timestamp": pendulum.now("UTC").isoformat(),
                }),
            )
        except Exception as exc:
            logger.debug("[COLLAB] Send failed: %s", exc)

    async def disconnect(self):
        """Rozłącz od NATS."""
        try:
            if self._nats_sub:
                await self._nats_sub.unsubscribe()
            if self._nats_nc:
                await self._nats_nc.drain()
        except Exception:
            pass
        self._active = False

    def get_remote_cursors(self) -> list[dict[str, Any]]:
        """Pobierz aktualne pozycje kursorów innych użytkowników.

        Usuwa nieaktywne kursory (starsze niż 30s).
        """
        now = pendulum.now("UTC")
        active = {}
        for uid, data in _cursor_store.items():
            age = (now - data.get("updated", now)).in_seconds()
            if age < 30:
                active[uid] = data
            else:
                logger.debug("[COLLAB] Removing stale cursor: %s", uid)

        _cursor_store.clear()
        _cursor_store.update(active)
        return list(active.values())


# ── Collaboration Cursors Overlay Widget ────────────────────────────────────


class CollaborationCursorsOverlay(ft.Stack):
    """Widget wyświetlający kursory innych użytkowników jako kolorowe etykiety.

    Użycie:
        overlay = CollaborationCursorsOverlay(collab_manager)
        # Dodaj jako overlay na głównym widoku
    """

    def __init__(self, manager: CollaborationManager, **kwargs):
        super().__init__(**kwargs)
        self.manager = manager
        self._cursor_labels: dict[str, ft.Container] = {}

    def update_cursors(self):
        """Aktualizuj wyświetlanie kursorów."""
        remote = self.manager.get_remote_cursors()
        active_ids = set()

        for cursor_data in remote:
            uid = cursor_data.get("user_id", "")
            if not uid:
                continue
            active_ids.add(uid)

            if uid not in self._cursor_labels:
                # Utwórz nowy label dla kursora
                initials = "".join(
                    w[0].upper() for w in (cursor_data.get("name", "?")).split()
                )[:2]
                label = ft.Container(
                    content=ft.Column(
                        [
                            ft.Container(
                                content=ft.Text(
                                    "▼",
                                    size=12,
                                    color=cursor_data.get("color", "#888"),
                                    weight=ft.FontWeight.BOLD,
                                ),
                                offset=ft.Offset(0, 0),
                            ),
                            ft.Container(
                                content=ft.Text(
                                    initials,
                                    size=10,
                                    color=ft.colors.WHITE,
                                    weight=ft.FontWeight.BOLD,
                                ),
                                padding=ft.padding.symmetric(horizontal=4, vertical=2),
                                border_radius=4,
                                bgcolor=cursor_data.get("color", "#888"),
                            ),
                        ],
                        spacing=0,
                        horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    ),
                    left=cursor_data.get("x", 0),
                    top=cursor_data.get("y", 0),
                    animate_opacity=ft.animation.Animation(300, ft.AnimationCurve.EASE_OUT),
                )
                self._cursor_labels[uid] = label
                self.controls.append(label)
            else:
                # Aktualizuj pozycję
                label = self._cursor_labels[uid]
                label.left = cursor_data.get("x", 0)
                label.top = cursor_data.get("y", 0)
                label.opacity = 1.0

        # Usuń nieaktywne kursory
        for uid in list(self._cursor_labels.keys()):
            if uid not in active_ids:
                old = self._cursor_labels.pop(uid)
                self.controls.remove(old)

        try:
            self.update()
        except Exception:
            pass
