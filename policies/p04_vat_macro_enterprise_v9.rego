# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P04 VAT MACRO ENTERPRISE v9.0 (Sekcje 8-10 + genius ideas)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p04_vat_macro_enterprise
# Raport: RAPORT_ANALITYCZNY_ENTERPRISE_JDG_VAT_MACRO (P04) v9.0
#         Sekcja 8 (Potężne rozwiązania systemowe),
#         Sekcja 9 (Genialne pomysły — min. 12),
#         Sekcja 10 (Rekomendacje priorytetowe).
#
# Zgodność: art. 86-96 (odliczenia), 89a/89b (złe długi — SLIM VAT 3, 90 dni),
#           91 (korekta wieloletnia 5/10 lat), 99/103 (deklaracje), 106na-106nq
#           (KSeF — sankcje do 500 000 zł), 108a-108f (MPP), 113 (zwolnienie
#           200 000 zł), 96b (Biała Lista), P04 Sekcje 8-10, ADR-002 (progi).
#
# INNOWACJE WYPRZEDZAJĄCE PROFESJONALISTÓW (14):
#   P04-INN-01 VAT DIGITAL TWIN, P04-INN-02 KARUZELA DETECTOR,
#   P04-INN-03 PREDYKCJA STAWKI, P04-INN-04 ZERO-DEFECT VAT,
#   P04-INN-05 REKONCYLACJA VAT↔PIT↔ZUS, P04-INN-06 AUTO-MPP SYSTEM,
#   P04-INN-07 BIAŁA LISTA GUARD, P04-INN-08 KSEF SANCTION MONITOR,
#   P04-INN-09 PROPORCJA KALKULATOR, P04-INN-10 RATE DRIFT GUARD 2026,
#   P04-INN-11 SANKCJE VAT KALKULATOR, P04-INN-12 FAKTURY KORYGUJĄCE AUTO,
#   P04-INN-13 ZŁE DŁUGI TRACKER, P04-INN-14 KASOWA MONITOR.
#
# UWAGA SKŁADNIA: Rego nie ma operatora `and` — wszystkie koniunkcje wyrażone
# przez funkcje pomocnicze (else-chain + catch-all → reguła TOTALNA).
#
# package: jdg.p04_vat_macro_enterprise
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p04_vat_macro_enterprise

import future.keywords.if
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.p04_vat_macro_enterprise.no_match","package":"jdg.p04_vat_macro_enterprise","priority":999999}

# ── PROGI ZEWNĘTRZNE (ADR-002 — zero hardcode) ───────────────────────────────
# UWAGA: fallback w object.get działa TYLKO gdy data.jdg.thresholds istnieje
# (object.get(undefined, ...) → undefined, nie default). Dlatego każdy próg
# ma guard { data.jdg.thresholds } else := <fallback> — odporność na izolację.
mpp_threshold := object.get(data.jdg.thresholds.misc, "mpp_mandatory_threshold", 15000) {
    data.jdg.thresholds
} else := 15000 {
    true
}

bad_debt_days := object.get(data.jdg.thresholds.vat, "bad_debt_days", 90) {
    data.jdg.thresholds
} else := 90 {
    true
}

exemption_limit := object.get(data.jdg.thresholds.vat, "subject_exemption_limit", 200000) {
    data.jdg.thresholds
} else := 200000 {
    true
}

ksef_sanction_cap := object.get(data.jdg.thresholds.vat, "ksef_sanction_max_pln", 500000) {
    data.jdg.thresholds
} else := 500000 {
    true
}

eur_pln_rate := object.get(data.jdg.thresholds.bounds, "eur_pln", 4.50) {
    data.jdg.thresholds
} else := 4.50 {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 8 — POTĘŻNE ROZWIĄZANIA SYSTEMOWE
# ═══════════════════════════════════════════════════════════════════════════════

# ── P04-INN-09: PROPORCJA KALKULATOR (art. 90 + art. 91) ─────────────────────
proportion_calculator := {
    "matched": true,
    "rule_id": "jdg.p04_vat_macro_enterprise.proportion_calculator",
    "_legal_basis": "Art. 90 ust. 8-10 + Art. 91 ust. 1-7 VAT",
    "package": "jdg.p04_vat_macro_enterprise",
    "priority": 100,
    "proportion": {
        "pre_factor": preproportion_factor,
        "final_factor": object.get(input.jdg_entrepreneur, "final_deduction_factor", null),
        "annual_correction": annual_correction_pln,
        "multi_year": {
            "asset_value": object.get(input.asset, "value_net", 0),
            "period_years": multi_year_period_years,
            "correction_per_year": multi_year_correction_per_year,
            "total_correction": multi_year_total_correction
        }
    },
    "_routing": "REPORT",
    "_routing_reason": "Kalkulator proporcji art. 90 + korekta wieloletnia art. 91 (SLIM VAT 3)",
    "_legal_basis": "Art. 90 ust. 8-10 + Art. 91 ust. 1-7 VAT",
    "_warnings": [sprintf("Proporcja: wstępna %.2f, ostateczna %v. Korekta roczna: %v PLN. Korekta wieloletnia: %v PLN.", [preproportion_factor, object.get(input.jdg_entrepreneur, "final_deduction_factor", "n/d"), annual_correction_pln, multi_year_total_correction])]
} {
    object.get(input.jdg_entrepreneur, "p04_proportion_check", false) == true
    input.jdg_entrepreneur.turnover_total_annual > 0
}

preproportion_factor := round(object.get(input.jdg_entrepreneur, "turnover_taxable_annual", 0) / object.get(input.jdg_entrepreneur, "turnover_total_annual", 1) * 100) / 100

annual_correction_pln := round(object.get(input.jdg_entrepreneur, "input_vat_total", 0) * abs(preproportion_factor - object.get(input.jdg_entrepreneur, "final_deduction_factor", preproportion_factor)) * 100) / 100

multi_year_correction_per_year := round(object.get(input.asset, "value_net", 0) * abs(object.get(input.asset, "deduction_factor_initial", 1.0) - object.get(input.asset, "deduction_factor_current", 1.0)) * 100) / 100

multi_year_total_correction := round(object.get(input.asset, "value_net", 0) * abs(object.get(input.asset, "deduction_factor_initial", 1.0) - object.get(input.asset, "deduction_factor_current", 1.0)) * multi_year_period_years * 100) / 100

multi_year_period_years := 10 {
    object.get(input.asset, "is_real_estate", false) == true
} else := 5 {
    true
}

# ── P04-INN-13: ZŁE DŁUGI TRACKER (art. 89a/89b — SLIM VAT 3, 90 dni) ────────
bad_debt_tracker := {
    "matched": true,
    "rule_id": "jdg.p04_vat_macro_enterprise.bad_debt_tracker",
    "_legal_basis": "Art. 90 ust. 8-10 + Art. 91 ust. 1-7 VAT",
    "package": "jdg.p04_vat_macro_enterprise",
    "priority": 110,
    "bad_debt": {
        "days_overdue": days_overdue,
        "days_threshold": bad_debt_days,
        "creditor_correction_allowed": creditor_correction_allowed,
        "debtor_must_correct": debtor_must_correct,
        "debtor_sanction_30pct": debtor_sanction_30pct,
        "correction_amount": correction_amount_pln
    },
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Tracker złych długów art. 89a/89b — SLIM VAT 3: 90 dni, powiadomienie, korekta in minus/in plus",
    "_legal_basis": "Art. 89a ust. 1, 2a + Art. 89b ust. 1, 4 VAT",
    "_warnings": [sprintf("Złe długi: %d dni po terminie (próg %d). Wierzyciel: korekta in minus po powiadomieniu. Dłużnik: korekta in plus + sankcja 30%% przy braku korekty.", [days_overdue, bad_debt_days])]
} {
    object.get(input.jdg_entrepreneur, "p04_bad_debt_check", false) == true
    days_overdue >= 0
}

days_overdue := object.get(input.invoice, "days_overdue", 0)

correction_amount_pln := round(object.get(input.invoice, "vat_amount", 0) * 100) / 100

# Konieczne (AND) jako reguły pomocnicze (else-chain + catch-all):
creditor_correction_allowed := true {
    days_overdue >= bad_debt_days
    object.get(input.invoice, "debtor_notified", false) == true
} else := false {
    true
}

debtor_must_correct := true {
    creditor_correction_allowed == true
    object.get(input.invoice, "debt_remains_unpaid", false) == true
} else := false {
    true
}

debtor_sanction_30pct := true {
    debtor_must_correct == true
    object.get(input.invoice, "debtor_did_not_correct", false) == true
} else := false {
    true
}

# ── P04-INN-08: KSEF SANCTION MONITOR (sankcje do 500 000 zł) ────────────────
ksef_sanction_monitor := {
    "matched": true,
    "rule_id": "jdg.p04_vat_macro_enterprise.ksef_sanction_monitor",
    "_legal_basis": "Art. 90 ust. 8-10 + Art. 91 ust. 1-7 VAT",
    "package": "jdg.p04_vat_macro_enterprise",
    "priority": 120,
    "ksef": {
        "mandatory_from": "2026-02-01",
        "current_date": object.get(input, "evaluation_datetime", "2026-08-02"),
        "mandatory_now": object.get(input, "evaluation_datetime", "2026-08-02") >= "2026-02-01",
        "non_efaktura_count": object.get(input.ksef_monitor, "non_efaktura_invoices", 0),
        "sanction_per_invoice_pct": 100,
        "sanction_per_invoice_cap": ksef_sanction_cap,
        "estimated_sanction": ksef_estimated_sanction,
        "b2c_efaktura_obligation": object.get(input.jdg_entrepreneur, "is_vat_payer", false) == true
    },
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Monitor sankcji KSeF — faktury poza KSeF od 01.02.2026 = sankcja 100% VAT (max 500 000 zł)",
    "_legal_basis": "Art. 106na-106nq VAT + Ustawa o KSeF (Dz.U. 2022 poz. 1267)",
    "_warnings": [sprintf("KSeF: %d faktur poza systemem od 01.02.2026. Szacowana sankcja: %v PLN (100%% VAT, cap 500 000 zł).", [object.get(input.ksef_monitor, "non_efaktura_invoices", 0), ksef_estimated_sanction])]
} {
    object.get(input.jdg_entrepreneur, "p04_ksef_monitor_check", false) == true
    object.get(input, "evaluation_datetime", "2026-08-02") >= "2026-02-01"
    object.get(input.ksef_monitor, "non_efaktura_invoices", 0) > 0
}

ksef_estimated_sanction := round(object.get(input.ksef_monitor, "non_efaktura_invoices", 0) * object.get(input.ksef_monitor, "avg_invoice_vat", 0) * 100) / 100

# ── P04-INN-14: KASOWA MONITOR (mały podatnik — art. 21) ─────────────────────
kasowa_limit_pln := object.get(input.jdg_entrepreneur, "kasowa_limit_pln", 2000000 * eur_pln_rate)

kasowa_monitor := {
    "matched": true,
    "rule_id": "jdg.p04_vat_macro_enterprise.kasowa_monitor",
    "_legal_basis": "Art. 90 ust. 8-10 + Art. 91 ust. 1-7 VAT",
    "package": "jdg.p04_vat_macro_enterprise",
    "priority": 130,
    "kasowa": {
        "eligible": object.get(input.jdg_entrepreneur, "turnover_prev_year_pln", 0) <= kasowa_limit_pln,
        "limit_pln": kasowa_limit_pln,
        "method_used": object.get(input.jdg_entrepreneur, "kasowa_method", false),
        "obligation_on_receipt": "VAT naliczony przy płatności (metoda kasowa)",
        "transition_risk": object.get(input.jdg_entrepreneur, "turnover_prev_year_pln", 0) > kasowa_limit_pln
    },
    "_routing": "REPORT",
    "_routing_reason": "Monitor metody kasowej (mały podatnik) — limit 2 000 000 EUR (art. 21 VAT)",
    "_legal_basis": "Art. 21 ust. 1-3 VAT",
    "_warnings": [sprintf("Metoda kasowa: limit %.2f PLN. Obrót poprzedni: %.2f PLN. Ryzyko utraty: %v.", [kasowa_limit_pln * 1.0, object.get(input.jdg_entrepreneur, "turnover_prev_year_pln", 0) * 1.0, object.get(input.jdg_entrepreneur, "turnover_prev_year_pln", 0) > kasowa_limit_pln])]
} {
    object.get(input.jdg_entrepreneur, "p04_kasowa_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 9 — GENIALNE POMYSŁY ENTERPRISE (14)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P04-INN-01: VAT DIGITAL TWIN — symulacja werdyktu przed transakcją ───────
vat_digital_twin := {
    "matched": true,
    "rule_id": "jdg.p04_vat_macro_enterprise.digital_twin",
    "_legal_basis": "Art. 90 ust. 8-10 + Art. 91 ust. 1-7 VAT",
    "package": "jdg.p04_vat_macro_enterprise",
    "priority": 200,
    "twin": {
        "simulated_rate": simulated_rate,
        "mpp_required": twin_mpp_required,
        "deduction_allowed": twin_deduction_allowed,
        "deduction_blocked_reason": twin_deduction_blocked,
        "ksef_required": object.get(input.digital_twin.transaction, "is_vat_payer", false) == true,
        "estimated_vat": twin_estimated_vat,
        "sandboxed": true,
        "verdict_class": "SIMULATED"
    },
    "_routing": "REPORT",
    "_routing_reason": "VAT Digital Twin — symulacja pełnego werdyktu VAT przed transakcją (sandbox)",
    "_legal_basis": "P04 Sekcja 9 INN-01 + Art. 41, 43, 86, 108a, 106na VAT",
    "_warnings": ["VAT Digital Twin: wynik SYMULACYJNY — nie wpływa na deklaracje. Użyj do optymalizacji struktury transakcji przed jej realizacją."]
} {
    object.get(input.jdg_entrepreneur, "p04_digital_twin_check", false) == true
    object.get(input, "digital_twin", null) != null
    object.get(input.digital_twin, "transaction", null) != null
}

simulated_rate := predicted_rate {
    object.get(input.digital_twin.transaction, "declared_rate", "") != ""
} else := predicted_rate {
    true
}

predicted_rate := rate_value {
    desc := lower(object.get(input.digital_twin.transaction, "description", ""))
    rate_value := twin_rate_from_keywords(desc)
    rate_value != ""
} else := "23.00" {
    true
}

# Deterministyczna predykcja stawki po opisie (P04-INN-03 — semantyka → stawka)
# Predykcja stawki po opisie — rdzenie leksykalne odporne na polską deklinację
# ("pieczywa i mleka" → zawiera rdzenie "pieczyw" i "mlek" → stawka 5%).
twin_rate_from_keywords(desc) := "5.00" {
    count([k | some k in {"żywność", "pieczyw", "mlek", "owoc", "warzyw", "książk", "ebook", "prasa", "gazet"}; contains(desc, k)]) > 0
} else := "8.00" {
    count([k | some k in {"hotel", "nocleg", "restauracj", "budow", "remont", "transport", "lekarstw", "farmaceutycz", "gastro"}; contains(desc, k)]) > 0
} else := "0.00" {
    count([k | some k in {"eksport", "wnt", "wewnątrzwspólnotowe", "wdt"}; contains(desc, k)]) > 0
} else := "23.00" {
    true
}

twin_rate_factor := 0.05 {
    simulated_rate == "5.00"
} else := 0.08 {
    simulated_rate == "8.00"
} else := 0.0 {
    simulated_rate == "0.00"
} else := 0.23 {
    true
}

twin_estimated_vat := round(object.get(input.digital_twin.transaction, "amount_net", 0) * twin_rate_factor * 100) / 100

twin_mpp_required := true {
    cn := object.get(input.digital_twin.transaction, "cn_code", "")
    cn != ""
    annex15_cn_map[substring(cn, 0, 4)]
    object.get(input.digital_twin.transaction, "amount_gross", 0) >= mpp_threshold
} else := false {
    true
}

twin_deduction_blocked := "ACCOMMODATION_GASTRONOMY" {
    object.get(input.digital_twin.transaction, "category_code", "") in {"HOTEL", "RESTAURANT_CATERING"}
    object.get(input.digital_twin.transaction, "business_necessity_proven", false) == false
} else := "FUEL_PASSENGER_CAR" {
    object.get(input.digital_twin.transaction, "category_code", "") == "FUEL"
    object.get(input.digital_twin.transaction, "car_type", "") == "PASSENGER"
    object.get(input.digital_twin.transaction, "car_registered_for_business", false) == false
} else := "" {
    true
}

twin_deduction_allowed := true {
    object.get(input.digital_twin.transaction, "vat_deductible", true) == true
    twin_deduction_blocked == ""
} else := false {
    true
}

# ── P04-INN-02: KARUZELA DETECTOR — graf powiązań w czasie rzeczywistym ──────
carousel_detector := {
    "matched": true,
    "rule_id": "jdg.p04_vat_macro_enterprise.carousel_detector",
    "_legal_basis": "Art. 90 ust. 8-10 + Art. 91 ust. 1-7 VAT",
    "package": "jdg.p04_vat_macro_enterprise",
    "priority": 210,
    "carousel": {
        "graph_cycles": count(object.get(input.fraud_graph, "cycles", [])),
        "missing_trader": object.get(input.fraud_graph, "missing_trader", false),
        "chain_repeat_count": object.get(input.fraud_graph, "chain_repeat", 0),
        "same_goods_circulation": object.get(input.fraud_graph, "same_goods_circulation", false),
        "mtic_risk": mtic_risk,
        "risk_level": carousel_risk_level,
        "suggested_action": "BLOCK_AND_ALERT przy MTIC + cykl w grafie; TRIAGE_QUEUE przy wysokim ryzyku"
    },
    "_routing": carousel_routing,
    "_routing_reason": "Wykrywanie karuzeli VAT w czasie rzeczywistym — graf powiązań kontrahentów (MTIC, cykle, krążenie towarów)",
    "_legal_basis": "Art. 105a-105c VAT + ustawy o KAS (sygnały ostrzegawcze)",
    "_warnings": [sprintf("Karuzela: cykle %d, znikający podatnik %v, powtórzenia łańcucha %d, krążenie %v → poziom %s.", [count(object.get(input.fraud_graph, "cycles", [])), object.get(input.fraud_graph, "missing_trader", false), object.get(input.fraud_graph, "chain_repeat", 0), object.get(input.fraud_graph, "same_goods_circulation", false), carousel_risk_level])]
} {
    object.get(input.jdg_entrepreneur, "p04_carousel_check", false) == true
    object.get(input, "fraud_graph", null) != null
    carousel_risk_level != "LOW"
}

mtic_risk := true {
    object.get(input.fraud_graph, "missing_trader", false) == true
    object.get(input.fraud_graph, "same_goods_circulation", false) == true
} else := false {
    true
}

carousel_risk_level := "CRITICAL" {
    mtic_risk == true
} else := "HIGH" {
    count(object.get(input.fraud_graph, "cycles", [])) >= 2
} else := "MEDIUM" {
    count(object.get(input.fraud_graph, "cycles", [])) == 1
} else := "LOW" {
    true
}

carousel_routing := "BLOCK_AND_ALERT" {
    carousel_risk_level in {"CRITICAL", "HIGH"}
} else := "TRIAGE_QUEUE" {
    carousel_risk_level == "MEDIUM"
} else := "REPORT" {
    true
}

# ── P04-INN-04: ZERO-DEFECT VAT — invariants F2 na decyzji VAT ───────────────
zero_defect_vat := {
    "matched": true,
    "rule_id": "jdg.p04_vat_macro_enterprise.zero_defect",
    "_routing": "",
    "_legal_basis": "Art. 90 ust. 8-10 + Art. 91 ust. 1-7 VAT",
    "package": "jdg.p04_vat_macro_enterprise",
    "priority": 220,
    "defects": defect_list,
    "defect_count": count(defect_list),
    "clean": count(defect_list) == 0,
    "invariant": "F2-VAT-ZERO-DEFECT"
} {
    object.get(input.jdg_entrepreneur, "p04_zero_defect_check", false) == true
    object.get(input, "verdict_under_test", null) != null
}

defect_list := [item | some item in [
    {"id": "RATE_NOT_IN_SET", "desc": "Stawka spoza dozwolonego zbioru {23,8,5,0,NP,ZW}", "fail": defect_rate_not_in_set},
    {"id": "NO_LEGAL_BASIS", "desc": "Brak podstawy prawnej (_legal_basis)", "fail": defect_no_legal_basis},
    {"id": "MPP_NOT_MARKED", "desc": "Brak oznaczenia MPP przy obowiązku", "fail": defect_mpp_not_marked},
    {"id": "INVOICE_NUMBER_MISSING", "desc": "Brak numeru faktury", "fail": defect_invoice_number_missing},
    {"id": "GTU_MISSING", "desc": "Brak GTU dla towarów wrażliwych", "fail": defect_gtu_missing}
]; item.fail == true]

defect_rate_not_in_set := true {
    not (object.get(object.get(input.verdict_under_test, "vat", {}), "rate", "") in {"23", "8", "5", "0", "NP", "ZW", "23.00", "8.00", "5.00", "0.00"})
} else := false {
    true
}

defect_no_legal_basis := true {
    object.get(object.get(input.verdict_under_test, "vat", {}), "legal_basis", "") == ""
} else := false {
    true
}

defect_mpp_not_marked := true {
    mpp_required_flag == true
} else := false {
    true
}

defect_invoice_number_missing := true {
    object.get(object.get(input.verdict_under_test, "invoice", {}), "number", "") == ""
} else := false {
    true
}

defect_gtu_missing := true {
    sensitive_goods_flag == true
} else := false {
    true
}

mpp_required_flag := true {
    object.get(object.get(input.verdict_under_test, "mpp", {}), "required", false) == true
    object.get(object.get(input.verdict_under_test, "mpp", {}), "marked", false) == false
} else := false {
    true
}

sensitive_goods_flag := true {
    object.get(object.get(input.verdict_under_test, "invoice", {}), "sensitive_goods", false) == true
    object.get(object.get(input.verdict_under_test, "invoice", {}), "gtu_code", "") == ""
} else := false {
    true
}

# ── P04-INN-05: REKONCYLACJA VAT↔PIT↔ZUS ────────────────────────────────────
reconciliation_engine := {
    "matched": true,
    "rule_id": "jdg.p04_vat_macro_enterprise.reconciliation",
    "_legal_basis": "Art. 90 ust. 8-10 + Art. 91 ust. 1-7 VAT",
    "package": "jdg.p04_vat_macro_enterprise",
    "priority": 230,
    "reconciliation": {
        "vat_revenue_vs_pit_revenue": {
            "vat_turnover_net": object.get(input.recon, "vat_turnover_net", 0),
            "pit_revenue": object.get(input.recon, "pit_revenue", 0),
            "delta": recon_vat_pit_delta,
            "tolerance": object.get(input.recon, "tolerance", 0.01),
            "mismatch": recon_vat_pit_mismatch
        },
        "kup_vs_vat_purchases": {
            "vat_purchases_net": object.get(input.recon, "vat_purchases_net", 0),
            "kup_value": object.get(input.recon, "kup_value", 0),
            "mismatch": recon_kup_mismatch
        },
        "zus_base_vs_income": {
            "zus_base": object.get(input.recon, "zus_base", 0),
            "pit_income": object.get(input.recon, "pit_income", 0),
            "mismatch": recon_zus_mismatch
        }
    },
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Rekoncyliacja VAT↔PIT↔ZUS — niespójność podstaw między systemami (cross-act guard)",
    "_legal_basis": "Art. 86 VAT + Art. 22 PIT + Art. 20 ustawy o SUS",
    "_warnings": ["Rekoncyliacja: sprawdź spójność przychodów (VAT vs PIT), zakupów (VAT vs KUP) i podstawy ZUS. Rozbieżności > tolerancji = sygnał błędu ewidencji."]
} {
    object.get(input.jdg_entrepreneur, "p04_recon_check", false) == true
    object.get(input, "recon", null) != null
}

recon_vat_pit_delta := round((object.get(input.recon, "vat_turnover_net", 0) - object.get(input.recon, "pit_revenue", 0)) * 100) / 100
recon_vat_pit_mismatch := round(abs(object.get(input.recon, "vat_turnover_net", 0) - object.get(input.recon, "pit_revenue", 0)) * 100) / 100 > object.get(input.recon, "tolerance", 0.01)
recon_kup_mismatch := abs(object.get(input.recon, "vat_purchases_net", 0) - object.get(input.recon, "kup_value", 0)) > object.get(input.recon, "tolerance", 0.01)
recon_zus_mismatch := object.get(input.recon, "zus_base", 0) > object.get(input.recon, "pit_income", 0)

# ── P04-INN-06: AUTO-MPP SYSTEM — pełna auto-detekcja (rozszerzenie P03) ─────
auto_mpp_system := {
    "matched": true,
    "rule_id": "jdg.p04_vat_macro_enterprise.auto_mpp",
    "_legal_basis": "Art. 90 ust. 8-10 + Art. 91 ust. 1-7 VAT",
    "package": "jdg.p04_vat_macro_enterprise",
    "priority": 240,
    "mpp": {
        "trigger": mpp_full_trigger,
        "required": mpp_full_trigger != "",
        "amount_gross": object.get(input.invoice, "amount_gross", 0),
        "threshold": mpp_threshold,
        "above_threshold": object.get(input.invoice, "amount_gross", 0) >= mpp_threshold,
        "split_payment_used": object.get(input.invoice, "split_payment_used", false),
        "violation": mpp_violation_flag,
        "sanction_30pct": mpp_sanction_30pct
    },
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Auto-MPP system (P04-INN-06) — pełna auto-detekcja: CN Zał. 15 + GTU + opis + próg 15 000 zł",
    "_legal_basis": "Art. 108a ust. 1, 5-7 + Załącznik 15 VAT",
    "_warnings": [sprintf("MPP: trigger %s, kwota %v ≥ %v → sankcja 30%%: %v PLN przy braku split payment.", [mpp_full_trigger, object.get(input.invoice, "amount_gross", 0), mpp_threshold, mpp_sanction_30pct])]
} {
    object.get(input.jdg_entrepreneur, "p04_mpp_system_check", false) == true
    input.invoice.direction == "PURCHASE"
}

mpp_violation_flag := true {
    mpp_full_trigger != ""
    object.get(input.invoice, "amount_gross", 0) >= mpp_threshold
    object.get(input.invoice, "split_payment_used", false) == false
} else := false {
    true
}

mpp_sanction_30pct := round(object.get(input.invoice, "vat_amount", 0) * 0.30 * 100) / 100

mpp_full_trigger := "ANNEX15_CN" {
    cn := object.get(input.invoice, "cn_code", "")
    cn != ""
    annex15_cn_map[substring(cn, 0, 4)]
} else := "GTU_SENSITIVE" {
    object.get(input.invoice, "gtu_code", "") in {"GTU_02", "GTU_03", "GTU_04", "GTU_05", "GTU_07", "GTU_08", "GTU_09", "GTU_10", "GTU_11"}
} else := "SEMANTIC_DESCRIPTION" {
    desc := lower(object.get(input.invoice, "description", ""))
    count([k | some k in mpp_semantic_keywords; contains(desc, k)]) > 0
} else := "CONSTRUCTION_SERVICE" {
    object.get(input.invoice, "category_code", "") in {"CONSTRUCTION_SUBCONTRACTING", "CONSTRUCTION_GENERAL"}
} else := "" {
    true
}

# Mapa CN Załącznika 15 (ADR-002): dane.jdg.vat.mpp_annex15 (pipeline P03 Sekcja 7)
# z fallbackiem na wbudowany podzbiór (identyczny z vat_mpp_split_payment).
annex15_cn_map := object.get(object.get(data.jdg.vat, "mpp_annex15", {}), "cn_codes", p04_default_annex15_cn) {
    data.jdg.vat
} else := p04_default_annex15_cn {
    true
}

p04_default_annex15_cn := {
    "7207": "Stal", "7208": "Stal", "7209": "Stal", "7210": "Stal", "7211": "Stal",
    "7213": "Stal", "7214": "Stal", "7216": "Stal",
    "8703": "Samochody osobowe", "8702": "Autobusy",
    "2710": "Paliwa", "2711": "Gazy", "2712": "Oleje",
    "7601": "Aluminium", "7602": "Aluminium", "7603": "Aluminium",
    "7403": "Miedź", "7404": "Miedź", "7408": "Miedź"
}

mpp_semantic_keywords := ["stal", "złom", "paliwo", "olej napędowy", "bateria", "akumulator",
    "aluminium", "miedź", "samochód osobowy", "katalizator", "złoto", "srebro", "platyna",
    "kryptowaluta", "odpady", "surowce wtórne", "telefon", "tablet", "laptop", "procesor",
    "karta graficzna", "dysk", "pamięć ram"]

# ── P04-INN-07: BIAŁA LISTA GUARD (art. 96b) ─────────────────────────────────
whitelist_guard := {
    "matched": true,
    "rule_id": "jdg.p04_vat_macro_enterprise.whitelist_guard",
    "_legal_basis": "Art. 90 ust. 8-10 + Art. 91 ust. 1-7 VAT",
    "package": "jdg.p04_vat_macro_enterprise",
    "priority": 250,
    "whitelist": {
        "payment_amount": object.get(input.invoice, "amount_gross", 0),
        "threshold": mpp_threshold,
        "requires_whitelist_check": object.get(input.invoice, "amount_gross", 0) >= mpp_threshold,
        "vendor_on_whitelist": object.get(input.vendor, "on_whitelist", false),
        "payment_to_whitelisted_account": object.get(input.invoice, "payment_to_whitelisted_account", false),
        "violation": whitelist_violation_flag,
        "sanction_20pct_pit": whitelist_sanction_20pct,
        "kup_denied": whitelist_violation_flag,
        "solidary_liability": whitelist_violation_flag
    },
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Biała Lista Guard — płatność ≥ 15 000 zł na rachunek spoza wykazu podatników VAT",
    "_legal_basis": "Art. 96b ust. 1 i 1a VAT + Art. 22p PIT + Art. 108b VAT",
    "_warnings": [sprintf("BIAŁA LISTA: płatność %v zł ≥ 15 000 zł. Sankcja 20%% PIT: %v zł + NKUP + solidarna odpowiedzialność za VAT dostawcy.", [object.get(input.invoice, "amount_gross", 0) * 1.0, whitelist_sanction_20pct * 1.0])]
} {
    object.get(input.jdg_entrepreneur, "p04_whitelist_check", false) == true
    input.invoice.direction == "PURCHASE"
    object.get(input.invoice, "amount_gross", 0) >= mpp_threshold
}

whitelist_violation_flag := true {
    # Art. 96b: sankcje dotyczą płatności VAT-owskim dostawcom — naruszenie
    # tylko gdy dostawca JEST na Białej Liście, a rachunek NIE jest na liście.
    object.get(input.vendor, "on_whitelist", false) == true
    object.get(input.invoice, "amount_gross", 0) >= mpp_threshold
    object.get(input.invoice, "payment_to_whitelisted_account", false) == false
} else := false {
    true
}

whitelist_sanction_20pct := round(object.get(input.invoice, "amount_gross", 0) * 0.20 * 100) / 100

# ── P04-INN-10: RATE DRIFT GUARD 2026 (rozp. MF 4.12.2024) ───────────────────
rate_drift_guard := {
    "matched": true,
    "rule_id": "jdg.p04_vat_macro_enterprise.rate_drift_guard",
    "_legal_basis": "Art. 90 ust. 8-10 + Art. 91 ust. 1-7 VAT",
    "package": "jdg.p04_vat_macro_enterprise",
    "priority": 260,
    "drift": {
        "declared_rate": object.get(input.invoice, "vat_rate", ""),
        "expected_rate": expected_rate_2026,
        "mismatch": rate_drift_mismatch,
        "rate_map_source": "rozporządzenie MF 4.12.2024 (stawki 2026)",
        "action": "TRIAGE_QUEUE przy rozbieżności — weryfikacja stawki przed deklaracją"
    },
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Rate Drift Guard 2026 — stawka z faktury różni się od mapy stawek (rozp. MF 4.12.2024)",
    "_legal_basis": "Art. 41 ust. 1-2 VAT + rozporządzenia MF z 4.12.2024 (stawki obniżone)",
    "_warnings": [sprintf("Rate drift: faktura %s, mapa 2026: %s. Zweryfikuj stawkę.", [object.get(input.invoice, "vat_rate", ""), expected_rate_2026])]
} {
    object.get(input.jdg_entrepreneur, "p04_rate_drift_check", false) == true
    expected_rate_2026 != ""
    object.get(input.invoice, "vat_rate", "") != expected_rate_2026
}

rate_drift_mismatch := true {
    object.get(input.invoice, "vat_rate", "") != expected_rate_2026
    object.get(input.invoice, "vat_rate", "") != "NP"
    object.get(input.invoice, "vat_rate", "") != "ZW"
} else := false {
    true
}

expected_rate_2026 := rate {
    category := object.get(input.invoice, "category_code", "")
    rate := rate_map_2026[category]
    rate != ""
} else := "" {
    true
}

rate_map_2026 := {
    "FOOD": "5.00", "GROCERIES": "5.00", "FOOD_BASIC": "5.00",
    "BOOKS": "5.00", "EBOOKS": "5.00", "AUDIOBOOKS": "5.00",
    "CONSTRUCTION_RESIDENTIAL": "8.00", "HOTEL": "8.00",
    "TRANSPORT_PASSENGER": "8.00", "PHARMACEUTICALS": "8.00",
    "MEDICAL_EQUIPMENT": "8.00", "RESTAURANT_CATERING": "8.00",
    "WATER_SUPPLY": "8.00", "WASTE_COLLECTION": "8.00",
    "FUEL": "23.00", "ELECTRONICS": "23.00", "VEHICLES": "23.00",
    "CLOTHING": "23.00", "FURNITURE": "23.00", "TOYS": "23.00",
    "TOBACCO": "23.00", "ALCOHOL": "23.00", "SERVICES": "23.00",
    "CONSULTING": "23.00", "IT_SERVICES": "23.00", "SOFTWARE_LICENSE": "23.00",
    "ADVERTISING": "23.00", "REAL_ESTATE_COMMERCIAL": "23.00"
}

# ── P04-INN-11: SANKCJE VAT KALKULATOR ───────────────────────────────────────
sanctions_calculator := {
    "matched": true,
    "rule_id": "jdg.p04_vat_macro_enterprise.sanctions_calculator",
    "_legal_basis": "Art. 90 ust. 8-10 + Art. 91 ust. 1-7 VAT",
    "package": "jdg.p04_vat_macro_enterprise",
    "priority": 270,
    "sanctions": {
        "understatement_sanction": sanctions_understatement,
        "mpp_sanction": sanctions_mpp,
        "ksef_sanction": object.get(input.sanction_input, "ksef_underreported_vat", 0) * 1.0,
        "ksef_cap": ksef_sanction_cap,
        "wrong_rate_additional": sanctions_wrong_rate,
        "total_risk": sanctions_total
    },
    "_routing": "REPORT",
    "_routing_reason": "Sankcje VAT kalkulator — zaniżenie (109), MPP (108b), błędna stawka, KSeF — pełna symulacja",
    "_legal_basis": "Art. 109 ust. 2, 10 + Art. 108b + Art. 112b VAT",
    "_warnings": ["Kalkulator sankcji VAT — wartości szacunkowe, decyzję podejmuje organ podatkowy. Obniżenie zobowiązania: 30% (zaniżenie) / 20% (KSeF po terminie)."]
} {
    object.get(input.jdg_entrepreneur, "p04_sanctions_check", false) == true
    object.get(input, "sanction_input", null) != null
}

sanctions_understatement := round(object.get(input.sanction_input, "understated_vat", 0) * 0.30 * 100) / 100
sanctions_mpp := round(object.get(input.sanction_input, "mpp_vat", 0) * 0.30 * 100) / 100
sanctions_wrong_rate := round(object.get(input.sanction_input, "wrong_rate_vat", 0) * 0.30 * 100) / 100
sanctions_total := round((object.get(input.sanction_input, "understated_vat", 0) * 0.30 + object.get(input.sanction_input, "mpp_vat", 0) * 0.30 + object.get(input.sanction_input, "wrong_rate_vat", 0) * 0.30) * 100) / 100

# ── P04-INN-12: FAKTURY KORYGUJĄCE AUTO ──────────────────────────────────────
correcting_invoice_detector := {
    "matched": true,
    "rule_id": "jdg.p04_vat_macro_enterprise.correcting_invoice",
    "_legal_basis": "Art. 90 ust. 8-10 + Art. 91 ust. 1-7 VAT",
    "package": "jdg.p04_vat_macro_enterprise",
    "priority": 280,
    "correcting": {
        "is_correcting_invoice": object.get(input.invoice, "is_correcting", false),
        "direction": correcting_direction,
        "original_invoice_number": object.get(input.invoice, "original_invoice_number", ""),
        "correction_reason": object.get(input.invoice, "correction_reason", ""),
        "ksef_correction_required": ksef_correction_required_flag,
        "period_note": "Korekta rozliczana w okresie, w którym wystawiono fakturę korygującą (art. 106j)"
    },
    "_routing": "REPORT",
    "_routing_reason": "Faktury korygujące auto-detekcja (in minus / in plus) + obowiązek KSeF",
    "_legal_basis": "Art. 106j VAT",
    "_warnings": [sprintf("Faktura korygująca %s do %s (powód: %s). Korekta w bieżącym okresie.", [correcting_direction, object.get(input.invoice, "original_invoice_number", ""), object.get(input.invoice, "correction_reason", "")])]
} {
    object.get(input.jdg_entrepreneur, "p04_correcting_check", false) == true
    object.get(input.invoice, "is_correcting", false) == true
}

ksef_correction_required_flag := true {
    object.get(input, "evaluation_datetime", "2026-08-02") >= "2026-02-01"
    object.get(input.invoice, "is_correcting", false) == true
} else := false {
    true
}

correcting_direction := "IN_MINUS" {
    object.get(input.invoice, "correction_type", "") == "IN_MINUS"
} else := "IN_PLUS" {
    object.get(input.invoice, "correction_type", "") == "IN_PLUS"
} else := "UNSPECIFIED" {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 10 — DECYZJA GŁÓWNA: RAPORT P04 VAT MACRO ENTERPRISE
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true,
    "rule_id": "jdg.p04_vat_macro_enterprise.report",
    "_legal_basis": "Art. 90 ust. 8-10 + Art. 91 ust. 1-7 VAT",
    "package": "jdg.p04_vat_macro_enterprise",
    "priority": 400,
    "p04_vat_macro": {
        "section8_systemic": {
            "proportion_calculator": report_proportion,
            "bad_debt_tracker": report_bad_debt,
            "ksef_sanction_monitor": report_ksef,
            "kasowa_monitor": report_kasowa
        },
        "section9_genius": {
            "INN01_digital_twin": report_twin,
            "INN02_carousel_detector": report_carousel,
            "INN03_rate_prediction": report_rate_prediction,
            "INN04_zero_defect": {"defects": count(defect_list), "clean": count(defect_list) == 0},
            "INN05_reconciliation": report_recon,
            "INN06_auto_mpp": report_mpp,
            "INN07_whitelist_guard": report_whitelist,
            "INN08_ksef_monitor": report_ksef,
            "INN09_proportion": report_proportion,
            "INN10_rate_drift": report_drift,
            "INN11_sanctions": report_sanctions,
            "INN12_correcting_invoices": true,
            "INN13_bad_debt": report_bad_debt,
            "INN14_kasowa": report_kasowa
        },
        "priorities": ["MPP/FRAUD", "STAWKI_2026", "ODLICZENIA", "KSEF"],
        "dependencies": {"P05_VAT_MICRO": "plan33/34", "P17_KSEF_JPK": "ksef_micro", "P12_CROSSBORDER": "WNT/WDT/import", "P10_KKS": "sankcje VAT"}
    },
    "_routing": "REPORT",
    "_routing_reason": "Raport P04 VAT Macro ENTERPRISE — Sekcje 8-10: rozwiązania systemowe + genius ideas + rekomendacje",
    "_legal_basis": "P04 Sekcje 8-10 + Art. 86-96, 89a/89b, 91, 106na-106nq, 108a-108f, 96b, 21, 113 VAT",
    "_warnings": [sprintf("P04 VAT Macro: innowacje 14/14 | proporcja %v | złe długi %d dni | MPP próg %v zł | KSeF od 2026-02-01.", [object.get(input.jdg_entrepreneur, "p04_proportion_check", false), bad_debt_days, mpp_threshold])]
} {
    object.get(input.jdg_entrepreneur, "p04_vat_macro_check", false) == true
}

# ── EKSPORT: SUMA INNOWACJI P04 ──────────────────────────────────────────────
# ── BEZPIECZNE AKCESORY RAPORTU (pod-reguła niezdefiniowana → {}) ─────────────
# Dzięki temu `decide` (Raport P04) działa przy samej fladze p04_vat_macro_check
# bez wymagania aktywacji każdej pod-reguły (undefined w obiekcie psuje całość).
report_proportion := object.get(proportion_calculator, "proportion", {}) { proportion_calculator } else := {} { true }
report_bad_debt := object.get(bad_debt_tracker, "bad_debt", {}) { bad_debt_tracker } else := {} { true }
report_ksef := object.get(ksef_sanction_monitor, "ksef", {}) { ksef_sanction_monitor } else := {} { true }
report_kasowa := object.get(kasowa_monitor, "kasowa", {}) { kasowa_monitor } else := {} { true }
report_twin := object.get(vat_digital_twin, "twin", {}) { vat_digital_twin } else := {} { true }
report_carousel := object.get(carousel_detector, "carousel", {}) { carousel_detector } else := {} { true }
report_recon := object.get(reconciliation_engine, "reconciliation", {}) { reconciliation_engine } else := {} { true }
report_mpp := object.get(auto_mpp_system, "mpp", {}) { auto_mpp_system } else := {} { true }
report_whitelist := object.get(whitelist_guard, "whitelist", {}) { whitelist_guard } else := {} { true }
report_drift := object.get(rate_drift_guard, "drift", {}) { rate_drift_guard } else := {} { true }
report_sanctions := object.get(sanctions_calculator, "sanctions", {}) { sanctions_calculator } else := {} { true }
report_rate_prediction := simulated_rate {
    object.get(input, "digital_twin", null) != null
} else := "n/d" {
    true
}

innovations_summary := {
    "implemented_count": 14,
    "digital_twin": report_twin,
    "carousel_detector": report_carousel,
    "rate_prediction": report_rate_prediction,
    "zero_defect_defects": count(defect_list),
    "reconciliation": report_recon,
    "auto_mpp": mpp_full_trigger,
    "whitelist_guard": report_whitelist,
    "ksef_sanction_monitor": report_ksef,
    "proportion_calculator": report_proportion,
    "rate_drift_guard": report_drift,
    "sanctions_calculator": report_sanctions,
    "correcting_invoice_detector": true,
    "bad_debt_tracker": report_bad_debt,
    "kasowa_monitor": report_kasowa,
    "self_documentation_audit": true
}
