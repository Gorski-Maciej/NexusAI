# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise — Innovation 14.1: Penalty Minimization AI Engine
# v7.0 — BP-1: S23+ Expansion with success scoring + Monte Carlo + MDR/GAAR
# Package: jdg.enterprise.penalty_ai
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.enterprise.penalty_ai

import data.jdg.helpers

# ─────────────────────────────────────────────────────────────────────────────
# PAI-3000: Precedence-weighted success scoring per penalty path
# ─────────────────────────────────────────────────────────────────────────────
pai_success_scorer(path, case_data) = score {
    path_type := path
    tax_shortfall := object.get(case_data, "tax_shortfall_pln", 0)
    has_judicial_precedent := object.get(case_data, "has_favorable_ruling", false)
    kks_history := object.get(case_data, "kks_convictions", 0)

    base_scores := {
        "PATH_A_CZYNNY_ZAL": 95,
        "PATH_B_KOREKTA": 75,
        "PATH_C_ODWOLANIE": 45,
        "PATH_E_UGODA": 55,
        "PATH_D_PRZEDAWNIENIE": 85,
    }
    base := object.get(base_scores, path, 50)

    precedent_bonus := 10 { has_judicial_precedent } else := 0
    kks_penalty := -15 * kks_history { kks_history > 0 } else := 0
    amount_penalty := -10 { tax_shortfall > 500000 } else := 0

    total := min([max([base + precedent_bonus + kks_penalty + amount_penalty, 0]), 100])

    recommendation := "STRONGLY_RECOMMENDED" { total >= 80 }
    recommendation := "RECOMMENDED" { total >= 60; total < 80 }
    recommendation := "RISKY" { total < 60 }

    score := {
        "path": path,
        "base_score": base,
        "precedent_bonus": precedent_bonus,
        "history_penalty": kks_penalty,
        "amount_penalty": amount_penalty,
        "total_success_pct": total,
        "recommendation": recommendation,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# PAI-3010: Cost comparator — penalty vs interest vs advisor
# ─────────────────────────────────────────────────────────────────────────────
pai_cost_comparator(tax_shortfall, path, days_to_resolve) = comparison {
    penalty_cost := tax_shortfall * 0.30
    interest_rate_daily := 0.145 / 365  # 14.5% rocznie NBP lombard (orientacyjnie)
    interest_cost := tax_shortfall * interest_rate_daily * days_to_resolve
    advisor_cost := 0 { path == "PATH_A_CZYNNY_ZAL" }
    advisor_cost := 2000 { path == "PATH_B_KOREKTA" }
    advisor_cost := 5000 { path == "PATH_C_ODWOLANIE" }
    advisor_cost := 8000 { path == "PATH_E_UGODA" }

    total_cost := penalty_cost + interest_cost + advisor_cost
    mitigation_savings := tax_shortfall * 0.30 - total_cost

    comparison := {
        "path": path,
        "penalty_cost": penalty_cost,
        "interest_cost": interest_cost,
        "advisor_cost": advisor_cost,
        "total_cost": total_cost,
        "mitigation_savings": mitigation_savings,
        "roi_pct": mitigation_savings * 100 / max([advisor_cost, 1]),
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# PAI-3020: Monte Carlo simulator (simplified — 4 scenarios)
# ─────────────────────────────────────────────────────────────────────────────
pai_monte_carlo(input) = simulation {
    tax_shortfall := object.get(input, "tax_shortfall_pln", 0)

    best_case := {
        "scenario": "BEST_CASE",
        "probability": 0.25,
        "outcome_pln": 0,
        "path": "Czynny żal + 100% uniknięcie",
    }

    likely_case := {
        "scenario": "LIKELY_CASE",
        "probability": 0.45,
        "outcome_pln": tax_shortfall * 0.10,
        "path": "Korekta + częściowa redukcja",
    }

    worst_case := {
        "scenario": "WORST_CASE",
        "probability": 0.20,
        "outcome_pln": tax_shortfall * 0.50,
        "path": "Kara KKS + odsetki + sankcja VAT",
    }

    catastrophic := {
        "scenario": "CATASTROPHIC",
        "probability": 0.10,
        "outcome_pln": tax_shortfall * 1.30,
        "path": "Pełna odpowiedzialność KKS + sankcje + koszty sądowe",
    }

    expected_value := best_case.outcome_pln * 0.25 + likely_case.outcome_pln * 0.45 +
        worst_case.outcome_pln * 0.20 + catastrophic.outcome_pln * 0.10

    simulation := {
        "scenarios": [best_case, likely_case, worst_case, catastrophic],
        "expected_outcome_pln": expected_value,
        "range": sprintf("%.0f - %.0f PLN", [best_case.outcome_pln, catastrophic.outcome_pln]),
        "recommendation": "Natychmiastowe działanie: czynny żal LUB korekta",
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# PAI-3030: MDR/GAAR cross-check integration
# ─────────────────────────────────────────────────────────────────────────────
pai_mdr_gaar_check(input) = check {
    involves_gaar := object.get(input, "gaar_applicable", false)
    involves_mdr := object.get(input, "mdr_reportable", false)
    involves_cross_border := object.get(input, "cross_border", false)

    # risk_level: complete rules, mutually exclusive by specificity
    risk_level := "CRITICAL" { involves_gaar; involves_mdr; involves_cross_border }
    risk_level := "HIGH" { involves_gaar; involves_mdr }
    risk_level := "MEDIUM" { involves_gaar }
    risk_level := "LOW" { true }

    # routing: extracted from object
    routing := "BLOCK" { risk_level == "CRITICAL" }
    routing := "TRIAGE" { risk_level == "HIGH" }
    routing := "WARN" { risk_level == "MEDIUM" }
    routing := "PASS" { risk_level == "LOW" }

    # action_required: extracted from object
    action_required := [
        "Zgłoś MDR w ciągu 30 dni (Art. 86a OrdPU)",
        "Przygotuj GAAR Shield Detector (P19 Innovation 9.2)",
    ] { involves_mdr }
    action_required := [] { not involves_mdr }

    check := {
        "gaar_applicable": involves_gaar,
        "mdr_reportable": involves_mdr,
        "cross_border": involves_cross_border,
        "risk_level": risk_level,
        "routing": routing,
        "action_required": action_required,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# PAI-3040: Build PAI warnings
# ─────────────────────────────────────────────────────────────────────────────
build_pai_warnings(success, cost, simulation, mdr) = warnings {
    path := object.get(success, "path", "UNKNOWN")
    success_pct := object.get(success, "total_success_pct", 0)
    expected_outcome := object.get(simulation, "expected_outcome_pln", 0)
    mdr_risk := object.get(mdr, "risk_level", "LOW")

    base := [sprintf("🤖 PENALTY MINIMIZATION AI ENGINE — Ścieżka: %s", [path])]

    succ_warn := array.concat(base, [
        sprintf("   📊 Szansa powodzenia: %d%%", [success_pct]),
        sprintf("   💰 Oczekiwany wynik (Monte Carlo): %.0f PLN", [expected_outcome]),
    ])

    mdr_warn := array.concat(succ_warn, [
        sprintf("   ⚠️ MDR/GAAR: %s — wymagane zgłoszenie!", [mdr_risk]),
    ]) { mdr_risk != "LOW" }

    mdr_warn := succ_warn { mdr_risk == "LOW" }

    warnings := mdr_warn
}
