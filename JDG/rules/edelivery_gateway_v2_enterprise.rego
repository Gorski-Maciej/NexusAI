# NexusAI JDG Enterprise — e-Doręczenia Gateway helper layer.
# Covers EDE address checks, PUH dispatch, UPO capture and shared outbox retention.

package jdg.enterprise.edelivery_gateway

import data.jdg.helpers

requires_ede_for(is_jdg, ceidg_registered) = true if {
    is_jdg == true
    ceidg_registered == true
} else = false if {
    true
}

missing_ede_for(requires_ede, has_address) = true if {
    requires_ede == true
    has_address == false
} else = false if {
    true
}

ede_action_for(missing, has_address) = "ZAREJESTRUJ ADRES DO DORĘCZEŃ ELEKTRONICZNYCH (EDE/PUH)!" if {
    missing == true
} else = "Adres EDE aktywny — OK" if {
    has_address == true
} else = "N/D" if {
    true
}

ede_routing_for(missing) = "BLOCK_AND_ALERT" if {
    missing == true
} else = "PASS" if {
    true
}

# EDG2-3100: EPU-400 — check EDE address.
ede_check_address(input) = check if {
    has_ede_address := object.get(input, "has_ede_address", false)
    ede_address := object.get(input, "ede_address", "")
    is_jdg := object.get(input, "business_type", "") == "JDG"
    ceidg_registered := object.get(input, "ceidg_registered", false)
    requires_ede := requires_ede_for(is_jdg, ceidg_registered)
    missing_ede := missing_ede_for(requires_ede, has_ede_address)
    check := {
        "article": "EPU-400",
        "has_ede_address": has_ede_address,
        "ede_address": ede_address,
        "requires_ede": requires_ede,
        "missing_ede": missing_ede,
        "action": ede_action_for(missing_ede, has_ede_address),
        "consequence_if_missing": "Doręczenie zastępcze (KEP), fikcja doręczenia po 14 dniach (art. 39-43 u.d.e.)",
        "deadline": "2025-10-01 (obowiązek dla JDG w CEIDG)",
        "routing": ede_routing_for(missing_ede),
        "legal_basis": "Art. 13-28, 39-43 ustawy o doręczeniach elektronicznych"
    }
}

# EDG2-3110: PUH API dispatch adapter.
ede_dispatch_via_puh(input) = result if {
    delivery_address := object.get(input, "ede_address", "")
    letter_content := object.get(input, "letter_content", "")
    letter_type := object.get(input, "letter_type", "GENERAL")
    has_signature := object.get(input, "has_qualified_signature", false)
    is_valid := count(delivery_address) > 0
    content_valid := count(letter_content) > 0
    signature_valid := has_signature == true
    dispatch_valid := all_dispatch_requirements(is_valid, content_valid, signature_valid)
    result := {
        "dispatch_id": sprintf("EDE-PUH-%d", [time.now_ns()]),
        "address": delivery_address,
        "letter_type": letter_type,
        "is_valid": dispatch_valid,
        "status": dispatch_status_for(dispatch_valid),
        "delivery_fiction_days": 14,
        "legal_basis": "Art. 39-43 u.d.e. — fikcja doręczenia po 14 dniach"
    }
}

all_dispatch_requirements(address_valid, content_valid, signature_valid) = true if {
    address_valid == true
    content_valid == true
    signature_valid == true
} else = false if {
    true
}

dispatch_status_for(valid) = "QUEUED_FOR_DISPATCH" if {
    valid == true
} else = "REJECTED_MISSING_DATA" if {
    true
}

# EDG2-3120: UPO capture and delivery tracking.
ede_upo_capture(dispatch_result, check_data) = upo if {
    dispatch_id := object.get(dispatch_result, "dispatch_id", "")
    days_since_sent := object.get(check_data, "days_since_sent", 0)
    upo_received := object.get(check_data, "upo_received", false)
    upo_status := upo_status_for(upo_received, days_since_sent)
    upo := {
        "dispatch_id": dispatch_id,
        "upo_status": upo_status,
        "days_waiting": days_since_sent,
        "fiction_days": 14,
        "warning": upo_warning_for(upo_status),
        "delivery_date": delivery_date_for(upo_received)
    }
}

upo_status_for(received, days) = "CONFIRMED" if {
    received == true
} else = "EXPIRED" if {
    received == false
    days >= 30
} else = "DELIVERY_FICTION_APPLIED" if {
    received == false
    days >= 14
} else = "PENDING" if {
    true
}

upo_warning_for(status) = "FIKCJA DORĘCZENIA — odbiór uznany za dokonany po 14 dniach (art. 39-43 u.d.e.)" if {
    status == "DELIVERY_FICTION_APPLIED"
} else = "" if {
    true
}

delivery_date_for(received) = time.now_ns() if {
    received == true
} else = 0 if {
    true
}

# EDG2-3130: shared outbox with KSeF and S22 retention.
ede_shared_outbox(entries) = outbox if {
    ede_entries := [entry | entry := entries[_]; object.get(entry, "channel", "") == "EDE"]
    s22_entries := [entry | entry := entries[_]; object.get(entry, "channel", "") == "S22"]
    ksef_entries := [entry | entry := entries[_]; object.get(entry, "channel", "") == "KSEF"]
    outbox := {
        "total_entries": count(entries),
        "ede_sent": count(ede_entries),
        "s22_sent": count(s22_entries),
        "ksef_sent": count(ksef_entries),
        "retention_required_years": 5,
        "retention_deadline": "2026-10-01 + 5 lat = 2031-10-01"
    }
}

# EDG2-3140: warning builder.
build_edg2_warnings(ede_check, dispatch, upo) = warnings if {
    missing_ede := object.get(ede_check, "missing_ede", false)
    dispatch_status := object.get(dispatch, "status", "UNKNOWN")
    upo_status := object.get(upo, "upo_status", "PENDING")
    base := edg2_check_warnings(missing_ede)
    warnings := edg2_upo_warnings(base, dispatch_status, upo_status)
}

edg2_check_warnings(missing) = [
    "📬 E-DORĘCZENIA GATEWAY (PUH API)",
    "   🚨 BRAK ADRESU EDE! Zarejestruj natychmiast w CEIDG!",
    "   ⚠️ Konsekwencja: doręczenie zastępcze + fikcja po 14 dniach"
] if {
    missing == true
} else = [
    "📬 E-DORĘCZENIA GATEWAY (PUH API)",
    "   ✅ Adres EDE aktywny"
] if {
    true
}

edg2_upo_warnings(base, dispatch_status, upo_status) = warnings if {
    upo_status == "DELIVERY_FICTION_APPLIED"
    warnings := array.concat(base, [sprintf("   📨 Status UPO: %s", [upo_status])])
} else = base if {
    true
}
