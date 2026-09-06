# Testy natywne V3-P24 — innowacje I1–I12 + L-PP-2 (Rego v0, OPA 0.68 + 1.9)
package test_jdg_p24_innovations

# ── I1: CEIDG change detectors (wyzwalacze naturalne) ────────────
test_ceidg_address_change {
    result := data.jdg.p24_innovations.decide with input as {
        "jdg_entrepreneur": {
            "ceidg_registered": true,
            "address_changed": true,
            "ceidg_address_updated": false
        }
    }
    result.rule_id == "jdg.p24_innovations.i1.ceidg_change_detector_address"
    result.detector_type == "ADDRESS_CHANGE"
    result.days_to_file == 7
    result._routing == "TRIAGE_QUEUE"
}

test_ceidg_pkd_change {
    result := data.jdg.p24_innovations.decide with input as {
        "jdg_entrepreneur": {
            "ceidg_registered": true,
            "pkd_codes_changed": true
        }
    }
    result.rule_id == "jdg.p24_innovations.i1.ceidg_change_detector_pkd"
    result.detector_type == "PKD_CHANGE"
}

# ── I1: deadline tracker (opty-in + routing po elapsed dniach) ───
test_ceidg_deadline_passed_blocks {
    result := data.jdg.p24_innovations.decide with input as {
        "jdg_entrepreneur": {
            "p24_deadline_check": true,
            "ceidg_change_days_elapsed": 10,
            "ceidg_deadline_violation_count": 0
        }
    }
    result.rule_id == "jdg.p24_innovations.i1.ceidg_deadline_tracker"
    result.deadline_passed == true
    result._routing == "BLOCK_AND_ALERT"
    # 0 wcześniejszych naruszeń → 700 zł (pierwsza luka), nie 1400
    result.estimated_penalty_pln == 700
}

test_ceidg_deadline_near_window_triage {
    result := data.jdg.p24_innovations.decide with input as {
        "jdg_entrepreneur": {
            "p24_deadline_check": true,
            "ceidg_change_days_elapsed": 6,
            "ceidg_deadline_violation_count": 0
        }
    }
    result.rule_id == "jdg.p24_innovations.i1.ceidg_deadline_tracker"
    result.deadline_passed == false
    result._routing == "TRIAGE_QUEUE"
    result.estimated_penalty_pln == 700
}

# ── I2: semantic matcher (wyzwalacz: niepusty opis usługi) ───────
test_semantic_matcher_it_3pct {
    result := data.jdg.p24_innovations.decide with input as {
        "invoice": {"service_description": "Programowanie stron internetowych i software"}
    }
    result.rule_id == "jdg.p24_innovations.i2.semantic_matcher_it"
    result.matched_rate == "3.0%"
}

test_semantic_matcher_transport_15pct {
    result := data.jdg.p24_innovations.decide with input as {
        "invoice": {"service_description": "Usługi transportowe i spedycja krajowa"}
    }
    result.rule_id == "jdg.p24_innovations.i2.semantic_matcher_transport"
    result.matched_rate == "15.0%"
}

test_semantic_matcher_health_20pct {
    result := data.jdg.p24_innovations.decide with input as {
        "invoice": {"service_description": "Usługi lekarza dentysty"}
    }
    result.rule_id == "jdg.p24_innovations.i2.semantic_matcher_health_20"
    result.matched_rate == "20.0%"
}

test_semantic_matcher_no_match_falls_through {
    result := data.jdg.p24_innovations.decide with input as {
        "invoice": {"service_description": "sprzedaż detaliczna artykułów spożywczych"}
    }
    result.rule_id != "jdg.p24_innovations.i2.semantic_matcher_it"
    result.rule_id != "jdg.p24_innovations.i2.semantic_matcher_transport"
    result.rule_id != "jdg.p24_innovations.i2.semantic_matcher_health_20"
}

# ── I3: succession scorecard (opty-in) ───────────────────────────
test_succession_scorecard_critical {
    result := data.jdg.p24_innovations.decide with input as {
        "jdg_entrepreneur": {"p24_succession_check": true}
    }
    result.rule_id == "jdg.p24_innovations.i3.succession_scorecard"
    result.scorecard_total == 0
    result._routing == "BLOCK_AND_ALERT"
}

# ── I5: transport tax (opty-in) ──────────────────────────────────
test_transport_truck_over_12t {
    result := data.jdg.p24_innovations.decide with input as {
        "jdg_entrepreneur": {
            "p24_transport_check": true,
            "vehicle_dmc_kg": 16000,
            "transport_vehicle_type": "TRUCK",
            "transport_fleet_size": 2
        }
    }
    result.rule_id == "jdg.p24_innovations.i5.transport_tax_fleet_optimizer"
    result.vehicle_category == "Ciężarowy >12t"
    result.tax_rate_category == "MAX_MF"
    result.total_fleet_tax_pln == 7000.0
}

test_transport_electric_exempt {
    result := data.jdg.p24_innovations.decide with input as {
        "jdg_entrepreneur": {
            "p24_transport_check": true,
            "vehicle_dmc_kg": 5000,
            "transport_vehicle_type": "TRUCK",
            "vehicle_is_electric": true,
            "transport_fleet_size": 1
        }
    }
    result.rule_id == "jdg.p24_innovations.i5.transport_tax_fleet_optimizer"
    result.tax_rate_category == "EXEMPT"
    result.total_fleet_tax_pln == 0.0
}

# ── I8: unregistered activity (wyzwalacz: jawny klucz przychodu) ─
test_unregistered_limit_exceeded {
    result := data.jdg.p24_innovations.decide with input as {
        "jdg_entrepreneur": {"monthly_revenue_unregistered_pln": 4000}
    }
    result.rule_id == "jdg.p24_innovations.i8.unregistered_activity_checker"
    result.limit_exceeded == true
    result._routing == "BLOCK_AND_ALERT"
}

test_unregistered_below_limit {
    result := data.jdg.p24_innovations.decide with input as {
        "jdg_entrepreneur": {"monthly_revenue_unregistered_pln": 1000}
    }
    result.rule_id == "jdg.p24_innovations.i8.unregistered_activity_checker"
    result.limit_exceeded == false
    result._routing == ""
}

test_unregistered_absent_key_reaches_no_match {
    # Fix AP10: brak klucza przychodu ≠ przychód 0 — i8 nie może połykać
    # inputów bez tego klucza (wcześniej zasłaniał i12/L-PP-2/no_match_final)
    result := data.jdg.p24_innovations.decide with input as {
        "jdg_entrepreneur": {"unrelated_key": true}
    }
    result.rule_id == "jdg.p24_innovations.no_match_final"
}

# ── I12: coverage matrix (opty-in) ───────────────────────────────
test_coverage_matrix_on_demand {
    result := data.jdg.p24_innovations.decide with input as {
        "jdg_entrepreneur": {"p24_coverage_check": true}
    }
    result.rule_id == "jdg.p24_innovations.i12.coverage_matrix"
    count(result.gaps_remaining) == 7
    result.ci_readiness_pct > 0
}

# ── L-PP-2: auto-indexation (opty-in) ────────────────────────────
test_autoindex_2026 {
    result := data.jdg.p24_innovations.decide with input as {
        "jdg_entrepreneur": {"p24_autoindex_check": true}
    }
    result.rule_id == "jdg.p24_innovations.l_pp2.auto_indexation"
    result.min_wage_current_pln == 4800
    result.limit_75pct_current_pln == 3600.0
    result.limit_changed_this_year == false
}
