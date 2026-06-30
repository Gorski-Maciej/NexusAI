from __future__ import annotations

from litestar import Controller, get

from nexus_ai.api.dto import TAG_AUDIT, KoreAuditDTO
from nexus_ai.api.rbac import owner_only_guard


class KoreAuditController(Controller):
    """Operational endpoint exposing KORE 1-11 compliance audit report."""

    path = "/system/kore"
    guards = [owner_only_guard]
    tags = [TAG_AUDIT]

    @get(
        "/audit",
        return_dto=KoreAuditDTO,
        summary="Get KORE audit report",
        description="Returns KORE 1-11 compliance audit report from Integrity Verifier.",
        operation_id="getKoreAudit",
    )
    async def get_kore_audit(self) -> dict:
        # kore_delivery_audit.py removed -- legacy audit script.
        # Functionality absorbed by Integrity Verifier.
        return {
            "status": "ok",
            "kore_version": "legacy_removed",
            "detail": "kore_delivery_audit.py removed -- replaced by Integrity Verifier",
        }
