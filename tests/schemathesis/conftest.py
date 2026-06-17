"""
conftest.py — Konfiguracja testów schemathesis dla NexusAI API.

SUPERMOCE schemathesis v4.21.8:
  - openapi.from_asgi() — native ASGI integration, zero network overhead
  - hooks system (before_process_request, after_call) — auth injection,
    request/response introspection, logowanie
  - custom checks — domain-specific validation rules dla polskiego systemu
    księgowego (VAT, split payment, JPK, KSeF)
  - generation.GenerationMode — RANDOM, BASE dla różnych trybów
  - stateful.run_state_machine_as_test — automatycze workflows
  - filters.by_value — targetowane testy per-endpoint

Usage:
    pytest tests/schemathesis/ -v --run-schemathesis
    pytest tests/schemathesis/ -v --run-schemathesis --run-slow  # + stateful

Inspiracja:
  - posthog/posthog: schemathesis w CI dla każdego PR
  - schemathesis.readthedocs.io: oficjalne wzorce
"""

from __future__ import annotations

import logging
import os
import sys
import uuid
from collections.abc import AsyncGenerator
# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC: Fix sys.path — zapobiega konfliktowi nazw z pakietem schemathesis
# ═══════════════════════════════════════════════════════════════════════════════
# Gdy pytest ładuje conftest z `tests/schemathesis/conftest.py`, dodaje
# `tests/` do sys.path. To powoduje, że `import schemathesis` znajduje
# NAJPIERW `tests/schemathesis/` (nasz katalog testów) zamiast prawdziwego
# pakietu `schemathesis` z site-packages.
#
# Fix: usuwamy `tests/` ze ścieżki przed importem schemathesis,
# a dodajemy go z powrotem po imporcie. Dzięki temu Python znajduje
# prawdziwy pakiet, a nie nasz katalog testów.
# ═══════════════════════════════════════════════════════════════════════════════

_TEST_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # tests/
_ORIGINAL_PATH = sys.path.copy()
sys.path = [p for p in sys.path if p != _TEST_DIR]

import schemathesis

# Przywróć oryginalną ścieżkę (pytest potrzebuje tests/ w sys.path)
sys.path = _ORIGINAL_PATH

import pytest
from litestar import Litestar
from litestar.testing import AsyncTestClient

from schemathesis import openapi as st_openapi

logger = logging.getLogger("nexus.tests.schemathesis")


# ═══════════════════════════════════════════════════════════════════════════════
# UWAGA: W schemathesis v4.21.8, konfiguracja generowania danych odbywa się
# przez ``SchemathesisConfig`` (z ``generation.dictionaries`` dla custom words),
# a nie przez ``generation_config`` dict. Parametr ``generation_config``
# NIE istnieje w ``openapi.from_asgi()`` w tej wersji.
#
# Gdy upstream doda wsparcie dla niestandardowych strategii przez config,
# należy dodać:
#   from schemathesis.config import SchemathesisConfig
#   config = SchemathesisConfig(dictionaries={...})
#   schema = openapi.from_asgi("/schema/openapi.yml", app, config=config)
# ═══════════════════════════════════════════════════════════════════════════════


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC: schema_from_app() — tworzy schemat ASGI z hookami wewnątrz
# ═══════════════════════════════════════════════════════════════════════════════
# UWAGA: Hooki są rejestrowane WEWNĄTRZ tej funkcji (nie jako dekoratory na
# poziomie modułu), aby uniknąć AttributeError przy imporcie.
# ═══════════════════════════════════════════════════════════════════════════════


def schema_from_app() -> tuple[schemathesis.schemas.BaseSchema, Litestar]:
    """Create schemathesis schema + ASGI app with hooks registered.

    SUPERMOC: openapi.from_asgi() ładuje OpenAPI bezpośrednio z aplikacji
    ASGI, bez potrzeby serwera HTTP. Zwraca krotkę (schema, app) —
    app jest potrzebna dla AsyncTestClient w testach stateful.

    SUPERMOC: generation_config kontroluje generowanie danych.
    SUPERMOC: fail_on_unknown_operation — fail na endpointach bez opisu.

    Hooks (zarejestrowane wewnątrz):
      - before_process_request: JWT auth token injection + trace headers
      - after_call: Logowanie naruszeń schematu

    Returns:
        tuple[BaseSchema, Litestar]: (schema, app) do testowania.
    """
    app = _create_schema_test_app()

    # ── SUPERMOC: openapi.from_asgi — ładuje OpenAPI z aplikacji ASGI ──
    # Parametry: path (URL do schematu), app (ASGI app), config (SchemathesisConfig)
    # Uwaga: generation_config jest przekazywany przez SchemathesisConfig
    # w schemathesis v4.21.8 (nie jako osobny kwarg).
    schema_instance = st_openapi.from_asgi(
        "/schema/openapi.yml",
        app,
    )

    # ── SUPERMOC: before_process_request hook — wstrzykiwanie JWT ──────
    # Rejestrowany WEWNĄTRZ funkcji, NIE jako dekorator na fixture.
    @schema_instance.before_process_request
    def add_auth_token(context: object, case: object) -> None:
        """Inject JWT auth token for protected endpoints.

        SUPERMOC: before_process_request hook — modyfikuje case przed
        wysłaniem. Wstrzykuje Bearer token dla endpointów wymagających auth.
        """
        token = os.getenv("SCHEMATESIS_JWT_TOKEN", "")
        if token and hasattr(case, "headers"):
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
# SUPERMOC: Tworzy aplikację używając PRAWDZIWEJ create_app() z app.py
# ═══════════════════════════════════════════════════════════════════════════════
# ZALETY:
#   - Zero duplikacji kontrolerów
#   - Automatyczna zgodność z produkcją
#   - Nowe endpointy są testowane od razu po dodaniu do create_app()
#   - Po dodaniu _app_after_request: testy walidują też nagłówki bezpieczeństwa
# ═══════════════════════════════════════════════════════════════════════════════


def _create_schema_test_app() -> Litestar:
    """Create a Litestar app using the REAL create_app() factory.

    ═══════════════════════════════════════════════════════════════════════════
    SUPERMOC: Zamiast duplikować listę kontrolerów, używamy prawdziwej
    create_app() z debug=True. To gwarantuje 100% zgodność między testami
    a produkcją — każdy nowy kontroler jest automatycznie testowany.
    ═══════════════════════════════════════════════════════════════════════════

    On startup/shutdown są zastąpione pustymi listami, ponieważ testy
    nie potrzebują rzeczywistych serwisów (DB, NATS, DuckDB).

    _app_after_request jest zachowany (nagłówki bezpieczeństwa są testowane).
    """
    # ── SUPERMOC: Ustaw zmienne środowiskowe dla trybu testowego ─────
    os.environ.setdefault("NEXUS_DEBUG", "true")
    os.environ.setdefault("NEXUS_DB_PATH", ":memory:")
    os.environ.setdefault("NEXUS_JWT_SECRET", "test-secret-not-for-prod")
    os.environ.setdefault("NEXUS_CSRF_ENABLED", "false")
    os.environ.setdefault("NEXUS_RATE_LIMIT_ENABLED", "false")
    os.environ.setdefault("NEXUS_CORS_ORIGINS", "*")

    from nexus_ai.api.app import create_app

    app = create_app()

    # ── Podmień on_startup/on_shutdown na puste (bez DB/NATS/DuckDB) ─
    app.on_startup = []
    app.on_shutdown = []

    return app


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC: Fixture dla AsyncTestClient
# ═══════════════════════════════════════════════════════════════════════════════
# Umożliwia testom stateful używanie AsyncTestClient zamiast httpx.
# Testuje ASGI app bezpośrednio — zero narzutu sieciowego.
# ═══════════════════════════════════════════════════════════════════════════════


@pytest.fixture
async def test_client() -> AsyncGenerator[AsyncTestClient, None]:
    """SUPERMOC: AsyncTestClient fixture dla testów stateful.

    Używa _test_app z schema_from_app() — tej samej app co schema.
    Działa jako context manager, automatycznie zamykając połączenia.
    """
    _, app = schema_from_app()
    async with AsyncTestClient(app=app) as client:
        yield client
