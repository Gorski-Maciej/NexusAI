# ------------------------------------------------------------------------------
# NexusAI JDG — Enterprise PKPiR Complete Validator (Doc 50: UoR Class VIII)
# ------------------------------------------------------------------------------
# ENTERPRISE v5.0 — Full Podatkowa Księga Przychodów i Rozchodów validation
# Legal basis: Rozp. MF z 15.11.2025 (PKPiR), Art. 24a PIT, Art. 22 UoR
# Architecture: Enterprise Multi-Pass, First-Match-Wins else-chain
# ------------------------------------------------------------------------------

package jdg.accounting.pkpir

import future.keywords.in
import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.accounting.pkpir.no_match",
    "package": "jdg.accounting.pkpir", "priority": 899
}

# ------------------------------------------------------------------------------
# K810-K819: PKPiR STRUCTURE — COLUMNS 1-19
# ------------------------------------------------------------------------------

# --- K810: Required columns ---
decide := {
    "matched": true, "rule_id": "jdg.accounting.pkpir.columns_structure",
    "package": "jdg.accounting.pkpir", "priority": 810,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_columns_required": 19,
    "pkpir_mandatory_columns": ["LP","DATA_ZAPISU","NR_DOWODU","KONTRAHENT","OPIS",
        "PRZYCHOD_SPRZEDANE","PRZYCHOD_POZOSTALE","ZAKUP_TOWAROW","KOSZTY_UBOCZNE",
        "WYNAGRODZENIA","POZOSTALE_WYDATKI","RAZEM_KUP","KOSZTY_NIESTANOWIACE_KUP",
        "AMORTYZACJA","SKLADKI_ZUS","PODATEK_NALICZONY_VAT","UWAGI","SALDO_PRZYCHODOW",
        "SALDO_KOSZTOW"],
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§ 10-12 rozporządzenia MF z 15.11.2025 r. w sprawie PKPiR",
    "_warnings": ["PKPiR — 19 kolumn obowiązkowych. Kolumny 10-13: KUP (wynagrodzenia, pozostałe). Kolumna 14: NKUP. Kolumna 15: amortyzacja. Prowadź chronologicznie, bez pustych wierszy."]
} {
    input.jdg_entrepreneur.tax_form in {"PIT_SCALE", "LINEAR"}
    input.jdg_entrepreneur.uses_pkpir == true
}

# --- K811: Revenue column validation (7-8) ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir.revenue_columns_validation",
    "package": "jdg.accounting.pkpir", "priority": 811,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_revenue_column": revenue_column,
    "pkpir_revenue_amount_pln": revenue_amount,
    "pkpir_revenue_date_rule": "CASH_METHOD",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": revenue_routing,
    "_routing_reason": sprintf("Kol. %s PKPiR — %.2f PLN. Metoda kasowa: data = data otrzymania zapłaty.", [revenue_column, revenue_amount]),
    "_legal_basis": "§ 13-14 rozporządzenia MF w sprawie PKPiR, Art. 14 PIT",
    "_warnings": [sprintf("PKPiR KOL.%s — Przychód %.2f PLN. Zasada: (1) Kol.7 = sprzedane towary/usługi, (2) Kol.8 = pozostałe przychody (dotacje, zwroty), (3) Ewidencja KASOWA — data otrzymania zapłaty, nie data faktury!", [revenue_column, revenue_amount])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.direction == "SALE"
    revenue_column := object.get({
        [true, false]: "7"
    }, [input.invoice.category_code in {"GOODS", "SERVICES", "MERCHANDISE"}, input.invoice.category_code in {"GRANTS", "REFUNDS", "OTHER_REVENUE"}], "8")
    revenue_amount := object.get(input.invoice, "amount_net", 0)
    revenue_routing := {true: "BLOCK_AND_ALERT", false: ""}[revenue_amount > object.get(data.thresholds.jdg.automatyzacja_ksiegowosci, "revenue_triage_limit", 100000)]
}

# --- K812: Cost columns validation (9-13) ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir.cost_columns_validation",
    "package": "jdg.accounting.pkpir", "priority": 812,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_cost_column": cost_column,
    "pkpir_cost_amount_pln": cost_amount,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": cost_routing,
    "_routing_reason": sprintf("Kol. %s PKPiR — koszt %.2f PLN (kategoria: %s)", [cost_column, cost_amount, cost_category]),
    "_legal_basis": "§ 15-20 rozporządzenia MF w sprawie PKPiR, Art. 22 PIT",
    "_warnings": [sprintf("PKPiR KOL.%s — KUP %.2f PLN. Kategorie: (1) Kol.10 = zakup towarów handlowych + materiałów podstawowych, (2) Kol.11 = koszty uboczne zakupu, (3) Kol.12 = wynagrodzenia brutto, (4) Kol.13 = pozostałe wydatki (czynsz, media, telefon). Ewidencja: data poniesienia = data faktury.", [cost_column, cost_amount])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.direction == "PURCHASE"
    cost_category := object.get(input.invoice, "category_code", "OTHER")
    cost_category in {"ALCOHOL", "ENTERTAINMENT", "LUXURY", "PERSONAL_EXPENSE", "LEASE", "CAR"} == false
    input.invoice.correction_type == "STORNO" == false
    input.invoice.is_cash_payment == true == false
    cost_column_opts := [
        {"c": cost_category in {"GOODS", "RAW_MATERIALS", "MERCHANDISE"}, "v": "10"},
        {"c": cost_category in {"TRANSPORT_COST", "INSURANCE_COST", "CUSTOMS_DUTY"}, "v": "11"},
        {"c": cost_category in {"SALARY", "WAGES", "BONUS"}, "v": "12"},
        {"c": true, "v": "13"}
    ]
    cost_column := [x.v | some x in cost_column_opts; x.c][0]
    cost_amount := object.get(input.invoice, "amount_net", 0)
    cost_routing := {true: "BLOCK_AND_ALERT", false: ""}[ [cost_amount > object.get(data.thresholds.jdg.automatyzacja_ksiegowosci, "cost_triage_limit", 50000), cost_category in {"GOODS", "RAW_MATERIALS"}] == [true,true] ]
}

# --- K813: NKUP column 14 validation ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir.nkup_column_validation",
    "package": "jdg.accounting.pkpir", "priority": 813,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_nkup_column": 14,
    "pkpir_nkup_reason": nkup_reason,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 23 PIT, § 21 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("PKPiR KOL.14 — NKUP %.2f PLN. Powód: %s. Kolumna 14 = wydatki NIEbędące KUP — NIE wliczaj do kosztów w PIT!", [nkup_amount, nkup_reason])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.direction == "PURCHASE"
    input.invoice.category_code in {"ALCOHOL", "ENTERTAINMENT", "LUXURY", "PERSONAL_EXPENSE", "LEASE", "CAR"}
    is_personal := input.invoice.category_code in {"ALCOHOL", "ENTERTAINMENT", "LUXURY", "PERSONAL_EXPENSE"}
    is_cash_over := [input.invoice.is_cash_payment == true, input.invoice.amount_gross >= object.get(data.thresholds.jdg.pit, "cash_payment_limit", 15000)] == [true, true]
    is_lease_excess := [input.invoice.category_code == "LEASE", object.get(input.invoice, "lease_excess_over_limit", 0) > 0] == [true, true]
    is_car_75 := [input.invoice.category_code == "CAR", object.get(input.invoice, "car_deduction_pct", 100) == 75] == [true, true]
    nkup_reason := object.get({
        [true, false, false, false]: "reprezentacja/wydatki osobiste — Art. 23 ust.1 pkt 23 PIT",
        [false, true, false, false]: "gotówka >15k PLN — Art. 22p PIT",
        [false, false, true, false]: sprintf("leasing powyżej limitu 150k PLN — nadwyżka: %.2f PLN", [nkup_amount]),
        [false, false, false, true]: "samochód osobowy — 75% limitu NKUP"
    }, [is_personal, is_cash_over, is_lease_excess, is_car_75], "art. 23 PIT — wydatek niestanowiący KUP")
    nkup_amount := object.get(input.invoice, "amount_net", 0)
}

# --- K814: Depreciation column 15 ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir.depreciation_column",
    "package": "jdg.accounting.pkpir", "priority": 814,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_depreciation_column": 15,
    "pkpir_depreciation_method": depr_method,
    "pkpir_depreciation_rate_pct": depr_rate,
    "pkpir_depreciation_monthly_pln": monthly_depr,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22a-22o PIT, § 22-26 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("PKPiR KOL.15 — Amortyzacja %.2f PLN/mies. Metoda: %s (stawka %.0f%%). ŚT wartość początkowa: %.2f PLN. Odpisy miesięczne od następnego miesiąca po przyjęciu do użytkowania!", [monthly_depr, depr_method, depr_rate, asset_value])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.category_code == "DEPRECIATION"
    asset_value := object.get(input.invoice, "asset_initial_value", 0)
    depr_rate := object.get(input.invoice, "depreciation_rate_pct", 20)
    depr_method_raw := object.get(input.invoice, "depreciation_method", "LINEAR")
    depr_method := object.get({
        [true, false, false]: "LINIOWA"
    }, [depr_method_raw == "LINEAR", depr_method_raw == "DEGRESSIVE", depr_method_raw == "ONE_TIME"], object.get({
        [false, true, false]: "DEGRESYWNA",
        [false, false, true]: "JEDNORAZOWA"
    }, [depr_method_raw == "LINEAR", depr_method_raw == "DEGRESSIVE", depr_method_raw == "ONE_TIME"], "LINIOWA"))
    monthly_depr := floor(asset_value * depr_rate / 100 / 12 * 100) / 100
}

# --- K815: Salary column 12 ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir.salary_column_validation",
    "package": "jdg.accounting.pkpir", "priority": 815,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_salary_column": 12,
    "pkpir_salary_gross_pln": salary_gross,
    "pkpir_salary_components": salary_components,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22 ust. 1 PIT, § 17 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("PKPiR KOL.12 — Wynagrodzenie brutto %.2f PLN. Składniki: brutto + składki ZUS pracodawcy (emerytalna, rentowa, wypadkowa, FP, FGŚP). Wpis w dacie wypłaty (kasowo!). Nie zapomnij o PIT-4R i ZUS DRA!", [salary_gross])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.category_code in {"SALARY", "WAGES", "BONUS", "SALARY_GROSS"}
    salary_gross := object.get(input.invoice, "amount_gross", 0)
    salary_components := ["Wynagrodzenie netto", "Zaliczka PIT", "ZUS pracownik", "ZUS pracodawca"]
}

# --- K816: Chronology validation ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir.date_order_validation",
    "package": "jdg.accounting.pkpir", "priority": 816,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_date_order_valid": is_chronological,
    "pkpir_last_entry_date": last_date,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": pkpir_routing,
    "_routing_reason": sprintf("PKPiR chronologia: %s. Ostatni zapis: %s.", [order_status, last_date]),
    "_legal_basis": "§ 9 rozporządzenia MF w sprawie PKPiR (chronologia zapisów)",
    "_warnings": [sprintf("PKPiR CHRONOLOGIA — %s. Zapis z datą %s. Wymóg: zapisy chronologicznie, bez pustych wierszy, bez przeróbek. Błędy poprawiaj przez STORNO CZERWONE (nie przekreślaj!).", [order_status, last_date])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    current_date := object.get(input.invoice, "transaction_date", "")
    last_date := object.get(input.jdg_entrepreneur, "pkpir_last_entry_date", "2000-01-01")
    current_date != ""
    is_chronological := current_date >= last_date
    order_status := {true: "OK", false: "BŁĄD — data wcześniejsza niż ostatni zapis!"}[is_chronological]
    pkpir_routing := {true: "", false: "BLOCK_AND_ALERT"}[is_chronological]
}

# --- K817: Correction storno ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir.correction_storno",
    "package": "jdg.accounting.pkpir", "priority": 817,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_correction_type": "STORNO_RED",
    "pkpir_correction_original_entry": original_entry_id,
    "pkpir_correction_amount_pln": correction_amount,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Korekta PKPiR: storno czerwone pozycji %s na kwotę %.2f PLN", [original_entry_id, correction_amount]),
    "_legal_basis": "§ 9 ust. 2 rozporządzenia MF w sprawie PKPiR (korekta przez storno)",
    "_warnings": [sprintf("KOREKTA PKPiR — storno czerwone zapisu nr %s. (1) NOWY wiersz z kwotą ujemną (ze znakiem minus lub kolorem czerwonym), (2) W kol. 17 wyjaśnij przyczynę korekty, (3) NIE przekreślaj ani nie wymazuj oryginalnego zapisu!", [original_entry_id])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.correction_type == "STORNO"
    original_entry_id := object.get(input.invoice, "corrected_entry_id", "")
    original_entry_id != ""
    correction_amount := object.get(input.invoice, "amount_net", 0)
}

# --- K818: Daily sum ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir.daily_integrity_sum",
    "package": "jdg.accounting.pkpir", "priority": 818,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_daily_revenue_sum": daily_revenue,
    "pkpir_daily_cost_sum": daily_cost,
    "pkpir_daily_balance": daily_balance,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§ 27 rozporządzenia MF w sprawie PKPiR (podsumowanie miesięczne i roczne)",
    "_warnings": [sprintf("PKPiR SUMA DZIENNA — Przychody: %.2f PLN | Koszty: %.2f PLN | Bilans: %.2f PLN. Sumuj codziennie na końcu strony. Narastająco miesięcznie.", [daily_revenue, daily_cost, daily_balance])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.end_of_day_summary == true
    daily_revenue := object.get(input.jdg_entrepreneur, "pkpir_daily_revenue", 0)
    daily_cost := object.get(input.jdg_entrepreneur, "pkpir_daily_cost", 0)
    daily_balance := daily_revenue - daily_cost
}

# --- K819: Annual close ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir.annual_close",
    "package": "jdg.accounting.pkpir", "priority": 819,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_annual_close_required": true,
    "pkpir_annual_close_deadline": "JANUARY_31",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Zamknięcie roczne PKPiR — podsumowanie + remanent na 31 grudnia",
    "_legal_basis": "§ 27-29 rozporządzenia MF w sprawie PKPiR, Art. 24 PIT",
    "_warnings": [sprintf("ZAMKNIĘCIE ROCZNE PKPiR — rok %d. Wymagane: (1) Podsumowanie wszystkich kolumn za rok, (2) Spis z natury (remanent) na 31 grudnia — wycena wg ceny zakupu lub niższej rynkowej, (3) Przeniesienie remanentu na 1 stycznia następnego roku, (4) Przechowuj PKPiR przez 5 lat!", [tax_year])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.calendar.month == 12
    input.calendar.day_of_month >= 28
    tax_year := object.get(input.jdg_entrepreneur, "tax_year_as_int", 2026)
}

# ------------------------------------------------------------------------------
# K820-K829: REMANENT (SPIS Z NATURY)
# ------------------------------------------------------------------------------

# --- K820: Annual inventory ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir.inventory_annual",
    "package": "jdg.accounting.pkpir", "priority": 820,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_inventory_required": true,
    "pkpir_inventory_date": "DECEMBER_31",
    "pkpir_inventory_valuation": "LOWER_OF_COST_OR_MARKET",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§ 27-29 rozporządzenia MF w sprawie PKPiR, Art. 24 ust. 2 PIT",
    "_warnings": [sprintf("REMANENT ROCZNY — Spis z natury na 31 grudnia %d. (1) Wycena: NIŻSZA z cen: zakupu lub rynkowej na dzień remanentu, (2) Uwzględnij towary, materiały, produkcję w toku, (3) Remanent końcowy = remanent początkowy następnego roku.", [tax_year])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.calendar.month == 12
    input.calendar.day_of_month >= 31
    input.jdg_entrepreneur.has_inventory == true
    tax_year := object.get(input.jdg_entrepreneur, "tax_year_as_int", 2026)
}

# --- K821: Inventory valuation ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir.inventory_valuation",
    "package": "jdg.accounting.pkpir", "priority": 821,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_inventory_valuation_method": "LOWER_OF",
    "pkpir_inventory_purchase_price": purchase_price,
    "pkpir_inventory_market_price": market_price,
    "pkpir_inventory_valuation_price": valuated_price,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§ 28 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("WYCENA REMANENTU — Cena zakupu: %.2f PLN | Cena rynkowa: %.2f PLN | Wycena: %.2f PLN (niższa z obu). Pamiętaj: (1) Towary uszkodzone/przeterminowane — wycena zerowa, (2) Produkcja w toku — koszt wytworzenia, (3) Nie wyceniaj ŚT i niematerialnych!", [purchase_price, market_price, valuated_price])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.category_code == "INVENTORY_VALUATION"
    purchase_price := object.get(input.invoice, "purchase_price", 0)
    market_price := object.get(input.invoice, "market_price", 0)
    valuated_price := min([purchase_price, market_price])
}

# --- K822: Liquidation inventory ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir.inventory_liquidation",
    "package": "jdg.accounting.pkpir", "priority": 822,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_inventory_liquidation": true,
    "pkpir_liquidation_tax_rate": 0.10,
    "pkpir_liquidation_tax_due": tax_due,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Remanent likwidacyjny — 10%% podatku od nadwyżki %.2f PLN = %.2f PLN", [remnant_surplus, tax_due]),
    "_legal_basis": "Art. 24 ust. 3 i 3a PIT",
    "_warnings": [sprintf("REMANENT LIKWIDACYJNY — Zamknięcie/zbycie JDG. (1) Spisz wszystkie towary i materiały, (2) 10%% zryczałtowany podatek od nadwyżki remanentu nad wartością początkową: %.2f PLN, (3) Zapłać przed likwidacją JDG!", [tax_due])]
} {
    input.jdg_entrepreneur.business_closure_in_progress == true
    input.jdg_entrepreneur.has_inventory == true
    remnant_surplus := object.get(input.jdg_entrepreneur, "remnant_surplus_value", 0)
    remnant_surplus > 0
    tax_due := floor(remnant_surplus * 0.10 * 100) / 100
}

# --- K823: Tax form change inventory ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir.inventory_tax_form_change",
    "package": "jdg.accounting.pkpir", "priority": 823,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_inventory_form_change": true,
    "pkpir_inventory_transfer_value": inventory_value,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Remanent przy zmianie formy: %s → %s", [old_form, new_form]),
    "_legal_basis": "Art. 24 ust. 2 PIT, Art. 44 ust. 2 PIT",
    "_warnings": [sprintf("REMANENT PRZY ZMIANIE FORMY — %s → %s. Wartość remanentu: %.2f PLN. Przenieś remanent końcowy ze starej formy jako remanent początkowy dla nowej formy. Data: 1 stycznia.", [old_form, new_form, inventory_value])]
} {
    input.jdg_entrepreneur.tax_form_changed_this_year == true
    old_form := object.get(input.jdg_entrepreneur, "previous_tax_form", "")
    new_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    old_form != new_form
    input.jdg_entrepreneur.has_inventory == true
    inventory_value := object.get(input.jdg_entrepreneur, "remnant_value_pln", 0)
}

# ------------------------------------------------------------------------------
# K830-K839: VEHICLE MILEAGE LOG
# ------------------------------------------------------------------------------

# --- K830: Mileage log required ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir.vehicle_mileage_log",
    "package": "jdg.accounting.pkpir", "priority": 830,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_mileage_log_required": true,
    "pkpir_mileage_vat_deduction_pct": vat_deduction,
    "pkpir_mileage_kup_deduction_pct": kup_deduction,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": mileage_routing,
    "_routing_reason": sprintf("Kilometrówka — VAT %.0f%% / KUP %.0f%%", [vat_deduction * 100, kup_deduction * 100]),
    "_legal_basis": "Art. 86a VAT, Art. 23 ust. 1 pkt 46 PIT",
    "_warnings": [sprintf("EWIDENCJA PRZEBIEGU POJAZDU — %s. (1) VAT: %d%% odliczenia (%s), (2) KUP: %d%% (%s), (3) Ewidencja musi zawierać: datę, trasę, cel, licznik km, (4) Przechowuj 5 lat.", [log_status, vat_pct, vat_note, kup_pct, kup_note])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.category_code in {"CAR", "VEHICLE", "FUEL", "CAR_SERVICE", "CAR_INSURANCE"}
    has_log := object.get(input.jdg_entrepreneur, "vehicle_mileage_log_maintained", false)
    log_status := {true: "PROWADZONA", false: "BRAK — załóż natychmiast!"}[has_log]
    vat_deduction := {true: 1.0, false: 0.5}[has_log]
    kup_deduction := {true: 1.0, false: 0.75}[has_log]
    vat_pct := floor(vat_deduction * 100)
    kup_pct := floor(kup_deduction * 100)
    vat_note := {true: "100% z ewidencją", false: "50% bez ewidencji"}[has_log]
    kup_note := {true: "100% z ewidencją", false: "75% (limit art. 23 PIT)"}[has_log]
    mileage_routing := {true: "", false: "TRIAGE_QUEUE"}[has_log]
}

# --- K831: Vehicle lease limit ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir.vehicle_lease_limit",
    "package": "jdg.accounting.pkpir", "priority": 831,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_LIMITED", "kus_percent": kup_pct_usable,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_lease_car_value_pln": car_value,
    "pkpir_lease_limit_pln": object.get(data.thresholds.jdg.depreciation, "pkpir_lease_limit_pln", 150000),
    "pkpir_lease_excess_nkup_pln": excess_nkup,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": lease_routing,
    "_routing_reason": sprintf("Leasing auta %.0f PLN — limit 150k. Nadwyżka NKUP: %.0f PLN.", [car_value, excess_nkup]),
    "_legal_basis": "Art. 23 ust. 1 pkt 47a PIT",
    "_warnings": [sprintf("LEASING SAMOCHODU OSOBOWEGO — Wartość auta: %.0f PLN. Limit: %d PLN (elektryczne: 225 000 PLN). Nadwyżka %.0f PLN → NKUP! Rata leasingowa: %d%% KUP (%d%% limitu) + %d%% NKUP. Rzeczywista rata = kwota z faktury leasingowej × %d%%.", [car_value, limit, excess_nkup, kup_portion, 100 - nkup_portion, nkup_portion, kup_portion])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.category_code == "CAR_LEASE"
    car_value := object.get(input.invoice, "car_value_pln", 0)
    car_value > object.get(data.thresholds.jdg.depreciation, "passenger_car_limit_standard", 150000)
    is_electric := object.get(input.invoice, "is_electric_vehicle", false)
    limit := {true: object.get(data.thresholds.jdg.depreciation, "passenger_car_limit_electric", 225000), false: object.get(data.thresholds.jdg.depreciation, "passenger_car_limit_standard", 150000)}[is_electric]
    excess_nkup := car_value - limit
    kup_portion := floor(limit * 100 / car_value)
    nkup_portion := floor(excess_nkup * 100 / car_value)
    kup_pct_usable := kup_portion
    lease_routing := {true: "TRIAGE_QUEUE", false: ""}[excess_nkup > 0]
}

# ------------------------------------------------------------------------------
# K840-K849: VAT REGISTERS
# ------------------------------------------------------------------------------

# --- K840: VAT evidence ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir.vat_evidence_journal",
    "package": "jdg.accounting.pkpir", "priority": 840,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_vat_column": 16,
    "pkpir_vat_deductible": vat_deductible,
    "pkpir_vat_nondeductible": vat_nondeductible,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 109 VAT, § 21 ust. 2 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("EWIDENCJA VAT W PKPiR — Kolumna 16. VAT naliczony odliczalny: %.2f PLN (odlicz w JPK_V7). VAT nieodliczalny: %.2f PLN (wchodzi w KUP). Pamiętaj: przy zwolnieniu z VAT — cały VAT wchodzi w KUP!", [vat_deductible, vat_nondeductible])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.jdg_entrepreneur.is_vat_payer == true
    input.invoice.direction == "PURCHASE"
    input.invoice.has_vat == true
    vat_deductible := object.get(input.invoice, "vat_deductible_amount", 0)
    vat_nondeductible := object.get(input.invoice, "vat_nondeductible_amount", 0)
}

# --- K841: VAT exempt ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir.vat_exempt_no_column_16",
    "package": "jdg.accounting.pkpir", "priority": 841,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_vat_exempt_note": "PODATNIK_ZWOLNIONY_Z_VAT",
    "pkpir_gross_amount_kup": amount_gross,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 113 VAT, § 21 ust. 3 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("PKPiR BEZ VAT — Jesteś zwolniony z VAT. Kwota brutto %.2f PLN jest w całości KUP. Nie wyodrębniaj VAT — cała kwota idzie w kolumnę kosztową (10-13).", [amount_gross])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.jdg_entrepreneur.is_vat_payer == false
    input.invoice.direction == "PURCHASE"
    amount_gross := object.get(input.invoice, "amount_gross", 0)
}

# ------------------------------------------------------------------------------
# K850-K859: ARCHIVING & AUDIT
# ------------------------------------------------------------------------------

# --- K850: Retention 5 years ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir.retention_5years",
    "package": "jdg.accounting.pkpir", "priority": 850,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_retention_years": 5,
    "pkpir_retention_from": retention_start_year,
    "pkpir_retention_until": retention_end_year,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 86 § 1 OrdPU, § 29 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("ARCHIWIZACJA PKPiR — Przechowuj PKPiR + faktury + dowody księgowe przez 5 lat (od końca roku podatkowego). Rok %d: przechowuj do końca %d. Zniszczenie dokumentów = KKS Art. 68!", [retention_start_year, retention_end_year])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    current_year := object.get(input.jdg_entrepreneur, "tax_year_as_int", 2026)
    retention_start_year := current_year
    retention_end_year := current_year + 5
}

# --- K855: KAS audit readiness ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir.kas_audit_readiness",
    "package": "jdg.accounting.pkpir", "priority": 855,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_kas_audit_score": audit_score,
    "pkpir_kas_audit_missing": missing_docs,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": audit_routing,
    "_routing_reason": sprintf("Gotowość na kontrolę KAS: %d/100 — %d brakujących dokumentów", [audit_score, missing_count]),
    "_legal_basis": "Art. 281-292 OrdPU, Art. 56 KKS",
    "_warnings": [sprintf("GOTOWOŚĆ NA KONTROLĘ KAS — Score: %d/100. %s. Sprawdź: (1) Czy wszystkie faktury zaksięgowane w PKPiR, (2) Czy remanent i podsumowania miesięczne zrobione, (3) Czy dokumenty sprzed 5 lat zarchiwizowane, (4) Czy ewidencja VAT zgodna z PKPiR.", [audit_score, audit_msg])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    integrity_score := object.get(input.jdg_entrepreneur, "pkpir_integrity_score", 1.0)
    has_inventory := object.get(input.jdg_entrepreneur, "has_inventory", false)
    inventory_done := object.get(input.jdg_entrepreneur, "inventory_done_current_year", false)
    audit_score := floor(integrity_score * 100)
    missing_docs := []
    has_missing_inv := [has_inventory, inventory_done == false] == [true, true]
    missing_docs := {true: array.concat(missing_docs, ["Brak remanentu rocznego"]), false: missing_docs}[has_missing_inv]
    missing_count := count(missing_docs)
    audit_msg_opts := [
        {"c": [audit_score >= 90, missing_count <= 0] == [true, true], "v": "Wszystko OK"},
        {"c": true, "v": "Uzupełnij braki przed kontrolą!"}
    ]
    audit_msg := [x.v | some x in audit_msg_opts; x.c][0]
    audit_routing := {true: "TRIAGE_QUEUE", false: ""}[audit_score < 80]
}

# ------------------------------------------------------------------------------
# FALLBACK
# ------------------------------------------------------------------------------
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir.fallback_no_match",
    "package": "jdg.accounting.pkpir", "priority": 899,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "rozporządzenia MF w sprawie PKPiR",
    "_warnings": ["[PKPiR] Transakcja nie wymaga specjalnej walidacji PKPiR — księguj standardowo"]
} {
    input.jdg_entrepreneur.uses_pkpir == true
}
