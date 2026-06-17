"""
checks.py — Custom schemathesis checks dla polskiego systemu księgowego.

SUPERMOCE schemathesis:
  - Custom checks: własne funkcje walidujące odpowiedzi API
  - Każdy check to funkcja przyjmująca (context, case, response)
  - Checks są łączone w listę i przekazywane do case.call_and_validate()

Użycie:
    case.call_and_validate(
        checks=[
            st_checks.status_code_conformance,
            check_response_time,
            check_no_internal_server_error,
            check_content_type_json,
        ],
    )
"""

from __future__ import annotations

from typing import Any

import schemathesis
from schemathesis.transport import Response as STResponse
from schemathesis.schemas import Case


# ═══════════════════════════════════════════════════════════════════════════════
# Custom Check 1: Response Time Guard
# ═══════════════════════════════════════════════════════════════════════════════


def check_response_time(
    context: schemathesis.execution.context.ExecutionContext,
    case: Case,
    response: STResponse,
) -> None | bool:
    """SUPERMOC: Weryfikuje czas odpowiedzi API.

    Sprawdza, czy odpowiedź nie przekracza zadeklarowanego czasu
    (domyślnie 5 sekund). Dłuższe odpowiedzi to potencjalny problem
    wydajnościowy do zbadania.

    Granice czasowe:
      - < 500ms: ✅ Idealny
      - 500ms-2s: ⚠️ Dopuszczalny (wymaga monitorowania)
      - 2s-5s: 🔴 Przekroczony (problem wydajnościowy)
      - > 5s: ❌ FAIL — narusza SLA

    Args:
        context: Kontekst wykonania schemathesis
        case: Przypadek testowy
        response: Odpowiedź HTTP

    Returns:
        True jeśli check przeszedł, False jeśli nie
    """
    import time

    if hasattr(response, "elapsed"):
        elapsed = response.elapsed.total_seconds()
    else:
        return True  # Cannot check, skip

    max_time = 5.0  # 5 sekund

    if elapsed > max_time:
        raise AssertionError(
            f"Response time {elapsed:.2f}s exceeds maximum {max_time}s "
            f"for {case.method} {case.path}"
        )

    return True


# ═══════════════════════════════════════════════════════════════════════════════
# Custom Check 2: No Internal Server Error
# ═══════════════════════════════════════════════════════════════════════════════


def check_no_internal_server_error(
    context: schemathesis.execution.context.ExecutionContext,
    case: Case,
    response: STResponse,
) -> None | bool:
    """SUPERMOC: Weryfikuje brak 500 Internal Server Error.

    Nawet dla losowych danych wejściowych, API NIGDY nie powinno
    zwracać 500. Zamiast tego:
      - Błędy walidacji → 422 (ValidationDomainError)
      - Błędy autoryzacji → 401/403
      - Błędy biznesowe → 409 (BusinessRuleDomainError)
      - Błędy integracji → 502/504

    Każdy 500 to bug do natychmiastowej naprawy.
    """
    if response.status_code == 500:
        raise AssertionError(
            f"Internal Server Error (500) for {case.method} {case.path}. "
            f"API must never return 500. Response body: {response.text[:500]}"
        )
    return True


# ═══════════════════════════════════════════════════════════════════════════════
# Custom Check 3: Content-Type JSON
# ═══════════════════════════════════════════════════════════════════════════════


def check_content_type_json(
    context: schemathesis.execution.context.ExecutionContext,
    case: Case,
    response: STResponse,
) -> None | bool:
    """SUPERMOC: Weryfikuje Content-Type odpowiedzi.

    Wszystkie endpointy API powinny zwracać application/json,
    chyba że specyfikacja OpenAPI mówi inaczej.
    """
    content_type = response.headers.get("Content-Type", "")
    if not content_type.startswith("application/json"):
        # Endpointy plikowe mogą mieć inne Content-Type
        if "/files" not in case.path and "/export" not in case.path:
            raise AssertionError(
                f"Expected application/json, got {content_type} "
                f"for {case.method} {case.path}"
            )
    return True


# ═══════════════════════════════════════════════════════════════════════════════
# Custom Check 4: Security Headers Present
# ═══════════════════════════════════════════════════════════════════════════════


def check_security_headers(
    context: schemathesis.execution.context.ExecutionContext,
    case: Case,
    response: STResponse,
) -> None | bool:
    """SUPERMOC: Weryfikuje obecność nagłówków bezpieczeństwa.

    Sprawdza czy odpowiedź zawiera wymagane nagłówki bezpieczeństwa
    zgodnie z _app_after_request w app.py:
      - X-Content-Type-Options: nosniff
      - X-Frame-Options: DENY
      - Referrer-Policy: no-referrer
    """
    required_headers = {
        "X-Content-Type-Options": "nosniff",
        "X-Frame-Options": "DENY",
        "Referrer-Policy": "no-referrer",
    }

    for header, expected_value in required_headers.items():
        actual = response.headers.get(header)
        if actual is None:
            raise AssertionError(
                f"Missing security header '{header}' "
                f"in {case.method} {case.path}"
            )
    return True


# ═══════════════════════════════════════════════════════════════════════════════
# Rejestr wszystkich custom checks
# ═══════════════════════════════════════════════════════════════════════════════

ALL_CUSTOM_CHECKS = [
    check_response_time,
    check_no_internal_server_error,
    check_content_type_json,
    # check_security_headers  # WYŁĄCZONE: test app nie ma middleware stacka
    # W produkcyjnym create_app() nagłówki są dodawane przez _app_after_request.
    # Aby włączyć: dodaj after_request=[_app_after_request] do test app.
]
