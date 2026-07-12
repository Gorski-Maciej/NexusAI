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
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Obowiązek ZFŚS — zatrudnienie ≥20 etatów (lub ≥50 wg stanu na 1 stycznia)",
    "_legal_basis": "Art. 3-5 Ustawy o ZFŚS",
    "_warnings": [sprintf("ZFŚS — %d pracowników. Odpis podstawowy: %.2f PLN/rok (37.5%% przeciętnego wynagrodzenia na pracownika)", [emp_count, zfss_amount])]
} {
    emp_count := object.get(input.employment, "employee_count", 0)
    emp_count >= 20
    avg_wage := object.get(object.get(object.get(data.thresholds, "jdg", {}), "bounds", {}), "avg_monthly_wage", 7000)
    zfss_amount = emp_count * 0.375 * avg_wage
}
