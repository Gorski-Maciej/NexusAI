# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE TAX AUTHORITY INTERACTION ENGINE (Strategic Initiative S22)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Tax Authority Interaction Engine — Auto-Korespondencja z US/KAS/ZUS
# description: |
#   ENTERPRISE v7.0 — Silnik automatyzacji interakcji z organami podatkowymi.
#   To jest "WIRTUALNY PEŁNOMOCNIK" — automatycznie generuje pisma, odwołania,
#   wnioski i odpowiedzi do US, KAS, ZUS.
#   
#   KLUCZOWA INNOWACJA: Wypełnia lukę między automatyzacją księgowości a
#   reprezentacją przed organami. Nie zastępuje prawnika, ale automatyzuje
#   90% rutynowej korespondencji.
#
#   FUNKCJONALNOŚCI:
#   - Auto-generacja pism do US (czynny żal, korekty, wyjaśnienia)
#   - Wnioski o interpretację indywidualną (WIS, WIP, WIT)
#   - Odpowiedzi na wezwania US (Art. 155, 159, 274c, 287 OrdPU)
#   - Wnioski o zwrot nadpłaty (Art. 75-79 OrdPU)
#   - Wnioski o odroczenie/rozłożenie na raty (Art. 67a-67e OrdPU)
#   - Korespondencja ZUS (wnioski, odwołania, zaświadczenia)
#   - Monitorowanie statusu spraw (terminy, odpowiedzi)
#   - Szablony z podstawą prawną
# architecture: Enterprise v7.0 Interaction Engine
# legal_basis: Ordynacja Podatkowa, KPA, KKS, Ustawa o SUS
# package: jdg.tax_authority_interaction
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.tax_authority_interaction

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.tax_interaction.no_match",
    "package": "jdg.tax_authority_interaction", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# S22-100: AUTO-GENERACJA CZYNNEGO ŻALU — Art. 16 KKS
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.tax_interaction.voluntary_disclosure_letter",
    "package": "jdg.tax_authority_interaction",
    "priority": 100,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "tax_interaction_letter_type": "CZYNNY_ZAL",
    "tax_interaction_letter_to": nus_name,
    "tax_interaction_letter_subject": vd_subject,
    "tax_interaction_letter_body": vd_body,
    "tax_interaction_attachments_needed": vd_attachments,
    "tax_interaction_deadline": "PRZED wszczęciem postępowania przez US",
    "tax_interaction_send_method": "ePUAP / e-Doręczenia / list polecony za potwierdzeniem odbioru",
    "tax_interaction_expected_outcome": "Brak kary KKS (Art. 16 § 1 KKS) + brak odpowiedzialności za przestępstwo skarbowe",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Czynny żal GOTOWY do wysłania — prześlij NATYCHMIAST",
    "_legal_basis": "Art. 16 § 1-5 KKS; Art. 16a KKS; Art. 56 § 1-3 KKS",
    "_warnings": [
        sprintf("📝 CZYNNY ŻAL — AUTOMATYCZNIE WYGENEROWANY", []),
        sprintf("   Do: %s", [nus_name]),
        sprintf("   Dotyczy: %s", [violation_desc]),
        sprintf("   Kwota zaległości: %.2f PLN + odsetki %.2f PLN = %.2f PLN",
            [tax_amount, interest_amount, total_to_pay]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "📋 PROCEDURA:",
        "   1. Podpisz pismo (ePUAP: profil zaufany / podpis kwalifikowany)",
        "   2. Wyślij do właściwego NUS przez ePUAP",
        "   3. Zapłać zaległość + odsetki w ciągu 7 dni od złożenia",
        "   4. Złóż korektę deklaracji (JPK_V7 / PIT / ZUS)",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        sprintf("🛡️ EFEKT: Unikniesz kary do %.2f PLN (30%% zaległości) + odpowiedzialności KKS.",
            [tax_amount * 0.30]),
        "⚠️ UWAGA: Czynny żal NIESKUTECZNY jeśli US już wszczął postępowanie!"
    ]
} {
    input.tax_interaction_vd_letter == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    
    violation_type := object.get(input.jdg_entrepreneur, "tax_violation_type", "LATE_FILING")
    tax_amount := object.get(input.jdg_entrepreneur, "unpaid_tax_amount", 0)
    days_late := object.get(input.jdg_entrepreneur, "days_since_violation", 30)
    nus_code := object.get(input.jdg_entrepreneur, "tax_office_code", "1471")
    entrepreneur_name := object.get(input.jdg_entrepreneur, "full_name", "Jan Kowalski")
    entrepreneur_nip := object.get(input.jdg_entrepreneur, "nip", "0000000000")
    tax_period := object.get(input.jdg_entrepreneur, "tax_period", "2026-06")
    declaration_type := object.get(input.jdg_entrepreneur, "declaration_type", "JPK_V7M")

    # NUS name mapping (simplified)
    nus_name := sprintf("Naczelnik Urzędu Skarbowego %s", [nus_code])

    # Interest calculation (simplified: ~8% annual = 0.0219% per day)
    interest_rate_daily := 0.000219
    interest_amount := floor(tax_amount * interest_rate_daily * days_late * 100) / 100

    total_to_pay := tax_amount + interest_amount

    violation_desc := sprintf("Nieterminowe złożenie deklaracji %s za okres %s",
        [declaration_type, tax_period]) { violation_type == "LATE_FILING" }
    violation_desc := sprintf("Niezapłacony podatek w kwocie %.2f PLN za okres %s",
        [tax_amount, tax_period]) { violation_type == "UNPAID_TAX" }
    violation_desc := sprintf("Błędna deklaracja %s za okres %s — zaniżenie o %.2f PLN",
        [declaration_type, tax_period, tax_amount]) { violation_type == "UNDERSTATED_TAX" }
    violation_desc := "Nieprawidłowość podatkowa" { violation_desc == "" }

    vd_subject := sprintf("Czynny żal — %s, NIP %s", [entrepreneur_name, entrepreneur_nip])

    vd_body := concat("\n", [
        sprintf("Ja, %s (NIP: %s), działając na podstawie art. 16 § 1 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2024 poz. 120), składam niniejszym czynny żal w związku z:", [entrepreneur_name, entrepreneur_nip]),
        "",
        sprintf("    %s", [violation_desc]),
        "",
        "Jednocześnie oświadczam, że:",
        "1) Organ podatkowy nie miał jeszcze w chwili składania niniejszego pisma wyraźnie udokumentowanej wiadomości o popełnieniu czynu zabronionego;",
        "2) W ciągu 7 dni od złożenia niniejszego czynnego żalu uiściłem/uiszczę w całości należność podatkową wraz z odsetkami za zwłokę;",
        "3) W ciągu 7 dni od złożenia niniejszego czynnego żalu złożyłem/złożę korektę deklaracji podatkowej.",
        "",
        sprintf("Kwota zaległości: %.2f PLN", [tax_amount]),
        sprintf("Odsetki: %.2f PLN (stan na dzień złożenia)", [interest_amount]),
        sprintf("Łącznie do zapłaty: %.2f PLN", [total_to_pay]),
        "",
        "Proszę o przyjęcie niniejszego czynnego żalu i odstąpienie od wymierzenia kary na podstawie art. 16 § 1 KKS.",
        "",
        "Z poważaniem,",
        sprintf("%s", [entrepreneur_name])
    ])

    vd_attachments := [
        "Dowód wpłaty zaległości + odsetek",
        sprintf("Korekta deklaracji %s za okres %s", [declaration_type, tax_period]),
        "Pełnomocnictwo (jeśli dotyczy)"
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# S22-200: AUTO-ODPOWIEDŹ NA WEZWANIE US — Art. 155, 159, 274c, 287 OrdPU
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.tax_interaction.response_to_summon",
    "package": "jdg.tax_authority_interaction",
    "priority": 200,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "tax_interaction_letter_type": "ODPOWIEDZ_NA_WEZWANIE",
    "tax_interaction_letter_to": nus_name,
    "tax_interaction_letter_subject": response_subject,
    "tax_interaction_letter_body": response_body,
    "tax_interaction_deadline_days": deadline_days,
    "tax_interaction_documents_to_provide": docs_to_provide,
    "tax_interaction_consequences_of_no_response": consequences,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Odpowiedź na wezwanie US — termin %d dni!", [deadline_days]),
    "_legal_basis": "Art. 155, 159, 274c, 287 OrdPU; Art. 50 KPA",
    "_warnings": [
        "📋 ODPOWIEDŹ NA WEZWANIE US — AUTOMATYCZNIE WYGENEROWANA",
        sprintf("   Termin: %d dni od doręczenia wezwania!", [deadline_days]),
        sprintf("   Dokumenty do dostarczenia: %d sztuk", [count(docs_to_provide)]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "⚠️ NIE IGNORUJ WEZWANIA US!",
        "   • Brak odpowiedzi = domiar podatku (szacowanie)",
        "   • Kara porządkowa do 2 800 PLN (Art. 262 OrdPU)",
        "   • Odpowiedzialność KKS za utrudnianie kontroli (Art. 83 KKS)",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "💡 WSKAZÓWKI:",
        "   1. Odpowiedz w terminie — nawet jeśli tylko wnioskujesz o przedłużenie",
        "   2. Dostarcz TYLKO dokumenty wymienione w wezwaniu",
        "   3. Zachowaj kopię odpowiedzi + dowód nadania",
        "   4. Rozważ konsultację z doradcą podatkowym dla złożonych spraw"
    ]
} {
    input.tax_interaction_us_summon == true
    summon_type := object.get(input.jdg_entrepreneur, "us_summon_type", "VERIFICATION")
    summon_ref := object.get(input.jdg_entrepreneur, "us_summon_reference", "")
    nus_code := object.get(input.jdg_entrepreneur, "tax_office_code", "1471")
    entrepreneur_name := object.get(input.jdg_entrepreneur, "full_name", "Jan Kowalski")
    entrepreneur_nip := object.get(input.jdg_entrepreneur, "nip", "0000000000")
    request_description := object.get(input.jdg_entrepreneur, "us_request_description", "")

    nus_name := sprintf("Naczelnik Urzędu Skarbowego %s", [nus_code])

    deadline_days := 7 { summon_type == "VERIFICATION" }
    deadline_days := 7 { summon_type == "EXPLANATION_274C" }
    deadline_days := 14 { summon_type == "TAX_AUDIT_INITIAL" }
    deadline_days := 30 { summon_type == "DOCUMENT_REQUEST" }

    response_subject := sprintf("Odpowiedź na wezwanie nr %s — %s, NIP %s",
        [summon_ref, entrepreneur_name, entrepreneur_nip])

    response_body := concat("\n", [
        sprintf("W odpowiedzi na wezwanie z dnia [...] nr %s, przedkładam następujące wyjaśnienia i dokumenty:", [summon_ref]),
        "",
        "--- WYJAŚNIENIA ---",
        sprintf("[OPIS STANU FAKTYCZNEGO — %s]", [request_description]),
        "",
        "--- PODSTAWA PRAWNA STANOWISKA PODATNIKA ---",
        "[ARTYKUŁY I INTERPRETACJE — do uzupełnienia na podstawie analizy reguł JDG]",
        "",
        "--- DOKUMENTY ---",
        "[LISTA DOKUMENTÓW — wygenerowana automatycznie na podstawie transakcji w systemie]",
        "",
        "Oświadczam, że przedstawione informacje są zgodne ze stanem faktycznym.",
        "",
        sprintf("%s", [entrepreneur_name])
    ])

    docs_to_provide := ["Faktury VAT objęte wezwaniem", "Ewidencja JPK_V7 za okres", 
                        "Dowody zapłaty", "Umowy z kontrahentami",
                        "Potwierdzenia przelewów", "Wyciągi bankowe"]

    consequences := "Niezłożenie wyjaśnień w terminie = US może oszacować podstawę opodatkowania (Art. 23 OrdPU) + kara porządkowa do 2 800 PLN (Art. 262 OrdPU)."
}


# ═══════════════════════════════════════════════════════════════════════════════
# S22-300: WNIOSEK O INTERPRETACJĘ INDYWIDUALNĄ (WIS/WIP/WIT)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.tax_interaction.individual_interpretation_request",
    "package": "jdg.tax_authority_interaction",
    "priority": 300,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "tax_interaction_letter_type": "WNIOSEK_O_INTERPRETACJE",
    "tax_interaction_interpretation_type": interpretation_type,
    "tax_interaction_authority": authority,
    "tax_interaction_fee_pln": fee_pln,
    "tax_interaction_processing_time": processing_time,
    "tax_interaction_legal_question": legal_question,
    "tax_interaction_taxpayer_position": taxpayer_position,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Wniosek o interpretację %s — opłata %.0f PLN",
        [interpretation_type, fee_pln]),
    "_legal_basis": "Art. 14b-14na OrdPU (WIP); Art. 42b-42h VAT (WIS); Art. 119zzf OrdPU (WIT)",
    "_warnings": [
        sprintf("📝 WNIOSEK O INTERPRETACJĘ %s", [interpretation_type]),
        sprintf("   Organ: %s", [authority]),
        sprintf("   Opłata: %.0f PLN", [fee_pln]),
        sprintf("   Czas oczekiwania: %s", [processing_time]),
        sprintf("   Pytanie: %s", [legal_question]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "📋 FORMA WNIOSKU:",
        "   • WIP (PIT/CIT/OrdPU): ePUAP do Dyrektora KIS",
        "   • WIS (VAT): ePUAP do Dyrektora KIS (specjalny formularz WIS-W)",
        "   • WIT (akcyza): ePUAP do Dyrektora KIS (specjalny formularz WIT-W)",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "🛡️ EFEKT: Interpretacja WIĄŻE organy podatkowe!",
        "   • Zastosowanie się do interpretacji = brak odpowiedzialności KKS",
        "   • Interpretacja chroni również w przypadku kontroli skarbowej"
    ]
} {
    input.tax_interaction_interpretation_needed == true
    tax_domain := object.get(input.jdg_entrepreneur, "interpretation_tax_domain", "VAT")
    legal_question := object.get(input.jdg_entrepreneur, "interpretation_legal_question", "")
    taxpayer_position := object.get(input.jdg_entrepreneur, "interpretation_taxpayer_position", "")

    interpretation_type := "WIS" { tax_domain == "VAT" }
    interpretation_type := "WIP" { tax_domain in {"PIT", "CIT", "ORD"} }
    interpretation_type := "WIT" { tax_domain == "EXCISE" }
    interpretation_type := "WIP" { interpretation_type == "" }

    authority := "Dyrektor Krajowej Informacji Skarbowej (KIS)"

    fee_pln := 40 { interpretation_type == "WIS" }
    fee_pln := 40 { interpretation_type == "WIP" }
    fee_pln := 40 { interpretation_type == "WIT" }

    processing_time := "do 3 miesięcy (Art. 14d OrdPU)" { interpretation_type == "WIP" }
    processing_time := "do 3 miesięcy (Art. 42g VAT)" { interpretation_type == "WIS" }
    processing_time := "do 3 miesięcy" { interpretation_type == "WIT" }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S22-400: WNIOSEK O ZWROT NADPŁATY / STWIERDZENIE NADPŁATY
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.tax_interaction.overpayment_refund_claim",
    "package": "jdg.tax_authority_interaction",
    "priority": 400,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "tax_interaction_letter_type": "WNIOSEK_O_STWIERDZENIE_NADPLATY",
    "tax_interaction_overpayment_amount": overpayment_amount,
    "tax_interaction_overpayment_source": overpayment_source,
    "tax_interaction_overpayment_period": overpayment_period,
    "tax_interaction_refund_deadline": refund_deadline,
    "tax_interaction_interest_if_late": interest_if_late,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Wniosek o zwrot nadpłaty %.2f PLN", [overpayment_amount]),
    "_legal_basis": "Art. 72-80 OrdPU (nadpłata); Art. 76-79 OrdPU (zwrot); Art. 78 OrdPU (odsetki)",
    "_warnings": [
        sprintf("💰 WNIOSEK O STWIERDZENIE NADPŁATY — %.2f PLN", [overpayment_amount]),
        sprintf("   Źródło: %s", [overpayment_source]),
        sprintf("   Okres: %s", [overpayment_period]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        sprintf("⏰ TERMIN ZWROTU: %s", [refund_deadline]),
        sprintf("   Po terminie: odsetki w wysokości %s!", [interest_if_late]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "⚠️ WAŻNE:",
        "   • Nadpłata przedawnia się po 5 latach (Art. 79 § 2 OrdPU)",
        "   • Wniosek o stwierdzenie nadpłaty przerywa bieg przedawnienia",
        "   • US może zaliczyć nadpłatę na poczet zaległości (Art. 76 § 1 OrdPU)",
        "   • Jeśli masz zaległości — US automatycznie potrąci z nadpłaty!"
    ]
} {
    input.tax_interaction_overpayment == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    overpayment_amount := object.get(input.jdg_entrepreneur, "overpayment_amount_pln", 0)
    overpayment_tax := object.get(input.jdg_entrepreneur, "overpayment_tax_type", "PIT")
    overpayment_period := object.get(input.jdg_entrepreneur, "overpayment_period", "2025")
    has_outstanding_debts := object.get(input.jdg_entrepreneur, "has_tax_debts", false)

    overpayment_source := sprintf("Nadpłata w podatku %s za rok %s", [overpayment_tax, overpayment_period])

    refund_deadline := "30 dni od złożenia wniosku" { not has_outstanding_debts }
    refund_deadline := "Po potrąceniu zaległości — US ma 30 dni na zwrot pozostałej kwoty" { has_outstanding_debts }
    interest_if_late := "odsetki ustawowe za zwłokę (obecnie ~14.5% rocznie)"
}

# ═══════════════════════════════════════════════════════════════════════════════
# S22-500: WNIOSEK O ODROCZENIE / ROZŁOŻENIE NA RATY — Art. 67a-67e OrdPU
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.tax_interaction.deferral_installment_request",
    "package": "jdg.tax_authority_interaction",
    "priority": 500,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "tax_interaction_letter_type": "WNIOSEK_O_ULGE_W_SPLACIE",
    "tax_interaction_debt_amount": debt_amount,
    "tax_interaction_installment_months_proposed": proposed_months,
    "tax_interaction_monthly_installment": monthly_installment,
    "tax_interaction_important_interest_note": interest_note,
    "tax_interaction_required_documents": required_docs,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Wniosek o rozłożenie %.2f PLN na %d rat",
        [debt_amount, proposed_months]),
    "_legal_basis": "Art. 67a-67e OrdPU; Rozporządzenie MF w sprawie udzielania ulg",
    "_warnings": [
        sprintf("📅 WNIOSEK O ROZŁOŻENIE NA RATY — %.2f PLN / %d miesięcy",
            [debt_amount, proposed_months]),
        sprintf("   Rata miesięczna: %.2f PLN", [monthly_installment]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        sprintf("⚠️ %s", [interest_note]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "📋 WYMAGANE DOKUMENTY:",
        "   • Wniosek z uzasadnieniem ważnego interesu podatnika / interesu publicznego",
        "   • Oświadczenie o stanie majątkowym i sytuacji finansowej",
        "   • Dokumenty potwierdzające trudną sytuację finansową",
        "   • Dowód wpłaty opłaty prolongacyjnej (50%% odsetek za zwłokę)",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "💡 UWAGA: Opłata prolongacyjna = 50%% stawki odsetek za zwłokę.",
        "   Obecnie: ~7.25%% rocznie (połowa z ~14.5%%).",
        "   Jeśli US odmówi — odsetki naliczane są od pierwotnego terminu!"
    ]
} {
    input.tax_interaction_installment_needed == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    debt_amount := object.get(input.jdg_entrepreneur, "tax_debt_amount_pln", 0)
    proposed_months := object.get(input.jdg_entrepreneur, "proposed_installment_months", 12)
    is_important_reason := object.get(input.jdg_entrepreneur, "has_important_interest_reason", false)

    monthly_installment := floor(debt_amount / proposed_months * 100) / 100

    interest_note := "OPŁATA PROLONGACYJNA = 50%% odsetek za zwłokę (~7.25%% rocznie). " + 
                     "Naliczana od dnia złożenia wniosku do dnia spłaty."

    required_docs := [
        "Formularz wniosku (własny format — zawierający uzasadnienie)",
        "Oświadczenie o stanie majątkowym, dochodach i źródłach przychodów",
        "Zestawienie zobowiązań i należności",
        "Wyciągi bankowe z ostatnich 3 miesięcy",
        "Dokumenty potwierdzające trudną sytuację (opcjonalne, ale zalecane)",
        "Dowód wpłaty opłaty prolongacyjnej (kwota symboliczna na start)"
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# S22-600: MONITOR STATUSU SPRAW — Śledzenie terminów i odpowiedzi US
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.tax_interaction.case_status_tracker",
    "package": "jdg.tax_authority_interaction",
    "priority": 600,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "tax_interaction_open_cases": open_cases_count,
    "tax_interaction_cases_nearing_deadline_7d": cases_7d,
    "tax_interaction_cases_missed_deadline": cases_missed,
    "tax_interaction_oldest_unresolved_days": oldest_days,
    "tax_interaction_next_expected_response_date": next_response_date,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": cases_routing,
    "_routing_reason": cases_reason,
    "_legal_basis": "Art. 139-140 OrdPU (terminy załatwiania spraw); Art. 36-38 KPA",
    "_warnings": warnings,
} {
    input.tax_interaction_case_tracker == true
    open_cases := object.get(input.jdg_entrepreneur, "open_tax_cases", [])
    open_cases_count := count(open_cases)

    # Cases with deadlines within 7 days
    cases_7d := count([c | c := open_cases[_]; days_to_deadline(c) <= 7; days_to_deadline(c) >= 0])

    # Missed deadlines
    cases_missed := count([c | c := open_cases[_]; days_to_deadline(c) < 0])

    oldest_days := max_val([days_since_opened(c) | c := open_cases[_]]) { count(open_cases) > 0 }
    oldest_days := 0 { count(open_cases) == 0 }

    next_response_date := "Brak otwartych spraw" { count(open_cases) == 0 }
    next_response_date := "W ciągu 7 dni" { cases_7d > 0 }

    cases_routing := "BLOCK_AND_ALERT" { cases_missed > 0 }
    cases_routing := "TRIAGE_QUEUE" { cases_7d > 0 }
    cases_routing := "" { true }
    cases_reason := sprintf("%d spraw po terminie — NATYCHMIASTOWA akcja!", [cases_missed]) { cases_missed > 0 }
    cases_reason := sprintf("%d spraw z terminem w ciągu 7 dni", [cases_7d]) { cases_7d > 0; cases_missed == 0 }
    cases_reason := "" { true }

    warnings := [
        sprintf("🚨 %d SPRAW PO TERMINIE — NATYCHMIASTOWA INTERWENCJA!", [cases_missed]),
        "   Konsekwencje: domiar podatku, odpowiedzialność KKS, kara porządkowa.",
        "   Działanie: złóż pismo z wyjaśnieniem opóźnienia (Art. 50 KPA)."
    ] { cases_missed > 0 }
    warnings := [
        sprintf("⚠️ %d SPRAW ZBLIŻA SIĘ DO TERMINU (≤7 dni)", [cases_7d]),
        "   Nie przegap terminów — odpowiedz przed deadlinem!"
    ] { cases_7d > 0 }
    warnings := [sprintf("✅ %d otwartych spraw — wszystkie w terminie.", [open_cases_count])] { true }
}

days_to_deadline(case) = days {
    deadline := object.get(case, "deadline_date", "2099-12-31")
    today := "2026-07-19"
    days := helpers.days_between(today, deadline)
} else = 999 { true }

days_since_opened(case) = days {
    opened := object.get(case, "date_opened", "2026-01-01")
    today := "2026-07-19"
    days := helpers.days_between(opened, today)
} else = 0 { true }

max_val(arr) = max(arr) { count(arr) > 0 } else = 0 { true }
