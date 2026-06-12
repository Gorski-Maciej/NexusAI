from __future__ import annotations

from litestar import Controller, get, post
from litestar.connection import Request
from litestar.exceptions import ClientException
from sqlalchemy import text

from nexus_ai.api.rbac import owner_only_guard
from nexus_ai.api.schemas import SagaTransitionRequest
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

    return {"status": "ok", "older_than_hours": hours, "deleted": max(0, before - after), "remaining": after}

from nexus_ai.services.migration_sanity import (  # noqa: E402
    run_migration_sanity_checks,
    verify_migration_checksums,
    verify_migration_integrity,
)


class SystemIntegrityController(Controller):
    """On-demand production integrity checks for migrations and schema."""

    path = "/api/v1/system/integrity"
    guards = [owner_only_guard]
    tags = ["System"]

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

    @get("/saga/{saga_id:str}")
    async def get_saga_state(self, request: Request, saga_id: str, history_limit: int = 20) -> dict:
        store = request.app.state.saga_store
        item = await store.get(saga_id)
        if not item:
            return {"status": "not_found", "saga_id": saga_id}
        history = await store.get_history(saga_id=saga_id, limit=history_limit)
        return {
            "status": "ok",
            "saga_id": item.saga_id,
            "current_state": item.state,
            "updated_at": str(item.updated_at),
            "payload": item.payload,
            "history": history,
        }

    @post("/saga/{saga_id:str}/transition")
    async def transition_saga(self, request: Request, saga_id: str, data: SagaTransitionRequest) -> dict:
        new_state = data.new_state.strip()
        payload = data.payload
        try:
            item = await request.app.state.saga_store.transition(
                saga_id=saga_id,
                new_state=new_state,
                payload=payload,
                expected_current_state=data.expected_current_state,
            )
        except ValueError as exc:
            if str(exc).startswith("state_conflict:"):
                raise ClientException(status_code=409, detail=str(exc)) from exc
            raise
        return {
            "status": "ok",
            "saga_id": item.saga_id,
            "current_state": item.state,
            "updated_at": str(item.updated_at),
            "payload": item.payload,
        }

    @get("/saga/stuck")
    async def list_stuck_sagas(self, request: Request, older_than_minutes: int = 120) -> dict:
        store = request.app.state.saga_store
        items = await store.list_stuck(older_than_minutes=older_than_minutes)
        return {
            "status": "ok",
            "older_than_minutes": older_than_minutes,
            "count": len(items),
            "items": [
                {
                    "saga_id": i.saga_id,
                    "current_state": i.state,
                    "updated_at": str(i.updated_at),
                    "payload": i.payload,
                }
                for i in items
            ],
        }


    @post("/saga/{saga_id:str}/compensate")
    async def force_compensate_saga(self, request: Request, saga_id: str) -> dict:
        """
        Wymuszenie kompensacji sagi (Rozwiązanie 33).
        Używane do ręcznego odblokowania zawieszonego procesu.
        """
        store = request.app.state.saga_store
        try:
            result = await store.compensate(saga_id)
            return {
                "status": "ok",
                "saga_id": result.saga_id,
                "current_state": result.state,
                "updated_at": str(result.updated_at),
            }
        except ValueError as exc:
            raise ClientException(status_code=404, detail=str(exc)) from exc

    @post("/ui-drafts/cleanup")
    async def cleanup_ui_drafts(self, request: Request, older_than_hours: int = 168) -> dict:
        return await cleanup_stale_ui_drafts(request.app.state.db_engine, older_than_hours)
