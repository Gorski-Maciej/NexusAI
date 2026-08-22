# NexusAI JDG — ETAP 25 TOOLS / API / RULESTORE / BUNDLES CONTROL-DATA PLANE
# Governance nad control/data plane: OpenAPI vs artefakty, JWT/RBAC/SoD,
# idempotencja, wersjonowanie, migracje+constraints, bundle (podpis/SBOM/
# node verify/persist healthy), progressive delivery (canary/shadow/ramped/
# soak/rollback), hot-reload, WORM/Merkle audit i disaster recovery.
# Każda bramka fail-closed; mock nie deklaruje się jako production.

package jdg.tools_api_rulestore_bundles_etap25

import future.keywords.if
import future.keywords.in

decision_mode := "SUGGEST"

default decide := {
    "matched": false,
    "rule_id": "jdg.tools_api_rulestore_bundles_etap25.no_match",
    "package": "jdg.tools_api_rulestore_bundles_etap25",
    "priority": 999996,
    "decision_mode": "SUGGEST",
    "no_auto_post": true,
}

_thresholds := object.get(object.get(data, "jdg", {}), "thresholds", {})
_et25 := object.get(_thresholds, "tools_api_rulestore_bundles_etap25", {})
registry_version := object.get(_et25, "registry_version", "tools-api-rulestore-bundles-etap25-2026.08")
legal_basis_version := object.get(_et25, "legal_basis_version", "control-data-plane-2026.08")
min_canary_pct := object.get(_et25, "min_canary_pct", 5)
max_shadow_delta_pct := object.get(_et25, "max_shadow_delta_pct", 2.0)
soak_hours := object.get(_et25, "soak_hours", 24)
max_rollback_mttr_min := object.get(_et25, "max_rollback_mttr_min", 5)
hot_reload_sla_min := object.get(_et25, "hot_reload_sla_min", 15)
max_rpo_min := object.get(_et25, "max_rpo_min", 15)
max_rto_min := object.get(_et25, "max_rto_min", 30)

ctx := object.get(input, "tools_api_rulestore_bundles_etap25", {})
activated := object.get(object.get(input, "jdg_entrepreneur", {}), "tools_api_rulestore_bundles_etap25_check", false)
evaluation_date := object.get(ctx, "evaluation_date", "")
run_id := object.get(ctx, "run_id", "")
evidence_refs := object.get(ctx, "evidence_refs", [])

# ── API: OpenAPI spójność z artefaktami ───────────────────────────────────
api := object.get(ctx, "api", {})
api_schema_consistent := object.get(api, "openapi_consistent", false) and
    object.get(api, "markers_complete", false) and
    object.get(api, "gap_count", 99) == 0

authnz := object.get(ctx, "authnz", {})
authnz_complete := object.get(authnz, "jwt", false) and
    object.get(authnz, "rbac", false) and
    object.get(authnz, "sod", false)

idempotency_complete := object.get(api, "idempotency_key", false)
versioning_complete := object.get(api, "versioning", false)

# ── Migracje + constraints (PK/FK/UNIQUE/CHECK/WORM/idempotent DDL) ─────
migrations := object.get(ctx, "migrations", {})
migrations_constraints_complete := object.get(migrations, "pk", false) and
    object.get(migrations, "fk", false) and
    object.get(migrations, "unique_constraint", false) and
    object.get(migrations, "check_constraint", false) and
    object.get(migrations, "idempotent_ddl", false) and
    object.get(migrations, "worm_append_only", false)

# ── Bundle integrity: podpis + SBOM + node verification ───────────────────
bundle := object.get(ctx, "bundle_integrity", {})
bundle_signing_ok := object.get(bundle, "signing", false) and
    object.get(bundle, "hsm_signature", false)
sbom_ok := object.get(bundle, "sbom_present", false) and
    object.get(bundle, "sbom_verified", false)
node_verify_ok := object.get(bundle, "node_verify", false)
bundle_integrity_complete := bundle_signing_ok and sbom_ok and node_verify_ok

healthy_persisted := object.get(bundle, "last_healthy_persisted", false)

# ── Progressive delivery: canary → shadow → ramped → soak → rollback ─────
delivery := object.get(ctx, "progressive_delivery", {})
canary_ok := object.get(delivery, "canary", false) and
    object.get(delivery, "canary_pct", 0) >= min_canary_pct
shadow_ok := object.get(delivery, "shadow_compare", false) and
    object.get(delivery, "shadow_delta_pct", 999) <= max_shadow_delta_pct
ramped_ok := object.get(delivery, "ramped", false)
soak_ok := object.get(delivery, "soak", false) and
    object.get(delivery, "soak_hours", 0) >= soak_hours
rollback_ok := object.get(delivery, "rollback", false) and
    object.get(delivery, "rollback_mttr_min", 9999) <= max_rollback_mttr_min
progressive_delivery_complete := canary_ok and shadow_ok and ramped_ok and
    soak_ok and rollback_ok

# ── Hot-reload danych ────────────────────────────────────────────────────
hot_reload := object.get(ctx, "hot_reload", {})
hot_reload_complete := object.get(hot_reload, "data_hot_reload", false) and
    object.get(hot_reload, "sla_minutes", 9999) <= hot_reload_sla_min

# ── WORM / Merkle audit ──────────────────────────────────────────────────
worm := object.get(ctx, "worm_merkle", {})
worm_merkle_complete := object.get(worm, "merkle_audit", false) and
    object.get(worm, "append_only", false) and
    object.get(worm, "decision_certificates_v4", false)

# ── Disaster Recovery ────────────────────────────────────────────────────
dr := object.get(ctx, "disaster_recovery", {})
dr_complete := object.get(dr, "backup", false) and
    object.get(dr, "restore_tested", false) and
    object.get(dr, "rpo_minutes", 9999) <= max_rpo_min and
    object.get(dr, "rto_minutes", 9999) <= max_rto_min and
    object.get(dr, "game_day_passed", false)

# ── Production honesty: mock ≠ produkcja ─────────────────────────────────
honesty := object.get(ctx, "production_honesty", {})
production_honest := object.get(honesty, "production_status", "MISSING") == "NOT_CERTIFIED" and
    not object.get(honesty, "mock_claimed_as_production", false)

provenance_complete := evaluation_date != "" and run_id != "" and
    count(evidence_refs) > 0 and registry_version != "" and
    legal_basis_version != ""

all_controls_complete := api_schema_consistent and authnz_complete and
    idempotency_complete and versioning_complete and
    migrations_constraints_complete and bundle_integrity_complete and
    healthy_persisted and progressive_delivery_complete and
    hot_reload_complete and worm_merkle_complete and dr_complete and
    production_honest and provenance_complete

manual_review_required := true
hard_block := not all_controls_complete
routing := "BLOCK_AND_ALERT" if {
    hard_block
} else := "TRIAGE_QUEUE" if {
    manual_review_required
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.tools_api_rulestore_bundles_etap25.control_data_plane_governance",
    "package": "jdg.tools_api_rulestore_bundles_etap25",
    "priority": 25001,
    "stage": "ETAP_25",
    "decision_mode": "SUGGEST",
    "no_auto_post": true,
    "state": "CONTROL_PLANE_READY" if {all_controls_complete} else "CONTROL_PLANE_BLOCKED",
    "api_schema_consistent": api_schema_consistent,
    "authnz_complete": authnz_complete,
    "idempotency_complete": idempotency_complete,
    "versioning_complete": versioning_complete,
    "migrations_constraints_complete": migrations_constraints_complete,
    "bundle_integrity_complete": bundle_integrity_complete,
    "healthy_version_persisted": healthy_persisted,
    "progressive_delivery_complete": progressive_delivery_complete,
    "hot_reload_complete": hot_reload_complete,
    "worm_merkle_complete": worm_merkle_complete,
    "disaster_recovery_complete": dr_complete,
    "production_honest": production_honest,
    "production_status": "NOT_CERTIFIED",
    "provenance_complete": provenance_complete,
    "manual_review_required": manual_review_required,
    "control_thresholds": {
        "min_canary_pct": min_canary_pct,
        "max_shadow_delta_pct": max_shadow_delta_pct,
        "soak_hours": soak_hours,
        "max_rollback_mttr_min": max_rollback_mttr_min,
        "hot_reload_sla_min": hot_reload_sla_min,
        "max_rpo_min": max_rpo_min,
        "max_rto_min": max_rto_min,
    },
    "evidence_chain": {
        "run_id": run_id,
        "evidence_refs": evidence_refs,
        "evaluation_date": evaluation_date,
        "registry_version": registry_version,
        "legal_basis_version": legal_basis_version,
    },
    "_routing": routing,
    "_routing_reason": "ETAP 25: control/data plane musi być kompletny i zweryfikowany; mock nie jest certyfikowany jako production.",
    "_legal_basis": "V1 §9, V2 §8, V1 §12.2; ADR-001; ADR-006; ADR-022; OpenAPI 3.0.3; migracje 001-004+013; SEPARATION_OF_DUTIES; NOT_CERTIFIED",
    "_warnings": ["Nieudokumentowany bundle, brak SBOM, niespójność OpenAPI/artefakty, nieudokumentowany DR lub deklarowanie mocka jako produkcja = BLOCK_AND_ALERT."],
    "valid_from": "2026-01-01",
    "valid_to": null,
} {
    activated
}