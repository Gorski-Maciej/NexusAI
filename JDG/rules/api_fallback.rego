# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — API Graceful Degradation & Fallback (P1850-P1855)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: API Graceful Degradation — Fallback dla Białej Listy, CEIDG, KSeF, GUS, NBP
# description: |
#   Reguły graceful degradation dla awarii zewnętrznych API:
#   P1850: Biała Lista MF offline → TRIAGE (nie blokuj automatycznie)
#   P1851: CEIDG API offline → warning (nie blokuj, chyba że fraud_flag)
#   P1852: KSeF offline → tryb awaryjny (7 dni na wysyłkę)
#   P1853: GUS BIR offline → pending verification
#   P1854: NBP API offline → użyj kursu z cache
#   P1855: Multi-API degradation → eskalacja do TRIAGE
# architecture: Multi-Pass PAS 2 (ADR-001) — operuje na poziomie compliance
# legal_basis: Art. 106ne VAT (KSeF offline), Art. 96b VAT (Biała Lista)
# edge_cases:
#   - Cache valid 30 dni dla Białej Listy (zgodnie z wymogami MF)
#   - NBP: użyj ostatniego kursu z cache z ostrzeżeniem
#   - KSeF offline: 7 dni na wysyłkę po przywróceniu (Art. 106ne VAT)
# package: jdg.api_fallback
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.api_fallback

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.api_fallback.no_match",
    "package": "jdg.api_fallback", "priority": 1899
}

# ══════ P1850: api_whitelist_graceful_degradation — Biała Lista MF offline ══════
decide := {
    "matched": true, "rule_id": "jdg.api_fallback.whitelist_degradation",
    "package": "jdg.api_fallback", "priority": 1850,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "", "vat_exemption": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "api_status": "WHITELIST_DEGRADED", "whitelist_check_retry": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Biała Lista MF niedostępna — faktura wstrzymana do weryfikacji manualnej",
    "_legal_basis": "Art. 96b VAT — weryfikacja Białej Listy",
    "_warnings": [
        "BIAŁA LISTA MF NIEDOSTĘPNA — API offline lub timeout. Faktura wstrzymana (TRIAGE). Nie blokujemy automatycznie. Zweryfikuj manualnie na portalu MF lub zaczekaj na ponowną próbę. Cache ważny 30 dni."
    ]
} {
    input.vendor.whitelist_status == "UNKNOWN"
    object.get(input.vendor, "whitelist_check_expired", true) == true
}

# ══════ P1851: api_ceidg_graceful_degradation — CEIDG API offline ══════
else := {
    "matched": true, "rule_id": "jdg.api_fallback.ceidg_degradation",
    "package": "jdg.api_fallback", "priority": 1851,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "", "vat_exemption": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "api_status": "CEIDG_DEGRADED", "ceidg_check_retry": true,
    "_routing": "",
    "_routing_reason": "CEIDG niedostępne — weryfikacja odroczona",
    "_legal_basis": "Art. 22-25 Prawa przedsiębiorców",
    "_warnings": [
        sprintf("CEIDG API NIEDOSTĘPNE — nie można zweryfikować statusu kontrahenta %s. Dodano do kolejki ponownej weryfikacji. Nie blokujemy transakcji (brak fraud_flag).", [vendor_name])
    ]
} {
    input.vendor.ceidg_status == "UNKNOWN"
    object.get(input.vendor, "fraud_flag", false) == false
    vendor_name := object.get(input.vendor, "name", "N/A")
}

# ══════ P1852: api_ksef_graceful_degradation — KSeF offline ══════
else := {
    "matched": true, "rule_id": "jdg.api_fallback.ksef_degradation",
    "package": "jdg.api_fallback", "priority": 1852,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "KSEF_OFFLINE", "vat_exemption": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "api_status": "KSEF_DEGRADED", "ksef_offline_mode": true,
    "ksef_submission_deadline_days": 7,
    "invoice_number_suffix": "/OFFLINE",
    "_routing": "FALLBACK_ACTIVE",
    "_routing_reason": "KSeF offline — tryb awaryjny. 7 dni na wysyłkę po przywróceniu.",
    "_legal_basis": "Art. 106ne VAT — tryb awaryjny KSeF",
    "_warnings": [
        sprintf("KSeF OFFLINE — system niedostępny od %s. Tryb awaryjny aktywny. Faktura wystawiana z sufiksem /OFFLINE. MASZ 7 DNI na przesłanie do KSeF po przywróceniu systemu. Numeruj faktury z dopiskiem /OFFLINE.", [offline_since])
    ]
} {
    system_ksef := object.get(input.system, "ksef_status", "ONLINE")
    system_ksef == "OFFLINE"
    offline_since := object.get(input.system, "ksef_offline_since", "nieznana data")
}

# ══════ P1853: api_gus_graceful_degradation — GUS BIR offline ══════
else := {
    "matched": true, "rule_id": "jdg.api_fallback.gus_degradation",
    "package": "jdg.api_fallback", "priority": 1853,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "", "vat_exemption": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "api_status": "GUS_DEGRADED", "gus_check_retry": true,
    "vendor_data_source": "INVOICE_ONLY",
    "_routing": "",
    "_routing_reason": "GUS BIR niedostępne — użyto danych z faktury",
    "_legal_basis": "Art. 106e VAT (dane z faktury jako źródło zastępcze)",
    "_warnings": [
        sprintf("GUS BIR API NIEDOSTĘPNE — dane kontrahenta %s (NIP: %s) pobrano z faktury. Weryfikacja w GUS odroczona. Dane z faktury są wiążące do czasu weryfikacji.", [vendor_name, vendor_nip])
    ]
} {
    object.get(input.vendor, "gus_verified", true) == false
    vendor_nip := object.get(input.vendor, "nip", "")
    vendor_nip != ""
    vendor_name := object.get(input.vendor, "name", "N/A")
}

# ══════ P1854: api_nbp_rate_fallback — NBP API offline ══════
else := {
    "matched": true, "rule_id": "jdg.api_fallback.nbp_rate_fallback",
    "package": "jdg.api_fallback", "priority": 1854,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "", "vat_exemption": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "api_status": "NBP_DEGRADED", "nbp_fallback_active": true,
    "fx_rate": cached_rate, "fx_rate_source": "CACHED",
    "fx_rate_date": cached_date,
    "_routing": "",
    "_routing_reason": "NBP API offline — użyto kursu z cache",
    "_legal_basis": "Art. 14 ust. 1c PIT (kursy walut — metoda podatkowa)",
    "_warnings": [
        sprintf("NBP API NIEDOSTĘPNE — użyto kursu %s z cache (data: %s). Kurs może być nieaktualny. Po przywróceniu NBP zweryfikuj transakcję i skoryguj jeśli potrzeba.", [cached_rate, cached_date])
    ]
} {
    input.invoice.currency != "PLN"
    object.get(input.system, "nbp_rate_available", true) == false
    cached_rate := object.get(input.invoice, "nbp_rate_cached", "N/A")
    cached_date := object.get(input.invoice, "nbp_rate_cached_date", "N/A")
    cached_rate != "N/A"
}

# ══════ P1855: api_multi_degradation_escalation — Eskalacja wielu awarii ══════
else := {
    "matched": true, "rule_id": "jdg.api_fallback.multi_degradation",
    "package": "jdg.api_fallback", "priority": 1855,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "", "vat_exemption": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "api_status": "MULTI_DEGRADED", "degraded_apis": degraded_list,
    "degraded_count": degraded_count,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Wielokrotna awaria API (%d systemów offline) — eskalacja", [degraded_count]),
    "_legal_basis": "Procedura operacyjna — ciągłość działania",
    "_warnings": [
        sprintf("KRYTYCZNA AWARIA — %d zewnętrznych API niedostępnych (%s). Transakcja zablokowana do czasu przywrócenia minimum 50%% API. Skontaktuj się z administratorem.", [degraded_count, degraded_list])
    ]
} {
    degraded_count := object.get(input.system, "degraded_api_count", 0)
    degraded_count >= 3
    degraded_list := object.get(input.system, "degraded_api_list", "unknown")
}
