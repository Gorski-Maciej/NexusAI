# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ePUAP/e-DORECZENIA INTEGRATION MODULE (FAZA 3)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Enterprise metadata is documented in comments below.
# title: JDG Enterprise ePUAP/e-Doreczenia Integration
# description: |
#   ENTERPRISE v7.0 — Moduł automatycznych doręczeń przez ePUAP/e-Doręczenia.
#   Integruje elektroniczną korespondencję z US, KAS, ZUS, KIS, CEIDG.
#
#   KLUCZOWE FUNKCJE:
#   - Automatyczne doręczenia pism do organów (US, KAS, ZUS, CEIDG)
#   - Śledzenie statusu doręczeń (UPO/UPD)
#   - Szablony pism: czynny żal, odwołanie, wniosek interpretacyjny
#   - Walidacja podpisów (profil zaufany / podpis kwalifikowany)
#   - Terminy odpowiedzi organów (monitoring)
#   - Integracja z S22 (Tax Authority Interaction) i S4 (Audit Defense)
#
# architecture: Enterprise v7.0 ePUAP Gateway
# legal_basis: Art. 144-144c OrdPU; Ustawa o e-Doreczeniach; KPA Art. 39
# package: jdg.epuap
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.epuap

upo_label(received) = "TAK" {
    received == true
} else = "NIE" {
    received == false
}

pending_days_for(precomputed, pending_count, oldest_date, current_eval_date) = precomputed {
    precomputed >= 0
    pending_count > 0
} else = calculate_pending_days(oldest_date, current_eval_date) {
    precomputed < 0
    pending_count > 0
    oldest_date != ""
} else = 0 {
    pending_count == 0
}

response_for(pending_count) = "W ciagu 14 dni" {
    pending_count > 0
} else = "Brak oczekujacych" {
    pending_count == 0
}

routing_for(oldest_pending) = "TRIAGE_QUEUE" {
    oldest_pending > 30
} else = "" {
    oldest_pending <= 30
}

reason_for(oldest_pending) = reason {
    oldest_pending > 30
    reason := sprintf("Doreczenie sprzed %d dni bez UPO — sprawdz status!", [oldest_pending])
} else = "" {
    oldest_pending <= 30
}

ready_label(ready, label) = label {
    ready == true
} else = "—" {
    ready == false
}

letter_count(vd_ready, appeal_ready, wip_ready) = 3 {
    vd_ready == true
    appeal_ready == true
    wip_ready == true
} else = 2 {
    [vd_ready, appeal_ready, wip_ready][0] == true
    [vd_ready, appeal_ready, wip_ready][1] == true
    [vd_ready, appeal_ready, wip_ready][2] == false
} else = 2 {
    [vd_ready, appeal_ready, wip_ready][0] == true
    [vd_ready, appeal_ready, wip_ready][1] == false
    [vd_ready, appeal_ready, wip_ready][2] == true
} else = 2 {
    [vd_ready, appeal_ready, wip_ready][0] == false
    [vd_ready, appeal_ready, wip_ready][1] == true
    [vd_ready, appeal_ready, wip_ready][2] == true
} else = 1 {
    count([x | x := [vd_ready, appeal_ready, wip_ready][_]; x == true]) == 1
} else = 0 {
    vd_ready == false
    appeal_ready == false
    wip_ready == false
}

integration_routing(total_letters) = "BLOCK_AND_ALERT" {
    total_letters >= 3
} else = "TRIAGE_QUEUE" {
    total_letters > 0
    total_letters < 3
} else = "" {
    total_letters == 0
}

integration_reason(total_letters) = reason {
    total_letters > 0
    reason := sprintf("%d pism do natychmiastowej wysylki przez ePUAP!", [total_letters])
} else = "" {
    total_letters == 0
}

default decide := {
    "matched": false, "rule_id": "jdg.epuap.no_match",
    "package": "jdg.epuap", "priority": 9999
}

# v7.0 (P18 LUKA-D5): Helper to calculate pending days from sent date to eval date
calculate_pending_days(sent_date, eval_date) = max([
    (to_number(substring(eval_date, 0, 4)) - to_number(substring(sent_date, 0, 4))) * 365
        + (to_number(substring(eval_date, 5, 7)) - to_number(substring(sent_date, 5, 7))) * 30
        + to_number(substring(eval_date, 8, 10)) - to_number(substring(sent_date, 8, 10)),
    1,
])

# ═══════════════════════════════════════════════════════════════════════════════
# EPU-100: ePUAP DELIVERY STATUS CHECK — Status doręczeń elektronicznych
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.epuap.delivery_status",
    "package": "jdg.epuap",
    "priority": 100,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "epuap_pending_deliveries": pending_count,
    "epuap_upo_received": upo_received,
    "epuap_oldest_pending_days": oldest_pending,
    "epuap_next_expected_response": next_response,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": epuap_routing,
    "_routing_reason": epuap_reason,
    "_legal_basis": "Art. 144-144c OrdPU; Art. 13-28 ustawy o e-Doreczeniach",
    "_warnings": [
        sprintf("📬 ePUAP/e-DORECZENIA — STATUS", []),
        sprintf("   Oczekujace doreczenia: %d", [pending_count]),
        sprintf("   UPO otrzymane: %s", [upo_label(upo_received)]),
        sprintf("   Najstarsze oczekujace: %d dni", [oldest_pending]),
        sprintf("   Nastepna oczekiwana odpowiedz: %s", [next_response])
    ]
} {
    input.epuap_status_check == true
    pending_deliveries := object.get(input.jdg_entrepreneur, "epuap_pending_documents", [])
    pending_count := count(pending_deliveries)
    upo_received := pending_count > 0

    oldest_doc := object.get(pending_deliveries, 0, {})
    oldest_date := object.get(oldest_doc, "sent_date", "2026-07-01")
    # v7.0 FIX (P18 LUKA-D5): Dynamic oldest_pending from input or calculated from sent_date
    precomputed_oldest := object.get(input, "epuap_oldest_pending_days", -1)
    current_eval_date := object.get(input, "evaluation_date", "2026-07-01")
    oldest_pending := pending_days_for(precomputed_oldest, pending_count, oldest_date, current_eval_date)
    next_response := response_for(pending_count)
    epuap_routing := routing_for(oldest_pending)
    epuap_reason := reason_for(oldest_pending)
}

# ═══════════════════════════════════════════════════════════════════════════════
# EPU-200: ePUAP SENDING INSTRUCTIONS — Instrukcje wysyłki przez ePUAP
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.epuap.sending_instructions",
    "package": "jdg.epuap",
    "priority": 200,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "epuap_document_type": doc_type,
    "epuap_recipient_box": recipient_box,
    "epuap_signature_required": signature_type,
    "epuap_attachments_max_size_mb": 5,
    "epuap_skrytka_url": "https://epuap.gov.pl",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": send_routing,
    "_routing_reason": send_reason,
    "_legal_basis": "Art. 144 OrdPU; Rozporzadzenie MAiC ws. e-Doreczen; Art. 39 KPA",
    "_warnings": [
        sprintf("📨 INSTRUKCJA WYSYLKI ePUAP", []),
        sprintf("   Dokument: %s", [doc_type]),
        sprintf("   Adresat: %s", [recipient_box]),
        sprintf("   Podpis: %s", [signature_type]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "📋 KROKI:",
        "   1. Zaloguj się na epuap.gov.pl",
        "   2. Wybierz 'Nowe pismo ogolne'",
        "   3. Wpisz adres skrytki odbiorcy",
        "   4. Dolacz dokument + zalaczniki",
        "   5. Podpisz (profil zaufany / podpis kwalifikowany)",
        "   6. Wyslij i zachowaj UPO (Urzedowe Potwierdzenie Odbioru)",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "💡 Doreczenie uznaje sie za skuteczne w momencie odebrania UPO!"
    ]
} {
    input.epuap_send_instructions == true
    doc_type := object.get(input, "epuap_document_type", "CZYNNY_ZAL")
    target_office := object.get(input.jdg_entrepreneur, "tax_office_code", "1471")
    
    recipient_box := sprintf("/US%s/SkrytkaESP", [target_office])
    signature_type := "Profil Zaufany / e-Dowod / Podpis Kwalifikowany"
    
    send_routing := "TRIAGE_QUEUE"
    send_reason := "Wyslij dokument przez ePUAP — zachowaj UPO!"
}

# ═══════════════════════════════════════════════════════════════════════════════
# EPU-300: ePUAP × S22 × S4 INTEGRATION — Automatyzacja pism
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.epuap.integration_s22_s4",
    "package": "jdg.epuap",
    "priority": 300,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "epuap_vd_letter_ready": vd_ready,
    "epuap_appeal_letter_ready": appeal_ready,
    "epuap_interpretation_request_ready": wip_ready,
    "epuap_all_letters_count": total_letters,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": int_routing,
    "_routing_reason": int_reason,
    "_legal_basis": "Art. 16 KKS; Art. 220 OrdPU; Art. 14b OrdPU; ePUAP API",
    "_warnings": [
        sprintf("🔗 ePUAP × S22 × S4 — INTEGRACJA", []),
        sprintf("   Czynny zal (S22): %s", [ready_label(vd_ready, "GOTOWY")]),
        sprintf("   Odwolanie (S4): %s", [ready_label(appeal_ready, "GOTOWE")]),
        sprintf("   Interpretacja (S22): %s", [ready_label(wip_ready, "GOTOWA")]),
        sprintf("   Lacznie pism do wyslania: %d", [total_letters])
    ]
} {
    input.epuap_integration_check == true
    has_vd := object.get(input.jdg_entrepreneur, "has_unpaid_tax", false)
    has_appeal := object.get(input.jdg_entrepreneur, "audit_appeal_needed", false)
    needs_interpretation := object.get(input.jdg_entrepreneur, "tax_interaction_interpretation_needed", false)
    
    vd_ready := has_vd
    appeal_ready := has_appeal
    wip_ready := needs_interpretation
    
    total_letters := letter_count(vd_ready, appeal_ready, wip_ready)
    int_routing := integration_routing(total_letters)
    int_reason := integration_reason(total_letters)
}
