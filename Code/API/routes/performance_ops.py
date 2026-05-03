from __future__ import annotations

import json
from pathlib import Path

from litestar import Controller, get

from api.rbac import owner_only_guard


class PerformanceOpsController(Controller):
    """Operational performance engineering visibility."""

    path = "/api/v1/system/performance"
    guards = [owner_only_guard]

    @get("/k6-summary")
    async def k6_summary(self) -> dict:
        summary_path = Path("reports") / "performance" / "k6_summary.json"
        if not summary_path.exists():
            return {"status": "missing", "summary_available": False}
        try:
            payload = json.loads(summary_path.read_text(encoding="utf-8"))
        except Exception:
            return {"status": "invalid", "summary_available": True}

        metrics = payload.get("metrics", {}) if isinstance(payload, dict) else {}
        p95 = (((metrics.get("http_req_duration") or {}).get("values") or {}).get("p(95)"))
        fail_rate = (((metrics.get("checks") or {}).get("values") or {}).get("fails"))
        return {
            "status": "ok",
            "summary_available": True,
            "p95_ms": float(p95) if p95 is not None else None,
            "check_failures": float(fail_rate) if fail_rate is not None else None,
            "raw": payload,
        }
