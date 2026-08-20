# NexusAI JDG — ETAP 13/29: ZUS Micro atom map, periods, benefits and property invariants
# Warstwa audytowa nad micro/sus, micro/zdrowotna, micro/zasilkowa oraz P07/P08.
# Nie zastępuje decyzji atomów; buduje mapę ustawa→artykuł→warunek→obliczenie→
# świadectwo→test, analizuje zbiegi/przerwy/zawieszenie, świadczenia chorobowe/
# macierzyńskie/opiekuńcze, podstawy i zaokrąglenia oraz egzekwuje property
# invariants i fail-closed TRIAGE/BLOCK. Żaden brak danych nie daje cichego
# domyślnego wyniku.
package jdg.zus_micro_etap13

import future.keywords.if
import future.keywords.in

package_id := "jdg.zus_micro_etap13"
decision_mode := "SUGGEST"
rounding_contract := "PLN_HALF_UP_2DP"
currency := "PLN"

thresholds := object.get(object.get(data, "jdg", {}), "thresholds", {})
zus := object.get(thresholds, "zus", {})
bounds := object.get(thresholds, "bounds", {})

# ── Wartości operacyjne — wyłącznie z data.jdg.thresholds; fallbacki są jawne ─
minimum_wage := to_number(object.get(zus, "minimum_wage_gross", object.get(bounds, "minimum_wage_gross", 4800)))
sickness_rate := to_number(object.get(zus, "sickness_benefit_rate", 0.80))
sickness_hospital_rate := to_number(object.get(zus, "sickness_hospital_rate", 0.70))
maternity_rate := to_number(object.get(zus, "maternity_benefit_rate", 1.00))
care_rate := to_number(object.get(zus, "care_benefit_rate", 0.80))
waiting_days := to_number(object.get(zus, "sickness_waiting_days_voluntary", object.get(zus, "sickness_waiting_days", 90)))
sickness_max_days := to_number(object.get(zus, "sickness_max_days_standard", 182))
sickness_max_days_tb := to_number(object.get(zus, "sickness_max_days_tb", 270))
maternity_weeks := to_number(object.get(zus, "maternity_weeks_standard", 20))
benefit_payment_days := to_number(object.get(zus, "benefit_payment_deadline_days", 30))
health_scale_rate := to_number(object.get(zus, "health_scale_rate", 0.09))

round2(x) = result {
    result := round(x * 100) / 100
}

# ── Input data contract ───────────────────────────────────────────────────────
ent := object.get(input, "jdg_entrepreneur", {})
micro := object.get(input, "zus_micro", {})
business_status := object.get(ent, "business_status", object.get(micro, "business_status", ""))
tax_form := object.get(ent, "tax_form", "")
monthly_income := max([0, to_number(object.get(micro, "monthly_income", object.get(ent, "monthly_income", 0)))])
annual_revenue := max([0, to_number(object.get(micro, "annual_revenue", object.get(ent, "annual_revenue", 0)))])

# Świadczenia
benefit_type := object.get(micro, "benefit_type", "")
benefit_requested := benefit_type != ""
benefit_base := max([0, to_number(object.get(micro, "benefit_base", 0))])
benefit_days := max([0, to_number(object.get(micro, "benefit_days", 0))])
hospitalization := object.get(micro, "hospitalization", false)
sickness_days_used := max([0, to_number(object.get(micro, "sickness_days_used", 0))])
insured_days := max([0, to_number(object.get(micro, "sickness_insurance_days", 0))])

# ── Temporal / version contract ───────────────────────────────────────────────
evaluation_date := object.get(input, "evaluation_datetime", object.get(micro, "evaluation_date", ""))
evaluation_year := object.get(input, "evaluation_year", object.get(micro, "evaluation_year", ""))
threshold_version := object.get(input, "threshold_version", object.get(micro, "threshold_version", ""))
legal_basis_version := object.get(input, "legal_basis_version", object.get(micro, "legal_basis_version", ""))
facts_version := object.get(input, "facts_version", object.get(micro, "facts_version", ""))

required_context := ["evaluation_datetime", "evaluation_year", "threshold_version", "legal_basis_version", "facts_version"]
missing_context := [field | field := required_context[_]; object.get(input, field, "") == ""]
uncertainty_markers := object.get(input, "uncertainty_markers", [])

# ── MAPA ATOMÓW: ustawa → artykuł → warunek → obliczenie → świadectwo → test ──
atom_map := [
    {"ustawa": "SUS", "artykul": "art. 6", "warunek": "Podleganie obowiązkowo ubezpieczeniom emerytalnemu i rentowym", "obliczenie": "Podstawa wymiaru art. 18", "swiadectwo": "zus_social_base_type", "test": "test_native_micro_zus.rego: test_sus_a6_*"},
    {"ustawa": "SUS", "artykul": "art. 6a", "warunek": "Opieka nad dzieckiem — wyłączenie z obowiązku składek", "obliczenie": "Brak podstawy (wyłączenie)", "swiadectwo": "zus_child_care_exemption", "test": "test_native_micro_zus.rego: test_sus_a6a_* (GAP — brak atomów micro)"},
    {"ustawa": "SUS", "artykul": "art. 6b", "warunek": "Dobrowolne ubezpieczenie chorobowe", "obliczenie": "Składka 2,45% od zadeklarowanej podstawy", "swiadectwo": "zus_sickness_voluntary", "test": "test_native_micro_zus.rego: test_sus_a6b_*"},
    {"ustawa": "SUS", "artykul": "art. 9", "warunek": "Zbieg tytułów ubezpieczenia (JDG + etat)", "obliczenie": "Podstawa ≥ 60% prognozowanego przeciętnego (art. 9 ust. 1a)", "swiadectwo": "zus_concurrent_titles", "test": "test_native_micro_zus.rego: test_sus_a9_*"},
    {"ustawa": "SUS", "artykul": "art. 11", "warunek": "Obowiązek ubezpieczeń (emerytalne/rentowe)", "obliczenie": "Składki emerytalna 19,52% + rentowa 8%", "swiadectwo": "zus_social_obligation", "test": "test_native_micro_zus.rego: test_sus_a11_*"},
    {"ustawa": "SUS", "artykul": "art. 13", "warunek": "Ubezpieczenie chorobowe obowiązkowe (pracownicy)", "obliczenie": "Składka chorobowa 2,45%", "swiadectwo": "zus_sickness_mandatory", "test": "test_native_micro_zus.rego: test_sus_a13_*"},
    {"ustawa": "SUS", "artykul": "art. 14", "warunek": "Ubezpieczenie chorobowe dobrowolne (JDG)", "obliczenie": "Składka chorobowa 2,45% — deklaracja", "swiadectwo": "zus_sickness_voluntary", "test": "test_native_micro_zus.rego: test_sus_a14_*"},
    {"ustawa": "SUS", "artykul": "art. 18", "warunek": "Podstawa wymiaru składek JDG ≥ 60% przeciętnego", "obliczenie": "Podstawa × stopy art. 22", "swiadectwo": "zus_social_base_type", "test": "test_native_micro_zus.rego: test_sus_a18_*"},
    {"ustawa": "SUS", "artykul": "art. 18a", "warunek": "Ulga na start — 6 miesięcy bez składek społecznych", "obliczenie": "Składki społeczne 0, zdrowotna nadal należna", "swiadectwo": "zus_relief_ulga_start", "test": "test_native_micro_zus.rego: test_sus_a18a_*"},
    {"ustawa": "SUS", "artykul": "art. 18c", "warunek": "Preferencyjny ZUS 24m / Mały ZUS+ 36m (limit 120k)", "obliczenie": "Podstawa 30% minimalnego", "swiadectwo": "zus_relief_preferential_or_mzplus", "test": "test_native_micro_zus.rego: test_sus_a18c_*"},
    {"ustawa": "SUS", "artykul": "art. 19", "warunek": "Zasady ustalania podstawy wymiaru", "obliczenie": "Dochód / deklaracja podstawy", "swiadectwo": "zus_base_rule", "test": "test_native_micro_zus.rego: test_sus_a19_*"},
    {"ustawa": "SUS", "artykul": "art. 22", "warunek": "Stopy procentowe składek", "obliczenie": "19,52% / 8% / 2,45% / 1,67% / FP 2,45% / FGŚP 0,1%", "swiadectwo": "zus_social_rates", "test": "test_native_micro_zus.rego: test_sus_a22_*"},
    {"ustawa": "SUS", "artykul": "art. 24", "warunek": "Fundusz Pracy — zbieg podstaw", "obliczenie": "Składka FP 2,45%", "swiadectwo": "zus_labour_fund", "test": "test_native_micro_zus.rego: test_sus_a24_*"},
    {"ustawa": "SUS", "artykul": "art. 36", "warunek": "Terminy płatności składek", "obliczenie": "10. dzień (JDG) / 15. dzień (z ubezpieczonymi)", "swiadectwo": "zus_payment_deadline", "test": "test_native_micro_zus.rego: test_sus_a36_*"},
    {"ustawa": "SUS", "artykul": "art. 40", "warunek": "Prawo do świadczeń z ubezpieczeń", "obliczenie": "Wyczekiwanie art. 4 u.z.", "swiadectwo": "zus_benefit_entitlement", "test": "test_native_micro_zus.rego: test_sus_a40_*"},
    {"ustawa": "SUS", "artykul": "art. 47", "warunek": "Obowiązek opłacania składek", "obliczenie": "Termin 10/15 dnia", "swiadectwo": "zus_payment_obligation", "test": "test_native_micro_zus.rego: test_sus_a47_*"},
    {"ustawa": "u.ś.o.z.", "artykul": "art. 79", "warunek": "Prawo do świadczeń opieki zdrowotnej", "obliczenie": "Składka zdrowotna", "swiadectwo": "zus_health_right", "test": "test_native_micro_zus.rego: test_zdrowotna_a79_*"},
    {"ustawa": "u.ś.o.z.", "artykul": "art. 81", "warunek": "Składka zdrowotna — 4 warianty (skala 9%/liniowy 4,9%/ryczałt progi/karta 9%)", "obliczenie": "dochód×9% / dochód×4,9% / kwota ryczałtowa / min×9%", "swiadectwo": "zus_health_rate", "test": "test_native_micro_zus.rego: test_zdrowotna_a81_*"},
    {"ustawa": "u.ś.o.z.", "artykul": "art. 81b", "warunek": "Roczne rozliczenie składki zdrowotnej (skala)", "obliczenie": "Σ wpłat vs 9% rocznego dochodu", "swiadectwo": "zus_health_annual_reconciliation", "test": "test_native_micro_zus.rego: test_zdrowotna_a81b_*"},
    {"ustawa": "u.ś.o.z.", "artykul": "art. 81c", "warunek": "Progi ryczałtowe 60k/300k (60%/100%/180%)", "obliczenie": "491,40 / 819,00 / 1474,20", "swiadectwo": "zus_health_tier", "test": "test_native_micro_zus.rego: test_zdrowotna_a81c_*"},
    {"ustawa": "u.ś.o.z.", "artykul": "art. 81d", "warunek": "Minimalna podstawa wymiaru składki", "obliczenie": "9% minimalnego wynagrodzenia", "swiadectwo": "zus_health_min_base", "test": "test_native_micro_zus.rego: test_zdrowotna_a81d_*"},
    {"ustawa": "u.ś.o.z.", "artykul": "art. 82", "warunek": "Obowiązek opłacania + terminy (do 10./20.)", "obliczenie": "Termin płatności", "swiadectwo": "zus_health_payment", "test": "test_native_micro_zus.rego: test_zdrowotna_a82_*"},
    {"ustawa": "u.z.", "artykul": "art. 4", "warunek": "Okres wyczekiwania 90 dni (dobrowolne)", "obliczenie": "insured_days ≥ 90", "swiadectwo": "zus_waiting_met", "test": "test_native_micro_zus.rego: test_zasilkowa_a4_*"},
    {"ustawa": "u.z.", "artykul": "art. 11", "warunek": "Podstawa zasiłku = przeciętna z 12 miesięcy", "obliczenie": "podstawa/30 = stawka dzienna", "swiadectwo": "zus_benefit_daily", "test": "test_native_micro_zus.rego: test_zasilkowa_a11_*"},
    {"ustawa": "u.z.", "artykul": "art. 19", "warunek": "Zasiłek chorobowy", "obliczenie": "podstawa/30 × 80% × dni (70% szpital)", "swiadectwo": "zus_sickness_benefit", "test": "test_native_micro_zus.rego: test_zasilkowa_a19_*"},
    {"ustawa": "u.z.", "artykul": "art. 29", "warunek": "Zasiłek macierzyński 20 tyg. (140 dni)", "obliczenie": "podstawa/30 × 100% × dni", "swiadectwo": "zus_maternity_benefit", "test": "test_native_micro_zus.rego: test_zasilkowa_a29_*"},
    {"ustawa": "u.z.", "artykul": "art. 32", "warunek": "Zasiłek opiekuńczy", "obliczenie": "podstawa/30 × 80% × dni", "swiadectwo": "zus_care_benefit", "test": "test_native_micro_zus.rego: test_zasilkowa_a32_*"},
    {"ustawa": "u.z.", "artykul": "art. 33", "warunek": "Termin wypłaty zasiłku (30 dni)", "obliczenie": "Termin wypłaty", "swiadectwo": "zus_benefit_payment_deadline", "test": "test_native_micro_zus.rego: test_zasilkowa_a33_*"},
]

atom_articles := [entry.artykul | entry := atom_map[_]]
atom_count := count(atom_map)

# ── Coverage: inwentarz vs pliki (ujawnia niespójność) ────────────────────────
# Stan z bundles/zus_micro_inventory.json (klucze tylko numerem artykułu).
inventory_coverage := {
    "6": "COMPLETE", "6a": "MISSING", "6b": "COMPLETE", "9": "COMPLETE",
    "11": "COMPLETE", "13": "COMPLETE", "14": "COMPLETE", "18": "COMPLETE",
    "18a": "COMPLETE", "18c": "COMPLETE", "19": "COMPLETE", "22": "COMPLETE",
    "24": "COMPLETE", "36": "COMPLETE", "40": "COMPLETE", "47": "COMPLETE",
    "79": "COMPLETE", "81": "COMPLETE", "81b": "MISSING", "81c": "MISSING",
    "81d": "MISSING", "82": "COMPLETE", "29": "COMPLETE", "32": "COMPLETE",
    "33": "COMPLETE",
}

# Rzeczywista obecność atomów w plikach micro (udokumentowana 2026-08-20).
file_presence := {
    "6a": "MISSING",
    "81b": "PRESENT", "81c": "PRESENT", "81d": "PRESENT",
}

coverage_discrepancies := [article |
    article := ["6a", "81b", "81c", "81d"][_]
    file_presence[article] != object.get(inventory_coverage, article, "MISSING")
]

missing_atoms := [article |
    article := ["6a", "81b", "81c", "81d"][_]
    file_presence[article] == "MISSING"
]

coverage_summary := {
    "atom_map_entries": atom_count,
    "inventory_missing": count([a | a := atom_articles[_]; object.get(inventory_coverage, a, "MISSING") == "MISSING"]),
    "discrepancies": coverage_discrepancies,
    "missing_atoms": missing_atoms,
    "note": "6a brak atomów micro; 81b/81c/81d obecne w plikach, lecz inwentarz je pomija",
}

# ── Okresy ubezpieczenia: zbiegi / przerwy / zawieszenie ──────────────────────
titles := object.get(micro, "titles", object.get(ent, "titles", []))
active_titles := [t | t := titles[_]; object.get(t, "active", true) == true]
has_jdg := business_status == "ACTIVE"
has_employment := count([t | t := active_titles[_]; object.get(t, "type", "") == "EMPLOYMENT"]) > 0

concurrency := "CONCURRENT_JDG_EMPLOYMENT" {
    has_jdg
    has_employment
} else := "SINGLE_TITLE" {
    has_jdg
    not has_employment
} else := "NO_ACTIVE_TITLE" {
    not has_jdg
}

suspended := business_status == "SUSPENDED"
break_months := max([0, to_number(object.get(micro, "break_months", 0))])
insurance_gap := break_months > 0

period_analysis := {
    "concurrency": concurrency,
    "suspended": suspended,
    "active_titles": count(active_titles),
    "break_months": break_months,
    "insurance_gap": insurance_gap,
    "social_due": has_jdg and not suspended,
    "health_due": has_jdg,
    "legal_basis": "Art. 6, 9 SUS; Art. 36a SUS (zawieszenie)",
    "warnings": array.concat(
        [sprintf("Zbieg tytułów: %s — podstawa ≥ 60%% przeciętnego (art. 9 ust. 1a)", [concurrency]) | has_jdg and has_employment],
        [sprintf("Zawieszenie działalności — składki społeczne wstrzymane, zdrowotna nadal należna", []) | suspended]
    ),
}

# ── Świadczenia: chorobowe / macierzyńskie / opiekuńcze + zaokrąglenia ────────
benefit_rate := sickness_rate {
    benefit_type == "CHOROBOWE"
    not hospitalization
} else := sickness_hospital_rate {
    benefit_type == "CHOROBOWE"
    hospitalization
} else := maternity_rate {
    benefit_type == "MACIERZYNSKIE"
} else := care_rate {
    benefit_type == "OPIEKUNCZE"
} else := 0 {
    true
}

benefit_daily := round2(benefit_base / 30)
benefit_amount := round2(benefit_daily * benefit_rate * benefit_days)
benefit_waiting_met := insured_days >= waiting_days
benefit_days_limit := sickness_max_days_tb {
    benefit_type == "CHOROBOWE"
    object.get(micro, "tuberculosis_or_pregnancy", false) == true
} else := sickness_max_days {
    benefit_type == "CHOROBOWE"
} else := maternity_weeks * 7 {
    benefit_type == "MACIERZYNSKIE"
} else := 0 {
    true
}
benefit_days_remaining := max([0, benefit_days_limit - sickness_days_used])

benefit_calculation := {
    "type": benefit_type,
    "base": benefit_base,
    "daily": benefit_daily,
    "rate": benefit_rate,
    "days": benefit_days,
    "amount": benefit_amount,
    "hospitalization": hospitalization,
    "waiting_days": waiting_days,
    "waiting_met": benefit_waiting_met,
    "insured_days": insured_days,
    "days_limit": benefit_days_limit,
    "days_used": sickness_days_used,
    "days_remaining": benefit_days_remaining,
    "unit": "PLN",
    "rounding": rounding_contract,
    "legal_basis": "Art. 4/11/19/29/32/33 ustawy zasiłkowej",
}

health_minimum := round2(minimum_wage * health_scale_rate)

# ── Property invariants (F2 V2) ───────────────────────────────────────────────
inv_rates_in_unit_interval := benefit_rate >= 0
inv_rates_in_unit_interval := benefit_rate <= 1
inv_amounts_non_negative := benefit_amount >= 0
inv_days_non_negative := benefit_days >= 0
inv_base_non_negative := benefit_base >= 0
inv_daily_le_base := benefit_daily <= benefit_base {
    benefit_base >= 0
}
inv_maternity_rate_one := benefit_rate == maternity_rate {
    benefit_type == "MACIERZYNSKIE"
}
inv_rounding_contract := rounding_contract == "PLN_HALF_UP_2DP"
inv_no_silent_default := benefit_requested == false or benefit_base > 0

property_invariants := {
    "rates_in_unit_interval": inv_rates_in_unit_interval,
    "amounts_non_negative": inv_amounts_non_negative,
    "days_non_negative": inv_days_non_negative,
    "base_non_negative": inv_base_non_negative,
    "daily_le_base": inv_daily_le_base,
    "maternity_rate_one": inv_maternity_rate_one,
    "rounding_contract": inv_rounding_contract,
    "no_silent_default": inv_no_silent_default,
}

invariant_failed := [name |
    name := ["rates_in_unit_interval", "amounts_non_negative", "days_non_negative", "base_non_negative", "daily_le_base", "maternity_rate_one", "rounding_contract", "no_silent_default"][_]
    property_invariants[name] == false
]

# ── Fail-closed gates: TRIAGE / BLOCK, nigdy cichy domyślny wynik ────────────
collisions := array.concat(
    object.get(input, "pit_conflicts", []),
    array.concat(object.get(input, "vat_conflicts", []), object.get(input, "uor_conflicts", []))
)
negative_numeric_data := [value |
    value := [monthly_income, annual_revenue, benefit_base, benefit_days][_]
    value < 0
]
benefit_data_missing := benefit_requested and (benefit_base == 0 or benefit_days == 0)
benefit_over_limit := benefit_days_remaining == 0 and sickness_days_used > 0 and benefit_days > 0 and benefit_type == "CHOROBOWE"

manual_review := count(missing_context) > 0 or count(uncertainty_markers) > 0 or count(collisions) > 0 or count(negative_numeric_data) > 0 or benefit_data_missing or count(invariant_failed) > 0

routing := "BLOCK_AND_ALERT" {
    count(missing_context) > 0
} else := "BLOCK_AND_ALERT" {
    count(negative_numeric_data) > 0
} else := "BLOCK_AND_ALERT" {
    benefit_data_missing
} else := "TRIAGE_QUEUE" {
    count(uncertainty_markers) > 0
} else := "TRIAGE_QUEUE" {
    count(collisions) > 0
} else := "TRIAGE_QUEUE" {
    count(invariant_failed) > 0
} else := "TRIAGE_QUEUE" {
    benefit_over_limit
} else := "REPORT" {
    true
}

# ── Certificate ───────────────────────────────────────────────────────────────
calculation_certificate := {
    "certificate_id": object.get(input, "calculation_id", "UNASSIGNED"),
    "evaluation_date": evaluation_date,
    "evaluation_year": evaluation_year,
    "threshold_version": threshold_version,
    "legal_basis_version": legal_basis_version,
    "facts_version": facts_version,
    "rounding": rounding_contract,
    "currency": currency,
    "units": {"benefit": "PLN", "daily": "PLN/day", "health": "PLN/month"},
    "source": "data.jdg.thresholds.zus + input.zus_micro + micro/sus|zdrowotna|zasilkowa",
    "manual_review": manual_review,
    "missing_context": missing_context,
    "uncertainty_markers": uncertainty_markers,
    "cross_domain_collisions": collisions,
    "property_invariants": property_invariants,
    "invariant_failed": invariant_failed,
}

# Publiczny wynik aktywowany osobną flagą — brak flagi pozostaje no_match.
default decide := {"matched": false, "rule_id": "jdg.zus_micro_etap13.no_match", "package": package_id, "priority": 999999}

decide := {
    "matched": true,
    "rule_id": "jdg.zus_micro_etap13.report",
    "package": package_id,
    "priority": 570,
    "decision_mode": decision_mode,
    "no_auto_post": true,
    "routing": routing,
    "manual_review": manual_review,
    "atom_map": {"entries": atom_map, "count": atom_count},
    "coverage": coverage_summary,
    "periods": period_analysis,
    "benefits": benefit_calculation,
    "health": {"minimum_monthly": health_minimum, "rate": health_scale_rate, "tax_form": tax_form, "monthly_income": monthly_income, "annual_revenue": annual_revenue},
    "property_invariants": property_invariants,
    "invariant_failed": invariant_failed,
    "calculation_certificate": calculation_certificate,
    "threshold_snapshot": {"minimum_wage": minimum_wage, "sickness_rate": sickness_rate, "sickness_hospital_rate": sickness_hospital_rate, "maternity_rate": maternity_rate, "care_rate": care_rate, "waiting_days": waiting_days, "sickness_max_days": sickness_max_days, "maternity_weeks": maternity_weeks, "evaluation_year": evaluation_year},
    "_routing": routing,
    "_routing_reason": "ETAP 13 ZUS Micro: mapa atomów, okresy, świadczenia, zaokrąglenia, property invariants i fail-closed gates",
    "_legal_basis": "SUS art. 6-47; u.ś.o.z. art. 79-82; ustawa zasiłkowa art. 4-33",
    "_warnings": ["SUGGEST only; brak danych lub naruszony invariant blokuje automatyzację. Art. 6a nie ma atomów micro (GAP); 81b/81c/81d w plikach, lecz inwentarz je pomija."],
} {
    object.get(input, "zus_micro_etap13_check", false) == true
}
