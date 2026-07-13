# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — BDO, KOBiZE, opłaty środowiskowe (P1400-P1407)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.environmental
#
# METADATA
# title: JDG Package — environmental
# description: Supporting package for JDG Multi-Pass evaluation (ADR-001).
# architecture: Multi-Pass (ADR-001)
# package: jdg.environmental
# deprecated: false
#
import data.jdg.helpers
default decide := {"matched":false,"rule_id":"jdg.environmental.no_match","package":"jdg.environmental","priority":1417}

# ══ P1400: bdo_registration_required — BDO — rejestracja obowiązkowa ══
decide := {
    "matched":true,"rule_id":"jdg.environmental.bdo_registration_required",
    "package":"jdg.environmental","priority":1400,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","environmental_obligation":"BDO_REGISTERED","bdo_fee_pln":300,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Brak rejestracji BDO — obowiązek dla wytwórców odpadów",
    "_legal_basis":"Art. 49 ust. 1 Ustawy o odpadach",
    "_warnings":["BDO — rejestracja w Bazie Danych o Odpadach. Opłata rejestracyjna 300 PLN (100 PLN mikroprzedsiębiorca). Termin: przed rozpoczęciem działalności."]
} {
    input.business.produces_waste == true
    input.business.bdo_registered == false
}

# ══ P1401: bdo_waste_ledger — BDO — ewidencja odpadów ══
else := {
    "matched":true,"rule_id":"jdg.environmental.bdo_waste_ledger",
    "package":"jdg.environmental","priority":1401,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","environmental_obligation":"BDO_WASTE_LEDGER_QUARTERLY",
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"BDO — ewidencja odpadów kwartalna. Termin: do końca miesiąca po kwartale.",
    "_legal_basis":"Art. 66-67 Ustawy o odpadach",
    "_warnings":["BDO — karta ewidencji odpadów. Prowadzenie w systemie BDO. Sprawozdanie kwartalne: do 30 kwietnia (Q1), 31 lipca (Q2), 31 października (Q3), 31 stycznia (Q4)."]
} {
    input.business.bdo_registered == true
    input.business.waste_generated_this_quarter > 0
}

# ══ P1402: environmental_fee_annual — Opłata środowiskowa roczna ══
else := {
    "matched":true,"rule_id":"jdg.environmental.fee_annual",
    "package":"jdg.environmental","priority":1402,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","environmental_obligation":"ENV_FEE_ANNUAL","environmental_fee_de_minimis":800,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 284 Ustawy Prawo ochrony środowiska",
    "_warnings":["Opłata środowiskowa — roczne sprawozdanie do 31 marca. Opłata poniżej 800 PLN nie podlega uiszczeniu (de minimis)."]
} {
    input.business.emits_pollutants == true
    input.calendar.month == 3
    input.calendar.day_of_month >= 15
}

# ══ P1403: kobize_emission_report — KOBiZE — raport emisji ══
else := {
    "matched":true,"rule_id":"jdg.environmental.kobize_emission_report",
    "package":"jdg.environmental","priority":1403,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","environmental_obligation":"KOBIZE_REPORT_ANNUAL",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 7 Ustawy o systemie zarządzania emisjami",
    "_warnings":["KOBiZE — Krajowy Ośrodek Bilansowania i Zarządzania Emisjami. Raport roczny do 28 lutego. Dotyczy CO2 i innych gazów cieplarnianych."]
} {
    input.business.co2_emissions_annual_tonnes >= 1
    input.calendar.month == 2
}

# ══ P1404: battery_disposal_fee — Opłata za baterie/akumulatory ══
else := {
    "matched":true,"rule_id":"jdg.environmental.battery_disposal_fee",
    "package":"jdg.environmental","priority":1404,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","environmental_obligation":"BATTERY_WEEE_FEE",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Ustawa o bateriach i akumulatorach",
    "_warnings":["Opłata produktowa za baterie/akumulatory. Dotyczy sprzedawców i importerów. Sprawozdanie roczne do 15 marca."]
} {
    input.business.sells_batteries == true
}

# ══ P1405: water_permit_check — Pozwolenie wodnoprawne ══
else := {
    "matched":true,"rule_id":"jdg.environmental.water_permit_check",
    "package":"jdg.environmental","priority":1405,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","environmental_obligation":"WATER_PERMIT_REQUIRED",
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Brak pozwolenia wodnoprawnego — wymagane dla poboru >5m³/dobę",
    "_legal_basis":"Art. 389 Ustawy Prawo wodne",
    "_warnings":["Pozwolenie wodnoprawne — wymagane przy poborze wody >5m³/dobę. Opłata za pobór wód. Sprawozdanie kwartalne."]
} {
    input.business.water_usage_m3_per_day >= 5
    input.business.water_permit_valid == false
}

# ══ P1406: waste_transport_card — Karta przekazania odpadów ══
else := {
    "matched":true,"rule_id":"jdg.environmental.waste_transport_card",
    "package":"jdg.environmental","priority":1406,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","environmental_obligation":"KPO_ELECTRONIC",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 67 Ustawy o odpadach",
    "_warnings":["Karta przekazania odpadów (KPO) — obowiązek elektroniczny w BDO od 2020. Podpis elektroniczny lub profil zaufany."]
} {
    input.business.waste_transported == true
}

# ══ P1407: packaging_recycling_fee — Opłata recyklingowa za opakowania ══
else := {
    "matched":true,"rule_id":"jdg.environmental.packaging_recycling_fee",
    "package":"jdg.environmental","priority":1407,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","environmental_obligation":"PACKAGING_RECYCLING",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Ustawa o gospodarce opakowaniami i odpadami opakowaniowymi",
    "_warnings":["Opłata recyklingowa za opakowania. Obowiązek osiągnięcia poziomów recyklingu. Sprawozdanie roczne do 15 marca. Dotyczy importerów/producentów opakowań."]
} {
    input.business.introduces_packaging == true
}
