# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE KSeF UPO TRACKER (Innovation 8.8, P18 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise KSeF UPO Tracker — Per-Invoice UPO Lifecycle
# description: |
#   ENTERPRISE v7.0 — Dedykowany tracker UPO (Urzędowe Poświadczenie Odbioru)
#   dla każdej faktury wysłanej do KSeF. Wypełnia lukę K15/K16 z raportu P18.
#
#   KLUCZOWE FUNKCJE:
#   - Status UPO per faktura: PENDING / ACCEPTED / REJECTED / MISSING
#   - Alert o brakującym UPO przed terminem odliczenia VAT
#   - Powiązanie UPO z ewidencją zakupów JPK_V7 (zakup bez UPO = ryzyko)
#   - Retencja UPO 5 lat + metadane (hash, timestamp odbioru)
#   - Weryfikacja UPO przez API KSeF
#
#   LUKI ZAMKNIĘTE: K15 (brak trackera), K16 (UPO a odliczenie VAT w zakupach)
# architecture: Enterprise v7.0 First-Match-Wins
# legal_basis: Art. 106nc VAT; Art. 86 ust. 10b pkt 1 VAT
# package: jdg.ksef_upo_tracker
# deprecated: false
# priority_range: 2000-2029
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.ksef_upo_tracker

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.ksef_upo_tracker.no_match",
    "package": "jdg.ksef_upo_tracker", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# UPO-2000: UPO STATUS CHECK — Sprawdzenie statusu UPO per faktura
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.ksef_upo_tracker.upo_status_check",
    "package": "jdg.ksef_upo_tracker",
    "priority": 2000,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "upo_invoice_reference": invoice_ref,
    "upo_status": upo_status,
    "upo_received_at": upo_timestamp,
    "upo_hash": upo_hash,
    "upo_retention_years": 5,
    "upo_vat_deduction_blocked": vat_blocked,
    "_routing": upo_routing,
    "_routing_reason": upo_routing_reason,
    "_legal_basis": "Art. 106nc VAT; Art. 86 ust. 10b pkt 1 VAT (UPO warunkiem odliczenia)",
    "_warnings": build_upo_warnings(invoice_ref, upo_status, vat_blocked, upo_timestamp)
} {
    input.upo_tracker_check == true
    invoice_ref := object.get(input.invoice, "ksef_number", object.get(input.invoice, "invoice_number", ""))
    upo_received := object.get(input.invoice, "upo_received", false)
    upo_timestamp := object.get(input.invoice, "upo_timestamp", "")
    upo_hash := object.get(input.invoice, "upo_xml_hash", "")

    upo_status := "MISSING" { not upo_received; upo_hash == "" }
    upo_status := "PENDING" { not upo_received; upo_hash != "" }
    upo_status := "ACCEPTED" { upo_received }
    upo_status := "REJECTED" { object.get(input.invoice, "upo_rejected", false) }

    # VAT odliczenie zablokowane bez UPO dla zakupów
    direction := object.get(input.invoice, "direction", "")
    is_purchase := direction == "PURCHASE"
    vat_blocked := is_purchase and not upo_received

    upo_routing := "BLOCK_AND_ALERT" { upo_status == "MISSING"; is_purchase }
    upo_routing := "TRIAGE_QUEUE" { upo_status == "PENDING"; is_purchase }
    upo_routing := "" { true }
    upo_routing_reason := sprintf("ZAKUP bez UPO — faktura %s: brak UPO blokuje odliczenie VAT! Wyślij do KSeF i pobierz UPO.", [invoice_ref]) { vat_blocked; upo_status == "MISSING" }
    upo_routing_reason := sprintf("UPO oczekujące — faktura %s: UPO jeszcze niepotwierdzone.", [invoice_ref]) { upo_status == "PENDING"; is_purchase }
    upo_routing_reason := "" { true }
}

build_upo_warnings(invoice_ref, status, vat_blocked, timestamp) = warnings {
    status == "MISSING"
    warnings := [
        sprintf("🚨 UPO MISSING — faktura %s: BRAK Urzędowego Poświadczenia Odbioru!", [invoice_ref]),
        "⚠️ Bez UPO NIE MOŻNA odliczyć VAT naliczonego od zakupów (Art. 86 ust. 10b pkt 1 VAT)!",
        "📋 DZIAŁANIE: Wyślij fakturę do KSeF → pobierz UPO → zapisz w archiwum (5 lat retencji)."
    ]
} else = warnings {
    status == "PENDING"
    warnings := [
        sprintf("⏳ UPO PENDING — faktura %s: UPO zostało wysłane, oczekuje na potwierdzenie KSeF.", [invoice_ref]),
        "📋 Sprawdź status za 5-30 minut. UPO powinno przyjść automatycznie po akceptacji przez KSeF."
    ]
} else = warnings {
    status == "ACCEPTED"
    warnings := [sprintf("✅ UPO ACCEPTED — faktura %s: odebrano %s. VAT można odliczyć. Retencja: 5 lat.", [invoice_ref, timestamp])]
} else = warnings {
    status == "REJECTED"
    warnings := [sprintf("🔴 UPO REJECTED — faktura %s: KSeF odrzucił fakturę! Sprawdź błędy walidacji i popraw XML przed ponowną wysyłką.", [invoice_ref])]
}

# ═══════════════════════════════════════════════════════════════════════════════
# UPO-2005: UPO BATCH DASHBOARD — Przegląd statusów UPO dla wszystkich faktur okresu
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_upo_tracker.upo_batch_dashboard",
    "package": "jdg.ksef_upo_tracker",
    "priority": 2005,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "upo_period": period,
    "upo_total_invoices": total,
    "upo_accepted": accepted,
    "upo_pending": pending,
    "upo_missing": missing,
    "upo_rejected": rejected,
    "upo_vat_at_risk": vat_at_risk,
    "_routing": dashboard_routing,
    "_routing_reason": dashboard_reason,
    "_legal_basis": "Art. 106nc VAT; Art. 86 ust. 10b pkt 1 VAT",
    "_warnings": build_dashboard_warnings(period, total, accepted, pending, missing, rejected, vat_at_risk)
} {
    input.upo_dashboard_check == true
    period := object.get(input, "upo_period", "2026-07")
    total := object.get(input, "upo_total_invoices", 0)
    accepted := object.get(input, "upo_accepted_count", 0)
    pending := object.get(input, "upo_pending_count", 0)
    missing := object.get(input, "upo_missing_count", 0)
    rejected := object.get(input, "upo_rejected_count", 0)
    vat_at_risk := object.get(input, "upo_vat_at_risk_pln", 0)

    dashboard_routing := "BLOCK_AND_ALERT" { missing + rejected > total * 0.5; total > 0 }
    dashboard_routing := "TRIAGE_QUEUE" { (missing + pending) > 0 }
    dashboard_routing := "" { true }
    dashboard_reason := sprintf("ALERT: %d/%d faktur bez UPO — VAT %.0f PLN zagrożony!", [missing + rejected, total, vat_at_risk]) { missing + rejected > 0 }
    dashboard_reason := "" { true }
}

build_dashboard_warnings(period, total, accepted, pending, missing, rejected, vat_risk) = warnings {
    warnings := [
        sprintf("📊 UPO DASHBOARD — OKRES %s", [period]),
        sprintf("   Faktur łącznie: %d", [total]),
        sprintf("   ✅ Zaakceptowane: %d | ⏳ Oczekujące: %d", [accepted, pending]),
        sprintf("   🚨 Brak UPO: %d | 🔴 Odrzucone: %d", [missing, rejected]),
        sprintf("   💰 VAT zagrożony (bez UPO): %.0f PLN", [vat_risk]),
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# UPO-2010: UPO-VAT DEDUCTION GATE — Brama odliczenia VAT zależna od UPO
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_upo_tracker.upo_vat_deduction_gate",
    "package": "jdg.ksef_upo_tracker",
    "priority": 2010,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "upo_vat_deduction_allowed": deduction_allowed,
    "upo_vat_blocked_amount": blocked_vat,
    "upo_vat_allowed_amount": allowed_vat,
    "_routing": gate_routing,
    "_routing_reason": gate_reason,
    "_legal_basis": "Art. 86 ust. 10b pkt 1 VAT (UPO warunek odliczenia VAT naliczonego)",
    "_warnings": build_gate_warnings(deduction_allowed, blocked_vat, allowed_vat)
} {
    input.upo_vat_deduction_gate == true
    input.invoice.direction == "PURCHASE"
    invoice_vat := object.get(input.invoice, "amount_vat", 0)
    upo_ok := object.get(input.invoice, "upo_received", false)

    deduction_allowed := upo_ok
    allowed_vat := invoice_vat { upo_ok }
    allowed_vat := 0 { not upo_ok }
    blocked_vat := invoice_vat { not upo_ok }
    blocked_vat := 0 { upo_ok }

    gate_routing := "BLOCK_AND_ALERT" { not upo_ok; invoice_vat > 0 }
    gate_routing := "" { true }
    gate_reason := sprintf("UPO GATE: VAT %.0f PLN zablokowany — faktura zakupu bez UPO z KSeF!", [blocked_vat]) { not upo_ok; invoice_vat > 0 }
    gate_reason := "" { true }
}

build_gate_warnings(ok, blocked_vat, allowed_vat) = warnings {
    ok == true
    warnings := [sprintf("✅ UPO GATE: VAT %.0f PLN — odliczenie DOZWOLONE (UPO potwierdzone).", [allowed_vat])]
} else = warnings {
    blocked_vat > 0
    warnings := [
        sprintf("🚫 UPO GATE: VAT %.0f PLN ZABLOKOWANY — odliczenie wstrzymane do czasu otrzymania UPO!", [blocked_vat]),
        "📋 Wyślij fakturę do KSeF, pobierz UPO, następnie odblokuj odliczenie VAT."
    ]
} else = ["✅ UPO GATE: brak VAT do odliczenia."]
