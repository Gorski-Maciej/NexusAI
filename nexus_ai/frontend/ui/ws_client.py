# ui/ws_client.py
"""Nasłuchuje zdarzeń postępu z serwera przez HTTP SSE (Server-Sent Events).

SUPERMOCE:
  - httpx + anyio (SSE zamiast WebSocket)
  - page.pubsub zamiast AppState
  - page.run_task zamiast anyio.create_task_group() w synchronicznej metodzie
  - Exponential backoff przy reconnect
"""

import httpx
from structlog import get_logger

import anyio

from nexus_ai.core.msgspec_utils import msgspec_loads

logger = get_logger("nexus.ui.ws")


class ProgressWebSocketClient:
    """Nasłuchuje zdarzeń postępu z serwera przez HTTP SSE i aktualizuje Flet UI.
    
    Backend publikuje zdarzenia postępu na endpoint HTTP SSE
    (np. GET /api/v1/events/progress), a klient odczytuje strumień
    linii w formacie SSE (data: {...}).
    """

    def __init__(self, page=None, base_url: str = "http://127.0.0.1:8000"):
        self._page = page
        self._events_url = f"{base_url}/api/v1/events/progress?task_id=*"
        self._task = None
        self._stop_event = anyio.Event()
        self._connected = False

    @property
    def is_connected(self) -> bool:
        return self._connected

    def set_page(self, page):
        self._page = page

    def start(self):
        """Legacy sync start — uses page.run_task internally."""
        if self._page:
            self._page.run_task(self.start_async())

    async def start_async(self):
        """Uruchamia nasłuchiwanie w tle jako async task."""
        self._stop_event.clear()
        # SUPERMOC: Używamy anyio.CancelledScope zamiast create_task_group
        # aby uniknąć buga z async with w sync metodzie
        try:
            await self._listen()
        except anyio.get_cancelled_exc_class():
            pass

    async def stop(self):
        """Zatrzymuje nasłuchiwanie."""
        self._stop_event.set()

    async def _listen(self):
        """Pętla główna z exponential backoff przy reconnect."""
        retry_delay = 1.0
        max_retry_delay = 60.0
        
        while not self._stop_event.is_set():
            try:
                async with httpx.AsyncClient(
                    timeout=None,
                    http2=True,
                    trust_env=True,
                    limits=httpx.Limits(max_connections=5, max_keepalive_connections=2),
                ) as client:
                    logger.info("Łączenie z kanałem SSE postępu...")
                    async with client.stream("GET", self._events_url) as response:
                        self._connected = True
                        retry_delay = 1.0  # Reset retry delay on successful connect
                        logger.info("Połączono z kanałem SSE postępu.")

                        async for line in response.aiter_lines():
                            if self._stop_event.is_set():
                                break

                            line = line.strip()
                            if not line:
                                continue

                            if line.startswith("data: "):
                                data = msgspec_loads(line[6:])
                                msg_type = data.get("type", "")

                                if msg_type in (
                                    "connected", "subscribed", "unsubscribed",
                                    "pong", "ping",
                                ):
                                    continue

                                # SUPERMOC: page.pubsub zamiast AppState
                                if self._page:
                                    self._page.pubsub.send_all_on_topic("progress_update", data)

                    self._connected = False

            except httpx.RemoteProtocolError:
                self._connected = False
                logger.warning("Połączenie SSE zamknięte. Ponawianie za %.1fs...", retry_delay)
                await anyio.sleep(retry_delay)
                retry_delay = min(retry_delay * 2, max_retry_delay)
            except httpx.ConnectError:
                self._connected = False
                logger.warning("Serwer niedostępny (SSE). Ponawianie za %.1fs...", retry_delay)
                await anyio.sleep(retry_delay)
                retry_delay = min(retry_delay * 2, max_retry_delay)
            except Exception as e:
                self._connected = False
                logger.error("Błąd SSE: %s. Ponawianie za %.1fs...", e, retry_delay)
                await anyio.sleep(retry_delay)
                retry_delay = min(retry_delay * 2, max_retry_delay)
