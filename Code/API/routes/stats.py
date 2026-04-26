"""Statistics and metrics endpoints."""
from __future__ import annotations

from typing import Any
from litestar import Controller, get


class StatsController(Controller):
    """Statistics and metrics API."""
    path = "/api/v1/stats"

    @get("/processing")
    async def get_processing_stats(self) -> dict[str, Any]:
        """Get invoice processing statistics."""
        return {
            "total_processed": 0,
            "avg_processing_time_ms": 0,
            "success_rate": 0.0,
            "error_count": 0,
        }
