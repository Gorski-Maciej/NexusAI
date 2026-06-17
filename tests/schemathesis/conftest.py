"""
conftest.py — Konfiguracja testów schemathesis dla NexusAI API.

SUPERMOCE schemathesis:
  - from_asgi() — native ASGI integration, zero network overhead
  - hooks system (before_process_request, after_call) — auth injection,
    request/response introspection, logowanie
  - custom checks — domain-specific validation rules dla polskiego systemu
    księgowego (VAT, split payment, JPK, KSeF)

Usage:
    pytest tests/schemathesis/ -v --run-schemathesis

Inspiracja:
  - posthog/posthog: schemathesis w CI dla każdego PR
  - schemathesis.readthedocs.io: oficjalne wzorce
"""

from __future__ import annotations

import logging
import os
import uuid

import pytest
import schemathesis
from litestar import Litestar, Router
from litestar.openapi.config import OpenAPIConfig
from litestar.openapi.plugins import SwaggerRenderPlugin

logger = logging.getLogger("nexus.tests.schemathesis")


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC: schema_from_app() — tworzy schemat ASGI z hookami wewnątrz
# ═══════════════════════════════════════════════════════════════════════════════
# UWAGA: Hooki są rejestrowane WEWNĄTRZ tej funkcji (nie jako dekoratory na
# poziomie modułu), aby uniknąć AttributeError przy imporcie.
# ═══════════════════════════════════════════════════════════════════════════════


def schema_from_app() -> tuple[schemathesis.schemas.ASGISchema, Litestar]:
    """Create schemathesis schema + ASGI app with hooks registered.

    SUPERMOC: from_asgi() ładuje OpenAPI bezpośrednio z aplikacji
    ASGI, bez potrzeby serwera HTTP. Zwraca krotkę (schema, app) —
    app jest potrzebna dla AsyncTestClient w testach stateful.

    Hooks (zarejestrowane wewnątrz):
      - before_process_request: JWT auth token injection + trace headers
      - after_call: Logowanie naruszeń schematu

    Returns:
        tuple[ASGISchema, Litestar]: (schema, app) do testowania.
    """
    app = _create_schema_test_app()
    schema_instance = schemathesis.from_asgi(
        "/schema/openapi.yml",
        app,
    )

    # ── SUPERMOC: before_process_request hook — wstrzykiwanie tokena JWT ──
    # Rejestrowany WEWNĄTRZ funkcji, NIE jako dekorator na fixture.

    @schema_instance.before_process_request
    def add_auth_token(context: object, case: object) -> None:
        """Inject JWT auth token for protected endpoints.

        SUPERMOC: before_process_request hook — modyfikuje case przed
        wysłaniem. Drugi argument to schemathesis.Case (nie request HTTP).
        Wstrzykuje Bearer token dla endpointów wymagających auth.
        """
        token = os.getenv("SCHEMATESIS_JWT_TOKEN", "")
        if token:
            case.headers.setdefault("Authorization", f"Bearer {token}")
            logger.debug("Added JWT token via SCHEMATESIS_JWT_TOKEN")

    @schema_instance.before_process_request
    def add_trace_headers(context: object, case: object) -> None:
        """Add tracing headers for request correlation."""
        if not hasattr(case, "headers"):
            return
        case.headers.setdefault("X-Request-ID", uuid.uuid4().hex[:12])
        case.headers.setdefault("X-Schemathesis", "true")

    @schema_instance.after_call
    def log_schema_violations(
        context: object,
        case: object,
        response: object,
    ) -> None:
        """Log OpenAPI schema violations for debugging."""
        status = getattr(response, "status_code", 0)
        if status >= 400:
            method = getattr(case, "method", "?")
            path = getattr(case, "path", "?")
            logger.warning(
                "Schema violation: %s %s → %s",
                method,
                path,
                status,
            )

    return schema_instance, app


# ═══════════════════════════════════════════════════════════════════════════════
# Helper — tworzy aplikację testową ze wszystkimi kontrolerami
# ═══════════════════════════════════════════════════════════════════════════════


def _create_schema_test_app() -> Litestar:
    """Create a Litestar app with ALL controllers registered.

    Aplikacja zawiera wszystkie kontrolery API, aby schemathesis miał pełen
    OpenAPI spec do walidacji. Używa pustych on_startup/on_shutdown
    (bez rzeczywistych serwisów: DB, NATS, DuckDB).

    Kontrolery są importowane z rzeczywistego kodu — to zapewnia, że schemat
    OpenAPI jest identyczny z produkcyjnym.
    """
    from nexus_ai.api.routes.admin import AdminController
    from nexus_ai.api.routes.analytics import AnalyticsController
    from nexus_ai.api.routes.auth import AuthController
    from nexus_ai.api.routes.autopilot import AutopilotController
    from nexus_ai.api.routes.circuit_breakers import CircuitBreakerController
    from nexus_ai.api.routes.dashboard import DashboardController
    from nexus_ai.api.routes.dlq import DLQController
    from nexus_ai.api.routes.events_schema import EventsSchemaController
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
    from nexus_ai.api.routes.outbox_ops import OutboxOpsController
    from nexus_ai.api.routes.partner import PartnerController
    from nexus_ai.api.routes.performance_ops import PerformanceOpsController
    from nexus_ai.api.pdf_endpoints import PDFController
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

    # ── Layered Architecture: Routery wg wersji API ────────────────────
    v1_router = Router(
        path="/api/v1",
        tags=["v1"],
        route_handlers=[
            HealthController,
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
            LivePreviewController,
            TaskController,
            TriageController,
            ExportController,
            FileController,
            UIStateController,
            CircuitBreakerController,
            FXController,
            DLQController,
            WorkerStatusController,
        ],
    )

    v2_router = Router(
        path="/api/v2",
        tags=["v2"],
        route_handlers=[
            HealthControllerV2,
            InvoiceControllerV2,
            TriageControllerV2,
            AnalyticsController,
            DashboardController,
            PartnerController,
            AutopilotController,
            TaxMathController,
            TaxPolicyController,
            RiskController,
            EventsSchemaController,
            PDFController,
        ],
    )

    unversioned_router = Router(
        path="/api",
        route_handlers=[
            AuthController,
            AdminController,
            VersionController,
        ],
    )

    # ── OpenAPI / Swagger ─────────────────────────────────────────────
    openapi_config = OpenAPIConfig(
        title="Nexus AI API (Schemathesis Test)",
        version="2.0.0",
        description=(
            "Test schema for schemathesis property-based API testing. "
            "Contains ALL production controllers for complete OpenAPI spec coverage."
        ),
        render_plugins=[SwaggerRenderPlugin()],
    )

    # ── Exception handlers — catch-all dla 500 (test app bez DB/NATS) ──
    # Bez tego, endpointy które próbują użyć DB/NATS/DuckDB rzucają 500.
    # Exception handler zwraca 500 z JSON body zamiast crashować test.
    from litestar import Response
    from litestar.status_codes import HTTP_500_INTERNAL_SERVER_ERROR

    def _catch_all_handler(request: object, exc: Exception) -> Response:
        """Catch-all exception handler for schemathesis test app.

        Zwraca 500 z komunikatem — schemathesis sprawdzi czy status code
        jest zgodny ze schematem (niekoniecznie 200).
        """
        return Response(
            content={"error": str(exc)[:200], "status": "error"},
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
        )

    app = Litestar(
        route_handlers=[
            v1_router,
            v2_router,
            unversioned_router,
        ],
        openapi_config=openapi_config,
        on_startup=[],
        on_shutdown=[],
        exception_handlers={Exception: _catch_all_handler},
        debug=True,
    )
    return app
