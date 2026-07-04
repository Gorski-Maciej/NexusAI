from __future__ import annotations

from litestar import Controller, delete, get, post
from litestar.connection import Request
from litestar.exceptions import ClientException
from sqlmodel import text

from nexus_ai.api.dto import (
    TAG_UI_STATE,
    SaveDraftResponseDTO,
    UIDeleteDraftDTO,
    UIGetDraftDTO,
    UIListDraftsDTO,
    UISaveDraftDTO,
)
from nexus_ai.api.rbac import owner_or_worker_guard
from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads

MAX_DRAFT_BYTES = 2 * 1024 * 1024


def validate_draft_key(draft_key: str) -> str:
    key = draft_key.strip()
    if not key or len(key) > 128:
        raise ClientException(status_code=400, detail="invalid draft_key")
    return key


def serialize_draft_payload(data: dict) -> str:
    payload_json = msgspec_dumps(data, ensure_ascii=False)
    if len(payload_json.encode("utf-8")) > MAX_DRAFT_BYTES:
        raise ClientException(status_code=413, detail="draft payload too large")
    return payload_json


class UIStateController(Controller):
    """Offline-resilient UI draft persistence for server-driven clients (e.g. Flet desktop UI)."""

    path = "/ui"
    guards = (owner_or_worker_guard,)
    tags = (TAG_UI_STATE,)

    @post(
        "/drafts/{draft_key:str}",
        dto=UISaveDraftDTO,
        return_dto=SaveDraftResponseDTO,
        summary="Save UI draft",
        description="Saves or updates a UI draft for offline-resilient persistence.",
        operation_id="saveUiDraft",
    )
    async def save_draft(self, request: Request, draft_key: str, data: dict) -> dict:
        draft_key = validate_draft_key(draft_key)
        user = getattr(request, "user", None)
        actor = getattr(user, "id", "anonymous")
        tenant_id = getattr(user, "tenant_id", "default")
        payload_json = serialize_draft_payload(data)

        async with request.app.state.db_engine.begin() as conn:
            await conn.execute(
                text(
                    """
                    INSERT INTO ui_drafts (tenant_id, actor_id, draft_key, payload_json, updated_at)
                    VALUES (:tenant_id, :actor_id, :draft_key, :payload_json, CURRENT_TIMESTAMP)
                    ON CONFLICT(tenant_id, actor_id, draft_key) DO UPDATE SET
                        payload_json = excluded.payload_json,
                        updated_at = CURRENT_TIMESTAMP
                    """
                ),
                {
                    "tenant_id": tenant_id,
                    "actor_id": actor,
                    "draft_key": draft_key,
                    "payload_json": payload_json,
                },
            )

        return {"status": "ok", "draft_key": draft_key}

    @get(
        "/drafts/{draft_key:str}",
        return_dto=UIGetDraftDTO,
        summary="Get UI draft",
        description="Retrieves a saved UI draft by key.",
        operation_id="getUiDraft",
    )
    async def get_draft(self, request: Request, draft_key: str) -> dict:
        draft_key = validate_draft_key(draft_key)
        user = getattr(request, "user", None)
        actor = getattr(user, "id", "anonymous")
        tenant_id = getattr(user, "tenant_id", "default")

        async with request.app.state.db_engine.begin() as conn:
            row = (
                (
                    await conn.execute(
                        text(
                            """
                        SELECT payload_json, updated_at
                        FROM ui_drafts
                        WHERE tenant_id = :tenant_id AND actor_id = :actor_id AND draft_key = :draft_key
                        """
                        ),
                        {"tenant_id": tenant_id, "actor_id": actor, "draft_key": draft_key},
                    )
                )
                .mappings()
                .first()
            )

        if not row:
            return {"status": "not_found", "draft_key": draft_key, "payload": {}}

        try:
            payload = msgspec_loads(row["payload_json"])
        except Exception:
            payload = {"raw": row["payload_json"]}
        return {
            "status": "ok",
            "draft_key": draft_key,
            "updated_at": str(row["updated_at"]),
            "payload": payload,
        }

    @delete(
        "/drafts/{draft_key:str}",
        status_code=200,
        return_dto=UIDeleteDraftDTO,
        summary="Delete UI draft",
        description="Deletes a saved UI draft by key.",
        operation_id="deleteUiDraft",
    )
    async def delete_draft(self, request: Request, draft_key: str) -> dict:
        draft_key = validate_draft_key(draft_key)
        user = getattr(request, "user", None)
        actor = getattr(user, "id", "anonymous")
        tenant_id = getattr(user, "tenant_id", "default")

        async with request.app.state.db_engine.begin() as conn:
            await conn.execute(
                text(
                    """
                    DELETE FROM ui_drafts
                    WHERE tenant_id = :tenant_id AND actor_id = :actor_id AND draft_key = :draft_key
                    """
                ),
                {"tenant_id": tenant_id, "actor_id": actor, "draft_key": draft_key},
            )

        return {"status": "ok", "draft_key": draft_key}

    @get(
        "/drafts",
        return_dto=UIListDraftsDTO,
        summary="List UI drafts",
        description="Lists all saved UI drafts for the current user.",
        operation_id="listUiDrafts",
    )
    async def list_drafts(self, request: Request, limit: int = 50) -> dict:
        user = getattr(request, "user", None)
        actor = getattr(user, "id", "anonymous")
        tenant_id = getattr(user, "tenant_id", "default")
        safe_limit = max(1, min(int(limit), 200))

        async with request.app.state.db_engine.begin() as conn:
            rows = (
                (
                    await conn.execute(
                        text(
                            """
                        SELECT draft_key, updated_at
                        FROM ui_drafts
                        WHERE tenant_id = :tenant_id AND actor_id = :actor_id
                        ORDER BY updated_at DESC
                        LIMIT :limit
                        """
                        ),
                        {"tenant_id": tenant_id, "actor_id": actor, "limit": safe_limit},
                    )
                )
                .mappings()
                .all()
            )

        return {
            "status": "ok",
            "count": len(rows),
            "items": [
                {"draft_key": str(r["draft_key"]), "updated_at": str(r["updated_at"])} for r in rows
            ],
        }
