# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE KSeF OUTBOX BUFFER (Innovation 8.10, P18 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise KSeF Outbox — Zero-Downtime Transactional Buffer
# description: |
#   ENTERPRISE v7.0 — Wzorzec Transactional Outbox dla niezawodnej wysyłki KSeF.
#   Wypełnia lukę K14 z raportu P18. Zapewnia semantykę exactly-once dla każdej
#   faktury wysyłanej do KSeF.
#
#   KLUCZOWE CECHY:
#   - Transactional Outbox: faktury zapisywane w outbox przed wysyłką do API
#   - Idempotency Keys: każda faktura z unikalnym kluczem idempotentności
#   - Delivery Guarantees: at-least-once z deduplikacją, exactly-once przez KSeF
#   - Dead Letter Queue: faktury które nie przeszły po max retries
#   - Circuit Breaker: automatyczne wstrzymanie wysyłki przy błędach KSeF
#   - Reconciliation: okresowe uzgadnianie stanu outbox z KSeF API
#
# architecture: Enterprise v7.0 Outbox Pattern, First-Match-Wins
# legal_basis: Art. 106na-106nq VAT; Specyfikacja API KSeF v2.0
# package: jdg.ksef_outbox
# deprecated: false
# priority_range: 2060-2089
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.ksef_outbox

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.ksef_outbox.no_match",
    "package": "jdg.ksef_outbox", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# KOB-2060: OUTBOX ENQUEUE — Zapis faktury do outbox przed wysyłką KSeF
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.ksef_outbox.enqueue_invoice",
    "package": "jdg.ksef_outbox",
    "priority": 2060,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_outbox_idempotency_key": idempotency_key,
    "ksef_outbox_status": "ENQUEUED",
    "ksef_outbox_enqueued_at": enqueued_at,
    "ksef_outbox_priority": outbox_priority,
    "_routing": "",
    "_routing_reason": sprintf("Faktura %s dodana do KSeF Outbox. Idempotency key: %s", [invoice_number, idempotency_key]),
    "_legal_basis": "Art. 106na VAT; Wzorzec Enterprise Outbox (Event-Driven Architecture)",
    "_warnings": [sprintf("📤 OUTBOX: Faktura %s (%.2f PLN) zakolejkowana do wysyłki KSeF. Klucz: %s", [invoice_number, invoice_amount, idempotency_key])]
} {
    input.ksef_outbox_enqueue == true
    input.invoice.direction == "SALE"

    invoice_number := object.get(input.invoice, "invoice_number", "")
    invoice_amount := object.get(input.invoice, "amount_gross", 0)
    seller_nip := object.get(input.invoice, "seller_nip", object.get(input.jdg_entrepreneur, "nip", ""))
    enqueued_at := object.get(input, "evaluation_datetime", "")

    # Idempotency key: NIP + numer faktury + data (zapobiega duplikatom)
    invoice_date := object.get(input.invoice, "issue_date", "")
    idempotency_key := sprintf("%s-%s-%s", [seller_nip, invoice_number, invoice_date])

    # Priorytet: HIGH dla faktur >50k PLN (szybka ścieżka), NORMAL dla reszty
    outbox_priority := "HIGH" { invoice_amount > 50000 }
    outbox_priority := "NORMAL" { invoice_amount <= 50000 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# KOB-2065: OUTBOX DISPATCH — Wysyłka faktury z outbox do API KSeF
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_outbox.dispatch_invoice",
    "package": "jdg.ksef_outbox",
    "priority": 2065,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_outbox_dispatch_status": dispatch_status,
    "ksef_outbox_dispatch_attempt": attempt_number,
    "ksef_outbox_dispatch_next_retry_seconds": next_retry_sec,
    "ksef_outbox_idempotency_key": idemp_key,
    "_routing": dispatch_routing,
    "_routing_reason": dispatch_reason,
    "_legal_basis": "Art. 106na VAT; API KSeF — POST /online/Invoice/Send",
    "_warnings": build_dispatch_warnings(dispatch_status, attempt_number, idemp_key, invoice_ref)
} {
    input.ksef_outbox_dispatch == true
    invoice_ref := object.get(input.invoice, "ksef_number", object.get(input.invoice, "invoice_number", ""))
    idemp_key := object.get(input, "ksef_outbox_idempotency_key", "")
    ksef_online := object.get(input, "ksef_api_available", true)

    attempt_number := object.get(input, "ksef_outbox_dispatch_attempt", 1)
    dispatch_result := object.get(input, "ksef_outbox_dispatch_result", "")

    dispatch_status := "SENT" { dispatch_result == "OK" }
    dispatch_status := "FAILED_RETRY" { dispatch_result != "OK"; attempt_number < 15; ksef_online }
    dispatch_status := "DEAD_LETTER" { dispatch_result != "OK"; attempt_number >= 15 }
    dispatch_status := "OFFLINE_DEFERRED" { not ksef_online }

    # Exponential backoff dla retry
    next_retry_sec := 5 * 2^attempt_number { attempt_number < 10 }
    next_retry_sec := 3600 { attempt_number >= 10 }
    next_retry_sec := 0 { dispatch_status == "SENT" }

    dispatch_routing := "" { dispatch_status == "SENT" }
    dispatch_routing := "TRIAGE_QUEUE" { dispatch_status in {"FAILED_RETRY", "OFFLINE_DEFERRED"} }
    dispatch_routing := "BLOCK_AND_ALERT" { dispatch_status == "DEAD_LETTER" }
    dispatch_reason := sprintf("Faktura %s wysłana do KSeF — UPO oczekiwane.", [invoice_ref]) { dispatch_status == "SENT" }
    dispatch_reason := sprintf("Outbox dispatch nieudany (próba %d) — retry za %ds", [attempt_number, next_retry_sec]) { dispatch_status == "FAILED_RETRY" }
    dispatch_reason := sprintf("KSeF offline — faktura w outbox, wyślij po przywróceniu (7 dni grace)", []) { dispatch_status == "OFFLINE_DEFERRED" }
    dispatch_reason := sprintf("DEAD LETTER: faktura %s po %d próbach — ręczna interwencja wymagana!", [invoice_ref, attempt_number]) { dispatch_status == "DEAD_LETTER" }
}

build_dispatch_warnings(status, attempt, key, ref) = warnings {
    status == "SENT"
    warnings := [sprintf("✅ KSeF OUTBOX: faktura %s wysłana (klucz: %s).", [ref, key])]
} else = warnings {
    status == "DEAD_LETTER"
    warnings := [
        sprintf("🚨 DEAD LETTER QUEUE: faktura %s NIE wysłana po %d próbach!", [ref, attempt]),
        "📋 Sprawdź: poprawność danych XML FA(2), token KSeF, dostępność API, limity batch.",
        "💡 Przenieś fakturę z powrotem do outbox po naprawie błędów i ponów wysyłkę."
    ]
} else = ["🔄 KSeF OUTBOX: oczekiwanie na wysyłkę / retry."]

# ═══════════════════════════════════════════════════════════════════════════════
# KOB-2070: OUTBOX RECONCILIATION — Uzgadnianie stanu outbox z KSeF
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_outbox.reconciliation",
    "package": "jdg.ksef_outbox",
    "priority": 2070,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_outbox_reconciled_total": reconciled,
    "ksef_outbox_stale_entries": stale_entries,
    "ksef_outbox_orphan_detected": orphans,
    "_routing": recon_routing,
    "_routing_reason": recon_reason,
    "_legal_basis": "Art. 106nc VAT (UPO); Specyfikacja API KSeF — GET /online/Invoice/Status",
    "_warnings": build_reconciliation_warnings(reconciled, stale_entries, orphans)
} {
    input.ksef_outbox_reconcile == true
    total_in_outbox := object.get(input, "ksef_outbox_total_entries", 0)
    reconciled := object.get(input, "ksef_outbox_reconciled_count", 0)
    stale_entries := total_in_outbox - reconciled

    # Osierocone wpisy: w outbox ale NIE w KSeF po >48h
    orphans := object.get(input, "ksef_outbox_orphan_count", 0)

    recon_routing := "TRIAGE_QUEUE" { stale_entries > 0 }
    recon_routing := "BLOCK_AND_ALERT" { orphans > 0 }
    recon_routing := "" { true }
    recon_reason := sprintf("Outbox reconciliation: %d/%d uzgodnionych, %d nieaktualnych.", [reconciled, total_in_outbox, stale_entries]) { stale_entries > 0 }
    recon_reason := "" { true }
}

build_reconciliation_warnings(reconciled, stale, orphans) = final_result {
    base := [
        sprintf("🔄 KSeF OUTBOX RECONCILIATION: %d uzgodnionych wpisów.", [reconciled]),
    ]
    with_stale := array.concat(base, [sprintf("   ⚠️ %d nieaktualnych wpisów — wymagają ręcznej weryfikacji.", [stale])]) { stale > 0 }
    with_stale := base { stale == 0 }
    with_orphans := array.concat(with_stale, [sprintf("   🚨 %d osieroconych wpisów — w outbox, brak w KSeF!", [orphans])]) { orphans > 0 }
    with_orphans := with_stale { orphans == 0 }
    final_result := with_orphans
}

# ═══════════════════════════════════════════════════════════════════════════════
# KOB-2075: CIRCUIT BREAKER — Bezpiecznik chroniący przed kaskadą błędów
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_outbox.circuit_breaker",
    "package": "jdg.ksef_outbox",
    "priority": 2075,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_outbox_circuit_state": circuit_state,
    "ksef_outbox_failure_rate_pct": failure_rate,
    "ksef_outbox_circuit_open_until": open_until,
    "_routing": circuit_routing,
    "_routing_reason": circuit_reason,
    "_legal_basis": "Wzorzec Circuit Breaker (Enterprise Resilience); Art. 106na VAT",
    "_warnings": build_circuit_warnings(circuit_state, failure_rate, open_until)
} {
    input.ksef_outbox_circuit_check == true
    recent_attempts := object.get(input, "ksef_outbox_recent_attempts", 1)
    recent_failures := object.get(input, "ksef_outbox_recent_failures", 0)
    failure_rate := recent_failures * 100 / max([recent_attempts, 1])

    ksef_online := object.get(input, "ksef_api_available", true)

    circuit_state := "CLOSED" { failure_rate < 50; ksef_online }
    circuit_state := "HALF_OPEN" { failure_rate < 50; not ksef_online }
    circuit_state := "OPEN" { failure_rate >= 50 }
    open_until := "do czasu spadku błędów <50%" { circuit_state == "OPEN" }
    open_until := "" { circuit_state != "OPEN" }

    circuit_routing := "BLOCK_AND_ALERT" { circuit_state == "OPEN" }
    circuit_routing := "TRIAGE_QUEUE" { circuit_state == "HALF_OPEN" }
    circuit_routing := "" { true }
    circuit_reason := sprintf("CIRCUIT BREAKER OPEN: %.0f%% błędów — wysyłka KSeF WSTRZYMANA! Sprawdź API.", [failure_rate]) { circuit_state == "OPEN" }
    circuit_reason := "Circuit half-open — KSeF może być niedostępny, sprawdź health check." { circuit_state == "HALF_OPEN" }
    circuit_reason := "" { true }
}

build_circuit_warnings(state, rate, until) = warnings {
    state == "OPEN"
    warnings := [
        sprintf("🔴 CIRCUIT BREAKER OPEN — %.0f%% nieudanych wysyłek KSeF!", [rate]),
        "🚫 Wysyłka faktur do KSeF automatycznie WSTRZYMANA.",
        sprintf("   ⏰ Automatyczne odblokowanie: %s", [until]),
        "📋 DZIAŁANIE: Sprawdź stan API KSeF, tokeny, certyfikaty. Faktury zapisywane w outbox."
    ]
} else = warnings {
    state == "HALF_OPEN"
    warnings := [sprintf("🟡 CIRCUIT BREAKER HALF-OPEN — %.0f%% błędów. Testuj połączenie z KSeF...", [rate])]
} else = [sprintf("🟢 CIRCUIT BREAKER CLOSED — %.0f%% błędów. Wysyłka KSeF aktywna.", [rate])]
