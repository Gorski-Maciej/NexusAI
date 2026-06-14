from __future__ import annotations

from pathlib import Path

from litestar import Controller, get

from nexus_ai.api.dto import K6SummaryDTO, TAG_SYSTEM
from nexus_ai.api.rbac import owner_only_guard
from nexus_ai.core.msgspec_utils import msgspec_loads


class PerformanceOpsController(Controller):
    """Operational performance engineering visibility."""

    path = "/system/performance"
    guards = [owner_only_guard]
    tags = [TAG_SYSTEM]

    @get(
        "/k6-summary",
        return_dto=K6SummaryDTO,
        summary="Get k6 performance summary",
        description="Returns the latest k6 load test performance summary including p95 latency and failure rate.",
        operation_id="getK6Summary",
    )
    async def k6_summary(self) -> dict:
        summary_path = Path("reports") / "performance" / "k6_summary.json"
        if not summary_path.exists():
            return {"status": "missing", "summary_available": False}
        try:
            payload = msgspec_loads(summary_path.read_bytes())
        except Exception:
            return {"status": "invalid", "summary_available": True}

        metrics = payload.get("metrics", {}) if isinstance(payload, dict) else {}
        p95 = ((metrics.get("http_req_duration") or {}).get("values") or {}).get("p(95)")
        fail_rate = ((metrics.get("checks") or {}).get("values") or {}).get("fails")
        return {
            "status": "ok",
            "summary_available": True,
            "p95_ms": float(p95) if p95 is not None else None,
            "check_failures": float(fail_rate) if fail_rate is not None else None,
            "raw": payload,
        }
