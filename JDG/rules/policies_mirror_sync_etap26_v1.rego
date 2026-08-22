# NexusAI JDG — ETAP 26 POLICIES MIRROR / SYNC / OVERLAYS GOVERNANCE
# Source of truth = JDG/rules/; policies/ jest mirror + overlays, nigdy
# drugim rejestrem. Mirror nie może cicho zmieniać decyzji JDG: drift 0%,
# hash parity 100%, decision parity 100%, legal parity 100%, overlays
# TCL 100% (zero nakładek/luk), zero duchów, warianty eksperymentalne
# jawnie oznaczone. Fail-closed — każda niezgodność = BLOCK_AND_ALERT.

package jdg.policies_mirror_sync_etap26

import future.keywords.if
import future.keywords.in

decision_mode := "SUGGEST"

default decide := {
    "matched": false,
    "rule_id": "jdg.policies_mirror_sync_etap26.no_match",
    "package": "jdg.policies_mirror_sync_etap26",
    "priority": 999995,
    "decision_mode": "SUGGEST",
    "no_auto_post": true,
}

_thresholds := object.get(object.get(data, "jdg", {}), "thresholds", {})
_et26 := object.get(_thresholds, "policies_mirror_sync_etap26", {})
registry_version := object.get(_et26, "registry_version", "policies-mirror-sync-etap26-2026.08")
legal_basis_version := object.get(_et26, "legal_basis_version", "mirror-sync-2026.08")
max_drift_pct := object.get(_et26, "max_drift_pct", 0.0)
min_parity_pct := object.get(_et26, "min_parity_pct", 100.0)

ctx := object.get(input, "policies_mirror_sync_etap26", {})
activated := object.get(object.get(input, "jdg_entrepreneur", {}), "policies_mirror_sync_etap26_check", false)
evaluation_date := object.get(ctx, "evaluation_date", "")
run_id := object.get(ctx, "run_id", "")
evidence_refs := object.get(ctx, "evidence_refs", [])

# ── Source of truth: JDG/rules/ deklarowane jako jedyne źródło ─────────────
source := object.get(ctx, "source_of_truth", {})
source_of_truth_declared := object.get(source, "declared", false) and
    object.get(source, "path", "") == "JDG/rules/" and
    object.get(source, "mirror_role", "") == "OVERLAY"

# ── Mirror synchronizacja: drift 0% i hash parity 100% ─────────────────────
mirror := object.get(ctx, "mirror", {})
drift := object.get(mirror, "drift", {})
mirror_synced := object.get(drift, "drift_pct", 999) <= max_drift_pct and
    object.get(drift, "drift_files", 999) == 0
hash_parity_ok := object.get(mirror, "hash_parity", {})
hash_parity_complete := object.get(hash_parity_ok, "parity_pct", 0) >= min_parity_pct and
    object.get(hash_parity_ok, "mismatched_count", 999) == 0 and
    object.get(hash_parity_ok, "missing_count", 999) == 0

# ── Decision parity: mirror nie zmienia cicho decyzji JDG ───────────────────
contract := object.get(ctx, "contract", {})
decision_parity_complete := object.get(contract, "decision_parity_pct", 0) >= min_parity_pct and
    object.get(contract, "missing_from_mirror", 999) == 0

# ── Legal parity: żaden artykuł nie znika w mirrorze ───────────────────────
legal := object.get(ctx, "legal_parity", {})
legal_parity_complete := object.get(legal, "legal_parity_pct", 0) >= min_parity_pct and
    object.get(legal, "missing_from_mirror", 999) == 0

# ── Overlays: TCL 100% (zero nakładek/luk) + zero duchów ────────────────────
overlays := object.get(ctx, "overlays", {})
intervals := object.get(overlays, "intervals", {})
overlays_tcl_100 := object.get(intervals, "tcl_100", false) and
    object.get(intervals, "overlaps_count", 1) == 0 and
    object.get(intervals, "gaps_count", 1) == 0
overlays_no_ghosts := object.get(overlays, "ghost_count", 1) == 0 and
    object.get(overlays, "ghosts", []) == []
overlays_complete := overlays_tcl_100 and overlays_no_ghosts and
    object.get(overlays, "manifest_count", 0) > 0

# ── Warianty eksperymentalne jawnie oznaczone ──────────────────────────────
experimental := object.get(ctx, "experimental_variants", {})
experimental_marked := object.get(experimental, "marked", false) and
    object.get(experimental, "excluded_from_decisions", false)

no_silent_change := decision_parity_complete and mirror_synced and hash_parity_complete

provenance_complete := evaluation_date != "" and run_id != "" and
    count(evidence_refs) > 0 and registry_version != "" and legal_basis_version != ""

all_controls_complete := source_of_truth_declared and mirror_synced and
    hash_parity_complete and decision_parity_complete and legal_parity_complete and
    overlays_complete and experimental_marked and no_silent_change and provenance_complete

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
    "rule_id": "jdg.policies_mirror_sync_etap26.mirror_governance",
    "package": "jdg.policies_mirror_sync_etap26",
    "priority": 26001,
    "stage": "ETAP_26",
    "decision_mode": "SUGGEST",
    "no_auto_post": true,
    "state": "MIRROR_SYNCED" if {all_controls_complete} else "MIRROR_DRIFT",
    "source_of_truth_declared": source_of_truth_declared,
    "mirror_synced": mirror_synced,
    "hash_parity_complete": hash_parity_complete,
    "decision_parity_complete": decision_parity_complete,
    "legal_parity_complete": legal_parity_complete,
    "overlays_complete": overlays_complete,
    "overlays_tcl_100": overlays_tcl_100,
    "overlays_no_ghosts": overlays_no_ghosts,
    "experimental_marked": experimental_marked,
    "no_silent_change": no_silent_change,
    "manual_review_required": manual_review_required,
    "mirror_thresholds": {
        "max_drift_pct": max_drift_pct,
        "min_parity_pct": min_parity_pct,
    },
    "evidence_chain": {
        "run_id": run_id,
        "evidence_refs": evidence_refs,
        "evaluation_date": evaluation_date,
        "registry_version": registry_version,
        "legal_basis_version": legal_basis_version,
    },
    "_routing": routing,
    "_routing_reason": "ETAP 26: mirror/overlays muszą być zsynchronizowane i nie mogą cicho zmieniać decyzji JDG.",
    "_legal_basis": "V1 §1 single source of truth; V1 §6.3 overlays; ADR-011; policies_sync_gate.py; overlay_engine.py; overlay_generator.py",
    "_warnings": ["Drift > 0%, hash/decision/legal parity < 100%, nakładki/luki w overlayach, duchy lub nieoznaczone warianty eksperymentalne = BLOCK_AND_ALERT."],
    "valid_from": "2026-01-01",
    "valid_to": null,
} {
    activated
}
