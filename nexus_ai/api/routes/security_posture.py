from __future__ import annotations

from pathlib import Path

from litestar import Controller, get

from nexus_ai.api.rbac import owner_only_guard
from nexus_ai.core.msgspec_utils import msgspec_loads


class SecurityPostureController(Controller):
    """Operational read-only security posture summary endpoint."""

    path = "/api/v1/system/security"
    guards = [owner_only_guard]
    tags = ["Security"]

    @get("/summary")
    async def summary(self) -> dict:
        reports = Path("reports")
        summary_file = reports / "security_scan_summary.json"
        zap_baseline = reports / "zap_baseline.json"
        zap_full = reports / "zap_full.json"

        payload: dict = {
            "summary_available": summary_file.exists(),
            "zap_baseline_available": zap_baseline.exists(),
            "zap_full_available": zap_full.exists(),
        }

        if summary_file.exists():
            payload["scan_summary"] = msgspec_loads(summary_file.read_bytes())
        return payload
