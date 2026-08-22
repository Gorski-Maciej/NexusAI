# NexusAI JDG — ETAP 12/29: ZUS Core audit and calculation certificate
# Warstwa audytowa nad istniejącymi jdg.zus, P07/P08 i micro/sus rules.
# Nie zastępuje ich decyzji; ujawnia kompletność danych, wersję progów,
# jednostki, zaokrąglenia, granice i manual review.
package jdg.zus_core_etap12

import future.keywords.if
import future.keywords.in

package_id := "jdg.zus_core_etap12"
decision_mode := "SUGGEST"
rounding_contract := "PLN_HALF_UP_2DP"

thresholds := object.get(object.get(data, "jdg", {}), "thresholds", {})
zus := object.get(thresholds, "zus", {})
bounds := object.get(thresholds, "bounds", {})

# Wszystkie wartości operacyjne pochodzą z data.jdg.thresholds; wartości
# domyślne są tylko bezpiecznym fallbackiem i są ujawniane w snapshot.
health_scale_rate := to_number(object.get(zus, "health_scale_rate", 0.09))
health_linear_rate := to_number(object.get(zus, "health_linear_rate", 0.049))
health_card_rate := to_number(object.get(zus, "health_card_rate", 0.09))
health_linear_limit := to_number(object.get(zus, "health_linear_deduction_limit", 14100))
health_tier_1_limit := to_number(object.get(zus, "health_lump_tier_1_limit", 60000))
health_tier_2_limit := to_number(object.get(zus, "health_lump_tier_2_limit", 300000))
health_tier_1 := to_number(object.get(zus, "health_lump_tier_1_amount", 491.40))
health_tier_2 := to_number(object.get(zus, "health_lump_tier_2_amount", 819.00))
health_tier_3 := to_number(object.get(zus, "health_lump_tier_3_amount", 1474.20))
minimum_wage := to_number(object.get(zus, "minimum_wage_gross", object.get(bounds, "minimum_wage_gross", 4800)))
standard_social_base := to_number(object.get(zus, "social_base_standard", object.get(zus, "social_base_standard_60pct", 5204.40)))
preferential_base_rate := to_number(object.get(zus, "preferential_base_rate", 0.30))
maly_base_rate := to_number(object.get(zus, "maly_zus_plus_base_rate", 0.30))
start_months := to_number(object.get(zus, "start_relief_months", object.get(zus, "ulga_start_months", 6)))
preferential_months := to_number(object.get(zus, "preferential_months", 24))
maly_months := to_number(object.get(zus, "maly_zus_plus_months", 36))
maly_window := to_number(object.get(zus, "maly_zus_plus_months_window", 60))
maly_revenue_limit := to_number(object.get(zus, "maly_zus_plus_revenue_limit", 120000))
waiting_days := to_number(object.get(zus, "sickness_waiting_days_voluntary", object.get(zus, "sickness_waiting_days", 90)))
sickness_rate := to_number(object.get(zus, "sickness_benefit_rate", 0.80))
sickness_special_rate := to_number(object.get(zus, "sickness_rate_special", 1.00))
sickness_max_days := to_number(object.get(zus, "sickness_max_days_standard", 182))
deadline_person := to_number(object.get(zus, "payment_deadline_social", 10))
deadline_employer := to_number(object.get(zus, "payment_deadline_social_employees", 15))

round2(x) = result {
    result := round(x * 100) / 100
}

ent := object.get(input, "jdg_entrepreneur", {})
core := object.get(input, "zus_core", {})
tax_form := object.get(ent, "tax_form", "")
monthly_income := max([0, to_number(object.get(core, "monthly_income", object.get(ent, "monthly_income", 0)))])
annual_revenue := max([0, to_number(object.get(core, "annual_revenue", object.get(ent, "annual_revenue", 0)))])
annual_income := max([0, to_number(object.get(core, "annual_income", object.get(ent, "annual_income", monthly_income * 12)))])

# ── Temporal/data contract ───────────────────────────────────────────────────
evaluation_date := object.get(input, "evaluation_datetime", object.get(core, "evaluation_date", ""))
evaluation_year := object.get(input, "evaluation_year", object.get(core, "evaluation_year", ""))
threshold_version := object.get(input, "threshold_version", object.get(core, "threshold_version", ""))
legal_basis_version := object.get(input, "legal_basis_version", object.get(core, "legal_basis_version", ""))
facts_version := object.get(input, "facts_version", object.get(core, "facts_version", ""))

required_context := ["evaluation_datetime", "evaluation_year", "threshold_version", "legal_basis_version", "facts_version"]
missing_context := [field | field := required_context[_]; object.get(input, field, "") == ""]

uncertainty_markers := [marker |
    marker := object.get(input, "uncertainty_markers", [])[_]
]

# ── Deterministyczne kalkulatory ─────────────────────────────────────────────
health_lump_amount(revenue) = amount {
    revenue <= health_tier_1_limit
    amount := health_tier_1
} else = amount {
    revenue > health_tier_1_limit
    revenue <= health_tier_2_limit
    amount := health_tier_2
} else = amount {
    revenue > health_tier_2_limit
    amount := health_tier_3
}

health_calculations := {
    "skala": {"monthly": round2(monthly_income * health_scale_rate), "annual": round2(monthly_income * 12 * health_scale_rate), "rate": health_scale_rate, "base": "dochód", "unit": "PLN", "rounding": rounding_contract, "legal_basis": "Art. 81 ust. 2 pkt 1 u.ś.o.z."},
    "liniowy": {"monthly": round2(monthly_income * health_linear_rate), "annual": round2(monthly_income * 12 * health_linear_rate), "rate": health_linear_rate, "deduction_limit": health_linear_limit, "base": "dochód", "unit": "PLN", "rounding": rounding_contract, "legal_basis": "Art. 81 ust. 2 pkt 2 u.ś.o.z."},
    "ryczałt": {"monthly": health_lump_amount(annual_revenue), "annual": round2(health_lump_amount(annual_revenue) * 12), "rate": 0.09, "base": "przychód / próg 60k-300k", "unit": "PLN", "rounding": rounding_contract, "legal_basis": "Art. 81 ust. 2 pkt 3 u.ś.o.z."},
    "karta": {"monthly": round2(minimum_wage * health_card_rate), "annual": round2(minimum_wage * health_card_rate * 12), "rate": health_card_rate, "base": "minimalne wynagrodzenie", "unit": "PLN", "rounding": rounding_contract, "legal_basis": "Art. 81 ust. 2za u.ś.o.z."},
}

social_emerytalna := to_number(object.get(zus, "pension_rate", 0.1952))
social_rentowa := to_number(object.get(zus, "disability_rate", 0.08))
social_chorobowa := to_number(object.get(zus, "sickness_voluntary_rate", 0.0245))
social_wypadkowa := to_number(object.get(zus, "accident_rate", 0.0167))

social_sickness_rate(included) = rate {
    included == true
    rate := social_chorobowa
} else = 0 {
    included == false
}

social_calculation(base, sickness_included) = result {
    sick := social_sickness_rate(sickness_included)
    result := {
        "base": round2(base),
        "emerytalna": round2(base * social_emerytalna),
        "rentowa": round2(base * social_rentowa),
        "chorobowa": round2(base * sick),
        "wypadkowa": round2(base * social_wypadkowa),
        "total": round2(base * (social_emerytalna + social_rentowa + sick + social_wypadkowa)),
        "unit": "PLN/month",
        "rounding": rounding_contract,
        "legal_basis": "Art. 18, 22 ustawy o SUS",
    }
}

social_calculations := {
    "standard": social_calculation(standard_social_base, object.get(core, "voluntary_sickness", false)),
    "preferential": social_calculation(round2(minimum_wage * preferential_base_rate), object.get(core, "voluntary_sickness", false)),
    "maly_zus_plus": social_calculation(round2(minimum_wage * maly_base_rate), object.get(core, "voluntary_sickness", false)),
}

# ── Boundary-safe relief phase engine ────────────────────────────────────────
months_since_start := max([0, to_number(object.get(core, "months_since_start", object.get(ent, "months_since_start", 0)))])
relief_phase := "ulga_na_start" {
    months_since_start < start_months
} else := "preferencyjny" {
    months_since_start >= start_months
    months_since_start < start_months + preferential_months
} else := "maly_zus_plus_or_standard" {
    months_since_start >= start_months + preferential_months
    months_since_start < start_months + preferential_months + maly_months
} else := "standard" {
    months_since_start >= start_months + preferential_months + maly_months
}

relief_boundary_tests := [
    {"name": "start_before_end", "input_month": start_months - 1, "expected": "ulga_na_start"},
    {"name": "start_boundary", "input_month": start_months, "expected": "preferencyjny"},
    {"name": "preferential_boundary", "input_month": start_months + preferential_months, "expected": "maly_zus_plus_or_standard"},
]

relief_audit := {
    "phase": relief_phase,
    "months_since_start": months_since_start,
    "ulga_na_start": {"months": start_months, "social_contributions": 0, "health_still_due": true, "legal_basis": "Art. 18 ust. 1 pkt 2a ustawy o SUS"},
    "preferential": {"months": preferential_months, "base_rate": preferential_base_rate, "legal_basis": "Art. 18a ustawy o SUS"},
    "maly_zus_plus": {"months": maly_months, "window_months": maly_window, "revenue_limit": maly_revenue_limit, "base_rate": maly_base_rate, "eligible_by_revenue": annual_revenue <= maly_revenue_limit, "legal_basis": "Art. 18c ustawy o SUS"},
    "boundary_tests": relief_boundary_tests,
}

# ── Benefits, PPK/PFRON and deadlines ────────────────────────────────────────
benefit_base := max([0, to_number(object.get(core, "benefit_base", 0))])
benefit_days := max([0, to_number(object.get(core, "benefit_days", 1))])
benefit_rate := sickness_rate {
    object.get(core, "special_case", false) == false
} else := sickness_special_rate {
    object.get(core, "special_case", false) == true
}
benefit_calculation := {
    "base": benefit_base,
    "days": benefit_days,
    "daily": round2(benefit_base / 30),
    "rate": benefit_rate,
    "amount": round2(benefit_base / 30 * benefit_rate * benefit_days),
    "waiting_days": waiting_days,
    "eligible_after_waiting": to_number(object.get(core, "insured_days", 0)) >= waiting_days,
    "max_days": sickness_max_days,
    "unit": "PLN",
    "rounding": rounding_contract,
    "legal_basis": "Art. 4 i 11 ustawy zasiłkowej",
}

employees := to_number(object.get(ent, "employees_count", object.get(core, "employees_count", 0)))
ppk_enabled := object.get(core, "ppk_applicable", employees > 0)
pfron_threshold := to_number(object.get(zus, "pfron_employees_threshold", 25))
ppk_pfron_audit := {
    "ppk_applicable": ppk_enabled,
    "pfron_applicable": employees >= pfron_threshold,
    "employees": employees,
    "pfron_threshold": pfron_threshold,
    "funds_require_manual_review": true,
    "legal_basis": "Ustawa o PPK; art. 21 ustawy o rehabilitacji",
}

payment_deadline := deadline_person {
    employees == 0
} else := deadline_employer {
    employees > 0
}
deadline_audit := {
    "payment_day": payment_deadline,
    "basis": "10. dzień JDG bez pracowników / 15. dzień z ubezpieczonymi",
    "unit": "calendar_day",
    "legal_basis": "Art. 47 ust. 1 ustawy o SUS",
}

# ── Cross-domain and fail-closed gates ───────────────────────────────────────
collisions := array.concat(
    object.get(input, "pit_conflicts", []),
    array.concat(object.get(input, "vat_conflicts", []), object.get(input, "uor_conflicts", []))
)
required_numeric_data := [monthly_income, annual_revenue, standard_social_base]
negative_numeric_data := [value | value := required_numeric_data[_]; value < 0]
manual_review := count(missing_context) > 0 or count(uncertainty_markers) > 0 or count(collisions) > 0 or count(negative_numeric_data) > 0
routing := "BLOCK_AND_ALERT" {
    count(missing_context) > 0
} else := "BLOCK_AND_ALERT" {
    count(negative_numeric_data) > 0
} else := "TRIAGE_QUEUE" {
    count(uncertainty_markers) > 0
    count(collisions) > 0
} else := "TRIAGE_QUEUE" {
    count(uncertainty_markers) > 0
} else := "TRIAGE_QUEUE" {
    count(collisions) > 0
} else := "REPORT" {
    true
}

calculation_certificate := {
    "certificate_id": object.get(input, "calculation_id", "UNASSIGNED"),
    "evaluation_date": evaluation_date,
    "evaluation_year": evaluation_year,
    "threshold_version": threshold_version,
    "legal_basis_version": legal_basis_version,
    "facts_version": facts_version,
    "rounding": rounding_contract,
    "currency": "PLN",
    "units": {"health": "PLN/month", "social": "PLN/month", "benefit": "PLN"},
    "source": "data.jdg.thresholds.zus + input.zus_core",
    "manual_review": manual_review,
    "missing_context": missing_context,
    "uncertainty_markers": uncertainty_markers,
    "cross_domain_collisions": collisions,
    "boundary_tests": relief_boundary_tests,
}

health_minimum := round2(minimum_wage * health_scale_rate)

# Publiczny wynik aktywowany osobną flagą — brak flagi pozostaje no_match.
default decide := {"matched": false, "rule_id": "jdg.zus_core_etap12.no_match", "package": package_id, "priority": 999999}

decide := {
    "matched": true,
    "rule_id": "jdg.zus_core_etap12.report",
    "package": package_id,
    "priority": 560,
    "decision_mode": decision_mode,
    "no_auto_post": true,
    "routing": routing,
    "manual_review": manual_review,
    "health": {"forms": health_calculations, "minimum_monthly": health_minimum, "inputs": {"tax_form": tax_form, "monthly_income": monthly_income, "annual_revenue": annual_revenue}},
    "social": {"calculations": social_calculations, "rates": {"emerytalna": social_emerytalna, "rentowa": social_rentowa, "chorobowa": social_chorobowa, "wypadkowa": social_wypadkowa}},
    "reliefs": relief_audit,
    "benefits": benefit_calculation,
    "ppk_pfron": ppk_pfron_audit,
    "deadlines": deadline_audit,
    "calculation_certificate": calculation_certificate,
    "threshold_snapshot": {"minimum_wage": minimum_wage, "standard_social_base": standard_social_base, "health_linear_limit": health_linear_limit, "start_months": start_months, "preferential_months": preferential_months, "maly_months": maly_months, "maly_window": maly_window, "evaluation_year": evaluation_year},
    "_routing": routing,
    "_routing_reason": "ETAP 12 ZUS Core: obliczenia, ulgi, świadczenia, terminy i manual gate",
    "_legal_basis": "Ustawa o SUS art. 6-22/47; u.ś.o.z. art. 81; ustawa zasiłkowa art. 4/11; ustawa o PPK; ustawa o rehabilitacji",
    "_warnings": ["SUGGEST only; brak kompletu danych lub konflikt PIT/VAT/UoR blokuje automatyzację."],
} {
    object.get(input, "zus_core_etap12_check", false) == true
}
