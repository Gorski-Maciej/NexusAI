"""unix_progress.py — Nasłuchuje zdarzeń postępu przez socket UNIX.

Zastępuje: ws_client.py (HTTP SSE → socket UNIX).
Komunikacja przez AF_UNIX jest szybsza i lżejsza niż HTTP/SSE w trybie desktopowym.

SUPERMOCE:
  - asyncio.open_unix_connection — natywne API Pythona, zero dodatkowych zależności
  - Exponential backoff z jitter przy reconnect
  - page.pubsub dla dystrybucji zdarzeń
  - Czyste zamknięcie przez asyncio.Event
"""

from __future__ import annotations

import asyncio
import json
import random

from structlog import get_logger

logger = get_logger("nexus.ui.unix_progress")

SOCKET_PATH = "/tmp/nexusai-progress.sock"

INITIAL_RETRY_DELAY = 1.0
MAX_RETRY_DELAY = 30.0
JITTER_FACTOR = 0.1
HEARTBEAT_TIMEOUT = 30.0


class UnixProgressClient:
    """Nasłuchuje zdarzeń postępu z backendu przez socket UNIX i aktualizuje Flet UI.

    Zastępuje ProgressWebSocketClient — zamiast HTTP SSE łączy się bezpośrednio
    przez AF_UNIX socket, co eliminuje narzut HTTP i TCP loopback.

    Użycie:
        client = UnixProgressClient(page=page)
        page.run_task(client.start_async())
        # ... później ...
        await client.stop()
    """

    def __init__(self, page=None):
        self._page = page
        self._task = None
        self._stop_event = asyncio.Event()
        self._connected = False

    @property
    def is_connected(self) -> bool:
        return self._connected

    def set_page(self, page):
        self._page = page

    def start(self):
        """Legacy sync start — używa page.run_task wewnętrznie."""
        if self._page:
            self._page.run_task(self.start_async())

    async def start_async(self):
        """Uruchamia nasłuchiwanie w tle jako async task."""
        self._stop_event.clear()
        try:
            await self._listen()
        except asyncio.CancelledError:
            pass

    async def stop(self):
        """Zatrzymuje nasłuchiwanie."""
        self._stop_event.set()

    async def _listen(self):
        """Pętla główna z exponential backoff + jitter i automatycznym reconnectem."""
        retry_delay = INITIAL_RETRY_DELAY

        while not self._stop_event.is_set():
            try:
                reader, writer = await asyncio.open_unix_connection(SOCKET_PATH)
                self._connected = True
                retry_delay = INITIAL_RETRY_DELAY
                logger.info("Połączono z kanałem postępu przez socket UNIX")

                while not self._stop_event.is_set():
                    try:
                        line = await asyncio.wait_for(
                            reader.readline(),
                            timeout=HEARTBEAT_TIMEOUT,
                        )
                    except asyncio.TimeoutError:
                        # Heartbeat — brak danych nie jest błędem, kontynuujemy
                        continue

                    if not line:
                        # Połączenie zamknięte przez serwer
                        break

                    try:
                        data = json.loads(line.decode("utf-8").strip())
                    except (json.JSONDecodeError, UnicodeDecodeError):
                        continue

                    if not isinstance(data, dict):
                        continue

                    # SUPERMOC: page.pubsub dla dystrybucji zdarzeń
                    if self._page:
                        self._page.pubsub.send_all_on_topic("progress_update", data)

                self._connected = False
                writer.close()
                await writer.wait_closed()

            except (FileNotFoundError, ConnectionRefusedError):
                self._connected = False
                delay = _backoff_with_jitter(retry_delay)
                logger.debug("Socket UNIX niedostępny. Ponawianie za %.1fs...", delay)
                await asyncio.sleep(delay)
                retry_delay = min(retry_delay * 2, MAX_RETRY_DELAY)
            except (ConnectionResetError, BrokenPipeError):
                self._connected = False
                delay = _backoff_with_jitter(retry_delay)
                logger.debug("Połączenie socket UNIX zerwane. Ponawianie za %.1fs...", delay)
                await asyncio.sleep(delay)
                retry_delay = min(retry_delay * 2, MAX_RETRY_DELAY)
            except asyncio.CancelledError:
                break
            except Exception as e:
                self._connected = False
                delay = _backoff_with_jitter(retry_delay)
                logger.error("Błąd socket UNIX: %s. Ponawianie za %.1fs...", e, delay)
                await asyncio.sleep(delay)
                retry_delay = min(retry_delay * 2, MAX_RETRY_DELAY)


def _backoff_with_jitter(delay: float) -> float:
    """Exponential backoff z jitter (±10%)."""
    jitter = delay * JITTER_FACTOR
    return delay + random.uniform(-jitter, jitter)
