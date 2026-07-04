"""File management endpoints."""

from __future__ import annotations

from litestar import Controller, Response, delete, get

from nexus_ai.api.dto import TAG_FILES, FileDeleteResponseDTO, FileInfoDTO


class FileController(Controller):
    """File management API.
    Rozwiązanie 31: CSP sandbox dla ścieżki /files aby zapobiec wykonaniu złośliwych plików.
    """

    path = "/files"
    tags = (TAG_FILES,)

    @get(
        "/{file_id:str}",
        media_type="application/json",
        return_dto=FileInfoDTO,
        summary="Get file metadata",
        description="Returns file metadata with CSP security headers (Rozwiązanie 31).",
        operation_id="getFileInfo",
    )
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

    @delete(
        "/{file_id:str}",
        status_code=200,
        return_dto=FileDeleteResponseDTO,
        summary="Delete a file",
        description="Deletes a file by its ID.",
        operation_id="deleteFile",
    )
    async def delete_file(self, file_id: str) -> dict[str, str]:
        """Delete a file."""
        return {"message": f"File {file_id} deleted successfully"}
