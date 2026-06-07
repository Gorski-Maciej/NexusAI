from __future__ import annotations

import os

import granian

from nexus_ai.api.app import create_app

# ASGI object.
app = create_app()


def run_backend() -> None:
    """Entrypoint used by launcher/containers.

    Uses Granian — Rust ASGI server (zastępuje Uvicorn).
    W trybie desktopowym nasłuchuje na gnieździe UNIX.
    """
    host = os.getenv("NEXUS_HOST", "127.0.0.1")
    port = int(os.getenv("NEXUS_PORT", "8000"))
    log_level = os.getenv("NEXUS_LOG_LEVEL", "info")

    # Użyj gniazda UNIX jeśli host to "unix"
    if host == "unix":
        socket_path = os.getenv("NEXUS_UNIX_SOCKET", "/tmp/nexus-api.sock")
        granian.Granian(
            "api.app:create_app",
            unix_socket=socket_path,
            log_level=log_level,
        ).serve()
    else:
        granian.Granian(
            "api.app:create_app",
            host=host,
            port=port,
            log_level=log_level,
        ).serve()


if __name__ == "__main__":
    run_backend()
