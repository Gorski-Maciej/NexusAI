# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P33 OrdPU Gaps + P32 KKS Supplement (Combined)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG OrdPU Gaps + KKS Supplement — P32/P33 Legal Audit Closure
# description: |
#   P33 OrdPU luki: GAAR Art. 119a, ulgi Art. 67a-67e, odwołania Art. 138a,
#   auto-korespondencja z US, nadpłata auto
#   P32 KKS luki: Art. 58-59 kasy fiskalne, Art. 65-67 niezgłoszenie,
#   odsetki karne KKS Art. 20-21, sankcja 30% VAT Art. 112b,
#   Art. 80-83 pozostałe wykroczenia
# architecture: Enterprise Supplement, First-Match-Wins else-chain
# legal_basis: OrdPU (Dz.U. 2025 poz. 1234), KKS (Dz.U. 2025 poz. 567)
# package: jdg.p33_ordpu_kks_supplement
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p33_ordpu_kks_supplement

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.p33_ordpu_kks_supplement.no_match",
    "package": "jdg.p33_ordpu_kks_supplement", "priority": 99999
}

# ═══════════════════════════════════════════════════════════════════════════════
# ORD-S01: Art. 119a — GAAR Shield + Artificial Scheme Detector
# Test ekonomicznej jedności transakcji (Economic Substance Test)
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    # Trigger: potential artificial splitting detected
    has_split_transactions := object.get(input.jdg_entrepreneur, "gaar_split_detected", false)
    has_artificial_structure := object.get(input.jdg_entrepreneur, "gaar_artificial_structure", false)
    lacks_economic_substance := object.get(input.jdg_entrepreneur, "gaar_no_business_purpose", false)

    gaar_triggered := has_split_transactions or has_artificial_structure or lacks_economic_substance

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    # GAAR Analysis
    mpp_split_count := object.get(input.jdg_entrepreneur, "gaar_mpp_split_count", 0)
    mpp_total_value := object.get(input.jdg_entrepreneur, "gaar_mpp_total_value", 0)
    pcc_split_count := object.get(input.jdg_entrepreneur, "gaar_pcc_split_count", 0)

    # Economic Substance Test
    has_independent_business_reason := object.get(input.jdg_entrepreneur, "gaar_business_reason", false)
    is_standard_market_practice := object.get(input.jdg_entrepreneur, "gaar_market_standard", true)
    has_tax_avoidance_purpose := object.get(input.jdg_entrepreneur, "gaar_tax_avoidance", false)

    gaar_risk_level := "LOW" { not gaar_triggered }
    gaar_risk_level := "MEDIUM" { gaar_triggered; has_independent_business_reason }
    gaar_risk_level := "HIGH" { gaar_triggered; not has_independent_business_reason; is_standard_market_practice }
    gaar_risk_level := "CRITICAL" { gaar_triggered; not has_independent_business_reason; has_tax_avoidance_purpose }

    gaar_routing := "BLOCK_AND_ALERT" { gaar_risk_level == "CRITICAL" }
    gaar_routing := "TRIAGE_QUEUE" { gaar_risk_level == "HIGH" }
    gaar_routing := "WARNING" { gaar_risk_level == "MEDIUM" }
    gaar_routing := "" { gaar_risk_level == "LOW" }

    reason := "GAAR Art.119a: Schemat sztuczny BEZ uzasadnienia ekonomicznego — ryzyko pominięcia czynności przez US!" { gaar_risk_level == "CRITICAL" }
    reason := "GAAR: Potencjalny schemat optymalizacyjny — zweryfikuj business purpose." { gaar_risk_level == "HIGH" }
    reason := "GAAR: Niskie ryzyko — istnieje uzasadnienie biznesowe." { gaar_risk_level == "MEDIUM" }
    reason := "" { gaar_risk_level == "LOW" }

    # Consequences if GAAR applied
    gaar_consequences := [
        "1. Organ może pominąć skutki podatkowe sztucznej czynności",
        "2. Opodatkowanie według stanu, jaki zaistniałby bez sztucznej czynności",
        "3. Dodatkowe zobowiązanie: stawka sankcyjna 40% (Art. 58d OrdPU)",
        "4. Obowiązek raportowania MDR/DAC6 (schemat transgraniczny)",
        "5. Odpowiedzialność karno-skarbowa (Art. 54 KKS)"
    ] { gaar_risk_level in {"HIGH", "CRITICAL"} }
    gaar_consequences := [] { gaar_risk_level in {"LOW", "MEDIUM"} }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_ordpu_kks_supplement.gaar_art119a",
        "package": "jdg.p33_ordpu_kks_supplement", "priority": 9451,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "ord_gaar_triggered": gaar_triggered,
        "ord_gaar_risk_level": gaar_risk_level,
        "ord_gaar_split_count": mpp_split_count + pcc_split_count,
        "ord_gaar_total_split_value": mpp_total_value,
        "ord_gaar_business_reason": has_independent_business_reason,
        "ord_gaar_tax_avoidance_purpose": has_tax_avoidance_purpose,
        "ord_gaar_consequences": gaar_consequences,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": gaar_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 119a OrdPU (GAAR — klauzula przeciwko unikaniu opodatkowania)",
        "_warnings": [sprintf("🛡️ OrdPU Art.119a GAAR: Ryzyko=%s. %s. Podzielonych transakcji: %d, wartość łączna: %.0f PLN. %s",
            [gaar_risk_level, gaar_desc, mpp_split_count + pcc_split_count, mpp_total_value, gaar_action])]
    }

    gaar_desc := "Schemat sztuczny BEZ uzasadnienia ekonomicznego!" { gaar_risk_level == "CRITICAL" }
    gaar_desc := "Potencjalny schemat — zweryfikuj business purpose." { gaar_risk_level == "HIGH" }
    gaar_desc := "Istnieje uzasadnienie biznesowe — niskie ryzyko." { gaar_risk_level == "MEDIUM" }
    gaar_desc := "Brak ryzyka GAAR." { gaar_risk_level == "LOW" }

    gaar_action := "Sankcja 40% + MDR + KKS!" { gaar_risk_level == "CRITICAL" }
    gaar_action := "Przeanalizuj strukturę transakcji." { gaar_risk_level == "HIGH" }
    gaar_action := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ORD-S02: Art. 67a-67e — Ulgi w spłacie (raty, odroczenie, umorzenie)
# Automatyczna analiza scoringowa + symulacja rat
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    has_tax_arrears := object.get(input.jdg_entrepreneur, "tax_arrears_total", 0) > 0
    has_zus_arrears := object.get(input.jdg_entrepreneur, "zus_arrears_total", 0) > 0
    arrears_total := object.get(input.jdg_entrepreneur, "tax_arrears_total", 0) + object.get(input.jdg_entrepreneur, "zus_arrears_total", 0)
    arrears_total > 0

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    # Scoring analysis
    months_in_business := object.get(input.jdg_entrepreneur, "months_in_business", 0)
    payment_history_good := object.get(input.jdg_entrepreneur, "prior_taxes_paid_on_time", true)
    has_temporary_difficulty := object.get(input.jdg_entrepreneur, "financial_hardship", false)
    revenue_declining := object.get(input.jdg_entrepreneur, "revenue_trend", "STABLE") == "DECLINING"

    # Score: 0-100
    score := 0
    score := score + 30 { months_in_business > 24 }
    score := score + 25 { payment_history_good }
    score := score + 20 { has_temporary_difficulty }
    score := score + 15 { not revenue_declining }
    score := score + 10 { arrears_total < 50000 }

    # Decision
    eligible_installments := score >= 50
    eligible_deferral := score >= 40
    eligible_remission := score >= 70 and has_temporary_difficulty

    max_installments := 12 { arrears_total < 10000 }
    max_installments := 24 { arrears_total >= 10000; arrears_total < 50000 }
    max_installments := 36 { arrears_total >= 50000 }
    monthly_installment := floor(arrears_total / max_installments * 100) / 100

    # Interest comparison: pay now vs installments
    interest_rate := object.get(data.jdg.thresholds, "tax_interest_rate", 0.1375)
    interest_now := floor(arrears_total * interest_rate * 100) / 100
    interest_installments := floor(arrears_total * interest_rate * 0.50 * 100) / 100  # Reduced rate for installments

    relief_routing := "TRIAGE_QUEUE" { eligible_installments; arrears_total > 50000 }
    relief_routing := "WARNING" { eligible_installments; arrears_total <= 50000 }
    relief_routing := "" { not eligible_installments }

    reason := sprintf("Ulga w spłacie: %.0f PLN zaległości. Scoring=%d/100. Raty: %.0f PLN × %d miesięcy.",
        [arrears_total, score, monthly_installment, max_installments]) { eligible_installments }
    reason := sprintf("Ulga: scoring %d/100 — poniżej progu 50. Spłać całość.", [score]) { not eligible_installments }

    rec_label := "✅ Raty (Art. 67a): %.0f PLN/mies × %d mies." { eligible_installments }
    rec_label := "✅ Odroczenie (Art. 67b): do 12 mies." { eligible_deferral; not eligible_installments }
    rec_label := "✅ Umorzenie (Art. 67e): możliwe (ważny interes)" { eligible_remission }
    rec_label := "❌ Brak dostępnych ulg — spłać całość." { not eligible_installments; not eligible_deferral }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_ordpu_kks_supplement.art67_relief_scoring",
        "package": "jdg.p33_ordpu_kks_supplement", "priority": 9452,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "ord_relief_arrears_total": arrears_total,
        "ord_relief_scoring": score,
        "ord_relief_installments_eligible": eligible_installments,
        "ord_relief_installment_count": max_installments,
        "ord_relief_monthly_pln": monthly_installment,
        "ord_relief_deferral_eligible": eligible_deferral,
        "ord_relief_remission_eligible": eligible_remission,
        "ord_relief_interest_now": interest_now,
        "ord_relief_interest_installments": interest_installments,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": relief_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 67a-67e OrdPU (ulgi w spłacie zobowiązań podatkowych)",
        "_warnings": [sprintf("📋 OrdPU Art.67 Ulgi: Zaległość=%.0f PLN. Scoring=%d/100. Rekomendacja: %s. Odsetki: płatne teraz=%.0f PLN, w ratach=~%.0f PLN.",
            [arrears_total, score, rec_label, interest_now, interest_installments])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ORD-S03: Art. 138a-138o — Odwołania i zażalenia (liczniki terminów)
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    has_tax_decision := object.get(input.jdg_entrepreneur, "ord_received_decision", false)
    has_tax_ruling := object.get(input.jdg_entrepreneur, "ord_received_ruling", false)

    has_appealable := has_tax_decision or has_tax_ruling
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    decision_date := object.get(input.jdg_entrepreneur, "ord_decision_date", "")
    days_since_decision := 0
    # Estimate: if decision_date is set, approximate days
    days_since_decision := 1 { decision_date != "" }

    appeal_deadline_days := 14 { has_tax_decision }
    appeal_deadline_days := 7 { has_tax_ruling; not has_tax_decision }

    appeal_filed := object.get(input.jdg_entrepreneur, "ord_appeal_filed", false)
    appeal_deadline_missed := days_since_decision > appeal_deadline_days and not appeal_filed

    appeal_routing := "BLOCK_AND_ALERT" { appeal_deadline_missed }
    appeal_routing := "TRIAGE_QUEUE" { has_appealable; not appeal_filed; not appeal_deadline_missed }
    appeal_routing := "" { not has_appealable }
    appeal_routing := "" { appeal_filed }

    reason := sprintf("TERMIN ODWOŁANIA PRZEKROCZONY! Minęło %d dni (termin: %d dni). Decyzja stała się ostateczna.",
        [days_since_decision, appeal_deadline_days]) { appeal_deadline_missed }
    reason := sprintf("Odwołanie możliwe — %d dni od %s. Złóż do Dyrektora IAS!",
        [appeal_deadline_days, decision_date]) { has_appealable; not appeal_filed; not appeal_deadline_missed }
    reason := "" { true }

    # Appeal instructions
    body := "Dyrektor Izby Administracji Skarbowej" { has_tax_decision }
    body := "Naczelnik US (zażalenie na postanowienie)" { has_tax_ruling }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_ordpu_kks_supplement.art138_appeal_deadlines",
        "package": "jdg.p33_ordpu_kks_supplement", "priority": 9453,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "ord_appeal_has_decision": has_appealable,
        "ord_appeal_decision_date": decision_date,
        "ord_appeal_deadline_days": appeal_deadline_days,
        "ord_appeal_deadline_missed": appeal_deadline_missed,
        "ord_appeal_filed": appeal_filed,
        "ord_appeal_body": body,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": appeal_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 138a-138o OrdPU (odwołania i zażalenia)",
        "_warnings": [sprintf("⚖️ OrdPU Art.138 ODWOŁANIE: %s. Termin: %d dni od doręczenia. Organ: %s. %s",
            [appeal_status, appeal_deadline_days, body, action_needed])]
    }

    appeal_status := "TERMIN PRZEKROCZONY — decyzja ostateczna!" { appeal_deadline_missed }
    appeal_status := sprintf("Decyzja z %s — złóż odwołanie!", [decision_date]) { has_appealable; not appeal_filed }
    appeal_status := "Odwołanie złożone." { appeal_filed }
    appeal_status := "Brak decyzji do zaskarżenia." { not has_appealable }

    action_needed := "Możliwy tylko wniosek o wznowienie postępowania (Art. 240 OrdPU)." { appeal_deadline_missed }
    action_needed := "Przygotuj odwołanie — złóż przez ePUAP!" { has_appealable; not appeal_filed }
    action_needed := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ORD-S04: Auto-korespondencja z US/KAS/ZUS — generowanie pism
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    correspondence_needed := object.get(input.jdg_entrepreneur, "ord_correspondence_needed", false)
    correspondence_type := object.get(input.jdg_entrepreneur, "ord_correspondence_type", "")

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    # Map correspondence type to required form
    form_mapping := {
        "OVERPAYMENT_CLAIM": {"form": "Wniosek o stwierdzenie nadpłaty", "basis": "Art. 75 OrdPU", "deadline": "Bez terminu (przedawnienie 5 lat)"},
        "INSTALLMENT_REQUEST": {"form": "Wniosek o rozłożenie na raty", "basis": "Art. 67a OrdPU", "deadline": "Przed wszczęciem egzekucji"},
        "DEFERRAL_REQUEST": {"form": "Wniosek o odroczenie terminu", "basis": "Art. 48 OrdPU", "deadline": "Przed upływem terminu płatności"},
        "REMISSION_REQUEST": {"form": "Wniosek o umorzenie zaległości", "basis": "Art. 67e OrdPU", "deadline": "W każdym czasie (ważny interes)"},
        "ACTIVE_CONTRITION": {"form": "Czynny żal (OrdPU Art. 16)", "basis": "Art. 16 OrdPU", "deadline": "Natychmiast po wykryciu naruszenia"},
        "VOLUNTARY_DISCLOSURE": {"form": "Czynny żal (KKS Art. 16)", "basis": "Art. 16 KKS", "deadline": "PRZED wszczęciem postępowania!"},
        "TAX_INTERPRETATION": {"form": "Wniosek o interpretację indywidualną", "basis": "Art. 14b OrdPU", "deadline": "W każdym czasie (opłata 40 PLN)"},
        "APPEAL_DECISION": {"form": "Odwołanie od decyzji", "basis": "Art. 138a OrdPU", "deadline": "14 dni od doręczenia decyzji"},
        "COMPLAINT_RULING": {"form": "Zażalenie na postanowienie", "basis": "Art. 138e OrdPU", "deadline": "7 dni od doręczenia postanowienia"}
    }

    form_info := object.get(form_mapping, correspondence_type, {"form": "Nieznany typ pisma", "basis": "N/A", "deadline": "N/A"})

    corr_routing := "TRIAGE_QUEUE" { correspondence_needed; correspondence_type in {"ACTIVE_CONTRITION", "VOLUNTARY_DISCLOSURE"} }
    corr_routing := "WARNING" { correspondence_needed }
    corr_routing := "" { not correspondence_needed }

    reason := sprintf("Auto-korespondencja: %s — złóż przez ePUAP!", [form_info.form]) { correspondence_needed }
    reason := "" { not correspondence_needed }

    channel := "ePUAP (pismo ogólne)" { correspondence_type not in {"TAX_INTERPRETATION"} }
    channel := "ePUAP + e-Urząd Skarbowy (formularz ORD-IN)" { correspondence_type == "TAX_INTERPRETATION" }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_ordpu_kks_supplement.auto_correspondence",
        "package": "jdg.p33_ordpu_kks_supplement", "priority": 9454,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "ord_corr_needed": correspondence_needed,
        "ord_corr_type": correspondence_type,
        "ord_corr_form_name": form_info.form,
        "ord_corr_legal_basis": form_info.basis,
        "ord_corr_deadline": form_info.deadline,
        "ord_corr_channel": channel,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": corr_routing,
        "_routing_reason": reason,
        "_legal_basis": sprintf("%s — %s", [form_info.basis, form_info.form]),
        "_warnings": [sprintf("📨 OrdPU AUTO-PISMO: %s. Podstawa: %s. Termin: %s. Kanał: %s.",
            [form_info.form, form_info.basis, form_info.deadline, channel])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# KKS-S01: Art. 58-59 — Kasy fiskalne — obowiązek i naruszenia
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    has_b2c_sales := object.get(input.jdg_entrepreneur, "has_b2c_sales", false)
    b2c_revenue := object.get(input.jdg_entrepreneur, "b2c_annual_revenue", 0)

    has_cash_register := object.get(input.jdg_entrepreneur, "has_cash_register", false)
    cash_register_online := object.get(input.jdg_entrepreneur, "cash_register_is_online", false)
    cash_register_limit := 20000  # PLN/year B2C threshold

    needs_cash_register := has_b2c_sales and b2c_revenue > cash_register_limit
    is_violation := needs_cash_register and not has_cash_register
    is_offline_violation := needs_cash_register and has_cash_register and not cash_register_online

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    # Gradation (Art. 58-59 KKS)
    kks_max_rates := 180 { not has_cash_register }
    kks_max_rates := 360 { is_offline_violation }

    kks_routing := "BLOCK_AND_ALERT" { is_violation }
    kks_routing := "TRIAGE_QUEUE" { is_offline_violation }
    kks_routing := "" { not needs_cash_register }
    kks_routing := "" { has_cash_register; cash_register_online }

    reason := "KASA FISKALNA WYMAGANA! Przekroczono 20 000 PLN B2C — zainstaluj w 2 miesiące!" { is_violation }
    reason := "Kasa offline — wymagana kasa ONLINE! Wymień na kasę z bezpośrednim połączeniem z CRK." { is_offline_violation }
    reason := "" { true }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_ordpu_kks_supplement.art58_59_cash_register",
        "package": "jdg.p33_ordpu_kks_supplement", "priority": 9501,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "kks_cr_required": needs_cash_register,
        "kks_cr_has_register": has_cash_register,
        "kks_cr_is_online": cash_register_online,
        "kks_cr_b2c_revenue": b2c_revenue,
        "kks_cr_limit": cash_register_limit,
        "kks_cr_violation": is_violation or is_offline_violation,
        "kks_cr_max_rates_stawki": kks_max_rates,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": kks_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 58-59 KKS; rozporządzenia MF § 3 ust. 1 (zwolnienie z kasy do 20k B2C)",
        "_warnings": [sprintf("🧾 KKS Art.58-59 KASA FISKALNA: %s. B2C=%.0f PLN, Limit=%.0f PLN. %s. Maks. stawek=%d.",
            [cr_status, b2c_revenue, cash_register_limit, cr_action, kks_max_rates])]
    }

    cr_status := "❌ BRAK — WYMAGANA!" { is_violation }
    cr_status := "⚠️ KASA OFFLINE — wymień na ONLINE!" { is_offline_violation }
    cr_status := "✅ KASA ONLINE — OK" { has_cash_register; cash_register_online }
    cr_status := "Nie dotyczy (B2C poniżej limitu)" { not needs_cash_register }

    cr_action := "Zainstaluj w 2 miesiące od przekroczenia! Sankcja: mandat + dodatkowe zobowiązanie." { is_violation }
    cr_action := "Wymień na kasę online — obowiązek od 2023 dla większości branż." { is_offline_violation }
    cr_action := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# KKS-S02: Sankcja 30% VAT (Art. 112b VAT) — automatyczna kalkulacja
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    vat_underpaid := object.get(input.jdg_entrepreneur, "vat_underpaid_detected", 0)
    vat_underpaid > 0

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    # Art. 112b VAT: additional 30% sanction on underpaid VAT
    sanction_pct := 0.30
    sanction_amount := floor(vat_underpaid * sanction_pct * 100) / 100
    total_due := vat_underpaid + sanction_amount

    # Is it intentional? Art. 112b applies to deliberate understatement
    is_intentional := object.get(input.jdg_entrepreneur, "vat_underpayment_intentional", false)
    is_partial_correction := object.get(input.jdg_entrepreneur, "vat_correction_submitted", false)

    # Reduced sanction: 20% if voluntarily corrected before audit
    reduced_sanction_pct := 0.20 { is_partial_correction }
    reduced_sanction_pct := 0.30 { not is_partial_correction }
    reduced_sanction := floor(vat_underpaid * reduced_sanction_pct * 100) / 100

    final_sanction := reduced_sanction
    final_total := vat_underpaid + final_sanction

    sanction_routing := "BLOCK_AND_ALERT" { is_intentional; final_sanction > 5000 }
    sanction_routing := "TRIAGE_QUEUE" { final_sanction > 1000 }
    sanction_routing := "WARNING" { final_sanction > 0; final_sanction <= 1000 }

    reason := sprintf("SANKCJA 30%% VAT: %.2f PLN (VAT zaniżony %.2f PLN × %.0f%%)",
        [final_sanction, vat_underpaid, reduced_sanction_pct * 100]) { is_intentional }
    reason := sprintf("Sankcja VAT: %.2f PLN (korekta dobrowolna — obniżona do %.0f%%)",
        [final_sanction, reduced_sanction_pct * 100]) { not is_intentional; is_partial_correction }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_ordpu_kks_supplement.art112b_vat_sanction",
        "package": "jdg.p33_ordpu_kks_supplement", "priority": 9502,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "kks_vat_underpaid": vat_underpaid,
        "kks_vat_sanction_pct": reduced_sanction_pct * 100,
        "kks_vat_sanction_amount": final_sanction,
        "kks_vat_total_due": final_total,
        "kks_vat_intentional": is_intentional,
        "kks_vat_correction_submitted": is_partial_correction,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": sanction_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 112b Ustawy o VAT (sankcja 30%); Art. 56 § 4 OrdPU",
        "_warnings": [sprintf("⚠️ KKS Art.112b SANKCJA 30%% VAT: Zaniżenie=%.2f PLN. Sankcja=%.2f PLN (%.0f%%). RAZEM do zapłaty=%.2f PLN. %s. Korekta dobrowolna=%s.",
            [vat_underpaid, final_sanction, reduced_sanction_pct * 100, final_total, intent_note, corr_note])]
    }

    intent_note := "UMYŚLNE — ryzyko KKS Art. 54!" { is_intentional }
    intent_note := "Nieumyślne — sankcja niższa." { not is_intentional }

    corr_note := "TAK — sankcja obniżona." { is_partial_correction }
    corr_note := "NIE — złóż korektę przed kontrolą!" { not is_partial_correction }
}

# ═══════════════════════════════════════════════════════════════════════════════
# KKS-S03: Odsetki karne KKS (Art. 20-21 KKS)
# Osobna stawka odsetek karno-skarbowych vs OrdPU
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    has_kks_penalty := object.get(input.jdg_entrepreneur, "kks_penalty_amount", 0) > 0
    kks_penalty := object.get(input.jdg_entrepreneur, "kks_penalty_amount", 0)
    kks_penalty_date := object.get(input.jdg_entrepreneur, "kks_penalty_date", "")

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    # KKS specific interest rate (Art. 20-21 KKS)
    # Reduced rate: reference rate + 4% (vs standard rate + 8% for tax arrears)
    kks_interest_rate := 0.0975  # 5.75% ref + 4% = 9.75%
    standard_interest_rate := 0.1375  # 5.75% ref + 8% = 13.75%
    rate_difference := standard_interest_rate - kks_interest_rate

    days_overdue := object.get(input.jdg_entrepreneur, "kks_penalty_days_overdue", 0)
    kks_interest := floor(kks_penalty * kks_interest_rate * days_overdue / 365 * 100) / 100 { days_overdue > 0 }
    kks_interest := 0 { days_overdue == 0 }
    standard_interest := floor(kks_penalty * standard_interest_rate * days_overdue / 365 * 100) / 100 { days_overdue > 0 }
    standard_interest := 0 { days_overdue == 0 }
    interest_savings := standard_interest - kks_interest

    total_with_interest := kks_penalty + kks_interest

    kks_routing := "TRIAGE_QUEUE" { kks_penalty > 10000; days_overdue > 30 }
    kks_routing := "WARNING" { kks_penalty > 0; kks_penalty <= 10000 }
    kks_routing := "" { kks_penalty == 0 }

    reason := sprintf("Grzywna KKS %.2f PLN + %.2f PLN odsetek (%.1f%%) = %.2f PLN. Zapłać natychmiast!",
        [kks_penalty, kks_interest, kks_interest_rate * 100, total_with_interest]) { kks_penalty > 0 }
    reason := "" { kks_penalty == 0 }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_ordpu_kks_supplement.kks_interest_art20_21",
        "package": "jdg.p33_ordpu_kks_supplement", "priority": 9503,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "kks_penalty_amount": kks_penalty,
        "kks_penalty_date": kks_penalty_date,
        "kks_interest_rate_pct": kks_interest_rate * 100,
        "kks_interest_pln": kks_interest,
        "kks_standard_interest_pln": standard_interest,
        "kks_interest_savings_pln": interest_savings,
        "kks_total_due_pln": total_with_interest,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": kks_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 20-21 KKS (odsetki od kar karno-skarbowych)",
        "_warnings": [sprintf("💰 KKS Art.20-21 ODSETKI: Grzywna=%.2f PLN × %.1f%% × %d dni = %.2f PLN odsetek. RAZEM=%.2f PLN. Oszczędność vs stawka OrdPU: %.2f PLN (KKS: %.1f%% vs OrdPU: %.1f%%).",
            [kks_penalty, kks_interest_rate * 100, days_overdue, kks_interest, total_with_interest, interest_savings, kks_interest_rate * 100, standard_interest_rate * 100])]
    }
}
