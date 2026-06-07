from __future__ import annotations

import asyncio
from structlog import get_logger
from typing import Any

from litestar import websocket

from nexus_ai.core.msgspec_utils import DecodeError, msgspec_loads

logger = get_logger("nexus.api.ws")

# Rejestr aktywnych połączeń WebSocket: task_id -> list[socket]
_active_connections: dict[str, list[Any]] = {}

# Rejestr flag anulowania: task_id -> asyncio.Event
_cancel_flags: dict[str, asyncio.Event] = {}

# Rejestr połączeń wildcard (subskrybuje wszystkie zadania)
_wildcard_connections: list[Any] = []


def register_connection(task_id: str, socket: Any) -> None:
    """Rejestruje połączenie WebSocket dla danego task_id.
    Gdy task_id=="*", rejestruje jako wildcard — otrzymuje postęp WSZYSTKICH zadań.
    """
    if task_id == "*":
        if socket not in _wildcard_connections:
            _wildcard_connections.append(socket)
        return
    if task_id not in _active_connections:
        _active_connections[task_id] = []
    _active_connections[task_id].append(socket)


def unregister_connection(task_id: str, socket: Any) -> None:
    """Wyrejestrowuje połączenie WebSocket."""
    if task_id == "*":
        _wildcard_connections[:] = [s for s in _wildcard_connections if s is not socket]
        return
    if task_id in _active_connections:
        _active_connections[task_id] = [s for s in _active_connections[task_id] if s is not socket]
        if not _active_connections[task_id]:
            del _active_connections[task_id]


async def broadcast_progress(task_id: str, progress: dict) -> None:
    """Wysyła postęp do wszystkich podłączonych klientów dla danego taska.
    Wysyła również do klientów wildcard (subskrybujących wszystkie zadania).
    """
    # Wyślij do subskrybentów konkretnego task_id
    if task_id in _active_connections:
        dead_sockets = []
        for socket in _active_connections[task_id]:
            try:
                await socket.send_json(progress)
            except Exception:
                dead_sockets.append(socket)
        for socket in dead_sockets:
            unregister_connection(task_id, socket)

    # Wyślij do wildcard subskrybentów ("*" — wszystkie zadania)
    if _wildcard_connections:
        dead_wildcards = []
        for socket in _wildcard_connections:
            try:
                await socket.send_json(progress)
            except Exception:
                dead_wildcards.append(socket)
        for socket in dead_wildcards:
            unregister_connection("*", socket)


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


@websocket(path="/api/v1/ws/progress")
async def progress_websocket(socket: Any) -> None:
    """
    WebSocket do subskrypcji postępu zadań długotrwałych.
    Rozwiązanie 17: Klient wysyła task_id, a serwer przekazuje zdarzenia postępu.
    """
    await socket.accept()
    await socket.send_json({"status": "connected", "message": "Progress WebSocket ready"})

    registered_task_id: str | None = None

    try:
        while True:
            try:
                raw = await asyncio.wait_for(socket.receive_text(), timeout=60.0)
            except TimeoutError:
                # Ping keep-alive
                try:
                    await socket.send_json({"type": "ping"})
                except Exception:
                    break
                continue

            if not raw:
                continue

            try:
                msg = msgspec_loads(raw)
            except DecodeError:
                continue

            msg_type = msg.get("type", "")

            if msg_type == "subscribe":
                task_id = msg.get("task_id", "")
                if task_id:
                    registered_task_id = task_id
                    register_connection(task_id, socket)
                    label = "all tasks" if task_id == "*" else f"task {task_id}"
                    await socket.send_json({
                        "type": "subscribed",
                        "task_id": task_id,
                        "message": f"Subscribed to progress for {label}",
                    })
            elif msg_type == "unsubscribe":
                if registered_task_id:
                    unregister_connection(registered_task_id, socket)
                    registered_task_id = None
                    await socket.send_json({"type": "unsubscribed"})
            elif msg_type == "pong":
                pass  # Keep-alive response
    except Exception:
        pass
    finally:
        if registered_task_id:
            unregister_connection(registered_task_id, socket)
