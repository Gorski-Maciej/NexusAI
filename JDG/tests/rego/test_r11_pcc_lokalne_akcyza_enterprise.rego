# ═══════════════════════════════════════════════════════════════════════════════
# RAPORT_11 — PCC / PODATKI LOKALNE / AKCYZĄ — natywne testy Rego
# Scenariusze: happy path, granice (progi, limity), negatywne (no_match),
# temporalność (valid_from/valid_to) dla R11-INN-01..05.
# Uruchomienie: opa test (native OPA) — struktura jak test_r10_*.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r11_pcc_lokalne_akcyza_innovations

import future.keywords.if

# ── R11-INN-01: PCC3 DEADLINE ALERT MONITOR ───────────────────────────────────

test_inn01_red_when_3_days_unfiled if {
    decide := jdg.r11_pcc_lokalne_akcyza_innovations.decide with input as {
        "jdg_entrepreneur": {"r11_pcc_local_excise_check": true},
        "pcc3_monitor": {
            "items": [
                {"label": "Umowa sprzedaży", "days_left": 3, "filed": false},
            ],
        },
    }
    decide.rule_id == "jdg.r11_pcc_lokalne_akcyza_innovations.pcc3_deadline_alert_monitor"
    decide.pcc3_red_count == 1
    decide.pcc3_unfiled_count == 1
    decide._routing == "BLOCK_AND_ALERT"
    decide.pcc3_items[0].level == "RED"
}

test_inn01_amber_when_5_days if {
    decide := jdg.r11_pcc_lokalne_akcyza_innovations.decide with input as {
        "jdg_entrepreneur": {"r11_pcc_local_excise_check": true},
        "pcc3_monitor": {
            "items": [
                {"label": "Pożyczka", "days_left": 5, "filed": false},
            ],
        },
    }
    decide.pcc3_items[0].level == "AMBER"
    decide._routing == "TRIAGE_QUEUE"
}

test_inn01_green_when_filed if {
    decide := jdg.r11_pcc_lokalne_akcyza_innovations.decide with input as {
        "jdg_entrepreneur": {"r11_pcc_local_excise_check": true},
        "pcc3_monitor": {
            "items": [
                {"label": "Spółka", "days_left": 10, "filed": true},
            ],
        },
    }
    decide.pcc3_unfiled_count == 0
    decide._routing == ""
}

# ── R11-INN-02: REAL ESTATE TAX SIMULATOR ─────────────────────────────────────

test_inn02_simulator_computes_annual if {
    decide := jdg.r11_pcc_lokalne_akcyza_innovations.decide with input as {
        "jdg_entrepreneur": {"r11_pcc_local_excise_check": true},
        "property_tax": {
            "land_business_m2": 500,
            "building_business_m2": 100,
            "months_remaining": 12,
        },
    }
    decide.rule_id == "jdg.r11_pcc_lokalne_akcyza_innovations.real_estate_tax_simulator"
    decide.ret_land_annual == 715
    decide.ret_building_annual == 3310
    decide.ret_total_annual == 4025
    decide.ret_due_now == 4025
}

# ── R11-INN-03: EXCISE PRODUCT CLASSIFIER ─────────────────────────────────────

test_inn03_gasoline_duty if {
    decide := jdg.r11_pcc_lokalne_akcyza_innovations.decide with input as {
        "jdg_entrepreneur": {"r11_pcc_local_excise_check": true},
        "excise_product": {"product_type": "GASOLINE", "quantity": 1000},
    }
    decide.rule_id == "jdg.r11_pcc_lokalne_akcyza_innovations.excise_product_classifier"
    decide.exc_rate == 1566
    decide.exc_duty_pln == 1566000
    decide.exc_needs_akcr == true
}

test_inn03_ethanol_needs_banderole if {
    decide := jdg.r11_pcc_lokalne_akcyza_innovations.decide with input as {
        "jdg_entrepreneur": {"r11_pcc_local_excise_check": true},
        "excise_product": {"product_type": "ETHANOL", "quantity": 1},
    }
    decide.exc_duty_pln == 6900
    decide.exc_needs_banderole == true
}

test_inn03_unknown_type_triage if {
    decide := jdg.r11_pcc_lokalne_akcyza_innovations.decide with input as {
        "jdg_entrepreneur": {"r11_pcc_local_excise_check": true},
        "excise_product": {"product_type": "UNKNOWN", "quantity": 10},
    }
    decide.exc_rate == 0
    decide._routing == "TRIAGE_QUEUE"
}

# ── R11-INN-04: TRANSPORT TAX DEADLINE MONITOR ────────────────────────────────

test_inn04_red_when_3_days_no_dn1 if {
    decide := jdg.r11_pcc_lokalne_akcyza_innovations.decide with input as {
        "jdg_entrepreneur": {"r11_pcc_local_excise_check": true},
        "transport_monitor": {
            "items": [
                {"label": "Ciężarówka >3,5t", "days_left": 3, "dn1_filed": false},
            ],
        },
    }
    decide.rule_id == "jdg.r11_pcc_lokalne_akcyza_innovations.transport_tax_deadline_monitor"
    decide.trt_red_count == 1
    decide._routing == "BLOCK_AND_ALERT"
}

# ── R11-INN-05: VAT VS PCC ARBITRATOR ─────────────────────────────────────────

test_inn05_vat_excludes_pcc if {
    decide := jdg.r11_pcc_lokalne_akcyza_innovations.decide with input as {
        "jdg_entrepreneur": {"r11_pcc_local_excise_check": true},
        "pcc_arbitration": {
            "transaction_type": "SALE",
            "value": 50000,
            "vat_applies": true,
            "family_loan": false,
        },
    }
    decide.rule_id == "jdg.r11_pcc_lokalne_akcyza_innovations.vat_vs_pcc_arbitrator"
    decide.arb_pcc_excluded == true
    decide.arb_pcc_due_pln == 0
    decide._routing == ""
}

test_inn05_pcc_due_when_no_vat if {
    decide := jdg.r11_pcc_lokalne_akcyza_innovations.decide with input as {
        "jdg_entrepreneur": {"r11_pcc_local_excise_check": true},
        "pcc_arbitration": {
            "transaction_type": "SALE",
            "value": 50000,
            "vat_applies": false,
            "family_loan": false,
        },
    }
    decide.arb_pcc_excluded == false
    decide.arb_pcc_due_pln == 1000
    decide._routing == "TRIAGE_QUEUE"
}

test_inn05_exempt_below_1000 if {
    decide := jdg.r11_pcc_lokalne_akcyza_innovations.decide with input as {
        "jdg_entrepreneur": {"r11_pcc_local_excise_check": true},
        "pcc_arbitration": {
            "transaction_type": "SALE",
            "value": 500,
            "vat_applies": false,
            "family_loan": false,
        },
    }
    decide.arb_pcc_due_pln == 0
}

test_inn05_no_input_no_match if {
    decide := jdg.r11_pcc_lokalne_akcyza_innovations.decide with input as {
        "jdg_entrepreneur": {"r11_pcc_local_excise_check": true},
    }
    decide.rule_id == "jdg.r11_pcc_lokalne_akcyza_innovations.no_match"
}
