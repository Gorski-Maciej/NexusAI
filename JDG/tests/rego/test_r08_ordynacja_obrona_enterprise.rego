# ═══════════════════════════════════════════════════════════════════════════════
# RAPORT_08 — ORDYNACJA PODATKOWA + OBRONA PODATNIKA — natywne testy Rego
# Scenariusze: happy path, granice (progi, limity), negatywne (no_match),
# temporalność (valid_from/valid_to) dla R08-INN-01..05.
# Uruchomienie: opa test (native OPA) — struktura jak test_r07_*.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r08_ordynacja_obrona_innovations

import future.keywords.if

# ── R08-INN-01: INTEREST CALCULATOR TEMPORAL ──────────────────────────────────

test_inn01_happy_path_three_periods if {
    decide := jdg.r08_ordynacja_obrona_innovations.decide with input as {
        "jdg_entrepreneur": {"r08_ordynacja_check": true},
        "int_temporal": {
            "principal": 10000,
            "days": 90,
            "periods": [
                {"from": "2025-01-01", "to": "2025-03-31", "days": 30, "rate": 0.125},
                {"from": "2025-04-01", "to": "2025-06-30", "days": 30, "rate": 0.12},
                {"from": "2025-07-01", "to": "2025-09-30", "days": 30, "rate": 0.115},
            ],
        },
    }
    decide.rule_id == "jdg.r08_ordynacja_obrona_innovations.interest_calculator_temporal"
    count(decide.int_schedule) == 3
    decide.int_principal == 10000
}

test_inn01_zero_principal_returns_zero if {
    decide := jdg.r08_ordynacja_obrona_innovations.decide with input as {
        "jdg_entrepreneur": {"r08_ordynacja_check": true},
        "int_temporal": {"principal": 0, "days": 30, "periods": [{"days": 30, "rate": 0.125}]},
    }
    decide.int_interest_total == 0
}

test_inn01_correction_7days_gets_reduced_savings if {
    decide := jdg.r08_ordynacja_obrona_innovations.decide with input as {
        "jdg_entrepreneur": {"r08_ordynacja_check": true},
        "int_temporal": {
            "principal": 5000,
            "days": 30,
            "violation_type": "CORRECTION_7DAYS",
            "periods": [{"days": 30, "rate": 0.125}],
        },
    }
    decide.int_reduced_rate_eligible == true
    decide.int_reduced_savings > 0
}

test_inn01_no_input_no_match if {
    decide := jdg.r08_ordynacja_obrona_innovations.decide with input as {
        "jdg_entrepreneur": {"r08_ordynacja_check": true},
    }
    decide.rule_id == "jdg.r08_ordynacja_obrona_innovations.no_match"
}

# ── R08-INN-02: PROCEEDING DEADLINE ALERTS 3LVL ───────────────────────────────

test_inn02_red_when_3_days if {
    decide := jdg.r08_ordynacja_obrona_innovations.decide with input as {
        "jdg_entrepreneur": {"r08_ordynacja_check": true},
        "proceeding_alerts": {
            "deadlines": [
                {"label": "Odwołanie od decyzji", "type": "APPEAL", "days_left": 3},
            ],
        },
    }
    decide.rule_id == "jdg.r08_ordynacja_obrona_innovations.proceeding_deadline_alerts_3lvl"
    decide.pr_red_count == 1
    decide._routing == "BLOCK_AND_ALERT"
    decide.pr_alerts[0].level == "RED"
}

test_inn02_amber_when_10_days if {
    decide := jdg.r08_ordynacja_obrona_innovations.decide with input as {
        "jdg_entrepreneur": {"r08_ordynacja_check": true},
        "proceeding_alerts": {
            "deadlines": [
                {"label": "Wezwanie", "type": "SUMMON", "days_left": 10},
            ],
        },
    }
    decide.pr_alerts[0].level == "AMBER"
    decide._routing == "TRIAGE_QUEUE"
}

test_inn02_green_when_30_days if {
    decide := jdg.r08_ordynacja_obrona_innovations.decide with input as {
        "jdg_entrepreneur": {"r08_ordynacja_check": true},
        "proceeding_alerts": {
            "deadlines": [
                {"label": "Postępowanie", "type": "PROCEEDING", "days_left": 30},
            ],
        },
    }
    decide.pr_alerts[0].level == "GREEN"
    decide._routing == ""
}

# ── R08-INN-03: CORRESPONDENCE AUTOPACK ───────────────────────────────────────

test_inn03_appeal_pack_ready if {
    decide := jdg.r08_ordynacja_obrona_innovations.decide with input as {
        "jdg_entrepreneur": {"r08_ordynacja_check": true},
        "correspondence": {
            "letter_type": "odwolanie",
            "taxpayer": {"nip": "1234567890", "name": "Jan Kowalski"},
            "case_ref": "DM-4101-1/2026",
        },
    }
    decide.rule_id == "jdg.r08_ordynacja_obrona_innovations.correspondence_autopack"
    decide.corr_ready == true
    decide.corr_deadline_days == 14
    contains(decide.corr_legal_basis, "art. 223")
}

test_inn03_missing_fields_fail_closed_triage if {
    decide := jdg.r08_ordynacja_obrona_innovations.decide with input as {
        "jdg_entrepreneur": {"r08_ordynacja_check": true},
        "correspondence": {"letter_type": "odwolanie", "taxpayer": {}, "case_ref": ""},
    }
    decide.corr_ready == false
    count(decide.corr_missing_fields) > 0
    decide._routing == "TRIAGE_QUEUE"
}

test_inn03_white_list_letter_30_days if {
    decide := jdg.r08_ordynacja_obrona_innovations.decide with input as {
        "jdg_entrepreneur": {"r08_ordynacja_check": true},
        "correspondence": {
            "letter_type": "powiadomienie_o_platnosci_na_rachunek",
            "taxpayer": {"nip": "1234567890", "name": "Jan Kowalski"},
            "case_ref": "F-2026-001",
        },
    }
    decide.corr_deadline_days == 30
    contains(decide.corr_legal_basis, "117ba")
}

test_inn03_unknown_letter_triage if {
    decide := jdg.r08_ordynacja_obrona_innovations.decide with input as {
        "jdg_entrepreneur": {"r08_ordynacja_check": true},
        "correspondence": {"letter_type": "nieznany_typ", "taxpayer": {"nip": "123"}, "case_ref": "X"},
    }
    decide.corr_title == "NIEZNANY TYP"
}

# ── R08-INN-04: JUDGMENT PREDICTOR WSA/NSA ────────────────────────────────────

test_inn04_high_probability_favorable if {
    decide := jdg.r08_ordynacja_obrona_innovations.decide with input as {
        "jdg_entrepreneur": {"r08_ordynacja_check": true},
        "judgment": {
            "court": "NSA",
            "article": "22",
            "trend": {"total": 20, "favorable_pct": 80},
            "precedent_weight": 8,
            "taxpayer_strength": 9,
        },
    }
    decide.rule_id == "jdg.r08_ordynacja_obrona_innovations.judgment_predictor_wsa_nsa"
    decide.judg_probability_favorable >= 65
    decide.judg_confidence == "HIGH"
    contains(decide.judg_recommendation, "Rozważ")
}

test_inn04_low_probability_triage if {
    decide := jdg.r08_ordynacja_obrona_innovations.decide with input as {
        "jdg_entrepreneur": {"r08_ordynacja_check": true},
        "judgment": {
            "court": "WSA",
            "article": "70",
            "trend": {"total": 3, "favorable_pct": 25},
            "precedent_weight": 2,
            "taxpayer_strength": 2,
        },
    }
    decide.judg_probability_favorable < 40
    decide._routing == "TRIAGE_QUEUE"
}

test_inn04_no_judgment_no_match if {
    decide := jdg.r08_ordynacja_obrona_innovations.decide with input as {
        "jdg_entrepreneur": {"r08_ordynacja_check": true},
    }
    decide.rule_id == "jdg.r08_ordynacja_obrona_innovations.no_match"
}

# ── R08-INN-05: LIMITATION EVIDENCE MONITOR ───────────────────────────────────

test_inn05_statute_barred_liability if {
    decide := jdg.r08_ordynacja_obrona_innovations.decide with input as {
        "jdg_entrepreneur": {"r08_ordynacja_check": true, "current_year": 2026},
        "limitation_monitor": {
            "liabilities": [
                {"type": "PIT", "tax_year": 2018, "suspended": false},
                {"type": "VAT", "tax_year": 2023, "suspended": false},
            ],
        },
    }
    decide.rule_id == "jdg.r08_ordynacja_obrona_innovations.limitation_evidence_monitor"
    decide.lim_barred_count == 1
    decide._routing == "BLOCK_AND_ALERT"
    decide.lim_evidence_certificate.decision_hash != ""
    contains(decide.lim_evidence_certificate.legal_basis, "art. 70")
}

test_inn05_expiring_window_alerts if {
    decide := jdg.r08_ordynacja_obrona_innovations.decide with input as {
        "jdg_entrepreneur": {"r08_ordynacja_check": true, "current_year": 2026},
        "limitation_monitor": {
            "liabilities": [
                {"type": "VAT", "tax_year": 2023, "suspended": false},
            ],
        },
    }
    # 2023+5=2028 -> remaining 2 lata = 730 dni > warn 180 -> brak alarmu
    decide.lim_expiring_count == 0
    decide._routing == ""
}

test_inn05_suspended_liability_max_extension if {
    decide := jdg.r08_ordynacja_obrona_innovations.decide with input as {
        "jdg_entrepreneur": {"r08_ordynacja_check": true, "current_year": 2026},
        "limitation_monitor": {
            "liabilities": [
                {"type": "PIT", "tax_year": 2020, "suspended": true, "suspension_reason": "KKS w toku"},
            ],
        },
    }
    decide.lim_items[0].suspended == true
    decide.lim_items[0].max_extension_years == 10
}
