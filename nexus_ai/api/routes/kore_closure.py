from __future__ import annotations

import importlib.util
from pathlib import Path

from litestar import Controller, get
from litestar.connection import Request
from sqlmodel import text

from nexus_ai.api.dto import TAG_AUDIT, KoreClosureDTO
from nexus_ai.api.rbac import owner_only_guard
from nexus_ai.core.msgspec_utils import msgspec_loads


class KoreClosureController(Controller):
    """Single endpoint with executable closure summary for KORE 1-11."""

    path = "/system/kore"
    guards = [owner_only_guard]
    tags = [TAG_AUDIT]

    @get(
        "/closure",
        return_dto=KoreClosureDTO,
        summary="Get KORE closure summary",
        description="Returns executable closure summary for KORE 1-11 compliance, including security summary and runtime counters.",
        operation_id="getKoreClosure",
    )
    async def closure_summary(self, request: Request) -> dict:
        _root_prj = Path(__file__).resolve().parents[3]  # project root

        def _run_script(module_name: str, relative_path: str, method: str = "build_report"):
            script_path = _root_prj / relative_path
            spec = importlib.util.spec_from_file_location(module_name, script_path)
            if not spec or not spec.loader:
                return {"status": "error", "detail": f"unable_to_load:{relative_path}"}
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)
            fn = getattr(mod, method, None)
            if not callable(fn):
                return {"status": "error", "detail": f"missing_method:{method}"}
            try:
                return fn()
            except Exception as exc:
                return {"status": "error", "detail": str(exc)}

        # kore_delivery_audit.py removed -- legacy, functionality absorbed by Integrity Verifier
        kore_audit = {
            "status": "removed",
            "detail": "kore_delivery_audit.py removed -- replaced by Integrity Verifier",
        }
        summary_path = _root_prj / "reports" / "security_scan_summary.json"
        if summary_path.exists():
            security_summary = msgspec_loads(summary_path.read_bytes())
        else:
            security_summary = {
                "status": "missing",
                "detail": "reports/security_scan_summary.json not found",
            }

        db_engine = request.app.state.db_engine
        async with db_engine.begin() as conn:

            async def _count(table_name: str) -> int:
                try:
                    return int(
                        (
                            await conn.execute(text(f"SELECT COUNT(1) FROM {table_name}"))
                        ).scalar_one()
                    )
                except Exception:
                    return 0

            users_count = await _count("users")
            drafts_count = await _count("ui_drafts")
            saga_count = await _count("workflow_saga_state")

        severity_ok = True
        if isinstance(security_summary, dict) and "severity_gate_rc" in security_summary:
            severity_ok = int(security_summary.get("severity_gate_rc", 1)) == 0
        overall_ok = bool(kore_audit.get("overall_ok", False)) and severity_ok

        return {
            "status": "ok" if overall_ok else "warning",
            "kore_audit": kore_audit,
            "security_summary": security_summary,
            "runtime_counters": {
                "users": users_count,
                "ui_drafts": drafts_count,
                "active_sagas": saga_count,
            },
        }
