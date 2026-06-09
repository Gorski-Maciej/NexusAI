"""
SSE (Server-Sent Events) endpoint for progress updates.

Zgodnie z aa3fvcx.txt: websockets zastąpione przez SSE + httpx.
Klient łączy się przez HTTP GET /api/v1/events/progress?task_id=*
i otrzymuje zdarzenia postępu w formacie SSE (data: {...}).

Litestar natywnie wspiera SSE przez Stream + SSEEvent.
"""
from __future__ import annotations

import asyncio
from typing import Any, AsyncGenerator

from litestar import get
from litestar.sse import SSEEvent
from structlog import get_logger

from nexus_ai.core.msgspec_utils import msgspec_dumps

logger = get_logger("nexus.api.ws")

# Rejestr aktywnych subskrybentów: task_id -> list[asyncio.Queue]
# Każdy podłączony klient SSE ma własną kolejkę asyncio.
_active_connections: dict[str, list[asyncio.Queue[str]]] = {}

# Rejestr subskrybentów wildcard ("*" — wszystkie zadania)
_wildcard_connections: list[asyncio.Queue[str]] = []

# Rejestr flag anulowania: task_id -> asyncio.Event
_cancel_flags: dict[str, asyncio.Event] = {}


def register_connection(task_id: str, queue: asyncio.Queue[str]) -> None:
    """Rejestruje subskrybenta SSE dla danego task_id.
    Gdy task_id=="*", rejestruje jako wildcard — otrzymuje postęp WSZYSTKICH zadań.
    """
    if task_id == "*":
        if queue not in _wildcard_connections:
            _wildcard_connections.append(queue)
        return
    if task_id not in _active_connections:
        _active_connections[task_id] = []
    _active_connections[task_id].append(queue)


def unregister_connection(task_id: str, queue: asyncio.Queue[str]) -> None:
    """Wyrejestrowuje subskrybenta SSE."""
    if task_id == "*":
        _wildcard_connections[:] = [q for q in _wildcard_connections if q is not queue]
        return
    if task_id in _active_connections:
        _active_connections[task_id] = [q for q in _active_connections[task_id] if q is not queue]
        if not _active_connections[task_id]:
            del _active_connections[task_id]


async def broadcast_progress(task_id: str, progress: dict) -> None:
    """Wysyła zdarzenie postępu do wszystkich podłączonych klientów SSE.

    Wysyła do subskrybentów konkretnego task_id oraz do wildcard ("*").
    Usuwa martwe subskrypcje (przerwane połączenia).
    """
    payload = msgspec_dumps(progress)

    # Wyślij do subskrybentów konkretnego task_id
    if task_id in _active_connections:
        dead: list[asyncio.Queue[str]] = []
        for queue in _active_connections[task_id]:
            try:
                await queue.put(payload)
            except Exception:
                dead.append(queue)
        for queue in dead:
            unregister_connection(task_id, queue)

    # Wyślij do wildcard subskrybentów ("*" — wszystkie zadania)
    if _wildcard_connections:
        dead_wildcards: list[asyncio.Queue[str]] = []
        for queue in _wildcard_connections:
            try:
                await queue.put(payload)
            except Exception:
                dead_wildcards.append(queue)
        for queue in dead_wildcards:
            unregister_connection("*", queue)


def get_cancel_event(task_id: str) -> asyncio.Event:
    """Zwraca (lub tworzy) flagę anulowania dla danego task_id."""
    if task_id not in _cancel_flags:
        _cancel_flags[task_id] = asyncio.Event()
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


@get(path="/api/v1/events/progress", sync_to_thread=False)
async def progress_sse(request: Any) -> Any:
    """SSE endpoint do subskrypcji postępu zadań długotrwałych.

    Klient łączy się przez HTTP GET z query param ``?task_id=*``
    (lub konkretnym task_id) i otrzymuje zdarzenia SSE z postępem.

    Format zdarzenia:
        data: {"type": "progress", "task_id": "...", "percent": 50, ...}

    Zastępuje: websockets → SSE (Server-Sent Events)
    """
    from litestar.response import Stream

    task_id = str(request.query_params.get("task_id", "*"))
    queue: asyncio.Queue[str] = asyncio.Queue(maxsize=256)
    register_connection(task_id, queue)

    async def event_generator() -> AsyncGenerator[SSEEvent, None]:
        try:
            # Wyślij zdarzenie connected
            yield SSEEvent(
                data=msgspec_dumps({
                    "type": "connected",
                    "task_id": task_id,
                    "message": "Progress SSE stream ready",
                }),
            )

            while True:
                try:
                    data = await asyncio.wait_for(queue.get(), timeout=60.0)
                    yield SSEEvent(data=data)
                except asyncio.TimeoutError:
                    # Ping keep-alive — pusta linia wystarczy dla SSE
                    yield SSEEvent(data="", event="ping")
        except asyncio.CancelledError:
            pass
        finally:
            unregister_connection(task_id, queue)

    return Stream(content=event_generator(), media_type="text/event-stream")
