# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — OrdPU+UoR+PCC+Akcyza Innovations v8.0 (P33 Report)
# ═══════════════════════════════════════════════════════════════════════════════
# Generated: 2026-07-29 — RAPORT_P33_LEGAL_AUDIT_ORDPU_UOR_PCC_AKCYZA_v7.0
# Implements: OrdPU gaps + UoR foundation + PCC complete + Akcyza + 12 innovations
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.ord.innovations

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false,
    "rule_id": "jdg.ord.innovations.no_match",
    "package": "jdg.ord.innovations",
    "priority": 999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  PART 1: OrdPU GAP FIXES (98% → 99%+)                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# P800: GAAR Shield + Artificial Scheme Detector (Art. 119a OrdPU)
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.ord.innovations.gaar_shield",
    "package": "jdg.ord.innovations", "priority": 800,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ord_gaar_risk": gaar_risk,
    "ord_gaar_artificiality_score": artificiality_score,
    "ord_gaar_economic_substance": economic_substance,
    "ord_gaar_action": gaar_action,
    "valid_from": "2019-01-01", "valid_to": null,
    "_routing": gaar_rt,
    "_routing_reason": sprintf("GAAR Shield: ryzyko=%s, sztuczność=%.0f%%, substancja ekonomiczna=%s", [gaar_risk, artificiality_score, economic_substance]),
    "_legal_basis": "Art. 119a OrdPU (GAAR — klauzula przeciwko unikaniu opodatkowania)",
    "_warnings": [sprintf("GAAR SHIELD — Ryzyko GAAR: %s (sztuczność %.0f%%). Substancja ekonomiczna: %s. %s", [gaar_risk, artificiality_score, economic_substance, gaar_action])]
} {
    # Detect MPP splitting (Art. 108a VAT + Art. 119a OrdPU)
    total_invoice_value := object.get(input.jdg_entrepreneur, "grouped_invoice_total", 0)
    invoice_count := object.get(input.jdg_entrepreneur, "grouped_invoice_count", 1)
    mpp_threshold := object.get(object.get(data.thresholds, "vat", {}), "mpp_threshold", 15000)
    avg_per_invoice := total_invoice_value / invoice_count

    # Detect MPP splitting — inverted logic fixed: true only when split suspected
    mpp_split_suspected { total_invoice_value > mpp_threshold; avg_per_invoice <= mpp_threshold; invoice_count > 1 }

    # Detect PCC loan splitting
    loan_total := object.get(input.jdg_entrepreneur, "family_loans_total", 0)
    loan_count_family := object.get(input.jdg_entrepreneur, "family_loans_count", 1)
    pcc_exempt_per_loan := object.get(object.get(data.thresholds, "pcc", {}), "loan_exemption", 36120)
    avg_per_loan := loan_total / loan_count_family

    pcc_split_suspected { loan_total > pcc_exempt_per_loan; avg_per_loan <= pcc_exempt_per_loan; loan_count_family > 1 }

    # Economic Substance Test
    has_business_purpose := object.get(input.jdg_entrepreneur, "has_business_purpose", true)
    has_economic_rationale := object.get(input.jdg_entrepreneur, "has_economic_rationale", true)
    transaction_chain_depth := object.get(input.jdg_entrepreneur, "transaction_chain_depth", 1)

    substance_failed := has_business_purpose == false
    substance_weak := transaction_chain_depth > 2

    # Calculate scores — single expression with conditional addition (no partial rule conflict)
    artificiality_score := 0 { mpp_split_suspected == false; pcc_split_suspected == false; substance_failed == false; substance_weak == false }
    artificiality_score := 25 { mpp_split_suspected == true; pcc_split_suspected == false; substance_failed == false; substance_weak == false }
    artificiality_score := 50 { mpp_split_suspected == true; pcc_split_suspected == true; substance_failed == false; substance_weak == false }
    artificiality_score := 55 { mpp_split_suspected == true; pcc_split_suspected == false; substance_failed == false; substance_weak == true }
    artificiality_score := 80 { mpp_split_suspected == true; pcc_split_suspected == true; substance_failed == false; substance_weak == true }
    artificiality_score := 30 { mpp_split_suspected == false; pcc_split_suspected == false; substance_failed == true; substance_weak == false }
    artificiality_score := 20 { mpp_split_suspected == false; pcc_split_suspected == false; substance_failed == false; substance_weak == true }
    artificiality_score := 50 { mpp_split_suspected == false; pcc_split_suspected == false; substance_failed == true; substance_weak == true }
    artificiality_score := 25 { mpp_split_suspected == false; pcc_split_suspected == true; substance_failed == false; substance_weak == false }
    artificiality_score := 50 { mpp_split_suspected == false; pcc_split_suspected == true; substance_failed == false; substance_weak == true }
    artificiality_score := 55 { mpp_split_suspected == false; pcc_split_suspected == true; substance_failed == true; substance_weak == false }
    artificiality_score := 75 { mpp_split_suspected == false; pcc_split_suspected == true; substance_failed == true; substance_weak == true }
    artificiality_score := 75 { mpp_split_suspected == true; pcc_split_suspected == false; substance_failed == true; substance_weak == false }
    artificiality_score := 95 { mpp_split_suspected == true; pcc_split_suspected == false; substance_failed == true; substance_weak == true }
    artificiality_score := 75 { mpp_split_suspected == true; pcc_split_suspected == true; substance_failed == true; substance_weak == false }
    artificiality_score := 100 { mpp_split_suspected == true; pcc_split_suspected == true; substance_failed == true; substance_weak == true }

    gaar_risk = "KRYTYCZNE" { artificiality_score >= 50 }
    gaar_risk = "WYSOKIE" { artificiality_score >= 30; artificiality_score < 50 }
    gaar_risk = "ŚREDNIE" { artificiality_score >= 10; artificiality_score < 30 }
    gaar_risk = "NISKIE" { artificiality_score < 10 }

    economic_substance = "BRAK" { substance_failed == true }
    economic_substance = "SŁABA" { substance_failed == false; substance_weak == true }
    economic_substance = "ADEKWATNA" { substance_failed == false; substance_weak == false }

    gaar_action = "NATYCHMIASTOWA KOREKTA — połącz faktury w jedną + zapłać MPP!" { mpp_split_suspected == true; artificiality_score >= 50 }
    gaar_action = "Zgłoś czynny żal + skonsultuj z doradcą podatkowym." { artificiality_score >= 30; artificiality_score < 50 }
    gaar_action = "Monitoruj — ryzyko GAAR jest podwyższone." { artificiality_score >= 10; artificiality_score < 30 }
    gaar_action = "Brak oznak sztuczności." { artificiality_score < 10 }

    gaar_rt = "BLOCK_AND_ALERT" { artificiality_score >= 50 }
    gaar_rt = "TRIAGE_QUEUE" { artificiality_score >= 30; artificiality_score < 50 }
    gaar_rt = "" { artificiality_score < 30 }

    # Gate condition
    artificiality_score >= 10
}

# ═══════════════════════════════════════════════════════════════════════════════
# P801: Ulgi w spłacie — Scoring & Automatyzacja (Art. 67a-67e OrdPU)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.ord.innovations.relief_scoring",
    "package": "jdg.ord.innovations", "priority": 801,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ord_relief_score": relief_score,
    "ord_relief_eligibility": eligibility,
    "ord_relief_recommended_type": relief_type,
    "ord_relief_installments": installments,
    "ord_relief_monthly_payment": monthly_payment,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": relief_rt,
    "_routing_reason": sprintf("Ulga w spłacie: scoring=%.0f%%, %s — %s", [relief_score, eligibility, relief_type]),
    "_legal_basis": "Art. 67a-67e OrdPU (ulgi w spłacie zobowiązań podatkowych)",
    "_warnings": [sprintf("ULGI W SPŁACIE — Scoring: %.0f%%. Status: %s. Rekomendacja: %s. Raty: %d × %.2f PLN. %s", [relief_score, eligibility, relief_type, installments, monthly_payment, relief_note])]
} {
    zaleglosc := object.get(input.jdg_entrepreneur, "tax_arrears_pln", 0)
    zaleglosc > 0

    income_monthly := object.get(input.jdg_entrepreneur, "monthly_income_net", 5000)
    has_important_interest := object.get(input.jdg_entrepreneur, "important_tax_interest", false)
    health_issue := object.get(input.jdg_entrepreneur, "health_crisis_affecting_business", false)
    force_majeure := object.get(input.jdg_entrepreneur, "force_majeure_event", false)
    prior_reliefs := object.get(input.jdg_entrepreneur, "prior_reliefs_count_5y", 0)

    # Scoring: max 100 — fully conditional, no unconditional+conditional conflict
    score_zaleglosc = 30 { zaleglosc < 10000 }
    score_zaleglosc = 15 { zaleglosc >= 10000; zaleglosc < 50000 }
    score_zaleglosc = 0 { zaleglosc >= 50000 }

    score_income = 20 { income_monthly > 3000 }
    score_income = 0 { income_monthly <= 3000 }

    score_interest = 20 { has_important_interest == true }
    score_interest = 0 { has_important_interest == false }

    score_health = 15 { health_issue == true }
    score_health = 0 { health_issue == false }

    score_majeure = 10 { force_majeure == true }
    score_majeure = 0 { force_majeure == false }

    penalty = 20 { prior_reliefs >= 2; prior_reliefs < 4 }
    penalty = 30 { prior_reliefs >= 4 }
    penalty = 0 { prior_reliefs < 2 }

    relief_score_ := score_zaleglosc + score_income + score_interest + score_health + score_majeure - penalty
    relief_score := max([relief_score_, 0])

    eligibility = "WYSOKA SZANSA" { relief_score >= 70 }
    eligibility = "ŚREDNIA SZANSA" { relief_score >= 40; relief_score < 70 }
    eligibility = "NISKA SZANSA" { relief_score < 40 }

    relief_type = "UMORZENIE (ważny interes)" { has_important_interest == true; relief_score >= 70 }
    relief_type = "ROZŁOŻENIE NA RATY" { has_important_interest == false; relief_score >= 40 }
    relief_type = "ODROCZENIE TERMINU" { has_important_interest == false; relief_score < 40 }

    installments = 4 { zaleglosc < 5000; relief_score >= 60 }
    installments = 8 { zaleglosc >= 5000; zaleglosc < 20000; relief_score >= 50 }
    installments = 12 { zaleglosc >= 20000; relief_score >= 40 }
    installments = 6 { relief_score < 40 }

    monthly_payment := floor(zaleglosc / installments * 100) / 100

    relief_note = "Złóż wniosek o umorzenie (ważny interes podatkowy)." { relief_score >= 70 }
    relief_note = sprintf("Złóż wniosek o rozłożenie na %d rat × %.2f PLN.", [installments, monthly_payment]) { relief_score >= 40; relief_score < 70 }
    relief_note = "Złóż wniosek o odroczenie terminu płatności." { relief_score < 40 }

    relief_rt = "TRIAGE_QUEUE" { relief_score >= 40 }
    relief_rt = "" { relief_score < 40 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P802: Odwołania — Liczniki terminów (Art. 138a-138o OrdPU)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.ord.innovations.appeal_deadline_tracker",
    "package": "jdg.ord.innovations", "priority": 802,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ord_appeal_days_remaining": days_remaining,
    "ord_appeal_type": appeal_type,
    "ord_appeal_deadline": deadline_date,
    "ord_appeal_overdue": is_overdue,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": appeal_rt,
    "_routing_reason": sprintf("Odwołanie: %s — %d dni do terminu", [appeal_type, days_remaining]),
    "_legal_basis": "Art. 138a-138o OrdPU (odwołania i zażalenia)",
    "_warnings": [sprintf("TERMIN ODWOŁAWCZY — %s: pozostało %d dni (do %s). %s", [appeal_type, days_remaining, deadline_date, appeal_action])]
} {
    decision_date := object.get(input.jdg_entrepreneur, "tax_decision_date", "")
    decision_date != ""
    decision_type := object.get(input.jdg_entrepreneur, "tax_decision_type", "DECYZJA")

    today_str := object.get(input.jdg_entrepreneur, "current_date", "2026-07-29")

    # Parse dates
    decision_ns := time.parse_ns("2006-01-02", decision_date)
    today_ns := time.parse_ns("2006-01-02", today_str)

    # Deadlines: 14 dni for odwołanie, 7 dni for zażalenie
    deadline_days = 14 { decision_type == "DECYZJA" }
    deadline_days = 7 { decision_type == "POSTANOWIENIE" }
    deadline_days = 30 { decision_type == "INTERPRETACJA" }

    decision_seconds := time.diff(decision_ns, today_ns)
    days_elapsed := floor(decision_seconds / 86400)

    days_remaining := deadline_days - days_elapsed
    is_overdue := days_remaining < 0

    appeal_type = "Odwołanie od DECYZJI (14 dni)" { decision_type == "DECYZJA" }
    appeal_type = "Zażalenie na POSTANOWIENIE (7 dni)" { decision_type == "POSTANOWIENIE" }
    appeal_type = "Skarga na INTERPRETACJĘ (30 dni)" { decision_type == "INTERPRETACJA" }

    # Calculate deadline date
    deadline_ns := time.add_date(decision_ns, 0, 0, deadline_days)
    deadline_date := time.format(deadline_ns)

    appeal_action = sprintf("TERMIN MINĄŁ %d dni temu! Skontaktuj się z adwokatem!", [abs(days_remaining)]) { is_overdue == true }
    appeal_action = "TERMIN DZIŚ — złóż natychmiast!" { days_remaining == 0 }
    appeal_action = sprintf("Złóż odwołanie w ciągu %d dni!", [days_remaining]) { days_remaining > 0; days_remaining <= 3 }
    appeal_action = sprintf("Przygotuj odwołanie — pozostało %d dni.", [days_remaining]) { days_remaining > 3 }

    appeal_rt = "BLOCK_AND_ALERT" { is_overdue == true }
    appeal_rt = "TRIAGE_QUEUE" { days_remaining >= 0; days_remaining <= 3 }
    appeal_rt = "" { days_remaining > 3 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P803: Pełnomocnictwa — Monitorowanie + Auto-generator PPS-1/UPL-1
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.ord.innovations.power_of_attorney_monitor",
    "package": "jdg.ord.innovations", "priority": 803,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ord_poa_type": poa_type,
    "ord_poa_status": poa_status,
    "ord_poa_expires_days": poa_expires_days,
    "ord_poa_needs_renewal": needs_renewal,
    "valid_from": "2024-01-01", "valid_to": null,
    "_routing": poa_rt,
    "_routing_reason": sprintf("Pełnomocnictwo: %s — %s", [poa_type, poa_status]),
    "_legal_basis": "Art. 120-129 OrdPU (pełnomocnictwa podatkowe)",
    "_warnings": [sprintf("PEŁNOMOCNICTWO — %s: %s. Wygasa za %d dni. %s", [poa_type, poa_status, poa_expires_days, poa_action])]
} {
    has_poa := object.get(input.jdg_entrepreneur, "has_tax_poa", false)
    has_poa == true

    poa_type := object.get(input.jdg_entrepreneur, "tax_poa_type", "PPS1")
    poa_expiry_str := object.get(input.jdg_entrepreneur, "tax_poa_expiry_date", "2026-12-31")
    today_str := object.get(input.jdg_entrepreneur, "current_date", "2026-07-29")

    expiry_ns := time.parse_ns("2006-01-02", poa_expiry_str)
    today_ns := time.parse_ns("2006-01-02", today_str)
    poa_expires_days := floor(time.diff(today_ns, expiry_ns) / 86400)

    needs_renewal := poa_expires_days <= 30
    needs_renewal := false { poa_expires_days > 30 }

    poa_status = "WYGASŁO" { poa_expires_days <= 0 }
    poa_status = sprintf("Wygasa za %d dni — ODNÓW!", [poa_expires_days]) { poa_expires_days > 0; poa_expires_days <= 30 }
    poa_status = sprintf("Aktywne (%d dni)", [poa_expires_days]) { poa_expires_days > 30 }

    poa_action = "Natychmiast złóż nowe pełnomocnictwo!" { poa_expires_days <= 0 }
    poa_action = sprintf("Złóż PPS-1/UPL-1 przed wygaśnięciem (zostało %d dni).", [poa_expires_days]) { poa_expires_days > 0; poa_expires_days <= 30 }
    poa_action = "Pełnomocnictwo aktywne." { poa_expires_days > 30 }

    poa_rt = "BLOCK_AND_ALERT" { poa_expires_days <= 0 }
    poa_rt = "TRIAGE_QUEUE" { poa_expires_days > 0; poa_expires_days <= 30 }
    poa_rt = "" { poa_expires_days > 30 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P804: Nadpłata Auto-Detector + Wniosek o stwierdzenie nadpłaty (Art. 72-80)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.ord.innovations.overpayment_auto_detector",
    "package": "jdg.ord.innovations", "priority": 804,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ord_overpayment_amount": overpayment,
    "ord_overpayment_interest": overpayment_interest,
    "ord_overpayment_total_refund": total_refund,
    "ord_overpayment_years": years_ago,
    "ord_overpayment_barred": is_barred,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": overpayment_rt,
    "_routing_reason": sprintf("Nadpłata: %.2f PLN + odsetki %.2f PLN", [overpayment, overpayment_interest]),
    "_legal_basis": "Art. 72-80 OrdPU (nadpłata podatkowa)",
    "_warnings": [sprintf("WYKRYTO NADPŁATĘ — %.2f PLN (sprzed %d lat). Odsetki (stopa ref - 0.5%%): %.2f PLN. Łącznie do zwrotu: %.2f PLN. %s", [overpayment, years_ago, overpayment_interest, total_refund, op_action])]
} {
    overpayment := object.get(input.jdg_entrepreneur, "detected_overpayment_pln", 0)
    overpayment > 0

    years_ago := object.get(input.jdg_entrepreneur, "overpayment_years_ago", 1)
    is_barred := years_ago > 5

    # Art. 78: oprocentowanie = stopa referencyjna - 0.5%
    ord_ref_rate := object.get(object.get(data.thresholds, "rates", {}), "tax_interest", 0.145)
    op_rate := max([ord_ref_rate - 0.005, 0])
    overpayment_interest := floor(overpayment * op_rate * years_ago * 100) / 100
    total_refund := overpayment + overpayment_interest

    op_action = "PRZEDAWNIONE — nadpłata sprzed >5 lat. Sprawdź z doradcą." { is_barred == true }
    op_action = sprintf("Złóż wniosek o stwierdzenie nadpłaty (Art. 75 OrdPU)! Oczekiwany zwrot: %.2f PLN w 30 dni.", [total_refund]) { is_barred == false }

    overpayment_rt = "TRIAGE_QUEUE" { is_barred == false }
    overpayment_rt = "" { is_barred == true }
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  PART 2: UoR FOUNDATION — Ustawa o Rachunkowości (~100 legal points)      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# P810: Próg 2M EUR — Obowiązek ksiąg rachunkowych (Art. 2 UoR)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.ord.innovations.uor_threshold_check",
    "package": "jdg.ord.innovations", "priority": 810,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "uor_threshold_eur": threshold_eur,
    "uor_threshold_pln": threshold_pln,
    "uor_annual_revenue_pln": annual_revenue,
    "uor_books_required": books_required,
    "uor_transition_year": transition_year,
    "valid_from": "2015-01-01", "valid_to": null,
    "_routing": uor_rt,
    "_routing_reason": sprintf("UoR próg: %.0f PLN / %.0f EUR — przychód: %.0f PLN → księgi: %s", [threshold_pln, threshold_eur, annual_revenue, books_required]),
    "_legal_basis": "Art. 2 UoR (obowiązek prowadzenia ksiąg rachunkowych)",
    "_warnings": [sprintf("UoR PRÓG 2M EUR — Przychód netto: %.0f PLN (kurs NBP: %.4f PLN/EUR). Próg: %.0f EUR (~%.0f PLN). Status: %s. %s", [annual_revenue, eur_rate, threshold_eur, threshold_pln, uor_status, uor_action])]
} {
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_net_pln", 0)
    eur_rate := object.get(input.jdg_entrepreneur, "nbp_eur_rate_end_of_year", 4.50)
    threshold_eur := 2000000
    threshold_pln := floor(threshold_eur * eur_rate)

    books_required := annual_revenue > threshold_pln
    current_year := object.get(input.jdg_entrepreneur, "current_year", 2026)
    transition_year := current_year + 1 { books_required == true }
    transition_year := 0 { books_required == false }

    uor_status = sprintf("KRYTYCZNY — Przychód %.0f PLN > próg %.0f PLN. Musisz prowadzić księgi rachunkowe od %d roku!", [annual_revenue, threshold_pln, transition_year]) { books_required == true }
    uor_status = sprintf("OK — Przychód %.0f PLN < próg %.0f PLN. Księgi nie są wymagane.", [annual_revenue, threshold_pln]) { books_required == false }

    uor_action = sprintf("Przygotuj przejście z PKPiR na księgi rachunkowe od 01.01.%d. Potrzebujesz: remanent na 31.12.%d, otwarcie ksiąg, plan kont, wycena aktywów.", [transition_year, current_year]) { books_required == true }
    uor_action = "Prowadź PKPiR. Monitoruj przychód — gdy przekroczysz ~9M PLN, przejdź na księgi." { books_required == false }

    uor_rt = "BLOCK_AND_ALERT" { books_required == true }
    uor_rt = "" { books_required == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P811: 7 Fundamentalnych Zasad Rachunkowości (Art. 4 UoR)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.ord.innovations.uor_accounting_principles",
    "package": "jdg.ord.innovations", "priority": 811,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "uor_principles_violations": violation_count,
    "uor_principles_list": principles_checked,
    "uor_principles_compliance_pct": compliance_pct,
    "valid_from": "2015-01-01", "valid_to": null,
    "_routing": princ_rt,
    "_routing_reason": sprintf("UoR Zasady: %.0f%% zgodności (%d naruszeń)", [compliance_pct, violation_count]),
    "_legal_basis": "Art. 4 UoR (fundamentalne zasady rachunkowości)",
    "_warnings": [sprintf("UoR 7 ZASAD RACHUNKOWOŚCI — Zgodność: %.0f%% (%d/7). Naruszenia: %s. %s", [compliance_pct, 7 - violation_count, violated_list, princ_action])]
} {
    uor_books_active := object.get(input.jdg_entrepreneur, "uor_books_active", false)
    uor_books_active == true

    # Check 7 principles
    principio_memorial := object.get(input.jdg_entrepreneur, "uor_principle_accrual", true)
    principio_wspolmiernosc := object.get(input.jdg_entrepreneur, "uor_principle_matching", true)
    principio_ostroznosc := object.get(input.jdg_entrepreneur, "uor_principle_prudence", true)
    principio_ciaglosc := object.get(input.jdg_entrepreneur, "uor_principle_continuity", true)
    principio_istotnosc := object.get(input.jdg_entrepreneur, "uor_principle_materiality", true)
    principio_tresc_nad_forma := object.get(input.jdg_entrepreneur, "uor_principle_substance_over_form", true)
    principio_zakaz_kompensaty := object.get(input.jdg_entrepreneur, "uor_principle_no_netting", true)

    # Build violations list — use `=` (partial rule) for each violation, concat at the end
    v1 = ["MEMORIAŁ"] { principio_memorial == false }
    v1 = [] { principio_memorial == true }
    v2 = ["WSPÓŁMIERNOŚĆ"] { principio_wspolmiernosc == false }
    v2 = [] { principio_wspolmiernosc == true }
    v3 = ["OSTROŻNOŚĆ"] { principio_ostroznosc == false }
    v3 = [] { principio_ostroznosc == true }
    v4 = ["CIĄGŁOŚĆ"] { principio_ciaglosc == false }
    v4 = [] { principio_ciaglosc == true }
    v5 = ["ISTOTNOŚĆ"] { principio_istotnosc == false }
    v5 = [] { principio_istotnosc == true }
    v6 = ["TREŚĆ>FORMA"] { principio_tresc_nad_forma == false }
    v6 = [] { principio_tresc_nad_forma == true }
    v7 = ["ZAKAZ KOMPENSATY"] { principio_zakaz_kompensaty == false }
    v7 = [] { principio_zakaz_kompensaty == true }

    violations := array.concat(v1, array.concat(v2, array.concat(v3, array.concat(v4, array.concat(v5, array.concat(v6, v7))))))

    violation_count := count(violations)
    compliance_pct := floor((7 - violation_count) / 7 * 100)
    violated_list := sprintf("%v", [violations])

    princ_action = "NATYCHMIAST KOREKTA KSIĄG! Naruszono fundamentalne zasady UoR." { violation_count >= 3 }
    princ_action = sprintf("Popraw %d naruszeń zasad rachunkowości.", [violation_count]) { violation_count >= 1; violation_count < 3 }
    princ_action = "Wszystkie 7 zasad zachowanych." { violation_count == 0 }

    princ_rt = "BLOCK_AND_ALERT" { violation_count >= 3 }
    princ_rt = "TRIAGE_QUEUE" { violation_count >= 1; violation_count < 3 }
    princ_rt = "" { violation_count == 0 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P812: Podwójny zapis Wn/Ma — Auto-Validator (Art. 22 UoR)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.ord.innovations.uor_double_entry_validator",
    "package": "jdg.ord.innovations", "priority": 812,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "uor_debit_total": debit_total,
    "uor_credit_total": credit_total,
    "uor_trial_balance_diff": balance_diff,
    "uor_trial_balance_ok": balance_ok,
    "uor_unbalanced_entries": unbalanced_count,
    "valid_from": "2015-01-01", "valid_to": null,
    "_routing": de_rt,
    "_routing_reason": sprintf("Wn/Ma: Wn=%.2f PLN, Ma=%.2f PLN — różnica: %.2f PLN", [debit_total, credit_total, balance_diff]),
    "_legal_basis": "Art. 22 UoR (podwójny zapis księgowy — Wn/Ma)",
    "_warnings": [sprintf("PODWÓJNY ZAPIS Wn/Ma — Suma Wn: %.2f PLN. Suma Ma: %.2f PLN. Różnica bilansu próbnego: %.2f PLN. Zapisów niezrównoważonych: %d. %s", [debit_total, credit_total, balance_diff, unbalanced_count, de_action])]
} {
    uor_books_active := object.get(input.jdg_entrepreneur, "uor_books_active", false)
    uor_books_active == true

    debit_total := object.get(input.jdg_entrepreneur, "uor_debit_total_pln", 0)
    credit_total := object.get(input.jdg_entrepreneur, "uor_credit_total_pln", 0)
    unbalanced_count := object.get(input.jdg_entrepreneur, "uor_unbalanced_entries_count", 0)

    balance_diff := abs(debit_total - credit_total)
    balance_ok := balance_diff < 0.01

    de_action = sprintf("BILANS NIEZGODNY! Różnica: %.2f PLN. Sprawdź %d niezrównoważonych zapisów.", [balance_diff, unbalanced_count]) { balance_ok == false }
    de_action = "Bilans próbny zgodny — Wn = Ma." { balance_ok == true }

    de_rt = "BLOCK_AND_ALERT" { balance_ok == false; balance_diff > 1000 }
    de_rt = "TRIAGE_QUEUE" { balance_ok == false; balance_diff <= 1000 }
    de_rt = "" { balance_ok == true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P813: Inwentaryzacja Auto-Reconciler (Art. 26 UoR)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.ord.innovations.uor_inventory_reconciler",
    "package": "jdg.ord.innovations", "priority": 813,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "uor_inventory_book_value": book_value,
    "uor_inventory_actual_value": actual_value,
    "uor_inventory_difference": inv_diff,
    "uor_inventory_diff_pct": diff_pct,
    "uor_inventory_method": inv_method,
    "valid_from": "2015-01-01", "valid_to": null,
    "_routing": inv_rt,
    "_routing_reason": sprintf("Inwentaryzacja: księgowe=%.2f PLN, rzeczywiste=%.2f PLN — różnica: %.2f PLN (%.1f%%)", [book_value, actual_value, inv_diff, diff_pct]),
    "_legal_basis": "Art. 26 UoR (inwentaryzacja aktywów i pasywów)",
    "_warnings": [sprintf("INWENTARYZACJA — %s. Wartość księgowa: %.2f PLN. Wartość rzeczywista: %.2f PLN. Różnica: %.2f PLN (%.1f%%). %s", [inv_method, book_value, actual_value, inv_diff, diff_pct, inv_action])]
} {
    uor_books_active := object.get(input.jdg_entrepreneur, "uor_books_active", false)
    uor_books_active == true

    book_value := object.get(input.jdg_entrepreneur, "uor_asset_book_value", 0)
    actual_value := object.get(input.jdg_entrepreneur, "uor_asset_actual_value", 0)
    asset_type := object.get(input.jdg_entrepreneur, "uor_asset_type", "INVENTORY")
    inv_diff := actual_value - book_value
    diff_pct := floor(abs(inv_diff) / max([book_value, 1]) * 1000) / 10

    inv_method = "SPIS Z NATURY" { asset_type in {"INVENTORY", "CASH", "SECURITIES"} }
    inv_method = "POTWIERDZENIE SALD" { asset_type in {"RECEIVABLES", "PAYABLES", "BANK_ACCOUNTS"} }
    inv_method = "PORÓWNANIE" { asset_type in {"LAND", "INTANGIBLES"} }

    inv_action = sprintf("ZNACZNA RÓŻNICA (%.1f%%)! Przeprowadź szczegółową inwentaryzację i skoryguj księgi.", [diff_pct]) { abs(inv_diff) > 0; diff_pct > 10 }
    inv_action = sprintf("Niewielka różnica (%.1f%%). Zweryfikuj i skoryguj.", [diff_pct]) { abs(inv_diff) > 0; diff_pct <= 10 }
    inv_action = "Stan zgodny — brak różnic." { inv_diff == 0 }

    inv_rt = "TRIAGE_QUEUE" { diff_pct > 10 }
    inv_rt = "" { diff_pct <= 10 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P814: Wycena aktywów wg UoR (Art. 28 UoR) — vs PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.ord.innovations.uor_asset_valuation",
    "package": "jdg.ord.innovations", "priority": 814,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "uor_valuation_fixed_assets": fa_uor,
    "uor_valuation_pit": fa_pit,
    "uor_valuation_diff": valuation_diff,
    "uor_valuation_method": val_method,
    "valid_from": "2015-01-01", "valid_to": null,
    "_routing": val_rt,
    "_routing_reason": sprintf("Wycena: UoR=%.2f PLN, PIT=%.2f PLN — różnica: %.2f PLN", [fa_uor, fa_pit, valuation_diff]),
    "_legal_basis": "Art. 28 UoR (wycena aktywów i pasywów)",
    "_warnings": [sprintf("WYCENA AKTYWÓW — %s. Wartość UoR: %.2f PLN. Wartość PIT: %.2f PLN. Różnica bilansowa: %.2f PLN (odroczony podatek). Amortyzacja UoR: %.2f PLN/rok vs PIT: %.2f PLN/rok.", [val_method, fa_uor, fa_pit, valuation_diff, uor_depr, pit_depr])]
} {
    uor_books_active := object.get(input.jdg_entrepreneur, "uor_books_active", false)
    uor_books_active == true

    purchase_price := object.get(input.jdg_entrepreneur, "asset_purchase_price", 100000)
    asset_type := object.get(input.jdg_entrepreneur, "asset_type_uor", "IT_EQUIPMENT")

    # UoR: economic useful life
    uor_years = 3 { asset_type == "IT_EQUIPMENT" }
    uor_years = 5 { asset_type == "VEHICLE" }
    uor_years = 10 { asset_type == "MACHINERY" }
    uor_years = 40 { asset_type == "BUILDING" }

    # PIT: tax schedule rates (fixed)
    pit_years = 5 { asset_type == "IT_EQUIPMENT" }
    pit_years = 5 { asset_type == "VEHICLE" }
    pit_years = 7 { asset_type == "MACHINERY" }
    pit_years = 40 { asset_type == "BUILDING" }

    uor_depr := floor(purchase_price / uor_years * 100) / 100
    pit_depr := floor(purchase_price / pit_years * 100) / 100

    age_years := object.get(input.jdg_entrepreneur, "asset_age_years", 0)
    fa_uor := max([purchase_price - uor_depr * age_years, 0])
    fa_pit := max([purchase_price - pit_depr * age_years, 0])
    valuation_diff := fa_uor - fa_pit

    val_method = sprintf("Amortyzacja UoR: %d lat (ekonomiczna użyteczność)", [uor_years])

    val_rt = "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P815: Sprawozdawczość — Bilans + RZiS + terminy (Art. 45-52 UoR)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.ord.innovations.uor_financial_reporting",
    "package": "jdg.ord.innovations", "priority": 815,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "uor_balance_total_assets": total_assets,
    "uor_balance_total_liabilities": total_liabilities,
    "uor_pnl_net_profit": net_profit,
    "uor_reporting_deadline_days": deadline_days,
    "uor_reporting_overdue": report_overdue,
    "valid_from": "2015-01-01", "valid_to": null,
    "_routing": rep_rt,
    "_routing_reason": sprintf("Sprawozdanie: Aktywa=%.2f PLN, Zysk netto=%.2f PLN, do terminu: %d dni", [total_assets, net_profit, deadline_days]),
    "_legal_basis": "Art. 45-52 UoR (sprawozdawczość finansowa)",
    "_warnings": [sprintf("SPRAWOZDAWCZOŚĆ UoR — Aktywa ogółem: %.2f PLN. Pasywa: %.2f PLN. Zysk netto: %.2f PLN. Termin sprawozdania: %d dni (do 31 marca). %s", [total_assets, total_liabilities, net_profit, deadline_days, rep_action])]
} {
    uor_books_active := object.get(input.jdg_entrepreneur, "uor_books_active", false)
    uor_books_active == true

    total_assets := object.get(input.jdg_entrepreneur, "uor_total_assets", 0)
    total_liabilities := object.get(input.jdg_entrepreneur, "uor_total_equity_liabilities", 0)
    net_profit := object.get(input.jdg_entrepreneur, "uor_net_profit_loss", 0)

    # Deadline: 3 months from balance date (31 March)
    today_str := object.get(input.jdg_entrepreneur, "current_date", "2026-07-29")
    today_ns := time.parse_ns("2006-01-02", today_str)
    deadline_ns := time.parse_ns("2006-01-02", "2026-03-31")
    deadline_days := floor(time.diff(today_ns, deadline_ns) / 86400)

    report_overdue := deadline_days > 0

    rep_action = sprintf("SPRAWOZDANIE ZALEGŁE o %d dni! Złóż natychmiast do KRS + US!", [deadline_days]) { report_overdue == true }
    rep_action = sprintf("Przygotuj sprawozdanie finansowe — pozostało %d dni do 31 marca.", [abs(deadline_days)]) { report_overdue == false }

    rep_rt = "BLOCK_AND_ALERT" { report_overdue == true }
    rep_rt = "" { report_overdue == false }
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  PART 3: PCC COMPLETE — Podatek od Czynności Cywilnoprawnych              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# P820: PCC Auto-Detector — 10 typów czynności + stawki
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.ord.innovations.pcc_auto_detector",
    "package": "jdg.ord.innovations", "priority": 820,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "pcc_transaction_type": pcc_type,
    "pcc_taxable_value": taxable_value,
    "pcc_rate_pct": pcc_rate,
    "pcc_tax_due": pcc_due,
    "pcc_vat_excluded": vat_excludes_pcc,
    "pcc_deadline_days": 14,
    "valid_from": "2024-01-01", "valid_to": null,
    "_routing": pcc_rt,
    "_routing_reason": sprintf("PCC: %s — %.0f%% × %.2f PLN = %.2f PLN", [pcc_type, pcc_rate * 100, taxable_value, pcc_due]),
    "_legal_basis": "Art. 1-10 Ustawy o PCC (podatek od czynności cywilnoprawnych)",
    "_warnings": [sprintf("PCC AUTO-DETECTOR — %s. Wartość: %.2f PLN. Stawka PCC: %.1f%%. Podatek: %.2f PLN. Termin PCC-3: 14 dni. %s", [pcc_type, taxable_value, pcc_rate * 100, pcc_due, pcc_action])]
} {
    # Detect transaction type
    has_pcc_sale := object.get(input.jdg_entrepreneur, "pcc_sale_of_goods", false)
    has_pcc_real_estate := object.get(input.jdg_entrepreneur, "pcc_real_estate_purchase", false)
    has_pcc_loan := object.get(input.jdg_entrepreneur, "pcc_loan_received", false)
    has_pcc_exchange := object.get(input.jdg_entrepreneur, "pcc_exchange", false)
    has_pcc_donation := object.get(input.jdg_entrepreneur, "pcc_donation", false)
    has_pcc_mortgage := object.get(input.jdg_entrepreneur, "pcc_mortgage", false)
    has_pcc_usufruct := object.get(input.jdg_entrepreneur, "pcc_usufruct", false)
    has_pcc_company := object.get(input.jdg_entrepreneur, "pcc_company_shares", false)
    has_pcc_pledge := object.get(input.jdg_entrepreneur, "pcc_pledge", false)
    has_pcc_court := object.get(input.jdg_entrepreneur, "pcc_court_ruling", false)

    pcc_detected { has_pcc_sale == true }
    pcc_detected { has_pcc_real_estate == true }
    pcc_detected { has_pcc_loan == true }
    pcc_detected { has_pcc_exchange == true }
    pcc_detected { has_pcc_donation == true }
    pcc_detected { has_pcc_mortgage == true }
    pcc_detected { has_pcc_usufruct == true }
    pcc_detected { has_pcc_company == true }
    pcc_detected { has_pcc_pledge == true }
    pcc_detected { has_pcc_court == true }

    pcc_detected

    taxable_value := object.get(input.jdg_entrepreneur, "pcc_transaction_value", 0)

    # Check VAT exclusion (Art. 2 pkt 4 PCC) — mutually exclusive: true only when BOTH taxpayer AND transaction has VAT
    vat_excludes_pcc := true { is_vat_taxpayer == true; transaction_vat_charged == true }
    vat_excludes_pcc := false { is_vat_taxpayer == false }
    vat_excludes_pcc := false { is_vat_taxpayer == true; transaction_vat_charged == false }

    # Determine type and rate
    pcc_type = "SPRZEDAŻ RZECZY (2%)" { has_pcc_sale == true }
    pcc_type = "SPRZEDAŻ NIERUCHOMOŚCI (1%)" { has_pcc_real_estate == true; has_pcc_sale == false }
    pcc_type = "POŻYCZKA (2%)" { has_pcc_loan == true }
    pcc_type = "ZAMIANA (1%)" { has_pcc_exchange == true }
    pcc_type = "DAROWIZNA (2%)" { has_pcc_donation == true }
    pcc_type = "HIPOTEKA (0.1%)" { has_pcc_mortgage == true }
    pcc_type = "UŻYTKOWANIE (1%)" { has_pcc_usufruct == true }
    pcc_type = "UMOWA SPÓŁKI (0.5%)" { has_pcc_company == true }
    pcc_type = "ZASTAW (0.1%)" { has_pcc_pledge == true }
    pcc_type = "ORZECZENIE SĄDU (wg właściwej stawki)" { has_pcc_court == true }

    # Rates — use lower-case THEN apply loan exemption override (mutually exclusive)
    pcc_rate_val = 0.02 { has_pcc_sale == true }
    pcc_rate_val = 0.01 { has_pcc_real_estate == true }
    pcc_rate_val = 0.02 { has_pcc_loan == true; taxable_value > 36120 }
    pcc_rate_val = 0.00 { has_pcc_loan == true; taxable_value <= 36120 }
    pcc_rate_val = 0.01 { has_pcc_exchange == true }
    pcc_rate_val = 0.02 { has_pcc_donation == true }
    pcc_rate_val = 0.001 { has_pcc_mortgage == true }
    pcc_rate_val = 0.01 { has_pcc_usufruct == true }
    pcc_rate_val = 0.005 { has_pcc_company == true }
    pcc_rate_val = 0.001 { has_pcc_pledge == true }
    pcc_rate_val = 0.02 { has_pcc_court == true }

    pcc_rate := pcc_rate_val
    pcc_due := floor(taxable_value * pcc_rate * 100) / 100

    pcc_action = "ZŁÓŻ PCC-3 w 14 dni + zapłać podatek!" { vat_excludes_pcc == false; pcc_due > 0 }
    pcc_action = "WYŁĄCZONE Z PCC — czynność podlega VAT (Art. 2 pkt 4 PCC)." { vat_excludes_pcc == true }
    pcc_action = "Zwolnione z PCC — pożyczka rodzinna do 36 120 PLN." { has_pcc_loan == true; taxable_value <= 36120 }

    pcc_rt = "BLOCK_AND_ALERT" { vat_excludes_pcc == false; pcc_due > 10000 }
    pcc_rt = "TRIAGE_QUEUE" { vat_excludes_pcc == false; pcc_due > 0; pcc_due <= 10000 }
    pcc_rt = "" { vat_excludes_pcc == true }
    pcc_rt = "" { pcc_due == 0 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P821: PCC+VAT Exclusion Firewall (Art. 2 pkt 4 PCC) — Innov #12
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.ord.innovations.pcc_vat_exclusion_firewall",
    "package": "jdg.ord.innovations", "priority": 821,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "pcc_vat_buyer_vat_status": buyer_vat_status,
    "pcc_vat_seller_vat_status": seller_vat_status,
    "pcc_vat_exclusion_applies": exclusion_applies,
    "pcc_vat_risk_note": risk_note,
    "valid_from": "2024-01-01", "valid_to": null,
    "_routing": pv_rt,
    "_routing_reason": sprintf("PCC+VAT Firewall: wyłączenie=%s, kupujący=%s, sprzedawca=%s", [exclusion_applies, buyer_vat_status, seller_vat_status]),
    "_legal_basis": "Art. 2 pkt 4 Ustawy o PCC (wyłączenie dla transakcji VAT)",
    "_warnings": [sprintf("PCC+VAT EXCLUSION FIREWALL — Kupujący: %s. Sprzedawca: %s. Wyłączenie z PCC przez VAT: %s. %s", [buyer_vat_status, seller_vat_status, exclusion_applies, risk_note])]
} {
    has_pcc_transaction := object.get(input.jdg_entrepreneur, "pcc_vat_conflict_detected", false)
    has_pcc_transaction == true

    buyer_is_vat := object.get(input.jdg_entrepreneur, "is_active_vat_taxpayer", false)
    seller_is_vat := object.get(input.jdg_entrepreneur, "pcc_seller_is_vat_taxpayer", false)
    seller_vat_exempt := object.get(input.jdg_entrepreneur, "pcc_seller_vat_exempt_subjectively", false)
    transaction_has_vat := object.get(input.jdg_entrepreneur, "pcc_transaction_has_vat", true)

    buyer_vat_status = "CZYNNY VAT" { buyer_is_vat == true }
    buyer_vat_status = "NIE-VAT" { buyer_is_vat == false }

    seller_vat_status = "CZYNNY VAT" { seller_is_vat == true; seller_vat_exempt == false }
    seller_vat_status = "ZWOLNIONY PODMIOTOWO (Art. 113 VAT) — UWAGA! PCC SIĘ NALEŻY!" { seller_vat_exempt == true }
    seller_vat_status = "NIE-VAT (osoba prywatna)" { seller_is_vat == false; seller_vat_exempt == false }

    # Exclusion applies only when seller is active VAT taxpayer AND transaction has VAT (mutually exclusive)
    exclusion_applies := true { seller_is_vat == true; seller_vat_exempt == false; transaction_has_vat == true }
    exclusion_applies := false { seller_is_vat == false }
    exclusion_applies := false { seller_vat_exempt == true }
    exclusion_applies := false { seller_is_vat == true; seller_vat_exempt == false; transaction_has_vat == false }

    risk_note = "PCC WYŁĄCZONE — transakcja podlega VAT (Art. 2 pkt 4 PCC). Nie składasz PCC-3." { exclusion_applies == true }
    risk_note = "UWAGA! Sprzedawca zwolniony podmiotowo z VAT → PCC SIĘ NALEŻY! Złóż PCC-3!" { seller_vat_exempt == true }
    risk_note = "PCC NALEŻNE — sprzedawca nie jest VAT-owcem. Złóż PCC-3." { exclusion_applies == false; seller_vat_exempt == false }

    pv_rt = "BLOCK_AND_ALERT" { seller_vat_exempt == true }
    pv_rt = "TRIAGE_QUEUE" { exclusion_applies == false; seller_vat_exempt == false }
    pv_rt = "" { exclusion_applies == true }
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  PART 4: AKCYZA + PODATKI LOKALNE                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# P830: Excise Warehouse Digital Twin (Skład podatkowy)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.ord.innovations.excise_warehouse_twin",
    "package": "jdg.ord.innovations", "priority": 830,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "excise_warehouse_license": license_valid,
    "excise_warehouse_guarantee": guarantee_pln,
    "excise_warehouse_stock_level": stock_level,
    "excise_warehouse_emcs_status": emcs_status,
    "excise_suspension_active": suspension_active,
    "valid_from": "2024-01-01", "valid_to": null,
    "_routing": exc_rt,
    "_routing_reason": sprintf("Skład podatkowy: licencja=%s, gwarancja=%.2f PLN, stock=%.2f, EMCS=%s", [license_valid, guarantee_pln, stock_level, emcs_status]),
    "_legal_basis": "Art. 48-63 Ustawy o podatku akcyzowym (skład podatkowy)",
    "_warnings": [sprintf("SKŁAD PODATKOWY — Licencja: %s. Gwarancja akcyzowa: %.2f PLN. Stan magazynowy: %.2f jednostek. EMCS: %s. Zawieszenie akcyzy: %s. %s", [license_valid, guarantee_pln, stock_level, emcs_status, suspension_active, exc_action])]
} {
    has_excise_warehouse := object.get(input.jdg_entrepreneur, "has_excise_warehouse", false)
    has_excise_warehouse == true

    license_valid := object.get(input.jdg_entrepreneur, "excise_warehouse_license_valid", false)
    license_expiry := object.get(input.jdg_entrepreneur, "excise_license_expiry_days", 365)
    guarantee_pln := object.get(input.jdg_entrepreneur, "excise_guarantee_amount_pln", 0)
    stock_level := object.get(input.jdg_entrepreneur, "excise_stock_quantity", 0)
    emcs_active := object.get(input.jdg_entrepreneur, "excise_emcs_active", false)

    suspension_active := license_valid == true

    emcs_status = "AKTYWNY" { emcs_active == true }
    emcs_status = "NIEAKTYWNY — wymagana rejestracja w EMCS!" { emcs_active == false }

    exc_action = "Skład podatkowy sprawny — ewidencja aktualna." { license_valid == true; emcs_active == true }
    exc_action = "Brak licencji składu podatkowego! Wymagane zezwolenie naczelnika UC." { license_valid == false }
    exc_action = sprintf("Licencja wygasa za %d dni — złóż wniosek o przedłużenie!", [license_expiry]) { license_valid == true; license_expiry <= 60 }
    exc_action = "Zarejestruj się w systemie EMCS do obsługi e-AD." { emcs_active == false }

    exc_rt = "BLOCK_AND_ALERT" { license_valid == false }
    exc_rt = "TRIAGE_QUEUE" { license_valid == true; license_expiry <= 60 }
    exc_rt = "TRIAGE_QUEUE" { emcs_active == false }
    exc_rt = "" { license_valid == true; license_expiry > 60; emcs_active == true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P831: Property Tax Auto-Classifier (Podatek od nieruchomości)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.ord.innovations.property_tax_classifier",
    "package": "jdg.ord.innovations", "priority": 831,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "property_tax_total": total_tax,
    "property_classification": prop_class,
    "property_tax_dn1_due": "31 stycznia",
    "valid_from": "2024-01-01", "valid_to": null,
    "_routing": prop_rt,
    "_routing_reason": sprintf("Podatek od nieruchomości: %s — %.2f PLN/rok", [prop_class, total_tax]),
    "_legal_basis": "Art. 2-7 u.p.o.l. (podatek od nieruchomości)",
    "_warnings": [sprintf("PODATEK OD NIERUCHOMOŚCI — %s. Powierzchnia: %.0f m². Stawka: %.2f PLN/m². Podatek roczny: %.2f PLN. Termin DN-1: 31 stycznia. %s", [prop_class, area, rate_per_m2, total_tax, prop_action])]
} {
    has_property := object.get(input.jdg_entrepreneur, "has_business_property", false)
    has_property == true

    area := object.get(input.jdg_entrepreneur, "property_area_m2", 0)
    is_business_use := object.get(input.jdg_entrepreneur, "property_business_use", false)
    is_residential := object.get(input.jdg_entrepreneur, "property_residential", false)
    is_structure := object.get(input.jdg_entrepreneur, "property_is_structure", false)
    structure_value := object.get(input.jdg_entrepreneur, "structure_value_pln", 0)

    # Stawki (przybliżone — zależne od gminy)
    business_rate := object.get(object.get(data.thresholds, "local_taxes", {}), "business_land_rate", 33.00)
    residential_rate := object.get(object.get(data.thresholds, "local_taxes", {}), "residential_rate", 1.15)

    rate_per_m2 = business_rate { is_business_use == true; is_structure == false }
    rate_per_m2 = residential_rate { is_residential == true; is_structure == false }

    prop_class = "GRUNT FIRMOWY" { is_business_use == true; is_structure == false }
    prop_class = "BUDYNEK MIESZKALNY" { is_residential == true; is_structure == false }
    prop_class = sprintf("BUDOWLA (2%% od %.2f PLN)", [structure_value]) { is_structure == true }

    total_tax = floor(area * rate_per_m2 * 100) / 100 { is_structure == false }
    total_tax = floor(structure_value * 0.02 * 100) / 100 { is_structure == true }

    prop_action = "Złóż deklarację DN-1 do 31 stycznia + zapłać podatek." { true }

    prop_rt = "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P832: Transport Tax Calculator (Podatek od środków transportowych)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.ord.innovations.transport_tax_calculator",
    "package": "jdg.ord.innovations", "priority": 832,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "transport_tax_annual": annual_tax,
    "transport_vehicle_class": vehicle_class,
    "transport_tax_dt1_due": "15 lutego",
    "valid_from": "2024-01-01", "valid_to": null,
    "_routing": trans_rt,
    "_routing_reason": sprintf("Podatek transportowy: %s — %.2f PLN/rok", [vehicle_class, annual_tax]),
    "_legal_basis": "Art. 8-14 u.p.o.l. (podatek od środków transportowych)",
    "_warnings": [sprintf("PODATEK TRANSPORTOWY — %s. DMC: %.1f t. Osie: %d. Norma Euro: %s. Podatek roczny: ~%.2f PLN. Termin DT-1: 15 lutego. %s", [vehicle_class, dmc, axles, euro_norm, annual_tax, trans_action])]
} {
    has_vehicle := object.get(input.jdg_entrepreneur, "has_taxable_vehicle", false)
    has_vehicle == true

    dmc := object.get(input.jdg_entrepreneur, "vehicle_dmc_tons", 0)
    axles := object.get(input.jdg_entrepreneur, "vehicle_axles", 2)
    vehicle_age := object.get(input.jdg_entrepreneur, "vehicle_age_years", 0)
    euro_norm := object.get(input.jdg_entrepreneur, "vehicle_euro_norm", "EURO6")

    vehicle_class = sprintf("CIĘŻAROWY %.1ft (%d osi)", [dmc, axles])

    # Simplified rate calculation based on DMC and axles
    base_rate_pln = 800 { dmc >= 3.5; dmc < 12 }
    base_rate_pln = 1200 { dmc >= 12; dmc < 25 }
    base_rate_pln = 1800 { dmc >= 25; dmc < 31 }
    base_rate_pln = 2500 { dmc >= 31 }

    # Age surcharge
    age_mult := 1.0 { vehicle_age <= 5 }
    age_mult := 1.2 { vehicle_age > 5; vehicle_age <= 10 }
    age_mult := 1.5 { vehicle_age > 10 }

    # Euro norm discount
    euro_disc := 1.0 { euro_norm in {"EURO5", "EURO6"} }
    euro_disc := 1.15 { euro_norm not in {"EURO5", "EURO6"} }

    annual_tax := floor(base_rate_pln * age_mult * euro_disc * 100) / 100

    trans_action = "Złóż deklarację DT-1 do 15 lutego + zapłać podatek." { true }

    trans_rt = "" { true }
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  PART 5: INNOVATIONS — Tax Authority Correspondence Auto-Engine + More    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# P840: Tax Authority Correspondence Auto-Engine (Innov #9)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.ord.innovations.tax_authority_correspondence",
    "package": "jdg.ord.innovations", "priority": 840,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "tax_corr_letter_type": letter_type,
    "tax_corr_authority": tax_authority,
    "tax_corr_template": "XML szablon dostępny",
    "tax_corr_deadline_days": corr_deadline_days,
    "valid_from": "2024-01-01", "valid_to": null,
    "_routing": corr_rt,
    "_routing_reason": sprintf("Korespondencja: %s → %s (%d dni)", [letter_type, tax_authority, corr_deadline_days]),
    "_legal_basis": "OrdPU + KKS + VAT + PIT (auto-generator pism do organów)",
    "_warnings": [sprintf("AUTO-KORESPONDENCJA — %s do %s. Szablon: XML. Termin: %d dni. %s", [letter_type, tax_authority, corr_deadline_days, corr_action])]
} {
    letter_needed := object.get(input.jdg_entrepreneur, "tax_letter_needed", false)
    letter_needed == true

    letter_type := object.get(input.jdg_entrepreneur, "tax_letter_type", "WNIOSEK")
    tax_authority := object.get(input.jdg_entrepreneur, "tax_authority_target", "US")

    corr_deadline_days = 0 { letter_type == "CZYNNY_ZAL" }
    corr_deadline_days = 14 { letter_type == "ODWOLANIE" }
    corr_deadline_days = 7 { letter_type == "ZAZALENIE" }
    corr_deadline_days = 30 { letter_type == "WNIOSEK" }
    corr_deadline_days = 14 { letter_type == "PCC3" }

    corr_action = "Wygenerowano szablon XML pisma. Wyślij przez ePUAP lub CEIDG." { true }

    corr_rt = "TRIAGE_QUEUE" { corr_deadline_days > 0; corr_deadline_days <= 7 }
    corr_rt = "" { corr_deadline_days <= 0 }
    corr_rt = "" { corr_deadline_days > 7 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P841: PKPiR → Księgi Rachunkowe Transition Auto-Pilot (Innov #10)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.ord.innovations.pkpir_to_uor_transition",
    "package": "jdg.ord.innovations", "priority": 841,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "uor_transition_required": transition_required,
    "uor_transition_phase": transition_phase,
    "uor_transition_steps_completed": steps_completed,
    "uor_transition_total_steps": 8,
    "valid_from": "2025-01-01", "valid_to": null,
    "_routing": trans_rt,
    "_routing_reason": sprintf("PKPiR→Księgi: Faza %d, %d/%d kroków", [transition_phase, steps_completed, 8]),
    "_legal_basis": "Art. 2 UoR + Art. 24a PIT (przejście PKPiR→Księgi rachunkowe)",
    "_warnings": [sprintf("AUTO-PILOT PKPiR→KSIĘGI — Faza %d/3: %s. Wykonano %d/8 kroków. %s", [transition_phase, phase_desc, steps_completed, trans_action])]
} {
    revenue_above_threshold := object.get(input.jdg_entrepreneur, "revenue_above_2m_eur", false)
    revenue_above_threshold == true

    transition_required := true

    # Transition phases
    step1 := object.get(input.jdg_entrepreneur, "uor_step1_remanent_done", false)
    step2 := object.get(input.jdg_entrepreneur, "uor_step2_opening_balance_done", false)
    step3 := object.get(input.jdg_entrepreneur, "uor_step3_chart_of_accounts_done", false)
    step4 := object.get(input.jdg_entrepreneur, "uor_step4_asset_valuation_done", false)
    step5 := object.get(input.jdg_entrepreneur, "uor_step5_double_entry_setup_done", false)
    step6 := object.get(input.jdg_entrepreneur, "uor_step6_inventory_opening_done", false)
    step7 := object.get(input.jdg_entrepreneur, "uor_step7_first_journal_done", false)
    step8 := object.get(input.jdg_entrepreneur, "uor_step8_reporting_setup_done", false)

    # Count completed steps — each step adds 1 when true, mutually exclusive via completion status
    steps_completed := count([s | s := [step1, step2, step3, step4, step5, step6, step7, step8][_]; s == true])

    transition_phase = 1 { steps_completed <= 2 }
    transition_phase = 2 { steps_completed >= 3; steps_completed <= 5 }
    transition_phase = 3 { steps_completed >= 6; steps_completed < 8 }
    transition_phase = 4 { steps_completed >= 8 }  # Complete

    phase_desc = "Faza 1: Remanent + bilans otwarcia" { steps_completed <= 2 }
    phase_desc = "Faza 2: Plan kont + wycena + Wn/Ma" { steps_completed >= 3; steps_completed <= 5 }
    phase_desc = "Faza 3: Inwentaryzacja + pierwsze księgowania + raportowanie" { steps_completed >= 6; steps_completed < 8 }
    phase_desc = "PRZEJŚCIE ZAKOŃCZONE — księgi rachunkowe aktywne!" { steps_completed >= 8 }

    trans_action = sprintf("Wykonaj pozostałe %d kroków przejścia na księgi rachunkowe.", [8 - steps_completed]) { steps_completed < 8 }
    trans_action = "Księgi rachunkowe w pełni aktywne. Rozpocznij pierwsze sprawozdanie finansowe." { steps_completed >= 8 }

    trans_rt = "BLOCK_AND_ALERT" { steps_completed == 0 }
    trans_rt = "TRIAGE_QUEUE" { steps_completed >= 1; steps_completed < 8 }
    trans_rt = "" { steps_completed >= 8 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P842: Cross-Domain Statute of Limitations Countdown (Innov #3)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.ord.innovations.cross_domain_limitation_countdown",
    "package": "jdg.ord.innovations", "priority": 842,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "statute_pit_days": pit_days,
    "statute_vat_days": vat_days,
    "statute_kks_days": kks_days,
    "statute_zus_days": zus_days,
    "statute_next_expiry_domain": next_domain,
    "statute_next_expiry_days": next_days,
    "valid_from": "2024-01-01", "valid_to": null,
    "_routing": stat_rt,
    "_routing_reason": sprintf("Przedawnienia: najbliższe=%s za %d dni", [next_domain, next_days]),
    "_legal_basis": "Art. 70 OrdPU + Art. 44 KKS + Art. 87 VAT + Art. 24 SUS (przedawnienia między-domenowe)",
    "_warnings": [sprintf("KALENDARZ PRZEDAWNIEŃ CROSS-DOMAIN — PIT: %d dni, VAT: %d dni, KKS: %d dni, ZUS: %d dni. Najbliższe przedawnienie: %s za %d dni. %s", [pit_days, vat_days, kks_days, zus_days, next_domain, next_days, stat_action])]
} {
    has_liabilities := object.get(input.jdg_entrepreneur, "has_potentially_barred_liabilities", false)
    has_liabilities == true

    pit_days := object.get(input.jdg_entrepreneur, "statute_pit_days", 9999)
    vat_days := object.get(input.jdg_entrepreneur, "statute_vat_days", 9999)
    kks_days := object.get(input.jdg_entrepreneur, "statute_kks_days", 9999)
    zus_days := object.get(input.jdg_entrepreneur, "statute_zus_days", 9999)

    # Find nearest expiry
    min_days := min([pit_days, vat_days, kks_days, zus_days])

    # Next expiry domain with tiebreaker: PIT first, then VAT, KKS, ZUS
    next_domain = "PIT" { min_days == pit_days; min_days <= vat_days; min_days <= kks_days; min_days <= zus_days }
    next_domain = "VAT" { min_days == vat_days; min_days < pit_days; min_days <= kks_days; min_days <= zus_days }
    next_domain = "KKS" { min_days == kks_days; min_days < pit_days; min_days < vat_days; min_days <= zus_days }
    next_domain = "ZUS" { min_days == zus_days; min_days < pit_days; min_days < vat_days; min_days < kks_days }
    next_days := min_days

    stat_action = sprintf("UWAGA! %s przedawnia się za %d dni. Sprawdź czy chcesz podjąć działania.", [next_domain, next_days]) { next_days <= 90 }
    stat_action = sprintf("Najbliższe przedawnienie: %s za %d dni. Monitoruj.", [next_domain, next_days]) { next_days > 90; next_days <= 365 }
    stat_action = "Wszystkie terminy przedawnień powyżej roku." { next_days > 365 }

    stat_rt = "TRIAGE_QUEUE" { next_days <= 90; next_days >= 0 }
    stat_rt = "" { next_days > 90 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P843: OrdPU Full Compliance Matrix (Innov #8) — Summary rule
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.ord.innovations.ordpu_compliance_matrix",
    "package": "jdg.ord.innovations", "priority": 843,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ord_matrix_coverage_pct": coverage_pct,
    "ord_matrix_total_articles": 193,
    "ord_matrix_covered_articles": covered,
    "ord_matrix_gaps": gap_count,
    "valid_from": "2026-07-27", "valid_to": null,
    "_routing": matrix_rt,
    "_routing_reason": sprintf("OrdPU Compliance: %.0f%% (%d/193 artykułów)", [coverage_pct, covered]),
    "_legal_basis": "OrdPU Art. 1-193a (macierz zgodności)",
    "_warnings": [sprintf("OrdPU COMPLIANCE MATRIX — Pokrycie: %.0f%% (%d/193 artykułów). Luki: %d artykułów. Priorytety: GAAR (119a), Ulgi (67a-67e), Odwołania (138a-138o), Pełnomocnictwa (120-129).", [coverage_pct, covered, gap_count])]
} {
    audit_requested := object.get(input.jdg_entrepreneur, "ordpu_compliance_audit_requested", false)
    audit_requested == true

    covered := object.get(input.jdg_entrepreneur, "ordpu_articles_covered", 190)
    gap_count := 193 - covered
    coverage_pct := floor(covered / 193 * 100)

    matrix_rt = "" { true }
}
