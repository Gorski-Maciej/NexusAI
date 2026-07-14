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

# ══ P1212e: employer_ppk_auto_enrollment — PPK auto-zapis + składki ══
else := {
    "matched":true,"rule_id":"jdg.employer.ppk_auto_enrollment",
    "package":"jdg.employer","priority":1212,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"PPK_EMPLOYER","zus_health_rate":"",
    "business_status":"","employment_tax_obligation":"PPK_REPORTING",
    "ppk_employer_pct":1.5,"ppk_employee_pct":2.0,"ppk_auto_enrolled":true,
    "_routing":"","_routing_reason":"PPK auto-zapis — employee ≥3 months, opt-out window 30+7 days",
    "_legal_basis":"Art. 31-32 ustawy o PPK",
    "_warnings":["PPK — wpłata podstawowa pracodawcy 1.5% + pracownik 2.0% (możliwość obniżenia do 0.5%). Składki PPK nie wlicza się do podstawy ZUS! Auto-zapis po 3 mies. zatrudnienia. Okno opt-out: 30 dni + 7 dni na rezygnację."]
} {
    input.employment.ppk_enabled == true
    input.employment.employee_count >= 1
    not input.employment.ppk_employee_opted_out
}

# ══ P1213e: employer_ppk_opt_out — PPK rezygnacja pracownika (opt-out) ══
else := {
    "matched":true,"rule_id":"jdg.employer.ppk_opt_out",
    "package":"jdg.employer","priority":1213,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"PPK_EMPLOYER","zus_health_rate":"",
    "business_status":"","employment_tax_obligation":"PPK_REPORTING",
    "ppk_employer_pct":1.5,"ppk_employee_pct":0.0,"ppk_opt_out":true,
    "_routing":"","_routing_reason":"PPK opt-out — pracownik zrezygnował, składka pracownika 0%",
    "_legal_basis":"Art. 32 ust. 3-4 ustawy o PPK",
    "_warnings":["PPK opt-out — pracownik złożył rezygnację. Pracodawca nadal wpłaca 1.5%. Co 4 lata ponowny auto-zapis!"]
} {
    input.employment.ppk_enabled == true
    input.employment.ppk_employee_opted_out == true
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

# ══ P1218e: employer_peron_contribution — PFRON ≥25 pracowników ══
else := {
    "matched":true,"rule_id":"jdg.employer.peron_contribution",
    "package":"jdg.employer","priority":1218,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","employment_tax_obligation":"PFRON_MONTHLY",
    "peron_quota_pct":6,"peron_threshold_employees":25,
    "peron_disabled_employed":0,"peron_contribution_due_pln":0,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"PFRON — ≥25 pracowników, obowiązek wpłat lub zatrudnienia 6% ON",
    "_legal_basis":"Art. 21 ustawy o rehabilitacji zawodowej i społecznej oraz zatrudnianiu osób niepełnosprawnych",
    "_warnings":["PFRON — ≥25 pracowników. Wymagane 6% zatrudnienia osób niepełnosprawnych LUB miesięczna wpłata na PFRON. Deklaracja DEK-I-a do 20-go."]
} {
    input.employment.employee_count >= 25
    input.employment.has_employees == true
    not input.employment.purchases_from_zpch_this_period
}

# ══ P1219e: employer_peron_exemption_zpch — PFRON ulga ZPCh ══
else := {
    "matched":true,"rule_id":"jdg.employer.peron_exemption_zpch",
    "package":"jdg.employer","priority":1219,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","employment_tax_obligation":"PFRON_EXEMPTION_ZPCH",
    "peron_exemption_type":"ZPCH_PURCHASE","peron_contribution_reduction_pct":100,
    "_routing":"","_routing_reason":"PFRON — ulga za zakupy od ZPCh (zakład pracy chronionej)",
    "_legal_basis":"Art. 22 ustawy o rehabilitacji",
    "_warnings":["PFRON ulga ZPCh — zakup od zakładu pracy chronionej. Wymagana faktura VAT z adnotacją ZPCh. Ulga pomniejsza wpłatę na PFRON."]
} {
    input.employment.employee_count >= 25
    input.employment.purchases_from_zpch_this_period == true
}

# ══ P1222e: employer_ohs_medical_exams_kup — Badania BHP i medycyna pracy 100% KUP ══
else := {
    "matched":true,"rule_id":"jdg.employer.ohs_medical_exams_kup",
    "package":"jdg.employer","priority":1222,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"KUP_FULL","kus_percent":100,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","employment_tax_obligation":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 229 KP w zw. z Art. 22 ust. 1 PIT",
    "_warnings":["Badania BHP i medycyna pracy → 100% KUP jako koszt obowiązkowy pracodawcy. Dotyczy: badań wstępnych, okresowych, kontrolnych. Wymagane skierowanie na badania."]
} {
    input.employment.has_employees == true
    input.invoice.category_code == "MEDICAL_EXAMS_OHS"
    input.employment.ohs_exams_mandatory == true
}

# ══ P1220e: employer_small_mandate_flat_tax — Małe zlecenie ≤200 PLN ryczałt ══
else := {
    "matched":true,"rule_id":"jdg.employer.small_mandate_flat_tax",
    "package":"jdg.employer","priority":1220,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"17%_RYCZAŁT","pit_bracket":"","pit_annual_return_type":"PIT-8AR",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","employment_tax_obligation":"SMALL_MANDATE_FLAT",
    "small_mandate_threshold_pln":200,"small_mandate_rate_pct":17,
    "_routing":"","_routing_reason":"Małe zlecenie ≤200 PLN — ryczałt 17% bez KUP, bez ZUS",
    "_legal_basis":"Art. 30 ust. 1 pkt 5a PIT",
    "_warnings":["Małe zlecenie ≤200 PLN — ryczałt 17%. BRAK KUP! BRAK składek ZUS (jeśli jedyny tytuł). PIT-8AR rocznie. Suma umów do jednego zleceniobiorcy ≤200 PLN miesięcznie dla tej stawki."]
} {
    input.employment.contract_type == "CIVIL_LAW"
    input.employment.contract_amount_gross <= 200
    not input.employment.has_other_insurance_title
}

# ══ P1223: employer_obligations_checklist — Pełna checklista JDG z pracownikami (Doc 35) ══
else := {
    "matched":true,"rule_id":"jdg.employer.obligations_checklist",
    "package":"jdg.employer","priority":1223,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","employment_tax_obligation":"FULL_CHECKLIST",
    "pit4r_required":true,"pit11_required":true,"pit8ar_required":true,
    "zus_dra_required":true,"zus_rca_required":true,"ppk_required":true,
    "bhp_training_required":true,"ohs_exams_required":true,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"JDG z pracownikami — pełna lista obowiązków",
    "_legal_basis":"Art. 38, 39, 42 PIT + Art. 46-47 SUS + Art. 31-32 PPK + Art. 237³ KP",
    "_warnings":["JDG z pracownikami — obowiązki: PIT-4R (mies.), PIT-11 (do 28.02), PIT-8AR (do 31.01), ZUS DRA (mies.), ZUS RCA (mies.), PPK (auto-zapis), szkolenia BHP, badania medycyny pracy, PFRON (≥25 os.)."]
} {
    input.employment.has_employees == true
    object.get(input.employment,"employee_count",0)>=1
    object.get(input.employment,"obligations_checklist_reviewed",true)==false
}

# ══════ P470-P477: EMPLOYER SZCZEGÓŁY — Doc 36 §16 (8 reguł) ══════

# P470: employer_zus_dra_monthly — ZUS DRA miesięczna
else := {
    "matched":true,"rule_id":"jdg.employer.zus_dra_monthly",
    "package":"jdg.employer","priority":470,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","zus_dra_required":true,"dra_deadline":"10th_or_15th",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 46 SUS",
    "_warnings":["ZUS DRA — deklaracja rozliczeniowa miesięczna. Termin: 10. (osoby fizyczne) lub 15. (jednostki budżetowe)."]
} {
    input.employment.has_employees==true
}

# P471: employer_zus_rca_reporting — ZUS RCA raport imienny
else := {
    "matched":true,"rule_id":"jdg.employer.zus_rca_reporting",
    "package":"jdg.employer","priority":471,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","zus_rca_required":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 40 SUS",
    "_warnings":["ZUS RCA — raport imienny o składkach za każdego pracownika. Co miesiąc razem z DRA."]
} {
    input.employment.has_employees==true
}

# P472: employer_pit11_annual — PIT-11 do 28 lutego
else := {
    "matched":true,"rule_id":"jdg.employer.pit11_annual",
    "package":"jdg.employer","priority":472,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","pit11_required":true,"pit11_deadline":"FEBRUARY_28",
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"PIT-11 — termin do 28 lutego!",
    "_legal_basis":"Art. 39 ust. 1 PIT",
    "_warnings":["PIT-11 — informacja dla pracownika do 28 lutego. Opóźnienie = grzywna!"]
} {
    input.employment.has_employees==true
    input.calendar.month==2
    input.calendar.day_of_month>=20
    object.get(input.employment,"pit11_filed",true)==false
}

# P473: employer_zus_zua_registration — Zgłoszenie pracownika w 7 dni
else := {
    "matched":true,"rule_id":"jdg.employer.zus_zua_registration",
    "package":"jdg.employer","priority":473,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","zua_deadline_days":7,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Nowy pracownik — zgłoś ZUS ZUA w 7 dni!",
    "_legal_basis":"Art. 36 ust. 1 SUS",
    "_warnings":["ZUS ZUA — zgłoszenie nowego pracownika do ubezpieczeń w ciągu 7 dni od zatrudnienia. Opóźnienie = kara!"]
} {
    object.get(input.employment,"new_employee_pending_registration",false)==true
}

# P474: employer_ppk_auto_enrollment — PPK auto-zapis
else := {
    "matched":true,"rule_id":"jdg.employer.ppk_auto_enrollment",
    "package":"jdg.employer","priority":474,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ppk_auto_enrolled":true,"ppk_opt_out_window_days":37,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 32 ustawy o PPK",
    "_warnings":["PPK — automatyczny zapis pracownika po 3 miesiącach. Pracownik może zrezygnować (opt-out) w ciągu 30+7 dni."]
} {
    input.employment.has_employees==true
    object.get(input.employment,"ppk_enabled",false)==true
    not input.employment.ppk_employee_opted_out
}

# P475: employer_osh_training — Szkolenie BHP
else := {
    "matched":true,"rule_id":"jdg.employer.osh_training_obligation",
    "package":"jdg.employer","priority":475,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","osh_training_required":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 237³ KP",
    "_warnings":["Szkolenie BHP — wstępne (przed rozpoczęciem pracy) + okresowe. Wymagane dla każdego pracownika. KUP 100%."]
} {
    input.employment.has_employees==true
    object.get(input.employment,"osh_training_overdue",false)==true
}

# P476: employer_peron_contribution — PFRON ≥25 pracowników
else := {
    "matched":true,"rule_id":"jdg.employer.peron_contribution",
    "package":"jdg.employer","priority":476,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","peron_required":true,"peron_threshold":25,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"PFRON ≥25 pracowników",
    "_legal_basis":"Art. 21 ustawy PFRON",
    "_warnings":["PFRON — ≥25 pracowników. Wymagane 6% zatrudnienia ON lub miesięczna wpłata. DEK-I-a do 20-go."]
} {
    input.employment.employee_count>=25
}

# P477: employer_work_fund — Fundusz Pracy, FGŚP, FS
else := {
    "matched":true,"rule_id":"jdg.employer.work_fund_obligations",
    "package":"jdg.employer","priority":477,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"FP_FGSP_FS","zus_health_rate":"",
    "business_status":"","fp_rate_pct":2.45,"fgsp_rate_pct":0.10,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 104-107 ustawy o promocji zatrudnienia",
    "_warnings":["Fundusz Pracy 2.45% + FGŚP 0.10% + Fundusz Solidarnościowy. Składki pracodawcy od wynagrodzeń."]
} {
    input.employment.has_employees==true
}
