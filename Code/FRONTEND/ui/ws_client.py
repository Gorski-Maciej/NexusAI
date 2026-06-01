# ui/ws_client.py
import asyncio
import json
import logging
import websockets
from websockets.exceptions import ConnectionClosed
from ui.state import app_state

logger = logging.getLogger("nexus.ui.ws")

class ProgressWebSocketClient:
    """Nasłuchuje zdarzeń z serwera w tle i aktualizuje Flet UI.

    Po nawiązaniu połączenia automatycznie subskrybuje wszystkie zadania
    (wildcard "*") i emituje zdarzenia postępu przez app_state.
    """

    def __init__(self, ws_url: str = "ws://127.0.0.1:8000/api/v1/ws/progress"):
        self.ws_url = ws_url
        self._task: asyncio.Task | None = None
        self._stop_event = asyncio.Event()
        self._connected = False

    @property
    def is_connected(self) -> bool:
        return self._connected

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
                    self._connected = True
                    logger.info("Połączono z kanałem WebSocket postępu.")

                    # Subskrybuj wszystkie zadania (wildcard "*")
                    await websocket.send(json.dumps({
                        "type": "subscribe",
                        "task_id": "*",
                    }))

                    while not self._stop_event.is_set():
                        message = await websocket.recv()
                        data = json.loads(message)
                        msg_type = data.get("type", "")

                        # Pomiń wiadomości systemowe (init, ping, potwierdzenia)
                        if msg_type in ("connected", "subscribed", "unsubscribed", "pong", "ping"):
                            continue

                        app_state.emit("progress_update", data)

                    # Normalne wyjście z pętli (stop request)
                    self._connected = False

            except ConnectionClosed:
                self._connected = False
                logger.warning("Połączenie WebSocket zamknięte. Ponawianie...")
                await asyncio.sleep(2)
            except Exception as e:
                self._connected = False
                logger.error(f"Błąd WebSocket: {e}")
                await asyncio.sleep(5)
