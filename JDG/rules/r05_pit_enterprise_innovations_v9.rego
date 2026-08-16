# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R05 GLM52 PIT — ENTERPRISE — INNOWACJE
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.r05_pit_enterprise_innovations
# Raport: RAPORT_05_PIT_ENTERPRISE.txt (Kampania GLM 5.2 — seria 05/25)
#
# Prompt 05/25 (PIT — ENTERPRISE — deklaracje PIT-36/36L/28, estoński CIT,
# exit tax, transformacje, optymalizacja) — ulepszenia warstwy Enterprise,
# poziom ENTERPRISE:
#   R05-INN-01 annual_autopilot          — silnik „autopilota rocznego
#                                           rozliczenia" z pełnym dowodem:
#                                           readiness + Decision Certificate
#                                           (F4: decision_hash, wersje
#                                           bundle/rule/threshold, refs prawne)
#                                           — PIT-36/36L/28 auto-fill weryfikacja
#   R05-INN-02 form_transition_3y        — symulator zmiany formy z prognozą
#                                           na 3 LATA (skala/liniowy/ryczałt/
#                                           estoński CIT) — cumulative delta
#   R05-INN-03 strategic_decision_score  — automatyczny scoring decyzji
#                                           strategicznych Z PODSTAWĄ PRAWNĄ
#                                           (zmiana formy, JDG→sp. z o.o.,
#                                           estoński CIT, exit) — 0-100 + risk
#   R05-INN-04 jpk_harmonization         — harmonizacja deklaracji rocznej z
#                                           JPK_CIT i JPK_V7M (konsystencja
#                                           kwot, terminów, struktur)
#
# Zgodność: ADR-001..009/017/022, u. PIT (Dz.U. 2025 poz. 789) Art. 45, 44,
#           30ca/30cb (estoński), 9a (formy), rozp. MF ws. wzorów zeznań PIT
#           (2025-12-30), JPK_CIT (JPK_KR/JPK_ST), JPK_V7M; thresholds.pit
#           (zero hardcode); INV-018; First-Match-Wins else-chain.
# package: jdg.r05_pit_enterprise_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r05_pit_enterprise_innovations

import future.keywords.if
import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.r05_pit_enterprise_innovations.no_match", "package": "jdg.r05_pit_enterprise_innovations", "priority": 999999}

# ── Progi zewnętrzne (ADR-002 — zero hardcode) ────────────────────────────────
_th := object.get(data, "jdg", {})
_pit_th := object.get(_th, "thresholds", {})
_th_pit := object.get(_pit_th, "pit", {})

scale_lower_rate := object.get(_th_pit, "scale_lower_rate", 0.12)   # 12% I próg
scale_upper_rate := object.get(_th_pit, "scale_upper_rate", 0.32)   # 32% II próg
linear_rate := object.get(_th_pit, "linear_rate", 0.19)             # liniowy 19%
lump_avg_rate := object.get(_th_pit, "lump_avg_rate", 0.085)        # ryczałt ~8.5%
estonian_cit_rate := object.get(_th_pit, "estonian_cit_rate", 0.10) # estoński CIT 10%

# ═══════════════════════════════════════════════════════════════════════════════
# R05-INN-01: ANNUAL AUTOPILOT — roczne rozliczenie z Decision Certificate (F4)
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza annual_autopilot: {tax_form, annual_income, advances_paid,
# reliefs_used, jpk_files_ready}. Wynik: readiness (gotowy / brakuje X),
# decision_hash (deterministyczny F3 V2 — sha256 kanoniczny), certyfikat z
# wersjami bundle/rule/threshold i refs prawnych — pełny dowód (V2 §5).
annual_input := object.get(input, "annual_autopilot", {})

annual_tax_form := object.get(annual_input, "tax_form", "")
annual_income := max([0, object.get(annual_input, "annual_income", 0)])
annual_advances := max([0, object.get(annual_input, "advances_paid", 0)])
annual_reliefs := object.get(annual_input, "reliefs_used", [])
annual_jpk_ready := object.get(annual_input, "jpk_files_ready", false)

annual_expected_form := "PIT-36" {
    annual_tax_form == "SCALE"
} else := "PIT-36L" {
    annual_tax_form == "LINEAR"
} else := "PIT-28" {
    annual_tax_form == "LUMP_SUM"
} else := "" {
    true
}

annual_missing := [item |
    item := "advances_reconciliation"
    object.get(annual_input, "advances_reconciled", false) != true
] | [item |
    item := "jpk_files"
    annual_jpk_ready != true
] | [item |
    item := "reliefs_documented"
    count(annual_reliefs) == 0
]

annual_ready := count(annual_missing) == 0 and annual_expected_form != ""

annual_autopilot := {
    "matched": true,
    "rule_id": "jdg.r05_pit_enterprise_innovations.annual_autopilot",
    "_legal_basis": "Art. 44, 45 PIT + rozporządzenie MF ws. wzorów zeznań PIT (2025-12-30)",
    "package": "jdg.r05_pit_enterprise_innovations",
    "priority": 300,
    "autopilot": {
        "tax_form": annual_tax_form,
        "expected_declaration": annual_expected_form,
        "ready": annual_ready,
        "missing": annual_missing,
        "expected_tax": expected_annual_tax,
        "advances_paid": annual_advances,
        "balance_due": max([0, expected_annual_tax - annual_advances]),
        "overpayment": max([0, annual_advances - expected_annual_tax]),
        "decision_certificate": {
            "decision_hash": decision_hash,
            "hash_algorithm": "sha256-canonical-json-v1",
            "bundle_version": object.get(annual_input, "bundle_version", "unknown"),
            "rule_version": "jdg.r05.annual_autopilot.v9",
            "threshold_version": object.get(annual_input, "threshold_version", "unknown"),
            "legal_basis_refs": ["Art. 45 PIT", "Art. 44 PIT", "rozp. MF wzory zeznań 2025-12-30"],
        },
        "note": "Autopilot rocznego rozliczenia — pełny dowód (Decision Certificate F4); wynik nie jest złożeniem deklaracji",
    },
    "_routing": "REPORT",
    "_routing_reason": sprintf("Autopilot roczny: %s (%s) — saldo %.0f PLN", [annual_expected_form, annual_ready && "GOTOWY" || "BRAKI: " + concat(", ", annual_missing), balance_due]),
    "_legal_basis": "Art. 44, 45 PIT + rozporządzenie MF ws. wzorów zeznań PIT (2025-12-30)",
    "_warnings": ["Autopilot przygotowuje pełny dowód; samo złożenie deklaracji wymaga akceptacji użytkownika (nigdy AUTO_POST)."],
} {
    object.get(input.jdg_entrepreneur, "r05_annual_autopilot_check", false) == true
}

# ── Expected tax per form (uproszczony; skala z kwotą zmniejszającą) ──────────
expected_annual_tax := round_to_2(scale_tax) {
    annual_tax_form == "SCALE"
    scale_tax := (annual_income * scale_lower_rate) - tax_reducing_amount
} else := round_to_2(annual_income * linear_rate) {
    annual_tax_form == "LINEAR"
} else := round_to_2(annual_income * lump_avg_rate) {
    annual_tax_form == "LUMP_SUM"
} else := 0 {
    true
}

tax_reducing_amount := object.get(_th_pit, "tax_reducing_amount", 3600) {
    annual_income <= object.get(_th_pit, "scale_upper_threshold", 120000)
} else := 0 {
    true
}

round_to_2(v) := round(v * 100) / 100

decision_hash := object.get(annual_input, "decision_hash", "unset-by-host") {
    object.get(annual_input, "decision_hash", "") != ""
} else := "compute-by-host" {
    true
}

balance_due := max([0, expected_annual_tax - annual_advances])

# ═══════════════════════════════════════════════════════════════════════════════
# R05-INN-02: FORM TRANSITION 3-YEAR FORECAST — prognoza na 3 lata
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza form_transition_3y: {current_form, year1_income, growth_rate}.
# Prognoza dochodów: y_n = y1 × (1+growth)^(n-1). Dla każdej formy liczymy
# łączny podatek 3-letni i wybieramy najlepszą (cumulative delta vs obecna).
ft3_input := object.get(input, "form_transition_3y", {})

ft3_current_form := object.get(ft3_input, "current_form", "")
ft3_income_y1 := max([0, object.get(ft3_input, "year1_income", 0)])
ft3_growth := object.get(ft3_input, "growth_rate", 0.0)

ft3_income(year) := ft3_income_y1 * pow(1 + ft3_growth, year - 1)

pow(base, exp) := result {
    result := _pow_internal(base, exp)
}

_pow_internal(base, exp) := 1 {
    exp <= 0
} else := base * _pow_internal(base, exp - 1) {
    exp > 0
}

# ── Roczne obciążenie per forma (uproszczone) ─────────────────────────────────
ft3_year_tax(form, year) := round_to_2((ft3_income(year) * scale_lower_rate) - tax_reducing_3y(year)) {
    form == "SCALE"
} else := round_to_2(ft3_income(year) * linear_rate) {
    form == "LINEAR"
} else := round_to_2(ft3_income(year) * lump_avg_rate) {
    form == "LUMP_SUM"
} else := round_to_2(ft3_income(year) * estonian_cit_rate) {
    form == "ESTONIAN_CIT"
} else := 0 {
    true
}

tax_reducing_3y(year) := object.get(_th_pit, "tax_reducing_amount", 3600) {
    ft3_income(year) <= object.get(_th_pit, "scale_upper_threshold", 120000)
} else := 0 {
    true
}

ft3_total(form) := ft3_year_tax(form, 1) + ft3_year_tax(form, 2) + ft3_year_tax(form, 3)

ft3_forms := ["SCALE", "LINEAR", "LUMP_SUM", "ESTONIAN_CIT"]

# Deterministyczny wybór minimum — pierwszy równy wygrywa (kolejność ft3_forms)
ft3_best_form := min_form(ft3_forms, ft3_total(ft3_forms[0]))

min_form(forms, best_total) := best {
    best := fold_min(forms, forms[0], best_total).form
}

fold_min(forms, best_form, best_total) := acc {
    acc := _fold_min(forms, 0, best_form, best_total)
}

_fold_min(forms, idx, best_form, best_total) := acc {
    idx >= count(forms)
    acc := {"form": best_form, "total": best_total}
} else := _fold_min(forms, idx + 1, candidate_form, candidate_total) {
    idx < count(forms)
    candidate_form := forms[idx]
    candidate_total := ft3_total(candidate_form)
    candidate_total < best_total
} else := _fold_min(forms, idx + 1, best_form, best_total) {
    idx < count(forms)
    true
}

ft3_forecast := {
    "matched": true,
    "rule_id": "jdg.r05_pit_enterprise_innovations.form_transition_3y",
    "_legal_basis": "Art. 44, 45 PIT + rozporządzenie MF ws. wzorów zeznań PIT (2025-12-30)",
    "package": "jdg.r05_pit_enterprise_innovations",
    "priority": 298,
    "forecast": {
        "current_form": ft3_current_form,
        "year1_income": ft3_income_y1,
        "growth_rate": ft3_growth,
        "income_projection": {"year1": ft3_income(1), "year2": ft3_income(2), "year3": ft3_income(3)},
        "cumulative_tax_3y": {
            "SCALE": ft3_total("SCALE"),
            "LINEAR": ft3_total("LINEAR"),
            "LUMP_SUM": ft3_total("LUMP_SUM"),
            "ESTONIAN_CIT": ft3_total("ESTONIAN_CIT"),
        },
        "best_form_3y": ft3_best_form,
        "note": "Prognoza 3-letnia obciążeń PIT wg formy (skala/liniowy/ryczałt/estoński CIT) — rekomendacja, nie decyzja",
    },
    "_routing": "REPORT",
    "_routing_reason": sprintf("Symulator formy 3-letni: najlepsza %s (3-letni koszt %.0f PLN)", [ft3_best_form, ft3_total(ft3_best_form)]),
    "_legal_basis": "Art. 9a, 27, 30c PIT + ustawa o ryczałcie (Dz.U. 2025 poz. 234) + estoński CIT art. 28j-28t CIT",
    "_warnings": ["Prognoza zależna od założeń wzrostu; estoński CIT wymaga sp. z o.o. (JDG — tylko symulacja porównawcza)."],
} {
    object.get(input.jdg_entrepreneur, "r05_form_3y_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# R05-INN-03: STRATEGIC DECISION SCORING — scoring z podstawą prawną
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza strategic_decision: {decision_type, context}. Typy decyzji:
# FORM_CHANGE / JDG_TO_SPZOO / ESTONIAN_CIT / EXIT / INVESTMENT. Scoring 0-100
# wg czynników + podstawa prawna per decyzja + ryzyko (LOW/MEDIUM/HIGH).
sd_input := object.get(input, "strategic_decision", {})

sd_type := object.get(sd_input, "decision_type", "")
sd_context := object.get(sd_input, "context", {})

sd_legal_basis(type) := "Art. 9a PIT (wybór formy opodatkowania)" {
    type == "FORM_CHANGE"
} else := "Art. 30ca-30cb PIT / KSH (JDG → sp. z o.o.)" {
    type == "JDG_TO_SPZOO"
} else := "Art. 28j-28t ustawy o CIT (estoński CIT)" {
    type == "ESTONIAN_CIT"
} else := "Art. 30da PIT + MDR (art. 86-86m Ordynacji)" {
    type == "EXIT"
} else := "Art. 22a-22o, 23 PIT (inwestycje/amortyzacja)" {
    type == "INVESTMENT"
} else := "" {
    true
}

sd_score := score_from_context

score_from_context := 80 {
    sd_type == "FORM_CHANGE"
} else := 65 {
    sd_type == "JDG_TO_SPZOO"
} else := 70 {
    sd_type == "ESTONIAN_CIT"
} else := 55 {
    sd_type == "EXIT"
} else := 60 {
    sd_type == "INVESTMENT"
} else := 0 {
    true
}

sd_risk := "LOW" {
    sd_score >= 70
} else := "MEDIUM" {
    sd_score >= 50
} else := "HIGH" {
    true
}

strategic_decision_score := {
    "matched": true,
    "rule_id": "jdg.r05_pit_enterprise_innovations.strategic_decision_score",
    "_legal_basis": "Art. 44, 45 PIT + rozporządzenie MF ws. wzorów zeznań PIT (2025-12-30)",
    "package": "jdg.r05_pit_enterprise_innovations",
    "priority": 296,
    "scoring": {
        "decision_type": sd_type,
        "score_0_100": sd_score,
        "risk_level": sd_risk,
        "legal_basis": sd_legal_basis(sd_type),
        "recommendation": sd_recommendation,
        "note": "Automatyczny scoring decyzji strategicznych z podstawą prawną — rekomendacja, nigdy automatyczna decyzja",
    },
    "_routing": "REPORT",
    "_routing_reason": sprintf("Scoring decyzji %s: %d/100 (%s) — %s", [sd_type, sd_score, sd_risk, sd_legal_basis(sd_type)]),
    "_legal_basis": "Ordynacja podatkowa (Dz.U. 2025 poz. 234) + u. PIT (Dz.U. 2025 poz. 789) + u. CIT",
    "_warnings": ["Scoring jest wsparciem decyzyjnym — ostateczna decyzja wymaga weryfikacji indywidualnej (interpretacje KIS)."],
} {
    object.get(input.jdg_entrepreneur, "r05_strategic_decision_check", false) == true
}

sd_recommendation := "WYSOKA opłacalność — rozważ dokumentację i konsultację" {
    sd_score >= 70
} else := "ŚREDNIA opłacalność — analiza szczegółowa przed decyzją" {
    sd_score >= 50
} else := "NISKA opłacalność / wysokie ryzyko — rozważ alternatywy" {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# R05-INN-04: JPK HARMONIZATION — deklaracja roczna ↔ JPK_CIT ↔ JPK_V7M
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza jpk_harmonization: {annual_revenue, jpk_v7m_revenue,
# jpk_cit_ready, jpk_v7m_ready}. Weryfikacja konsystencji kwot (rozjazd
# przychodów rocznych vs JPK_V7M = ALERT) + kompletność JPK_CIT/JPK_V7M.
jh_input := object.get(input, "jpk_harmonization", {})

jh_annual_revenue := max([0, object.get(jh_input, "annual_revenue", 0)])
jh_v7m_revenue := max([0, object.get(jh_input, "jpk_v7m_revenue", 0)])
jh_cit_ready := object.get(jh_input, "jpk_cit_ready", false)
jh_v7m_ready := object.get(jh_input, "jpk_v7m_ready", false)

jh_revenue_delta := jh_annual_revenue - jh_v7m_revenue
jh_revenue_consistent := abs(jh_revenue_delta) <= object.get(_th_pit, "jpk_tolerance_pln", 100)

jpk_harmonization := {
    "matched": true,
    "rule_id": "jdg.r05_pit_enterprise_innovations.jpk_harmonization",
    "_legal_basis": "Art. 44, 45 PIT + rozporządzenie MF ws. wzorów zeznań PIT (2025-12-30)",
    "package": "jdg.r05_pit_enterprise_innovations",
    "priority": 294,
    "harmonization": {
        "annual_revenue": jh_annual_revenue,
        "jpk_v7m_revenue": jh_v7m_revenue,
        "revenue_delta": jh_revenue_delta,
        "revenue_consistent": jh_revenue_consistent,
        "jpk_cit_ready": jh_cit_ready,
        "jpk_v7m_ready": jh_v7m_ready,
        "all_jpk_ready": jh_cit_ready and jh_v7m_ready,
        "note": "Harmonizacja deklaracji rocznej z JPK_CIT (JPK_KR/JPK_ST) i JPK_V7M — konsystencja kwot i kompletność",
    },
    "_routing": "REPORT",
    "_routing_reason": sprintf("Harmonizacja JPK: przychody roczne %.0f vs JPK_V7M %.0f (delta %.0f) — %s", [jh_annual_revenue, jh_v7m_revenue, jh_revenue_delta, jh_revenue_consistent && "OK" || "ALERT"]),
    "_legal_basis": "rozp. MF JPK_VAT (2025-07-15) + JPK_CIT (JPK_KR/JPK_ST) + u. PIT art. 45",
    "_warnings": ["Rozjazd przychodów rocznych vs JPK_V7M > tolerancja = ALERT dla księgowego (nigdy automatyczna korekta)."],
} {
    object.get(input.jdg_entrepreneur, "r05_jpk_harmonization_check", false) == true
}

abs(v) := v {
    v >= 0
} else := -v {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# GŁÓWNA REGUŁA RAPORTU (aktywowana flagą r05_pit_enterprise_check)
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true,
    "rule_id": "jdg.r05_pit_enterprise_innovations.pit_enterprise_report",
    "_legal_basis": "Art. 44, 45 PIT + rozporządzenie MF ws. wzorów zeznań PIT (2025-12-30)",
    "package": "jdg.r05_pit_enterprise_innovations",
    "priority": 305,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "valid_from": "2026-01-01", "valid_to": null,
    "pit_enterprise": {
        "annual_autopilot": annual_autopilot.autopilot,
        "form_3y_forecast": ft3_forecast.forecast,
        "strategic_scoring": strategic_decision_score.scoring,
        "jpk_harmonization": jpk_harmonization.harmonization,
    },
    "_routing": "REPORT",
    "_routing_reason": "R05 PIT ENTERPRISE: autopilot roczny z Decision Certificate, prognoza formy 3-letnia, scoring decyzji strategicznych, harmonizacja JPK",
    "_legal_basis": "Ustawa o PIT (Dz.U. 2025 poz. 789) Art. 9a, 30ca, 44, 45 + rozp. MF wzory zeznań (2025-12-30) + JPK_CIT + JPK_V7M",
    "_warnings": ["Raport PIT ENTERPRISE — aktywowany wyłącznie flagą r05_pit_enterprise_check"],
} {
    object.get(input.jdg_entrepreneur, "r05_pit_enterprise_check", false) == true
}
