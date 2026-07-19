# ------------------------------------------------------------------------------
# NexusAI JDG — Enterprise Depreciation (Amortyzacja ŚT) Complete (Class B → A)
# Amortyzacja liniowa, degresywna, jednorazowa, stawki KŚT, limity, WNiP
# Legal basis: Art. 22a-22o PIT, Załącznik nr 1 do PIT (stawki KŚT)
# Architecture: Enterprise Multi-Pass, First-Match-Wins else-chain
# ------------------------------------------------------------------------------

package jdg.accounting.depreciation

import future.keywords.in
import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.accounting.depreciation.no_match",
    "package": "jdg.accounting.depreciation", "priority": 9999
}

# ==============================================================================
#   D100-D109: DEFINICJA ŚRODKA TRWAŁEGO (Art. 22a PIT)
# ==============================================================================

# ── D100: fixed_asset_definition — Definicja środka trwałego ──
decide := {
    "matched": true, "rule_id": "jdg.accounting.depreciation.asset_definition",
    "package": "jdg.accounting.depreciation", "priority": 100,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "asset_is_fixed": is_fixed_asset,
    "asset_minimum_value_pln": 10000,
    "asset_expected_life_years": expected_life,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": asset_routing,
    "_routing_reason": sprintf("Środek trwały: %.2f PLN — %s", [asset_value, asset_status]),
    "_legal_basis": "Art. 22a ust. 1 PIT",
    "_warnings": [sprintf("ŚRODEK TRWAŁY — %s. Wartość: %.2f PLN. Warunki ŚT: (1) Własność lub współwłasność podatnika, (2) Kompletny i zdatny do użytku, (3) Przewidywany okres użytkowania > 1 rok, (4) Wartość początkowa ≥ 10 000 PLN. Poniżej 10k PLN → jednorazowo w KUP!", [asset_status, asset_value])]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.category_code in {"FIXED_ASSET", "MACHINERY", "VEHICLE", "COMPUTER_EQUIPMENT", "OFFICE_EQUIPMENT", "REAL_ESTATE"}
    asset_value := object.get(input.invoice, "amount_net", 0)
    expected_life := object.get(input.invoice, "expected_useful_life_years", 5)
    is_fixed_asset := [asset_value >= 10000, expected_life > 1] == [true, true]
    asset_status_opts := [
        {"c": is_fixed_asset == true, "v": sprintf("ŚT — amortyzuj przez %d lat", [expected_life])},
        {"c": asset_value < 10000, "c2": asset_value > 0, "v": "NISKOCENNY — jednorazowo w KUP"}
    ]
    asset_status := [x.v | some x in asset_status_opts; x.c; object.get(x, "c2", true)][0]
    asset_routing := ""
}

# ── D101: low_value_asset_one_time — Niskocenne składniki majątku do 10k ──
else := {
    "matched": true, "rule_id": "jdg.accounting.depreciation.low_value_one_time",
    "package": "jdg.accounting.depreciation", "priority": 101,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "asset_low_value": true,
    "asset_kup_one_time_pln": asset_value,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Niskocenny składnik %.2f PLN — jednorazowo w KUP", [asset_value]),
    "_legal_basis": "Art. 22d ust. 1 PIT",
    "_warnings": [sprintf("NISKOCENNY SKŁADNIK MAJĄTKU — %.2f PLN (< 10 000 PLN). Jednorazowo w KUP w miesiącu oddania do użytkowania. Nie amortyzuj! Nie wpisuj do ewidencji ŚT. Zachowaj fakturę 5 lat.", [asset_value])]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.category_code in {"FIXED_ASSET", "MACHINERY", "COMPUTER_EQUIPMENT", "OFFICE_EQUIPMENT"}
    asset_value := object.get(input.invoice, "amount_net", 0)
    asset_value > 0
    asset_value < 10000
}

# ==============================================================================
#   D200-D209: METODY AMORTYZACJI (Art. 22i-22k PIT)
# ==============================================================================

# ── D200: linear_depreciation — Amortyzacja liniowa ──
else := {
    "matched": true, "rule_id": "jdg.accounting.depreciation.linear",
    "package": "jdg.accounting.depreciation", "priority": 200,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "depreciation_method": "LINEAR",
    "depreciation_rate_pct": annual_rate,
    "depreciation_annual_pln": annual_depr,
    "depreciation_monthly_pln": monthly_depr,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Amortyzacja liniowa: %.1f%% × %.2f PLN = %.2f PLN/rok (%.2f PLN/mies)", [annual_rate, initial_value, annual_depr, monthly_depr]),
    "_legal_basis": "Art. 22i ust. 1 PIT, Załącznik nr 1 (stawki KŚT)",
    "_warnings": [sprintf("AMORTYZACJA LINIOWA — %s. Wartość początkowa: %.2f PLN. Stawka: %.1f%% rocznie = %.2f PLN/rok (%d mies. × %.2f PLN). Rozpocznij od następnego miesiąca po przyjęciu do użytkowania! Ewidencja ŚT obowiązkowa.", [asset_type, initial_value, annual_rate, annual_depr, months, monthly_depr])]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.category_code in {"FIXED_ASSET", "MACHINERY", "VEHICLE", "COMPUTER_EQUIPMENT", "OFFICE_EQUIPMENT", "REAL_ESTATE"}
    initial_value := object.get(input.invoice, "amount_net", 0)
    initial_value >= 10000
    # Stawka KŚT per typ — OPA 0.68 opts pattern
    asset_type_opts := [
        {"c": input.invoice.category_code == "REAL_ESTATE", "c2": input.invoice.subtype == "RESIDENTIAL", "v": "Budynki mieszkalne"},
        {"c": input.invoice.category_code == "REAL_ESTATE", "c2": input.invoice.subtype != "RESIDENTIAL", "v": "Budynki niemieszkalne"},
        {"c": input.invoice.category_code in {"MACHINERY", "COMPUTER_EQUIPMENT", "OFFICE_EQUIPMENT"}, "v": "Maszyny i urządzenia"},
        {"c": input.invoice.category_code == "VEHICLE", "v": "Środki transportu"},
        {"c": input.invoice.category_code == "INTANGIBLE_ASSET", "v": "WNiP"}
    ]
    asset_type := [x.v | some x in asset_type_opts; x.c; object.get(x, "c2", true)][0]
    # Stawki roczne KŚT
    annual_rate_opts := [
        {"c": input.invoice.subtype == "RESIDENTIAL", "v": 1.5},
        {"c": input.invoice.subtype == "NON_RESIDENTIAL", "v": 2.5},
        {"c": input.invoice.category_code == "VEHICLE", "v": 20.0},
        {"c": input.invoice.category_code == "COMPUTER_EQUIPMENT", "v": 30.0},
        {"c": input.invoice.category_code == "OFFICE_EQUIPMENT", "v": 20.0},
        {"c": input.invoice.category_code == "MACHINERY", "v": 14.0},
        {"c": input.invoice.category_code == "INTANGIBLE_ASSET", "v": 20.0},
        {"c": true, "v": 10.0}
    ]
    annual_rate := [x.v | some x in annual_rate_opts; x.c][0]
    months := 12
    annual_depr := floor(initial_value * annual_rate / 100 * 100) / 100
    monthly_depr := floor(annual_depr / 12 * 100) / 100
}

# ── D201: degressive_depreciation — Amortyzacja degresywna (przyspieszona) ──
else := {
    "matched": true, "rule_id": "jdg.accounting.depreciation.degressive",
    "package": "jdg.accounting.depreciation", "priority": 201,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "depreciation_method": "DEGRESSIVE",
    "depreciation_coefficient": coeff,
    "depreciation_annual_rate_pct": effective_rate,
    "depreciation_annual_pln": annual_depr,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Amortyzacja degresywna: %.0f%% (wsp. %.1f × %.1f%%) = %.2f PLN/rok", [effective_rate, coeff, base_rate, annual_depr]),
    "_legal_basis": "Art. 22i ust. 2 PIT",
    "_warnings": [sprintf("AMORTYZACJA DEGRESYWNA — Współczynnik %.1f × stawka podstawowa %.1f%% = %.0f%% efektywna. %.2f PLN w pierwszym roku. Przy przejściu na liniową — od nowej wartości netto. Dotyczy maszyn w warunkach przyspieszonego zużycia.", [coeff, base_rate, effective_rate, annual_depr])]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.depreciation_method == "DEGRESSIVE"
    initial_value := object.get(input.invoice, "amount_net", 0)
    base_rate := object.get(input.invoice, "depreciation_base_rate", 20)
    coeff := object.get(input.invoice, "degressive_coefficient", 2.0)
    coeff <= 2.0
    effective_rate := base_rate * coeff
    annual_depr := floor(initial_value * effective_rate / 100 * 100) / 100
}

# ── D202: one_time_depreciation_100k — Jednorazowa amortyzacja de minimis do 100k ──
else := {
    "matched": true, "rule_id": "jdg.accounting.depreciation.one_time_100k",
    "package": "jdg.accounting.depreciation", "priority": 202,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "depreciation_method": "ONE_TIME_DE_MINIMIS",
    "depreciation_limit_pln": 100000,
    "depreciation_one_time_amount": one_time_amount,
    "depreciation_remaining_value": remaining_value,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Amortyzacja jednorazowa de minimis: %.2f PLN (limit 100k)", [one_time_amount]),
    "_legal_basis": "Art. 22k ust. 7-12 PIT (pomoc de minimis)",
    "_warnings": [sprintf("AMORTYZACJA JEDNORAZOWA DE MINIMIS — %.2f PLN. Warunki: (1) Mały podatnik lub pierwszy rok działalności, (2) Limit 100 000 PLN łącznie w roku (EUR przeliczeniowe), (3) ŚT z grup 3-8 KŚT (oprócz samochodów), (4) Wymagana ewidencja ŚT + zaświadczenie o pomocy de minimis. Nadwyżka ponad 100k: %.2f PLN — amortyzuj normalnie.", [one_time_amount, remaining_value])]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.one_time_depreciation == true
    initial_value := object.get(input.invoice, "amount_net", 0)
    is_small_taxpayer := object.get(input.jdg_entrepreneur, "is_small_taxpayer", false)
    is_first_year := object.get(input.jdg_entrepreneur, "is_first_year", false)
    [is_small_taxpayer, is_first_year] != [false, false]
    one_time_amount := min([initial_value, 100000])
    remaining_value := max([0, initial_value - 100000])
}

# ==============================================================================
#   D300-D309: LIMITY I OGRANICZENIA
# ==============================================================================

# ── D300: car_depreciation_limit — Limit amortyzacji auta 150k/225k ──
else := {
    "matched": true, "rule_id": "jdg.accounting.depreciation.car_limit",
    "package": "jdg.accounting.depreciation", "priority": 300,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_LIMITED", "kus_percent": kup_allowed_pct,
    "zus_social_base_type": "", "zus_health_rate": "",
    "depreciation_car_limit_pln": car_limit,
    "depreciation_car_excess_nkup_pln": excess_nkup,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": car_routing,
    "_routing_reason": sprintf("Amortyzacja auta: limit %.0f PLN, nadwyżka NKUP %.0f PLN", [car_limit, excess_nkup]),
    "_legal_basis": "Art. 23 ust. 1 pkt 4 PIT (limit 150 000 / 225 000 PLN)",
    "_warnings": [sprintf("AMORTYZACJA SAMOCHODU OSOBOWEGO — Wartość: %.0f PLN. Limit: %.0f PLN (%s). Amortyzacja od limitu: %.0f PLN — KUP. Nadwyżka: %.0f PLN — NKUP (amortyzacja nie stanowi KUP). Pamiętaj: limit VAT 50/100%% to ODDZIELNY problem!", [car_value, car_limit, limit_type, depreciable_base, excess_nkup])]
} {
    input.invoice.category_code in {"VEHICLE", "CAR"}
    car_value := object.get(input.invoice, "amount_net", 0)
    is_electric := object.get(input.invoice, "is_electric_vehicle", false)
    is_passenger := object.get(input.invoice, "is_passenger_car", true)
    car_limit_opts := [
        {"c": is_electric == true, "v": 225000},
        {"c": true, "v": 150000}
    ]
    car_limit := [x.v | some x in car_limit_opts; x.c][0]
    limit_type_opts := [
        {"c": is_electric == true, "v": "elektryczny"},
        {"c": is_electric == false, "v": "spalinowy"}
    ]
    limit_type := [x.v | some x in limit_type_opts; x.c][0]
    depreciable_base := min([car_value, car_limit])
    excess_nkup := max([0, car_value - car_limit])
    kup_allowed_pct := floor(depreciable_base / max([car_value, 0.01]) * 100)
    car_routing_opts := [
        {"c": excess_nkup > 0, "v": "TRIAGE_QUEUE"},
        {"c": true, "v": ""}
    ]
    car_routing := [x.v | some x in car_routing_opts; x.c][0]
}

# ── D301: improvement_threshold — Ulepszenie ŚT powyżej 10k ──
else := {
    "matched": true, "rule_id": "jdg.accounting.depreciation.improvement",
    "package": "jdg.accounting.depreciation", "priority": 301,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "IMPROVEMENT", "kus_percent": kup_treatment,
    "zus_social_base_type": "", "zus_health_rate": "",
    "improvement_amount_pln": improvement_amount,
    "improvement_threshold": 10000,
    "improvement_exceeds_threshold": exceeds_threshold,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Ulepszenie ŚT: %.2f PLN — %s", [improvement_amount, improvement_treatment]),
    "_legal_basis": "Art. 22g ust. 17 PIT",
    "_warnings": [sprintf("ULEPSZENIE ŚT — %.2f PLN. Próg: 10 000 PLN rocznie. %s. (1) Ulepszenie >10k PLN: zwiększa wartość początkową ŚT i podstawę amortyzacji, (2) Remont (odtworzenie): KUP bezpośrednio, (3) Ulepszenie ≤10k PLN: KUP jednorazowo. Przechowuj dokumentację techniczną!", [improvement_amount, improvement_treatment])]
} {
    input.invoice.category_code == "ASSET_IMPROVEMENT"
    improvement_amount := object.get(input.invoice, "amount_net", 0)
    exceeds_threshold := improvement_amount >= 10000
    improvement_treatment_opts := [
        {"c": exceeds_threshold == true, "v": "ZWIĘKSZA WARTOŚĆ POCZĄTKOWĄ ŚT — amortyzuj"},
        {"c": exceeds_threshold == false, "v": "KUP JEDNORAZOWO — próg 10k nie przekroczony"}
    ]
    improvement_treatment := [x.v | some x in improvement_treatment_opts; x.c][0]
    kup_treatment_opts := [
        {"c": exceeds_threshold == true, "v": 0},
        {"c": exceeds_threshold == false, "v": 100}
    ]
    kup_treatment := [x.v | some x in kup_treatment_opts; x.c][0]
}

# ==============================================================================
#   D400-D409: WARTOŚCI NIEMATERIALNE I PRAWNE (WNiP)
# ==============================================================================

# ── D400: intangible_asset_depreciation — Amortyzacja WNiP ──
else := {
    "matched": true, "rule_id": "jdg.accounting.depreciation.intangible",
    "package": "jdg.accounting.depreciation", "priority": 400,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "intangible_type": wnip_type,
    "intangible_amortization_years": amort_years,
    "intangible_annual_pln": annual_depr,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("WNiP: %s — %.2f PLN/rok przez %d lat", [wnip_type, annual_depr, amort_years]),
    "_legal_basis": "Art. 22b, 22m PIT",
    "_warnings": [sprintf("WARTOŚCI NIEMATERIALNE I PRAWNE — %s. Wartość: %.2f PLN. Amortyzacja: %d lat (min. 5 lat dla WNiP >10k PLN). Stawka: %.1f%% rocznie = %.2f PLN/rok. Ewidencja WNiP osobno od ŚT!", [wnip_type, wnip_value, amort_years, annual_rate, annual_depr])]
} {
    input.invoice.category_code == "INTANGIBLE_ASSET"
    wnip_value := object.get(input.invoice, "amount_net", 0)
    wnip_type_opts := [
        {"c": input.invoice.subtype == "SOFTWARE_LICENSE", "v": "Licencja / oprogramowanie"},
        {"c": input.invoice.subtype == "PATENT", "v": "Patent / znak towarowy"},
        {"c": input.invoice.subtype == "COPYRIGHT", "v": "Prawa autorskie"},
        {"c": input.invoice.subtype == "RND", "v": "Koszty prac rozwojowych"},
        {"c": input.invoice.subtype == "GOODWILL", "v": "Wartość firmy"}
    ]
    wnip_type := [x.v | some x in wnip_type_opts; x.c][0]
    # Minimalny okres amortyzacji
    amort_years_opts := [
        {"c": input.invoice.subtype == "GOODWILL", "v": 60},
        {"c": input.invoice.subtype in {"SOFTWARE_LICENSE", "PATENT", "COPYRIGHT"}, "v": 24},
        {"c": input.invoice.subtype == "RND", "v": 12},
        {"c": true, "v": 60}
    ]
    amort_years := [x.v | some x in amort_years_opts; x.c][0]
    annual_rate := floor(100 / amort_years * 10) / 10
    annual_depr := floor(wnip_value * annual_rate / 100 * 100) / 100
}

# ==============================================================================
#   D500-D509: EWIDENCJA ŚRODKÓW TRWAŁYCH
# ==============================================================================

# ── D500: asset_register_required — Obowiązek prowadzenia ewidencji ŚT ──
else := {
    "matched": true, "rule_id": "jdg.accounting.depreciation.register_required",
    "package": "jdg.accounting.depreciation", "priority": 500,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "asset_register_required": true,
    "asset_register_elements": ["NUMER_EWIDENCYJNY", "DATA_PRZYJECIA", "NAZWA_SRODKA",
        "WARTOSC_POCZATKOWA", "STAWKA_AMORTYZACJI", "ODPISY_ROCZNE",
        "DATA_LIKWIDACJI", "PRZYCZYNA_LIKWIDACJI"],
    "business_status": "", "ceidg_registration_required": false,
    "_routing": register_routing,
    "_routing_reason": "Ewidencja ŚT — obowiązkowa dla amortyzowanych środków trwałych",
    "_legal_basis": "Art. 22n PIT",
    "_warnings": [sprintf("EWIDENCJA ŚRODKÓW TRWAŁYCH — Obowiązkowa! %s. (1) Prowadź dla każdego ŚT osobno, (2) Obejmuje: nr, datę przyjęcia, nazwę, wartość początkową, stawkę, odpisy, (3) Aktualizuj przy ulepszeniach >10k PLN, (4) Przechowuj 5 lat od likwidacji ŚT.", [register_status])]
} {
    input.jdg_entrepreneur.has_fixed_assets == true
    register_exists := object.get(input.jdg_entrepreneur, "asset_register_exists", false)
    register_status_opts := [
        {"c": register_exists == true, "v": "OK — prowadzona"},
        {"c": register_exists == false, "v": "BRAK — załóż natychmiast!"}
    ]
    register_status := [x.v | some x in register_status_opts; x.c][0]
    register_routing_opts := [
        {"c": register_exists == false, "v": "BLOCK_AND_ALERT"},
        {"c": true, "v": ""}
    ]
    register_routing := [x.v | some x in register_routing_opts; x.c][0]
}

# ── D501: asset_sale_income_tax — Sprzedaż ŚT — przychód/koszt ──
else := {
    "matched": true, "rule_id": "jdg.accounting.depreciation.asset_sale",
    "package": "jdg.accounting.depreciation", "priority": 501,
    "vat_rate": "0.23", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "ASSET_SALE", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "asset_sale_revenue_pln": sale_price,
    "asset_book_value_pln": book_value,
    "asset_sale_gain_pln": gain,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Sprzedaż ŚT: przychód %.2f PLN, wartość księgowa %.2f PLN, zysk/strata: %.2f PLN", [sale_price, book_value, gain]),
    "_legal_basis": "Art. 14 ust. 2 pkt 1 PIT, Art. 23 ust. 1 pkt 1 PIT",
    "_warnings": [sprintf("SPRZEDAŻ ŚRODKA TRWAŁEGO — %.2f PLN. (1) Przychód = cena sprzedaży netto (kol. 7-8 PKPiR), (2) Koszt = niezamortyzowana wartość (KUP), (3) VAT: 23%% jeśli ŚT był używany w działalności, (4) Zysk/strata: przychód - wartość księgowa. Przychód podlega PIT + składce zdrowotnej!", [sale_price])]
} {
    input.invoice.direction == "SALE"
    input.invoice.category_code in {"FIXED_ASSET_SALE", "VEHICLE_SALE", "MACHINERY_SALE"}
    sale_price := object.get(input.invoice, "amount_net", 0)
    book_value := object.get(input.invoice, "asset_book_value", 0)
    gain := sale_price - book_value
}

# ==============================================================================
# FALLBACK
# ==============================================================================
else := {
    "matched": true, "rule_id": "jdg.accounting.depreciation.fallback",
    "package": "jdg.accounting.depreciation", "priority": 999,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22a-22o PIT",
    "_warnings": ["Transakcja nie wymaga amortyzacji — księguj standardowo jako KUP jednorazowe."]
} {
    true
}
