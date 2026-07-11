# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Local: PCC, nieruchomości, transport (P1300-P1320)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.local
#
# METADATA
# title: JDG Package — local
# description: Supporting package for JDG Multi-Pass evaluation (ADR-001).
# architecture: Multi-Pass (ADR-001)
# package: jdg.local
# deprecated: false
#
import data.jdg.helpers
default decide := {"matched":false,"rule_id":"jdg.local.no_match","package":"jdg.local","priority":1330}

# ══════ P1300: pcc_mandatory — PCC 2% od zakupu od osób prywatnych ══════
decide := {
    "matched":true,"rule_id":"jdg.local.pcc_mandatory",
    "package":"jdg.local","priority":1300,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","local_tax_type":"PCC","local_tax_rate":"0.02",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Ustawa o podatku od czynności cywilnoprawnych",
    "_warnings":["PCC 2% — zakup od osoby prywatnej! Deklaracja PCC-3 w 14 dni."]
} {
    input.invoice.direction == "PURCHASE"
    input.vendor.is_company == false
    input.invoice.is_asset_purchase == true
}

# ══════ P1310: real_estate_commercial — Podatek od nieruchomości firmowych ══════
else := {
    "matched":true,"rule_id":"jdg.local.real_estate_commercial",
    "package":"jdg.local","priority":1310,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","local_tax_type":"REAL_ESTATE","local_tax_land_rate":1.15,"local_tax_building_rate":33.00,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Ustawa o podatkach i opłatach lokalnych",
    "_warnings":["Podatek od nieruchomości firmowych — deklaracja DN-1 do 31 stycznia"]
} {
    input.invoice.category_code == "REAL_ESTATE"
    input.invoice.is_commercial == true
}

# ══════ P1320: transport_tax — Podatek od środków transportowych ══════
else := {
    "matched":true,"rule_id":"jdg.local.transport_tax",
    "package":"jdg.local","priority":1320,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","local_tax_type":"TRANSPORT","local_tax_applicable":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Ustawa o podatkach i opłatach lokalnych",
    "_warnings":["Podatek od środków transportowych — deklaracja DT-1"]
} {
    input.invoice.category_code == "VEHICLE"
    input.invoice.vehicle_dmc >= 3.5
}
