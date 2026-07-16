# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Local: PCC, nieruchomości, transport (P1300-P1320)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.local_taxes
#
# METADATA
# title: JDG Package — local
# description: Supporting package for JDG Multi-Pass evaluation (ADR-001).
# architecture: Multi-Pass (ADR-001)
# package: jdg.local
# deprecated: false
#
import data.jdg.helpers
default decide := {"matched":false,"rule_id":"jdg.local_taxes.no_match","package":"jdg.local_taxes","priority":1399}

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

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1301-P1304 — PCC ROZSZERZONE: Pożyczki, udziały, zwolnienia            ║
# ║  Ustawa o podatku od czynności cywilnoprawnych (PCC)                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════ P1301-P1304: PCC ROZSZERZONE — UWAGA: leksykalnie po P1320, ale przed P1331 ══════
# FIXME: Reorder P1301-P1304 before P1310-P1320 in else-chain for logical priority consistency
# ══════ P1301: pcc_loan_agreement — PCC 0.5% od pożyczki ══════
else := {
    "matched":true,"rule_id":"jdg.local.pcc_loan_agreement",
    "package":"jdg.local","priority":1301,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","local_tax_type":"PCC","local_tax_rate":"0.005",
    "pcc_transaction_type":"LOAN","pcc_declaration":"PCC-3","pcc_deadline_days":14,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"PCC od pożyczki — 0.5% od kwoty, deklaracja PCC-3 w 14 dni",
    "_legal_basis":"Art. 7 ust. 1 pkt 4 Ustawy o PCC",
    "_warnings":[sprintf("PCC OD POŻYCZKI — %.2f PLN (0.5%% od %.2f PLN). %s. Deklaracja PCC-3 w 14 dni od zawarcia umowy", [pcc_amount, loan_amount, exemption_info])]
} {
    input.invoice.transaction_type == "LOAN_RECEIVED"
    loan_amount := object.get(input.invoice, "amount_net", 0)
    loan_amount > 0

    # Zwolnienie: pożyczka od rodziny (grupa 0) do 36 120 PLN
    is_family := object.get(input.invoice, "loan_from_family", false)
    is_under_limit := loan_amount <= 36120

    is_exempt = true { is_family == true; is_under_limit == true }
    is_exempt = false { is_family == false }
    is_exempt = false { is_under_limit == false }

    pcc_amount = loan_amount * 0.005 { is_exempt == false }
    pcc_amount = 0 { is_exempt == true }
    exemption_info = "ZWOLNIONE (pożyczka rodzinna ≤ 36 120 PLN)" { is_exempt == true }
    exemption_info = "Pełna stawka 0.5%" { is_exempt == false }
}

# ══════ P1302: pcc_share_purchase — PCC 1% od zakupu udziałów/akcji ══════
else := {
    "matched":true,"rule_id":"jdg.local.pcc_share_purchase",
    "package":"jdg.local","priority":1302,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","local_tax_type":"PCC","local_tax_rate":"0.01",
    "pcc_transaction_type":"SHARE_PURCHASE","pcc_declaration":"PCC-3","pcc_deadline_days":14,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"PCC od zakupu udziałów — 1% od wartości, deklaracja PCC-3",
    "_legal_basis":"Art. 7 ust. 1 pkt 1 lit. a Ustawy o PCC",
    "_warnings":[sprintf("PCC OD ZAKUPU UDZIAŁÓW — %.2f PLN (1%% od %.2f PLN). Deklaracja PCC-3 w 14 dni! Uwaga: jeśli transakcja podlega VAT, PCC jest wyłączone", [pcc_amount, share_value])]
} {
    input.invoice.transaction_type == "SHARE_PURCHASE"
    input.invoice.vat_applies == false
    share_value := object.get(input.invoice, "amount_net", 0)
    share_value > 0
    pcc_amount = share_value * 0.01
}

# ══════ P1303: pcc_sale_agreement — PCC 2% od umowy sprzedaży rzeczy ruchomych ══════
else := {
    "matched":true,"rule_id":"jdg.local.pcc_sale_agreement",
    "package":"jdg.local","priority":1303,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","local_tax_type":"PCC","local_tax_rate":"0.02",
    "pcc_transaction_type":"SALE_AGREEMENT","pcc_declaration":"PCC-3","pcc_deadline_days":14,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"PCC od umowy sprzedaży poza VAT — 2% od wartości rynkowej",
    "_legal_basis":"Art. 7 ust. 1 pkt 1 lit. a Ustawy o PCC",
    "_warnings":[sprintf("PCC OD UMOWY SPRZEDAŻY — %.2f PLN (2%% od %.2f PLN). Dotyczy sprzedaży poza VAT (osoba prywatna nieprowadząca działalności). Deklaracja PCC-3 w 14 dni", [pcc_amount, sale_value])]
} {
    input.invoice.transaction_type == "GOODS_SALE_PRIVATE"
    input.invoice.direction == "PURCHASE"
    input.vendor.is_company == false
    input.invoice.vat_applies == false
    sale_value := object.get(input.invoice, "amount_net", 0)
    sale_value > 1000
    pcc_amount = sale_value * 0.02
}

# ══════ P1304: pcc_exemption_check — Zwolnienia z PCC — kontrola progów ══════
else := {
    "matched":true,"rule_id":"jdg.local.pcc_exemption_check",
    "package":"jdg.local","priority":1304,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","local_tax_type":"PCC","pcc_exemption_applies": exemption_applies,
    "pcc_exemption_type": exemption_type,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 9 Ustawy o PCC",
    "_warnings":[sprintf("PCC — KONTROLA ZWOLNIEŃ: %s", [exemption_info])]
} {
    input.invoice.pcc_transaction == true
    amount := object.get(input.invoice, "amount_net", 0)
    below_threshold := amount <= 1000
    vat_applies := object.get(input.invoice, "vat_applies", false)
    vat_excludes_pcc := vat_applies == true
    exemption_applies = true { below_threshold }
    exemption_applies = true { vat_excludes_pcc }
    exemption_applies = false { not below_threshold; not vat_excludes_pcc }
    exemption_type = "PONIŻEJ_PROGU_1000PLN" { below_threshold == true }
    exemption_type = "VAT_WYŁĄCZA_PCC" { vat_applies == true }
    exemption_type = "OPODATKOWANE_0.5-2%" { below_threshold == false; vat_applies == false }
    exemption_info = "Zwolnione: kwota ≤ 1000 PLN" { below_threshold == true }
    exemption_info = "Zwolnione: transakcja podlega VAT" { vat_applies == true }
    exemption_info = sprintf("Opodatkowane PCC. Kwota %.2f PLN > 1000 PLN, brak VAT", [amount]) { below_threshold == false; vat_applies == false }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1331-P1334 — PODATEK OD ŚRODKÓW TRANSPORTOWYCH (DT-1)                  ║
# ║  Art. 9-14 Ustawy o podatkach i opłatach lokalnych                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1331: transport_tax_detailed — DT-1 ze stawkami per DMC
else := {
    "matched":true,"rule_id":"jdg.local.transport_tax_detailed",
    "package":"jdg.local","priority":1331,
    "local_tax_type":"TRANSPORT","local_tax_rate_pln":annual_rate,
    "dt1_declaration_required":true,"dt1_deadline":"FEBRUARY_15",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 9-14 Ustawy o podatkach i opłatach lokalnych",
    "_warnings":[sprintf("PODATEK TRANSPORTOWY — DMC %.1f t, stawka %.0f PLN/rok. Deklaracja DT-1 do 15 lutego. Płatność w 2 ratach: 15.02 i 15.09.",[vehicle_dmc,annual_rate])]
} {
    input.invoice.category_code == "VEHICLE"
    vehicle_dmc := object.get(input.invoice,"vehicle_dmc",0)
    is_ev := object.get(input.invoice,"vehicle_is_electric",false)
    is_trailer := object.get(input.invoice,"vehicle_is_trailer",false)
    axles := object.get(input.invoice,"vehicle_axles",2)
    # Stawki 2026 (wg obwieszczenia MF) — pojazdy ciężarowe
    annual_rate = 0 { is_ev == true }
    annual_rate = 800 { vehicle_dmc > 3.5; vehicle_dmc <= 5.5; not is_trailer }
    annual_rate = 1000 { vehicle_dmc > 5.5; vehicle_dmc <= 9; not is_trailer }
    annual_rate = 1400 { vehicle_dmc > 9; vehicle_dmc <= 12; not is_trailer }
    annual_rate = 2000 { vehicle_dmc > 12; not is_trailer }
    annual_rate = 1200 { is_trailer == true; vehicle_dmc > 3.5 }
    annual_rate = 1800 { is_trailer == true; vehicle_dmc > 12; axles >= 3 }
    annual_rate = 0 { vehicle_dmc <= 3.5 }
}

# P1332: transport_tax_tractor_unit — Ciągnik siodłowy
else := {
    "matched":true,"rule_id":"jdg.local.transport_tax_tractor",
    "package":"jdg.local","priority":1332,
    "local_tax_type":"TRANSPORT_TRACTOR","local_tax_rate_pln":annual_rate,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 10 ust. 2 Ustawy o podatkach i opłatach lokalnych",
    "_warnings":[sprintf("CIĄGNIK SIODŁOWY — DMC %.1f t, stawka %.0f PLN/rok. DT-1 do 15 lutego.",[vehicle_dmc,annual_rate])]
} {
    input.invoice.vehicle_type == "TRACTOR_UNIT"
    vehicle_dmc := object.get(input.invoice,"vehicle_dmc",0)
    annual_rate = 2200 { vehicle_dmc <= 36 }
    annual_rate = 2800 { vehicle_dmc > 36 }
}

# P1333: transport_tax_bus — Autobus
else := {
    "matched":true,"rule_id":"jdg.local.transport_tax_bus",
    "package":"jdg.local","priority":1333,
    "local_tax_type":"TRANSPORT_BUS","local_tax_rate_pln":annual_rate,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 12 Ustawy o podatkach i opłatach lokalnych",
    "_warnings":[sprintf("AUTOBUS — %d miejsc, stawka %.0f PLN/rok. DT-1 do 15 lutego.",[seats,annual_rate])]
} {
    input.invoice.vehicle_type == "BUS"
    seats := object.get(input.invoice,"vehicle_seats",0)
    annual_rate = 1600 { seats < 22 }
    annual_rate = 2400 { seats >= 22 }
}

# P1334: transport_tax_exemption_check — Zwolnienia DT-1 (EV, hybryda, zabytkowe)
else := {
    "matched":true,"rule_id":"jdg.local.transport_tax_exemption",
    "package":"jdg.local","priority":1334,
    "local_tax_type":"TRANSPORT","transport_tax_exempt":is_exempt,
    "exemption_reason":exempt_reason,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 12 ust. 1-4 Ustawy o podatkach i opłatach lokalnych",
    "_warnings":[sprintf("PODATEK TRANSPORTOWY — %s",[exempt_info])]
} {
    input.invoice.category_code == "VEHICLE"
    is_ev := object.get(input.invoice,"vehicle_is_electric",false)
    is_hybrid := object.get(input.invoice,"vehicle_is_hybrid",false)
    is_historic := object.get(input.invoice,"vehicle_is_historic",false)
    is_emergency := object.get(input.invoice,"vehicle_is_emergency",false)
    is_exempt = true { is_ev == true }
    is_exempt = true { is_historic == true }
    is_exempt = true { is_emergency == true }
    is_exempt = false { not is_exempt }
    exempt_reason = "Pojazd elektryczny — zwolniony z podatku" { is_ev == true }
    exempt_reason = "Pojazd zabytkowy — zwolniony" { is_historic == true }
    exempt_reason = "Pojazd ratowniczy — zwolniony" { is_emergency == true }
    exempt_reason = "Brak zwolnienia — podlega DT-1" { is_exempt == false }
    exempt_info = "ZWOLNIONE" { is_exempt == true }
    exempt_info = "PODLEGA DT-1" { is_exempt == false }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1335-P1339 — OPŁATY LOKALNE: targowa, miejscowa, uzdrowiskowa          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1335: market_fee — Opłata targowa (Art. 15-16 UoPiOL)
else := {
    "matched":true,"rule_id":"jdg.local.market_fee",
    "package":"jdg.local","priority":1335,
    "local_tax_type":"MARKET_FEE",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 15-16 Ustawy o podatkach i opłatach lokalnych",
    "_warnings":[sprintf("OPŁATA TARGOWA — %.2f m² × %.2f PLN/dzień. Pobierana przez gminę przy sprzedaży na targowisku. Stawka max: %.2f PLN/dzień (uchwała Rady Gminy).",[area,rate,max_rate])]
} {
    input.invoice.local_tax_type == "MARKET_FEE"
    area := object.get(input.invoice,"stand_area_m2",0)
    area > 0
    rate := object.get(input.invoice,"market_fee_rate",5)
    max_rate := 800
}

# P1336: resort_fee — Opłata miejscowa (Art. 17-18 UoPiOL)
else := {
    "matched":true,"rule_id":"jdg.local.resort_fee",
    "package":"jdg.local","priority":1336,
    "local_tax_type":"RESORT_FEE",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 17-18 Ustawy o podatkach i opłatach lokalnych",
    "_warnings":[sprintf("OPŁATA MIEJSCOWA — %.2f PLN/os/dzień. Pobierana w miejscowościach turystycznych. Max stawka %.2f PLN (uchwała Rady Gminy).",[rate,max_rate])]
} {
    input.invoice.local_tax_type == "RESORT_FEE"
    rate := object.get(input.invoice,"resort_fee_rate",3)
    max_rate := 6.00
}

# P1337: spa_fee — Opłata uzdrowiskowa (Art. 17a UoPiOL)
else := {
    "matched":true,"rule_id":"jdg.local.spa_fee",
    "package":"jdg.local","priority":1337,
    "local_tax_type":"SPA_FEE",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 17a Ustawy o podatkach i opłatach lokalnych",
    "_warnings":["OPŁATA UZDROWISKOWA — pobierana w miejscowościach uzdrowiskowych. Max stawka 8 PLN/os/dzień (uchwała Rady Gminy)."]
} {
    input.invoice.local_tax_type == "SPA_FEE"
}

# P1338: property_tax_rates_detail — Stawki podatku od nieruchomości 2026
else := {
    "matched":true,"rule_id":"jdg.local.property_tax_rates_2026",
    "package":"jdg.local","priority":1338,
    "local_tax_type":"REAL_ESTATE_DETAIL",
    "land_business_rate":1.43,"land_other_rate":0.71,
    "building_business_rate":33.10,"building_residential_rate":1.15,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Obwieszczenie MF — maksymalne stawki podatków lokalnych 2026",
    "_warnings":[sprintf("NIERUCHOMOŚĆ FIRMOWA — grunt: %.2f PLN/m², budynek: %.2f PLN/m². Uwaga: stawka firmowa ~29× wyższa od prywatnej! DN-1 do 31 stycznia.",[land_rate,bldg_rate])]
} {
    input.invoice.local_tax_type == "REAL_ESTATE_RATES"
    land_rate := 1.43
    bldg_rate := 33.10
}

# P1339: mining_fee — Opłata eksploatacyjna
else := {
    "matched":true,"rule_id":"jdg.local.mining_fee",
    "package":"jdg.local","priority":1339,
    "local_tax_type":"MINING_FEE",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Prawo geologiczne i górnicze — Art. 133-140",
    "_warnings":[sprintf("OPŁATA EKSPLOATACYJNA — kopalina: %s, %.2f ton. Opłata do gminy + NFOŚiGW. Stawka per tona wg rozporządzenia.",[mineral_type,tonnage])]
} {
    input.invoice.local_tax_type == "MINING_FEE"
    mineral_type := object.get(input.invoice,"mineral_type","")
    tonnage := object.get(input.invoice,"mining_tonnage",0)
    tonnage > 0
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1340-P1349 — AKCYZA: wyroby akcyzowe, energia, zwolnienia               ║
# ║  Ustawa o podatku akcyzowym (Dz.U. 2025 poz. 890)                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1340: excise_fuel — Akcyza od paliw silnikowych
else := {
    "matched":true,"rule_id":"jdg.local.excise_fuel",
    "package":"jdg.local","priority":1340,
    "local_tax_type":"EXCISE","excise_category":"FUEL",
    "excise_rate_pln_per_unit":excise_rate,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 89-90 Ustawy o podatku akcyzowym",
    "_warnings":[sprintf("AKCYZA PALIWOWA — %s: %.0f litrów × %.0f PLN/1000l = %.2f PLN. Deklaracja AKC-4 miesięcznie do 25. dnia.",[fuel_type,liters,excise_rate,excise_amount])]
} {
    input.invoice.excise_category == "FUEL"
    fuel_type := object.get(input.invoice,"fuel_type","")
    liters := object.get(input.invoice,"quantity",0)
    liters > 0
    excise_rate = 1740 { fuel_type == "PB95" }
    excise_rate = 1740 { fuel_type == "PB98" }
    excise_rate = 1200 { fuel_type == "ON" }
    excise_rate = 1200 { fuel_type == "BIO_ON" }
    excise_rate = 700 { fuel_type == "LPG" }
    excise_rate = 0 { fuel_type == "CNG" }
    excise_rate = 0 { fuel_type == "ELECTRIC" }
    excise_rate = 0 { fuel_type == "HYDROGEN" }
    excise_amount := liters * excise_rate / 1000
}

# P1341: excise_alcohol — Akcyza od alkoholu
else := {
    "matched":true,"rule_id":"jdg.local.excise_alcohol",
    "package":"jdg.local","priority":1341,
    "local_tax_type":"EXCISE","excise_category":"ALCOHOL",
    "excise_rate_pln_per_hl":excise_rate,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 93-96 Ustawy o podatku akcyzowym",
    "_warnings":[sprintf("AKCYZA ALKOHOLOWA — %s: %.0f hl × %.0f PLN/hl = %.2f PLN. Zezwolenie + banderole + AKC-4.",[alc_type,volume_hl,excise_rate,excise_amount])]
} {
    input.invoice.excise_category == "ALCOHOL"
    alc_type := object.get(input.invoice,"alcohol_type","")
    volume_hl := object.get(input.invoice,"volume_hl",0)
    volume_hl > 0
    excise_rate = 6900 { alc_type == "SPIRITS" }
    excise_rate = 600 { alc_type == "BEER" }
    excise_rate = 180 { alc_type == "WINE" }
    excise_amount := volume_hl * excise_rate
}

# P1342: excise_tobacco — Akcyza tytoniowa
else := {
    "matched":true,"rule_id":"jdg.local.excise_tobacco",
    "package":"jdg.local","priority":1342,
    "local_tax_type":"EXCISE","excise_category":"TOBACCO",
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Wyroby tytoniowe — wymagane zezwolenie akcyzowe + banderole + AKC-4",
    "_legal_basis":"Art. 98-105 Ustawy o podatku akcyzowym",
    "_warnings":["AKCYZA TYTONIOWA — JDG handlująca wyrobami tytoniowymi! Wymagane: skład podatkowy, zezwolenie, banderole, AKC-4 miesięcznie. Sankcja: do 720 stawek KKS!"]
} {
    input.invoice.excise_category == "TOBACCO"
}

# P1343: excise_energy — Akcyza od energii elektrycznej
else := {
    "matched":true,"rule_id":"jdg.local.excise_energy",
    "package":"jdg.local","priority":1343,
    "local_tax_type":"EXCISE","excise_category":"ENERGY",
    "excise_rate_pln_per_mwh":5.00,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 11-12 Ustawy o podatku akcyzowym",
    "_warnings":[sprintf("AKCYZA ENERGETYCZNA — %.0f MWh × 5 PLN/MWh = %.2f PLN. Dotyczy sprzedaży energii przez JDG. Deklaracja AKC-4.",[mwh,excise_amount])]
} {
    input.invoice.excise_category == "ENERGY"
    mwh := object.get(input.invoice,"energy_mwh",0)
    mwh > 0
    excise_amount := mwh * 5.00
}

# P1344: excise_exemption_check — Zwolnienia akcyzowe
else := {
    "matched":true,"rule_id":"jdg.local.excise_exemption_check",
    "package":"jdg.local","priority":1344,
    "local_tax_type":"EXCISE","excise_exempt":is_exempt,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 30-39 Ustawy o podatku akcyzowym",
    "_warnings":[sprintf("AKCYZA — %s",[exempt_info])]
} {
    input.invoice.excise_category != ""
    is_renewable := object.get(input.invoice,"energy_from_renewables",false)
    is_export := object.get(input.invoice,"excise_export",false)
    is_small_producer := object.get(input.invoice,"excise_small_producer",false)
    is_exempt = true { is_renewable == true }
    is_exempt = true { is_export == true }
    is_exempt = false { not is_renewable; not is_export }
    exempt_info = "ZWOLNIONE — energia z OZE / eksport" { is_exempt == true }
    exempt_info = "PODLEGA AKCYZIE — AKC-4 wymagane" { is_exempt == false }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1350-P1354 — BDO / KOBiZE / ODPADY: rejestracja + sprawozdania          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1350: bdo_registration_check — Obowiązek rejestracji BDO
else := {
    "matched":true,"rule_id":"jdg.local.bdo_registration_check",
    "package":"jdg.local","priority":1350,
    "local_tax_type":"BDO","bdo_registration_required":true,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Brak rejestracji w BDO — obowiązek ustawowy!",
    "_legal_basis":"Ustawa o odpadach — Art. 50-51 (BDO)",
    "_warnings":["BDO — BAZA DANYCH ODPADOWYCH. JDG wytwarzająca/zbierająca odpady MUSI być zarejestrowana w BDO. Kara za brak: 1000-1 000 000 PLN! Rejestracja przez ePUAP."]
} {
    input.jdg_entrepreneur.produces_waste == true
    object.get(input.jdg_entrepreneur,"bdo_registered",true) == false
}

# P1351: bdo_annual_report — Raport roczny BDO do 15 marca
else := {
    "matched":true,"rule_id":"jdg.local.bdo_annual_report",
    "package":"jdg.local","priority":1351,
    "local_tax_type":"BDO","bdo_report_deadline":"MARCH_15",
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Raport BDO — termin 15 marca",
    "_legal_basis":"Art. 75 Ustawy o odpadach",
    "_warnings":[sprintf("RAPORT ROCZNY BDO — za rok %s. Termin: 15 marca %d. Obejmuje: masa odpadów, sposób zagospodarowania, kody odpadów.",[report_year,report_year+1])]
} {
    input.jdg_entrepreneur.bdo_registered == true
    report_year := object.get(input.invoice,"bdo_report_year",2025)
}

# P1352: kobize_emission_report — KOBiZE — raport emisji CO2
else := {
    "matched":true,"rule_id":"jdg.local.kobize_emission_report",
    "package":"jdg.local","priority":1352,
    "local_tax_type":"KOBIZE","kobize_report_required":true,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"KOBiZE — obowiązek raportowania emisji",
    "_legal_basis":"Ustawa o systemie zarządzania emisjami gazów cieplarnianych",
    "_warnings":["KOBIZE — Krajowy Ośrodek Bilansowania i Zarządzania Emisjami. Raport roczny do 28 lutego. Dotyczy JDG z instalacjami emisyjnymi."]
} {
    input.jdg_entrepreneur.has_emissions_installation == true
}

# P1353: sup_waste_report — SUP — raport o produktach jednorazowych z plastiku
else := {
    "matched":true,"rule_id":"jdg.local.sup_waste_report",
    "package":"jdg.local","priority":1353,
    "local_tax_type":"SUP","sup_report_required":true,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"SUP — obowiązek raportowania produktów jednorazowych",
    "_legal_basis":"Dyrektywa SUP (EU 2019/904) + ustawa o obowiązkach przedsiębiorców",
    "_warnings":[sprintf("SUP (Single-Use Plastics) — JDG wprowadzająca produkty jednorazowe z plastiku. Raport roczny do BDO do 15 marca. Opłata SUP: %.2f PLN.",[sup_fee])]
} {
    input.invoice.sup_products_sold == true
    sup_fee := object.get(input.invoice,"sup_fee_amount",0)
}

# P1354: environmental_fee — Opłata środowiskowa
else := {
    "matched":true,"rule_id":"jdg.local.environmental_fee",
    "package":"jdg.local","priority":1354,
    "local_tax_type":"ENVIRONMENTAL",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Prawo Ochrony Środowiska — Art. 273-291",
    "_warnings":[sprintf("OPŁATA ŚRODOWISKOWA — %s: %.2f kg × stawka = %.2f PLN. Wpłata do Urzędu Marszałkowskiego do 31 marca.",[emission_type,emission_qty,fee_amount])]
} {
    input.invoice.local_tax_type == "ENVIRONMENTAL"
    emission_type := object.get(input.invoice,"emission_type","")
    emission_qty := object.get(input.invoice,"emission_quantity_kg",0)
    fee_amount := emission_qty * 0.50
}
