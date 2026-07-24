from __future__ import annotations

import re
from typing import Any

from litestar import Litestar, Router
from litestar.config.cors import CORSConfig
from litestar.config.csrf import CSRFConfig
from litestar.config.response_cache import ResponseCacheConfig
from litestar.connection import ASGIConnection, Request
from litestar.handlers.base import BaseRouteHandler
from litestar.middleware.rate_limit import RateLimitConfig
from litestar.openapi.config import OpenAPIConfig
from litestar.openapi.plugins import SwaggerRenderPlugin
from litestar.plugins.opentelemetry import OpenTelemetryPlugin
from litestar.plugins.problem_details import ProblemDetailsConfig, ProblemDetailsPlugin
from litestar.plugins.prometheus import PrometheusConfig, PrometheusController
from litestar.plugins.sqlalchemy import SQLAlchemyConfig, SQLAlchemyPlugin
from litestar.response import Response
from structlog import get_logger as _get_logger

from nexus_ai.api.dependencies import (
    provide_config,
    provide_db_engine,
    provide_duckdb,
    provide_shared_image_buffer,
    provide_tenant_manager,
)
from nexus_ai.api.exceptions import EXCEPTION_HANDLERS
from nexus_ai.api.middleware import (
    TenantContextMiddleware,
)
from nexus_ai.api.pdf_endpoints import PDFController
from nexus_ai.api.routes.admin import AdminController
from nexus_ai.api.routes.analytics import AnalyticsController
from nexus_ai.api.routes.auth import AuthController
from nexus_ai.api.routes.autopilot import AutopilotController
from nexus_ai.api.routes.system_ops import CircuitBreakerController
from nexus_ai.api.routes.dashboard import DashboardController
from nexus_ai.api.routes.dlq import DLQController
from nexus_ai.api.routes.events_schema import EventsSchemaController
from nexus_ai.api.routes.exports import ExportController
from nexus_ai.api.routes.files import FileController
from nexus_ai.api.routes.system_ops import FinOpsController
from nexus_ai.api.routes.health import HealthController
from nexus_ai.api.routes.system_ops import I18nOpsController
from nexus_ai.api.routes.invoices import InvoiceController
from nexus_ai.api.routes.system_ops import KoreAuditController
from nexus_ai.api.routes.kore_closure import KoreClosureController
from nexus_ai.api.routes.live_preview import LivePreviewController
from nexus_ai.api.routes.outbox_ops import OutboxOpsController
from nexus_ai.api.routes.partner import PartnerController
from nexus_ai.api.routes.performance_ops import PerformanceOpsController
from nexus_ai.api.routes.system_ops import PrivacyController
from nexus_ai.api.routes.risk import RiskController
from nexus_ai.api.routes.contractor import ContractorController
from nexus_ai.api.routes.security_alert import SecurityAlertController
from nexus_ai.api.routes.system_ops import SecurityPostureController
from nexus_ai.api.routes.system_ops import SecurityTxtController
from nexus_ai.api.routes.system_integrity import SystemIntegrityController
from nexus_ai.api.routes.tasks import TaskController
from nexus_ai.api.routes.tax_math import TaxMathController
from nexus_ai.api.routes.tax_policy import TaxPolicyController
from nexus_ai.api.routes.system_ops import TelemetryOpsController
from nexus_ai.api.routes.triage import TriageController
from nexus_ai.api.routes.ui_state import UIStateController
from nexus_ai.api.routes.system_ops import VersionController
from nexus_ai.api.routes.workers import WorkerStatusController
from nexus_ai.api.routes.ws import progress_sse
from nexus_ai.api.routes.proof_chain_export import ProofChainExportController, CSPReportController
from nexus_ai.api.security import jwt_auth, jwt_cookie_auth
from nexus_ai.api.state import make_on_startup, on_shutdown
from nexus_ai.api.static import get_static_config
from nexus_ai.db.database import create_session_factory

# Używany przez RateLimitConfig.identifier_for_request w create_app().
# Zdefiniowany na poziomie modułu dla testowalności.


def _role_aware_identifier(request: Request) -> str:
    """Per-role rate limiting identifier.

    Zwraca role-aware klucz dla RateLimitMiddleware:
    - Zalogowani: ``user:{role}:{user.id}`` -- admini mają wyższe limity
    - Auth endpoints: ``auth:{ip}`` -- brute-force protection per-IP
    - Niezalogowani: ``anon:{ip}`` -- standardowy limit

    Używa ``request.url.path`` zamiast    ``str(request.url)`` dla
    precyzyjnego dopasowania ścieżki bez fałszywych trafień z query string.

    Uwaga: request.client to tuple (host, port) w ASGI -- używamy [0] dla hosta.
    Nie request.client.host -- to nie jest obiekt, a tuple!
    """
    user = getattr(request, "user", None)
    if user:
        role = getattr(user, "role", "viewer")
        return f"user:{role}:{user.id}"
    path = getattr(request.url, "path", "/")
    # Auth endpoints (login/register): strict limit per-IP
    client_host = request.client[0] if request.client else "unknown"
    if path.startswith("/api/auth/"):
        return f"auth:{client_host}"
    return f"anon:{client_host}"


SUPPORTED_HEALTH_ENDPOINTS = ("/api/v1/health", "/api/v2/health")


# ── GraphQL plugin lazy init (v7.0 INNOWACJA #7) ─────────────────────
_GRAPHQL_PLUGIN: Any = None


def _get_graphql_plugin() -> Any:
    """Lazy-load GraphQL Strawberry plugin — tylko jeśli dostępny.

    SUPERMOC v7.0: GraphQL endpoint przez Litestar Strawberry.
    Importowany leniwie żeby nie blokować startu bez strawberry-graphql.
    """
    global _GRAPHQL_PLUGIN
    # Sentinel: None = nie próbowano, False = próbowano i nie udało się
    if _GRAPHQL_PLUGIN is False:
        return None
    if _GRAPHQL_PLUGIN is not None:
        return _GRAPHQL_PLUGIN
    try:
        from nexus_ai.api.graphql import create_graphql_plugin
        _GRAPHQL_PLUGIN = create_graphql_plugin()
        return _GRAPHQL_PLUGIN or None  # create_graphql_plugin może zwrócić None
    except ImportError:
        _GRAPHQL_PLUGIN = False  # Sentinel: nie próbuj ponownie
        return None


# ── Router-level guards dla Layered Architecture ──────────────────────
# V1 guard -- ostrzeżenie o deprecation dla klientów
# V2 guard -- weryfikacja minimalnej wersji klienta (Accept-Version)


def _v1_guard(connection: ASGIConnection, _: BaseRouteHandler) -> None:
    """V1 guard: loguje użycie deprecated API.
    Docelowo może blokować nowych klientów po dacie sunset."""
    _get_logger("nexus.api.versioning").warning(
        "Deprecated API v1 called: path=%s method=%s",
        connection.url.path,
        connection.method,
    )


# ── Router-level after_request hooks dla Layered Architecture ──────────


async def _v1_after_request(response: Response) -> Response:
    """Dodaje nagłówki deprecation dla /api/v1 (wersja deprecated)."""
    response.headers["Deprecation"] = "true"
    response.headers["Sunset"] = "Wed, 31 Dec 2026 23:59:59 GMT"
    response.headers["Link"] = '</api/v2>; rel="successor-version"'
    return response


async def _v2_after_request(response: Response) -> Response:
    """Dodaje nagłówek wersji dla /api/v2."""
    response.headers["X-API-Version"] = "v2"
    return response


# ── App-level after_request (zastępuje correlation-id + security headers z CorrelationAndDeprecationMiddleware) ──


async def _app_after_request(response: Response) -> Response:
    """Dodaje nagłówki bezpieczeństwa do każdej odpowiedzi HTTP.

    Zastępuje część funkcjonalności ``CorrelationAndDeprecationMiddleware``:
    - X-Content-Type-Options, X-Frame-Options, Referrer-Policy
    - Permissions-Policy, Content-Security-Policy z nonce (v7.0 Rec)

    SUPERMOC v7.0 Security Audit (Raport sekcja 6.2):
    - CSP nonce zamiast statycznego 'self' — per-request nonce
    - CSP report-uri dla monitorowania naruszeń
    - SRI integrity hashe dla static assets (obsługiwane w static_files)

    Tenant context i x-correlation-id są obsługiwane przez ``TenantContextMiddleware``.
    Metryki czasu przetwarzania są zbierane przez ``PrometheusConfig``.
    """
    import secrets as _secrets
    import hashlib as _hashlib

    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "no-referrer"
    response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"

    # ── CSP z per-request nonce (v7.0 Security Audit, sekcja 6.2) ───
    # Generuj unikalny nonce dla każdego requestu — bezpieczniejsze niż 'self'
    csp_nonce = _secrets.token_urlsafe(24)
    response.headers["X-CSP-Nonce"] = csp_nonce
    response.headers["Content-Security-Policy"] = (
        f"default-src 'self'; "
        f"script-src 'self' 'nonce-{csp_nonce}'; "
        f"style-src 'self' 'nonce-{csp_nonce}'; "
        f"frame-ancestors 'none'; "
        f"base-uri 'self'; "
        f"report-uri /api/v2/security/csp-report"
    )

    # ── SRI: Dodaj nagłówek dla static assets (v7.0 Security Audit) ──
    response.headers["Content-Security-Policy-Report-Only"] = (
        "require-sri-for script style"
    )
    return response


def create_app() -> Litestar:
    """Single official backend bootstrap point."""
    config = provide_config()

    # ── Utwórz engine + session_factory dla SQLAlchemyPlugin ────────────
    from nexus_ai.api.state import _make_engine

    engine = _make_engine(config)
    session_factory = create_session_factory(engine)

    # ── SQLAlchemyPlugin -- wstrzykuje db_session: Session do kontrolerów ─
    # Zastępuje manualny provide_db_session z dependencies.py
    sqlalchemy_plugin = SQLAlchemyPlugin(
        config=SQLAlchemyConfig(
            engine_instance=engine,
            session_maker=session_factory,
        )
    )

    # ── on_startup z pre-created engine ─────────────────────────────────
    on_startup = make_on_startup(engine, session_factory)

    cors_allow_credentials = config.cors_origins_list != ["*"]

    # ── Layered Architecture: Routery wg wersji API ────────────────────
    # Każdy Router ma własne: tags, guards, after_request.
    # Kontrolery dziedziczą te ustawienia od rodzica Router (merge).

    v1_router = Router(
        path="/api/v1",
        tags=["v1"],
        guards=[_v1_guard],
        after_request=_v1_after_request,
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
            DLQController,
            WorkerStatusController,
        ],
    )

    v2_router = Router(
        path="/api/v2",
        tags=["v2"],
        after_request=_v2_after_request,
        route_handlers=[
            HealthController,
            InvoiceController,
            TriageController,
            AnalyticsController,
            DashboardController,
            PartnerController,
            AutopilotController,
            TaxMathController,
            TaxPolicyController,
            RiskController,
            EventsSchemaController,
            PDFController,
            # v7.0 Security Audit: Proof Chain export + RBAC audit + CSP reports
            ProofChainExportController,
            CSPReportController,
        ],
    )

    unversioned_router = Router(
        path="/api",
        route_handlers=[
            AuthController,
            AdminController,
            ContractorController,
            SecurityAlertController,
            VersionController,
        ],
    )

    wellknown_router = Router(
        path="",
        route_handlers=[
            SecurityTxtController,  # v7.0 Security Audit: RFC 9116
        ],
    )

    # Używa _role_aware_identifier zdefiniowanego na poziomie modułu.
    # Jeden RateLimitConfig z custom identifier dla wszystkich endpointów.
    # identifier_for_request zwraca role-aware klucz, co daje per-role limity.
    # Endpointy wykluczone: health, schema -- nie wymagają rate limitingu.

    # ── Tenant-level rate limiting (v7.0 Security Audit: per-tenant isolation) ──
    # Rozszerza _role_aware_identifier o tenant_id dla pełnej izolacji
    _original_role_aware = _role_aware_identifier

    def _tenant_role_identifier(request: Request) -> str:
        """Per-tenant + per-role rate limiting identifier.

        SUPERMOC v7.0: Dodaje tenant_id do klucza rate limitingu,
        zapobiegając sytuacji gdzie jeden tenant zużywa limit innego.
        """
        base = _original_role_aware(request)
        tenant_id = getattr(request, "headers", {}).get("x-tenant-id", "") or "default"
        # Bezpieczne — tylko alfanumeryczne
        safe_tenant = "".join(c for c in str(tenant_id) if c.isalnum() or c in "_-")[:64]
        return f"{safe_tenant}:{base}"

    # ── CSRF exclude z configu ──
    csrf_exclude_patterns: list[Any] = []
    if config.csrf_exclude_patterns:
        for pattern in config.csrf_exclude_patterns:
            csrf_exclude_patterns.append(re.compile(pattern))
    else:
        csrf_exclude_patterns = [
            re.compile(r"^/api/auth/"),
            re.compile(r"/health"),
        ]

    # ── Import metrics debug endpoint ──────────────────────────────
    from nexus_ai.api.routes.metrics_debug import MetricsDebugController

    # ── Prometheus metrics config (zastępuje MetricsMiddleware + MetricsController) ──
    prometheus_config = PrometheusConfig(
        metrics_prefix="nexus",
        exclude=["/metrics", "/health", "/schema"],
    )

    return Litestar(
        after_request=[_app_after_request],
        route_handlers=[
            v1_router,
            v2_router,
            unversioned_router,
            wellknown_router,  # v7.0: /.well-known/security.txt
            PrometheusController,  # Zastępuje MetricsController -- wbudowany /metrics
            MetricsDebugController,  # /debug/metrics -- debug endpoint
            progress_sse,  # path="/api/v1/events/progress" -- pełna ścieżka
        ],
        plugins=[
            sqlalchemy_plugin,
            # OpenTelemetryPlugin -- automatyczne tracing spanów dla każdego requestu
            OpenTelemetryPlugin(),
            # ProblemDetailsPlugin -- RFC 9457 dla wszystkich błędów HTTP (w tym własnych DomainError)
            ProblemDetailsPlugin(ProblemDetailsConfig(enable_for_all_http_exceptions=True)),
            # v7.0 SUPERMOC #7: GraphQL Strawberry endpoint dla analityki
            _get_graphql_plugin(),
        ],
        on_app_init=[jwt_auth.on_app_init, jwt_cookie_auth.on_app_init],
        on_startup=[on_startup],
        on_shutdown=[on_shutdown],
        dependencies={
            "config": provide_config,
            "tenant_manager": provide_tenant_manager,
            "db_engine": provide_db_engine,
            "duckdb": provide_duckdb,
            "buffer": provide_shared_image_buffer,
        },
        exception_handlers=EXCEPTION_HANDLERS,
        middleware=[
            # Jeden middleware zamiast trzech -- identifier zwraca role-aware klucz
            RateLimitConfig(
                rate_limit=("minute", config.rate_limit_general),
                identifier_for_request=_tenant_role_identifier,  # v7.0: per-tenant + per-role
                exclude=[
                    "/api/v1/health",
                    "/api/v2/health",
                    "/schema/openapi.yml",
                    "/schema/swagger",
                ],
                exclude_opt_key="no_rate_limit",
            ).middleware,
            # TenantContextMiddleware -- ustawia ContextVar tenant_id dla każdego requestu
            # Zastępuje część CorrelationAndDeprecationMiddleware (tenant context + correlation-id)
            TenantContextMiddleware,
            # Prometheus middleware -- metryki HTTP (zastępuje MetricsMiddleware)
            prometheus_config.middleware,
        ],
        # ── ResponseCacheConfig -- wbudowane cachowanie odpowiedzi ──────
        # Zastępuje własny @ttl_cache dekorator z cache.py
        # ``@get(cache=60)`` na endpointach = 60s TTL
        response_cache_config=ResponseCacheConfig(default_expiration=60),
        # ── request_max_body_size -- zastępuje UploadSizeGuardMiddleware ──
        # 50MB dla największych uploadów
        request_max_body_size=50 * 1024 * 1024,
        cors_config=CORSConfig(
            allow_origins=config.cors_origins_list,
            allow_methods=["*"],
            allow_headers=["*"],
            allow_credentials=cors_allow_credentials,
            max_age=86400,  # v7.0 Security Audit: CORS preflight cache 24h (redukcja requestów OPTIONS o ~50%)
        ),
        csrf_config=CSRFConfig(
            secret=config.jwt_secret or "dev-csrf-secret",
            cookie_name="csrf_token",
            header_name="X-CSRF-Token",
            safe_methods={"GET", "HEAD", "OPTIONS", "TRACE"},
            exclude=csrf_exclude_patterns,
        )
        if config.csrf_enabled
        else None,
        # OpenAPI/Swagger wyłączone w produkcji zgodnie z aa3fvcx.txt (Punkt 3).
        # W trybie desktopowym (Flet) Swagger UI jest zbędny -- oszczędza RAM i czas startu.
        # Import SwaggerRenderPlugin na górze pliku jest bezpieczny (import klasy = 0 kosztu).
        openapi_config=OpenAPIConfig(
            title="Nexus AI API",
            version="2.0.0",
            description=(
                "API lifecycle: /api/v1 (deprecated) and /api/v2 (current). "
                f"Health endpoints: {SUPPORTED_HEALTH_ENDPOINTS[0]}, {SUPPORTED_HEALTH_ENDPOINTS[1]}"
            ),
            render_plugins=[SwaggerRenderPlugin()],
        )
        if config.debug
        else None,
        static_files_config=get_static_config(config),
        debug=config.debug,
    )
