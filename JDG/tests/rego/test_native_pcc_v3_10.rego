# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE REGO TESTS: jdg.local_taxes.v3_10 (Kampania V3, część 10)
# Uruchamiane przez `opa test JDG/rules JDG/tests/rego` (bramka CI).
# Konwencja: `v := ...decide with input as {...}` — modyfikator `with` dotyczy
# dokładnie jednego wyrażenia, dlatego każdy test wiąże wynik do zmiennej `v`.
# ═══════════════════════════════════════════════════════════════════════════════
package tests.test_native_pcc_v3_10

import future.keywords.in

# T01: fail-closed — brak snapshotu pcc_local_excise blokuje domenę
test_v3_10_fail_closed_without_thresholds {
    v := data.jdg.local_taxes.v3_10.decide with input as {"invoice": {}, "jdg_entrepreneur": {}}
         with data.jdg.thresholds as {}
    startswith(v.rule_id, "jdg.local_taxes.v3_10.thresholds_missing")
    v._routing == "BLOCK_AND_ALERT"
}

# T02: PCC sprzedaż 2% — 100k PLN → podatek 2000 PLN, TRIAGE
test_v3_10_pcc_sale_rate {
    v := data.jdg.local_taxes.v3_10.decide with input as {
        "invoice": {"pcc_contract_type": "sale", "pcc_market_value_pln": 100000},
        "vendor": {},
        "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.local_taxes.v3_10.pcc_rate_engine"
    v.pcc_rate == 0.02
    v.pcc_tax_due_pln == 2000
    v._routing == "TRIAGE_QUEUE"
}

# T03: PCC zwolnienie ≤1000 zł — umowa 800 PLN bez podatku
test_v3_10_pcc_small_exemption {
    v := data.jdg.local_taxes.v3_10.decide with input as {
        "invoice": {"pcc_contract_type": "sale", "pcc_market_value_pln": 800},
        "vendor": {},
        "jdg_entrepreneur": {},
    }
    v.pcc_small_exemption_applied == true
    v.pcc_tax_due_pln == 0
    v._routing == ""
}

# T04: PCC pożyczka rodzinna ≤36120 zł — zwolnienie art. 9 pkt 9
test_v3_10_pcc_family_loan_exemption {
    v := data.jdg.local_taxes.v3_10.decide with input as {
        "invoice": {"pcc_contract_type": "LOAN", "pcc_market_value_pln": 30000},
        "vendor": {"is_close_family": true},
        "jdg_entrepreneur": {},
    }
    v.pcc_family_loan_exemption_applied == true
    v.pcc_tax_due_pln == 0
}

# T05: PCC-3 w terminie (5 dni z 14) → TRIAGE przypomnienie
test_v3_10_pcc3_in_time {
    v := data.jdg.local_taxes.v3_10.decide with input as {
        "invoice": {"pcc_filing_required": true},
        "jdg_entrepreneur": {"days_since_pcc_event": 5, "pcc3_filed": false, "uses_notary": false},
    }
    v.rule_id == "jdg.local_taxes.v3_10.pcc3_deadline_guard"
    v.pcc3_deadline_days == 14
    v.pcc3_overdue == false
}

# T06: PCC-3 po terminie (20 dni, niezłożony) → BLOCK_AND_ALERT
test_v3_10_pcc3_overdue {
    v := data.jdg.local_taxes.v3_10.decide with input as {
        "invoice": {"pcc_filing_required": true},
        "jdg_entrepreneur": {"days_since_pcc_event": 20, "pcc3_filed": false, "uses_notary": false},
    }
    v.pcc3_overdue == true
    v._routing == "BLOCK_AND_ALERT"
}

# T07: nieruchomości — stawki gminy w granicach maksimów
test_v3_10_real_estate_within_max {
    v := data.jdg.local_taxes.v3_10.decide with input as {
        "jdg_entrepreneur": {
            "owns_business_real_estate": true,
            "gmina_land_rate_pln_m2": 1.40,
            "gmina_building_rate_pln_m2": 32.00,
            "gmina_resolution_evidence": true,
        },
    }
    v.rule_id == "jdg.local_taxes.v3_10.real_estate_max_rate_validator"
    v.re_land_over_max == false
    v.re_building_over_max == false
    v.manual_review_required == false
}

# T08: nieruchomości — stawka gminy przekracza maksimum → BLOCK_AND_ALERT
test_v3_10_real_estate_over_max {
    v := data.jdg.local_taxes.v3_10.decide with input as {
        "jdg_entrepreneur": {
            "owns_business_real_estate": true,
            "gmina_land_rate_pln_m2": 1.60,
            "gmina_building_rate_pln_m2": 33.00,
            "gmina_resolution_evidence": true,
        },
    }
    v.re_land_over_max == true
    v._routing == "BLOCK_AND_ALERT"
}

# T09: DN-1 po terminie rejestracji pojazdu → BLOCK_AND_ALERT
test_v3_10_dn1_overdue {
    v := data.jdg.local_taxes.v3_10.decide with input as {
        "jdg_entrepreneur": {
            "vehicle_registered_for_business": true,
            "dn1_filed": false,
            "days_since_vehicle_registration": 30,
        },
    }
    v.rule_id == "jdg.local_taxes.v3_10.dn1_deadline_guard"
    v.dn1_deadline_days == 14
    v.dn1_overdue == true
    v._routing == "BLOCK_AND_ALERT"
}

# T10: akcyza benzyna — stawka jednostkowa z thresholds (1566 zł/1000 l)
test_v3_10_excise_gasoline {
    v := data.jdg.local_taxes.v3_10.decide with input as {
        "invoice": {"excise_product_key": "gasoline", "excise_quantity": 1000},
        "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.local_taxes.v3_10.excise_rate_check"
    v.excise_unit_rate == 1566
    v.excise_estimated_pln == 1566000
}

# T11: krotka akcyza↔VAT — skład celny (CUSTOMS_WAREHOUSE)
test_v3_10_excise_vat_shortcut {
    v := data.jdg.local_taxes.v3_10.decide with input as {
        "invoice": {"procedure": "CUSTOMS_WAREHOUSE"},
        "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.local_taxes.v3_10.excise_vat_shortcut"
    v.shortcut_applicable == true
}

# T12: certyfikat zbiorczy domeny (catch-all, ≥10 pakietów)
test_v3_10_certificate_catch_all {
    v := data.jdg.local_taxes.v3_10.decide with input as {
        "invoice": {},
        "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.local_taxes.v3_10.local_taxes_certificate"
    count(v.lt_domain_packages_wired) >= 10
}
