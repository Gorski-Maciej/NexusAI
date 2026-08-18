# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P32+P33 Combined Innovations Engine (22 Innowacji)
# ═══════════════════════════════════════════════════════════════════════════════
#
# P32 KKS (10): Penalty Simulator, Czynny Żal Auto-Generator, Risk Dashboard 5Y,
#   Integrity Score Monitor, KSeF+KKS Shield, VAT 30% Calculator, Recydywa Monitor,
#   Banking Impact Simulator, PZP Exclusion Checker, Kalendarz Przedawnień
#
# P33 OrdPU+UoR+PCC+Akcyza (12): UoR Article-to-Rego Builder, PCC Auto-Detector,
#   Statute Limitation Countdown, GAAR Shield Advanced, Double-Entry Validator,
#   Excise Warehouse Twin, Property Tax Classifier, OrdPU Compliance Matrix,
#   Tax Authority Correspondence Engine, Full Accounting Transition Pilot,
#   Inventory Auto-Reconciler, PCC+VAT Exclusion Firewall
#
# architecture: Enterprise Innovations Layer, First-Match-Wins else-chain
# package: jdg.p3233_innovations
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p3233_innovations

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.p3233_innovations.no_match",
    "package": "jdg.p3233_innovations", "priority": 99999
}

# ═══════════════════════════════════════════════════════════════════════════════
# INN-01: P32 — KKS Penalty Simulator Enterprise
# Symulacja kary: wprowadź kwotę uszczuplenia, typ czynu, okoliczności
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    has_kks_risk := object.get(input.jdg_entrepreneur, "kks_risk_detected", false)
    has_kks_risk == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    offense_type := object.get(input.jdg_entrepreneur, "kks_offense_type", "UNKNOWN")
    tax_deficiency := object.get(input.jdg_entrepreneur, "kks_deficiency_amount", 0)
    is_intentional := object.get(input.jdg_entrepreneur, "kks_offense_intentional", false)
    has_voluntary_disclosure := object.get(input.jdg_entrepreneur, "kks_active_contrition", false)
    repeat_count := object.get(input.jdg_entrepreneur, "kks_prior_offenses_5y", 0)

    # Penalty simulation
    daily_rate_base := 156  # PLN (1/30 minimalnego ~4666 PLN)
    max_daily_rates := 180 { tax_deficiency < 100000 }
    max_daily_rates := 360 { tax_deficiency >= 100000; tax_deficiency < 500000 }
    max_daily_rates := 720 { tax_deficiency >= 500000; tax_deficiency < 5000000 }
    max_daily_rates := 1080 { tax_deficiency >= 5000000 }

    # Mitigating factors
    mitigation_pct := 0
    mitigation_pct := mitigation_pct + 50 { has_voluntary_disclosure }
    mitigation_pct := mitigation_pct + 20 { not is_intentional }
    mitigation_pct := mitigation_pct - 30 { repeat_count >= 3 }

    effective_rates := floor(max_daily_rates * (100 - mitigation_pct) / 100)
    effective_rates := 10 { effective_rates < 10 }
    estimated_fine := effective_rates * daily_rate_base
    imprisonment_risk_years := 0 { tax_deficiency < 100000 }
    imprisonment_risk_years := 3 { tax_deficiency >= 100000; tax_deficiency < 5000000 }
    imprisonment_risk_years := 8 { tax_deficiency >= 5000000; offense_type == "EMPTY_INVOICE" }
    imprisonment_risk_years := 15 { tax_deficiency >= 5000000; offense_type == "VAT_CAROUSEL" }
    imprisonment_risk_years := 5 { tax_deficiency >= 5000000 }

    sim_routing := "BLOCK_AND_ALERT" { imprisonment_risk_years >= 8 }
    sim_routing := "TRIAGE_QUEUE" { estimated_fine > 50000 }
    sim_routing := "" { estimated_fine <= 50000 }

    reason := sprintf("KKS Penalty Sim: grzywna ~%.0f PLN (%.0f stawek × %.0f PLN), ryzyko więzienia do %d lat",
        [estimated_fine, effective_rates, daily_rate_base, imprisonment_risk_years]) { estimated_fine > 0 }
    reason := "" { estimated_fine == 0 }

    verdict := {
        "matched": true, "rule_id": "jdg.p3233_innovations.kks_penalty_simulator",
        "package": "jdg.p3233_innovations", "priority": 9601,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "inn_kks_deficiency": tax_deficiency,
        "inn_kks_max_rates": max_daily_rates,
        "inn_kks_effective_rates": effective_rates,
        "inn_kks_estimated_fine": estimated_fine,
        "inn_kks_imprisonment_years": imprisonment_risk_years,
        "inn_kks_mitigation_pct": mitigation_pct,
        "inn_kks_contrition_active": has_voluntary_disclosure,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": sim_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 23 KKS; Art. 54 KKS (symulacja kary)",
        "_warnings": [sprintf("🎯 KKS SYMULATOR KARY: Deficyt=%.0f PLN, Maks.stawek=%d (%.0f po ulgach %d%%). Grzywna ~%.0f PLN. Ryzyko więzienia: %s. Czynny żal: %s.",
            [tax_deficiency, max_daily_rates, effective_rates, mitigation_pct, estimated_fine, prison_note, contrition_note])]
    }

    prison_note := sprintf("do %d lat!", [imprisonment_risk_years]) { imprisonment_risk_years > 0 }
    prison_note := "brak" { imprisonment_risk_years == 0 }
    contrition_note := "AKTYWNY — ochrona!" { has_voluntary_disclosure }
    contrition_note := "NIEZŁOŻONY — złóż natychmiast!" { not has_voluntary_disclosure }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INN-02: P33 — Cross-Domain Statute of Limitations Countdown
# Zunifikowany kalendarz przedawnień: OrdPU, KKS, PIT, VAT, ZUS
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.invoice, "is_period_end", false) == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    # Collect all limitation periods
    limitations := [
        {"domain": "OrdPU", "years": 5, "description": "Zobowiązania podatkowe (Art. 70 § 1)", "interruptions": ["Zawiadomienie o postępowaniu", "Zabezpieczenie", "Egzekucja"]},
        {"domain": "KKS_crime", "years": 5, "description": "Przestępstwa skarbowe (Art. 44 § 1)", "interruptions": ["Wszczęcie postępowania KKS", "Zawiadomienie"]},
        {"domain": "KKS_misdemeanor", "years": 3, "description": "Wykroczenia skarbowe (Art. 44 § 2)", "interruptions": ["Wszczęcie postępowania"]},
        {"domain": "PIT", "years": 5, "description": "Zobowiązania PIT", "interruptions": ["Zawiadomienie o kontroli"]},
        {"domain": "VAT", "years": 5, "description": "Zobowiązania VAT", "interruptions": ["Zawiadomienie o kontroli", "JPK na żądanie"]},
        {"domain": "ZUS", "years": 5, "description": "Składki ZUS (Art. 24 u.s.u.s.)", "interruptions": ["Wszczęcie postępowania ZUS", "Zabezpieczenie"]},
        {"domain": "NADPLATA", "years": 5, "description": "Nadpłata podatku (Art. 71 OrdPU)", "interruptions": ["Wniosek o stwierdzenie nadpłaty"]}
    ]

    domain_count := count(limitations)
    total_years := 0
    total_years := total_years + 5 { true }

    verdict := {
        "matched": true, "rule_id": "jdg.p3233_innovations.limitation_calendar",
        "package": "jdg.p3233_innovations", "priority": 9602,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "inn_limitation_domains": domain_count,
        "inn_limitation_max_years": 10,
        "inn_limitation_absolute_bar": "10 lat od końca roku (Art. 70 § 7 OrdPU)",
        "business_status": "", "ceidg_registration_required": false,
        "_routing": "",
        "_routing_reason": "",
        "_legal_basis": "Art. 70-71 OrdPU; Art. 44 KKS; Art. 24 u.s.u.s.",
        "_warnings": [sprintf("📅 KALENDARZ PRZEDAWNIEŃ: %d domen monitorowanych. Maks: 5-10 lat zależnie od domeny. Bezwzględny termin: 10 lat (Art. 70 § 7 OrdPU). Przerwanie biegu resetuje licznik! Najważniejsze zdarzenia: zawiadomienie o postępowaniu, zabezpieczenie, egzekucja.", [domain_count])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INN-03: P33 — Double-Entry Auto-Validator (Wn/Ma) for UoR
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_period_end", false) == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    total_debit := object.get(input.jdg_entrepreneur, "uor_debit_total", 0)
    total_credit := object.get(input.jdg_entrepreneur, "uor_credit_total", 0)
    diff := abs(total_debit - total_credit)
    is_balanced := diff < 0.01
    unbalanced_count := object.get(input.jdg_entrepreneur, "uor_unbalanced_entries", 0)

    de_routing := "BLOCK_AND_ALERT" { not is_balanced }
    de_routing := "" { is_balanced }

    reason := sprintf("Podwójny zapis NIEZBILANSOWANY! Wn=%.2f ≠ Ma=%.2f (Δ=%.2f, %d wpisów)",
        [total_debit, total_credit, diff, unbalanced_count]) { not is_balanced }

    verdict := {
        "matched": true, "rule_id": "jdg.p3233_innovations.double_entry_validator",
        "package": "jdg.p3233_innovations", "priority": 9603,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "inn_double_entry_balanced": is_balanced,
        "inn_debit_total": total_debit,
        "inn_credit_total": total_credit,
        "inn_unbalanced_entries": unbalanced_count,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": de_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 22 Ustawy o rachunkowości (podwójny zapis)",
        "_warnings": [sprintf("⚖️ Wn/Ma AUTO-VALIDATOR: %s. Suma Wn=%.0f PLN, Suma Ma=%.0f PLN, Δ=%.2f PLN.",
            [de_status, total_debit, total_credit, diff])]
    }

    de_status := "✅ ZBILANSOWANE" { is_balanced }
    de_status := "❌ NIEZBILANSOWANE — sprawdź księgowania!" { not is_balanced }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INN-04: P33 — PCC+VAT Exclusion Firewall (Art. 2 pkt 4 PCC)
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.direction == "PURCHASE"
    not object.get(input.vendor, "is_company", true)
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    transaction_value := object.get(input.invoice, "amount_gross", 0)
    vat_rate := object.get(input.invoice, "vat_rate", 0)
    seller_is_vat_payer := object.get(input.vendor, "is_vat_payer", false)
    seller_vat_exempt_subjective := object.get(input.vendor, "vat_exempt_subjective", false)
    transaction_vat_applicable := object.get(input.invoice, "vat_applicable", false)

    pcc_applies := true { seller_vat_exempt_subjective }
    pcc_applies := true { not seller_is_vat_payer and not transaction_vat_applicable }
    pcc_applies := false { seller_is_vat_payer and vat_rate > 0 }
    pcc_applies := false { transaction_vat_applicable and vat_rate > 0 }

    pcc_2pct := floor(transaction_value * 0.02 * 100) / 100 { pcc_applies }
    pcc_2pct := 0 { not pcc_applies }

    fw_routing := "TRIAGE_QUEUE" { pcc_applies; pcc_2pct > 1000 }
    fw_routing := "" { not pcc_applies }
    fw_routing := "" { pcc_2pct <= 1000 }

    reason := sprintf("PCC vs VAT: PCC %.2f PLN. Sprzedawca zwolniony z VAT podmiotowo → PCC się należy!",
        [pcc_2pct]) { pcc_applies }
    reason := "Transakcja opodatkowana VAT → wyłączona z PCC (Art. 2 pkt 4)." { not pcc_applies }

    verdict := {
        "matched": true, "rule_id": "jdg.p3233_innovations.pcc_vat_firewall",
        "package": "jdg.p3233_innovations", "priority": 9604,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "inn_pcc_vat_pcc_applies": pcc_applies,
        "inn_pcc_vat_estimated_pcc": pcc_2pct,
        "inn_pcc_vat_seller_exempt": seller_vat_exempt_subjective,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": fw_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 2 pkt 4 Ustawy o PCC; Art. 113 Ustawy o VAT",
        "_warnings": [sprintf("🛡️ PCC-VAT FIREWALL: %s. Wartość transakcji=%.0f PLN. %s",
            [fw_scenario, transaction_value, fw_action])]
    }

    fw_scenario := "PCC SIĘ NALEŻY (sprzedawca zwolniony z VAT podmiotowo — Art. 113)" { seller_vat_exempt_subjective }
    fw_scenario := "PCC SIĘ NALEŻY (sprzedawca nie jest VAT-owcem)" { not seller_is_vat_payer; not seller_vat_exempt_subjective }
    fw_scenario := "WYŁĄCZONE z PCC (transakcja VAT)" { not pcc_applies }

    fw_action := sprintf("PCC 2%% = %.2f PLN — złóż PCC-3 w 14 dni!", [pcc_2pct]) { pcc_applies }
    fw_action := "" { not pcc_applies }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INN-05: P33 — GAAR Shield Advanced + Economic Substance Test
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    has_split := object.get(input.jdg_entrepreneur, "gaar_split_detected", false) or
        object.get(input.jdg_entrepreneur, "pcc_related_loans_count", 0) > 1
    has_artificial := object.get(input.jdg_entrepreneur, "gaar_artificial_structure", false)
    has_no_business_purpose := object.get(input.jdg_entrepreneur, "gaar_no_business_purpose", false)

    gaar_active := has_split or has_artificial or has_no_business_purpose
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    split_count := object.get(input.jdg_entrepreneur, "gaar_mpp_split_count", 0) + object.get(input.jdg_entrepreneur, "pcc_related_loans_count", 0)
    total_split := object.get(input.jdg_entrepreneur, "gaar_mpp_total_value", 0) + object.get(input.jdg_entrepreneur, "pcc_related_loans_total", 0)

    gaar_risk := "LOW" { not gaar_active }
    gaar_risk := "MEDIUM" { gaar_active; not has_no_business_purpose }
    gaar_risk := "HIGH" { gaar_active; has_no_business_purpose; total_split < 100000 }
    gaar_risk := "CRITICAL" { gaar_active; has_no_business_purpose; total_split >= 100000 }

    gaar_routing := "BLOCK_AND_ALERT" { gaar_risk == "CRITICAL" }
    gaar_routing := "TRIAGE_QUEUE" { gaar_risk == "HIGH" }
    gaar_routing := "WARNING" { gaar_risk == "MEDIUM" }
    gaar_routing := "" { gaar_risk == "LOW" }

    reason := sprintf("GAAR CRITICAL: %d transakcji na %.0f PLN BEZ celu biznesowego. Sankcja 40%% + MDR!",
        [split_count, total_split]) { gaar_risk == "CRITICAL" }
    reason := sprintf("GAAR HIGH: %d transakcji, %.0f PLN. Zweryfikuj business purpose.",
        [split_count, total_split]) { gaar_risk == "HIGH" }
    reason := "" { gaar_risk in {"LOW", "MEDIUM"} }

    verdict := {
        "matched": true, "rule_id": "jdg.p3233_innovations.gaar_shield_advanced",
        "package": "jdg.p3233_innovations", "priority": 9605,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "inn_gaar_active": gaar_active,
        "inn_gaar_risk_level": gaar_risk,
        "inn_gaar_split_count": split_count,
        "inn_gaar_total_value": total_split,
        "inn_gaar_no_business_purpose": has_no_business_purpose,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": gaar_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 119a OrdPU (GAAR); Art. 58d OrdPU (sankcja 40%)",
        "_warnings": [sprintf("🔍 GAAR SHIELD: Ryzyko=%s. %d transakcji podzielonych, łączna wartość=%.0f PLN. %s. %s",
            [gaar_risk, split_count, total_split, bp_note, action_note])]
    }

    bp_note := "BEZ celu biznesowego — GAAR wysokie ryzyko!" { has_no_business_purpose }
    bp_note := "Istnieje cel biznesowy." { not has_no_business_purpose }

    action_note := "Sankcja 40% + MDR + KKS Art. 54!" { gaar_risk == "CRITICAL" }
    action_note := "Przeanalizuj strukturę transakcji." { gaar_risk == "HIGH" }
    action_note := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INN-06: P32 — Czynny Żal Auto-Generator z check-listą
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    has_voluntary_disclosure := object.get(input.jdg_entrepreneur, "kks_active_contrition", false)
    needs_disclosure := object.get(input.jdg_entrepreneur, "kks_disclosure_needed", false)

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    # Check-list warunków skuteczności
    before_proceedings := object.get(input.jdg_entrepreneur, "kks_before_proceedings", false)
    full_disclosure := object.get(input.jdg_entrepreneur, "kks_full_disclosure", false)
    payment_7_days := object.get(input.jdg_entrepreneur, "kks_payment_within_7_days", false)
    all_offenses := object.get(input.jdg_entrepreneur, "kks_all_circumstances", false)

    conditions_met := [before_proceedings, full_disclosure, payment_7_days, all_offenses]
    met_count := count({x | x := conditions_met[_]; x == true})
    all_met := met_count == 4

    disclosure_routing := "BLOCK_AND_ALERT" { needs_disclosure; not has_voluntary_disclosure; before_proceedings }
    disclosure_routing := "TRIAGE_QUEUE" { needs_disclosure; not before_proceedings }
    disclosure_routing := "" { not needs_disclosure }
    disclosure_routing := "" { all_met }

    reason := "Czynny żal WYMAGANY — złóż PRZED wszczęciem postępowania!" { needs_disclosure; not has_voluntary_disclosure }
    reason := sprintf("Czynny żal: %d/4 warunków spełnionych. %s", [met_count, status_detail]) { has_voluntary_disclosure }
    reason := "" { true }

    verdict := {
        "matched": true, "rule_id": "jdg.p3233_innovations.active_contrition_checklist", "_legal_basis": "Art. 23 KKS; Art. 54 KKS (symulacja kary)",
        "package": "jdg.p3233_innovations", "priority": 9606,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "inn_contrition_active": has_voluntary_disclosure,
        "inn_contrition_conditions_met": met_count,
        "inn_contrition_all_met": all_met,
        "inn_contrition_checklist": {
            "przed_postepowaniem": before_proceedings,
            "pelne_ujawnienie": full_disclosure,
            "wplata_7_dni": payment_7_days,
            "wszystkie_okolicznosci": all_offenses
        },
        "business_status": "", "ceidg_registration_required": false,
        "_routing": disclosure_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 16 KKS (czynny żal — warunki skuteczności)",
        "_warnings": [sprintf("📝 CZYNNY ŻAL CHECK-LISTA: %d/4 warunków spełnionych. %s. %s. Termin: PRZED wszczęciem postępowania! Po kontroli = tylko nadzwyczajne złagodzenie.",
            [met_count, checklist_detail, instruction])]
    }

    checklist_detail := "PRZED postępowaniem=OK" { before_proceedings }
    checklist_detail := "⚠️ PO wszczęciu — tylko Art. 16a!" { not before_proceedings }

    status_detail := "WSZYSTKIE spełnione — pełna ochrona!" { all_met }
    status_detail := sprintf("Brakuje: %s", [concat(", ", missing)]) { not all_met }

    instruction := "Złóż zawiadomienie przez ePUAP + wpłać należność w 7 dni." { not all_met }
    instruction := "✅ Czynny żal SKUTECZNY — pełny immunitet karny." { all_met }
    missing := [] { all_met }
    missing := array.concat(missing, ["PRZED postępowaniem"]) { not before_proceedings }
    missing := array.concat(missing, ["pełnego ujawnienia"]) { not full_disclosure }
    missing := array.concat(missing, ["wpłaty w 7 dni"]) { not payment_7_days }
    missing := array.concat(missing, ["wszystkich okoliczności"]) { not all_offenses }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INN-07: P33 — Full Accounting Transition Auto-Pilot (PKPiR → UoR)
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    revenue_eur := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 0) / object.get(data.jdg.thresholds, "bounds", {"eur_pln": 4.5}).eur_pln
    needs_transition := revenue_eur >= 2000000 and not object.get(input.jdg_entrepreneur, "uses_uor", false)
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    transition_steps := [
        "1. REMANENT na 31.12 — spisz wszystkie aktywa i pasywa wg PKPiR",
        "2. WYCENA wg UoR Art. 28 — przecena z ceny nabycia na wartość rynkową/odzyskiwalną",
        "3. BILANS OTWARCIA na 01.01 — pierwszy zapis Wn/Ma",
        "4. PLAN KONT — minimum 5 klas (0-Majątek, 1-Środki, 2-Rozrachunki, 4-Koszty, 7-Przychody)",
        "5. AMORTYZACJA BILANSOWA ≠ PODATKOWA — dwie ewidencje!",
        "6. RMK — rozliczenia międzyokresowe kosztów (Art. 39 UoR)",
        "7. SPRAWOZDANIE FINANSOWE — Bilans + RZiS + Info dodatkowa (do 31.03)",
        "8. ZGŁOSZENIE do US — CEIDG-1 + NIP-2 (zmiana formy księgowości)"
    ] { needs_transition }
    transition_steps := [] { not needs_transition }

    trans_routing := "BLOCK_AND_ALERT" { needs_transition }
    trans_routing := "" { not needs_transition }

    reason := sprintf("PRZEJŚCIE PKPiR→UoR: Przychód %.0f EUR ≥ 2M EUR. Obowiązkowe od 01.01!",
        [revenue_eur]) { needs_transition }

    verdict := {
        "matched": true, "rule_id": "jdg.p3233_innovations.uor_transition_pilot",
        "package": "jdg.p3233_innovations", "priority": 9607,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "inn_uor_transition_needed": needs_transition,
        "inn_uor_revenue_eur": revenue_eur,
        "inn_uor_threshold_eur": 2000000,
        "inn_uor_transition_steps": transition_steps,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": trans_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 2 UoR; Art. 24a PIT (przejście PKPiR→księgi)",
        "_warnings": [sprintf("🔄 PKPiR→UoR AUTO-PILOT: Przychód=%.0f EUR. Próg=2M EUR. %s. Kroków do wykonania: %d.",
            [revenue_eur, trans_status, count(transition_steps)])]
    }

    trans_status := "⚠️ PRZEJŚCIE WYMAGANE!" { needs_transition }
    trans_status := "✅ PKPiR wystarczające." { not needs_transition }
}
