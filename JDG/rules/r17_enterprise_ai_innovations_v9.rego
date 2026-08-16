# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R17 GLM52 ENTERPRISE AI — INNOWACJE
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.r17_enterprise_ai_innovations
# Raport: RAPORT_17_ENTERPRISE_AI.txt (Kampania GLM 5.2 — seria 17/25)
#
# Prompt 17/25 (Enterprise AI — inteligencja systemu wokół deterministycznego
# silnika OPA). Zasada graniczna V1/V2: inteligencja REKOMENDUJE/OSTRZEGA,
# ale decyzja ewaluacyjna zawsze zostaje w deterministycznym Rego.
#   R17-INN-01 adaptive_trust_monitor — monitor Trust Score (AUTO_POST ≥0.92 /
#                                     SUGGEST ≥0.75 / ASK_USER <0.75)
#   R17-INN-02 neural_mesh_confidence_monitor — monitor pewności synapse +
#                                     konfliktów między domenami
#   R17-INN-03 cashflow_forecast_monitor — monitor prognozy 90 dni + luki
#                                     płynności (art. 44/103/47)
#   R17-INN-04 banking_psd2_monitor — monitor split payment MPP (art. 108a) +
#                                     batche + IBAN
#   R17-INN-05 legislative_change_monitor — monitor zmian legislacyjnych
#                                     (art. 4 OrdPU, vacatio legis)
#
# Zgodność: ADR-001..009/016..021/022; filary V2 (Legal Twin / invariants /
#           Decision Certificate / Law Radar / Declarative Change);
#           thresholds.enterprise_ai (zero hardcode); INV-018; First-Match-Wins.
# package: jdg.r17_enterprise_ai_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r17_enterprise_ai_innovations

import future.keywords.if
import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.r17_enterprise_ai_innovations.no_match", "package": "jdg.r17_enterprise_ai_innovations", "priority": 999999}

# ── Progi zewnętrzne (ADR-002 — zero hardcode) ────────────────────────────────
_th := object.get(object.get(data, "jdg", {}), "thresholds", {})
_th_ai := object.get(_th, "enterprise_ai", {})

trust_auto_post_min := object.get(_th_ai, "trust_auto_post_min", 0.92)
trust_suggest_min := object.get(_th_ai, "trust_suggest_min", 0.75)
mesh_confidence_min := object.get(_th_ai, "mesh_confidence_min", 0.5)
mesh_conflict_penalty := object.get(_th_ai, "mesh_conflict_penalty", 0.2)
forecast_horizon_days := object.get(_th_ai, "forecast_horizon_days", 90)
liquidity_buffer_pct := object.get(_th_ai, "liquidity_buffer_pct", 20)
split_payment_threshold_pln := object.get(_th_ai, "split_payment_threshold_pln", 15000)
batch_max_items := object.get(_th_ai, "batch_max_items", 100)
vacatio_legis_days := object.get(_th_ai, "vacatio_legis_days", 14)
impact_high_threshold := object.get(_th_ai, "impact_high_threshold", 70)

# ═══════════════════════════════════════════════════════════════════════════════
# R17-INN-01: ADAPTIVE TRUST MONITOR — Trust Score → tryb decyzyjny
#             (AUTO_POST ≥0.92 / SUGGEST ≥0.75 / ASK_USER <0.75)
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza adaptive_trust: {trust_score, feedback_count}.
at_input := object.get(input, "adaptive_trust", {})
at_trust_score := object.get(at_input, "trust_score", 0)
at_feedback_count := object.get(at_input, "feedback_count", 0)

at_mode := "AUTO_POST" if {
    at_trust_score >= trust_auto_post_min
} else := "SUGGEST" if {
    at_trust_score >= trust_suggest_min
} else := "ASK_USER" if {
    true
}

at_routing := "BLOCK_AND_ALERT" if {
    at_mode == "ASK_USER"
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r17_enterprise_ai_innovations.adaptive_trust_monitor",
    "_legal_basis": "P02 (Adaptive Trust), V1/V2 granica decyzyjna (AI rekomenduje, Rego decyduje), ADR-022 (invariants)",
    "package": "jdg.r17_enterprise_ai_innovations",
    "priority": 11046,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "at_trust_score": at_trust_score,
    "at_feedback_count": at_feedback_count,
    "at_mode": at_mode,
    "at_trust_auto_post_min": trust_auto_post_min,
    "at_trust_suggest_min": trust_suggest_min,
    "_routing": at_routing,
    "_routing_reason": sprintf("Adaptive Trust — score %.3f (progi %.2f/%.2f), feedback %d. Tryb %s. %s", [at_trust_score, trust_auto_post_min, trust_suggest_min, at_feedback_count, at_mode, "ASK_USER — decyzja wymaga księgowego (trust < próg)." if {at_mode == "ASK_USER"} else "Rekomendacja — decyzja zostaje w Rego."]),
    "_legal_basis": "P02 (Adaptive Trust), V1/V2 granica decyzyjna (AI rekomenduje, Rego decyduje), ADR-022 (invariants)",
    "_warnings": [sprintf("ADAPTIVE TRUST: tryb %s. %s", [at_mode, "poniżej progu — wymagany nadzór." if {at_mode == "ASK_USER"} else "OK."])],
} if {
    object.get(input.jdg_entrepreneur, "r17_enterprise_ai_check", false) == true
    object.get(input, "adaptive_trust", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R17-INN-02: NEURAL MESH CONFIDENCE MONITOR — pewność synapse + konflikty
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza neural_mesh: {confidence, conflict_count}.
nm_input := object.get(input, "neural_mesh", {})
nm_confidence := object.get(nm_input, "confidence", 0)
nm_conflicts := max([0, object.get(nm_input, "conflict_count", 0)])

nm_effective := nm_confidence - (nm_conflicts * mesh_conflict_penalty)
nm_reliable := nm_effective >= mesh_confidence_min

nm_routing := "BLOCK_AND_ALERT" if {
    not nm_reliable
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r17_enterprise_ai_innovations.neural_mesh_confidence_monitor",
    "_legal_basis": "P02 (Adaptive Trust), V1/V2 granica decyzyjna (AI rekomenduje, Rego decyduje), ADR-022 (invariants)",
    "package": "jdg.r17_enterprise_ai_innovations",
    "priority": 11047,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "nm_confidence": nm_confidence,
    "nm_conflicts": nm_conflicts,
    "nm_effective_confidence": nm_effective,
    "nm_reliable": nm_reliable,
    "nm_confidence_min": mesh_confidence_min,
    "_routing": nm_routing,
    "_routing_reason": sprintf("Neural Mesh — pewność %.3f, konflikty %d (kara %.2f każdy) → efektywna %.3f (próg %.2f). %s", [nm_confidence, nm_conflicts, mesh_conflict_penalty, nm_effective, mesh_confidence_min, "BLOKUJ — pewność synapse poniżej progu lub konflikty." if {not nm_reliable} else "Synapse spójna."]),
    "_legal_basis": "Neural Mesh (knowledge graph), V2 F3 (Decision Certificate), ADR-022 (invariants)",
    "_warnings": [sprintf("NEURAL MESH: %s", ["konflikt/pewność poniżej progu." if {not nm_reliable} else "spójna."])],
} if {
    object.get(input.jdg_entrepreneur, "r17_enterprise_ai_check", false) == true
    object.get(input, "neural_mesh", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R17-INN-03: CASHFLOW FORECAST MONITOR — prognoza 90 dni + luka płynności
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza cashflow: {forecast_days, liquidity_gap_pln, buffer_pct}.
cf_input := object.get(input, "cashflow", {})
cf_days := object.get(cf_input, "forecast_days", forecast_horizon_days)
cf_gap := object.get(cf_input, "liquidity_gap_pln", 0)
cf_buffer := object.get(cf_input, "buffer_pct", 0)

cf_gap_alert := cf_gap > 0
cf_buffer_ok := cf_buffer >= liquidity_buffer_pct
cf_ok := not cf_gap_alert and cf_buffer_ok

cf_routing := "BLOCK_AND_ALERT" if {
    cf_gap_alert
} else := "TRIAGE_QUEUE" if {
    not cf_buffer_ok
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r17_enterprise_ai_innovations.cashflow_forecast_monitor",
    "_legal_basis": "P02 (Adaptive Trust), V1/V2 granica decyzyjna (AI rekomenduje, Rego decyduje), ADR-022 (invariants)",
    "package": "jdg.r17_enterprise_ai_innovations",
    "priority": 11048,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "cf_forecast_days": cf_days,
    "cf_liquidity_gap_pln": cf_gap,
    "cf_buffer_pct": cf_buffer,
    "cf_gap_alert": cf_gap_alert,
    "cf_buffer_ok": cf_buffer_ok,
    "cf_buffer_min_pct": liquidity_buffer_pct,
    "_routing": cf_routing,
    "_routing_reason": sprintf("Cashflow — prognoza %d dni, luka płynności %.2f PLN, bufor %.0f%% (min %.0f%%). %s", [cf_days, cf_gap, cf_buffer, liquidity_buffer_pct, "LUKA PŁYNNOŚCI — sfinansuj zobowiązania." if {cf_gap_alert} else "Bufor poniżej minimum." if {not cf_buffer_ok} else "Płynność OK."]),
    "_legal_basis": "ustawa o VAT art. 103, ustawa o PIT art. 44, ustawa o ZUS art. 47 (terminy płatności)",
    "_warnings": [sprintf("CASHFLOW: %s", ["luka płynności." if {cf_gap_alert} else "bufor niski." if {not cf_buffer_ok} else "OK."])],
} if {
    object.get(input.jdg_entrepreneur, "r17_enterprise_ai_check", false) == true
    object.get(input, "cashflow", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R17-INN-04: BANKING PSD2 MONITOR — split payment MPP (art. 108a) + batche
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza banking: {split_payment_amount_pln, iban_valid, batch_size}.
bk_input := object.get(input, "banking", {})
bk_amount := object.get(bk_input, "split_payment_amount_pln", 0)
bk_iban := object.get(bk_input, "iban_valid", false)
bk_batch := max([0, object.get(bk_input, "batch_size", 0)])

bk_split_required := bk_amount >= split_payment_threshold_pln
bk_batch_ok := bk_batch <= batch_max_items
bk_ok := bk_iban and bk_batch_ok and (not bk_split_required or bk_split_required)

bk_routing := "BLOCK_AND_ALERT" if {
    not bk_iban or not bk_batch_ok
} else := "TRIAGE_QUEUE" if {
    bk_split_required
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r17_enterprise_ai_innovations.banking_psd2_monitor",
    "_legal_basis": "P02 (Adaptive Trust), V1/V2 granica decyzyjna (AI rekomenduje, Rego decyduje), ADR-022 (invariants)",
    "package": "jdg.r17_enterprise_ai_innovations",
    "priority": 11049,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "bk_split_payment_amount_pln": bk_amount,
    "bk_iban_valid": bk_iban,
    "bk_batch_size": bk_batch,
    "bk_split_required": bk_split_required,
    "bk_split_threshold_pln": split_payment_threshold_pln,
    "bk_batch_max_items": batch_max_items,
    "_routing": bk_routing,
    "_routing_reason": sprintf("Bankowość PSD2 — kwota %.2f PLN (próg MPP %.2f), IBAN=%s, batch %d (max %d). %s", [bk_amount, split_payment_threshold_pln, bk_iban, bk_batch, batch_max_items, "IBAN/batch niepoprawny — BLOKUJ." if {not bk_iban or not bk_batch_ok} else "Split payment wymagany (art. 108a)." if {bk_split_required} else "Płatność standardowa."]),
    "_legal_basis": "ustawa o VAT art. 108a (MPP split payment), PSD2/PolishAPI (AIS/PIS)",
    "_warnings": [sprintf("BANKING: %s", ["IBAN/batch niepoprawny." if {not bk_iban or not bk_batch_ok} else "split payment (art. 108a)." if {bk_split_required} else "OK."])],
} if {
    object.get(input.jdg_entrepreneur, "r17_enterprise_ai_check", false) == true
    object.get(input, "banking", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R17-INN-05: LEGISLATIVE CHANGE MONITOR — zmiany legislacyjne (vacatio legis)
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza legislative: {days_until_effective, impact_score, vacatio_compliant}.
lg_input := object.get(input, "legislative", {})
lg_days := object.get(lg_input, "days_until_effective", 0)
lg_impact := max([0, object.get(lg_input, "impact_score", 0)])
lg_vacatio := object.get(lg_input, "vacatio_compliant", true)

lg_high_impact := lg_impact >= impact_high_threshold
lg_urgent := lg_days <= vacatio_legis_days
lg_alert := lg_high_impact and lg_urgent and not lg_vacatio

lg_routing := "BLOCK_AND_ALERT" if {
    lg_alert
} else := "TRIAGE_QUEUE" if {
    lg_high_impact
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r17_enterprise_ai_innovations.legislative_change_monitor",
    "_legal_basis": "P02 (Adaptive Trust), V1/V2 granica decyzyjna (AI rekomenduje, Rego decyduje), ADR-022 (invariants)",
    "package": "jdg.r17_enterprise_ai_innovations",
    "priority": 11050,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "lg_days_until_effective": lg_days,
    "lg_impact_score": lg_impact,
    "lg_vacatio_compliant": lg_vacatio,
    "lg_high_impact": lg_high_impact,
    "lg_urgent": lg_urgent,
    "lg_alert": lg_alert,
    "lg_vacatio_days": vacatio_legis_days,
    "lg_impact_high_threshold": impact_high_threshold,
    "_routing": lg_routing,
    "_routing_reason": sprintf("Legislacyjny — %d dni do wejścia (vacatio %d), wpływ %.0f (próg %.0f), vacatio=%s. %s", [lg_days, vacatio_legis_days, lg_impact, impact_high_threshold, lg_vacatio, "ALERT — wysoki wpływ + brak vacatio w terminie." if {lg_alert} else "Wysoki wpływ — analizuj." if {lg_high_impact} else "Zmiana niskiego ryzyka."]),
    "_legal_basis": "OrdPU art. 4 (vacatio legis), V2 F5 (Law Radar), ISAP change detection",
    "_warnings": [sprintf("LEGISLACYJNY: %s", ["alert (wysoki wpływ, vacatio)." if {lg_alert} else "wysoki wpływ." if {lg_high_impact} else "OK."])],
} if {
    object.get(input.jdg_entrepreneur, "r17_enterprise_ai_check", false) == true
    object.get(input, "legislative", {}) != {}
}
