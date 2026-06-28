"""Scheduler — zarządzanie terminami przypomnień i cyklicznych zadań.

Zgodnie z aa3fvcx.txt (Punkt 26): zarządzanie terminami przypomnień
(deadline ZUS, upływające licencje, cykliczne raporty).

Oparty na Python + anyio dla lekkiej, asynchronicznej pracy w tle.
Integruje się z NotificationManager do wysyłania przypomnień.

Storage: Główna baza danych (SQLModel / native SQL).
DDL w migracji 0003_consolidate_service_tables.
"""

from __future__ import annotations

import enum
from typing import Any, Callable, final

import pendulum
from sqlalchemy import Engine
from sqlmodel import text
from structlog import get_logger

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads

logger = get_logger("nexus.services.scheduler")


class ReminderType(enum.Enum):
    """Typy przypomnień."""

    ZUS_DEADLINE = "zus_deadline"  # Terminy składek ZUS
    LICENSE_EXPIRY = "license_expiry"  # Upływające licencje
    TAX_REPORT = "tax_report"  # Cykliczne raporty podatkowe
    INVOICE_DEADLINE = "invoice_deadline"  # Terminy płatności faktur
    CONTRACT_RENEWAL = "contract_renewal"  # Odnowienie umów
    CUSTOM = "custom"  # Niestandardowe


class ReminderStatus(enum.Enum):
    """Status przypomnienia."""

    ACTIVE = "active"
    SENT = "sent"
    DISMISSED = "dismissed"
    COMPLETED = "completed"


@final
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

    Storage: Główna baza danych (SQLModel).
    Tabele: scheduled_tasks, reminders (migracja 0003).
    """

    def __init__(
        self,
        engine: Engine,
        notification_manager: Any = None,
        event_log: Any = None,
    ) -> None:
        self._engine = engine
        self._notification_manager = notification_manager
        self._event_log = event_log
        self._callbacks: dict[str, Callable] = {}

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

        Returns:
            ID utworzonego przypomnienia
        """
        now = pendulum.now("UTC").isoformat()
        with self._engine.begin() as conn:
            result = conn.execute(
                text(
                    """INSERT INTO reminders
                       (user_id, title, message, reminder_type, remind_at,
                        status, reference_type, reference_id, created_at)
                       VALUES (:user_id, :title, :message, :reminder_type, :remind_at,
                               :status, :reference_type, :reference_id, :created_at)"""
                ),
                {
                    "user_id": user_id,
                    "title": title,
                    "message": message,
                    "reminder_type": reminder_type,
                    "remind_at": remind_at,
                    "status": ReminderStatus.ACTIVE.value,
                    "reference_type": reference_type,
                    "reference_id": reference_id,
                    "created_at": now,
                },
            )
            reminder_id = int(result.lastrowid)

        logger.info(
            "[Scheduler] reminder added id=%d user=%s type=%s at=%s",
            reminder_id,
            user_id,
            reminder_type,
            remind_at,
        )
        return reminder_id

    def add_zus_deadline_reminder(
        self,
        user_id: str,
        deadline_date: str,
        days_before: int = 7,
    ) -> int:
        """Dodaj przypomnienie o deadline ZUS."""
        deadline = pendulum.parse(deadline_date)
        # SUPERMOC pendulum: yesterday()/tomorrow() — idiomatyczne przesunięcia
        remind_at = (
            pendulum.yesterday() if days_before <= 1 else deadline.subtract(days=days_before)
        )

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
        with self._engine.connect() as conn:
            rows = (
                conn.execute(
                    text(
                        """SELECT * FROM reminders
                       WHERE status = :status AND remind_at <= :now
                       ORDER BY remind_at ASC
                       LIMIT 50"""
                    ),
                    {"status": ReminderStatus.ACTIVE.value, "now": now},
                )
                .mappings()
                .all()
            )

            processed = []
            for reminder in rows:
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
                        with self._engine.begin() as uc:
                            uc.execute(
                                text("UPDATE reminders SET notification_id = :nid WHERE id = :rid"),
                                {"nid": notif_id, "rid": reminder_dict["id"]},
                            )
                    except Exception as exc:
                        logger.warning(
                            "[Scheduler] Failed to send notification for reminder %d: %s",
                            reminder_dict["id"],
                            exc,
                        )

                # Oznacz jako wysłane
                with self._engine.begin() as uc:
                    uc.execute(
                        text("UPDATE reminders SET status = :status WHERE id = :rid"),
                        {"status": ReminderStatus.SENT.value, "rid": reminder_dict["id"]},
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

        if processed:
            logger.info("[Scheduler] processed %d due reminders", len(processed))

        return processed

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

        Returns:
            ID utworzonego zadania
        """
        now = pendulum.now("UTC").isoformat()
        params_json = msgspec_dumps(params or {})

        next_run = trigger_at
        if interval_minutes and pendulum.parse(trigger_at) < pendulum.now("UTC"):
            next_run = pendulum.now("UTC").isoformat()

        with self._engine.begin() as conn:
            result = conn.execute(
                text(
                    """INSERT INTO scheduled_tasks
                       (name, task_type, trigger_at, interval_minutes,
                        callback, params, is_active, next_run_at, created_at)
                       VALUES (:name, :task_type, :trigger_at, :interval_minutes,
                               :callback, :params, 1, :next_run_at, :created_at)"""
                ),
                {
                    "name": name,
                    "task_type": task_type,
                    "trigger_at": trigger_at,
                    "interval_minutes": interval_minutes,
                    "callback": callback,
                    "params": params_json,
                    "next_run_at": next_run,
                    "created_at": now,
                },
            )
            task_id = int(result.lastrowid)

        logger.info(
            "[Scheduler] task added id=%d name=%s type=%s interval=%s",
            task_id,
            name,
            task_type,
            interval_minutes,
        )
        return task_id

    def process_due_tasks(self) -> list[dict[str, Any]]:
        """Przetwórz wszystkie dojrzałe zadania cykliczne.

        Wykonuje callback dla każdego dojrzałego zadania,
        aktualizuje next_run_at dla zadań cyklicznych.
        """
        now = pendulum.now("UTC").isoformat()
        with self._engine.connect() as conn:
            rows = (
                conn.execute(
                    text(
                        """SELECT * FROM scheduled_tasks
                       WHERE is_active = 1 AND next_run_at IS NOT NULL
                         AND next_run_at <= :now
                       ORDER BY next_run_at ASC
                       LIMIT 20"""
                    ),
                    {"now": now},
                )
                .mappings()
                .all()
            )

            processed = []
            for task in rows:
                task_dict = dict(task)

                # Wykonaj callback
                callback_name = task_dict.get("callback", "")
                if callback_name and callback_name in self._callbacks:
                    try:
                        params = msgspec_loads(task_dict.get("params", "{}"))
                        self._callbacks[callback_name](**params)
                        logger.info(
                            "[Scheduler] executed callback '%s' for task %d",
                            callback_name,
                            task_dict["id"],
                        )
                    except Exception as exc:
                        logger.error(
                            "[Scheduler] callback '%s' failed for task %d: %s",
                            callback_name,
                            task_dict["id"],
                            exc,
                        )

                # Oblicz następny termin
                last_run = now
                next_run = None
                interval = task_dict.get("interval_minutes")
                if interval:
                    next_run = pendulum.now("UTC").add(minutes=interval).isoformat()

                with self._engine.begin() as uc:
                    uc.execute(
                        text(
                            """UPDATE scheduled_tasks
                               SET last_run_at = :last_run, next_run_at = :next_run
                               WHERE id = :tid"""
                        ),
                        {"last_run": last_run, "next_run": next_run, "tid": task_dict["id"]},
                    )

                processed.append(task_dict)

        return processed

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

        with self._engine.connect() as conn:
            query = """SELECT * FROM reminders
                       WHERE status = 'active'
                         AND remind_at >= :now
                         AND remind_at <= :until"""
            params: dict[str, Any] = {"now": now, "until": until}

            if user_id:
                query += " AND user_id = :user_id"
                params["user_id"] = user_id

            query += " ORDER BY remind_at ASC LIMIT :limit"
            params["limit"] = limit

            rows = conn.execute(text(query), params).mappings().all()
            return [dict(r) for r in rows]

    def get_overdue_reminders(self, user_id: str | None = None) -> list[dict[str, Any]]:
        """Pobierz zaległe (niewysłane, po terminie) przypomnienia."""
        now = pendulum.now("UTC").isoformat()

        with self._engine.connect() as conn:
            query = """SELECT * FROM reminders
                       WHERE status = 'active'
                         AND remind_at < :now"""
            params: dict[str, Any] = {"now": now}

            if user_id:
                query += " AND user_id = :user_id"
                params["user_id"] = user_id

            query += " ORDER BY remind_at ASC LIMIT 50"

            rows = conn.execute(text(query), params).mappings().all()
            return [dict(r) for r in rows]

    def get_pending_count(self, user_id: str | None = None) -> int:
        """Policz aktywne, jeszcze niewysłane przypomnienia."""
        now = pendulum.now("UTC").isoformat()
        with self._engine.connect() as conn:
            query = "SELECT COUNT(*) FROM reminders WHERE status = 'active' AND remind_at > :now"
            params: dict[str, Any] = {"now": now}
            if user_id:
                query += " AND user_id = :user_id"
                params["user_id"] = user_id
            return int(conn.execute(text(query), params).scalar() or 0)

    def dismiss_reminder(self, reminder_id: int) -> None:
        """Odrzuć przypomnienie (nie chcemy więcej przypomnień o tym)."""
        with self._engine.begin() as conn:
            conn.execute(
                text("UPDATE reminders SET status = :status WHERE id = :rid"),
                {"status": ReminderStatus.DISMISSED.value, "rid": reminder_id},
            )

    # ── Sprzątanie ─────────────────────────────────────────────────────────

    def clean_old(self, days: int = 90) -> dict[str, int]:
        """Wyczyść stare wpisy.

        Args:
            days: Usuń wpisy starsze niż N dni

        Returns:
            Dict z liczbą usuniętych wpisów.
        """
        cutoff = pendulum.now("UTC").subtract(days=days).isoformat()
        with self._engine.begin() as conn:
            removed_reminders = conn.execute(
                text("DELETE FROM reminders WHERE status != 'active' AND created_at < :cutoff"),
                {"cutoff": cutoff},
            ).rowcount

            removed_tasks = conn.execute(
                text("DELETE FROM scheduled_tasks WHERE is_active = 0 AND created_at < :cutoff"),
                {"cutoff": cutoff},
            ).rowcount

        if removed_reminders or removed_tasks:
            logger.info(
                "[Scheduler] cleaned %d reminders, %d tasks (>%d days)",
                removed_reminders,
                removed_tasks,
                days,
            )

        return {"reminders": removed_reminders, "tasks": removed_tasks}
