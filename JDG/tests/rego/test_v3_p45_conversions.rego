# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY V3-P45 KONWERSJE (negative-first, P39-I04; I03/I04/I12)
# Każda konwersja: test pozytywny (przesłanki → MANUAL_REVIEW), test negatywny
# (brak przesłanki → NEEDS_ADVICE — DOWÓD, ŻE REGUŁA NIE JEST STUBEM),
# test fail-closed (brak progów → BLOCK).
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.v3_p45_conversions_test

import future.keywords.in
import future.keywords.every

import data.jdg.v3_p45_conversions

# ── Helper ─────────────────────────────────────────────────────────────────────
conv_input(ctx) = {"jdg_entrepreneur": {"v3_p45_check": true}, "v3_p45_conversions": ctx}

# ═══════════════════════════════════════════════════════════════════════════════
# Fail-closed i no_match (determinizm)
# ═══════════════════════════════════════════════════════════════════════════════
test_p45conv_thresholds_missing_fail_closed {
    r := v3_p45_conversions.decide with input as conv_input({"prior_year_revenue_eur": 3000000})
        with data.jdg.thresholds.v3_p45_conversions as {}
    r.rule_id == "jdg.v3_p45_conversions.thresholds_missing"
    r.decision_mode == "BLOCK"
}

test_p45conv_no_activation_no_match {
    # Moduł uśpiony (brak flagi) → no_match (determinizm łańcucha, konwencja P44)
    r := v3_p45_conversions.decide with input as {"v3_p45_conversions": {"analysis": "uor_a2", "prior_year_revenue_eur": 3000000}}
    r.rule_id == "jdg.v3_p45_conversions.no_match"
    r.matched == false
}

test_p45conv_unknown_selector_needs_advice {
    # Aktywowany + nieznany selektor → NEEDS_ADVICE (V1 zasada 6: wątpliwość
    # nigdy nie jest cicha — FAIL-CLOSED, silniejszy niż no_match)
    r := v3_p45_conversions.decide with input as conv_input({"analysis": "nieznana"})
    r.rule_id == "jdg.v3_p45_conversions.needs_advice"
    r.decision_mode == "NEEDS_ADVICE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# K1: uor_a2_threshold — próg UoR 2M EUR
# ═══════════════════════════════════════════════════════════════════════════════
test_p45conv_uor_a2_above_threshold {
    r := v3_p45_conversions.uor_a2_threshold with input as conv_input({"analysis": "uor_a2", "prior_year_revenue_eur": 2500000})
    r.decision_mode == "MANUAL_REVIEW"
    r._routing == "TRIAGE_QUEUE"
    r.revenue_eur == 2500000
}

test_p45conv_uor_a2_below_threshold {
    r := v3_p45_conversions.uor_a2_threshold with input as conv_input({"analysis": "uor_a2", "prior_year_revenue_eur": 1500000})
    r.decision_mode == "MANUAL_REVIEW"
    r._routing == "AUTO_FILE"
    r.threshold_eur == 2000000
}

test_p45conv_uor_a2_at_exact_threshold {
    r := v3_p45_conversions.uor_a2_threshold with input as conv_input({"analysis": "uor_a2", "prior_year_revenue_eur": 2000000})
    r._routing == "TRIAGE_QUEUE"   # granica: >= progu → obowiązek
}

# NEGATYWNA (I04): brak przesłanki (danych) → NEEDS_ADVICE, nigdy cicha decyzja
test_p45conv_neg_uor_a2_below_threshold {
    r := v3_p45_conversions.uor_a2_threshold with input as conv_input({"analysis": "uor_a2", "prior_year_revenue_eur": 1000})
    r.decision_mode != "AUTO_POST"
}

test_p45conv_neg_uor_a2_missing_data {
    r := v3_p45_conversions.uor_a2_threshold with input as conv_input({"analysis": "uor_a2"})
    r.decision_mode == "NEEDS_ADVICE"
    r._routing == "TRIAGE_QUEUE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# K2: uor_a3_conditions — wyłączenia art. 3 UoR
# ═══════════════════════════════════════════════════════════════════════════════
test_p45conv_uor_a3_exempt_person {
    r := v3_p45_conversions.uor_a3_conditions with input as conv_input({
        "analysis": "uor_a3",
        "tax_form": "JDG_osoba_fizyczna",
        "keeps_revenue_cost_ledger": true,
    })
    r.decision_mode == "MANUAL_REVIEW"
    r._routing == "AUTO_FILE"
}

# NEGATYWNA (I04): brak ewidencji → NEEDS_ADVICE (nie AUTO_POST)
test_p45conv_neg_uor_a3_missing_data {
    r := v3_p45_conversions.uor_a3_conditions with input as conv_input({
        "analysis": "uor_a3",
        "tax_form": "JDG_osoba_fizyczna",
        "keeps_revenue_cost_ledger": false,
    })
    r.decision_mode == "NEEDS_ADVICE"
}

test_p45conv_neg_uor_a3_wrong_form {
    r := v3_p45_conversions.uor_a3_conditions with input as conv_input({
        "analysis": "uor_a3",
        "tax_form": "spolka_zoo",
        "keeps_revenue_cost_ledger": true,
    })
    r.decision_mode == "NEEDS_ADVICE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# K3: mdr_hallmark_a — znacznik ogólny MDR
# ═══════════════════════════════════════════════════════════════════════════════
test_p45conv_mdr_hallmark_triggered {
    r := v3_p45_conversions.mdr_hallmark_a with input as conv_input({
        "analysis": "mdr_hallmark",
        "cross_border_arrangement": true,
        "main_benefit_test_positive": true,
        "arrangement_value_pln": 3000000,
    })
    r.decision_mode == "MANUAL_REVIEW"
    r.value_pln == 3000000
}

# NEGATYWNA (I04): brak testu głównej korzyści → NEEDS_ADVICE
test_p45conv_neg_mdr_hallmark_missing_benefit {
    r := v3_p45_conversions.mdr_hallmark_a with input as conv_input({
        "analysis": "mdr_hallmark",
        "cross_border_arrangement": true,
        "main_benefit_test_positive": false,
        "arrangement_value_pln": 3000000,
    })
    r.decision_mode == "NEEDS_ADVICE"
}

test_p45conv_mdr_below_value_threshold {
    r := v3_p45_conversions.mdr_hallmark_a with input as conv_input({
        "analysis": "mdr_hallmark",
        "cross_border_arrangement": true,
        "main_benefit_test_positive": true,
        "arrangement_value_pln": 1000000,
    })
    r.decision_mode == "NEEDS_ADVICE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# K4: pcc_a1_condition — podmiotowość PCC
# ═══════════════════════════════════════════════════════════════════════════════
test_p45conv_pcc_subject_to_tax {
    r := v3_p45_conversions.pcc_a1_condition with input as conv_input({
        "analysis": "pcc_a1",
        "agreement_type": "sprzedaz",
        "made_in_poland": true,
        "not_vat_taxed": true,
        "agreement_value_pln": 50000,
    })
    r.decision_mode == "MANUAL_REVIEW"
}

# NEGATYWNA (I04): umowa opodatkowana VAT → nie PCC → NEEDS_ADVICE
test_p45conv_neg_pcc_not_subject {
    r := v3_p45_conversions.pcc_a1_condition with input as conv_input({
        "analysis": "pcc_a1",
        "agreement_type": "sprzedaz",
        "made_in_poland": true,
        "not_vat_taxed": false,
        "agreement_value_pln": 50000,
    })
    r.decision_mode == "NEEDS_ADVICE"
}

test_p45conv_pcc_below_min {
    r := v3_p45_conversions.pcc_a1_condition with input as conv_input({
        "analysis": "pcc_a1",
        "agreement_type": "sprzedaz",
        "made_in_poland": true,
        "not_vat_taxed": true,
        "agreement_value_pln": 500,
    })
    r.decision_mode == "NEEDS_ADVICE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# K5: wht_foreign_service — WHT 20%
# ═══════════════════════════════════════════════════════════════════════════════
test_p45conv_wht_triggered {
    r := v3_p45_conversions.wht_foreign_service with input as conv_input({
        "analysis": "wht_foreign",
        "service_rendered_in_poland": true,
        "buyer_no_pl_residency": true,
    })
    r.decision_mode == "MANUAL_REVIEW"
    r.rate_pct == 20
}

# NEGATYWNA (I04): brak danych nabywcy → NEEDS_ADVICE
test_p45conv_neg_wht_missing_recipient {
    r := v3_p45_conversions.wht_foreign_service with input as conv_input({
        "analysis": "wht_foreign",
        "service_rendered_in_poland": true,
        "buyer_no_pl_residency": false,
    })
    r.decision_mode == "NEEDS_ADVICE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Routing/fallback determinizm
# ═══════════════════════════════════════════════════════════════════════════════
test_p45conv_needs_advice_fallback {
    r := v3_p45_conversions.decide with input as conv_input({"analysis": "uor_a2_bez_danych", "unknown": true})
    r.rule_id == "jdg.v3_p45_conversions.needs_advice"
    r.decision_mode == "NEEDS_ADVICE"
    r._routing == "TRIAGE_QUEUE"
}

test_p45conv_decide_routes_conversion_1 {
    r := v3_p45_conversions.decide with input as conv_input({"analysis": "uor_a2", "prior_year_revenue_eur": 2500000})
    r.rule_id == "jdg.v3_p45_conversions.uor_a2_threshold"
}

test_p45conv_never_silent_auto_post {
    # Symetria dowodu: żaden wynik decide nigdy nie jest AUTO_POST
    outputs := [r |
        some ctx in [
            {"analysis": "uor_a2", "prior_year_revenue_eur": 3000000},
            {"analysis": "uor_a2", "prior_year_revenue_eur": 100},
            {"analysis": "uor_a2"},
            {"analysis": "pcc_a1", "agreement_type": "sprzedaz", "made_in_poland": true,
             "not_vat_taxed": true, "agreement_value_pln": 90000},
            {"analysis": "wht_foreign", "service_rendered_in_poland": true, "buyer_no_pl_residency": true},
        ]
        r := v3_p45_conversions.decide with input as object.union(
            {"jdg_entrepreneur": {"v3_p45_check": true}}, {"v3_p45_conversions": ctx})
    ]
    every r in outputs {
        r.decision_mode != "AUTO_POST"
    }
}
