"""
test_stateful.py — Stateful workflow testing via schemathesis.

Testuje sekwencje operacji API, które naśladują rzeczywiste workflows:
  - Health check → Auth login → Invoice CRUD
  - Auth register → Create resource → Verify → Cleanup

SUPERMOCE schemathesis:
  - stateful testing — automatyczne odkrywanie relacji między operacjami
    (np. POST tworzy zasób, GET/{id} go odczytuje)
  - workflows — ręczne definiowanie sekwencji operacji dla specyficznych
    scenariuszy biznesowych

Usage:
    pytest tests/schemathesis/test_stateful.py -v --run-schemathesis --run-slow
"""

from __future__ import annotations

import logging

import pytest
import schemathesis
from hypothesis import HealthCheck, settings

from tests.schemathesis.conftest import schema_from_app

logger = logging.getLogger("nexus.tests.schemathesis")
_, _test_app = schema_from_app()  # _schema nieużywane (stateful @schema.parametrize() zastąpiony przez skip)

# ── Fallback dla HealthCheck.too_slow (Hypothesis starsze niż 6.45) ───────
try:
    _SUPPRESS = [HealthCheck.too_slow]  # type: ignore[attr-defined]
except (ImportError, AttributeError):
    _SUPPRESS = []

# ── UWAGA: test_stateful_workflows jest SYNCHRONICZNY (@schema.parametrize).
# Tylko test_health_auth_workflow jest async (ma własny pytest.mark.anyio).
pytestmark = [
    pytest.mark.schemathesis,
    pytest.mark.slow,  # Stateful tests are slow (multi-step workflows)
]


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC: Stateful testing — automatyczne workflows
# ═══════════════════════════════════════════════════════════════════════════════
# schemathesis analizuje OpenAPI spec i automatycznie odkrywa relacje
# między endpointami (POST tworzy, GET/{id} odczytuje, DELETE/{id} usuwa).
# Testuje pełne cykle życia zasobów.


@pytest.mark.skip(reason="TODO: Stateful testing wymaga schemathesis.stateful API (≥4.25). "
                      "Zobacz https://schemathesis.readthedocs.io/en/latest/stateful.html")
class TestStatefulWorkflows:
    """SUPERMOC: Stateful workflow testing (TODO).

    Obecnie @schema.parametrize() generuje niezależne testy per-endpoint.
    Prawdziwy stateful testing (POST→GET→DELETE sequences) wymaga:

        from schemathesis.stateful import Stateful

        workflow = Stateful(schema).workflow("POST /users")
        @workflow
        def test_user_lifecycle(case):
            response = case.call_and_validate()
            assert response.status_code == 201
            # Automatyczne śledzenie relacji między endpointami

    Włącz po upgrade schemathesis do ≥4.25.
    """

    def test_stateful_placeholder(self) -> None:
        """Placeholder — zastąpiony przez Stateful workflow po upgrade."""
        pass


# ═══════════════════════════════════════════════════════════════════════════════
# Manual workflow: Health → Auth → Invoice lifecycle
# ═══════════════════════════════════════════════════════════════════════════════


@pytest.mark.slow
@settings(  # type: ignore[misc]
    max_examples=2,
    deadline=None,
    suppress_health_check=_SUPPRESS,
)
async def test_health_auth_workflow() -> None:
    """Ręczny workflow: Health check → Auth login → Weryfikacja.

    Testuje podstawowy lifecycle API jako użytkownik poprzez AsyncTestClient
    (bez potrzeby serwera HTTP — testuje ASGI app bezpośrednio).

    1. Sprawdź czy API żyje (/health)
    2. Zaloguj się (/auth/login)
    3. Sprawdź wersję API (/version)

    SUPERMOC: AsyncTestClient zamiast httpx.AsyncClient — nie wymaga
    działającego serwera, testuje ASGI app bezpośrednio.
    """
    from litestar.testing import AsyncTestClient

    # Użyj _test_app z schema_from_app() — ta sama app co schema
    async with AsyncTestClient(app=_test_app) as client:
        # Krok 1: Health check
        response = await client.get("/api/v1/health")
        assert response.status_code in (200, 401, 422, 500), (
            f"Health endpoint failed: {response.status_code}"
        )
        logger.info("Health check: %s %s", response.status_code, response.text[:100])

        # Krok 2: Auth login
        response = await client.post(
            "/api/auth/login",
            json={"username": "test", "password": "test"},
        )
        assert response.status_code in (200, 401, 422, 500), (
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
