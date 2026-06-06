from __future__ import annotations

from litestar import Controller, get

from api.rbac import owner_only_guard
from core.config import AppConfig
from services.log_pii_monitor import notify_dpo, scan_logs_for_pii


class PrivacyController(Controller):
    """Operational privacy controls (PII leak scans)."""

    path = "/api/v1/system/privacy"
    guards = [owner_only_guard]

    @get("/pii-scan")
    async def scan_pii_logs(self) -> dict:
        config = AppConfig()
        findings = scan_logs_for_pii(config.base_dir / "app_data" / "logs")
        total = int(sum(findings.values()))
        notified = False
        if total > 0:
            notified = notify_dpo(config.dpo_alert_webhook, findings)
        return {"status": "ok", "findings": findings, "total_matches": total, "dpo_notified": bool(notified)}
