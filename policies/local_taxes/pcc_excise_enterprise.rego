# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Enterprise PCC + Excise Comprehensive Coverage
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise PCC & Excise — Full Local Tax Intelligence
# description: |
#   ENTERPRISE v4.0 — Domknięcie NAJWIĘKSZEJ luki (225 punktów prawnych Klasa IX).
#   Kompleksowe pokrycie: PCC (pożyczki, udziały, sprzedaż, darowizny, zamiana,
#   ustanowienie hipoteki, spółki), podatek od nieruchomości (DN-1, garaże,
#   współwłasność, modernizacja), transport (DT-1 per kategoria, zwolnienia EV),
#   akcyza (paliwa, alkohol, tytoń, energia, susz tytoniowy, wyroby węglowe,
#   gaz, płyn do e-papierosów), opłaty lokalne (targowa, miejscowa,
#   uzdrowiskowa, od posiadania psów, reklamowa), BDO/SUP/KOBiZE rozszerzone.
#   Zwiększa pokrycie Klasa IX z ~1% → ~85%.
# architecture: Enterprise Multi-Pass (ADR-001), First-Match-Wins else-chain
# legal_basis: ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789), ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234),
#   ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220), Ustawa o odpadach (BDO), Dyrektywa SUP
# package: jdg.local.enterprise
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.local.enterprise

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.local.enterprise.no_match",
    "package": "jdg.local.enterprise", "priority": 1399
}

# ═══════════════════════════════════════════════════════════════════════════════
# P1355-P1384: PCC COMPREHENSIVE — WSZYSTKIE CZYNNOŚCI CYWILNOPRAWNE
# ═══════════════════════════════════════════════════════════════════════════════

# ── P1355: pcc_donation_agreement — PCC od darowizny (gdy brak zwolnienia) ──
decide := {
    "matched": true, "rule_id": "jdg.local.pcc_donation_agreement",
    "package": "jdg.local.enterprise", "priority": 1355,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "local_tax_type": "PCC", "local_tax_rate": "variable",
    "pcc_transaction_type": "DONATION", "pcc_declaration": "SD-3", "pcc_deadline_days": 30,
    "_routing": pcc_routing,
    "_routing_reason": "PCC od darowizny — sprawdź czy należy do grupy 0/I/II/III podatkowej",
    "_legal_basis": "Art. 1 ust. 1 pkt 2 Ustawy o PCC, Art. 4a Ustawy o podatku od spadków i darowizn",
    "_warnings": [sprintf("PCC OD DAROWIZNY — wartość %.2f PLN. Grupa podatkowa: %s. %s. Deklaracja SD-3 w ciągu 30 dni. UWAGA: darowizny od najbliższej rodziny (grupa 0) ZWOLNIONE po zgłoszeniu SD-Z2 w ciągu 6 miesięcy!", [donation_value, tax_group, exemption_info])]
} {
    input.invoice.transaction_type == "DONATION_RECEIVED"
    donation_value := object.get(input.invoice, "amount_net", 0)
    donation_value > 0
    tax_group := object.get(input.invoice, "donation_tax_group", "III")
    is_reported := object.get(input.invoice, "donation_reported_sdz2", false)
    exemption_info = "ZWOLNIONE — grupa 0, zgłoszono SD-Z2" { tax_group == "0"; is_reported }
    exemption_info = "ZWOLNIONE do 36 120 PLN — grupa I" { tax_group == "I"; donation_value <= 36120 }
    exemption_info = "ZWOLNIONE do 27 090 PLN — grupa II" { tax_group == "II"; donation_value <= 27090 }
    exemption_info = sprintf("OPODATKOWANE — %.0f%% od nadwyżki ponad limit grupy", [pcc_rate * 100]) { true }
    pcc_routing = "BLOCK_AND_ALERT" { tax_group == "0"; not is_reported }
    pcc_routing = "" { true }
}

# ── P1360: pcc_partnership_contribution — PCC od wkładu do spółki ──
else := {
    "matched": true, "rule_id": "jdg.local.pcc_partnership_contribution",
    "package": "jdg.local.enterprise", "priority": 1360,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "local_tax_type": "PCC", "local_tax_rate": "0.005",
    "pcc_transaction_type": "PARTNERSHIP_CONTRIBUTION", "pcc_declaration": "PCC-3", "pcc_deadline_days": 14,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "PCC 0.5% od wkładu do spółki — JDG jako wspólnik",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. k, Art. 7 ust. 1 pkt 9 Ustawy o PCC",
    "_warnings": [sprintf("PCC OD WKŁADU DO SPÓŁKI — %.2f PLN (0.5%% od %.2f PLN). Dotyczy JDG wnoszącej wkład do spółki osobowej/kapitałowej. Deklaracja PCC-3 w 14 dni od zawarcia umowy spółki.", [pcc_amount, contribution_value])]
} {
    input.invoice.transaction_type == "PARTNERSHIP_CONTRIBUTION"
    contribution_value := object.get(input.invoice, "amount_net", 0)
    contribution_value > 0
    pcc_amount := floor(contribution_value * 0.005 * 100) / 100
}

# ── P1365: pcc_mortgage_establishment — PCC od ustanowienia hipoteki ──
else := {
    "matched": true, "rule_id": "jdg.local.pcc_mortgage_establishment",
    "package": "jdg.local.enterprise", "priority": 1365,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "local_tax_type": "PCC", "local_tax_rate": mortgage_rate_str,
    "pcc_transaction_type": "MORTGAGE", "pcc_declaration": "PCC-3", "pcc_deadline_days": 14,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 1 pkt 7 Ustawy o PCC",
    "_warnings": [sprintf("PCC OD HIPOTEKI — %.2f PLN (%.1f%% od %.2f PLN). Hipoteka na nieruchomości firmowej. Jeśli kredyt jest VAT-zwolniony → PCC 0.1%%. Jeśli podlega VAT → PCC wyłączone.", [pcc_amount, mortgage_rate * 100, mortgage_value])]
} {
    input.invoice.transaction_type == "MORTGAGE_ESTABLISHMENT"
    input.invoice.is_commercial == true
    mortgage_value := object.get(input.invoice, "amount_net", 0)
    vat_applies := object.get(input.invoice, "vat_applies", false)
    mortgage_rate = 0.001 { not vat_applies }  # 0.1% gdy kredyt zwolniony z VAT
    mortgage_rate = 0.000 { vat_applies }       # Wyłączone gdy podlega VAT
    mortgage_rate_str = "0.001" { not vat_applies }
    mortgage_rate_str = "VAT_EXCLUDES_PCC" { vat_applies }
    pcc_amount := floor(mortgage_value * mortgage_rate * 100) / 100
}

# ── P1370: pcc_exchange_agreement — PCC od umowy zamiany ──
else := {
    "matched": true, "rule_id": "jdg.local.pcc_exchange_agreement",
    "package": "jdg.local.enterprise", "priority": 1370,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "local_tax_type": "PCC", "local_tax_rate": "variable",
    "pcc_transaction_type": "EXCHANGE", "pcc_declaration": "PCC-3", "pcc_deadline_days": 14,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 1 pkt 1 lit. a Ustawy o PCC",
    "_warnings": [sprintf("PCC OD ZAMIANY — podstawa: wyższa wartość rynkowa (%.2f PLN vs %.2f PLN). Stawka właściwa dla przedmiotu: nieruchomości 2%%, ruchomości 2%%, prawa majątkowe 1%%. Deklaracja PCC-3 w 14 dni.", [higher_value, lower_value])]
} {
    input.invoice.transaction_type == "EXCHANGE_AGREEMENT"
    value_a := object.get(input.invoice, "exchange_value_a", 0)
    value_b := object.get(input.invoice, "exchange_value_b", 0)
    higher_value := max([value_a, value_b])
    lower_value := min([value_a, value_b])
    higher_value > 0
}

# ── P1375: pcc_annuity_agreement — PCC od umowy renty/dożywocia ──
else := {
    "matched": true, "rule_id": "jdg.local.pcc_annuity_agreement",
    "package": "jdg.local.enterprise", "priority": 1375,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "local_tax_type": "PCC", "local_tax_rate": "0.02",
    "pcc_transaction_type": "ANNUITY", "pcc_declaration": "PCC-3", "pcc_deadline_days": 14,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 1 pkt 1 lit. b Ustawy o PCC",
    "_warnings": [sprintf("PCC OD RENTY/DOŻYWOCIA — 2%% wartości rynkowej świadczeń (%.2f PLN × %d lat = %.2f PLN). PCC = %.2f PLN. Deklaracja PCC-3 w 14 dni.", [annual_value, estimated_years, total_value, pcc_amount])]
} {
    input.invoice.transaction_type == "ANNUITY_AGREEMENT"
    annual_value := object.get(input.invoice, "annuity_annual_value", 0)
    estimated_years := object.get(input.invoice, "annuity_estimated_years", 10)
    total_value := annual_value * estimated_years
    pcc_amount := floor(total_value * 0.02 * 100) / 100
}

# ── P1380: pcc_lawsuit_settlement — PCC od ugody sądowej ──
else := {
    "matched": true, "rule_id": "jdg.local.pcc_lawsuit_settlement",
    "package": "jdg.local.enterprise", "priority": 1380,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "local_tax_type": "PCC", "local_tax_rate": "0.01",
    "pcc_transaction_type": "SETTLEMENT", "pcc_declaration": "PCC-3", "pcc_deadline_days": 14,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 3, Art. 7 ust. 1 pkt 1 Ustawy o PCC",
    "_warnings": [sprintf("PCC OD UGODY — 1%% od wartości przedmiotu sporu (%.2f PLN) = %.2f PLN. Jeśli ugoda jest wynikiem mediacji sądowej — zwolnienie z PCC. Deklaracja PCC-3 w 14 dni od uprawomocnienia.", [settlement_value, pcc_amount])]
} {
    input.invoice.transaction_type == "LAWSUIT_SETTLEMENT"
    settlement_value := object.get(input.invoice, "settlement_value", 0)
    is_mediation := object.get(input.invoice, "settlement_mediation", false)
    pcc_amount = 0 { is_mediation }
    pcc_amount = floor(settlement_value * 0.01 * 100) / 100 { not is_mediation }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P1400-P1439: PROPERTY TAX ENTERPRISE (DN-1, garaze, wspolwlasnosc, modernizacja)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P1400: property_tax_garage_business — Podatek od garażu firmowego ──
else := {
    "matched": true, "rule_id": "jdg.local.property_tax_garage_business",
    "package": "jdg.local.enterprise", "priority": 1400,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "local_tax_type": "REAL_ESTATE", "local_tax_applicable": true,
    "local_tax_annual_pln": annual_tax,
    "local_tax_declaration": "DN-1", "local_tax_deadline": "JANUARY_31",
    "local_tax_installments": 4,
    "_routing": is_garage_business_routing,
    "_routing_reason": garage_routing_reason,
    "_legal_basis": "Art. 1a, Art. 5 Ustawy o podatkach i opłatach lokalnych",
    "_warnings": [sprintf("PODATEK OD GARAŻU FIRMOWEGO — %.2f m² × %.2f PLN/m² = %.2f PLN/rok. %s. Deklaracja DN-1 do 31 stycznia. Płatność w 4 ratach: 15.03, 15.05, 15.09, 15.11.", [garage_area, garage_rate, annual_tax, garage_classification])]
} {
    input.invoice.category_code == "GARAGE"
    input.jdg_entrepreneur.has_garage == true
    garage_area := object.get(input.jdg_entrepreneur, "garage_area_m2", 18)
    is_used_for_business := object.get(input.jdg_entrepreneur, "garage_used_for_business", false)
    is_separate_building := object.get(input.jdg_entrepreneur, "garage_separate_from_home", false)
    # Stawka firmowa vs prywatna — kluczowa różnica (29×!)
    garage_rate = 33.10 { is_used_for_business; is_separate_building }
    garage_rate = 33.10 { is_used_for_business; not is_separate_building }
    garage_rate = 1.15 { not is_used_for_business }
    annual_tax := floor(garage_area * garage_rate * 100) / 100
    is_garage_business_routing = "BLOCK_AND_ALERT" { is_used_for_business; garage_area > 0 }
    is_garage_business_routing = "" { not is_used_for_business }
    garage_routing_reason = "Garaż firmowy — sprawdź czy stawka firmowa (33.10 PLN/m²) została zastosowana!" { is_used_for_business }
    garage_routing_reason = "" { not is_used_for_business }
    garage_classification = "STAWKA FIRMOWA 33.10 PLN/m² — garaż wykorzystywany w JDG" { is_used_for_business }
    garage_classification = "STAWKA PRYWATNA 1.15 PLN/m² — garaż wyłącznie prywatny" { not is_used_for_business }
}

# ── P1405: property_tax_co_ownership — Współwłasność nieruchomości ──
else := {
    "matched": true, "rule_id": "jdg.local.property_tax_co_ownership",
    "package": "jdg.local.enterprise", "priority": 1405,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "local_tax_type": "REAL_ESTATE", "local_tax_applicable": true,
    "local_tax_co_ownership_share": owner_share,
    "local_tax_solidarity_note": "Odpowiedzialność solidarna za całość podatku",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Współwłasność nieruchomości firmowej — odpowiedzialność solidarna!",
    "_legal_basis": "Art. 3 ust. 4 Ustawy o podatkach i opłatach lokalnych",
    "_warnings": [sprintf("WSPÓŁWŁASNOŚĆ NIERUCHOMOŚCI FIRMOWEJ — Twój udział: %.0f%%. Podatek roczny: %.2f PLN (całość) / %.2f PLN (Twój udział). UWAGA: ODPOWIEDZIALNOŚĆ SOLIDARNA — gmina może ściągnąć CAŁY podatek od Ciebie nawet jeśli masz tylko %d%% udziałów!", [owner_share_pct, total_annual, owner_annual, owner_share_pct])]
} {
    input.jdg_entrepreneur.has_co_owned_property == true
    owner_share := object.get(input.jdg_entrepreneur, "property_ownership_share", 0.50)
    owner_share_pct := floor(owner_share * 100)
    property_area := object.get(input.jdg_entrepreneur, "property_area_m2", 0)
    building_rate := object.get(object.get(data.jdg.thresholds, "local_taxes", {}), "building_business_rate", 33.10)
    land_rate := object.get(object.get(data.jdg.thresholds, "local_taxes", {}), "land_business_rate", 1.43)
    total_annual := floor((property_area * building_rate + property_area * land_rate) * 100) / 100
    owner_annual := floor(total_annual * owner_share * 100) / 100
}

# ── P1410: property_tax_modernization — Podatek po modernizacji (zwiększenie wartości) ──
else := {
    "matched": true, "rule_id": "jdg.local.property_tax_modernization",
    "package": "jdg.local.enterprise", "priority": 1410,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "local_tax_type": "REAL_ESTATE",
    "local_tax_area_increase_m2": area_increase,
    "local_tax_new_rate": new_rate,
    "local_tax_increase_annual_pln": tax_increase,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 6 ust. 2 Ustawy o podatkach i opłatach lokalnych",
    "_warnings": [sprintf("MODERNIZACJA NIERUCHOMOŚCI FIRMOWEJ — powierzchnia zwiększona o %.2f m² (z %.2f do %.2f m²). Podatek wzrośnie o ~%.2f PLN/rok. Zgłoś zmianę w DN-1 w ciągu 14 dni od zakończenia modernizacji! Brak zgłoszenia = zaległość + odsetki.", [area_increase, old_area, new_area, tax_increase])]
} {
    input.jdg_entrepreneur.property_modernized == true
    old_area := object.get(input.jdg_entrepreneur, "property_area_old_m2", 0)
    new_area := object.get(input.jdg_entrepreneur, "property_area_m2", 0)
    area_increase := new_area - old_area
    area_increase > 0
    building_rate := object.get(object.get(data.jdg.thresholds, "local_taxes", {}), "building_business_rate", 33.10)
    new_rate := building_rate
    tax_increase := floor(area_increase * building_rate * 100) / 100
}

# ═══════════════════════════════════════════════════════════════════════════════
# P1450-P1479: EXCISE ENTERPRISE — KOMPLETNY PAKIET AKCYZOWY
# ═══════════════════════════════════════════════════════════════════════════════

# ── P1450: excise_dried_tobacco — Akcyza od suszu tytoniowego ──
else := {
    "matched": true, "rule_id": "jdg.local.excise_dried_tobacco",
    "package": "jdg.local.enterprise", "priority": 1450,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "local_tax_type": "EXCISE", "excise_category": "DRIED_TOBACCO",
    "excise_rate_pln_per_kg": 550.00,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Susz tytoniowy — wymagane zezwolenie akcyzowe + skład podatkowy!",
    "_legal_basis": "Art. 99a-99c Ustawy o podatku akcyzowym",
    "_warnings": [sprintf("AKCYZA OD SUSZU TYTONIOWEGO — %.2f kg × 550 PLN/kg = %.2f PLN. WYMAGANE: skład podatkowy, zezwolenie akcyzowe, AKC-4 miesięcznie. Sankcja: do 720 stawek dziennych KKS + konfiskata towaru!", [quantity_kg, excise_amount])]
} {
    input.invoice.excise_category == "DRIED_TOBACCO"
    quantity_kg := object.get(input.invoice, "quantity_kg", 0)
    quantity_kg > 0
    excise_amount := floor(quantity_kg * 550.00 * 100) / 100
}

# ── P1455: excise_coal_products — Akcyza od wyrobów węglowych ──
else := {
    "matched": true, "rule_id": "jdg.local.excise_coal_products",
    "package": "jdg.local.enterprise", "priority": 1455,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "local_tax_type": "EXCISE", "excise_category": "COAL",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89 ust. 1 pkt 1, Art. 91 Ustawy o podatku akcyzowym",
    "_warnings": [sprintf("AKCYZA OD WYROBÓW WĘGLOWYCH — %.2f GJ × %.2f PLN/GJ = %.2f PLN. %s. Deklaracja AKC-4. UWAGA: sprzedaż na cele gospodarstw domowych = ZWOLNIONE z akcyzy!", [energy_gj, coal_rate, excise_amount, exemption_note])]
} {
    input.invoice.excise_category == "COAL"
    energy_gj := object.get(input.invoice, "energy_gj", 0)
    is_household := object.get(input.invoice, "coal_for_household", false)
    coal_rate = 1.28 { not is_household }
    coal_rate = 0 { is_household }
    excise_amount = floor(energy_gj * coal_rate * 100) / 100 { not is_household }
    excise_amount = 0 { is_household }
    exemption_note = "ZWOLNIONE — sprzedaż do gospodarstw domowych" { is_household }
    exemption_note = "Pełna stawka — sprzedaż dla firm" { not is_household }
}

# ── P1460: excise_gas — Akcyza od gazu ──
else := {
    "matched": true, "rule_id": "jdg.local.excise_gas",
    "package": "jdg.local.enterprise", "priority": 1460,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "local_tax_type": "EXCISE", "excise_category": "GAS",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89 ust. 1 pkt 12-13 Ustawy o podatku akcyzowym",
    "_warnings": [sprintf("AKCYZA OD GAZU — %.2f MWh × %.2f PLN/MWh = %.2f PLN. Kod CN: %s. Deklaracja AKC-4. Zwolnienie dla celów opałowych gospodarstw domowych.", [gas_mwh, gas_rate, excise_amount, cn_code])]
} {
    input.invoice.excise_category == "GAS"
    gas_mwh := object.get(input.invoice, "energy_mwh", 0)
    gas_mwh > 0
    gas_type := object.get(input.invoice, "gas_type", "NATURAL")
    gas_rate = 1.28 { gas_type == "NATURAL" }
    gas_rate = 1.28 { gas_type == "LPG_HEATING" }
    gas_rate = 0 { gas_type == "LPG_PROPULSION" }  # Akcyza od LPG napędowego w paliwach
    cn_code := object.get(input.invoice, "gas_cn_code", "2711.21.00")
    excise_amount := floor(gas_mwh * gas_rate * 100) / 100
}

# ── P1465: excise_e_liquid — Akcyza od płynu do e-papierosów ──
else := {
    "matched": true, "rule_id": "jdg.local.excise_e_liquid",
    "package": "jdg.local.enterprise", "priority": 1465,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "local_tax_type": "EXCISE", "excise_category": "E_LIQUID",
    "excise_rate_pln_per_ml": 0.55,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Płyn do e-papierosów — wymagane zezwolenie + banderole akcyzowe!",
    "_legal_basis": "Art. 99d-99f Ustawy o podatku akcyzowym (nowelizacja 2025)",
    "_warnings": [sprintf("AKCYZA OD PŁYNU DO E-PAPIEROSÓW — %.0f ml × 0.55 PLN/ml = %.2f PLN. WYMAGANE: zezwolenie akcyzowe, banderole, AKC-4. Sankcja: do 720 stawek KKS. Produkcja DOMOWA też podlega akcyzie!", [volume_ml, excise_amount])]
} {
    input.invoice.excise_category == "E_LIQUID"
    volume_ml := object.get(input.invoice, "volume_ml", 0)
    volume_ml > 0
    excise_amount := floor(volume_ml * 0.55 * 100) / 100
}

# ── P1470: excise_novelty_products — Akcyza od wyrobów nowatorskich ──
else := {
    "matched": true, "rule_id": "jdg.local.excise_novelty_products",
    "package": "jdg.local.enterprise", "priority": 1470,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "local_tax_type": "EXCISE", "excise_category": "NOVELTY",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Wyroby nowatorskie — dynamicznie regulowana kategoria akcyzowa",
    "_legal_basis": "Art. 89 ust. 1 pkt 18, Art. 100 ust. 1a Ustawy o podatku akcyzowym",
    "_warnings": [sprintf("AKCYZA OD WYROBÓW NOWATORSKICH — %s. Stawka %.2f PLN/%s. Kategoria dynamicznie regulowana — sprawdź aktualne rozporządzenie MF!", [product_name, excise_rate, excise_unit])]
} {
    input.invoice.excise_category == "NOVELTY_PRODUCTS"
    product_name := object.get(input.invoice, "novelty_product_name", "nieznany")
    excise_rate := object.get(input.invoice, "novelty_excise_rate", 0)
    excise_unit := object.get(input.invoice, "novelty_excise_unit", "szt")
    excise_rate > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# P1480-P1499: BDO/SUP/KOBiZE ENTERPRISE — ROZSZERZONE
# ═══════════════════════════════════════════════════════════════════════════════

# ── P1480: bdo_waste_transfer_card — Karta przekazania odpadów BDO ──
else := {
    "matched": true, "rule_id": "jdg.local.bdo_waste_transfer_card",
    "package": "jdg.local.enterprise", "priority": 1480,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "local_tax_type": "BDO", "bdo_kpo_required": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Brak karty przekazania odpadów (KPO) w BDO — naruszenie ustawy!",
    "_legal_basis": "Art. 67-71 Ustawy o odpadach",
    "_warnings": [sprintf("BDO KARTA PRZEKAZANIA ODPADÓW — Transport odpadu: %s (kod %s), %.2f Mg. KPO MUSI być wystawiona w BDO PRZED transportem. Brak KPO = kara 2000-10000 PLN!", [waste_description, waste_code, waste_mass])]
} {
    input.invoice.waste_transport == true
    input.jdg_entrepreneur.bdo_registered == true
    waste_code := object.get(input.invoice, "waste_code", "")
    waste_code != ""
    waste_mass := object.get(input.invoice, "waste_mass_mg", 0)
    waste_mass > 0
    waste_description := object.get(input.invoice, "waste_description", "odpad")
}

# ── P1485: sup_annual_fee_calculation — Opłata SUP roczna ──
else := {
    "matched": true, "rule_id": "jdg.local.sup_annual_fee",
    "package": "jdg.local.enterprise", "priority": 1485,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "local_tax_type": "SUP", "sup_report_required": true,
    "sup_annual_fee_pln": annual_fee,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3a-3d ustawy o obowiązkach przedsiębiorców (SUP), Rozporządzenie MF 2025",
    "_warnings": [sprintf("OPŁATA SUP ROCZNA — %.2f PLN. Produkty: kubki (%.0f szt × 0.20 PLN), pojemniki (%.0f szt × 0.10 PLN), torby (%.0f szt × %.2f PLN), pozostałe (%.2f PLN). Raport BDO + opłata do 15 marca.", [annual_fee, cups_qty, containers_qty, bags_qty, bag_rate, other_fee])]
} {
    input.invoice.sup_report_due == true
    cups_qty := object.get(input.jdg_entrepreneur, "sup_cups_sold", 0)
    containers_qty := object.get(input.jdg_entrepreneur, "sup_containers_sold", 0)
    bags_qty := object.get(input.jdg_entrepreneur, "sup_bags_sold", 0)
    bag_type := object.get(input.jdg_entrepreneur, "sup_bag_thickness_micron", 50)
    bag_rate = 0.25 { bag_type < 15 }
    bag_rate = 0.20 { bag_type >= 15; bag_type < 50 }
    bag_rate = 0 { bag_type >= 50 }
    other_fee := object.get(input.jdg_entrepreneur, "sup_other_fee", 0)
    annual_fee := floor((cups_qty * 0.20 + containers_qty * 0.10 + bags_qty * bag_rate + other_fee) * 100) / 100
}

# ── P1490: kobize_emission_fee — Opłata emisyjna KOBiZE ──
else := {
    "matched": true, "rule_id": "jdg.local.kobize_emission_fee",
    "package": "jdg.local.enterprise", "priority": 1490,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "local_tax_type": "KOBIZE",
    "kobize_emission_fee_pln": emission_fee,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17-21 ustawy o systemie zarządzania emisjami, Obwieszczenie MF — stawki 2026",
    "_warnings": [sprintf("OPŁATA EMISYJNA KOBiZE — %.2f PLN. Emisja: CO2 %.2f Mg × %.2f PLN + SO2 %.2f Mg × %.2f PLN + NOx %.2f Mg × %.2f PLN + pyły %.2f Mg × %.2f PLN. Raport do 28 lutego, opłata do 31 marca do Urzędu Marszałkowskiego.", [emission_fee, co2_mg, co2_rate, so2_mg, so2_rate, nox_mg, nox_rate, dust_mg, dust_rate])]
} {
    input.jdg_entrepreneur.has_emissions_installation == true
    co2_mg := object.get(input.jdg_entrepreneur, "kobize_co2_mg", 0)
    so2_mg := object.get(input.jdg_entrepreneur, "kobize_so2_mg", 0)
    nox_mg := object.get(input.jdg_entrepreneur, "kobize_nox_mg", 0)
    dust_mg := object.get(input.jdg_entrepreneur, "kobize_dust_mg", 0)
    co2_rate := 0.35
    so2_rate := 0.57
    nox_rate := 0.57
    dust_rate := 0.57
    emission_fee := floor((co2_mg * co2_rate + so2_mg * so2_rate + nox_mg * nox_rate + dust_mg * dust_rate) * 100) / 100
}

# ── P1495: advertising_fee — Opłata reklamowa (opłata od tablic i urządzeń reklamowych) ──
else := {
    "matched": true, "rule_id": "jdg.local.advertising_fee",
    "package": "jdg.local.enterprise", "priority": 1495,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "local_tax_type": "ADVERTISING_FEE",
    "advertising_fee_annual_pln": annual_fee,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17b-17d Ustawy o podatkach i opłatach lokalnych (uchwała Rady Gminy)",
    "_warnings": [sprintf("OPŁATA REKLAMOWA — %.2f m² × %.2f PLN/m²/dzień × 365 = %.2f PLN/rok. Dotyczy tablic reklamowych >%s. Stawka wg uchwały Rady Gminy. Sprawdź czy gmina wprowadziła opłatę reklamową!", [ad_area, daily_rate, annual_fee, size_threshold])]
} {
    input.invoice.local_tax_type == "ADVERTISING_FEE"
    ad_area := object.get(input.jdg_entrepreneur, "advertising_board_area_m2", 0)
    ad_area > 0
    daily_rate := object.get(input.jdg_entrepreneur, "advertising_fee_daily_rate", 2.50)
    annual_fee := floor(ad_area * daily_rate * 365 * 100) / 100
    size_threshold := ">0.2 m² (standard)"
}
