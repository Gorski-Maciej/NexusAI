"""NotificationManager — centralny system powiadomień NexusAI.

Zgodnie z aa3fvcx.txt (Punkt 26): centralny system zarządzania wszystkimi
komunikatami od komponentów systemu do użytkownika: powiadomienia, alerty,
pytania decyzyjne, przypomnienia.

Integruje się z:
  - DecisionQueue (kolejka decyzji oczekujących na użytkownika)
  - EventLog (historia zdarzeń)
  - Scheduler (terminy przypomnień)

Storage: Główna baza danych (SQLAlchemy / Alembic).
DDL w migracji 0003_consolidate_service_tables (tabela: notifications).
"""

from __future__ import annotations

import enum
from typing import Any, final

import pendulum
from sqlalchemy import Engine, text
from structlog import get_logger

from nexus_ai.services.decision_queue import DecisionQueue

logger = get_logger("nexus.services.notification_manager")


class NotificationPriority(enum.IntEnum):
    """Priorytety powiadomień."""

    LOW = 0
    NORMAL = 1
    HIGH = 2
    CRITICAL = 3


class NotificationCategory(enum.Enum):
    """Kategorie powiadomień."""

    INFO = "info"
    ALERT = "alert"
    DECISION = "decision"
    REMINDER = "reminder"
    ERROR = "error"
    DAILY_BRIEFING = "daily_briefing"


@final
class NotificationManager:
    """Centralny system zarządzania powiadomieniami.

    Obsługuje:
      - Powiadomienia informacyjne (INFO)
      - Alerty krytyczne (ALERT)
      - Pytania decyzyjne (DECISION)
      - Przypomnienia czasowe (REMINDER)
      - Błędy systemowe (ERROR)
      - Codzienne podsumowania (DAILY_BRIEFING)

    Storage: Główna baza danych (Alembic, tabela: notifications).
    """

    def __init__(self, engine: Engine) -> None:
        self._engine = engine

    def send(
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
        """Wyślij powiadomienie do użytkownika.

        Returns:
            ID utworzonego powiadomienia
        """
        now = pendulum.now("UTC").isoformat()
        expires_at = None
        if expires_in_hours is not None:
            expires_at = pendulum.now("UTC").add(hours=expires_in_hours).isoformat()

        with self._engine.begin() as conn:
            result = conn.execute(
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

    def send_decision_request(
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
        """Wyślij pytanie decyzyjne.

        Przekierowuje również do DecisionQueue dla trwałego przechowania.
        """
        notif_id = self.send(
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

        # Dodaj również do DecisionQueue dla kolejkowania decyzji
        try:
            dq = DecisionQueue(engine=self._engine)
            dq.enqueue(
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

    def get_notifications(
        self,
        user_id: str,
        limit: int = 50,
        unread_only: bool = False,
        category: str | None = None,
        min_priority: int | None = None,
    ) -> list[dict[str, Any]]:
        """Pobierz powiadomienia użytkownika."""
        with self._engine.connect() as conn:
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

            rows = conn.execute(text(query), params).mappings().all()
            return [dict(r) for r in rows]

    def get_unread_count(self, user_id: str, min_priority: int | None = None) -> int:
        """Policz nieprzeczytane powiadomienia."""
        with self._engine.connect() as conn:
            query = "SELECT COUNT(*) FROM notifications WHERE user_id = :user_id AND is_read = 0"
            params: dict[str, Any] = {"user_id": user_id}
            if min_priority is not None:
                query += " AND priority >= :min_priority"
                params["min_priority"] = min_priority
            return int(conn.execute(text(query), params).scalar() or 0)

    def mark_read(self, notification_id: int) -> None:
        """Oznacz powiadomienie jako przeczytane."""
        with self._engine.begin() as conn:
            conn.execute(
                text("UPDATE notifications SET is_read = 1 WHERE id = :nid"),
                {"nid": notification_id},
            )

    def mark_all_read(self, user_id: str) -> None:
        """Oznacz wszystkie powiadomienia użytkownika jako przeczytane."""
        with self._engine.begin() as conn:
            conn.execute(
                text("UPDATE notifications SET is_read = 1 WHERE user_id = :user_id"),
                {"user_id": user_id},
            )

    def clean_expired(self) -> int:
        """Usuń wygasłe powiadomienia (expires_at < now).

        Returns:
            Liczba usuniętych powiadomień.
        """
        now = pendulum.now("UTC").isoformat()
        with self._engine.begin() as conn:
            result = conn.execute(
                text(
                    "DELETE FROM notifications WHERE expires_at IS NOT NULL AND expires_at < :now"
                ),
                {"now": now},
            )
            deleted = result.rowcount
        if deleted:
            logger.info("[NotificationManager] cleaned %d expired notifications", deleted)
        return deleted

    def get_alerts(
        self, user_id: str, min_priority: int = NotificationPriority.HIGH
    ) -> list[dict[str, Any]]:
        """Pobierz aktywne alerty wysokiego priorytetu."""
        return self.get_notifications(
            user_id=user_id,
            category=NotificationCategory.ALERT.value,
            min_priority=min_priority,
            unread_only=True,
        )
