# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise Policies — MDR/DAC6 Enterprise (P1950-P1965)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: MDR Enterprise — Mandatory Disclosure Rules / DAC6 for JDG
# description: |
#   Rozbudowany pakiet Enterprise dla MDR/DAC6 — schematy podatkowe w JDG.
#   Uzupełnia jdg.mdr (P1800-P1809 wykrywanie) i jdg.mdr.hyper (R1001-R1042 hallmarks)
#   o 16 reguł pokrywających: formularze MDR-1/MDR-3/MDR-4, klasyfikację
#   promotor/korzystający/wspomagający, terminy 30-dniowe z trackingiem,
#   cross-domain integrację (MDR × VAT/KSeF/IP Box/PIT), sankcje do 21M PLN,
#   privilege exceptions, retencję 6-letnią, raportowanie kwartalne.
# architecture: Multi-Pass Enterprise (ADR-001), sub-package of jdg.mdr
# legal_basis: Art. 86a-86o Ordynacji podatkowej, Dyrektywa DAC6 2018/822,
#   Rozp. MF ws. MDR, Rozp. wykonawcze UE 2018/822
# package: jdg.mdr.enterprise
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.mdr.enterprise

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.mdr.enterprise.no_match",
    "package": "jdg.mdr.enterprise",
    "priority": 1966
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1950-P1952: Classifier — Promotor / Korzystający / Wspomagający       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1950: mdr_role_promoter — promujący schemat (doradca, kancelaria, biuro rachunkowe)
decide := {
    "matched": true, "rule_id": "jdg.mdr.enterprise.role_promoter",
    "package": "jdg.mdr.enterprise", "priority": 1950,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mdr_role": "PROMOTOR", "mdr_form_type": "MDR-3",
    "mdr_deadline_days": 30, "mdr_deadline_trigger": "data_udostepnienia_schematu",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "MDR PROMOTOR — obowiązek MDR-3 w 30 dni od udostępnienia schematu!",
    "_legal_basis": "Art. 86a § 1, Art. 86f § 1 OrdPU",
    "_warnings": [sprintf("[MDR] PROMOTOR: %s. MDR-3 w 30 dni od %s. Opisz: dane promotora, schemat (hallmarki), uzasadnienie biznesowe, lista korzystających. NIEZGŁOSZENIE = kara do 21 mln PLN (Art. 86o)!", [promoter_type, availability_date])]
} {
    object.get(input.jdg_entrepreneur, "mdr_scheme_detected", false) == true
    mdr_role := object.get(input.document, "mdr_role", "")
    mdr_role == "PROMOTER"
    promoter_type := object.get(input.document, "mdr_promoter_type", "doradca podatkowy")
    availability_date := object.get(input.document, "mdr_scheme_available_date", "data nieznana")
}

# P1951: mdr_role_user — korzystający ze schematu (przedsiębiorca JDG)
else := {
    "matched": true, "rule_id": "jdg.mdr.enterprise.role_user",
    "package": "jdg.mdr.enterprise", "priority": 1951,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mdr_role": "KORZYSTAJACY", "mdr_form_type": "MDR-3",
    "mdr_deadline_days": 30, "mdr_deadline_trigger": "data_pierwszej_czynnosci",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("MDR KORZYSTAJĄCY — MDR-3 w 30 dni od pierwszej czynności (%s)!", [first_date]),
    "_legal_basis": "Art. 86a § 1, Art. 86f § 1 OrdPU",
    "_warnings": [sprintf("[MDR] KORZYSTAJĄCY: pierwsza czynność %s. MDR-3 w 30 dni. Opisz: dane korzystającego, NIP, schemat, korzyść podatkową (szacunkowo %.2f PLN). NIEZGŁOSZENIE = odpowiedzialność solidarna KKS!", [first_date, benefit_amount])]
} {
    object.get(input.jdg_entrepreneur, "mdr_scheme_detected", false) == true
    mdr_role := object.get(input.document, "mdr_role", "")
    mdr_role == "USER"
    first_date := object.get(input.document, "mdr_first_implementation_date", "data nieznana")
    benefit_amount := object.get(input.document, "mdr_tax_benefit_estimated_pln", 0)
}

# P1952: mdr_role_support — wspomagający (pośrednik, bank, notariusz)
else := {
    "matched": true, "rule_id": "jdg.mdr.enterprise.role_support",
    "package": "jdg.mdr.enterprise", "priority": 1952,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mdr_role": "WSPOMAGAJACY", "mdr_form_type": "MDR-3 (ograniczony)",
    "mdr_deadline_days": 30,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("MDR WSPOMAGAJĄCY — ograniczony obowiązek MDR-3. Rola: %s", [support_type]),
    "_legal_basis": "Art. 86a § 1, Art. 86h OrdPU",
    "_warnings": [sprintf("[MDR] WSPOMAGAJĄCY: %s. MDR-3 w zakresie: dane identyfikacyjne + NIP + opis roli w schemacie. Nie masz obowiązku opisywania pełnego schematu.", [support_type])]
} {
    object.get(input.jdg_entrepreneur, "mdr_scheme_detected", false) == true
    mdr_role := object.get(input.document, "mdr_role", "")
    mdr_role == "SUPPORT"
    support_type := object.get(input.document, "mdr_support_type", "instytucja finansowa")
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1953-P1956: Formularze — MDR-1 / MDR-2 / MDR-3 / MDR-4                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1953: mdr_form_mdr1_internal — MDR-1: zgłoszenie wewnętrzne (pracownik → promotor)
else := {
    "matched": true, "rule_id": "jdg.mdr.enterprise.form_mdr1_internal",
    "package": "jdg.mdr.enterprise", "priority": 1953,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mdr_form_type": "MDR-1", "mdr_reporting_level": "WEWNETRZNE",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "MDR-1 — zgłoszenie wewnętrzne. Pracownik do promotora.",
    "_legal_basis": "Art. 86j OrdPU (procedura wewnętrzna MDR)",
    "_warnings": [sprintf("[MDR] MDR-1 WEWNĘTRZNY: %d zatrudnionych. Wdróż procedurę wewnętrzną MDR (Art. 86j). Pracownicy zgłaszają schematy promotorowi w ciągu 5 dni roboczych.", [employees])]
} {
    employees := object.get(input.employment, "employee_count", 0)
    employees >= 10
    object.get(input.jdg_entrepreneur, "mdr_internal_procedure_implemented", false) == false
}

# P1954: mdr_form_mdr3_deadline_tracker — tracking terminu MDR-3
else := {
    "matched": true, "rule_id": "jdg.mdr.enterprise.form_mdr3_deadline_tracker",
    "package": "jdg.mdr.enterprise", "priority": 1954,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mdr_form_type": "MDR-3", "mdr_overdue": true,
    "mdr_days_overdue": days_overdue,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("MDR-3 PO TERMINIE o %d dni! Złóż natychmiast!", [days_overdue]),
    "_legal_basis": "Art. 86f § 1, Art. 86o OrdPU",
    "_warnings": [sprintf("[MDR] MDR-3 DEADLINE: %d dni PO TERMINIE (termin: %s). Narosła kara: %.0f PLN (max %.0f PLN). Złóż natychmiast!", [days_overdue, due_date, accrued_penalty, max_penalty])]
} {
    object.get(input.jdg_entrepreneur, "mdr_scheme_detected", false) == true
    object.get(input.mdr, "mdr3_submitted", false) == false
    days_overdue := object.get(input.mdr, "mdr3_days_overdue", 0)
    days_overdue > 0
    due_date := object.get(input.mdr, "mdr3_due_date", "brak")
    daily_penalty := object.get(object.get(data.thresholds, "jdg", {}), "mdr_daily_penalty_pln", 5000)
    max_penalty := object.get(object.get(data.thresholds, "jdg", {}), "mdr_sanction_max_pln", 21000000)
    accrued_penalty := min([days_overdue * daily_penalty, max_penalty])
} else = {
    "matched": true, "rule_id": "jdg.mdr.enterprise.form_mdr3_deadline_ok",
    "package": "jdg.mdr.enterprise", "priority": 1954,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mdr_form_type": "MDR-3", "mdr_submitted": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 86f § 1 OrdPU",
    "_warnings": [sprintf("[MDR] MDR-3 ZŁOŻONY %s — OK. Zachowaj potwierdzenie + kopię przez 6 lat. Numer referencyjny: %s.", [submission_date, nrs])]
} {
    object.get(input.mdr, "mdr3_submitted", false) == true
    submission_date := object.get(input.mdr, "mdr3_submission_date", "")
    nrs := object.get(input.mdr, "mdr3_nrs", "brak")
}

# P1955: mdr_form_mdr4_quarterly — MDR-4: kwartalne zestawienie
else := {
    "matched": true, "rule_id": "jdg.mdr.enterprise.form_mdr4_quarterly",
    "package": "jdg.mdr.enterprise", "priority": 1955,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mdr_form_type": "MDR-4", "mdr_quarterly_due": true,
    "mdr_quarterly_deadline": deadline,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("MDR-4 — zestawienie kwartalne Q%d. Termin: %s.", [quarter, deadline]),
    "_legal_basis": "Art. 86k OrdPU",
    "_warnings": [sprintf("[MDR] MDR-4 KWARTALNY: Q%d — złóż zestawienie zgłoszonych schematów do %s. %d schematów w tym kwartale. NIEZŁOŻENIE = kara do 500 000 PLN.", [quarter, deadline, scheme_count])]
} {
    object.get(input.mdr, "mdr4_due", false) == true
    quarter := object.get(input.calendar, "quarter", 2)
    deadline = "30 kwietnia" { quarter == 1 }; deadline = "31 lipca" { quarter == 2 }
    deadline = "31 października" { quarter == 3 }; deadline = "31 stycznia" { quarter == 4 }
    scheme_count := object.get(input.mdr, "mdr_schemes_this_quarter", 0)
}

# P1956: mdr_form_mdr2_new_scheme_variant — MDR-2: nowy wariant schematu
else := {
    "matched": true, "rule_id": "jdg.mdr.enterprise.form_mdr2_variant",
    "package": "jdg.mdr.enterprise", "priority": 1956,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mdr_form_type": "MDR-2", "mdr_variant_detected": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("MDR-2 — nowy wariant schematu %s. Aktualizuj MDR-3!", [nrs]),
    "_legal_basis": "Art. 86i OrdPU (aktualizacja zgłoszenia)",
    "_warnings": [sprintf("[MDR] MDR-2 — NOWY WARIANT schematu %s. Złóż MDR-2 z aktualizacją w ciągu 30 dni od zmiany. Opisz: co się zmieniło, nowe korzyści, nowi korzystający.", [nrs])]
} {
    object.get(input.mdr, "mdr_scheme_variant_detected", false) == true
    nrs := object.get(input.mdr, "mdr3_nrs", "brak")
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1957-P1959: Cross-Domain — MDR × VAT/KSeF, MDR × IP Box, MDR × PIT   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1957: mdr_cross_vat_ksef — MDR × VAT/KSeF — schematy fakturowe
else := {
    "matched": true, "rule_id": "jdg.mdr.enterprise.cross_vat_ksef",
    "package": "jdg.mdr.enterprise", "priority": 1957,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mdr_cross_domain": "VAT_KSEF",
    "mdr_vat_scheme_type": scheme_type,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("MDR × VAT/KSeF — schemat fakturowy: %s. Hallmark: %s.", [scheme_type, hallmark]),
    "_legal_basis": "Art. 86a § 1 pkt 1-3 OP + Art. 106na-106nq VAT (KSeF)",
    "_warnings": [sprintf("[MDR] CROSS-VAT: schemat fakturowy %s (%.2f PLN). Hallmark A3/A6 + KSeF mandatory. Jeśli schemat wykorzystuje KSeF do strukturyzacji = MDR + KSeF sanction do 500k PLN!", [scheme_type, amount])]
} {
    object.get(input.jdg_entrepreneur, "mdr_scheme_detected", false) == true
    object.get(input.invoice, "is_vat_scheme", false) == true
    scheme_type := object.get(input.invoice, "mdr_vat_scheme_type", "karuzela VAT")
    hallmark := object.get(input.invoice, "mdr_hallmark_matched", "A6")
    amount := object.get(input.invoice, "amount_gross", 0)
}

# P1958: mdr_cross_ip_box — MDR × IP Box — schematy IP
else := {
    "matched": true, "rule_id": "jdg.mdr.enterprise.cross_ip_box",
    "package": "jdg.mdr.enterprise", "priority": 1958,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mdr_cross_domain": "IP_BOX",
    "mdr_ip_box_nexus_ratio_pct": nexus_pct,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("MDR × IP Box — schemat IP: nexus %.0f%%. Hallmark D1/C6.", [nexus_pct]),
    "_legal_basis": "Art. 86e OP (Hallmark D — IP transfer) + Art. 30ca PIT (IP Box)",
    "_warnings": [sprintf("[MDR] CROSS-IP: IP Box + transgraniczny transfer IP (nexus %.0f%%). Jeśli IP zostało przeniesione do podmiotu powiązanego bez wynagrodzenia → MDR Hallmark D1 + ryzyko GAAR! Dokumentuj DEMPE.", [nexus_pct])]
} {
    object.get(input.jdg_entrepreneur, "mdr_scheme_detected", false) == true
    object.get(input.jdg_entrepreneur, "ip_box_active", false) == true
    object.get(input.invoice, "ip_cross_border_transfer", false) == true
    nexus_pct := object.get(input.jdg_entrepreneur, "ip_box_nexus_ratio", 0)
}

# P1959: mdr_cross_pit_income_conversion — MDR × PIT — konwersja dochodu
else := {
    "matched": true, "rule_id": "jdg.mdr.enterprise.cross_pit_conversion",
    "package": "jdg.mdr.enterprise", "priority": 1959,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mdr_cross_domain": "PIT_CONVERSION",
    "mdr_conversion_type": conversion_type,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("MDR × PIT — konwersja: %s. Hallmark A5/B2.", [conversion_type]),
    "_legal_basis": "Art. 86a OP (Hallmark A5, B2) + Art. 27, 30c PIT",
    "_warnings": [sprintf("[MDR] CROSS-PIT: konwersja %s (%.2f PLN). Zmiana formy opodatkowania + optymalizacja transgraniczna. Jeśli główną korzyścią jest podatkowa → MBT = TRUE → MDR obowiązkowy!", [conversion_type, amount])]
} {
    object.get(input.jdg_entrepreneur, "mdr_scheme_detected", false) == true
    tax_form_changed := object.get(input.jdg_entrepreneur, "mdr_tax_form_conversion", false)
    income_to_capital := object.get(input.jdg_entrepreneur, "mdr_income_to_capital", false)
    tax_form_changed or income_to_capital
    conversion_type = "forma opodatkowania" { tax_form_changed }
    conversion_type = "dochód → kapitał" { income_to_capital }
    amount := object.get(input.invoice, "amount_net", 0)
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1960-P1962: Sanctions — Kary administracyjne i karno-skarbowe          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1960: mdr_sanction_non_filing — Kara za niezłożenie MDR-3
else := {
    "matched": true, "rule_id": "jdg.mdr.enterprise.sanction_non_filing",
    "package": "jdg.mdr.enterprise", "priority": 1960,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "sanction_type": "MDR_ADMINISTRACYJNA",
    "mdr_sanction_max_pln": max_penalty, "mdr_sanction_daily_penalty": daily_penalty,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("MDR SANKCJA: brak MDR-3! Kara %.0f PLN za każdy dzień zwłoki (max %.0f mln)!", [daily_penalty, max_penalty/1000000]),
    "_legal_basis": "Art. 86o OrdPU, Art. 80f, 54-56 KKS",
    "_warnings": [sprintf("[MDR] SANKCJA MDR: brak MDR-3 od %d dni. Narosła kara: %.0f PLN (max %.0f PLN). + KKS (do 720 stawek). ZŁÓŻ MDR-3 + czynny żal!", [days_overdue, accrued_penalty, max_penalty])]
} {
    object.get(input.jdg_entrepreneur, "mdr_scheme_detected", false) == true
    object.get(input.mdr, "mdr3_submitted", false) == false
    object.get(input.mdr, "mdr3_overdue", false) == true
    days_overdue := object.get(input.mdr, "mdr3_days_overdue", 0)
    daily_penalty := object.get(object.get(data.thresholds, "jdg", {}), "mdr_daily_penalty_pln", 5000)
    max_penalty := object.get(object.get(data.thresholds, "jdg", {}), "mdr_sanction_max_pln", 21000000)
    accrued_penalty := min([days_overdue * daily_penalty, max_penalty])
}

# P1961: mdr_sanction_incomplete_filing — Kara za niekompletne MDR-3
else := {
    "matched": true, "rule_id": "jdg.mdr.enterprise.sanction_incomplete",
    "package": "jdg.mdr.enterprise", "priority": 1961,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "sanction_type": "MDR_NIEKOMPLETNE",
    "mdr_missing_fields": missing_fields,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("MDR-3 niekompletne — brak: %s. Uzupełnij w 7 dni!", [missing_fields]),
    "_legal_basis": "Art. 86o OrdPU (niekompletne zgłoszenie = niezłożenie)",
    "_warnings": [sprintf("[MDR] MDR-3 NIEKOMPLETNE — brak pól: %s. Złożone bez tych danych = traktowane jak NIEZŁOŻONE. Uzupełnij MDR-2 w ciągu 7 dni. Kara: jak za brak zgłoszenia!", [missing_fields])]
} {
    object.get(input.mdr, "mdr3_submitted", false) == true
    object.get(input.mdr, "mdr3_incomplete", false) == true
    missing_fields := object.get(input.mdr, "mdr3_missing_fields", "hallmarki, opis schematu, uzasadnienie biznesowe")
}

# P1962: mdr_sanction_mitigation_voluntary — Czynny żal MDR — redukcja kary
else := {
    "matched": true, "rule_id": "jdg.mdr.enterprise.sanction_mitigation",
    "package": "jdg.mdr.enterprise", "priority": 1962,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mdr_voluntary_disclosure": true,
    "mdr_penalty_reduction_pct": reduction_pct,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "MDR CZYNNY ŻAL — złóż przed wszczęciem kontroli! Redukcja kary.",
    "_legal_basis": "Art. 16a KKS, Art. 86n OrdPU (czynny żal)",
    "_warnings": [sprintf("[MDR] CZYNNY ŻAL MDR: złóż MDR-3 + pismo do Szefa KAS przed kontrolą. Kara zredukowana o %.0f%% — z %.0f PLN do %.0f PLN.", [reduction_pct, original_penalty, reduced_penalty])]
} {
    object.get(input.mdr, "mdr_voluntary_disclosure_pending", false) == true
    original_penalty := object.get(input.mdr, "mdr_potential_penalty_pln", 5000000)
    reduction_pct := object.get(object.get(data.thresholds, "jdg", {}), "mdr_voluntary_disclosure_reduction_pct", 50)
    reduced_penalty := floor(original_penalty * (100 - reduction_pct) / 100)
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1963-P1965: Retention, Privilege, Audit Trail                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1963: mdr_privilege_attorney — Tajemnica adwokacka/radcowska
else := {
    "matched": true, "rule_id": "jdg.mdr.enterprise.privilege_attorney",
    "package": "jdg.mdr.enterprise", "priority": 1963,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mdr_privilege_active": true, "mdr_obligation_on_client": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "MDR PRIVILEGE — tajemnica zawodowa. Obowiązek MDR przechodzi na KLIENTA!",
    "_legal_basis": "Art. 86a § 4 OrdPU, Art. 86c OrdPU",
    "_warnings": [sprintf("[MDR] TAJEMNICA ZAWODOWA — %s. NIE składasz MDR-3. Obowiązek zgłoszenia przechodzi na KLIENTA (Art. 86c). POINFORMUJ klienta pisemnie + zachowaj kopię pisma przez 6 lat!", [profession])]
} {
    profession := object.get(input.jdg_entrepreneur, "profession", "")
    profession in {"ATTORNEY", "RADCA_PRAWNY", "DORADCA_PODATKOWY"}
    object.get(input.jdg_entrepreneur, "mdr_legal_privilege_claimed", false) == true
}

# P1964: mdr_retention_6years — Retencja dokumentacji MDR przez 6 lat
else := {
    "matched": true, "rule_id": "jdg.mdr.enterprise.retention_6years",
    "package": "jdg.mdr.enterprise", "priority": 1964,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mdr_retention_years": 6,
    "mdr_retention_until": retention_end,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("MDR retencja — przechowuj do końca %d (6 lat).", [retention_end]),
    "_legal_basis": "Art. 86m OrdPU",
    "_warnings": [sprintf("[MDR] RETENCJA 6 LAT: przechowuj wszystkie MDR-3, MDR-4, korespondencję z KAS, analizy MBT, opinie prawne do końca %d. Zniszczenie przed terminem = kara KKS Art. 68!", [retention_end])]
} {
    object.get(input.jdg_entrepreneur, "mdr_scheme_detected", false) == true
    scheme_year := object.get(input.mdr, "mdr_scheme_registration_year", 2026)
    retention_end := scheme_year + 6
    object.get(input.mdr, "mdr_retention_verified", false) == false
}

# P1965: mdr_audit_trail — Ścieżka audytu MDR
else := {
    "matched": true, "rule_id": "jdg.mdr.enterprise.audit_trail",
    "package": "jdg.mdr.enterprise", "priority": 1965,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mdr_audit_trail_complete": is_complete,
    "mdr_documents_count": doc_count,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("MDR audit trail — %d dokumentów. Kompletność: %s", [doc_count, audit_status]),
    "_legal_basis": "Art. 86m § 2 OrdPU, Art. 86n (obowiązek dokumentowania)",
    "_warnings": [sprintf("[MDR] AUDIT TRAIL MDR: %d dokumentów. %s. Kompletny audit trail: (1) analiza MBT, (2) lista hallmarks, (3) MDR-3 + potwierdzenia, (4) MDR-4 kwartalne, (5) korespondencja z KAS, (6) opinie prawne.", [doc_count, audit_status])]
} {
    object.get(input.jdg_entrepreneur, "mdr_scheme_detected", false) == true
    doc_count := object.get(input.mdr, "mdr_audit_documents_count", 0)
    is_complete := object.get(input.mdr, "mdr_audit_trail_complete", false)
    audit_status = "KOMPLETNY — OK" { is_complete == true }
    audit_status = "NIEKOMPLETNY — uzupełnij!" { is_complete == false }
}

# ── Fallback ──────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.mdr.enterprise.fallback",
    "package": "jdg.mdr.enterprise", "priority": 1997,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 86a-86o OrdPU",
    "_warnings": ["[MDR] MDR Enterprise — brak schematów podatkowych do zgłoszenia. JDG nie jest promotorem ani korzystającym z raportowalnych schematów."]
} { true }
