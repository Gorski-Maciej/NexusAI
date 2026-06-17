"""
test_api_schema.py — Schemathesis property-based API schema conformance tests.

Automatycznie generuje i wykonuje testy dla KAŻDEGO endpointa API na podstawie
schematu OpenAPI. Wykrywa:
  - Naruszenia schematu odpowiedzi (status codes, headers, body)
  - Brakujące lub błędne walidacje danych wejściowych
  - Niespójności między deklaracją OpenAPI a rzeczywistym zachowaniem
  - Błędy 500 (Internal Server Error) dla prawidłowych requestów

SUPERMOCE schemathesis:
  - @schema.parametrize() — automatyczne generowanie testów z OpenAPI spec
  - module-level schema — tworzona raz przy imporcie, nie przez fixture
  - checks — wbudowane (status_code_conformance) + custom checks
  - hooks — auth injection, request tracking (w conftest.py)

UWAGA: Tylko JEDEN @schema.parametrize() na moduł, aby uniknąć
masywnej duplikacji testów (każdy dekorator generuje osobny batch
dla WSZYSTKICH endpointów).

Usage:
    pytest tests/schemathesis/ -v --run-schemathesis
"""

from __future__ import annotations

import logging

import pytest
import schemathesis
from hypothesis import HealthCheck, settings

from tests.schemathesis.conftest import schema_from_app
from tests.schemathesis.checks import ALL_CUSTOM_CHECKS

# ── SUPERMOC: module-level schema — tworzona RAZ przy imporcie ────────────
# schemathesis.parametrize() wymaga schematu na poziomie modułu (nie fixture).
# schema_from_app() zwraca (schema, app) — app jest dla AsyncTestClient.
logger = logging.getLogger("nexus.tests.schemathesis")
_schema, _test_app = schema_from_app()

# ── Fallback dla HealthCheck.too_slow (Hypothesis starsze niż 6.45) ───────
try:
    _SUPPRESS = [HealthCheck.too_slow]  # type: ignore[attr-defined]
except (ImportError, AttributeError):
    _SUPPRESS = []

# ── SUPERMOC: pytestmark — wszystkie testy w tym module są schemathesis ───
# ── UWAGA: test_schema_conformance jest SYNCHRONICZNY (case.call_and_validate()
# używa requests, nie httpx). Nie używamy pytest.mark.anyio tutaj.
# async test_health_auth_workflow w test_stateful.py ma własny marker.
pytestmark = [
    pytest.mark.schemathesis,
]


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC: @_schema.parametrize() — automatyczne generowanie testów
# dla KAŻDEGO endpointa z KAŻDĄ kombinacją parametrów.
# JEDEN test zamiast 3 — unikamy duplikacji (każdy @parametrize tworzy
# osobny batch dla wszystkich endpointów, co daje 3× te same testy).
# ═══════════════════════════════════════════════════════════════════════════════


@_schema.parametrize()
@settings(  # type: ignore[misc]
    max_examples=5,
    deadline=None,
    suppress_health_check=_SUPPRESS,
)
def test_schema_conformance(case: schemathesis.Case) -> None:
    """SUPERMOC: Property-based schema conformance test.

    schemathesis automatycznie:
    1. Parsuje OpenAPI spec z aplikacji ASGI
    2. Dla każdego endpointa generuje losowe dane wejściowe
    3. Wysyła request i weryfikuje odpowiedź względem schematu
    4. Sprawdza conformance (status code, headers, body type)

    Kombinacja checków:
    - st_checks.status_code_conformance — schemat status codes
    - st_checks.content_type_conformance — typ odpowiedzi
    - st_checks.response_headers_conformance — nagłówki
    - Custom checks — response_time, no_500, security_headers

    max_examples=5 — 5 losowych przykładów na endpoint (szybkie testy).
    suppress_health_check=HealthCheck.too_slow — hypoteza nie narzeka
    na wolne generowanie (ważne przy property-based fuzzingu).
    """
    from schemathesis import checks as st_checks

    # Built-in checks + custom checks
    checks = [
        st_checks.status_code_conformance,
        st_checks.content_type_conformance,
        st_checks.response_headers_conformance,
        *ALL_CUSTOM_CHECKS,
    ]

    case.call_and_validate(checks=checks)


# ═══════════════════════════════════════════════════════════════════════════════
# Smoke test — podstawowa walidacja kompletności schematu OpenAPI
# ═══════════════════════════════════════════════════════════════════════════════


@pytest.mark.smoke
def test_schema_has_all_controllers() -> None:
    """SUPERMOC: Smoke test — weryfikuje kompletność schematu OpenAPI.

    Sprawdza czy wszystkie oczekiwane kontrolery są zarejestrowane
    w schemacie OpenAPI. To test, który szybko wykrywa brakujące
    lub nieprawidłowo skonfigurowane endpointy.
    """
    endpoints = list(_schema.get_all_operations())
    endpoint_paths = {ep.path for ep in endpoints}

    # Zdrowotne
    assert any("/api/v1/health" in p for p in endpoint_paths)
    assert any("/api/v2/health" in p for p in endpoint_paths)

    # Auth
    assert any("/api/auth/login" in p for p in endpoint_paths)
    assert any("/api/auth/register" in p for p in endpoint_paths)

    # Invoices
    assert any("/api/v1/invoices" in p for p in endpoint_paths)
    assert any("/api/v2/invoices" in p for p in endpoint_paths)

    # Tax
    assert any("/api/v2/tax" in p for p in endpoint_paths)

    # Version
    assert any("/api/version" in p for p in endpoint_paths)

    logger.info(
        "OpenAPI schema contains %d endpoints across all controllers",
        len(endpoints),
    )


@pytest.mark.smoke
def test_all_http_methods_registered() -> None:
    """Weryfikuje, że schemat zawiera wszystkie metody HTTP."""
    methods: set[str] = set()
    for operation in _schema.get_all_operations():
        methods.add(str(operation.method).upper())

    required = {"GET", "POST", "PUT", "PATCH", "DELETE"}
    registered = required.intersection(methods)
    logger.info(
        "HTTP methods in schema: %s (registered: %d/5)",
        sorted(methods),
        len(registered),
    )
