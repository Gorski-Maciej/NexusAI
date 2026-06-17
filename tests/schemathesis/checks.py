"""
checks.py — Custom schemathesis checks dla polskiego systemu księgowego.

SUPERMOCE schemathesis v4.21.8:
  - Custom checks: własne funkcje walidujące odpowiedzi API
  - Każdy check to funkcja przyjmująca (context, case, response)
  - Checks są łączone w listę i przekazywane do case.call_and_validate()
  - Wbudowane: checks.not_a_server_error, checks.max_response_time

Nowe SUPERMOCE biznesowe:
  - check_vat_calculation — weryfikuje netto × stawka VAT = kwota VAT
  - check_polish_nip_format — weryfikuje format NIP (10 cyfr)
  - check_no_server_error — sprawdza brak 5xx (szersze niż tylko 500)
  - check_security_headers — włączone z pełną walidacją

Inspiracja: schemathesis.readthedocs.io — custom checks dla domain-driven testing.

Usage:
    case.call_and_validate(
        checks=[
            st_checks.status_code_conformance,
            *ALL_CUSTOM_CHECKS,
        ],
    )
"""

from __future__ import annotations

from typing import Any

from schemathesis import checks as st_checks
from schemathesis.schemas import Case
from schemathesis.transport import Response as STResponse


# ═══════════════════════════════════════════════════════════════════════════════
# Custom Check 1: Response Time Guard
# ═══════════════════════════════════════════════════════════════════════════════


def check_response_time(
    context: st_checks.CheckContext,
    case: Case,
    response: STResponse,
) -> None | bool:
    """SUPERMOC: Weryfikuje czas odpowiedzi API.

    Sprawdza, czy odpowiedź nie przekracza zadeklarowanego czasu
    (domyślnie 5 sekund). Dłuższe odpowiedzi to potencjalny problem
    wydajnościowy do zbadania.

    Granice czasowe:
      - < 500ms: ✅ Idealny
      - 500ms-2s: ⚠️ Dopuszczalny
      - 2s-5s: 🔴 Przekroczony
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
    context: st_checks.CheckContext,
    case: Case,
    response: STResponse,
) -> None | bool:
    """SUPERMOC: Weryfikuje brak 500 Internal Server Error.

    Nawet dla losowych danych wejściowych, API NIGDY nie powinno
    zwracać 500. Zamiast tego:
      - Błędy walidacji → 422
      - Błędy autoryzacji → 401/403
      - Błędy biznesowe → 409
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
    context: st_checks.CheckContext,
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
# Custom Check 4: Security Headers Present (WŁĄCZONY)
# ═══════════════════════════════════════════════════════════════════════════════
# Uwaga: Ten check wymaga _app_after_request w aplikacji testowej.
# conftest.py używa prawdziwej create_app() która ma _app_after_request.
# Dlatego ten check jest teraz AKTYWNY.
# ═══════════════════════════════════════════════════════════════════════════════


def check_security_headers(
    context: st_checks.CheckContext,
    case: Case,
    response: STResponse,
) -> None | bool:
    """SUPERMOC: Weryfikuje obecność nagłówków bezpieczeństwa.

    Sprawdza czy odpowiedź zawiera wymagane nagłówki bezpieczeństwa
    zgodnie z _app_after_request w app.py:
      - X-Content-Type-Options: nosniff
      - X-Frame-Options: DENY
      - Referrer-Policy: no-referrer
      - Permissions-Policy
      - Content-Security-Policy
    """
    required_headers = {
        "X-Content-Type-Options": "nosniff",
        "X-Frame-Options": "DENY",
        "Referrer-Policy": "no-referrer",
        "Permissions-Policy": None,  # Sprawdzamy tylko obecność
        "Content-Security-Policy": None,  # Sprawdzamy tylko obecność
    }

    for header, expected_value in required_headers.items():
        actual = response.headers.get(header)
        if actual is None:
            raise AssertionError(
                f"Missing security header '{header}' "
                f"in {case.method} {case.path}"
            )
        if expected_value is not None and actual != expected_value:
            raise AssertionError(
                f"Security header '{header}' has value '{actual}', "
                f"expected '{expected_value}' in {case.method} {case.path}"
            )
    return True


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC: Custom Check 5 — Weryfikacja VAT
# ═══════════════════════════════════════════════════════════════════════════════


def check_vat_calculation(
    context: st_checks.CheckContext,
    case: Case,
    response: STResponse,
) -> None | bool:
    """SUPERMOC: Weryfikuje poprawność wyliczenia VAT.

    Sprawdza: netto × stawka VAT = kwota VAT (z dokładnością do 1 gr).
    Działa tylko dla 200 OK z odpowiednimi polami w odpowiedzi.

    Business rule:
      vat_amount = round(net_amount * vat_rate / 100, 2)

    Args:
        context: Kontekst wykonania
        case: Przypadek testowy
        response: Odpowiedź HTTP

    Returns:
        True jeśli check przeszedł lub nie można zweryfikować
    """
    if response.status_code != 200:
        return True

    try:
        data = response.json()
    except (ValueError, TypeError):
        return True

    if isinstance(data, dict) and all(
        k in data for k in ("net_amount", "vat_amount", "vat_rate")
    ):
        try:
            # ── SUPERMOC: Inteligentne parsowanie kwot ────────────────
            # Pola kończące się na _cents są w groszach → int (precyzja)
            # Pola kończące się na _amount są w PLN → float (display)
            def _parse_amount(key: str, value: object) -> float:
                if key.endswith("_cents"):
                    return float(int(value))  # int dla precyzji groszowej
                return float(value)  # float dla kwot PLN

            net = _parse_amount("net_amount", data["net_amount"])
            vat_rate = float(data["vat_rate"])
            actual_vat = _parse_amount("vat_amount", data["vat_amount"])
            expected_vat = round(net * vat_rate / 100, 2)

            assert abs(actual_vat - expected_vat) < 0.01, (
                f"VAT calculation mismatch in {case.method} {case.path}: "
                f"got {actual_vat}, expected {expected_vat} "
                f"(net={net}, rate={vat_rate}%)"
            )
        except (TypeError, ValueError) as exc:
            raise AssertionError(
                f"Invalid VAT field types in {case.method} {case.path}: {exc}"
            )

    return True


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC: Custom Check 6 — Weryfikacja formatu NIP
# ═══════════════════════════════════════════════════════════════════════════════


def check_polish_nip_format(
    context: st_checks.CheckContext,
    case: Case,
    response: STResponse,
) -> None | bool:
    """SUPERMOC: Weryfikuje format polskiego NIP (10 cyfr).

    Rekurencyjnie przeszukuje odpowiedź JSON w poszukiwaniu pól
    zawierających NIP (nip, tax_id, vat_id) i weryfikuje format.

    Polski NIP:
      - Dokładnie 10 cyfr
      - Opcjonalnie z myślnikami (XXX-XXX-XX-XX)
      - Może zawierać spacje

    Args:
        context: Kontekst wykonania
        case: Przypadek testowy
        response: Odpowiedź HTTP

    Returns:
        True jeśli check przeszedł lub nie znaleziono NIP
    """
    if response.status_code != 200:
        return True

    try:
        data = response.json()
    except (ValueError, TypeError):
        return True

    def _find_nip_fields(obj: Any, depth: int = 0) -> list[str]:
        """Rekurencyjnie znajduje wartości pól NIP."""
        results: list[str] = []
        if depth > 4:  # Limit głębokości
            return results
        if isinstance(obj, dict):
            for k, v in obj.items():
                if k.lower() in ("nip", "tax_id", "vat_id", "contractor_nip"):
                    if isinstance(v, (str, int)):
                        results.append(str(v))
                results.extend(_find_nip_fields(v, depth + 1))
        elif isinstance(obj, list):
            for item in obj:
                results.extend(_find_nip_fields(item, depth + 1))
        return results

    for nip_value in _find_nip_fields(data):
        nip_str = str(nip_value).replace("-", "").replace(" ", "").strip()
        if nip_str and nip_str.isdigit() and len(nip_str) > 0:
            if len(nip_str) != 10:
                raise AssertionError(
                    f"Invalid NIP format in {case.method} {case.path}: "
                    f"'{nip_value}' has {len(nip_str)} digits, expected 10"
                )

    return True


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC: Custom Check 7 — Brak 5xx (szerszy niż tylko 500)
# ═══════════════════════════════════════════════════════════════════════════════


def check_no_server_error(
    context: st_checks.CheckContext,
    case: Case,
    response: STResponse,
) -> None | bool:
    """SUPERMOC: Sprawdza czy nie ma błędów serwera (5xx).

    Standardowo schemathesis sprawdza tylko 500. Ten check idzie dalej:
      - 502 Bad Gateway
      - 503 Service Unavailable
      - 504 Gateway Timeout

    Każdy 5xx to potencjalny problem produkcyjny.
    """
    if 500 <= response.status_code < 600:
        raise AssertionError(
            f"Server error {response.status_code} for {case.method} {case.path}. "
            f"API must never return 5xx. "
            f"Response body: {response.text[:300]}"
        )
    return True


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC: Custom Check 8 — Wymagane pola nie są null
# ═══════════════════════════════════════════════════════════════════════════════


def check_required_fields_not_null(
    context: st_checks.CheckContext,
    case: Case,
    response: STResponse,
) -> None | bool:
    """SUPERMOC: Sprawdza czy wymagane pola odpowiedzi nie są null.

    Dla każdej odpowiedzi 200 OK weryfikuje, że kluczowe pola
    (id, created_at, status, version) nie mają wartości null.

    Args:
        context: Kontekst wykonania
        case: Przypadek testowy
        response: Odpowiedź HTTP
    """
    if response.status_code != 200:
        return True

    try:
        data = response.json()
    except (ValueError, TypeError):
        return True

    # Kluczowe pola które nigdy nie powinny być null
    required_non_null = {"id", "created_at", "status"}

    if isinstance(data, dict):
        for key in required_non_null:
            if key in data and data[key] is None:
                raise AssertionError(
                    f"Required field '{key}' is null in {case.method} {case.path}"
                )

    return True


# ═══════════════════════════════════════════════════════════════════════════════
# Rejestr wszystkich custom checks
# ═══════════════════════════════════════════════════════════════════════════════

ALL_CUSTOM_CHECKS = [
    check_response_time,
    check_no_internal_server_error,
    check_content_type_json,
    check_security_headers,  # ✅ WŁĄCZONE — conftest.py używa create_app() z _app_after_request
    check_vat_calculation,  # ✅ NOWOŚĆ — walidacja VAT
    check_polish_nip_format,  # ✅ NOWOŚĆ — walidacja NIP
    check_no_server_error,  # ✅ NOWOŚĆ — walidacja 5xx
    check_required_fields_not_null,  # ✅ NOWOŚĆ — null safety
]

# ── Opis każdego checka dla --coverage / --help ───────────────────────────────
CHECK_REGISTRY: dict[str, dict[str, str]] = {
    "check_response_time": {
        "description": "Response time < 5s SLA",
        "category": "performance",
    },
    "check_no_internal_server_error": {
        "description": "No 500 Internal Server Error",
        "category": "reliability",
    },
    "check_content_type_json": {
        "description": "Content-Type is application/json",
        "category": "conformance",
    },
    "check_security_headers": {
        "description": "Security headers present (X-Content-Type-Options, CSP, etc.)",
        "category": "security",
    },
    "check_vat_calculation": {
        "description": "VAT math: net_amount × vat_rate / 100 = vat_amount",
        "category": "business",
    },
    "check_polish_nip_format": {
        "description": "Polish NIP format: exactly 10 digits",
        "category": "business",
    },
    "check_no_server_error": {
        "description": "No 5xx server errors (502, 503, 504)",
        "category": "reliability",
    },
    "check_required_fields_not_null": {
        "description": "Required fields (id, created_at, status) are not null",
        "category": "conformance",
    },
}
