# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — VAT DEDUCTIONS & CORRECTIONS AUDIT (P03 VAT Macro — Sekcja 3)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.vat_deductions_audit
# Raport: RAPORT_ANALITYCZNY_ENTERPRISE_JDG_VAT_MACRO (P03) v8.0 — Sekcja 3
#
# AUDYT ODLICZEŃ (art. 86-95) I KOREKT (poziom ENTERPRISE):
#   DC-01 Ogólna zasada odliczenia (art. 86 ust. 1) — związek z czynnościami
#        opodatkowanymi + posiadanie faktury/dokumentu celnego.
#   DC-02 Odliczenia BLOKOWANE (art. 88) — NKUP-owe wydatki: paliwo do aut
#        osobowych (art. 88a), usługi noclegowe/gastronomiczne (art. 88 ust. 1
#        pkt 4), towary/usługi bez dokumentu, inne.
#   DC-03 Proporcja (art. 90) — pre-proporcja (art. 90 ust. 10) i korekta
#        roczna (art. 91 ust. 1-4): współczynnik wstępny vs ostateczny.
#   DC-04 Pre-proporcja nowego podatnika (art. 90 ust. 8-9) — szacunek wg
#        planowanych obrotów, korekta wstępna po zakończeniu roku.
#   DC-05 Korekta wieloletnia środków trwałych (art. 91 ust. 2-7) — 5/10 lat.
#   DC-06 Złe długi: wierzyciel (art. 89a) i dłużnik (art. 89b) — SLIM VAT 3:
#        90 dni, powiadomienie, korekta in minus/in plus.
#   DC-07 Sankcje odliczeń — odliczenie bez prawa (art. 88) → korekta
#        deklaracji + odsetki; sygnał do BLOCK_AND_ALERT.
#
# Zgodność: art. 86-95 VAT (SLIM VAT 3), P03 Sekcja 3, ADR-002 (progi).
# package: jdg.vat_deductions_audit
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.vat_deductions_audit

import data.jdg.thresholds
import future.keywords.if
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.vat_deductions_audit.no_match","package":"jdg.vat_deductions_audit","priority":999999}

# ── DC-02: ODLICZENIA BLOKOWANE (art. 88) ────────────────────────────────────
# Wydatki, od których VAT naliczony NIE podlega odliczeniu — niezależnie od
# posiadania faktury. BLOCK_AND_ALERT przy próbie odliczenia.
blocked_deduction_reasons := [reason |
    input.invoice.direction == "PURCHASE"
    object.get(input.invoice, "vat_deducted", false) == true
    reason := blocked_reason
    blocked_reason != ""
] else := [] {
    true
}

blocked_reason := "ACCOMMODATION_GASTRONOMY" {
    input.invoice.category_code in {"HOTEL", "RESTAURANT_CATERING"}
    object.get(input.invoice, "business_necessity_proven", false) == false
} else := "FUEL_PASSENGER_CAR" {
    input.invoice.category_code == "FUEL"
    object.get(input.invoice, "car_type", "") == "PASSENGER"
    object.get(input.invoice, "car_registered_for_business", false) == false
} else := "EXPENSE_WITHOUT_DOCUMENT" {
    object.get(input.invoice, "has_valid_invoice", false) == false
    object.get(input.invoice, "is_customs_document", false) == false
} else := "NON_DEDUCTIBLE_NATURE" {
    object.get(input.invoice, "category_code", "") in {"FINES", "PERSONAL_CONSUMPTION", "REPRESENTATION"}
} else := "" {
    true
}

deduction_blocked := {
    "matched": true,
    "rule_id": "jdg.vat_deductions_audit.deduction_blocked",
    "package": "jdg.vat_deductions_audit",
    "priority": 100,
    "blocked_reasons": blocked_deduction_reasons,
    "blocked_count": count(blocked_deduction_reasons),
    "vat_deducted": object.get(input.invoice, "vat_deducted", false),
    "amount_vat_blocked": object.get(input.invoice, "vat_amount", 0),
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Próba odliczenia VAT naliczonego z wydatków objętych zakazem (art. 88 VAT)",
    "_legal_basis": "Art. 88 ust. 1 pkt 2, 4 VAT + art. 88a VAT",
    "_warnings": [sprintf("ODLICZENIE BLOKOWANE (art. 88): powody: %v. VAT %v PLN nie podlega odliczeniu — korekta deklaracji wymagana jeśli już odliczono.", [blocked_deduction_reasons, object.get(input.invoice, "vat_amount", 0)])]
} {
    object.get(input.jdg_entrepreneur, "vat_deductions_check", false) == true
    count(blocked_deduction_reasons) > 0
}

# ── DC-03/DC-04: PROPORCJA I PRE-PROPORCJA (art. 90) ─────────────────────────
# Współczynnik = obrót opodatkowany / obrót ogółem. Pre-proporcja dla nowego
# podatnika (art. 90 ust. 8-10) wg planowanych obrotów; po roku — korekta.
proportional_deduction_factor := factor {
    turnover_taxable := object.get(input.jdg_entrepreneur, "turnover_taxable_annual", 0)
    turnover_total := object.get(input.jdg_entrepreneur, "turnover_total_annual", 0)
    turnover_total > 0
    raw := turnover_taxable / turnover_total
    factor := round(raw * 1000) / 1000
} else := 1.0 {
    true
}

# Kierunek korekty rocznej: wyższy współczynnik ostateczny → IN_PLUS.
adjustment_direction := "IN_PLUS" {
    proportional_deduction_factor > object.get(input.jdg_entrepreneur, "initial_deduction_factor", 1.0)
} else := "IN_MINUS" {
    proportional_deduction_factor < object.get(input.jdg_entrepreneur, "initial_deduction_factor", 1.0)
} else := "NONE" {
    true
}

preproportion_report := {
    "matched": true,
    "rule_id": "jdg.vat_deductions_audit.preproportion",
    "_legal_basis": "Art. 88 ust. 1 pkt 2, 4 VAT + art. 88a VAT",
    "package": "jdg.vat_deductions_audit",
    "priority": 200,
    "preproportion": {
        "planned_taxable": object.get(input.jdg_entrepreneur, "planned_turnover_taxable", 0),
        "planned_total": object.get(input.jdg_entrepreneur, "planned_turnover_total", 0),
        "initial_factor": object.get(input.jdg_entrepreneur, "initial_deduction_factor", 1.0),
        "final_factor": proportional_deduction_factor,
        "annual_adjustment_needed": object.get(input.jdg_entrepreneur, "initial_deduction_factor", 1.0) != proportional_deduction_factor,
        "adjustment_direction": adjustment_direction
    },
    "_routing": "REPORT",
    "_routing_reason": "Pre-proporcja i korekta roczna współczynnika odliczenia (art. 90-91 VAT)",
    "_legal_basis": "Art. 90 ust. 8-10 + Art. 91 ust. 1-4 VAT",
    "_warnings": [sprintf("Pre-proporcja: wstępny %v, ostateczny %v. Korekta roczna: %s.", [object.get(input.jdg_entrepreneur, "initial_deduction_factor", 1.0), proportional_deduction_factor, adjustment_direction])]
} {
    object.get(input.jdg_entrepreneur, "vat_deductions_check", false) == true
}

# ── DC-05: KOREKTA WIELOLETNIA ŚRODKÓW TRWAŁYCH (art. 91 ust. 2-7) ──────────
# Środki trwałe < 15 000 PLN → jednorazowa korekta; ≥ 15 000 PLN → korekta
# przez 5 lat (nieruchomości 10 lat). Zmiana przeznaczenia → korekta wstecz.
correction_period_years := 10 {
    object.get(input.invoice, "asset_type", "") == "REAL_ESTATE"
} else := 5 {
    object.get(input.invoice, "amount_net", 0) >= thresholds.vat.asset_correction_threshold
} else := 1 {
    true
}

multi_year_correction := {
    "matched": true,
    "rule_id": "jdg.vat_deductions_audit.multi_year_correction",
    "_legal_basis": "Art. 88 ust. 1 pkt 2, 4 VAT + art. 88a VAT",
    "package": "jdg.vat_deductions_audit",
    "priority": 300,
    "correction": {
        "asset_value": object.get(input.invoice, "amount_net", 0),
        "correction_period_years": correction_period_years,
        "purchase_year": object.get(input.invoice, "purchase_year", ""),
        "deducted_in_purchase_year": object.get(input.invoice, "vat_deducted", false),
        "use_changed": object.get(input.invoice, "asset_use_changed", false),
        "adjustment_required": object.get(input.invoice, "asset_use_changed", false)
    },
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Środek trwały — korekta wieloletnia odliczenia (art. 91 ust. 2-7) — wymaga weryfikacji zmiany przeznaczenia",
    "_legal_basis": "Art. 91 ust. 2-7 VAT",
    "_warnings": ["Korekta wieloletnia: zmiana przeznaczenia środka trwałego wymaga korekty odliczenia w JPK_V7 — sprawdź lata korekty (5/10)."]
} {
    object.get(input.jdg_entrepreneur, "vat_deductions_check", false) == true
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# ── DC-06: ZŁE DŁUGI — WIERZYCIEL I DŁUŻNIK (art. 89a/89b) ──────────────────
# SLIM VAT 3 (od 2023-01-01): wierzyciel koryguje po 90 dniach (art. 89a),
# dłużnik koryguje po powiadomieniu (art. 89b). Obie strony — synchronizacja.
bad_debt_creditor_correction := {
    "matched": true,
    "rule_id": "jdg.vat_deductions_audit.bad_debt_creditor",
    "_legal_basis": "Art. 88 ust. 1 pkt 2, 4 VAT + art. 88a VAT",
    "package": "jdg.vat_deductions_audit",
    "priority": 400,
    "bad_debt": {
        "side": "CREDITOR",
        "days_overdue": object.get(input.invoice, "days_overdue", 0),
        "threshold_days": 90,
        "debtor_notified": object.get(input.invoice, "debtor_notified", false),
        "eligible": object.get(input.invoice, "days_overdue", 0) >= 90 and object.get(input.invoice, "debtor_notified", false) == true,
        "correction_direction": "IN_MINUS"
    },
    "_routing": "REPORT",
    "_routing_reason": "Zły dług wierzyciela — korekta in minus po 90 dniach (SLIM VAT 3)",
    "_legal_basis": "Art. 89a ust. 1, 1a VAT (SLIM VAT 3)",
    "_warnings": ["Ulga na złe długi: korekta in minus w JPK_V7 po 90 dniach + powiadomienie dłużnika. Uwaga na limit 5 lat od wystawienia faktury."]
} {
    object.get(input.jdg_entrepreneur, "vat_bad_debt_check", false) == true
    input.invoice.direction == "SALE"
    object.get(input.invoice, "is_paid", false) == false
}

bad_debt_debtor_correction := {
    "matched": true,
    "rule_id": "jdg.vat_deductions_audit.bad_debt_debtor",
    "_legal_basis": "Art. 88 ust. 1 pkt 2, 4 VAT + art. 88a VAT",
    "package": "jdg.vat_deductions_audit",
    "priority": 410,
    "bad_debt": {
        "side": "DEBTOR",
        "creditor_notified": object.get(input.invoice, "creditor_notified", false),
        "eligible": object.get(input.invoice, "creditor_notified", false) == true,
        "correction_direction": "IN_PLUS",
        "note": "Dłużnik koryguje odliczenie in plus po otrzymaniu zawiadomienia od wierzyciela"
    },
    "_routing": "REPORT",
    "_routing_reason": "Zły dług dłużnika — korekta in plus po zawiadomieniu (art. 89b VAT)",
    "_legal_basis": "Art. 89b ust. 1 VAT",
    "_warnings": ["Korekta dłużnika: po zawiadomieniu od wierzyciela o korekcie (art. 89b) — korekta in plus odliczenia VAT."]
} {
    object.get(input.jdg_entrepreneur, "vat_bad_debt_check", false) == true
    input.invoice.direction == "PURCHASE"
    object.get(input.invoice, "is_paid", false) == false
}

# ── DC-07: SANKCJA — ODLICZENIE BEZ PRAWA (art. 88 + 108) ───────────────────
# Odliczenie VAT z wydatków blokowanych / bez dokumentu = zaniżenie zobowiązania.
deduction_sanction := {
    "matched": true,
    "rule_id": "jdg.vat_deductions_audit.deduction_sanction",
    "_legal_basis": "Art. 88 ust. 1 pkt 2, 4 VAT + art. 88a VAT",
    "package": "jdg.vat_deductions_audit",
    "priority": 500,
    "sanction": {
        "vat_improperly_deducted": object.get(input.invoice, "vat_amount", 0),
        "interest_note": "Odsetki od zaległości podatkowej od dnia złożenia deklaracji",
        "action": "KOREKTA_DEKLARACJI + czynny żal (jeśli nie wszczęto postępowania)"
    },
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Odliczenie VAT bez prawa (art. 88) — ryzyko zaniżenia zobowiązania + odsetki",
    "_legal_basis": "Art. 88, 108 VAT + Ordynacja podatkowa",
    "_warnings": ["Odliczono VAT z wydatku blokowanego. Konieczna korekta deklaracji i zapłata odsetek — rozważ czynny żal."]
} {
    object.get(input.jdg_entrepreneur, "vat_deductions_check", false) == true
    input.invoice.direction == "PURCHASE"
    object.get(input.invoice, "vat_deducted", false) == true
    count(blocked_deduction_reasons) > 0
}

# ── DECYZJA: RAPORT AUDYTU ODLICZEŃ ──────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "jdg.vat_deductions_audit.report",
    "_legal_basis": "Art. 88 ust. 1 pkt 2, 4 VAT + art. 88a VAT",
    "package": "jdg.vat_deductions_audit",
    "priority": 600,
    "deductions_audit": {
        "blocked_reasons": blocked_deduction_reasons,
        "blocked_count": count(blocked_deduction_reasons),
        "proportional_factor": proportional_deduction_factor,
        "preproportion": {
            "initial": object.get(input.jdg_entrepreneur, "initial_deduction_factor", 1.0),
            "final": proportional_deduction_factor,
            "adjustment_needed": object.get(input.jdg_entrepreneur, "initial_deduction_factor", 1.0) != proportional_deduction_factor
        },
        "multi_year_asset": object.get(input.invoice, "is_fixed_asset", false),
        "bad_debt_sides": [side | side := s; some s in ["CREDITOR", "DEBTOR"]]
    },
    "_routing": "REPORT",
    "_routing_reason": "Raport audytu odliczeń i korekt VAT (Sekcja 3 P03) — proporcja, korekty, złe długi",
    "_legal_basis": "Art. 86-95 VAT + P03 Sekcja 3",
    "_warnings": [sprintf("Blokady odliczeń: %d | Współczynnik proporcji: %v | Korekta wieloletnia: %v", [count(blocked_deduction_reasons), proportional_deduction_factor, object.get(input.invoice, "is_fixed_asset", false)])]
} {
    object.get(input.jdg_entrepreneur, "vat_deductions_check", false) == true
}
