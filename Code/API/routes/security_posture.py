from __future__ import annotations

import json
from pathlib import Path

from litestar import Controller, get

from api.rbac import owner_only_guard


class SecurityPostureController(Controller):
    """Operational read-only security posture summary endpoint."""

    path = "/api/v1/system/security"
    guards = [owner_only_guard]

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
            payload["scan_summary"] = json.loads(summary_file.read_text(encoding="utf-8"))
        return payload
