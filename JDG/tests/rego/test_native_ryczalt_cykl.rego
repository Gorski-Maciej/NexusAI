# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE TESTS: RYCZAŁT / CYKL ŻYCIA ATOMIC (GLM52 P13)
# Testy reguł atomowych ryczalt_cykl_atomic_p13: stawki PKWiU, limit 2M EUR,
# zawieszenie, nieewidencjonowana, sukcesja, karta podatkowa.
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.native_ryczalt_cykl

import data.jdg.micro.ryczalt_cykl_atomic_p13 as atomic

# ── stawki PKWiU ───────────────────────────────────────────────────────────────
test_ryczalt_services_85 {
    r := atomic.decide with input as {"ryczalt": {"pkwiu_code": "62.01.1", "activity_type": "services"}}
    r.matched == true
    r.rule_id == "jdg.micro.ryczalt_cykl_atomic_p13.ryczalt_pkwiu.r2"
    r.pit_rate == "0.085"
}

test_ryczalt_manufacturing_3 {
    r := atomic.decide with input as {"ryczalt": {"pkwiu_code": "10.71.1", "activity_type": "manufacturing"}}
    r.matched == true
    r.rule_id == "jdg.micro.ryczalt_cykl_atomic_p13.ryczalt_pkwiu.r3"
    r.pit_rate == "0.03"
}

test_ryczalt_professional_125 {
    r := atomic.decide with input as {"ryczalt": {"pkwiu_code": "69.10.1", "activity_type": "professional"}}
    r.matched == true
    r.rule_id == "jdg.micro.ryczalt_cykl_atomic_p13.ryczalt_pkwiu.r4"
    r.pit_rate == "0.125"
}

test_ryczalt_rental_17 {
    r := atomic.decide with input as {"ryczalt": {"pkwiu_code": "68.20.1", "activity_type": "rental"}}
    r.matched == true
    r.rule_id == "jdg.micro.ryczalt_cykl_atomic_p13.ryczalt_pkwiu.r5"
    r.pit_rate == "0.17"
}

test_ryczalt_construction_55 {
    r := atomic.decide with input as {"ryczalt": {"pkwiu_code": "41.00.1", "activity_type": "construction"}}
    r.matched == true
    r.rule_id == "jdg.micro.ryczalt_cykl_atomic_p13.ryczalt_pkwiu.r6"
    r.pit_rate == "0.055"
}

test_ryczalt_special_agriculture_20 {
    r := atomic.decide with input as {"ryczalt": {"pkwiu_code": "01.11.Z", "activity_type": "special_agriculture"}}
    r.matched == true
    r.rule_id == "jdg.micro.ryczalt_cykl_atomic_p13.ryczalt_pkwiu.r7"
    r.pit_rate == "0.20"
}

test_ryczalt_high_rate_services_25 {
    r := atomic.decide with input as {"ryczalt": {"pkwiu_code": "74.90.Z", "activity_type": "high_rate_services"}}
    r.matched == true
    r.rule_id == "jdg.micro.ryczalt_cykl_atomic_p13.ryczalt_pkwiu.r8"
    r.pit_rate == "0.25"
}

# ── limit 2M EUR ───────────────────────────────────────────────────────────────
test_limit_alert_95 {
    r := atomic.decide with input as {"ryczalt": {"revenue_pln": 9_000_000}}
    # limit = 2 000 000 EUR × 4.3 = 8 600 000 PLN → 9 000 000 > 8 600 000 → przekroczony
    r.matched == true
    r.rule_id == "jdg.micro.ryczalt_cykl_atomic_p13.limit_2m.r2"
}

test_limit_ok_under {
    r := atomic.decide with input as {"ryczalt": {"revenue_pln": 8_000_000}}
    # 8 000 000 / 8 600 000 = 93% < 95% → brak dopasowania limit → no_match
    r.matched == false
    r.rule_id == "jdg.micro.ryczalt_cykl_atomic_p13.no_match"
}

# ── zawieszenie ────────────────────────────────────────────────────────────────
test_suspension_ok_30_days {
    r := atomic.decide with input as {"business": {"suspension_requested": true, "suspension_days": 60}}
    r.matched == true
    r.rule_id == "jdg.micro.ryczalt_cykl_atomic_p13.suspension.r1"
    r.business_status == "SUSPENDED"
}

test_suspension_too_short {
    r := atomic.decide with input as {"business": {"suspension_requested": true, "suspension_days": 15}}
    r.matched == true
    r.rule_id == "jdg.micro.ryczalt_cykl_atomic_p13.suspension.r2"
}

test_suspension_over_24_months {
    r := atomic.decide with input as {"business": {"suspension_months": 30}}
    r.matched == true
    r.rule_id == "jdg.micro.ryczalt_cykl_atomic_p13.suspension.r3"
}

# ── nieewidencjonowana ─────────────────────────────────────────────────────────
test_unregistered_allowed {
    r := atomic.decide with input as {"business": {"unregistered": true, "monthly_revenue_pln": 2000}}
    # 2000 <= 4800 × 0.5 = 2400 → dozwolona
    r.matched == true
    r.rule_id == "jdg.micro.ryczalt_cykl_atomic_p13.unregistered.r1"
}

test_unregistered_over_limit {
    r := atomic.decide with input as {"business": {"unregistered": true, "monthly_revenue_pln": 3000}}
    # 3000 > 2400 → wymaga rejestracji
    r.matched == true
    r.rule_id == "jdg.micro.ryczalt_cykl_atomic_p13.unregistered.r2"
}

# ── sukcesja ───────────────────────────────────────────────────────────────────
test_succession_2_years {
    r := atomic.decide with input as {"business": {"succession_active": true, "succession_ceidg_within_days": 10, "succession_months": 12}}
    r.matched == true
    r.rule_id == "jdg.micro.ryczalt_cykl_atomic_p13.succession.r1"
    r.business_status == "IN_SUCCESSIO"
}

test_succession_extended {
    r := atomic.decide with input as {"business": {"succession_active": true, "succession_ceidg_within_days": 10, "succession_months": 30}}
    # 30 > 24 i <= 60 → przedłużenie
    r.matched == true
    r.rule_id == "jdg.micro.ryczalt_cykl_atomic_p13.succession.r3"
}

test_succession_over_5_years {
    r := atomic.decide with input as {"business": {"succession_active": true, "succession_ceidg_within_days": 10, "succession_months": 70}}
    # 70 > 60 → wygaśnięcie
    r.matched == true
    r.rule_id == "jdg.micro.ryczalt_cykl_atomic_p13.succession.r4"
}

# ── karta podatkowa ────────────────────────────────────────────────────────────
test_karta_ok {
    r := atomic.decide with input as {"ryczalt": {"karta_podatkowa": true, "employees": 3}}
    r.matched == true
    r.rule_id == "jdg.micro.ryczalt_cykl_atomic_p13.karta.r1"
}

test_karta_too_many_employees {
    r := atomic.decide with input as {"ryczalt": {"karta_podatkowa": true, "employees": 8}}
    r.matched == false
    r.rule_id == "jdg.micro.ryczalt_cykl_atomic_p13.no_match"
}
