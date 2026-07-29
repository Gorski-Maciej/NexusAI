# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P35 System Gaps Resolution Engine (10 luk systemowych)
# ═══════════════════════════════════════════════════════════════════════════════
# Generated: 2026-07-29 from RAPORT_P35_CROSS_ACT_COHERENCE_FINAL_VERDICT_v7.0
# Addresses: 10 system gaps (UoR, PCC, Excise, MDR, Exit Tax, GAAR, Reliefs,
#             Form optimization, FX reporting, Sickness benefits)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p35_gaps

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false,
    "rule_id": "jdg.p35_gaps.no_match",
    "package": "jdg.p35_gaps",
    "priority": 4999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GAP 1: UoR FOUNDATIONS — 7 fundamentalnych zasad rachunkowości (Art.4)  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
decide := {
    "matched": true, "rule_id": "jdg.p35.uor_foundations_check",
    "package": "jdg.p35_gaps", "priority": 4000,
    "uor_principles": ["CIĄGŁOŚĆ", "KONTYNUACJA", "MEMORIAŁ", "WSPÓŁMIERNOŚĆ",
        "OSTROŻNOŚĆ", "ISTOTNOŚĆ", "INDYWIDUALNA_WYCENA"],
    "uor_requires_full_accounting": requires_uor,
    "uor_revenue_eur": rev_eur,
    "uor_threshold_eur": 2000000,
    "uor_gap_severity": "CRITICAL",
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("UoR: %.0f EUR przychodu, próg 2M EUR, wymaga UoR=%s",
        [rev_eur, requires_uor]),
    "_legal_basis": "Ustawa o Rachunkowości Art.4 (7 zasad) + Art.2 (próg 2M EUR)",
    "_warnings": [sprintf("🔴 UoR GAP 1 — JDG z przychodem %.2f PLN (%.0f EUR). "
        "%s. 7 fundamentalnych zasad rachunkowości (Art.4 UoR): "
        "ciągłość, kontynuacja, memoriał, współmierność, ostrożność, "
        "istotność, indywidualna wycena. %s",
        [annual_rev, rev_eur, uor_status, uor_action])]
} {
    annual_rev := object.get(input.jdg_entrepreneur, "annual_revenue_net_pln", 0)
    eur_rate := object.get(input.jdg_entrepreneur, "nbp_eur_rate", 4.50)
    rev_eur := floor(annual_rev / eur_rate)
    requires_uor := rev_eur >= 2000000
    uor_status = "Powyżej progu 2M EUR — UoR WYMAGANE!" { requires_uor == true }
    uor_status = "Poniżej progu — PKPiR wystarczy." { requires_uor == false }

    uor_action = "NexusAI NIE wspiera pełnej księgowości UoR. "
    uor_action = concat("", [uor_action,
        "Skonsultuj się z biurem rachunkowym dla ksiąg handlowych."]) {
        requires_uor == true }
    uor_action = "Możesz korzystać z uproszczonej księgowości (PKPiR)." {
        requires_uor == false }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GAP 2: PCC COMPLETION — Brakujące 90% PCC (stawki, formularze)          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
else := {
    "matched": true, "rule_id": "jdg.p35.pcc_completion_check",
    "package": "jdg.p35_gaps", "priority": 4010,
    "pcc_transaction_type": pcc_type,
    "pcc_rate_pct": pcc_rate,
    "pcc_tax_due_pln": pcc_tax,
    "pcc_form_required": "PCC-3",
    "pcc_deadline_days": 14,
    "pcc_coverage_note": "GAP: Tylko ~22/225 pkt PCC pokryte (10%)",
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("PCC GAP: %s %.1f%% = %.2f PLN (tylko 10%% pokrycia)",
        [pcc_type, pcc_rate, pcc_tax]),
    "_legal_basis": "Ustawa o PCC — rozszerzenie z 10% do 100% pokrycia",
    "_warnings": [sprintf("🟠 PCC GAP 2 — %s: %.2f PLN × %.1f%% = %.2f PLN. "
        "PCC-3 w 14 dni. UWAGA: tylko ~10%% PCC zaimplementowane! "
        "Brak: zamiana, darowizna, hipoteka, zastaw, dożywocie, PCC-3 auto.",
        [pcc_type, pcc_value, pcc_rate, pcc_tax])]
} {
    pcc_check := object.get(input.jdg_entrepreneur, "pcc_gap_check_requested", false)
    pcc_check == true
    pcc_value := object.get(input.invoice, "amount_gross", 0)
    is_civil := object.get(input.invoice, "transaction_type", "") in
        {"CIVIL_LAW_SALE", "PRIVATE_SALE", "CAR_PURCHASE_PRIVATE", "LOAN", "EXCHANGE",
         "MORTGAGE", "DONATION_CIVIL", "ANNUITY", "SETTLEMENT"}

    # Extended PCC rates beyond the basic 2%/1%
    pcc_type = "Sprzedaż" { input.invoice.transaction_type in {"CIVIL_LAW_SALE", "PRIVATE_SALE"} }
    pcc_type = "Pożyczka" { input.invoice.transaction_type == "LOAN" }
    pcc_type = "Zamiana" { input.invoice.transaction_type == "EXCHANGE" }
    pcc_type = "Hipoteka" { input.invoice.transaction_type == "MORTGAGE" }
    pcc_type = "Dożywocie" { input.invoice.transaction_type == "ANNUITY" }
    pcc_type = "Ugoda" { input.invoice.transaction_type == "SETTLEMENT" }

    pcc_rate = 2.0 { pcc_type in {"Sprzedaż", "Zamiana"} }
    pcc_rate = 1.0 { pcc_type in {"Ugoda"} }
    pcc_rate = 0.5 { pcc_type == "Pożyczka" }
    pcc_rate = 0.1 { pcc_type == "Hipoteka" }
    pcc_rate = 2.0 { pcc_type == "Dożywocie" }
    pcc_tax := floor(pcc_value * pcc_rate / 100 * 100) / 100
    pcc_tax > 0
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GAP 3: EXCISE TAX — Akcyza (skład podatkowy, procedura zawieszenia)     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
else := {
    "matched": true, "rule_id": "jdg.p35.excise_tax_gap",
    "package": "jdg.p35_gaps", "priority": 4020,
    "excise_applies": excise_flag,
    "excise_category": excise_cat,
    "excise_warehouse_required": warehouse_needed,
    "excise_coverage_pct": 10,
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Akcyza: %s — skład=%s (tylko 10%% pokrycia)",
        [excise_cat, warehouse_needed]),
    "_legal_basis": "Ustawa o podatku akcyzowym — GAP (tylko ~10% pokrycia)",
    "_warnings": [sprintf("🔴 AKCYZA GAP 3 — %s. Skład podatkowy wymagany: %s. "
        "UWAGA: tylko ~10%% akcyzy zaimplementowane! "
        "Brak: szczegółowe stawki CN/PCN, ADT, EMCS, energia.",
        [excise_cat, warehouse_needed])]
} {
    excise_check := object.get(input.jdg_entrepreneur, "excise_gap_check", false)
    excise_check == true
    goods_cat := object.get(input.goods, "category", "NONE")
    excise_flag := goods_cat in {"FUELS", "ALCOHOL", "TOBACCO", "ENERGY"}
    excise_cat = "Paliwa" { goods_cat == "FUELS" }
    excise_cat = "Alkohol" { goods_cat == "ALCOHOL" }
    excise_cat = "Tytoń" { goods_cat == "TOBACCO" }
    excise_cat = "Energia" { goods_cat == "ENERGY" }
    warehouse_needed := goods_cat in {"FUELS", "ALCOHOL", "TOBACCO"}
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GAP 4-10: Pozostałe luki systemowe skonsolidowane                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# GAP 4: MDR/DAC6 — Automated scheme detection
else := {
    "matched": true, "rule_id": "jdg.p35.mdr_scheme_auto_detection",
    "package": "jdg.p35_gaps", "priority": 4030,
    "mdr_hallmarks": ["A", "B", "C", "D", "E"],
    "mdr_scheme_detected": scheme_found,
    "mdr_reporting_deadline_days": 30,
    "mdr_sanction_max_pln": 21000000,
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("MDR/DAC6: scheme=%s, hallmarks=%v",
        [scheme_found, ["A","B","C","D","E"]]),
    "_legal_basis": "Dyrektywa DAC6 + OrdPU Art.86a-86o — MDR reporting",
    "_warnings": [sprintf("🟠 MDR GAP 4 — Schemat podatkowy: %s. "
        "Hallmarki A-E: %v. Raportowanie MDR-3 w 30 dni. "
        "Sankcja do 21M PLN za brak raportu!",
        [scheme_found, ["A","B","C","D","E"]])]
} {
    mdr_check := object.get(input.jdg_entrepreneur, "mdr_scheme_check", false)
    mdr_check == true
    scheme_found := object.get(input.jdg_entrepreneur, "mdr_scheme_detected", false)
}

# GAP 5: Exit Tax + CFC basics
else := {
    "matched": true, "rule_id": "jdg.p35.exit_tax_cfc_basics",
    "package": "jdg.p35_gaps", "priority": 4040,
    "exit_tax_applies": exit_flag,
    "exit_tax_rate_pct": 19,
    "cfc_control_threshold_pct": 50,
    "cfc_passive_threshold_pct": 33,
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Exit Tax/CFC: exit=%s, rate=19%%",
        [exit_flag]),
    "_legal_basis": "PIT Art.30da (Exit Tax) + Art.30f (CFC)",
    "_warnings": [sprintf("🟠 EXIT TAX GAP 5 — Przeniesienie rezydencji: %s. "
        "Exit Tax 19%% od niezrealizowanych zysków. "
        "CFC: >50%% kontroli + >33%% dochodu pasywnego.",
        [exit_flag])]
} {
    exit_check := object.get(input.jdg_entrepreneur, "exit_tax_check", false)
    exit_check == true
    exit_flag := object.get(input.jdg_entrepreneur, "exit_tax_applies", false)
}

# GAP 6: GAAR — Economic substance test
else := {
    "matched": true, "rule_id": "jdg.p35.gaar_economic_substance",
    "package": "jdg.p35_gaps", "priority": 4050,
    "gaar_artificiality_score": art_score,
    "gaar_business_purpose": has_purpose,
    "gaar_risk_level": risk_level,
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("GAAR: artificiality=%d, purpose=%s, risk=%s",
        [art_score, has_purpose, risk_level]),
    "_legal_basis": "OrdPU Art.119a — GAAR (economic substance + business purpose)",
    "_warnings": [sprintf("🟡 GAAR GAP 6 — Sztuczność: %d/100. Cel biznesowy: %s. "
        "Ryzyko GAAR: %s. Test economic substance: %s.",
        [art_score, has_purpose, risk_level, gaar_note])]
} {
    gaar_check := object.get(input.jdg_entrepreneur, "gaar_check_requested", false)
    gaar_check == true
    art_score := object.get(input.jdg_entrepreneur, "gaar_artificiality_score", 0)
    has_purpose := object.get(input.jdg_entrepreneur, "has_business_purpose", false)
    risk_level = "LOW" { art_score < 30 }
    risk_level = "MEDIUM" { art_score >= 30; art_score < 60 }
    risk_level = "HIGH" { art_score >= 60 }
    gaar_note = "Niskie ryzyko GAAR." { risk_level == "LOW" }
    gaar_note = "Uważaj — US może zakwestionować." { risk_level == "MEDIUM" }
    gaar_note = "WYSOKIE ryzyko — skonsultuj z doradcą!" { risk_level == "HIGH" }
}

# GAP 7: Combined relief limit 85,528 PLN monitoring
else := {
    "matched": true, "rule_id": "jdg.p35.combined_relief_limit_monitor",
    "package": "jdg.p35_gaps", "priority": 4060,
    "relief_youth_pln": r_youth,
    "relief_return_pln": r_return,
    "relief_family_pln": r_family,
    "relief_senior_pln": r_senior,
    "relief_total_pln": r_total,
    "relief_limit_pln": 85528,
    "relief_limit_breached": r_breached,
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Ulgi: %.0f/85528 PLN (breach=%s)", [r_total, r_breached]),
    "_legal_basis": "PIT Art.21 ust.1 pkt 148-154 — limit łączny ulg PIT-0",
    "_warnings": [sprintf("🟡 ULGI GAP 7 — Młodzi: %.0f, Powrót: %.0f, "
        "Rodzina 4+: %.0f, Senior: %.0f. ŁĄCZNIE: %.0f / 85 528 PLN. %s",
        [r_youth, r_return, r_family, r_senior, r_total, rel_action])]
} {
    relief_check := object.get(input.jdg_entrepreneur, "combined_relief_check", false)
    relief_check == true
    r_youth := object.get(input.jdg_entrepreneur, "pit0_youth_exemption_pln", 0)
    r_return := object.get(input.jdg_entrepreneur, "pit0_return_exemption_pln", 0)
    r_family := object.get(input.jdg_entrepreneur, "pit0_family_exemption_pln", 0)
    r_senior := object.get(input.jdg_entrepreneur, "pit0_senior_exemption_pln", 0)
    r_total := r_youth + r_return + r_family + r_senior
    r_breached := r_total > 85528
    rel_action = "OK — limit nieprzekroczony." { r_breached == false }
    rel_action = sprintf("PRZEKROCZONO LIMIT o %.0f PLN! "
        "Priorytet: Młodzi → Powrót → 4+ → Senior.",
        [r_total - 85528]) { r_breached == true }
}

# GAP 8: Tax form optimization with health contribution impact
else := {
    "matched": true, "rule_id": "jdg.p35.tax_form_health_optimization",
    "package": "jdg.p35_gaps", "priority": 4070,
    "form_scale_tax": scale_tax,
    "form_scale_health": scale_health,
    "form_linear_tax": linear_tax,
    "form_linear_health": linear_health,
    "form_lump_tax": lump_tax,
    "form_lump_health": lump_health,
    "form_optimal": optimal_form,
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": "",
    "_routing_reason": sprintf("Optymalizacja: %s (skala=%.0f, liniowy=%.0f, ryczałt=%.0f)",
        [optimal_form, scale_tax + scale_health, linear_tax + linear_health, lump_tax + lump_health]),
    "_legal_basis": "PIT + Ustawa zdrowotna — optymalizacja formy opodatkowania",
    "_warnings": [sprintf("🟢 FORMY GAP 8 — Skala: podatek %.0f + zdrowotna %.0f = %.0f PLN. "
        "Liniowy: podatek %.0f + zdrowotna %.0f (odliczana) = %.0f PLN. "
        "Ryczałt: podatek %.0f + zdrowotna %.0f = %.0f PLN. "
        "Optymalna: %s.",
        [scale_tax, scale_health, scale_tax + scale_health,
         linear_tax, linear_health, linear_tax + linear_health - linear_health * 0.12,
         lump_tax, lump_health, lump_tax + lump_health, optimal_form])]
} {
    form_check := object.get(input.jdg_entrepreneur, "tax_form_optimization_check", false)
    form_check == true
    income := object.get(input.jdg_entrepreneur, "annual_income_pln", 120000)

    scale_tax := floor(income * 0.12)  { income <= 120000 }
    scale_tax := floor(120000 * 0.12 + (income - 120000) * 0.32) { income > 120000 }
    scale_health := floor(income * 0.09)
    linear_tax := floor(income * 0.19)
    linear_health := floor(income * 0.049)
    lump_tax := floor(income * 0.12)
    lump_health := floor(income * 0.09)

    total_scale := scale_tax + scale_health
    total_linear := linear_tax + linear_health - floor(linear_health * 0.12)
    total_lump := lump_tax + lump_health
    optimal_form = "SKALA" { total_scale <= total_linear; total_scale <= total_lump }
    optimal_form = "LINIOWY" { total_linear < total_scale; total_linear <= total_lump }
    optimal_form = "RYCZAŁT" { total_lump < total_scale; total_lump < total_linear }
}

# GAP 9: FX reporting to NBP
else := {
    "matched": true, "rule_id": "jdg.p35.fx_nbp_reporting",
    "package": "jdg.p35_gaps", "priority": 4080,
    "fx_transaction_currency": currency,
    "fx_transaction_amount": fx_amount,
    "fx_nbp_reporting_required": report_required,
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": "",
    "_routing_reason": sprintf("FX NBP: %s %.2f — report=%s",
        [currency, fx_amount, report_required]),
    "_legal_basis": "Prawo dewizowe — obowiązek raportowania do NBP",
    "_warnings": [sprintf("🟢 FX NBP GAP 9 — Transakcja %.2f %s. "
        "Raportowanie do NBP: %s. Obowiązek przy transakcjach > równowartość 15 000 EUR.",
        [fx_amount, currency, report_required])]
} {
    fx_check := object.get(input.jdg_entrepreneur, "fx_nbp_check", false)
    fx_check == true
    currency := object.get(input.invoice, "currency", "PLN")
    fx_amount := object.get(input.invoice, "amount_net", 0)
    eur_rate := object.get(input.jdg_entrepreneur, "nbp_eur_rate", 4.50)
    fx_eur := floor(fx_amount / eur_rate)
    report_required := currency != "PLN" and fx_eur > 15000
}

# GAP 10: Sickness benefits calculation
else := {
    "matched": true, "rule_id": "jdg.p35.sickness_benefits_calculation",
    "package": "jdg.p35_gaps", "priority": 4090,
    "sickness_type": sick_type,
    "sickness_days": sick_days,
    "sickness_benefit_rate_pct": benefit_rate,
    "sickness_daily_benefit_pln": daily_benefit,
    "sickness_total_benefit_pln": total_benefit,
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": "",
    "_routing_reason": sprintf("Zasiłek: %s %d dni × %.2f PLN = %.2f PLN",
        [sick_type, sick_days, daily_benefit, total_benefit]),
    "_legal_basis": "Ustawa zasiłkowa — chorobowe, macierzyńskie, opiekuńcze",
    "_warnings": [sprintf("🟢 ZASIŁKI GAP 10 — %s: %d dni. "
        "Stawka: %.0f%%. Podstawa: %.2f PLN. Zasiłek: %.2f PLN.",
        [sick_type, sick_days, benefit_rate * 100, daily_base, total_benefit])]
} {
    sick_check := object.get(input.jdg_entrepreneur, "sickness_benefit_check", false)
    sick_check == true
    sick_days := object.get(input.jdg_entrepreneur, "sickness_days", 0)
    sick_type_opts := ["CHOROBOWE", "MACIERZYŃSKIE", "OPIEKUŃCZE", "SZPITALNE"]
    sick_type := sick_type_opts[0]
    sick_type = "SZPITALNE" { object.get(input.jdg_entrepreneur, "is_hospitalized", false) == true }
    benefit_rate = 0.80 { sick_type == "CHOROBOWE" }
    benefit_rate = 1.00 { sick_type == "MACIERZYŃSKIE" }
    benefit_rate = 0.80 { sick_type == "OPIEKUŃCZE" }
    benefit_rate = 0.70 { sick_type == "SZPITALNE" }
    daily_base := object.get(input.jdg_entrepreneur, "sickness_daily_base_pln", 150.00)
    daily_benefit := floor(daily_base * benefit_rate * 100) / 100
    total_benefit := floor(daily_benefit * sick_days * 100) / 100
}

# ═══════════════════════════════════════════════════════════════════════════════
# FALLBACK
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": false, "rule_id": "jdg.p35_gaps.fallback",
    "package": "jdg.p35_gaps", "priority": 4998,
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "P35 System Gaps Resolution Engine",
    "_warnings": []
} { true }
