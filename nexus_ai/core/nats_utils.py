"""
NATS Utilities — shared connection, publish, and RPC helpers for nats-py.

SUPERMOCE nats-py (biblioteka kliencka):
  1. Connection callbacks — disconnected_cb, reconnected_cb, closed_cb
  2. nats-py error types — nats.errors.TimeoutError, ConnectionClosedError, NoRespondersError
  3. nc.flush() przed drain() — bezpieczne zamykanie z opróżnieniem bufora
  4. nc.request() z NoRespondersError — request-reply pattern
  5. nc.subscribe_async() — nowe API z async iteratorem
  6. Msg.metadata() — timestamp, sequence, stream z metadanych wiadomości
  7. Graceful degradation — gdy NATS niedostępny, zwraca None zamiast crasha

Usage:
    from nexus_ai.core.nats_utils import (
        get_connection,
        publish_event,
        NatsRpcClient,
        NatsSubscription,
    )

    # One-off publish
    await publish_event("subject.name", {"key": "value"})

    # RPC client
    rpc = NatsRpcClient()
    response = await rpc.request("service.method", {"data": ...})
    await rpc.close()

    # Subscription with async iterator
    sub = NatsSubscription("subject.>")
    async for msg in sub:
        data = msg.data
"""

from __future__ import annotations

import json
import random
from typing import Any, AsyncIterator

import anyio
import pendulum
from structlog import get_logger

from nexus_ai.core.config import AppConfig

logger = get_logger("nexus.nats.utils")


# ── nats-py error types ─────────────────────────────────────────────────


class NatsErrors:
    """Kontener dla typów błędów nats-py.

    SUPERMOC nats-py: Używamy dedykowanych typów błędów zamiast gołych Exception:
      - nats.errors.TimeoutError — timeout na operacji (request, fetch)
      - nats.errors.ConnectionClosedError — połączenie zamknięte
      - nats.errors.NoRespondersError — brak responderów dla request()
    """

    TimeoutError: type[BaseException] = TimeoutError  # fallback
    ConnectionClosedError: type[BaseException] = ConnectionError  # fallback
    NoRespondersError: type[BaseException] = ConnectionError  # fallback

    @classmethod
    def init(cls) -> None:
        """Zainicjalizuj z rzeczywistymi typami nats-py (jeśli dostępne)."""
        try:
            import nats.errors as nats_errors

            cls.TimeoutError = nats_errors.TimeoutError
            cls.ConnectionClosedError = nats_errors.ConnectionClosedError
            cls.NoRespondersError = nats_errors.NoRespondersError
        except (ImportError, AttributeError):
            pass  # fallback do standardowych typów


# ── Connection helpers ────────────────────────────────────────────────────


async def get_connection(
    nats_url: str | list[str] | None = None,
    name: str = "nexus-nats",
    connect_timeout: float = 10.0,
    enable_callbacks: bool = True,
) -> Any | None:
    """Połącz z NATS z pełną konfiguracją i callbackami.

    SUPERMOC nats-py:
      - disconnected_cb — loguje gdy połączenie zostało przerwane
      - reconnected_cb — loguje gdy połączenie zostało przywrócone
      - closed_cb — loguje gdy połączenie zostało zamknięte
      - max_reconnect_attempts=-1 — nieskończone próby reconnectu
      - reconnect_time_wait — opóźnienie między reconnectami

    Args:
        nats_url: Serwer(y) NATS.
        name: Nazwa połączenia (dla diagnostyki).
        connect_timeout: Timeout na połączenie.
        enable_callbacks: Czy włączyć callbacki connection lifecycle.

    Returns:
        Połączenie NATS lub None jeśli nie udało się połączyć.
    """
    import nats as nats_module

    NatsErrors.init()

    if nats_url is None:
        config = AppConfig()
        nats_url = config.nats_url

    if isinstance(nats_url, str):
        servers = [nats_url]
    else:
        servers = list(nats_url)

    callbacks: dict[str, Any] = {}

    if enable_callbacks:
        async def _on_disconnect() -> None:
            logger.warning("[NATS:CALLBACK] Disconnected from %s", servers)

        async def _on_reconnect() -> None:
            logger.info("[NATS:CALLBACK] Reconnected to %s", servers)

        async def _on_close() -> None:
            logger.info("[NATS:CALLBACK] Connection closed to %s", servers)

        async def _on_error(err: Any) -> None:
            logger.error("[NATS:CALLBACK] Error: %s", err)

        callbacks = {
            "disconnected_cb": _on_disconnect,
            "reconnected_cb": _on_reconnect,
            "closed_cb": _on_close,
            "error_cb": _on_error,
        }

    try:
        nc = await nats_module.connect(
            servers=servers,
            name=name,
            connect_timeout=connect_timeout,
            max_reconnect_attempts=-1,
            reconnect_time_wait=2.0,
            **callbacks,
        )
        logger.debug("[NATS] Connected to %s (name=%s)", servers, name)
        return nc
    except NatsErrors.TimeoutError:
        logger.warning("[NATS] Connection timeout to %s", servers)
        return None
    except NatsErrors.ConnectionClosedError:
        logger.warning("[NATS] Connection closed during connect to %s", servers)
        return None
    except Exception as exc:
        logger.warning("[NATS] Failed to connect to %s: %s", servers, exc)
        return None


async def safe_close(nc: Any | None, flush: bool = True) -> None:
    """Bezpiecznie zamknij połączenie NATS z flush.

    SUPERMOC nats-py:
      - nc.flush() — opróżnij bufor przed zamknięciem (gwarantuje dostarczenie)
      - nc.drain() — graceful shutdown z oczekiwaniem na pending messages

    Args:
        nc: Połączenie NATS (lub None).
        flush: Czy wykonać flush() przed drain().
    """
    if nc is None:
        return
    try:
        # SUPERMOC: flush() opróżnia bufor nadawczy przed drain()
        if flush:
            try:
                await nc.flush()
            except Exception:
                pass
        await nc.drain()
    except Exception:
        try:
            await nc.close()
        except Exception:
            pass


# ── One-off publish ──────────────────────────────────────────────────────


async def publish_event(
    subject: str,
    data: Any,
    nats_url: str | list[str] | None = None,
) -> bool:
    """Opublikuj event przez NATS z automatycznym connect/disconnect.

    SUPERMOC nats-py:
      - Automatyczne połączenie + flush + zamknięcie
      - Graceful degradation gdy NATS niedostępny
      - Obsługa nats.errors.TimeoutError, ConnectionClosedError

    Args:
        subject: Subject NATS (np. \"risk.thresholds.updated\").
        data: Dane do opublikowania (słownik, zostanie zserializowany).
        nats_url: Opcjonalny URL NATS.

    Returns:
        True jeśli opublikowano, False jeśli NATS niedostępny.
    """
    NatsErrors.init()

    nc = await get_connection(nats_url=nats_url, name="nexus-publisher")
    if nc is None:
        return False

    try:
        payload: bytes
        if isinstance(data, bytes):
            payload = data
        elif isinstance(data, str):
            payload = data.encode("utf-8")
        else:
            try:
                import msgspec

                payload = msgspec.json.encode(data)
            except Exception:
                payload = json.dumps(data).encode("utf-8")

        await nc.publish(subject, payload)

        # SUPERMOC: flush() gwarantuje że wiadomość została wysłana przed zamknięciem
        await nc.flush()
        return True
    except NatsErrors.ConnectionClosedError:
        logger.warning("[NATS:PUBLISH] Connection closed during publish to %s", subject)
        return False
    except Exception as exc:
        logger.warning("[NATS:PUBLISH] Failed to publish to %s: %s", subject, exc)
        return False
    finally:
        await safe_close(nc, flush=False)


# ── Request-Reply (RPC) ──────────────────────────────────────────────────


class NatsRpcClient:
    """NATS Request-Reply klient.

    SUPERMOC nats-py:
      - nc.request() z timeoutem — czeka na odpowiedź
      - nats.errors.NoRespondersError — graceful degradation gdy brak serwisu
      - Automatyczny reconnect gdy połączenie przerwane

    Usage:
        rpc = NatsRpcClient()
        try:
            response = await rpc.request(\"service.method\", {\"data\": ...})
        except NoRespondersError:
            # Serwis niedostępny — fallback
            pass
        except TimeoutError:
            # Serwis nie odpowiedział w czasie
            pass
        await rpc.close()
    """

    def __init__(
        self,
        nats_url: str | list[str] | None = None,
        name: str = "nexus-rpc-client",
        request_timeout: float = 5.0,
    ) -> None:
        NatsErrors.init()

        self._nats_url = nats_url
        self._name = name
        self._request_timeout = request_timeout
        self._nc: Any = None

    async def _ensure_connected(self) -> bool:
        """Upewnij się, że połączenie jest aktywne."""
        if self._nc is not None and not self._nc.is_closed:
            try:
                await self._nc.ping()
                return True
            except Exception:
                pass
        self._nc = await get_connection(
            nats_url=self._nats_url,
            name=self._name,
        )
        return self._nc is not None

    async def request(
        self,
        subject: str,
        data: Any,
        timeout: float | None = None,
    ) -> Any:
        """Wyślij request i czekaj na odpowiedź.

        SUPERMOC nats-py:
          - NoRespondersError — łapany i podnoszony dalej (caller decyduje o fallbacku)
          - TimeoutError — gdy serwis nie odpowiedział w czasie

        Args:
            subject: Subject NATS dla RPC.
            data: Dane requestu.
            timeout: Timeout w sekundach (domyślnie self._request_timeout).

        Returns:
            Odpowiedź (deserializowana z JSON).

        Raises:
            NoRespondersError: Gdy nie ma serwisu obsługującego ten subject.
            TimeoutError: Gdy serwis nie odpowiedział w czasie.
        """
        if not await self._ensure_connected():
            raise NatsErrors.NoRespondersError(f"No NATS connection for {subject}")

        timeout = timeout or self._request_timeout

        payload: bytes
        if isinstance(data, bytes):
            payload = data
        elif isinstance(data, str):
            payload = data.encode("utf-8")
        else:
            try:
                import msgspec

                payload = msgspec.json.encode(data)
            except Exception:
                payload = json.dumps(data).encode("utf-8")

        try:
            msg = await self._nc.request(subject, payload, timeout=timeout)

            # Deserializuj odpowiedź
            try:
                import msgspec

                return msgspec.json.decode(msg.data)
            except Exception:
                try:
                    return json.loads(msg.data)
                except Exception:
                    return msg.data

        except NatsErrors.NoRespondersError:
            logger.warning("[NATS:RPC] No responders for %s", subject)
            raise
        except NatsErrors.TimeoutError:
            logger.warning("[NATS:RPC] Timeout for %s (%.1fs)", subject, timeout)
            raise
        except Exception as exc:
            logger.error("[NATS:RPC] Error for %s: %s", subject, exc)
            raise

    async def close(self) -> None:
        """Zamknij połączenie."""
        await safe_close(self._nc)
        self._nc = None


# ── Async Iterator Subscription ──────────────────────────────────────────


class NatsSubscription:
    """NATS subscription z async iteratorem.

    SUPERMOC nats-py:
      - nc.subscribe() z async iteratorem — nowoczesne API zamiast callback
      - Msg.metadata() — dostęp do metadanych (timestamp, sequence, stream)
      - Queue group dla horizontal scaling
      - Automatyczny reconnect

    Usage:
        sub = NatsSubscription(\"nexus.tasks.status\")
        async for msg in sub:
            data = msg.data
            meta = msg.metadata()  # nats-py metadata
            print(f\"Seq: {meta.sequence.stream}\")
            await msg.ack()
    """

    def __init__(
        self,
        subject: str,
        queue: str = "",
        nats_url: str | list[str] | None = None,
        name: str = "nexus-subscriber",
    ) -> None:
        NatsErrors.init()

        self._subject = subject
        self._queue = queue
        self._nats_url = nats_url
        self._name = name
        self._nc: Any = None
        self._sub: Any = None

    async def __aenter__(self) -> NatsSubscription:
        await self._connect()
        return self

    async def __aexit__(self, *args: Any) -> None:
        await self._disconnect()

    async def _connect(self) -> None:
        self._nc = await get_connection(
            nats_url=self._nats_url,
            name=self._name,
        )
        if self._nc is not None:
            self._sub = await self._nc.subscribe(
                self._subject,
                queue=self._queue or None,
            )

    async def _disconnect(self) -> None:
        if self._sub is not None:
            try:
                await self._sub.unsubscribe()
            except Exception:
                pass
            self._sub = None
        await safe_close(self._nc)
        self._nc = None

    async def __aiter__(self) -> AsyncIterator[Any]:
        """Iteruj po wiadomościach z NATS.

        Yields:
            Wiadomość NATS z dostępem do .data, .subject, .metadata().
        """
        if self._sub is None:
            return

        try:
            async for msg in self._sub.messages:
                yield msg
        except Exception as exc:
            logger.warning("[NATS:SUB] Subscription error on %s: %s", self._subject, exc)

    async def get_metadata(self, msg: Any) -> dict[str, Any]:
        """Pobierz metadane z wiadomości NATS.

        SUPERMOC nats-py: Msg.metadata() zwraca:
          - timestamp — czas publikacji (nanosekundy)
          - sequence.stream — numer sekwencyjny w strumieniu
          - sequence.consumer — numer sekwencyjny u konsumenta
          - stream — nazwa strumienia JetStream
          - subject — subject w strumieniu

        Args:
            msg: Wiadomość NATS.

        Returns:
            Słownik z metadanymi.
        """
        try:
            meta = msg.metadata()
            if meta is not None:
                return {
                    "timestamp": meta.timestamp,
                    "stream_seq": meta.sequence.stream if hasattr(meta, "sequence") else 0,
                    "consumer_seq": meta.sequence.consumer_seq if hasattr(meta, "sequence") else 0,
                    "stream": meta.stream if hasattr(meta, "stream") else "",
                    "subject": msg.subject,
                }
        except Exception:
            pass
        return {
            "timestamp": pendulum.now("UTC").timestamp(),
            "subject": msg.subject,
        }


# ── Module init ──────────────────────────────────────────────────────────

NatsErrors.init()
