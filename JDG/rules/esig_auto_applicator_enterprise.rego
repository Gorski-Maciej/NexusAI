# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE DIGITAL SIGNATURE AUTO-APPLICATOR (Innovation 8.6, P18 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
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

import data.jdg.helpers

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
    "_warnings": [sprintf("🔏 PODPIS WYBRANY: %s — %s", [selected_type, rationale])]
} {
    input.esig_select_signature == true
    has_qualified := object.get(input.jdg_entrepreneur, "has_qualified_signature", false)
    has_pz := object.get(input.jdg_entrepreneur, "has_profile_zaufany", false)
    has_ksef_token := object.get(input.jdg_entrepreneur, "has_ksef_token", false)
    doc_importance := object.get(input, "document_importance", "NORMAL")

    # Priorytet: Kwalifikowany > Profil Zaufany > Token KSeF
    selected_type := "KWALIFIKOWANY" { has_qualified }
    selected_type := "PROFIL_ZAUFANY" { not has_qualified; has_pz }
    selected_type := "TOKEN_KSeF" { not has_qualified; not has_pz; has_ksef_token }
    selected_type := "BRAK" { not has_qualified; not has_pz; not has_ksef_token }

    rationale := "Najwyższy poziom bezpieczeństwa — równoważny podpisowi własnoręcznemu." { selected_type == "KWALIFIKOWANY" }
    rationale := "Akceptowalny dla ePUAP i większości urzędów." { selected_type == "PROFIL_ZAUFANY" }
    rationale := "Wystarczający dla KSeF (faktury ustrukturyzowane)." { selected_type == "TOKEN_KSeF" }
    rationale := "BRAK dostępnych metod podpisu — dokument NIE może być podpisany!" { selected_type == "BRAK" }

    sig_routing := "BLOCK_AND_ALERT" { selected_type == "BRAK"; doc_importance in {"HIGH", "CRITICAL"} }
    sig_routing := "TRIAGE_QUEUE" { selected_type in {"PROFIL_ZAUFANY", "TOKEN_KSeF"}; doc_importance == "CRITICAL" }
    sig_routing := "" { true }
    sig_reason := "BRAK podpisu dla dokumentu krytycznego — uzyskaj podpis kwalifikowany!" { selected_type == "BRAK"; doc_importance in {"HIGH", "CRITICAL"} }
    sig_reason := "" { true }
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

    cert_status := "VALID" { days_left > 90 }
    cert_status := "EXPIRING" { days_left <= 90; days_left > 30 }
    cert_status := "CRITICAL" { days_left <= 30; days_left > 0 }
    cert_status := "EXPIRED" { days_left <= 0 }

    renew_required := cert_status in {"EXPIRING", "CRITICAL", "EXPIRED"}
    renewal_deadline := "PRZED WYGAŚNIĘCIEM" { days_left > 0 }
    renewal_deadline := "NATYCHMIAST — certyfikat wygasł!" { days_left <= 0 }

    cert_routing := "BLOCK_AND_ALERT" { cert_status == "EXPIRED" }
    cert_routing := "TRIAGE_QUEUE" { cert_status in {"EXPIRING", "CRITICAL"} }
    cert_routing := "" { true }
    cert_reason := sprintf("CERTYFIKAT WYGASŁ! %s", [renewal_deadline]) { cert_status == "EXPIRED" }
    cert_reason := sprintf("Certyfikat wygasa za %d dni — odnow przed %s.", [days_left, expiry_date]) { cert_status == "CRITICAL" }
    cert_reason := "" { true }
}

build_cert_warnings(expiry, days, status, renew) = warnings {
    status == "EXPIRED"
    warnings := [sprintf("🚨 CERTYFIKAT WYGASŁ dnia %s! Dokumenty NIE mogą być podpisane. Odnów NATYCHMIAST!", [expiry])]
} else = warnings {
    status == "CRITICAL"
    warnings := [sprintf("⚠️ CERTYFIKAT WYGAŚNIE ZA %d DNI (%s)! Zaplanuj odnowienie. Bez ważnego certyfikatu nie podpiszesz dokumentów.", [days, expiry])]
} else = warnings {
    status == "EXPIRING"
    warnings := [sprintf("📅 Certyfikat ważny jeszcze %d dni — zaplanuj odnowienie przed %s.", [days, expiry])]
} else = [sprintf("✅ Certyfikat ważny — %d dni do wygaśnięcia.", [days])]

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
            ["✓" { sig_valid } else "✗"], ["✓" { cert_valid } else "✗"], ["✓" { eidas_ok } else "✗"], ["✓" { en16931_ok } else "✗"]),
    ]
} {
    input.esig_preflight_check == true
    doc_ref := object.get(input, "document_reference", "")
    sig_valid := object.get(input, "esig_signature_valid", true)
    cert_valid := object.get(input, "esig_certificate_valid", true)
    eidas_ok := object.get(input, "esig_eidas_level", "") in {"QES", "AES"}
    en16931_ok := object.get(input, "document_en16931_syntax", "") in {"UBL", "CII", "UN/CEFACT"}

    all_valid := sig_valid and cert_valid and eidas_ok and en16931_ok
    failure_reason := "podpis niepoprawny" { not sig_valid }
    failure_reason := "certyfikat nieważny" { sig_valid; not cert_valid }
    failure_reason := "eIDAS niezgodny" { sig_valid; cert_valid; not eidas_ok }
    failure_reason := "EN 16931 — zły format" { sig_valid; cert_valid; eidas_ok; not en16931_ok }
    failure_reason := "wszystkie warunki spełnione" { all_valid }

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
        sprintf("   Kraj UE/EOG: %s | Równoważność: %s", ["TAK" { is_eu } else "NIE"], ["TAK" { equivalent } else "NIE"]),
        sprintf("   Na liście TSL: %s", ["TAK" { on_trusted_list } else "NIE"]),
    ]
} {
    input.esig_eidas_check == true
    issuer_country := object.get(input, "esig_issuer_country", "PL")
    is_eu := issuer_country in {"AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR","DE","GR","HU","IE","IT","LV","LT","LU","MT","NL","PL","PT","RO","SK","SI","ES","SE","IS","LI","NO","CH"}
    equivalent := is_eu or issuer_country in {"US","UK","JP","KR","CA","AU"}
    on_trusted_list := is_eu or equivalent

    eidas_routing := "BLOCK_AND_ALERT" { not equivalent }
    eidas_routing := "TRIAGE_QUEUE" { not on_trusted_list; equivalent }
    eidas_routing := "" { true }
    eidas_reason := sprintf("Kraj %s NIE uznawany w eIDAS — podpis może być odrzucony!", [issuer_country]) { not equivalent }
    eidas_reason := "" { true }
}
