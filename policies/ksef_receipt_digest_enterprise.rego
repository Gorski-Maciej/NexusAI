# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE KSeF RECEIPT DIGEST (LUKA-K18, P18 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise KSeF Receipt Digest — Inbound Invoice Reader
# description: |
#   ENTERPRISE v7.0 — Moduł okresowego odbioru faktur kosztowych z KSeF.
#   Wypełnia lukę K18 z raportu P18: automatyzacja pobierania faktur zakupowych
#   wystawionych przez kontrahentów w KSeF i ich księgowania.
#
#   KLUCZOWE FUNKCJE:
#   - Okresowe pobieranie faktur kosztowych z KSeF (polling / webhook)
#   - Walidacja poprawności faktur kosztowych przed księgowaniem
#   - Porównanie z własnymi ewidencjami zakupów (uzgodnienie KSeF vs JPK_V7)
#   - Wykrywanie brakujących faktur zakupowych (kontrahent wysłał, JDG nie zaksięgowało)
#   - Ewidencja UPO dla faktur zakupowych (warunek odliczenia VAT)
#
# architecture: Enterprise v7.0 First-Match-Wins
# legal_basis: Art. 106na-106nw VAT; Art. 86 ust. 10b pkt 1 VAT
# package: jdg.ksef_receipt_digest
# deprecated: false
# priority_range: 2090-2119
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.ksef_receipt_digest

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.ksef_receipt_digest.no_match",
    "package": "jdg.ksef_receipt_digest", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# KRD-2090: RECEIPT DIGEST POLL — Okresowe pobranie faktur kosztowych z KSeF
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.ksef_receipt_digest.digest_poll",
    "package": "jdg.ksef_receipt_digest",
    "priority": 2090,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_receipt_period": period,
    "ksef_receipt_total_fetched": total_fetched,
    "ksef_receipt_new_invoices": new_count,
    "ksef_receipt_total_net": total_net,
    "ksef_receipt_total_vat": total_vat,
    "_routing": digest_routing,
    "_routing_reason": digest_reason,
    "_legal_basis": "Art. 106na-106nw VAT; API KSeF — GET /online/Invoice/List",
    "_warnings": build_digest_warnings(period, total_fetched, new_count, total_net, total_vat)
} {
    input.ksef_receipt_digest_poll == true
    period := object.get(input, "ksef_receipt_period", "2026-07")
    total_fetched := object.get(input, "ksef_receipt_total_fetched", 0)
    new_count := object.get(input, "ksef_receipt_new_count", 0)
    total_net := object.get(input, "ksef_receipt_net_total", 0)
    total_vat := object.get(input, "ksef_receipt_vat_total", 0)

    digest_routing := "TRIAGE_QUEUE" { new_count > 0 }
    digest_routing := "" { true }
    digest_reason := sprintf("%d nowych faktur kosztowych z KSeF — wymagają zaksięgowania w JPK_V7.", [new_count]) { new_count > 0 }
    digest_reason := "Brak nowych faktur kosztowych w KSeF." { new_count == 0 }
}

build_digest_warnings(period, total, new_count, net, vat) = warnings {
    warnings := [
        sprintf("📥 KSeF RECEIPT DIGEST — OKRES %s", [period]),
        sprintf("   Faktur kosztowych w KSeF: %d (nowych: %d)", [total, new_count]),
        sprintf("   Netto zakupy: %.0f PLN | VAT naliczony: %.0f PLN", [net, vat]),
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# KRD-2095: RECEIPT VS JPK_V7 RECONCILIATION — Uzgodnienie faktur KSeF z JPK
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_receipt_digest.receipt_jpk_reconciliation",
    "package": "jdg.ksef_receipt_digest",
    "priority": 2095,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_recon_ksef_invoices": ksef_invoices,
    "ksef_recon_jpk_invoices": jpk_invoices,
    "ksef_recon_matched": matched_count,
    "ksef_recon_only_ksef": only_ksef,
    "ksef_recon_only_jpk": only_jpk,
    "ksef_recon_status": recon_status,
    "_routing": recon_routing,
    "_routing_reason": recon_reason,
    "_legal_basis": "Art. 109 ust. 3d VAT; Art. 86 ust. 10b pkt 1 VAT; Art. 193 OrdPU",
    "_warnings": build_recon_warnings(ksef_invoices, jpk_invoices, matched_count, only_ksef, only_jpk)
} {
    input.ksef_receipt_reconcile == true
    ksef_invoices := object.get(input, "ksef_purchase_invoice_count", 0)
    jpk_invoices := object.get(input, "jpk_purchase_invoice_count", 0)
    matched_count := object.get(input, "ksef_jpk_matched_purchase_count", 0)
    only_ksef := ksef_invoices - matched_count
    only_jpk := jpk_invoices - matched_count

    recon_status := "ZGODNE" { only_ksef == 0; only_jpk == 0 }
    recon_status := sprintf("ROZBIEŻNOŚCI: +%d KSeF / -%d JPK", [only_ksef, only_jpk]) { only_ksef + only_jpk > 0 }

    recon_routing := "BLOCK_AND_ALERT" { only_ksef > 5 }
    recon_routing := "TRIAGE_QUEUE" { only_ksef + only_jpk > 0 }
    recon_routing := "" { true }
    recon_reason := sprintf("UZGODNIENIE: %d faktur w KSeF bez księgowania w JPK! Sprawdź i zaksięguj.", [only_ksef]) { only_ksef > 0 }
    recon_reason := sprintf("UZGODNIENIE: %d faktur w JPK bez potwierdzenia w KSeF — zweryfikuj.", [only_jpk]) { only_jpk > 0 }
    recon_reason := "KSeF ↔ JPK_V7: wszystkie faktury uzgodnione." { true }
}

build_recon_warnings(ksef, jpk, matched, only_ksef, only_jpk) = warnings {
    warnings := [
        sprintf("🔗 KSeF ↔ JPK_V7 RECONCILIATION", []),
        sprintf("   Faktury KSeF: %d | JPK: %d | Uzgodnione: %d", [ksef, jpk, matched]),
        sprintf("   Tylko w KSeF (brak w JPK): %d ⚠️", [only_ksef]),
        sprintf("   Tylko w JPK (brak w KSeF): %d", [only_jpk]),
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# KRD-2100: MISSING PURCHASE INVOICE ALERT — Wykrywanie brakujących faktur zakupowych
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_receipt_digest.missing_purchase_alert",
    "package": "jdg.ksef_receipt_digest",
    "priority": 2100,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_missing_purchase_invoices": missing_count,
    "ksef_missing_purchase_vat_at_risk": vat_risk,
    "ksef_missing_purchase_suppliers": missing_suppliers,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("BRAKUJĄCE FAKTURY ZAKUPOWE: %d faktur od kontrahentów (KSeF) nie zaksięgowanych. VAT zagrożony: %.0f PLN.", [missing_count, vat_risk]),
    "_legal_basis": "Art. 109 ust. 3d VAT; Art. 86 ust. 10b pkt 1 VAT",
    "_warnings": [
        sprintf("🚨 BRAKUJĄCE FAKTURY ZAKUPOWE Z KSeF!", []),
        sprintf("   Niezaksięgowanych: %d faktur od %d dostawców", [missing_count, missing_suppliers]),
        sprintf("   VAT naliczony zagrożony: %.0f PLN", [vat_risk]),
        "📋 DZIAŁANIE:",
        "   1. Pobierz faktury z KSeF (API: GET /online/Invoice/List)",
        "   2. Zweryfikuj poprawność danych (NIP, kwoty, data)",
        "   3. Zaksięguj w JPK_V7 (rejestr zakupów)",
        "   4. Pobierz UPO dla każdej faktury (warunek odliczenia VAT!)",
    ]
} {
    input.ksef_missing_purchase_check == true
    missing_count := object.get(input, "ksef_unbooked_purchase_count", 0)
    vat_risk := object.get(input, "ksef_unbooked_purchase_vat", 0)
    missing_suppliers := object.get(input, "ksef_unbooked_supplier_count", 0)
    missing_count > 0
}
