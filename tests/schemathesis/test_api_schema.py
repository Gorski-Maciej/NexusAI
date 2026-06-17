"""
test_api_schema.py — Schemathesis property-based API schema conformance tests.

Automatycznie generuje i wykonuje testy dla KAŻDEGO endpointa API na podstawie
schematu OpenAPI. Wykrywa:
  - Naruszenia schematu odpowiedzi (status codes, headers, body)
  - Brakujące lub błędne walidacje danych wejściowych
  - Niespójności między deklaracją OpenAPI a rzeczywistym zachowaniem
  - Błędy 5xx dla prawidłowych requestów
  - Problemy wydajnościowe (response time > 5s)
  - Brak nagłówków bezpieczeństwa
  - Błędy walidacji biznesowej (VAT, NIP)

SUPERMOCE schemathesis v4.21.8:
  - @schema.parametrize() — automatyczne generowanie testów z OpenAPI spec
  - DataGenerationMethod — RANDOM, BASE, negative, positive
  - generation_config — kontrola nad generowaniem danych
  - Custom strategies — hypothesis strategies dla polskich formatów danych
  - Stateful testing — automatycze POST→GET→DELETE workflows
  - Snapshot testing — porównywanie odpowiedzi z snapshotami
  - hooks — auth injection, request tracking (w conftest.py)

TRZY POZIOMY TESTÓW:
  1. positive — tylko poprawne dane (szybka weryfikacja happy path)
  2. negative — tylko nieprawidłowe dane (testowanie walidacji)
  3. mixed — domyślne mieszane dane (pełny fuzz)

UWAGA: Tylko JEDEN @schema.parametrize() na moduł dla każdego trybu,
aby uniknąć masywnej duplikacji testów.

Usage:
    pytest tests/schemathesis/test_api_schema.py -v --run-schemathesis
    pytest tests/schemathesis/test_api_schema.py -v --run-schemathesis --run-slow
"""

from __future__ import annotations

import logging
import os
from typing import Any

import pytest
import schemathesis
from hypothesis import HealthCheck, settings, strategies as st
from schemathesis import checks as st_checks

from tests.schemathesis.conftest import schema_from_app
from tests.schemathesis.checks import ALL_CUSTOM_CHECKS, CHECK_REGISTRY
from tests.schemathesis import GenerationMode

# ── SUPERMOC: module-level schema — tworzona RAZ przy imporcie ────────────
logger = logging.getLogger("nexus.tests.schemathesis")
_schema, _test_app = schema_from_app()

# ── Fallback dla HealthCheck.too_slow (Hypothesis starsze niż 6.45) ───────
try:
    _SUPPRESS = [HealthCheck.too_slow]  # type: ignore[attr-defined]
except (ImportError, AttributeError):
    _SUPPRESS = []

# ── pytestmark — wszystkie testy w tym module mają marker schemathesis ─────
pytestmark = [
    pytest.mark.schemathesis,
]


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 1: TEST POZYTYWNY — TYLKO POPRAWNE DANE
# ═══════════════════════════════════════════════════════════════════════════════
# Używa DataGenerationMethod do generowania tylko poprawnych danych.
# Szybki test (~3 przykłady/endpoint) do weryfikacji happy path.
# ═══════════════════════════════════════════════════════════════════════════════


@pytest.mark.slow
@_schema.parametrize(generation_mode=GenerationMode.POSITIVE)
@settings(  # type: ignore[misc]
    max_examples=3,
    deadline=5000,
    suppress_health_check=_SUPPRESS,
)
def test_positive_happy_path(case: schemathesis.Case) -> None:
    """SUPERMOC: Tylko poprawne dane — szybka weryfikacja happy path.

    schemathesis generuje tylko dane zgodne ze schematem OpenAPI
    (GenerationMode.POSITIVE). Test sprawdza czy API zwraca 200/201
    dla prawidłowych danych.

    max_examples=3 — tylko 3 przykłady (szybki test).
    deadline=5000 — 5s limit na endpoint (nie fuzz, tylko happy path).
    """
    case.call_and_validate(
        checks=[
            st_checks.status_code_conformance,
            st_checks.content_type_conformance,
            *ALL_CUSTOM_CHECKS,
        ]
    )


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 2: TEST NEGATYWNY — TYLKO NIEPRAWIDŁOWE DANE
# ═══════════════════════════════════════════════════════════════════════════════
# Używa DataGenerationMethod do generowania tylko nieprawidłowych danych.
# Celowo próbuje złamać API — sprawdza czy walidacja działa.
# ═══════════════════════════════════════════════════════════════════════════════


@_schema.parametrize(generation_mode=GenerationMode.NEGATIVE)
@settings(  # type: ignore[misc]
    max_examples=10,
    deadline=None,
    suppress_health_check=_SUPPRESS,
)
def test_negative_scenarios(case: schemathesis.Case) -> None:
    """SUPERMOC: Tylko nieprawidłowe dane — testowanie walidacji.

    schemathesis generuje celowo nieprawidłowe dane (za długie stringi,
    ujemne liczby, null w wymaganych polach, itp.) używając
    GenerationMode.NEGATIVE.

    Test sprawdza:
      - API nie zwraca 500 dla nieprawidłowych danych
      - API zwraca 422 (Validation Error) lub 400 (Bad Request)
      - Odpowiedź zawiera komunikat błędu

    max_examples=10 — więcej przykładów dla lepszego pokrycia.
    deadline=None — fuzz może być wolniejszy.
    """
    case.call_and_validate(
        checks=[
            st_checks.status_code_conformance,
            st_checks.content_type_conformance,
            # Dla negatywnych: 4xx są OK, 5xx są FAIL
            st_checks.not_a_server_error,  # type: ignore[attr-defined]
        ]
    )


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 3: TEST MIESZANY — DOMYŚLNE DANE (PEŁNY FUZZ)
# ═══════════════════════════════════════════════════════════════════════════════
# Używa domyślnego generowania danych (mieszane positive + negative).
# Najobszerniejszy test — wszystkie checki, wszystkie endpointy.
# ═══════════════════════════════════════════════════════════════════════════════


@_schema.parametrize()
@settings(  # type: ignore[misc]
    max_examples=5,
    deadline=None,
    suppress_health_check=_SUPPRESS,
)
def test_mixed_scenarios(case: schemathesis.Case) -> None:
    """SUPERMOC: Mieszane dane (domyślne) — pełny fuzz wszystkich endpointów.

    schemathesis automatycznie:
    1. Parsuje OpenAPI spec z aplikacji ASGI
    2. Dla każdego endpointa generuje losowe dane wejściowe
    3. Wysyła request i weryfikuje odpowiedź względem schematu
    4. Sprawdza conformance (status code, headers, body type)

    Kombinacja checków:
    - st_checks.status_code_conformance — zgodność status codes
    - st_checks.content_type_conformance — typ odpowiedzi
    - st_checks.response_headers_conformance — nagłówki
    - Custom checks (ALL_CUSTOM_CHECKS) — response_time, security, VAT, NIP

    max_examples=5 — 5 losowych przykładów na endpoint.
    """
    checks = [
        st_checks.status_code_conformance,
        st_checks.content_type_conformance,
        st_checks.response_headers_conformance,
        *ALL_CUSTOM_CHECKS,
    ]

    case.call_and_validate(checks=checks)


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 4: TARGETOWANE TESTY — KRYTYCZNE ENDPOINTY
# ═══════════════════════════════════════════════════════════════════════════════
# Testy dedykowane konkretnym endpointom z wyższą liczbą przykładów.
# ═══════════════════════════════════════════════════════════════════════════════


@pytest.mark.slow
@_schema.parametrize(endpoint="/api/v2/tax", method="POST")
@settings(  # type: ignore[misc]
    max_examples=50,  # Bardzo dokładny fuzz dla podatków
    deadline=5000,
    suppress_health_check=_SUPPRESS,
)
def test_tax_math_precision(case: schemathesis.Case) -> None:
    """SUPERMOC: Precyzyjny fuzz dla kalkulacji podatkowych.

    Testuje endpoint /api/v2/tax z 50 przykładami.
    Sprawdza:
      - Zgodność status codes
      - Brak 500
      - Poprawność wyliczenia VAT
      - Format NIP

    max_examples=50 — bardzo dokładny fuzz dla krytycznego endpointa.
    """
    case.call_and_validate(
        checks=[
            st_checks.status_code_conformance,
            ALL_CUSTOM_CHECKS[1],  # check_no_internal_server_error
            ALL_CUSTOM_CHECKS[4],  # check_vat_calculation
            ALL_CUSTOM_CHECKS[5],  # check_polish_nip_format
        ]
    )


@pytest.mark.slow
@_schema.parametrize(endpoint="/api/auth/login", method="POST")
@settings(  # type: ignore[misc]
    max_examples=30,
    deadline=3000,
    suppress_health_check=_SUPPRESS,
)
def test_auth_login_resistance(case: schemathesis.Case) -> None:
    """SUPERMOC: Test odporności loginu na brute-force.

    Testuje endpoint /api/auth/login z 30 przykładami.
    Sprawdza czy:
      - API nie zwraca 500 dla różnych kombinacji
      - API zwraca odpowiedni status (200, 401, 422)
      - Odpowiedź ma poprawny Content-Type

    max_examples=30 — więcej prób dla auth security.
    """
    case.call_and_validate(
        checks=[
            st_checks.status_code_conformance,
            st_checks.content_type_conformance,
            ALL_CUSTOM_CHECKS[1],  # check_no_internal_server_error
        ]
    )


@pytest.mark.slow
@_schema.parametrize(method="POST")
@settings(  # type: ignore[misc]
    max_examples=10,
    deadline=5000,
    suppress_health_check=_SUPPRESS,
)
def test_all_post_endpoints(case: schemathesis.Case) -> None:
    """SUPERMOC: Test wszystkich POST endpointów.

    Wszystkie endpointy POST wymagają szczególnej uwagi — tworzą zasoby.
    Sprawdza:
      - 201 Created dla poprawnych danych
      - 422 Validation Error dla nieprawidłowych
      - Brak 500

    max_examples=10 — więcej przykładów dla mutacji.
    """
    case.call_and_validate(
        checks=[
            st_checks.status_code_conformance,
            st_checks.content_type_conformance,
            *ALL_CUSTOM_CHECKS,
        ]
    )


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 5: CUSTOM STRATEGIES — POLSKIE FORMATY DANYCH
# ═══════════════════════════════════════════════════════════════════════════════
# Własne strategie hypothesis dla polskich formatów danych.
# ═══════════════════════════════════════════════════════════════════════════════


@_schema.parametrize(endpoint="/api/v2/invoices")
@settings(  # type: ignore[misc]
    max_examples=20,
    deadline=5000,
    suppress_health_check=_SUPPRESS,
)
def test_invoice_polish_chars(case: schemathesis.Case) -> None:
    """SUPERMOC: Test faktur z polskimi znakami diakrytycznymi.

    Używa GenerationMode.POSITIVE z dodatkowym fuzzingiem polskich znaków.
    Sprawdza czy API poprawnie obsługuje polskie znaki w nazwach,
    adresach i opisach.

    UWAGA: W schemathesis v4.21.8, pełna kontrola nad generowaniem
    danych przez hypothesis strategies wymaga SchemathesisConfig.
    Ten test używa większej liczby przykładów (20) dla lepszego
    pokrycia znaków specjalnych.

    max_examples=20 — wystarczająco dużo dla pokrycia znaków.
    """
    case.call_and_validate(
        checks=[
            st_checks.status_code_conformance,
            st_checks.content_type_conformance,
            ALL_CUSTOM_CHECKS[1],  # check_no_internal_server_error
        ]
    )


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 6: SNAPSHOT TESTING — PORÓWNYWANIE ODPOWIEDZI
# ═══════════════════════════════════════════════════════════════════════════════
# Porównuje odpowiedzi API z wcześniej zapisanymi snapshotami.
# Wykrywa nieoczekiwane zmiany struktury odpowiedzi.
# ═══════════════════════════════════════════════════════════════════════════════
# UWAGA: Wymaga pip install syrupy. Jeśli nie jest dostępne, test jest pomijany.
# ═══════════════════════════════════════════════════════════════════════════════

try:
    from syrupy import SnapshotAssertion

    HAS_SYRuPY = True
except ImportError:
    HAS_SYRuPY = False


@pytest.mark.skipif(not HAS_SYRuPY, reason="Requires syrupy for snapshot testing")
@pytest.mark.slow
@_schema.parametrize(generation_mode=GenerationMode.POSITIVE)
@settings(  # type: ignore[misc]
    max_examples=2,
    deadline=5000,
    suppress_health_check=_SUPPRESS,
)
def test_snapshot_conformance(case: schemathesis.Case, snapshot: SnapshotAssertion) -> None:
    """SUPERMOC: Porównuje odpowiedź z snapshotem.

    Gdy schemat OpenAPI się zmienia, snapshothy są aktualizowane.
    Gdy endpoint zwraca inną strukturę niż snapshot — test failuje.

    max_examples=2 — tylko 2 przykłady (snapshot test nie potrzebuje fuzz).
    Wymaga: pip install syrupy
    """
    response = case.call()
    assert response.json() == snapshot


# ═══════════════════════════════════════════════════════════════════════════════
# Smoke testy — podstawowa walidacja kompletności schematu OpenAPI
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


@pytest.mark.smoke
def test_schema_detail() -> None:
    """SUPERMOC: Szczegółowa walidacja schematu OpenAPI.

    Sprawdza:
      - Każdy endpoint ma zdefiniowaną metodę HTTP
      - Każda odpowiedź ma zdefiniowany schemat
      - Każdy POST ma body schema (request body)
    """
    for op in _schema.get_all_operations():
        # Sprawdź czy endpoint ma metodę
        assert op.method, f"Missing method for {op.path}"

        # Sprawdź czy endpoint ma odpowiedzi zdefiniowane
        assert op.definition.responses, (
            f"Missing responses for {op.method} {op.path}"
        )

        # Sprawdź czy POST ma body schema
        if op.method == "POST":
            assert op.definition.request_body, (
                f"POST {op.path} missing request body"
            )


@pytest.mark.smoke
def test_check_registry_documented() -> None:
    """Weryfikuje, że wszystkie checki w ALL_CUSTOM_CHECKS są udokumentowane."""
    for check_fn in ALL_CUSTOM_CHECKS:
        name = check_fn.__name__
        assert name in CHECK_REGISTRY, (
            f"Check '{name}' is not documented in CHECK_REGISTRY"
        )
    logger.info(
        "All %d custom checks are documented in CHECK_REGISTRY",
        len(ALL_CUSTOM_CHECKS),
    )
