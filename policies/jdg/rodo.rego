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
