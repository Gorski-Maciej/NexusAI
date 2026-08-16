# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P33 Excise Supplement (Legal Audit Gap Closure)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Excise Supplement — Tax Warehouse, EMCS, Coal, Lubricants, PV Energy
# description: |
#   Uzupełnienie luk akcyzowych z RAPORT_P33:
#   - Skład podatkowy: rejestracja, ewidencja ilościowa, zabezpieczenia
#   - EMCS: e-AD, e-PP, przemieszczanie między składami
#   - Węgiel i koks: stawki, zwolnienia, e-DD
#   - Oleje smarowe: klasyfikacja, zwolnienia
#   - Energia elektryczna: PV prosumenci, sprzedaż nadwyżki
#   - Zabezpieczenia akcyzowe: gwarancje bankowe, kaucje
#   - Banderole: obowiązek, zwolnienia
# architecture: Enterprise Supplement, First-Match-Wins else-chain
# legal_basis: Ustawa o podatku akcyzowym (Dz.U. 2025 poz. 901)
# package: jdg.p33_excise_supplement
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p33_excise_supplement

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.p33_excise_supplement.no_match",
    "package": "jdg.p33_excise_supplement", "priority": 99999
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-S01: Skład podatkowy — obowiązek rejestracji i prowadzenia
# Wymagany dla produkcji/magazynowania wyrobów akcyzowych
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    excise_category := object.get(input.invoice, "excise_category", "")
    has_tax_warehouse := object.get(input.jdg_entrepreneur, "excise_tax_warehouse", false)

    # Categories requiring tax warehouse
    warehouse_required := excise_category in {"ALCOHOL_PRODUCTION", "TOBACCO_PRODUCTION",
        "MOTOR_FUEL_STORAGE", "ALCOHOL_STORAGE_LARGE"}

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    wh_routing := "BLOCK_AND_ALERT" { warehouse_required; not has_tax_warehouse }
    wh_routing := "" { not warehouse_required }
    wh_routing := "" { has_tax_warehouse }

    reason := sprintf("SKŁAD PODATKOWY WYMAGANY dla kategorii %s! Złóż wniosek do naczelnika UC.",
        [excise_category]) { warehouse_required; not has_tax_warehouse }
    reason := sprintf("Skład podatkowy AKTYWNY — kategoria %s.", [excise_category]) { has_tax_warehouse; warehouse_required }
    reason := "" { not warehouse_required }

    wh_requirements := [
        "1. Zezwolenie naczelnika urzędu celnego",
        "2. Ewidencja ilościowa wyrobów (art. 138a u.p.a.)",
        "3. Zabezpieczenie akcyzowe (gwarancja bankowa lub kaucja)",
        "4. Regularne obmiary i inwentaryzacja",
        "5. Monitoring i rejestracja ruchów EMCS"
    ] { warehouse_required }
    wh_requirements := [] { not warehouse_required }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_excise_supplement.tax_warehouse",
        "package": "jdg.p33_excise_supplement", "priority": 9401,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "excise_warehouse_required": warehouse_required,
        "excise_warehouse_active": has_tax_warehouse,
        "excise_warehouse_category": excise_category,
        "excise_warehouse_requirements": wh_requirements,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": wh_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 47-48 Ustawy o podatku akcyzowym (skład podatkowy)",
        "_warnings": [sprintf("🏭 AKCYZA SKŁAD PODATKOWY: %s. %s",
            [wh_status, req_note])]
    }

    wh_status := "✅ AKTYWNY" { has_tax_warehouse; warehouse_required }
    wh_status := "❌ BRAK — WYMAGANY!" { not has_tax_warehouse; warehouse_required }
    wh_status := "Nie dotyczy" { not warehouse_required }

    req_note := sprintf("%d wymagań do spełnienia.", [count(wh_requirements)]) { count(wh_requirements) > 0 }
    req_note := "" { count(wh_requirements) == 0 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-S02: EMCS — Excise Movement and Control System
# e-AD (elektroniczny dokument administracyjny) przy przemieszczaniu
# między składami podatkowymi w UE
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    excise_category := object.get(input.invoice, "excise_category", "")
    is_intra_eu_movement := object.get(input.invoice, "excise_intra_eu_movement", false)
    is_suspended_duty := object.get(input.invoice, "excise_duty_suspended", false)

    needs_emcs := is_intra_eu_movement and is_suspended_duty
    has_e_ad := object.get(input.invoice, "excise_e_ad_reference", "") != ""

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    emcs_routing := "BLOCK_AND_ALERT" { needs_emcs; not has_e_ad }
    emcs_routing := "" { not needs_emcs }
    emcs_routing := "" { needs_emcs; has_e_ad }

    reason := "EMCS: Wymagane e-AD dla przemieszczenia w procedurze zawieszenia!" { needs_emcs; not has_e_ad }
    reason := sprintf("EMCS: e-AD %s — przemieszczenie w procedurze zawieszenia.",
        [object.get(input.invoice, "excise_e_ad_reference", "N/A")]) { needs_emcs; has_e_ad }
    reason := "" { not needs_emcs }

    # EMCS documents
    emcs_docs := ["e-AD (elektroniczny dokument administracyjny)",
        "e-PP (projektowane powiadomienie o przyjęciu)",
        "Raport odbioru (e-AD zamknięty)" ] { needs_emcs }
    emcs_docs := [] { not needs_emcs }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_excise_supplement.emcs_movement", "_legal_basis": "Art. 47-48 Ustawy o podatku akcyzowym (skład podatkowy)",
        "package": "jdg.p33_excise_supplement", "priority": 9402,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "excise_emcs_required": needs_emcs,
        "excise_emcs_has_e_ad": has_e_ad,
        "excise_emcs_documents": emcs_docs,
        "excise_emcs_procedure": "PROCEDURA ZAWIESZENIA AKCYZY" { is_suspended_duty }
            else = "PROCEDURA STANDARDOWA" { true },
        "business_status": "", "ceidg_registration_required": false,
        "_routing": emcs_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 40-46b Ustawy o podatku akcyzowym; Dyrektywa 2020/262 (EMCS)",
        "_warnings": [sprintf("📋 AKCYZA EMCS: %s. Dokumenty: %d wymagane. %s",
            [emcs_status, count(emcs_docs), link_note])]
    }

    emcs_status := "e-AD WYMAGANY — złóż w systemie EMCS!" { needs_emcs; not has_e_ad }
    emcs_status := sprintf("e-AD %s — w toku", [object.get(input.invoice, "excise_e_ad_reference", "")]) { needs_emcs; has_e_ad }
    emcs_status := "Nie dotyczy" { not needs_emcs }

    link_note := "System EMCS: https://emcs.mf.gov.pl" { needs_emcs }
    link_note := "" { not needs_emcs }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-S03: Węgiel i koks — stawki akcyzy, zwolnienia, e-DD
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    excise_category := object.get(input.invoice, "excise_category", "")
    excise_category in {"COAL", "COKE", "COAL_PRODUCTS"}

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    tonnes := object.get(input.invoice, "quantity_tonnes", 0)
    tonnes > 0

    # Coal excise rates per tonne (2026)
    rate_per_tonne := 13.50 { excise_category == "COAL" }
    rate_per_tonne := 13.50 { excise_category == "COKE" }
    rate_per_tonne := 0 { excise_category == "COAL_PRODUCTS" }
    excise_amount := floor(tonnes * rate_per_tonne * 100) / 100

    # Exemptions
    is_household_heating := object.get(input.invoice, "coal_household_use", false)
    is_business_use := object.get(input.invoice, "coal_business_use", false) and not is_household_heating
    has_e_dd := object.get(input.invoice, "coal_e_dd_compliant", false)

    # Household exemption: coal for household heating is exempt
    final_excise := 0 { is_household_heating }
    final_excise := excise_amount { is_business_use }
    final_excise := excise_amount { true }

    coal_routing := "BLOCK_AND_ALERT" { is_business_use; not has_e_dd; tonnes > 0.5 }
    coal_routing := "TRIAGE_QUEUE" { is_business_use; final_excise > 5000 }
    coal_routing := "" { is_household_heating }
    coal_routing := "" { is_business_use; has_e_dd; final_excise <= 5000 }

    reason := "Węgiel dla FIRMY — wymagane e-DD w systemie SENT!" { is_business_use; not has_e_dd }
    reason := sprintf("Węgiel biznesowy: %.1f ton × %.2f PLN/t = %.2f PLN akcyzy.",
        [tonnes, rate_per_tonne, final_excise]) { is_business_use; has_e_dd }
    reason := "Węgiel do ogrzewania domowego — ZWOLNIONY z akcyzy." { is_household_heating }
    reason := "" { true }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_excise_supplement.coal_excise",
        "package": "jdg.p33_excise_supplement", "priority": 9403,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "excise_coal_type": excise_category,
        "excise_coal_tonnes": tonnes,
        "excise_coal_rate_per_tonne": rate_per_tonne,
        "excise_coal_amount_pln": final_excise,
        "excise_coal_household_exempt": is_household_heating,
        "excise_coal_e_dd_required": is_business_use,
        "excise_coal_e_dd_compliant": has_e_dd,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": coal_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 89 ust. 1 pkt 1 Ustawy o podatku akcyzowym; Art. 31b SENT/e-DD",
        "_warnings": [sprintf("🪨 AKCYZA WĘGIEL/KOKS: %s — %.1f ton. Akcyza=%.2f PLN. %s %s",
            [excise_category, tonnes, final_excise, use_note, edd_note])]
    }

    use_note := "ZWOLNIONE (gospodarstwo domowe)" { is_household_heating }
    use_note := sprintf("BIZNES — %.2f PLN akcyzy", [final_excise]) { is_business_use }

    edd_note := "⚠️ e-DD WYMAGANE w SENT!" { is_business_use; not has_e_dd }
    edd_note := "✅ e-DD zgłoszone" { is_business_use; has_e_dd }
    edd_note := "" { is_household_heating }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-S04: Oleje smarowe — klasyfikacja i zwolnienia
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    excise_category := object.get(input.invoice, "excise_category", "")
    excise_category == "LUBRICANT_OIL"

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    volume_liters := object.get(input.invoice, "quantity_liters", 0)
    volume_liters > 0

    oil_type := object.get(input.invoice, "oil_type", "ENGINE_OIL")
    cn_code := object.get(input.invoice, "oil_cn_code", "")

    # Most lubricating oils: 0% excise rate (zero rate)
    rate_per_1000l := 0 { cn_code in {"27101981", "27101983", "27101987", "27101991", "27101993", "27101999"} }
    rate_per_1000l := 0 { oil_type in {"ENGINE_OIL", "GEAR_OIL", "HYDRAULIC_OIL", "INDUSTRIAL_OIL"} }
    rate_per_1000l := 1180 { oil_type == "HEATING_LUBRICANT" }  # If used as heating fuel
    else := 0 { true }

    excise_amount := floor(volume_liters * rate_per_1000l / 1000 * 100) / 100
    is_exempt := rate_per_1000l == 0

    oil_routing := "TRIAGE_QUEUE" { not is_exempt; excise_amount > 1000 }
    oil_routing := "" { is_exempt }
    oil_routing := "" { not is_exempt; excise_amount <= 1000 }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_excise_supplement.lubricant_oils",
        "package": "jdg.p33_excise_supplement", "priority": 9404,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "excise_oil_type": oil_type,
        "excise_oil_cn_code": cn_code,
        "excise_oil_volume_l": volume_liters,
        "excise_oil_rate_per_1000l": rate_per_1000l,
        "excise_oil_amount_pln": excise_amount,
        "excise_oil_is_exempt": is_exempt,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": oil_routing,
        "_routing_reason": sprintf("Oleje smarowe: %s", [oil_status]),
        "_legal_basis": "Art. 89 ust. 1 Ustawy o podatku akcyzowym (załącznik nr 1)",
        "_warnings": [sprintf("🛢️ AKCYZA OLEJE SMAROWE: %s (CN %s) — %.0f L. %s. Stawka=%.0f PLN/1000L.",
            [oil_type, cn_code, volume_liters, oil_status, rate_per_1000l])]
    }

    oil_status := "ZWOLNIONE (stawka 0%)" { is_exempt }
    oil_status := sprintf("Akcyza=%.2f PLN", [excise_amount]) { not is_exempt }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-S05: Energia elektryczna — PV prosumenci i sprzedaż nadwyżki
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    excise_category := object.get(input.invoice, "excise_category", "")
    excise_category in {"ELECTRICITY_SALE", "PV_ENERGY"}

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    energy_mwh := object.get(input.invoice, "quantity_mwh", 0)
    energy_mwh > 0

    is_prosumer := object.get(input.jdg_entrepreneur, "pv_prosumer", false)
    pv_capacity_kw := object.get(input.jdg_entrepreneur, "pv_installed_capacity_kw", 0)
    is_micro_installation := pv_capacity_kw <= 50

    # Prosumer exemption: micro-installations (≤50 kW) exempt from excise
    is_exempt := is_prosumer and is_micro_installation
    # Commercial producer rate
    rate_per_mwh := 5.00  # PLN/MWh for commercial producers
    excise_amount := floor(energy_mwh * rate_per_mwh * 100) / 100
    final_excise := 0 { is_exempt }
    final_excise := excise_amount { not is_exempt }

    energy_routing := "TRIAGE_QUEUE" { not is_exempt; final_excise > 500 }
    energy_routing := "" { is_exempt }
    energy_routing := "" { not is_exempt; final_excise <= 500 }

    reason := sprintf("Energia PV — produkcja komercyjna: %.2f MWh × %.2f PLN/MWh = %.2f PLN akcyzy.",
        [energy_mwh, rate_per_mwh, final_excise]) { not is_exempt }
    reason := sprintf("Prosument PV (%.0f kW) — ZWOLNIONY z akcyzy od sprzedaży nadwyżki.",
        [pv_capacity_kw]) { is_exempt }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_excise_supplement.electricity_pv",
        "package": "jdg.p33_excise_supplement", "priority": 9405,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "excise_energy_mwh": energy_mwh,
        "excise_energy_rate_per_mwh": rate_per_mwh,
        "excise_energy_amount_pln": final_excise,
        "excise_energy_prosumer": is_prosumer,
        "excise_energy_pv_capacity_kw": pv_capacity_kw,
        "excise_energy_is_exempt": is_exempt,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": energy_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 2 ust. 1 pkt 6, Art. 89 ust. 1 Ustawy o podatku akcyzowym; Art. 4d zwolnienie prosumentów",
        "_warnings": [sprintf("⚡ AKCYZA ENERGIA PV: Moc=%.0f kW, Produkcja=%.2f MWh. %s. %s",
            [pv_capacity_kw, energy_mwh, pv_status, note]])]
    }

    pv_status := sprintf("ZWOLNIONE (prosument ≤50 kW, %s kW)", [pv_capacity_kw]) { is_exempt }
    pv_status := sprintf("Akcyza komercyjna: %.2f PLN", [final_excise]) { not is_exempt }

    note := "Ewidencja ilościowa nawet dla prosumenta (de minimis)!" { is_prosumer }
    note := "Deklaracja AKC-4 miesięcznie + ewidencja ilościowa." { not is_prosumer }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-S06: Zabezpieczenia akcyzowe — gwarancje i kaucje
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    has_tax_warehouse := object.get(input.jdg_entrepreneur, "excise_tax_warehouse", false)
    is_registered_trader := object.get(input.jdg_entrepreneur, "excise_registered_trader", false)

    needs_guarantee := has_tax_warehouse or is_registered_trader

    guarantee_type := object.get(input.jdg_entrepreneur, "excise_guarantee_type", "NONE")
    guarantee_amount := object.get(input.jdg_entrepreneur, "excise_guarantee_amount", 0)
    guarantee_valid_until := object.get(input.jdg_entrepreneur, "excise_guarantee_valid_until", "")
    is_expired := guarantee_valid_until != "" and guarantee_valid_until < "2026-07-01"

    has_valid_guarantee := guarantee_type in {"BANK_GUARANTEE", "CASH_DEPOSIT", "INSURANCE_BOND"} and not is_expired and guarantee_amount > 0

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    guar_routing := "BLOCK_AND_ALERT" { needs_guarantee; not has_valid_guarantee }
    guar_routing := "TRIAGE_QUEUE" { needs_guarantee; is_expired }
    guar_routing := "" { not needs_guarantee }
    guar_routing := "" { needs_guarantee; has_valid_guarantee; not is_expired }

    reason := "ZABEZPIECZENIE AKCYZOWE WYMAGANE — złóż gwarancję bankową lub kaucję!" { needs_guarantee; not has_valid_guarantee }
    reason := sprintf("Zabezpieczenie WYGASŁO %s — odnowić!", [guarantee_valid_until]) { needs_guarantee; is_expired }
    reason := "" { true }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_excise_supplement.excise_guarantee",
        "package": "jdg.p33_excise_supplement", "priority": 9406,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "excise_guarantee_required": needs_guarantee,
        "excise_guarantee_type": guarantee_type,
        "excise_guarantee_amount": guarantee_amount,
        "excise_guarantee_valid_until": guarantee_valid_until,
        "excise_guarantee_is_valid": has_valid_guarantee,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": guar_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 64-76 Ustawy o podatku akcyzowym (zabezpieczenia akcyzowe)",
        "_warnings": [sprintf("🔐 AKCYZA ZABEZPIECZENIE: %s. Typ=%s, Kwota=%.0f PLN, Ważne do=%s. %s",
            [guar_needed, guarantee_type, guarantee_amount, guarantee_valid_until, guar_status])]
    }

    guar_needed := "WYMAGANE" { needs_guarantee }
    guar_needed := "Nie dotyczy" { not needs_guarantee }

    guar_status := "✅ AKTYWNE" { has_valid_guarantee; not is_expired }
    guar_status := "⚠️ WYGASŁO — odnów!" { is_expired }
    guar_status := "❌ BRAK — złóż natychmiast!" { needs_guarantee; not has_valid_guarantee }
    guar_status := "" { not needs_guarantee }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-S07: Banderole podatkowe — obowiązek i zwolnienia
# Dla alkoholu i tytoniu w opakowaniach detalicznych
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    excise_category := object.get(input.invoice, "excise_category", "")
    needs_banderole := excise_category in {"ALCOHOL", "TOBACCO"}

    has_banderoles := object.get(input.jdg_entrepreneur, "excise_banderoles_acquired", false)
    banderole_quantity := object.get(input.jdg_entrepreneur, "excise_banderole_quantity", 0)

    is_export := object.get(input.invoice, "excise_export", false)
    is_duty_free := object.get(input.invoice, "excise_duty_free_shop", false)
    exempt_banderole := is_export or is_duty_free

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    band_routing := "BLOCK_AND_ALERT" { needs_banderole; not has_banderoles; not exempt_banderole }
    band_routing := "" { not needs_banderole }
    band_routing := "" { exempt_banderole }
    band_routing := "" { has_banderoles }

    reason := "BANDEROLE WYMAGANE dla alkoholu/tytoniu w opakowaniach detalicznych!" { needs_banderole; not has_banderoles; not exempt_banderole }
    reason := sprintf("Banderole: %d szt. na składzie.", [banderole_quantity]) { has_banderoles }
    reason := "Zwolnienie z banderol (eksport/duty-free)." { exempt_banderole }
    reason := "" { not needs_banderole }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_excise_supplement.banderoles",
        "package": "jdg.p33_excise_supplement", "priority": 9407,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "excise_banderole_required": needs_banderole,
        "excise_banderole_acquired": has_banderoles,
        "excise_banderole_quantity": banderole_quantity,
        "excise_banderole_exempt_export": exempt_banderole,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": band_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 114-134 Ustawy o podatku akcyzowym (banderole podatkowe)",
        "_warnings": [sprintf("🏷️ AKCYZA BANDEROLE: %s. %s. %s",
            [band_status, quant, exempt_note])]
    }

    band_status := "WYMAGANE" { needs_banderole; not has_banderoles; not exempt_banderole }
    band_status := sprintf("%d szt. na stanie", [banderole_quantity]) { has_banderoles }
    band_status := "ZWOLNIONE" { exempt_banderole }
    band_status := "Nie dotyczy" { not needs_banderole }

    quant := sprintf("Ilość: %d", [banderole_quantity]) { has_banderoles }
    quant := "Zamów w urzędzie celnym" { needs_banderole; not has_banderoles }

    exempt_note := "(eksport/duty-free)" { exempt_banderole }
    exempt_note := "" { not exempt_banderole }
}
