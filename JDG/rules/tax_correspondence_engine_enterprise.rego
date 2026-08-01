# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise — Innovation 9.1: Tax Authority Auto-Correspondence Engine
# v7.0 — S22 Expansion: Dispatch + Status Monitoring + UPO Tracker
# Package: jdg.enterprise.tax_correspondence
# Expands: tax_authority_interaction_enterprise.rego (S22)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.enterprise.tax_correspondence

import data.jdg.helpers

# ─────────────────────────────────────────────────────────────────────────────
# TCE-2500: Dispatch Router — klasyfikuje zdarzenie i wybiera szablon S22
# ─────────────────────────────────────────────────────────────────────────────
tce_dispatch_classification(event) = classification {
    event_type := object.get(event, "type", "UNKNOWN")
    classification := {
        "CZ-1": "ZAL/ORD",      # Zaległość podatkowa
        "CZ-2": "NAD/ORD",      # Nadpłata
        "CZ-3": "RAT/ORD",      # Raty/odroczenia
        "CZ-4": "UMO/ORD",      # Umorzenie
        "CZ-5": "ODW/ORD",      # Odwołanie
        "CZ-6": "INT/ORD",      # Interpretacja
        "CZ-7": "PRZ/ORD",      # Przedawnienie
        "CZ-8": "PEŁ/ORD",      # Pełnomocnictwo
    }[event_type]
} else := "NIEZN/ORD"

tce_select_s22_template(classification) = template {
    templates := {
        "ZAL/ORD": "S22_ZAL_wniosek_o_odroczenie",
        "NAD/ORD": "S22_NAD_wniosek_o_zwrot_nadplaty",
        "RAT/ORD": "S22_RAT_wniosek_o_rozlozenie_na_raty",
        "UMO/ORD": "S22_UMO_wniosek_o_umorzenie",
        "ODW/ORD": "S22_ODW_odwolanie_od_decyzji",
        "INT/ORD": "S22_INT_wniosek_o_interpretacje",
        "PRZ/ORD": "S22_PRZ_wniosek_o_stwierdzenie_przedawnienia",
        "PEŁ/ORD": "S22_PEL_zgloszenie_pelnomocnictwa",
    }
    template := templates[classification]
}

# ─────────────────────────────────────────────────────────────────────────────
# TCE-2510: Dispatch Engine — wysyłka przez e-Urząd Skarbowy / e-Doręczenia
# ─────────────────────────────────────────────────────────────────────────────
dispatch_via_eus(input) = result {
    letter_content := object.get(input, "letter_content", "")
    recipient := object.get(input, "tax_office_code", "BRAK")
    delivery_method := object.get(input, "delivery_method", "EUS")

    # Walidacja kompletności pisma
    completeness_checks := {
        "has_signature": count(letter_content) > 0,
        "has_legal_basis": contains(letter_content, "Art."),
        "has_nip": contains(letter_content, "NIP"),
        "has_date": contains(letter_content, "202"),
    }
    all_checks_pass := [v | v := completeness_checks[_]; v == false]
    is_complete := count(all_checks_pass) == 0

    result := {
        "dispatch_id": sprintf("EUS-%s-%d", [recipient, time.now_ns() / 1000000]),
        "delivery_method": delivery_method,
        "template": tce_select_s22_template(tce_dispatch_classification(input)),
        "sent_at": time.now_ns(),
        "recipient": recipient,
        "is_complete": is_complete,
        "checks": completeness_checks,
        "status": "QUEUED",
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# TCE-2520: Status Monitor — śledzenie odpowiedzi z urzędu
# ─────────────────────────────────────────────────────────────────────────────
dispatch_status_monitor(dispatch_id, input) = monitor {
    days_since_sent := object.get(input, "days_since_sent", 0)
    response_received := object.get(input, "response_received", false)

    monitor := {"dispatch_id": dispatch_id, "days_since_sent": days_since_sent}

    monitor := object.union(monitor, {
        "status": "AWAITING_RESPONSE",
        "deadline_days": 30,
        "days_remaining": max([30 - days_since_sent, 0]),
        "escalation": "NONE",
    }) { not response_received; days_since_sent <= 30 }

    monitor := object.union(monitor, {
        "status": "OVERDUE",
        "deadline_days": 30,
        "days_remaining": 0,
        "days_overdue": days_since_sent - 30,
        "escalation": "PONAGLENIE",
    }) { not response_received; days_since_sent > 30; days_since_sent <= 60 }

    monitor := object.union(monitor, {
        "status": "CRITICAL_OVERDUE",
        "deadline_days": 30,
        "days_remaining": 0,
        "days_overdue": days_since_sent - 30,
        "escalation": "SKARGA_NA_BEZCZYNNOŚĆ",
    }) { not response_received; days_since_sent > 60 }

    monitor := object.union(monitor, {
        "status": "RESPONSE_RECEIVED",
        "deadline_days": 30,
        "days_remaining": 0,
        "escalation": "ANALIZA_ODPOWIEDZI",
    }) { response_received }
}

# ─────────────────────────────────────────────────────────────────────────────
# TCE-2530: Correspondence Registry — rejestr korespondencji
# ─────────────────────────────────────────────────────────────────────────────
correspondence_registry(entries) = registry {
    sent_count := count([e | e := entries[_]; object.get(e, "direction", "") == "SENT"])
    received_count := count([e | e := entries[_]; object.get(e, "direction", "") == "RECEIVED"])
    pending_count := count([e | e := entries[_]; object.get(e, "status", "") == "AWAITING_RESPONSE"])
    overdue_count := count([e | e := entries[_]; object.get(e, "status", "") == "OVERDUE"])
    answered_count := count([e | e := entries[_]; object.get(e, "status", "") == "ANSWERED"])

    registry := {
        "total_entries": count(entries),
        "sent": sent_count,
        "received": received_count,
        "pending": pending_count,
        "overdue": overdue_count,
        "answered": answered_count,
        "audit_trail_complete": sent_count == received_count + pending_count,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# TCE-2540: UPO Tracker — Urzędowe Potwierdzenie Odbioru
# ─────────────────────────────────────────────────────────────────────────────
upo_status(check_data) = upo {
    dispatch_id := object.get(check_data, "dispatch_id", "")
    upo_received := object.get(check_data, "upo_received", false)
    upo_timestamp := object.get(check_data, "upo_timestamp", 0)
    days_since_dispatch := object.get(check_data, "days_since_dispatch", 0)

    upo := {
        "dispatch_id": dispatch_id,
        "upo_status": "PENDING",
        "days_waiting": days_since_dispatch,
        "warn": false,
    } { not upo_received; days_since_dispatch <= 7 }

    upo := {
        "dispatch_id": dispatch_id,
        "upo_status": "MISSING_UPO",
        "days_waiting": days_since_dispatch,
        "warn": true,
        "action": "Sprawdź e-Urząd Skarbowy — UPO powinno być dostępne w ciągu 7 dni",
    } { not upo_received; days_since_dispatch > 7 }

    upo := {
        "dispatch_id": dispatch_id,
        "upo_status": "CONFIRMED",
        "upo_timestamp": upo_timestamp,
        "days_waiting": days_since_dispatch,
        "warn": false,
    } { upo_received }
}

# ─────────────────────────────────────────────────────────────────────────────
# TCE-2550: Build correspondence warnings
# ─────────────────────────────────────────────────────────────────────────────
build_tce_warnings(dispatch_result, monitor_result, upo) = warnings {
    dispatch_status := object.get(dispatch_result, "status", "ERROR")
    monitor_status := object.get(monitor_result, "status", "UNKNOWN")
    upo_status := object.get(upo, "upo_status", "PENDING")

    base := [sprintf("📬 TAX CORRESPONDENCE ENGINE — Status: %s", [dispatch_status])]

    dispatch_warn := array.concat(base, [
        "   ⚠️ Pismo NIEKOMPLETNE — sprawdź podpis, NIP, datę i podstawę prawną",
    ]) { dispatch_status == "INCOMPLETE" }

    dispatch_warn := base { dispatch_status != "INCOMPLETE" }

    base2 := dispatch_warn

    monitor_warn := array.concat(base2, [
        sprintf("   📩 Korespondencja %s: %d dni od wysłania, deadline: %d dni",
            [monitor_status, object.get(monitor_result, "days_since_sent", 0),
             object.get(monitor_result, "deadline_days", 30)]),
    ]) { monitor_status != "UNKNOWN" }

    monitor_warn := base2 { monitor_status == "UNKNOWN" }

    base3 := monitor_warn

    upo_warn := array.concat(base3, [
        "   📨 MISSING UPO — potwierdzenie odbioru nie otrzymane po 7 dniach!",
    ]) { upo_status == "MISSING_UPO" }

    upo_warn := array.concat(base3, [
        sprintf("   ✅ UPO potwierdzone: %d", [object.get(upo, "upo_timestamp", 0)]),
    ]) { upo_status == "CONFIRMED" }

    upo_warn := base3 { upo_status == "PENDING" }

    warnings := upo_warn
}

# ─────────────────────────────────────────────────────────────────────────────
# TCE-2560: Cross-domain integration — link S22 dispatch to a16 active remorse
# v7.0 FIX (LUKA-M5): Integracja czynnego żalu (KKS a16) z szablonami S22
# ─────────────────────────────────────────────────────────────────────────────
tce_a16_active_remorse_linker(input) = linker {
    is_active_remorse := object.get(input, "ord_a16_applicable", false)
    kks_art_16_conditions := {
        "before_detection": object.get(input, "a16_before_detection", false),
        "full_disclosure": object.get(input, "a16_full_disclosure", false),
        "timely_payment": object.get(input, "a16_timely_payment", false),
        "not_excluded": not object.get(input, "a16_organizer_exclusion", false),
    }
    all_met := [v | v := kks_art_16_conditions[_]; v == true]
    eligible := is_active_remorse and count(all_met) == count(kks_art_16_conditions)

    a16_routing := "BLOCK" { not eligible }
    a16_routing := "ALLOW" { eligible }

    linker := {
        "a16_applicable": true,
        "s22_template": "S22_CZ_czynny_zal_kks_a16",
        "eligible": eligible,
        "conditions": kks_art_16_conditions,
        "legal_basis": "KKS Art. 16 § 1-4",
        "routing": a16_routing,
    } { is_active_remorse }

    linker := {
        "a16_applicable": false,
        "s22_template": "",
        "routing": "",
    } { not is_active_remorse }
}

# ─────────────────────────────────────────────────────────────────────────────
# TCE-2570: Response Analyzer — analiza odpowiedzi z urzędu
# ─────────────────────────────────────────────────────────────────────────────
response_analyzer(response) = analysis {
    response_type := object.get(response, "response_type", "UNKNOWN")
    favorable := object.get(response, "favorable", false)
    deadline_to_appeal := object.get(response, "days_to_appeal", 0)

    analysis := {
        "type": "FAVORABLE",
        "action": "ARCHIVE",
        "appeal_window": 0,
    } { response_type != "UNKNOWN"; favorable }

    analysis := {
        "type": "UNFAVORABLE",
        "action": "APPEAL",
        "appeal_window": max([deadline_to_appeal, 0]),
        "appeal_deadline_hint": "14 dni od doręczenia decyzji (art. 223 OrdPU)",
    } { response_type != "UNKNOWN"; not favorable; deadline_to_appeal > 0 }

    analysis := {
        "type": "SILENCE",
        "action": "PONAGLENIE_LUB_SKARGA",
        "appeal_window": 0,
        "warning": "Brak odpowiedzi w ustawowym terminie — rozważ ponaglenie (art. 141 OrdPU)",
    } { response_type == "UNKNOWN" }
}
