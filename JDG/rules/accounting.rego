# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Accounting: PKPiR, amortyzacja, leasing (P800-P870)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: Accounting Package — PKPiR Columns, Depreciation, Leasing, Mixed-Use
# description: |
#   PAS 7 Multi-Pass. First-Match-Wins else-chain. Obsługuje księgowość JDG:
#   mapowanie na kolumny PKPiR (P800-P802), amortyzację liniową (P840) i
#   jednorazową dla małych podatników (P842), wydatki mieszane: home office
#   proporcjonalnie (P850), samochód 75%/50% bez ewidencji (P852), leasing
#   operacyjny (P860), różnice kursowe (P870).
# architecture: Multi-Pass PAS 7 (ADR-001)
# legal_basis: Rozp. MF PKPiR, Art. 22a-22o PIT, Art. 86a VAT
# edge_cases:
#   - P842: tylko dla małych podatników + kwota ≤ 100k PLN
#   - P850: home_office_area_percent musi być > 0
#   - P852: private_use_percent > 0 AND has_mileage_log = false → 75% KUP/50% VAT
# package: jdg.accounting
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.accounting
import data.jdg.helpers
default decide := {"matched":true,"rule_id":"jdg.accounting.no_match","package":"jdg.accounting","priority":899,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","ceidg_registration_required":false,"_routing":"","_routing_reason":"","_legal_basis":"N/A — no accounting rule matched","_warnings":["Brak dopasowania reguły księgowej — transakcja nie wymaga specjalnego traktowania PKPiR/KŚT/UoR"]}

pkpir_map := {
    "GOODS_REVENUE":10, "OTHER_REVENUE":11, "GOODS_PURCHASE":12,
    "ANCILLARY_COSTS":13, "SALARIES":14, "OTHER_EXPENSES":15,
    "NON_KUP":16, "FIXED_ASSET":17, "ZUS_SOCIAL_ENTREPRENEUR":15,
    "ZUS_HEALTH_ENTREPRENEUR":16, "RENT":15, "UTILITIES":15,
    "OFFICE_SUPPLIES":15, "SOFTWARE":15, "ACCOUNTING_SERVICES":15,
    "LEGAL_SERVICES":15, "MARKETING":15, "ADVERTISING":15,
    "CONSULTING":15, "TRAINING":15, "TELECOMMUNICATIONS":15,
    "TRANSPORT_GOODS":15, "MAINTENANCE":15, "SECURITY":15
}

# ══════ P800: pkpir_column_mapping — Mapowanie wydatku na kolumnę PKPiR ══════
decide := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_column_mapping",
    "package":"jdg.accounting","priority":800,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,"pkpir_column":col_num,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Rozporządzenie MF w sprawie PKPiR",
    "_warnings":[]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    expense_type := object.get(input.invoice,"expense_type","OTHER_EXPENSES")
    col_num := object.get(pkpir_map,expense_type,15)
}

# ══════ P801: pkpir_revenue_recognition — Moment rozpoznania przychodu ══════
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_revenue_recognition",
    "package":"jdg.accounting","priority":801,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,"pkpir_revenue_date":revenue_date,"pkpir_column":10,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 20-21 rozporządzenia PKPiR",
    "_warnings":[]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.direction == "SALE"
    revenue_date := object.get(input.invoice,"issue_date","")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P811-P818: PKPiR Column-by-Column Validation (Sprint 2)
# ═══════════════════════════════════════════════════════════════════════════════

# P811: pkpir_col1_sequential — Kolumna 1: liczba porządkowa ciągła
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_col1_sequential",
    "package":"jdg.accounting","priority":811,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "pkpir_validation_error":"COL1_NOT_SEQUENTIAL",
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Kolumna 1 PKPiR — brak ciągłości numeracji",
    "_legal_basis":"§ 10 ust. 1 rozporządzenia PKPiR",
    "_warnings":[sprintf("Kolumna 1 PKPiR: luka w numeracji — oczekiwano %d, otrzymano %d", [expected_lp, actual_lp])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    expected_lp := object.get(input.invoice,"pkpir_expected_lp",0)
    actual_lp := object.get(input.invoice,"pkpir_lp",0)
    actual_lp != expected_lp + 1
    expected_lp > 0
}

# P812: pkpir_col2_date_validation — Kolumna 2: format daty i chronologia
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_col2_date_validation",
    "package":"jdg.accounting","priority":812,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "pkpir_validation_error":"COL2_DATE_INVALID",
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Kolumna 2 PKPiR — niepoprawna data",
    "_legal_basis":"§ 10 ust. 1 pkt 2 rozporządzenia PKPiR",
    "_warnings":["Kolumna 2 PKPiR: data zdarzenia gospodarczego nie może być późniejsza niż data bieżąca"]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.transaction_date > input.invoice.current_date
}

# P813: pkpir_col6_7_kup_validation — Kolumny 6/7: KUP bezpośrednie/pośrednie
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_col6_7_kup_validation",
    "package":"jdg.accounting","priority":813,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "pkpir_validation_error":"COL6_7_KUP_MISMATCH",
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Kolumny 6/7 PKPiR — niespójność KUP",
    "_legal_basis":"§ 10 ust. 1 pkt 6-7, Art. 22 PIT",
    "_warnings":["Kolumny 6/7 PKPiR: wydatek zaklasyfikowany jako KUP pośredni mimo że dotyczy przychodów bieżących"]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    kup_type := object.get(input.invoice,"kus_qualification","")
    # KUP bezpośredni (kol. 6) tylko dla wydatków ściśle związanych z konkretnym przychodem
    kup_type == "direct"
    input.invoice.expense_type in {"GOODS_PURCHASE","MATERIALS"}
}

# P814: pkpir_col8_goods_purchase — Kolumna 8: zakup towarów i materiałów
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_col8_goods_purchase",
    "package":"jdg.accounting","priority":814,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "pkpir_column":8,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 10 ust. 1 pkt 8 rozporządzenia PKPiR",
    "_warnings":["Kol. 8 PKPiR: zakup towarów i materiałów — ujęto w kolumnie zakupów"]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.expense_type in {"GOODS_PURCHASE","MATERIALS","RAW_MATERIALS"}
    input.invoice.direction == "PURCHASE"
}

# P815: pkpir_col14_notes_mandatory — Kolumna 14: uwagi OBOWIĄZKOWE od 2025
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_col14_notes_mandatory",
    "package":"jdg.accounting","priority":815,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "pkpir_validation_error":"COL14_NOTES_MISSING",
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Kolumna 14 PKPiR — brak wymaganych uwag",
    "_legal_basis":"§ 10 ust. 1 pkt 14 rozporządzenia PKPiR (od 2025)",
    "_warnings":["Kol. 14 PKPiR: OBOWIĄZKOWE uwagi od 2025 — wpisz opis nietypowej transakcji"]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.transaction_date >= "2025-01-01"
    input.invoice.expense_type in {"NON_KUP","PRIVATE_MIXED","FIXED_ASSET"}
    input.invoice.pkpir_col14_notes == ""
}

# P816: pkpir_remnant_midyear_check — Remanent: kontrola śródroczna (TRIAGE)
# R0472 obsługuje walidację na początek roku (BLOCK_AND_ALERT).
# P816 ostrzega o niezgodnościach śródrocznych mniej krytycznie.
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_remnant_midyear_check",
    "package":"jdg.accounting","priority":816,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "remnant_discrepancy":remnant_diff,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Remanent śródroczny — rozbieżność wymaga wyjaśnienia",
    "_legal_basis":"§ 27-29 rozporządzenia PKPiR",
    "_warnings":[sprintf("REMANENT ŚRÓDROCZNY: pocz. %.2f PLN ≠ końc. poprzedniego okresu %.2f PLN (różnica %.2f PLN). Wyjaśnij rozbieżność.", [remnant_start, remnant_prev_end, remnant_diff])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    # P816 uruchamia się tylko dla kontroli śródrocznych (NIE na początek roku — to R0472)
    input.invoice.is_year_start == false
    remnant_start := object.get(input.invoice,"remnant_start_value",0)
    remnant_prev_end := object.get(input.invoice,"remnant_previous_end_value",0)
    remnant_prev_end > 0
    remnant_start != remnant_prev_end
    remnant_diff = remnant_start - remnant_prev_end
}

# P817: pkpir_retention_5years — Przechowywanie PKPiR 5 lat (tylko przy archiwizacji)
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_retention_5years",
    "package":"jdg.accounting","priority":817,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "retention_required_years":5,"retention_deadline":retention_deadline,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 86 § 1 OrdPU, art. 74 UoR",
    "_warnings":[sprintf("ARCHIWIZACJA PKPiR za %s — termin przechowywania upływa %s. Nie niszcz przed tym terminem!", [tax_year, retention_deadline])]
} {
    # P817 uruchamia się TYLKO przy zdarzeniu archiwizacji, nie przy każdej transakcji
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.is_archive_event == true
    tax_year := object.get(input.invoice,"tax_year","")
    tax_year != ""
    retention_deadline := sprintf("%s-12-31", [sprintf("%d", [to_number(tax_year) + 5])])
}

# P818: pkpir_income_calculation — Obliczanie dochodu z kolumn
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_income_calculation",
    "package":"jdg.accounting","priority":818,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "pkpir_income_calculated":income,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 24 PIT, § 20-21 rozporządzenia PKPiR",
    "_warnings":[]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    is_period_end := object.get(input.invoice,"is_period_end",false)
    is_period_end == true
    col10 := object.get(input.invoice,"pkpir_col10_total",0)  # przychód
    col11 := object.get(input.invoice,"pkpir_col11_total",0)  # zakupy
    col12 := object.get(input.invoice,"pkpir_col12_total",0)  # koszty uboczne
    col13 := object.get(input.invoice,"pkpir_col13_total",0)  # wynagrodzenia
    col14 := object.get(input.invoice,"pkpir_col14_total",0)  # pozostałe
    remnant_start := object.get(input.invoice,"remnant_start_value",0)
    remnant_end := object.get(input.invoice,"remnant_end_value",0)
    total_costs = col11 + col12 + col13 + col14
    income = col10 - total_costs - remnant_start + remnant_end
}

# ══════ P802: pkpir_expense_recognition — Moment ujęcia kosztu ══════
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_expense_recognition",
    "package":"jdg.accounting","priority":802,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,"pkpir_expense_date":expense_date,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 20 rozporządzenia PKPiR",
    "_warnings":[]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.direction == "PURCHASE"
    expense_date := object.get(input.invoice,"issue_date","")
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P819-P829 — PKPiR KOLUMNY 10-19 — SZCZEGÓŁOWE WALIDACJE               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P819: pkpir_col10_revenue_validation — Kolumna 10: przychód ze sprzedaży
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_col10_revenue",
    "package":"jdg.accounting","priority":819,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","pkpir_column":10,
    "pkpir_validation_error":"COL10_REVENUE_MISMATCH",
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Kol. 10 PKPiR — niespójność przychodu",
    "_legal_basis":"§ 10 ust. 1 pkt 10 rozporządzenia PKPiR",
    "_warnings":["Kol. 10 PKPiR: przychód ze sprzedaży — ujmij tylko przychody z działalności JDG. Nie uwzględniaj: najmu prywatnego, sprzedaży majątku osobistego, odsetek bankowych."]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.pkpi_col10_entry > 0
    input.invoice.transaction_type in {"PRIVATE_RENTAL","PERSONAL_ASSET_SALE","BANK_INTEREST"}
}

# P820: pkpir_col11_other_revenue — Kolumna 11: pozostałe przychody
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_col11_other_revenue",
    "package":"jdg.accounting","priority":820,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","pkpir_column":11,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 10 ust. 1 pkt 11 rozporządzenia PKPiR",
    "_warnings":[sprintf("Kol. 11 PKPiR: pozostałe przychody — %.2f PLN. Obejmuje: dotacje, refundacje, odszkodowania związane z działalnością, różnice kursowe dodatnie.",[col11_value])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    col11_value := object.get(input.invoice,"pkpir_col11_total",0)
    col11_value > 0
}

# P821: pkpir_col12_purchase_cost — Kolumna 12: koszt zakupu towarów
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_col12_purchase_cost",
    "package":"jdg.accounting","priority":821,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","pkpir_column":12,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 10 ust. 1 pkt 12 rozporządzenia PKPiR",
    "_warnings":["Kol. 12 PKPiR: koszt zakupu towarów i materiałów wg cen nabycia. NIE obejmuje: środków trwałych (>10k PLN), wyposażenia, kosztów ubocznych zakupu."]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.expense_type in {"GOODS_PURCHASE","MATERIALS","RAW_MATERIALS"}
    input.invoice.direction == "PURCHASE"
    input.invoice.amount_net > 10000
    object.get(input.invoice,"is_fixed_asset",false) == true
}

# P822: pkpir_col13_ancillary_costs — Kolumna 13: koszty uboczne zakupu
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_col13_ancillary",
    "package":"jdg.accounting","priority":822,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","pkpir_column":13,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 10 ust. 1 pkt 13 rozporządzenia PKPiR",
    "_warnings":["Kol. 13 PKPiR: koszty uboczne zakupu — transport, załadunek, ubezpieczenie w drodze, cło, opakowania. Te koszty ZWIĘKSZAJĄ wartość towaru w kol. 12."]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.expense_type in {"TRANSPORT_IN","INSURANCE_TRANSIT","CUSTOMS_DUTY","PACKAGING"}
}

# P823: pkpir_col14_wages — Kolumna 14: wynagrodzenia brutto
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_col14_wages",
    "package":"jdg.accounting","priority":823,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","pkpir_column":14,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 10 ust. 1 pkt 14 rozporządzenia PKPiR",
    "_warnings":["Kol. 14 PKPiR: wynagrodzenia BRUTTO + składki ZUS pracodawcy. NIE obejmuje: wynagrodzenia własnego JDG (to NIE jest KUP), umów o dzieło z własną firmą."]
} {
    input.employment.has_employees == true
    input.invoice.expense_type == "SALARIES"
    input.invoice.is_own_wage == true
}

# P824: pkpir_col15_other_expenses — Kolumna 15: pozostałe wydatki
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_col15_other_expenses",
    "package":"jdg.accounting","priority":824,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","pkpir_column":15,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 10 ust. 1 pkt 15 rozporządzenia PKPiR",
    "_warnings":[sprintf("Kol. 15 PKPiR: pozostałe wydatki — %.2f PLN. Kategoria: %s. Uwzględniaj TYLKO wydatki firmowe. Dokumentuj każdy wydatek!",[expense_amount,expense_cat])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.expense_type in {"RENT","UTILITIES","OFFICE_SUPPLIES","SOFTWARE","TELECOMMUNICATIONS","MARKETING","LEGAL_SERVICES","ACCOUNTING_SERVICES","CONSULTING","TRAINING"}
    expense_amount := object.get(input.invoice,"amount_net",0)
    expense_cat := object.get(input.invoice,"expense_type","")
    expense_amount > 0
}

# P825: pkpir_col16_non_kup — Kolumna 16: wydatki niestanowiące KUP
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_col16_non_kup",
    "package":"jdg.accounting","priority":825,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"NKUP","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","pkpir_column":16,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Kol. 16 PKPiR — wydatek NKUP",
    "_legal_basis":"Art. 23 PIT",
    "_warnings":[sprintf("Kol. 16 PKPiR: WYDATEK NKUP — %.2f PLN (%s). Nie obniża dochodu do opodatkowania. Przykłady NKUP: reprezentacja, kary umowne, odsetki budżetowe, darowizny, składki ZUS właściciela.",[nkup_amount,nkup_reason])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.kus_qualification == "NKUP"
    nkup_amount := object.get(input.invoice,"amount_net",0)
    nkup_reason := object.get(input.invoice,"nkup_reason","reprezentacja")
    nkup_amount > 0
}

# P826: pkpir_col17_fixed_asset — Kolumna 17: środki trwałe
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_col17_fixed_asset",
    "package":"jdg.accounting","priority":826,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","pkpir_column":17,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 10 ust. 1 pkt 16 rozporządzenia PKPiR (kolumna 17 to ewidencja ŚT)",
    "_warnings":[sprintf("Kol. 17 PKPiR / Ewidencja ŚT: %.2f PLN — amortyzacja za %s. Ujęta w kosztach pośrednio poprzez odpis amortyzacyjny. Prowadź ewidencję ŚT osobno!",[depreciation_amount,period])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.expense_type == "FIXED_ASSET"
    input.invoice.is_depreciation_entry == true
    depreciation_amount := object.get(input.invoice,"depreciation_amount",0)
    period := object.get(input.invoice,"tax_period","")
    depreciation_amount > 0
}

# P827: pkpir_remnant_columns — Remanent w kolumnach PKPiR
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_remnant_columns",
    "package":"jdg.accounting","priority":827,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","pkpir_remnant_start":remnant_start,"pkpir_remnant_end":remnant_end,
    "pkpir_remnant_impact":remnant_end - remnant_start,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 27 rozporządzenia PKPiR",
    "_warnings":[sprintf("REMANENT PKPiR: pocz. %.2f PLN, końc. %.2f PLN. Wpływ na dochód: %.2f PLN. Remanent końcowy WIĘKSZY od początkowego → ZWIĘKSZA dochód.",[remnant_start,remnant_end,remnant_end-remnant_start])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.is_period_end == true
    remnant_start := object.get(input.invoice,"remnant_start_value",0)
    remnant_end := object.get(input.invoice,"remnant_end_value",0)
    remnant_end > 0
}

# P828: pkpir_col19_remarks — Kolumna 19: uwagi dotyczące nietypowych transakcji
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_col19_remarks",
    "package":"jdg.accounting","priority":828,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","pkpir_column":19,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 10 ust. 1 pkt 17 rozporządzenia PKPiR",
    "_warnings":["Kol. 19 PKPiR: UWAGI — opisz nietypowe transakcje: sprzedaż eksportowa, odwrotne obciążenie, korekty storna, transakcje walutowe, transakcje z podmiotami powiązanymi."]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    has_notes := object.get(input.invoice,"pkpir_has_unusual_transaction",false)
    has_notes == true
    notes_empty := object.get(input.invoice,"pkpir_col19_notes","")
    notes_empty == ""
}

# P829: pkpir_cross_column_consistency — Spójność międzykolumnowa PKPiR
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_cross_column_consistency",
    "package":"jdg.accounting","priority":829,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "pkpir_cross_check":"COL10+11 ≠ COL12+13+14+15",
    "_routing":"TRIAGE_QUEUE","_routing_reason":"PKPiR — niespójność suma przychodów ≠ suma kosztów + remanent",
    "_legal_basis":"§ 10-21 rozporządzenia PKPiR, Art. 24 PIT",
    "_warnings":[sprintf("SPÓJNOŚĆ PKPiR: przychody (kol.10+11)=%.2f PLN, koszty (kol.12+13+14+15)=%.2f PLN, remanent Δ=%.2f PLN. Dochód=%.2f PLN. Sprawdź czy remanent poprawnie ujęty.",[total_revenue,total_costs,remnant_delta,total_revenue-total_costs+remnant_delta])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.is_period_end == true
    col10 := object.get(input.invoice,"pkpir_col10_total",0)
    col11 := object.get(input.invoice,"pkpir_col11_total",0)
    col12 := object.get(input.invoice,"pkpir_col12_total",0)
    col13 := object.get(input.invoice,"pkpir_col13_total",0)
    col14 := object.get(input.invoice,"pkpir_col14_total",0)
    col15 := object.get(input.invoice,"pkpir_col15_total",0)
    total_revenue = col10 + col11
    total_costs = col12 + col13 + col14 + col15
    rem_start := object.get(input.invoice,"remnant_start_value",0)
    rem_end := object.get(input.invoice,"remnant_end_value",0)
    remnant_delta = rem_end - rem_start
}

# ══════ P840: depreciation_linear_jdg — Amortyzacja liniowa (rozszerzona KŚT) ══════
# Pełna tabela KŚT 881 grup (Rozporządzenie RM z 30.12.1999).
# Stawki amortyzacyjne dla najważniejszych środków trwałych.
else := {
    "matched":true,"rule_id":"jdg.accounting.depreciation_linear",
    "package":"jdg.accounting","priority":840,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,"pkpir_column":17,
    "depreciation_method":"LINEAR","depreciation_rate":depreciation_rate,
    "kst_group":kst_group,"kst_subgroup":kst_subgroup,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22a-22o PIT, Rozporządzenie RM KŚT",
    "_warnings":[sprintf("Amortyzacja liniowa — KŚT grupa %d, stawka %.1f%%", [kst_group, depreciation_rate * 100])]
} {
    input.invoice.expense_type == "FIXED_ASSET"
    kst_group := object.get(input.invoice,"kst_group",0)
    kst_subgroup := object.get(input.invoice,"kst_subgroup",0)

    # Rozszerzona tabela KŚT — 10 grup głównych + najważniejsze podgrupy
    # Grupa 0: Grunty (NIE amortyzuje się — wyjątek: prawo wieczystego użytkowania)
    # Grupa 1: Budynki i lokale (2.5% rocznie, 40 lat)
    # Grupa 2: Budowle i obiekty inżynierii (2.5%-4.5%)
    # Grupa 3: Kotły i maszyny energetyczne (7%)
    # Grupa 4: Maszyny i urządzenia ogólnego zastosowania (10-30%)
    # Grupa 5: Maszyny specjalne branżowe (14-20%)
    # Grupa 6: Urządzenia techniczne (10-20%)
    # Grupa 7: Środki transportu (14-20%)
    # Grupa 8: Narzędzia i wyposażenie (20%)
    # Grupa 9: Inwentarz żywy (10-20%)
    # Grupa 10: WNiP — wartości niematerialne i prawne

    # Szczegółowe stawki per grupa + podgrupa (najczęściej używane w JDG)
    depreciation_rates := {
        "0_0":0.00,   # Grunty — bez amortyzacji
        "1_1":0.025,  # Budynki mieszkalne (ZAKAZ amortyzacji — P847)
        "1_2":0.025,  # Budynki niemieszkalne (biura, magazyny)
        "1_3":0.025,  # Lokale mieszkalne
        "1_4":0.025,  # Lokale użytkowe
        "2_1":0.045,  # Budowle przemysłowe
        "2_2":0.025,  # Budowle pozostałe
        "3_1":0.07,   # Kotły i maszyny energetyczne
        "4_1":0.14,   # Maszyny ogólne — obróbka metali
        "4_2":0.18,   # Maszyny ogólne — obróbka drewna
        "4_3":0.20,   # Maszyny ogólne — pakowanie
        "4_4":0.10,   # Urządzenia biurowe
        "4_5":0.30,   # Komputery i serwery
        "4_6":0.20,   # Sprzęt telekomunikacyjny
        "4_7":0.30,   # Oprogramowanie (licencje wieczyste)
        "5_1":0.14,   # Maszyny specjalne — budowlane
        "5_2":0.20,   # Maszyny specjalne — rolnicze
        "6_1":0.10,   # Urządzenia techniczne — kotły grzewcze
        "6_2":0.20,   # Urządzenia techniczne — klimatyzacja
        "7_1":0.20,   # Samochody osobowe (limit 150k/225k EV)
        "7_2":0.14,   # Samochody ciężarowe
        "7_3":0.20,   # Motocykle, skutery
        "7_4":0.14,   # Przyczepy i naczepy
        "8_1":0.20,   # Narzędzia i przyrządy
        "8_2":0.20,   # Wyposażenie biurowe (meble)
        "10_1":0.20,  # WNiP — programy komputerowe
        "10_2":0.20,  # WNiP — patenty, licencje
        "10_3":0.10,  # WNiP — know-how
    }

    key := sprintf("%d_%d", [kst_group, kst_subgroup])
    depreciation_rate := object.get(depreciation_rates,key,0.20)
}

# ══════ P842: depreciation_one_off_jdg — Jednorazowa amortyzacja dla małych podatników ══════
else := {
    "matched":true,"rule_id":"jdg.accounting.depreciation_one_off",
    "package":"jdg.accounting","priority":842,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,"pkpir_column":17,
    "depreciation_method":"ONE_OFF","depreciation_rate":"1.00",
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22k ust. 7 PIT",
    "_warnings":["Jednorazowa amortyzacja — limit 50 000 EUR rocznie dla małych podatników"]
} {
    input.jdg_entrepreneur.is_small_taxpayer == true
    input.invoice.expense_type == "FIXED_ASSET"
    input.invoice.amount_net <= 100000
}

# ══════ P850: private_mixed_home_office — Home office proporcja ══════
else := {
    "matched":true,"rule_id":"jdg.accounting.private_mixed_home_office",
    "package":"jdg.accounting","priority":850,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"partial","kus_percent":ku_percent,
    "vat_deduction_percent":ku_percent,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22 ust. 1 PIT, Art. 86 ust. 1 VAT",
    "_warnings":["Home office — KUP i VAT proporcjonalnie do powierzchni firmowej"]
} {
    input.invoice.is_home_office == true
    ho_pct := object.get(input.invoice,"home_office_area_percent",0)
    ho_pct > 0
    ku_percent := ho_pct
}

# ══════ P852: private_mixed_car — Samochód mieszany 75% KUP ══════
else := {
    "matched":true,"rule_id":"jdg.accounting.private_mixed_car",
    "package":"jdg.accounting","priority":852,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"partial","kus_percent":75,
    "vat_deduction_percent":50,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 23 ust. 1 pkt 46 PIT, Art. 86a VAT",
    "_warnings":["Samochód bez ewidencji przebiegu — KUP 75%, VAT 50%"]
} {
    input.invoice.category_code == "CAR"
    input.invoice.private_use_percent > 0
    input.invoice.has_mileage_log == false
}

# ══════ P860: operating_lease_full_kup — Leasing operacyjny → KUP ══════
else := {
    "matched":true,"rule_id":"jdg.accounting.operating_lease_full_kup",
    "package":"jdg.accounting","priority":860,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"full","kus_percent":100,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22 ust. 1 PIT",
    "_warnings":[]
} {
    input.invoice.expense_type == "LEASE"
    input.invoice.lease_type == "OPERATING"
}

# ══════ P870: fx_differences_recognition — Różnice kursowe (rozszerzone NBP A/B/C) ══════
# Kursy NBP: Tabela A (średnie — codziennie), Tabela B (UE — od 2025),
# Tabela C (celne — dla akcyzy/SAD).
# Zgodność: art. 14c PIT (przychody walutowe) i art. 24 ust. 2 PIT (koszty).
else := {
    "matched":true,"rule_id":"jdg.accounting.fx_differences_recognition",
    "package":"jdg.accounting","priority":870,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "fx_source_table":fx_table,"fx_rate_used":fx_rate,"fx_amount_pln":amount_pln,
    "_routing":fx_routing,"_routing_reason":fx_routing_reason,
    "_legal_basis":"Art. 14c, art. 24 ust. 2 PIT",
    "_warnings":fx_warnings
} {
    input.invoice.currency != "PLN"
    invoice_currency := input.invoice.currency
    amount_foreign := input.invoice.amount_gross

    # Wybór tabeli NBP wg typu transakcji
    # Tabela A: kursy średnie (domyślnie dla PIT/VAT)
    # Tabela B: kursy średnie walut UE (statystyczne)
    # Tabela C: kursy celne (import/eksport, SAD)
    fx_table = "A" {
        input.invoice.currency != "PLN"
    }
    fx_table = "C" {
        input.invoice.is_customs_transaction == true
    }

    # Pobierz kurs z data.thresholds (dzień roboczy poprzedzający)
    fx_rate := object.get(object.get(object.get(data.thresholds,"jdg",{}),"rates",{}),"forex",{})
    eur_pln := object.get(fx_rate,"eur_pln",4.5000)
    usd_pln := object.get(fx_rate,"usd_pln",3.8500)
    gbp_pln := object.get(fx_rate,"gbp_pln",5.2500)
    chf_pln := object.get(fx_rate,"chf_pln",4.6500)

    rate = eur_pln { invoice_currency == "EUR" }
    rate = usd_pln { invoice_currency == "USD" }
    rate = gbp_pln { invoice_currency == "GBP" }
    rate = chf_pln { invoice_currency == "CHF" }
    # Fallback: nieobsługiwana waluta — zablokuj transakcję
    rate = 0 { not invoice_currency in {"EUR","USD","GBP","CHF"} }

    fx_rate = rate
    # Jeśli rate=0 (nieobsługiwana waluta), ustaw BLOCK
    amount_pln = floor(amount_foreign * fx_rate * 100) / 100 { fx_rate > 0 }
    amount_pln = 0 { fx_rate == 0 }

    # Routing i ostrzeżenia zależne od tego czy waluta jest obsługiwana
    fx_routing = "" { fx_rate > 0 }
    fx_routing = "BLOCK_AND_ALERT" { fx_rate == 0 }
    fx_routing_reason = "" { fx_rate > 0 }
    fx_routing_reason = sprintf("Nieobsługiwana waluta: %s — brak kursu NBP", [invoice_currency]) { fx_rate == 0 }
    fx_warnings = [sprintf("Transakcja %s: kurs z Tabeli %s NBP = %.4f PLN/%s. Kwota w PLN: %.2f", [invoice_currency, fx_table, fx_rate, invoice_currency, amount_pln])] { fx_rate > 0 }
    fx_warnings = [sprintf("BLOKADA: waluta %s nieobsługiwana — dodaj kurs w data.thresholds lub użyj Tabeli C NBP", [invoice_currency])] { fx_rate == 0 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P875-P879: UoR — Inwentaryzacja, wycena, RMK, sprawozdanie (Sprint 2)
# ═══════════════════════════════════════════════════════════════════════════════

# P875: uor_annual_inventory — Inwentaryzacja roczna (Art. 26 UoR)
else := {
    "matched":true,"rule_id":"jdg.accounting.uor_annual_inventory",
    "package":"jdg.accounting","priority":875,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "inventory_required":true,"inventory_deadline":deadline,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Inwentaryzacja roczna wymagana — Art. 26 UoR",
    "_legal_basis":"Art. 26-27 Ustawy o rachunkowości",
    "_warnings":[sprintf("INWENTARYZACJA ROCZNA — termin: %s. Spis z natury, potwierdzenie sald, weryfikacja dokumentów.", [deadline])]
} {
    is_year_end := object.get(input.invoice,"is_year_end",false)
    is_year_end == true
    tax_year := object.get(input.invoice,"tax_year","")
    deadline := sprintf("%s-03-31", [sprintf("%d", [to_number(tax_year) + 1])])
}

# P876: uor_asset_valuation — Wycena aktywów (Art. 28-34 UoR)
else := {
    "matched":true,"rule_id":"jdg.accounting.uor_asset_valuation",
    "package":"jdg.accounting","priority":876,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "valuation_method":valuation_method,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 28-34 Ustawy o rachunkowości",
    "_warnings":[sprintf("Wycena aktywów — metoda: %s (cena nabycia / koszt wytworzenia / wartość godziwa)", [valuation_method])]
} {
    input.jdg_entrepreneur.uses_uor == true
    input.invoice.expense_type == "FIXED_ASSET"
    asset_type := object.get(input.invoice,"asset_type","TANGIBLE")
    valuation_method = "PURCHASE_PRICE" { asset_type == "TANGIBLE" }
    valuation_method = "FAIR_VALUE" { asset_type == "FINANCIAL_INSTRUMENT" }
    valuation_method = "PRODUCTION_COST" { asset_type == "SELF_MANUFACTURED" }
}

# P877: uor_accruals_deferrals — Rozliczenia międzyokresowe RMK (Art. 39 UoR)
else := {
    "matched":true,"rule_id":"jdg.accounting.uor_accruals_deferrals",
    "package":"jdg.accounting","priority":877,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "rmk_type":rmk_type,"rmk_amount":rmk_amount,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 39 Ustawy o rachunkowości",
    "_warnings":[sprintf("RMK %s: %.2f PLN — rozliczenie międzyokresowe", [rmk_type, rmk_amount])]
} {
    input.jdg_entrepreneur.uses_uor == true
    input.invoice.is_accrual == true
    rmk_type = "czynne" { input.invoice.accrual_type == "PREPAID" }
    rmk_type = "bierne" { input.invoice.accrual_type == "ACCRUED" }
    rmk_amount := object.get(input.invoice,"accrual_amount",0)
}

# P878: uor_financial_statement — Sprawozdanie finansowe (Art. 45-52 UoR)
else := {
    "matched":true,"rule_id":"jdg.accounting.uor_financial_statement",
    "package":"jdg.accounting","priority":878,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "financial_statement_required":true,"statement_deadline":deadline,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 45-52 Ustawy o rachunkowości",
    "_warnings":[sprintf("Sprawozdanie finansowe za %s — termin: %s. Bilans + RZiS + informacja dodatkowa.", [tax_year, deadline])]
} {
    input.jdg_entrepreneur.annual_revenue_eur > 2000000
    is_year_end := object.get(input.invoice,"is_year_end",false)
    is_year_end == true
    tax_year := object.get(input.invoice,"tax_year","")
    deadline := sprintf("%s-03-31", [sprintf("%d", [to_number(tax_year) + 1])])
}

# P879: uor_document_retention — Przechowywanie dokumentów (Art. 74 UoR)
else := {
    "matched":true,"rule_id":"jdg.accounting.uor_document_retention",
    "package":"jdg.accounting","priority":879,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "retention_years":5,"retention_post_closure_years":5,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 74 Ustawy o rachunkowości",
    "_warnings":["Dokumenty księgowe — 5 lat od końca roku + 5 lat po zakończeniu działalności"]
} {
    input.jdg_entrepreneur.uses_uor == true
    input.invoice.is_year_end == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P880-P884: Pełna klasyfikacja KŚT (Sprint 2)
# ═══════════════════════════════════════════════════════════════════════════════

# P880: kst_group_classification — Klasyfikacja środka trwałego do grupy KŚT
else := {
    "matched":true,"rule_id":"jdg.accounting.kst_group_classification",
    "package":"jdg.accounting","priority":880,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "kst_classified_group":kst_g,"kst_classified_subgroup":kst_sg,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Rozporządzenie RM z 30.12.1999 w sprawie KŚT",
    "_warnings":[sprintf("KŚT: grupa %d, podgrupa %d", [kst_g, kst_sg])]
} {
    input.invoice.expense_type == "FIXED_ASSET"
    asset_category := object.get(input.invoice,"asset_category","")

    # Automatyczna klasyfikacja KŚT na podstawie kategorii środka trwałego
    kst_g = 0 { asset_category in {"LAND","LAND_RIGHT"} }
    kst_sg = 0 { asset_category in {"LAND","LAND_RIGHT"} }
    kst_g = 1 { asset_category in {"BUILDING","PREMISES","APARTMENT"} }
    kst_sg = 1 { asset_category in {"BUILDING","PREMISES","APARTMENT"} }
    kst_g = 2 { asset_category in {"CIVIL_STRUCTURE","BRIDGE","ROAD"} }
    kst_sg = 1 { asset_category in {"CIVIL_STRUCTURE","BRIDGE","ROAD"} }
    kst_g = 4 { asset_category in {"MACHINERY","PRODUCTION_EQUIPMENT"} }
    kst_sg = 1 { asset_category in {"MACHINERY","PRODUCTION_EQUIPMENT"} }
    kst_g = 4 { asset_category == "COMPUTER" }
    kst_sg = 5 { asset_category == "COMPUTER" }
    kst_g = 4 { asset_category == "OFFICE_EQUIPMENT" }
    kst_sg = 4 { asset_category == "OFFICE_EQUIPMENT" }
    kst_g = 7 { asset_category in {"CAR","TRUCK","MOTORCYCLE"} }
    kst_sg = 1 { asset_category == "CAR" }
    kst_sg = 2 { asset_category == "TRUCK" }
    kst_sg = 3 { asset_category == "MOTORCYCLE" }
    kst_g = 8 { asset_category in {"TOOLS","FURNITURE","FIXTURES"} }
    kst_sg = 2 { asset_category in {"TOOLS","FURNITURE","FIXTURES"} }
    kst_g = 10 { asset_category in {"SOFTWARE","PATENT","LICENSE","KNOW_HOW"} }
    kst_sg = 1 { asset_category == "SOFTWARE" }
    kst_sg = 2 { asset_category in {"PATENT","LICENSE"} }
    kst_sg = 3 { asset_category == "KNOW_HOW" }
}

# P881: depreciation_rate_assignment — Przypisanie stawki z walidacją KŚT
else := {
    "matched":true,"rule_id":"jdg.accounting.depreciation_rate_assignment",
    "package":"jdg.accounting","priority":881,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "depreciation_rate":rate,"depreciation_period_years":years,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22i PIT, Załącznik nr 1 do ustawy PIT",
    "_warnings":[sprintf("Stawka amortyzacji: %.1f%% rocznie (okres: %.0f lat)", [rate*100, years])]
} {
    input.invoice.expense_type == "FIXED_ASSET"
    rate := object.get(input.invoice,"depreciation_rate",0.20)
    rate > 0
    years = 1.0 / rate
}

# P882: intangible_assets_classification — WNiP (wartości niematerialne i prawne)
else := {
    "matched":true,"rule_id":"jdg.accounting.intangible_assets_classification",
    "package":"jdg.accounting","priority":882,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "wnip_type":wnip_type,"wnip_amortization_months":months,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22b, art. 22m PIT",
    "_warnings":[sprintf("WNiP: %s — amortyzacja przez %d miesięcy", [wnip_type, months])]
} {
    input.invoice.expense_type == "INTANGIBLE_ASSET"
    asset_category := object.get(input.invoice,"asset_category","")

    wnip_type = "software" { asset_category == "SOFTWARE" }
    months = 24 { asset_category == "SOFTWARE" }
    wnip_type = "patent" { asset_category == "PATENT" }
    months = 60 { asset_category == "PATENT" }
    wnip_type = "license" { asset_category == "LICENSE" }
    months = 60 { asset_category == "LICENSE" }
    wnip_type = "know_how" { asset_category == "KNOW_HOW" }
    months = 60 { asset_category == "KNOW_HOW" }
    wnip_type = "goodwill" { asset_category == "GOODWILL" }
    months = 60 { asset_category == "GOODWILL" }
}

# P883: one_time_depreciation_eligibility — Jednorazowa amortyzacja dla ≤10k PLN
else := {
    "matched":true,"rule_id":"jdg.accounting.one_time_depreciation_eligibility",
    "package":"jdg.accounting","priority":883,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "depreciation_method":"ONE_OFF_LOW_VALUE","depreciation_rate":"1.00",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22d ust. 1 PIT",
    "_warnings":[sprintf("Jednorazowa amortyzacja — wartość %.2f PLN ≤ 10 000 PLN", [asset_value])]
} {
    input.invoice.expense_type == "FIXED_ASSET"
    asset_value := object.get(input.invoice,"amount_net",0)
    asset_value <= 10000
    asset_value > 0
    input.jdg_entrepreneur.is_small_taxpayer == false
}

# P884: improvement_threshold_check — Ulepszenie >10k PLN podwyższa podstawę
else := {
    "matched":true,"rule_id":"jdg.accounting.improvement_threshold_check",
    "package":"jdg.accounting","priority":884,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "improvement_exceeds_threshold":true,"base_increase_required":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22g ust. 17 PIT",
    "_warnings":[sprintf("ULEPSZENIE %.2f PLN > 10 000 PLN — podwyższa wartość początkową środka trwałego!", [improvement_cost])]
} {
    input.invoice.expense_type == "FIXED_ASSET_IMPROVEMENT"
    improvement_cost := object.get(input.invoice,"amount_net",0)
    improvement_cost > 10000
}

# ═══════════════════════════════════════════════════════════════════════════════
# R0472-R0479: Remanent — ciągłość, wycena, likwidacja (Sprint 2)
# ═══════════════════════════════════════════════════════════════════════════════

# R0472: remnant_continuity_validation — Remanent początkowy = końcowy poprzedniego roku
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_continuity_validation",
    "package":"jdg.accounting","priority":472,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "remnant_discrepancy":diff,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Remanent — brak ciągłości między latami",
    "_legal_basis":"§ 27-29 rozporządzenia PKPiR",
    "_warnings":[sprintf("REMANENT ROCZNY: pocz. %.2f ≠ końc. poprzedniego %.2f (różnica %.2f PLN). Korekta wymagana!", [rem_start_year, rem_end_prev_year, diff])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    is_year_start := object.get(input.invoice,"is_year_start",false)
    is_year_start == true
    rem_start_year := object.get(input.invoice,"remnant_start_of_year",0)
    rem_end_prev_year := object.get(input.invoice,"remnant_end_previous_year",0)
    rem_end_prev_year > 0
    rem_start_year != rem_end_prev_year
    diff = rem_start_year - rem_end_prev_year
}

# R0473: remnant_valuation_method — Wycena remanentu (cena nabycia / rynkowa)
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_valuation_method",
    "package":"jdg.accounting","priority":473,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "remnant_valuation":valuation,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 29 rozporządzenia PKPiR, Art. 24 ust. 2 PIT",
    "_warnings":[sprintf("Wycena remanentu: %s", [valuation])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.is_period_end == true
    remnant_v := object.get(input.invoice,"remnant_valuation_method","")
    valuation = "cena nabycia" { remnant_v == "PURCHASE_PRICE" }
    valuation = "cena rynkowa (niższa od nabycia)" { remnant_v == "LOWER_OF_COST_OR_MARKET" }
    valuation = "koszt wytworzenia" { remnant_v == "PRODUCTION_COST" }
}

# R0474: remnant_liquidation_inventory — Remanent likwidacyjny
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_liquidation_inventory",
    "package":"jdg.accounting","priority":474,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "liquidation_inventory_required":true,"liquidation_income":liquidation_income,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Remanent likwidacyjny — koniec działalności",
    "_legal_basis":"Art. 24 ust. 3 PIT, § 27-29 PKPiR",
    "_warnings":[sprintf("REMANENT LIKWIDACYJNY — przychód z likwidacji: %.2f PLN. Obowiązek sporządzenia w dniu zakończenia działalności!", [liquidation_income])]
} {
    input.jdg_entrepreneur.business_closing == true
    remnant_value := object.get(input.invoice,"remnant_end_value",0)
    remnant_value > 0
    liquidation_income = remnant_value
}

# R0475: remnant_scrap_loss — Ubytki i straty w remanencie
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_scrap_loss",
    "package":"jdg.accounting","priority":475,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"none","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "scrap_loss_amount":loss_amount,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Ubytki remanentowe — wymagane udokumentowanie",
    "_legal_basis":"§ 28 rozporządzenia PKPiR",
    "_warnings":[sprintf("UBYTKI REMANENTOWE: %.2f PLN — udokumentuj przyczynę (zniszczenie, kradzież, przeterminowanie)", [loss_amount])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.expense_type == "INVENTORY_LOSS"
    loss_amount := object.get(input.invoice,"amount_net",0)
    loss_amount > 0
}

# R0476: remnant_market_price_correction — Korekta do cen rynkowych
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_market_price_correction",
    "package":"jdg.accounting","priority":476,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "market_price_adjustment":adjustment,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 14 ust. 2 PIT, § 29 ust. 2 rozporządzenia PKPiR",
    "_warnings":[sprintf("KOREKTA REMANENTU — wycena rynkowa %.2f PLN vs księgowa %.2f PLN (różnica: %.2f PLN)", [market_val, book_val, adjustment])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.is_period_end == true
    book_val := object.get(input.invoice,"remnant_book_value",0)
    market_val := object.get(input.invoice,"remnant_market_value",0)
    market_val > 0
    market_val != book_val
    adjustment = market_val - book_val
}

# R0477: remnant_damage_disposal_protocol — Protokół zniszczenia/likwidacji
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_damage_disposal_protocol",
    "package":"jdg.accounting","priority":477,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "disposal_protocol_required":true,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Brak protokołu zniszczenia/likwidacji towarów",
    "_legal_basis":"§ 28 ust. 4 rozporządzenia PKPiR, Art. 24 ust. 2 PIT",
    "_warnings":["PROTOKÓŁ ZNISZCZENIA WYMAGANY — towary uszkodzone/przeterminowane muszą być udokumentowane komisyjnym protokołem likwidacji"]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.expense_type == "INVENTORY_DISPOSAL"
    input.invoice.has_disposal_protocol == false
}

# R0478: remnant_tax_return_correction — Korekta zeznania rocznego o remanent
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_tax_return_correction",
    "package":"jdg.accounting","priority":478,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "remnant_pit_correction":correction,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 24 ust. 2 PIT, § 27 rozporządzenia PKPiR",
    "_warnings":[sprintf("KOREKTA PIT O REMANENT: %.2f PLN (końcowy=%.2f, początkowy=%.2f)", [correction, rem_end, rem_start])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.is_period_end == true
    # Oblicz korektę dochodu o różnicę remanentową
    # Dochód = przychód - koszty + remanent_końcowy - remanent_początkowy
    rem_end := object.get(input.invoice,"remnant_end_value",0)
    rem_start := object.get(input.invoice,"remnant_start_value",0)
    correction = rem_end - rem_start
    correction != 0
}

# R0479: remnant_physical_count_obligation — Obowiązek spisu z natury
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_physical_count_obligation",
    "package":"jdg.accounting","priority":479,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "physical_count_deadline":deadline,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Spis z natury — obowiązek na koniec roku",
    "_legal_basis":"§ 27 ust. 1 rozporządzenia PKPiR",
    "_warnings":[sprintf("SPIS Z NATURY — termin: %s. Obejmuje: towary handlowe, materiały, półprodukty, wyroby gotowe, braki.", [deadline])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.is_year_end == true
    tax_year := object.get(input.invoice,"tax_year","")
    deadline := sprintf("%s-01-15", [sprintf("%d", [to_number(tax_year) + 1])])
}

# R0480: remnant_goods_in_transit — Towary w drodze
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_goods_in_transit",
    "package":"jdg.accounting","priority":480,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "goods_in_transit_value":transit_value,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 27 ust. 3 rozporządzenia PKPiR",
    "_warnings":[sprintf("TOWARY W DRODZE: %.2f PLN — ujęte w remanencie na podstawie dokumentów dostawy", [transit_value])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    transit_value := object.get(input.invoice,"goods_in_transit_value",0)
    transit_value > 0
}

# R0481: remnant_third_party_goods — Towary obce w remanencie (komis, konsygnacja)
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_third_party_goods",
    "package":"jdg.accounting","priority":481,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "third_party_goods_excluded":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 27 ust. 4 rozporządzenia PKPiR",
    "_warnings":[sprintf("TOWARY OBCE — %.2f PLN (komis/konsygnacja) NIE są ujmowane w remanencie własnym", [third_party_val])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    third_party_val := object.get(input.invoice,"third_party_goods_value",0)
    third_party_val > 0
}

# R0482: remnant_consignment_own — Towary własne w komisie (ujęte w remanencie)
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_consignment_own",
    "package":"jdg.accounting","priority":482,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "consignment_own_included":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 27 ust. 2 rozporządzenia PKPiR",
    "_warnings":[sprintf("TOWARY WŁASNE W OBECYM POSIADANIU: %.2f PLN — ujęte w remanencie mimo że fizycznie u kontrahenta", [consignment_val])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    consignment_val := object.get(input.invoice,"own_goods_at_third_party",0)
    consignment_val > 0
}

# R0483: remnant_write_off_approval — Zatwierdzenie odpisu przeterminowanych zapasów
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_write_off_approval",
    "package":"jdg.accounting","priority":483,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "write_off_amount":write_off,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Odpis przeterminowanych zapasów — wymagane zatwierdzenie",
    "_legal_basis":"Art. 24 ust. 2 PIT w zw. z Art. 22 ust. 1 PIT",
    "_warnings":[sprintf("ODPIS ZAPASÓW: %.2f PLN — towary przeterminowane > %d dni. Wymagane zatwierdzenie przez właściciela.", [write_off, expiry_days])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.expense_type == "INVENTORY_WRITE_OFF"
    write_off := object.get(input.invoice,"amount_net",0)
    expiry_days := object.get(input.invoice,"days_past_expiry",0)
    write_off > 0
    input.invoice.write_off_approved == false
}

# R0484: remnant_charity_donation — Przekazanie towarów na cele charytatywne
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_charity_donation",
    "package":"jdg.accounting","priority":484,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"none","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "donation_value_pln":donation_val,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 23 ust. 1 pkt 11 PIT, Art. 7 ust. 2 VAT",
    "_warnings":[sprintf("DAROWIZNA TOWARÓW: %.2f PLN — NIE stanowi KUP. Udokumentuj protokołem przekazania + umową darowizny.", [donation_val])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.expense_type == "INVENTORY_DONATION"
    donation_val := object.get(input.invoice,"amount_net",0)
    donation_val > 0
}

# R0485: remnant_theft_documentation — Kradzież — wymagane zgłoszenie na policję
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_theft_documentation",
    "package":"jdg.accounting","priority":485,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"none","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "theft_loss":theft_val,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Kradzież towarów — brak zgłoszenia policyjnego",
    "_legal_basis":"Art. 23 ust. 1 pkt 5 PIT, § 28 rozporządzenia PKPiR",
    "_warnings":[sprintf("KRADZIEŻ TOWARÓW: %.2f PLN — wymagane zgłoszenie na policję + protokół szkody. Bez dokumentu NIE stanowi KUP.", [theft_val])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.expense_type == "INVENTORY_THEFT"
    theft_val := object.get(input.invoice,"amount_net",0)
    theft_val > 0
    input.invoice.police_report_filed == false
}

# R0486: remnant_natural_decay — Ubytki naturalne (parowanie, wysychanie)
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_natural_decay",
    "package":"jdg.accounting","priority":486,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"full","kus_percent":100,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "natural_decay_pct":decay_pct,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 28 ust. 2 rozporządzenia PKPiR",
    "_warnings":[sprintf("UBYTKI NATURALNE: %.1f%% (%.2f PLN) — mieszczą się w normie. KUP zachowany.", [decay_pct, decay_val])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.expense_type == "INVENTORY_NATURAL_DECAY"
    decay_val := object.get(input.invoice,"amount_net",0)
    total_stock := object.get(input.invoice,"remnant_start_value",0)
    decay_val > 0
    total_stock > 0
    decay_pct := decay_val / total_stock * 100
    decay_pct < 5
}

# R0487: remnant_production_waste — Odpady produkcyjne
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_production_waste",
    "package":"jdg.accounting","priority":487,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"full","kus_percent":100,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "production_waste_value":waste_val,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 28 rozporządzenia PKPiR",
    "_warnings":[sprintf("ODPADY PRODUKCYJNE: %.2f PLN — ewidencjonowane jako KUP. Technologicznie uzasadnione.", [waste_val])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.expense_type == "PRODUCTION_WASTE"
    waste_val := object.get(input.invoice,"amount_net",0)
    waste_val > 0
}

# R0488: remnant_sample_giveaway — Próbki i prezenty małej wartości
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_sample_giveaway",
    "package":"jdg.accounting","priority":488,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "sample_value_per_item":unit_val,
    "_routing":routing_val,
    "_routing_reason":routing_reason,
    "_legal_basis":"Art. 7 ust. 1-2 VAT, Art. 23 ust. 1 pkt 11 PIT",
    "_warnings":[sprintf("PRÓBKI/UPOMINKI: %d szt. × %.2f PLN = %.2f PLN. Limit zwolnienia z VAT: 200 PLN/szt. (bez limitu ilości dla próbek).", [qty, unit_val, total_val])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.expense_type == "INVENTORY_SAMPLE"
    unit_val := object.get(input.invoice,"amount_net",0)
    qty := object.get(input.invoice,"quantity",1)
    total_val := unit_val * qty
    total_val > 0
    # Rego: inkrementalne definicje zamiast ternary ?:
    routing_val = "TRIAGE_QUEUE" { unit_val > 200 }
    routing_val = "" { unit_val <= 200 }
    routing_reason = "Próbka > 200 PLN — może wymagać opodatkowania VAT" { unit_val > 200 }
    routing_reason = "" { unit_val <= 200 }
}

# R0489: remnant_consignment_return — Zwrot towarów z komisu
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_consignment_return",
    "package":"jdg.accounting","priority":489,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "consignment_return_value":ret_val,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 27 rozporządzenia PKPiR",
    "_warnings":[sprintf("ZWROT Z KOMISU: %.2f PLN — towary wracają do remanentu własnego. Aktualizuj stan magazynowy.", [ret_val])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.expense_type == "CONSIGNMENT_RETURN"
    ret_val := object.get(input.invoice,"amount_net",0)
    ret_val > 0
}

# R0490: remnant_archive_index — Indeksacja archiwalna remanentów
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_archive_index",
    "package":"jdg.accounting","priority":490,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "remnant_archive_id":archive_id,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 29 rozporządzenia PKPiR, Art. 86 § 1 OrdPU",
    "_warnings":[sprintf("ARCHIWIZACJA REMANENTU: ID=%s — przechowuj przez 5 lat od końca roku", [archive_id])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.is_period_end == true
    tax_year := object.get(input.invoice,"tax_year","")
    remnant_id := object.get(input.invoice,"remnant_document_id","")
    archive_id := sprintf("REM-%s-%s", [tax_year, remnant_id])
}

# R0491: remnant_cross_year_comparison — Porównanie międzyokresowe
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_cross_year_comparison",
    "package":"jdg.accounting","priority":491,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "remnant_yoy_change_pct":yoy_pct,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Anomalia remanentowa — zmiana YoY > 50%",
    "_legal_basis":"§ 27-29 rozporządzenia PKPiR",
    "_warnings":[sprintf("REMANENT YoY: zmiana o %.1f%% (%.2f → %.2f PLN). Zweryfikuj poprawność spisu!", [yoy_pct, prev_year_val, current_year_val])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.is_year_end == true
    current_year_val := object.get(input.invoice,"remnant_end_value",0)
    prev_year_val := object.get(input.invoice,"remnant_previous_end_value",0)
    prev_year_val > 0
    yoy_pct := abs(current_year_val - prev_year_val) / prev_year_val * 100
    yoy_pct > 50
}

# R0492: remnant_multi_warehouse_reconciliation — Uzgodnienie magazynów
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_multi_warehouse_reconciliation",
    "package":"jdg.accounting","priority":492,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "warehouse_count":wh_count,"reconciled":all_reconciled,
    "_routing":routing_val,
    "_routing_reason":routing_reason,
    "_legal_basis":"§ 27 rozporządzenia PKPiR",
    "_warnings":[sprintf("UZGODNIENIE MAGAZYNÓW: %d magazynów, suma=%.2f PLN, niezgodność=%.2f PLN", [wh_count, total_sum, discrepancy])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.is_period_end == true
    wh_count := object.get(input.invoice,"warehouse_count",0)
    discrepancy := object.get(input.invoice,"warehouse_discrepancy",0)
    total_sum := object.get(input.invoice,"remnant_end_value",0)
    wh_count > 1
    all_reconciled = (discrepancy == 0)
    # Rego: inkrementalne definicje zamiast ternary ?:
    routing_val = "" { all_reconciled == true }
    routing_val = "TRIAGE_QUEUE" { all_reconciled == false }
    routing_reason = "" { all_reconciled == true }
    routing_reason = "Remanent — niezgodność między magazynami" { all_reconciled == false }
}

# R0493: remnant_fx_foreign_goods — Wycena towarów z importu w PLN
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_fx_foreign_goods",
    "package":"jdg.accounting","priority":493,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "fx_valuation_rate":fx_rate,"fx_converted_value_pln":value_pln,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 24 ust. 2 PIT, § 29 rozporządzenia PKPiR",
    "_warnings":[sprintf("TOWARY Z IMPORTU: %.2f %s × kurs %.4f = %.2f PLN (Tabela A NBP z dnia poprzedzającego spis)", [value_fx, currency, fx_rate, value_pln])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.is_period_end == true
    currency := object.get(input.invoice,"remnant_fx_currency","")
    currency != ""
    currency != "PLN"
    value_fx := object.get(input.invoice,"remnant_fx_value",0)
    fx_rate := object.get(input.invoice,"remnant_fx_rate",0)
    fx_rate > 0
    value_pln = value_fx * fx_rate
}

# R0494: remnant_seasonal_markdown — Przecena sezonowa towarów
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_seasonal_markdown",
    "package":"jdg.accounting","priority":494,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "markdown_pct":markdown,"markdown_value":markdown_val,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 29 ust. 2 rozporządzenia PKPiR",
    "_warnings":[sprintf("PRZECENA SEZONOWA: -%.0f%% (%.2f PLN). Wycena wg niższej wartości rynkowej.", [markdown, markdown_val])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.expense_type == "INVENTORY_MARKDOWN"
    original_val := object.get(input.invoice,"amount_net",0)
    market_val := object.get(input.invoice,"remnant_market_value",0)
    original_val > 0
    market_val > 0
    market_val < original_val
    markdown := (1.0 - market_val / original_val) * 100
    markdown_val := original_val - market_val
}

# R0495: remnant_digital_record — Obowiązek ewidencji elektronicznej
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_digital_record",
    "package":"jdg.accounting","priority":495,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "digital_record_required":true,"digital_format":"JPK_PKPIR",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 193a OrdPU, § 11 rozporządzenia PKPiR",
    "_warnings":["REMAMENT ELEKTRONICZNY — od 2025 obowiązek prowadzenia w formie elektronicznej. Zgodność z JPK_PKPIR."]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.is_year_end == true
    input.invoice.transaction_date >= "2025-01-01"
    input.invoice.remnant_is_digital == false
}

# R0496: remnant_audit_trail_documentation — Ścieżka audytu dla kontroli skarbowej
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_audit_trail_documentation",
    "package":"jdg.accounting","priority":496,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "audit_trail_complete":false,"missing_items":missing,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Brak kompletnej ścieżki audytu remanentu",
    "_legal_basis":"Art. 193 OrdPU, § 11 rozporządzenia PKPiR",
    "_warnings":[sprintf("ŚCIEŻKA AUDYTU REMANENTU: brakuje %d elementów. Wymagane: arkusze spisowe, protokoły różnic, wycena, zatwierdzenie.", [missing])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.is_period_end == true
    has_sheets := object.get(input.invoice,"remnant_has_count_sheets",false)
    has_diff_protocol := object.get(input.invoice,"remnant_has_diff_protocol",false)
    has_valuation := object.get(input.invoice,"remnant_has_valuation",false)
    has_approval := object.get(input.invoice,"remnant_has_approval",false)
    all_docs = count([has_sheets, has_diff_protocol, has_valuation, has_approval])
    all_docs < 4
    missing = 4 - all_docs
}

# R0497: remnant_transport_damage — Szkody transportowe
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_transport_damage",
    "package":"jdg.accounting","priority":497,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "transport_damage":damage_val,
    "_routing":routing_val,
    "_routing_reason":routing_reason,
    "_legal_basis":"§ 28 rozporządzenia PKPiR",
    "_warnings":[sprintf("SZKODA TRANSPORTOWA: %.2f PLN — udokumentuj protokołem szkody + reklamacją do przewoźnika.", [damage_val])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.expense_type == "TRANSPORT_DAMAGE"
    damage_val := object.get(input.invoice,"amount_net",0)
    damage_val > 0
    # Rego: inkrementalne definicje zamiast ternary ?:
    routing_val = "TRIAGE_QUEUE" { damage_val > 5000 }
    routing_val = "" { damage_val <= 5000 }
    routing_reason = "Szkoda transportowa > 5000 PLN — wymagany protokół przewoźnika" { damage_val > 5000 }
    routing_reason = "" { damage_val <= 5000 }
}

# R0498: remnant_warranty_replacement — Towary z wymiany gwarancyjnej
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_warranty_replacement",
    "package":"jdg.accounting","priority":498,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "warranty_replacement_value":rep_val,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 27 rozporządzenia PKPiR, Kodeks Cywilny art. 577",
    "_warnings":[sprintf("WYMIANA GWARANCYJNA: %.2f PLN — towary wymienione nie wchodzą do remanentu (własność gwaranta).", [rep_val])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.expense_type == "WARRANTY_REPLACEMENT"
    rep_val := object.get(input.invoice,"amount_net",0)
    rep_val > 0
}

# R0499: remnant_annual_summary_report — Raport roczny remanentu
else := {
    "matched":true,"rule_id":"jdg.accounting.remnant_annual_summary_report",
    "package":"jdg.accounting","priority":499,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "remnant_summary_start":rem_start_val,"remnant_summary_end":rem_end_val,
    "remnant_summary_change":change_val,"remnant_summary_change_pct":change_pct,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 27-29 rozporządzenia PKPiR",
    "_warnings":[sprintf("RAPORT ROCZNY REMANENTU: pocz. %.2f PLN → końc. %.2f PLN (Δ=%.2f PLN, %.1f%%). Załącznik do PIT-36.", [rem_start_val, rem_end_val, change_val, change_pct])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.is_year_end == true
    rem_start_val := object.get(input.invoice,"remnant_start_value",0)
    rem_end_val := object.get(input.invoice,"remnant_end_value",0)
    change_val := rem_end_val - rem_start_val
    change_pct = 0 { rem_start_val == 0 }
    change_pct = change_val / rem_start_val * 100 { rem_start_val > 0 }
}
