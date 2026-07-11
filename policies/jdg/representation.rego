# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Pełnomocnictwa PPS-1, UPL-1, prokura (P1200-P1212)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.representation
#
# METADATA
# title: JDG Package — representation
# description: Supporting package for JDG Multi-Pass evaluation (ADR-001).
# architecture: Multi-Pass (ADR-001)
# package: jdg.representation
# deprecated: false
#
import data.jdg.helpers
default decide := {"matched":false,"rule_id":"jdg.representation.no_match","package":"jdg.representation","priority":1222}

# ══ P1200: power_of_attorney_PPS1 — Pełnomocnictwo ogólne PPS-1 ══
decide := {
    "matched":true,"rule_id":"jdg.representation.pps1_required",
    "package":"jdg.representation","priority":1200,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","representation_type":"PPS-1","representation_fee_pln":17,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"PPS-1 wymaga opłaty skarbowej 17 PLN",
    "_legal_basis":"Art. 138a § 1 Ordynacja podatkowa",
    "_warnings":["PPS-1 — pełnomocnictwo ogólne. Wymagana opłata skarbowa 17 PLN. Zgłoszenie przez ePUAP."]
} {
    input.representation.poa_type == "general"
    input.representation.poa_submitted == false
}

# ══ P1202: power_of_attorney_UPL1 — Pełnomocnictwo szczególne UPL-1 ══
else := {
    "matched":true,"rule_id":"jdg.representation.upl1_required",
    "package":"jdg.representation","priority":1202,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","representation_type":"UPL-1","representation_fee_pln":17,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"UPL-1 wymaga opłaty skarbowej 17 PLN",
    "_legal_basis":"Art. 138d § 1 Ordynacja podatkowa",
    "_warnings":["UPL-1 — pełnomocnictwo szczególne. Opłata skarbowa 17 PLN. Składane elektronicznie."]
} {
    input.representation.poa_type == "specific"
    input.representation.poa_submitted == false
}

# ══ P1204: poa_certified_accountant — Pełnomocnictwo dla doradcy podatkowego ══
else := {
    "matched":true,"rule_id":"jdg.representation.poa_certified_accountant",
    "package":"jdg.representation","priority":1204,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","representation_type":"UPL-1P","representation_fee_pln":0,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 138d § 2 Ordynacja podatkowa",
    "_warnings":["UPL-1P — doradca podatkowy/radca prawny/adwokat. Brak opłaty skarbowej."]
} {
    input.representation.representative_type in {"tax_advisor","attorney","legal_counsel"}
}

# ══ P1206: poa_revocation — Odwołanie pełnomocnictwa ══
else := {
    "matched":true,"rule_id":"jdg.representation.poa_revocation",
    "package":"jdg.representation","priority":1206,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","representation_type":"OPP-1","representation_fee_pln":0,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 138g Ordynacja podatkowa",
    "_warnings":["Odwołanie pełnomocnictwa — formularz OPP-1. Bez opłaty. Skuteczne z dniem doręczenia."]
} {
    input.representation.action == "REVOKE"
}

# ══ P1208: poa_change_scope — Zmiana zakresu pełnomocnictwa ══
else := {
    "matched":true,"rule_id":"jdg.representation.poa_change_scope",
    "package":"jdg.representation","priority":1208,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","representation_type":"UPL-1","representation_fee_pln":17,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 138f Ordynacja podatkowa",
    "_warnings":["Zmiana zakresu pełnomocnictwa — nowy formularz UPL-1. Opłata 17 PLN."]
} {
    input.representation.action == "MODIFY"
    input.representation.poa_type == "specific"
}

# ══ P1210: poa_automatic_expiry — Automatyczne wygaśnięcie ══
else := {
    "matched":true,"rule_id":"jdg.representation.poa_automatic_expiry",
    "package":"jdg.representation","priority":1210,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","representation_type":"","representation_fee_pln":0,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Pełnomocnictwo wygasło — wymagane odnowienie",
    "_legal_basis":"Art. 138h § 1 Ordynacja podatkowa",
    "_warnings":["Pełnomocnictwo wygasa z mocy prawa: śmierć mocodawcy/pełnomocnika, likwidacja JDG."]
} {
    input.representation.poa_valid == false
    input.representation.is_required == true
}

# ══ P1212: poa_cross_border — Pełnomocnictwo transgraniczne ══
else := {
    "matched":true,"rule_id":"jdg.representation.poa_cross_border",
    "package":"jdg.representation","priority":1212,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","representation_type":"PPS-1","representation_fee_pln":17,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 138a § 2 Ordynacja podatkowa + DAC6",
    "_warnings":["Pełnomocnictwo transgraniczne — dodatkowe wymogi DAC6. Tłumaczenie przysięgłe wymagane."]
} {
    input.representation.cross_border == true
}
