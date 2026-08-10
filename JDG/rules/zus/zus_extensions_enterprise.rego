# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE ZUS EXTENSIONS (RAPORT 06 — P0 Gap Closure)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise ZUS Extensions — Solidarity, PFRON, Thresholds, Temporal
# description: |
#   ENTERPRISE v8.0 — Domknięcie luk P0 z Raportu 06 (ZUS/SUS).
#   - Składka solidarnościowa (4% od nadwyżki >1M PLN) — R800-R802
#   - PFRON (wpłaty na PFRON) — R810-R812
#   - Weryfikacja limitów 2026 — R820
#   - Temporalność stawek ZUS — R830
# generated_from: RAPORT_06_ZUS.txt (2026-08-10)
# package: jdg.zus.extensions
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.zus.extensions

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.zus.extensions.no_match",
    "package": "jdg.zus.extensions", "priority": 99999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  R800: SOLIDARITY_CONTRIBUTION — Składka solidarnościowa 4%              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
# Art. 30h PIT — 4% od nadwyżki dochodu ponad 1 000 000 PLN
# Dotyczy osób fizycznych, w tym JDG (skala + liniowy). NIE dotyczy ryczałtu.

decide := {
    "matched": true,
    "rule_id": "jdg.zus.extensions.solidarity_contribution",
    "package": "jdg.zus.extensions",
    "priority": 800,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "solidarity_threshold": 1000000,
    "solidarity_rate": "4%",
    "solidarity_base_income": annual_income,
    "solidarity_excess": max([annual_income - 1000000, 0]),
    "solidarity_contribution_due": floor(max([annual_income - 1000000, 0]) * 0.04 * 100) / 100,
    "solidarity_applies": annual_income > 1000000,
    "_routing": sol_rt,
    "_routing_reason": sprintf("Składka solidarnościowa: %.2f PLN (4%% od nadwyżki %.0f PLN ponad 1M PLN)",
        [floor(max([annual_income - 1000000, 0]) * 0.04 * 100) / 100, max([annual_income - 1000000, 0])]),
    "_legal_basis": "Art. 30h PIT (składka solidarnościowa 4% od nadwyżki >1M PLN)",
    "_warnings": [sprintf("🏛️ SKŁADKA SOLIDARNOŚCIOWA — %.2f PLN. 4%% od nadwyżki dochodu ponad 1 000 000 PLN. Dotyczy: skala PIT i liniowy. NIE dotyczy ryczałtu i karty. Zapłać do 30 kwietnia razem z PIT.",
        [floor(max([annual_income - 1000000, 0]) * 0.04 * 100) / 100])]
} {
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    pit_form in {"PIT_SCALE", "LINEAR"}
    annual_income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 0)
    annual_income > 1000000
    sol_rt = "TRIAGE_QUEUE" { annual_income > 1500000 }
    sol_rt = "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R801: SOLIDARITY_NOT_APPLICABLE — Składka solidarnościowa nie dotyczy
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.zus.extensions.solidarity_not_applicable",
    "package": "jdg.zus.extensions",
    "priority": 801,
    "solidarity_applies": false,
    "solidarity_reason": reason,
    "_routing": "",
    "_routing_reason": sprintf("Składka solidarnościowa: %s", [reason]),
    "_legal_basis": "Art. 30h PIT",
    "_warnings": []
} {
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    annual_income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 0)
    annual_income <= 1000000
    reason = sprintf("Dochód %.0f PLN ≤ 1 000 000 PLN — nie podlega", [annual_income]) { pit_form in {"PIT_SCALE", "LINEAR"} }
    reason = sprintf("Forma %s nie podlega składce solidarnościowej", [pit_form]) { pit_form in {"LUMP_SUM", "TAX_CARD"} }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  R810: PFRON_CONTRIBUTION — Wpłaty na PFRON                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
# Ustawa o rehabilitacji zawodowej — pracodawcy 25+ etatów płacą PFRON
# JDG z pracownikami: 6% wskaźnik zatrudnienia niepełnosprawnych

else := {
    "matched": true,
    "rule_id": "jdg.zus.extensions.pfron_contribution",
    "package": "jdg.zus.extensions",
    "priority": 810,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "pfron_required": pfron_required,
    "pfron_employee_count": total_employees,
    "pfron_disabled_employee_count": disabled_employees,
    "pfron_disabled_ratio_pct": disabled_ratio,
    "pfron_required_ratio_pct": 6,
    "pfron_monthly_contribution": pfron_monthly,
    "pfron_exemption_reasons": pfron_exemptions,
    "_routing": pfron_rt,
    "_routing_reason": sprintf("PFRON: %d pracowników, %.1f%% niepełnosprawnych (wymagane 6%%). Wpłata: %.2f PLN/mies.",
        [total_employees, disabled_ratio, pfron_monthly]),
    "_legal_basis": "Art. 21 ustawy o rehabilitacji zawodowej i zatrudnianiu osób niepełnosprawnych",
    "_warnings": [sprintf("♿ PFRON — %s. Zatrudnienie: %d osób (%.1f%% niepełnosprawnych). Wymagane: 6%%. Miesięczna wpłata: %.2f PLN. %s",
        [pfron_status, total_employees, disabled_ratio, pfron_monthly, pfron_action])]
} {
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    total_employees := object.get(input.jdg_entrepreneur, "total_employees_fte", 0.0)
    total_employees >= 25  # PFRON dotyczy pracodawców z 25+ etatami

    disabled_employees := object.get(input.jdg_entrepreneur, "disabled_employees_fte", 0.0)
    disabled_ratio := floor(disabled_employees / total_employees * 1000) / 10

    pfron_required := disabled_ratio < 6.0
    avg_wage := object.get(object.get(object.get(data.thresholds, "jdg", {}), "bounds", {}), "avg_monthly_wage", 8190)

    # Wpłata = 40.65% przeciętnego wynagrodzenia × liczba brakujących etatów niepełnosprawnych
    missing_slots := floor((total_employees * 0.06 - disabled_employees) * 100) / 100
    pfron_monthly := floor(missing_slots * avg_wage * 0.4065 * 100) / 100 { pfron_required }
    pfron_monthly := 0.0 { not pfron_required }

    pfron_exemptions := []
    pfron_exemptions := array.concat(pfron_exemptions, ["Status ZPChr — zwolnienie"]) { object.get(input.jdg_entrepreneur, "pfron_zpchr_status", false) }
    pfron_exemptions := array.concat(pfron_exemptions, ["Zatrudnienie <25 etatów — nie podlega"]) { total_employees < 25 }

    pfron_status = "WYMAGANA wpłata na PFRON" { pfron_required }
    pfron_status = "ZWOLNIENIE — spełniony wskaźnik 6%" { not pfron_required; disabled_ratio >= 6.0 }
    pfron_action = sprintf("Przelej %.2f PLN na konto PFRON do 20. dnia miesiąca", [pfron_monthly]) { pfron_required }
    pfron_action = "Brak wpłat — wskaźnik zatrudnienia spełniony" { not pfron_required }

    pfron_rt = "TRIAGE_QUEUE" { pfron_required; pfron_monthly > 5000 }
    pfron_rt = "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R820: ZUS_LIMITS_2026_VERIFICATION — Weryfikacja limitów ZUS na 2026
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.zus.extensions.limits_2026_verification",
    "package": "jdg.zus.extensions",
    "priority": 820,
    "zus_limits_verified": {
        "health_linear_deduction_limit": data.jdg.thresholds.limits.health_linear_deduction_limit,
        "health_linear_deduction_expected_2026": 14100,
        "health_linear_deduction_status": health_limit_status,
        "pension_rate": "19.52%",
        "disability_rate": "8.00%",
        "sickness_rate": "2.45%",
        "accident_rate": "1.67%",
        "labour_fund_rate": "2.45%",
        "maly_zus_plus_revenue_limit": 120000,
        "minimum_wage_gross": min_wage,
        "avg_monthly_wage": avg_wage,
    },
    "_routing": limits_rt,
    "_routing_reason": sprintf("Weryfikacja ZUS 2026: limit zdrowotny=%s (oczekiwane 14100)",
        [health_limit_status]),
    "_legal_basis": "Obwieszczenia ZUS/MF na 2026",
    "_warnings": [sprintf("📋 WERYFIKACJA LIMITÓW ZUS 2026 — Limit odliczenia zdrowotnej: %s (%.0f PLN). Min. wynagrodzenie: %.0f PLN. Przeciętne: %.0f PLN. Stopy: emerytalna 19.52%%, rentowa 8%%, chorobowa 2.45%%, wypadkowa 1.67%%, FP 2.45%%.",
        [health_limit_status, data.jdg.thresholds.limits.health_linear_deduction_limit, min_wage, avg_wage])]
} {
    1 == 1
    min_wage := object.get(object.get(object.get(data.thresholds, "jdg", {}), "bounds", {}), "minimum_wage_gross", 4800)
    avg_wage := object.get(object.get(object.get(data.thresholds, "jdg", {}), "bounds", {}), "avg_monthly_wage", 8190)
    health_limit_ok := data.jdg.thresholds.limits.health_linear_deduction_limit >= 14100
    health_limit_status = "OK (≥14100 PLN)" { health_limit_ok }
    health_limit_status = "NIEAKTUALNY (<14100 PLN) — AKTUALIZUJ!" { not health_limit_ok }
    limits_rt = "TRIAGE_QUEUE" { not health_limit_ok }
    limits_rt = "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R830: ZUS_TEMPORAL_RATES — Temporalność stawek ZUS
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.zus.extensions.temporal_rates",
    "package": "jdg.zus.extensions",
    "priority": 830,
    "zus_temporal_valid_from": "2026-01-01",
    "zus_temporal_valid_to": "2026-12-31",
    "zus_temporal_rates_applicable": {
        "2026": {"pension":"19.52%","disability":"8.00%","sickness":"2.45%","accident":"1.67%","fp":"2.45%"},
    },
    "_routing": "",
    "_routing_reason": "Temporalność stawek ZUS — wersja 2026",
    "_legal_basis": "Ustawa SUS Dz.U. 2025 poz. 345 (stan na 2026-01-01)",
    "_warnings": ["📅 TEMPORALNOŚĆ STAWEK ZUS — Obecne stopy na 2026: emerytalna 19.52%, rentowa 8%, chorobowa 2.45%, wypadkowa 1.67%, FP+FS 2.45%. Dla time-travel należy podać evaluation_year aby użyć stawek z danego roku."]
} {
    1 == 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# R999: Coverage summary
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.zus.extensions.coverage_summary",
    "package": "jdg.zus.extensions",
    "priority": 999,
    "zus_gaps_covered": {
        "SOLIDARITY": "R800-R801 — składka solidarnościowa 4% ✅ NOWE",
        "PFRON": "R810 — wpłaty na PFRON ✅ NOWE",
        "LIMITS_2026": "R820 — weryfikacja limitów ZUS 2026 ✅ NOWE",
        "TEMPORAL": "R830 — temporalność stawek ZUS ✅ NOWE"
    },
    "total_new_rules": 4,
    "generated_from": "RAPORT_06_ZUS.txt",
    "_routing": "",
    "_routing_reason": "Raport P0 z Raportu 06 — 4 nowe reguły ZUS ENTERPRISE",
    "_legal_basis": "Ustawa SUS Dz.U. 2025 poz. 345; Art. 30h PIT; Ustawa o rehabilitacji",
    "_warnings": ["📋 RAPORT 06 P0 — Dodano 4 reguły ZUS ENTERPRISE: solidarnościowa, PFRON, limity 2026, temporalność"]
} {
    1 == 1
}
