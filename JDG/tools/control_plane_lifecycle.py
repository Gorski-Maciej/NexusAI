#!/usr/bin/env python3
"""JDG Control Plane lifecycle coordinator — ETAP 04.

This module coordinates the existing lifecycle, registry, Law Radar and rollout
utilities through an append-only change ledger. It deliberately does not edit
production policy files: a change is only eligible for deployment after its
manifest, legal references, review, rollout evidence and SoD are complete.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import re
import sys
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any

JDG_ROOT = Path(__file__).resolve().parent.parent
STATE_PATH = JDG_ROOT / "bundles" / "control_plane_state.json"
RULE_REGISTRY_PATH = JDG_ROOT / "bundles" / "rule_registry.json"

OPERATIONS = {"ADD", "CHANGE", "DEPRECATE", "RETIRE", "PURGE", "SUSPEND", "ROLLBACK"}
STATUSES = {"SHADOW", "CANDIDATE", "ACTIVE", "DEPRECATED", "RETIRED", "PURGED", "SUSPENDED", "ROLLED_BACK"}
ROLLOUT_STAGES = ("CANARY", "SHADOW_COMPARE", "RAMPED", "SOAK", "ACTIVE")
RAMP_PCTS = {25, 50, 100}
SEMVER_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")
SHA256_RE = re.compile(r"^sha256:[0-9a-f]{64}$")


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def canonical_hash(value: Any) -> str:
    payload = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return "sha256:" + hashlib.sha256(payload.encode("utf-8")).hexdigest()


def sign_manifest(manifest: dict[str, Any], signer: str) -> str:
    """Create a deterministic content signature for tests/local control-plane use.

    Production must replace this with an HSM/KMS signature; the registry records
    the boundary explicitly and never treats this local signature as certification.
    """
    unsigned = {key: value for key, value in manifest.items() if key not in {"signature", "signer", "manifest_hash"}}
    return canonical_hash({"manifest": unsigned, "signer": signer})


def _default_state() -> dict[str, Any]:
    return {
        "schema_version": "1.0.0",
        "control_plane_id": "jdg.control_plane.lifecycle",
        "registry_source": "JDG/bundles/rule_registry.json",
        "production_mutation_policy": "FORBIDDEN",
        "changes": {},
        "audit_events": [],
        "law_events": {},
        "traceability": {},
        "rollouts": {},
        "bootstrap": None,
    }


def load_state(path: Path | None = None) -> dict[str, Any]:
    target = path or STATE_PATH
    if not target.exists():
        return _default_state()
    data = json.loads(target.read_text(encoding="utf-8"))
    state = _default_state()
    state.update(data)
    return state


def save_state(state: dict[str, Any], path: Path | None = None) -> None:
    target = path or STATE_PATH
    target.parent.mkdir(parents=True, exist_ok=True)
    temp = target.with_suffix(target.suffix + ".tmp")
    temp.write_text(json.dumps(state, indent=2, ensure_ascii=False, sort_keys=True), encoding="utf-8")
    temp.replace(target)


def _audit(state: dict[str, Any], event: str, actor: str, change_id: str | None = None, **details: Any) -> None:
    state["audit_events"].append({
        "event_id": f"AUD-{len(state['audit_events']) + 1:08d}",
        "event": event,
        "actor": actor,
        "change_id": change_id,
        "at": now(),
        "details": details,
    })


def validate_manifest(manifest: dict[str, Any], operation: str | None = None) -> list[str]:
    """Validate the complete human-facing change manifest fail-closed."""
    errors: list[str] = []
    required = {
        "rule_id", "title", "version", "legal_node_ids", "valid_from", "valid_to",
        "owner", "domain", "dependencies", "tests", "impact", "author", "change_ticket",
        "bundle_version", "content_hash", "signer", "signature",
    }
    for key in sorted(required):
        if key not in manifest or (manifest[key] == "") or (manifest[key] is None and key != "valid_to"):
            errors.append(f"missing manifest field: {key}")
    operation = operation or manifest.get("operation")
    if operation not in OPERATIONS:
        errors.append(f"operation must be one of {sorted(OPERATIONS)}")
    version = manifest.get("version")
    if version and not SEMVER_RE.fullmatch(str(version)):
        errors.append("version must be semver x.y.z")
    for key in ("legal_node_ids", "dependencies", "tests"):
        if key in manifest and not isinstance(manifest[key], list):
            errors.append(f"{key} must be an array")
    if not manifest.get("legal_node_ids"):
        errors.append("at least one LKG legal_node_id is required")
    for key in ("valid_from", "valid_to"):
        if manifest.get(key) is not None:
            try:
                date.fromisoformat(str(manifest[key]))
            except ValueError:
                errors.append(f"{key} must be an ISO date")
    if manifest.get("valid_from") and manifest.get("valid_to"):
        if str(manifest["valid_from"]) > str(manifest["valid_to"]):
            errors.append("valid_from must not be after valid_to")
    if manifest.get("content_hash") and not SHA256_RE.fullmatch(str(manifest["content_hash"])):
        errors.append("content_hash must use sha256:<64 hex> format")
    if manifest.get("signature") and not SHA256_RE.fullmatch(str(manifest["signature"])):
        errors.append("signature must use sha256:<64 hex> format")
    if manifest.get("signature") and manifest.get("signer"):
        if manifest["signature"] != sign_manifest(manifest, str(manifest["signer"])):
            errors.append("signature does not match manifest content and signer")
    if manifest.get("signer") == manifest.get("author"):
        errors.append("signer/reviewer identity cannot be the author")
    if manifest.get("operation") == "CHANGE" and not manifest.get("supersedes"):
        errors.append("CHANGE requires supersedes")
    if manifest.get("operation") in {"DEPRECATE", "RETIRE", "PURGE", "SUSPEND", "ROLLBACK"} and not manifest.get("reason"):
        errors.append(f"{manifest['operation']} requires reason")
    return errors


def make_manifest(**values: Any) -> dict[str, Any]:
    manifest = dict(values)
    manifest.setdefault("valid_to", None)
    manifest.setdefault("dependencies", [])
    manifest.setdefault("tests", [])
    manifest.setdefault("impact", {"level": "MEDIUM", "affected_rules": []})
    manifest.setdefault("content_hash", canonical_hash({"rule_id": manifest.get("rule_id"), "version": manifest.get("version")}))
    signer = manifest.get("signer") or "reviewer"
    manifest["signer"] = signer
    manifest["signature"] = sign_manifest(manifest, signer)
    return manifest


def submit_change(state: dict[str, Any], manifest: dict[str, Any], actor: str) -> str:
    operation = manifest.get("operation")
    errors = validate_manifest(manifest, operation)
    if errors:
        raise ValueError("invalid manifest: " + "; ".join(errors))
    if actor != manifest.get("author"):
        raise ValueError("submitter must equal manifest author")
    change_id = f"CHG-{len(state['changes']) + 1:08d}"
    snapshot = copy.deepcopy(manifest)
    snapshot["manifest_hash"] = canonical_hash(snapshot)
    state["changes"][change_id] = {
        "change_id": change_id,
        "operation": operation,
        "manifest": snapshot,
        "manifest_hash": snapshot["manifest_hash"],
        "status": "PENDING_REVIEW",
        "reviews": [],
        "deployment_authorized": False,
        "created_at": now(),
        "updated_at": now(),
    }
    _audit(state, "CHANGE_SUBMITTED", actor, change_id, operation=operation, manifest_hash=snapshot["manifest_hash"])
    return change_id


def review_change(state: dict[str, Any], change_id: str, reviewer: str, decision: str = "APPROVE", note: str = "") -> None:
    change = state["changes"].get(change_id)
    if not change:
        raise KeyError(f"unknown change: {change_id}")
    if reviewer == change["manifest"].get("author"):
        raise ValueError("reviewer cannot be the author (SoD)")
    if decision not in {"APPROVE", "REJECT", "REQUEST_CHANGES"}:
        raise ValueError("invalid review decision")
    if any(row["reviewer"] == reviewer for row in change["reviews"]):
        raise ValueError("reviewer may approve a change only once")
    change["reviews"].append({
        "reviewer": reviewer,
        "decision": decision,
        "manifest_hash": change["manifest_hash"],
        "note": note,
        "at": now(),
    })
    if decision != "APPROVE":
        change["status"] = "BLOCKED_REVIEW"
    elif len([row for row in change["reviews"] if row["decision"] == "APPROVE"]) >= 1:
        change["status"] = "REVIEWED"
    change["updated_at"] = now()
    _audit(state, "CHANGE_REVIEWED", reviewer, change_id, decision=decision)


def authorize_deployment(state: dict[str, Any], change_id: str, operator: str) -> None:
    change = state["changes"].get(change_id)
    if not change:
        raise KeyError(f"unknown change: {change_id}")
    if operator == change["manifest"].get("author"):
        raise ValueError("deployment operator cannot be the author (SoD)")
    approved = [row for row in change["reviews"] if row["decision"] == "APPROVE"]
    if not approved:
        raise ValueError("deployment requires an independent approval")
    if operator == approved[0]["reviewer"]:
        raise ValueError("deployment operator must differ from reviewer (SoD)")
    if change["manifest_hash"] != canonical_hash({key: value for key, value in change["manifest"].items() if key != "manifest_hash"}):
        raise ValueError("manifest hash changed after review")
    change["deployment_authorized"] = True
    change["operator"] = operator
    change["status"] = "SHADOW"
    change["updated_at"] = now()
    _audit(state, "DEPLOYMENT_AUTHORIZED", operator, change_id, production_mutation="FORBIDDEN")


def _get_change(state: dict[str, Any], change_id: str) -> dict[str, Any]:
    if change_id not in state["changes"]:
        raise KeyError(f"unknown change: {change_id}")
    return state["changes"][change_id]


def record_rollout(
    state: dict[str, Any], change_id: str, stage: str, actor: str,
    *, delta_pct: float | None = None, quality: float | None = None,
    error_rate: float | None = None, rollout_pct: int | None = None,
    soak_hours: float | None = None,
) -> None:
    change = _get_change(state, change_id)
    if not change["deployment_authorized"]:
        raise ValueError("rollout requires independent review and deployment authorization")
    if stage not in ROLLOUT_STAGES:
        raise ValueError(f"stage must be one of {ROLLOUT_STAGES}")
    rollout = state["rollouts"].setdefault(change_id, {"stages": [], "last_stage": None})
    previous = rollout["last_stage"]
    order = {name: index for index, name in enumerate(ROLLOUT_STAGES)}
    if previous is not None and order[stage] < order[previous]:
        raise ValueError("rollout stages cannot move backwards")
    row = {"stage": stage, "actor": actor, "at": now(), "delta_pct": delta_pct,
           "quality": quality, "error_rate": error_rate, "rollout_pct": rollout_pct,
           "soak_hours": soak_hours}
    if stage == "CANARY" and rollout_pct not in (None, 5):
        raise ValueError("CANARY rollout must be 5%")
    if stage == "SHADOW_COMPARE" and (delta_pct is None or delta_pct > 2.0):
        change["status"] = "BLOCKED_ROLLOUT"
        _audit(state, "ROLLOUT_BLOCKED", actor, change_id, reason="shadow delta > 2%", delta_pct=delta_pct)
        raise ValueError("shadow delta must be present and <= 2%")
    if stage == "RAMPED" and rollout_pct not in RAMP_PCTS:
        raise ValueError("RAMPED rollout must be 25%, 50% or 100%")
    if stage == "SOAK" and (soak_hours is None or soak_hours < 24):
        raise ValueError("SOAK requires at least 24 hours")
    if stage == "ACTIVE":
        if previous != "SOAK":
            raise ValueError("ACTIVE requires completed SOAK")
        if quality is None or error_rate is None or quality < 95.0 or error_rate > 1.0:
            change["status"] = "BLOCKED_ROLLOUT"
            raise ValueError("ACTIVE requires quality >= 95 and error_rate <= 1")
    rollout["stages"].append(row)
    rollout["last_stage"] = stage
    change["status"] = "ACTIVE" if stage == "ACTIVE" else stage
    change["updated_at"] = now()
    _audit(state, "ROLLOUT_STAGE_RECORDED", actor, change_id, stage=stage, metrics=row)


def auto_rollback(state: dict[str, Any], change_id: str, actor: str, reason: str) -> None:
    change = _get_change(state, change_id)
    manifest = change["manifest"]
    if not manifest.get("supersedes"):
        raise ValueError("rollback requires a superseded/previous version")
    change["status"] = "ROLLED_BACK"
    change["rollback"] = {"target_version": manifest["supersedes"], "reason": reason, "actor": actor, "at": now()}
    _audit(state, "AUTO_ROLLBACK", actor, change_id, target_version=manifest["supersedes"], reason=reason)


def apply_lifecycle_operation(state: dict[str, Any], change_id: str, actor: str) -> None:
    """Apply only to the control-plane ledger; production files are untouched."""
    change = _get_change(state, change_id)
    if change["status"] not in {"ACTIVE", "REVIEWED", "SHADOW", "ROLLED_BACK", "DEPRECATED", "RETIRED", "SUSPENDED"}:
        raise ValueError(f"change is not eligible for lifecycle operation: {change['status']}")
    operation = change["operation"]
    current_status = change["manifest"].get("current_status", change["status"])
    if operation == "DEPRECATE":
        if current_status not in {"ACTIVE", "SUSPENDED"}:
            raise ValueError("DEPRECATE requires ACTIVE or SUSPENDED source status")
        change["status"] = "DEPRECATED"
    elif operation == "RETIRE":
        if current_status != "DEPRECATED":
            raise ValueError("RETIRE requires DEPRECATED source status")
        change["status"] = "RETIRED"
    elif operation == "PURGE":
        if current_status != "RETIRED":
            raise ValueError("PURGE requires RETIRED source status")
        if change["manifest"].get("active_references", 0) != 0:
            raise ValueError("PURGE requires zero active references")
        # Keep the immutable event and manifest; only runtime eligibility changes.
        change["status"] = "PURGED"
    elif operation == "SUSPEND":
        change["status"] = "SUSPENDED"
    elif operation == "ROLLBACK":
        auto_rollback(state, change_id, actor, change["manifest"].get("reason", "manual rollback"))
        return
    _audit(state, f"LIFECYCLE_{operation}", actor, change_id, production_mutation="FORBIDDEN")
    change["updated_at"] = now()


def link_law_event(state: dict[str, Any], change_id: str, amendment_id: str, issue_id: str, pr_id: str) -> None:
    change = _get_change(state, change_id)
    if not amendment_id or not issue_id or not pr_id:
        raise ValueError("amendment_id, issue_id and pr_id are required")
    row = {"amendment_id": amendment_id, "issue_id": issue_id, "pr_id": pr_id,
           "change_id": change_id, "at": now()}
    state["law_events"][amendment_id] = row
    state["traceability"].setdefault(change_id, {}).update(row)
    _audit(state, "LAW_EVENT_LINKED", change["manifest"].get("author", "system"), change_id,
           amendment_id=amendment_id, issue_id=issue_id, pr_id=pr_id)


def link_bundle_and_verdicts(state: dict[str, Any], change_id: str, bundle_version: str, verdict_ids: list[str]) -> None:
    _get_change(state, change_id)
    if not bundle_version or not isinstance(verdict_ids, list):
        raise ValueError("bundle_version and verdict_ids are required")
    chain = state["traceability"].setdefault(change_id, {})
    chain["bundle_version"] = bundle_version
    chain["verdict_ids"] = verdict_ids
    _audit(state, "BUNDLE_VERDICTS_LINKED", "deployment-operator", change_id,
           bundle_version=bundle_version, verdict_count=len(verdict_ids))


def validate_state(state: dict[str, Any], publication_gate: bool = False) -> dict[str, Any]:
    issues: list[str] = []
    for change_id, change in state.get("changes", {}).items():
        manifest = change.get("manifest", {})
        errors = validate_manifest(manifest, change.get("operation"))
        issues.extend(f"{change_id}: {error}" for error in errors)
        if change.get("manifest_hash") != canonical_hash({key: value for key, value in manifest.items() if key != "manifest_hash"}):
            issues.append(f"{change_id}: manifest hash mismatch")
        if publication_gate and change.get("status") == "ACTIVE":
            if not change.get("deployment_authorized"):
                issues.append(f"{change_id}: active without deployment authorization")
            chain = state.get("traceability", {}).get(change_id, {})
            for key in ("amendment_id", "issue_id", "pr_id", "bundle_version"):
                if not chain.get(key):
                    issues.append(f"{change_id}: missing traceability {key}")
            rollout = state.get("rollouts", {}).get(change_id, {})
            stages = [row.get("stage") for row in rollout.get("stages", [])]
            if "SHADOW_COMPARE" not in stages or "SOAK" not in stages:
                issues.append(f"{change_id}: incomplete rollout evidence")
    if state.get("production_mutation_policy") != "FORBIDDEN":
        issues.append("production mutation policy is not FORBIDDEN")
    return {"status": "PASS" if not issues else "FAIL", "issues": issues,
            "changes": len(state.get("changes", {})),
            "audit_events": len(state.get("audit_events", [])),
            "publication_gate": publication_gate}


def bootstrap_state(state: dict[str, Any], registry_path: Path = RULE_REGISTRY_PATH) -> None:
    """Record inventory facts without rewriting the legacy registry."""
    registry_entries = 0
    if registry_path.exists():
        raw = json.loads(registry_path.read_text(encoding="utf-8"))
        registry_entries = len(raw) if isinstance(raw, dict) else len(raw.get("rules", []))
    state["bootstrap"] = {
        "legacy_registry_path": str(registry_path.relative_to(JDG_ROOT) if registry_path.is_relative_to(JDG_ROOT) else registry_path),
        "legacy_registry_entries": registry_entries,
        "migration_status": "LEGACY_ENTRIES_REQUIRE_MANIFEST_REVIEW",
        "production_mutation": "NONE",
        "at": now(),
    }
    _audit(state, "CONTROL_PLANE_BOOTSTRAPPED", "system", None, legacy_registry_entries=registry_entries)


def plan_declarative_change(text: str) -> dict[str, Any]:
    lowered = text.lower()
    if any(token in lowered for token in ("stawka", "limit", "próg", "prog", "kwota")):
        route = "DATA_SERVICE"
    elif any(token in lowered for token in ("nowelizac", "zmiana prawa", "projekt ustawy")):
        route = "LAW_RADAR_AND_RULE_LIFECYCLE"
    else:
        raise ValueError("change request is not recognized by the declarative contract")
    return {"request": text, "route": route,
            "gates": ["LEGAL_SOURCE", "IMPACT", "GOLDEN_REPLAY", "TESTS", "FOUR_EYES", "ROLLOUT"],
            "production_direct_write": False,
            "status": "PLAN_ONLY"}


def main() -> None:
    parser = argparse.ArgumentParser(description="JDG Control Plane lifecycle coordinator — ETAP 04")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("bootstrap")
    val = sub.add_parser("validate"); val.add_argument("--publication-gate", action="store_true")
    plan = sub.add_parser("plan"); plan.add_argument("--change", required=True)
    status = sub.add_parser("status")
    args = parser.parse_args()
    state = load_state()
    if args.command == "bootstrap":
        bootstrap_state(state); save_state(state); print(json.dumps(state["bootstrap"], ensure_ascii=False, indent=2)); return
    if args.command == "validate":
        result = validate_state(state, args.publication_gate)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        raise SystemExit(0 if result["status"] == "PASS" else 1)
    if args.command == "plan":
        print(json.dumps(plan_declarative_change(args.change), ensure_ascii=False, indent=2)); return
    print(json.dumps({"control_plane_id": state["control_plane_id"], "changes": len(state["changes"]),
                      "audit_events": len(state["audit_events"]),
                      "production_mutation_policy": state["production_mutation_policy"]}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
