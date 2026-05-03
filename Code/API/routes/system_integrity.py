from __future__ import annotations

from litestar import Controller, get

from api.rbac import owner_only_guard
from core.config import AppConfig
from db.database import create_oltp_engine
from services.migration_sanity import (
    run_migration_sanity_checks,
    verify_migration_integrity,
    verify_migration_checksums,
)


class SystemIntegrityController(Controller):
    """On-demand production integrity checks for migrations and schema."""

    path = "/api/v1/system/integrity"
    guards = [owner_only_guard]

    @get("/migration")
    async def migration_integrity(self) -> dict:
        config = AppConfig()
        engine = create_oltp_engine(config)
        try:
            sanity = await run_migration_sanity_checks(engine)
            rowcount = await verify_migration_integrity(engine, config.migration_baseline_path)
            checksums = await verify_migration_checksums(engine, config.migration_checksum_baseline_path)
            return {
                "status": "ok" if rowcount.get("status") in {"ok", "baseline_created"} and checksums.get("status") in {"ok", "baseline_created"} else "warning",
                "sanity": sanity,
                "rowcount_integrity": rowcount,
                "checksum_integrity": checksums,
            }
        finally:
            await engine.dispose()
