from __future__ import annotations

from litestar import Controller, get, post

from nexus_ai.api.dto import GenericDictDTO, TAG_SYSTEM
from nexus_ai.api.rbac import owner_only_guard
from nexus_ai.core.config import AppConfig
from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.services.otel_fallback import FileSpanBuffer
from nexus_ai.services.telemetry import flush_fallback_spans


class TelemetryOpsController(Controller):
    """Operational telemetry fallback controls."""

    path = "/api/v1/system/telemetry"
    guards = [owner_only_guard]
    tags = [TAG_SYSTEM]

    @get(
        "/fallback-status",
        return_dto=GenericDictDTO,
        summary="Get telemetry fallback status",
        description="Returns the status of the OpenTelemetry fallback buffer including queued span count.",
        operation_id="getTelemetryFallbackStatus",
    )
    async def fallback_status(self) -> dict:
        config = AppConfig()
        buffer = FileSpanBuffer(max_records=50000)
        records = buffer.read_all()
        return {
            "buffer_file": str(buffer.file_path),
            "buffer_exists": buffer.file_path.exists(),
            "queued_spans": len(records),
            "duckdb_path": str(config.duckdb_path),
        }

    @post(
        "/fallback-replay",
        return_dto=GenericDictDTO,
        summary="Replay telemetry fallback spans",
        description="Flushes queued fallback spans from the local buffer to the primary telemetry backend.",
        operation_id="replayTelemetryFallback",
    )
    async def fallback_replay(self) -> dict:
        config = AppConfig()
        return await flush_fallback_spans(
            lambda: DuckDBManager(
                db_path=config.duckdb_path, sqlite_path=config.sqlite_path, read_only=False
            ),
            retries=3,
            base_delay=0.5,
        )
