"""AsyncNotificationManager -- centralny system powiadomień (async).

Wszystkie operacje są async -- używa AsyncEngine.
"""

from __future__ import annotations

import enum
from typing import Any, final

import pendulum
from sqlalchemy.ext.asyncio import AsyncEngine
from sqlmodel import text
from structlog import get_logger

from nexus_ai.services.decision_queue import AsyncDecisionQueue

logger = get_logger("nexus.services.notification_manager")


class NotificationPriority(enum.IntEnum):
    __slots__ = ()

    LOW = 0
    NORMAL = 1
    HIGH = 2
    CRITICAL = 3


class NotificationCategory(enum.Enum):
    INFO = "info"
    ALERT = "alert"
    DECISION = "decision"
    REMINDER = "reminder"
    ERROR = "error"
    DAILY_BRIEFING = "daily_briefing"


@final
class AsyncNotificationManager:
    """Centralny async system zarządzania powiadomieniami.

    Wszystkie operacje są async -- używa AsyncEngine zamiast sync Engine.
    """

    def __init__(self, engine: AsyncEngine) -> None:
        self._engine = engine

    async def send(
        self,
        user_id: str,
        title: str,
        message: str,
        category: str = NotificationCategory.INFO.value,
        priority: int = NotificationPriority.NORMAL,
        source_agent: str | None = None,
        reference_type: str | None = None,
        reference_id: str | None = None,
        requires_action: bool = False,
        expires_in_hours: int | None = None,
    ) -> int:
        """Wyślij powiadomienie do użytkownika (ASYNC)."""
        now = pendulum.now("UTC").isoformat()
        expires_at = None
        if expires_in_hours is not None:
            expires_at = pendulum.now("UTC").add(hours=expires_in_hours).isoformat()

        async with self._engine.begin() as conn:
            result = await conn.execute(
                text(
                    """INSERT INTO notifications
                       (user_id, title, message, category, priority, source_agent,
                        reference_type, reference_id, is_read, requires_action,
                        expires_at, created_at)
                       VALUES (:user_id, :title, :message, :category, :priority, :source_agent,
                               :reference_type, :reference_id, 0, :requires_action,
                               :expires_at, :created_at)"""
                ),
                {
                    "user_id": user_id,
                    "title": title,
                    "message": message,
                    "category": category,
                    "priority": priority,
                    "source_agent": source_agent or "",
                    "reference_type": reference_type,
                    "reference_id": reference_id,
                    "requires_action": requires_action,
                    "expires_at": expires_at,
                    "created_at": now,
                },
            )
            notif_id = int(result.lastrowid)

        logger.info(
            "[NotificationManager] sent user=%s cat=%s pri=%d agent=%s id=%d",
            user_id,
            category,
            priority,
            source_agent,
            notif_id,
        )
        return notif_id

    async def send_decision_request(
        self,
        user_id: str,
        title: str,
        message: str,
        source_agent: str,
        reference_type: str,
        reference_id: str,
        priority: int = NotificationPriority.HIGH,
        expires_in_hours: int = 48,
    ) -> int:
        """Wyślij pytanie decyzyjne (ASYNC)."""
        notif_id = await self.send(
            user_id=user_id,
            title=title,
            message=message,
            category=NotificationCategory.DECISION.value,
            priority=priority,
            source_agent=source_agent,
            reference_type=reference_type,
            reference_id=reference_id,
            requires_action=True,
            expires_in_hours=expires_in_hours,
        )

        # Dodaj do DecisionQueue (async)
        try:
            dq = AsyncDecisionQueue(engine=self._engine)
            await dq.enqueue(
                user_id=user_id,
                notification_id=notif_id,
                title=title,
                message=message,
                source_agent=source_agent,
                reference_type=reference_type,
                reference_id=reference_id,
                priority=priority,
                expires_in_hours=expires_in_hours,
            )
        except Exception as exc:
            logger.warning("[NotificationManager] Failed to enqueue decision: %s", exc)

        return notif_id

    async def get_notifications(
        self,
        user_id: str,
        limit: int = 50,
        unread_only: bool = False,
        category: str | None = None,
        min_priority: int | None = None,
    ) -> list[dict[str, Any]]:
        """Pobierz powiadomienia użytkownika (ASYNC)."""
        async with self._engine.connect() as conn:
            query = "SELECT * FROM notifications WHERE user_id = :user_id"
            params: dict[str, Any] = {"user_id": user_id}

            if unread_only:
                query += " AND is_read = 0"
            if category:
                query += " AND category = :category"
                params["category"] = category
            if min_priority is not None:
                query += " AND priority >= :min_priority"
                params["min_priority"] = min_priority

            query += " ORDER BY priority DESC, created_at DESC LIMIT :limit"
            params["limit"] = limit

            result = await conn.execute(text(query), params)
            rows = result.mappings().all()
            return [dict(r) for r in rows]

    async def get_unread_count(self, user_id: str, min_priority: int | None = None) -> int:
        """Policz nieprzeczytane powiadomienia (ASYNC)."""
        async with self._engine.connect() as conn:
            query = "SELECT COUNT(*) FROM notifications WHERE user_id = :user_id AND is_read = 0"
            params: dict[str, Any] = {"user_id": user_id}
            if min_priority is not None:
                query += " AND priority >= :min_priority"
                params["min_priority"] = min_priority
            result = await conn.execute(text(query), params)
            return int(result.scalar() or 0)

    async def mark_read(self, notification_id: int) -> None:
        """Oznacz powiadomienie jako przeczytane (ASYNC)."""
        async with self._engine.begin() as conn:
            await conn.execute(
                text("UPDATE notifications SET is_read = 1 WHERE id = :nid"),
                {"nid": notification_id},
            )

    async def mark_all_read(self, user_id: str) -> None:
        """Oznacz wszystkie powiadomienia użytkownika jako przeczytane (ASYNC)."""
        async with self._engine.begin() as conn:
            await conn.execute(
                text("UPDATE notifications SET is_read = 1 WHERE user_id = :user_id"),
                {"user_id": user_id},
            )

    async def clean_expired(self) -> int:
        """Usuń wygasłe powiadomienia (ASYNC)."""
        now = pendulum.now("UTC").isoformat()
        async with self._engine.begin() as conn:
            result = await conn.execute(
                text(
                    "DELETE FROM notifications WHERE expires_at IS NOT NULL AND expires_at < :now"
                ),
                {"now": now},
            )
            deleted = result.rowcount
        if deleted:
            logger.info("[NotificationManager] cleaned %d expired notifications", deleted)
        return deleted

    async def get_alerts(
        self, user_id: str, min_priority: int = NotificationPriority.HIGH
    ) -> list[dict[str, Any]]:
        """Pobierz aktywne alerty wysokiego priorytetu (ASYNC)."""
        return await self.get_notifications(
            user_id=user_id,
            category=NotificationCategory.ALERT.value,
            min_priority=min_priority,
            unread_only=True,
        )


# ── Alias dla kompatybilności wstecznej ─────────────────────────────────
NotificationManager = AsyncNotificationManager
