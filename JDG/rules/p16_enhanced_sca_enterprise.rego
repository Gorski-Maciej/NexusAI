# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P16 ENHANCED SCA BANKING MODULE (Strategic Initiative BNK-SCA)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: Enhanced PSD2 SCA (Strong Customer Authentication) — Banking Extension
# description: |
#   ENTERPRISE v8.0 — Rozszerzenie bankowosci o pelna implementacje SCA.
#   Wypelnia luke z RAPORT_P16: szczegolowa implementacja SCA (RTS Art. 30-35).
#   - SCA Methods: SMS OTP, Mobile App (biometric), Hardware Token, Push Notification
#   - SCA Exemptions: Low Value (<30 EUR), Trusted Beneficiary, Recurring, Corporate
#   - Transaction Risk Analysis (TRA): amount-based exemption tiers
#   - PSD2 RTS Art. 10: AIS consent every 90 days with SCA
#   - PSD2 RTS Art. 30-35: dynamic linking, transaction monitoring
#   - eIDAS QWAC/QSEAL certificate management for TPP
#   - Fallback mechanisms: bank interface / dedicated interface
# architecture: Enterprise SCA Extension (addon to banking_automation_enterprise.rego)
# legal_basis: PSD2 RTS SCA (EU 2018/389); PolishAPI v3.x; eIDAS (EU 910/2014)
# package: jdg.banking_sca
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.banking_sca

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false, "rule_id": "jdg.banking_sca.no_match",
    "valid_from":"2024-01-01","valid_to":"9999-12-31","temporal_source":"Ustawa z dnia 26 lipca 1991 r. o podatku dochodowym od osob fizycznych"
    "package": "jdg.banking_sca", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# SCA-100: SCA METHOD SELECTION — Wybor metody silnego uwierzytelnienia
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    object.get(input.jdg_entrepreneur, "banking_sca_required", false) == true

    transaction_amount := object.get(input, "transaction_amount_pln", 0)
    is_recurring := object.get(input, "sca_is_recurring", false)
    is_trusted_beneficiary := object.get(input, "sca_is_trusted_beneficiary", false)
    is_corporate := object.get(input, "sca_is_corporate_payment", false)
    is_low_value := transaction_amount <= 30
    is_contactless := object.get(input, "sca_is_contactless", false)
    consecutive_contactless_count := object.get(input, "sca_contactless_count_since_sca", 0)
    cumulative_contactless_amount := object.get(input, "sca_contactless_cumulative_since_sca", 0)

    # ── SCA EXEMPTIONS (RTS Art. 10-18) ──
    sca_exempt_low_value := is_low_value and not is_recurring
    sca_exempt_trusted_beneficiary := is_trusted_beneficiary and transaction_amount <= 500
    sca_exempt_recurring := is_recurring and object.get(input, "sca_previous_sca_performed", true)
    sca_exempt_corporate := is_corporate and object.get(input, "sca_has_dedicated_corporate_process", true)
    sca_exempt_contactless := is_contactless and transaction_amount <= 50 and consecutive_contactless_count <= 5 and cumulative_contactless_amount <= 150

    sca_exempt := sca_exempt_low_value or sca_exempt_trusted_beneficiary or sca_exempt_recurring or sca_exempt_corporate or sca_exempt_contactless

    # ── TRA (Transaction Risk Analysis) exemption ──
    tra_fraud_rate := object.get(input, "sca_bank_fraud_rate_bps", 5)  # basis points
    tra_exemption_amount := 500 { tra_fraud_rate <= 1 }
    tra_exemption_amount := 250 { tra_fraud_rate > 1; tra_fraud_rate <= 6 }
    tra_exemption_amount := 100 { tra_fraud_rate > 6 }
    tra_exempt := transaction_amount <= tra_exemption_amount and not sca_exempt

    # ── SCA METHOD ──
    available_methods := ["SMS_OTP", "MOBILE_APP_BIOMETRIC", "PUSH_NOTIFICATION", "HARDWARE_TOKEN"]
    preferred_method := object.get(input, "sca_preferred_method", "MOBILE_APP_BIOMETRIC")
    fallback_method := "SMS_OTP" { preferred_method != "SMS_OTP" }
    fallback_method := "HARDWARE_TOKEN" { preferred_method == "SMS_OTP" }

    selected_method := preferred_method { not sca_exempt; not tra_exempt }
    selected_method := "NONE (EXEMPT)" { sca_exempt }
    selected_method := "NONE (TRA EXEMPT)" { tra_exempt }

    # SCA method details
    sca_methods_detail := {
        "SMS_OTP": {
            "type": "KNOWLEDGE (something you know)",
            "delivery": "SMS na zarejestrowany numer telefonu",
            "validity_seconds": 300,
            "length": 6,
            "retry_limit": 3,
            "rts_article": "Art. 4-6 RTS SCA"
        },
        "MOBILE_APP_BIOMETRIC": {
            "type": "INHERENCE (something you are)",
            "delivery": "Biometria (odcisk palca / FaceID) w aplikacji bankowej",
            "validity_seconds": 120,
            "retry_limit": 5,
            "rts_article": "Art. 4(30) RTS SCA"
        },
        "PUSH_NOTIFICATION": {
            "type": "POSSESSION (something you have)",
            "delivery": "Push na zarejestrowane urzadzenie mobilne",
            "validity_seconds": 180,
            "retry_limit": 3,
            "rts_article": "Art. 5 RTS SCA"
        },
        "HARDWARE_TOKEN": {
            "type": "POSSESSION (something you have)",
            "delivery": "Token sprzetowy (czytnik kart / generator kodow)",
            "validity_seconds": 60,
            "retry_limit": 3,
            "rts_article": "Art. 7 RTS SCA"
        }
    }

    # Dynamic Linking (RTS Art. 5)
    dynamic_linking_info := sprintf("Transakcja %.2f PLN do %s — kod wiazacy", [transaction_amount, object.get(input, "sca_payee", "")])

    routing := "TRIAGE_QUEUE" { not sca_exempt; transaction_amount > 1000 }
    routing := "" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.banking_sca.method_selection",
        "package": "jdg.banking_sca",
        "priority": 100,
        "action": "SELECT_SCA_METHOD",
        "sca_required": not sca_exempt and not tra_exempt,
        "sca_exempt": sca_exempt,
        "sca_exempt_reason": build_exemption_reason(sca_exempt_low_value, sca_exempt_trusted_beneficiary, sca_exempt_recurring, sca_exempt_corporate, sca_exempt_contactless, tra_exempt),
        "sca_selected_method": selected_method,
        "sca_fallback_method": fallback_method,
        "sca_method_details": object.get(sca_methods_detail, preferred_method, {}),
        "sca_dynamic_linking": dynamic_linking_info,
        "sca_tra_exemption_amount_pln": tra_exemption_amount,
        "sca_available_methods": available_methods,
        "sca_rts_compliant": true,
        "legal_basis": "PSD2 RTS SCA Art. 4-18, 30-35; PolishAPI v3.x; eIDAS Art. 24-31",
        "_routing": routing,
        "_routing_reason": sprintf("SCA: %s — %s", [selected_method, sca_exempt && "ZWOLNIONE" || "WYMAGANE"]),
        "_warnings": build_sca_warnings(selected_method, sca_exempt, transaction_amount, dynamic_linking_info, tra_exemption_amount)
    }
}

build_exemption_reason(low_value, trusted, recurring, corporate, contactless, tra_exempt) = reason {
    reason := "Low Value (<30 EUR)" { low_value }
    reason := "Trusted Beneficiary" { trusted; not low_value }
    reason := "Recurring Payment" { recurring; not trusted; not low_value }
    reason := "Corporate Payment" { corporate; not recurring; not trusted; not low_value }
    reason := "Contactless (<50 EUR × 5)" { contactless; not corporate; not recurring; not trusted; not low_value }
    reason := sprintf("TRA (fraud rate OK, amount ≤ %.0f PLN)", [tra_exemption_amount]) { tra_exempt }
    reason := "" { true }
}

build_sca_warnings(method, exempt, amount, dyn_link, tra_amount) = warnings {
    exempt == true
    warnings := [sprintf("🔐 SCA: ZWOLNIONE — transakcja %.2f PLN nie wymaga silnego uwierzytelnienia.\n   TRA limit: %.0f PLN | Dynamic Linking: %s", [amount, tra_amount, dyn_link])]
} else = warnings {
    warnings := [
        sprintf("🔐 SCA WYMAGANE: Metoda %s dla transakcji %.2f PLN", [method, amount]),
        sprintf("   Dynamic Linking: %s", [dyn_link]),
        sprintf("   Fallback: SMS OTP w razie niedostepnosci"),
        "   RTS Art. 30: SCA dla dostepu do konta przez AIS co 90 dni",
        "   RTS Art. 35: Dynamic Linking dla kazdej transakcji >30 EUR",
        "   ⚠️ eIDAS: Wymagany certyfikat QWAC/QSEAL dla TPP!"
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# SCA-200: AIS CONSENT RENEWAL — Odnowienie zgody AIS co 90 dni
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "banking_ais_consent_check", false) == true

    consent_type := object.get(input, "sca_consent_type", "AIS")
    consent_age_days := object.get(input, "sca_consent_age_days", 0)
    ais_max_days := 90
    pis_max_minutes := 5

    consent_expired := consent_age_days >= ais_max_days { consent_type == "AIS" }
    consent_expired := consent_age_days >= 1 { consent_type == "PIS" }
    consent_expiring_soon := consent_age_days >= 75 and consent_age_days < ais_max_days { consent_type == "AIS" }

    sca_needed := consent_expired or consent_expiring_soon

    sca_renewal_method := "REDIRECT (bank login + approve consent)" { consent_type == "AIS" }
    sca_renewal_method := "EMBEDDED (in-app SCA before payment)" { consent_type == "PIS" }

    routing := "BLOCK_AND_ALERT" { consent_expired }
    routing := "TRIAGE_QUEUE" { consent_expiring_soon }
    routing := "" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.banking_sca.ais_consent_renewal",
        "package": "jdg.banking_sca",
        "priority": 200,
        "action": "RENEW_AIS_CONSENT",
        "sca_consent_type": consent_type,
        "sca_consent_age_days": consent_age_days,
        "sca_consent_max_days": ais_max_days,
        "sca_consent_expired": consent_expired,
        "sca_consent_expiring_soon": consent_expiring_soon,
        "sca_renewal_required": sca_needed,
        "sca_renewal_method": sca_renewal_method,
        "legal_basis": "PSD2 RTS SCA Art. 10, 30-32",
        "_routing": routing,
        "_routing_reason": sprintf("AIS Consent: %d/%d dni — %s", [consent_age_days, ais_max_days, consent_expired && "WYGASLA!" || consent_expiring_soon && "Wkrotce wygasnie" || "OK"]),
        "_warnings": [sprintf("🔄 SCA-200 AIS CONSENT: Zgoda %s ma %d dni (max %d).\n   %s\n   SCA przez: %s\n   ⚠️ RTS Art. 10: SCA obowiazkowe przy pierwszej autoryzacji i co 90 dni!",
            [consent_type, consent_age_days, ais_max_days, consent_expired && "❌ WYGASLA — SCA WYMAGANE!" || consent_expiring_soon && "⚠️ Wygasa za %d dni — zaplanuj SCA!" or "✅ Aktywna", sca_renewal_method])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# SCA-300: eIDAS CERTIFICATE MANAGEMENT — QWAC/QSEAL dla TPP
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "banking_eidas_check", false) == true

    has_qwac := object.get(input, "eidas_has_qwac_certificate", false)
    has_qseal := object.get(input, "eidas_has_qseal_certificate", false)
    qwac_expiry_days := object.get(input, "eidas_qwac_expiry_days", 365)
    qseal_expiry_days := object.get(input, "eidas_qseal_expiry_days", 365)
    tpp_authorization_status := object.get(input, "eidas_tpp_authorization_status", "ACTIVE")
    eidas_qtsp := object.get(input, "eidas_qtsp_name", "KIR / PWPW / Asseco / Certum")

    # Cert requirements
    qwac_required := true
    qseal_required := true
    qwac_valid := has_qwac and qwac_expiry_days > 30
    qwac_expiring := has_qwac and qwac_expiry_days <= 30 and qwac_expiry_days > 0
    qwac_expired := has_qwac and qwac_expiry_days <= 0
    qseal_valid := has_qseal and qseal_expiry_days > 30

    all_ok := has_qwac and has_qseal and tpp_authorization_status == "ACTIVE" and qwac_valid and qseal_valid

    missing_certs := []
    missing_certs := array.concat(missing_certs, ["QWAC (Website Authentication)"]) { not has_qwac }
    missing_certs := array.concat(missing_certs, ["QSEAL (Electronic Seal)"]) { not has_qseal }

    routing_ok := "" { all_ok }
    routing_ok := "BLOCK_AND_ALERT" { not all_ok }
    routing := routing_ok

    verdict := {
        "matched": true,
        "rule_id": "jdg.banking_sca.eidas_certificates",
        "package": "jdg.banking_sca",
        "priority": 300,
        "action": "CHECK_EIDAS_CERTS",
        "eidas_qwac_valid": qwac_valid,
        "eidas_qseal_valid": qseal_valid,
        "eidas_all_certs_ok": all_ok,
        "eidas_missing_certificates": missing_certs,
        "eidas_authorized_qtsp": eidas_qtsp,
        "eidas_tpp_status": tpp_authorization_status,
        "legal_basis": "eIDAS (EU 910/2014); PSD2 Art. 34-35; PolishAPI",
        "_routing": routing,
        "_routing_reason": sprintf("eIDAS: QWAC %s | QSEAL %s | TPP: %s",
            [qwac_valid && "✅" || qwac_expiring && "⚠️WYGASA" || "❌", qseal_valid && "✅" || "❌", tpp_authorization_status]),
        "_warnings": [sprintf("🔏 SCA-300 eIDAS CERTIFICATES:\n   QWAC: %s (wazny %d dni) | QSEAL: %s (wazny %d dni)\n   TPP Status: %s | QTSP: %s\n   %s\n   ⚠️ Bez certyfikatow eIDAS PSD2 API NIE DZIALA!",
            [qwac_valid && "✅" || qwac_expiring && "⚠️ WYGASA" || qwac_expired && "❌ WYGAZL" || "❌ BRAK", qwac_expiry_days, qseal_valid && "✅" || "❌ BRAK", qseal_expiry_days, tpp_authorization_status, eidas_qtsp, count(missing_certs) > 0 && sprintf("Brak: %s", [concat(", ", missing_certs)]) || "✅ Komplet"])]
    }
}
