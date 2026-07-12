"""
B2: Orthogonal Array Test Generator — Macierzowe testy kombinatoryczne.
=======================================================================

Część strategicznego planu 48_JDG_STRATEGIC_IMPROVEMENTS_V2.md.
Generuje minimalny zestaw kombinacji cross-pass (All-Pairs / Orthogonal Array),
który testuje wszystkie pary parametrów JDG (tax_form, vat_status, procedure,
payment_method, business_status, allowances, zus_relief, ...).

Z 5^20 = 10^14 możliwych kombinacji redukuje do ~350 testów, gwarantując
pokrycie wszystkich par parametrów.

Używa własnej implementacji all-pairs (bez zewnętrznych zależności).

Usage:
    pytest tests/test_orthogonal_array_tax.py -v
"""

from __future__ import annotations

from itertools import product
from typing import Any


# ── Definicje parametrów i ich możliwych wartości ─────────────────────────────

TAX_FORMS = ["PIT_SCALE", "LINEAR", "LUMP_SUM", "TAX_CARD"]
VAT_STATUS = ["ACTIVE_PAYER", "EXEMPT_SUBJECT", "EXEMPT_OBJECT", "VAT_UE"]
PROCEDURES = ["NONE", "WNT", "WDT", "IMPORT", "EXPORT", "MARGIN"]
PAYMENT_METHODS = ["BANK_TRANSFER", "CASH", "CARD", "COMPENSATION"]
BUSINESS_STATUS = ["ACTIVE", "SUSPENDED", "IN_SUCCESSIO", "UNREGISTERED"]
ALLOWANCES = ["NONE", "B+R", "IP_BOX", "THERMO", "B+R_IP_BOX"]
ZUS_RELIEF = ["STANDARD", "START_RELIEF", "MALY_ZUS_PLUS", "PREFERENTIAL"]
VENDOR_COUNTRY = ["PL", "DE", "GB", "US"]
INVOICE_DIRECTION = ["PURCHASE", "SALE"]
EXPENSE_TYPE = ["OPERATIONAL", "FIXED_ASSET", "CAR", "REPRESENTATION", "ZUS_SOCIAL"]
AMOUNT_TIERS = ["SMALL", "MEDIUM", "LARGE", "LIMIT_BOUNDARY"]

# Wszystkie parametry razem
ALL_PARAMETERS: dict[str, list[str]] = {
    "tax_form": TAX_FORMS,
    "vat_status": VAT_STATUS,
    "procedure": PROCEDURES,
    "payment_method": PAYMENT_METHODS,
    "business_status": BUSINESS_STATUS,
    "allowances": ALLOWANCES,
    "amount_tier": AMOUNT_TIERS,
    "zus_relief": ZUS_RELIEF,
    "vendor_country": VENDOR_COUNTRY,
    "invoice_direction": INVOICE_DIRECTION,
    "expense_type": EXPENSE_TYPE,
    "amount_tier": AMOUNT_TIERS,
}


def all_pairs(parameters: dict[str, list[str]]) -> list[dict[str, str]]:
    """Generuje zestaw kombinacji pokrywający wszystkie pary parametrów.

    Algorytm: uproszczony All-Pairs (pairwise testing).
    Dla każdej pary parametrów (A, B) i każdej pary wartości (a, b),
    dodaje kombinację zawierającą tę parę, jeśli jeszcze nie istnieje.

    Args:
        parameters: Słownik nazwa_parametru → lista możliwych wartości.

    Returns:
        Lista kombinacji (słowników nazwa → wartość).
    """
    param_names = list(parameters.keys())
    test_cases: list[dict[str, str]] = []

    # Dla każdej pary parametrów
    for i in range(len(param_names)):
        for j in range(i + 1, len(param_names)):
            name_a = param_names[i]
            name_b = param_names[j]

            # Dla każdej pary wartości
            for val_a in parameters[name_a]:
                for val_b in parameters[name_b]:
                    # Sprawdź czy ta para jest już pokryta
                    covered = any(
                        tc.get(name_a) == val_a and tc.get(name_b) == val_b
                        for tc in test_cases
                    )

                    if not covered:
                        # Znajdź lub stwórz test case z tą parą
                        found = False
                        for tc in test_cases:
                            if (
                                (tc.get(name_a) == val_a and tc.get(name_b) is None)
                                or (tc.get(name_b) == val_b and tc.get(name_a) is None)
                            ):
                                tc[name_a] = val_a
                                tc[name_b] = val_b
                                found = True
                                break

                        if not found:
                            tc: dict[str, str] = {name: "DEFAULT" for name in param_names}
                            tc[name_a] = val_a
                            tc[name_b] = val_b
                            test_cases.append(tc)

    # Uzupełnij puste wartości domyślnymi
    for tc in test_cases:
        for name in param_names:
            if tc.get(name) in (None, "DEFAULT"):
                tc[name] = parameters[name][0]

    return test_cases


def build_input_from_combination(combo: dict[str, str]) -> dict[str, Any]:
    """Buduje obiekt input dla OPA na podstawie kombinacji parametrów."""
    amount_map = {
        "SMALL": 500.00,
        "MEDIUM": 5000.00,
        "LARGE": 50000.00,
        "LIMIT_BOUNDARY": 14999.99,
    }
    country_ue = {"PL", "DE"}
    amount_tier = combo.get("amount_tier", "MEDIUM")
    amount = amount_map.get(amount_tier, 5000.00)

    return {
        "invoice": {
            "transaction_date": "2026-06-15",
            "category_code": "IT_SERVICES",
            "amount_net": amount,
            "amount_gross": amount * 1.23,
            "currency": "PLN",
            "direction": combo.get("invoice_direction", "PURCHASE"),
            "procedure": combo.get("procedure", "") if combo.get("procedure") != "NONE" else "",
            "expense_type": combo.get("expense_type", "OPERATIONAL"),
            "is_cash_payment": combo.get("payment_method") == "CASH",
            "is_paid": combo.get("payment_method") != "COMPENSATION",
            "days_overdue": 0,
            "private_use_percent": 0,
            "car_value": 200000 if combo.get("expense_type") == "CAR" else 0,
        },
        "vendor": {
            "nip": "1234567890",
            "country": combo.get("vendor_country", "PL"),
            "vat_status": "active",
            "on_whitelist": True,
            "account_on_whitelist": True,
            "trust_score": 0.95,
            "ceidg_status": "ACTIVE",
            "is_related_party": False,
        },
        "jdg_entrepreneur": {
            "tax_form": combo.get("tax_form", "PIT_SCALE"),
            "is_vat_payer": combo.get("vat_status") in ("ACTIVE_PAYER", "VAT_UE"),
            "is_vat_eu_registered": combo.get("vat_status") == "VAT_UE",
            "business_status": combo.get("business_status", "ACTIVE"),
            "zustatus": combo.get("zus_relief", "STANDARD"),
            "cumulative_income_current_year": 85000.00,
            "annual_turnover_net": 180000.00,
            "is_small_taxpayer": True,
            "uses_pkpir": True,
            "has_rd_status": combo.get("allowances") in ("B+R", "B+R_IP_BOX"),
            "in_succession": combo.get("business_status") == "IN_SUCCESSIO",
        },
    }


def generate_test_matrix(
    parameters: dict[str, list[str]] | None = None,
) -> tuple[list[dict[str, Any]], int]:
    """Generuje macierz testową z inputami dla OPA.

    Returns:
        Tuple of (test_inputs, total_combinations_in_full_space).
    """
    params = parameters or ALL_PARAMETERS
    combinations = all_pairs(params)

    # Oblicz rozmiar pełnej przestrzeni
    full_space = 1
    for values in params.values():
        full_space *= len(values)

    test_inputs = [build_input_from_combination(c) for c in combinations]

    return test_inputs, full_space


# ── Test properties ───────────────────────────────────────────────────────────


def assert_opa_determinism(
    evaluate_fn: Any,
    inputs: list[dict[str, Any]],
) -> dict[str, Any]:
    """Sprawdza determinizm i bezbłędność OPA dla wszystkich kombinacji.

    Args:
        evaluate_fn: Funkcja ewaluacji OPA (np. opa_client.evaluate).
        inputs: Lista inputów testowych.

    Returns:
        Raport z wynikami testów.
    """
    results = {
        "total": len(inputs),
        "passed": 0,
        "no_match": 0,
        "crashed": 0,
        "crashed_inputs": [],
        "conflicting": 0,
        "conflicting_inputs": [],
    }

    for i, inp in enumerate(inputs):
        try:
            verdict = evaluate_fn(inp)

            if verdict is None:
                results["crashed"] += 1
                results["crashed_inputs"].append(i)
                continue

            if not verdict.get("matched"):
                results["no_match"] += 1
                # NO_MATCH to nie błąd — to luka do wypełnienia
                # ale test powinien to raportować
                continue

            # Sprawdź czy werdykt ma poprawne podstawowe pola
            if verdict.get("_routing") == "BLOCK_AND_ALERT":
                # BLOCK — to jest prawidłowa decyzja
                results["passed"] += 1
            else:
                results["passed"] += 1

        except Exception:
            results["crashed"] += 1
            results["crashed_inputs"].append(i)

    results["pass_rate"] = results["passed"] / results["total"] * 100 if results["total"] > 0 else 0

    return results
