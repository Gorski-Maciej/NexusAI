"""NotificationManager — centralny system powiadomień NexusAI.

Zgodnie z aa3fvcx.txt (Punkt 26): centralny system zarządzania wszystkimi
komunikatami od komponentów systemu do użytkownika: powiadomienia, alerty,
pytania decyzyjne, przypomnienia.

Integruje się z:
  - DecisionQueue (kolejka decyzji oczekujących na użytkownika)
  - EventLog (historia zdarzeń)
  - Scheduler (terminy przypomnień)
"""

from __future__ import annotations

import enum
import sqlite3
from pathlib import Path
from typing import Any

import pendulum
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


class NotificationManager:
    """Centralny system zarządzania powiadomieniami.

    Obsługuje:
      - Powiadomienia informacyjne (INFO)
      - Alerty krytyczne (ALERT)
      - Pytania decyzyjne (DECISION)
      - Przypomnienia czasowe (REMINDER)
      - Błędy systemowe (ERROR)
      - Codzienne podsumowania (DAILY_BRIEFING)

    Storage: SQLite z auto-migracją schematu.
    """

    def __init__(self, db_path: Path | str | None = None) -> None:
        self._db_path = Path(db_path) if db_path else Path("app_data/notifications.db")
        self._db_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_schema()

    def _init_schema(self) -> None:
        """Inicjalizuj schemat bazy danych."""
        conn = sqlite3.connect(str(self._db_path))
        try:
            conn.executescript("""
                CREATE TABLE IF NOT EXISTS notifications (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    title TEXT NOT NULL,
                    message TEXT NOT NULL,
                    category TEXT NOT NULL DEFAULT 'info',
                    priority INTEGER NOT NULL DEFAULT 1,
                    source_agent TEXT NOT NULL DEFAULT '',
                    reference_type TEXT,
                    reference_id TEXT,
                    is_read INTEGER NOT NULL DEFAULT 0,
                    requires_action INTEGER NOT NULL DEFAULT 0,
                    expires_at TEXT,
                    created_at TEXT NOT NULL
                );
                CREATE INDEX IF NOT EXISTS idx_notif_user_read
                    ON notifications(user_id, is_read, created_at DESC);
                CREATE INDEX IF NOT EXISTS idx_notif_category
                    ON notifications(category, created_at DESC);
                CREATE INDEX IF NOT EXISTS idx_notif_expires
                    ON notifications(expires_at)
                    WHERE expires_at IS NOT NULL;
            """)
            conn.commit()
        finally:
            conn.close()

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

        Args:
            user_id: ID użytkownika
            title: Tytuł powiadomienia
            message: Treść powiadomienia
            category: Kategoria (info, alert, decision, reminder, error)
            priority: Priorytet (0=low, 1=normal, 2=high, 3=critical)
            source_agent: Nazwa komponentu źródłowego
            reference_type: Typ referencji (invoice, decision, itp.)
            reference_id: ID referencji
            requires_action: Czy wymaga akcji użytkownika
            expires_in_hours: Po ilu godzinach wygasa

        Returns:
            ID utworzonego powiadomienia
        """
        now = pendulum.now("UTC").isoformat()
        expires_at = None
        if expires_in_hours is not None:
            expires_at = pendulum.now("UTC").add(hours=expires_in_hours).isoformat()

        conn = sqlite3.connect(str(self._db_path))
        try:
            cursor = conn.execute(
                """INSERT INTO notifications
                   (user_id, title, message, category, priority, source_agent,
                    reference_type, reference_id, is_read, requires_action,
                    expires_at, created_at)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?)""",
                (
                    user_id, title, message, category, priority,
                    source_agent or "", reference_type, reference_id,
                    requires_action, expires_at, now,
                ),
            )
            conn.commit()
            notif_id = int(cursor.lastrowid)

            logger.info(
                "[NotificationManager] sent user=%s cat=%s pri=%d agent=%s id=%d",
                user_id, category, priority, source_agent, notif_id,
            )
            return notif_id
        finally:
            conn.close()

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
            dq = DecisionQueue()
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
        conn = sqlite3.connect(str(self._db_path))
        try:
            conn.row_factory = sqlite3.Row
            query = "SELECT * FROM notifications WHERE user_id = ?"
            params: list[Any] = [user_id]

            if unread_only:
                query += " AND is_read = 0"
            if category:
                query += " AND category = ?"
                params.append(category)
            if min_priority is not None:
                query += " AND priority >= ?"
                params.append(min_priority)

            query += " ORDER BY priority DESC, created_at DESC LIMIT ?"
            params.append(limit)

            return [dict(r) for r in conn.execute(query, params).fetchall()]
        finally:
            conn.close()

    def get_unread_count(self, user_id: str, min_priority: int | None = None) -> int:
        """Policz nieprzeczytane powiadomienia."""
        conn = sqlite3.connect(str(self._db_path))
        try:
            query = "SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0"
            params: list[Any] = [user_id]
            if min_priority is not None:
                query += " AND priority >= ?"
                params.append(min_priority)
            return conn.execute(query, params).fetchone()[0]
        finally:
            conn.close()

    def mark_read(self, notification_id: int) -> None:
        """Oznacz powiadomienie jako przeczytane."""
        conn = sqlite3.connect(str(self._db_path))
        try:
            conn.execute("UPDATE notifications SET is_read = 1 WHERE id = ?", (notification_id,))
            conn.commit()
        finally:
            conn.close()

    def mark_all_read(self, user_id: str) -> None:
        """Oznacz wszystkie powiadomienia użytkownika jako przeczytane."""
        conn = sqlite3.connect(str(self._db_path))
        try:
            conn.execute("UPDATE notifications SET is_read = 1 WHERE user_id = ?", (user_id,))
            conn.commit()
        finally:
            conn.close()

    def clean_expired(self) -> int:
        """Usuń wygasłe powiadomienia (expires_at < now).

        Returns:
            Liczba usuniętych powiadomień.
        """
        now = pendulum.now("UTC").isoformat()
        conn = sqlite3.connect(str(self._db_path))
        try:
            cursor = conn.execute(
                "DELETE FROM notifications WHERE expires_at IS NOT NULL AND expires_at < ?",
                (now,),
            )
            conn.commit()
            deleted = cursor.rowcount
            if deleted:
                logger.info("[NotificationManager] cleaned %d expired notifications", deleted)
            return deleted
        finally:
            conn.close()

    def get_alerts(self, user_id: str, min_priority: int = NotificationPriority.HIGH) -> list[dict[str, Any]]:
        """Pobierz aktywne alerty wysokiego priorytetu."""
        return self.get_notifications(
            user_id=user_id,
            category=NotificationCategory.ALERT.value,
            min_priority=min_priority,
            unread_only=True,
        )
