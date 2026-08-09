# NexusAI JDG — Enterprise GAAR Shield Detector.
# Documentation is ordinary comments because the legacy metadata was not valid YAML.
# Package: jdg.gaar_shield
# Public rules: three-test analyzer and round-tripping detector.

package jdg.gaar_shield

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.gaar_shield.no_match",
    "package": "jdg.gaar_shield",
    "priority": 9999,
}

bool_text(value) := sprintf("%v", [value])
bool_not(value) := object.get({"true": false, "false": true}, bool_text(value), false)
bool_or(a, b) := object.get({
    "true|true": true,
    "true|false": true,
    "false|true": true,
    "false|false": false,
}, sprintf("%v|%v", [a, b]), false)
bool_and(a, b) := object.get({"true|true": true}, sprintf("%v|%v", [a, b]), false)

score_for(flag, points) := points if {
    flag
} else := 0 if {
    not flag
}

check_mark(value) := "✓" if {
    value
} else := "✗" if {
    not value
}

risk_for(all_tests, threshold_exceeded, score) := "LOW" if {
    not all_tests
} else := "MEDIUM" if {
    all_tests
    not threshold_exceeded
} else := "HIGH" if {
    all_tests
    threshold_exceeded
    score < 75
} else := "CRITICAL" if {
    all_tests
    threshold_exceeded
    score >= 75
}

routing_for(risk) := "BLOCK_AND_ALERT" if {
    risk in {"HIGH", "CRITICAL"}
} else := "TRIAGE_QUEUE" if {
    risk == "MEDIUM"
} else := ""

reason_for(all_tests, risk, benefit, score, t1, t2, t3) := sprintf("GAAR ALERT: ryzyko %s — 3 testy PASS, korzyść %.0f PLN, sztuczność %d/100", [risk, benefit, score]) if {
    all_tests
} else := sprintf("GAAR: test 1=%s, test 2=%s, test 3=%s (%d/100). Ryzyko: %s", [t1, t2, t3, score, risk]) if {
    not all_tests
}

build_gaar_warnings(t1, t2, t3, benefit, threshold, score, risk) := [
    "═══════════════════════════════════════════",
    sprintf("🛡️ GAAR SHIELD — TRÓJTEST ANALIZA (ryzyko: %s)", [risk]),
    sprintf("   Test 1 — Korzyść podatkowa: %s (%.0f PLN)", [check_mark(t1), benefit]),
    sprintf("   Test 2 — Sprzeczność z celem: %s", [check_mark(t2)]),
    sprintf("   Test 3 — Sztuczność: %s (%d/100)", [check_mark(t3), score]),
    sprintf("   Próg 100 000 PLN: %s", [object.get({"true": "PRZEKROCZONY ⚠️", "false": "nieprzekroczony"}, bool_text(threshold), "nieprzekroczony")]),
    "═══════════════════════════════════════════",
]

# GAA-3000: GAAR three-test analyzer.
decide := {
    "matched": true,
    "rule_id": "jdg.gaar_shield.three_test_analyzer",
    "package": "jdg.gaar_shield",
    "priority": 3000,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "gaar_test_1_tax_benefit": test1,
    "gaar_test_2_contrary_to_purpose": test2,
    "gaar_test_3_artificiality": test3,
    "gaar_benefit_amount_pln": benefit_amount,
    "gaar_threshold_100k_exceeded": threshold_exceeded,
    "gaar_artificiality_score": artificiality_score,
    "gaar_overall_risk": risk_level,
    "gaar_mdr_reportable": mdr_reportable,
    "_routing": gaar_routing,
    "_routing_reason": gaar_reason,
    "_legal_basis": "Art. 119a-119l OrdPU (GAAR); Art. 86a-86o OrdPU (MDR)",
    "_warnings": build_gaar_warnings(test1, test2, test3, benefit_amount, threshold_exceeded, artificiality_score, risk_level),
} if {
    input.gaar_shield_analyze == true
    benefit_amount := object.get(input, "gaar_estimated_tax_benefit_pln", 0)
    threshold_exceeded := benefit_amount > 100000
    test1 := benefit_amount > 0
    tax_purpose_override := object.get(input, "gaar_tax_purpose_override", false)
    regulatory_arbitrage := object.get(input, "gaar_regulatory_arbitrage", false)
    test2 := bool_or(tax_purpose_override, regulatory_arbitrage)
    business_rationale := object.get(input, "gaar_business_rationale_exists", false)
    substance_level := object.get(input, "gaar_substance_level", "NONE")
    related_parties := object.get(input, "gaar_related_parties", false)
    circular_structure := object.get(input, "gaar_circular_structure", false)
    offshore_elements := object.get(input, "gaar_offshore_elements", false)
    aggressive_timeline := object.get(input, "gaar_aggressive_timeline", false)
    raw_artificiality_score := score_for(bool_not(business_rationale), 30) + score_for(substance_level == "NONE", 25) + score_for(substance_level == "LOW", 15) + score_for(bool_and(related_parties, circular_structure), 15) + score_for(offshore_elements, 15) + score_for(aggressive_timeline, 10)
    artificiality_score := min([raw_artificiality_score, 100])
    test3 := artificiality_score >= 50
    all_tests_pass := bool_and(bool_and(test1, test2), test3)
    risk_level := risk_for(all_tests_pass, threshold_exceeded, artificiality_score)
    mdr_reportable := bool_and(all_tests_pass, threshold_exceeded)
    gaar_routing := routing_for(risk_level)
    gaar_reason := reason_for(all_tests_pass, risk_level, benefit_amount, artificiality_score, test1, test2, test3)
} else := {
    "matched": true,
    "rule_id": "jdg.gaar_shield.round_tripping_detector",
    "package": "jdg.gaar_shield",
    "priority": 3010,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "gaar_round_trip_detected": detected,
    "gaar_round_trip_cycle_parties": cycle_parties,
    "gaar_round_trip_net_effect": net_effect,
    "_routing": round_trip_routing,
    "_routing_reason": round_trip_reason,
    "_legal_basis": "Art. 119a § 1 OrdPU (sztuczność); Art. 119d OrdPU",
    "_warnings": [
        "🔴 GAAR ROUND-TRIPPING ALERT!",
        sprintf("   Łańcuch: %s", [cycle_parties]),
        sprintf("   Efekt netto: %s", [net_effect]),
        "⚠️ Transakcja okrężna BEZ substancji gospodarczej → GAAR HIGH RISK!",
        "📋 Uzyskaj opinię zabezpieczającą (Art. 119f OrdPU) przed realizacją transakcji.",
    ],
} if {
    input.gaar_round_trip_check == true
    chain := object.get(input, "gaar_transaction_chain", [])
    chain_count := count(chain)
    first_party := object.get(chain[0], "party_id", "")
    last_party := object.get(chain[chain_count - 1], "party_id", "")
    detected := bool_and(chain_count >= 3, first_party == last_party)
    cycle_parties := concat(" → ", [object.get(p, "party_id", "?") | p := chain[_]])
    net_effect := sprintf("Środki wracają do %s po %.0f dniach bez zmiany ekonomicznej", [first_party, object.get(input, "gaar_cycle_days", 0)])
    round_trip_routing := object.get({"true": "BLOCK_AND_ALERT", "false": ""}, bool_text(detected), "")
    round_trip_reason := object.get({"true": sprintf("ROUND-TRIPPING WYKRYTE: %s — transakcja okrężna bez substancji gospodarczej!", [net_effect]), "false": "Brak wykrytego round-trippingu."}, bool_text(detected), "Brak wykrytego round-trippingu.")
}
