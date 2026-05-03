from __future__ import annotations

from litestar import Litestar
from litestar.config.cors import CORSConfig
from litestar.openapi.config import OpenAPIConfig
from litestar.openapi.plugins import SwaggerRenderPlugin

from api.dependencies import provide_config, provide_db_session, provide_duckdb, provide_shared_image_buffer
from api.exceptions import global_exception_handler
from api.middleware import CorrelationAndDeprecationMiddleware, UploadSizeGuardMiddleware
from api.rate_limit import SimpleRateLimitMiddleware
from api.routes.auth import AuthController
from api.routes.analytics import AnalyticsController
from api.routes.exports import ExportController
from api.routes.files import FileController
from api.routes.finops import FinOpsController
from api.routes.health import HealthController, HealthControllerV2
from api.routes.i18n_ops import I18nOpsController
from api.routes.kore_audit import KoreAuditController
from api.routes.invoices import InvoiceController, InvoiceControllerV2
from api.routes.live_preview import LivePreviewController
from api.routes.model_registry import ModelRegistryController
from api.routes.outbox_ops import OutboxOpsController
from api.routes.privacy import PrivacyController
from api.routes.performance_ops import PerformanceOpsController
from api.routes.tasks import TaskController
from api.routes.security_posture import SecurityPostureController
from api.routes.system_integrity import SystemIntegrityController
from api.routes.triage import TriageController
from api.routes.telemetry_ops import TelemetryOpsController
from api.routes.ws import progress_websocket
from api.static import get_static_config
from api.security import jwt_auth
from api.state import on_shutdown, on_startup

SUPPORTED_HEALTH_ENDPOINTS = ("/api/v1/health", "/api/v2/health")


def create_app() -> Litestar:
    """Single official backend bootstrap point."""
    config = provide_config()

    cors_allow_credentials = config.cors_origins != ["*"]

    return Litestar(
        route_handlers=[
            HealthController,
            HealthControllerV2,
            KoreAuditController,
            SystemIntegrityController,
            PrivacyController,
            FinOpsController,
            ModelRegistryController,
            OutboxOpsController,
            I18nOpsController,
            SecurityPostureController,
            PerformanceOpsController,
            TelemetryOpsController,
            InvoiceController,
            InvoiceControllerV2,
            LivePreviewController,
            AnalyticsController,
            TaskController,
            TriageController,
            ExportController,
            FileController,
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
        middleware=[UploadSizeGuardMiddleware, SimpleRateLimitMiddleware, CorrelationAndDeprecationMiddleware],
        cors_config=CORSConfig(allow_origins=config.cors_origins, allow_methods=["*"], allow_headers=["*"], allow_credentials=cors_allow_credentials),
        openapi_config=OpenAPIConfig(
            title="Nexus AI API",
            version="2.0.0",
            description=(
                "API lifecycle: /api/v1 (deprecated) and /api/v2 (current). "
                f"Health endpoints: {SUPPORTED_HEALTH_ENDPOINTS[0]}, {SUPPORTED_HEALTH_ENDPOINTS[1]}"
            ),
            render_plugins=[SwaggerRenderPlugin()],
        ),
        static_files_config=get_static_config(config),
        debug=config.debug,
    )
