# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — International: WHT, zakład (PE), ceny transferowe (P100-P117)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.international

import future.keywords.in
#
# Documentation metadata (ordinary comments; legacy text is not OPA annotation YAML).
# title: JDG Package — international
# description: Supporting package for JDG Multi-Pass evaluation (ADR-001).
# architecture: Multi-Pass (ADR-001)
# package: jdg.international
# deprecated: false
#
import data.jdg.helpers
default decide := {"matched":false,"rule_id":"jdg.international.no_match","package":"jdg.international","priority":127}

# ══════ P100: wht_obligation_detection — Obowiązek poboru WHT ══════
decide := {
    "matched":true,"rule_id":"jdg.international.wht_obligation",
    "package":"jdg.international","priority":100,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","wht_required":true,"wht_rate":"0.20",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 30a PIT, art. 21 CIT",
    "_warnings":["WHT — obowiązek poboru podatku u źródła 20% (lub stawka z UPO)"]
} {
    input.invoice.direction == "PURCHASE"
    not input.vendor.country in {"PL"}
    input.invoice.expense_type in {"ROYALTIES","INTEREST","DIVIDENDS","SERVICES","LICENSES"}
}

# ══════ P114: tp_documentation_threshold — Obowiązek dokumentacji TP ══════
else := {
    "matched":true,"rule_id":"jdg.international.tp_documentation_threshold",
    "package":"jdg.international","priority":114,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","tp_documentation_required":true,"tp_threshold":100000,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 23q-23zf PIT",
    "_warnings":["Ceny transferowe — obowiązek dokumentacji TP dla transakcji z podmiotami powiązanymi > 100 000 PLN"]
} {
    input.vendor.is_related_party == true
    input.invoice.amount_net >= 100000
}

# ══════ P110: permanent_establishment_risk — Ryzyko zakładu (PE) ══════
else := {
    "matched":true,"rule_id":"jdg.international.pe_risk",
    "package":"jdg.international","priority":110,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","pe_risk":true,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Ryzyko powstania zakładu (PE) za granicą",
    "_legal_basis":"Art. 5 umów o unikaniu podwójnego opodatkowania",
    "_warnings":["Ryzyko PE — praca za granicą > 6 miesięcy może skutkować powstaniem zakładu!"]
} {
    input.jdg_entrepreneur.days_abroad > 180
}

# ══════ P102: tp_safe_harbour_low_value — Safe harbour 5% TP ══════
else := {
    "matched":true,"rule_id":"jdg.international.tp_safe_harbour_low_value",
    "package":"jdg.international","priority":102,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","tp_safe_harbour_applied":true,"tp_markup":"0.05",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 23zf PIT",
    "_warnings":["Safe harbour TP — usługi niskowartościowe, narzut 5%"]
} {
    input.vendor.is_related_party == true
    input.invoice.expense_type in {"CONSULTING","MARKETING","MANAGEMENT"}
    input.invoice.amount_net < 2000000
}

# ══════ P460-P467: WHT SZCZEGÓŁY — Doc 36 §15 (8 reguł) ══════

# P460: wht_dividend_19pct — Dywidendy 19% WHT
else := {
    "matched":true,"rule_id":"jdg.international.wht_dividend_19pct",
    "package":"jdg.international","priority":460,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"PIT-8AR",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","wht_type":"DIVIDEND","wht_rate_pct":19,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 30a ust. 1 pkt 4 PIT",
    "_warnings":["WHT 19% — dywidendy wypłacane za granicę. Pobierz podatek i złóż PIT-8AR do końca stycznia."]
} {
    input.invoice.direction=="PURCHASE"
    input.invoice.expense_type=="DIVIDEND"
    input.vendor.country!="PL"
}

# P461: wht_interest_20pct — Odsetki 20% WHT
else := {
    "matched":true,"rule_id":"jdg.international.wht_interest_20pct",
    "package":"jdg.international","priority":461,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"PIT-8AR",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","wht_type":"INTEREST","wht_rate_pct":20,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 30a ust. 1 pkt 1 PIT",
    "_warnings":["WHT 20% — odsetki wypłacane za granicę. PIT-8AR do końca stycznia. Sprawdź UPO — może być obniżona stawka."]
} {
    input.invoice.direction=="PURCHASE"
    input.invoice.expense_type=="INTEREST"
    input.vendor.country!="PL"
}

# P462: wht_royalties_20pct — Należności licencyjne 20% WHT
else := {
    "matched":true,"rule_id":"jdg.international.wht_royalties_20pct",
    "package":"jdg.international","priority":462,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"PIT-8AR",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","wht_type":"ROYALTIES","wht_rate_pct":20,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 30a ust. 1 pkt 2 PIT",
    "_warnings":["WHT 20% — należności licencyjne (prawa autorskie, patenty, znaki towarowe). Sprawdź umowę UPO — możliwa stawka 5% lub 10%."]
} {
    input.invoice.direction=="PURCHASE"
    input.invoice.expense_type in {"ROYALTIES","LICENSES","PATENTS"}
    input.vendor.country!="PL"
}

# P463: wht_dtt_reduced_rate — Stawka z umowy UPO
else := {
    "matched":true,"rule_id":"jdg.international.wht_treaty_rate",
    "package":"jdg.international","priority":463,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","treaty_rate_applies":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Umowy UPO",
    "_warnings":[sprintf("UMOWA UPO — stawka z umowy dla %s może być niższa (5%%/10%%/15%%) niż standardowa. Wymagany certyfikat rezydencji kontrahenta.",[country])]
} {
    country:=object.get(input.vendor,"country","")
    country!="PL"
    object.get(input.vendor,"has_dtt_treaty",false)==true
    object.get(input.invoice,"wht_obligation",false)==true
}

# P464: wht_certificate_of_residence — Certyfikat rezydencji
else := {
    "matched":true,"rule_id":"jdg.international.wht_certificate_of_residence",
    "package":"jdg.international","priority":464,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","certificate_of_residence_required":true,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Brak certyfikatu rezydencji — brak preferencji UPO",
    "_legal_basis":"Art. 30a ust. 2 PIT",
    "_warnings":[sprintf("CERTYFIKAT REZYDENCJI — wymagany od kontrahenta z %s dla zastosowania stawki z UPO. Bez certyfikatu: stawka standardowa (19%% lub 20%%).",[country])]
} {
    country:=object.get(input.vendor,"country","PL")
    country!="PL"
    object.get(input.invoice,"wht_obligation",false)==true
    object.get(input.vendor,"certificate_of_residence_valid",true)==false
}

# P465: wht_due_diligence — Należyta staranność (beneficial owner)
else := {
    "matched":true,"rule_id":"jdg.international.wht_due_diligence",
    "package":"jdg.international","priority":465,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","due_diligence_required":true,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Należyta staranność WHT — beneficial owner",
    "_legal_basis":"Art. 26 ust. 2e CIT",
    "_warnings":["NALEŻYTA STARANNOŚĆ WHT — sprawdź czy kontrahent jest rzeczywistym właścicielem (beneficial owner). Bez weryfikacji ryzyko odpowiedzialności solidarnej!"]
} {
    object.get(input.invoice,"wht_amount",0)>2000000
    object.get(input.jdg_entrepreneur,"wht_due_diligence_done",true)==false
}

# P467: wht_pay_and_refund — Mechanizm pay-and-refund >2M PLN
else := {
    "matched":true,"rule_id":"jdg.international.wht_pay_and_refund",
    "package":"jdg.international","priority":467,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","pay_and_refund_active":true,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"WHT >2M PLN — mechanizm pay-and-refund",
    "_legal_basis":"Art. 26 ust. 2e CIT",
    "_warnings":[sprintf("WHT PAY-AND-REFUND — wypłata %.2f PLN > 2M PLN. Pobierz pełny WHT, złóż wniosek o zwrot z powołaniem na UPO.",[wht_amt])]
} {
    wht_amt:=object.get(input.invoice,"wht_amount",0)
    wht_amt>2000000
}

# ══════ P470-P479: ROZSZERZENIE INTERNATIONAL — UPO, IFT-2R, PE Fixed-Base (Raport P26 R9) ══════

# P470: upo_treaty_database_lookup — Baza UPO — stawki per kraj
else := {
    "matched":true,"rule_id":"jdg.international.upo_treaty_lookup",
    "package":"jdg.international","priority":470,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","upo_country":country,"upo_dividend_rate_pct":div_rate,
    "upo_interest_rate_pct":int_rate,"upo_royalties_rate_pct":roy_rate,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Konwencja MLI + bilateralne UPO",
    "_warnings":[sprintf("UPO lookup — %s: dywidendy %d%%, odsetki %d%%, należności licencyjne %d%%. Wymagany certyfikat rezydencji.",[country,div_rate,int_rate,roy_rate])]
} {
    country:=object.get(input.vendor,"country","")
    country!="PL"
    object.get(input.vendor,"has_treaty",false)==true

    # UPO Treaty Database (P26 R9 — mapa stawek per kraj)
    treaties := {
        "DE": {"dividend": 5, "interest": 5, "royalties": 5},
        "GB": {"dividend": 10, "interest": 5, "royalties": 5},
        "FR": {"dividend": 5, "interest": 5, "royalties": 10},
        "US": {"dividend": 15, "interest": 0, "royalties": 10},
        "NL": {"dividend": 5, "interest": 5, "royalties": 5},
        "CZ": {"dividend": 5, "interest": 5, "royalties": 10},
        "SK": {"dividend": 5, "interest": 5, "royalties": 5},
        "UA": {"dividend": 5, "interest": 10, "royalties": 10},
        "IT": {"dividend": 10, "interest": 10, "royalties": 10},
        "AT": {"dividend": 5, "interest": 5, "royalties": 5},
        "BE": {"dividend": 5, "interest": 5, "royalties": 5},
        "SE": {"dividend": 5, "interest": 5, "royalties": 5}
    }

    treaty := object.get(treaties, country, {"dividend": 20, "interest": 20, "royalties": 20})
    div_rate := object.get(treaty, "dividend", 20)
    int_rate := object.get(treaty, "interest", 20)
    roy_rate := object.get(treaty, "royalties", 20)
}

# P471: ift2r_filing_obligation — Obowiązek złożenia IFT-2R
else := {
    "matched":true,"rule_id":"jdg.international.ift2r_filing",
    "package":"jdg.international","priority":471,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"IFT-2R",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ift2r_required":true,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"IFT-2R — informacja o wypłatach na rzecz nierezydentów",
    "_legal_basis":"Art. 42 ust. 2 pkt 2 PIT (IFT-2R do końca lutego)",
    "_warnings":[sprintf("IFT-2R — złóż do końca lutego za poprzedni rok podatkowy dla wypłat do %s. Kwota: %.2f PLN. Dotyczy: dywidend, odsetek, należności licencyjnych.",[country,total_paid])]
} {
    country:=object.get(input.vendor,"country","")
    country!="PL"
    object.get(input.invoice,"wht_obligation",false)==true
    total_paid:=object.get(input.invoice,"amount_gross",0)
    total_paid>0
}

# P472: pe_fixed_base_risk — Ryzyko stałej placówki (fixed-base PE)
else := {
    "matched":true,"rule_id":"jdg.international.pe_fixed_base",
    "package":"jdg.international","priority":472,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","pe_fixed_base_risk":true,"pe_country":country,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Ryzyko stałej placówki (fixed-base PE) za granicą",
    "_legal_basis":"Art. 5 ust. 2 OECD Model Convention + UPO bilateralne",
    "_warnings":[sprintf("PE FIXED-BASE — %d dni w %s z użyciem stałego biura/placówki. Ryzyko opodatkowania dochodów w %s! Sprawdź definicję PE w UPO z %s.",[days_abroad,country,country,country])]
} {
    country:=object.get(input.jdg_entrepreneur,"abroad_country","")
    country!="PL"
    days_abroad:=object.get(input.jdg_entrepreneur,"days_abroad_in_country",0)
    days_abroad>90
    object.get(input.jdg_entrepreneur,"has_fixed_office_abroad",false)==true
}

# P473: pe_construction_site — PE budowlany — plac budowy > 12 miesięcy
else := {
    "matched":true,"rule_id":"jdg.international.pe_construction_site",
    "package":"jdg.international","priority":473,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","pe_construction_site":true,"pe_country":country,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"PE budowlany — plac budowy > 12 miesięcy",
    "_legal_basis":"Art. 5 ust. 3 OECD Model Convention (Construction PE)",
    "_warnings":[sprintf("PE BUDOWLANY — plac budowy/montaż w %s trwa %d miesięcy (>12). Powstaje zakład (PE)! Obowiązek rejestracji podatkowej i CIT w %s.",[country,months,country])]
} {
    country:=object.get(input.jdg_entrepreneur,"construction_abroad_country","")
    country!="PL"
    months:=object.get(input.jdg_entrepreneur,"construction_months_abroad",0)
    months>12
}

# P474: crossborder_vat_register — Obowiązek rejestracji VAT za granicą
else := {
    "matched":true,"rule_id":"jdg.international.crossborder_vat_register",
    "package":"jdg.international","priority":474,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","foreign_vat_registration_required":true,"foreign_country":country,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Rejestracja VAT za granicą — transakcje B2B w UE",
    "_legal_basis":"Dyrektywa VAT 2006/112/WE; Art. 28a VAT",
    "_warnings":[sprintf("VAT ZA GRANICĄ — %d transakcji B2B do %s przekracza próg. Obowiązek rejestracji VAT w %s (VAT OSS/IOSS lub rejestracja lokalna).",[eu_sales_count,country,country])]
} {
    country:=object.get(input.vendor,"country","")
    country!="PL"
    country in {"DE","FR","IT","ES","NL","BE","AT","CZ","SK","SE"}
    eu_sales_count:=object.get(input.jdg_entrepreneur,"eu_b2b_sales_count_12mo",0)
    eu_sales_count>0
    object.get(input.jdg_entrepreneur,"eu_vat_registered",false)==false
}
