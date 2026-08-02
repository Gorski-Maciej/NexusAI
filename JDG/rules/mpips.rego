# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — MPiPS: Social Contributions & Labor Fund (P770-P773)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: MPiPS Package — Social Contributions Reporting and Labor Obligations
# description: |
#   First-Match-Wins else-chain dla składek na fundusze pozaubezpieczeniowe
#   (FP, FGŚP, FS, PFRON) oraz obowiązków raportowych do MPiPS.
#   JDG z pracownikami odprowadza składki na FP i FGŚP od wynagrodzeń.
#   Zatrudnienie >25 etatów → obowiązek wpłat na PFRON.
#   Zatrudnienie >20 etatów → obowiązek tworzenia ZFŚS.
# legal_basis: Ustawa o promocji zatrudnienia, Ustawa o ochronie roszczeń
#   pracowniczych, Ustawa o rehabilitacji, Ustawa o ZFŚS
# edge_cases:
#   - FP: zwolnienie dla pracowników powracających z urlopu rodzicielskiego (36 mies.)
#   - FGŚP: tylko dla umów o pracę (nie dla umów cywilnych)
#   - PFRON: wpłata = 0.4065 × przeciętne wynagrodzenie × brakujące etaty
#   - ZFŚS: 37.5% odpisu podstawowego na jednego pracownika
# package: jdg.mpips
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.mpips

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.mpips.no_match",
    "package": "jdg.mpips", "priority": 780
}

# ══════ P770: mpips_labour_fund_fp — Składka na Fundusz Pracy ══════
decide := {
    "matched": true, "rule_id": "jdg.mpips.labour_fund_fp",
    "package": "jdg.mpips", "priority": 770,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mpips_fp_rate": "0.0245", "mpips_fp_exemption_possible": fp_exempt,
    "mpips_reporting_obligation": "DRA_MONTHLY",
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 104-107 Ustawy o promocji zatrudnienia",
    "_warnings": [sprintf("Fundusz Pracy — składka %.1f%% od wynagrodzeń brutto. %s", [2.45, fp_info])]
} {
    input.employment.has_employees == true
    emp_count := object.get(input.employment, "employee_count", 0)
    emp_count > 0
    employment_contract_count == 0

    # Zwolnienie z FP: pracownicy powracający z urlopu macierzyńskiego/rodzicielskiego (36 mies.)
    fp_exempt_count := object.get(input.employment, "fp_exempt_employees", 0)
    fp_exempt = fp_exempt_count > 0
    fp_info = sprintf("Zwolnienie z FP dla %d pracowników (powrót z urlopu rodzicielskiego, do 36 mies.)", [fp_exempt_count]) { fp_exempt_count > 0 }
    else = "Brak zwolnień z FP" { fp_exempt_count == 0 }
}

# ══════ P771: mpips_fgsp_guaranteed_benefits — Składka na FGŚP ══════
else := {
    "matched": true, "rule_id": "jdg.mpips.fgsp_guaranteed_benefits",
    "package": "jdg.mpips", "priority": 771,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mpips_fgsp_rate": "0.0010", "mpips_fgsp_applies_to": "EMPLOYMENT_CONTRACTS_ONLY",
    "mpips_reporting_obligation": "DRA_MONTHLY",
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 25-29 Ustawy o ochronie roszczeń pracowniczych",
    "_warnings": ["FGŚP — składka 0.10% od wynagrodzeń z umów o pracę. NIE dotyczy umów cywilnoprawnych"]
} {
    input.employment.has_employees == true
    employment_contract_count := object.get(input.employment, "employment_contract_count", 0)
    employment_contract_count > 0
}

# FGŚP — obsługiwane przez P771; P770 tylko dla umów cywilnoprawnych (brak etatów)

# ══════ P772: mpips_pfron_disabled_fund — Wpłata na PFRON (≥25 etatów) ══════
else := {
    "matched": true, "rule_id": "jdg.mpips.pfron_disabled_fund",
    "package": "jdg.mpips", "priority": 772,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mpips_pfron_obligation": true, "mpips_pfron_missing_etats": missing_etats,
    "mpips_pfron_monthly_amount": floor(pfron_amount),
    "mpips_reporting_obligation": "PFRON_MONTHLY",
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Obowiązek PFRON — zatrudnienie ≥25 etatów",
    "_legal_basis": "Art. 21 Ustawy o rehabilitacji zawodowej",
    "_warnings": [sprintf("PFRON — zatrudnienie %d etatów. Brakuje %d etatów niepełnosprawnych (6%%). Miesięczna wpłata: %.2f PLN", [total_etats, missing_etats, pfron_amount])]
} {
    total_etats := object.get(input.employment, "employee_count_etat", 0)
    total_etats >= 25
    disabled_etats := object.get(input.employment, "disabled_employee_etats", 0)
    required_disabled := ceil(total_etats * 0.06)
    missing_etats = required_disabled - disabled_etats { disabled_etats < required_disabled }
    else = 0 { disabled_etats >= required_disabled }
    avg_wage := object.get(object.get(object.get(data.thresholds, "jdg", {}), "bounds", {}), "avg_monthly_wage", 7000)
    pfron_amount = missing_etats * 0.4065 * avg_wage
}

# ══════ P773: mpips_zfss_social_fund — ZFŚS — Zakładowy Fundusz Świadczeń Socjalnych ══════
else := {
    "matched": true, "rule_id": "jdg.mpips.zfss_social_fund",
    "package": "jdg.mpips", "priority": 773,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mpips_zfss_obligation": true, "mpips_zfss_annual_amount": floor(zfss_amount),
    "mpips_reporting_obligation": "ZFSS_ANNUAL",
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Obowiązek ZFŚS — zatrudnienie ≥50 etatów (wg stanu na 1 stycznia)",
    "_legal_basis": "Art. 3-5 Ustawy o ZFŚS",
    "_warnings": [sprintf("ZFŚS — %d pracowników. Odpis podstawowy: %.2f PLN/rok (37.5%% przeciętnego wynagrodzenia na pracownika)", [emp_count, zfss_amount])]
} {
    emp_count := object.get(input.employment, "employee_count", 0)
    emp_count >= 50
    avg_wage := object.get(object.get(object.get(data.thresholds, "jdg", {}), "bounds", {}), "avg_monthly_wage", 7000)
    zfss_amount = emp_count * 0.375 * avg_wage
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P774-P781 — MPiPS ROZSZERZENIE: PPK, Urlopy, Odprawy, Nagrody          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════ P774: ppk_employee_capital_plan — Pracownicze Plany Kapitałowe ══════
else := {
    "matched": true, "rule_id": "jdg.mpips.ppk_employee_capital_plan",
    "package": "jdg.mpips", "priority": 774,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mpips_ppk_obligation": true, "mpips_ppk_employer_pct": employer_pct,
    "mpips_ppk_employee_pct": employee_pct, "mpips_ppk_state_subsidy": 240,
    "mpips_reporting_obligation": "PPK_MONTHLY",
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "PPK obowiązkowe dla JDG z pracownikami (auto-enrolment)",
    "_legal_basis": "Ustawa o PPK z dn. 4.10.2018",
    "_warnings": [sprintf("PPK — %d pracowników. Składka pracodawcy: %.1f%%, pracownika: %.1f%% + dopłata państwa 240 PLN/rok. Auto-zapis co 4 lata. Możliwość rezygnacji przez pracownika.", [emp_count, employer_pct, employee_pct])]
} {
    input.employment.has_employees == true
    emp_count := object.get(input.employment, "employee_count", 0)
    emp_count >= 1
    ppk_age := object.get(input.employment, "ppk_eligible_employees", 0)
    ppk_age > 0
    employer_pct := object.get(input.employment, "ppk_employer_contribution_pct", 1.5)
    employee_pct := object.get(input.employment, "ppk_employee_contribution_pct", 2.0)
}

# ══════ P775: vacation_benefit_swiadczenie_urlopowe — Świadczenie urlopowe ══════
else := {
    "matched": true, "rule_id": "jdg.mpips.vacation_benefit",
    "package": "jdg.mpips", "priority": 775,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mpips_vacation_benefit_amount": benefit_amount,
    "mpips_vacation_benefit_per_employee": floor(benefit_amount / emp_count),
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 3 Ustawy o ZFŚS",
    "_warnings": [sprintf("ŚWIADCZENIE URLOPOWE — %d pracowników × %.2f PLN = %.2f PLN. Wypłata do 31 sierpnia. Dotyczy JDG <20 etatów (zamiast ZFŚS).", [emp_count, floor(benefit_amount / emp_count), benefit_amount])]
} {
    input.employment.has_employees == true
    emp_count := object.get(input.employment, "employee_count", 0)
    emp_count > 0
    emp_count < 20
    avg_wage := object.get(object.get(object.get(data.thresholds, "jdg", {}), "bounds", {}), "avg_monthly_wage", 7000)
    benefit_amount = emp_count * 0.375 * avg_wage
}

# ══════ P776: mpips_severance_pay_odprawa — Odprawa emerytalno-rentowa ══════
else := {
    "matched": true, "rule_id": "jdg.mpips.severance_pay",
    "package": "jdg.mpips", "priority": 776,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mpips_severance_type": severance_type, "mpips_severance_amount": severance_amount,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Odprawa emerytalna/rentowa — obowiązek pracodawcy",
    "_legal_basis": "Art. 92¹ Kodeksu Pracy",
    "_warnings": [sprintf("ODPRAWA %s — %.2f PLN (1-miesięczne wynagrodzenie). Wypłać w dniu rozwiązania umowy. %s", [severance_type, severance_amount, tax_info])]
} {
    input.employment.has_employees == true
    is_retirement := object.get(input.employment, "employee_retiring", false)
    is_disability_pension := object.get(input.employment, "employee_disability_pension", false)
    severance_triggered := is_retirement | is_disability_pension
    severance_triggered == true

    severance_type = "EMERYTALNA" { is_retirement == true }
    severance_type = "RENTOWA" { is_disability_pension == true }
    monthly_wage := object.get(input.employment, "employee_monthly_wage", 5000)
    severance_amount = monthly_wage
    tax_info = "Zwolnione z PIT do limitu"
}

# ══════ P777: mpips_jubilee_award — Nagroda jubileuszowa ══════
else := {
    "matched": true, "rule_id": "jdg.mpips.jubilee_award",
    "package": "jdg.mpips", "priority": 777,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mpips_jubilee_years": jubilee_years, "mpips_jubilee_award_pct": award_pct,
    "mpips_jubilee_amount": floor(monthly_wage * award_pct / 100),
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 77² Kodeksu Pracy (zakładowe układy zbiorowe)",
    "_warnings": [sprintf("NAGRODA JUBILEUSZOWA — %d lat stażu. %d%% wynagrodzenia = %.2f PLN. Obowiązkowa jeśli przewidziana w regulaminie/układzie zbiorowym.", [jubilee_years, award_pct, floor(monthly_wage * award_pct / 100)])]
} {
    input.employment.has_employees == true
    jubilee_years := object.get(input.employment, "jubilee_qualifying_years", 0)
    jubilee_years >= 10
    has_regulation := object.get(input.employment, "has_jubilee_regulation", false)
    has_regulation == true

    award_pct = 75 { jubilee_years >= 10; jubilee_years < 20 }
    award_pct = 100 { jubilee_years >= 20; jubilee_years < 25 }
    award_pct = 150 { jubilee_years >= 25; jubilee_years < 30 }
    award_pct = 200 { jubilee_years >= 30; jubilee_years < 35 }
    award_pct = 300 { jubilee_years >= 35; jubilee_years < 40 }
    award_pct = 400 { jubilee_years >= 40 }
    monthly_wage := object.get(input.employment, "employee_monthly_wage", 5000)
}

# ══════ P778: mpips_bhp_training_fund — Fundusz szkoleń BHP ══════
else := {
    "matched": true, "rule_id": "jdg.mpips.bhp_training_fund",
    "package": "jdg.mpips", "priority": 778,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mpips_bhp_training_required": true, "mpips_bhp_initial_hours": 8,
    "mpips_bhp_periodic_hours": periodic_hours,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Szkolenie BHP — obowiązek pracodawcy",
    "_legal_basis": "Art. 237³ KP, Rozporządzenie w sprawie szkolenia BHP",
    "_warnings": [sprintf("SZKOLENIE BHP — %d pracowników wymaga szkolenia. Wstępne: min. 8h. Okresowe: %dh co %d lata. Pracodawca ponosi koszt!", [workers_to_train, periodic_hours, periodic_years])]
} {
    input.employment.has_employees == true
    workers_to_train := object.get(input.employment, "bhp_workers_requiring_training", 0)
    workers_to_train > 0
    is_office := object.get(input.employment, "bhp_office_workers", true)
    periodic_hours = 8 { is_office == true }
    periodic_hours = 16 { is_office == false }
    periodic_years = 5 { is_office == true }
    periodic_years = 3 { is_office == false }
}

# ══════ P779: mpips_maternity_leave_topup — Uzupełnienie zasiłku macierzyńskiego ══════
else := {
    "matched": true, "rule_id": "jdg.mpips.maternity_leave_topup",
    "package": "jdg.mpips", "priority": 779,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mpips_maternity_topup_pct": topup_pct,
    "mpips_maternity_topup_amount": topup_amount,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 184 KP, Ustawa o świadczeniach pieniężnych z ubezp. społ.",
    "_warnings": [sprintf("UZUPEŁNIENIE MACIERZYŃSKIEGO — ZUS płaci 100%% podstawy. Pracodawca może uzupełnić do %.0f%% wynagrodzenia (%.2f PLN/mies.). Dobrowolne.", [100 + topup_pct, topup_amount])]
} {
    input.employment.has_employees == true
    input.employment.employee_on_maternity_leave == true
    has_topup_policy := object.get(input.employment, "has_maternity_topup_policy", false)
    has_topup_policy == true
    topup_pct := object.get(input.employment, "maternity_topup_percent", 20)
    base_wage := object.get(input.employment, "employee_monthly_wage", 5000)
    topup_amount = base_wage * topup_pct / 100
}

# ══════ P780: mpips_parental_leave — Urlop rodzicielski i ojcowski ══════
else := {
    "matched": true, "rule_id": "jdg.mpips.parental_leave",
    "package": "jdg.mpips", "priority": 780,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mpips_parental_leave_type": leave_type, "mpips_parental_weeks": weeks,
    "mpips_parental_payment_pct": pay_pct,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 182¹a-182¹e KP, Art. 182³ KP (ojcowski)",
    "_warnings": [sprintf("URLOP %s — %d tygodni. Płatność: %d%% podstawy (ZUS). Pracodawca udziela, ZUS płaci.", [leave_type, weeks, pay_pct])]
} {
    input.employment.has_employees == true
    is_parental := object.get(input.employment, "employee_parental_leave_requested", false)
    is_paternity := object.get(input.employment, "employee_paternity_leave_requested", false)
    leave_triggered := is_parental | is_paternity
    leave_triggered == true

    leave_type = "RODZICIELSKI" { is_parental == true }
    leave_type = "OJCOWSKI" { is_paternity == true }
    weeks = 32 { is_parental == true }
    weeks = 2 { is_paternity == true }
    pay_pct = 70 { is_parental == true }
    pay_pct = 100 { is_paternity == true }
}

# ══════ P781: mpips_childcare_subsidy — Dofinansowanie opieki nad dziećmi ══════
else := {
    "matched": true, "rule_id": "jdg.mpips.childcare_subsidy",
    "package": "jdg.mpips", "priority": 781,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mpips_childcare_subsidy_amount": subsidy_total,
    "mpips_childcare_subsidy_per_child": subsidy_per_child,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 12a Ustawy o opiece nad dziećmi do lat 3, ZFŚS",
    "_warnings": [sprintf("DOFINANSOWANIE ŻŁOBKA/PRZEDSZKOLA — %d dzieci × %.2f PLN = %.2f PLN/mies. Ze środków ZFŚS lub przychodu. Limit: 1000 PLN/dziecko/mies.", [children_count, subsidy_per_child, subsidy_total])]
} {
    input.employment.has_employees == true
    children_count := object.get(input.employment, "childcare_eligible_children", 0)
    children_count > 0
    subsidy_per_child := object.get(input.employment, "childcare_subsidy_per_child", 300)
    subsidy_total = children_count * subsidy_per_child
}
