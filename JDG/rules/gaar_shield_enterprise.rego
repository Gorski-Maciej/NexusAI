# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE GAAR SHIELD DETECTOR (Innovation 9.2 / BP-2, P19 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise GAAR Shield Detector — Pre-Transaction GAAR Risk Analysis
# description: |
#   ENTERPRISE v7.0 — Detektor ryzyka GAAR (Art. 119a-119l OrdPU) przed
#   dokonaniem transakcji. Wypełnia lukę M1 z raportu P19.
#
#   KLUCZOWE FUNKCJE:
#   - Trójtest GAAR: korzyść podatkowa, sprzeczność z celem, sztuczność
#   - Próg 100 000 PLN (Art. 119b) — automatyczne sprawdzenie
#   - Scoring sztuczności (0-100): uzasadnienie gospodarcze, substancja
#   - Detekcja round-tripping (transakcje okrężne)
#   - Integracja z MDR (raportowanie schematów podatkowych)
#   - Integracja z cenami transferowymi (TP) dla podmiotów powiązanych
#
# architecture: Enterprise v7.0 First-Match-Wins
# legal_basis: Art. 119a-119l OrdPU; Art. 86a-86o OrdPU (MDR)
# package: jdg.gaar_shield
# deprecated: false
# priority_range: 3000-3029
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.gaar_shield

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.gaar_shield.no_match",
    "package": "jdg.gaar_shield", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# GAA-3000: GAAR THREE-TEST ANALYZER — Trójtest GAAR dla transakcji
# ═══════════════════════════════════════════════════════════════════════════════

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
    "_warnings": build_gaar_warnings(test1, test2, test3, benefit_amount, threshold_exceeded, artificiality_score, risk_level)
} {
    input.gaar_shield_analyze == true

    # Test 1: Korzyść podatkowa
    benefit_amount := object.get(input, "gaar_estimated_tax_benefit_pln", 0)
    gaar_threshold := 100000  # Art. 119b § 1 pkt 1
    threshold_exceeded := benefit_amount > gaar_threshold
    test1 := benefit_amount > 0

    # Test 2: Sprzeczność z przedmiotem/celem przepisu
    tax_purpose_override := object.get(input, "gaar_tax_purpose_override", false)
    regulatory_arbitrage := object.get(input, "gaar_regulatory_arbitrage", false)
    test2 := tax_purpose_override or regulatory_arbitrage

    # Test 3: Sztuczność (scoring 0-100)
    business_rationale := object.get(input, "gaar_business_rationale_exists", false)
    substance_level := object.get(input, "gaar_substance_level", "NONE")
    related_parties := object.get(input, "gaar_related_parties", false)
    circular_structure := object.get(input, "gaar_circular_structure", false)
    offshore_elements := object.get(input, "gaar_offshore_elements", false)
    aggressive_timeline := object.get(input, "gaar_aggressive_timeline", false)

    artificiality_score := 0
    a1 := 30 { not business_rationale }
    a2 := 25 { substance_level == "NONE" }
    a3 := 0 { substance_level != "NONE" }
    a4 := 15 { substance_level == "LOW" }
    a5 := 15 { related_parties; circular_structure }
    a6 := 15 { offshore_elements }
    a7 := 10 { aggressive_timeline }
    a1 := 0 { business_rationale }
    a4 := 0 { substance_level != "LOW" }
    a5 := 0 { not related_parties or not circular_structure }
    a6 := 0 { not offshore_elements }
    a7 := 0 { not aggressive_timeline }
    artificiality_score := a1 + a2 + a3 + a4 + a5 + a6 + a7
    test3 := artificiality_score >= 50

    # Overall risk
    all_tests_pass := test1 and test2 and test3
    risk_level := "LOW" { not all_tests_pass }
    risk_level := "MEDIUM" { all_tests_pass; not threshold_exceeded }
    risk_level := "HIGH" { all_tests_pass; threshold_exceeded; artificiality_score < 75 }
    risk_level := "CRITICAL" { all_tests_pass; threshold_exceeded; artificiality_score >= 75 }

    mdr_reportable := all_tests_pass and threshold_exceeded

    gaar_routing := "BLOCK_AND_ALERT" { risk_level in {"HIGH", "CRITICAL"} }
    gaar_routing := "TRIAGE_QUEUE" { risk_level == "MEDIUM" }
    gaar_routing := "" { true }
    gaar_reason := sprintf("GAAR ALERT: ryzyko %s — 3 testy PASS, korzyść %.0f PLN, sztuczność %d/100", [risk_level, benefit_amount, artificiality_score]) { all_tests_pass }
    gaar_reason := sprintf("GAAR: test 1=%s, test 2=%s, test 3=%s (%d/100). Ryzyko: %s", [test1, test2, test3, artificiality_score, risk_level]) { not all_tests_pass }
}

build_gaar_warnings(t1, t2, t3, benefit, threshold, score, risk) = warnings {
    check1 := "✓" { t1 }
    check1 := "✗" { not t1 }
    check2 := "✓" { t2 }
    check2 := "✗" { not t2 }
    check3 := "✓" { t3 }
    check3 := "✗" { not t3 }
    warnings := [
        "═══════════════════════════════════════════",
        sprintf("🛡️ GAAR SHIELD — TRÓJTEST ANALIZA (ryzyko: %s)", [risk]),
        sprintf("   Test 1 — Korzyść podatkowa: %s (%.0f PLN)", [check1, benefit]),
        sprintf("   Test 2 — Sprzeczność z celem: %s", [check2]),
        sprintf("   Test 3 — Sztuczność: %s (%d/100)", [check3, score]),
        sprintf("   Próg 100 000 PLN: %s", ["PRZEKROCZONY ⚠️" { threshold } else "nieprzekroczony"]),
        "═══════════════════════════════════════════",
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# GAA-3010: ROUND-TRIPPING DETECTOR — Detekcja transakcji okrężnych
# ═══════════════════════════════════════════════════════════════════════════════

else := {
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
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("ROUND-TRIPPING WYKRYTE: %s — transakcja okrężna bez substancji gospodarczej!", [net_effect]),
    "_legal_basis": "Art. 119a § 1 OrdPU (sztuczność); Art. 119d OrdPU",
    "_warnings": [
        sprintf("🔴 GAAR ROUND-TRIPPING ALERT!", []),
        sprintf("   Łańcuch: %s", [cycle_parties]),
        sprintf("   Efekt netto: %s", [net_effect]),
        "⚠️ Transakcja okrężna BEZ substancji gospodarczej → GAAR HIGH RISK!",
        "📋 Uzyskaj opinię zabezpieczającą (Art. 119f OrdPU) przed realizacją transakcji.",
    ]
} {
    input.gaar_round_trip_check == true
    chain := object.get(input, "gaar_transaction_chain", [])
    detected := count(chain) >= 3
    first_party := object.get(chain[0], "party_id", "") { count(chain) > 0 }
    last_party := object.get(chain[count(chain)-1], "party_id", "") { count(chain) > 0 }
    detected := detected and (first_party == last_party)
    cycle_parties := concat(" → ", [object.get(p, "party_id", "?") | p := chain[_]])
    net_effect := sprintf("Środki wracają do %s po %.0f dniach bez zmiany ekonomicznej", [first_party, object.get(input, "gaar_cycle_days", 0)])
    detected
}
