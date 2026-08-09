# NexusAI JDG — Enterprise e-Delivery integration gateway.
# Legal basis: electronic delivery act and Art. 144-144c OrdPU.

package jdg.edelivery_gateway

import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.edelivery_gateway.no_match",
    "package": "jdg.edelivery_gateway",
    "priority": 9999
}

base_fields := {
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false
}

business_type := object.get(input.jdg_entrepreneur, "business_type", "JDG")
is_jdg := business_type == "JDG"
is_mandatory := not_jdg(is_jdg)

bae_registered := object.get(input.jdg_entrepreneur, "bae_registered", false)
bae_address := object.get(input.jdg_entrepreneur, "bae_address", "")
pending_delivery_count := object.get(input, "edelivery_pending_count", 0)
fiction_days_remaining := object.get(input, "edelivery_fiction_days_remaining", 999)
next_fiction_date := object.get(input, "edelivery_next_fiction_date", "")

delivery_routing(days_remaining, pending) = "BLOCK_AND_ALERT" if {
    days_remaining <= 1
    pending > 0
} else = "TRIAGE_QUEUE" if {
    days_remaining <= 7
    pending > 0
} else = "" if {
    true
}

delivery_reason(days_remaining, pending) = sprintf("FIKCJA DORĘCZENIA ZA %d DNI! %d dokumentów — odbierz NATYCHMIAST!", [days_remaining, pending]) if {
    days_remaining <= 1
} else = "" if {
    true
}

not_jdg(value) = false if {
    value == true
} else = true if {
    true
}

obligation_label(mandatory) = "OBOWIĄZKOWY" if {
    mandatory == true
} else = "DOBROWOLNY (JDG)" if {
    true
}

bae_label(registered) = "zarejestrowany" if {
    registered == true
} else = "NIEZAREJESTROWANY" if {
    true
}

fiction_warning_lines(mandatory, registered, pending, days_remaining, next_date) = warnings if {
    base := [
        "📬 e-DORĘCZENIA — STATUS JDG",
        sprintf("   Obowiązek: %s", [obligation_label(mandatory)]),
        sprintf("   Adres BAE: %s", [bae_label(registered)]),
        sprintf("   Oczekujące doręczenia: %d", [pending])
    ]
    pending > 0
    days_remaining <= 14
    warnings := array.concat(base, [sprintf("   ⚠️ Fikcja doręczenia za %d dni (%s)!", [days_remaining, next_date])])
} else = warnings if {
    warnings := [
        "📬 e-DORĘCZENIA — STATUS JDG",
        sprintf("   Obowiązek: %s", [obligation_label(mandatory)]),
        sprintf("   Adres BAE: %s", [bae_label(registered)]),
        sprintf("   Oczekujące doręczenia: %d", [pending])
    ]
}

# EDG-2330: delivery status.
decide := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.edelivery_gateway.delivery_status",
    "package": "jdg.edelivery_gateway",
    "priority": 2330,
    "edelivery_jdg_mandatory": is_mandatory,
    "edelivery_bae_registered": bae_registered,
    "edelivery_bae_address": bae_address,
    "edelivery_pending_deliveries": pending_delivery_count,
    "edelivery_fiction_days_remaining": fiction_days_remaining,
    "edelivery_next_fiction_date": next_fiction_date,
    "_routing": delivery_routing(fiction_days_remaining, pending_delivery_count),
    "_routing_reason": delivery_reason(fiction_days_remaining, pending_delivery_count),
    "_legal_basis": "Ustawa o doręczeniach elektronicznych; Art. 144-144c OrdPU",
    "_warnings": fiction_warning_lines(is_mandatory, bae_registered, pending_delivery_count, fiction_days_remaining, next_fiction_date)
}) if {
    object.get(input, "edelivery_status_check", false) == true
} else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.edelivery_gateway.eus_scanner",
    "package": "jdg.edelivery_gateway",
    "priority": 2340,
    "eus_new_messages": new_messages,
    "eus_unread_total": unread_total,
    "eus_latest_message_date": latest_message_date,
    "eus_latest_message_type": latest_message_type,
    "eus_requires_action": requires_action,
    "_routing": eus_routing,
    "_routing_reason": eus_reason,
    "_legal_basis": "Art. 144-144c OrdPU; e-Urząd Skarbowy API",
    "_warnings": [
        sprintf("🏛️ e-US SCANNER — %d nowych wiadomości (%d nieprzeczytanych)", [new_messages, unread_total]),
        sprintf("   Ostatnia: %s — %s", [latest_message_date, latest_message_type]),
        sprintf("   %s", [eus_action_label(requires_action)])
    ]
}) if {
    object.get(input, "edelivery_eus_scan", false) == true
} else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.edelivery_gateway.fiction_delivery_alert",
    "package": "jdg.edelivery_gateway",
    "priority": 2350,
    "edelivery_fiction_document_ref": document_ref,
    "edelivery_fiction_days_remaining": fiction_remaining,
    "edelivery_fiction_date": fiction_date,
    "edelivery_fiction_consequences": consequences,
    "_routing": fiction_routing,
    "_routing_reason": fiction_reason,
    "_legal_basis": "Art. 16-19 ustawy o e-Doręczeniach (fikcja po 14 dniach)",
    "_warnings": fiction_alert_warnings(document_ref, fiction_remaining, fiction_date, consequences)
}) if {
    object.get(input, "edelivery_fiction_alert", false) == true
}

# EDG-2340: e-US scanner.
new_messages := object.get(input, "eus_new_messages_count", 0)
unread_total := object.get(input, "eus_unread_total", 0)
latest_message_date := object.get(input, "eus_latest_message_date", "")
latest_message_type := object.get(input, "eus_latest_message_type", "INFORMACYJNE")
requires_action := latest_message_type in {"WEZWANIE", "DECYZJA", "POSTANOWIENIE", "ZAWIADOMIENIE", "KONTROLA"}
eus_routing = "BLOCK_AND_ALERT" if {
    requires_action
    new_messages > 0
} else = "TRIAGE_QUEUE" if {
    unread_total > 3
} else = "" if {
    true
}
eus_reason = sprintf("e-US ALERT: '%s' — wymaga natychmiastowej odpowiedzi!", [latest_message_type]) if {
    requires_action
} else = sprintf("%d nieprzeczytanych wiadomości w e-US.", [unread_total]) if {
    unread_total > 3
} else = "" if {
    true
}
eus_action_label(action_required) = "⚠️ WYMAGA DZIAŁANIA!" if {
    action_required == true
} else = "✅ Tylko informacyjne." if {
    true
}

# EDG-2350: fiction delivery alert.
document_ref := object.get(input, "edelivery_document_ref", "")
fiction_remaining := object.get(input, "edelivery_fiction_days_remaining", 14)
fiction_date := object.get(input, "edelivery_fiction_date", "")
sender := object.get(input, "edelivery_sender", "US/KAS/ZUS")
consequences := sprintf("Dokument od %s uznany za DORĘCZONY — bieg terminów procesowych rozpoczęty!", [sender])
fiction_routing = "BLOCK_AND_ALERT" if {
    fiction_remaining <= 3
} else = "TRIAGE_QUEUE" if {
    fiction_remaining <= 7
} else = "" if {
    true
}
fiction_reason = sprintf("FIKCJA DORĘCZENIA: '%s' za %d dni! Odbiór NATYCHMIAST!", [document_ref, fiction_remaining]) if {
    fiction_remaining <= 3
} else = "" if {
    true
}

fiction_alert_warnings(ref, remaining, date, consequence) = warnings if {
    remaining <= 3
    warnings := [
        sprintf("🚨 FIKCJA DORĘCZENIA — %d DNI!", [remaining]),
        sprintf("   Dokument: %s", [ref]),
        sprintf("   Data fikcji: %s", [date]),
        sprintf("   ⚠️ %s", [consequence]),
        "📋 NATYCHMIAST zaloguj się na ePUAP / e-US i ODBIERZ dokument!"
    ]
} else = warnings if {
    remaining <= 7
    warnings := [
        sprintf("⚠️ FIKCJA DORĘCZENIA ZA %d DNI — %s", [remaining, ref]),
        sprintf("   Odbierz przed %s aby uniknąć fikcji doręczenia.", [date])
    ]
} else = [sprintf("📬 e-Doręczenie '%s' — pozostało %d dni do fikcji doręczenia.", [ref, remaining])] if {
    true
}
