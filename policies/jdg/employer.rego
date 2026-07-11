# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Wynagrodzenia, umowy cywilne, 50% KUP (P1200e-P1223)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.employer
#
# METADATA
# title: JDG Package — employer
# description: Supporting package for JDG Multi-Pass evaluation (ADR-001).
# architecture: Multi-Pass (ADR-001)
# package: jdg.employer
# deprecated: false
#
import data.jdg.helpers
default decide := {"matched":false,"rule_id":"jdg.employer.no_match","package":"jdg.employer","priority":1233}

# ══ P1200e: employer_creative_kup_50 — Podwyższone 50% KUP (twórcy) ══
decide := {
    "matched":true,"rule_id":"jdg.employer.creative_kup_50",
    "package":"jdg.employer","priority":1200,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"KUP_CREATIVE","kus_percent":50,"kup_monthly_cap_pln":120000,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","employment_tax_obligation":"PIT-4R_MONTHLY",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22 ust. 9 pkt 3 PIT",
    "_warnings":["50% KUP dla twórców. Limit miesięczny: ½ kwoty z art. 22 ust. 9a (120 000 PLN/rok). Wymagana dokumentacja przeniesienia praw autorskich."]
} {
    input.employment.contract_type == "EMPLOYMENT"
    input.employment.has_copyright_transfer == true
}

# ══ P1202e: employer_standard_kup_250 — Standardowe KUP 250 PLN ══
else := {
    "matched":true,"rule_id":"jdg.employer.standard_kup_250",
    "package":"jdg.employer","priority":1202,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"KUP_STANDARD","kus_percent":0,"kup_monthly_amount_pln":250,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","employment_tax_obligation":"PIT-4R_MONTHLY",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22 ust. 2 PIT",
    "_warnings":["Standardowe KUP: 250 PLN miesięcznie przy jednym pracodawcy. 300 PLN przy dojeździe z innej miejscowości."]
} {
    input.employment.contract_type == "EMPLOYMENT"
    not input.employment.has_copyright_transfer
}

# ══ P1204e: employer_kup_300_commuting — Podwyższone KUP 300 PLN (dojazd) ══
else := {
    "matched":true,"rule_id":"jdg.employer.kup_300_commuting",
    "package":"jdg.employer","priority":1204,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"KUP_COMMUTING","kus_percent":0,"kup_monthly_amount_pln":300,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","employment_tax_obligation":"PIT-4R_MONTHLY",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22 ust. 2 pkt 3 PIT",
    "_warnings":["Podwyższone KUP 300 PLN — dojazd z innej miejscowości. Pracownik nie otrzymuje dodatku za rozłąkę."]
} {
    input.employment.contract_type == "EMPLOYMENT"
    input.employment.commute_from_other_city == true
    not input.employment.receives_separation_allowance
}

# ══ P1206e: employer_multiple_contracts_kup — Wieloetatowość — suma KUP ══
else := {
    "matched":true,"rule_id":"jdg.employer.multiple_contracts_kup",
    "package":"jdg.employer","priority":1206,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"KUP_MULTIPLE","kus_percent":0,"kup_yearly_cap_pln":4500,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","employment_tax_obligation":"PIT-4R_MONTHLY",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22 ust. 2 pkt 4 PIT",
    "_warnings":["Wieloetatowość. Suma KUP nie może przekroczyć rocznie 4 500 PLN dla wszystkich stosunków pracy. Limit łączy się z 50% KUP!"]
} {
    input.employment.contract_count > 1
}

# ══ P1208e: employer_civil_law_contract_20 — Umowa zlecenie — 20% KUP ══
else := {
    "matched":true,"rule_id":"jdg.employer.civil_law_contract_20",
    "package":"jdg.employer","priority":1208,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"KUP_CIVIL_LAW_20","kus_percent":20,"kup_monthly_amount_pln":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","employment_tax_obligation":"PIT-8AR_ANNUAL",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22 ust. 9 pkt 4 PIT",
    "_warnings":["Umowa zlecenie/o dzieło — 20% KUP. PIT-8AR rocznie do 31 stycznia za poprzedni rok."]
} {
    input.employment.contract_type == "CIVIL_LAW"
    not input.employment.has_copyright_transfer
}

# ══ P1210e: employer_civil_law_creative_50 — Umowa cywilna z przeniesieniem praw — 50% ══
else := {
    "matched":true,"rule_id":"jdg.employer.civil_law_creative_50",
    "package":"jdg.employer","priority":1210,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"KUP_CREATIVE_CIVIL_LAW","kus_percent":50,"kup_yearly_cap_pln":120000,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","employment_tax_obligation":"PIT-8AR_ANNUAL",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22 ust. 9 pkt 3 PIT",
    "_warnings":["Umowa cywilna z prawami autorskimi — 50% KUP. Wspólny roczny limit z umowami o pracę (120 000 PLN)."]
} {
    input.employment.contract_type == "CIVIL_LAW"
    input.employment.has_copyright_transfer == true
}

# ══ P1212e: employer_ppk_contributions — Pracownicze Plany Kapitałowe ══
else := {
    "matched":true,"rule_id":"jdg.employer.ppk_contributions",
    "package":"jdg.employer","priority":1212,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"PPK_EMPLOYER","zus_health_rate":"",
    "business_status":"","employment_tax_obligation":"PPK_REPORTING",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Ustawa o PPK",
    "_warnings":["PPK — wpłata podstawowa pracodawcy 1.5% + pracownik 2.0% (możliwość obniżenia do 0.5%). Składki PPK nie wlicza się do podstawy ZUS!"]
} {
    input.employment.ppk_enabled == true
}

# ══ P1214e: employer_pit4r_monthly — PIT-4R obowiązek miesięczny ══
else := {
    "matched":true,"rule_id":"jdg.employer.pit4r_monthly",
    "package":"jdg.employer","priority":1214,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","employment_tax_obligation":"PIT-4R_MONTHLY",
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"PIT-4R termin: do 20-go następnego miesiąca",
    "_legal_basis":"Art. 38 ust. 1 PIT",
    "_warnings":["PIT-4R — deklaracja miesięczna. Termin: 20 dzień miesiąca następnego. Zaliczka PIT od wynagrodzeń."]
} {
    input.employment.has_employees == true
    input.calendar.day_of_month >= 15
    input.calendar.day_of_month <= 20
    input.employment.pit4r_current_month_filed == false
}

# ══ P1216e: employer_annual_pit_summary — PIT-4R + PIT-8AR roczne podsumowanie ══
else := {
    "matched":true,"rule_id":"jdg.employer.annual_pit_summary",
    "package":"jdg.employer","priority":1216,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","employment_tax_obligation":"PIT-4R_ANNUAL_AND_8AR",
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Termin PIT-4R roczny i PIT-8AR — 31 stycznia za poprzedni rok",
    "_legal_basis":"Art. 38 ust. 1a i Art. 42 ust. 1a PIT",
    "_warnings":["PIT-4R roczny do 31 stycznia. PIT-8AR do 31 stycznia. PIT-11 do pracownika do 28 lutego."]
} {
    input.employment.has_employees == true
    input.calendar.month == 1
    input.calendar.day_of_month >= 20
}
