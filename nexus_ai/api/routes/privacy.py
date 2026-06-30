from __future__ import annotations

from litestar import Controller, get

from nexus_ai.api.dto import TAG_PRIVACY, PiiScanDTO
from nexus_ai.api.rbac import owner_only_guard
from nexus_ai.core.config import AppConfig
from nexus_ai.services.log_pii_monitor import notify_dpo, scan_logs_for_pii


class PrivacyController(Controller):
    """Operational privacy controls (PII leak scans)."""

    path = "/system/privacy"
    guards = [owner_only_guard]
    tags = [TAG_PRIVACY]

    @get(
        "/pii-scan",
        return_dto=PiiScanDTO,
        summary="Scan logs for PII",
        description="Scans application logs for potential PII leaks and notifies the DPO if findings are detected.",
        operation_id="scanPiiLogs",
    )
    async def scan_pii_logs(self) -> dict:
        config = AppConfig()
        findings = scan_logs_for_pii(config.base_dir / "app_data" / "logs")
        total = int(sum(findings.values()))
        notified = False
        if total > 0:
            notified = notify_dpo(config.dpo_alert_webhook, findings)
        return {
            "status": "ok",
            "findings": findings,
            "total_matches": total,
            "dpo_notified": bool(notified),
        }
