from __future__ import annotations

import re

from litestar import Litestar
from litestar.config.cors import CORSConfig
from litestar.config.csrf import CSRFConfig
from litestar.openapi.config import OpenAPIConfig
from litestar.openapi.plugins import SwaggerRenderPlugin

from nexus_ai.api.dependencies import provide_config as _app_config_provider

from nexus_ai.api.dependencies import (
    provide_config,
    provide_db_engine,
    provide_db_session,
    provide_duckdb,
    provide_shared_image_buffer,
    provide_tenant_manager,
)
from nexus_ai.api.exceptions import global_exception_handler
from nexus_ai.api.metrics_middleware import MetricsMiddleware
from nexus_ai.api.middleware import (
    CorrelationAndDeprecationMiddleware,
    UploadSizeGuardMiddleware,
)
from nexus_ai.api.rate_limit import SimpleRateLimitMiddleware
from nexus_ai.api.routes.admin import AdminController
from nexus_ai.api.routes.analytics import AnalyticsController
from nexus_ai.api.routes.auth import AuthController
from nexus_ai.api.routes.autopilot import AutopilotController
from nexus_ai.api.routes.circuit_breakers import CircuitBreakerController
from nexus_ai.api.routes.dashboard import DashboardController
from nexus_ai.api.routes.dlq import DLQController
from nexus_ai.api.routes.exports import ExportController
from nexus_ai.api.routes.files import FileController
from nexus_ai.api.routes.finops import FinOpsController
from nexus_ai.api.routes.fx import FXController
from nexus_ai.api.routes.health import HealthController, HealthControllerV2
from nexus_ai.api.routes.i18n_ops import I18nOpsController
from nexus_ai.api.routes.invoices import InvoiceController, InvoiceControllerV2
from nexus_ai.api.routes.kore_audit import KoreAuditController
from nexus_ai.api.routes.kore_closure import KoreClosureController
from nexus_ai.api.routes.live_preview import LivePreviewController
from nexus_ai.api.routes.metrics import MetricsController
from nexus_ai.api.routes.outbox_ops import OutboxOpsController
from nexus_ai.api.routes.partner import PartnerController
from nexus_ai.api.routes.performance_ops import PerformanceOpsController
from nexus_ai.api.routes.privacy import PrivacyController
from nexus_ai.api.routes.risk import RiskController
from nexus_ai.api.routes.security_posture import SecurityPostureController
from nexus_ai.api.routes.system_integrity import SystemIntegrityController
from nexus_ai.api.routes.tasks import TaskController
from nexus_ai.api.routes.tax_math import TaxMathController
from nexus_ai.api.routes.tax_policy import TaxPolicyController
from nexus_ai.api.routes.telemetry_ops import TelemetryOpsController
from nexus_ai.api.routes.triage import TriageController, TriageControllerV2
from nexus_ai.api.routes.ui_state import UIStateController
from nexus_ai.api.routes.version import VersionController
from nexus_ai.api.routes.workers import WorkerStatusController
from nexus_ai.api.routes.ws import progress_sse
from nexus_ai.api.security import jwt_auth
from nexus_ai.api.state import on_shutdown, on_startup
from nexus_ai.api.static import get_static_config
from nexus_ai.services.currency_converter import Money, msgspec_money_enc_hook

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
            KoreClosureController,
            SystemIntegrityController,
            PrivacyController,
            FinOpsController,
            OutboxOpsController,
            I18nOpsController,
            SecurityPostureController,
            PerformanceOpsController,
            TelemetryOpsController,
            InvoiceController,
            InvoiceControllerV2,
            LivePreviewController,
            AnalyticsController,
            DashboardController,
            PartnerController,
            TaskController,
            TriageController,
            TriageControllerV2,
            ExportController,
            FileController,
            AuthController,
            AdminController,
            UIStateController,
            AutopilotController,
            MetricsController,
            CircuitBreakerController,
            VersionController,
            FXController,
            DLQController,
            RiskController,
            WorkerStatusController,
            TaxPolicyController,
            TaxMathController,
            progress_sse,
        ],
        on_app_init=[jwt_auth.on_app_init],
        on_startup=[on_startup],
        on_shutdown=[on_shutdown],
        dependencies={
            "config": provide_config,
            "tenant_manager": provide_tenant_manager,
            "db_session": provide_db_session,
            "db_engine": provide_db_engine,
            "duckdb": provide_duckdb,
            "buffer": provide_shared_image_buffer,
        },
        exception_handlers={Exception: global_exception_handler},
        middleware=[UploadSizeGuardMiddleware, SimpleRateLimitMiddleware, CorrelationAndDeprecationMiddleware, MetricsMiddleware],
        cors_config=CORSConfig(allow_origins=config.cors_origins, allow_methods=["*"], allow_headers=["*"], allow_credentials=cors_allow_credentials),
        csrf_config=CSRFConfig(
            secret=config.jwt_secret or "dev-csrf-secret",
            cookie_name="csrf_token",
            header_name="X-CSRF-Token",
            safe_methods={"GET", "HEAD", "OPTIONS", "TRACE"},
            exclude=[
                # Wszystkie endpointy /api/auth/* (rejestracja, logowanie, refresh, itp.)
                re.compile(r"^/api/auth/"),
                # Wszystkie endpointy /health
                re.compile(r"/health"),
            ],
        ) if config.csrf_enabled else None,
        # OpenAPI/Swagger wyłączone w produkcji zgodnie z aa3fvcx.txt (Punkt 3).
        # W trybie desktopowym (Flet) Swagger UI jest zbędny — oszczędza RAM i czas startu.
        # Import SwaggerRenderPlugin na górze pliku jest bezpieczny (import klasy = 0 kosztu).
        openapi_config=OpenAPIConfig(
            title="Nexus AI API",
            version="2.0.0",
            description=(
                "API lifecycle: /api/v1 (deprecated) and /api/v2 (current). "
                f"Health endpoints: {SUPPORTED_HEALTH_ENDPOINTS[0]}, {SUPPORTED_HEALTH_ENDPOINTS[1]}"
            ),
            render_plugins=[SwaggerRenderPlugin()],
        ) if config.debug else None,
        static_files_config=get_static_config(config),
        debug=config.debug,
        type_encoders={Money: msgspec_money_enc_hook},
    )
