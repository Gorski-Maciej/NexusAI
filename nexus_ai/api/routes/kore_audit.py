from __future__ import annotations

import importlib.util
from pathlib import Path

from litestar import Controller, get
from litestar.exceptions import InternalServerException

from nexus_ai.api.rbac import owner_only_guard


class KoreAuditController(Controller):
    """Operational endpoint exposing KORE 1-11 compliance audit report."""

    path = "/api/v1/system/kore"
    guards = [owner_only_guard]

    @get("/audit")
    async def get_kore_audit(self) -> dict:
        root = Path(__file__).resolve().parents[3]  # project root
        script_path = root / "nexus_ai" / "scripts" / "kore_delivery_audit.py"
        spec = importlib.util.spec_from_file_location("kore_delivery_audit", script_path)
        if not spec or not spec.loader:
            raise InternalServerException("Unable to load KORE audit script")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        report = module.build_report()
        return report
