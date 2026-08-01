# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ePUAP/e-DORECZENIA INTEGRATION MODULE (FAZA 3)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
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

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.epuap.no_match",
    "package": "jdg.epuap", "priority": 9999
}

# v7.0 (P18 LUKA-D5): Helper to calculate pending days from sent date to eval date
calculate_pending_days(sent_date, eval_date) = days {
    sent_year := to_number(substring(sent_date, 0, 4))
    eval_year := to_number(substring(eval_date, 0, 4))
    sent_month := to_number(substring(sent_date, 5, 7))
    eval_month := to_number(substring(eval_date, 5, 7))
    sent_day := to_number(substring(sent_date, 8, 10))
    eval_day := to_number(substring(eval_date, 8, 10))
    # Simplified day calculation (assumes months ~30 days each)
    days := (eval_year - sent_year) * 365 + (eval_month - sent_month) * 30 + (eval_day - sent_day)
    days := max([days, 1])
}

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
        sprintf("   UPO otrzymane: %s", ["TAK" { upo_received } else "NIE"]),
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
    oldest_pending := precomputed_oldest { precomputed_oldest >= 0; pending_count > 0 }
    oldest_pending := calculate_pending_days(oldest_date, current_eval_date) { precomputed_oldest < 0; pending_count > 0; oldest_date != "" }
    oldest_pending := 0 { pending_count == 0 }
    
    next_response := "W ciagu 14 dni" { pending_count > 0 }
    next_response := "Brak oczekujacych" { pending_count == 0 }
    
    epuap_routing := "TRIAGE_QUEUE" { oldest_pending > 30 }
    epuap_routing := "" { true }
    epuap_reason := sprintf("Doreczenie sprzed %d dni bez UPO — sprawdz status!", [oldest_pending]) { oldest_pending > 30 }
    epuap_reason := "" { true }
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
    
    send_routing := "TRIAGE_QUEUE" { true }
    send_reason := "Wyslij dokument przez ePUAP — zachowaj UPO!" { true }
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
        sprintf("   Czynny zal (S22): %s", ["GOTOWY" { vd_ready } else "—"]),
        sprintf("   Odwolanie (S4): %s", ["GOTOWE" { appeal_ready } else "—"]),
        sprintf("   Interpretacja (S22): %s", ["GOTOWA" { wip_ready } else "—"]),
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
    
    total_letters := 0
    total_letters := total_letters + 1 { vd_ready }
    total_letters := total_letters + 1 { appeal_ready }
    total_letters := total_letters + 1 { wip_ready }
    
    int_routing := "BLOCK_AND_ALERT" { total_letters >= 3 }
    int_routing := "TRIAGE_QUEUE" { total_letters > 0 }
    int_routing := "" { true }
    int_reason := sprintf("%d pism do natychmiastowej wysylki przez ePUAP!", [total_letters]) { total_letters > 0 }
    int_reason := "" { true }
}
