# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests — ETAP 16 KKS + Ordynacja
# Package: jdg.kks_ord_etap16
# Coverage: risk scoring, evidence chain, czynny żal, sankcje,
#           przedawnienia, korekty/odsetki/nadpłaty/ulgi, deadline engine
# ═══════════════════════════════════════════════════════════════

package test_jdg_kks_ord_etap16

import data.jdg.kks_ord_etap16

ctx := {
    "evaluation_datetime": "2026-08-20T00:00:00Z",
    "evaluation_year": "2026",
    "threshold_version": "v9.0.0",
    "legal_basis_version": "v9.0.0",
    "facts_version": "v9.0.0",
}

# ── 1. RISK SCORING ───────────────────────────────────────────
test_risk_low_exposure {
    result := kks_ord_etap16.decide with input as object.union(ctx, {
        "kks_ord_etap16_check": true,
        "risk": {"exposure_pln": 1000},
    })
    result.risk_scoring.class == "LOW"
}

test_risk_critical_with_intent_and_recidivism {
    result := kks_ord_etap16.decide with input as object.union(ctx, {
        "kks_ord_etap16_check": true,
        "risk": {"exposure_pln": 1000000, "intentional": true, "recidivism": true},
    })
    result.risk_scoring.class == "CRITICAL"
    result.routing == "TRIAGE_QUEUE"
}

test_property_risk_score_in_range {
    result := kks_ord_etap16.decide with input as object.union(ctx, {
        "kks_ord_etap16_check": true,
        "risk": {"exposure_pln": 500000},
    })
    result.property_invariants.risk_in_range == true
}

# ── 2. EVIDENCE CHAIN ─────────────────────────────────────────
test_positive_evidence_chain_present {
    result := kks_ord_etap16.decide with input as object.union(ctx, {"kks_ord_etap16_check": true})
    result.evidence_chain.count == 10
}

# ── 3. CZYNNY ŻAL + DISCLAIMER ────────────────────────────────
test_property_voluntary_disclosure_not_automatic {
    result := kks_ord_etap16.decide with input as object.union(ctx, {
        "kks_ord_etap16_check": true,
        "kks_ord": {"voluntary_disclosure": true, "disclosure_before_detection": true, "disclosure_paid": true},
    })
    result.voluntary_disclosure.eligible == true
    result.voluntary_disclosure.automatic == false
    result.property_invariants.disclaimer_present == true
}

test_negative_voluntary_disclosure_not_eligible {
    result := kks_ord_etap16.decide with input as object.union(ctx, {
        "kks_ord_etap16_check": true,
        "kks_ord": {"voluntary_disclosure": true, "disclosure_before_detection": false, "disclosure_paid": true},
    })
    result.voluntary_disclosure.eligible == false
}

# ── 4. SANKCJE + MATERIALNOŚĆ ─────────────────────────────────
test_boundary_materiality_felony_above_threshold {
    result := kks_ord_etap16.decide with input as object.union(ctx, {
        "kks_ord_etap16_check": true,
        "risk": {"exposure_pln": 1000000},
        "kks_ord": {"penalty_multiplier": 100},
    })
    result.sanctions.materiality == "FELONY"
    result.sanctions.penalty_amount > 0
}

test_property_penalty_non_negative {
    result := kks_ord_etap16.decide with input as object.union(ctx, {
        "kks_ord_etap16_check": true,
        "kks_ord": {"penalty_multiplier": 0},
    })
    result.property_invariants.penalty_non_negative == true
}

# ── 5. PRZEDAWNIENIE ──────────────────────────────────────────
test_temporal_limitation_expired {
    result := kks_ord_etap16.decide with input as object.union(ctx, {
        "kks_ord_etap16_check": true,
        "risk": {"exposure_pln": 1000},
        "kks_ord": {"offense_year": 2019},
    })
    result.limitation.expired == true
}

test_temporal_limitation_not_expired {
    result := kks_ord_etap16.decide with input as object.union(ctx, {
        "kks_ord_etap16_check": true,
        "risk": {"exposure_pln": 1000},
        "kks_ord": {"offense_year": 2024},
    })
    result.limitation.expired == false
}

# ── 6. DEADLINE ENGINE ────────────────────────────────────────
test_boundary_deadline_red_overdue {
    result := kks_ord_etap16.decide with input as object.union(ctx, {
        "kks_ord_etap16_check": true,
        "kks_ord": {"deadline_days": 0},
    })
    result.deadline.level == "RED"
    result.deadline.overdue == true
    result.routing == "TRIAGE_QUEUE"
}

test_boundary_deadline_amber_soon {
    result := kks_ord_etap16.decide with input as object.union(ctx, {
        "kks_ord_etap16_check": true,
        "kks_ord": {"deadline_days": 10},
    })
    result.deadline.level == "AMBER"
}

test_boundary_deadline_green {
    result := kks_ord_etap16.decide with input as object.union(ctx, {
        "kks_ord_etap16_check": true,
        "kks_ord": {"deadline_days": 30},
    })
    result.deadline.level == "GREEN"
}

# ── 7. NO_MATCH (default — brak flagi) ────────────────────────
test_no_match_without_activation_flag {
    result := kks_ord_etap16.decide with input as object.union(ctx, {})
    result.matched == false
    result.rule_id == "jdg.kks_ord_etap16.no_match"
}
