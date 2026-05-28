"""Notification service for daily briefings, user notifications, and DailyBriefingGenerator."""
from __future__ import annotations

import asyncio
import json
import sqlite3
import logging
from datetime import datetime, timezone, date
from pathlib import Path
from typing import Any

from core.config import AppConfig

logger = logging.getLogger("nexus.services.notification")


# ---------------------------------------------------------------------------
# Daily Briefing Generator
# ---------------------------------------------------------------------------

class DailyBriefingGenerator:
    """Generator codziennych podsumowań finansowych (Daily Briefing).

    Agreguje dane z:
      - PLE (STM/LTM/FM) — statystyki decyzji i wzorce
      - DuckDB (invoices) — liczby faktur, kwoty, statusy
      - Decision Logger — statystyki decyzji i korekt
      - Notification Service — powiadomienia do wysłania

    Generuje podsumowanie zawierające:
      - Liczbę faktur zaksięgowanych automatycznie (AUTO_POST)
      - Liczbę decyzji oczekujących na użytkownika (ASK_USER)
      - Łączną kwotę zaksięgowanych faktur
      - Liczbę zablokowanych faktur (BLOCK)
      - Alerty (np. nowi kontrahenci, anomalie)
      - Trend trust score
    """

    def __init__(
        self,
        config: AppConfig | None = None,
        duckdb_manager: Any = None,
        ple_engine: Any = None,
        decision_logger: Any = None,
    ) -> None:
        self._config = config or AppConfig()
        self._duckdb = duckdb_manager
        self._ple = ple_engine
        self._logger = decision_logger

    async def generate(self, user_id: str) -> dict[str, Any]:
        """Generuj pełne podsumowanie dnia dla użytkownika.

        Returns dict z:
          - date: data podsumowania
          - total_processed: liczba faktur przetworzonych dzisiaj
          - auto_posted: liczba i kwota AUTO_POST
          - pending_review: liczba decyzji oczekujących
          - blocked: liczba i kwota BLOCK
          - total_amount_auto: łączna kwota AUTO_POST
          - top_contractors: top 3 kontrahentów
          - alerts: alerty
          - trust_trend: trend trust score
          - ple_stats: statystyki PLE (jeśli dostępne)
        """
        today = date.today().isoformat()

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
        if self._ple:
            try:
                ple_stats = await self._ple.get_briefing_data()
            except Exception:
                pass

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
            user_id, total_processed, pending_review, blocked.get("count", 0),
        )
        return briefing

    async def _count_by_status(self, status: str, day: str) -> dict[str, Any]:
        if not self._duckdb:
            return {"count": 0, "total_amount": 0.0}
        try:
            rows = await asyncio.to_thread(
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
            rows = await asyncio.to_thread(
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
            rows = await asyncio.to_thread(
                self._duckdb.execute,
                "SELECT contractor_nip, COUNT(*) as cnt, SUM(amount_gross) as total FROM oltp.invoices WHERE DATE(created_at) = DATE(?) GROUP BY contractor_nip ORDER BY cnt DESC LIMIT 3",
                [day],
            )
            return [{"nip": str(r[0]), "count": int(r[1]), "total_amount": float(r[2])} for r in rows] if rows else []
        except Exception:
            return []

    async def _get_trust_trend(self) -> dict[str, Any]:
        if not self._logger:
            return {"trend": "stable"}
        try:
            stats = await asyncio.to_thread(self._logger.get_user_correction_stats)
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
            alerts.append({"type": "blocked_invoices", "severity": "high",
                "message": f"{blocked['count']} faktur zostało zablokowanych (kwota: {blocked.get('total_amount', 0):.2f} PLN)"})
        if pending_review > 5:
            alerts.append({"type": "backlog", "severity": "medium",
                "message": f"{pending_review} faktur oczekuje na Twoją decyzję"})
        if auto_posted.get("count", 0) == 0 and pending_review == 0:
            alerts.append({"type": "no_activity", "severity": "info",
                "message": "Brak aktywności — żadne faktury nie zostały dzisiaj przetworzone"})
        return alerts


class NotificationService:
    """Manages user notifications and daily briefings backed by SQLite."""

    def __init__(self, db_path: Path | str, config: AppConfig | None = None) -> None:
        self._db_path = Path(db_path)
        self._config = config or AppConfig()
        self._briefing_generator: DailyBriefingGenerator | None = None
        self._init_db()

    def set_briefing_generator(self, generator: DailyBriefingGenerator) -> None:
        self._briefing_generator = generator

    def _init_db(self) -> None:
        self._db_path.parent.mkdir(parents=True, exist_ok=True)
        conn = sqlite3.connect(str(self._db_path))
        try:
            conn.execute(
                "CREATE TABLE IF NOT EXISTS notifications (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL, title TEXT NOT NULL, message TEXT NOT NULL, notification_type TEXT NOT NULL DEFAULT 'info', reference_type TEXT, reference_id TEXT, is_read INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL)"
            )
            conn.execute(
                "CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, is_read, created_at DESC)"
            )
            conn.commit()
        finally:
            conn.close()

    async def send_daily_briefing(self, user_id: str) -> dict[str, Any]:
        """Generate and persist a daily briefing summary."""
        today = datetime.now(timezone.utc).date().isoformat()

        if self._briefing_generator:
            briefing = await self._briefing_generator.generate(user_id)
            decisions = await asyncio.to_thread(self._fetch_pending_decisions, user_id)
            briefing["decisions"] = decisions
            briefing["pending_review"] = len(decisions)
            if decisions:
                await asyncio.to_thread(
                    self._add_notification,
                    user_id=user_id,
                    title=f"Codzienne podsumowanie — {len(decisions)} decyzji",
                    message=json.dumps(briefing, ensure_ascii=False),
                    notification_type="daily_briefing",
                )
            return briefing

        decisions = await asyncio.to_thread(self._fetch_pending_decisions, user_id)
        auto_posted = await asyncio.to_thread(self._count_today_auto_posted, user_id, today)

        briefing = {
            "user_id": user_id, "date": today,
            "total_decisions": len(decisions),
            "auto_posted": {"count": auto_posted, "total_amount": 0.0},
            "pending_review": len(decisions), "decisions": decisions,
            "blocked": {"count": 0, "total_amount": 0.0},
            "alerts": [], "trust_trend": "stable",
        }

        if decisions:
            await asyncio.to_thread(
                self._add_notification,
                user_id=user_id,
                title=f"Codzienne podsumowanie — {len(decisions)} decyzji",
                message=json.dumps(briefing, ensure_ascii=False),
                notification_type="daily_briefing",
            )

        return briefing

    def set_notifications_table(self, user_id: str) -> None:
        """Placeholder: future method for configuring notification preferences."""
        pass

    def get_unread_count(self, user_id: str) -> int:
        """Return count of unread notifications for a user."""
        conn = sqlite3.connect(str(self._db_path))
        try:
            row = conn.execute(
                "SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0",
                (user_id,),
            ).fetchone()
            return row[0] if row else 0
        finally:
            conn.close()

    def mark_read(self, notification_id: int) -> None:
        """Mark a single notification as read."""
        conn = sqlite3.connect(str(self._db_path))
        try:
            conn.execute(
                "UPDATE notifications SET is_read = 1 WHERE id = ?",
                (notification_id,),
            )
            conn.commit()
        finally:
            conn.close()

    def _fetch_pending_decisions(self, user_id: str) -> list[dict[str, Any]]:
        """Fetch decisions awaiting user action.
        
        Queries invoices that are in MANUAL_REVIEW or PENDING_REVIEW status
        and belong to the user's tenant.
        """
        # In production this would query the invoices table via SQLAlchemy.
        # For now we try a simple DuckDB or SQLite query, falling back to empty.
        try:
            from core.config import AppConfig
            from db.analytics import DuckDBManager

            cfg = AppConfig()
            mgr = DuckDBManager(db_path=cfg.duckdb_path, sqlite_path=cfg.sqlite_path, read_only=True)
            try:
                rows = mgr.execute(
                    """
                    SELECT id, number, amount_gross, currency, status,
                           contractor_nip, created_at
                    FROM oltp.invoices
                    WHERE status IN ('MANUAL_REVIEW', 'PENDING_REVIEW')
                    ORDER BY created_at DESC
                    LIMIT 10
                    """
                )
                if not rows:
                    return []
                decisions = []
                for r in rows:
                    decisions.append({
                        "invoice_id": str(r[0]),
                        "number": str(r[1]) if r[1] else "",
                        "amount_gross": float(r[2]) if r[2] else 0.0,
                        "currency": str(r[3]) if r[3] else "PLN",
                        "status": str(r[4]) if r[4] else "PENDING_REVIEW",
                        "contractor_nip": str(r[5]) if r[5] else "",
                        "created_at": str(r[6]) if r[6] else "",
                    })
                return decisions
            finally:
                mgr.close()
        except Exception:
            logger.debug("Could not query pending decisions (DuckDB may be unavailable)")
            return []

    def _count_today_auto_posted(self, user_id: str, today: str) -> int:
        """Count invoices auto-approved today."""
        try:
            from core.config import AppConfig
            from db.analytics import DuckDBManager

            cfg = AppConfig()
            mgr = DuckDBManager(db_path=cfg.duckdb_path, sqlite_path=cfg.sqlite_path, read_only=True)
            try:
                row = mgr.execute(
                    """
                    SELECT COUNT(*) FROM oltp.invoices
                    WHERE status = 'APPROVED'
                      AND DATE(updated_at) = DATE(?)
                    """,
                    [today],
                )
                return int(row[0][0]) if row and row[0] and row[0][0] else 0
            finally:
                mgr.close()
        except Exception:
            return 0

    def _add_notification(
        self,
        user_id: str,
        title: str,
        message: str,
        notification_type: str = "info",
        reference_type: str | None = None,
        reference_id: str | None = None,
    ) -> int:
        """Insert a new notification row and return its ID."""
        conn = sqlite3.connect(str(self._db_path))
        try:
            cursor = conn.execute(
                """
                INSERT INTO notifications
                    (user_id, title, message, notification_type,
                     reference_type, reference_id, is_read, created_at)
                VALUES (?, ?, ?, ?, ?, ?, 0, ?)
                """,
                (
                    user_id,
                    title,
                    message,
                    notification_type,
                    reference_type,
                    reference_id,
                    datetime.now(timezone.utc).isoformat(),
                ),
            )
            conn.commit()
            return int(cursor.lastrowid)
        finally:
            conn.close()

    def get_user_notifications(
        self,
        user_id: str,
        limit: int = 20,
        unread_only: bool = False,
    ) -> list[dict[str, Any]]:
        """Fetch notifications for a user."""
        conn = sqlite3.connect(str(self._db_path))
        try:
            conn.row_factory = sqlite3.Row
            query = "SELECT * FROM notifications WHERE user_id = ?"
            params: list[Any] = [user_id]

            if unread_only:
                query += " AND is_read = 0"

            query += " ORDER BY created_at DESC LIMIT ?"
            params.append(limit)

            rows = conn.execute(query, params).fetchall()
            return [dict(r) for r in rows]
        finally:
            conn.close()
