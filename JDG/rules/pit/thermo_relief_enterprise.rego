# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE THERMO-MODERNIZATION RELIEF (Art. 26h PIT)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Thermo-Modernization Relief — Ulga Termomodernizacyjna
# description: |
#   ENTERPRISE v7.0 — Wypełnia lukę CR3 z Raportu v7.0.
#   Ulga termomodernizacyjna (Art. 26h PIT): odliczenie do 53 000 PLN
#   na podatnika (nie na budynek!) wydatków na termomodernizację budynku
#   mieszkalnego jednorodzinnego. R120-R129.
#   - R120: Definicja przedsięwzięcia termomodernizacyjnego
#   - R121-R125: Katalog wydatków kwalifikowanych
#   - R126: Limit 53 000 PLN per podatnik
#   - R127: Wymóg faktury VAT od czynnego podatnika VAT
#   - R128: Termin 3 lata od pierwszej faktury
#   - R129: Wykluczenie podwójnego odliczenia (Czyste Powietrze itp.)
# architecture: Enterprise Multi-Pass (ADR-001), First-Match-Wins else-chain
# legal_basis: Art. 26h PIT; Rozporządzenie MF ws. termomodernizacji
# package: jdg.pit.thermo_relief
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.thermo_relief

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.pit.thermo.no_match",
    "package": "jdg.pit.thermo_relief", "priority": 999
}

# ═══════════════════════════════════════════════════════════════════════════════
# R120: thermo_enterprise_qualification — Definicja przedsięwzięcia
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true,
    "rule_id": "jdg.pit.thermo.relief_qualification",
    "package": "jdg.pit.thermo_relief",
    "priority": 120,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "thermo_relief_eligible": thermo_eligible,
    "thermo_property_type": property_type,
    "thermo_relief_limit_pln": 53000,
    "thermo_relief_limit_per_taxpayer": true,
    "thermo_relief_limit_note": "Limit 53 000 PLN NA PODATNIKA (nie na budynek!) — jeśli małżonkowie mają wspólnotę, każde może odliczyć osobno swoje wydatki",
    "_routing": thermo_rt,
    "_routing_reason": thermo_rs,
    "_legal_basis": "Art. 26h ust. 1-2 PIT",
    "_warnings": [
        sprintf("🏠 ULGA TERMOMODERNIZACYJNA — %s. Limit: 53 000 PLN na podatnika. Właściciel: %s.",
            [qualification_msg, property_type])
    ]
} {
    input.thermo_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    is_owner := object.get(input.jdg_entrepreneur, "owns_single_family_home", false)
    is_co_owner := object.get(input.jdg_entrepreneur, "is_co_owner_single_family_home", false)
    building_type := object.get(input.jdg_entrepreneur, "building_type", "")

    thermo_eligible := is_owner or is_co_owner
    property_type = "WŁAŚCICIEL" { is_owner }
    property_type = "WSPÓŁWŁAŚCICIEL" { is_co_owner }
    qualification_msg = "KWALIFIKUJE SIĘ" { thermo_eligible }
    qualification_msg = "NIE kwalifikuje — brak własności/współwłasności budynku jednorodzinnego" { not thermo_eligible }

    thermo_rt = "TRIAGE_QUEUE" { thermo_eligible }
    thermo_rt = "BLOCK_AND_ALERT" { not thermo_eligible }
    thermo_rs = sprintf("Ulga termomodernizacyjna dostępna — maksymalnie 53 000 PLN odliczenia", []) { thermo_eligible }
    thermo_rs = "Brak prawa do ulgi termomodernizacyjnej" { not thermo_eligible }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R121: thermo_qualifying_expenses_windows — Okna i drzwi
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.thermo.qualifying_windows_doors",
    "package": "jdg.pit.thermo_relief",
    "priority": 121,
    "pit_form": pit_form,
    "thermo_expense_type": "WINDOWS_DOORS",
    "thermo_is_qualifying": is_qualifying,
    "thermo_expense_amount": expense_amount,
    "thermo_requires_vat_invoice": true,
    "_routing": thermo_rt,
    "_routing_reason": sprintf("Okna/drzwi: %.2f PLN — %s", [expense_amount, qualifying_msg]),
    "_legal_basis": "Art. 26h ust. 3 pkt 1 PIT (materiały budowlane do ocieplenia)",
    "_warnings": [sprintf("Okna/drzwi — %.2f PLN. %s. Wymagana FAKTURA VAT od czynnego podatnika VAT. Paragon NIE wystarczy! Zachowaj fakturę przez 5 lat.",
        [expense_amount, qualifying_msg])]
} {
    input.thermo_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    expense_type := object.get(input.invoice, "thermo_expense_type", "")
    expense_type in {"WINDOWS", "DOORS", "GARAGE_DOOR"}
    expense_amount := object.get(input.invoice, "amount_net", 0)
    has_vat_invoice := object.get(input.invoice, "is_vat_invoice_from_active_vat_payer", false)

    is_qualifying := expense_amount > 0 and has_vat_invoice
    qualifying_msg = "KWALIFIKUJE SIĘ do ulgi" { is_qualifying }
    qualifying_msg = "NIE kwalifikuje — brak faktury VAT od czynnego podatnika VAT" { not has_vat_invoice; expense_amount > 0 }
    qualifying_msg = "NIE kwalifikuje — kwota zerowa" { expense_amount == 0 }

    thermo_rt = "" { is_qualifying }
    thermo_rt = "BLOCK_AND_ALERT" { not is_qualifying; expense_amount > 10000 }
    thermo_rt = "TRIAGE_QUEUE" { not is_qualifying; expense_amount > 0; expense_amount <= 10000 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R122: thermo_qualifying_expenses_insulation — Izolacja, ocieplenie
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.thermo.qualifying_insulation",
    "package": "jdg.pit.thermo_relief",
    "priority": 122,
    "pit_form": pit_form,
    "thermo_expense_type": "INSULATION",
    "thermo_is_qualifying": is_qualifying,
    "thermo_expense_amount": expense_amount,
    "_routing": thermo_rt,
    "_routing_reason": sprintf("Izolacja/ocieplenie: %.2f PLN — %s", [expense_amount, qualifying_msg]),
    "_legal_basis": "Art. 26h ust. 3 pkt 1-2 PIT",
    "_warnings": [sprintf("Izolacja/ocieplenie — %.2f PLN. Dotyczy: ścian, dachu, fundamentów, stropów. Wymagana faktura VAT + dokumentacja techniczna (audyt energetyczny zalecany).",
        [expense_amount])]
} {
    input.thermo_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    expense_type := object.get(input.invoice, "thermo_expense_type", "")
    expense_type in {"WALL_INSULATION", "ROOF_INSULATION", "FLOOR_INSULATION", "FOUNDATION_INSULATION"}
    expense_amount := object.get(input.invoice, "amount_net", 0)
    has_vat_invoice := object.get(input.invoice, "is_vat_invoice_from_active_vat_payer", false)

    is_qualifying := expense_amount > 0 and has_vat_invoice
    qualifying_msg = "KWALIFIKUJE SIĘ" { is_qualifying }
    qualifying_msg = "NIE kwalifikuje" { not is_qualifying }

    thermo_rt = "TRIAGE_QUEUE" { is_qualifying; expense_amount > 15000 }
    thermo_rt = "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R123: thermo_qualifying_expenses_heating — Ogrzewanie, pompy ciepła, kotły
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.thermo.qualifying_heating",
    "package": "jdg.pit.thermo_relief",
    "priority": 123,
    "pit_form": pit_form,
    "thermo_expense_type": "HEATING_SYSTEM",
    "thermo_is_qualifying": is_qualifying,
    "thermo_expense_amount": expense_amount,
    "thermo_heating_type": heating_type,
    "_routing": thermo_rt,
    "_routing_reason": sprintf("System grzewczy (%s): %.2f PLN — %s", [heating_type, expense_amount, qualifying_msg]),
    "_legal_basis": "Art. 26h ust. 3 pkt 3-5 PIT",
    "_warnings": [sprintf("System grzewczy (%s) — %.2f PLN. UWAGA: kocioł na węgiel NIE kwalifikuje się od 2024! Tylko: pompa ciepła, kocioł gazowy kondensacyjny, pellet klasy 5, przyłącze ciepłownicze.",
        [heating_type, expense_amount])]
} {
    input.thermo_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    heating_type := object.get(input.invoice, "thermo_heating_type", "")
    qualifying_heating := {"HEAT_PUMP", "CONDENSING_GAS_BOILER", "BIOMASS_PELLET_CLASS5", "DISTRICT_HEATING_CONNECTION", "SOLAR_THERMAL"}
    heating_type in qualifying_heating
    expense_amount := object.get(input.invoice, "amount_net", 0)
    has_vat_invoice := object.get(input.invoice, "is_vat_invoice_from_active_vat_payer", false)

    is_coal := heating_type == "COAL_BOILER"
    is_qualifying := expense_amount > 0 and has_vat_invoice and not is_coal
    qualifying_msg = "KWALIFIKUJE SIĘ" { is_qualifying }
    qualifying_msg = "NIE kwalifikuje — kocioł węglowy wykluczony od 2024" { is_coal }

    thermo_rt = "BLOCK_AND_ALERT" { is_coal; expense_amount > 0 }
    thermo_rt = "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R124: thermo_qualifying_expenses_solar_pv — Fotowoltaika
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.thermo.qualifying_solar_pv",
    "package": "jdg.pit.thermo_relief",
    "priority": 124,
    "pit_form": pit_form,
    "thermo_expense_type": "PHOTOVOLTAIC",
    "thermo_is_qualifying": is_qualifying,
    "thermo_expense_amount": expense_amount,
    "_routing": "",
    "_routing_reason": sprintf("Fotowoltaika: %.2f PLN — %s", [expense_amount, qualifying_msg]),
    "_legal_basis": "Art. 26h ust. 3 pkt 6 PIT (odnawialne źródła energii)",
    "_warnings": [sprintf("Fotowoltaika — %.2f PLN. Kwalifikuje się do ulgi. UWAGA: jeśli korzystasz z dotacji 'Mój Prąd'/'Czyste Powietrze', odliczasz TYLKO wydatki ponad dotację! Nie podwójne odliczenie.",
        [expense_amount])]
} {
    input.thermo_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    expense_type := object.get(input.invoice, "thermo_expense_type", "")
    expense_type == "PHOTOVOLTAIC"
    expense_amount := object.get(input.invoice, "amount_net", 0)
    has_vat_invoice := object.get(input.invoice, "is_vat_invoice_from_active_vat_payer", false)
    gov_subsidy := object.get(input.invoice, "government_subsidy_amount", 0)

    # Tylko wydatki ponad dotację
    net_expense := expense_amount - gov_subsidy
    is_qualifying := net_expense > 0 and has_vat_invoice
    qualifying_msg = "KWALIFIKUJE SIĘ (kwota netto po odjęciu dotacji)" { is_qualifying }
    qualifying_msg = "NIE kwalifikuje — dotacja pokrywa całość" { not is_qualifying; gov_subsidy >= expense_amount }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R125: thermo_qualifying_expenses_ventilation — Wentylacja i rekuperacja
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.thermo.qualifying_ventilation",
    "package": "jdg.pit.thermo_relief",
    "priority": 125,
    "pit_form": pit_form,
    "thermo_expense_type": "VENTILATION",
    "thermo_is_qualifying": is_qualifying,
    "thermo_expense_amount": expense_amount,
    "_routing": "",
    "_routing_reason": sprintf("Wentylacja/rekuperacja: %.2f PLN — %s", [expense_amount, qualifying_msg]),
    "_legal_basis": "Art. 26h ust. 3 pkt 4 PIT (systemy wentylacji mechanicznej z odzyskiem ciepła)",
    "_warnings": [sprintf("Wentylacja mechaniczna z rekuperacją — %.2f PLN. Kwalifikuje się do ulgi. Wymagana dokumentacja techniczna projektowa.",
        [expense_amount])]
} {
    input.thermo_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    expense_type := object.get(input.invoice, "thermo_expense_type", "")
    expense_type in {"MECHANICAL_VENTILATION_RECUPERATION", "HEAT_RECOVERY_SYSTEM"}
    expense_amount := object.get(input.invoice, "amount_net", 0)
    has_vat_invoice := object.get(input.invoice, "is_vat_invoice_from_active_vat_payer", false)

    is_qualifying := expense_amount > 0 and has_vat_invoice
    qualifying_msg = "KWALIFIKUJE SIĘ" { is_qualifying }
    qualifying_msg = "NIE kwalifikuje" { not is_qualifying }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R126: thermo_aggregate_limit — Łączny limit 53 000 PLN per podatnik
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.thermo.aggregate_limit_53k",
    "package": "jdg.pit.thermo_relief",
    "priority": 126,
    "pit_form": pit_form,
    "thermo_annual_total_pln": annual_total,
    "thermo_limit_pln": 53000,
    "thermo_deductible_pln": deductible,
    "thermo_excess_pln": excess,
    "thermo_excess_note": excess_note,
    "_routing": thermo_rt,
    "_routing_reason": sprintf("Limit termo: %.2f PLN wykorzystane z 53 000 PLN. Do odliczenia: %.2f PLN. Nadwyżka: %.2f PLN.", [annual_total, deductible, excess]),
    "_legal_basis": "Art. 26h ust. 1 PIT (limit 53 000 PLN)",
    "_warnings": [sprintf("ŁĄCZNY LIMIT TERMOMODERNIZACJI: %.2f PLN z 53 000 PLN. Odliczasz: %.2f PLN. %s. PAMIĘTAJ: limit 53k jest NA PODATNIKA (nie na budynek). Małżonkowie osobno wykorzystują swoje limity!",
        [annual_total, deductible, excess_note])]
} {
    input.thermo_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    annual_total := object.get(input.jdg_entrepreneur, "thermo_expenses_annual_total", 0)
    deductible := min([annual_total, 53000])
    excess := max([annual_total - 53000, 0])
    excess_note = sprintf("Nadwyżka %.2f PLN PRZEPADA — nie przechodzi na kolejne lata!", [excess]) { excess > 0 }
    excess_note = "OK — w limicie" { excess == 0 }

    thermo_rt = "BLOCK_AND_ALERT" { excess > 10000 }
    thermo_rt = "TRIAGE_QUEUE" { excess > 0; excess <= 10000 }
    thermo_rt = "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R127: thermo_vat_invoice_requirement — Wymóg faktury VAT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.thermo.vat_invoice_missing",
    "package": "jdg.pit.thermo_relief",
    "priority": 127,
    "pit_form": pit_form,
    "thermo_invoice_valid": false,
    "thermo_invoice_issue": "BRAK FAKTURY VAT od czynnego podatnika VAT",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Brak faktury VAT — wydatek NIE kwalifikuje się do ulgi termomodernizacyjnej!",
    "_legal_basis": "Art. 26h ust. 7 PIT (wymóg faktury VAT)",
    "_warnings": [sprintf("BRAK FAKTURY VAT! Wydatek %.2f PLN na %s NIE kwalifikuje się do ulgi termomodernizacyjnej. Wymagana faktura VAT wystawiona przez czynnego podatnika VAT. Paragon, rachunek uproszczony, faktura od zwolnionego z VAT — NIE wystarczają!",
        [expense_amount, expense_desc])]
} {
    input.thermo_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    expense_amount := object.get(input.invoice, "amount_net", 0)
    expense_desc := object.get(input.invoice, "thermo_expense_type", "nieznany")
    expense_amount > 0
    input.invoice.is_vat_invoice_from_active_vat_payer == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# R128: thermo_three_year_deadline — Termin 3 lata od pierwszej faktury
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.thermo.three_year_deadline",
    "package": "jdg.pit.thermo_relief",
    "priority": 128,
    "pit_form": pit_form,
    "thermo_first_invoice_date": first_date,
    "thermo_deadline_date": deadline,
    "thermo_days_remaining": days_remaining,
    "thermo_deadline_exceeded": deadline_exceeded,
    "_routing": thermo_rt,
    "_routing_reason": sprintf("Termin 3-letni: pierwsza faktura %s, deadline %s. Pozostało: %d dni. %s",
        [first_date, deadline, days_remaining, deadline_msg]),
    "_legal_basis": "Art. 26h ust. 9 PIT (termin 3 lat)",
    "_warnings": [sprintf("TERMIN 3-LETNI — Pierwsza faktura: %s. Deadline: %s (3 lata). %s. Wszystkie wydatki muszą być poniesione w ciągu 3 lat od pierwszej faktury! Po terminie — ulga PRZEPADA dla pozostałych wydatków.",
        [first_date, deadline, deadline_msg])]
} {
    input.thermo_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    first_date := object.get(input.jdg_entrepreneur, "thermo_first_invoice_date", "2026-01-01")
    current_date := object.get(input, "evaluation_date", "2026-07-25")

    # Parse dates and compute 3-year deadline
    first_year := to_number(substring(first_date, 0, 4))
    deadline_year := first_year + 3
    deadline := sprintf("%d%s", [deadline_year, substring(first_date, 4, 6)])

    days_remaining := 0
    deadline_exceeded := current_date > deadline
    days_remaining := 365 * (deadline_year - to_number(substring(current_date, 0, 4)))
    deadline_msg = "TERMIN PRZEKROCZONY — nie możesz już odliczać nowych wydatków!" { deadline_exceeded }
    deadline_msg = sprintf("OK — jeszcze %d dni na poniesienie wydatków", [days_remaining]) { not deadline_exceeded }

    thermo_rt = "BLOCK_AND_ALERT" { deadline_exceeded }
    thermo_rt = "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R129: thermo_no_double_deduction — Wykluczenie podwójnego odliczenia
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.thermo.no_double_deduction",
    "package": "jdg.pit.thermo_relief",
    "priority": 129,
    "pit_form": pit_form,
    "thermo_double_deduction_risk": true,
    "thermo_other_program": other_program,
    "thermo_warning": "PODWÓJNE ODLICZENIE — wydatek już odliczony w innym programie!",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Podwójne odliczenie: wydatek już odliczony w programie '%s'!", [other_program]),
    "_legal_basis": "Art. 26h ust. 8 PIT (zakaz podwójnego odliczenia)",
    "_warnings": [sprintf("ZAKAZ PODWÓJNEGO ODLICZENIA! Wydatek %.2f PLN na %s został już odliczony w programie '%s'. NIE możesz go ponownie odliczyć w uldze termomodernizacyjnej. Odlicz TYLKO nadwyżkę ponad dotację!",
        [expense_amount, expense_desc, other_program])]
} {
    input.thermo_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    already_deducted_elsewhere := object.get(input.invoice, "already_deducted_in_other_program", false)
    already_deducted_elsewhere == true
    other_program := object.get(input.invoice, "other_deduction_program", "Czyste Powietrze")
    expense_amount := object.get(input.invoice, "amount_net", 0)
    expense_desc := object.get(input.invoice, "thermo_expense_type", "termomodernizacja")
}

# ═══════════════════════════════════════════════════════════════════════════════
# NO-MATCH (R04 P1: stub { true } usunięty — nie generuje fałszywego matched:true)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": false,
    "rule_id": "jdg.pit.thermo_relief.no_match",
    "package": "jdg.pit.thermo_relief",
    "priority": 999,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 26h PIT"
} {
    false
}
