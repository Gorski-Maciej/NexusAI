# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE JPK_V7 CORRECTIONS WORKFLOW (Innovation 8.14, P18 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise JPK_V7 Corrections Workflow — Korygowanie deklaracji JPK
# description: |
#   ENTERPRISE v7.0 — Moduł obsługi korekt JPK_V7 (V7M/V7K).
#   Automatyzuje proces korygowania deklaracji JPK_VAT i ewidencji.
#
#   KLUCZOWE FUNKCJE:
#   - Identyfikacja przyczyn korekty (kody 1-5 wg rozporządzenia MF)
#   - Auto-generacja korekty JPK_V7M/V7K
#   - Walidacja chronologii korekt (korekta nie może być wcześniejsza niż pierwotna)
#   - Śledzenie łańcucha korekt (korekta do korekty)
#   - Terminy korekt (w ciągu 14 dni od wykrycia błędu)
#   - Integracja z KSeF dla faktur korygujących
#
# architecture: Enterprise v7.0 First-Match-Wins
# legal_basis: Art. 81 OrdPU; Art. 106j VAT; Rozporządzenie MF JPK_V7
# package: jdg.jpk_corrections
# deprecated: false
# priority_range: 2150-2179
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.jpk_corrections

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.jpk_corrections.no_match",
    "package": "jdg.jpk_corrections", "priority": 9999
}

# Kody przyczyn korekty JPK_V7 (zgodne z rozporządzeniem MF)
correction_reasons := {
    1: "Korekta wynikająca z błędu rachunkowego lub oczywistej omyłki",
    2: "Korekta wynikająca z błędu w danych kontrahenta (NIP, nazwa)",
    3: "Korekta wynikająca z błędnego kodu GTU / procedury / znacznika",
    4: "Korekta wynikająca z uwzględnienia faktury korygującej",
    5: "Korekta wynikająca z decyzji / interpretacji organu podatkowego"
}

# ═══════════════════════════════════════════════════════════════════════════════
# JPC-2150: CORRECTION NEED DETECTION — Wykrywanie potrzeby korekty JPK
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.jpk_corrections.correction_need_detection",
    "package": "jdg.jpk_corrections",
    "priority": 2150,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_correction_needed": correction_needed,
    "jpk_correction_reason_code": reason_code,
    "jpk_correction_reason_desc": reason_desc,
    "jpk_correction_period": period,
    "jpk_correction_deadline_days": 14,
    "_routing": corr_routing,
    "_routing_reason": corr_reason,
    "_legal_basis": "Art. 81 § 1 OrdPU; § 12 rozporządzenia JPK_VAT",
    "_warnings": build_correction_need_warnings(period, reason_code, reason_desc)
} {
    input.jpk_correction_check == true
    has_errors := object.get(input, "jpk_has_discrepancies", false)
    has_gtu_errors := object.get(input, "jpk_gtu_errors_detected", false)
    has_counterparty_errors := object.get(input, "jpk_counterparty_errors", false)
    has_correction_invoice := object.get(input, "jpk_correction_invoice_pending", false)
    has_tax_decision := object.get(input, "jpk_tax_authority_decision", false)

    correction_needed := has_errors or has_gtu_errors or has_counterparty_errors or has_correction_invoice or has_tax_decision

    # Priorytet przyczyn (niższy kod = wyższy priorytet)
    reason_code := 1 { has_errors }
    reason_code := 2 { has_counterparty_errors; not has_errors }
    reason_code := 3 { has_gtu_errors; not has_errors; not has_counterparty_errors }
    reason_code := 4 { has_correction_invoice; not has_errors; not has_counterparty_errors; not has_gtu_errors }
    reason_code := 5 { has_tax_decision; not has_errors; not has_counterparty_errors; not has_gtu_errors; not has_correction_invoice }

    reason_desc := object.get(correction_reasons, reason_code, "Nieznana przyczyna korekty")
    period := object.get(input, "jpk_correction_period", "")

    corr_routing := "TRIAGE_QUEUE" { correction_needed }
    corr_routing := "" { true }
    corr_reason := sprintf("KOREKTA JPK_V7 wymagana — %s (kod %d). Termin: 14 dni.", [reason_desc, reason_code]) { correction_needed }
    corr_reason := "" { true }
}

build_correction_need_warnings(period, code, desc) = warnings {
    warnings := [
        sprintf("📝 KOREKTA JPK_V7 WYMAGANA — okres %s", [period]),
        sprintf("   Przyczyna (kod %d): %s", [code, desc]),
        "   ⏰ Termin: 14 dni od wykrycia błędu (Art. 81 OrdPU)",
        "📋 Wyślij korektę JPK_V7M/V7K z oznaczeniem celu złożenia: 2 (korekta)",
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# JPC-2155: CORRECTION AUTO-GENERATION — Auto-generacja korekty JPK_V7
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.jpk_corrections.correction_autogen",
    "package": "jdg.jpk_corrections",
    "priority": 2155,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_correction_version": jpk_version,
    "jpk_correction_period": period,
    "jpk_correction_purpose": 2,
    "jpk_correction_sales_diff_net": sales_net_diff,
    "jpk_correction_sales_diff_vat": sales_vat_diff,
    "jpk_correction_purchase_diff_net": purchase_net_diff,
    "jpk_correction_purchase_diff_vat": purchase_vat_diff,
    "jpk_correction_vat_diff": vat_to_pay_diff,
    "_routing": autogen_routing,
    "_routing_reason": autogen_reason,
    "_legal_basis": "Art. 81 § 1 OrdPU; Rozporządzenie MF JPK_V7",
    "_warnings": [
        sprintf("🔄 KOREKTA JPK_V7 — okres %s", [period]),
        sprintf("   Sprzedaż netto: %+.0f PLN | VAT: %+.0f PLN", [sales_net_diff, sales_vat_diff]),
        sprintf("   Zakupy netto: %+.0f PLN | VAT: %+.0f PLN", [purchase_net_diff, purchase_vat_diff]),
        sprintf("   Zmiana VAT do zapłaty: %+.0f PLN", [vat_to_pay_diff]),
        "   ⚠️ Cel złożenia: 2 (korekta) — podaj przyczynę złożenia korekty!",
    ]
} {
    input.jpk_correction_generate == true
    period := object.get(input, "jpk_correction_period", "")
    jpk_version := object.get(input, "jpk_version", "JPK_V7M(1)")

    # Różnice między pierwotną deklaracją a stanem po korekcie
    sales_net_original := object.get(input, "jpk_sales_net_original", 0)
    sales_net_corrected := object.get(input, "jpk_sales_net_corrected", 0)
    sales_vat_original := object.get(input, "jpk_sales_vat_original", 0)
    sales_vat_corrected := object.get(input, "jpk_sales_vat_corrected", 0)

    purchase_net_original := object.get(input, "jpk_purchase_net_original", 0)
    purchase_net_corrected := object.get(input, "jpk_purchase_net_corrected", 0)
    purchase_vat_original := object.get(input, "jpk_purchase_vat_original", 0)
    purchase_vat_corrected := object.get(input, "jpk_purchase_vat_corrected", 0)

    sales_net_diff := sales_net_corrected - sales_net_original
    sales_vat_diff := sales_vat_corrected - sales_vat_original
    purchase_net_diff := purchase_net_corrected - purchase_net_original
    purchase_vat_diff := purchase_vat_corrected - purchase_vat_original
    vat_to_pay_diff := sales_vat_diff - purchase_vat_diff

    autogen_routing := "BLOCK_AND_ALERT" { vat_to_pay_diff > 0 }
    autogen_routing := "TRIAGE_QUEUE" { vat_to_pay_diff != 0 }
    autogen_routing := "" { true }
    autogen_reason := sprintf("KOREKTA: VAT do dopłaty %.0f PLN — ureguluj przed wysyłką korekty!", [vat_to_pay_diff]) { vat_to_pay_diff > 0 }
    autogen_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# JPC-2160: CORRECTION CHAIN VALIDATOR — Walidacja łańcucha korekt
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.jpk_corrections.correction_chain_validator",
    "package": "jdg.jpk_corrections",
    "priority": 2160,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_correction_chain_sequence": correction_seq,
    "jpk_correction_chain_valid": chain_valid,
    "jpk_correction_chain_previous": previous_correction_ref,
    "_routing": chain_routing,
    "_routing_reason": chain_reason,
    "_legal_basis": "Art. 81 § 1 OrdPU; Instrukcja wypełniania JPK_V7M",
    "_warnings": build_chain_warnings(correction_seq, chain_valid, previous_correction_ref)
} {
    input.jpk_correction_chain_check == true
    correction_seq := object.get(input, "jpk_correction_sequence_number", 1)
    previous_correction_ref := object.get(input, "jpk_correction_previous_ref", "")
    previous_correction_date := object.get(input, "jpk_correction_previous_date", "")
    current_correction_date := object.get(input, "jpk_correction_current_date", "")

    # Korekta nie może być wcześniejsza niż poprzednia
    chain_valid := current_correction_date >= previous_correction_date { correction_seq > 1 }
    chain_valid := true { correction_seq == 1 }

    chain_routing := "BLOCK_AND_ALERT" { not chain_valid }
    chain_routing := "" { true }
    chain_reason := sprintf("ŁAŃCUCH KOREKT: korekta #%d nie może być wcześniejsza niż korekta #%d z %s!", [correction_seq, correction_seq - 1, previous_correction_date]) { not chain_valid }
    chain_reason := "" { true }
}

build_chain_warnings(seq, valid, prev_ref) = warnings {
    seq == 1
    warnings := ["✅ Korekta #1 — pierwsza korekta deklaracji pierwotnej."]
} else = warnings {
    valid
    warnings := [sprintf("✅ Korekta #%d — poprzednia: %s. Łańcuch korekt spójny.", [seq, prev_ref])]
} else = ["🚫 ŁAŃCUCH KOREKT NIESPÓJNY — chronologia naruszona! Sprawdź daty korekt."]
