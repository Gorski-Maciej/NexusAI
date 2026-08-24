# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests — P11 GLM52 KKS + ORDYNACJA + AUDYT/OBRONA
# Package: jdg.micro.kks_ord_atomic_p11
# Rules tested: penalty calculator (a54), active remorse (a16), voluntary
#               submission (a17), recidivism (a37), limitation (a44 KKS / a70 OP),
#               correction (a81b), whitelist (a117ba), GAAR (a119a), audit rights
# ═══════════════════════════════════════════════════════════════════════════════

package test_jdg_kks_ord

import data.jdg.micro.kks_ord_atomic_p11

# ── 1. KKS ART. 54 — KALKULATOR KARY (przestępstwo do 720 stawek) ──────────────
test_positive_penalty_crime {
    result := kks_ord_atomic_p11.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "kks_penalty_check": true,
            "kks_crime_type": "PRZESTEPSTWO",
            "min_wage_pln": 4800.0,
            "kks_rates_count": 100
        }
    } with data.jdg.thresholds as {"kks": {"daily_rates_crime_max": 720}}
    result.matched == true
    result.rule_id == "jdg.micro.kks.a54.penalty_calculator.r1"
    result.kks_crime_type == "PRZESTEPSTWO"
    result.kks_daily_rate_pln == 6.67
    result.kks_penalty_pln == 667
}

test_positive_penalty_misdemeanor {
    result := kks_ord_atomic_p11.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "kks_penalty_check": true,
            "kks_crime_type": "WYKROCZENIE",
            "min_wage_pln": 4800.0,
            "kks_rates_count": 100
        }
    } with data.jdg.thresholds as {"kks": {"daily_rates_misdemeanor_max": 240}}
    result.rule_id == "jdg.micro.kks.a54.penalty_calculator.r2"
    result.kks_crime_type == "WYKROCZENIE"
    result.kks_penalty_pln == 667
}

# ── 2. KKS ART. 16 — CZYNNY ŻAL (zawiadomienie przed wykryciem) ────────────────
test_positive_active_remorse {
    result := kks_ord_atomic_p11.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "kks_active_remorse_check": true,
            "remorse_notified_before_detection": true
        }
    }
    result.rule_id == "jdg.micro.kks.a16.active_remorse"
    result.active_remorse_applicable == true
}

test_negative_active_remorse_after_detection {
    result := kks_ord_atomic_p11.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "kks_active_remorse_check": true,
            "remorse_notified_before_detection": false
        }
    }
    result.rule_id != "jdg.micro.kks.a16.active_remorse"
}

# ── 3. KKS ART. 17 — DOBROWOLNE PODDANIE SIĘ ODPOWIEDZIALNOŚCI ─────────────────
test_positive_voluntary_submission {
    result := kks_ord_atomic_p11.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "kks_voluntary_submission_check": true,
            "voluntary_submission_paid_full": true
        }
    }
    result.rule_id == "jdg.micro.kks.a17.voluntary_submission"
    result.voluntary_submission_applicable == true
}

# ── 4. KKS ART. 37 — RECYDYWA (ponowny czyn w 5 lat) ───────────────────────────
test_positive_recidivism {
    result := kks_ord_atomic_p11.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "kks_recidivism_check": true,
            "days_since_previous_conviction": 1000,
            "previous_conviction_similar": true
        }
    } with data.jdg.thresholds as {"kks": {"recidivism_days_window": 1825}}
    result.rule_id == "jdg.micro.kks.a37.recidivism_monitor"
    result.recidivism_detected == true
    result._routing == "BLOCK_AND_ALERT"
}

test_negative_recidivism_outside_window {
    result := kks_ord_atomic_p11.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "kks_recidivism_check": true,
            "days_since_previous_conviction": 2000,
            "previous_conviction_similar": true
        }
    }
    result.rule_id != "jdg.micro.kks.a37.recidivism_monitor"
}

# ── 5. KKS ART. 44 — PRZEDAWNIENIE KARALNOŚCI (5 lat) ──────────────────────────
test_positive_kks_limitation {
    result := kks_ord_atomic_p11.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "kks_limitation_check": true,
            "offense_date": "2020-01-01",
            "eval_date": "2026-06-01"
        }
    } with data.jdg.thresholds as {"kks": {"statute_limitation_kks_years": 5}}
    result.rule_id == "jdg.micro.kks.a44.limitation"
    result.kks_limitation_applicable == true
    result._routing == "OK"
}

# ── 5b. KKS ART. 45 — ZATARCIE SKAZANIA ───────────────────────────────────────
test_positive_expungement {
    result := kks_ord_atomic_p11.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "kks_expungement_check": true,
            "conviction_type": "PRZESTĘPSTWO",
            "penalty_end_date": "2020-01-01",
            "eval_date": "2026-06-01"
        }
    } with data.jdg.thresholds as {"kks": {"expungement_conviction_years": 5}}
    result.rule_id == "jdg.micro.kks.a45.expungement_tracker"
    result.expungement_eligible == true
    result._routing == "OK"
}

test_negative_expungement_not_yet {
  result := kks_ord_atomic_p11.decide with input as {
    "jdg_entrepreneur": {
      "business_status": "ACTIVE",
      "kks_expungement_check": true,
      "conviction_type": "PRZESTĘPSTWO",
      "penalty_end_date": "2024-01-01",
      "eval_date": "2026-06-01"
    }
  }
  result.rule_id != "jdg.micro.kks.a45.expungement_tracker"
}

# ── 5ter. KKS ART. 53 — MAŁA WARTOŚĆ (próg 500 × min. wynagrodzenie) ──────────
test_positive_small_value {
  result := kks_ord_atomic_p11.decide with input as {
    "jdg_entrepreneur": {
      "business_status": "ACTIVE",
      "kks_small_value_check": true,
      "offense_value_pln": 100000,
      "min_wage_pln": 4800.0
    }
  } with data.jdg.thresholds as {"kks": {"small_value_multiple": 500}}
  result.rule_id == "jdg.micro.kks.a53.small_value_classifier"
  result.small_value_class == "MAŁA WARTOŚĆ"
  result._routing == "TRIAGE_QUEUE"
}

test_negative_small_value_over_threshold {
  result := kks_ord_atomic_p11.decide with input as {
    "jdg_entrepreneur": {
      "business_status": "ACTIVE",
      "kks_small_value_check": true,
      "offense_value_pln": 3000000,
      "min_wage_pln": 4800.0
    }
  }
  result.rule_id != "jdg.micro.kks.a53.small_value_classifier"
}

# ── 5c. ORDYNACJA ART. 14a/14d — INTERPRETACJE INDYWIDUALNE (Legal Twin) ─────
test_positive_interpretation_protection {
    result := kks_ord_atomic_p11.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "interpretation_requested": true,
            "facts_match_interpretation": true
        }
    } with data.jdg.thresholds as {"ord": {"interpretation_days": 30}}
    result.rule_id == "jdg.micro.ord.a14a.interpretation_protection"
    result.interpretation_protection_applicable == true
    result._routing == "TRIAGE_QUEUE"
}

test_negative_interpretation_facts_mismatch {
  result := kks_ord_atomic_p11.decide with input as {
    "jdg_entrepreneur": {
      "business_status": "ACTIVE",
      "interpretation_requested": true,
      "facts_match_interpretation": false
    }
  }
  result.rule_id != "jdg.micro.ord.a14a.interpretation_protection"
}

test_positive_interpretation_deemed_issued {
  result := kks_ord_atomic_p11.decide with input as {
    "jdg_entrepreneur": {
      "business_status": "ACTIVE",
      "interpretation_requested": true,
      "days_since_application": 45,
      "case_obviously_unfounded": false
    }
  } with data.jdg.thresholds as {"ord": {"interpretation_days": 30}}
  result.rule_id == "jdg.micro.ord.a14d.interpretation_deadline"
  result.interpretation_deemed_issued == true
  result._routing == "OK"
}

test_negative_interpretation_not_yet_deadline {
  result := kks_ord_atomic_p11.decide with input as {
    "jdg_entrepreneur": {
      "business_status": "ACTIVE",
      "interpretation_requested": true,
      "days_since_application": 10,
      "case_obviously_unfounded": false
    }
  }
  result.rule_id != "jdg.micro.ord.a14d.interpretation_deadline"
}

# ── 6. ORDYNACJA ART. 70 — PRZEDAWNIENIE ZOBOWIĄZANIA (5 lat od końca roku) ───
test_positive_ord_limitation {
    result := kks_ord_atomic_p11.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "ord_limitation_check": true,
            "tax_year_end_date": "2020-12-31",
            "eval_date": "2026-06-01"
        }
    } with data.jdg.thresholds as {"ord": {"statute_of_limitations_years": 5}}
    result.rule_id == "jdg.micro.ord.a70.limitation"
    result.ord_limitation_applicable == true
}

test_negative_ord_limitation_not_yet {
    result := kks_ord_atomic_p11.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "ord_limitation_check": true,
            "tax_year_end_date": "2023-12-31",
            "eval_date": "2026-06-01"
        }
    }
    result.rule_id != "jdg.micro.ord.a70.limitation"
}

# ── 7. ORDYNACJA ART. 81b — OBOWIĄZEK KOREKTY (14 dni) ─────────────────────────
test_positive_correction_duty {
    result := kks_ord_atomic_p11.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "ord_correction_check": true,
            "declaration_error_found": true,
            "under_audit": true,
            "correction_type": "MINUS"
        }
    }
    result.rule_id == "jdg.micro.ord.a81b.correction_duty"
    result.correction_required == true
    result.correction_minus_blocked == true
}

# ── 8. ORDYNACJA ART. 117ba — BIAŁA LISTA (sankcja 20%) ────────────────────────
test_positive_whitelist_sanction {
    result := kks_ord_atomic_p11.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "whitelist_check": true,
            "counterparty_on_whitelist": false,
            "payment_amount_pln": 10000
        }
    } with data.jdg.thresholds as {"ord": {"whitelist_sanction_pct": 0.20}}
    result.rule_id == "jdg.micro.ord.a117ba.whitelist_monitor"
    result.whitelist_verified == false
    result.whitelist_sanction_pln == 2000
}

test_negative_whitelist_ok {
    result := kks_ord_atomic_p11.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "whitelist_check": true,
            "counterparty_on_whitelist": true,
            "payment_amount_pln": 10000
        }
    }
    result.rule_id != "jdg.micro.ord.a117ba.whitelist_monitor"
}

# ── 9. ORDYNACJA ART. 119a — GAAR ──────────────────────────────────────────────
test_positive_gaar_risk {
    result := kks_ord_atomic_p11.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "gaar_check": true,
            "tax_benefit": true,
            "no_economic_purpose": true,
            "artificial_arrangement": true
        }
    }
    result.rule_id == "jdg.micro.ord.a119a.gaar_risk"
    result.gaar_risk_level == "WYSOKIE"
}

test_negative_gaar_ok {
    result := kks_ord_atomic_p11.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "gaar_check": true,
            "tax_benefit": false,
            "no_economic_purpose": false,
            "artificial_arrangement": false
        }
    }
    result.rule_id != "jdg.micro.ord.a119a.gaar_risk"
}

# ── 10. ORDYNACJA ART. 282b/291/223 — PAKIET PRAW W KONTROLI ──────────────────
test_positive_audit_defense_packet {
    result := kks_ord_atomic_p11.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "audit_defense_check": true,
            "audit_active": true
        }
    }
    result.rule_id == "jdg.micro.ord.a282b.audit_defense_packet"
    result.audit_rights_available == true
    result.notification_days == 7
    result.protocol_objection_days == 14
    result.appeal_days == 14
    result.wsa_days == 30
}

# ── 11. ORDYNACJA ART. 193a — JPK NA ŻĄDANIE ───────────────────────────────────
test_positive_jpk_request {
    result := kks_ord_atomic_p11.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "jpk_request_check": true,
            "jpk_requested": true
        }
    }
    result.rule_id == "jdg.micro.ord.a193a.jpk_request"
    result.jpk_deadline_days == 14
}

# ── 12. NO_MATCH — brak flagi domenowej → default (INV-018) ────────────────────
test_no_match_without_domain_flag {
    result := kks_ord_atomic_p11.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE"
        }
    }
    result.matched == false
    result.rule_id == "jdg.micro.kks_ord_atomic_p11.no_match"
}
