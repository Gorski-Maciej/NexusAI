# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE e-DELIVERY INTEGRATION GATEWAY (Innovation 8.5, P18 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise e-Delivery Gateway — Automated BAE & e-US Integration
# description: |
#   ENTERPRISE v7.0 — Bramka automatycznych e-Doręczeń. Integruje BAE (Baza
#   Adresów Elektronicznych), e-US (e-Urząd Skarbowy), e-PUAP i profil zaufany.
#
#   KLUCZOWE FUNKCJE:
#   - Automatyczna rejestracja adresu BAE dla JDG
#   - Monitorowanie fikcji doręczenia (14 dni) z alertami 7/3/1 dzień
#   - Integracja e-US: automatyczne pobieranie korespondencji z US
#   - eIDAS/DAC/CRS/FATCA — walidacja transgraniczna
#   - v7.0 FIX (LUKA-D2): Rozróżnienie dobrowolność JDG vs obowiązek KRS
#
# architecture: Enterprise v7.0 First-Match-Wins
# legal_basis: Ustawa o doręczeniach elektronicznych (Dz.U. 2020 poz. 2320)
# package: jdg.edelivery_gateway
# deprecated: false
# priority_range: 2330-2359
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.edelivery_gateway

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.edelivery_gateway.no_match",
    "package": "jdg.edelivery_gateway", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# EDG-2330: e-DELIVERY STATUS — Status e-Doręczeń dla JDG
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.edelivery_gateway.delivery_status",
    "package": "jdg.edelivery_gateway",
    "priority": 2330,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "edelivery_jdg_mandatory": is_mandatory,
    "edelivery_bae_registered": bae_registered,
    "edelivery_bae_address": bae_address,
    "edelivery_pending_deliveries": pending_count,
    "edelivery_fiction_days_remaining": fiction_days,
    "edelivery_next_fiction_date": next_fiction,
    "_routing": edel_routing,
    "_routing_reason": edel_reason,
    "_legal_basis": "Ustawa o doręczeniach elektronicznych (Dz.U. 2020 poz. 2320); Art. 144-144c OrdPU",
    "_warnings": build_edelivery_warnings(is_mandatory, bae_registered, pending_count, fiction_days, next_fiction)
} {
    input.edelivery_status_check == true
    business_type := object.get(input.jdg_entrepreneur, "business_type", "JDG")

    # v7.0 FIX (P18 LUKA-D2): e-Doręczenia dla JDG (osób fizycznych) są DOBROWOLNE.
    # Obowiązkowe tylko dla podmiotów publicznych, zawodów zaufania i spółek KRS.
    is_jdg := business_type == "JDG"
    is_mandatory := not is_jdg

    bae_registered := object.get(input.jdg_entrepreneur, "bae_registered", false)
    bae_address := object.get(input.jdg_entrepreneur, "bae_address", "")
    pending_count := object.get(input, "edelivery_pending_count", 0)
    fiction_days := object.get(input, "edelivery_fiction_days_remaining", 999)
    next_fiction := object.get(input, "edelivery_next_fiction_date", "")

    edel_routing := "BLOCK_AND_ALERT" { fiction_days <= 1; pending_count > 0 }
    edel_routing := "TRIAGE_QUEUE" { fiction_days <= 7; pending_count > 0 }
    edel_routing := "" { true }
    edel_reason := sprintf("FIKCJA DORĘCZENIA ZA %d DNI! %d dokumentów — odbierz NATYCHMIAST!", [fiction_days, pending_count]) { fiction_days <= 1 }
    edel_reason := "" { true }
}

build_edelivery_warnings(mandatory, bae_ok, pending, fiction, next) = warnings {
    obowiazek_text := "DOBROWOLNY (JDG)" { not mandatory }
    obowiazek_text := "OBOWIĄZKOWY" { mandatory }
    bae_text := "zarejestrowany" { bae_ok }
    bae_text := "NIEZAREJESTROWANY" { not bae_ok }
    base := [
        sprintf("📬 e-DORĘCZENIA — STATUS JDG", []),
        sprintf("   Obowiązek: %s", [obowiazek_text]),
        sprintf("   Adres BAE: %s", [bae_text]),
        sprintf("   Oczekujące doręczenia: %d", [pending]),
    ]
    with_fiction := array.concat(base, [sprintf("   ⚠️ Fikcja doręczenia za %d dni (%s)!", [fiction, next])]) { fiction <= 14; pending > 0 }
    with_fiction := base { fiction > 14 or pending == 0 }
    warnings := with_fiction
}

# ═══════════════════════════════════════════════════════════════════════════════
# EDG-2340: e-US SCANNER — Automatyczne skanowanie e-US
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.edelivery_gateway.eus_scanner",
    "package": "jdg.edelivery_gateway",
    "priority": 2340,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "eus_new_messages": new_msgs,
    "eus_unread_total": unread_total,
    "eus_latest_message_date": latest_date,
    "eus_latest_message_type": latest_type,
    "eus_requires_action": requires_action,
    "_routing": eus_routing,
    "_routing_reason": eus_reason,
    "_legal_basis": "Art. 144-144c OrdPU; e-Urząd Skarbowy API",
    "_warnings": [
        sprintf("🏛️ e-US SCANNER — %d nowych wiadomości (%d nieprzeczytanych)", [new_msgs, unread_total]),
        sprintf("   Ostatnia: %s — %s", [latest_date, latest_type]),
        sprintf("   %s", [action_text]),
    ]
} {
    input.edelivery_eus_scan == true
    new_msgs := object.get(input, "eus_new_messages_count", 0)
    unread_total := object.get(input, "eus_unread_total", 0)
    latest_date := object.get(input, "eus_latest_message_date", "")
    latest_type := object.get(input, "eus_latest_message_type", "INFORMACYJNE")

    action_types := {"WEZWANIE", "DECYZJA", "POSTANOWIENIE", "ZAWIADOMIENIE", "KONTROLA"}
    requires_action := latest_type in action_types

    action_text := "⚠️ WYMAGA DZIAŁANIA!" { requires_action }
    action_text := "✅ Tylko informacyjne." { not requires_action }

    eus_routing := "BLOCK_AND_ALERT" { requires_action; new_msgs > 0 }
    eus_routing := "TRIAGE_QUEUE" { unread_total > 3 }
    eus_routing := "" { true }
    eus_reason := sprintf("e-US ALERT: '%s' — wymaga natychmiastowej odpowiedzi!", [latest_type]) { requires_action }
    eus_reason := sprintf("%d nieprzeczytanych wiadomości w e-US.", [unread_total]) { unread_total > 3 }
    eus_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EDG-2350: FICTION DELIVERY ALERT — System alertów przed fikcją doręczenia
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.edelivery_gateway.fiction_delivery_alert",
    "package": "jdg.edelivery_gateway",
    "priority": 2350,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "edelivery_fiction_document_ref": doc_ref,
    "edelivery_fiction_days_remaining": remaining,
    "edelivery_fiction_date": fiction_date,
    "edelivery_fiction_consequences": consequences,
    "_routing": fiction_routing,
    "_routing_reason": fiction_reason,
    "_legal_basis": "Art. 16-19 ustawy o e-Doręczeniach (fikcja doręczenia po 14 dniach)",
    "_warnings": build_fiction_warnings(doc_ref, remaining, fiction_date, consequences)
} {
    input.edelivery_fiction_alert == true
    doc_ref := object.get(input, "edelivery_document_ref", "")
    remaining := object.get(input, "edelivery_fiction_days_remaining", 14)
    fiction_date := object.get(input, "edelivery_fiction_date", "")
    sender := object.get(input, "edelivery_sender", "US/KAS/ZUS")

    consequences := sprintf("Dokument od %s uznany za DORĘCZONY — bieg terminów procesowych rozpoczęty!", [sender])

    fiction_routing := "BLOCK_AND_ALERT" { remaining <= 3 }
    fiction_routing := "TRIAGE_QUEUE" { remaining <= 7 }
    fiction_routing := "" { true }
    fiction_reason := sprintf("FIKCJA DORĘCZENIA: '%s' za %d dni! Odbiór NATYCHMIAST!", [doc_ref, remaining]) { remaining <= 3 }
    fiction_reason := "" { true }
}

build_fiction_warnings(ref, remaining, date, consequences) = warnings {
    remaining <= 3
    warnings := [
        sprintf("🚨 FIKCJA DORĘCZENIA — %d DNI!", [remaining]),
        sprintf("   Dokument: %s", [ref]),
        sprintf("   Data fikcji: %s", [date]),
        sprintf("   ⚠️ %s", [consequences]),
        "📋 NATYCHMIAST zaloguj się na ePUAP / e-US i ODBIERZ dokument!",
    ]
} else = warnings {
    remaining <= 7
    warnings := [
        sprintf("⚠️ FIKCJA DORĘCZENIA ZA %d DNI — %s", [remaining, ref]),
        sprintf("   Odbierz przed %s aby uniknąć fikcji doręczenia.", [date]),
    ]
} else = [
    sprintf("📬 e-Doręczenie '%s' — pozostało %d dni do fikcji doręczenia.", [ref, remaining]),
]
