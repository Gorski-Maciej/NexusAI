"""Export API endpoints for invoice data."""
from __future__ import annotations

from enum import Enum
from typing import Any
from litestar import Controller, get
from litestar.exceptions import ClientException
from core.config import AppConfig


class ExportFormat(str, Enum):
    """Supported export formats."""
    CSV = "csv"
    EXCEL = "xlsx"
    JSON = "json"
    PDF = "pdf"


class ExportController(Controller):
    """Handle invoice data export."""
    path = "/api/v1/exports"

    @get("/{export_id:str}/status")
    async def get_export_status(self, export_id: str) -> dict[str, Any]:
        """Get status of ongoing export."""
        return {
            "export_id": export_id,
            "status": "COMPLETED",
            "format": "csv",
            "file_url": f"/api/v1/exports/{export_id}/download",
        }

    @get("/{export_id:str}/download")
    async def download_export(self, export_id: str) -> dict[str, str]:
        """Download exported file."""
        return {
            "message": f"File for export {export_id} ready for download",
            "format": "csv",
        }
