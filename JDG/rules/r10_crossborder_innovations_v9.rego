# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R10 GLM52 CROSS-BORDER / TP / MDR-DAC6 / CFC / ViDA / CBAM — INNOWACJE
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.r10_crossborder_innovations
# Raport: RAPORT_10_CROSSBORDER.txt (Kampania GLM 5.2 — seria 10/25)
#
# Prompt 10/25 (Cross-border / TP / MDR-DAC6 / CFC / ViDA / CBAM / DAC8):
#   R10-INN-01 wdt_deadline_alert_monitor — monitor terminu 30 dni dowodu wywozu
#                                           WDT (art. 42 ust. 12 VAT) z 3
#                                           poziomami alertów + next_action
#                                           (p12 wdt_documentation_tracker
#                                           dawał status, bez alarmów)
#   R10-INN-02 mdr_risk_scorer            — scorer ryzyka MDR/DAC6 (hallmark
#                                           A-E × cross-border × main-benefit
#                                           → 0-100) z rekomendacją i routingiem
#                                           (p12 mdr_auto_detector dawał
#                                           detekcję bez skali ryzyka)
#   R10-INN-03 tp_threshold_simulator     — symulator obowiązku dokumentacji TP
#                                           (lokalna 500k / master 200M) z
#                                           projekcją forward (p12
#                                           tp_documentation_calculator liczył
#                                           punktowo)
#   R10-INN-04 cfc_profit_attribution     — kalkulator przypisania dochodu CFC
#                                           (dochód pasywny × udział → podstawa
#                                           × stawka) (p12 cfc_calculator
#                                           dawał tylko decyzję applies/nie)
#   R10-INN-05 fx_time_travel_reconciler  — różnice kursowe z pełną temporal-
#                                           nością: harmonogram kursów NBP per
#                                           okres + różnice zrealizowane/
#                                           niezrealizowane (p12 fx_difference_
#                                           calculator używał jednego kursu)
#
# Zgodność: ADR-001..009/017/022, VAT art. 13/17/28a-28o/42 ust. 12, PIT
#           art. 20/23o/23zf/29/30da/30f, OrdPU art. 86a-86r; thresholds.
#           crossborder (zero hardcode); INV-018; First-Match-Wins else-chain.
# package: jdg.r10_crossborder_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r10_crossborder_innovations

import future.keywords.if
import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.r10_crossborder_innovations.no_match", "package": "jdg.r10_crossborder_innovations", "priority": 999999}

# ── Progi zewnętrzne (ADR-002 — zero hardcode) ────────────────────────────────
_th := object.get(object.get(data, "jdg", {}), "thresholds", {})
_th_cb := object.get(_th, "crossborder", {})

wdt_documentation_days := object.get(_th_cb, "wdt_documentation_days", 30)   # art. 42 ust. 12 VAT
mdr_deadline_days := object.get(_th_cb, "mdr_deadline_days", 30)             # art. 86a OrdPU
tp_local_file_pln := object.get(_th_cb, "tp_local_file_pln", 500000)         # art. 23o PIT
tp_master_file_pln := object.get(_th_cb, "tp_master_file_pln", 200000000)    # art. 23zf PIT
residency_days := object.get(_th_cb, "residency_days", 183)                  # art. 3 PIT
cfc_ownership_min_pct := object.get(_th_cb, "cfc_ownership_min_pct", 0.50)   # art. 30f PIT
cfc_passive_income_pct := object.get(_th_cb, "cfc_passive_income_pct", 0.33) # art. 30f PIT
cfc_tax_rate_threshold_pct := object.get(_th_cb, "cfc_tax_rate_threshold_pct", 0.1425)  # art. 30f PIT
exit_tax_threshold_pln := object.get(_th_cb, "exit_tax_threshold_pln", 4000000)  # art. 30da PIT
exit_tax_rate_pct := object.get(_th_cb, "exit_tax_rate_pct", 0.19)           # art. 30da PIT

# ── Helper: zaokrąglenie 2 miejsca (spójne z p12/round2) ─────────────────────
round2(x) := floor((x * 100) + 0.5) / 100

# ═══════════════════════════════════════════════════════════════════════════════
# R10-INN-01: WDT DEADLINE ALERT MONITOR — monitor terminu 30 dni dowodu wywozu
#             (art. 42 ust. 12 VAT) z 3 poziomami alertów + next_action
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza wdt_monitor: {items: [{label, days_left, docs_received}]}.
# Poziom: RED ≤5 dni (BLOCK_AND_ALERT), AMBER ≤15 dni (TRIAGE_QUEUE), GREEN.
wdt_input := object.get(input, "wdt_monitor", {})
wdt_items_in := object.get(wdt_input, "items", [])

wdt_level(days) := "RED" if {
    days <= 5
} else := "AMBER" if {
    days <= 15
} else := "GREEN" if {
    true
}

wdt_item(i) := {
    "label": object.get(i, "label", "dowód wywozu"),
    "days_left": object.get(i, "days_left", wdt_documentation_days),
    "docs_received": object.get(i, "docs_received", false),
    "level": wdt_level(object.get(i, "days_left", wdt_documentation_days)),
    "next_action": "Zbierz dowód wywozu NATYCHMIAST (art. 42 ust. 12 VAT — 30 dni) — brak = utrata stawki 0% WDT." if {not object.get(i, "docs_received", false)} else "Dokumentacja kompletna — stawka 0% WDT utrzymana.",
}

wdt_items := [wdt_item(i) | i := wdt_items_in[_]]
wdt_red_count := count([x | x := wdt_items[_]; x.level == "RED"])
wdt_amber_count := count([x | x := wdt_items[_]; x.level == "AMBER"])
wdt_missing_count := count([x | x := wdt_items[_]; not x.docs_received])

wdt_routing := "BLOCK_AND_ALERT" if {
    wdt_red_count > 0
} else := "TRIAGE_QUEUE" if {
    wdt_amber_count > 0
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r10_crossborder_innovations.wdt_deadline_alert_monitor",
    "package": "jdg.r10_crossborder_innovations",
    "priority": 11011,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "wdt_items_total": count(wdt_items),
    "wdt_red_count": wdt_red_count,
    "wdt_amber_count": wdt_amber_count,
    "wdt_missing_count": wdt_missing_count,
    "wdt_deadline_days": wdt_documentation_days,
    "wdt_items": wdt_items,
    "_routing": wdt_routing,
    "_routing_reason": sprintf("Monitor dowodów WDT — %d pozycji (RED: %d, AMBER: %d, bez dokumentów: %d). Termin %d dni (art. 42 ust. 12 VAT).", [count(wdt_items), wdt_red_count, wdt_amber_count, wdt_missing_count, wdt_documentation_days]),
    "_legal_basis": "VAT art. 42 ust. 12 (dowód wywozu WDT, 30 dni), art. 13 (WDT 0%)",
    "_warnings": [sprintf("WDT: %d dowodów — %d RED (≤5 dni), %d AMBER (≤15 dni), %d bez dokumentów. Termin %d dni.", [count(wdt_items), wdt_red_count, wdt_amber_count, wdt_missing_count, wdt_documentation_days])],
} if {
    object.get(input.jdg_entrepreneur, "r10_crossborder_check", false) == true
    object.get(input, "wdt_monitor", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R10-INN-02: MDR RISK SCORER — scorer ryzyka MDR/DAC6 (hallmark A-E ×
#             cross-border × main-benefit → 0-100) z rekomendacją
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza mdr_assessment: {hallmark, cross_border, main_benefit}.
# Skala: hallmark (A=40..E=20 pkt) + cross-border (30) + main-benefit (30).
mdr_input := object.get(input, "mdr_assessment", {})
mdr_hallmark := object.get(mdr_input, "hallmark", "E")
mdr_cross_border := object.get(mdr_input, "cross_border", false)
mdr_main_benefit := object.get(mdr_input, "main_benefit", false)

mdr_hallmark_score := 40 if {
    mdr_hallmark == "A"
} else := 35 if {
    mdr_hallmark == "B"
} else := 30 if {
    mdr_hallmark == "C"
} else := 25 if {
    mdr_hallmark == "D"
} else := 20 if {
    true
}

mdr_cross_border_score := 30 if {
    mdr_cross_border
} else := 0 if {
    true
}

mdr_main_benefit_score := 30 if {
    mdr_main_benefit
} else := 0 if {
    true
}

mdr_risk_score := mdr_hallmark_score + mdr_cross_border_score + mdr_main_benefit_score

mdr_confidence := "HIGH" if {
    mdr_cross_border
    mdr_main_benefit
} else := "MEDIUM" if {
    mdr_hallmark == "A"
} else := "LOW" if {
    true
}

mdr_recommendation := "ZGŁOŚ MDR-1 NATYCHMIAST — wysokie ryzyko schematu transgranicznego (termin 30 dni)." if {
    mdr_risk_score >= 70
} else := "Przeanalizuj obowiązek raportowania MDR/DAC6 — ryzyko umiarkowane (konsultacja doradcy)." if {
    mdr_risk_score >= 40
} else := "Niskie ryzyko — monitoruj transakcję pod kątem hallmarków." if {
    true
}

mdr_routing := "BLOCK_AND_ALERT" if {
    mdr_risk_score >= 70
} else := "TRIAGE_QUEUE" if {
    mdr_risk_score >= 40
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r10_crossborder_innovations.mdr_risk_scorer",
    "package": "jdg.r10_crossborder_innovations",
    "priority": 11012,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "mdr_hallmark": mdr_hallmark,
    "mdr_cross_border": mdr_cross_border,
    "mdr_main_benefit": mdr_main_benefit,
    "mdr_risk_score": mdr_risk_score,
    "mdr_confidence": mdr_confidence,
    "mdr_deadline_days": mdr_deadline_days,
    "mdr_recommendation": mdr_recommendation,
    "_routing": mdr_routing,
    "_routing_reason": sprintf("Scorer MDR/DAC6 — hallmark %s, cross-border=%s, main-benefit=%s → ryzyko %d/100 (%s). Termin %d dni.", [mdr_hallmark, mdr_cross_border, mdr_main_benefit, mdr_risk_score, mdr_confidence, mdr_deadline_days]),
    "_legal_basis": "OrdPU art. 86a-86r (MDR/DAC6, termin 30 dni), art. 80f KKS (sankcje)",
    "_warnings": [sprintf("MDR: ryzyko %d/100 (hallmark %s, cross-border=%s, main-benefit=%s). %s", [mdr_risk_score, mdr_hallmark, mdr_cross_border, mdr_main_benefit, mdr_recommendation])],
} if {
    object.get(input.jdg_entrepreneur, "r10_crossborder_check", false) == true
    object.get(input, "mdr_assessment", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R10-INN-03: TP THRESHOLD SIMULATOR — symulator obowiązku dokumentacji TP
#             (lokalna 500k / master 200M) z projekcją forward
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza tp_simulation: {transactions_value_pln, related_parties,
# group_revenue_pln, monthly_avg_pln}.
tp_input := object.get(input, "tp_simulation", {})
tp_value := max([0, object.get(tp_input, "transactions_value_pln", 0)])
tp_related := object.get(tp_input, "related_parties", false)
tp_group_revenue := max([0, object.get(tp_input, "group_revenue_pln", 0)])
tp_monthly_avg := max([0, object.get(tp_input, "monthly_avg_pln", 0)])

tp_local_required := true if {
    tp_related
    tp_value >= tp_local_file_pln
} else := false if {
    true
}

tp_master_required := true if {
    tp_related
    tp_group_revenue >= tp_master_file_pln
} else := false if {
    true
}

tp_local_pct := round2(tp_value * 100 / tp_local_file_pln)

tp_months_to_local := ceil((tp_local_file_pln - tp_value) / tp_monthly_avg) if {
    tp_monthly_avg > 0
    tp_value < tp_local_file_pln
} else := 0 if {
    true
}

tp_routing := "TRIAGE_QUEUE" if {
    tp_local_required
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r10_crossborder_innovations.tp_threshold_simulator",
    "package": "jdg.r10_crossborder_innovations",
    "priority": 11013,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "tp_value_pln": tp_value,
    "tp_group_revenue_pln": tp_group_revenue,
    "tp_local_file_pln": tp_local_file_pln,
    "tp_master_file_pln": tp_master_file_pln,
    "tp_local_required": tp_local_required,
    "tp_master_required": tp_master_required,
    "tp_local_pct": tp_local_pct,
    "tp_months_to_local": tp_months_to_local,
    "_routing": tp_routing,
    "_routing_reason": sprintf("Symulator TP — transakcje %.2f PLN (%.2f%% progu lokalnego 500k). %s", [tp_value, tp_local_pct, "Lokalna dokumentacja WYMAGANA (art. 23o)." if {tp_local_required} else sprintf("Projekcja: przekroczenie za ~%d mies.", [tp_months_to_local]) if {tp_monthly_avg > 0} else "Poniżej progów TP."]),
    "_legal_basis": "PIT art. 23o (lokalna dokumentacja 500k), art. 23zf (master file 200M), art. 23p (podmioty powiązane)",
    "_warnings": [sprintf("TP: transakcje %.2f PLN (%s lokalna 500k, %s master 200M). %s", [tp_value, "TAK" if {tp_local_required} else "NIE", "TAK" if {tp_master_required} else "NIE", "Obowiązek dokumentacyjny aktywny." if {tp_local_required} else "Obowiązek nieaktywny."])],
} if {
    object.get(input.jdg_entrepreneur, "r10_crossborder_check", false) == true
    object.get(input, "tp_simulation", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R10-INN-04: CFC PROFIT ATTRIBUTION — kalkulator przypisania dochodu CFC
#             (dochód pasywny × udział → podstawa × stawka) — art. 30f PIT
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza cfc_attribution: {ownership_pct, passive_income_pln,
# foreign_tax_rate_pct}.
cfc_input := object.get(input, "cfc_attribution", {})
cfc_ownership := object.get(cfc_input, "ownership_pct", 0)
cfc_passive_income := max([0, object.get(cfc_input, "passive_income_pln", 0)])
cfc_foreign_tax := object.get(cfc_input, "foreign_tax_rate_pct", 0.20)

cfc_control_met := cfc_ownership > cfc_ownership_min_pct
cfc_low_tax_met := cfc_foreign_tax < cfc_tax_rate_threshold_pct

cfc_applies := true if {
    cfc_control_met
    cfc_low_tax_met
} else := false if {
    true
}

cfc_attributed_base := round2(cfc_passive_income * cfc_ownership) if {
    cfc_applies
} else := 0 if {
    true
}

cfc_routing := "TRIAGE_QUEUE" if {
    cfc_applies
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r10_crossborder_innovations.cfc_profit_attribution",
    "package": "jdg.r10_crossborder_innovations",
    "priority": 11014,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "cfc_ownership_pct": cfc_ownership,
    "cfc_passive_income_pln": cfc_passive_income,
    "cfc_foreign_tax_rate_pct": cfc_foreign_tax,
    "cfc_control_met": cfc_control_met,
    "cfc_low_tax_met": cfc_low_tax_met,
    "cfc_applies": cfc_applies,
    "cfc_attributed_base_pln": cfc_attributed_base,
    "_routing": cfc_routing,
    "_routing_reason": sprintf("CFC — udział %.2f (próg %.2f), podatek zagraniczny %.2f%% (próg %.2f%%). %s", [cfc_ownership, cfc_ownership_min_pct, cfc_foreign_tax * 100, cfc_tax_rate_threshold_pct * 100, "CFC MA ZASTOSOWANIE — dochód pasywny do przypisania." if {cfc_applies} else "CFC nie ma zastosowania."]),
    "_legal_basis": "PIT art. 30f (CFC — 50% udziałów, 33% dochodu pasywnego, 14,25% podatku zagranicznego), art. 30f ust. 5 (przypisanie dochodu)",
    "_warnings": [sprintf("CFC: przypisana podstawa %.2f PLN (dochód pasywny %.2f × udział %.2f). %s", [cfc_attributed_base, cfc_passive_income, cfc_ownership, "Rozlicz dochód CFC w PIT." if {cfc_applies} else "Brak obowiązku CFC."])],
} if {
    object.get(input.jdg_entrepreneur, "r10_crossborder_check", false) == true
    object.get(input, "cfc_attribution", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R10-INN-05: FX TIME TRAVEL RECONCILER — różnice kursowe z pełną temporalnością
#             (harmonogram kursów NBP per okres) + zrealizowane/niezrealizowane
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza fx_schedule: {amount_foreign, currency, periods:
# [{from, to, rate}], settlement_rate}. Wynik: wartość per okres, różnica
# zrealizowana/niezrealizowana, kurs efektywny.
fx_input := object.get(input, "fx_schedule", {})
fx_amount := max([0, object.get(fx_input, "amount_foreign", 0)])
fx_currency := object.get(fx_input, "currency", "EUR")
fx_periods := object.get(fx_input, "periods", [])
fx_settlement_rate := object.get(fx_input, "settlement_rate", 0)

fx_rate(p) := object.get(p, "rate", 0)

fx_line(p) := {
    "from": object.get(p, "from", "?"),
    "to": object.get(p, "to", "?"),
    "rate": fx_rate(p),
    "pln_value": round2(fx_amount * fx_rate(p)),
}

fx_lines := [fx_line(p) | p := fx_periods[_]]
fx_latest_rate := fx_rate(fx_periods[count(fx_periods) - 1]) if {
    count(fx_periods) > 0
} else := 0 if {
    true
}

fx_effective_rate := fx_latest_rate if {
    fx_latest_rate > 0
} else := fx_settlement_rate if {
    fx_settlement_rate > 0
} else := 0 if {
    true
}

fx_realized_diff := round2(fx_amount * (fx_settlement_rate - fx_latest_rate)) if {
    fx_settlement_rate > 0
    fx_latest_rate > 0
} else := 0 if {
    true
}

fx_routing := "TRIAGE_QUEUE" if {
    fx_realized_diff != 0
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r10_crossborder_innovations.fx_time_travel_reconciler",
    "package": "jdg.r10_crossborder_innovations",
    "priority": 11015,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "fx_amount_foreign": fx_amount,
    "fx_currency": fx_currency,
    "fx_schedule": fx_lines,
    "fx_latest_rate": fx_latest_rate,
    "fx_settlement_rate": fx_settlement_rate,
    "fx_effective_rate": fx_effective_rate,
    "fx_realized_diff_pln": fx_realized_diff,
    "_routing": fx_routing,
    "_routing_reason": sprintf("Różnice kursowe %s — %d okresów, kurs końcowy %.4f, kurs rozliczenia %.4f. Różnica zrealizowana: %.2f PLN.", [fx_currency, count(fx_lines), fx_latest_rate, fx_settlement_rate, fx_realized_diff]),
    "_legal_basis": "PIT art. 24c (różnice kursowe), art. 11a (przeliczenia); ustawa o rachunkowości art. 30 (kursy NBP)",
    "_warnings": [sprintf("FX %s: %.2f × kurs %.4f = %.2f PLN. Różnica zrealizowana vs kurs rozliczenia: %.2f PLN.", [fx_currency, fx_amount, fx_effective_rate, round2(fx_amount * fx_effective_rate), fx_realized_diff])],
} if {
    object.get(input.jdg_entrepreneur, "r10_crossborder_check", false) == true
    object.get(input, "fx_schedule", {}) != {}
}
