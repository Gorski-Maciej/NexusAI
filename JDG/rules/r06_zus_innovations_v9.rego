# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R06 GLM52 ZUS/SUS — INNOWACJE
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.r06_zus_innovations
# Raport: RAPORT_06_ZUS.txt (Kampania GLM 5.2 — seria 06/25)
#
# Prompt 06/25 (ZUS/SUS — składki, ulgi (start/preferencyjny/Mały ZUS+),
# zdrowotna, zasiłki, PPK/PFRON, HR) — ulepszenia, poziom ENTERPRISE:
#   R06-INN-01 health_whatif_4form — kalkulator optymalnej składki zdrowotnej
#                                     4-formowy z symulacją „co by było gdyby":
#                                     skala 9% od dochodu, liniowy 4,9% od
#                                     dochodu (limit odliczenia), ryczałt 4,9%
#                                     z 3 progami podstawy (60%/100%/180%
#                                     przeciętnego), karta podatkowa 9% od
#                                     minimalnego (P07 miał tylko 1-formowy
#                                     health_form_change_simulator)
#   R06-INN-02 zus_relief_tracker — automatyczny tracker ulg ZUS z alarmami
#                                     terminów: ulga na start (art. 18a — 6
#                                     mies.), preferencyjny (art. 18c — 24
#                                     mies.), Mały ZUS+ (art. 18c — 36 mies.,
#                                     30% minimalnego) — pozostałe miesiące,
#                                     status, alarmy (insurance_tracker
#                                     dotyczył tylko OC zawodowego)
#   R06-INN-03 sus_a6a — domknięcie pustyni pokrycia (zus_micro_inventory:
#                                     art. 6a MISSING): obowiązkowe ubezpie-
#                                     czenia emerytalne/rentowe rodzica
#                                     sprawującego osobistą opiekę nad dzieckiem
#
# Zgodność: ADR-001..009/017/022, u. o SUS (Dz.U. 2025 poz. 345) Art. 6a, 18a,
#           18c; u. o świadczeniach opieki zdrowotnej (Dz.U. 2025 poz. 890)
#           art. 81; rozp. MPiPS ws. podstawy wymiaru składek (2025-12-30);
#           thresholds.zus (zero hardcode); INV-018; First-Match-Wins.
# package: jdg.r06_zus_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r06_zus_innovations

import future.keywords.if
import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.r06_zus_innovations.no_match", "package": "jdg.r06_zus_innovations", "priority": 999999}

# ── Progi zewnętrzne (ADR-002 — zero hardcode) ────────────────────────────────
_th := object.get(data, "jdg", {})
_zus_th := object.get(_th, "thresholds", {})
_th_zus := object.get(_zus_th, "zus", {})

health_scale_rate := object.get(_th_zus, "health_scale_rate", 0.09)      # 9% skala
health_linear_rate := object.get(_th_zus, "health_linear_rate", 0.049)   # 4,9% liniowy
health_lump_rate := object.get(_th_zus, "health_lump_rate", 0.049)       # 4,9% ryczałt
health_card_rate := object.get(_th_zus, "health_card_rate", 0.09)        # 9% karta (od minimalnego)
health_linear_deduction_limit := object.get(_th_zus, "health_linear_deduction_limit", 14100)  # limit odliczenia liniowy/rok
lump_base_multipliers := object.get(_th_zus, "lump_health_base_multipliers", [0.6, 1.0, 1.8])  # progi 60/100/180%
lump_revenue_thresholds := object.get(_th_zus, "lump_health_revenue_thresholds", [60000, 300000])  # progi przychodów

average_wage := object.get(_th_zus, "average_wage_monthly", 8673.58)     # przeciętne wynagrodzenie (podstawa ryczałt)
minimum_wage := object.get(_th_zus, "minimum_wage_gross", 4666)          # minimalne 2026

ulga_start_months := object.get(_th_zus, "ulga_start_months", 6)
preferential_months := object.get(_th_zus, "preferential_months", 24)
maly_zus_months := object.get(_th_zus, "maly_zus_plus_months", 36)
maly_zus_base_rate := object.get(_th_zus, "maly_zus_plus_base_rate", 0.30)

# ═══════════════════════════════════════════════════════════════════════════════
# R06-INN-01: HEALTH WHAT-IF 4-FORM — kalkulator optymalnej składki zdrowotnej
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza health_whatif: {annual_income, annual_revenue, card_base}.
# Porównanie ROCZNEJ składki zdrowotnej wg formy (Polski Ład):
#   skala   — 9% od dochodu (częściowo odliczana od podatku)
#   liniowy — 4,9% od dochodu, odliczenie od dochodu do limitu/rok
#   ryczałt — 4,9% od podstawy wg 3 progów przychodów (60/100/180% przeciętnego)
#   karta   — 9% od minimalnego wynagrodzenia
hw_input := object.get(input, "health_whatif", {})

hw_annual_income := max([0, object.get(hw_input, "annual_income", 0)])
hw_annual_revenue := max([0, object.get(hw_input, "annual_revenue", 0)])
hw_card_base := max([0, object.get(hw_input, "card_base", minimum_wage)])

# ── Ryczałt: progi podstawy wg przychodów (60/100/180% przeciętnego) ───────────
lump_base_multiplier := 0.6 {
    hw_annual_revenue <= lump_revenue_thresholds[0]
} else := 1.8 {
    hw_annual_revenue > lump_revenue_thresholds[1]
} else := 1.0 {
    hw_annual_revenue > lump_revenue_thresholds[0]
    hw_annual_revenue <= lump_revenue_thresholds[1]
}

hw_scale := hw_annual_income * health_scale_rate
hw_linear := hw_annual_income * health_linear_rate
hw_lump := average_wage * lump_base_multiplier * health_lump_rate * 12
hw_card := hw_card_base * health_card_rate * 12

hw_best_form := "SCALE" {
    hw_scale <= hw_linear
    hw_scale <= hw_lump
    hw_scale <= hw_card
} else := "LINEAR" {
    hw_linear <= hw_lump
    hw_linear <= hw_card
} else := "LUMP_SUM" {
    hw_lump <= hw_card
} else := "CARD" {
    true
}

health_whatif_4form := {
    "matched": true,
    "rule_id": "jdg.r06_zus_innovations.health_whatif_4form",
    "package": "jdg.r06_zus_innovations",
    "priority": 310,
    "whatif": {
        "annual_income": hw_annual_income,
        "annual_revenue": hw_annual_revenue,
        "scale_annual": hw_scale,
        "linear_annual": hw_linear,
        "lump_annual": hw_lump,
        "lump_base_multiplier": lump_base_multiplier,
        "card_annual": hw_card,
        "best_form": hw_best_form,
        "linear_deduction_limit": health_linear_deduction_limit,
        "note": "Porównanie 4-formowe rocznej składki zdrowotnej (skala 9% / liniowy 4,9% / ryczałt 4,9% z progami / karta 9%) — rekomendacja, nigdy decyzja",
    },
    "_routing": "REPORT",
    "_routing_reason": sprintf("Składka zdrowotna 4-formy: skala=%.0f | liniowy=%.0f | ryczałt=%.0f | karta=%.0f → min: %s", [hw_scale, hw_linear, hw_lump, hw_card, hw_best_form]),
    "_legal_basis": "Art. 81 ustawy o świadczeniach opieki zdrowotnej (Dz.U. 2025 poz. 890) + rozp. MPiPS ws. podstawy wymiaru (2025-12-30)",
    "_warnings": ["Wynik szacunkowy; liniowy 4,9% z odliczeniem do limitu od 2022; ryczałt z podstawą zależną od przychodów — decyzja wymaga pełnej kalkulacji PIT+ZUS."],
} {
    object.get(input.jdg_entrepreneur, "r06_health_whatif_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# R06-INN-02: ZUS RELIEF TRACKER — tracker ulg z alarmami terminów
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza zus_relief_tracker: {months_since_start, relief_type}.
# Typy: ULGA_START (art. 18a — 6 mies., 0 składek społecznych),
#       PREFERENCYJNY (art. 18c — 24 mies., 30% minimalnego),
#       MALY_ZUS_PLUS (art. 18c — 36 mies., 30% minimalnego).
# Wynik: pozostałe miesiące, status (ACTIVE/EXPIRING/EXPIRED), alarmy.
rt_input := object.get(input, "zus_relief_tracker", {})

rt_months := max([0, object.get(rt_input, "months_since_start", 0)])
rt_type := object.get(rt_input, "relief_type", "")

rt_max_months := ulga_start_months {
    rt_type == "ULGA_START"
} else := preferential_months {
    rt_type == "PREFERENCYJNY"
} else := maly_zus_months {
    rt_type == "MALY_ZUS_PLUS"
} else := 0 {
    true
}

rt_remaining := max([0, rt_max_months - rt_months])

rt_status := "ACTIVE" {
    rt_remaining > 2
} else := "EXPIRING" {
    rt_remaining > 0
} else := "EXPIRED" {
    true
}

rt_alarms := [alarm |
    rt_remaining > 0
    rt_remaining <= 2
    alarm := sprintf("Uwaga: ulga %s wygasa za %d mies. — przygotuj pełne składki", [rt_type, rt_remaining])
] | [alarm |
    rt_remaining == 0
    rt_type != ""
    alarm := sprintf("Ulga %s WYGASŁA — obowiązują pełne składki społeczne", [rt_type])
]

zus_relief_tracker := {
    "matched": true,
    "rule_id": "jdg.r06_zus_innovations.zus_relief_tracker",
    "package": "jdg.r06_zus_innovations",
    "priority": 308,
    "tracker": {
        "relief_type": rt_type,
        "months_since_start": rt_months,
        "max_months": rt_max_months,
        "remaining_months": rt_remaining,
        "status": rt_status,
        "alarms": rt_alarms,
        "note": "Tracker ulg ZUS (art. 18a/18c): ulga na start 6 mies., preferencyjny 24 mies., Mały ZUS+ 36 mies. — alarmy przed wygaśnięciem",
    },
    "_routing": "REPORT",
    "_routing_reason": sprintf("Tracker ulgi %s: %d/%d mies. (%s)", [rt_type, rt_months, rt_max_months, rt_status]),
    "_legal_basis": "Art. 18a i 18c ustawy o SUS (Dz.U. 2025 poz. 345)",
    "_warnings": ["Mały ZUS+ wymaga spełnienia limitu przychodów z poprzedniego roku (thresholds.zus.maly_zus_plus_revenue_limit)."],
} {
    object.get(input.jdg_entrepreneur, "r06_relief_tracker_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# R06-INN-03: SUS A6A — opieka nad dzieckiem (domknięcie pustyni inventory)
# ═══════════════════════════════════════════════════════════════════════════════
# Art. 6a ust. 1-3 u. o SUS: obowiązkowo ubezpieczeniom emerytalnemu i rentowym
# podlegają osoby sprawujące osobistą opiekę nad dzieckiem — prawo przysługuje
# jednemu z rodziców, pod warunkiem że drugi rodzic nie jest objęty
# ubezpieczeniem (ust. 3). Weryfikacja zgodności JDG-owicza (np. okres
# przerwy w działalności).
a6a_input := object.get(input, "sus_a6a", {})

a6a_child_care := object.get(a6a_input, "personal_child_care", false)
a6a_other_parent_insured := object.get(a6a_input, "other_parent_insured", false)

sus_a6a := {
    "matched": true,
    "rule_id": "jdg.r06_zus_innovations.sus_a6a",
    "package": "jdg.r06_zus_innovations",
    "priority": 306,
    "a6a": {
        "personal_child_care": a6a_child_care,
        "other_parent_insured": a6a_other_parent_insured,
        "eligible": a6a_child_care and not a6a_other_parent_insured,
        "note": "Art. 6a: obowiązkowe ubezpieczenia emerytalne/rentowe rodzica sprawującego osobistą opiekę nad dzieckiem (jeden rodzic — drugi nieubezpieczony)",
    },
    "_routing": "REPORT",
    "_routing_reason": sprintf("Art. 6a: opieka nad dzieckiem — %s", [a6a_child_care and not a6a_other_parent_insured && "UPRAWNIONY" || "BRAK UPRAWNIENIA"]),
    "_legal_basis": "Art. 6a ust. 1-3 ustawy o SUS (Dz.U. 2025 poz. 345)",
    "_warnings": ["Domknięcie pustyni pokrycia zus_micro_inventory (art. 6a MISSING)."],
} {
    object.get(input.jdg_entrepreneur, "r06_sus_a6a_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# GŁÓWNA REGUŁA RAPORTU (aktywowana flagą r06_zus_check)
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true,
    "rule_id": "jdg.r06_zus_innovations.zus_report",
    "package": "jdg.r06_zus_innovations",
    "priority": 315,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "valid_from": "2026-01-01", "valid_to": null,
    "zus": {
        "health_whatif": health_whatif_4form.whatif,
        "relief_tracker": zus_relief_tracker.tracker,
        "sus_a6a": sus_a6a.a6a,
    },
    "_routing": "REPORT",
    "_routing_reason": "R06 ZUS: kalkulator składki zdrowotnej 4-formowy, tracker ulg z alarmami, domknięcie art. 6a",
    "_legal_basis": "Ustawa o SUS (Dz.U. 2025 poz. 345) Art. 6a, 18a, 18c + u. zdrowotna (Dz.U. 2025 poz. 890) art. 81",
    "_warnings": ["Raport ZUS — aktywowany wyłącznie flagą r06_zus_check"],
} {
    object.get(input.jdg_entrepreneur, "r06_zus_check", false) == true
}
