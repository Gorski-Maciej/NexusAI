"""File management endpoints."""
from __future__ import annotations

from typing import Any
from litestar import Controller, get, delete, Response
from litestar.exceptions import ClientException


class FileController(Controller):
    """File management API.
    Rozwiązanie 31: CSP sandbox dla ścieżki /files aby zapobiec wykonaniu złośliwych plików.
    """
    path = "/api/v1/files"

    @get("/{file_id:str}", media_type="application/json")
    async def get_file_info(self, file_id: str) -> Response:
        """Get file metadata with CSP headers (Rozwiązanie 31)."""
        return Response(
            content={
                "file_id": file_id,
                "name": f"invoice_{file_id}.pdf",
                "size_bytes": 0,
                "mime_type": "application/pdf",
            },
            headers={
                "Content-Security-Policy": "default-src 'none'; sandbox",
                "X-Content-Type-Options": "nosniff",
            },
        )

    @delete("/{file_id:str}")
    async def delete_file(self, file_id: str) -> dict[str, str]:
        """Delete a file."""
        return {"message": f"File {file_id} deleted successfully"}
