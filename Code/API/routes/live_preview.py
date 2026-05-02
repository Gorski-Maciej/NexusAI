from __future__ import annotations

from litestar import Controller, get
from litestar.exceptions import NotFoundException
from litestar.response import Response

from api.shared_image_buffer import SharedImageBuffer


class LivePreviewController(Controller):
    path = "/api/v1/live-preview"

    @get("/{doc_id:str}")
    async def get_latest_preview(self, doc_id: str, buffer: SharedImageBuffer) -> Response[bytes]:
        frame = buffer.latest(doc_id)
        if frame is None:
            raise NotFoundException(detail="No live preview for this document")

        return Response(content=frame.payload, media_type=frame.mime_type)
