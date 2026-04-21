from __future__ import annotations

from litestar import websocket


@websocket(path="/api/v1/ws/progress")
async def progress_websocket(socket) -> None:
    await socket.accept()
    await socket.send_json({"status": "connected"})
    await socket.close()
