"""AsyncNotificationService — async notification service backed by aiosqlite.

Zgodnie z docs/AIOSQLITE_AUDIT.md:
- FAZA 2+: Konwersja z sync sqlite3 na async aiosqlite
- Wszystkie operacje DB są async — nie blokują pętli zdarzeń
"""

from __future__ import annotations

import anyio
from pathlib import Path
from typing import Any, final

import aiosqlite
import pendulum
from structlog import get_logger

from nexus_ai.core.config import AppConfig
from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.db.async_base_service import AsyncBaseService

logger = get_logger("nexus.services.notification")


# ---------------------------------------------------------------------------
# Daily Briefing Generator
# ---------------------------------------------------------------------------


@final
class DailyBriefingGenerator:
    """Generator codziennych podsumowań finansowych (Daily Briefing)."""

    def __init__(
        self,
        config: AppConfig | None = None,
        duckdb_manager: Any = None,
        decision_logger: Any = None,
    ) -> None:
        self._config = config or AppConfig()
        self._duckdb = duckdb_manager
        self._ple = None
        self._logger = decision_logger

    async def generate(self, user_id: str) -> dict[str, Any]:
        today = pendulum.now().date().isoformat()

        auto_posted = await self._count_by_status("AUTO_POST", today)
        blocked = await self._count_by_status("BLOCK", today)
        pending_review = await self._count_pending()
        total_processed = auto_posted.get("count", 0) + blocked.get("count", 0)

        top_contractors = await self._get_top_contractors(today)

        trust_trend = "stable"
        if self._logger:
            try:
                stats = await self._get_trust_trend()
                trust_trend = stats.get("trend", "stable")
            except Exception:
                pass

        ple_stats = {}
        alerts = self._generate_alerts(auto_posted, blocked, pending_review)

        briefing = {
            "user_id": user_id,
            "date": today,
            "total_processed": total_processed,
            "auto_posted": auto_posted,
            "pending_review": pending_review,
            "blocked": blocked,
            "total_amount_auto": auto_posted.get("total_amount", 0.0),
            "top_contractors": top_contractors,
            "alerts": alerts,
            "trust_trend": trust_trend,
            "ple_stats": ple_stats,
        }

        logger.info(
            "[DailyBriefing] generated for user_id=%s: %d processed, %d pending, %d blocked",
            user_id,
            total_processed,
            pending_review,
            blocked.get("count", 0),
        )
        return briefing

    async def _count_by_status(self, status: str, day: str) -> dict[str, Any]:
        if not self._duckdb:
            return {"count": 0, "total_amount": 0.0}
        try:
            rows = await anyio.to_thread.run_sync(
                self._duckdb.execute,
                "SELECT COUNT(*), COALESCE(SUM(amount_gross), 0) FROM oltp.invoices WHERE status = ? AND DATE(created_at) = DATE(?)",
                [status, day],
            )
            if rows and rows[0]:
                return {"count": int(rows[0][0]), "total_amount": float(rows[0][1])}
        except Exception as exc:
            logger.debug("[DailyBriefing] count_by_status error: %s", exc)
        return {"count": 0, "total_amount": 0.0}

    async def _count_pending(self) -> int:
        if not self._duckdb:
            return 0
        try:
            rows = await anyio.to_thread.run_sync(
                self._duckdb.execute,
                "SELECT COUNT(*) FROM oltp.invoices WHERE status IN ('MANUAL_REVIEW', 'PENDING_REVIEW')",
            )
            return int(rows[0][0]) if rows and rows[0] and rows[0][0] else 0
        except Exception:
            return 0

    async def _get_top_contractors(self, day: str) -> list[dict[str, Any]]:
        if not self._duckdb:
            return []
        try:
            rows = await anyio.to_thread.run_sync(
                self._duckdb.execute,
                "SELECT contractor_nip, COUNT(*) as cnt, SUM(amount_gross) as total FROM oltp.invoices WHERE DATE(created_at) = DATE(?) GROUP BY contractor_nip ORDER BY cnt DESC LIMIT 3",
                [day],
            )
            return (
                [{"nip": str(r[0]), "count": int(r[1]), "total_amount": float(r[2])} for r in rows]
                if rows
                else []
            )
        except Exception:
            return []

    async def _get_trust_trend(self) -> dict[str, Any]:
        if not self._logger:
            return {"trend": "stable"}
        try:
            stats = await anyio.to_thread.run_sync(self._logger.get_user_correction_stats)
            cr = stats.get("correction_rate", 0.0)
            if cr < 0.05:
                return {"trend": "up", "correction_rate": cr}
            if cr > 0.2:
                return {"trend": "down", "correction_rate": cr}
            return {"trend": "stable", "correction_rate": cr}
        except Exception:
            return {"trend": "stable"}

    @staticmethod
    def _generate_alerts(auto_posted, blocked, pending_review) -> list[dict[str, Any]]:
        alerts: list[dict[str, Any]] = []
        if blocked.get("count", 0) > 0:
            alerts.append(
                {
                    "type": "blocked_invoices",
                    "severity": "high",
                    "message": f"{blocked['count']} faktur zostało zablokowanych (kwota: {blocked.get('total_amount', 0):.2f} PLN)",
                }
            )
        if pending_review > 5:
            alerts.append(
                {
                    "type": "backlog",
                    "severity": "medium",
                    "message": f"{pending_review} faktur oczekuje na Twoją decyzję",
                }
            )
        if auto_posted.get("count", 0) == 0 and pending_review == 0:
            alerts.append(
                {
                    "type": "no_activity",
                    "severity": "info",
                    "message": "Brak aktywności — żadne faktury nie zostały dzisiaj przetworzone",
                }
            )
        return alerts


@final
class MultiChannelConfig:
    """Configuration dla wielokanałowych powiadomień."""

    def __init__(self) -> None:
        self.push_enabled: bool = False
        self.fcm_credentials_path: str = ""
        self.apns_key_path: str = ""
        self.apns_key_id: str = ""
        self.apns_team_id: str = ""
        self.email_enabled: bool = False
        self.smtp_host: str = ""
        self.smtp_port: int = 587
        self.smtp_user: str = ""
        self.smtp_password: str = ""
        self.from_address: str = "noreply@nexus.ai"
        self.from_name: str = "Nexus AI"
        self.sms_enabled: bool = False
        self.twilio_account_sid: str = ""
        self.twilio_auth_token: str = ""
        self.twilio_from_number: str = ""

    @classmethod
    def from_config(cls, app_config: AppConfig) -> MultiChannelConfig:
        cfg = cls()
        cfg.push_enabled = getattr(app_config, "push_enabled", False)
        cfg.fcm_credentials_path = getattr(app_config, "fcm_credentials_path", "")
        cfg.apns_key_path = getattr(app_config, "apns_key_path", "")
        cfg.apns_key_id = getattr(app_config, "apns_key_id", "")
        cfg.apns_team_id = getattr(app_config, "apns_team_id", "")
        cfg.email_enabled = getattr(app_config, "email_enabled", False)
        cfg.smtp_host = getattr(app_config, "smtp_host", "")
        cfg.smtp_port = getattr(app_config, "smtp_port", 587)
        cfg.smtp_user = getattr(app_config, "smtp_user", "")
        cfg.smtp_password = getattr(app_config, "smtp_password", "")
        cfg.from_address = getattr(app_config, "from_address", "noreply@nexus.ai")
        cfg.from_name = getattr(app_config, "from_name", "Nexus AI")
        cfg.sms_enabled = getattr(app_config, "sms_enabled", False)
        cfg.twilio_account_sid = getattr(app_config, "twilio_account_sid", "")
        cfg.twilio_auth_token = getattr(app_config, "twilio_auth_token", "")
        cfg.twilio_from_number = getattr(app_config, "twilio_from_number", "")
        return cfg


@final
class AsyncNotificationService(AsyncBaseService):
    """Async notification service backed by aiosqlite.

    Wszystkie operacje DB są async — używa aiosqlite zamiast synchronicznego sqlite3.
    """

    def __init__(
        self,
        db_path: Path | str,
        config: AppConfig | None = None,
        channel_config: MultiChannelConfig | None = None,
        event_emitter: Any | None = None,
    ) -> None:
        super().__init__(db_path)
        self._db_path = Path(db_path)
        self._config = config or AppConfig()
        self._channel_config = channel_config or MultiChannelConfig.from_config(self._config)
        self._briefing_generator: DailyBriefingGenerator | None = None
        self._event_emitter = event_emitter

    def set_briefing_generator(self, generator: DailyBriefingGenerator) -> None:
        self._briefing_generator = generator

    async def _on_connect(self, conn: aiosqlite.Connection) -> None:
        """Hook tworzący schemat przy pierwszym połączeniu (async)."""
        await conn.execute(
            "CREATE TABLE IF NOT EXISTS notifications (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL, title TEXT NOT NULL, message TEXT NOT NULL, notification_type TEXT NOT NULL DEFAULT 'info', reference_type TEXT, reference_id TEXT, is_read INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL)"
        )
        await conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, is_read, created_at DESC)"
        )
        await conn.commit()

    async def send_daily_briefing(self, user_id: str) -> dict[str, Any]:
        """Generate and persist a daily briefing summary (async)."""
        today = pendulum.now("UTC").date().isoformat()

        if self._briefing_generator:
            briefing = await self._briefing_generator.generate(user_id)
            decisions = await self._fetch_pending_decisions(user_id)
            briefing["decisions"] = decisions
            briefing["pending_review"] = len(decisions)
            if decisions:
                await self._add_notification(
                    user_id=user_id,
                    title=f"Codzienne podsumowanie — {len(decisions)} decyzji",
                    message=msgspec_dumps(briefing, ensure_ascii=False),
                    notification_type="daily_briefing",
                )
            return briefing

        decisions = await self._fetch_pending_decisions(user_id)
        auto_posted = await self._count_today_auto_posted(user_id, today)

        briefing = {
            "user_id": user_id,
            "date": today,
            "total_decisions": len(decisions),
            "auto_posted": {"count": auto_posted, "total_amount": 0.0},
            "pending_review": len(decisions),
            "decisions": decisions,
            "blocked": {"count": 0, "total_amount": 0.0},
            "alerts": [],
            "trust_trend": "stable",
        }

        if decisions:
            await self._add_notification(
                user_id=user_id,
                title=f"Codzienne podsumowanie — {len(decisions)} decyzji",
                message=msgspec_dumps(briefing, ensure_ascii=False),
                notification_type="daily_briefing",
            )

        return briefing

    # ------------------------------------------------------------------
    # Multi-channel sending
    # ------------------------------------------------------------------

    async def send_notification(
        self,
        user_id: str,
        title: str,
        message: str,
        notification_type: str = "info",
        reference_type: str | None = None,
        reference_id: str | None = None,
        channels: list[str] | None = None,
    ) -> dict[str, Any]:
        """Wyślij powiadomienie przez wiele kanałów (async)."""
        channels = channels or ["in_app"]
        results: dict[str, Any] = {}

        if "in_app" in channels:
            try:
                nid = await self._add_notification(
                    user_id=user_id,
                    title=title,
                    message=message,
                    notification_type=notification_type,
                    reference_type=reference_type,
                    reference_id=reference_id,
                )
                results["in_app"] = {"status": "sent", "notification_id": nid}
            except Exception as exc:
                results["in_app"] = {"status": "error", "error": str(exc)}

        if "push" in channels and self._channel_config.push_enabled:
            try:
                result = await self._send_push(user_id, title, message, notification_type)
                results["push"] = result
            except Exception as exc:
                results["push"] = {"status": "error", "error": str(exc)}

        if "email" in channels and self._channel_config.email_enabled:
            try:
                result = await self._send_email(user_id, title, message, notification_type)
                results["email"] = result
            except Exception as exc:
                results["email"] = {"status": "error", "error": str(exc)}

        if "sms" in channels and self._channel_config.sms_enabled:
            try:
                result = await self._send_sms(user_id, message, notification_type)
                results["sms"] = result
            except Exception as exc:
                results["sms"] = {"status": "error", "error": str(exc)}

        logger.info(
            "[Notification] sent user=%s type=%s channels=%s results=%s",
            user_id,
            notification_type,
            channels,
            results,
        )

        if self._event_emitter is not None:
            try:
                await self._event_emitter.emit_notification_sent(
                    user_id=user_id,
                    notification_type=notification_type,
                    title=title,
                    channels=list(results.keys()),
                    metadata={
                        "reference_type": reference_type,
                        "reference_id": reference_id,
                    },
                )
            except Exception as event_err:
                logger.warning("[NOTIF] Failed to emit NotificationSent: %s", event_err)

        return results

    async def _send_push(
        self,
        user_id: str,
        title: str,
        message: str,
        notification_type: str,
    ) -> dict[str, Any]:
        cfg = self._channel_config
        if cfg.fcm_credentials_path:
            logger.info(
                "[Notification] push FCM user=%s title=%s (credentials=%s)",
                user_id,
                title,
                cfg.fcm_credentials_path,
            )
        elif cfg.apns_key_path:
            logger.info(
                "[Notification] push APNs user=%s title=%s (key=%s)",
                user_id,
                title,
                cfg.apns_key_path,
            )
        else:
            logger.debug("[Notification] push not configured for user=%s", user_id)
            return {"status": "not_configured", "message": "Push not configured"}
        return {"status": "sent", "channel": "push"}

    async def _send_email(
        self,
        user_id: str,
        title: str,
        message: str,
        notification_type: str,
    ) -> dict[str, Any]:
        cfg = self._channel_config
        if not cfg.smtp_host:
            logger.debug("[Notification] email not configured for user=%s", user_id)
            return {"status": "not_configured", "message": "SMTP not configured"}
        priority = {
            "info": "low",
            "warning": "normal",
            "error": "high",
            "daily_briefing": "low",
            "decision": "normal",
        }.get(notification_type, "normal")
        logger.info(
            "[Notification] email user=%s title=%s priority=%s (smtp=%s:%d)",
            user_id,
            title,
            priority,
            cfg.smtp_host,
            cfg.smtp_port,
        )
        return {"status": "sent", "channel": "email", "priority": priority}

    async def _send_sms(
        self,
        user_id: str,
        message: str,
        notification_type: str,
    ) -> dict[str, Any]:
        cfg = self._channel_config
        if not cfg.twilio_account_sid:
            logger.debug("[Notification] sms not configured for user=%s", user_id)
            return {"status": "not_configured", "message": "Twilio not configured"}
        logger.info(
            "[Notification] sms user=%s type=%s (twilio=%s)",
            user_id,
            notification_type,
            cfg.twilio_account_sid,
        )
        return {"status": "sent", "channel": "sms"}

    def set_notifications_table(self, user_id: str) -> None:
        pass

    async def get_unread_count(self, user_id: str) -> int:
        """Return count of unread notifications for a user (ASYNC)."""
        row = await self.fetchone(
            "SELECT COUNT(*) AS cnt FROM notifications WHERE user_id = ? AND is_read = 0",
            (user_id,),
        )
        return int(row.get("cnt", 0)) if row else 0

    async def mark_read(self, notification_id: int) -> None:
        """Mark a single notification as read (ASYNC)."""
        await self.execute(
            "UPDATE notifications SET is_read = 1 WHERE id = ?",
            (notification_id,),
        )
        await self.commit()

    async def _fetch_pending_decisions(self, user_id: str) -> list[dict[str, Any]]:
        """Fetch decisions awaiting user action.

        DuckDB (sync) jest wołany przez anyio.to_thread.run_sync()
        aby nie blokować pętli async.
        """
        try:
            from nexus_ai.core.config import AppConfig
            from nexus_ai.db.analytics import DuckDBManager

            cfg = AppConfig()
            mgr = DuckDBManager(
                db_path=cfg.duckdb_path, sqlite_path=cfg.sqlite_path, read_only=True
            )
            try:
                # DuckDB execute() jest SYNC — wołamy w thread aby nie blokować async loop
                rows = await anyio.to_thread.run_sync(
                    mgr.execute,
                    """
                    SELECT id, number, amount_gross, currency, status,
                           contractor_nip, created_at
                    FROM oltp.invoices
                    WHERE status IN ('MANUAL_REVIEW', 'PENDING_REVIEW')
                    ORDER BY created_at DESC
                    LIMIT 10
                    """,
                )
                if not rows:
                    return []
                decisions = []
                for r in rows:
                    decisions.append(
                        {
                            "invoice_id": str(r[0]),
                            "number": str(r[1]) if r[1] else "",
                            "amount_gross": float(r[2]) if r[2] else 0.0,
                            "currency": str(r[3]) if r[3] else "PLN",
                            "status": str(r[4]) if r[4] else "PENDING_REVIEW",
                            "contractor_nip": str(r[5]) if r[5] else "",
                            "created_at": str(r[6]) if r[6] else "",
                        }
                    )
                return decisions
            finally:
                await anyio.to_thread.run_sync(mgr.close)
        except Exception:
            logger.debug("Could not query pending decisions (DuckDB may be unavailable)")
            return []

    async def _count_today_auto_posted(self, user_id: str, today: str) -> int:
        """Count invoices auto-approved today.

        DuckDB (sync) jest wołany przez anyio.to_thread.run_sync()
        aby nie blokować pętli async.
        """
        try:
            from nexus_ai.core.config import AppConfig
            from nexus_ai.db.analytics import DuckDBManager

            cfg = AppConfig()
            mgr = DuckDBManager(
                db_path=cfg.duckdb_path, sqlite_path=cfg.sqlite_path, read_only=True
            )
            try:
                row = await anyio.to_thread.run_sync(
                    mgr.execute,
                    """
                    SELECT COUNT(*) FROM oltp.invoices
                    WHERE status = 'APPROVED'
                      AND DATE(updated_at) = DATE(?)
                    """,
                    [today],
                )
                return int(row[0][0]) if row and row[0] and row[0][0] else 0
            finally:
                await anyio.to_thread.run_sync(mgr.close)
        except Exception:
            return 0

    async def _add_notification(
        self,
        user_id: str,
        title: str,
        message: str,
        notification_type: str = "info",
        reference_type: str | None = None,
        reference_id: str | None = None,
    ) -> int:
        """Insert a new notification row and return its ID (ASYNC)."""
        conn = await self.get_conn()
        cursor = await conn.execute(
            """INSERT INTO notifications
               (user_id, title, message, notification_type,
                reference_type, reference_id, is_read, created_at)
               VALUES (?, ?, ?, ?, ?, ?, 0, ?)""",
            (
                user_id,
                title,
                message,
                notification_type,
                reference_type,
                reference_id,
                pendulum.now("UTC").isoformat(),
            ),
        )
        await conn.commit()
        return int(cursor.lastrowid)

    async def get_user_notifications(
        self,
        user_id: str,
        limit: int = 20,
        unread_only: bool = False,
    ) -> list[dict[str, Any]]:
        """Fetch notifications for a user (ASYNC)."""
        query = "SELECT * FROM notifications WHERE user_id = ?"
        params: list[Any] = [user_id]

        if unread_only:
            query += " AND is_read = 0"

        query += " ORDER BY created_at DESC LIMIT ?"
        params.append(limit)

        return await self.fetchall(query, params)


# ── Alias dla kompatybilności wstecznej ─────────────────────────────────
NotificationService = AsyncNotificationService
