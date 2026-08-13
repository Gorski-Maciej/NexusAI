# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE DIGITAL SIGNATURE AUTO-APPLICATOR (Innovation 8.6, P18 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Enterprise metadata is documented in comments.
# title: JDG Enterprise Digital Signature Auto-Applicator — Automated Signing
# description: |
#   ENTERPRISE v7.0 — Automatyczny aplikator podpisów cyfrowych dla JDG.
#   Wypełnia lukę D6 z raportu P18. Zarządza pełnym cyklem życia podpisów.
#
#   KLUCZOWE FUNKCJE:
#   - Automatyczny wybór typu podpisu (kwalifikowany / profil zaufany / pieczęć KSeF)
#   - Monitorowanie ważności certyfikatów (2 lata) z alertami przed wygaśnięciem
#   - Walidacja podpisu przed wysyłką (pre-flight signature check)
#   - eIDAS cross-border equivalence (kraje EU/EFTA)
#   - Integracja z e-umowami (77^2-78^1 KC)
#   - EN 16931 — zgodność z europejskim standardem e-faktur
#
# architecture: Enterprise v7.0 First-Match-Wins
# legal_basis: Rozporządzenie eIDAS (910/2014); Art. 78^1 KC; EN 16931
# package: jdg.esig_auto
# deprecated: false
# priority_range: 2360-2389
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.esig_auto

import future.keywords.in

esig_selected_type(has_qualified, has_pz, has_ksef_token) = "KWALIFIKOWANY" {
    has_qualified == true
} else = "PROFIL_ZAUFANY" {
    has_qualified == false
    has_pz == true
} else = "TOKEN_KSeF" {
    has_qualified == false
    has_pz == false
    has_ksef_token == true
} else = "BRAK" {
    has_qualified == false
    has_pz == false
    has_ksef_token == false
}

esig_rationale(selected_type) = "Najwyższy poziom bezpieczeństwa — równoważny podpisowi własnoręcznemu." {
    selected_type == "KWALIFIKOWANY"
} else = "Akceptowalny dla ePUAP i większości urzędów." {
    selected_type == "PROFIL_ZAUFANY"
} else = "Wystarczający dla KSeF (faktury ustrukturyzowane)." {
    selected_type == "TOKEN_KSeF"
} else = "BRAK dostępnych metod podpisu — dokument NIE może być podpisany!" {
    selected_type == "BRAK"
}

esig_routing_for(selected_type, doc_importance) = "BLOCK_AND_ALERT" {
    selected_type == "BRAK"
    doc_importance in {"HIGH", "CRITICAL"}
} else = "TRIAGE_QUEUE" {
    selected_type in {"PROFIL_ZAUFANY", "TOKEN_KSeF"}
    doc_importance == "CRITICAL"
} else = "" {
    true
}

esig_reason_for(selected_type, doc_importance) = "BRAK podpisu dla dokumentu krytycznego — uzyskaj podpis kwalifikowany!" {
    selected_type == "BRAK"
    doc_importance in {"HIGH", "CRITICAL"}
} else = "" {
    true
}

cert_status_for(days_left) = "VALID" {
    days_left > 90
} else = "EXPIRING" {
    days_left <= 90
    days_left > 30
} else = "CRITICAL" {
    days_left <= 30
    days_left > 0
} else = "EXPIRED" {
    days_left <= 0
}

cert_renewal_required(status) = true {
    status in {"EXPIRING", "CRITICAL", "EXPIRED"}
} else = false {
    status == "VALID"
}

cert_renewal_deadline(days_left) = "PRZED WYGAŚNIĘCIEM" {
    days_left > 0
} else = "NATYCHMIAST — certyfikat wygasł!" {
    days_left <= 0
}

cert_routing_for(status) = "BLOCK_AND_ALERT" {
    status == "EXPIRED"
} else = "TRIAGE_QUEUE" {
    status in {"EXPIRING", "CRITICAL"}
} else = "" {
    status == "VALID"
}

cert_reason_for(status, days_left, expiry_date) = reason {
    status == "EXPIRED"
    reason := sprintf("CERTYFIKAT WYGASŁ! %s", [cert_renewal_deadline(days_left)])
} else = reason {
    status == "CRITICAL"
    reason := sprintf("Certyfikat wygasa za %d dni — odnow przed %s.", [days_left, expiry_date])
} else = "" {
    status in {"VALID", "EXPIRING"}
}

bool_label(value, positive) = positive {
    value == true
} else = "✗" {
    value == false
}

all_signature_checks_valid(sig_valid, cert_valid, eidas_ok, en16931_ok) {
    sig_valid == true
    cert_valid == true
    eidas_ok == true
    en16931_ok == true
}

eidas_is_eu(country) {
    country in {"AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE", "IS", "LI", "NO", "CH"}
}

eidas_is_equivalent(is_eu, country) {
    is_eu == true
} else {
    is_eu == false
    country in {"US", "UK", "JP", "KR", "CA", "AU"}
}

eidas_on_trusted_list(is_eu, equivalent) {
    is_eu == true
} else {
    equivalent == true
}

eidas_label(value) = "TAK" {
    value == true
} else = "NIE" {
    value == false
}

eidas_routing_for(equivalent, trusted) = "BLOCK_AND_ALERT" {
    equivalent == false
} else = "TRIAGE_QUEUE" {
    trusted == false
    equivalent == true
} else = "" {
    trusted == true
}

eidas_reason_for(equivalent, country) = reason {
    equivalent == false
    reason := sprintf("Kraj %s NIE uznawany w eIDAS — podpis może być odrzucony!", [country])
} else = "" {
    equivalent == true
}

preflight_failure_reason(sig_valid, cert_valid, eidas_ok, en16931_ok) = "podpis niepoprawny" {
    not sig_valid
} else = "certyfikat nieważny" {
    sig_valid
    not cert_valid
} else = "eIDAS niezgodny" {
    sig_valid
    cert_valid
    not eidas_ok
} else = "EN 16931 — zły format" {
    sig_valid
    cert_valid
    eidas_ok
    not en16931_ok
} else = "wszystkie warunki spełnione" {
    all_signature_checks_valid(sig_valid, cert_valid, eidas_ok, en16931_ok)
}

build_cert_warnings(expiry, days, status, _) = warnings {
    status == "EXPIRED"
    warnings := [sprintf("🚨 CERTYFIKAT WYGASŁ dnia %s! Dokumenty NIE mogą być podpisane. Odnów NATYCHMIAST!", [expiry])]
} else = warnings {
    status == "CRITICAL"
    warnings := [sprintf("⚠️ CERTYFIKAT WYGAŚNIE ZA %d DNI (%s)! Zaplanuj odnowienie. Bez ważnego certyfikatu nie podpiszesz dokumentów.", [days, expiry])]
} else = warnings {
    status == "EXPIRING"
    warnings := [sprintf("📅 Certyfikat ważny jeszcze %d dni — zaplanuj odnowienie przed %s.", [days, expiry])]
} else = [sprintf("✅ Certyfikat ważny — %d dni do wygaśnięcia.", [days])]

default decide := {
    "matched": false, "rule_id": "jdg.esig_auto.no_match",
    "package": "jdg.esig_auto", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# ESA-2360: SIGNATURE SELECTOR — Automatyczny wybór typu podpisu
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.esig_auto.signature_selector",
    "package": "jdg.esig_auto",
    "priority": 2360,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "esig_selected_type": selected_type,
    "esig_qualified_available": has_qualified,
    "esig_profile_zaufany_available": has_pz,
    "esig_ksef_token_available": has_ksef_token,
    "esig_selection_rationale": rationale,
    "_routing": sig_routing,
    "_routing_reason": sig_reason,
    "_legal_basis": "eIDAS Art. 25-26; Art. 126 § 5 OrdPU",
    "_warnings": [sprintf("🔏 PODPIS WYBRANY: %s — %s", [selected_type, rationale])],
    "valid_from": "2016-07-01",
    "valid_to": null,
    "decision_mode": "SUGGEST",
} {
    input.esig_select_signature == true
    has_qualified := object.get(input.jdg_entrepreneur, "has_qualified_signature", false)
    has_pz := object.get(input.jdg_entrepreneur, "has_profile_zaufany", false)
    has_ksef_token := object.get(input.jdg_entrepreneur, "has_ksef_token", false)
    doc_importance := object.get(input, "document_importance", "NORMAL")

    # Priorytet: Kwalifikowany > Profil Zaufany > Token KSeF
    selected_type := esig_selected_type(has_qualified, has_pz, has_ksef_token)
    rationale := esig_rationale(selected_type)
    sig_routing := esig_routing_for(selected_type, doc_importance)
    sig_reason := esig_reason_for(selected_type, doc_importance)
}

# ═══════════════════════════════════════════════════════════════════════════════
# ESA-2365: CERTIFICATE MONITOR — Monitorowanie ważności certyfikatów
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.esig_auto.certificate_monitor",
    "package": "jdg.esig_auto",
    "priority": 2365,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "esig_certificate_expiry_date": expiry_date,
    "esig_certificate_days_remaining": days_left,
    "esig_certificate_status": cert_status,
    "esig_certificate_renewal_required": renew_required,
    "esig_certificate_renewal_deadline": renewal_deadline,
    "_routing": cert_routing,
    "_routing_reason": cert_reason,
    "_legal_basis": "eIDAS Art. 28; Ustawa o podpisie elektronicznym",
    "_warnings": build_cert_warnings(expiry_date, days_left, cert_status, renew_required)
} {
    input.esig_certificate_check == true
    expiry_date := object.get(input.jdg_entrepreneur, "signature_cert_expiry", "2028-01-01")
    days_left := object.get(input, "esig_cert_days_remaining", 365)

    cert_status := cert_status_for(days_left)
    renew_required := cert_renewal_required(cert_status)
    renewal_deadline := cert_renewal_deadline(days_left)
    cert_routing := cert_routing_for(cert_status)
    cert_reason := cert_reason_for(cert_status, days_left, expiry_date)
}

# ═══════════════════════════════════════════════════════════════════════════════
# ESA-2370: PRE-FLIGHT SIGNATURE VALIDATION — Walidacja podpisu przed wysyłką
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.esig_auto.preflight_validation",
    "package": "jdg.esig_auto",
    "priority": 2370,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "esig_preflight_document": doc_ref,
    "esig_preflight_signature_valid": sig_valid,
    "esig_preflight_cert_valid": cert_valid,
    "esig_preflight_eidas_compliant": eidas_ok,
    "esig_preflight_en16931_compliant": en16931_ok,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Pre-flight FAILED: %s — dokument %s NIE wysłany.", [failure_reason, doc_ref]),
    "_legal_basis": "eIDAS (910/2014); EN 16931 (e-faktury); Art. 106na VAT",
    "_warnings": [
        sprintf("🔏 PRE-FLIGHT SIGNATURE VALIDATION — %s", [doc_ref]),
        sprintf("   Podpis: %s | Certyfikat: %s | eIDAS: %s | EN16931: %s",
            [[bool_label(sig_valid, "✓"), bool_label(cert_valid, "✓"), bool_label(eidas_ok, "✓"), bool_label(en16931_ok, "✓")]]),
    ]
} {
    input.esig_preflight_check == true
    doc_ref := object.get(input, "document_reference", "")
    sig_valid := object.get(input, "esig_signature_valid", true)
    cert_valid := object.get(input, "esig_certificate_valid", true)
    eidas_ok := object.get(input, "esig_eidas_level", "") in {"QES", "AES"}
    en16931_ok := object.get(input, "document_en16931_syntax", "") in {"UBL", "CII", "UN/CEFACT"}

    all_valid := all_signature_checks_valid(sig_valid, cert_valid, eidas_ok, en16931_ok)
    failure_reason := preflight_failure_reason(sig_valid, cert_valid, eidas_ok, en16931_ok)

    not all_valid
}

# ═══════════════════════════════════════════════════════════════════════════════
# ESA-2375: eIDAS CROSS-BORDER VALIDATOR — Walidacja transgraniczna podpisów
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.esig_auto.eidas_cross_border",
    "package": "jdg.esig_auto",
    "priority": 2375,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "esig_eidas_issuer_country": issuer_country,
    "esig_eidas_is_eu_eea": is_eu,
    "esig_eidas_equivalent": equivalent,
    "esig_eidas_trusted_list": on_trusted_list,
    "_routing": eidas_routing,
    "_routing_reason": eidas_reason,
    "_legal_basis": "eIDAS Art. 6, 25-26 (wzajemne uznawanie); Decyzja 2009/767/WE (EU Trusted Lists)",
    "_warnings": [
        sprintf("🌍 eIDAS CROSS-BORDER — %s", [issuer_country]),
        sprintf("   Kraj UE/EOG: %s | Równoważność: %s", [[eidas_label(is_eu), eidas_label(equivalent)]]),
        sprintf("   Na liście TSL: %s", [[eidas_label(on_trusted_list)]]),
    ]
} {
    input.esig_eidas_check == true
    issuer_country := object.get(input, "esig_issuer_country", "PL")
    is_eu := eidas_is_eu(issuer_country)
    equivalent := eidas_is_equivalent(is_eu, issuer_country)
    on_trusted_list := eidas_on_trusted_list(is_eu, equivalent)
    eidas_routing := eidas_routing_for(equivalent, on_trusted_list)
    eidas_reason := eidas_reason_for(equivalent, issuer_country)
}
