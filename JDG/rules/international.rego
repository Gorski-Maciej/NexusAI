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
