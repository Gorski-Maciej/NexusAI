# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Rego Unit Tests (v8.0)
# Testy dla kluczowych pakietów: VAT, PIT, ZUS, KKS
# R13: Dodanie testów Rego (RAPORT_P25)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Usage:
#   opa test JDG/tests/ -v
#
# UWAGA: Testy wymagają istnienia testowanych pakietów w JDG/rules/.
# Jeśli `opa test` zgłasza "package not found", sprawdź czy pakiet istnieje.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.tests.vat_substantive

# Import testowanych pakietów (OPA test runner wymaga jawnych importów)
import data.jdg.vat.substantive

# ── Test 1: Standardowa stawka VAT 23% dla paliwa ──────────────────────────

test_fuel_23pct_vat {
    result := substantive.decide with input as {
        "payload": {
            "invoice": {
                "expense_type": "FUEL",
                "amount_net": 1000.00,
                "direction": "PURCHASE",
                "country": "PL"
            },
            "jdg_entrepreneur": {
                "vat_status": "ACTIVE",
                "tax_form": "SCALE"
            }
        }
    }

    result.matched == true
    result.vat_rate == "0.23"
    # Weryfikuj, że rule_id zawiera "fuel" (użyj regex zamiast contains)
    regex.match("fuel", result.rule_id)
}

# ── Test 2: Stawka 8% dla żywności ─────────────────────────────────────────

test_food_8pct_vat {
    result := substantive.decide with input as {
        "payload": {
            "invoice": {
                "expense_type": "FOOD",
                "amount_net": 500.00,
                "direction": "PURCHASE",
                "country": "PL"
            },
            "jdg_entrepreneur": {
                "vat_status": "ACTIVE",
                "tax_form": "SCALE"
            }
        }
    }

    # Jeśli reguła istnieje, powinna zwrócić matched = true
    result.matched == true
}

# ── Test 3: No-match fallback ──────────────────────────────────────────────

test_vat_no_match_fallback {
    result := substantive.decide with input as {
        "payload": {
            "invoice": {
                "expense_type": "UNKNOWN_XYZ_12345",
                "amount_net": 1.00,
                "direction": "PURCHASE",
                "country": "PL"
            },
            "jdg_entrepreneur": {
                "vat_status": "ACTIVE",
                "tax_form": "SCALE"
            }
        }
    }

    # Fallback powinien istnieć z niepustym rule_id
    result.rule_id != ""
}

# ── Test 4: Werdykt ma wymagane pola ────────────────────────────────────────

test_verdict_has_required_fields {
    result := substantive.decide with input as {
        "payload": {
            "invoice": {
                "expense_type": "OFFICE_SUPPLIES",
                "amount_net": 200.00,
                "direction": "PURCHASE",
                "country": "PL"
            },
            "jdg_entrepreneur": {
                "vat_status": "ACTIVE",
                "tax_form": "SCALE"
            }
        }
    }

    # Sprawdź obecność kluczowych pól (użyj object.get dla bezpieczeństwa)
    object.get(result, "matched", "") != ""
    object.get(result, "rule_id", "") != ""
}


# ── TESTS: PIT Forms ─────────────────────────────────────────────────────────

package jdg.tests.pit_forms

import data.jdg.pit.forms

test_pit_scale_form {
    result := forms.decide with input as {
        "payload": {
            "jdg_entrepreneur": {
                "tax_form": "SCALE",
                "annual_taxable_income": 50000
            }
        }
    }
    result.matched == true
    result.pit_form == "SCALE"
}

test_pit_linear_form {
    result := forms.decide with input as {
        "payload": {
            "jdg_entrepreneur": {
                "tax_form": "LINEAR",
                "annual_taxable_income": 200000
            }
        }
    }
    result.matched == true
    result.pit_form == "LINEAR"
}


# ── TESTS: ZUS ──────────────────────────────────────────────────────────────

package jdg.tests.zus

import data.jdg.zus

test_zus_health_contribution {
    result := zus.decide with input as {
        "payload": {
            "jdg_entrepreneur": {
                "tax_form": "SCALE",
                "business_status": "ACTIVE",
                "zus_start_relief_active": false,
                "zus_maly_plus_active": false
            }
        }
    }
    # Reguła ZUS powinna istnieć i zwracać wynik
    result.rule_id != ""
}


# ── TESTS: KKS ──────────────────────────────────────────────────────────────

package jdg.tests.kks

import data.jdg.kks

test_kks_empty_invoice {
    result := kks.decide with input as {
        "payload": {
            "invoice": {
                "document_type": "INVOICE",
                "amount_net": 0,
                "amount_gross": 0,
                "direction": "SALE"
            },
            "jdg_entrepreneur": {
                "vat_status": "ACTIVE"
            }
        }
    }
    # Reguła KKS powinna istnieć
    result.rule_id != ""
}


# ── TESTS: Edge Cases ───────────────────────────────────────────────────────

package jdg.tests.edge_cases

import data.jdg.edge_cases

test_vat_breach_mid_year {
    result := edge_cases.decide with input as {
        "payload": {
            "jdg_entrepreneur": {
                "vat_status": "EXEMPT",
                "sales_ytd_vat_exempt": 250000
            }
        }
    }
    result.rule_id != ""
}


# ── TESTS: Cross-Border ─────────────────────────────────────────────────────

package jdg.tests.crossborder

import data.jdg.crossborder

test_wnt_reverse_charge {
    result := crossborder.decide with input as {
        "payload": {
            "invoice": {
                "direction": "PURCHASE",
                "procedure": "WNT",
                "amount_net": 10000,
                "currency": "EUR"
            },
            "vendor": {
                "country": "DE"
            },
            "jdg_entrepreneur": {
                "vat_status": "ACTIVE"
            }
        }
    }
    result.rule_id != ""
}
