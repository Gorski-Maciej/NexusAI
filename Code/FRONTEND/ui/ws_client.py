# ui/ws_client.py
import asyncio
import json
import logging
import websockets
from websockets.exceptions import ConnectionClosed
from ui.state import app_state

logger = logging.getLogger("nexus.ui.ws")

class ProgressWebSocketClient:
    """Nasłuchuje zdarzeń z serwera w tle i aktualizuje Flet UI."""

    def __init__(self, ws_url: str = "ws://127.0.0.1:8000/api/v1/ws/progress"):
        self.ws_url = ws_url
        self._task: asyncio.Task | None = None
        self._stop_event = asyncio.Event()

    def start(self):
        self._stop_event.clear()
        self._task = asyncio.create_task(self._listen())

    async def stop(self):
        self._stop_event.set()
        if self._task:
            await self._task

    async def _listen(self):
        while not self._stop_event.is_set():
            try:
                async with websockets.connect(self.ws_url) as websocket:
                    logger.info("Połączono z kanałem WebSockets paska postępu.")
                    while not self._stop_event.is_set():
                        message = await websocket.recv()
                        data = json.loads(message)
                        app_state.emit("progress_update", data)
            except ConnectionClosed:
                logger.warning("Połączenie WebSocket zamknięte. Ponawianie...")
                await asyncio.sleep(2)
            except Exception as e:
                logger.error(f"Błąd WebSocket: {e}")
                await asyncio.sleep(5)
