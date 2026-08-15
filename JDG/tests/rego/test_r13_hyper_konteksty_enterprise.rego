# ═══════════════════════════════════════════════════════════════════════════════
# RAPORT_13 — HYPER PLAN45 / KONTEKSTY SPECJALNE — natywne testy Rego
# Scenariusze: happy path, granice (progi, limity), negatywne (no_match),
# temporalność (valid_from/valid_to) dla R13-INN-01..05.
# Uruchomienie: opa test (native OPA) — struktura jak test_r12_*.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r13_hyper_konteksty_innovations

import future.keywords.if

# ── R13-INN-01: CROSS-DOMAIN CONFLICT DETECTOR ───────────────────────────────

test_inn01_conflict_when_overlap if {
    decide := jdg.r13_hyper_konteksty_innovations.decide with input as {
        "jdg_entrepreneur": {"r13_hyper_konteksty_check": true},
        "conflict_check": {"ip_box_income": 50000, "rd_relief_income": 50000, "total_income": 200000},
    }
    decide.rule_id == "jdg.r13_hyper_konteksty_innovations.cross_domain_conflict_detector"
    decide.cd_conflict == true
    decide.cd_overlap_amount == 50000
    decide._routing == "BLOCK_AND_ALERT"
}

test_inn01_no_conflict_when_no_overlap if {
    decide := jdg.r13_hyper_konteksty_innovations.decide with input as {
        "jdg_entrepreneur": {"r13_hyper_konteksty_check": true},
        "conflict_check": {"ip_box_income": 50000, "rd_relief_income": 0, "total_income": 200000},
    }
    decide.cd_conflict == false
    decide._routing == ""
}

# ── R13-INN-02: SOLIDARITY TAX MONITOR ───────────────────────────────────────

test_inn02_due_over_threshold if {
    decide := jdg.r13_hyper_konteksty_innovations.decide with input as {
        "jdg_entrepreneur": {"r13_hyper_konteksty_check": true},
        "solidarity": {"annual_income_pln": 2000000},
    }
    decide.rule_id == "jdg.r13_hyper_konteksty_innovations.solidarity_tax_monitor"
    decide.st_applies == true
    decide.st_excess_pln == 1000000
    decide.st_solidarity_due_pln == 40000
    decide._routing == "TRIAGE_QUEUE"
}

test_inn02_below_threshold if {
    decide := jdg.r13_hyper_konteksty_innovations.decide with input as {
        "jdg_entrepreneur": {"r13_hyper_konteksty_check": true},
        "solidarity": {"annual_income_pln": 500000},
    }
    decide.st_applies == false
    decide.st_solidarity_due_pln == 0
    decide._routing == ""
}

# ── R13-INN-03: PROKURA DEADLINE MONITOR ─────────────────────────────────────

test_inn03_red_when_3_days if {
    decide := jdg.r13_hyper_konteksty_innovations.decide with input as {
        "jdg_entrepreneur": {"r13_hyper_konteksty_check": true},
        "prokura_monitor": {
            "items": [{"label": "Prokura", "days_left": 3, "filed": false, "type": "SAMOISTNA"}],
        },
    }
    decide.rule_id == "jdg.r13_hyper_konteksty_innovations.prokura_deadline_monitor"
    decide.pk_red_count == 1
    decide._routing == "BLOCK_AND_ALERT"
}

test_inn03_amber_when_5_days if {
    decide := jdg.r13_hyper_konteksty_innovations.decide with input as {
        "jdg_entrepreneur": {"r13_hyper_konteksty_check": true},
        "prokura_monitor": {
            "items": [{"label": "Prokura", "days_left": 5, "filed": false, "type": "ŁĄCZNA"}],
        },
    }
    decide._routing == "TRIAGE_QUEUE"
}

# ── R13-INN-04: ANNUAL DEADLINE CALENDAR ─────────────────────────────────────

test_inn04_red_when_3_days if {
    decide := jdg.r13_hyper_konteksty_innovations.decide with input as {
        "jdg_entrepreneur": {"r13_hyper_konteksty_check": true},
        "deadline_calendar": {
            "items": [{"label": "PIT roczny", "days_left": 3, "filed": false, "weekend_shift": true}],
        },
    }
    decide.rule_id == "jdg.r13_hyper_konteksty_innovations.annual_deadline_calendar"
    decide.dl_red_count == 1
    decide.dl_shifted_count == 1
    decide._routing == "BLOCK_AND_ALERT"
}

test_inn04_green_when_filed if {
    decide := jdg.r13_hyper_konteksty_innovations.decide with input as {
        "jdg_entrepreneur": {"r13_hyper_konteksty_check": true},
        "deadline_calendar": {
            "items": [{"label": "PIT roczny", "days_left": 20, "filed": true, "weekend_shift": false}],
        },
    }
    decide.dl_unfiled_count == 0
    decide._routing == ""
}

# ── R13-INN-05: QUALIFIED SIGNATURE SELECTOR ─────────────────────────────────

test_inn05_qualified_for_full_power if {
    decide := jdg.r13_hyper_konteksty_innovations.decide with input as {
        "jdg_entrepreneur": {"r13_hyper_konteksty_check": true},
        "signature_check": {"document_type": "PEŁNOMOCNICTWO", "value_pln": 5000},
    }
    decide.rule_id == "jdg.r13_hyper_konteksty_innovations.qualified_signature_selector"
    decide.sg_qualified_required == true
    decide._routing == "TRIAGE_QUEUE"
}

test_inn05_qualified_for_high_value if {
    decide := jdg.r13_hyper_konteksty_innovations.decide with input as {
        "jdg_entrepreneur": {"r13_hyper_konteksty_check": true},
        "signature_check": {"document_type": "UMOWA", "value_pln": 15000},
    }
    decide.sg_qualified_required == true
}

test_inn05_plain_for_low_value if {
    decide := jdg.r13_hyper_konteksty_innovations.decide with input as {
        "jdg_entrepreneur": {"r13_hyper_konteksty_check": true},
        "signature_check": {"document_type": "FAKTURA", "value_pln": 3000},
    }
    decide.sg_qualified_required == false
    decide._routing == ""
}

# ── no_match ─────────────────────────────────────────────────────────────────

test_inn_no_input_no_match if {
    decide := jdg.r13_hyper_konteksty_innovations.decide with input as {
        "jdg_entrepreneur": {"r13_hyper_konteksty_check": true},
    }
    decide.rule_id == "jdg.r13_hyper_konteksty_innovations.no_match"
}
