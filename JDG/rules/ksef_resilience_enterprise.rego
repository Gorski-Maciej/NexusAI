# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE KSeF RESILIENCE MODULE (Strategic Initiative S6)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise KSeF API Resilience — Offline, Retry, Fallback Engine
# description: |
#   ENTERPRISE v5.1 — Moduł odporności systemu KSeF. Obsługuje sytuacje awaryjne:
#   - Offline Mode: co robić gdy KSeF nie odpowiada (przerwa techniczna, awaria)
#   - Retry Engine: inteligentne ponawianie z exponential backoff
#   - Token Expiry: odświeżanie tokena sesji KSeF
#   - XML Validation: walidacja faktur przed wysyłką
#   - Error Classification: klasyfikacja błędów KSeF (4xx vs 5xx)
#   - Notification Engine: powiadomienia do US o opóźnieniach
#   - Session Recovery: odzyskiwanie sesji po awarii
#   - Batch Retry: zbiorcze ponawianie po przywróceniu
#   Wypełnia lukę: KSeF ma regularne awarie — przedsiębiorca musi wiedzieć co robić.
# architecture: Enterprise Resilience Engine, First-Match-Wins else-chain
# legal_basis: Ustawa o KSeF (Dz.U. 2023 poz. 1598); Art. 106na-106nw VAT
# package: jdg.ksef_resilience
# deprecated: false
# priority_range: 1600-1649
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.ksef_resilience

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.ksef_resilience.no_match",
    "package": "jdg.ksef_resilience", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# KSR-1600: KSEF API STATUS CHECK — sprawdzenie dostępności KSeF
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.ksef_resilience.api_health_check",
    "package": "jdg.ksef_resilience",
    "priority": 1600,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_api_status": api_status,
    "ksef_production_available": prod_available,
    "ksef_test_available": test_available,
    "ksef_maintenance_window": maintenance_active,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 106na-106nw VAT; Komunikat MF o dostępności KSeF",
    "_warnings": build_health_warnings(api_status, prod_available, maintenance_active)
} {
    input.ksef_resilience_check == true
    prod_status := object.get(object.get(input, "ksef", {}), "production_status", "UP")
    test_status := object.get(object.get(input, "ksef", {}), "test_status", "UP")
    maintenance_start := object.get(object.get(input, "ksef", {}), "maintenance_start", "")
    maintenance_end := object.get(object.get(input, "ksef", {}), "maintenance_end", "")
    current_time := object.get(input, "evaluation_datetime", "")

    prod_available = prod_status == "UP"
    test_available = test_status == "UP"

    maintenance_active = true {
        maintenance_start != ""
        maintenance_end != ""
        current_time >= maintenance_start
        current_time <= maintenance_end
    } else = false

    api_status = "OPERATIONAL" { prod_available }
    api_status = "DEGRADED" { not prod_available; test_available }
    api_status = "DOWN" { not prod_available; not test_available }

    routing = "" { prod_available }
    routing = "TRIAGE_QUEUE" { not prod_available }
    routing_reason = "" { prod_available }
    routing_reason = sprintf("KSeF niedostępny: %s", [api_status]) { not prod_available }
}

build_health_warnings(status, prod_ok, maint) = warnings {
    status == "OPERATIONAL"
    warnings := ["✅ KSeF API: produkcyjne i testowe — DOSTĘPNE. Możesz wysyłać faktury."]
} else = warnings {
    status == "DEGRADED"
    maint_msg := ""
    maint_msg := " ⚠️ TRWA PRZERWA SERWISOWA MF!" { maint }
    warnings := [sprintf("⚠️ KSeF API: PRODUKCYJNE NIEDOSTĘPNE, testowe działa.%s Użyj trybu awaryjnego (offline → późniejsza wysyłka).", [maint_msg])]
} else = warnings {
    status == "DOWN"
    warnings := ["🔴 KSeF API: CAŁKOWICIE NIEDOSTĘPNE! Przejdź w tryb OFFLINE. Faktury wystawiaj poza KSeF, wyślij batch po przywróceniu. Masz 7 dni na wysyłkę po ustaniu awarii."]
}

# ═══════════════════════════════════════════════════════════════════════════════
# KSR-1610: OFFLINE MODE — procedura awaryjna podczas awarii KSeF
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_resilience.offline_mode_procedure",
    "package": "jdg.ksef_resilience",
    "priority": 1610,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_offline_mode": true,
    "ksef_offline_deadline_hours": deadline_hours,
    "ksef_offline_pending_count": pending_count,
    "ksef_offline_max_retry_date": max_retry_date,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("OFFLINE MODE — %d faktur oczekuje na wysyłkę KSeF. Deadline: %s", [pending_count, max_retry_date]),
    "_legal_basis": "Art. 106na ust. 2-3 VAT (tryb offline w przypadku awarii KSeF); § 3 Rozporządzenia MF ws. KSeF",
    "_warnings": build_offline_warnings(pending_count, deadline_hours, max_retry_date)
} {
    input.ksef_is_offline == true
    input.invoice.document_type == "INVOICE"
    input.invoice.direction == "SALE"
    input.invoice.ksef_status == "PENDING_OFFLINE"

    pending_count := object.get(input, "ksef_offline_queue_count", 1)
    outage_start := object.get(input, "ksef_outage_start_time", "")
    outage_end_expected := object.get(input, "ksef_outage_end_expected", "")

    # Deadline: 7 dni od ustania awarii na wysyłkę (lub 24h od końca dnia awarii)
    deadline_hours := 168
    max_retry_date := ""
    # Jeśli znamy koniec awarii, deadline = koniec + 7 dni (TODO: full date arithmetic)
    max_retry_date := sprintf("%sT23:59:59 (TODO: +7 dni)", [outage_end_expected]) { outage_end_expected != "" }
    max_retry_date := "7 dni od ustania awarii (nieznana data)" { outage_end_expected == "" }
}

# TODO: Replace with time.add_date() when OPA runtime provides it.
# Current implementation is a placeholder—real date arithmetic requires external data.

build_offline_warnings(count, hours, deadline) = warnings {
    count > 0
    warnings := [
        sprintf("🔴 OFFLINE MODE AKTYWNY — %d faktur czeka na wysyłkę KSeF.", [count]),
        sprintf("⏰ DEADLINE: %s (masz %d godzin na wysyłkę po ustaniu awarii).", [deadline, hours]),
        "📋 PROCEDURA OFFLINE:",
        "   1. Wystawiaj faktury normalnie (PDF + XML lokalnie)",
        "   2. Przechowuj XML w strukturze KSeF (FA(2))",
        "   3. Po przywróceniu KSeF → wyślij batch wszystkich oczekujących",
        "   4. Zachowaj potwierdzenie próby wysyłki (timestamp)",
        "   5. Jeśli KSeF nie działa >7 dni → powiadom US o opóźnieniu",
        "⚠️ NIE wystawiaj faktur 'z datą wsteczną' po ustaniu awarii!",
        "📌 Podstawa prawna: Art. 106na ust. 2-3 VAT"
    ]
} else = ["✅ Brak faktur oczekujących w trybie offline."]

# ═══════════════════════════════════════════════════════════════════════════════
# KSR-1620: RETRY ENGINE — inteligentne ponawianie z exponential backoff
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_resilience.retry_engine",
    "package": "jdg.ksef_resilience",
    "priority": 1620,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_retry_count": retry_count,
    "ksef_retry_next_delay_seconds": next_delay,
    "ksef_retry_recommendation": recommendation,
    "ksef_retry_max_reached": max_reached,
    "_routing": retry_routing,
    "_routing_reason": retry_routing_reason,
    "_legal_basis": "Art. 106na VAT; Polityka retry KSeF MF",
    "_warnings": build_retry_warnings(retry_count, next_delay, recommendation, max_reached)
} {
    input.ksef_retry_needed == true
    retry_count := object.get(object.get(input, "ksef", {}), "retry_count", 0)
    error_code := object.get(object.get(input, "ksef", {}), "last_error_code", "")
    last_error_msg := object.get(object.get(input, "ksef", {}), "last_error_message", "")
    invoice_ref := object.get(input.invoice, "invoice_number", "")

    # Exponential backoff: 2^n * base_delay (precomputed—OPA has no pow())
    base_delay_seconds := 5
    backoff_map := {0:1,1:2,2:4,3:8,4:16,5:32,6:64,7:128,8:256,9:512,10:1024,11:2048,12:4096,13:8192,14:16384}
    mult := object.get(backoff_map, retry_count, 1024)
    next_delay := base_delay_seconds { retry_count == 0 }
    next_delay := mult * base_delay_seconds { retry_count < 10; retry_count > 0 }
    next_delay := 3600 { retry_count >= 10 }  # Cap at 1 hour

    max_retries := 15
    max_reached := retry_count >= max_retries

    # Error classification
    is_4xx := contains(error_code, "4")
    is_5xx := contains(error_code, "5")
    is_timeout := contains(lower(last_error_msg), "timeout")
    is_auth_error := contains(lower(last_error_msg), "unauthorized") or contains(lower(last_error_msg), "token")

    recommendation := "Token wygasł — odśwież token sesji przed kolejną próbą." { is_auth_error }
    recommendation := sprintf("Błąd klienta (4xx: %s). Sprawdź poprawność danych faktury przed ponowną wysyłką. NIE ponawiaj z tymi samymi danymi!", [error_code]) { is_4xx; not is_auth_error }
    recommendation := sprintf("Błąd serwera KSeF (5xx: %s). Ponów za %d sekund (exponential backoff).", [error_code, next_delay]) { is_5xx }
    recommendation := sprintf("Timeout połączenia. Sprawdź łączność, ponów za %d sekund.", [next_delay]) { is_timeout }

    retry_routing := ""
    retry_routing := "TRIAGE_QUEUE" { retry_count > 5 }
    retry_routing := "BLOCK_AND_ALERT" { max_reached }
    retry_routing_reason := ""
    retry_routing_reason := sprintf("Przekroczono 5 ponowień dla faktury %s", [invoice_ref]) { retry_count > 5; not max_reached }
    retry_routing_reason := sprintf("MAX RETRY (15) dla faktury %s — wymagana ręczna interwencja! Błąd: %s", [invoice_ref, error_code]) { max_reached }
}

build_retry_warnings(count, delay, reco, max_reached_flag) = warnings {
    max_reached_flag == true
    warnings := [
        sprintf("🚨 MAX PONOWIEŃ (%d)! System nie może wysłać faktury do KSeF.", [count]),
        sprintf("💡 REKOMENDACJA: %s", [reco]),
        "⚠️ Sprawdź ręcznie: poprawność NIP, datę faktury, format XML, token sesji KSeF.",
        "📌 Jeśli problem persistuje — zgłoś do helpdesk KSeF: https://www.podatki.gov.pl/ksef/"
    ]
} else = warnings {
    count > 3
    warnings := [
        sprintf("⚠️ Ponowienie nr %d dla KSeF (następna próba za %d s)", [count, delay]),
        sprintf("💡 %s", [reco]),
        "📊 System automatycznie ponowi wysyłkę z exponential backoff."
    ]
} else = warnings {
    count > 0
    warnings := [sprintf("🔄 Ponowienie nr %d — następna próba za %d s", [count, delay])]
} else = ["✅ Pierwsza próba wysyłki KSeF."]

# ═══════════════════════════════════════════════════════════════════════════════
# KSR-1630: TOKEN MANAGEMENT — zarządzanie tokenem sesji KSeF
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_resilience.token_management",
    "package": "jdg.ksef_resilience",
    "priority": 1630,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_token_status": token_status,
    "ksef_token_expires_in_minutes": expires_in,
    "ksef_token_renew_required": renew_required,
    "_routing": token_routing,
    "_routing_reason": token_routing_reason,
    "_legal_basis": "Art. 106nb VAT; API KSeF — specyfikacja techniczna MF",
    "_warnings": build_token_warnings(token_status, expires_in)
} {
    input.ksef_token_check == true
    token_expiry := object.get(object.get(input, "ksef", {}), "token_expiry_datetime", "")
    current_time := object.get(input, "evaluation_datetime", "")
    token_exists := object.get(object.get(input, "ksef", {}), "token_available", false)

    # Token lifetime: 600 minut (10 godzin) dla środowiska produkcyjnego KSeF
    token_max_lifetime := 600
    expires_in := 0

    # Calculate remaining time
    expires_in := token_max_lifetime { not token_exists }
    expires_in := calculate_remaining_minutes(token_expiry, current_time) { token_exists }

    token_status := "MISSING" { not token_exists }
    token_status := "EXPIRED" { token_exists; expires_in <= 0 }
    token_status := "EXPIRING_SOON" { token_exists; expires_in > 0; expires_in <= 30 }
    token_status := "VALID" { token_exists; expires_in > 30 }

    renew_required := token_status in {"MISSING", "EXPIRED", "EXPIRING_SOON"}

    token_routing := ""
    token_routing := "TRIAGE_QUEUE" { token_status == "EXPIRED" }
    token_routing := "BLOCK_AND_ALERT" { token_status == "MISSING" }
    token_routing_reason := ""
    token_routing_reason := "Token KSeF wygasł — odśwież przed wysyłką" { token_status == "EXPIRED" }
    token_routing_reason := "Brak tokena KSeF — wygeneruj token sesji przed wysyłką faktur!" { token_status == "MISSING" }
}

calculate_remaining_minutes(expiry_str, current_str) = minutes {
    # Simplified: extract hour/minute difference (real implementation uses timestamps)
    expiry_hour := to_number(substring(expiry_str, 11, 13))
    current_hour := to_number(substring(current_str, 11, 13))
    expiry_min := to_number(substring(expiry_str, 14, 16))
    current_min := to_number(substring(current_str, 14, 16))
    diff_min := (expiry_hour - current_hour) * 60 + (expiry_min - current_min)
    minutes := diff_min
}

build_token_warnings(status, remaining_min) = warnings {
    status == "VALID"
    warnings := [sprintf("✅ Token KSeF ważny przez jeszcze %d minut.", [remaining_min])]
} else = warnings {
    status == "EXPIRING_SOON"
    warnings := [sprintf("⚠️ Token KSeF wygaśnie za %d minut. Odśwież token przed wysyłką.", [remaining_min])]
} else = warnings {
    status == "EXPIRED"
    warnings := ["🔴 Token KSeF WYGASŁ! Wygeneruj nowy token przez API KSeF /online/Session/AuthorisationChallenge."]
} else = ["🚨 BRAK TOKENA KSeF! Zainicjuj sesję: POST /online/Session/AuthorisationChallenge → GET /online/Session/AuthorisationToken"]

# ═══════════════════════════════════════════════════════════════════════════════
# KSR-1640: XML SCHEMA VALIDATION — walidacja przed wysyłką
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_resilience.xml_validation_preflight",
    "package": "jdg.ksef_resilience",
    "priority": 1640,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_xml_schema_version": "FA(2) v3.0",
    "ksef_xml_structure_valid": xml_valid,
    "ksef_xml_missing_fields": missing_fields,
    "ksef_xml_business_rules_ok": business_rules_ok,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "XML KSeF nie przechodzi walidacji — napraw przed wysyłką",
    "_legal_basis": "Rozporządzenie MF ws. struktury FA(2); Art. 106na VAT; Specyfikacja XSD KSeF",
    "_warnings": build_xml_validation_warnings(xml_valid, missing_fields, business_rules_ok)
} {
    input.ksef_validate_xml == true
    xml_valid := object.get(object.get(input, "ksef", {}), "xml_schema_valid", true)
    business_rules_ok := object.get(object.get(input, "ksef", {}), "xml_business_rules_ok", true)
    missing_fields := object.get(object.get(input, "ksef", {}), "xml_missing_fields", [])

    # Critical business rules for FA(2) that MUST pass
    has_nip_seller := object.get(input, "seller_nip", "") != ""
    has_invoice_date := object.get(input.invoice, "issue_date", "") != ""
    has_invoice_number := object.get(input.invoice, "invoice_number", "") != ""
    has_amount := object.get(input.invoice, "amount_gross", 0) > 0

    # Build missing fields list
    missing_check := []
    missing_check := array.concat(missing_check, ["Sprzedawca NIP"]) { not has_nip_seller }
    missing_check := array.concat(missing_check, ["Data wystawienia"]) { not has_invoice_date }
    missing_check := array.concat(missing_check, ["Numer faktury"]) { not has_invoice_number }
    missing_check := array.concat(missing_check, ["Kwota brutto"]) { not has_amount }

    xml_valid := xml_valid and has_nip_seller and has_invoice_date and has_invoice_number and has_amount
    business_rules_ok := business_rules_ok and xml_valid
    missing_fields := array.concat(missing_fields, missing_check)

    # Only fire BLOCK if XML actually invalid
    not xml_valid
}

build_xml_validation_warnings(xml_ok, missing, rules_ok) = warnings {
    not xml_ok
    missing_list := concat(", ", missing)
    warnings := [
        sprintf("🔴 WALIDACJA XML FA(2) NIEUDANA! Brakujące pola: %s", [missing_list]),
        "📋 SPRAWDŹ:",
        "   • NIP sprzedawcy (obowiązkowy)",
        "   • Data wystawienia faktury (YYYY-MM-DD)",
        "   • Numer faktury (unikalny w systemie)",
        "   • Kwota brutto > 0",
        "   • NIP nabywcy (dla B2B) — obowiązkowy od 2026",
        "📌 Struktura FA(2) v3.0 wymaga co najmniej 15 pól obowiązkowych.",
        "   Sprawdź pełną specyfikację: https://www.podatki.gov.pl/ksef/struktury-fa/"
    ]
} else = ["✅ XML FA(2) przeszedł walidację strukturalną — gotowy do wysyłki."]

# ═══════════════════════════════════════════════════════════════════════════════
# KSR-1645: BATCH RECOVERY — zbiorcze ponawianie po przywróceniu KSeF
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_resilience.batch_recovery",
    "package": "jdg.ksef_resilience",
    "priority": 1645,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_batch_size": batch_size,
    "ksef_batch_oldest_pending_hours": oldest_age_hours,
    "ksef_batch_recovery_plan": recovery_plan,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Batch recovery: %d faktur do wysłania po przywróceniu KSeF", [batch_size]),
    "_legal_basis": "Art. 106na ust. 3 VAT",
    "_warnings": build_batch_warnings(batch_size, oldest_age_hours)
} {
    input.ksef_start_recovery == true
    input.ksef_is_offline == false  # KSeF wrócił — recovery mode
    pending_invoices := object.get(input, "ksef_offline_queue", [])
    batch_size := count(pending_invoices)

    oldest_timestamp := ""
    oldest_timestamp := object.get(pending_invoices[0], "created_at", "") { batch_size > 0 }
    current_time := object.get(input, "evaluation_datetime", "")

    oldest_age_hours := 0
    oldest_age_hours := calculate_age_hours(oldest_timestamp, current_time) { oldest_timestamp != "" }

    # Recovery plan: batch size determines strategy
    recovery_plan := "single" { batch_size <= 3 }
    recovery_plan := "batch_3_per_cycle" { batch_size > 3; batch_size <= 20 }
    recovery_plan := "batch_10_per_cycle" { batch_size > 20 }

    batch_size > 0
}

calculate_age_hours(old_ts, new_ts) = hours {
    old_h := to_number(substring(old_ts, 11, 13))
    new_h := to_number(substring(new_ts, 11, 13))
    hours := new_h - old_h
}

build_batch_warnings(size, age) = warnings {
    size > 0
    warnings := [
        sprintf("🔄 BATCH RECOVERY: %d faktur do wysłania po przywróceniu KSeF.", [size]),
        sprintf("⏰ Najstarsza faktura czeka %d godzin.", [age]),
        "📋 PLAN: Wysyłaj chronologicznie (od najstarszej), monitoruj statusy UPO.",
        sprintf("⚠️ MASZ 7 DNI od ustania awarii na wysyłkę! Najstarsza faktura ma już %d godz.", [age]) { age >= 120 }
    ]
} else = ["✅ Wszystkie faktury wysłane. Batch recovery zakończony."]

# ═══════════════════════════════════════════════════════════════════════════════
# KSR-1648: NOTIFICATION TO TAX OFFICE — powiadomienie US o opóźnieniu
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_resilience.notify_tax_office",
    "package": "jdg.ksef_resilience",
    "priority": 1648,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_notification_required": true,
    "ksef_notification_reason": "KSeF outage >7 days",
    "ksef_notification_deadline": notification_deadline,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("POWIADOM US — awaria KSeF przekroczyła 7 dni. Złóż zawiadomienie ZAW-NR do %s", [notification_deadline]),
    "_legal_basis": "Art. 106na ust. 4 VAT; Obwieszczenie MF ws. wzoru ZAW-NR",
    "_warnings": [
        "🚨 AWARIA KSeF PRZEKROCZYŁA 7 DNI!",
        "📋 PROCEDURA:",
        "   1. Złów zawiadomienie ZAW-NR (wzór z obwieszczenia MF)",
        "   2. Wyślij do właściwego Naczelnika US (przez e-PUAP lub e-Urząd Skarbowy)",
        "   3. Dołącz listę faktur wystawionych poza KSeF (daty, numery, NIP nabywców)",
        "   4. Zachowaj UPO (Urzędowe Poświadczenie Odbioru) z e-PUAP",
        "⚠️ Termin: 7 dni od dnia następującego po ostatnim dniu awarii KSeF",
        "📌 Bez ZAW-NR grozi kara do 5000 PLN za każdy przypadek (Art. 106nb VAT)!"
    ]
} {
    input.ksef_is_offline == true
    input.ksef_outage_duration_hours > 168  # 7 dni × 24h
    object.get(input, "ksef_zaw_nr_sent", false) == false

    outage_last_day := object.get(input, "ksef_outage_start_time", "")
    notification_deadline := ""
    notification_deadline := sprintf("%s + 8 dni", [outage_last_day]) { outage_last_day != "" }
    notification_deadline := "7 dni od zakończenia awarii" { outage_last_day == "" }
}
