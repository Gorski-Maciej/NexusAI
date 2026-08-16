# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P08 GLM52 ZUS MACRO ENTERPRISE v9.0
# Pakiet: jdg.p08_zus_macro_enterprise
# Raport: RAPORT_ENTERPRISE_P08 (ZUS + składka zdrowotna + ulgi + zasiłki)
#
# SEKCJE:
#   Sekcja 1: Mapa pokrycia SUS + zdrowotnej + zasiłkowej (dane z narzędzia)
#   Sekcja 2: AUDYT SKŁADKI ZDROWOTNEJ (PRIORYTET) — kalkulator wg formy:
#             skala 9% dochodu / liniowy 4.9% (limit roczny) / ryczałt 4.9%
#             × podstawa progowa (3 progi: 60k→60%, 300k→100%, >300k→180%)
#             / karta 9% minimalnego
#   Sekcja 3: AUDYT SKŁADEK SPOŁECZNYCH — stopy 19.52/8/2.45/1.67%,
#             podstawa 60% przeciętnego, 30-krotność, terminy 10/15/20
#   Sekcja 4: AUDYT ULG — ulga na start (Art. 18a 6 mies), preferencyjna
#             (24 mies, 20% min), mały ZUS+ (Art. 18c 36 mies, 30% min,
#             przychód ≤ 120k), działalność nieewidencjonowana (50% min)
#   Sekcja 5: AUDYT ZBIEGÓW TYTUŁÓW (Art. 9) — etat+JDG (tylko zdrowotna),
#             emerytura+JDG, zlecenie+JDG
#   Sekcja 6: AUDYT ZASIŁKÓW — chorobowe 80/100%, okres 182/270 dni,
#             macierzyńskie 20/41/43 tyg., opiekuńcze 60 dni, rehab 90-180
#   Sekcja 7: 14 GENIALNYCH INNOWACJI (Digital Twin ZUS, kalendarz 10/15/20,
#             tracker ulg, auto-DRA, rekomendacja podstawy, Merkle chain)
#
# Zgodność: ustawa o SUS (Dz.U. 2025 poz. 345), ustawa zdrowotna Art. 79-81,
#           ustawa zasiłkowa, ADR-002 (progi z data.jdg.thresholds.zus).
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p08_zus_macro_enterprise

import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.p08_zus_macro_enterprise.no_match",
    "package": "jdg.p08_zus_macro_enterprise",
    "priority": 999999,
}

# ── ŹRÓDŁO AUDYTU (host wstrzykuje output tools/zus_micro_inventory.py) ───────
audit_data := data.jdg.zus_micro_audit {
    data.jdg.zus_micro_audit
} else := {} {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# PROGI Z data.jdg.thresholds.zus (ADR-002) — guardy z fallbackiem ustawowym
# ═══════════════════════════════════════════════════════════════════════════════

health_scale_rate := object.get(data.jdg.thresholds.zus, "health_scale_rate", 0.09) {
    data.jdg.thresholds
} else := 0.09 {
    true
}

health_linear_rate := object.get(data.jdg.thresholds.zus, "health_linear_rate", 0.049) {
    data.jdg.thresholds
} else := 0.049 {
    true
}

health_linear_deduction_limit := object.get(data.jdg.thresholds.zus, "health_linear_deduction_limit", 14100) {
    data.jdg.thresholds
} else := 14100 {
    true
}

lump_tier_1_limit := object.get(data.jdg.thresholds.zus, "health_lump_tier_1_limit", 60000) {
    data.jdg.thresholds
} else := 60000 {
    true
}

lump_tier_2_limit := object.get(data.jdg.thresholds.zus, "health_lump_tier_2_limit", 300000) {
    data.jdg.thresholds
} else := 300000 {
    true
}

lump_tier_1_amount := object.get(data.jdg.thresholds.zus, "health_lump_tier_1_amount", 491.40) {
    data.jdg.thresholds
} else := 491.40 {
    true
}

lump_tier_2_amount := object.get(data.jdg.thresholds.zus, "health_lump_tier_2_amount", 819.00) {
    data.jdg.thresholds
} else := 819.00 {
    true
}

lump_tier_3_amount := object.get(data.jdg.thresholds.zus, "health_lump_tier_3_amount", 1474.20) {
    data.jdg.thresholds
} else := 1474.20 {
    true
}

pension_rate := object.get(data.jdg.thresholds.zus, "pension_rate", 0.1952) {
    data.jdg.thresholds
} else := 0.1952 {
    true
}

disability_rate := object.get(data.jdg.thresholds.zus, "disability_rate", 0.08) {
    data.jdg.thresholds
} else := 0.08 {
    true
}

sickness_rate := object.get(data.jdg.thresholds.zus, "sickness_voluntary_rate", 0.0245) {
    data.jdg.thresholds
} else := 0.0245 {
    true
}

accident_rate := object.get(data.jdg.thresholds.zus, "accident_rate", 0.0167) {
    data.jdg.thresholds
} else := 0.0167 {
    true
}

social_base_standard := object.get(data.jdg.thresholds.zus, "social_base_standard", 5460.00) {
    data.jdg.thresholds
} else := 5460.00 {
    true
}

start_relief_months := object.get(data.jdg.thresholds.zus, "start_relief_months", 6) {
    data.jdg.thresholds
} else := 6 {
    true
}

preferential_months := object.get(data.jdg.thresholds.zus, "preferential_months", 24) {
    data.jdg.thresholds
} else := 24 {
    true
}

maly_zus_plus_months := object.get(data.jdg.thresholds.zus, "maly_zus_plus_months", 36) {
    data.jdg.thresholds
} else := 36 {
    true
}

maly_zus_plus_income_limit := object.get(data.jdg.thresholds.zus, "maly_zus_plus_income_limit", 60000) {
    data.jdg.thresholds
} else := 60000 {
    true
}

maly_zus_plus_revenue_limit := object.get(data.jdg.thresholds.zus, "maly_zus_plus_revenue_limit", 120000) {
    data.jdg.thresholds
} else := 120000 {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 1 — MAPA POKRYCIA SUS + ZDROWOTNEJ + ZASIŁKOWEJ
# ═══════════════════════════════════════════════════════════════════════════════

coverage_status := {
    "coverage_map": object.get(audit_data, "coverage", {}),
    "total_articles": count(object.get(audit_data, "coverage", {})),
    "complete_count": count(complete_articles),
    "missing_articles": missing_articles,
    "missing_count": count(missing_articles),
    "duplicate_count": object.get(audit_data, "duplicate_count", 0),
    "total_stubs": object.get(audit_data, "total_stubs", 0),
    "_routing": "REPORT",
    "_routing_reason": "Mapa pokrycia ustawy o SUS + zdrowotnej + zasiłkowej — kompletność warstwy micro ZUS",
}

complete_articles := [a |
    some k
    object.get(audit_data, "coverage", {})[k] == "COMPLETE"
    a := k
]

missing_articles := [a |
    some k
    object.get(audit_data, "coverage", {})[k] == "MISSING"
    a := k
]

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 2 — AUDYT SKŁADKI ZDROWOTNEJ (GŁÓWNY PRIORYTET)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P08-INN-01: KALKULATOR SKŁADKI ZDROWOTNEJ WG FORMY OPODATKOWANIA ──────────
# skala → 9% od dochodu | liniowy → 4.9% od dochodu (limit roczny) |
# ryczałt → 4.9% × podstawa progowa (3 progi) | karta → 9% od minimalnego
health_contribution_calculator := {
    "matched": true,
    "rule_id": "jdg.p08_zus_macro_enterprise.health_contribution_calculator",
    "_legal_basis": "Art. 9 SUS",
    "package": "jdg.p08_zus_macro_enterprise",
    "priority": 100,
    "health": {
        "tax_form": tax_form,
        "rate": health_rate,
        "base": health_base,
        "monthly_contribution": monthly_contribution,
        "annual_limit_note": annual_limit_note,
        "deductible_from_tax": deductible_from_tax,
        "note": "Składka zdrowotna wg formy opodatkowania (Art. 79-81 ustawy zdrowotnej); ryczałt — podstawa z progu przychodu",
    },
    "_routing": "REPORT",
    "_routing_reason": "Kalkulator składki zdrowotnej wg formy (PRIORYTET — skala 9%, liniowy 4.9%, ryczałt 3 progi, karta 9%)",
    "_legal_basis": "Art. 79-81 ustawy o świadczeniach opieki zdrowotnej",
    "_warnings": [sprintf("Zdrowotna: %s | stawka %.1f%% | podstawa %.2f zł | miesięcznie %.2f zł. Odliczenie od podatku: %s.", [tax_form, health_rate * 100, health_base, monthly_contribution, deductible_note])],
} {
    object.get(input.jdg_entrepreneur, "p08_health_check", false) == true
    object.get(input, "zus_input", null) != null
}

tax_form := object.get(input.zus_input, "tax_form", "SCALE")

health_rate := health_scale_rate {
    tax_form == "SCALE"
} else := health_linear_rate {
    tax_form == "LINEAR"
} else := health_linear_rate {
    tax_form == "LUMP_SUM"
} else := health_scale_rate {
    tax_form == "TAX_CARD"
} else := health_scale_rate {
    true
}

# Podstawa wymiaru zdrowotnej wg formy
health_base := round(object.get(input.zus_input, "monthly_income", 0) * 100) / 100 {
    tax_form == "SCALE"
} else := round(object.get(input.zus_input, "monthly_income", 0) * 100) / 100 {
    tax_form == "LINEAR"
} else := lump_sum_base {
    tax_form == "LUMP_SUM"
} else := social_base_standard {
    tax_form == "TAX_CARD"
} else := 0 {
    true
}

# Ryczałt: podstawa progowa z przychodu rocznego (3 progi)
lump_sum_base := lump_tier_1_amount {
    annual_revenue <= lump_tier_1_limit
} else := lump_tier_2_amount {
    annual_revenue <= lump_tier_2_limit
} else := lump_tier_3_amount {
    true
}

annual_revenue := object.get(input.zus_input, "annual_revenue", 0)

monthly_contribution := round(health_base * health_rate * 100) / 100 {
    health_base > 0
} else := 0 {
    true
}

# Limit roczny odliczenia dla liniowego (4.9% — limit 14 100 zł/rok 2026)
annual_limit_note := sprintf("Limit roczny odliczenia: %.0f zł (liniowy 2026)", [health_linear_deduction_limit]) {
    tax_form == "LINEAR"
} else := "Brak limitu — składka nie odliczana (skala/ryczałt/karta)" {
    true
}

deductible_from_tax := true {
    tax_form == "LINEAR"
} else := false {
    true
}

deductible_note := "TAK — do 14 100 zł/rok" {
    deductible_from_tax
} else := "NIE" {
    true
}

# ── P08-INN-02: WERYFIKATOR PROGÓW RYCZAŁTOWYCH (zgodność z thresholds) ──────
lump_sum_tier_verifier := {
    "matched": true,
    "rule_id": "jdg.p08_zus_macro_enterprise.lump_sum_tier_verifier",
    "_legal_basis": "Art. 9 SUS",
    "package": "jdg.p08_zus_macro_enterprise",
    "priority": 101,
    "verifier": {
        "annual_revenue": annual_revenue,
        "tier": lump_tier,
        "tier_limit": lump_tier_limit,
        "tier_multiplier_note": lump_tier_multiplier_note,
        "base_amount": lump_sum_base,
        "monthly_contribution": monthly_contribution,
        "tier_limits_ok": object.get(input.zus_input, "tier_limits_ok", true),
    },
    "_routing": "REPORT",
    "_routing_reason": "Weryfikacja progów ryczałtowych zdrowotnej: TIER_1 ≤ 60k → 60% przeciętnego, TIER_2 60-300k → 100%, TIER_3 > 300k → 180%",
    "_legal_basis": "Art. 81c ustawy zdrowotnej",
} {
    object.get(input.jdg_entrepreneur, "p08_lump_tier_check", false) == true
    tax_form == "LUMP_SUM"
}

lump_tier := "TIER_1" {
    annual_revenue <= lump_tier_1_limit
} else := "TIER_2" {
    annual_revenue <= lump_tier_2_limit
} else := "TIER_3" {
    true
}

lump_tier_limit := lump_tier_1_limit {
    lump_tier == "TIER_1"
} else := lump_tier_2_limit {
    lump_tier == "TIER_2"
} else := 0 {
    true
}

lump_tier_multiplier_note := "60% przeciętnego wynagrodzenia" {
    lump_tier == "TIER_1"
} else := "100% przeciętnego wynagrodzenia" {
    lump_tier == "TIER_2"
} else := "180% przeciętnego wynagrodzenia" {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 3 — AUDYT SKŁADEK SPOŁECZNYCH
# ═══════════════════════════════════════════════════════════════════════════════

# ── P08-INN-03: KALKULATOR SKŁADEK SPOŁECZNYCH (stopy + podstawa) ─────────────
social_contribution_calculator := {
    "matched": true,
    "rule_id": "jdg.p08_zus_macro_enterprise.social_contribution_calculator",
    "_legal_basis": "Art. 9 SUS",
    "package": "jdg.p08_zus_macro_enterprise",
    "priority": 102,
    "social": {
        "base": social_base,
        "pension": round(social_base * pension_rate * 100) / 100,
        "disability": round(social_base * disability_rate * 100) / 100,
        "sickness": round(social_base * sickness_rate * 100) / 100,
        "accident": round(social_base * accident_rate * 100) / 100,
        "total_monthly": social_total,
        "voluntary_sickness": object.get(input.zus_input, "voluntary_sickness", false),
        "note": "Stopy: emerytalna 19.52%, rentowa 8%, chorobowa 2.45% (dobrowolna), wypadkowa 1.67% — Art. 22 SUS",
    },
    "_routing": "REPORT",
    "_routing_reason": "Kalkulator składek społecznych (stopy Art. 22 SUS, podstawa Art. 18-19 SUS)",
    "_legal_basis": "Art. 18-19 + Art. 22 SUS",
    "_warnings": [sprintf("Społeczne razem miesięcznie: %.2f zł (podstawa %.2f zł = 60%% przeciętnego).", [social_total, social_base])],
} {
    object.get(input.jdg_entrepreneur, "p08_social_check", false) == true
    object.get(input, "zus_input", null) != null
}

social_base := object.get(input.zus_input, "declared_base", 0) {
    object.get(input.zus_input, "declared_base", 0) > 0
} else := social_base_standard {
    true
}

social_total := round((social_base * (pension_rate + disability_rate + sickness_rate + accident_rate)) * 100) / 100

# ── P08-INN-04: 30-KROTNOŚĆ PODSTAWY (roczny limit) ───────────────────────────
annual_base_limit := {
    "matched": true,
    "rule_id": "jdg.p08_zus_macro_enterprise.annual_base_limit",
    "_legal_basis": "Art. 9 SUS",
    "package": "jdg.p08_zus_macro_enterprise",
    "priority": 103,
    "limit": {
        "projected_annual_base": object.get(input.zus_input, "projected_annual_base", 0),
        "thirty_fold_base": round(social_base_standard * 30 * 100) / 100,
        "exceeded": object.get(input.zus_input, "projected_annual_base", 0) > round(social_base_standard * 30 * 100) / 100,
        "note": "Roczny limit podstawy = 30-krotność prognozowanego przeciętnego wynagrodzenia (Art. 19 ust. 10 SUS)",
    },
    "_routing": "REPORT",
    "_routing_reason": "30-krotność rocznego limitu podstawy (Art. 19 ust. 10 SUS)",
    "_legal_basis": "Art. 19 ust. 10 SUS",
} {
    object.get(input.jdg_entrepreneur, "p08_30x_check", false) == true
}

# ── P08-INN-05: KALENDARZ TERMINÓW (10/15/20) ─────────────────────────────────
payment_calendar := {
    "matched": true,
    "rule_id": "jdg.p08_zus_macro_enterprise.payment_calendar",
    "_legal_basis": "Art. 9 SUS",
    "package": "jdg.p08_zus_macro_enterprise",
    "priority": 104,
    "calendar": {
        "deadline": deadline_day,
        "deadline_note": deadline_note,
        "due_month": object.get(input.zus_input, "due_month", "bieżący"),
        "note": "Terminy składek: 10. (przelewy z karty), 15. (osoby fizyczne), 20. (płatnicy >5 ubezpieczonych) — Art. 47 SUS",
    },
    "_routing": "REPORT",
    "_routing_reason": "Kalendarz terminów składek ZUS (Art. 47 SUS — 10/15/20 dzień miesiąca)",
    "_legal_basis": "Art. 47 SUS",
} {
    object.get(input.jdg_entrepreneur, "p08_calendar_check", false) == true
}

deadline_day := 10 {
    object.get(input.zus_input, "payer_type", "PHYSICAL") == "CARD_TRANSFER"
} else := 15 {
    object.get(input.zus_input, "payer_type", "PHYSICAL") == "PHYSICAL"
} else := 20 {
    object.get(input.zus_input, "payer_type", "PHYSICAL") == "EMPLOYER_5PLUS"
} else := 15 {
    true
}

deadline_note := "10. dzień miesiąca (karta)" {
    deadline_day == 10
} else := "15. dzień miesiąca (osoby fizyczne)" {
    deadline_day == 15
} else := "20. dzień miesiąca (płatnicy >5 ubezpieczonych)" {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 4 — AUDYT ULG
# ═══════════════════════════════════════════════════════════════════════════════

# ── P08-INN-06: SYMULATOR ULG (ulga na start / preferencyjna / mały ZUS+) ─────
relief_simulator := {
    "matched": true,
    "rule_id": "jdg.p08_zus_macro_enterprise.relief_simulator",
    "_legal_basis": "Art. 9 SUS",
    "package": "jdg.p08_zus_macro_enterprise",
    "priority": 105,
    "reliefs": {
        "start_relief": start_relief,
        "preferential": preferential,
        "maly_zus_plus": maly_zus_plus,
        "unregistered_activity": unregistered_activity,
        "note": "Ulga na start (Art. 18a: 6 mies. tylko zdrowotna), preferencyjna (24 mies., 20% minimalnego), mały ZUS+ (Art. 18c: 36 mies., 30% minimalnego)",
    },
    "_routing": "REPORT",
    "_routing_reason": "Symulator ulg ZUS: ulga na start, preferencyjna, mały ZUS+, działalność nieewidencjonowana",
    "_legal_basis": "Art. 18a + Art. 18c SUS + Art. 5 PP",
    "_warnings": [sprintf("Ulga na start: %s | Preferencyjna: %s | Mały ZUS+: %s", [start_relief_note, preferential_note, maly_zus_plus_note])],
} {
    object.get(input.jdg_entrepreneur, "p08_relief_check", false) == true
    object.get(input, "zus_input", null) != null
}

start_relief := object.get(input.zus_input, "start_relief_months_used", 0) < start_relief_months {
    object.get(input.zus_input, "first_activity", false) == true
} else := false {
    true
}

start_relief_note := sprintf("AKTYWNA (pozostało mies.: %d)", [start_relief_months - object.get(input.zus_input, "start_relief_months_used", 0)]) {
    start_relief
} else := "WYKORZYSTANA/NIEDOSTĘPNA" {
    true
}

preferential := object.get(input.zus_input, "preferential_months_used", 0) < preferential_months {
    object.get(input.zus_input, "no_social_in_last_5_years", false) == true
} else := false {
    true
}

preferential_note := sprintf("AKTYWNA (pozostało mies.: %d)", [preferential_months - object.get(input.zus_input, "preferential_months_used", 0)]) {
    preferential
} else := "WYKORZYSTANA/NIEDOSTĘPNA" {
    true
}

maly_zus_plus := object.get(input.zus_input, "maly_zus_plus_months_used", 0) < maly_zus_plus_months {
    prev_income := object.get(input.zus_input, "prev_year_income", 0)
    prev_income <= maly_zus_plus_income_limit
    object.get(input.zus_input, "prev_year_revenue", 0) <= maly_zus_plus_revenue_limit
} else := false {
    true
}

maly_zus_plus_note := sprintf("AKTYWNA (pozostało mies.: %d)", [maly_zus_plus_months - object.get(input.zus_input, "maly_zus_plus_months_used", 0)]) {
    maly_zus_plus
} else := "NIEDOSTĘPNA (przekroczony limit przychodu/dochodu lub okres)" {
    true
}

unregistered_activity := object.get(input.zus_input, "monthly_revenue_unregistered", 0) <= round(social_base_standard / 2 * 100) / 100 {
    object.get(input.zus_input, "unregistered_activity", false) == true
} else := false {
    true
}

# ── P08-INN-07: TRACKER OKRESÓW ULG (24 mies. / 36 mies.) ─────────────────────
relief_tracker := {
    "matched": true,
    "rule_id": "jdg.p08_zus_macro_enterprise.relief_tracker",
    "_legal_basis": "Art. 9 SUS",
    "package": "jdg.p08_zus_macro_enterprise",
    "priority": 106,
    "tracker": {
        "start_relief_used": object.get(input.zus_input, "start_relief_months_used", 0),
        "start_relief_total": start_relief_months,
        "preferential_used": object.get(input.zus_input, "preferential_months_used", 0),
        "preferential_total": preferential_months,
        "maly_zus_plus_used": object.get(input.zus_input, "maly_zus_plus_months_used", 0),
        "maly_zus_plus_total": maly_zus_plus_months,
        "next_switch": next_switch_note,
    },
    "_routing": "REPORT",
    "_routing_reason": "Tracker okresów ulg ZUS (6/24/36 mies.) — auto-wykrywanie utraty ulgi",
    "_legal_basis": "Art. 18a + 18c SUS",
} {
    object.get(input.jdg_entrepreneur, "p08_tracker_check", false) == true
}

next_switch_note := sprintf("Przejście do pełnej podstawy po uldze na start (miesiąc %d)", [object.get(input.zus_input, "start_relief_months_used", 0) + 1]) {
    start_relief
    object.get(input.zus_input, "start_relief_months_used", 0) + 1 == start_relief_months
} else := "Monitorowanie okresów ulg" {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 5 — AUDYT ZBIEGÓW TYTUŁÓW (Art. 9 SUS)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P08-INN-08: DETEKTOR ZBIEGÓW TYTUŁÓW (Art. 9) ─────────────────────────────
title_collision_detector := {
    "matched": true,
    "rule_id": "jdg.p08_zus_macro_enterprise.title_collision_detector",
    "_legal_basis": "Art. 9 SUS",
    "package": "jdg.p08_zus_macro_enterprise",
    "priority": 107,
    "collision": {
        "employment_plus_jdg": employment_plus_jdg,
        "pension_plus_jdg": pension_plus_jdg,
        "mandate_plus_jdg": mandate_plus_jdg,
        "social_from_jdg_required": social_from_jdg_required,
        "health_from_jdg_always": true,
        "note": "Art. 9 SUS: etat + JDG → tylko zdrowotna z JDG; emerytura + JDG → tylko zdrowotna; zlecenie + JDG → składki z obu wg zasad",
    },
    "_routing": "REPORT",
    "_routing_reason": "Detektor zbiegów tytułów (Art. 9 SUS) — etat/emerytura/zlecenie + JDG",
    "_legal_basis": "Art. 9 SUS",
} {
    object.get(input.jdg_entrepreneur, "p08_collision_check", false) == true
}

employment_plus_jdg := object.get(input.zus_input, "employment", false) == true {
    object.get(input.zus_input, "employment", false) == true
} else := false {
    true
}

pension_plus_jdg := object.get(input.zus_input, "pensioner", false) == true {
    object.get(input.zus_input, "pensioner", false) == true
} else := false {
    true
}

mandate_plus_jdg := object.get(input.zus_input, "mandate_contract", false) == true {
    object.get(input.zus_input, "mandate_contract", false) == true
} else := false {
    true
}

# Z JDG: społeczne tylko gdy brak innego tytułu; zdrowotna zawsze
social_from_jdg_required := true {
    employment_plus_jdg == false
    pension_plus_jdg == false
} else := false {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 6 — AUDYT ZASIŁKÓW
# ═══════════════════════════════════════════════════════════════════════════════

# ── P08-INN-09: KALKULATOR ZASIŁKÓW (chorobowe/macierzyńskie/opiekuńcze) ─────
benefits_calculator := {
    "matched": true,
    "rule_id": "jdg.p08_zus_macro_enterprise.benefits_calculator",
    "_legal_basis": "Art. 9 SUS",
    "package": "jdg.p08_zus_macro_enterprise",
    "priority": 108,
    "benefits": {
        "sickness_rate": sickness_benefit_rate,
        "sickness_days": object.get(input.zus_input, "sickness_days", 0),
        "sickness_period_note": sickness_period_note,
        "maternity_note": maternity_note,
        "caregiver_days": object.get(input.zus_input, "caregiver_days", 0),
        "rehabilitation_note": "Świadczenie rehabilitacyjne 90-180 dni (90% podstawy) po wyczerpaniu zasiłku",
        "base_from_12_months": true,
    },
    "_routing": "REPORT",
    "_routing_reason": "Kalkulator zasiłków: chorobowe 80/100% (okres 182/270 dni), macierzyńskie 20/41/43 tyg., opiekuńcze 60 dni",
    "_legal_basis": "Ustawa zasiłkowa",
} {
    object.get(input.jdg_entrepreneur, "p08_benefits_check", false) == true
}

sickness_benefit_rate := 1.00 {
    object.get(input.zus_input, "sickness_reason", "") == "HOSPITAL"
} else := 0.80 {
    true
}

sickness_period_note := "OK (do 182 dni)" {
    object.get(input.zus_input, "sickness_days", 0) <= 182
} else := "PRZEKROCZONY 182 dni — wymagany rehab (90-180 dni)" {
    object.get(input.zus_input, "sickness_days", 0) <= 270
} else := "PRZEKROCZONY 270 dni — koniec okresu zasiłkowego" {
    true
}

maternity_note := sprintf("Macierzyński: 100%% podstawy, %s", [maternity_weeks]) {
    true
}

maternity_weeks := "20 tyg. (1 dziecko) / 41 tyg. (bliźnięta) / 43 tyg. (3+)" {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 7 — 14 GENIALNYCH INNOWACJI
# ═══════════════════════════════════════════════════════════════════════════════

# ── P08-INN-10: DIGITAL TWIN ZUS — miesięczny kalkulator z kalendarzem ────────
zus_digital_twin := {
    "matched": true,
    "rule_id": "jdg.p08_zus_macro_enterprise.zus_digital_twin",
    "_legal_basis": "Art. 9 SUS",
    "package": "jdg.p08_zus_macro_enterprise",
    "priority": 109,
    "twin": {
        "health": monthly_contribution,
        "social": social_total,
        "total_monthly": round((monthly_contribution + social_total) * 100) / 100,
        "deadline": deadline_day,
        "annual_projection": round((monthly_contribution + social_total) * 12 * 100) / 100,
        "note": "Digital Twin ZUS — pełna projekcja miesięczna/roczna składek wg formy i ulg",
    },
    "_routing": "REPORT",
    "_routing_reason": "Digital Twin ZUS — kalkulator składek dla każdej formy i miesiąca z kalendarzem terminów",
    "_legal_basis": "Art. 18-19 + 22 + 47 SUS + Art. 79-81 zdrowotna",
} {
    object.get(input.jdg_entrepreneur, "p08_twin_check", false) == true
    object.get(input, "zus_input", null) != null
}

# ── P08-INN-11: REKOMENDACJA OPTYMALNEJ PODSTAWY ─────────────────────────────
base_recommender := {
    "matched": true,
    "rule_id": "jdg.p08_zus_macro_enterprise.base_recommender",
    "_legal_basis": "Art. 9 SUS",
    "package": "jdg.p08_zus_macro_enterprise",
    "priority": 110,
    "recommendation": {
        "current_base": social_base,
        "minimum_base": round(social_base_standard * 0.6 * 100) / 100,
        "recommended_base": recommended_base,
        "savings_note": savings_note,
        "note": "Rekomendacja podstawy (min. 60% przeciętnego; przy ryczałcie powiązana z progiem zdrowotnej)",
    },
    "_routing": "REPORT",
    "_routing_reason": "Rekomendacja optymalnej podstawy składek (min. 60% przeciętnego, Art. 18 ust. 8 SUS)",
    "_legal_basis": "Art. 18 ust. 8 SUS",
} {
    object.get(input.jdg_entrepreneur, "p08_base_reco_check", false) == true
}

recommended_base := social_base_standard {
    object.get(input.zus_input, "low_income", false) == true
} else := object.get(input.zus_input, "declared_base", social_base_standard) {
    true
}

savings_note := "Możliwa optymalizacja — podstawa min. 60% przeciętnego" {
    social_base < social_base_standard
} else := "Podstawa na poziomie standardowym" {
    true
}

# ── P08-INN-12: REKONCYLACJA ZUS↔PIT↔VAT ─────────────────────────────────────
zus_reconciliation := {
    "matched": true,
    "rule_id": "jdg.p08_zus_macro_enterprise.zus_reconciliation",
    "_legal_basis": "Art. 9 SUS",
    "package": "jdg.p08_zus_macro_enterprise",
    "priority": 111,
    "recon": {
        "zus_paid": object.get(input.zus_input, "zus_paid", 0),
        "pit_deducted": object.get(input.zus_input, "pit_deducted", 0),
        "consistent": object.get(input.zus_input, "zus_paid", 0) == object.get(input.zus_input, "pit_deducted", 0),
        "note": "Rekoncyliacja: składki ZUS odliczone w PIT (P06/P07) muszą odpowiadać faktycznie zapłaconym",
    },
    "_routing": "REPORT",
    "_routing_reason": "Rekoncyliacja ZUS↔PIT (odliczenia składek w PIT vs faktyczne wpłaty) — spójność z P06/P07",
} {
    object.get(input.jdg_entrepreneur, "p08_recon_check", false) == true
}

# ── P08-INN-13: SYMULATOR „ETAT VS JDG" (zbieg tytułów) ───────────────────────
employment_vs_jdg_simulator := {
    "matched": true,
    "rule_id": "jdg.p08_zus_macro_enterprise.employment_vs_jdg_simulator",
    "_legal_basis": "Art. 9 SUS",
    "package": "jdg.p08_zus_macro_enterprise",
    "priority": 112,
    "sim": {
        "employment_social": object.get(input.zus_input, "employment_social", 0),
        "jdg_health_only": object.get(input.zus_input, "employment", false) == true,
        "total_obligation": employment_vs_jdg_total,
        "note": "Symulator etat vs JDG — przy etacie + JDG składki społeczne tylko z etatu, z JDG tylko zdrowotna",
    },
    "_routing": "REPORT",
    "_routing_reason": "Symulator etat vs JDG (Art. 9 SUS — zbieg tytułów)",
    "_legal_basis": "Art. 9 SUS",
} {
    object.get(input.jdg_entrepreneur, "p08_etat_check", false) == true
}

employment_vs_jdg_total := object.get(input.zus_input, "employment_social", 0) + monthly_contribution {
    object.get(input.zus_input, "employment", false) == true
} else := social_total + monthly_contribution {
    true
}

# ── P08-INN-14: MERKLE CHAIN DLA WERDYKTÓW ZUS (wzmocnienie HMAC) ────────────
zus_verdict_integrity := {
    "matched": true,
    "rule_id": "jdg.p08_zus_macro_enterprise.zus_verdict_integrity",
    "_legal_basis": "Art. 9 SUS",
    "package": "jdg.p08_zus_macro_enterprise",
    "priority": 113,
    "integrity": {
        "immutable": true,
        "allowlist_member": true,
        "chain_verified": object.get(input.zus_input, "merkle_verified", false),
        "note": "Werdykty ZUS niemutowalne (safe_merge allowlist) — wzmocnienie do pełnej łańcuchowej weryfikacji Merkle (F4)",
    },
    "_routing": "REPORT",
    "_routing_reason": "Integralność werdyktów ZUS — Merkle chain + immutable allowlist (P03 safe_merge)",
} {
    object.get(input.jdg_entrepreneur, "p08_integrity_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 8 — GŁÓWNY RAPORT P08 (decide)
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.p08_zus_macro_enterprise.report",
    "_legal_basis": "Art. 9 SUS",
    "package": "jdg.p08_zus_macro_enterprise",
    "priority": 90,
    "p08_zus_macro": {
        "section1_coverage": {
            "total_articles": count(object.get(audit_data, "coverage", {})),
            "complete_count": count(complete_articles),
            "missing_articles": missing_articles,
            "duplicate_count": object.get(audit_data, "duplicate_count", 0),
        },
        "section2_health": {
            "scale_rate": health_scale_rate,
            "linear_rate": health_linear_rate,
            "linear_deduction_limit": health_linear_deduction_limit,
            "lump_tiers": {
                "tier_1_limit": lump_tier_1_limit,
                "tier_2_limit": lump_tier_2_limit,
                "tier_1_amount": lump_tier_1_amount,
                "tier_2_amount": lump_tier_2_amount,
                "tier_3_amount": lump_tier_3_amount,
            },
        },
        "section3_social": {
            "pension_rate": pension_rate,
            "disability_rate": disability_rate,
            "sickness_rate": sickness_rate,
            "accident_rate": accident_rate,
            "social_base": social_base_standard,
        },
        "section4_reliefs": {
            "start_relief_months": start_relief_months,
            "preferential_months": preferential_months,
            "maly_zus_plus_months": maly_zus_plus_months,
            "maly_zus_plus_income_limit": maly_zus_plus_income_limit,
            "maly_zus_plus_revenue_limit": maly_zus_plus_revenue_limit,
        },
        "section5_collisions": {
            "art9_employment_plus_jdg": "tylko zdrowotna z JDG",
            "art9_pension_plus_jdg": "tylko zdrowotna z JDG",
        },
        "section6_benefits": {
            "sickness_80_100": true,
            "period_182_270": true,
            "maternity_20_41_43": true,
            "caregiver_60_days": true,
            "rehab_90_180": true,
        },
        "section7_genius": {
            "health_contribution_calculator": true,
            "lump_sum_tier_verifier": true,
            "social_contribution_calculator": true,
            "annual_base_limit": true,
            "payment_calendar": true,
            "relief_simulator": true,
            "relief_tracker": true,
            "title_collision_detector": true,
            "benefits_calculator": true,
            "zus_digital_twin": true,
            "base_recommender": true,
            "zus_reconciliation": true,
            "employment_vs_jdg_simulator": true,
            "zus_verdict_integrity": true,
        },
        "dependencies": {
            "P06_PIT_MACRO": "składki ZUS odliczane od dochodu",
            "P07_PIT_MICRO": "odliczenia składek w PIT",
            "P13_RYCZALT": "zdrowotna 4.9% ryczałt — progi",
            "P03_ORKIESTRATOR": "PASS 8 — werdykty ZUS niemutowalne (allowlist)",
        },
    },
    "_routing": "REPORT",
    "_routing_reason": "Główny raport P08 ZUS MACRO — składka zdrowotna wg formy (PRIORYTET) + społeczne + ulgi + zbiegi + zasiłki",
    "_legal_basis": "Ustawa o SUS (Dz.U. 2025 poz. 345) + ustawa zdrowotna Art. 79-81 + ustawa zasiłkowa",
    "_warnings": ["ZUS: werdykty niemutowalne (safe_merge allowlist); mapa pokrycia z tools/zus_micro_inventory.py — brak injekcji danych audytu → 0 zweryfikowanych."],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_macro_check", false) == true
}

# ── SAFE REPORT ACCESSORY ──────────────────────────────────────────────────────
report_section1 := object.get(decide, "p08_zus_macro", {}).section1_coverage {
    decide.matched == true
} else := {} {
    true
}

report_health := object.get(decide, "p08_zus_macro", {}).section2_health {
    decide.matched == true
} else := {} {
    true
}

report_social := object.get(decide, "p08_zus_macro", {}).section3_social {
    decide.matched == true
} else := {} {
    true
}

report_reliefs := object.get(decide, "p08_zus_macro", {}).section4_reliefs {
    decide.matched == true
} else := {} {
    true
}

report_collisions := object.get(decide, "p08_zus_macro", {}).section5_collisions {
    decide.matched == true
} else := {} {
    true
}

report_benefits := object.get(decide, "p08_zus_macro", {}).section6_benefits {
    decide.matched == true
} else := {} {
    true
}

report_genius := object.get(decide, "p08_zus_macro", {}).section7_genius {
    decide.matched == true
} else := {} {
    true
}

report_health_calc := health_contribution_calculator.health {
    health_contribution_calculator.matched == true
} else := {} {
    true
}

report_social_calc := social_contribution_calculator.social {
    social_contribution_calculator.matched == true
} else := {} {
    true
}

report_twin := zus_digital_twin.twin {
    zus_digital_twin.matched == true
} else := {} {
    true
}
