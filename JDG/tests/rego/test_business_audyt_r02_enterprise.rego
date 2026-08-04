# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R02 PRAWA PRZEDSIĘBIORCÓW AUDYT — testy rego
# (raport raporty_audyt_glm52/R02_Prawa_Przedsiebiorcow.txt)
# Uruchom: opa test JDG/rules JDG/tests/rego/test_business_audyt_r02_enterprise.rego
# ═══════════════════════════════════════════════════════════════════════════════
# Pokrycie R02:
#  - P1: limit działalności nieewidencjonowanej z data.thresholds (temporalny:
#        50% do 30.06.2023 → 75% od 01.07.2023 → 225% kwartalnie od 2026) — T1
#  - P1: sukcesja bez zarządcy — okno 2 mies. (grace) + wygaśnięcie (expiry) — T4
#  - P2: prokura (art. 18 PP) ↔ poa_manager_enterprise — bridge — T4b
#  - T3: granica okresu zawieszenia (31.12 23:59 vs 1.01 00:01)
#  - T5: aktualizacja CEIDG w trakcie roku (zmiana danych 7 dni)
#  - T9: zawieszenie + zmiana formy opodatkowania w tym samym roku
#  - T10: próg trust_score AUTO_POST (0,92) — routing
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.tests.business_audyt_r02

import data.jdg.business
import data.jdg.representation
import data.jdg.thresholds

# ── P1/T1: LIMIT DZIAŁALNOŚCI NIEEWIDENCJONOWANEJ — 2026 (75% mies. / 225% kwartalnie) ──

test_r02_t1_unregistered_limit_2026_monthly_below if {
    result := business.decide with input as {
        "business_unregistered_limit_check": true,
        "jdg_entrepreneur": {
            "effective_date": "2026-03-15",
            "monthly_revenue_current": 3599.99
        }
    }
    result.rule_id == "jdg.business.unregistered_limit_check"
    result.unregistered_limit_monthly == 3600
    result.unregistered_limit_pct == 0.75
    result.unregistered_quarterly_mode == true
    result.unregistered_within_limit == true
    result.unregistered_activity_limit_exceeded == false
    result._routing == ""
}

test_r02_t1_unregistered_limit_2026_monthly_exceeded if {
    result := business.decide with input as {
        "business_unregistered_limit_check": true,
        "jdg_entrepreneur": {
            "effective_date": "2026-03-15",
            "monthly_revenue_current": 3600.01
        }
    }
    result.rule_id == "jdg.business.unregistered_limit_check"
    result.unregistered_activity_limit_exceeded == true
    result.unregistered_within_limit == false
    result._routing == "BLOCK_AND_ALERT"
}

test_r02_t1_unregistered_limit_2026_quarterly_below if {
    result := business.decide with input as {
        "business_unregistered_limit_check": true,
        "jdg_entrepreneur": {
            "effective_date": "2026-03-15",
            "quarterly_revenue": 10799.99
        }
    }
    # 2026: limit kwartalny = 225% × 4800 = 10 800 zł
    result.unregistered_limit_quarterly == 10800
    result.unregistered_limit_applied == 10800
    result.unregistered_revenue_checked == 10799.99
    result.unregistered_within_limit == true
}

test_r02_t1_unregistered_limit_2026_quarterly_exceeded if {
    result := business.decide with input as {
        "business_unregistered_limit_check": true,
        "jdg_entrepreneur": {
            "effective_date": "2026-03-15",
            "quarterly_revenue": 10800.01
        }
    }
    result.unregistered_activity_limit_exceeded == true
    result._routing == "BLOCK_AND_ALERT"
}

# ── P1/T1: 2022 — 50% płacy minimalnej (płaca 3 010 zł → limit 1 505 zł) ─────

test_r02_t1_unregistered_limit_2022_50pct if {
    result := business.decide with input as {
        "business_unregistered_limit_check": true,
        "jdg_entrepreneur": {
            "effective_date": "2022-06-01",
            "monthly_revenue_current": 1504.99
        }
    } with data.thresholds as {"jdg": {"bounds": {"minimum_wage_gross": 3010}}}
    result.unregistered_limit_monthly == 1505
    result.unregistered_limit_pct == 0.5
    result.unregistered_quarterly_mode == false
    result.unregistered_within_limit == true
}

test_r02_t1_unregistered_limit_2022_50pct_exceeded if {
    result := business.decide with input as {
        "business_unregistered_limit_check": true,
        "jdg_entrepreneur": {
            "effective_date": "2022-06-01",
            "monthly_revenue_current": 1505.01
        }
    } with data.thresholds as {"jdg": {"bounds": {"minimum_wage_gross": 3010}}}
    result.unregistered_activity_limit_exceeded == true
    result._routing == "BLOCK_AND_ALERT"
}

# ── P1/T1: od 01.07.2023 — 75% płacy minimalnej (płaca 3 600 zł → limit 2 700 zł) ──

test_r02_t1_unregistered_limit_2023h2_75pct if {
    result := business.decide with input as {
        "business_unregistered_limit_check": true,
        "jdg_entrepreneur": {
            "effective_date": "2023-07-01",
            "monthly_revenue_current": 2699.99
        }
    } with data.thresholds as {"jdg": {"bounds": {"minimum_wage_gross": 3600}}}
    result.unregistered_limit_monthly == 2700
    result.unregistered_limit_pct == 0.75
    result.unregistered_quarterly_mode == false
    result.unregistered_within_limit == true
}

# ── P1/T1: P930 w łańcuchu else — równy limit NIE przekracza; +1 grosz przekracza ──

test_r02_t1_p930_equal_limit_not_exceeded if {
    result := business.decide with input as {
        "jdg_entrepreneur": {
            "is_unregistered_activity": true,
            "monthly_revenue_current": 3600.00
        }
    }
    # 3600 == limit (75% × 4800) → P930 NIE odpala → P932 (zwolnienie ZUS)
    result.rule_id == "jdg.business.unregistered_zus_exemption"
}

test_r02_t1_p930_exceeded_by_1grosz if {
    result := business.decide with input as {
        "jdg_entrepreneur": {
            "is_unregistered_activity": true,
            "monthly_revenue_current": 3600.01
        }
    }
    result.rule_id == "jdg.business.unregistered_activity_limit_exceeded"
    result._routing == "BLOCK_AND_ALERT"
}

# ── T3: GRANICA OKRESU ZAWIESZENIA (31.12 23:59 vs 1.01 00:01) ──────────────

test_r02_t3_suspension_in_period_last_day if {
    result := business.decide with input as {
        "business_suspension_check": true,
        "business_suspension": {
            "start_date": "2026-01-01",
            "end_date": "2026-12-31",
            "eval_date": "2026-12-31"
        }
    }
    result.rule_id == "jdg.business.suspension_period_boundary"
    result.suspension_in_period == true
    result.suspension_resumed == false
    result.business_status == "SUSPENDED"
}

test_r02_t3_suspension_resumed_next_day if {
    result := business.decide with input as {
        "business_suspension_check": true,
        "business_suspension": {
            "start_date": "2026-01-01",
            "end_date": "2026-12-31",
            "eval_date": "2027-01-01"
        }
    }
    result.suspension_in_period == false
    result.suspension_resumed == true
    result.business_status == "ACTIVE"
}

test_r02_t3_suspension_pre_start if {
    result := business.decide with input as {
        "business_suspension_check": true,
        "business_suspension": {
            "start_date": "2026-01-01",
            "end_date": "2026-12-31",
            "eval_date": "2025-12-31"
        }
    }
    result.business_status == "PRE_SUSPENSION"
}

# ── P1/T4: SUKCESJA BEZ ZARZĄDCY — okno 2 mies. (grace) + wygaśnięcie (expiry) ──

test_r02_t4_succession_grace_window if {
    result := business.decide with input as {
        "jdg_entrepreneur": {
            "in_succession": true,
            "succession_days_elapsed": 30
        }
    }
    result.rule_id == "jdg.business.succession_no_manager_grace"
    result.succession_manager_missing == true
    result.succession_grace_days_left == 30
    result._routing == "TRIAGE_QUEUE"
}

test_r02_t4_succession_grace_day59 if {
    result := business.decide with input as {
        "jdg_entrepreneur": {
            "in_succession": true,
            "succession_days_elapsed": 59
        }
    }
    result.rule_id == "jdg.business.succession_no_manager_grace"
}

test_r02_t4_succession_expiry_day60 if {
    result := business.decide with input as {
        "jdg_entrepreneur": {
            "in_succession": true,
            "succession_days_elapsed": 60
        }
    }
    result.rule_id == "jdg.business.succession_no_manager_expiry"
    result.succession_expired == true
    result.ceidg_deregistration_required == true
    result._routing == "BLOCK_AND_ALERT"
}

test_r02_t4_succession_expiry_day61 if {
    result := business.decide with input as {
        "jdg_entrepreneur": {
            "in_succession": true,
            "succession_days_elapsed": 61
        }
    }
    result.rule_id == "jdg.business.succession_no_manager_expiry"
    result.business_status == "EXPIRED"
}

test_r02_t4_succession_no_manager_field_no_crash if {
    # T4: brak pola "zarządca" w input — brak mdlenia silnika (grace z dniem 0)
    result := business.decide with input as {
        "jdg_entrepreneur": {"in_succession": true}
    }
    result.matched == true
    result.rule_id == "jdg.business.succession_no_manager_grace"
}

test_r02_t4_empty_input_no_match if {
    result := business.decide with input as {}
    result.matched == false
    result.rule_id == "jdg.business.no_match"
}

# ── T5: AKTUALIZACJA CEIDG W TRAKCIE ROKU (zmiana danych → 7 dni) ─────────────

test_r02_t5_ceidg_change_during_year if {
    result := business.decide with input as {
        "jdg_entrepreneur": {
            "ceidg_last_update_date": "2026-03-01",
            "tax_form_change_date": "2026-03-15"
        }
    }
    result.rule_id == "jdg.business.ceidg_data_change_overdue"
    result.ceidg_update_overdue == true
    result._routing == "TRIAGE_QUEUE"
}

# ── T9: ZAWIESZENIE + ZMIANA FORMY OPODATKOWANIA W TYM SAMYM ROKU ────────────

test_r02_t9_suspension_and_form_change if {
    result := business.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "SUSPENDED",
            "tax_form_changed_this_year": true,
            "has_pre_change_expenses": true
        }
    }
    # Silnik utrzymuje werdykt zawieszenia (P910) — zmiana formy wymaga remanentu po wznowieniu
    result.business_status == "SUSPENDED"
    result.pit_advance_required == false
    result.ceidg_registration_required == false
}

# ── T10: PRÓG TRUST_SCORE AUTO_POST (0,92) — ROUTING ─────────────────────────

test_r02_t10_trust_auto_post_threshold if {
    data.jdg.thresholds.limits.trust_auto_post == 0.92
}

test_r02_t10_trust_threshold_exposed if {
    t := data.jdg.thresholds.limits.trust_auto_post
    t >= 0.919
    t <= 0.921
}

# ── P2: PROKURA (art. 18 PP) ↔ POA_MANAGER_ENTERPRISE — BRIDGE ──────────────

test_r02_p2_prokura_poa_manager_bridge if {
    result := representation.decide with input as {
        "business_audit_prokura_check": true,
        "jdg_entrepreneur": {
            "prokura_registered": true,
            "prokura_type": "SELF_EMPLOYED"
        }
    }
    result.rule_id == "jdg.representation.prokura_poa_manager_bridge"
    result.prokura_poa_manager_linked == true
    result.poa_manager_package == "jdg.poa_manager"
}

test_r02_p2_prokura_normal_chain_without_audit if {
    result := representation.decide with input as {
        "jdg_entrepreneur": {
            "prokura_registered": true,
            "prokura_type": "SELF_EMPLOYED"
        }
    }
    result.rule_id == "jdg.representation.prokura_self_employed"
    result._routing == "TRIAGE_QUEUE"
}

test_r02_p2_prokura_unregistered_block if {
    result := representation.decide with input as {
        "jdg_entrepreneur": {
            "prokura_requested": true,
            "prokura_registered": false
        }
    }
    result.rule_id == "jdg.representation.prokura_unregistered"
    result._routing == "BLOCK_AND_ALERT"
}
