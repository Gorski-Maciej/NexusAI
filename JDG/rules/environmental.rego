# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — BDO, KOBiZE, opłaty środowiskowe (P1400-P1407)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.environmental
#
# JDG environmental package — Multi-Pass architecture (ADR-001).
# Covers BDO, KOBiZE, environmental fees, ESG and related obligations.
#

csrd_threshold_met(emp, assets, rev) = true {
    emp > 250
    assets > 20
}

csrd_threshold_met(emp, assets, rev) = true {
    emp > 250
    rev > 40
}

csrd_threshold_met(emp, assets, rev) = true {
    assets > 20
    rev > 40
}

default decide := {"matched":false,"rule_id":"jdg.environmental.no_match","package":"jdg.environmental","priority":1775}

# ══════ P1770: environment_sup_plastic_fee — Opłata SUP od plastikowych opakowań ══════
# ⚖️ Obowiązek od 2024: gastronomia/handel → opłata za kubki/pojemniki plastikowe
# Podstawa: Ustawa SUP (Dz.U. 2023 poz. 877), Dyrektywa SUP 2019/904
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched":true,"rule_id":"jdg.environmental.sup_plastic_fee",
    "package":"jdg.environmental","priority":1770,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "sup_fee_amount": sup_amount,
    "sup_fee_included_in_vat_base":true,
    "sup_fee_quarterly_report_required":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Ustawa SUP (Dz.U. 2023 poz. 877)",
    "_warnings":[sprintf("Opłata SUP — %d szt. × %.2f PLN = %.2f PLN. Odprowadź kwartalnie do US.", [items, sup_rate, sup_amount])]
} {
    pkd := object.get(input.jdg_entrepreneur, "pkd_main", "")
    sup_pkd := {"56.10.A", "56.30.Z", "47.11.Z", "47.81.Z"}
    sup_pkd[pkd]
    items := object.get(input.invoice, "sup_plastic_items_sold", 0)
    items > 0
    sup_rate := object.get(object.get(object.get(data.thresholds, "jdg", {}), "environmental", {}), "sup_fee_rate", 0.25)
    sup_amount := items * sup_rate
}

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

# ══ P540-P544: ESG/CSRD — Doc 36 §23 (5 reguł ENTERPRISE) ══

# P540: esg_csrd_threshold — Próg raportowania CSRD
else := {
    "matched":true,"rule_id":"jdg.environmental.csrd_threshold",
    "package":"jdg.environmental","priority":540,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","csrd_reporting_required":true,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"CSRD — obowiązek raportowania ESG",
    "_legal_basis":"Dyrektywa CSRD 2022/2464",
    "_warnings":[sprintf("CSRD — 2 z 3 progów spełnione: %.0f prac., %.0fM EUR aktywa, %.0fM EUR przychody. Obowiązek raportowania ESG od 2025.",[emp,assets,rev])]
} {
    emp:=object.get(input.employment,"employee_count",0)
    assets:=object.get(input.jdg_entrepreneur,"total_assets_eur_m",0)
    rev:=object.get(input.jdg_entrepreneur,"annual_revenue_eur_m",0)
    csrd_threshold_met(emp, assets, rev)
}

# P541: esg_carbon_footprint — Ślad węglowy
else := {
    "matched":true,"rule_id":"jdg.environmental.carbon_footprint_tracking",
    "package":"jdg.environmental","priority":541,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","carbon_tracking_required":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"EU Taxonomy Regulation 2020/852",
    "_warnings":["Ślad węglowy — raportowanie emisji Scope 1/2/3. Zakres: spalanie paliw (S1), energia elektryczna (S2), łańcuch dostaw (S3). Coroczne raportowanie."]
} {
    object.get(input.jdg_entrepreneur,"csrd_reporting_required",false)==true
}

# P542: esg_supply_chain_due_diligence — Należyta staranność w łańcuchu dostaw
else := {
    "matched":true,"rule_id":"jdg.environmental.supply_chain_due_diligence",
    "package":"jdg.environmental","priority":542,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","supply_chain_dd_required":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Dyrektywa CSDDD 2024/1760",
    "_warnings":["Należyta staranność w łańcuchu dostaw — obowiązek identyfikacji ryzyk ESG u dostawców. Audyt dostawców + raportowanie."]
} {
    object.get(input.jdg_entrepreneur,"csrd_reporting_required",false)==true
}

# P543: esg_greenwashing_flag — Wykrywanie greenwashingu
else := {
    "matched":true,"rule_id":"jdg.environmental.greenwashing_flag",
    "package":"jdg.environmental","priority":543,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","greenwashing_risk":true,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Deklaracje środowiskowe bez certyfikacji",
    "_legal_basis":"Taksonomia UE + Art. 7 RODO",
    "_warnings":["GREENWASHING RISK — deklaracje środowiskowe bez certyfikacji. Wymagane potwierdzenie zewnętrzne (ISO 14001, EMAS, ETV). Ryzyko kary UOKiK!"]
} {
    object.get(input.jdg_entrepreneur,"environmental_claims_made",false)==true
    object.get(input.jdg_entrepreneur,"environmental_certification_valid",true)==false
}

# P544: esg_energy_efficiency_certificate — Świadectwo energetyczne
else := {
    "matched":true,"rule_id":"jdg.environmental.energy_efficiency_certificate",
    "package":"jdg.environmental","priority":544,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","energy_cert_required":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Dyrektywa EPBD 2010/31/UE",
    "_warnings":["Świadectwo charakterystyki energetycznej — wymagane dla budynków JDG przy sprzedaży/najmie. Ważne 10 lat."]
} {
    object.get(input.jdg_entrepreneur,"owns_commercial_building",false)==true
    object.get(input.jdg_entrepreneur,"energy_certificate_valid",true)==false
}

