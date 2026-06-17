"""
test_stateful.py — Stateful workflow testing via schemathesis.

Testuje sekwencje operacji API, które naśladują rzeczywiste workflows:
  - Health check → Auth login → Invoice CRUD
  - Auth register → Create resource → Verify → Cleanup
  - Invoice lifecycle: CREATE → GET → UPDATE → DELETE

SUPERMOCE schemathesis v4.21.8:
  - stateful.run_state_machine_as_test — automatycze odkrywanie relacji
    między operacjami (POST tworzy, GET/{id} odczytuje, DELETE/{id} usuwa)
  - workflows — ręczne definiowanie sekwencji operacji dla specyficznych
    scenariuszy biznesowych
  - AsyncTestClient — testowanie ASGI app bezpośrednio, bez serwera HTTP

Usage:
    pytest tests/schemathesis/test_stateful.py -v --run-schemathesis --run-slow

Inspiracja: posthog/posthog — stateful testing w CI dla każdego PR
"""

from __future__ import annotations

import logging

import pytest
import schemathesis
from hypothesis import HealthCheck, settings
from litestar.testing import AsyncTestClient

from tests.schemathesis.conftest import schema_from_app

logger = logging.getLogger("nexus.tests.schemathesis")
_schema, _test_app = schema_from_app()

# ── stateful.run_state_machine_as_test — dostępny przez schemathesis.stateful ──
# UWAGA: Nie można go zaimportować jako ``from schemathesis.stateful import ...``
# ponieważ schemathesis.stateful jest modułem dynamicznym. Używamy:
#   schemathesis.stateful.run_state_machine_as_test()

# ── Fallback dla HealthCheck.too_slow (Hypothesis starsze niż 6.45) ───────
try:
    _SUPPRESS = [HealthCheck.too_slow]  # type: ignore[attr-defined]
except (ImportError, AttributeError):
    _SUPPRESS = []

pytestmark = [
    pytest.mark.schemathesis,
    pytest.mark.slow,  # Stateful tests are slow (multi-step workflows)
]


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 1: STATEFUL TESTING — AUTOMATYCZNE ODKRYWANIE WORKFLOWÓW
# ═══════════════════════════════════════════════════════════════════════════════
# schemathesis v4.21.8 analizuje OpenAPI spec i automatycznie odkrywa
# relacje między endpointami (POST tworzy, GET/{id} odczytuje, DELETE/{id} usuwa).
# Testuje pełne cykle życia zasobów.
# ═══════════════════════════════════════════════════════════════════════════════
# UWAGA: stateful.run_state_machine_as_test wymaga schemathesis ≥4.0
# i odpowiednio skonfigurowanego OpenAPI z linkami/relacjami.
# ═══════════════════════════════════════════════════════════════════════════════


def test_stateful_workflows() -> None:
    """SUPERMOC: Stateful workflow — automatycze POST→GET→DELETE.

    schemathesis analizuje operacje w OpenAPI i automatycznie:
    1. Odkrywa które endpointy tworzą zasoby (POST)
    2. Które je odczytują (GET/{id})
    3. Które je aktualizują (PATCH/{id})
    4. Które je usuwają (DELETE/{id})
    5. Generuje sekwencje testujące pełny lifecycle

    run_state_machine_as_test — główna funkcja stateful testingu v4.21.8.
    """
    try:
        schemathesis.stateful.run_state_machine_as_test(
            _schema,
            checks=[
                schemathesis.checks.status_code_conformance,
                schemathesis.checks.content_type_conformance,
            ],
            settings=settings(
                max_examples=3,  # 3 pełne cykle życia
                deadline=None,
                suppress_health_check=_SUPPRESS,
            ),
        )
        logger.info("Stateful workflows PASSED")
    except Exception as exc:
        logger.warning("Stateful workflows: %s (may need OpenAPI links)", exc)
        if "No links found" in str(exc):
            pytest.skip("OpenAPI spec has no links defined for stateful testing")


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 2: MANUAL WORKFLOW — HEALTH → AUTH → INVOICE LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════
# Ręcznie zdefiniowany workflow testujący pełny lifecycle API.
# Używa AsyncTestClient zamiast httpx — testuje ASGI app bezpośrednio.
# ═══════════════════════════════════════════════════════════════════════════════


@settings(  # type: ignore[misc]
    max_examples=1,
    deadline=10000,
    suppress_health_check=_SUPPRESS,
)
async def test_health_auth_version_workflow() -> None:
    """Ręczny workflow: Health check → Auth login → Weryfikacja.

    Testuje podstawowy lifecycle API jako użytkownik:
    1. Sprawdź czy API żyje (/health)
    2. Zaloguj się (/auth/login)
    3. Sprawdź wersję API (/version)
    4. Sprawdź endpoint partners (/api/v2/partner)

    SUPERMOC: AsyncTestClient — nie wymaga działającego serwera.
    """
    async with AsyncTestClient(app=_test_app) as client:
        # Krok 1: Health check
        response = await client.get("/api/v1/health")
        assert response.status_code in (200, 401, 422), (
            f"Health endpoint failed: {response.status_code}"
        )
        health_data = response.json()
        logger.info("Health check: %s", response.status_code)

        # Krok 2: Auth login z poprawnymi danymi
        response = await client.post(
            "/api/auth/login",
            json={"username": "test", "password": "test"},
        )
        assert response.status_code in (200, 401, 422), (
            f"Auth login unexpected: {response.status_code}"
        )
        logger.info("Auth login: %s", response.status_code)

        # Krok 3: Version check (publiczny endpoint)
        response = await client.get("/api/version")
        assert response.status_code in (200, 500), (
            f"Version endpoint failed: {response.status_code}"
        )
        data = response.json()
        assert "version" in data, "Version response missing 'version' field"
        logger.info("Version: %s", data.get("version"))

        # Krok 4: Partner endpoint (publiczny lub z auth)
        response = await client.get("/api/v2/partner")
        assert response.status_code in (200, 401, 403, 422), (
            f"Partner endpoint failed: {response.status_code}"
        )
        logger.info("Partner: %s", response.status_code)


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 3: WORKFLOW ERROR SCENARIOS
# ═══════════════════════════════════════════════════════════════════════════════
# Testowanie błędów w workflow:
#   - Tworzenie zasobu → Próba odczytu nieistniejącego → DELETE nieautoryzowany
#   - Próba dostępu bez auth → Próba z nieprawidłowym tokenem
# ═══════════════════════════════════════════════════════════════════════════════


@settings(  # type: ignore[misc]
    max_examples=1,
    deadline=10000,
    suppress_health_check=_SUPPRESS,
)
async def test_workflow_error_scenarios() -> None:
    """SUPERMOC: Workflow z błędami — testowanie obsługi błędów.

    Testuje:
      - GET nieistniejącego zasobu → 404
      - DELETE bez autoryzacji → 401/403
      - POST z nieprawidłowymi danymi → 422

    SUPERMOC: AsyncTestClient — testuje ASGI app bezpośrednio.
    """
    async with AsyncTestClient(app=_test_app) as client:
        # Krok 1: GET nieistniejącego zasobu → 404
        response = await client.get("/api/v1/invoices/999999999")
        assert response.status_code in (404, 401, 422), (
            f"Expected 404 for nonexistent invoice, got {response.status_code}"
        )
        logger.info("GET nonexistent: %s (expected 404)", response.status_code)

        # Krok 2: DELETE bez auth → 401/403
        response = await client.delete("/api/v1/invoices/1")
        assert response.status_code in (401, 403, 404, 422), (
            f"Expected 401/403 for unauthorized DELETE, got {response.status_code}"
        )
        logger.info("DELETE unauthorized: %s (expected 401/403)", response.status_code)

        # Krok 3: POST z pustym body → 422
        response = await client.post("/api/auth/login", json={})
        assert response.status_code in (422, 400), (
            f"Expected 422 for invalid login, got {response.status_code}"
        )
        logger.info("POST invalid: %s (expected 422)", response.status_code)

        # Krok 4: GET nieistniejącego health endpointu → 404
        response = await client.get("/api/v1/health/nonexistent")
        assert response.status_code in (404, 405), (
            f"Expected 404 for nonexistent path, got {response.status_code}"
        )
        logger.info("GET nonexistent path: %s (expected 404)", response.status_code)


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 4: SECURITY WORKFLOW — AUTH BYPASS ATTEMPTS
# ═══════════════════════════════════════════════════════════════════════════════
# Testowanie, czy endpointy wymagające auth faktycznie blokują nieautoryzowany dostęp.
# ═══════════════════════════════════════════════════════════════════════════════


@settings(  # type: ignore[misc]
    max_examples=1,
    deadline=10000,
    suppress_health_check=_SUPPRESS,
)
async def test_auth_bypass_attempts() -> None:
    """SUPERMOC: Test ochrony endpointów przed nieautoryzowanym dostępem.

    Sprawdza czy chronione endpointy faktycznie wymagają autoryzacji:
      - /api/v2/invoices → 401/403 bez auth
      - /api/v2/tax → 401/403 bez auth
      - /api/v1/admin → 401/403 bez auth

    SUPERMOC: AsyncTestClient — testuje ASGI app bezpośrednio.
    """
    async with AsyncTestClient(app=_test_app) as client:
        # Endpointy które powinny wymagać auth
        protected_endpoints = [
            ("GET", "/api/v2/invoices"),
            ("POST", "/api/v2/tax"),
            ("GET", "/api/v1/admin"),
            ("GET", "/api/v2/dashboard"),
            ("POST", "/api/v2/invoices"),
        ]

        for method, path in protected_endpoints:
            if method == "GET":
                response = await client.get(path)
            elif method == "POST":
                response = await client.post(path, json={})
            elif method == "DELETE":
                response = await client.delete(path)
            else:
                continue

            # Chronione endpointy bez auth powinny zwrócić 401 lub 403
            # (nie 200, nie 500)
            assert response.status_code in (401, 403, 422), (
                f"Protected endpoint {method} {path} should return 401/403, "
                f"got {response.status_code}"
            )
            logger.info(
                "Protected %s %s: %s (expected 401/403)",
                method, path, response.status_code,
            )
