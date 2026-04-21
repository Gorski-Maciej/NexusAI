from __future__ import annotations

import os

import uvicorn

from api.app import create_app

# ASGI object used by launchers (`uvicorn api.server:app`).
app = create_app()


def run_backend() -> None:
    """Entrypoint used by launcher/containers."""
    host = os.getenv("NEXUS_HOST", "127.0.0.1")
    port = int(os.getenv("NEXUS_PORT", "8000"))

    uvicorn.run(
        app,
        host=host,
        port=port,
        loop="asyncio",
        log_level=os.getenv("NEXUS_LOG_LEVEL", "info"),
        access_log=True,
    )


if __name__ == "__main__":
    run_backend()
