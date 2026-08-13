# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise Policies — RODO Extended: Advanced GDPR Compliance (P1640-P1655)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: RODO Enterprise Extended — Advanced GDPR Compliance for JDG
# description: |
#   Rozszerzony pakiet Enterprise RODO dla JDG pokrywający zaawansowane obowiązki
#   ochrony danych osobowych, wykraczające poza podstawowy pakiet jdg.rodo (P1610-P1621):
#   automatyzacja prawa do usunięcia (Art. 17), audyt minimalizacji danych (Art. 5(1)(c)),
#   zarządzanie łańcuchem podprocesorów, pseudonimizacja i szyfrowanie (Art. 32),
#   ocena skutków cross-domain (RODO × PKPiR retencja, RODO × ZUS dane wrażliwe),
#   RODO w kontekście zatrudnienia (zgody, monitoring email, badanie trzeźwości),
#   RODO a marketing B2B vs B2C, profilowanie AI a Art. 22,
#   sankcje UODO — progi kar, rejestr naruszeń, odpowiedzialność administratorska.
#   Uzupełnia jdg.rodo (P1610-P1621) o 16 reguł klasy Enterprise.
# architecture: Multi-Pass Enterprise (ADR-001), companion to jdg.rodo
# legal_basis: RODO 2016/679, Ustawa o ochronie danych osobowych (Dz.U. 2019 poz. 1781),
#   Wytyczne EROD (Europejskiej Rady Ochrony Danych), Kodeks Pracy, Prawo telekomunikacyjne
# package: jdg.rodo_extended
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.rodo_extended

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.rodo_extended.no_match",
    "package": "jdg.rodo_extended",
    "priority": 1656
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1640-P1643: Automated Data Lifecycle — Prawo do usunięcia, minimalizacja║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1640: rodo_erasure_automation — Automatyzacja prawa do usunięcia (Art. 17)
decide := {
    "matched": true, "rule_id": "jdg.rodo_extended.erasure_automation",
    "package": "jdg.rodo_extended", "priority": 1640,
    "valid_from": "2018-05-25", "valid_to": null, "decision_mode": "SUGGEST",
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_erasure_requested": true, "rodo_erasure_deadline_days": 30,
    "rodo_erasure_scope": erasure_scope,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO Art.17 — żądanie usunięcia danych: %s", [erasure_scope]),
    "_legal_basis": "Art. 17 RODO (prawo do bycia zapomnianym), Art. 19 RODO (powiadomienie odbiorców)",
    "_warnings": [sprintf("[RODO] PRAWO DO USUNIĘCIA — zakres: %s. Usuń dane we wszystkich systemach (CRM, faktury, email, backup) w ciągu 30 dni. Powiadom wszystkich odbiorców (Art. 19). Wyjątek: dane księgowe (5 lat — Art. 74 UoR).", [erasure_scope])]
} {
    input.jdg_entrepreneur.processes_personal_data == true
    object.get(input.jdg_entrepreneur, "rodo_erasure_requested", false) == true
    erasure_scope := object.get(input.jdg_entrepreneur, "rodo_erasure_scope", "wszystkie dane osobowe")
}

# P1641: rodo_erasure_exception_accounting — Wyjątek: dane księgowe (kolizja RODO × UoR)
else := {
    "matched": true, "rule_id": "jdg.rodo_extended.erasure_exception_accounting",
    "package": "jdg.rodo_extended", "priority": 1641,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_erasure_exception": "UoR_RETENCJA_5_LAT",
    "rodo_deletion_restricted_until": retention_end_year,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO × UoR — dane księgowe NIE podlegają usunięciu do końca %d.", [retention_end_year]),
    "_legal_basis": "Art. 17 ust. 3 lit. b RODO (obowiązek prawny) + Art. 74 ust. 2 UoR",
    "_warnings": [sprintf("[RODO] WYJĄTEK USUNIĘCIA — dane na fakturach/rachunkach NIE podlegają usunięciu do końca %d (Art. 74 UoR — 5 lat retencji księgowej). Odpowiedz wnioskodawcy: 'dane przetwarzane na podstawie obowiązku prawnego'.", [retention_end_year])]
} {
    object.get(input.jdg_entrepreneur, "rodo_erasure_requested", false) == true
    object.get(input.invoice, "is_accounting_document", false) == true
    doc_year := object.get(input.invoice, "document_year", 2026)
    retention_end_year := doc_year + 5
    object.get(input.calendar, "year", 2026) < retention_end_year
}

# P1642: rodo_data_minimization_audit — Audyt minimalizacji danych (Art. 5(1)(c))
else := {
    "matched": true, "rule_id": "jdg.rodo_extended.data_minimization_audit",
    "package": "jdg.rodo_extended", "priority": 1642,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_minimization_audit_due": true,
    "rodo_excessive_fields": excessive_fields,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO — audyt minimalizacji: %d zbędnych pól danych", [excessive_fields]),
    "_legal_basis": "Art. 5 ust. 1 lit. c RODO (minimalizacja danych), Art. 25 RODO (privacy by design)",
    "_warnings": [sprintf("[RODO] MINIMALIZACJA DANYCH — %d pól danych przekracza niezbędne minimum. Przykład: %s. Usuń/ogranicz zbieranie w ciągu 90 dni. Privacy by Design = zbieraj TYLKO to co niezbędne!", [excessive_fields, example_field])]
} {
    input.jdg_entrepreneur.processes_personal_data == true
    excessive_fields := object.get(input.jdg_entrepreneur, "rodo_excessive_data_fields", 0)
    excessive_fields > 0
    example_field := object.get(input.jdg_entrepreneur, "rodo_excessive_field_example", "PESEL w formularzu kontaktowym")
}

# P1643: rodo_pseudonymization_encryption — Pseudonimizacja i szyfrowanie (Art. 32)
else := {
    "matched": true, "rule_id": "jdg.rodo_extended.pseudonymization_encryption",
    "package": "jdg.rodo_extended", "priority": 1643,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_encryption_required": encryption_gap,
    "rodo_pseudonymization_required": pseudonymization_gap,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO Art.32 — luka w zabezpieczeniach: szyfrowanie=%s, pseudonimizacja=%s", [encryption_status, pseudonym_status]),
    "_legal_basis": "Art. 32 RODO (bezpieczeństwo przetwarzania), Art. 25 RODO (privacy by design/default)",
    "_warnings": [sprintf("[RODO] BEZPIECZEŃSTWO DANYCH — szyfrowanie: %s. Pseudonimizacja: %s. Wdróż: AES-256 dla danych at-rest, TLS 1.3 dla danych in-transit, pseudonimizację dla analityki. Brak = kara UODO!", [encryption_status, pseudonym_status])]
} {
    input.jdg_entrepreneur.processes_personal_data == true
    has_encryption := object.get(input.jdg_entrepreneur, "rodo_encryption_active", false)
    has_pseudonym := object.get(input.jdg_entrepreneur, "rodo_pseudonymization_active", false)
    encryption_gap = not has_encryption
    pseudonymization_gap = not has_pseudonym
    encryption_status = "BRAK — wdróż natychmiast!" { has_encryption == false }
    encryption_status = "OK" { has_encryption == true }
    pseudonym_status = "BRAK — wdróż!" { has_pseudonym == false }
    pseudonym_status = "OK" { has_pseudonym == true }
    encryption_gap or pseudonymization_gap
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1644-P1647: Subprocessor Management — Łańcuch podprocesorów            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1644: rodo_subprocessor_chain_audit — Audyt łańcucha podprocesorów
else := {
    "matched": true, "rule_id": "jdg.rodo_extended.subprocessor_chain_audit",
    "package": "jdg.rodo_extended", "priority": 1644,
    "valid_from": "2018-05-25", "valid_to": null, "decision_mode": "SUGGEST",
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_subprocessor_count": sp_count,
    "rodo_subprocessor_no_agreement": sp_no_agreement_count,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO — łańcuch podprocesorów: %d łącznie, %d bez umowy!", [sp_count, sp_no_agreement_count]),
    "_legal_basis": "Art. 28 ust. 2-4 RODO (podpowierzenie), Wytyczne EROD 07/2020",
    "_warnings": [sprintf("[RODO] ŁAŃCUCH PODPROCESORÓW — %d podprocesorów, %d BEZ UMOWY POWIERZENIA! Każdy podprocesor wymaga: (1) pisemnej zgody administratora, (2) umowy powierzenia Art. 28, (3) takich samych obowiązków jak główny procesor.", [sp_count, sp_no_agreement_count])]
} {
    input.jdg_entrepreneur.processes_personal_data == true
    object.get(input.jdg_entrepreneur, "uses_external_processors", false) == true
    sp_count := object.get(input.jdg_entrepreneur, "subprocessor_count", 0)
    sp_no_agreement_count := object.get(input.jdg_entrepreneur, "subprocessor_no_agreement_count", 0)
    sp_count > 0
}

# P1645: rodo_subprocessor_third_country — Podprocesor w kraju trzecim
else := {
    "matched": true, "rule_id": "jdg.rodo_extended.subprocessor_third_country",
    "package": "jdg.rodo_extended", "priority": 1645,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_third_country_transfer": true,
    "rodo_transfer_country_name": country,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("RODO — podprocesor w kraju trzecim: %s bez zabezpieczeń!", [country]),
    "_legal_basis": "Art. 44-49 RODO (Rozdział V), Wyrok TSUE C-311/18 (Schrems II)",
    "_warnings": [sprintf("[RODO] PODPROCESOR W KRAJU TRZECIM — %s. Wymagane: SCC + DPIA + TIA (ocena skutków transferu). Bez Schrems II compliance = transfer NIELEGALNY. Kara: do 20 mln EUR!", [country])]
} {
    object.get(input.jdg_entrepreneur, "subprocessor_in_third_country", false) == true
    country := object.get(input.jdg_entrepreneur, "subprocessor_country", "USA")
    object.get(input.jdg_entrepreneur, "subprocessor_scc_signed", false) == false
}

# P1646: rodo_data_breach_register — Rejestr naruszeń (Art. 33 ust. 5)
else := {
    "matched": true, "rule_id": "jdg.rodo_extended.data_breach_register",
    "package": "jdg.rodo_extended", "priority": 1646,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_breach_register_required": true,
    "rodo_breaches_total": breach_count,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO — rejestr naruszeń: %d incydentów. Prowadź na bieżąco!", [breach_count]),
    "_legal_basis": "Art. 33 ust. 5 RODO (dokumentowanie naruszeń)",
    "_warnings": [sprintf("[RODO] REJESTR NARUSZEŃ — %d incydentów w rejestrze. Każdy wpis musi zawierać: datę, opis, skutki, działania naprawcze, decyzję o zgłoszeniu do UODO. Prowadź na bieżąco — UODO może zażądać wglądu!", [breach_count])]
} {
    input.jdg_entrepreneur.rodo_breach_register_not_maintained == true
    breach_count := object.get(input.jdg_entrepreneur, "rodo_breach_total_count", 0)
}

# P1647: rodo_processor_liability — Odpowiedzialność solidarna procesora
else := {
    "matched": true, "rule_id": "jdg.rodo_extended.processor_liability",
    "package": "jdg.rodo_extended", "priority": 1647,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_joint_liability": true,
    "rodo_data_breach_by_processor": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("RODO — naruszenie przez procesora %s. Odpowiedzialność solidarna!", [processor_name]),
    "_legal_basis": "Art. 82 RODO (odpowiedzialność solidarna), Art. 28 ust. 3 lit. f RODO",
    "_warnings": [sprintf("[RODO] ODPOWIEDZIALNOŚĆ PROCESORA — naruszenie przez %s. Jako ADMINISTRATOR ponosisz odpowiedzialność solidarną! Żądaj od procesora: audytu, raportu o naruszeniu, działań naprawczych. Roszczenie regresowe Art. 82 ust. 5.", [processor_name])]
} {
    input.jdg_entrepreneur.uses_external_processors == true
    object.get(input.jdg_entrepreneur, "processor_data_breach", false) == true
    processor_name := object.get(input.jdg_entrepreneur, "processor_name_breach", "procesor zewnętrzny")
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1648-P1651: RODO × Employment — Zatrudnienie, monitoring, zgody        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1648: rodo_employee_email_monitoring — Monitoring poczty służbowej
else := {
    "matched": true, "rule_id": "jdg.rodo_extended.employee_email_monitoring",
    "package": "jdg.rodo_extended", "priority": 1648,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_email_monitoring_active": true,
    "rodo_email_policy_required": policy_gap,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO — monitoring poczty służbowej: %d pracowników. Polityka: %s", [emp_count, policy_status]),
    "_legal_basis": "Art. 223 Kodeksu Pracy, Art. 5, 6, 88 RODO, Wyrok ETPC Barbulescu v. Romania",
    "_warnings": [sprintf("[RODO] MONITORING POCZTY — %d pracowników. %s. Wymagane: polityka monitoringu, zgoda/związek z pracą, proporcjonalność, prawo do prywatności. Zakaz monitorowania prywatnej poczty!", [emp_count, policy_status])]
} {
    input.employment.has_employees == true
    object.get(input.jdg_entrepreneur, "employee_email_monitoring_active", false) == true
    emp_count := object.get(input.employment, "employee_count", 0)
    has_policy := object.get(input.jdg_entrepreneur, "email_monitoring_policy_exists", false)
    policy_status = "BRAK POLITYKI — wdróż natychmiast!" { has_policy == false }
    policy_status = "OK — polityka wdrożona" { has_policy == true }
}

# P1649: rodo_employee_sobriety_testing — Badanie trzeźwości pracowników
else := {
    "matched": true, "rule_id": "jdg.rodo_extended.employee_sobriety_testing",
    "package": "jdg.rodo_extended", "priority": 1649,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_sobriety_testing_active": true,
    "rodo_sensitive_data_processed": "DANE_ZDROWOTNE",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO — badanie trzeźwości: %d pracowników. Dane wrażliwe!", [emp_count]),
    "_legal_basis": "Art. 22(1c) Kodeksu Pracy, Art. 9 RODO (dane szczególnej kategorii), Art. 17 Ustawy o wychowaniu w trzeźwości",
    "_warnings": [sprintf("[RODO] BADANIE TRZEŹWOŚCI — %d pracowników. To DANE WRAŻLIWE (Art. 9 RODO)! Wymagane: (1) regulamin kontroli, (2) zgoda lub obowiązek prawny, (3) rejestracja w RCP, (4) DPIA, (5) ograniczony dostęp do wyników.", [emp_count])]
} {
    input.employment.has_employees == true
    object.get(input.jdg_entrepreneur, "employee_sobriety_testing_active", false) == true
    emp_count := object.get(input.employment, "employee_count", 0)
}

# P1650: rodo_employee_consent_validity — Nieważność zgody pracowniczej
else := {
    "matched": true, "rule_id": "jdg.rodo_extended.employee_consent_validity",
    "package": "jdg.rodo_extended", "priority": 1650,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_consent_invalid": true,
    "rodo_consent_issue": consent_issue,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO — nieważna zgoda pracownicza: %s", [consent_issue]),
    "_legal_basis": "Art. 7 RODO (warunki wyrażenia zgody), Art. 4 pkt 11 RODO, Wytyczne EROD 05/2020",
    "_warnings": [sprintf("[RODO] ZGODA PRACOWNICZA — %s. Zgoda pracownika wobec pracodawcy jest domniemanie nieważna (nierównowaga stosunku pracy)! Użyj innej podstawy: obowiązek prawny (Art. 6(1)(c)) lub prawnie uzasadniony interes (Art. 6(1)(f)).", [consent_issue])]
} {
    input.employment.has_employees == true
    object.get(input.employment, "employee_consent_as_legal_basis", false) == true
    consent_issue := object.get(input.employment, "consent_validity_issue", "nierównowaga stosunku pracy — zgoda nieważna")
}

# P1651: rodo_cross_domain_retention — Cross-domain: RODO × PKPiR/ZUS retencja
else := {
    "matched": true, "rule_id": "jdg.rodo_extended.cross_domain_retention",
    "package": "jdg.rodo_extended", "priority": 1651,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_cross_domain_conflict": true,
    "rodo_retention_sources": conflicting_domains,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO × Cross-Domain — konflikt retencji między domenami: %s", [conflicting_domains]),
    "_legal_basis": "Art. 5 ust. 1 lit. e RODO (ograniczenie przechowywania) + Art. 74 UoR + Art. 147a OrdPU",
    "_warnings": [sprintf("[RODO] CROSS-DOMAIN RETENCJA — konflikt między domenami: %s. ZUS: 10 lat (dane płacowe), PKPiR: 5 lat (księgowe), RODO: 'nie dłużej niż to konieczne'. Zastosuj NAJDŁUŻSZY okres retencji = 10 lat dla danych ZUS!", [conflicting_domains])]
} {
    input.jdg_entrepreneur.processes_personal_data == true
    has_accounting_data := object.get(input.jdg_entrepreneur, "processes_accounting_data", false)
    has_employee_data := object.get(input.jdg_entrepreneur, "has_employees", false)
    has_zus_data := object.get(input.jdg_entrepreneur, "has_zus_records", false)
    (has_accounting_data and has_employee_data) or (has_zus_data and has_employee_data)
    conflicting_domains = "ZUS+RODO+PKPiR" { has_zus_data == true; has_accounting_data == true }
    conflicting_domains = "ZUS+RODO" { has_zus_data == true; has_accounting_data == false }
    conflicting_domains = "PKPiR+RODO" { has_accounting_data == true; has_zus_data == false }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1652-P1655: Profiling, AI, Sanctions                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1652: rodo_ai_profiling_art22 — Profilowanie a zautomatyzowane decyzje (Art. 22)
else := {
    "matched": true, "rule_id": "jdg.rodo_extended.ai_profiling_art22",
    "package": "jdg.rodo_extended", "priority": 1652,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_automated_decision": true,
    "rodo_ai_profiling_type": profiling_type,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("RODO Art.22 — zautomatyzowana decyzja: %s. Wymagana zgoda/umowa/przepis prawa!", [profiling_type]),
    "_legal_basis": "Art. 22 RODO (zautomatyzowane podejmowanie decyzji), Art. 35 RODO (DPIA), Wytyczne EROD",
    "_warnings": [sprintf("[RODO] AI PROFILING — %s wywołuje skutki prawne. Wymagane: (1) wyraźna zgoda lub (2) niezbędność do umowy, (3) prawo do interwencji ludzkiej, (4) prawo do wyrażenia stanowiska, (5) DPIA obowiązkowa!", [profiling_type])]
} {
    object.get(input.jdg_entrepreneur, "uses_ai_automated_decisions", false) == true
    profiling_type := object.get(input.jdg_entrepreneur, "ai_profiling_type", "scoring klientów")
    object.get(input.jdg_entrepreneur, "rodo_art22_safeguards", false) == false
}

# P1653: rodo_marketing_b2b_vs_b2c — Marketing B2B vs B2C — różne podstawy
else := {
    "matched": true, "rule_id": "jdg.rodo_extended.marketing_b2b_vs_b2c",
    "package": "jdg.rodo_extended", "priority": 1653,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_marketing_b2b_basis": b2b_basis,
    "rodo_marketing_b2c_basis": b2c_basis,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO — marketing B2B (%s) vs B2C (%s) — różne podstawy prawne!", [b2b_basis, b2c_basis]),
    "_legal_basis": "Art. 6 ust. 1 lit. f RODO (B2B — prawnie uzasadniony interes), Art. 6 ust. 1 lit. a RODO (B2C — zgoda), Art. 10 Uśude, Art. 172 PT",
    "_warnings": [sprintf("[RODO] MARKETING B2B vs B2C — B2B: %s (podstawa: prawnie uzasadniony interes + opt-out). B2C: %s (podstawa: ZGODA + opt-in). BŁĄD: używasz podstawy B2B dla B2C!", [b2b_basis, b2c_basis])]
} {
    input.jdg_entrepreneur.has_email_campaigns == true
    has_b2b := object.get(input.jdg_entrepreneur, "markets_to_b2b", false)
    has_b2c := object.get(input.jdg_entrepreneur, "markets_to_b2c", false)
    b2b_basis = "Prawnie uzasadniony interes (Art. 6(1)(f))" { has_b2b == true }
    b2b_basis = "Nie dotyczy" { has_b2b == false }
    b2c_basis = "Zgoda marketingowa (Art. 6(1)(a))" { has_b2c == true }
    b2c_basis = "Nie dotyczy" { has_b2c == false }
    uses_wrong_basis := object.get(input.jdg_entrepreneur, "uses_b2b_basis_for_b2c", false)
    uses_wrong_basis == true
}

# P1654: rodo_sanctions_uodo — Sankcje UODO — progi i kategorie
else := {
    "matched": true, "rule_id": "jdg.rodo_extended.sanctions_uodo",
    "package": "jdg.rodo_extended", "priority": 1654,
    "valid_from": "2018-05-25", "valid_to": null, "decision_mode": "SUGGEST",
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_sanction_risk": "HIGH",
    "rodo_sanction_max_pln": sanction_max,
    "rodo_sanction_category": sanction_cat,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("RODO — ryzyko sankcji UODO: %s. Max kara: %s", [sanction_cat, sanction_max]),
    "_legal_basis": "Art. 83 RODO (kary administracyjne), Art. 107-111 Ustawy o ochronie danych osobowych",
    "_warnings": [sprintf("[RODO] SANKCJA UODO — naruszenie: %s. Maksymalna kara: %s. %s. Natychmiastowe działania naprawcze mogą obniżyć karę o 50%% (współpraca z UODO)!", [sanction_cat, sanction_max, violation_desc])]
} {
    object.get(input.jdg_entrepreneur, "rodo_violation_detected", false) == true
    violation_type := object.get(input.jdg_entrepreneur, "rodo_violation_type", "DATA_BREACH_UNREPORTED")

    sanction_max = "10 000 000 EUR lub 2% rocznego obrotu" {
        violation_type in {"NO_DPO", "NO_RECORDS", "NO_DPIA", "NO_BREACH_REGISTER"}
    }
    sanction_max = "20 000 000 EUR lub 4% rocznego obrotu" {
        violation_type in {"NO_CONSENT", "DATA_BREACH_UNREPORTED", "ILLEGAL_TRANSFER", "NO_ERASURE", "VIOLATION_DATA_PRINCIPLES"}
    }

    sanction_cat = "Brak IOD/rejestru" { violation_type == "NO_DPO" }
    sanction_cat = "Brak DPIA" { violation_type == "NO_DPIA" }
    sanction_cat = "Naruszenie niezgłoszone" { violation_type == "DATA_BREACH_UNREPORTED" }
    sanction_cat = "Nielegalny transfer danych" { violation_type == "ILLEGAL_TRANSFER" }
    sanction_cat = "Przetwarzanie bez zgody" { violation_type == "NO_CONSENT" }
    sanction_cat = "Naruszenie zasad RODO" { violation_type == "VIOLATION_DATA_PRINCIPLES" }

    violation_desc = "Art. 83 ust. 4 RODO — niższy próg" { sanction_max == "10 000 000 EUR lub 2% rocznego obrotu" }
    violation_desc = "Art. 83 ust. 5 RODO — WYŻSZY PRÓG!" { sanction_max == "20 000 000 EUR lub 4% rocznego obrotu" }
}

# P1655: rodo_annual_compliance_review — Roczny przegląd zgodności RODO
else := {
    "matched": true, "rule_id": "jdg.rodo_extended.annual_compliance_review",
    "package": "jdg.rodo_extended", "priority": 1655,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rodo_annual_review_due": true,
    "rodo_compliance_score_pct": compliance_score,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO — roczny przegląd zgodności. Score: %.0f%%", [compliance_score]),
    "_legal_basis": "Art. 24 ust. 1 RODO (odpowiedzialność administratora), Art. 32 ust. 1 lit. d RODO",
    "_warnings": [sprintf("[RODO] ROCZNY PRZEGLĄD RODO — wynik zgodności: %.0f%%. Obszary do poprawy: %s. Przeprowadź przegląd do końca kwartału + udokumentuj wnioski (accountability — Art. 5(2) RODO).", [compliance_score, gap_areas])]
} {
    input.jdg_entrepreneur.processes_personal_data == true
    compliance_score := object.get(input.jdg_entrepreneur, "rodo_compliance_score_pct", 50)
    input.calendar.month == 12
    gap_areas := object.get(input.jdg_entrepreneur, "rodo_gap_areas", "zgody, retencja, zabezpieczenia")
    compliance_score < 90
}

# ── Fallback ──────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.rodo_extended.fallback",
    "package": "jdg.rodo_extended", "priority": 1699,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "RODO 2016/679",
    "_warnings": ["[RODO] RODO Extended — zaawansowana zgodność w normie. Brak naruszeń wysokiego ryzyka."]
} { true }
