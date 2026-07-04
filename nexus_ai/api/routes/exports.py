"""Export API endpoints for invoice data."""

from __future__ import annotations

from enum import StrEnum
from typing import Any

from litestar import Controller, get

from nexus_ai.api.dto import TAG_FILES, TAG_SYSTEM, ExportDownloadDTO, ExportStatusDTO


class ExportFormat(StrEnum):
    """Supported export formats."""

    CSV = "csv"
    EXCEL = "xlsx"
    JSON = "json"
    PDF = "pdf"


class ExportController(Controller):
    """Handle invoice data export."""

    path = "/exports"
    tags = (TAG_FILES, TAG_SYSTEM,)

    @get(
        "/{export_id:str}/status",
        return_dto=ExportStatusDTO,
        summary="Get export status",
        description="Returns the status of an ongoing or completed export.",
        operation_id="getExportStatus",
    )
    async def get_export_status(self, export_id: str) -> dict[str, Any]:
        """Get status of ongoing export."""
        return {
            "export_id": export_id,
            "status": "COMPLETED",
            "format": "csv",
            "file_url": f"/api/v1/exports/{export_id}/download",
        }

    @get(
        "/{export_id:str}/download",
        return_dto=ExportDownloadDTO,
        summary="Download export file",
        description="Downloads an exported file by its ID.",
        operation_id="downloadExport",
    )
    async def download_export(self, export_id: str) -> dict[str, str]:
        """Download exported file."""
        return {
            "message": f"File for export {export_id} ready for download",
            "format": "csv",
        }
