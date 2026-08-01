# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise — Innovation 14.4: e-Doręczenia Gateway (PUH API)
# v7.0 — BP-4: EPU-400 check_ede_address + dispatch adapter + UPO capture
# Package: jdg.enterprise.edelivery_gateway
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.enterprise.edelivery_gateway

import data.jdg.helpers

# ─────────────────────────────────────────────────────────────────────────────
# EDG2-3100: EPU-400 — Check EDE address + alert if missing
# v7.0 FIX (LUKA-KEPU-1/KEPU-2): e-Doręczenia Gateway
# ─────────────────────────────────────────────────────────────────────────────
ede_check_address(input) = check {
    has_ede_address := object.get(input, "has_ede_address", false)
    ede_address := object.get(input, "ede_address", "")
    is_jdg := object.get(input, "business_type", "") == "JDG"
    ceidg_registered := object.get(input, "ceidg_registered", false)

    requires_ede := is_jdg and ceidg_registered
    missing_ede := requires_ede and not has_ede_address

    action := "ZAREJESTRUJ ADRES DO DORĘCZEŃ ELEKTRONICZNYCH (EDE/PUH)!" { missing_ede }
    action := "Adres EDE aktywny — OK" { has_ede_address }
    action := "N/D" { true }

    routing := "BLOCK_AND_ALERT" { missing_ede }
    routing := "PASS" { not missing_ede }

    check := {
        "article": "EPU-400",
        "has_ede_address": has_ede_address,
        "ede_address": ede_address,
        "requires_ede": requires_ede,
        "missing_ede": missing_ede,
        "action": action,
        "consequence_if_missing": "Doręczenie zastępcze (KEP), fikcja doręczenia po 14 dniach (art. 39-43 u.d.e.)",
        "deadline": "2025-10-01 (obowiązek dla JDG w CEIDG)",
        "routing": routing,
        "legal_basis": "Art. 13-28, 39-43 ustawy o doręczeniach elektronicznych",
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# EDG2-3110: PUH API dispatch adapter — wysyłka przez e-Doręczenia
# ─────────────────────────────────────────────────────────────────────────────
ede_dispatch_via_puh(input) = result {
    delivery_address := object.get(input, "ede_address", "")
    letter_content := object.get(input, "letter_content", "")
    letter_type := object.get(input, "letter_type", "GENERAL")
    has_signature := object.get(input, "has_qualified_signature", false)

    is_valid := count(delivery_address) > 0 and count(letter_content) > 0 and has_signature

    dispatch_status := "QUEUED_FOR_DISPATCH" { is_valid }
    dispatch_status := "REJECTED_MISSING_DATA" { not is_valid }

    result := {
        "dispatch_id": sprintf("EDE-PUH-%d", [time.now_ns()]),
        "address": delivery_address,
        "letter_type": letter_type,
        "is_valid": is_valid,
        "status": dispatch_status,
        "delivery_fiction_days": 14,
        "legal_basis": "Art. 39-43 u.d.e. — fikcja doręczenia po 14 dniach",
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# EDG2-3120: UPO capture + delivery tracking
# ─────────────────────────────────────────────────────────────────────────────
ede_upo_capture(dispatch_result, check_data) = upo {
    dispatch_id := object.get(dispatch_result, "dispatch_id", "")
    days_since_sent := object.get(check_data, "days_since_sent", 0)
    upo_received := object.get(check_data, "upo_received", false)

    # Mutually exclusive guards — complete rules
    upo_status := "CONFIRMED" { upo_received }
    upo_status := "EXPIRED" { not upo_received; days_since_sent >= 30 }
    upo_status := "DELIVERY_FICTION_APPLIED" { not upo_received; days_since_sent >= 14; days_since_sent < 30 }
    upo_status := "PENDING" { true }

    fiction_warning := "FIKCJA DORĘCZENIA — odbiór uznany za dokonany po 14 dniach (art. 39-43 u.d.e.)" {
        upo_status == "DELIVERY_FICTION_APPLIED"
    }
    fiction_warning := "" { upo_status != "DELIVERY_FICTION_APPLIED" }

    delivery_date := time.now_ns() { upo_received }
    delivery_date := 0 { true }

    upo := {
        "dispatch_id": dispatch_id,
        "upo_status": upo_status,
        "days_waiting": days_since_sent,
        "fiction_days": 14,
        "warning": fiction_warning,
        "delivery_date": delivery_date,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# EDG2-3130: Shared outbox with KSeF + S22 retention
# ─────────────────────────────────────────────────────────────────────────────
ede_shared_outbox(entries) = outbox {
    ede_entries := [e | e := entries[_]; object.get(e, "channel", "") == "EDE"]
    s22_entries := [e | e := entries[_]; object.get(e, "channel", "") == "S22"]
    ksef_entries := [e | e := entries[_]; object.get(e, "channel", "") == "KSEF"]

    retention_years := 5  # Wymóg u.d.e.

    outbox := {
        "total_entries": count(entries),
        "ede_sent": count(ede_entries),
        "s22_sent": count(s22_entries),
        "ksef_sent": count(ksef_entries),
        "retention_required_years": retention_years,
        "retention_deadline": "2026-10-01 + 5 lat = 2031-10-01",
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# EDG2-3140: Build EDG2 warnings
# ─────────────────────────────────────────────────────────────────────────────
build_edg2_warnings(ede_check, dispatch, upo) = warnings {
    missing_ede := object.get(ede_check, "missing_ede", false)
    dispatch_status := object.get(dispatch, "status", "UNKNOWN")
    upo_status := object.get(upo, "upo_status", "PENDING")

    base := ["📬 E-DORĘCZENIA GATEWAY (PUH API)"]

    check_warn := array.concat(base, [
        "   🚨 BRAK ADRESU EDE! Zarejestruj natychmiast w CEIDG!",
        "   ⚠️ Konsekwencja: doręczenie zastępcze + fikcja po 14 dniach",
    ]) { missing_ede }

    check_warn := array.concat(base, ["   ✅ Adres EDE aktywny"]) { not missing_ede }

    base2 := check_warn

    upo_warn := array.concat(base2, [
        sprintf("   📨 Status UPO: %s", [upo_status]),
    ]) { upo_status == "DELIVERY_FICTION_APPLIED" }

    upo_warn := base2 { upo_status != "DELIVERY_FICTION_APPLIED" }

    warnings := upo_warn
}
