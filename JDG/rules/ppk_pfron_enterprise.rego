# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE PPK + PFRON MODULE (Strategic Initiative S18)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise PPK + PFRON — Employee Obligations Automation
# description: |
#   ENTERPRISE v5.1 — Automatyzacja obowiązków pracodawcy JDG:
#   - PPK (Pracownicze Plany Kapitałowe): auto-enrollment, wpłaty, rezygnacje, limity
#   - PFRON: wpłaty na PFRON, ulgi, status ZPChr, obliczanie wskaźnika zatrudnienia
#   - FGŚP (Fundusz Gwarantowanych Świadczeń Pracowniczych): składki
#   - ZFŚS (Zakładowy Fundusz Świadczeń Socjalnych): obowiązki
#   Wypełnia lukę: brak reguł dla pracodawcy JDG z pracownikami.
# architecture: Enterprise Employer Engine, First-Match-Wins else-chain
# legal_basis: Ustawa o PPK (Dz.U. 2018 poz. 2215); Ustawa o rehabilitacji (Dz.U. 1997 nr 123 poz. 776)
# package: jdg.ppk_pfron
# deprecated: false
# priority_range: 1650-1699
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.ppk_pfron

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.ppk_pfron.no_match",
    "package": "jdg.ppk_pfron", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# PPK-1650: PPK AUTO-ENROLLMENT CHECK — sprawdzenie obowiązku PPK
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.ppk_pfron.ppk_enrollment_check",
    "package": "jdg.ppk_pfron",
    "priority": 1650,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ppk_obligated": ppk_required,
    "ppk_employee_count": ee_count,
    "ppk_enrolled_count": enrolled,
    "ppk_auto_enrollment_date": auto_enroll_date,
    "_routing": ppk_routing,
    "_routing_reason": ppk_routing_reason,
    "_legal_basis": "Art. 7-16 Ustawy o PPK; Art. 25 ustawy o PPK (kary do 1.5% funduszu płac)",
    "_warnings": build_ppk_warnings(ppk_required, ee_count, enrolled, auto_enroll_date)
} {
    input.employment.has_employees == true
    input.ppk_check_requested == true

    ee_count := object.get(input.employment, "employee_count", 0)
    ee_age_18_55 := object.get(input.employment, "employees_age_18_55", 0)
    enrolled := object.get(input.employment, "ppk_enrolled_count", 0)
    all_opted_out := object.get(input.employment, "ppk_all_opted_out", false)
    has_ppe := object.get(input.employment, "has_ppe", false)  # Pracowniczy Program Emerytalny

    # PPK required if:
    # - At least 1 employee (JDG with employees)
    # - Not all opted out
    # - No PPE (PPE exempts from PPK)
    ppk_required := ee_count > 0 and not all_opted_out and not has_ppe

    # Auto-enrollment rules
    auto_enroll_date := ""
    auto_enroll_date := sprintf("2026-04-01", []) { ee_count >= 50; enrolled < ee_age_18_55 }
    auto_enroll_date := sprintf("2026-10-01", []) { ee_count >= 20; ee_count < 50; enrolled < ee_age_18_55 }
    auto_enroll_date := sprintf("2027-01-01", []) { ee_count < 20; enrolled < ee_age_18_55 }

    ppk_routing := ""
    ppk_routing := "TRIAGE_QUEUE" { ppk_required; enrolled < ee_age_18_55 }
    ppk_routing_reason := ""
    ppk_routing_reason := sprintf("PPK: %d pracowników nie zapisanych — auto-enrollment wymagany do %s", [ee_age_18_55 - enrolled, auto_enroll_date]) { ppk_required; enrolled < ee_age_18_55 }
}

build_ppk_warnings(required, total_ee, enrolled_ee, enroll_date) = warnings {
    required == true
    not_enrolled := total_ee - enrolled_ee
    warnings := [
        sprintf("📊 PPK — OBOWIĄZEK PRACODAWCY (%d pracowników)", [total_ee]),
        sprintf("   Zapisanych: %d | Niezapisanych: %d", [enrolled_ee, not_enrolled]),
        sprintf("⏰ Auto-enrollment do: %s", [enroll_date]),
        "",
        "💰 SKŁADKI PPK (od wynagrodzenia brutto):",
        "   • Pracownik: 2.0% (obowiązkowo) + max 2.0% (dobrowolnie)",
        "   • Pracodawca: 1.5% (obowiązkowo) + max 2.5% (dobrowolnie)",
        "   • Dopłata roczna z FRD: 240 PLN za aktywnych",
        "",
        "⚠️ KARY: brak wpłat PPK → grzywna do 1.5% funduszu wynagrodzeń (Art. 25)",
        "📌 Rezygnacja pracownika z PPK: co 4 lata ponowny auto-enrollment!"
    ]
} else = warnings {
    required == true; enrolled_ee == total_ee
    warnings := ["✅ PPK: wszyscy pracownicy zapisani. Składki naliczane prawidłowo."]
} else = ["ℹ️ PPK nie dotyczy — brak pracowników lub PPE zwalnia z obowiązku."]

# ═══════════════════════════════════════════════════════════════════════════════
# PPK-1655: PPK CONTRIBUTION CALCULATION — obliczanie składek PPK
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ppk_pfron.ppk_contribution_calculation",
    "package": "jdg.ppk_pfron",
    "priority": 1655,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ppk_employer_total_monthly": employer_total,
    "ppk_employee_total_monthly": ee_total,
    "ppk_monthly_kup_pln": employer_total,
    "ppk_annual_state_subsidy_pln": state_subsidy,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 27-32 Ustawy o PPK; Art. 22 ust. 1 PIT (KUP dla pracodawcy)",
    "_warnings": [sprintf("💰 PPK — składki miesięczne: Pracodawca=%.2f PLN (KUP!), Pracownicy łącznie=%.2f PLN, Dopłata roczna FRD=%.0f PLN", [employer_total, ee_total, state_subsidy])]
} {
    input.employment.has_employees == true
    input.ppk_calculate_contributions == true

    enrolled_ee := object.get(input.employment, "ppk_enrolled_count", 0)
    monthly_payroll := object.get(input.employment, "monthly_payroll_gross", 20000)
    employer_basic_pct := 0.015
    employee_basic_pct := 0.02
    employer_extra_pct := object.get(input.employment, "ppk_employer_extra_pct", 0) / 100
    employee_extra_pct := object.get(input.employment, "ppk_employee_extra_pct", 0) / 100

    employer_total := monthly_payroll * (employer_basic_pct + employer_extra_pct)
    ee_total := monthly_payroll * (employee_basic_pct + employee_extra_pct)
    state_subsidy := enrolled_ee * 240
}

# ═══════════════════════════════════════════════════════════════════════════════
# PFRON-1660: PFRON OBLIGATION CHECK — sprawdzenie obowiązku wpłat na PFRON
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ppk_pfron.pfron_obligation_check",
    "package": "jdg.ppk_pfron",
    "priority": 1660,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "pfron_required": pfron_needed,
    "pfron_monthly_amount_pln": pfron_amount,
    "pfron_disabled_employed": disabled_count,
    "pfron_required_ratio": required_ratio,
    "pfron_actual_ratio": actual_ratio,
    "_routing": pfron_routing,
    "_routing_reason": pfron_routing_reason,
    "_legal_basis": "Art. 21 Ustawy o rehabilitacji zawodowej; Dz.U. 1997 nr 123 poz. 776",
    "_warnings": build_pfron_warnings(pfron_needed, pfron_amount, disabled_count, required_ratio, actual_ratio)
} {
    input.employment.has_employees == true
    input.pfron_check_requested == true

    total_ee := object.get(input.employment, "employee_count", 0)
    disabled_ee := object.get(input.employment, "disabled_employee_count", 0)
    avg_monthly_wage := object.get(object.get(data.thresholds, "bounds", {}), "average_wage", 8000)
    is_zpchr := object.get(input.employment, "is_zpchr", false)  # Status ZPChr
    uses_pfron_relief := object.get(input.employment, "uses_buying_from_zpchr_relief", false)

    # PFRON THRESHOLD: required if >=25 employees (FTE) AND disabled ratio < 6%
    pfron_threshold := 25
    required_ratio := 0.06
    actual_ratio := disabled_ee / total_ee { total_ee > 0 }
    actual_ratio := 0 { total_ee == 0 }

    pfron_needed := total_ee >= pfron_threshold and actual_ratio < required_ratio and not is_zpchr

    # PFRON monthly contribution calculation
    missing_disabled := floor((total_ee * required_ratio) - disabled_ee)
    missing_disabled := max([missing_disabled, 0])
    pfron_amount := missing_disabled * avg_monthly_wage * 0.4065  # 40.65% przeciętnego wynagrodzenia

    pfron_routing := ""
    pfron_routing := "TRIAGE_QUEUE" { pfron_needed and pfron_amount > 0 }
    pfron_routing_reason := ""
    pfron_routing_reason := sprintf("PFRON: brakuje %d niepełnosprawnych (%.1f%%) — wpłata %.2f PLN/mies", [missing_disabled, actual_ratio * 100, pfron_amount]) { pfron_needed }
}

build_pfron_warnings(needed, amount, disabled, required, actual) = warnings {
    needed == true
    warnings := [
        sprintf("🔴 PFRON — OBOWIĄZEK WPŁAT! Zatrudniasz %d+ pracowników.", [25]),
        sprintf("   Wskaźnik: %.1f%% (wymagane 6%%) — zatrudnionych niepełnosprawnych: %d", [actual * 100, disabled]),
        sprintf("💰 MIESIĘCZNA WPŁATA: %.2f PLN (40.65%% przeciętnego wynagrodzenia × brakujący etat)", [amount]),
        "",
        "📋 JAK UNIKNĄĆ PFRON:",
        "   1. Zatrudnij 1 osobę niepełnosprawną (obniża wskaźnik o ~4%)",
        "   2. Uzyskaj status ZPChr (Zakład Pracy Chronionej)",
        "   3. Kupuj produkty/usługi od ZPChr (ulga do 50% wpłaty)",
        "   4. Zatrudniaj osoby ze schorzeniami szczególnymi (3× waga!)",
        "",
        "📌 Wpłaty do 20. dnia miesiąca za miesiąc poprzedni. Deklaracja DEK-I-a co miesiąc."
    ]
} else = warnings {
    actual >= 0.06
    warnings := [sprintf("✅ PFRON: wskaźnik %.1f%% — powyżej wymaganego 6%%. Brak obowiązku wpłat. Zatrudnieni niepełnosprawni: %d.", [actual * 100, disabled])]
} else = ["ℹ️ PFRON nie dotyczy — mniej niż 25 pracowników."]

# ═══════════════════════════════════════════════════════════════════════════════
# PFRON-1665: PFRON RELIEF CALCULATION — ulgi we wpłatach na PFRON
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ppk_pfron.pfron_relief_calculation",
    "package": "jdg.ppk_pfron",
    "priority": 1665,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "pfron_base_monthly": base_pfron,
    "pfron_relief_zpchr_purchases": zpchr_relief,
    "pfron_relief_special_condition": special_relief,
    "pfron_after_relief": final_pfron,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21-22 Ustawy o rehabilitacji; Rozporządzenie MPiPS ws. ulg PFRON",
    "_warnings": [sprintf("💰 PFRON PO ULGACH: %.2f PLN (bazowa: %.2f, ulga ZPChr: %.2f, ulga schorzenia szczególne: %.2f)", [final_pfron, base_pfron, zpchr_relief, special_relief])]
} {
    input.pfron_calculate_relief == true
    base_pfron := object.get(input.employment, "pfron_base_monthly", 0)
    zpchr_purchases := object.get(input.employment, "monthly_zpchr_purchases", 0)
    special_condition_ee := object.get(input.employment, "employees_special_conditions", 0)
    avg_wage := object.get(object.get(data.thresholds, "bounds", {}), "average_wage", 8000)

    # Ulga: zakupy od ZPChr — do 50% wpłaty
    zpchr_relief_pct := 0.50
    zpchr_relief := min([zpchr_purchases * zpchr_relief_pct, base_pfron * 0.50])

    # Ulga: zatrudnienie osób ze schorzeniami szczególnymi (3× waga)
    special_weight := 3
    special_relief := special_condition_ee * special_weight * avg_wage * 0.4065

    final_pfron := base_pfron - zpchr_relief - special_relief
    final_pfron := max([final_pfron, 0])
}

# ═══════════════════════════════════════════════════════════════════════════════
# FGSP-1670: FUNDUSZ GWARANTOWANYCH ŚWIADCZEŃ PRACOWNICZYCH
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ppk_pfron.fgsp_contribution",
    "package": "jdg.ppk_pfron",
    "priority": 1670,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "fgsp_rate_pct": 0.10,
    "fgsp_monthly_pln": fgsp_amount,
    "fgsp_annual_pln": fgsp_annual,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o FGŚP (Dz.U. 2006 nr 158 poz. 1121); Art. 9-10 ustawy FGŚP",
    "_warnings": [sprintf("💼 FGŚP: składka %.2f%% od wynagrodzeń = %.2f PLN/mies (%.2f PLN/rok), płatne do 15. dnia miesiąca", [0.10, fgsp_amount, fgsp_annual])]
} {
    input.employment.has_employees == true
    monthly_payroll := object.get(input.employment, "monthly_payroll_gross", 20000)
    fgsp_amount := monthly_payroll * 0.001
    fgsp_annual := fgsp_amount * 12
}

# ═══════════════════════════════════════════════════════════════════════════════
# ZFSS-1675: ZAKŁADOWY FUNDUSZ ŚWIADCZEŃ SOCJALNYCH — obowiązek
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ppk_pfron.zfss_obligation",
    "package": "jdg.ppk_pfron",
    "priority": 1675,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "zfss_required": zfss_needed,
    "zfss_threshold_employees": 50,
    "zfss_annual_budget_pln": zfss_budget,
    "zfss_per_employee_pln": per_ee_amount,
    "_routing": zfss_routing,
    "_routing_reason": zfss_routing_reason,
    "_legal_basis": "Ustawa o ZFŚS (Dz.U. 2024 poz. 288); Art. 5-6 ustawy ZFŚS",
    "_warnings": build_zfss_warnings(zfss_needed, zfss_budget, per_ee_amount)
} {
    input.employment.has_employees == true
    input.zfss_check_requested == true

    total_ee := object.get(input.employment, "employee_count", 0)
    ee_fte := object.get(input.employment, "employee_fte_count", total_ee)
    avg_wage := object.get(object.get(data.thresholds, "bounds", {}), "average_wage", 8000)

    zfss_needed := ee_fte >= 50
    per_ee_amount := avg_wage * 0.375  # 37.5% przeciętnego wynagrodzenia
    zfss_budget := ee_fte * per_ee_amount

    zfss_routing := ""
    zfss_routing := "TRIAGE_QUEUE" { zfss_needed }
    zfss_routing_reason := ""
    zfss_routing_reason := sprintf("ZFŚS wymagany: %d pracowników — budżet %.2f PLN/rok", [ee_fte, zfss_budget]) { zfss_needed }
}

build_zfss_warnings(needed, budget, per_ee) = warnings {
    needed == true
    warnings := [
        sprintf("💰 ZFŚS — OBOWIĄZEK OD 50+ PRACOWNIKÓW (FTE)", []),
        sprintf("   Budżet roczny: %.2f PLN (%.2f PLN/pracownika)", [budget, per_ee]),
        sprintf("   Odpis podstawowy: 37.5%% przeciętnego wynagrodzenia na etat", []),
        "",
        "📅 TERMINY PRZELEWÓW:",
        "   • Do 31 maja: 75% odpisu",
        "   • Do 30 września: 25% odpisu",
        "",
        "📋 Kryteria socjalne: obowiązek regulaminu ZFŚS (uzgodnionego ze związkami)",
        "⚠️ Brak ZFŚS → grzywna do 5000 PLN (Art. 12a)"
    ]
} else = ["ℹ️ ZFŚS nie dotyczy — mniej niż 50 pracowników (FTE)."]

# ═══════════════════════════════════════════════════════════════════════════════
# PPK-1680: EMPLOYER COST SUMMARY — łączne koszty pracodawcy JDG
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ppk_pfron.employer_total_cost_summary",
    "package": "jdg.ppk_pfron",
    "priority": 1680,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "employer_total_monthly_cost": total_monthly,
    "employer_zus_contributions_pln": zus_total,
    "employer_ppk_pln": ppk_contrib,
    "employer_pfron_pln": pfron_contrib,
    "employer_fgsp_pln": fgsp_contrib,
    "employer_monthly_kup_total_pln": total_monthly,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22 ust. 1 PIT (wszystkie składki pracodawcy są KUP)",
    "_warnings": [sprintf("📊 CAŁKOWITY KOSZT PRACODAWCY: %.2f PLN/mies (ZUS pracodawcy + PPK + PFRON + FGŚP). WSZYSTKO jest KUP w PKPiR (kol. 14).", [total_monthly])]
} {
    input.employment.has_employees == true
    input.employer_cost_summary == true

    zus_total := object.get(input.employment, "zus_employer_monthly", 0)
    ppk_contrib := object.get(input.employment, "ppk_employer_monthly", 0)
    pfron_contrib := object.get(input.employment, "pfron_monthly", 0)
    fgsp_contrib := object.get(input.employment, "fgsp_monthly", 0)

    total_monthly := zus_total + ppk_contrib + pfron_contrib + fgsp_contrib
}
