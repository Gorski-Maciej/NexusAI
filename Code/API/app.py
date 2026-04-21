from litestar import Litestar
from litestar.config.cors import CORSConfig
from litestar.openapi.config import OpenAPIConfig
from litestar.openapi.plugins import SwaggerRenderPlugin
from litestar.di import Provide

from core.config import AppConfig
from api.dependencies import provide_db_session, provide_duckdb
from api.routes.invoices import InvoiceController
from api.routes.analytics import AnalyticsController
from api.routes.exports import ExportController
from api.routes.health import HealthController
from api.routes.tasks import TaskController
from api.routes.ws import progress_websocket
from api.exceptions import global_exception_handler
from api.static import get_static_config
from api.middleware import AuditMiddleware

def create_app() -> Litestar:
    """Fabryka aplikacji dla absolutnego maksimum (Enterprise)."""
    config = AppConfig()

    cors_config = CORSConfig(
        allow_origins=["*"], # W produkcji ograniczyć do UI
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["*"]
    )

    openapi_config = OpenAPIConfig(
        title="Nexus AI API",
        version="1.0.0",
        description="API do zarządzania fakturami i analityką",
        render_plugins=[SwaggerRenderPlugin()]
    )

    return Litestar(
        route_handlers=[
            HealthController,
            InvoiceController,
            AnalyticsController,
            TaskController,
            ExportController,
            progress_websocket
        ],
        dependencies={
            "config": lambda: config, # Singleton konfiguracji
            "db_session": provide_db_session,
            "duckdb": provide_duckdb,
        },
        exception_handlers={Exception: global_exception_handler},
        middleware=[AuditMiddleware], # Aktywacja audytu
        static_files_config=get_static_config(config), # Serwowanie PDF
        compression_config={"backend": "gzip", "minimum_size": 1024},
        debug=config.debug
    )
