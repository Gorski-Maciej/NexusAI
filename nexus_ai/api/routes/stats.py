"""Statistics and metrics endpoints."""

from __future__ import annotations

from typing import Any

from litestar import Controller, get

from nexus_ai.api.dto import GenericDictDTO, TAG_ANALYTICS


class StatsController(Controller):
    """Statistics and metrics API."""

    path = "/api/v1/stats"
    tags = [TAG_ANALYTICS]

    @get(
        "/processing",
        return_dto=GenericDictDTO,
        summary="Get processing statistics",
        description="Returns invoice processing statistics including success rate and error count.",
        operation_id="getProcessingStats",
    )
    async def get_processing_stats(self) -> dict[str, Any]:
        """Get invoice processing statistics."""
        return {
            "total_processed": 0,
            "avg_processing_time_ms": 0,
            "success_rate": 0.0,
            "error_count": 0,
        }
