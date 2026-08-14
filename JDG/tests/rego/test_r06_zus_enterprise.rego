# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for R06 GLM52 ZUS/SUS
# Package: jdg.r06_zus_innovations
# Source: 06_ZUS_SUS_składki_ulgi.txt (prompty_glm52)
# Generated: 2026-08-14
# ═══════════════════════════════════════════════════════════════════════════════

package test_r06_zus

import future.keywords.in

# ═══ DEFAULT: bez flagi r06_zus_check → no_match ═══

test_default_no_match {
    result := data.jdg.r06_zus_innovations.decide with input as {
        "jdg_entrepreneur": {"r06_zus_check": false}
    }
    result.matched == false
    result.rule_id == "jdg.r06_zus_innovations.no_match"
}

# ═══ R06-INN-01: HEALTH WHAT-IF 4-FORM ═══

test_health_whatif_scale_low_income {
    wi := data.jdg.r06_zus_innovations.health_whatif_4form with input as {
        "jdg_entrepreneur": {"r06_health_whatif_check": true},
        "health_whatif": {"annual_income": 50000, "annual_revenue": 50000},
    }
    wi.whatif.scale_annual == 4500
    wi.whatif.linear_annual == 2450
    wi.whatif.lump_base_multiplier == 0.6
    wi.whatif.card_annual == 5039.28
    wi.whatif.best_form == "LINEAR"
}

test_health_whatif_lump_low_revenue {
    wi := data.jdg.r06_zus_innovations.health_whatif_4form with input as {
        "jdg_entrepreneur": {"r06_health_whatif_check": true},
        "health_whatif": {"annual_income": 100000, "annual_revenue": 50000},
    }
    wi.whatif.lump_base_multiplier == 0.6
    wi.whatif.best_form == "LUMP_SUM"
}

test_health_whatif_lump_high_revenue_180 {
    wi := data.jdg.r06_zus_innovations.health_whatif_4form with input as {
        "jdg_entrepreneur": {"r06_health_whatif_check": true},
        "health_whatif": {"annual_income": 200000, "annual_revenue": 400000},
    }
    wi.whatif.lump_base_multiplier == 1.8
    wi.whatif.best_form == "LINEAR"
}

test_health_whatif_lump_mid_revenue_100 {
    wi := data.jdg.r06_zus_innovations.health_whatif_4form with input as {
        "jdg_entrepreneur": {"r06_health_whatif_check": true},
        "health_whatif": {"annual_income": 80000, "annual_revenue": 100000},
    }
    wi.whatif.lump_base_multiplier == 1.0
    wi.whatif.best_form == "LUMP_SUM"
}

# ═══ R06-INN-02: ZUS RELIEF TRACKER ═══

test_relief_tracker_start_active {
    tr := data.jdg.r06_zus_innovations.zus_relief_tracker with input as {
        "jdg_entrepreneur": {"r06_relief_tracker_check": true},
        "zus_relief_tracker": {"months_since_start": 2, "relief_type": "ULGA_START"},
    }
    tr.tracker.max_months == 6
    tr.tracker.remaining_months == 4
    tr.tracker.status == "ACTIVE"
    count(tr.tracker.alarms) == 0
}

test_relief_tracker_preferential_expiring {
    tr := data.jdg.r06_zus_innovations.zus_relief_tracker with input as {
        "jdg_entrepreneur": {"r06_relief_tracker_check": true},
        "zus_relief_tracker": {"months_since_start": 22, "relief_type": "PREFERENCYJNY"},
    }
    tr.tracker.max_months == 24
    tr.tracker.remaining_months == 2
    tr.tracker.status == "EXPIRING"
    count(tr.tracker.alarms) == 1
}

test_relief_tracker_maly_zus_expired {
    tr := data.jdg.r06_zus_innovations.zus_relief_tracker with input as {
        "jdg_entrepreneur": {"r06_relief_tracker_check": true},
        "zus_relief_tracker": {"months_since_start": 36, "relief_type": "MALY_ZUS_PLUS"},
    }
    tr.tracker.max_months == 36
    tr.tracker.remaining_months == 0
    tr.tracker.status == "EXPIRED"
    count(tr.tracker.alarms) == 1
}

# ═══ R06-INN-03: SUS A6A (domknięcie pustyni) ═══

test_a6a_eligible {
    a6a := data.jdg.r06_zus_innovations.sus_a6a with input as {
        "jdg_entrepreneur": {"r06_sus_a6a_check": true},
        "sus_a6a": {"personal_child_care": true, "other_parent_insured": false},
    }
    a6a.a6a.eligible == true
}

test_a6a_not_eligible_other_parent_insured {
    a6a := data.jdg.r06_zus_innovations.sus_a6a with input as {
        "jdg_entrepreneur": {"r06_sus_a6a_check": true},
        "sus_a6a": {"personal_child_care": true, "other_parent_insured": true},
    }
    a6a.a6a.eligible == false
}

test_a6a_not_eligible_no_care {
    a6a := data.jdg.r06_zus_innovations.sus_a6a with input as {
        "jdg_entrepreneur": {"r06_sus_a6a_check": true},
        "sus_a6a": {"personal_child_care": false, "other_parent_insured": false},
    }
    a6a.a6a.eligible == false
}

# ═══ RAPORT ZUS: aktywna flaga ═══

test_zus_report {
    result := data.jdg.r06_zus_innovations.decide with input as {
        "jdg_entrepreneur": {"r06_zus_check": true},
        "health_whatif": {"annual_income": 50000, "annual_revenue": 50000},
        "zus_relief_tracker": {"months_since_start": 2, "relief_type": "ULGA_START"},
        "sus_a6a": {"personal_child_care": true, "other_parent_insured": false},
    }
    result.matched == true
    result.rule_id == "jdg.r06_zus_innovations.zus_report"
    result._routing == "REPORT"
    result.zus.health_whatif.best_form == "LINEAR"
    result.zus.relief_tracker.status == "ACTIVE"
    result.zus.sus_a6a.eligible == true
}
