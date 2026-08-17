# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Excise Enterprise Complete (Class IX: Excise Duty)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Excise Enterprise Complete — Comprehensive Excise Duty Coverage
# description: |
#   ENTERPRISE v6.1 — Domknięcie luki 75+ punktów prawnych w akcyzie.
#   Pekrycie: paliwa (benzyna/ON/LPG/olej opałowy), alkohol (piwo/wino/
#   wyroby spirytusowe/alkohol etylowy), tytoń (papierosy/cygara/tytoń do
#   palenia), energia (prąd dla biznesu), skład podatkowy, procedury
#   zawieszenia akcyzy, AKC-4/AKC-4ZO, zwolnienia (lotnictwo, rolnictwo,
#   ogrzewanie, żegluga), banderole, zabezpieczenia akcyzowe, e-DD.
# architecture: Enterprise Multi-Pass (ADR-001), First-Match-Wins else-chain
# legal_basis: ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) (Dz.U. 2025 poz. 901),
#   Rozporządzenia MF w sprawie stawek akcyzy, Dyrektywa 2020/262
# package: jdg.local_taxes.excise_enterprise
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.local_taxes.excise_enterprise

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.local_taxes.excise.no_match",
    "package": "jdg.local_taxes.excise_enterprise", "priority": 1499
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-100: FUEL EXCISE — Benzyna silnikowa (gasoline)
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    input.invoice.excise_category == "MOTOR_FUEL"
    fuel_type := object.get(input.invoice, "fuel_type", "GASOLINE_UNLEADED")
    fuel_type in {"GASOLINE_UNLEADED", "GASOLINE_LEADED", "GASOLINE_E5", "GASOLINE_E10"}

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    volume_liters := object.get(input.invoice, "quantity_liters", 0)
    volume_liters > 0

    # Stawki akcyzy 2026 per 1000 litrów
    rate_per_1000l := 1659 { fuel_type in {"GASOLINE_UNLEADED", "GASOLINE_E5", "GASOLINE_E10"} }
    rate_per_1000l := 1859 { fuel_type == "GASOLINE_LEADED" }
    excise_amount := floor(volume_liters * rate_per_1000l / 1000 * 100) / 100

    fuel_label := "Benzyna bezołowiowa 95/98" { fuel_type != "GASOLINE_LEADED" }
    fuel_label := "Benzyna ołowiowa" { fuel_type == "GASOLINE_LEADED" }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.excise.motor_fuel_gasoline",
        "package": "jdg.local_taxes.excise_enterprise", "priority": 1451,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
        "local_tax_type": "EXCISE", "excise_category": "MOTOR_FUEL",
        "excise_fuel_type": fuel_label, "excise_volume_liters": volume_liters,
        "excise_rate_per_1000l": rate_per_1000l,
        "excise_amount_pln": excise_amount,
        "excise_declaration": "AKC-4", "excise_deadline_monthly": "25th of following month",
        "_routing": excise_routing, "_routing_reason": excise_routing_reason,
        "_legal_basis": "Art. 89 ust. 1 pkt 1-5 Ustawy o podatku akcyzowym",
        "_warnings": [sprintf("⛽ AKCYZA PALIWOWA: %s — %.0f L × %.0f PLN/1000L = %.2f PLN. AKC-4 do 25. dnia następnego miesiąca. Częściowy zwrot dla rolników (olej napędowy).", [fuel_label, volume_liters, rate_per_1000l, excise_amount])]
    }

    excise_routing := "TRIAGE_QUEUE" { excise_amount > 5000 }
    excise_routing := "" { excise_amount <= 5000 }
    excise_routing_reason := sprintf("Akcyza paliwowa %.2f PLN — sprawdź AKC-4", [excise_amount]) { excise_amount > 5000 }
    excise_routing_reason := "" { excise_amount <= 5000 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-105: FUEL EXCISE — Olej napędowy (diesel)
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.excise_category == "MOTOR_FUEL"
    fuel_type := object.get(input.invoice, "fuel_type", "DIESEL")
    fuel_type == "DIESEL"

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    volume_liters := object.get(input.invoice, "quantity_liters", 0)
    volume_liters > 0

    rate_per_1000l := 1319  # Stawka 2026 dla ON
    excise_amount := floor(volume_liters * rate_per_1000l / 1000 * 100) / 100

    is_agriculture := object.get(input.invoice, "diesel_for_agriculture", false)
    refund_pct := 1.20 { is_agriculture == true }
    refund_pct := 0 { is_agriculture == false }
    refund_amount := floor(volume_liters * refund_pct * 100) / 100 { is_agriculture == true }
    refund_amount := 0 { is_agriculture == false }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.excise.motor_fuel_diesel",
        "package": "jdg.local_taxes.excise_enterprise", "priority": 1452,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
        "local_tax_type": "EXCISE", "excise_category": "MOTOR_FUEL",
        "excise_fuel_type": "Olej napędowy (ON)", "excise_volume_liters": volume_liters,
        "excise_rate_per_1000l": rate_per_1000l,
        "excise_amount_pln": excise_amount,
        "excise_diesel_agriculture_refund_pln": refund_amount,
        "excise_declaration": "AKC-4", "excise_deadline_monthly": "25th of following month",
        "_routing": "", "_routing_reason": "",
        "_legal_basis": "Art. 89 ust. 1 pkt 6 Ustawy o podatku akcyzowym; Art. 5-7 ustawy o zwrocie akcyzy rolnikom",
        "_warnings": [sprintf("⛽ AKCYZA ON: Olej napędowy — %.0f L × %.0f PLN/1000L = %.2f PLN. %s. AKC-4 miesięcznie. Zwrot dla rolników: %.2f PLN/litr × limit 100 L/ha.", [volume_liters, rate_per_1000l, excise_amount, agri_note])]
    }

    agri_note := sprintf("Refundacja rolnicza: %.2f PLN", [refund_amount]) { is_agriculture == true }
    agri_note := "" { is_agriculture == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-110: FUEL EXCISE — LPG i gaz ziemny napędowy (CNG/LNG)
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.excise_category == "MOTOR_FUEL"
    fuel_type := object.get(input.invoice, "fuel_type", "LPG")
    fuel_type in {"LPG", "CNG", "LNG"}

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    volume_kg := object.get(input.invoice, "quantity_kg", 0)
    volume_kg > 0

    rate_per_1000kg := 700 { fuel_type == "LPG" }
    rate_per_1000kg := 449 { fuel_type in {"CNG", "LNG"} }
    excise_amount := floor(volume_kg * rate_per_1000kg / 1000 * 100) / 100

    fuel_label := "LPG (autogaz)" { fuel_type == "LPG" }
    fuel_label := "CNG (sprężony gaz ziemny)" { fuel_type == "CNG" }
    fuel_label := "LNG (skroplony gaz ziemny)" { fuel_type == "LNG" }
    unit_label := "kg"

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.excise.motor_fuel_lpg_cng",
        "package": "jdg.local_taxes.excise_enterprise", "priority": 1453,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
        "local_tax_type": "EXCISE", "excise_category": "MOTOR_FUEL",
        "excise_fuel_type": fuel_label, "excise_quantity": volume_kg,
        "excise_rate_per_1000kg": rate_per_1000kg,
        "excise_amount_pln": excise_amount,
        "excise_declaration": "AKC-4", "excise_deadline_monthly": "25th of following month",
        "_routing": "", "_routing_reason": "",
        "_legal_basis": "Art. 89 ust. 1 pkt 7-9 Ustawy o podatku akcyzowym",
        "_warnings": [sprintf("⛽ AKCYZA %s: %.0f kg × %.0f PLN/1000kg = %.2f PLN. AKC-4 miesięcznie.", [fuel_label, volume_kg, rate_per_1000kg, excise_amount])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-115: HEATING FUEL — Olej opałowy i grzewczy
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.excise_category == "HEATING_FUEL"
    fuel_type := object.get(input.invoice, "fuel_type", "HEATING_OIL_LIGHT")

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    volume_liters := object.get(input.invoice, "quantity_liters", 0)
    volume_liters > 0

    # Stawki dla olejów grzewczych
    rate_per_1000l := 64 { fuel_type == "HEATING_OIL_LIGHT" }
    rate_per_1000l := 64 { fuel_type == "HEATING_OIL_HEAVY" }
    rate_per_1000l := 0 { fuel_type == "HEATING_OIL_RESIDENTIAL" }
    excise_amount := floor(volume_liters * rate_per_1000l / 1000 * 100) / 100

    is_business_use := object.get(input.invoice, "heating_business_use", false)
    has_e_dd := object.get(input.invoice, "heating_e_dd_compliant", false)

    fuel_label := "Olej opałowy lekki" { fuel_type == "HEATING_OIL_LIGHT" }
    fuel_label := "Olej opałowy ciężki" { fuel_type == "HEATING_OIL_HEAVY" }
    fuel_label := "Olej grzewczy — mieszkalny (zwolniony)" { fuel_type == "HEATING_OIL_RESIDENTIAL" }

    excise_routing := "BLOCK_AND_ALERT" { is_business_use == true; has_e_dd == false }
    excise_routing := "" { true }
    excise_routing_reason := "Olej opałowy dla firmy — wymagane e-DD!" { is_business_use == true; has_e_dd == false }
    excise_routing_reason := "" { true }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.excise.heating_fuel",
        "package": "jdg.local_taxes.excise_enterprise", "priority": 1454,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
        "local_tax_type": "EXCISE", "excise_category": "HEATING_FUEL",
        "excise_fuel_type": fuel_label, "excise_volume_liters": volume_liters,
        "excise_amount_pln": excise_amount,
        "excise_e_dd_required": is_business_use, "excise_e_dd_compliant": has_e_dd,
        "excise_declaration": "AKC-4",
        "_routing": excise_routing, "_routing_reason": excise_routing_reason,
        "_legal_basis": "Art. 89 ust. 1 pkt 10-12 Ustawy o podatku akcyzowym; Art. 31b e-DD",
        "_warnings": [sprintf("🔥 AKCYZA GRZEWCZA: %s — %.0f L × %.0f PLN/1000L = %.2f PLN. %s AKC-4 miesięcznie. Używanie oleju opałowego jako napędowego = KARA do 720 stawek KKS!", [fuel_label, volume_liters, rate_per_1000l, excise_amount, edd_note])]
    }

    edd_note := "e-DD WYMAGANE — zgłoś w systemie SENT!" { is_business_use == true; has_e_dd == false }
    edd_note := "e-DD OK" { is_business_use == true; has_e_dd == true }
    edd_note := "" { is_business_use == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-200: ALCOHOL EXCISE — Piwo (beer)
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.excise_category == "ALCOHOL"
    alcohol_type := object.get(input.invoice, "alcohol_type", "BEER")
    alcohol_type == "BEER"

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    volume_hl := object.get(input.invoice, "quantity_hectoliters", 0)
    plato_degree := object.get(input.invoice, "beer_plato_degree", 12.0)
    volume_hl > 0

    # Stawka akcyzy na piwo: 9.29 PLN od 1 hl za każdy stopień Plato
    rate_per_hl_plato := 9.29
    excise_per_hl := rate_per_hl_plato * plato_degree
    excise_amount := floor(volume_hl * excise_per_hl * 100) / 100

    is_small_brewery := object.get(input.invoice, "alcohol_small_producer", false)
    annual_production_hl := object.get(input.jdg_entrepreneur, "annual_beer_production_hl", 500)
    reduced_rate := excise_per_hl { is_small_brewery == false }
    reduced_rate := excise_per_hl * 0.7 { is_small_brewery == true; annual_production_hl <= 5000 }
    reduced_rate := excise_per_hl { is_small_brewery == true; annual_production_hl > 5000; annual_production_hl <= 200000 }
    final_amount := floor(volume_hl * reduced_rate * 100) / 100

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.excise.alcohol_beer",
        "package": "jdg.local_taxes.excise_enterprise", "priority": 1461,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
        "local_tax_type": "EXCISE", "excise_category": "ALCOHOL",
        "excise_alcohol_type": "Piwo", "excise_volume_hl": volume_hl,
        "excise_plato_degree": plato_degree, "excise_rate_per_hl": excise_per_hl,
        "excise_amount_pln": final_amount,
        "excise_small_brewery_discount": is_small_brewery,
        "excise_declaration": "AKC-4", "excise_deadline_monthly": "25th of following month",
        "_routing": excise_routing, "_routing_reason": excise_routing_reason,
        "_legal_basis": "Art. 94-96 Ustawy o podatku akcyzowym",
        "_warnings": [sprintf("🍺 AKCYZA PIWO: %.2f hl × %.1f°Plato × %.2f PLN = %.2f PLN (podstawa), %.2f PLN (po ulgach). %s AKC-4 + banderole (jeśli sprzedaż detaliczna). Skład podatkowy WYMAGANY!", [volume_hl, plato_degree, rate_per_hl_plato, excise_amount, final_amount, brewery_note])]
    }

    brewery_note := sprintf("Ulga dla małego browaru (produkcja %.0f hl/rok)", [annual_production_hl]) { is_small_brewery == true }
    brewery_note := "Standardowa stawka" { is_small_brewery == false }
    excise_routing := "BLOCK_AND_ALERT" { volume_hl > 100 }
    excise_routing := "" { volume_hl <= 100 }
    excise_routing_reason := "Akcyza piwo — duży wolumen, weryfikacja składu podatkowego!" { volume_hl > 100 }
    excise_routing_reason := "" { volume_hl <= 100 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-205: ALCOHOL EXCISE — Wino i napoje fermentowane
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.excise_category == "ALCOHOL"
    alcohol_type := object.get(input.invoice, "alcohol_type", "WINE")
    alcohol_type in {"WINE", "CIDER", "MEAD", "FERMENTED_DRINK"}

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    volume_hl := object.get(input.invoice, "quantity_hectoliters", 0)
    volume_hl > 0

    rate_per_hl := 216 { alcohol_type == "WINE" }
    rate_per_hl := 108 { alcohol_type in {"CIDER", "MEAD", "FERMENTED_DRINK"} }
    excise_amount := floor(volume_hl * rate_per_hl * 100) / 100

    label := "Wino" { alcohol_type == "WINE" }
    label := "Cydr" { alcohol_type == "CIDER" }
    label := "Miód pitny" { alcohol_type == "MEAD" }
    label := "Napój fermentowany" { alcohol_type == "FERMENTED_DRINK" }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.excise.alcohol_wine",
        "package": "jdg.local_taxes.excise_enterprise", "priority": 1462,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
        "local_tax_type": "EXCISE", "excise_category": "ALCOHOL",
        "excise_alcohol_type": label, "excise_volume_hl": volume_hl,
        "excise_rate_per_hl": rate_per_hl, "excise_amount_pln": excise_amount,
        "excise_declaration": "AKC-4", "excise_deadline_monthly": "25th of following month",
        "_routing": "", "_routing_reason": "",
        "_legal_basis": "Art. 97 Ustawy o podatku akcyzowym",
        "_warnings": [sprintf("🍷 AKCYZA %s: %.2f hl × %.0f PLN/hl = %.2f PLN. AKC-4 miesięcznie. Banderole dla opakowań detalicznych.", [label, volume_hl, rate_per_hl, excise_amount])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-210: ALCOHOL EXCISE — Wyroby spirytusowe + alkohol etylowy
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.excise_category == "ALCOHOL"
    alcohol_type := object.get(input.invoice, "alcohol_type", "SPIRITS")
    alcohol_type in {"SPIRITS", "ETHYL_ALCOHOL", "VODKA", "WHISKY"}

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    volume_hl_100pct := object.get(input.invoice, "quantity_hl_100pct_alcohol", 0)
    volume_hl_100pct > 0

    rate_per_hl_100pct := 8700  # Stawka 2026 za 1 hl 100% alkoholu
    excise_amount := floor(volume_hl_100pct * rate_per_hl_100pct * 100) / 100

    label := "Wyroby spirytusowe" { alcohol_type in {"SPIRITS", "VODKA", "WHISKY"} }
    label := "Alkohol etylowy" { alcohol_type == "ETHYL_ALCOHOL" }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.excise.alcohol_spirits",
        "package": "jdg.local_taxes.excise_enterprise", "priority": 1463,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
        "local_tax_type": "EXCISE", "excise_category": "ALCOHOL",
        "excise_alcohol_type": label, "excise_volume_hl_100pct": volume_hl_100pct,
        "excise_rate_per_hl_100pct": rate_per_hl_100pct,
        "excise_amount_pln": excise_amount,
        "excise_declaration": "AKC-4", "excise_deadline_monthly": "25th of following month",
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": "Wyroby spirytusowe — skład podatkowy + zabezpieczenie akcyzowe WYMAGANE!",
        "_legal_basis": "Art. 93 Ustawy o podatku akcyzowym",
        "_warnings": [sprintf("🥃 AKCYZA SPIRYTUSOWA: %s — %.4f hl 100%% × %.0f PLN/hl = %.2f PLN. SKŁAD PODATKOWY + ZABEZPIECZENIE AKCYZOWE WYMAGANE! Banderole legalizacyjne. AKC-4 miesięcznie. Produkcja DOMOWA na własny użytek = ZWOLNIONA (tylko dla celów niehandlowych).", [label, volume_hl_100pct, rate_per_hl_100pct, excise_amount])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-300: TOBACCO EXCISE — Papierosy
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.excise_category == "TOBACCO"
    tobacco_type := object.get(input.invoice, "tobacco_type", "CIGARETTES")
    tobacco_type == "CIGARETTES"

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    quantity_1000s := object.get(input.invoice, "quantity_per_1000", 0)
    quantity_1000s > 0
    retail_price_per_1000 := object.get(input.invoice, "retail_price_per_1000_pln", 0)
    retail_price_per_1000 > 0

    # Stawka: 32% ceny detalicznej + 105 PLN/1000 szt
    ad_valorem := retail_price_per_1000 * 0.32
    specific := 105.00
    total_per_1000 := ad_valorem + specific
    excise_amount := floor(quantity_1000s * total_per_1000 * 100) / 100

    min_excise_per_1000 := retail_price_per_1000 * 0.70  # Minimum 70% ceny
    final_per_1000 := total_per_1000 { total_per_1000 >= min_excise_per_1000 }
    final_per_1000 := min_excise_per_1000 { total_per_1000 < min_excise_per_1000 }
    final_amount := floor(quantity_1000s * final_per_1000 * 100) / 100

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.excise.tobacco_cigarettes",
        "package": "jdg.local_taxes.excise_enterprise", "priority": 1471,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
        "local_tax_type": "EXCISE", "excise_category": "TOBACCO",
        "excise_tobacco_type": "Papierosy", "excise_quantity_1000s": quantity_1000s,
        "excise_retail_price_1000": retail_price_per_1000,
        "excise_ad_valorem_pct": 32, "excise_specific_pln": specific,
        "excise_amount_pln": final_amount,
        "excise_minimum_70pct_applied": total_per_1000 < min_excise_per_1000,
        "excise_declaration": "AKC-4", "excise_deadline_monthly": "25th of following month",
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": "Wyroby tytoniowe — skład podatkowy + banderole + nanoszenie znaków akcyzy!",
        "_legal_basis": "Art. 99-99a Ustawy o podatku akcyzowym; Mapa drogowa akcyzy tytoniowej 2025-2027",
        "_warnings": [sprintf("🚬 AKCYZA PAPIEROSY: %.1f tys. szt × (32%% z %.2f PLN + 105 PLN) = %.2f PLN. %s SKŁAD PODATKOWY + BANDEROLE + ZNAKI AKCYZY WYMAGANE! MAPA DROGOWA 2027: stawka rośnie do 40%% + 140 PLN/1000szt.", [quantity_1000s, retail_price_per_1000, final_amount, min_note])]
    }

    min_note := "MINIMUM 70% ceny detalicznej ZASTOSOWANE" { total_per_1000 < min_excise_per_1000 }
    min_note := "" { total_per_1000 >= min_excise_per_1000 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-305: TOBACCO EXCISE — Cygara i cygaretki
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.excise_category == "TOBACCO"
    tobacco_type := object.get(input.invoice, "tobacco_type", "CIGARS")
    tobacco_type in {"CIGARS", "CIGARILLOS"}

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    quantity_1000s := object.get(input.invoice, "quantity_per_1000", 0)
    quantity_1000s > 0

    rate_per_1000 := 595 { tobacco_type == "CIGARS" }
    rate_per_1000 := 595 { tobacco_type == "CIGARILLOS" }
    excise_amount := floor(quantity_1000s * rate_per_1000 * 100) / 100

    label := "Cygara" { tobacco_type == "CIGARS" }
    label := "Cygaretki" { tobacco_type == "CIGARILLOS" }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.excise.tobacco_cigars",
        "package": "jdg.local_taxes.excise_enterprise", "priority": 1472,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
        "local_tax_type": "EXCISE", "excise_category": "TOBACCO",
        "excise_tobacco_type": label, "excise_quantity_1000s": quantity_1000s,
        "excise_rate_per_1000": rate_per_1000, "excise_amount_pln": excise_amount,
        "excise_declaration": "AKC-4", "excise_deadline_monthly": "25th of following month",
        "_routing": "TRIAGE_QUEUE", "_routing_reason": "Cygara — skład podatkowy + banderole",
        "_legal_basis": "Art. 99b Ustawy o podatku akcyzowym",
        "_warnings": [sprintf("🚬 AKCYZA %s: %.1f tys. szt × %.0f PLN/1000szt = %.2f PLN. Banderole + skład podatkowy.", [label, quantity_1000s, rate_per_1000, excise_amount])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-310: TOBACCO EXCISE — Tytoń do palenia
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.excise_category == "TOBACCO"
    tobacco_type := object.get(input.invoice, "tobacco_type", "SMOKING_TOBACCO")
    tobacco_type in {"SMOKING_TOBACCO", "PIPE_TOBACCO"}

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    quantity_kg := object.get(input.invoice, "quantity_kg", 0)
    quantity_kg > 0

    rate_per_kg := 300 { tobacco_type == "SMOKING_TOBACCO" }
    rate_per_kg := 300 { tobacco_type == "PIPE_TOBACCO" }
    excise_amount := floor(quantity_kg * rate_per_kg * 100) / 100

    label := "Tytoń do palenia" { tobacco_type == "SMOKING_TOBACCO" }
    label := "Tytoń fajkowy" { tobacco_type == "PIPE_TOBACCO" }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.excise.tobacco_smoking",
        "package": "jdg.local_taxes.excise_enterprise", "priority": 1473,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
        "local_tax_type": "EXCISE", "excise_category": "TOBACCO",
        "excise_tobacco_type": label, "excise_quantity_kg": quantity_kg,
        "excise_rate_per_kg": rate_per_kg, "excise_amount_pln": excise_amount,
        "excise_declaration": "AKC-4", "excise_deadline_monthly": "25th of following month",
        "_routing": "", "_routing_reason": "",
        "_legal_basis": "Art. 99c Ustawy o podatku akcyzowym",
        "_warnings": [sprintf("🚬 AKCYZA TYTOŃ: %s — %.1f kg × %.0f PLN/kg = %.2f PLN. Banderole + AKC-4.", [label, quantity_kg, rate_per_kg, excise_amount])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-400: ENERGY EXCISE — Energia elektryczna dla biznesu
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.excise_category == "ENERGY"
    energy_type := object.get(input.invoice, "energy_type", "ELECTRICITY")
    energy_type == "ELECTRICITY"

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    energy_mwh := object.get(input.invoice, "energy_mwh", 0)
    energy_mwh > 0

    is_business := object.get(input.invoice, "electricity_business_use", true)
    is_renewable := object.get(input.invoice, "electricity_renewable_source", false)

    rate_per_mwh := 5.00 { is_business == true }
    rate_per_mwh := 0 { is_business == false }
    rate_per_mwh := 0 { is_renewable == true }
    excise_amount := floor(energy_mwh * rate_per_mwh * 100) / 100

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.excise.energy_electricity",
        "package": "jdg.local_taxes.excise_enterprise", "priority": 1481,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
        "local_tax_type": "EXCISE", "excise_category": "ENERGY",
        "excise_energy_type": "Energia elektryczna",
        "excise_energy_mwh": energy_mwh, "excise_rate_per_mwh": rate_per_mwh,
        "excise_amount_pln": excise_amount,
        "excise_business_use": is_business,
        "excise_renewable_exempt": is_renewable,
        "excise_declaration": "AKC-4", "excise_deadline_monthly": "25th of following month",
        "_routing": "", "_routing_reason": "",
        "_legal_basis": "Art. 89 ust. 1 pkt 14-16, Art. 30 ust. 8 Ustawy o podatku akcyzowym",
        "_warnings": [sprintf("⚡ AKCYZA ENERGETYCZNA: Prąd — %.2f MWh × %.2f PLN/MWh = %.2f PLN. %sAKC-4 miesięcznie. OZE = zwolnione. Gospodarstwa domowe = zwolnione.", [energy_mwh, rate_per_mwh, excise_amount, exempt_note])]
    }

    exempt_note := "ZWOLNIONE — OZE " { is_renewable == true }
    exempt_note := "" { is_renewable == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-500: EXCISE PROCEDURES — Skład podatkowy / zawieszenie akcyzy
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.excise_category in {"ALCOHOL", "TOBACCO", "MOTOR_FUEL"}
    requires_warehouse := object.get(input.invoice, "excise_warehouse_required", false)
    requires_warehouse == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    has_warehouse := object.get(input.jdg_entrepreneur, "excise_has_tax_warehouse", false)
    has_security := object.get(input.jdg_entrepreneur, "excise_has_general_security", false)

    proc_ok := has_warehouse == true and has_security == true
    missing_parts := []
    missing_parts := array.concat(missing_parts, ["skład podatkowy"]) { has_warehouse == false }
    missing_parts := array.concat(missing_parts, ["zabezpieczenie akcyzowe"]) { has_security == false }

    excise_routing := "BLOCK_AND_ALERT" { proc_ok == false }
    excise_routing := "" { proc_ok == true }
    excise_routing_reason := sprintf("Brak: %s — produkcja/obrót wyrobami akcyzowymi ZABLOKOWANY!", [concat(", ", missing_parts)]) { proc_ok == false }
    excise_routing_reason := "" { proc_ok == true }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.excise.tax_warehouse_procedure",
        "package": "jdg.local_taxes.excise_enterprise", "priority": 1491,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "", "kus_percent": 0,
        "local_tax_type": "EXCISE", "excise_category": "PROCEDURE",
        "excise_warehouse_required": true,
        "excise_has_tax_warehouse": has_warehouse,
        "excise_has_security": has_security,
        "excise_procedure_status": proc_status,
        "_routing": excise_routing, "_routing_reason": excise_routing_reason,
        "_legal_basis": "Art. 38-48, 63-76 Ustawy o podatku akcyzowym (skład podatkowy, procedura zawieszenia)",
        "_warnings": [sprintf("🏭 SKŁAD PODATKOWY: %s. Zezwolenie akcyzowe + zabezpieczenie generalne + e-DD. Akcyza płatna do 25. dnia miesiąca następującego po wyprowadzeniu ze składu.", [proc_status])]
    }

    proc_status := "✅ KOMPLETNY" { proc_ok == true }
    proc_status := sprintf("❌ BRAK: %s", [concat(", ", missing_parts)]) { proc_ok == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-505: EXCISE EXEMPTIONS — Zwolnienia akcyzowe
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.excise_category in {"MOTOR_FUEL", "HEATING_FUEL", "ENERGY", "ALCOHOL"}
    is_exempt := object.get(input.invoice, "excise_exemption_applies", false)
    is_exempt == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    exemption_code := object.get(input.invoice, "excise_exemption_code", "GEN")
    has_documentation := object.get(input.invoice, "excise_exemption_documented", false)

    exemption_label := "Lotnictwo komercyjne (Art. 32 ust. 1 pkt 1)" { exemption_code == "AVIATION" }
    exemption_label := "Żegluga morska (Art. 32 ust. 1 pkt 2)" { exemption_code == "MARITIME" }
    exemption_label := "Rolnictwo/ogrodnictwo/rybactwo (Art. 32 ust. 1 pkt 3-4)" { exemption_code == "AGRICULTURE" }
    exemption_label := "Cele opałowe gospodarstw domowych (Art. 31b ust. 2)" { exemption_code == "HOUSEHOLD_HEATING" }
    exemption_label := "Energia odnawialna (Art. 30 ust. 8)" { exemption_code == "RENEWABLE" }
    exemption_label := "Alkohol do celów medycznych (Art. 30 ust. 7 pkt 2)" { exemption_code == "MEDICAL" }
    exemption_label := sprintf("Inne zwolnienie: %s", [exemption_code]) { true }

    excise_routing := "TRIAGE_QUEUE" { has_documentation == false }
    excise_routing := "" { has_documentation == true }
    excise_routing_reason := "Zwolnienie akcyzowe bez dokumentacji — ryzyko kontroli!" { has_documentation == false }
    excise_routing_reason := "" { has_documentation == true }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.excise.exemption_verification",
        "package": "jdg.local_taxes.excise_enterprise", "priority": 1492,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "", "kus_percent": 0,
        "local_tax_type": "EXCISE", "excise_category": "EXEMPTION",
        "excise_exemption_applies": true,
        "excise_exemption_code": exemption_code,
        "excise_exemption_documented": has_documentation,
        "excise_exemption_label": exemption_label,
        "_routing": excise_routing, "_routing_reason": excise_routing_reason,
        "_legal_basis": "Art. 30-32, 31b Ustawy o podatku akcyzowym",
        "_warnings": [sprintf("✅ ZWOLNIENIE AKCYZOWE: %s. %sPamiętaj o przechowywaniu dokumentacji przez 5 lat! Kontrole US/UC mogą weryfikować zasadność zwolnienia.", [exemption_label, doc_note])],
        "valid_from": "2009-03-01", "valid_to": null,
    }

    doc_note := "⚠️ BRAK DOKUMENTACJI! " { has_documentation == false }
    doc_note := "Dokumentacja OK. " { has_documentation == true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-510: AKC-4 DECLARATION — Obowiązek złożenia deklaracji miesięcznej
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.jdg_entrepreneur.excise_registered == true
    input.invoice.is_month_end == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    akc4_filed := object.get(input.jdg_entrepreneur, "akc4_filed_this_month", false)
    excise_due_this_month := object.get(input.jdg_entrepreneur, "excise_due_monthly_pln", 0)

    akc4_routing := "BLOCK_AND_ALERT" { akc4_filed == false; excise_due_this_month > 0 }
    akc4_routing := "TRIAGE_QUEUE" { akc4_filed == false; excise_due_this_month == 0 }
    akc4_routing := "" { akc4_filed == true }

    akc4_routing_reason := sprintf("AKC-4 niezłożona! Akcyza należna: %.2f PLN", [excise_due_this_month]) { akc4_filed == false; excise_due_this_month > 0 }
    akc4_routing_reason := "AKC-4 zerowa — złóż dla formalności" { akc4_filed == false; excise_due_this_month == 0 }
    akc4_routing_reason := "" { akc4_filed == true }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.excise.akc4_monthly_declaration",
        "package": "jdg.local_taxes.excise_enterprise", "priority": 1493,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "", "kus_percent": 0,
        "local_tax_type": "EXCISE", "excise_category": "DECLARATION",
        "excise_declaration": "AKC-4", "excise_akc4_filed": akc4_filed,
        "excise_due_this_month_pln": excise_due_this_month,
        "excise_deadline": "25. dnia następnego miesiąca",
        "_routing": akc4_routing, "_routing_reason": akc4_routing_reason,
        "_legal_basis": "Art. 21-24 Ustawy o podatku akcyzowym",
        "_warnings": [sprintf("📋 AKC-4: Deklaracja miesięczna — %s. Akcyza do zapłaty: %.2f PLN. Termin: 25. dnia następnego miesiąca. Opóźnienie = odsetki od zaległości + mandat KKS (do 720 stawek).", [filed_status, excise_due_this_month])]
    }

    filed_status := "✅ ZŁOŻONA" { akc4_filed == true }
    filed_status := "❌ NIEZŁOŻONA — złóż natychmiast!" { akc4_filed == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXC-515: EXCISE BANDEROLES — Obowiązek oznaczenia znakami akcyzy
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.excise_category in {"ALCOHOL", "TOBACCO"}
    requires_banderoles := object.get(input.invoice, "excise_banderoles_required", false)
    requires_banderoles == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    has_banderoles := object.get(input.invoice, "excise_has_banderoles", false)
    banderole_type := object.get(input.invoice, "excise_banderole_type", "LEGALIZACYJNE")

    banderole_routing := "BLOCK_AND_ALERT" { has_banderoles == false }
    banderole_routing := "" { has_banderoles == true }
    banderole_routing_reason := "Brak banderol/znaków akcyzy — obrót ZABLOKOWANY!" { has_banderoles == false }
    banderole_routing_reason := "" { has_banderoles == true }

    band_stat := "✅ OZNACZONE" { has_banderoles == true }
    band_stat := "❌ BRAK BANDEROL — nielegalny obrót!" { has_banderoles == false }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.excise.banderoles_required",
        "package": "jdg.local_taxes.excise_enterprise", "priority": 1494,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "", "kus_percent": 0,
        "local_tax_type": "EXCISE", "excise_category": "BANDEROLES",
        "excise_banderoles_required": true,
        "excise_has_banderoles": has_banderoles,
        "excise_banderole_type": banderole_type,
        "_routing": banderole_routing, "_routing_reason": banderole_routing_reason,
        "_legal_basis": "Art. 114-138 Ustawy o podatku akcyzowym (znaki akcyzy/banderole)",
        "_warnings": [sprintf("🏷️ BANDEROLE AKCYZOWE: %s. Typ: %s. Wyroby alkoholowe >0.5L i tytoniowe MUSZĄ być oznaczone. Brak banderol = konfiskata towaru + kara do 720 stawek KKS!", [band_stat, banderole_type])]
    }
}
