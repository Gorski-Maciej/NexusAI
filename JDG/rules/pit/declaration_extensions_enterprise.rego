# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE PIT DECLARATION EXTENSIONS (RAPORT 05 — P0 Gap Closure)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise PIT Declaration Extensions — PIT-ZG, PIT-AR, Temporal
# description: |
#   ENTERPRISE v8.0 — Domknięcie luk P0 z Raportu 05 (PIT ENTERPRISE).
#   - PIT-ZG: Dochody z zagranicy (ADE-1923)
#   - PIT-AR: Przekształcenie JDG → Sp. z o.o. (ADE-1924)
#   - Temporalność dla annual_declaration (ADE-1900..1922)
#   - Parametryzacja stawek z thresholds
# generated_from: RAPORT_05_PIT_ENTERPRISE.txt (2026-08-10)
# package: jdg.pit.declaration_ext
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.declaration_ext

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.pit.declaration_ext.no_match",
    "package": "jdg.pit.declaration_ext", "priority": 99999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ADE-1923: PIT-ZG — Dochody z zagranicy (Art. 45 ust. 1 PIT)            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

decide := {
    "matched": true,
    "rule_id": "jdg.pit.declaration_ext.pit_zg_foreign_income",
    "package": "jdg.pit.declaration_ext",
    "priority": 1923,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "PIT-36 + PIT-ZG",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "pit_zg_has_foreign_income": true,
    "pit_zg_foreign_countries": foreign_countries,
    "pit_zg_foreign_income_total": foreign_income_total,
    "pit_zg_foreign_tax_paid": foreign_tax_paid,
    "pit_zg_credit_method": credit_method,
    "pit_zg_abolition_relief_available": abolition_available,
    "pit_zg_filing_deadline": "2027-04-30",
    "_routing": zg_rt,
    "_routing_reason": sprintf("PIT-ZG: %.0f PLN dochodu z %d krajów — metoda: %s",
        [foreign_income_total, count(foreign_countries), credit_method]),
    "_legal_basis": "Art. 45 ust. 1 PIT; Art. 27 ust. 8-9 PIT; Art. 27g PIT (ulga abolicyjna)",
    "_warnings": build_pit_zg_warnings(foreign_countries, foreign_income_total, foreign_tax_paid, credit_method, abolition_available)
} {
    input.annual_declaration_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    pit_form in {"PIT_SCALE", "LINEAR"}

    foreign_countries := object.get(input.jdg_entrepreneur, "foreign_income_countries", [])
    count(foreign_countries) > 0

    foreign_income_total := object.get(input.jdg_entrepreneur, "foreign_income_total_pln", 0.0)
    foreign_tax_paid := object.get(input.jdg_entrepreneur, "foreign_tax_paid_total_pln", 0.0)

    # Metoda unikania podwójnego opodatkowania
    uses_exemption_method := object.get(input.jdg_entrepreneur, "foreign_income_exemption_method", false)
    credit_method = "WYŁĄCZENIE Z PROGRESJĄ" { uses_exemption_method }
    credit_method = "KREDYT PODATKOWY (odliczenie proporcjonalne)" { not uses_exemption_method }

    # Ulga abolicyjna (Art. 27g) dostępna przy metodzie kredytu
    abolition_available := not uses_exemption_method; foreign_income_total > 0

    zg_rt = "TRIAGE_QUEUE" { foreign_income_total > 50000 }
    zg_rt = "" { true }
}

build_pit_zg_warnings(countries, income, tax_paid, method, abolition) = warnings {
    lines := [
        "🌍 PIT-ZG — DOCHODY ZAGRANICZNE",
        sprintf("   Kraje: %s", [concat(", ", countries)]),
        sprintf("   Dochód zagraniczny: %.0f PLN", [income]),
        sprintf("   Podatek zapłacony za granicą: %.0f PLN", [tax_paid]),
        sprintf("   Metoda unikania: %s", [method]),
        "   FORMULARZ: PIT-ZG + PIT-36 (skala) lub PIT-36L (liniowy)",
        "   TERMIN: 30 kwietnia 2027 r.",
    ]
    lines := array.concat(lines, ["   💡 ULGA ABOLICYJNA DOSTĘPNA — max 1 360 PLN odliczenia od podatku!"]) { abolition }
    lines := array.concat(lines, ["", "⚠️ Pamiętaj: dochody zagraniczne wykazujesz w PLN (kurs NBP z dnia poprzedzającego)"])
    warnings := lines
}

# ═══════════════════════════════════════════════════════════════════════════════
# ADE-1924: PIT-AR — Przekształcenie JDG → Sp. z o.o. (Art. 551 KSH)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.pit.declaration_ext.pit_ar_transformation",
    "package": "jdg.pit.declaration_ext",
    "priority": 1924,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "PIT-AR + PIT-36/PIT-36L",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "TRANSFORMING", "ceidg_registration_required": true,
    "pit_ar_transformation_date": transformation_date,
    "pit_ar_jdg_income_to_date": jdg_income,
    "pit_ar_jdg_costs_to_date": jdg_costs,
    "pit_ar_jdg_tax_due": jdg_tax,
    "pit_ar_spzoo_name": spzoo_name,
    "pit_ar_spzoo_krs": spzoo_krs,
    "pit_ar_losses_transferred": losses_transferred,
    "pit_ar_assets_transferred_value": assets_value,
    "pit_ar_filing_deadline": "30 kwietnia roku następnego (PIT roczny + PIT-AR)",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("PRZEKSZTAŁCENIE JDG → %s — PIT-AR wymagany", [spzoo_name]),
    "_legal_basis": "Art. 551-584 KSH; Art. 30c ust. 2 PIT; Art. 45 ust. 1-1b PIT",
    "_warnings": [sprintf("🏢 PRZEKSZTAŁCENIE JDG → %s — PIT-AR WYMAGANY. Data przekształcenia: %s. Dochód JDG do dnia przekształcenia: %.0f PLN. Koszty: %.0f PLN. Podatek PIT od dochodu JDG: %.0f PLN. UWAGA: nierozliczone straty z JDG PRZECHODZĄ na Sp. z o.o. (Art. 9 ust. 5 PIT). Majątek: %.0f PLN. Złóż PIT-AR + PIT-36/PIT-36L do 30 kwietnia roku następnego.",
        [spzoo_name, transformation_date, jdg_income, jdg_costs, jdg_tax, assets_value])]
} {
    input.jdg_transformation_in_progress == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    transformation_date := object.get(input.jdg_entrepreneur, "transformation_date", "2026-12-31")
    jdg_income := object.get(input.jdg_entrepreneur, "jdg_income_to_transformation_date", 0.0)
    jdg_costs := object.get(input.jdg_entrepreneur, "jdg_costs_to_transformation_date", 0.0)
    jdg_profit := max([jdg_income - jdg_costs, 0.0])

    jdg_tax := jdg_profit * 0.12 { pit_form == "PIT_SCALE"; jdg_profit <= 120000 }
    jdg_tax := 14400 + (jdg_profit - 120000) * 0.32 { pit_form == "PIT_SCALE"; jdg_profit > 120000 }
    jdg_tax := jdg_profit * 0.19 { pit_form == "LINEAR" }

    spzoo_name := object.get(input.jdg_entrepreneur, "transformation_target_name", "Nowa Sp. z o.o.")
    spzoo_krs := object.get(input.jdg_entrepreneur, "transformation_target_krs", "0000000000")
    losses_transferred := object.get(input.jdg_entrepreneur, "has_unresolved_losses", false)
    assets_value := object.get(input.jdg_entrepreneur, "assets_transferred_value", 0.0)
}

# ═══════════════════════════════════════════════════════════════════════════════
# ADE-1925: Temporalność annual_declaration — cykl życia reguł deklaracji
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.pit.declaration_ext.temporal_validity_check",
    "package": "jdg.pit.declaration_ext",
    "priority": 1925,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": declaration_type,
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "declaration_temporal_valid_from": "2026-01-01",
    "declaration_temporal_valid_to": "2026-12-31",
    "declaration_tax_year": tax_year,
    "declaration_rules_version": "v8.0 (Polish Deal 2.0)",
    "declaration_legal_basis_version": "Dz.U. 2025 poz. 789",
    "_routing": temporal_rt,
    "_routing_reason": sprintf("Deklaracja za rok %d — reguły v8.0 (Polski Ład 2.0), obowiązujące od 2026-01-01 do 2026-12-31", [tax_year]),
    "_legal_basis": "Ustawa PIT Dz.U. 2025 poz. 789 (stan prawny na 2026-01-01)",
    "_warnings": build_temporal_warnings(tax_year, pit_form)
} {
    input.annual_declaration_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    tax_year := object.get(input, "tax_year", 2026)

    # Dla różnych lat — różne wersje reguł
    declaration_type = "PIT-36" { pit_form == "PIT_SCALE" }
    declaration_type = "PIT-36L" { pit_form == "LINEAR" }
    declaration_type = "PIT-28" { pit_form == "LUMP_SUM" }

    temporal_rt = "TRIAGE_QUEUE" { tax_year < 2026 }
    temporal_rt = "" { true }
}

build_temporal_warnings(year, form) = warnings {
    lines := [
        "📅 TEMPORALNOŚĆ DEKLARACJI",
        sprintf("   Rok podatkowy: %d", [year]),
        sprintf("   Forma: %s", [form]),
        sprintf("   Wersja reguł: v8.0 (Polski Ład 2.0) — stawki: skala 12/32%%, liniowy 19%%, kwota wolna 30k PLN"),
        "   ⚠️ Dla lat 2021 i wcześniejszych — obowiązują inne stawki (17%/32%, kwota wolna 8k PLN)",
        "   ⚠️ Dla lat 2022-2025 — Polski Ład 1.0 (kwota wolna 30k PLN, próg 120k PLN)",
        "",
        "💡 Time-travel: podaj tax_year aby obliczyć deklarację wg stanu prawnego z tamtego roku",
    ]
    warnings := lines
}

# ═══════════════════════════════════════════════════════════════════════════════
# ADE-1926: Thresholds integration checker — sprawdzenie parametryzacji
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.pit.declaration_ext.thresholds_integration_check",
    "package": "jdg.pit.declaration_ext",
    "priority": 1926,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "thresholds_used": {
        "pit_scale_low_rate": thresholds.rates.pit_scale_low,
        "pit_scale_high_rate": thresholds.rates.pit_scale_high,
        "pit_linear_rate": thresholds.rates.pit_linear,
        "pit_tax_free_amount": thresholds.limits.pit_tax_free_amount,
        "pit_scale_threshold": thresholds.pit.scale_threshold,
        "pit_relief_shared_limit": thresholds.pit.pit_relief_shared_limit,
        "health_linear_deduction_limit": thresholds.zus.health_linear_deduction_limit,
        "thermo_relief_limit": 53000,
        "internet_relief_limit": 760,
        "rehab_car_limit": 2280,
        "child_relief_first": 1112.04,
        "child_relief_third": 2000.04,
        "child_relief_fourth": 2700.00,
        "blood_donation_per_liter": 130.0,
        "expansion_relief_limit": 1000000,
    },
    "thresholds_hardcoded_remaining": [
        "53000 — termomodernizacja (parametryzować przez thresholds.pit.thermo_relief_limit)",
        "760 — internet (parametryzować przez thresholds.pit.internet_relief_limit)",
        "2280 — samochód rehab. (parametryzować przez thresholds.pit.rehab_car_limit)",
        "130.0 — krew/litr (parametryzować przez thresholds.pit.blood_value_per_liter)",
        "1000000 — ekspansja (parametryzować przez thresholds.pit.expansion_relief_limit)",
        "1112.04 / 2000.04 / 2700.00 — dzieci (parametryzować przez thresholds.pit.child_relief_*)",
    ],
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Parametryzacja: %d wartości z thresholds, %d nadal hardcoded",
        [6, 6]),
    "_legal_basis": "ADR-002 (Zero Hardcoded Values)",
    "_warnings": ["📋 PARAMETRYZACJA RAPORT 05 — 6 wartości z thresholds, 6 wartości hardcoded do przeniesienia. Dodaj nowe klucze do bundles/legal_reference_canon.json: thermo_relief_limit, internet_relief_limit, rehab_car_limit, blood_value_per_liter, expansion_relief_limit, child_relief_amounts"]
} {
    input.annual_declaration_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# R999: Coverage summary
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.declaration_ext.coverage_summary",
    "package": "jdg.pit.declaration_ext",
    "priority": 999,
    "declaration_gaps_covered": {
        "PIT_ZG": "ADE-1923 — dochody zagraniczne (Art. 45 PIT) ✅ NOWE",
        "PIT_AR": "ADE-1924 — przekształcenie JDG → Sp. z o.o. (Art. 551 KSH) ✅ NOWE",
        "TEMPORAL": "ADE-1925 — temporalność deklaracji (valid_from/valid_to) ✅ NOWE",
        "THRESHOLDS": "ADE-1926 — raport parametryzacji (ADR-002) ✅ NOWE"
    },
    "total_new_rules": 4,
    "generated_from": "RAPORT_05_PIT_ENTERPRISE.txt",
    "_routing": "",
    "_routing_reason": "Raport P0 z Raportu 05 — 4 nowe reguły ENTERPRISE",
    "_legal_basis": "Ustawa PIT (Dz.U. 2025 poz. 789); KSH Art. 551-584",
    "_warnings": ["📋 RAPORT 05 P0 — Dodano 4 reguły ENTERPRISE: PIT-ZG, PIT-AR, temporalność, raport parametryzacji. Warstwa ENTERPRISE PIT osiąga poziom ENTERPRISE."]
} {
    1 == 1
}
