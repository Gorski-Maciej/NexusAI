# NexusAI JDG — V3-15 ENTERPRISE INITIATIVES / NEURAL MESH / SCORING
# Przeprowadź głębokie myślenie i przeprowadź głęboką analizę przed zmianą
# scoringu. Warstwa jest deterministyczna, guidance-only i fail-closed.

package jdg.enterprise.quality_v3_15

import future.keywords.if
import future.keywords.in

_snapshot := object.get(data.jdg.thresholds, "enterprise_quality_v3_15", {})
threshold_version := object.get(_snapshot, "threshold_version", "")
registry_version := object.get(_snapshot, "registry_version", "")
legal_basis_version := object.get(_snapshot, "legal_basis_version", "")
valid_from := object.get(_snapshot, "valid_from", "")
valid_to := object.get(_snapshot, "valid_to", null)
score_auto_post_min := object.get(_snapshot, "score_auto_post_min", 0)
score_suggest_min := object.get(_snapshot, "score_suggest_min", 0)
score_abstain_max := object.get(_snapshot, "score_abstain_max", 0)
calibration_min_samples := object.get(_snapshot, "calibration_min_samples", 0)
max_conflicts_for_suggest := object.get(_snapshot, "max_conflicts_for_suggest", 0)

ctx := object.get(input, "enterprise_quality_v3_15", {})
initiatives := object.get(ctx, "initiatives", [])
initiative_registry := object.get(ctx, "initiative_registry", [])
source_refs := object.get(ctx, "source_refs", [])
legal_nodes := object.get(ctx, "legal_nodes", [])
facts_version := object.get(ctx, "facts_version", "")
evaluation_date := object.get(ctx, "evaluation_date", "")
input_hash := object.get(ctx, "input_hash", "")
owner_approval := object.get(ctx, "owner_approval", false)
manual_recipient := object.get(ctx, "manual_recipient", "")

initiative_ids := [id |
    item := initiatives[_]
    id := object.get(item, "id", "")
]
required_ids := [sprintf("S%d", [n]) | n := numbers.range(1, 24)]
missing_initiatives := [id | id := required_ids[_]; not id in initiative_ids]
initiative_registry_missing := [id |
    id := initiative_ids[_]
    count([item | item := initiative_registry[_]; object.get(item, "id", "") == id]) == 0
]
initiative_registry_complete := count(initiatives) >= 24 and
    count(missing_initiatives) == 0 and count(initiative_registry_missing) == 0 and
    registry_version != ""

source_complete := count(source_refs) > 0 and count(legal_nodes) > 0 and
    legal_basis_version != ""
temporal_valid := evaluation_date != "" and facts_version != "" and
    threshold_version != "" and valid_from != ""

scoring := object.get(ctx, "scoring", {})
scoring_samples := object.get(scoring, "sample_count", 0)
scoring_accuracy := object.get(scoring, "accuracy", 0)
scoring_brier := object.get(scoring, "brier_score", 1)
scoring_calibrated := scoring_samples >= calibration_min_samples and
    scoring_accuracy >= object.get(_snapshot, "calibration_accuracy_min", 0) and
    scoring_brier <= object.get(_snapshot, "calibration_brier_max", 1)
score := object.get(scoring, "score", 0)
score_range_valid := score >= 0 and score <= 100
score_class := "AUTO_CANDIDATE" if {
    score >= score_auto_post_min
} else := "SUGGEST" if {
    score >= score_suggest_min
} else := "ABSTAIN" if {
    score <= score_abstain_max
} else := "MANUAL_REVIEW" if {
    true
}

mesh := object.get(ctx, "mesh", {})
mesh_nodes := object.get(mesh, "nodes", [])
mesh_edges := object.get(mesh, "edges", [])
mesh_conflicts := object.get(mesh, "conflicts", [])
mesh_version := object.get(mesh, "version", "")
mesh_nodes_complete := count(mesh_nodes) >= object.get(_snapshot, "min_mesh_nodes", 0)
mesh_edges_complete := count(mesh_edges) >= object.get(_snapshot, "min_mesh_edges", 0)
mesh_conflict_free := count(mesh_conflicts) == 0
mesh_complete := mesh_nodes_complete and mesh_edges_complete and mesh_version != ""

composer := object.get(ctx, "composer", {})
composer_inputs := object.get(composer, "inputs", [])
composer_evidence := object.get(composer, "evidence_refs", [])
composer_tests := object.get(composer, "test_refs", [])
composer_complete := count(composer_inputs) > 0 and count(composer_evidence) > 0 and
    count(composer_tests) > 0 and object.get(composer, "deterministic", false)

red_team := object.get(ctx, "red_team", {})
red_team_complete := object.get(red_team, "scenarios", 0) >= object.get(_snapshot, "min_red_team_scenarios", 0) and
    object.get(red_team, "undetected_failures", 1) == 0

contract_complete := initiative_registry_complete and source_complete and temporal_valid and
    scoring_calibrated and score_range_valid and mesh_complete and mesh_conflict_free and
    composer_complete and red_team_complete and input_hash != ""
hard_block := not contract_complete or not owner_approval or manual_recipient == ""
contract_state := "ENTERPRISE_VALIDATED" if {
    contract_complete
    not hard_block
} else := "ENTERPRISE_BLOCKED" if {
    true
}
routing := "BLOCK_AND_ALERT" if {
    hard_block
} else := "TRIAGE_QUEUE"

# Enterprise Decision Certificate: recommendation is never an external action.
decide := {
    "matched": true,
    "rule_id": "jdg.enterprise.quality_v3_15.enterprise_initiatives_contract",
    "package": "jdg.enterprise.quality_v3_15",
    "priority": 22003,
    "stage": "V3-15",
    "state": contract_state,
    "decision_mode": "SUGGEST",
    "mode": "DECOUPLED",
    "no_auto_post": true,
    "initiative_registry_complete": initiative_registry_complete,
    "missing_initiatives": missing_initiatives,
    "source_complete": source_complete,
    "temporal_valid": temporal_valid,
    "scoring": {"score": score, "class": score_class, "calibrated": scoring_calibrated, "sample_count": scoring_samples, "accuracy": scoring_accuracy, "brier_score": scoring_brier},
    "mesh": {"complete": mesh_complete, "nodes": count(mesh_nodes), "edges": count(mesh_edges), "conflicts": mesh_conflicts, "version": mesh_version},
    "composer_complete": composer_complete,
    "red_team_complete": red_team_complete,
    "hard_block": hard_block,
    "_routing": routing,
    "_routing_reason": "S1-S24 + Neural Mesh wymagają kalibracji, grafu, evidence, testów, źródeł prawnych i ręcznego odbiorcy.",
    "_legal_basis": "PIT art. 27, 30c, 30ca; VAT art. 86, 113; OrdPU art. 70, 119a; KKS art. 16, 54-62; SUS art. 18a-18c; UoR art. 2; AML; RODO; eIDAS",
    "_threshold_version": threshold_version,
    "_registry_version": registry_version,
    "_valid_from": valid_from,
    "_valid_to": valid_to,
    "owner_approval": owner_approval,
    "manual_recipient": manual_recipient,
    "_warnings": [
        "Scoring jest rekomendacją i wymaga kalibracji na danych zatwierdzonych przez właściciela.",
        "Neural Mesh nie może samodzielnie wykonać płatności, wysyłki ani AUTO_POST.",
        "Konflikt, brak evidence, brak kalibracji lub brak odbiorcy blokuje wynik.",
    ],
} if {
    object.get(input, "enterprise_quality_v3_15_check", false) == true
}

default decide := {
    "matched": false,
    "rule_id": "jdg.enterprise.quality_v3_15.no_match",
    "package": "jdg.enterprise.quality_v3_15",
    "priority": 999999,
    "mode": "DECOUPLED",
    "no_auto_post": true,
}
