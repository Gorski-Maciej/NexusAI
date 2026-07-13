# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — RODO/GDPR Data Protection for JDG (P1610-P1613)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: RODO Package — GDPR Compliance for Sole Proprietorship
# description: |
#   First-Match-Wins else-chain dla podstawowych obowiązków RODO w JDG.
#   JDG jako administrator danych osobowych (klientów, pracowników, kontrahentów)
#   podlega RODO tak samo jak spółki. 4 reguły pokrywają kluczowe obowiązki:
#   rejestr czynności przetwarzania, retencja danych, zgłaszanie naruszeń,
#   ochrona danych pracowniczych.
# legal_basis: Rozporządzenie Parlamentu Europejskiego i Rady (UE) 2016/679
#   (RODO/GDPR), Ustawa z dn. 10.05.2018 o ochronie danych osobowych
# edge_cases:
#   - JDG bez pracowników: uproszczone obowiązki (brak zgód pracowniczych)
#   - Monitoring wizyjny: obowiązek oznaczenia + rejestracja
#   - Przetwarzanie danych wrażliwych (zdrowotne, biometryczne): zaostrzone wymogi
# package: jdg.rodo
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.rodo

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.rodo.no_match",
    "package": "jdg.rodo", "priority": 1620
}

# ══════ P1610: rodo_data_processing_register — Rejestr czynności przetwarzania ══════
decide := {
    "matched": true, "rule_id": "jdg.rodo.data_processing_register",
    "package": "jdg.rodo", "priority": 1610,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_register_required": true, "rodo_register_type": register_type,
    "rodo_data_categories": data_categories,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Obowiązek prowadzenia rejestru czynności przetwarzania (Art. 30 RODO)",
    "_legal_basis": "Art. 30 RODO (Rozporządzenie 2016/679)",
    "_warnings": [sprintf("REJESTR CZYNNOŚCI PRZETWARZANIA — Art. 30 RODO. %s. Kategorie danych: %s. Aktualizuj na bieżąco!", [register_type, data_categories])]
} {
    input.jdg_entrepreneur.processes_personal_data == true
    input.jdg_entrepreneur.rodo_register_not_maintained == true

    # JDG z pracownikami → pełny rejestr; bez pracowników → uproszczony
    has_employees := object.get(input.employment, "has_employees", false)
    register_type = "PELNY (zatrudnienie + klienci + kontrahenci)" { has_employees == true }
    register_type = "UPROSZCZONY (tylko klienci i kontrahenci)" { has_employees == false }

    # Kategorie danych
    data_categories = "DANE_ZATRUDNIENIA+DANE_KLIENTOW+DANE_KONTRAHENTOW" {
        has_employees == true
    }
    data_categories = "DANE_KLIENTOW+DANE_KONTRAHENTOW" {
        has_employees == false
    }
}

# ══════ P1611: rodo_data_retention — Obowiązek retencji i usuwania danych ══════
else := {
    "matched": true, "rule_id": "jdg.rodo.data_retention",
    "package": "jdg.rodo", "priority": 1611,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_retention_required": true, "rodo_retention_years_min": 5,
    "rodo_deletion_deadline": deletion_deadline_days,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Obowiązek retencji danych księgowych + RODO — min. 5 lat",
    "_legal_basis": "Art. 5 ust. 1 lit. e RODO + Art. 74 ust. 2 UoR (5 lat przechowywania ksiąg)",
    "_warnings": [sprintf("RETENCJA DANYCH — minimum 5 lat dla danych księgowych (Art. 74 UoR). Dane osobowe klientów: usuń po %d dniach od zakończenia współpracy (chyba że wymóg prawny nakazuje dłużej)", [deletion_deadline_days])]
} {
    input.jdg_entrepreneur.processes_personal_data == true

    # Termin usunięcia danych klientów po zakończeniu współpracy
    deletion_deadline_days = 30 {
        object.get(input.invoice, "client_relationship_ended", false) == true
    }
    deletion_deadline_days = 365 {
        object.get(input.invoice, "client_relationship_ended", false) == false
    }
}

# ══════ P1612: rodo_data_breach_notification — Zgłoszenie naruszenia danych ══════
else := {
    "matched": true, "rule_id": "jdg.rodo.data_breach_notification",
    "package": "jdg.rodo", "priority": 1612,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_breach_detected": true, "rodo_notification_deadline_hours": 72,
    "rodo_notify_uodo": true, "rodo_notify_data_subjects": notify_subjects,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Naruszenie danych osobowych — obowiązek zgłoszenia w 72h do UODO!",
    "_legal_basis": "Art. 33-34 RODO",
    "_warnings": [sprintf("NARUSZENIE DANYCH OSOBOWYCH — zgłoś do UODO w ciągu 72 godzin! %s. Kara do 20 mln EUR lub 4%% rocznego obrotu!", [subject_info])]
} {
    input.jdg_entrepreneur.rodo_data_breach == true
    breach_risk := object.get(input.jdg_entrepreneur, "rodo_breach_risk_level", "LOW")

    notify_subjects = true { breach_risk == "HIGH" }
    notify_subjects = false { breach_risk != "HIGH" }

    subject_info = "Poinformuj osoby, których dane dotyczą (wysokie ryzyko)" { notify_subjects == true }
    subject_info = "Nie ma obowiązku informowania osób (niskie ryzyko)" { notify_subjects == false }
}

# ══════ P1613: rodo_employee_data_protection — Ochrona danych pracowniczych ══════
else := {
    "matched": true, "rule_id": "jdg.rodo.employee_data_protection",
    "package": "jdg.rodo", "priority": 1613,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_employee_consent_required": consent_needed,
    "rodo_monitoring_declaration": monitoring,
    "rodo_dpo_required": dpo_required,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "RODO — ochrona danych pracowniczych. Obowiązek informacyjny Art. 13 RODO",
    "_legal_basis": "Art. 13, 35, 37 RODO",
    "_warnings": [sprintf("RODO PRACOWNICZE: %s | Monitoring: %s | IOD: %s", [consent_info, monitoring_info, dpo_info])]
} {
    input.employment.has_employees == true
    emp_count := object.get(input.employment, "employee_count", 0)
    emp_count > 0

    # Zgoda tylko gdy podstawa ≠ obowiązek prawny (np. zdjęcia pracowników na stronie)
    consent_needed_count := object.get(input.employment, "rodo_consent_required_count", 0)
    consent_needed = consent_needed_count > 0
    consent_info = sprintf("Wymagana zgoda dla %d pracowników", [consent_needed_count]) { consent_needed == true }
    consent_info = "Zgody nie są wymagane (podstawa: obowiązek prawny)" { consent_needed == false }

    # Monitoring wizyjny
    monitoring_active := object.get(input.jdg_entrepreneur, "cctv_monitoring_active", false)
    monitoring = "AKTYWNY — wymagane oznaczenie stref + klauzula informacyjna" { monitoring_active == true }
    monitoring = "BRAK" { monitoring_active == false }
    monitoring_info = "Aktywny" { monitoring_active == true }
    monitoring_info = "Brak" { monitoring_active == false }

    # Inspektor Ochrony Danych (wymagany przy przetwarzaniu na dużą skalę)
    dpo_required = emp_count >= 50
    dpo_info = "WYMAGANY (≥50 pracowników)" { dpo_required == true }
    dpo_info = "Niewymagany (<50 pracowników)" { dpo_required == false }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1614-P1621 — RODO ROZSZERZENIE: Marketing, Monitoring, Transfer, DPIA  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════ P1614: rodo_marketing_consent — Zgody marketingowe ══════
else := {
    "matched": true, "rule_id": "jdg.rodo.marketing_consent",
    "package": "jdg.rodo", "priority": 1614,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_marketing_consent_required": consent_needed,
    "rodo_marketing_channels": channels,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "RODO — zgody marketingowe wymagane przed wysyłką",
    "_legal_basis": "Art. 6 ust. 1 lit. a RODO + Art. 10 Ustawy o świadczeniu usług drogą elektroniczną + Art. 172 Prawo telekomunikacyjne",
    "_warnings": [sprintf("ZGODY MARKETINGOWE — %s. Kanały: %s. Zgoda musi być: dobrowolna, konkretna, świadoma, jednoznaczna. Obowiązek wykazania!", [consent_status, channels])]
} {
    input.jdg_entrepreneur.processes_personal_data == true
    has_newsletter := object.get(input.jdg_entrepreneur, "has_newsletter", false)
    has_email_campaigns := object.get(input.jdg_entrepreneur, "has_email_campaigns", false)
    has_sms_marketing := object.get(input.jdg_entrepreneur, "has_sms_marketing", false)

    marketing_active := has_newsletter | has_email_campaigns | has_sms_marketing
    marketing_active == true

    consent_needed = true
    channels = concat(", ", array.concat(
        array.concat(
            [e | e := "EMAIL"; has_newsletter],
            [e | e := "EMAIL"; has_email_campaigns]
        ),
        [e | e := "SMS"; has_sms_marketing]
    ))

    consent_obtained := object.get(input.jdg_entrepreneur, "marketing_consent_obtained", false)
    consent_status = "ZGODY UZYSKANE — OK" { consent_obtained == true }
    consent_status = "BRAK ZGÓD — NIE wysyłaj komunikacji marketingowej!" { consent_obtained == false }
}

# ══════ P1615: rodo_cctv_monitoring — Monitoring wizyjny ══════
else := {
    "matched": true, "rule_id": "jdg.rodo.cctv_monitoring",
    "package": "jdg.rodo", "priority": 1615,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_cctv_active": true, "rodo_cctv_retention_days": retention_days,
    "rodo_cctv_signage_required": true,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Monitoring CCTV — obowiązek oznaczenia + klauzula + rejestr",
    "_legal_basis": "Art. 6 ust. 1 lit. f RODO + Art. 222 Kodeksu Pracy (pracownicy) + Art. 22² § 2 KP",
    "_warnings": [sprintf("MONITORING CCTV — %d kamer. Retencja: max %d dni. %s. Obowiązek: tabliczki informacyjne + klauzula RODO przy wejściu + wpis do rejestru czynności!", [camera_count, retention_days, consent_check])]
} {
    input.jdg_entrepreneur.cctv_monitoring_active == true
    camera_count := object.get(input.jdg_entrepreneur, "cctv_camera_count", 1)
    camera_count > 0
    retention_days := object.get(input.jdg_entrepreneur, "cctv_retention_days", 30)

    has_signage := object.get(input.jdg_entrepreneur, "cctv_signage_installed", false)
    has_clause := object.get(input.jdg_entrepreneur, "cctv_rodo_clause_posted", false)
    consent_check = "Oznaczenie + klauzula OK" { has_signage == true; has_clause == true }
    consent_check = "BRAK oznaczenia lub klauzuli — NATYCHMIAST uzupełnij!" { has_signage == false }
    consent_check = "BRAK oznaczenia lub klauzuli — NATYCHMIAST uzupełnij!" { has_clause == false }
}

# ══════ P1616: rodo_data_transfer_eog — Transfer danych poza EOG ══════
else := {
    "matched": true, "rule_id": "jdg.rodo.data_transfer_eog",
    "package": "jdg.rodo", "priority": 1616,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_transfer_eog": true, "rodo_transfer_country": transfer_country,
    "rodo_transfer_safeguard": safeguard,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Transfer danych poza EOG — wymagane zabezpieczenia Art. 44-49 RODO!",
    "_legal_basis": "Art. 44-49 RODO (Rozdział V)",
    "_warnings": [sprintf("TRANSFER DANYCH POZA EOG — do: %s. Wymagane zabezpieczenie: %s. Bez tego → NIE przekazuj danych! Kara do 20 mln EUR!", [transfer_country, safeguard])]
} {
    input.jdg_entrepreneur.rodo_data_transfer_eog == true
    transfer_country := object.get(input.jdg_entrepreneur, "rodo_transfer_country", "USA")

    has_scc := object.get(input.jdg_entrepreneur, "rodo_scc_documented", false)
    has_bcr := object.get(input.jdg_entrepreneur, "rodo_bcr_approved", false)
    has_adequacy := object.get(input.jdg_entrepreneur, "rodo_adequacy_decision", false)

    safeguard = "Standardowe Klauzule Umowne (SCC)" { has_scc == true }
    safeguard = "Wiążące Reguły Korporacyjne (BCR)" { has_bcr == true }
    safeguard = "Decyzja adekwatności KE" { has_adequacy == true }
    safeguard = "BRAK ZABEZPIECZEŃ — zatrzymaj transfer!" { has_scc == false; has_bcr == false; has_adequacy == false }
}

# ══════ P1617: rodo_dpia_privacy_impact — Ocena skutków dla ochrony danych (DPIA) ══════
else := {
    "matched": true, "rule_id": "jdg.rodo.dpia_required",
    "package": "jdg.rodo", "priority": 1617,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_dpia_required": true, "rodo_dpia_trigger": dpia_trigger,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "DPIA wymagana — przetwarzanie wysokiego ryzyka",
    "_legal_basis": "Art. 35 RODO",
    "_warnings": [sprintf("DPIA WYMAGANA — %s. Przeprowadź ocenę skutków przed rozpoczęciem przetwarzania. Konsultuj z UODO jeśli wysokie ryzyko.", [dpia_trigger])]
} {
    input.jdg_entrepreneur.processes_personal_data == true

    processes_sensitive := object.get(input.jdg_entrepreneur, "processes_sensitive_data", false)
    large_scale := object.get(input.jdg_entrepreneur, "large_scale_processing", false)
    systematic_monitoring := object.get(input.jdg_entrepreneur, "systematic_monitoring", false)
    uses_ai_profiling := object.get(input.jdg_entrepreneur, "uses_ai_automated_decisions", false)

    dpia_required_trigger := processes_sensitive | large_scale | systematic_monitoring | uses_ai_profiling
    dpia_required_trigger == true

    dpia_trigger = "dane wrażliwe na dużą skalę" { processes_sensitive == true; large_scale == true }
    dpia_trigger = "monitoring systematyczny" { systematic_monitoring == true }
    dpia_trigger = "profilowanie AI / decyzje automatyczne" { uses_ai_profiling == true }
    dpia_trigger = "przetwarzanie wysokiego ryzyka" { dpia_required_trigger == true }
}

# ══════ P1618: rodo_dsar_access_request — Prawo dostępu do danych (DSAR) ══════
else := {
    "matched": true, "rule_id": "jdg.rodo.dsar_access_request",
    "package": "jdg.rodo", "priority": 1618,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_dsar_received": true, "rodo_dsar_deadline_days": 30,
    "rodo_dsar_type": request_type,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "DSAR — żądanie osoby, której dane dotyczą. Termin: 30 dni!",
    "_legal_basis": "Art. 15-22 RODO (prawa osób, których dane dotyczą)",
    "_warnings": [sprintf("DSAR — żądanie: %s. Odpowiedz w ciągu 30 dni (+30 dni przy skomplikowanych). Odmowa tylko z uzasadnieniem + pouczenie o prawie do skargi do UODO.", [request_type])]
} {
    input.jdg_entrepreneur.rodo_dsar_received == true
    request_type := object.get(input.jdg_entrepreneur, "rodo_dsar_request_type", "ACCESS")
    request_type in {"ACCESS", "RECTIFICATION", "ERASURE", "RESTRICTION", "PORTABILITY", "OBJECTION"}
}

# ══════ P1619: rodo_cookie_consent — Zgoda na cookies ══════
else := {
    "matched": true, "rule_id": "jdg.rodo.cookie_consent",
    "package": "jdg.rodo", "priority": 1619,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_cookies_active": true, "rodo_cookie_banner_required": banner_needed,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Cookies analityczne/marketingowe — wymagana zgoda przed zapisem",
    "_legal_basis": "Art. 173 Prawa telekomunikacyjnego + Art. 6 ust. 1 lit. a RODO",
    "_warnings": ["COOKIES — niezbędne techniczne OK bez zgody. Analityczne/marketingowe: WYMAGANA zgoda przed zapisem. Banner: 'zgadzam się' / 'odrzucam' — obie opcje równie widoczne!"]
} {
    input.jdg_entrepreneur.has_website == true
    has_analytics := object.get(input.jdg_entrepreneur, "website_uses_analytics_cookies", false)
    has_marketing := object.get(input.jdg_entrepreneur, "website_uses_marketing_cookies", false)
    banner_needed = has_analytics | has_marketing
    banner_needed == true
}

# ══════ P1620: rodo_data_portability — Prawo do przenoszenia danych ══════
else := {
    "matched": true, "rule_id": "jdg.rodo.data_portability",
    "package": "jdg.rodo", "priority": 1620,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_portability_required": true, "rodo_portability_format": format,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Prawo do przenoszenia danych — Art. 20 RODO",
    "_legal_basis": "Art. 20 RODO",
    "_warnings": [sprintf("PRZENOSZENIE DANYCH — format: %s. Dane muszą być w ustrukturyzowanym, powszechnie używanym formacie nadającym się do odczytu maszynowego (CSV, JSON, XML).", [format])]
} {
    input.jdg_entrepreneur.rodo_portability_requested == true
    format := object.get(input.jdg_entrepreneur, "rodo_portability_format", "CSV")
    format in {"CSV", "JSON", "XML", "PDF"}
}

# ══════ P1621: rodo_processor_agreement — Umowa powierzenia danych ══════
else := {
    "matched": true, "rule_id": "jdg.rodo.processor_agreement",
    "package": "jdg.rodo", "priority": 1621,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_processor_agreement_required": agreement_needed,
    "rodo_processor_name": processor_name,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Powierzenie danych — wymagana umowa Art. 28 RODO",
    "_legal_basis": "Art. 28 RODO",
    "_warnings": [sprintf("UMOWA POWIERZENIA DANYCH — procesor: %s. %s. Umowa musi zawierać: cel, czas, rodzaj danych, obowiązki procesora, podpowierzenie, audyt.", [processor_name, agreement_status])]
} {
    input.jdg_entrepreneur.processes_personal_data == true
    uses_external_processors := object.get(input.jdg_entrepreneur, "uses_external_processors", false)
    uses_external_processors == true
    processor_name := object.get(input.jdg_entrepreneur, "external_processor_name", "zewnętrzny procesor")

    has_agreement := object.get(input.jdg_entrepreneur, "processor_agreement_signed", false)
    agreement_needed = true
    agreement_status = "Umowa podpisana — OK" { has_agreement == true }
    agreement_status = "BRAK UMOWY — podpisz natychmiast! Kara do 10 mln EUR!" { has_agreement == false }
}
