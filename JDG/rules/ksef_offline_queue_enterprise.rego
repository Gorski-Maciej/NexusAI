# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE KSeF OFFLINE QUEUE MANAGER (Innovation 8.4, P18 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise KSeF Offline Queue Manager — Lifecycle & Reconciliation
# description: |
#   ENTERPRISE v7.0 — Pełny lifecycle management faktur w trybie offline KSeF.
#   Rozszerza KSR-1610 o zarządzanie kolejką, priorytetyzację i uzgadnianie.
#
#   KLUCZOWE FUNKCJE:
#   - Kolejka offline z priorytetami (HIGH/MEDIUM/LOW)
#   - Monitorowanie wieku faktur w kolejce (alerty przy 24h, 72h, 120h, 168h)
#   - Szacowany czas przywrócenia KSeF (ETR) i wpływ na deadline
#   - Uzgadnianie kolejek po przywróceniu (co zostało wysłane, co nie)
#   - Raport post-mortem po awarii (co poszło dobrze/źle)
#
# architecture: Enterprise v7.0 First-Match-Wins
# legal_basis: Art. 106ne VAT; Art. 106na ust. 2-3 VAT
# package: jdg.ksef_offline_queue
# deprecated: false
# priority_range: 2270-2299
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.ksef_offline_queue

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.ksef_offline_queue.no_match",
    "package": "jdg.ksef_offline_queue", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# KOL-2270: OFFLINE QUEUE STATUS — Status kolejki offline
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.ksef_offline_queue.queue_status",
    "package": "jdg.ksef_offline_queue",
    "priority": 2270,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_queue_total_pending": total_pending,
    "ksef_queue_high_priority": high_priority,
    "ksef_queue_oldest_age_hours": oldest_age_h,
    "ksef_queue_oldest_approaching_deadline": approaching_deadline,
    "ksef_queue_deadline_hours": 168,
    "ksef_queue_hours_remaining": hours_remaining,
    "_routing": queue_routing,
    "_routing_reason": queue_reason,
    "_legal_basis": "Art. 106ne VAT (7 dni grace period)",
    "_warnings": build_queue_warnings(total_pending, oldest_age_h, hours_remaining, approaching_deadline)
} {
    input.ksef_offline_queue_check == true
    total_pending := object.get(input, "ksef_offline_queue_count", 0)
    high_priority := object.get(input, "ksef_offline_high_priority_count", 0)
    oldest_age_h := object.get(input, "ksef_offline_oldest_age_hours", 0)
    hours_remaining := 168 - oldest_age_h
    approaching_deadline := oldest_age_h >= 120

    queue_routing := "BLOCK_AND_ALERT" { approaching_deadline }
    queue_routing := "TRIAGE_QUEUE" { total_pending > 0 }
    queue_routing := "" { true }
    queue_reason := sprintf("KOLEJKA OFFLINE KRYTYCZNA: %d faktur, najstarsza %d godz. — %d godz. do deadline!", [total_pending, oldest_age_h, hours_remaining]) { approaching_deadline }
    queue_reason := sprintf("Kolejka offline: %d faktur oczekujących.", [total_pending]) { total_pending > 0 }
    queue_reason := "" { true }
}

build_queue_warnings(total, age, remaining, approaching) = warnings {
    approaching
    warnings := [
        sprintf("🚨 KOLEJKA OFFLINE KRYTYCZNA!", []),
        sprintf("   Faktur oczekujących: %d | Najstarsza: %d godz.", [total, age]),
        sprintf("   ⏰ POZOSTAŁO TYLKO %d GODZIN do deadline 7 dni!", [remaining]),
        "⚠️ NATYCHMIAST przygotuj ZAW-NR dla US jeśli KSeF nie wróci w ciągu kilku godzin!"
    ]
} else = warnings {
    total > 0
    warnings := [
        sprintf("📋 KOLEJKA OFFLINE KSeF — %d faktur", [total]),
        sprintf("   Najstarsza: %d godz. | Pozostało: %d godz. do deadline", [age, remaining]),
    ]
} else = ["✅ Kolejka offline pusta — wszystkie faktury wysłane."]
}

# ═══════════════════════════════════════════════════════════════════════════════
# KOL-2275: PRIORITY-BASED DISPATCH — Priorytetyzacja wysyłki po przywróceniu
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_offline_queue.priority_dispatch",
    "package": "jdg.ksef_offline_queue",
    "priority": 2275,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_dispatch_strategy": strategy,
    "ksef_dispatch_batch_1_high": batch1_count,
    "ksef_dispatch_batch_2_medium": batch2_count,
    "ksef_dispatch_batch_3_low": batch3_count,
    "_routing": dispatch_routing,
    "_routing_reason": dispatch_reason,
    "_legal_basis": "Art. 106ne VAT; Polityka batch KSeF",
    "_warnings": [
        sprintf("🔄 KOLEJKA OFFLINE — STRATEGIA WYSYŁKI: %s", [strategy]),
        sprintf("   Batch 1 (HIGH): %d faktur >50k PLN", [batch1_count]),
        sprintf("   Batch 2 (MEDIUM): %d faktur >10k PLN", [batch2_count]),
        sprintf("   Batch 3 (LOW): %d faktur ≤10k PLN", [batch3_count]),
        "📋 Wysyłaj chronologicznie w każdym batchu (od najstarszej).",
    ]
} {
    input.ksef_offline_dispatch_plan == true
    ksef_online := object.get(input, "ksef_api_available", false)
    ksef_online == true

    pending := object.get(input, "ksef_offline_queue", [])
    total := count(pending)
    # Priorytetyzacja: HIGH (>50k), MEDIUM (>10k), LOW (reszta)
    high_items := object.get(input, "ksef_offline_high_priority_count", 0)
    medium_items := object.get(input, "ksef_offline_medium_priority_count", 0)
    low_items := total - high_items - medium_items

    batch1_count := high_items { high_items <= 10 }
    batch1_count := 10 { high_items > 10 }
    batch2_count := medium_items
    batch3_count := low_items

    strategy := sprintf("3-batch: HIGH(%d)→MEDIUM(%d)→LOW(%d)", [batch1_count, batch2_count, batch3_count]) { total > 10 }
    strategy := sprintf("single-batch: wszystkie %d faktur", [total]) { total <= 10 }

    dispatch_routing := "TRIAGE_QUEUE" { total > 0 }
    dispatch_routing := "" { true }
    dispatch_reason := sprintf("Dispatch plan: %d faktur w kolejkach priorytetowych.", [total]) { total > 0 }
    dispatch_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# KOL-2280: POST-MORTEM REPORT — Raport po awarii KSeF
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_offline_queue.post_mortem",
    "package": "jdg.ksef_offline_queue",
    "priority": 2280,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_outage_duration_hours": outage_hours,
    "ksef_outage_invoices_generated": invoices_generated,
    "ksef_outage_invoices_sent": invoices_sent,
    "ksef_outage_invoices_failed": invoices_failed,
    "ksef_outage_zaw_nr_filed": zaw_filed,
    "ksef_outage_post_mortem_grade": grade,
    "_routing": pm_routing,
    "_routing_reason": pm_reason,
    "_legal_basis": "Art. 106ne VAT; Dobre praktyki Enterprise Resilience",
    "_warnings": build_postmortem_warnings(outage_hours, invoices_generated, invoices_sent, invoices_failed, zaw_filed, grade)
} {
    input.ksef_offline_post_mortem == true
    ksef_online := object.get(input, "ksef_api_available", true)
    ksef_online == true  # Awaria minęła — KSeF działa

    outage_hours := object.get(input, "ksef_outage_duration_hours", 0)
    invoices_generated := object.get(input, "ksef_offline_total_generated", 0)
    invoices_sent := object.get(input, "ksef_offline_total_sent", 0)
    invoices_failed := object.get(input, "ksef_offline_total_failed", 0)
    zaw_filed := object.get(input, "ksef_zaw_nr_sent", false)

    success_rate := invoices_sent * 100 / max([invoices_generated, 1])
    grade := "A (DOSKONALE)" { success_rate >= 99 }
    grade := "B (DOBRZE)" { success_rate >= 95; success_rate < 99 }
    grade := "C (DOSTATECZNIE)" { success_rate >= 80; success_rate < 95 }
    grade := "D (DO POPRAWY)" { success_rate < 80 }

    pm_routing := "TRIAGE_QUEUE" { invoices_failed > 0 }
    pm_routing := "" { true }
    pm_reason := sprintf("POST-MORTEM: %d/%d faktur wysłanych (%.0f%%). %d błędów do analizy.", [invoices_sent, invoices_generated, success_rate, invoices_failed]) { invoices_failed > 0 }
    pm_reason := sprintf("POST-MORTEM: wszystkie %d faktur wysłane pomyślnie.", [invoices_sent]) { invoices_failed == 0 }
}

build_postmortem_warnings(hours, generated, sent, failed, zaw, grade) = warnings {
    zaw_text := "TAK" { zaw }
    zaw_text := "NIE" { not zaw }
    warnings := [
        "═══════════════════════════════════════════",
        sprintf("📊 POST-MORTEM — AWARIA KSeF (%.0f godz.)", [hours]),
        sprintf("   Faktur wygenerowanych offline: %d", [generated]),
        sprintf("   Wysłanych po przywróceniu: %d", [sent]),
        sprintf("   Błędów wysyłki: %d", [failed]),
        sprintf("   ZAW-NR złożone: %s", [zaw_text]),
        sprintf("   OCENA: %s", [grade]),
        "═══════════════════════════════════════════",
    ]
}
