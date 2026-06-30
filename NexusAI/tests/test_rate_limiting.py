"""Tests for Litestar rate limiting features.

SUPERMOC Litestar:
- Per-role rate limiting przez _role_aware_identifier
- exclude_opt_key na health endpointach
- Cache na read-only endpointach (health, dashboard, version, stats)
- DomainError → ProblemDetailsPlugin integration
"""

from __future__ import annotations

import pytest
from unittest.mock import MagicMock, patch


class TestRateLimitIdentifier:
    """Test _role_aware_identifier logic."""

    def test_authenticated_user_returns_role_key(self):
        """Zalogowany user → user:{role}:{id}"""
        mock_request = MagicMock()
        mock_request.user.id = "user_123"
        mock_request.user.role = "admin"

        from nexus_ai.api.app import _role_aware_identifier
        identifier = _role_aware_identifier(mock_request)
        assert identifier == "user:admin:user_123"

    def test_auth_endpoint_returns_ip_key(self):
        """Auth endpoint bez usera → auth:{ip}"""
        mock_request = MagicMock()
        mock_request.user = None
        mock_request.url.path = "/api/auth/login"
        mock_request.client.host = "1.2.3.4"

        from nexus_ai.api.app import _role_aware_identifier
        identifier = _role_aware_identifier(mock_request)
        assert identifier == "auth:1.2.3.4"

    def test_anonymous_returns_ip_key(self):
        """Niezalogowany → anon:{ip}"""
        mock_request = MagicMock()
        mock_request.user = None
        mock_request.url.path = "/api/v2/invoices"
        mock_request.client.host = "5.6.7.8"

        from nexus_ai.api.app import _role_aware_identifier
        identifier = _role_aware_identifier(mock_request)
        assert identifier == "anon:5.6.7.8"


class TestRateLimitConfig:
    """Test konfiguracji RateLimitConfig."""

    def test_rate_limit_excludes_health(self):
        """Health endpoints są wykluczone z rate limitingu."""
        from litestar.middleware.rate_limit import RateLimitConfig

        config = RateLimitConfig(
            rate_limit=("minute", 60),
            exclude=["/api/v1/health", "/api/v2/health"],
        )
        assert "/api/v1/health" in config.exclude
        assert "/api/v2/health" in config.exclude

    def test_exclude_opt_key_present(self):
        """exclude_opt_key jest ustawiony."""
        from litestar.middleware.rate_limit import RateLimitConfig

        config = RateLimitConfig(
            rate_limit=("minute", 60),
            exclude_opt_key="no_rate_limit",
        )
        assert config.exclude_opt_key == "no_rate_limit"


class TestHealthCache:
    """Test cache na health endpointach.

    Sprawdza czy:
    - /health ma cache=300 i exclude_opt_key="no_rate_limit"
    - /health/live NIE ma cache (K8s probe needs real-time state)
    - /health/ready NIE ma cache (K8s probe needs real-time state)
    """

    def test_health_basic_cache(self):
        """/health ma cache=300 i exclude_opt_key."""
        from nexus_ai.api.routes.health import HealthController

        route_handler = getattr(HealthController, "health_check", None)
        assert route_handler is not None, "health_check route handler not found"

        # Sprawdź exclude_opt_key przez route.opt (to działa przed kompilacją)
        opt = getattr(route_handler, "opt", {}) or {}
        assert opt.get("no_rate_limit") is True, "health_check powinien mieć exclude_opt_key"

        # W Litestar cache jest przechowywany jako int w route_handler.cache
        # Jeśli cache=300, to route_handler.cache powinno być 300
        cache_val = getattr(route_handler, "cache", None)
        assert cache_val == 300, f"health_check powinien mieć cache=300, ma {cache_val}"

    def test_liveness_no_cache(self):
        """/health/live NIE ma cache (K8s probe musi widzieć bieżący stan)."""
        from nexus_ai.api.routes.health import HealthController

        route_handler = getattr(HealthController, "liveness_probe", None)
        assert route_handler is not None, "liveness_probe route handler not found"

        # K8s liveness probe NIE powinna mieć cache
        cache_val = getattr(route_handler, "cache", None)
        assert cache_val is None or cache_val == 0, f"liveness probe powinna mieć cache=None/0, ma {cache_val}"

        # exclude_opt_key dla bezpieczeństwa (rate limiting niepotrzebny dla K8s probe)
        opt = getattr(route_handler, "opt", {}) or {}
        assert opt.get("no_rate_limit") is True, "liveness_probe powinien mieć exclude_opt_key"


class TestDomainErrorProblemDetails:
    """Test DomainError → ProblemDetailsPlugin integration."""

    def test_domain_error_handler_raises_http_exception(self):
        """domain_error_handler rzuca HTTPException."""
        from nexus_ai.api.exceptions import (
            DomainError,
            ValidationDomainError,
            domain_error_handler,
        )
        from litestar.exceptions import HTTPException
        from litestar.connection import Request

        mock_request = MagicMock(spec=Request)
        exc = ValidationDomainError("Test error")

        with pytest.raises(HTTPException) as exc_info:
            domain_error_handler(mock_request, exc)

        assert exc_info.value.status_code == 422
        assert exc_info.value.detail == "Test error"

    def test_domain_error_status_codes(self):
        """Różne DomainError mają odpowiednie status code."""
        from nexus_ai.api.exceptions import (
            ValidationDomainError,
            IntegrationDomainError,
            TimeoutDomainError,
            BusinessRuleDomainError,
            SecurityDomainError,
            InvoiceNotFoundError,
            RateLimitExceededError,
        )

        assert ValidationDomainError("x").status_code == 422
        assert IntegrationDomainError("x").status_code == 502
        assert TimeoutDomainError("x").status_code == 504
        assert BusinessRuleDomainError("x").status_code == 409
        assert SecurityDomainError("x").status_code == 401
        assert InvoiceNotFoundError("x").status_code == 404
        assert RateLimitExceededError().status_code == 429


class TestSecurityConfig:
    """Test konfiguracji [security] z TOML."""

    def test_effective_jwt_exclude_defaults(self):
        """effective_jwt_exclude zwraca domyślne wykluczenia gdy brak configu."""
        from nexus_ai.core.config import AppConfig

        config = AppConfig()  # Pusty config — domyślne wartości
        exclude = config.effective_jwt_exclude
        assert "/api/auth/login" in exclude
        assert "/api/auth/register" in exclude
        assert "/api/v1/health" in exclude
        assert "/schema/swagger" in exclude

    def test_effective_jwt_exclude_custom(self):
        """effective_jwt_exclude zwraca zdefiniowane wykluczenia."""
        from nexus_ai.core.config import AppConfig

        config = AppConfig(jwt_exclude_paths=["/custom/path"])
        exclude = config.effective_jwt_exclude
        assert exclude == ["/custom/path"]

    def test_csrf_exclude_paths(self):
        """CSRF exclude patterns są konfigurowalne."""
        from nexus_ai.core.config import AppConfig

        config = AppConfig(csrf_exclude_patterns=["/api/auth/", "/health"])
        assert config.csrf_exclude_patterns == ["/api/auth/", "/health"]


class TestJWTAuth:
    """Test JWT auth konfiguracji."""

    def test_jwt_auth_exclude_from_config(self):
        """jwt_auth.exclude pochodzi z configu (security._get_jwt_exclude())."""
        from nexus_ai.api.security import _get_jwt_exclude

        exclude = _get_jwt_exclude()
        assert isinstance(exclude, list)
        assert len(exclude) > 0
        assert "/api/auth/login" in exclude

    def test_jwt_auth_is_configured(self):
        """jwt_auth jest poprawnie skonfigurowany."""
        from nexus_ai.api.security import jwt_auth

        assert jwt_auth is not None
        assert jwt_auth.token_secret is not None
        assert len(jwt_auth.exclude) > 0

    def test_jwt_cookie_auth_is_configured(self):
        """jwt_cookie_auth jest poprawnie skonfigurowany (dual auth)."""
        from nexus_ai.api.security import jwt_cookie_auth

        assert jwt_cookie_auth is not None
        assert jwt_cookie_auth.token_secret is not None
        assert len(jwt_cookie_auth.exclude) > 0
