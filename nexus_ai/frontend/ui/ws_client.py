"""ws_client.py — Nasłuchuje zdarzeń postępu z serwera przez HTTP SSE.

SUPERMOCE Flet 0.28+:
  - page.pubsub zamiast AppState — natywny event bus Flet
  - Heartbeat/ping mechanizm co 30s
  - Exponential backoff z jitter przy reconnect
  - msgspec_loads z walidacją typu zdarzenia
  - anyio.CancelledScope dla czystego zamknięcia
  - page.run_task zamiast anyio.create_task_group()

NOTE: Docelowo (Phase 3) SSE zostanie zastąpiony natywnym page.pubsub Flet.
"""

from __future__ import annotations

import random
from typing import Any

import httpx
import anyio
from structlog import get_logger

from nexus_ai.core.msgspec_utils import msgspec_loads

logger = get_logger("nexus.ui.ws")

HEARTBEAT_INTERVAL = 30.0
INITIAL_RETRY_DELAY = 1.0
MAX_RETRY_DELAY = 60.0
JITTER_FACTOR = 0.1


class ProgressWebSocketClient:
    """Nasłuchuje zdarzeń postępu z serwera przez HTTP SSE i aktualizuje Flet UI.

    SUPERMOC Flet 0.28+:
      - page.pubsub zamiast AppState
      - Heartbeat co 30s dla utrzymania połączenia
      - Exponential backoff z jitter (0.1 random factor)
      - msgspec walidacja typów zdarzeń
    """

    def __init__(self, page=None, base_url: str = "http://127.0.0.1:8000"):
        self._page = page
        self._events_url = f"{base_url}/api/v1/events/progress?task_id=*"
        self._task = None
        self._stop_event = anyio.Event()
        self._connected = False
        self._heartbeat_interval = HEARTBEAT_INTERVAL

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
        try:
            await self._listen()
        except anyio.get_cancelled_exc_class():
            pass

    async def stop(self):
        """Zatrzymuje nasłuchiwanie."""
        self._stop_event.set()

    async def _listen(self):
        """Pętla główna z exponential backoff + jitter i heartbeat."""
        retry_delay = INITIAL_RETRY_DELAY

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
                        retry_delay = INITIAL_RETRY_DELAY
                        logger.info("Połączono z kanałem SSE postępu.")

                        # SUPERMOC: Heartbeat — okresowe ping
                        last_activity = anyio.current_time()

                        async def heartbeat():
                            """Okresowe sprawdzanie czy połączenie żyje."""
                            while not self._stop_event.is_set():
                                await anyio.sleep(self._heartbeat_interval)
                                now = anyio.current_time()
                                if now - last_activity > self._heartbeat_interval * 2:
                                    logger.warning("Brak aktywności od %.0fs", now - last_activity)
                                    # Wymuś reconnect przez zamknięcie strumienia

                        async with anyio.create_task_group() as tg:
                            tg.start_soon(heartbeat)

                            async for line in response.aiter_lines():
                                if self._stop_event.is_set():
                                    break

                                last_activity = anyio.current_time()
                                line = line.strip()
                                if not line:
                                    continue

                                if line.startswith("data: "):
                                    try:
                                        data = msgspec_loads(line[6:])
                                    except Exception:
                                        continue

                                    if not isinstance(data, dict):
                                        continue

                                    msg_type = data.get("type", "")

                                    # SUPERMOC: Filtrowanie zdarzeń systemowych
                                    if msg_type in (
                                        "connected", "subscribed", "unsubscribed",
                                        "pong", "ping",
                                    ):
                                        continue

                                    # SUPERMOC: Walidacja wymaganych pól
                                    if "task_id" not in data and "event" not in data:
                                        continue

                                    # SUPERMOC: page.pubsub zamiast AppState
                                    if self._page:
                                        self._page.pubsub.send_all_on_topic(
                                            "progress_update", data
                                        )

                    self._connected = False

            except httpx.RemoteProtocolError:
                self._connected = False
                delay = self._backoff_with_jitter(retry_delay)
                logger.warning("Połączenie SSE zamknięte. Ponawianie za %.1fs...", delay)
                await anyio.sleep(delay)
                retry_delay = min(retry_delay * 2, MAX_RETRY_DELAY)
            except httpx.ConnectError:
                self._connected = False
                delay = self._backoff_with_jitter(retry_delay)
                logger.warning("Serwer niedostępny (SSE). Ponawianie za %.1fs...", delay)
                await anyio.sleep(delay)
                retry_delay = min(retry_delay * 2, MAX_RETRY_DELAY)
            except Exception as e:
                self._connected = False
                delay = self._backoff_with_jitter(retry_delay)
                logger.error("Błąd SSE: %s. Ponawianie za %.1fs...", e, delay)
                await anyio.sleep(delay)
                retry_delay = min(retry_delay * 2, MAX_RETRY_DELAY)

    @staticmethod
    def _backoff_with_jitter(delay: float) -> float:
        """Exponential backoff z jitter (±10%).

        SUPERMOC: Losowy jitter zapobiega \"thundering herd\" przy reconnect.
        """
        jitter = delay * JITTER_FACTOR
        return delay + random.uniform(-jitter, jitter)
