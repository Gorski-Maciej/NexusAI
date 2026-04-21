import os
import secrets
import asyncio
from typing import AsyncGenerator
import uvicorn
from litestar import Litestar, get, Response
from litestar.di import Provide
from litestar.config.cors import CORSConfig
from litestar.status_codes import HTTP_200_OK, HTTP_401_UNAUTHORIZED
from sqlalchemy.ext.asyncio import AsyncSession
from core.config import AppConfig
from db.database import create_oltp_engine, create_session_factory
from db.analytics import DuckDBManager
from api.security import token_guard
from api.controllers.invoices import InvoiceController
from api.controllers.analytics import AnalyticsController

# Konfiguracja wstrzykiwania zależności bazy danych
async def provide_db_session() -> AsyncGenerator[AsyncSession, None]:
    config = AppConfig()
    engine = create_oltp_engine(config)
    factory = create_session_factory(engine)
    async with factory() as session:
        yield session

class RuntimeState:
    def __init__(self, bootstrap_token: str):
        self.bootstrap_token = bootstrap_token

def create_runtime_state() -> RuntimeState:
    """Create runtime state with secure random bootstrap token."""
    return RuntimeState(bootstrap_token=secrets.token_urlsafe(32))

def _is_authorized(expected_token: str, received_token: str | None) -> bool:
    """Constant-time bootstrap token check."""
    if not received_token:
        return False
    return secrets.compare_digest(expected_token, received_token)

@get("/health", exclude_from_auth=True)
async def health_check() -> dict:
    return {"status": "ok", "service": "nexus_api", "system": "Nexus Accounting OS"}

def create_app(state: RuntimeState, olap_manager: DuckDBManager) -> Litestar:
    """Buduje aplikację Litestar z wstrzykniętym managerem DuckDB."""
    return Litestar(
        route_handlers=[
            health_check,
            InvoiceController,
            AnalyticsController,
        ],
        state={
            "olap_manager": olap_manager,
            "bootstrap_token": state.bootstrap_token
        },
        guards=[token_guard], # Aktywujemy strażnika globalnie
    )

async def serve() -> None:
    pass # Implementacja serwera np. dla Nuitki

def run() -> None:
    """Entrypoint compatible with direct python execution and Nuitka."""
    if os.name == "nt":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(serve())

def run_backend():
    """Uruchamia produkcyjną instancję serwera API."""
    state = create_runtime_state()
    olap_manager = DuckDBManager(db_path="nexus_olap.duckdb")
    app = create_app(state, olap_manager)

    uvicorn_config = uvicorn.Config(
        app=app,
        host="127.0.0.1",
        port=8000,
        loop="asyncio",
        log_level="info",
        reload=False,
        workers=1,
        access_log=True,
    )
    # Server start logic
