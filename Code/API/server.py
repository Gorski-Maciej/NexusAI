from __future__ import annotations

import uvicorn

from api.app import create_app


def run_backend() -> None:
    """Entrypoint used by launcher/containers."""
    uvicorn.run(
        create_app(),
        host="127.0.0.1",
        port=8000,
        loop="asyncio",
        log_level="info",
        access_log=True,
    )
