from __future__ import annotations

from litestar import Controller, get, post
from litestar.connection import Request
from sqlmodel import text

from nexus_ai.api.dto import (
    TAG_SYSTEM,
    MigrationIntegrityDTO,
    UICleanupDTO,
)
from nexus_ai.api.rbac import owner_only_guard
from nexus_ai.core.config import AppConfig
from nexus_ai.db.database import create_oltp_engine


async def cleanup_stale_ui_drafts(engine, older_than_hours: int) -> dict:
    hours = max(1, min(int(older_than_hours), 24 * 365))
    async with engine.begin() as conn:
        before = int((await conn.execute(text("SELECT COUNT(1) FROM ui_drafts"))).scalar_one())
        await conn.execute(
            text("DELETE FROM ui_drafts WHERE updated_at < datetime('now', :interval)"),
            {"interval": f"-{hours} hours"},
        )
        after = int((await conn.execute(text("SELECT COUNT(1) FROM ui_drafts"))).scalar_one())

    return {
        "status": "ok",
        "older_than_hours": hours,
        "deleted": max(0, before - after),
        "remaining": after,
    }


from nexus_ai.services.migration_sanity import (  # noqa: E402
    run_migration_sanity_checks,
    verify_migration_checksums,
    verify_migration_integrity,
)


class SystemIntegrityController(Controller):
    """On-demand production integrity checks for migrations and schema."""

    path = "/system/integrity"
    guards = [owner_only_guard]
    tags = [TAG_SYSTEM]

    @get(
        "/migration",
        return_dto=MigrationIntegrityDTO,
        summary="Check migration integrity",
        description="Runs on-demand migration sanity, rowcount integrity, and checksum checks.",
        operation_id="checkMigrationIntegrity",
    )
    async def migration_integrity(self) -> dict:
        config = AppConfig()
        engine = create_oltp_engine(config)
        try:
            sanity = await run_migration_sanity_checks(engine)
            rowcount = await verify_migration_integrity(engine, config.migration_baseline_path)
            checksums = await verify_migration_checksums(
                engine, config.migration_checksum_baseline_path
            )
            return {
                "status": "ok"
                if rowcount.get("status") in {"ok", "baseline_created"}
                and checksums.get("status") in {"ok", "baseline_created"}
                else "warning",
                "sanity": sanity,
                "rowcount_integrity": rowcount,
                "checksum_integrity": checksums,
            }
        finally:
            await engine.dispose()

    @post(
        "/ui-drafts/cleanup",
        return_dto=UICleanupDTO,
        summary="Cleanup stale UI drafts",
        description="Deletes UI drafts older than the specified hours (default 7 days).",
        operation_id="cleanupStaleUiDrafts",
    )
    async def cleanup_ui_drafts(self, request: Request, older_than_hours: int = 168) -> dict:
        return await cleanup_stale_ui_drafts(request.app.state.db_engine, older_than_hours)
