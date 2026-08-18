# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — WDT DOCUMENT TRACKER (P13 Priority 1)
# ═══════════════════════════════════════════════════════════════════════════════
# Package:     jdg.wdt_document_tracker
# Report:      RAPORT_P13 Section 7 — Priority 1
# Purpose:     Automatic WDT document tracking with 25-day alert before 30-day deadline
#              Brak dokumentów = 23% zamiast 0% VAT!
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.wdt_document_tracker

import data.jdg.thresholds
import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.wdt_document_tracker.no_match",
    "package": "jdg.wdt_document_tracker",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# WDT-001: WDT DOCUMENT TRACKING — Alert 25 dni przed terminem 30 dni
# Monitoruje status dokumentów WDT i generuje alerty eskalacji
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    input.invoice.procedure == "WDT"
    vendor_country := object.get(input.vendor, "country", "PL")
    vendor_country != "PL"

    has_transport_docs := object.get(input.invoice, "has_transport_docs", false)
    days_since_invoice := object.get(input.invoice, "days_since_issue", 0)
    transport_docs_date := object.get(input.invoice, "transport_docs_received_date", "")
    docs_received := transport_docs_date != ""

    deadline_days := object.get(data.jdg.thresholds.ksef_jpk_edeklaracje, "wdt_deadline_days", 30)
    days_remaining := deadline_days - days_since_invoice

    alert_level := "OK" { has_transport_docs }
    alert_level := "GREEN" { not has_transport_docs; days_remaining > object.get(data.jdg.thresholds.ksef_jpk_edeklaracje, "wdt_alert_days", 25) }
    alert_level := "YELLOW_25_DAYS_WARNING" { not has_transport_docs; days_remaining <= object.get(data.jdg.thresholds.ksef_jpk_edeklaracje, "wdt_alert_days", 25); days_remaining > 15 }
    alert_level := "ORANGE_15_DAYS_CRITICAL" { not has_transport_docs; days_remaining <= 15; days_remaining > 5 }
    alert_level := "RED_5_DAYS_URGENT" { not has_transport_docs; days_remaining <= 5; days_remaining > 0 }
    alert_level := "EXPIRED_23PCT_VAT" { not has_transport_docs; days_remaining <= 0 }

    vat_rate_if_expired := "23%"
    vat_rate_if_ok := "0%"
    effective_vat_rate := vat_rate_if_ok { has_transport_docs or days_remaining > 0 }
    effective_vat_rate := vat_rate_if_expired { not has_transport_docs; days_remaining <= 0 }

    penalty_risk_pln := floor(object.get(input.invoice, "amount_net", 0) * 0.23 * 100) / 100 { not has_transport_docs; days_remaining <= 0 }
    penalty_risk_pln := 0 { true }

    required_docs := [
        "Faktura sprzedaży",
        "CMR / list przewozowy / dokument przewozowy",
        "Potwierdzenie odbioru przez nabywcę w kraju UE",
        "Specyfikacja towarów"
    ]

    routing := ""
    routing := "BLOCK_AND_ALERT" { alert_level == "EXPIRED_23PCT_VAT" }
    routing := "BLOCK_AND_ALERT" { alert_level == "RED_5_DAYS_URGENT" }
    routing := "TRIAGE_QUEUE" { alert_level == "ORANGE_15_DAYS_CRITICAL" }
    routing := "WARNING" { alert_level == "YELLOW_25_DAYS_WARNING" }

    wdt_next_action := "Documents OK — WDT 0% applies" { has_transport_docs }
    wdt_next_action := sprintf("⚠️ %d days remaining — collect transport documents!", [days_remaining]) { not has_transport_docs; days_remaining > 0 }
    wdt_next_action := sprintf("🚨 DEADLINE EXPIRED! WDT 23%% applies! Penalty: %.0f PLN", [penalty_risk_pln]) { not has_transport_docs; days_remaining <= 0 }

    verdict := {
        "matched": true,
        "rule_id": "jdg.wdt_document_tracker.doc_tracking",
        "package": "jdg.wdt_document_tracker",
        "priority": 18101,
        "wdt_has_docs": has_transport_docs,
        "wdt_days_since_invoice": days_since_invoice,
        "wdt_days_remaining": days_remaining,
        "wdt_deadline_days": deadline_days,
        "wdt_alert_level": alert_level,
        "wdt_effective_vat_rate": effective_vat_rate,
        "wdt_penalty_risk_pln": penalty_risk_pln,
        "wdt_required_docs": required_docs,
        "wdt_next_action": wdt_next_action,
        "_routing": routing,
        "_routing_reason": sprintf("WDT Docs: %s — %d/%d days. VAT: %s. Risk: %.0f PLN", [alert_level, days_remaining, deadline_days, effective_vat_rate, penalty_risk_pln]),
        "_legal_basis": "Art. 13 VAT; Art. 42 ust. 1 pkt 2 VAT",
        "_description": "WDT-001: Document tracker — alert 25 days before 30-day WDT deadline"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WDT-002: WDT VIES CROSS-CHECK
# Weryfikacja statusu NIP-UE nabywcy przez VIES i powiązanie z WDT
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.procedure == "WDT"
    vendor_country := object.get(input.vendor, "country", "PL")
    vendor_country != "PL"

    vendor_nip_eu := object.get(input.vendor, "nip_eu", "")
    vendor_vat_active := object.get(input.vendor, "vat_status", "") == "ACTIVE"
    vies_verified := object.get(input.vendor, "vies_verified", false)

    needs_vies_check := vendor_nip_eu != "" and not vies_verified

    vies_status := "VERIFIED" { vies_verified }
    vies_status := "PENDING_CHECK" { needs_vies_check }
    vies_status := "NO_NIP_EU" { vendor_nip_eu == "" }

    routing := "TRIAGE_QUEUE" { needs_vies_check }
    routing := "" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.wdt_document_tracker.vies_cross_check",
        "package": "jdg.wdt_document_tracker",
        "priority": 18102,
        "wdt_vendor_nip_eu": vendor_nip_eu,
        "wdt_vies_status": vies_status,
        "wdt_vies_verified": vies_verified,
        "wdt_needs_vies": needs_vies_check,
        "wdt_vies_url": "ec.europa.eu/taxation_customs/vies",
        "_routing": routing,
        "_routing_reason": sprintf("WDT VIES: %s — %s", [vendor_nip_eu, vies_status]),
        "_legal_basis": "Art. 13, 97 VAT; VIES Regulation",
        "_description": "WDT-002: VIES cross-check for WDT buyer — verify VAT number before 0% applies"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WDT-003: WDT ACCELERATED REFUND READINESS (25-day)
# Sprawdza warunki dla przyśpieszonego zwrotu VAT 25 dni zamiast 60
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.procedure == "WDT"
    has_transport_docs := object.get(input.invoice, "has_transport_docs", false)
    all_purchases_paid := object.get(input.invoice, "all_purchases_paid_by_transfer", false)
    has_bank_account := object.get(input.jdg_entrepreneur, "bank_account_reported_to_us", false)

    qualifies_25day := has_transport_docs and all_purchases_paid and has_bank_account
    standard_refund := 60
    accelerated_refund := 25
    refund_days := accelerated_refund { qualifies_25day }
    refund_days := standard_refund { not qualifies_25day }

    missing_conditions := []
    missing_conditions := array.concat(missing_conditions, ["transport documents"]) { not has_transport_docs }
    missing_conditions := array.concat(missing_conditions, ["all purchases paid by bank transfer"]) { not all_purchases_paid }
    missing_conditions := array.concat(missing_conditions, ["bank account reported to US"]) { not has_bank_account }

    verdict := {
        "matched": true,
        "rule_id": "jdg.wdt_document_tracker.accelerated_refund",
        "_legal_basis": "Art. 13 VAT; Art. 42 ust. 1 pkt 2 VAT",
        "package": "jdg.wdt_document_tracker",
        "priority": 18103,
        "wdt_qualifies_25day": qualifies_25day,
        "wdt_refund_days": refund_days,
        "wdt_standard_refund": standard_refund,
        "wdt_accelerated_refund": accelerated_refund,
        "wdt_missing_conditions": missing_conditions,
        "_routing": "",
        "_routing_reason": sprintf("WDT Refund: %d days (%s)", [refund_days, "ACCELERATED 25 days!" { qualifies_25day } else "standard 60 days"]),
        "_legal_basis": "Art. 87 ust. 6 VAT",
        "_description": "WDT-003: Accelerated 25-day VAT refund readiness check for WDT"
    }
}
