from __future__ import annotations

from litestar import Litestar, get
from litestar.config.cors import CORSConfig
from litestar.openapi.config import OpenAPIConfig
from litestar.openapi.plugins import SwaggerRenderPlugin

from api.dependencies import provide_config, provide_db_session, provide_duckdb, provide_shared_image_buffer
from api.exceptions import global_exception_handler
from api.middleware import CorrelationAndDeprecationMiddleware
from api.routes.auth import AuthController
from api.routes.analytics import AnalyticsController
from api.routes.exports import ExportController
from api.routes.health import HealthController
from api.routes.invoices import InvoiceController
from api.routes.live_preview import LivePreviewController
from api.routes.tasks import TaskController
from api.routes.triage import TriageController
from api.routes.ws import progress_websocket
from api.static import get_static_config
from api.security import jwt_auth
from api.state import on_shutdown, on_startup


@get("/api/v2/health")
async def health_v2() -> dict[str, str]:
    return {"api": "OK", "version": "v2"}


def create_app() -> Litestar:
    """Single official backend bootstrap point."""
    config = provide_config()

    return Litestar(
        route_handlers=[
            HealthController,
            health_v2,
            InvoiceController,
            LivePreviewController,
            AnalyticsController,
            TaskController,
            TriageController,
            ExportController,
            AuthController,
            progress_websocket,
        ],
        on_app_init=[jwt_auth.on_app_init],
        on_startup=[on_startup],
        on_shutdown=[on_shutdown],
        dependencies={
            "config": provide_config,
            "db_session": provide_db_session,
            "duckdb": provide_duckdb,
            "buffer": provide_shared_image_buffer,
        },
        exception_handlers={Exception: global_exception_handler},
        middleware=[CorrelationAndDeprecationMiddleware],
        cors_config=CORSConfig(allow_origins=["*"], allow_methods=["*"], allow_headers=["*"]),
        openapi_config=OpenAPIConfig(
            title="Nexus AI API",
            version="2.0.0",
            description="API lifecycle: /api/v1 (deprecated) and /api/v2 (current)",
            render_plugins=[SwaggerRenderPlugin()],
        ),
        static_files_config=get_static_config(config),
        debug=config.debug,
    )
