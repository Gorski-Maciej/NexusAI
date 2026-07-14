# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — International: WHT, zakład (PE), ceny transferowe (P100-P117)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.international
#
# METADATA
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
    input.vendor.country not in {"PL"}
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

# ══════ P29: tp_safe_harbour_low_value — Safe harbour 5% TP ══════
else := {
    "matched":true,"rule_id":"jdg.international.tp_safe_harbour_low_value",
    "package":"jdg.international","priority":29,
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
