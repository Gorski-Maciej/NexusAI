from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import datetime, timezone, timedelta
from typing import Any

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncEngine


@dataclass(slots=True)
class SagaState:
    saga_id: str
    state: str
    payload: dict[str, Any]
    updated_at: datetime


class PersistedSagaStore:
    """Durable saga state store persisted in SQLite with transition history."""

    def __init__(self, engine: AsyncEngine) -> None:
        self._engine = engine

    @staticmethod
    def _normalize_payload(payload: dict[str, Any] | str | None) -> tuple[dict[str, Any], str]:
        if payload is None:
            return {}, "{}"
        if isinstance(payload, dict):
            return payload, json.dumps(payload, ensure_ascii=False)
        if isinstance(payload, str):
            try:
                parsed = json.loads(payload)
                if isinstance(parsed, dict):
                    return parsed, json.dumps(parsed, ensure_ascii=False)
            except Exception:
                pass
            return {"raw": payload}, json.dumps({"raw": payload}, ensure_ascii=False)
        return {"raw": str(payload)}, json.dumps({"raw": str(payload)}, ensure_ascii=False)

    @staticmethod
    def _parse_timestamp(value: Any) -> datetime:
        """Konwertuje timestamp z SQLite (string lub datetime) na datetime."""
        if isinstance(value, datetime):
            return value
        if isinstance(value, str):
            try:
                return datetime.fromisoformat(value)
            except ValueError:
                pass
            for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%d %H:%M:%S.%f"):
                try:
                    return datetime.strptime(value, fmt).replace(tzinfo=timezone.utc)
                except ValueError:
                    continue
        raise ValueError(f"Cannot parse timestamp: {value!r}")

    async def ensure_schema(self) -> None:
        async with self._engine.begin() as conn:
            await conn.execute(
                text(
                    """
                    CREATE TABLE IF NOT EXISTS workflow_saga_state (
                        saga_id TEXT PRIMARY KEY,
                        current_state TEXT NOT NULL,
                        payload_json TEXT NOT NULL DEFAULT '{}',
                        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
                    )
                    """
                )
            )
            await conn.execute(
                text(
                    """
                    CREATE TABLE IF NOT EXISTS workflow_saga_history (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        saga_id TEXT NOT NULL,
                        previous_state TEXT,
                        new_state TEXT NOT NULL,
                        payload_json TEXT NOT NULL DEFAULT '{}',
                        transitioned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
                    )
                    """
                )
            )
            await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_workflow_saga_history_saga_id ON workflow_saga_history(saga_id, transitioned_at DESC)"))

    async def transition(self, saga_id: str, new_state: str, payload: dict[str, Any] | str | None = None, expected_current_state: str | None = None) -> SagaState:
        if not saga_id.strip():
            raise ValueError("saga_id cannot be empty")
        if not new_state.strip():
            raise ValueError("new_state cannot be empty")

        payload_dict, payload_json = self._normalize_payload(payload)
        now = datetime.now(timezone.utc)
        # Format zgodny z SQLite CURRENT_TIMESTAMP, żeby string comparison w list_stuck działał poprawnie
        now_str = now.strftime("%Y-%m-%d %H:%M:%S")

        async with self._engine.begin() as conn:
            current = (
                await conn.execute(
                    text("SELECT current_state FROM workflow_saga_state WHERE saga_id = :saga_id"),
                    {"saga_id": saga_id},
                )
            ).scalar_one_or_none()
            previous_state = str(current) if current is not None else None
            if expected_current_state is not None and previous_state != expected_current_state:
                raise ValueError(f"state_conflict: expected={expected_current_state} actual={previous_state}")

            await conn.execute(
                text(
                    """
                    INSERT INTO workflow_saga_state (saga_id, current_state, payload_json, updated_at)
                    VALUES (:saga_id, :current_state, :payload_json, :updated_at)
                    ON CONFLICT(saga_id) DO UPDATE SET
                        current_state = excluded.current_state,
                        payload_json = excluded.payload_json,
                        updated_at = excluded.updated_at
                    """
                ),
                {
                    "saga_id": saga_id,
                    "current_state": new_state,
                    "payload_json": payload_json,
                    "updated_at": now_str,
                },
            )

            await conn.execute(
                text(
                    """
                    INSERT INTO workflow_saga_history (saga_id, previous_state, new_state, payload_json, transitioned_at)
                    VALUES (:saga_id, :previous_state, :new_state, :payload_json, :transitioned_at)
                    """
                ),
                {
                    "saga_id": saga_id,
                    "previous_state": previous_state,
                    "new_state": new_state,
                    "payload_json": payload_json,
                    "transitioned_at": now_str,
                },
            )

        return SagaState(saga_id=saga_id, state=new_state, payload=payload_dict, updated_at=now)

    async def get(self, saga_id: str) -> SagaState | None:
        async with self._engine.begin() as conn:
            row = (
                await conn.execute(
                    text(
                        """
                        SELECT saga_id, current_state, payload_json, updated_at
                        FROM workflow_saga_state
                        WHERE saga_id = :saga_id
                        """
                    ),
                    {"saga_id": saga_id},
                )
            ).mappings().first()
        if not row:
            return None
        payload, _ = self._normalize_payload(row["payload_json"])
        return SagaState(
            saga_id=str(row["saga_id"]),
            state=str(row["current_state"]),
            payload=payload,
            updated_at=self._parse_timestamp(row["updated_at"]),
        )

    async def list_stuck(self, older_than_minutes: int = 120) -> list[SagaState]:
        threshold = max(1, int(older_than_minutes))
        cutoff = datetime.now(timezone.utc) - timedelta(minutes=threshold)
        # Używamy formatu zgodnego z SQLite CURRENT_TIMESTAMP, aby string comparison działał
        cutoff_str = cutoff.strftime("%Y-%m-%d %H:%M:%S")
        async with self._engine.begin() as conn:
            rows = (
                await conn.execute(
                    text(
                        """
                        SELECT saga_id, current_state, payload_json, updated_at
                        FROM workflow_saga_state
                        WHERE updated_at < :cutoff
                        ORDER BY updated_at ASC
                        """
                    ),
                    {"cutoff": cutoff_str},
                )
            ).mappings().all()
        return [
            SagaState(
                saga_id=str(r["saga_id"]),
                state=str(r["current_state"]),
                payload=self._normalize_payload(r["payload_json"])[0],
                updated_at=self._parse_timestamp(r["updated_at"]),
            )
            for r in rows
        ]

    async def get_history(self, saga_id: str, limit: int = 50) -> list[dict[str, Any]]:
        safe_limit = min(max(1, int(limit)), 500)
        async with self._engine.begin() as conn:
            rows = (
                await conn.execute(
                    text(
                        """
                        SELECT id, previous_state, new_state, payload_json, transitioned_at
                        FROM workflow_saga_history
                        WHERE saga_id = :saga_id
                        ORDER BY id DESC
                        LIMIT :limit
                        """
                    ),
                    {"saga_id": saga_id, "limit": safe_limit},
                )
            ).mappings().all()
        return [
            {
                "id": int(r["id"]),
                "previous_state": r["previous_state"],
                "new_state": r["new_state"],
                "payload": self._normalize_payload(r["payload_json"])[0],
                "transitioned_at": str(r["transitioned_at"]),
            }
            for r in rows
        ]
