# NexusAI JDG — V3-18 BUNDLES + POLICIES MIRROR + RULESTORE + MIGRACJE + DEPLOY
# Przeprowadź głębokie myślenie i przeprowadź głęboką analizę przed zmianą
# progów deployu. Warstwa bramkuje WYNIKI control plane z evidence; jest
# deterministyczna, guidance-only i fail-closed (brak dowodu = FAIL).

package jdg.bundles.quality_v3_18

import future.keywords.if
import future.keywords.in

_snapshot := object.get(data.jdg.thresholds, "bundles_quality_v3_18", {})
threshold_version := object.get(_snapshot, "threshold_version", "")
registry_version := object.get(_snapshot, "registry_version", "")
legal_basis_version := object.get(_snapshot, "legal_basis_version", "")
valid_from := object.get(_snapshot, "valid_from", "")
valid_to := object.get(_snapshot, "valid_to", null)
min_rulestore_migrations := object.get(_snapshot, "min_rulestore_migrations", 0)
max_hot_reload_seconds := object.get(_snapshot, "max_hot_reload_seconds", 0)
max_rollback_mttr_min := object.get(_snapshot, "max_rollback_mttr_min", 0)
max_mirror_drift_pct := object.get(_snapshot, "max_mirror_drift_pct", 0)
max_rto_min := object.get(_snapshot, "max_rto_min", 0)
max_rpo_min := object.get(_snapshot, "max_rpo_min", 0)
dr_game_day_max_days := object.get(_snapshot, "dr_game_day_max_days", 0)

ctx := object.get(input, "bundles_quality_v3_18", {})
source_refs := object.get(ctx, "source_refs", [])
legal_nodes := object.get(ctx, "legal_nodes", [])
facts_version := object.get(ctx, "facts_version", "")
evaluation_date := object.get(ctx, "evaluation_date", "")
input_hash := object.get(ctx, "input_hash", "")
owner_approval := object.get(ctx, "owner_approval", false)
manual_recipient := object.get(ctx, "manual_recipient", "")

source_complete := count(source_refs) > 0 and count(legal_nodes) > 0 and
    legal_basis_version != ""
temporal_valid := evaluation_date != "" and facts_version != "" and
    threshold_version != "" and valid_from != ""

bundle := object.get(ctx, "bundle", {})
bundle_ok := object.get(bundle, "build_passed", false) and
    object.get(bundle, "sbom_generated", false) and
    object.get(bundle, "signature_present", false)
verify_ok := object.get(object.get(ctx, "verify", {}), "local_verify_passed", false)

overlay := object.get(ctx, "overlay", {})
overlay_ok := object.get(overlay, "matrix_pass", false) and
    count(object.get(overlay, "versions_tested", [])) > 0

mirror := object.get(ctx, "mirror", {})
mirror_drift_pct := object.get(mirror, "drift_pct", 100)
mirror_parity := object.get(mirror, "hash_parity_pct", 0)
mirror_ok := mirror_drift_pct <= max_mirror_drift_pct and mirror_parity >= 100 - max_mirror_drift_pct

rulestore := object.get(ctx, "rulestore", {})
migrations_applied := object.get(rulestore, "migrations_applied", 0)
rulestore_ok := migrations_applied >= min_rulestore_migrations and
    object.get(rulestore, "schema_versioned", false) and
    object.get(rulestore, "seeded_from_official_gazettes", false)

deploy := object.get(ctx, "deploy", {})
hot_reload_seconds := object.get(deploy, "hot_reload_seconds", -1)
canary_ok := hot_reload_seconds >= 0 and hot_reload_seconds <= max_hot_reload_seconds and
    object.get(deploy, "rollback_mttr_min", 9999) <= max_rollback_mttr_min

dr := object.get(ctx, "dr", {})
dr_ok := object.get(dr, "rto_min", 9999) <= max_rto_min and
    object.get(dr, "rpo_min", 9999) <= max_rpo_min and
    object.get(dr, "days_since_game_day", 9999) <= dr_game_day_max_days

contract_complete := bundle_ok and verify_ok and overlay_ok and mirror_ok and
    rulestore_ok and canary_ok and dr_ok and source_complete and
    temporal_valid and input_hash != ""

hard_block := not contract_complete or not owner_approval or manual_recipient == ""
bundles_state := "BUNDLES_VALIDATED" if {
    contract_complete
    not hard_block
} else := "BUNDLES_BLOCKED" if {
    true
}
routing := "BLOCK_AND_ALERT" if {
    hard_block
} else := "TRIAGE_QUEUE"

# Publiczny wynik: Delivery Certificate — nigdy czynność wdrożeniowa.
decide := {
    "matched": true,
    "rule_id": "jdg.bundles.quality_v3_18.delivery_contract",
    "package": "jdg.bundles.quality_v3_18",
    "priority": 22006,
    "stage": "V3-18",
    "state": bundles_state,
    "decision_mode": "SUGGEST",
    "mode": "DECOUPLED",
    "no_auto_post": true,
    "bundle_ok": bundle_ok,
    "verify_ok": verify_ok,
    "overlay_ok": overlay_ok,
    "mirror": {"drift_pct": mirror_drift_pct, "hash_parity_pct": mirror_parity, "ok": mirror_ok},
    "rulestore": {"migrations_applied": migrations_applied, "ok": rulestore_ok},
    "canary_ok": canary_ok,
    "hot_reload_seconds": hot_reload_seconds,
    "dr_ok": dr_ok,
    "hard_block": hard_block,
    "_routing": routing,
    "_routing_reason": "Delivery wymaga podpisanego i zweryfikowanego bundla, SBOM, testowanej macierzy overlay, 0% driftu mirrora, migracji RuleStore, canary z rollbackiem w SLA i DR w RTO/RPO.",
    "_legal_basis": "OrdPU art. 12 § 5, art. 193a; PIT art. 44-45; VAT art. 109; obwieszczenia MF (RuleStore seed); eIDAS (podpis); ADR-002; MANIFEST.md",
    "_threshold_version": threshold_version,
    "_registry_version": registry_version,
    "_valid_from": valid_from,
    "_valid_to": valid_to,
    "owner_approval": owner_approval,
    "manual_recipient": manual_recipient,
    "_warnings": [
        "V3-18 bramkuje wyniki control plane — sam nie buduje ani nie wdraża bundli.",
        "Bundle bez weryfikacji podpisu lokalnie lub drift mirrora > 0% blokują wynik.",
        "Canary bez rollbacku w SLA albo DR po terminie game-day blokują wynik.",
    ],
} if {
    object.get(input, "bundles_quality_v3_18_check", false) == true
}

default decide := {
    "matched": false,
    "rule_id": "jdg.bundles.quality_v3_18.no_match",
    "package": "jdg.bundles.quality_v3_18",
    "priority": 999999,
    "mode": "DECOUPLED",
    "no_auto_post": true,
}
