"""Scheduler — zarządzanie terminami przypomnień i cyklicznych zadań.

Zgodnie z aa3fvcx.txt (Punkt 26): zarządzanie terminami przypomnień
(deadline ZUS, upływające licencje, cykliczne raporty).

Oparty na Python + anyio dla lekkiej, asynchronicznej pracy w tle.
Integruje się z NotificationManager do wysyłania przypomnień.
"""

from __future__ import annotations

import enum
import sqlite3
from pathlib import Path
from typing import Any, Callable

import pendulum
from structlog import get_logger

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads

logger = get_logger("nexus.services.scheduler")


class ReminderType(enum.Enum):
    """Typy przypomnień."""
    ZUS_DEADLINE = "zus_deadline"              # Terminy składek ZUS
    LICENSE_EXPIRY = "license_expiry"           # Upływające licencje
    TAX_REPORT = "tax_report"                    # Cykliczne raporty podatkowe
    INVOICE_DEADLINE = "invoice_deadline"       # Terminy płatności faktur
    CONTRACT_RENEWAL = "contract_renewal"       # Odnowienie umów
    CUSTOM = "custom"                           # Niestandardowe


class ReminderStatus(enum.Enum):
    """Status przypomnienia."""
    ACTIVE = "active"
    SENT = "sent"
    DISMISSED = "dismissed"
    COMPLETED = "completed"


class Scheduler:
    """Zarządzanie terminami i cyklicznymi zadaniami.

    Obsługuje:
      - Przypomnienia o deadline ZUS
      - Przypomnienia o upływających licencjach
      - Cykliczne generowanie raportów
      - Terminy płatności faktur
      - Niestandardowe harmonogramy

    Integracja:
      - NotificationManager: wysyła przypomnienia
      - EventLog: loguje wykonane zadania
      - DecisionQueue: może dodawać decyzje wymagające uwagi

    Storage: SQLite z auto-migracją.
    """

    def __init__(
        self,
        db_path: Path | str | None = None,
        notification_manager: Any = None,
        event_log: Any = None,
    ) -> None:
        self._db_path = Path(db_path) if db_path else Path("app_data/scheduler.db")
        self._db_path.parent.mkdir(parents=True, exist_ok=True)
        self._notification_manager = notification_manager
        self._event_log = event_log
        self._callbacks: dict[str, Callable] = {}
        self._init_schema()

    def _init_schema(self) -> None:
        """Inicjalizuj schemat bazy."""
        conn = sqlite3.connect(str(self._db_path))
        try:
            conn.executescript("""
                CREATE TABLE IF NOT EXISTS scheduled_tasks (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    task_type TEXT NOT NULL DEFAULT 'custom',
                    trigger_at TEXT NOT NULL,
                    interval_minutes INTEGER,
                    callback TEXT NOT NULL DEFAULT '',
                    params TEXT NOT NULL DEFAULT '{}',
                    is_active INTEGER NOT NULL DEFAULT 1,
                    last_run_at TEXT,
                    next_run_at TEXT,
                    created_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS reminders (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    title TEXT NOT NULL,
                    message TEXT NOT NULL,
                    reminder_type TEXT NOT NULL DEFAULT 'custom',
                    remind_at TEXT NOT NULL,
                    status TEXT NOT NULL DEFAULT 'active',
                    reference_type TEXT,
                    reference_id TEXT,
                    notification_id INTEGER DEFAULT NULL,
                    created_at TEXT NOT NULL
                );
                CREATE INDEX IF NOT EXISTS idx_reminders_pending
                    ON reminders(status, remind_at);
                CREATE INDEX IF NOT EXISTS idx_scheduler_next
                    ON scheduled_tasks(next_run_at)
                    WHERE is_active = 1;
            """)
            conn.commit()
        finally:
            conn.close()

    # ── Przypomnienia (reminders) ─────────────────────────────────────────

    def add_reminder(
        self,
        user_id: str,
        title: str,
        message: str,
        remind_at: str,
        reminder_type: str = ReminderType.CUSTOM.value,
        reference_type: str | None = None,
        reference_id: str | None = None,
    ) -> int:
        """Dodaj nowe przypomnienie.

        Args:
            user_id: ID użytkownika
            title: Tytuł przypomnienia
            message: Treść przypomnienia
            remind_at: Kiedy przypomnieć (ISO datetime)
            reminder_type: Typ przypomnienia
            reference_type: Typ referencji
            reference_id: ID referencji

        Returns:
            ID utworzonego przypomnienia
        """
        now = pendulum.now("UTC").isoformat()
        conn = sqlite3.connect(str(self._db_path))
        try:
            cursor = conn.execute(
                """INSERT INTO reminders
                   (user_id, title, message, reminder_type, remind_at,
                    status, reference_type, reference_id, created_at)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (user_id, title, message, reminder_type, remind_at,
                 ReminderStatus.ACTIVE.value, reference_type, reference_id, now),
            )
            conn.commit()
            reminder_id = int(cursor.lastrowid)

            logger.info(
                "[Scheduler] reminder added id=%d user=%s type=%s at=%s",
                reminder_id, user_id, reminder_type, remind_at,
            )
            return reminder_id
        finally:
            conn.close()

    def add_zus_deadline_reminder(
        self,
        user_id: str,
        deadline_date: str,
        days_before: int = 7,
    ) -> int:
        """Dodaj przypomnienie o deadline ZUS.

        Args:
            user_id: ID użytkownika
            deadline_date: Data deadline (YYYY-MM-DD)
            days_before: Na ile dni przed deadline przypomnieć (domyślnie 7)

        Returns:
            ID utworzonego przypomnienia
        """
        deadline = pendulum.parse(deadline_date)
        remind_at = deadline.subtract(days=days_before)

        return self.add_reminder(
            user_id=user_id,
            title=f"Termin składki ZUS — {deadline.format('DD.MM.YYYY')}",
            message=f"Zbliża się termin opłacenia składki ZUS ({deadline.format('DD.MM.YYYY')}). "
                    f"Pozostało {days_before} dni.",
            remind_at=remind_at.isoformat(),
            reminder_type=ReminderType.ZUS_DEADLINE.value,
            reference_type="zus_deadline",
            reference_id=deadline_date,
        )

    def add_license_expiry_reminder(
        self,
        user_id: str,
        license_name: str,
        expiry_date: str,
        days_before: int = 30,
    ) -> int:
        """Dodaj przypomnienie o upływającej licencji."""
        expiry = pendulum.parse(expiry_date)
        remind_at = expiry.subtract(days=days_before)

        return self.add_reminder(
            user_id=user_id,
            title=f"Licencja {license_name} wygasa {expiry.format('DD.MM.YYYY')}",
            message=f"Licencja '{license_name}' wygaśnie za {days_before} dni. "
                    f"Termin: {expiry.format('DD.MM.YYYY')}.",
            remind_at=remind_at.isoformat(),
            reminder_type=ReminderType.LICENSE_EXPIRY.value,
            reference_type="license",
            reference_id=license_name,
        )

    def add_tax_report_reminder(
        self,
        user_id: str,
        report_name: str,
        due_date: str,
        days_before: int = 14,
    ) -> int:
        """Dodaj przypomnienie o cyklicznym raporcie podatkowym."""
        due = pendulum.parse(due_date)
        remind_at = due.subtract(days=days_before)

        return self.add_reminder(
            user_id=user_id,
            title=f"Raport {report_name} — termin {due.format('DD.MM.YYYY')}",
            message=f"Zbliża się termin złożenia raportu '{report_name}'. "
                    f"Termin: {due.format('DD.MM.YYYY')}.",
            remind_at=remind_at.isoformat(),
            reminder_type=ReminderType.TAX_REPORT.value,
            reference_type="tax_report",
            reference_id=report_name,
        )

    # ── Wykonywanie przypomnień ────────────────────────────────────────────

    def process_due_reminders(self) -> list[dict[str, Any]]:
        """Przetwórz wszystkie aktywne przypomnienia, które są już dojrzałe.

        Wysyła powiadomienia przez NotificationManager i oznacza jako 'sent'.

        Returns:
            Lista przetworzonych przypomnień.
        """
        now = pendulum.now("UTC").isoformat()
        conn = sqlite3.connect(str(self._db_path))
        try:
            conn.row_factory = sqlite3.Row
            due = conn.execute(
                """SELECT * FROM reminders
                   WHERE status = ? AND remind_at <= ?
                   ORDER BY remind_at ASC
                   LIMIT 50""",
                (ReminderStatus.ACTIVE.value, now),
            ).fetchall()

            processed = []
            for reminder in due:
                reminder_dict = dict(reminder)

                # Wyślij powiadomienie
                if self._notification_manager:
                    try:
                        notif_id = self._notification_manager.send(
                            user_id=reminder_dict["user_id"],
                            title=reminder_dict["title"],
                            message=reminder_dict["message"],
                            category="reminder",
                            source_agent="scheduler",
                            reference_type=reminder_dict.get("reference_type"),
                            reference_id=reminder_dict.get("reference_id"),
                            requires_action=True,
                            expires_in_hours=72,
                        )
                        # Zapisz ID powiadomienia
                        conn.execute(
                            "UPDATE reminders SET notification_id = ? WHERE id = ?",
                            (notif_id, reminder_dict["id"]),
                        )
                    except Exception as exc:
                        logger.warning(
                            "[Scheduler] Failed to send notification for reminder %d: %s",
                            reminder_dict["id"], exc,
                        )

                # Oznacz jako wysłane
                conn.execute(
                    "UPDATE reminders SET status = ? WHERE id = ?",
                    (ReminderStatus.SENT.value, reminder_dict["id"]),
                )

                # Zaloguj do EventLog
                if self._event_log:
                    try:
                        self._event_log.log(
                            event_type=f"reminder.{reminder_dict['reminder_type']}",
                            source="scheduler",
                            description=f"Reminder sent: {reminder_dict['title']}",
                            user_id=reminder_dict["user_id"],
                            metadata={
                                "reminder_id": reminder_dict["id"],
                                "reminder_type": reminder_dict["reminder_type"],
                            },
                            severity="info",
                        )
                    except Exception as exc:
                        logger.debug("[Scheduler] EventLog log failed: %s", exc)

                processed.append(reminder_dict)

            conn.commit()

            if processed:
                logger.info("[Scheduler] processed %d due reminders", len(processed))

            return processed
        finally:
            conn.close()

    # ── Cykliczne zadania ──────────────────────────────────────────────────

    def register_callback(self, name: str, callback: Callable) -> None:
        """Zarejestruj funkcję callback dla zadania cyklicznego."""
        self._callbacks[name] = callback

    def add_scheduled_task(
        self,
        name: str,
        task_type: str,
        trigger_at: str,
        interval_minutes: int | None = None,
        callback: str = "",
        params: dict[str, Any] | None = None,
    ) -> int:
        """Dodaj zadanie cykliczne.

        Args:
            name: Nazwa zadania
            task_type: Typ zadania
            trigger_at: Kiedy uruchomić (ISO datetime)
            interval_minutes: Interwał w minutach (None = jednorazowe)
            callback: Nazwa zarejestrowanego callbacka
            params: Parametry zadania (JSON)

        Returns:
            ID utworzonego zadania
        """
        now = pendulum.now("UTC").isoformat()
        params_json = msgspec_dumps(params or {})

        next_run = trigger_at
        if interval_minutes and pendulum.parse(trigger_at) < pendulum.now("UTC"):
            # Jeśli trigger_at już minął, oblicz następny termin
            next_run = pendulum.now("UTC").isoformat()

        conn = sqlite3.connect(str(self._db_path))
        try:
            cursor = conn.execute(
                """INSERT INTO scheduled_tasks
                   (name, task_type, trigger_at, interval_minutes,
                    callback, params, is_active, next_run_at, created_at)
                   VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?)""",
                (name, task_type, trigger_at, interval_minutes,
                 callback, params_json, next_run, now),
            )
            conn.commit()
            task_id = int(cursor.lastrowid)

            logger.info(
                "[Scheduler] task added id=%d name=%s type=%s interval=%s",
                task_id, name, task_type, interval_minutes,
            )
            return task_id
        finally:
            conn.close()

    def process_due_tasks(self) -> list[dict[str, Any]]:
        """Przetwórz wszystkie dojrzałe zadania cykliczne.

        Wykonuje callback dla każdego dojrzałego zadania,
        aktualizuje next_run_at dla zadań cyklicznych.
        """
        now = pendulum.now("UTC").isoformat()
        conn = sqlite3.connect(str(self._db_path))
        try:
            conn.row_factory = sqlite3.Row
            due = conn.execute(
                """SELECT * FROM scheduled_tasks
                   WHERE is_active = 1 AND next_run_at IS NOT NULL
                     AND next_run_at <= ?
                   ORDER BY next_run_at ASC
                   LIMIT 20""",
                (now,),
            ).fetchall()

            processed = []
            for task in due:
                task_dict = dict(task)

                # Wykonaj callback
                callback_name = task_dict.get("callback", "")
                if callback_name and callback_name in self._callbacks:
                    try:
                        params = msgspec_loads(task_dict.get("params", "{}"))
                        self._callbacks[callback_name](**params)
                        logger.info(
                            "[Scheduler] executed callback '%s' for task %d",
                            callback_name, task_dict["id"],
                        )
                    except Exception as exc:
                        logger.error(
                            "[Scheduler] callback '%s' failed for task %d: %s",
                            callback_name, task_dict["id"], exc,
                        )

                # Oblicz następny termin
                last_run = now
                next_run = None
                interval = task_dict.get("interval_minutes")
                if interval:
                    next_run = pendulum.now("UTC").add(minutes=interval).isoformat()

                conn.execute(
                    """UPDATE scheduled_tasks
                       SET last_run_at = ?, next_run_at = ?
                       WHERE id = ?""",
                    (last_run, next_run, task_dict["id"]),
                )

                processed.append(task_dict)

            conn.commit()
            return processed
        finally:
            conn.close()

    # ── Zapytania ──────────────────────────────────────────────────────────

    def get_upcoming_reminders(
        self,
        user_id: str | None = None,
        days: int = 30,
        limit: int = 20,
    ) -> list[dict[str, Any]]:
        """Pobierz nadchodzące przypomnienia."""
        now = pendulum.now("UTC").isoformat()
        until = pendulum.now("UTC").add(days=days).isoformat()

        conn = sqlite3.connect(str(self._db_path))
        try:
            conn.row_factory = sqlite3.Row

            query = """SELECT * FROM reminders
                       WHERE status = 'active'
                         AND remind_at >= ?
                         AND remind_at <= ?"""
            params: list[Any] = [now, until]

            if user_id:
                query += " AND user_id = ?"
                params.append(user_id)

            query += " ORDER BY remind_at ASC LIMIT ?"
            params.append(limit)

            return [dict(r) for r in conn.execute(query, params).fetchall()]
        finally:
            conn.close()

    def get_overdue_reminders(self, user_id: str | None = None) -> list[dict[str, Any]]:
        """Pobierz zaległe (niewysłane, po terminie) przypomnienia."""
        now = pendulum.now("UTC").isoformat()

        conn = sqlite3.connect(str(self._db_path))
        try:
            conn.row_factory = sqlite3.Row

            query = """SELECT * FROM reminders
                       WHERE status = 'active'
                         AND remind_at < ?"""
            params: list[Any] = [now]

            if user_id:
                query += " AND user_id = ?"
                params.append(user_id)

            query += " ORDER BY remind_at ASC LIMIT 50"

            return [dict(r) for r in conn.execute(query, params).fetchall()]
        finally:
            conn.close()

    def get_pending_count(self, user_id: str | None = None) -> int:
        """Policz aktywne, jeszcze niewysłane przypomnienia."""
        now = pendulum.now("UTC").isoformat()
        conn = sqlite3.connect(str(self._db_path))
        try:
            query = "SELECT COUNT(*) FROM reminders WHERE status = 'active' AND remind_at > ?"
            params: list[Any] = [now]
            if user_id:
                query += " AND user_id = ?"
                params.append(user_id)
            return conn.execute(query, params).fetchone()[0]
        finally:
            conn.close()

    def dismiss_reminder(self, reminder_id: int) -> None:
        """Odrzuć przypomnienie (nie chcemy więcej przypomnień o tym)."""
        conn = sqlite3.connect(str(self._db_path))
        try:
            conn.execute(
                "UPDATE reminders SET status = ? WHERE id = ?",
                (ReminderStatus.DISMISSED.value, reminder_id),
            )
            conn.commit()
        finally:
            conn.close()

    # ── Sprzątanie ─────────────────────────────────────────────────────────

    def clean_old(self, days: int = 90) -> dict[str, int]:
        """Wyczyść stare wpisy.

        Args:
            days: Usuń wpisy starsze niż N dni

        Returns:
            Dict z liczbą usuniętych wpisów.
        """
        cutoff = pendulum.now("UTC").subtract(days=days).isoformat()
        conn = sqlite3.connect(str(self._db_path))
        try:
            # Usuń wysłane/odrzucone przypomnienia starsze niż N dni
            removed_reminders = conn.execute(
                "DELETE FROM reminders WHERE status != 'active' AND created_at < ?",
                (cutoff,),
            ).rowcount

            # Usuń nieaktywne zadania starsze niż N dni
            removed_tasks = conn.execute(
                "DELETE FROM scheduled_tasks WHERE is_active = 0 AND created_at < ?",
                (cutoff,),
            ).rowcount

            conn.commit()

            if removed_reminders or removed_tasks:
                logger.info(
                    "[Scheduler] cleaned %d reminders, %d tasks (>%d days)",
                    removed_reminders, removed_tasks, days,
                )

            return {"reminders": removed_reminders, "tasks": removed_tasks}
        finally:
            conn.close()
