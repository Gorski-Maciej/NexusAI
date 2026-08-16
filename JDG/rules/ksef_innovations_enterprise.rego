# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — KSeF INNOWACJE ENTERPRISE (P18 Raport v7.0 Wdrożenie)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise KSeF Innovations — Sanction Exposure, UPO Tracker, Receipt Digest, Outbox Buffer
# description: |
#   ENTERPRISE v7.0 — Innowacje wyprzedzające z raportu P18:
#   - Innowacja 8.8: UPO Tracker per faktura
#   - Innowacja 8.9: Sanction Exposure Calculator
#   - Innowacja 8.10: Zero-Downtime KSeF Buffer (Outbox)
#   - LUKA-K18: KSeF Receipt Digest (odbiór faktur kosztowych)
#   - LUKA-K16: UPO a odliczenie VAT w ewidencji zakupów
# architecture: Enterprise Innovation Engine, First-Match-Wins else-chain
# legal_basis: Art. 106na-106nq VAT; Art. 86 VAT (odliczenie); Art. 106ne VAT
# package: jdg.ksef_innovations
# deprecated: false
# priority_range: 1650-1699
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.ksef_innovations

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.ksef_innovations.no_match",
    "package": "jdg.ksef_innovations", "priority": 9999,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false
}

# ═══════════════════════════════════════════════════════════════════════════════
# KIN-1650: UPO TRACKER — Śledzenie UPO per faktura (Innowacja 8.8)
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.ksef_innovations.upo_tracker",
    "package": "jdg.ksef_innovations",
    "priority": 1650,
    "ksef_upo_tracker_active": true,
    "ksef_upo_invoice_id": invoice_id,
    "ksef_upo_status": upo_status,
    "ksef_upo_received_at": upo_received_at,
    "ksef_upo_hash": upo_hash,
    "ksef_upo_days_since_send": days_since_send,
    "ksef_upo_alert_level": alert_level,
    "_routing": upo_routing,
    "_routing_reason": upo_routing_reason,
    "_legal_basis": "Art. 106nc VAT (UPO); Art. 106ne VAT (tryb awaryjny)",
    "_warnings": build_upo_warnings(invoice_id, upo_status, days_since_send, alert_level)
} {
    input.ksef_upo_track == true
    invoice_id := object.get(input.invoice, "ksef_number", object.get(input.invoice, "invoice_number", "UNKNOWN"))
    upo_status := object.get(input.invoice, "ksef_upo_status", "PENDING")
    upo_received_at := object.get(input.invoice, "ksef_upo_received_at", "")
    upo_hash := object.get(input.invoice, "ksef_upo_hash", "")
    sent_date := object.get(input.invoice, "ksef_sent_date", "")

    # Calculate days since send (simplified — real compute from integration layer)
    days_since_send := object.get(input.invoice, "ksef_days_since_send", 0)

    # Alert levels
    alert_level := "OK" { upo_status == "ACCEPTED" }
    alert_level := "WARNING" { upo_status == "PENDING"; days_since_send < 3 }
    alert_level := "CRITICAL" { upo_status == "PENDING"; days_since_send >= 3 }
    alert_level := "BLOCK" { upo_status == "REJECTED" }

    upo_routing := "" { upo_status == "ACCEPTED" }
    upo_routing := "TRIAGE_QUEUE" { upo_status == "PENDING"; days_since_send >= 3 }
    upo_routing := "BLOCK_AND_ALERT" { upo_status == "REJECTED" }
    upo_routing_reason := "UPO odebrane — OK" { upo_status == "ACCEPTED" }
    upo_routing_reason := sprintf("UPO dla faktury %s — PENDING od %d dni", [invoice_id, days_since_send]) { upo_status == "PENDING"; days_since_send >= 3 }
    upo_routing_reason := sprintf("UPO dla faktury %s ODRZUCONE — sprawdź błędy strukturalne!", [invoice_id]) { upo_status == "REJECTED" }
    upo_routing_reason := sprintf("UPO dla faktury %s — oczekiwanie", [invoice_id]) { true }
}

build_upo_warnings(inv_id, status, days, alert) = warnings {
    status == "ACCEPTED"
    warnings := [sprintf("✅ UPO dla faktury %s — ODEBRANE. Zachowaj 5 lat (Art. 106nc VAT).", [inv_id])]
} else = warnings {
    status == "PENDING"; days < 3
    warnings := [sprintf("⏳ UPO dla faktury %s — OCZEKUJE (%d dni). Monitoruj codziennie.", [inv_id, days])]
} else = warnings {
    status == "PENDING"; days >= 3
    warnings := [
        sprintf("🚨 UPO dla faktury %s — BRAK PO %d DNIACH!", [inv_id, days]),
        "⚠️ Bez UPO = brak prawa do odliczenia VAT (Art. 106nc ust. 3 VAT)!",
        "📋 Sprawdź: status wysyłki w KSeF, poprawność XML FA(2), ważność tokena."
    ]
} else = warnings {
    status == "REJECTED"
    warnings := [
        sprintf("🔴 UPO dla faktury %s — ODRZUCONE przez KSeF!", [inv_id]),
        "📋 Sprawdź błędy walidacji (XML, NIP, kwoty) i wyślij ponownie jako korektę."
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# KIN-1660: SANCTION EXPOSURE CALCULATOR — Kalkulator ekspozycji sankcyjnej (Innowacja 8.9)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_innovations.sanction_exposure_calculator",
    "package": "jdg.ksef_innovations",
    "priority": 1660,
    "ksef_sanction_invoices_without_ksef": invoices_without_ksef,
    "ksef_sanction_total_vat_exposed": total_vat_exposed,
    "ksef_sanction_100pct_exposure": sanction_100pct,
    "ksef_sanction_70pct_exposure": sanction_70pct,
    "ksef_sanction_50pct_exposure": sanction_50pct,
    "ksef_sanction_max_cap_pln": sanction_max_cap,
    "ksef_sanction_risk_level": risk_level,
    "ksef_sanction_first_violation": first_violation,
    "_routing": sanction_routing,
    "_routing_reason": sanction_reason,
    "_legal_basis": "Art. 106nq VAT (dodatkowe zobowiązanie podatkowe)",
    "_warnings": build_sanction_warnings(
        invoices_without_ksef, total_vat_exposed, sanction_100pct,
        sanction_70pct, sanction_50pct, sanction_max_cap, risk_level
    )
} {
    input.ksef_sanction_exposure_check == true
    # Count invoices without KSeF
    invoices_without_ksef := object.get(input, "ksef_invoices_missing_count", 0)
    total_vat_exposed := object.get(input, "ksef_missing_vat_total", 0)
    first_violation := object.get(input, "ksef_first_violation", false)
    _th_kj := object.get(data.jdg.thresholds, "ksef_jpk_edeklaracje", {})
    sanction_max_cap := object.get(_th_kj, "ksef_sanction_max_pln", 500000)

    # Sanction scenarios
    sanction_100pct := min([total_vat_exposed, sanction_max_cap])
    sanction_70pct := min([total_vat_exposed * 0.70, object.get(_th_kj, "ksef_sanction_70_cap_pln", 300000)])
    sanction_50pct := min([total_vat_exposed * 0.50, object.get(_th_kj, "ksef_sanction_50_cap_pln", 250000)])

    # Risk level classification
    risk_level := "NONE" { invoices_without_ksef == 0 }
    risk_level := "LOW" { invoices_without_ksef > 0; invoices_without_ksef <= 3; total_vat_exposed <= 10000 }
    risk_level := "MEDIUM" { invoices_without_ksef > 3; total_vat_exposed <= 100000 }
    risk_level := "HIGH" { invoices_without_ksef > 3; total_vat_exposed > 100000 }
    risk_level := "CRITICAL" { total_vat_exposed > 500000 }

    sanction_routing := "" { risk_level == "NONE" }
    sanction_routing := "WARNING" { risk_level == "LOW" }
    sanction_routing := "TRIAGE_QUEUE" { risk_level == "MEDIUM" }
    sanction_routing := "BLOCK_AND_ALERT" { risk_level in {"HIGH", "CRITICAL"} }
    sanction_reason := sprintf("Ekspozycja sankcyjna KSeF: %s — %d faktur, %.2f PLN VAT ryzyka",
        [risk_level, invoices_without_ksef, total_vat_exposed]) { risk_level != "NONE" }
    sanction_reason := "Brak ekspozycji sankcyjnej KSeF" { risk_level == "NONE" }
}

build_sanction_warnings(count, vat, s100, s70, s50, cap, risk) = warnings {
    count == 0
    warnings := ["✅ KSeF SANCTION EXPOSURE: Brak faktur bez KSeF. Ekspozycja sankcyjna = 0 PLN."]
} else = warnings {
    lines := [
        sprintf("⚠️ KSeF SANCTION EXPOSURE — RYZYKO: %s", [risk]),
        sprintf("   Faktur bez KSeF: %d", [count]),
        sprintf("   VAT zagrożony: %.2f PLN", [vat]),
        sprintf("   Sankcja 100%% VAT: %.2f PLN (max %d PLN)", [s100, cap]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "📋 SCENARIUSZE SANKCYJNE:",
        sprintf("   • 100%% VAT (brak KSeF): %.2f PLN", [s100]),
        sprintf("   • 70%% VAT (opóźnienie >24h): %.2f PLN", [s70]),
        sprintf("   • 50%% VAT (pierwsze naruszenie): %.2f PLN", [s50]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "💡 REKOMENDACJA: Natychmiast wyślij zaległe faktury przez KSeF!",
        "   Złóż czynny żal (Art. 16a KKS) dla redukcji sankcji o 50%."
    ]
    warnings := lines
}

# ═══════════════════════════════════════════════════════════════════════════════
# KIN-1670: KSeF RECEIPT DIGEST — Okresowy odbiór faktur kosztowych (LUKA-K18)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_innovations.receipt_digest",
    "package": "jdg.ksef_innovations",
    "priority": 1670,
    "ksef_receipt_digest_active": true,
    "ksef_receipt_period": receipt_period,
    "ksef_receipt_new_invoices_count": new_count,
    "ksef_receipt_total_purchase_net": total_net,
    "ksef_receipt_total_purchase_vat": total_vat,
    "ksef_receipt_last_digest_date": last_digest,
    "ksef_receipt_next_digest_deadline": next_deadline,
    "_routing": digest_routing,
    "_routing_reason": digest_reason,
    "_legal_basis": "Art. 106na-106nq VAT (KSeF); Art. 86 VAT (odliczenie)",
    "_warnings": build_digest_warnings(receipt_period, new_count, total_net, total_vat, last_digest)
} {
    input.ksef_receipt_digest_check == true
    receipt_period := object.get(input, "ksef_digest_period", "2026-07")
    new_count := object.get(input, "ksef_new_receipts_count", 0)
    total_net := object.get(input, "ksef_receipts_net_total", 0)
    total_vat := object.get(input, "ksef_receipts_vat_total", 0)
    last_digest := object.get(input, "ksef_last_digest_date", "")
    next_deadline := object.get(input, "ksef_next_digest_deadline", "")
    days_since_digest := object.get(input, "ksef_days_since_last_digest", 0)

    digest_routing := "" { days_since_digest < 7 }
    digest_routing := "TRIAGE_QUEUE" { days_since_digest >= 7 }
    digest_routing := "BLOCK_AND_ALERT" { days_since_digest >= 30 }
    digest_reason := sprintf("Pobrano %d nowych faktur kosztowych z KSeF. VAT do odliczenia: %.2f PLN.", [new_count, total_vat]) { new_count > 0 }
    digest_reason := "Brak nowych faktur kosztowych w KSeF w okresie." { new_count == 0 }
}

build_digest_warnings(period, count, net, vat, last_date) = warnings {
    count == 0
    warnings := [sprintf("📥 KSeF RECEIPT DIGEST (%s): Brak nowych faktur kosztowych. Ostatni digest: %s", [period, last_date])]
} else = warnings {
    warnings := [
        sprintf("📥 KSeF RECEIPT DIGEST (%s): %d nowych faktur kosztowych!", [period, count]),
        sprintf("   Netto zakupy: %.2f PLN | VAT do odliczenia: %.2f PLN", [net, vat]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "📋 KROKI:",
        "   1. Zweryfikuj UPO dla każdej faktury kosztowej",
        "   2. Ujęcie w JPK_V7 w bieżącym okresie (P_38/P_39)",
        "   3. Bez UPO = brak prawa do odliczenia VAT!",
        "   4. Sprawdź poprawność NIP sprzedawcy na Białej Liście",
        sprintf("   Ostatni digest: %s", [last_date]),
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# KIN-1680: ZERO-DOWNTIME KSeF BUFFER — Warstwa Outbox (Innowacja 8.10)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_innovations.outbox_buffer",
    "package": "jdg.ksef_innovations",
    "priority": 1680,
    "ksef_outbox_queue_size": queue_size,
    "ksef_outbox_oldest_pending_hours": oldest_hours,
    "ksef_outbox_idempotency_keys": idempotency_active,
    "ksef_outbox_batch_ready": batch_ready,
    "ksef_outbox_delivery_strategy": delivery_strategy,
    "_routing": outbox_routing,
    "_routing_reason": outbox_reason,
    "_legal_basis": "Art. 106na-106nq VAT; Specyfikacja API KSeF v3.0",
    "_warnings": build_outbox_warnings(queue_size, oldest_hours, batch_ready, delivery_strategy)
} {
    input.ksef_outbox_check == true
    queue := object.get(input, "ksef_outbox_queue", [])
    queue_size := count(queue)
    oldest_hours := object.get(input, "ksef_outbox_oldest_age_hours", 0)
    batch_ready := queue_size > 0
    idempotency_active := true

    # Delivery strategy
    delivery_strategy := "single" { queue_size <= 3 }
    delivery_strategy := "batch_5_per_cycle" { queue_size > 3; queue_size <= 50 }
    delivery_strategy := "batch_20_per_cycle" { queue_size > 50 }

    outbox_routing := "" { queue_size == 0 }
    outbox_routing := "TRIAGE_QUEUE" { queue_size > 0; oldest_hours < 12 }
    outbox_routing := "BLOCK_AND_ALERT" { oldest_hours >= 24 }
    outbox_reason := sprintf("Outbox KSeF: %d faktur oczekuje na wysyłkę. Najstarsza: %d h. Strategia: %s. Idempotency: ON.",
        [queue_size, oldest_hours, delivery_strategy]) { queue_size > 0 }
    outbox_reason := "Outbox KSeF pusty — wszystkie faktury wysłane." { queue_size == 0 }
}

build_outbox_warnings(size, age, ready, strategy) = warnings {
    size == 0
    warnings := ["✅ KSeF OUTBOX BUFFER: Wszystkie faktury wysłane. Kolejka pusta."]
} else = warnings {
    age_warning := ""
    age_warning := " ⚠️ Najstarsza faktura >24h — NATYCHMIAST wyślij!" { age >= 24 }
    warnings := [
        sprintf("📤 KSeF OUTBOX BUFFER: %d faktur w kolejce.%s", [size, age_warning]),
        sprintf("   Strategia wysyłki: %s", [strategy]),
        sprintf("   Najstarsza faktura: %d godzin", [age]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "📋 ZASADY OUTBOX (Zero-Downtime):",
        "   • Idempotency keys: każda faktura ma unikalny klucz",
        "   • Exactly-once delivery: brak duplikatów",
        "   • Retry z exponential backoff (max 15 prób)",
        "   • Dead letter queue po 15 nieudanych próbach",
        "   • Monitorowanie: alert przy kolejce >50 faktur",
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# KIN-1690: UPO × VAT DEDUCTION LINK — Powiązanie UPO z odliczeniem VAT (LUKA-K16)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_innovations.upo_vat_deduction_link",
    "package": "jdg.ksef_innovations",
    "priority": 1690,
    "ksef_upo_vat_risk_invoices": risk_invoices,
    "ksef_upo_vat_risk_amount": risk_vat_amount,
    "ksef_upo_vat_deduction_blocked": deduction_blocked,
    "_routing": upo_vat_routing,
    "_routing_reason": upo_vat_reason,
    "_legal_basis": "Art. 106nc ust. 3 VAT (UPO warunkiem odliczenia); Art. 86 ust. 10 VAT",
    "_warnings": build_upo_vat_warnings(risk_invoices, risk_vat_amount, deduction_blocked)
} {
    input.ksef_upo_vat_check == true
    # Check purchase invoices without UPO
    purchases_without_upo := object.get(input, "ksef_purchases_without_upo", [])
    risk_invoices := count(purchases_without_upo)
    risk_vat_amount := object.get(input, "ksef_purchases_vat_at_risk", 0)
    deduction_blocked := risk_invoices > 0

    upo_vat_routing := "" { risk_invoices == 0 }
    upo_vat_routing := "TRIAGE_QUEUE" { risk_invoices > 0; risk_vat_amount <= 5000 }
    upo_vat_routing := "BLOCK_AND_ALERT" { risk_vat_amount > 5000 }
    upo_vat_reason := sprintf("Brak UPO dla %d faktur zakupowych — VAT %.2f PLN do odliczenia ZAGROŻONY!",
        [risk_invoices, risk_vat_amount]) { risk_invoices > 0 }
    upo_vat_reason := "Wszystkie faktury zakupowe mają UPO — odliczenie VAT bezpieczne." { risk_invoices == 0 }
}

build_upo_vat_warnings(count, vat, blocked) = warnings {
    count == 0
    warnings := ["✅ UPO × ODLICZENIE VAT: Wszystkie faktury zakupowe posiadają UPO."]
} else = warnings {
    warnings := [
        sprintf("🚨 UPO × ODLICZENIE VAT — RYZYKO KOREKTY!", []),
        sprintf("   Faktur zakupowych bez UPO: %d", [count]),
        sprintf("   VAT zagrożony korektą: %.2f PLN", [vat]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "📋 KONSEKWENCJE:",
        "   • Bez UPO = US może zakwestionować odliczenie VAT",
        "   • Konieczność korekty JPK_V7 wstecz",
        "   • Odsetki od zaległości (14.5% rocznie)",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "💡 REKOMENDACJA:",
        "   1. Pobierz UPO z API KSeF dla brakujących faktur",
        "   2. Jeśli UPO niedostępne — skontaktuj się ze sprzedawcą",
        "   3. Rozważ korektę odliczenia VAT w bieżącym okresie",
        "   4. Zachowaj dokumentację prób uzyskania UPO"
    ]
}
