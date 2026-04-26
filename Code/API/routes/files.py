"""File management endpoints."""
from __future__ import annotations

from typing import Any
from litestar import Controller, get, delete
from litestar.exceptions import ClientException


class FileController(Controller):
    """File management API."""
    path = "/api/v1/files"

    @get("/{file_id:str}")
    async def get_file_info(self, file_id: str) -> dict[str, Any]:
        """Get file metadata."""
        return {
            "file_id": file_id,
            "name": f"invoice_{file_id}.pdf",
            "size_bytes": 0,
            "mime_type": "application/pdf",
        }

    @delete("/{file_id:str}")
    async def delete_file(self, file_id: str) -> dict[str, str]:
        """Delete a file."""
        return {"message": f"File {file_id} deleted successfully"}
