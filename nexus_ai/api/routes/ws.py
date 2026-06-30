"""
SSE (Server-Sent Events) + Unix Socket endpoints for progress updates.

Zgodnie z finalną architekturą: komunikacja przez WebSocket/SSE została
rozszerzona o socket UNIX dla szybszej komunikacji lokalnej (AF_UNIX).

Backend:
  - SSE endpoint: HTTP GET /api/v1/events/progress?task_id=*
  - Unix socket: /tmp/nexusai-progress.sock (AF_UNIX, lokalny IPC)

Frontend (Flet desktop) łączy się przez socket UNIX zamiast HTTP SSE,
co eliminuje narzut TCP loopback i HTTP.
"""

from __future__ import annotations

import asyncio
import json
import os
from collections.abc import AsyncGenerator
from typing import Any

import anyio
from litestar import get
from litestar.sse import SSEEvent
from structlog import get_logger

from nexus_ai.core.msgspec_utils import msgspec_dumps

logger = get_logger("nexus.api.ws")

# ── SSE (Server-Sent Events) infrastructure ──────────────────────────────

# Rejestr aktywnych subskrybentów SSE: task_id -> list[anyio.MemoryObjectSendStream]
_active_connections: dict[str, list[anyio.MemoryObjectSendStream[str]]] = {}

# Rejestr subskrybentów wildcard ("*" -- wszystkie zadania)
_wildcard_senders: list[anyio.MemoryObjectSendStream[str]] = []

# Rejestr flag anulowania: task_id -> anyio.Event
_cancel_flags: dict[str, anyio.Event] = {}

# ── Unix Socket infrastructure ──────────────────────────────────────────

UNIX_SOCKET_PATH = "/tmp/nexusai-progress.sock"

# Rejestr podłączonych klientów UNIX socket
_unix_clients: set[asyncio.StreamWriter] = set()
_unix_server: asyncio.AbstractServer | None = None


# ── SSE functions ────────────────────────────────────────────────────────


def register_connection(task_id: str, sender: anyio.MemoryObjectSendStream[str]) -> None:
    """Rejestruje subskrybenta SSE dla danego task_id.

    Gdy task_id=="*", rejestruje jako wildcard -- otrzymuje postęp WSZYSTKICH zadań.
    """
    if task_id == "*":
        if sender not in _wildcard_senders:
            _wildcard_senders.append(sender)
        return
    if task_id not in _active_connections:
        _active_connections[task_id] = []
    _active_connections[task_id].append(sender)


def unregister_connection(task_id: str, sender: anyio.MemoryObjectSendStream[str]) -> None:
    """Wyrejestrowuje subskrybenta SSE."""
    if task_id == "*":
        _wildcard_senders[:] = [s for s in _wildcard_senders if s is not sender]
        return
    if task_id in _active_connections:
        _active_connections[task_id] = [s for s in _active_connections[task_id] if s is not sender]
        if not _active_connections[task_id]:
            del _active_connections[task_id]


# ── Unix Socket functions ──────────────────────────────────────────────────


async def _handle_unix_client(reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
    """Obsługuje połączenie klienta UNIX socket.

    Rejestruje klienta i utrzymuje połączenie do momentu rozłączenia.
    Dane są wysyłane przez broadcast_progress() do wszystkich klientów.
    """
    _unix_clients.add(writer)
    try:
        # Utrzymuj połączenie do momentu rozłączenia przez klienta
        while True:
            data = await reader.read(1024)
            if not data:
                break
    except (ConnectionResetError, BrokenPipeError):
        pass
    finally:
        _unix_clients.discard(writer)
        try:
            writer.close()
            await writer.wait_closed()
        except Exception:
            pass


async def start_unix_progress_server() -> None:
    """Uruchamia serwer socket UNIX dla broadcastu postępu.

    Serwer nasłuchuje na UNIX_SOCKET_PATH i akceptuje połączenia
    od klientów Flet UI (UnixProgressClient).
    """
    global _unix_server

    if os.path.exists(UNIX_SOCKET_PATH):
        os.unlink(UNIX_SOCKET_PATH)

    try:
        _unix_server = await asyncio.start_unix_server(
            _handle_unix_client,
            path=UNIX_SOCKET_PATH,
        )
        logger.info(
            "[UNIX-SOCKET] Server postępu uruchomiony na %s",
            UNIX_SOCKET_PATH,
        )
    except Exception as exc:
        logger.warning(
            "[UNIX-SOCKET] Nie można uruchomić serwera: %s",
            exc,
        )


async def stop_unix_progress_server() -> None:
    """Zatrzymuje serwer socket UNIX i czyści połączenia."""
    global _unix_server

    # Zamknij wszystkie połączenia klienckie
    for writer in list(_unix_clients):
        try:
            writer.close()
            await writer.wait_closed()
        except Exception:
            pass
    _unix_clients.clear()

    # Zamknij serwer
    if _unix_server is not None:
        _unix_server.close()
        await _unix_server.wait_closed()
        _unix_server = None

    # Usuń plik socketa
    if os.path.exists(UNIX_SOCKET_PATH):
        try:
            os.unlink(UNIX_SOCKET_PATH)
        except Exception:
            pass

    logger.info("[UNIX-SOCKET] Serwer zatrzymany")


async def _broadcast_via_unix(progress: dict) -> None:
    """Wysyła zdarzenie postępu do wszystkich podłączonych klientów UNIX socket.

    Serializuje do JSON (newline-delimited) i wysyła do każdego klienta.
    Usuwa martwe połączenia.
    """
    if not _unix_clients:
        return

    payload = json.dumps(progress, ensure_ascii=False)
    dead: set[asyncio.StreamWriter] = set()

    for writer in _unix_clients:
        try:
            writer.write((payload + "\n").encode("utf-8"))
            await writer.drain()
        except Exception:
            dead.add(writer)

    if dead:
        _unix_clients -= dead


# ── Broadcast functions ──────────────────────────────────────────────────


async def broadcast_progress(task_id: str, progress: dict) -> None:
    """Wysyła zdarzenie postępu do wszystkich podłączonych klientów (SSE + UNIX socket).

    Wysyła:
      - do subskrybentów SSE konkretnego task_id oraz do wildcard ("*")
      - do wszystkich podłączonych klientów UNIX socket
    Usuwa martwe subskrypcje (przerwane połączenia).
    """
    payload = msgspec_dumps(progress)

    # Wyślij do subskrybentów SSE konkretnego task_id
    if task_id in _active_connections:
        dead: list[anyio.MemoryObjectSendStream[str]] = []
        for sender in _active_connections[task_id]:
            try:
                await sender.send(payload)
            except Exception:
                dead.append(sender)
        for sender in dead:
            unregister_connection(task_id, sender)

    # Wyślij do wildcard subskrybentów SSE ("*" -- wszystkie zadania)
    if _wildcard_senders:
        dead_wildcards: list[anyio.MemoryObjectSendStream[str]] = []
        for sender in _wildcard_senders:
            try:
                await sender.send(payload)
            except Exception:
                dead_wildcards.append(sender)
        for sender in dead_wildcards:
            unregister_connection("*", sender)

    # Wyślij do klientów UNIX socket
    await _broadcast_via_unix(progress)


# ── Cancel flags ──────────────────────────────────────────────────────────


def get_cancel_event(task_id: str) -> anyio.Event:
    """Zwraca (lub tworzy) flagę anulowania dla danego task_id."""
    if task_id not in _cancel_flags:
        _cancel_flags[task_id] = anyio.Event()
    return _cancel_flags[task_id]


def signal_cancel(task_id: str) -> None:
    """Sygnalizuje anulowanie zadania."""
    event = get_cancel_event(task_id)
    event.set()


def cleanup_cancel_flag(task_id: str) -> None:
    """Czyści flagę anulowania po zakończeniu zadania."""
    _cancel_flags.pop(task_id, None)


def is_cancelled(task_id: str) -> bool:
    """Sprawdza, czy zadanie zostało anulowane."""
    event = _cancel_flags.get(task_id)
    if event is None:
        return False
    return event.is_set()


# ── SSE endpoint ──────────────────────────────────────────────────────────


@get(path="/api/v1/events/progress", sync_to_thread=False)
async def progress_sse(request: Any) -> Any:
    """SSE endpoint do subskrypcji postępu zadań długotrwałych.

    Klient łączy się przez HTTP GET z query param ``?task_id=*``
    (lub konkretnym task_id) i otrzymuje zdarzenia SSE z postępem.

    Dla klientów lokalnych (Flet desktop) zalecane jest użycie socket UNIX
    (UnixProgressClient) zamiast SSE -- szybsza komunikacja bez narzutu HTTP.

    Format zdarzenia:
        data: {"type": "progress", "task_id": "...", "percent": 50, ...}
    """
    from litestar.response import Stream

    task_id = str(request.query_params.get("task_id", "*"))
    send, receive = anyio.create_memory_object_stream[str](max_buffer_size=256)
    register_connection(task_id, send)

    async def event_generator() -> AsyncGenerator[SSEEvent]:
        try:
            # Wyślij zdarzenie connected
            yield SSEEvent(
                data=msgspec_dumps(
                    {
                        "type": "connected",
                        "task_id": task_id,
                        "message": "Progress SSE stream ready",
                    }
                ),
            )

            async with receive:
                async for data in receive:
                    yield SSEEvent(data=data)
        except anyio.get_cancelled_exc_class():
            pass
        finally:
            unregister_connection(task_id, send)

    return Stream(content=event_generator(), media_type="text/event-stream")
