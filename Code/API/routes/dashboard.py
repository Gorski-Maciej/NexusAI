"""Dashboard API endpoints — daily briefing and summary statistics."""
from __future__ import annotations

from typing import Any
from litestar import Controller, get
from litestar.connection import Request

from core.config import AppConfig
from services.notification_service import NotificationService


class DashboardController(Controller):
    """Dashboard endpoints for the daily briefing and summary stats."""

    path = "/api/v2/dashboard"

    @get("/briefing")
    async def get_daily_briefing(self, request: Request, config: AppConfig) -> dict[str, Any]:
        """Return today's briefing: top 1-3 decisions needing user action.

        Returns:
          {
            "date": "2026-05-28",
            "total_decisions": 2,
            "auto_posted": 15,
            "pending_review": 2,
            "message": "Dzień dobry! Masz 2 decyzje do podjęcia",
            "decisions": [
              {
                "invoice_id": "...",
                "contractor": "Firma XYZ",
                "amount_gross": 1234.56,
                "currency": "PLN",
                "reason": "Kwota powyżej progu automatycznego zatwierdzenia",
                "status": "PENDING_REVIEW"
              }
            ]
          }
        """
        user_id = self._resolve_user_id(request)

        notif_db = config.base_dir / "app_data" / "notifications.sqlite"
        service = NotificationService(notif_db)
        briefing = service.send_daily_briefing(user_id)

        decisions = briefing.get("decisions", [])
        count = len(decisions)

        if count == 0:
            briefing["message"] = "Wszystko zaksięgowane automatycznie ✅"
        else:
            briefing["message"] = f"Dzień dobry! Masz {count} decyzji do podjęcia"

        # Limit to 3 most important decisions
        briefing["decisions"] = decisions[:3]
        return briefing

    @get("/summary")
    async def get_dashboard_summary(self, config: AppConfig) -> dict[str, Any]:
        """Return dashboard summary statistics.

        Returns:
          {
            "booked_today": 12,
            "pending_approval": 3,
            "pending_review": 2,
            "total_invoices": 150,
            "auto_approval_rate": 0.85,
            "total_gross_today": 45230.00,
            "currency": "PLN"
          }
        """
        summary = {
            "booked_today": 0,
            "pending_approval": 0,
            "pending_review": 0,
            "total_invoices": 0,
            "auto_approval_rate": 0.0,
            "total_gross_today": 0.0,
            "currency": "PLN",
        }

        try:
            from db.analytics import DuckDBManager

            mgr = DuckDBManager(
                db_path=config.duckdb_path,
                sqlite_path=config.sqlite_path,
                read_only=True,
            )
            try:
                today = "CURRENT_DATE"

                # Booked today
                row = mgr.execute(
                    f"""
                    SELECT COUNT(*), COALESCE(SUM(amount_gross), 0)
                    FROM oltp.invoices
                    WHERE status IN ('APPROVED', 'PAID')
                      AND DATE(updated_at) = {today}
                    """
                )
                if row and row[0]:
                    summary["booked_today"] = int(row[0][0]) if row[0][0] else 0
                    summary["total_gross_today"] = float(row[0][1]) if row[0][1] else 0.0

                # Pending approval
                row = mgr.execute(
                    """
                    SELECT COUNT(*) FROM oltp.invoices
                    WHERE status IN ('NEW', 'PROCESSING')
                    """
                )
                if row and row[0] and row[0][0]:
                    summary["pending_approval"] = int(row[0][0])

                # Pending review
                row = mgr.execute(
                    """
                    SELECT COUNT(*) FROM oltp.invoices
                    WHERE status IN ('MANUAL_REVIEW', 'PENDING_REVIEW')
                    """
                )
                if row and row[0] and row[0][0]:
                    summary["pending_review"] = int(row[0][0])

                # Total
                row = mgr.execute("SELECT COUNT(*) FROM oltp.invoices")
                if row and row[0] and row[0][0]:
                    summary["total_invoices"] = int(row[0][0])

                # Auto-approval rate (last 7 days)
                row = mgr.execute(
                    f"""
                    SELECT
                        COUNT(*) FILTER (WHERE status IN ('APPROVED', 'PAID')) * 1.0 /
                        NULLIF(COUNT(*), 0)
                    FROM oltp.invoices
                    WHERE DATE(updated_at) >= {today} - INTERVAL '7 days'
                    """
                )
                if row and row[0] and row[0][0]:
                    summary["auto_approval_rate"] = round(float(row[0][0]), 4)

            finally:
                mgr.close()
        except Exception:
            pass

        return summary

    def _resolve_user_id(self, request: Request) -> str:
        """Extract user identifier from JWT claims via Litestar auth."""
        try:
            auth = getattr(request, "auth", None)
            if auth is not None:
                sub = getattr(auth, "claims", {}).get("sub", None) or getattr(auth, "username", None)
                if sub:
                    return str(sub)
        except Exception:
            pass
        return "anonymous"
