# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: mdr_dac6_enterprise (P27 CFC_EXIT_MDG)
# Behavioral tests: MDR-100 hallmarks / MDR-200 threshold / MDR-300 timeline
# Contract: decide = 1 obiekt; kolejność MDR-100 → MDR-200 → MDR-300 → no_match
# ═══════════════════════════════════════════════════════════════════════════════

package test_jdg_mdr_dac6

import data.jdg.mdr_dac6

# ── no_match (fail-safe default) ──────────────────────────────────────────────

test_no_match_on_empty_input {
    result := data.jdg.mdr_dac6.decide with input as {}
    result.matched == false
    result.rule_id == "jdg.mdr_dac6.no_match"
}

test_mdr100_beats_no_match {
    result := data.jdg.mdr_dac6.decide with input as {"mdr_dac6_check": true}
    result.rule_id != "jdg.mdr_dac6.no_match"
}

# ── MDR-100: hallmark detection (Art. 86a-86o OrdPU) ──────────────────────────

test_mdr100_single_hallmark_triage {
    result := data.jdg.mdr_dac6.decide with input as {
        "mdr_dac6_check": true,
        "mdr_involves_countries": ["PL", "DE"],
        "mdr_confidentiality_clause": true,
        "mdr_tax_advantage_pln": 60000,
    }
    result.matched == true
    result.rule_id == "jdg.mdr_dac6.hallmark_detection"
    object.get(result, "mdr_reportable", false) == true
    object.get(result, "mdr_hallmarks_detected", []) == ["A1"]
    object.get(result, "mdr_hallmark_category", "-") == "A"
    object.get(result, "mdr_main_benefit_test", false) == true
    # 1 hallmark + korzyść > 50k → 14 dni → TRIAGE_QUEUE
    object.get(result, "mdr_deadline_days", 0) == 14
    object.get(result, "_routing", "") == "TRIAGE_QUEUE"
}

test_mdr100_three_hallmarks_block {
    result := data.jdg.mdr_dac6.decide with input as {
        "mdr_dac6_check": true,
        "mdr_involves_countries": ["PL", "DE", "FR"],
        "mdr_confidentiality_clause": true,
        "mdr_standardized_docs": true,
        "mdr_circular_cash_flow": true,
        "mdr_tax_advantage_pln": 1000,
    }
    object.get(result, "mdr_hallmarks_detected", []) == ["A1", "A2", "B3"]
    # ≥3 hallmarks → 7 dni → BLOCK_AND_ALERT (najsurowszy termin wygrywa)
    object.get(result, "mdr_deadline_days", 0) == 7
    object.get(result, "_routing", "") == "BLOCK_AND_ALERT"
}

test_mdr100_category_e_ip_transfer_10m {
    result := data.jdg.mdr_dac6.decide with input as {
        "mdr_dac6_check": true,
        "mdr_involves_countries": ["PL"],
        "mdr_ip_transfer": true,
        "mdr_tax_advantage_pln": 11000000,
    }
    object.get(result, "mdr_hallmarks_detected", []) == ["E1"]
    object.get(result, "mdr_hallmark_category", "-") == "E"
    # korzyść > 10M → 7 dni
    object.get(result, "mdr_deadline_days", 0) == 7
}

test_mdr100_no_countries_not_reportable {
    result := data.jdg.mdr_dac6.decide with input as {
        "mdr_dac6_check": true,
        "mdr_involves_countries": [],
        "mdr_confidentiality_clause": true,
    }
    object.get(result, "mdr_hallmarks_detected", []) == ["A1"]
    # hallmark bez elementu transgranicznego → brak obowiązku (schemat krajowy)
    object.get(result, "mdr_reportable", false) == false
    object.get(result, "_routing", "") == ""
}

# ── MDR-200: próg korzyści podatkowej (50k / 10M) ─────────────────────────────

test_mdr200_threshold_exceeded {
    result := data.jdg.mdr_dac6.decide with input as {
        "mdr_dac6_threshold_check": true,
        "mdr_tax_advantage_pln": 120000,
        "jdg_entrepreneur": {"business_type": "JDG"},
    }
    result.matched == true
    result.rule_id == "jdg.mdr_dac6.tax_advantage_analyzer"
    object.get(result, "mdr_tax_advantage_exceeds_threshold", false) == true
    object.get(result, "mdr_jdg_exemption_possible", false) == false
    object.get(result, "_routing", "") == "TRIAGE_QUEUE"
}

test_mdr200_jdg_small_benefit_exempt {
    result := data.jdg.mdr_dac6.decide with input as {
        "mdr_dac6_threshold_check": true,
        "mdr_tax_advantage_pln": 20000,
        "jdg_entrepreneur": {"business_type": "JDG"},
    }
    object.get(result, "mdr_tax_advantage_exceeds_threshold", false) == false
    object.get(result, "mdr_jdg_exemption_possible", false) == true
    object.get(result, "_routing", "") == ""
}

# ── MDR-300: kalendarz raportowania ───────────────────────────────────────────

test_mdr300_promoter_form {
    result := data.jdg.mdr_dac6.decide with input as {
        "mdr_dac6_timeline": true,
        "mdr_is_promoter": true,
    }
    result.matched == true
    result.rule_id == "jdg.mdr_dac6.timeline_calculator"
    object.get(result, "mdr_reporter_type", "") == "PROMOTOR/DORADCA — MDR-1 w 30 dni"
    object.get(result, "mdr_form_to_file", "") == "MDR-1 + MDR-3 (kwartalny)"
    object.get(result, "mdr_deadline_calendar_days", 0) == 30
    object.get(result, "mdr_annual_report_required", false) == true
    object.get(result, "_routing", "") == "TRIAGE_QUEUE"
}

test_mdr300_user_form {
    result := data.jdg.mdr_dac6.decide with input as {
        "mdr_dac6_timeline": true,
        "mdr_is_user": true,
    }
    object.get(result, "mdr_reporter_type", "") == "KORZYSTAJACY — MDR-1 w 30 dni od gotowosci do wdrozenia"
    object.get(result, "mdr_form_to_file", "") == "MDR-1"
    object.get(result, "mdr_annual_report_required", false) == false
}

test_mdr300_neither_role_undefined {
    result := data.jdg.mdr_dac6.decide with input as {
        "mdr_dac6_timeline": true,
    }
    object.get(result, "mdr_reporter_type", "") == "NIEOKRESLONY"
    object.get(result, "_routing", "") == ""
}
