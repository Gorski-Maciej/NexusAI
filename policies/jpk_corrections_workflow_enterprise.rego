# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE JPK_V7 CORRECTIONS WORKFLOW (Innovation 8.14, P18 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Metadata documentation (kept as ordinary comments; no executable annotation).
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
import future.keywords.if
import future.keywords.in

correction_reason_code_value(has_errors, has_gtu_errors, has_counterparty_errors, has_correction_invoice, has_tax_decision) = 1 {
    has_errors
} else = 2 {
    not has_errors
    has_counterparty_errors
} else = 3 {
    not has_errors
    not has_counterparty_errors
    has_gtu_errors
} else = 4 {
    not has_errors
    not has_counterparty_errors
    not has_gtu_errors
    has_correction_invoice
} else = 5 {
    not has_errors
    not has_counterparty_errors
    not has_gtu_errors
    not has_correction_invoice
    has_tax_decision
} else = 0 {
    not has_errors
    not has_counterparty_errors
    not has_gtu_errors
    not has_correction_invoice
    not has_tax_decision
}

correction_needed_value(has_errors, has_gtu_errors, has_counterparty_errors, has_correction_invoice, has_tax_decision) = true {
    has_errors
} else = true {
    not has_errors
    has_gtu_errors
} else = true {
    not has_errors
    not has_gtu_errors
    has_counterparty_errors
} else = true {
    not has_errors
    not has_gtu_errors
    not has_counterparty_errors
    has_correction_invoice
} else = true {
    not has_errors
    not has_gtu_errors
    not has_counterparty_errors
    not has_correction_invoice
    has_tax_decision
} else = false {
    not has_errors
    not has_gtu_errors
    not has_counterparty_errors
    not has_correction_invoice
    not has_tax_decision
}

corr_routing_value(needed) = "TRIAGE_QUEUE" if { needed } else = ""
corr_reason_value(needed, desc, code) = reason if {
    needed
    reason := sprintf("KOREKTA JPK_V7 wymagana — %s (kod %d). Termin: 14 dni.", [desc, code])
} else = ""

autogen_routing_value(vat_diff) = "BLOCK_AND_ALERT" if { vat_diff > 0 } else = "TRIAGE_QUEUE" if { vat_diff != 0 } else = ""
autogen_reason_value(vat_diff) = reason if {
    vat_diff > 0
    reason := sprintf("KOREKTA: VAT do dopłaty %.0f PLN — ureguluj przed wysyłką korekty!", [vat_diff])
} else = ""

chain_valid_value(seq, current_date, previous_date) = current_date >= previous_date if { seq > 1 } else = true
chain_routing_value(valid) = "BLOCK_AND_ALERT" if { not valid } else = ""
chain_reason_value(seq, previous_date, valid) = reason if {
    not valid
    reason := sprintf("ŁAŃCUCH KOREKT: korekta #%d nie może być wcześniejsza niż korekta #%d z %s!", [seq, seq - 1, previous_date])
} else = ""

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

    correction_needed := correction_needed_value(has_errors, has_gtu_errors, has_counterparty_errors, has_correction_invoice, has_tax_decision)

    # Priorytet przyczyn (niższy kod = wyższy priorytet)
    reason_code := correction_reason_code_value(has_errors, has_gtu_errors, has_counterparty_errors, has_correction_invoice, has_tax_decision)

    reason_desc := object.get(correction_reasons, reason_code, "Nieznana przyczyna korekty")
    period := object.get(input, "jpk_correction_period", "")

    corr_routing := corr_routing_value(correction_needed)
    corr_reason := corr_reason_value(correction_needed, reason_desc, reason_code)
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

    autogen_routing := autogen_routing_value(vat_to_pay_diff)
    autogen_reason := autogen_reason_value(vat_to_pay_diff)
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
    chain_valid := chain_valid_value(correction_seq, current_correction_date, previous_correction_date)
    chain_routing := chain_routing_value(chain_valid)
    chain_reason := chain_reason_value(correction_seq, previous_correction_date, chain_valid)
}

build_chain_warnings(seq, valid, prev_ref) = warnings {
    seq == 1
    warnings := ["✅ Korekta #1 — pierwsza korekta deklaracji pierwotnej."]
} else = warnings {
    valid
    warnings := [sprintf("✅ Korekta #%d — poprzednia: %s. Łańcuch korekt spójny.", [seq, prev_ref])]
} else = ["🚫 ŁAŃCUCH KOREKT NIESPÓJNY — chronologia naruszona! Sprawdź daty korekt."]
