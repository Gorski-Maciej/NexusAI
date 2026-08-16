# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P16 AUTO-FORM GENERATOR ENTERPRISE (Strategic Initiative G1-G5)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Auto-Form Generator — CEIDG-1, ZUS ZUA/ZWUA, VAT-Z, PIT-4R/11
# description: |
#   ENTERPRISE v8.0 — Automatyczne wypełnianie formularzy rejestracyjnych i zgłoszeniowych.
#   Wypełnia krytyczne luki zidentyfikowane w RAPORT_P16_JDG_BUSINESS_LIFECYCLE_v7.0:
#   - G1: CEIDG-1 Auto-Fill Engine (rejestracja, zmiana, zawieszenie, wykreślenie)
#   - G2: ZUS ZUA Auto-Fill (zgłoszenie do ubezpieczeń — kod 05 10/05 12)
#   - G3: ZUS ZWUA Auto-Fill (wyrejestrowanie z ubezpieczeń)
#   - G4: VAT-Z Auto-Fill (wyrejestrowanie z VAT)
#   - G5: PIT-4R / PIT-11 Auto-Fill (deklaracje pracownicze)
#   - G6: Notarial Deed Template (akt notarialny dla sukcesji)
#   - G7: Receipt/Note Generator (kwity dla działalności nierejestrowanej)
# architecture: Auto-Generation Engine, First-Match-Wins else-chain
# legal_basis: Prawo Przedsiębiorców; SUS; VAT; Kodeks Pracy; Ustawa o zarządzie sukcesyjnym
# package: jdg.autoform
# deprecated: false
# priority_range: 8000-8099
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.autoform

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false, "rule_id": "jdg.autoform.no_match", "_legal_basis": "ustawa o CEIDG (Dz.U. 2024 poz. 1228 ze zm.)",
    "valid_from":"2024-01-01","valid_to":"9999-12-31","temporal_source":"Ustawa z dnia 26 lipca 1991 r. o podatku dochodowym od osob fizycznych"
    "package": "jdg.autoform", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# G1: CEIDG-1 AUTO-FILL ENGINE — Rejestracja, zmiana, zawieszenie, wykreślenie
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    object.get(input.jdg_entrepreneur, "autoform_ceidg1", false) == true

    first_name := object.get(input.jdg_entrepreneur, "first_name", "")
    last_name := object.get(input.jdg_entrepreneur, "last_name", "")
    pesel := object.get(input.jdg_entrepreneur, "pesel", "")
    nip := object.get(input.jdg_entrepreneur, "nip", "")
    pkd_main := object.get(input.jdg_entrepreneur, "pkd_main_code", "")
    pkd_additional := object.get(input.jdg_entrepreneur, "pkd_additional_codes", [])
    business_address := object.get(input.jdg_entrepreneur, "business_address", "")
    mailing_address := object.get(input.jdg_entrepreneur, "mailing_address", business_address)
    tax_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    vat_registration_planned := object.get(input.jdg_entrepreneur, "vat_registration_planned", false)
    bank_account := object.get(input.jdg_entrepreneur, "bank_account_nrb", "")
    planned_start_date := object.get(input.jdg_entrepreneur, "ceidg_planned_start_date", "")
    is_suspension_resume := object.get(input.jdg_entrepreneur, "ceidg_resume_from_suspension", false)
    is_closure := object.get(input.jdg_entrepreneur, "ceidg_closure_request", false)
    is_data_change := object.get(input.jdg_entrepreneur, "ceidg_data_change", false)
    change_description := object.get(input.jdg_entrepreneur, "ceidg_change_description", "")

    # Określ typ wniosku CEIDG-1
    ceidg_form_type := "WNIOSEK O WPIS" { not is_data_change; not is_closure; not is_suspension_resume }
    ceidg_form_type := "WNIOSEK O ZMIANĘ WPISU" { is_data_change }
    ceidg_form_type := "WNIOSEK O WYKREŚLENIE" { is_closure }
    ceidg_form_type := "WNIOSEK O WZNOWIENIE" { is_suspension_resume }

    # Kod ZUS
    zus_code := "05 10" { not is_suspension_resume; ceidg_form_type == "WNIOSEK O WPIS" }
    zus_code := "05 12" { is_suspension_resume }
    zus_code := "" { is_closure }

    # Zbuduj kompletny formularz CEIDG-1
    ceidg_sections := {
        "A_DANE_WNIOSKODAWCY": {
            "imie": first_name,
            "nazwisko": last_name,
            "pesel": pesel,
            "nip": nip,
            "kod_kraju_urodzenia": object.get(input.jdg_entrepreneur, "birth_country_code", "PL"),
            "obywatelstwo": object.get(input.jdg_entrepreneur, "citizenship", "PL")
        },
        "B_ADRES": {
            "adres_zamieszkania": object.get(input.jdg_entrepreneur, "home_address", ""),
            "adres_prowadzenia_dzialalnosci": business_address,
            "adres_korespondencyjny": mailing_address,
            "adres_przechowywania_dokumentacji": object.get(input.jdg_entrepreneur, "document_storage_address", business_address)
        },
        "C_DZIALALNOSC": {
            "data_rozpoczecia": planned_start_date,
            "pkd_glowne": pkd_main,
            "pkd_dodatkowe": pkd_additional,
            "nazwa_skrocona": sprintf("%s %s", [first_name, last_name]),
            "forma_wykonywania": "INDYWIDUALNA"
        },
        "D_OPODATKOWANIE": {
            "forma_opodatkowania": tax_form,
            "opodatkowanie_karta_podatkowa": false { tax_form != "TAX_CARD" },
            "podatkowa_ksiega_przychodow": true { tax_form != "LUMP_SUM" }
        },
        "E_UBEZPIECZENIA": {
            "kod_zus": zus_code,
            "ubezpieczenie_zdrowotne_obowiazkowe": true,
            "fundusz_pracy": true { zus_code != "" },
            "ubezpieczenie_chorobowe_dobrowolne": object.get(input.jdg_entrepreneur, "sickness_insurance_voluntary", true)
        },
        "F_VAT": {
            "rejestracja_vat": vat_registration_planned,
            "vat_zwolnienie_podmiotowe": not vat_registration_planned
        },
        "G_RACHUNEK_BANKOWY": {
            "numer_rachunku": bank_account,
            "bank_nazwa": object.get(input.jdg_entrepreneur, "bank_name", "")
        },
        "H_OSWIADCZENIA": [
            "Nie jestem wpisany/a do CEIDG pod innym numerem",
            "Nie jestem ubezpieczony/a w KRUS",
            "Spełniam warunki określone w Prawie Przedsiębiorców",
            "Dane zawarte we wniosku są zgodne ze stanem faktycznym",
            "Jestem świadomy/a odpowiedzialności karnej za podanie fałszywych danych"
        ]
    }

    # Sprawdź kompletność
    missing_fields := []
    missing_fields := array.concat(missing_fields, ["imię"]) { first_name == "" }
    missing_fields := array.concat(missing_fields, ["nazwisko"]) { last_name == "" }
    missing_fields := array.concat(missing_fields, ["PESEL"]) { pesel == "" }
    missing_fields := array.concat(missing_fields, ["PKD główne"]) { pkd_main == "" }
    missing_fields := array.concat(missing_fields, ["adres działalności"]) { business_address == "" }
    missing_fields := array.concat(missing_fields, ["data rozpoczęcia"]) { planned_start_date == ""; not is_closure; not is_data_change }

    form_ready := count(missing_fields) == 0

    # Wygeneruj tekstową reprezentację CEIDG-1
    vat_note := "TAK (VAT-R)" { vat_registration_planned }
    vat_note := "ZWO (art. 113)" { not vat_registration_planned }

    ceidg_draft := sprintf("CEIDG-1: %s\nA. %s %s (PESEL: %s, NIP: %s)\nB. Adres: %s\nC. PKD: %s, Start: %s\nD. Forma PIT: %s\nE. ZUS: %s\nF. VAT: %s\nG. Konto: %s",
        [ceidg_form_type, first_name, last_name, pesel, nip, business_address, pkd_main, planned_start_date, tax_form, zus_code,
         vat_note, bank_account])

    routing := "TRIAGE_QUEUE" { form_ready }
    routing := "BLOCK_AND_ALERT" { not form_ready }

    verdict := {
        "matched": true,
        "rule_id": "jdg.autoform.ceidg1_autofill",
        "_legal_basis": "ustawa o CEIDG (Dz.U. 2024 poz. 1228 ze zm.)",
        "package": "jdg.autoform",
        "priority": 8000,
        "action": "GENERATE_CEIDG1_FORM",
        "autoform_ceidg_type": ceidg_form_type,
        "autoform_ceidg_sections": ceidg_sections,
        "autoform_ceidg_draft_text": ceidg_draft,
        "autoform_ceidg_ready": form_ready,
        "autoform_ceidg_missing_fields": missing_fields,
        "autoform_ceidg_zus_deadline_days": 7,
        "autoform_ceidg_pit_form_deadline": "20. dzień po pierwszym przychodzie",
        "legal_basis": "Art. 5-7 Ustawy o CEIDG; Prawo Przedsiębiorców; Art. 43 SUS; Art. 96 VAT",
        "_routing": routing,
        "_routing_reason": sprintf("CEIDG-1: %s — %s", [ceidg_form_type, form_ready && "✅ GOTOWY" || sprintf("❌ BRAKUJE: %s", [concat(", ", missing_fields)])]),
        "_warnings": [sprintf("📝 G1 AUTO-FORM CEIDG-1: %s\n   %s\n   %s",
            [ceidg_form_type,
             form_ready && "✅ Wszystkie pola wypełnione — gotowe do złożenia!" || sprintf("❌ Brakujące pola: %s", [concat(", ", missing_fields)]),
             sprintf("⚠️ Kluczowe terminy: ZUS ZUA 7 dni | %s zmiany CEIDG 7 dni | VAT-R przed transakcją", [is_closure && "Wykreślenie CEIDG" || "Aktualizacja"])])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# G2: ZUS ZUA AUTO-FILL — Zgłoszenie do ubezpieczeń (kod 05 10 / 05 12)
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "autoform_zus_zua", false) == true

    first_name := object.get(input.jdg_entrepreneur, "first_name", "")
    last_name := object.get(input.jdg_entrepreneur, "last_name", "")
    pesel := object.get(input.jdg_entrepreneur, "pesel", "")
    nip := object.get(input.jdg_entrepreneur, "nip", "")
    birth_date := object.get(input.jdg_entrepreneur, "birth_date", "")
    is_entrepreneur := object.get(input.jdg_entrepreneur, "business_type", "JDG") == "JDG"
    is_employee := object.get(input.jdg_entrepreneur, "autoform_zua_for_employee", false)
    employee_first_name := object.get(input.jdg_entrepreneur, "employee_first_name", "")
    employee_last_name := object.get(input.jdg_entrepreneur, "employee_last_name", "")
    employee_pesel := object.get(input.jdg_entrepreneur, "employee_pesel", "")
    salary_gross := object.get(input.jdg_entrepreneur, "employee_salary_gross", 4800)
    contract_start_date := object.get(input.jdg_entrepreneur, "employee_start_date", "")
    zus_code := "05 10" { is_entrepreneur; not is_employee }
    zus_code := "05 12" { is_entrepreneur; object.get(input.jdg_entrepreneur, "ceidg_resume_from_suspension", false) }
    zus_code := "01 10" { is_employee }

    target_person := {
        "imie": is_employee && employee_first_name || first_name,
        "nazwisko": is_employee && employee_last_name || last_name,
        "pesel": is_employee && employee_pesel || pesel,
        "data_urodzenia": is_employee && object.get(input.jdg_entrepreneur, "employee_birth_date", "") || birth_date
    }

    # Kod tytułu ubezpieczenia
    insurance_components := {
        "emerytalne": true,
        "rentowe": true,
        "chorobowe": object.get(input.jdg_entrepreneur, "sickness_insurance_voluntary", true) { not is_employee },
        "chorobowe": true { is_employee },
        "wypadkowe": true,
        "zdrowotne": true,
        "fundusz_pracy": true,
        "fgsp": true
    }

    # Podstawa wymiaru składek
    base_amount := salary_gross { is_employee }
    base_amount := 0 { not is_employee; object.get(input.jdg_entrepreneur, "zus_status", "STANDARD") == "START_RELIEF" }
    base_amount := floor(4800 * 0.30 * 100) / 100 { not is_employee; object.get(input.jdg_entrepreneur, "zus_status", "STANDARD") == "PREFERENTIAL" }
    base_amount := floor(4800 * 0.60 * 100) / 100 { not is_employee }

    zus_zua_form := {
        "form_type": "ZUS ZUA",
        "target": target_person,
        "kod_tytulu_ubezpieczenia": zus_code,
        "data_zgloszenia": contract_start_date { is_employee },
        "data_zgloszenia": object.get(input.jdg_entrepreneur, "ceidg_planned_start_date", "") { not is_employee },
        "ubezpieczenia": insurance_components,
        "podstawa_wymiaru_pln": base_amount,
        "nip_platnika": nip,
        "deadline_dni": 7,
        "deadline_podstawa_prawna": "Art. 43 SUS"
    }

    deadlines := {
        "entrepreneur_zua": "7 dni od wpisu CEIDG",
        "employee_zua": "7 dni od rozpoczęcia pracy",
        "health_deadline": "do 15. dnia następnego miesiąca — pierwsza składka"
    }

    verdict := {
        "matched": true,
        "rule_id": "jdg.autoform.zus_zua_autofill",
        "_legal_basis": "ustawa o CEIDG (Dz.U. 2024 poz. 1228 ze zm.)",
        "package": "jdg.autoform",
        "priority": 8010,
        "action": "GENERATE_ZUS_ZUA",
        "autoform_zus_zua_data": zus_zua_form,
        "autoform_zus_zua_deadlines": deadlines,
        "autoform_zus_zua_for_whom": is_employee && "PRACOWNIK" || "JDG PRZEDSIĘBIORCA",
        "autoform_zus_zua_deadline_days": 7,
        "legal_basis": "Art. 43 SUS; Art. 36 ust. 1, 4 SUS",
        "_routing": "TRIAGE_QUEUE",
        "_routing_reason": sprintf("ZUS ZUA: %s (kod %s) — złóż w 7 dni!", [zus_zua_form.target.imie, zus_code]),
        "_warnings": [sprintf("📋 G2 AUTO-FORM ZUS ZUA: Zgłoszenie %s %s (PESEL: %s, kod: %s)\n   Podstawa: %.2f PLN | Termin: 7 dni od %s\n   ⚠️ Kluczowe: ubezpieczenie zdrowotne obowiązkowe!",
            [target_person.imie, target_person.nazwisko, target_person.pesel, zus_code, base_amount,
             is_employee && "rozpoczęcia pracy" || "wpisu CEIDG"])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# G3: ZUS ZWUA AUTO-FILL — Wyrejestrowanie z ubezpieczeń
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "autoform_zus_zwua", false) == true

    pesel := object.get(input.jdg_entrepreneur, "pesel", "")
    nip := object.get(input.jdg_entrepreneur, "nip", "")
    closure_date := object.get(input.jdg_entrepreneur, "business_closure_date", "")
    is_employee_termination := object.get(input.jdg_entrepreneur, "autoform_zwua_employee", false)
    employee_pesel := object.get(input.jdg_entrepreneur, "employee_pesel", "")
    termination_date := object.get(input.jdg_entrepreneur, "employee_termination_date", "")

    zus_zwua_form := {
        "form_type": "ZUS ZWUA",
        "nip_platnika": nip,
        "pesel_ubezpieczonego": is_employee_termination && employee_pesel || pesel,
        "data_wyrejestrowania": is_employee_termination && termination_date || closure_date,
        "kod_tytulu": is_employee_termination && "01 10" || "05 10",
        "przyczyna_wyrejestrowania": is_employee_termination && "ROZWIAZANIE UMOWY" || "LIKWIDACJA_JDG",
        "deadline_dni": 7,
        "deadline_podstawa_prawna": "Art. 43 SUS",
        "konsekwencje_nieterminowego": "Brak ubezpieczenia zdrowotnego od daty wyrejestrowania + możliwość kary"
    }

    # G3 verdict
    zus_deadline_horizon := termination_date { is_employee_termination }
    zus_deadline_horizon := closure_date { not is_employee_termination }

    verdict := {
        "matched": true,
        "rule_id": "jdg.autoform.zus_zwua_autofill",
        "_legal_basis": "ustawa o CEIDG (Dz.U. 2024 poz. 1228 ze zm.)",
        "package": "jdg.autoform",
        "priority": 8020,
        "action": "GENERATE_ZUS_ZWUA",
        "autoform_zus_zwua_data": zus_zwua_form,
        "autoform_zus_zwua_deadline_days": 7,
        "legal_basis": "Art. 43 SUS; Art. 36 ust. 9-11 SUS",
        "_routing": "TRIAGE_QUEUE",
        "_routing_reason": sprintf("ZUS ZWUA: wyrejestrowanie %s z dniem %s", [zus_zwua_form.przyczyna_wyrejestrowania, zus_deadline_horizon]),
        "_warnings": [sprintf("📋 G3 AUTO-FORM ZUS ZWUA: Wyrejestrowanie — %s\n   Data: %s | Termin: 7 dni\n   ⚠️ Po wyrejestrowaniu UTRATA ubezpieczenia zdrowotnego!", [zus_zwua_form.przyczyna_wyrejestrowania, zus_zwua_form.data_wyrejestrowania])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# G4: VAT-Z AUTO-FILL — Wyrejestrowanie z VAT
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "autoform_vat_z", false) == true

    nip := object.get(input.jdg_entrepreneur, "nip", "")
    first_name := object.get(input.jdg_entrepreneur, "first_name", "")
    last_name := object.get(input.jdg_entrepreneur, "last_name", "")
    vat_closure_date := object.get(input.jdg_entrepreneur, "vat_closure_date", "")
    inventory_remnant_value := object.get(input.jdg_entrepreneur, "inventory_remnant_value", 0)
    has_remnant_vat := inventory_remnant_value > 0
    remnant_vat := floor(inventory_remnant_value * 0.23 * 100) / 100

    vat_z_form := {
        "form_type": "VAT-Z",
        "nip": nip,
        "nazwa_podatnika": sprintf("%s %s", [first_name, last_name]),
        "data_zaprzestania": vat_closure_date,
        "przyczyna": "LIKWIDACJA_DZIALALNOSCI",
        "ostatnia_deklaracja_vat7": sprintf("miesiąc poprzedzający %s", [vat_closure_date]),
        "remanent_likwidacyjny_pln": inventory_remnant_value,
        "vat_od_remanentu_pln": remnant_vat { has_remnant_vat },
        "vat_od_remanentu_pln": 0 { not has_remnant_vat },
        "termin_zlozenia": sprintf("przed dniem %s", [vat_closure_date]),
        "konsekwencje": "Obowiązek zapłaty VAT od remanentu w terminie 14 dni + złożenie ostatniego JPK_V7M"
    }

    verdict := {
        "matched": true,
        "rule_id": "jdg.autoform.vat_z_autofill",
        "_legal_basis": "ustawa o CEIDG (Dz.U. 2024 poz. 1228 ze zm.)",
        "package": "jdg.autoform",
        "priority": 8030,
        "action": "GENERATE_VAT_Z",
        "autoform_vat_z_data": vat_z_form,
        "autoform_vat_z_remnant_pln": inventory_remnant_value,
        "autoform_vat_z_remnant_vat_23pct_pln": remnant_vat,
        "autoform_vat_z_deadline": sprintf("przed dniem zaprzestania czynności: %s", [vat_closure_date]),
        "legal_basis": "Art. 96 ust. 6-7 VAT; Art. 14 VAT (remanent likwidacyjny)",
        "_routing": "TRIAGE_QUEUE" { has_remnant_vat },
        "_routing": "" { true },
        "_routing_reason": sprintf("VAT-Z: %s — VAT od remanentu %.2f PLN (23%%)", [vat_z_form.przyczyna, remnant_vat]) { has_remnant_vat },
        "_routing_reason": "VAT-Z: wyrejestrowanie bez remanentu" { not has_remnant_vat },
        "_warnings": [sprintf("📋 G4 AUTO-FORM VAT-Z: Wyrejestrowanie VAT dla %s %s (NIP: %s)\n   Data: %s | %s\n   ⚠️ Ostatni JPK_V7M + zapłata VAT od remanentu!",
            [first_name, last_name, nip, vat_closure_date,
             has_remnant_vat && sprintf("Remanent: %.2f PLN → VAT 23%%: %.2f PLN", [inventory_remnant_value, remnant_vat]) || "Brak remanentu"])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# G5: PIT-4R / PIT-11 AUTO-FILL — Deklaracje pracownicze
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "autoform_pit_employee", false) == true

    employee_name := object.get(input.jdg_entrepreneur, "employee_name", "")
    employee_pesel := object.get(input.jdg_entrepreneur, "employee_pesel", "")
    salary_gross := object.get(input.jdg_entrepreneur, "employee_salary_gross", 4800)
    tax_month := object.get(input.jdg_entrepreneur, "employee_tax_month", 1)
    tax_year := object.get(input.jdg_entrepreneur, "employee_tax_year", 2026)
    nip := object.get(input.jdg_entrepreneur, "nip", "")
    is_annual := object.get(input.jdg_entrepreneur, "autoform_pit11_annual", false)
    form_type_employee := "PIT-11" { is_annual }
    form_type_employee := "PIT-4R" { not is_annual }

    # Obliczenia wynagrodzenia
    zus_employee_pct := 0.1371  # 9.76% + 1.5% + 2.45%
    zus_employee := floor(salary_gross * zus_employee_pct * 100) / 100
    health_base := salary_gross - zus_employee
    health_paid := floor(health_base * 0.09 * 100) / 100
    health_deductible := floor(health_base * 0.0775 * 100) / 100
    tax_base := floor((salary_gross - zus_employee - 250) * 100) / 100  # KUP 250 PLN
    tax_advance := floor(tax_base * 0.12 * 100) / 100 { tax_base <= 120000 }
    tax_advance := floor((tax_base * 0.12 + max([tax_base - 120000, 0]) * 0.32) * 100) / 100 { tax_base > 120000 }
    tax_advance := floor((tax_advance - health_deductible) * 100) / 100
    tax_advance := max([tax_advance, 0])
    net_salary := floor((salary_gross - zus_employee - health_paid - tax_advance) * 100) / 100

    # ZUS pracodawcy
    employer_zus := floor(salary_gross * 0.205 * 100) / 100
    total_employer_cost := floor((salary_gross + employer_zus) * 100) / 100

    pit_form_data := {
        "form_type": form_type_employee,
        "rok": tax_year,
        "miesiac": tax_month { not is_annual },
        "platnik_nip": nip,
        "platnik_nazwa": object.get(input.jdg_entrepreneur, "business_name", "JDG"),
        "pracownik_imie_nazwisko": employee_name,
        "pracownik_pesel": employee_pesel,
        "przychod_brutto": salary_gross,
        "skladki_spoleczne_pracownik": zus_employee,
        "skladki_zdrowotne_pobrane": health_paid,
        "skladki_zdrowotne_odliczone": health_deductible,
        "zaliczka_pit": tax_advance,
        "wynagrodzenie_netto": net_salary,
        "koszt_pracodawcy_calkowity": total_employer_cost,
        "koszt_pracodawcy_zus": employer_zus,
        "termin_zlozenia": is_annual && "do 31 stycznia" || sprintf("do 20.%02d.%d", [tax_month + 1, tax_year])
    }

    # Deadline
    deadline_annual := sprintf("do 31.01.%d", [tax_year + 1])
    deadline_monthly := sprintf("do 20.%02d.%d", [tax_month + 1, tax_year])
    deadline := deadline_monthly { not is_annual }
    deadline := deadline_annual { is_annual }

    routing := "TRIAGE_QUEUE" { tax_advance > 0 }
    routing := "" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.autoform.pit_employee_autofill",
        "_legal_basis": "ustawa o CEIDG (Dz.U. 2024 poz. 1228 ze zm.)",
        "package": "jdg.autoform",
        "priority": 8040,
        "action": "GENERATE_PIT_EMPLOYEE",
        "autoform_pit_employee_type": form_type_employee,
        "autoform_pit_employee_data": pit_form_data,
        "autoform_pit_employee_deadline": deadline,
        "autoform_pit_employee_net_salary_pln": net_salary,
        "autoform_pit_employee_employer_total_cost_pln": total_employer_cost,
        "legal_basis": "Art. 32, 38, 39 PIT; Art. 42 PIT",
        "_routing": routing,
        "_routing_reason": sprintf("%s: %s — zaliczka %.2f PLN / netto %.2f PLN",
            [form_type_employee, employee_name, tax_advance, net_salary]),
        "_warnings": [sprintf("📋 G5 AUTO-FORM %s: Pracownik %s (PESEL: %s)\n   Brutto: %.2f PLN | Netto: %.2f PLN | Zaliczka PIT: %.2f PLN\n   Koszt pracodawcy: %.2f PLN/mies. | Termin: %s\n   ⚠️ PPK, PFRON, badania BHP — dodatkowe obowiązki!",
            [form_type_employee, employee_name, employee_pesel, salary_gross, net_salary, tax_advance, total_employer_cost, deadline])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# G6: NOTARIAL DEED TEMPLATE — Akt notarialny zarządcy sukcesyjnego
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "autoform_notarial_deed", false) == true

    business_owner_name := object.get(input.jdg_entrepreneur, "business_owner_name", "")
    business_owner_pesel := object.get(input.jdg_entrepreneur, "pesel", "")
    manager_name := object.get(input.jdg_entrepreneur, "succession_manager_name", "")
    manager_pesel := object.get(input.jdg_entrepreneur, "succession_manager_pesel", "")
    business_name := object.get(input.jdg_entrepreneur, "business_name", "")
    nip := object.get(input.jdg_entrepreneur, "nip", "")
    notary_name := object.get(input.jdg_entrepreneur, "notary_name", "[IMIĘ I NAZWISKO NOTARIUSZA]")
    notary_city := object.get(input.jdg_entrepreneur, "notary_city", "[MIASTO]")

    deed_sections := [
        sprintf("AKT NOTARIALNY — POWOŁANIE ZARZĄDCY SUKCESYJNEGO"),
        sprintf("Rep. A nr [NUMER]/%d", [2026]),
        "",
        "Dnia [DATA] w [MIEJSCOWOŚĆ] przed notariuszem [IMIĘ NOTARIUSZA] stawił się:",
        sprintf("   %s, PESEL: %s, zam. [ADRES] (dalej: 'Przedsiębiorca')", [business_owner_name, business_owner_pesel]),
        "",
        "§1. PRZEDMIOT",
        sprintf("Przedsiębiorca prowadzi działalność gospodarczą pod firmą '%s' (NIP: %s),", [business_name, nip]),
        "wpisaną do CEIDG, i niniejszym aktem notarialnym powołuje zarządcę sukcesyjnego",
        sprintf("w osobie: %s, PESEL: %s (dalej: 'Zarządca'),", [manager_name, manager_pesel]),
        "na wypadek śmierci Przedsiębiorcy, zgodnie z ustawą z dnia 5 lipca 2018 r.",
        "o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2018 poz. 1703).",
        "",
        "§2. ZAKRES UPRAWNIEŃ",
        "Zarządca sukcesyjny uprawniony jest do:",
        "   a) prowadzenia przedsiębiorstwa w spadku pod dotychczasową firmą z dopiskiem 'w spadku',",
        "   b) dokonywania czynności zwykłego zarządu i czynności przekraczających zwykły zarząd,",
        "   c) reprezentowania przedsiębiorstwa przed organami administracji, sądami i kontrahentami,",
        "   d) składania deklaracji podatkowych i ZUS za zmarłego przedsiębiorcę,",
        "   e) dostępu do rachunków bankowych i dokonywania płatności.",
        "",
        "§3. TERMINY",
        "   - Zarządca działa od chwili śmierci Przedsiębiorcy do 2 lat (Art. 49 ust. 1 u.z.s.)",
        "   - Wpis do CEIDG: 14 dni od śmierci (Art. 12 ust. 1 u.z.s.)",
        "   - Możliwość przedłużenia zarządu do 5 lat przez sąd (Art. 49 ust. 2 u.z.s.)",
        "",
        "§4. ZGODA ZARZĄDCY",
        sprintf("Zarządca %s wyraża zgodę na powołanie i przyjmuje obowiązki.", [manager_name]),
        "",
        "§5. KOSZTY",
        "Koszty aktu notarialnego ponosi Przedsiębiorca.",
        "",
        sprintf("Podpisy: Przedsiębiorca: ..............  Zarządca: ..............  Notariusz: ..............", [])
    ]

    deed_text := concat("\n", deed_sections)

    verdict := {
        "matched": true,
        "rule_id": "jdg.autoform.notarial_deed_template",
        "_legal_basis": "ustawa o CEIDG (Dz.U. 2024 poz. 1228 ze zm.)",
        "package": "jdg.autoform",
        "priority": 8050,
        "action": "GENERATE_NOTARIAL_DEED",
        "autoform_notarial_deed_sections": deed_sections,
        "autoform_notarial_deed_full_text": deed_text,
        "autoform_notarial_deed_ceidg_deadline_days": 14,
        "autoform_succession_max_months_standard": 24,
        "autoform_succession_max_months_extended": 60,
        "legal_basis": "Art. 7-9, 12, 49 Ustawy o zarządzie sukcesyjnym (Dz.U. 2018 poz. 1703)",
        "_routing": "TRIAGE_QUEUE",
        "_routing_reason": sprintf("Akt notarialny: %s → zarządca %s", [business_owner_name, manager_name]),
        "_warnings": [sprintf("📜 G6 AUTO-FORM AKT NOTARIALNY: Powołanie zarządcy sukcesyjnego\n   Przedsiębiorca: %s → Zarządca: %s\n   Wpis CEIDG: 14 dni od śmierci | Maks. 2 lata (5 lat z sądem)\n   ⚠️ Akt notarialny MUSI być sporządzony za życia przedsiębiorcy!",
            [business_owner_name,    manager_name,)]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# G7: RECEIPT/NOTE GENERATOR — Kwity dla działalności nierejestrowanej
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "autoform_receipt", false) == true

    seller_name := object.get(input.jdg_entrepreneur, "name", "")
    seller_address := object.get(input.jdg_entrepreneur, "home_address", "")
    receipt_date := object.get(input.invoice, "issue_date", "")
    receipt_number := object.get(input.invoice, "invoice_number", "RCPT/001/2026")
    buyer_name := object.get(input.vendor, "name", "")
    description := object.get(input.invoice, "description", "")
    amount := object.get(input.invoice, "amount_gross", 0)
    service_type := object.get(input.invoice, "category_code", "SERVICES")
    is_unregistered := object.get(input.jdg_entrepreneur, "is_unregistered_activity", false)

    unregistered_limit := floor(4800 * 0.50 * 100) / 100
    exceeds_limit := amount > unregistered_limit
    monthly_revenue := object.get(input.jdg_entrepreneur, "monthly_revenue_current", 0)
    monthly_exceeds_limit := monthly_revenue > unregistered_limit

    receipt := {
        "type": "RACHUNEK / KWIT",
        "number": receipt_number,
        "date": receipt_date,
        "seller": {"name": seller_name, "address": seller_address},
        "buyer": {"name": buyer_name, "address": ""},
        "description": description,
        "amount_pln": amount,
        "amount_words": sprintf("słownie: %.2f PLN", [amount]),
        "service_type": service_type,
        "unregistered_activity_note": "Działalność nierejestrowana — art. 5 Prawa Przedsiębiorców" { is_unregistered },
        "vat_note": "Nie podlega VAT — działalność nierejestrowana < 200k PLN" { is_unregistered },
        "archival_requirement": "Przechowywać 5 lat (Art. 86 OrdPU)"
    }

    # G7 routing vars
    unreg_tag := "(nierejestrowana)" { is_unregistered }
    unreg_tag := "" { not is_unregistered }

    routing := "BLOCK_AND_ALERT" { monthly_exceeds_limit; is_unregistered }
    routing := "TRIAGE_QUEUE" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.autoform.receipt_generator",
        "_legal_basis": "ustawa o CEIDG (Dz.U. 2024 poz. 1228 ze zm.)",
        "package": "jdg.autoform",
        "priority": 8060,
        "action": "GENERATE_RECEIPT",
        "autoform_receipt_data": receipt,
        "autoform_receipt_unregistered_limit_pln": unregistered_limit,
        "autoform_receipt_exceeds_unregistered_limit": monthly_exceeds_limit,
        "autoform_receipt_monthly_revenue_pln": monthly_revenue,
        "legal_basis": "Art. 5 Prawa Przedsiębiorców; Art. 87 OrdPU",
        "_routing": routing,
        "_routing_reason": sprintf("Kwit: %s — %.2f PLN %s", [receipt_number, amount, unreg_tag]) { not monthly_exceeds_limit },
        "_routing_reason": sprintf("⚠️ Limit działalności nierejestrowanej PRZEKROCZONY! %.2f PLN > %.2f PLN — REJESTRACJA CEIDG WYMAGANA!", [monthly_revenue, unregistered_limit]) { monthly_exceeds_limit; is_unregistered },
        "_warnings": [sprintf("🧾 G7 AUTO-FORM KWIT/RACHUNEK: %s\n   Sprzedawca: %s → Kupujący: %s\n   Kwota: %.2f PLN | %s\n   %s",
            [receipt_number, seller_name, buyer_name, amount,
             is_unregistered && sprintf("Działalność nierejestrowana (limit %.2f PLN/mies.)", [unregistered_limit]) || "Działalność zarejestrowana",
             monthly_exceeds_limit && "⚠️ UWAGA: Przekroczony limit nierejestrowanej — REJESTRUJ CEIDG!" || "✅ W limicie"])]
    }
}
