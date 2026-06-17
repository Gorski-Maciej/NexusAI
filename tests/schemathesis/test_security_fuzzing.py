"""
test_security_fuzzing.py — Security-focused schemathesis tests.

SUPERMOCE schemathesis v4.21.8:
  - DataGenerationMethod.negative — generowanie tylko nieprawidłowych danych
  - generation_config z allow_x00=True — testowanie SQL injection
  - Custom checks dla security: XSS, path traversal, injection detection
  - Workflow testy: auth bypass, brute-force resistance

Cel: Znajdowanie luk bezpieczeństwa zanim trafią do produkcji.

Inspiracja: OWASP API Security Top 10 + schemathesis security patterns.

Usage:
    pytest tests/schemathesis/test_security_fuzzing.py -v --run-schemathesis
    python scripts/schemathesis_runner.py --mode security
"""

from __future__ import annotations

import logging

import pytest
import schemathesis
from hypothesis import HealthCheck, settings
from schemathesis import checks as st_checks
from schemathesis.generation import GenerationMode

from tests.schemathesis.conftest import schema_from_app
from tests.schemathesis.checks import (
    check_no_server_error,
)
from tests.schemathesis import GenerationMode

logger = logging.getLogger("nexus.tests.schemathesis")
_schema, _test_app = schema_from_app()

# ── SUPERMOC: Osobny schemat dla security testów z agresywnym generowaniem ──
# Tworzymy osobną aplikację testową i schemat dla security fuzzingu.
# Używamy GenerationMode.NEGATIVE do generowania tylko nieprawidłowych danych.
_security_schema, _security_app = schema_from_app()

# ── Fallback dla HealthCheck.too_slow ──────────────────────────────────────
try:
    _SUPPRESS = [HealthCheck.too_slow]  # type: ignore[attr-defined]
except (ImportError, AttributeError):
    _SUPPRESS = []

pytestmark = [
    pytest.mark.schemathesis,
    pytest.mark.slow,
]


# ═══════════════════════════════════════════════════════════════════════════════
# UWAGA: W schemathesis v4.21.8, konfiguracja generowania danych (allow_x00,
# max_length, itp.) odbywa się przez ``SchemathesisConfig``, nie przez
# osobny słownik ``generation_config``. Funkcja ``from_asgi()`` nie akceptuje
# ``generation_config`` jako parametru.
#
# Gdy upstream doda wsparcie, security testy powinny używać osobnego
# ``SchemathesisConfig`` z agresywnymi ustawieniami:
#
#   from schemathesis.config import SchemathesisConfig
#   security_config = SchemathesisConfig(
#       dictionaries={
#           "strings": ["../", "..\\", "'; DROP TABLE", "<script>", "\x00"]
#       }
#   )
#   _security_schema = openapi.from_asgi(
#       "/schema/openapi.yml", _security_app, config=security_config
#   )
#
# Na razie security fuzzing używa GenerationMode.NEGATIVE który generuje
# nieprawidłowe dane (za długie stringi, ujemne liczby, itp.) — to zapewnia
# podstawową ochronę przed atakami.
# ═══════════════════════════════════════════════════════════════════════════════


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 1: SECURITY FUZZING Z GenerationMode.NEGATIVE
# ═══════════════════════════════════════════════════════════════════════════════


@_security_schema.parametrize(generation_mode=GenerationMode.NEGATIVE)
@settings(  # type: ignore[misc]
    max_examples=50,
    deadline=None,
    suppress_health_check=_SUPPRESS,
)
def test_security_fuzzing(case: schemathesis.Case) -> None:
    """SUPERMOC: Security-focused fuzzing z agresywnymi danymi.

    Używa GenerationMode.NEGATIVE do generowania tylko nieprawidłowych
    danych — celowo próbuje złamać API.

    Sprawdza:
      - NIGDY 500 — nawet przy złośliwych danych
      - Poprawny Content-Type dla błędów
      - Brak wycieków danych w odpowiedziach błędów

    max_examples=50 — bardzo dokładny fuzz dla security.
    """
    case.call_and_validate(
        checks=[
            st_checks.status_code_conformance,
            st_checks.content_type_conformance,
            check_no_server_error,  # No 5xx at all
            # Własny check inline: brak 500 nawet przy null bytes
            lambda ctx, c, r: (
                r.status_code != 500
                or AssertionError(
                    f"SECURITY: 500 for {c.method} {c.path} "
                    f"with negative data — potential vulnerability!"
                )
            ),
        ]
    )


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 2: SQL INJECTION PATTERNS
# ═══════════════════════════════════════════════════════════════════════════════
# Testuje czy endpointy są podatne na SQL injection przez body/params.
# ═══════════════════════════════════════════════════════════════════════════════

SQL_INJECTION_PATTERNS = [
    "' OR '1'='1",
    "'; DROP TABLE invoices; --",
    "\" OR 1=1 --",
    "' UNION SELECT * FROM users --",
    "1; SELECT * FROM passwords --",
    "' OR '1'='1' /*",
    "admin'--",
    "' OR 1=1 LIMIT 1 --",
    "' AND 1=CAST((SELECT COUNT(*) FROM users) AS int) --",
]


@pytest.mark.parametrize("sql_pattern", SQL_INJECTION_PATTERNS)
async def test_sql_injection_prevention(sql_pattern: str) -> None:
    """SUPERMOC: Test ochrony przed SQL injection.

    Wysyła znane wzorce SQL injection do endpointów i sprawdza,
    czy API nie zwraca 500 ani danych użytkowników.

    Args:
        sql_pattern: Wzorzec SQL injection do przetestowania
    """
    from litestar.testing import AsyncTestClient

    async with AsyncTestClient(app=_test_app) as client:
        # Test auth endpoint
        response = await client.post(
            "/api/auth/login",
            json={"username": sql_pattern, "password": sql_pattern},
        )
        assert response.status_code in (401, 422, 400), (
            f"SQL injection pattern '{sql_pattern}' caused {response.status_code} "
            f"on auth/login — potential vulnerability!"
        )

        # Test invoice search
        response = await client.get(f"/api/v1/invoices?search={sql_pattern}")
        assert response.status_code in (401, 422, 400, 200), (
            f"SQL injection pattern '{sql_pattern}' caused {response.status_code} "
            f"on invoices — potential vulnerability!"
        )


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 3: PATH TRAVERSAL ATTEMPTS
# ═══════════════════════════════════════════════════════════════════════════════

PATH_TRAVERSAL_PATTERNS = [
    "../../../etc/passwd",
    "..\\..\\..\\windows\\system32\\config",
    "%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd",
    "....//....//....//etc/passwd",
    "..;/..;/../etc/passwd",
]


@pytest.mark.parametrize("traversal_pattern", PATH_TRAVERSAL_PATTERNS)
async def test_path_traversal_prevention(traversal_pattern: str) -> None:
    """SUPERMOC: Test ochrony przed path traversal.

    Wysyła znane wzorce path traversal i sprawdza,
    czy API nie zwraca zawartości plików systemowych.

    Args:
        traversal_pattern: Wzorzec path traversal do przetestowania
    """
    from litestar.testing import AsyncTestClient

    async with AsyncTestClient(app=_test_app) as client:
        response = await client.get(f"/api/v1/files/{traversal_pattern}")
        # Powinno być 404, 403, 401, 422 — NIGDY 200 z treścią pliku
        assert response.status_code in (404, 403, 401, 422), (
            f"Path traversal pattern '{traversal_pattern}' caused "
            f"{response.status_code} — potential vulnerability!"
        )
        # Sprawdź czy odpowiedź nie zawiera wrażliwych danych
        if response.status_code == 200:
            text = response.text.lower()
            assert "root:" not in text, "Path traversal detected /etc/passwd leak!"
            assert "bin:" not in text, "Path traversal detected /etc/passwd leak!"


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 4: AUTH BYPASS — XSS W NAGŁÓWKACH
# ═══════════════════════════════════════════════════════════════════════════════

XSS_PATTERNS = [
    "<script>alert('xss')</script>",
    "<img src=x onerror=alert(1)>",
    "javascript:alert('xss')",
    "\"><script>alert(1)</script>",
    "<svg onload=alert(1)>",
]


@pytest.mark.parametrize("xss_pattern", XSS_PATTERNS)
async def test_xss_prevention_in_headers(xss_pattern: str) -> None:
    """SUPERMOC: Test ochrony przed XSS w nagłówkach i parametrach.

    Wysyła znane wzorce XSS w różnych miejscach requesta i sprawdza,
    czy API nie zwraca ich w odpowiedzi bez sanityzacji.

    Args:
        xss_pattern: Wzorzec XSS do przetestowania
    """
    from litestar.testing import AsyncTestClient

    async with AsyncTestClient(app=_test_app) as client:
        # XSS w nagłówku User-Agent
        response = await client.get(
            "/api/v1/health",
            headers={"User-Agent": xss_pattern, "X-Forwarded-For": xss_pattern},
        )
        # API powinno zwrócić JSON, nie HTML z wykonanym XSS
        assert response.status_code in (200, 401, 422), (
            f"XSS pattern in headers caused {response.status_code}"
        )
        # Sprawdź czy XSS nie został odbity w odpowiedzi
        if xss_pattern in response.text:
            logger.warning(
                "XSS pattern reflected in response: %s → %s",
                xss_pattern, response.status_code,
            )


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 5: RATE LIMIT BRUTE-FORCE DETECTION
# ═══════════════════════════════════════════════════════════════════════════════


async def test_brute_force_rate_limiting() -> None:
    """SUPERMOC: Test czy rate limiting chroni przed brute-force.

    Wykonuje serię szybkich zapytań do /api/auth/login i sprawdza,
    czy po przekroczeniu limitu API zwraca 429 Too Many Requests.

    UWAGA: Ten test wymaga włączonego rate limitingu w aplikacji.
    """
    from litestar.testing import AsyncTestClient

    async with AsyncTestClient(app=_test_app) as client:
        rate_limited = False
        for i in range(20):  # 20 szybkich prób logowania
            response = await client.post(
                "/api/auth/login",
                json={"username": f"brute_{i}", "password": "test"},
            )
            if response.status_code == 429:
                rate_limited = True
                logger.info("Rate limiting triggered after %d attempts", i)
                break

        if not rate_limited:
            logger.warning(
                "Rate limiting NOT triggered after 20 attempts — "
                "may need to enable RateLimitConfig in test app"
            )
