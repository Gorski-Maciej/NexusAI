# ui/ws_client.py
"""Nasłuchuje zdarzeń postępu z serwera przez HTTP SSE (Server-Sent Events).

Zgodnie z aa3fvcx.txt:
  - websockets → httpx + anyio (SSE zamiast WebSocket)
  - Litestar natywnie wspiera SSE (EventSourceResponse / StreamingResponse)
"""

import httpx
from structlog import get_logger
from ui.state import app_state

import anyio

from nexus_ai.core.msgspec_utils import msgspec_loads

logger = get_logger("nexus.ui.ws")


class ProgressWebSocketClient:
    """Nasłuchuje zdarzeń postępu z serwera przez HTTP SSE i aktualizuje Flet UI.

    Backend publikuje zdarzenia postępu na endpoint HTTP SSE
    (np. GET /api/v1/events/progress), a klient odczytuje strumień
    linii w formacie SSE (data: {...}).

    Zastępuje: websockets → httpx.AsyncClient.stream() + anyio
    """

    def __init__(self, base_url: str = "http://127.0.0.1:8000"):
        self._events_url = f"{base_url}/api/v1/events/progress?task_id=*"
        self._task: anyio.abc.TaskStatus | None = None
        self._stop_event = anyio.Event()
        self._connected = False

    @property
    def is_connected(self) -> bool:
        return self._connected

    def start(self):
        """Uruchamia nasłuchiwanie w tle (Task)."""
        self._stop_event.clear()
        async with anyio.create_task_group() as tg:
            tg.start_soon(self._listen)

    async def stop(self):
        """Zatrzymuje nasłuchiwanie."""
        self._stop_event.set()
        if self._task:
            await self._task

    async def _listen(self):
        """Pętla główna — łączy się z SSE endpointem i odczytuje zdarzenia.

        Automatycznie wznawia połączenie po zamknięciu lub błędzie.
        """
        while not self._stop_event.is_set():
            try:
                async with httpx.AsyncClient(timeout=None) as client:
                    logger.info("Łączenie z kanałem SSE postępu...")
                    async with client.stream("GET", self._events_url) as response:
                        self._connected = True
                        logger.info("Połączono z kanałem SSE postępu.")

                        async for line in response.aiter_lines():
                            if self._stop_event.is_set():
                                break

                            line = line.strip()
                            if not line:
                                continue

                            # Format SSE: "data: {\"type\": \"progress\", ...}"
                            if line.startswith("data: "):
                                data = msgspec_loads(line[6:])
                                msg_type = data.get("type", "")

                                # Pomiń wiadomości systemowe
                                if msg_type in ("connected", "subscribed",
                                                "unsubscribed", "pong", "ping"):
                                    continue

                                app_state.emit("progress_update", data)

                    self._connected = False

            except httpx.RemoteProtocolError:
                self._connected = False
                logger.warning("Połączenie SSE zamknięte. Ponawianie...")
                await anyio.sleep(2)
            except httpx.ConnectError:
                self._connected = False
                logger.warning("Serwer niedostępny (SSE). Ponawianie...")
                await anyio.sleep(5)
            except Exception as e:
                self._connected = False
                logger.error(f"Błąd SSE: {e}")
                await anyio.sleep(5)
