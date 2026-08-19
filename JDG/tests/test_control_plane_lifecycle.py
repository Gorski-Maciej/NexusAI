"""Acceptance tests for ETAP 04 Control Plane Rule Lifecycle."""
from __future__ import annotations

import copy
import json
from pathlib import Path

import pytest

JDG_ROOT = Path(__file__).resolve().parent.parent
import sys
sys.path.insert(0, str(JDG_ROOT / "tools"))

import control_plane_lifecycle as cp  # noqa: E402


def manifest(operation="ADD", **extra):
    values = {
        "operation": operation,
        "rule_id": "jdg.vat.example.r1",
        "title": "Przykładowa reguła VAT",
        "version": "1.0.0",
        "legal_node_ids": ["LKG-0001"],
        "valid_from": "2026-01-01",
        "valid_to": None,
        "owner": "vat-team",
        "domain": "vat",
        "dependencies": [],
        "tests": ["JDG/tests/rego/test_example.rego"],
        "impact": {"level": "LOW", "affected_rules": []},
        "author": "alice",
        "change_ticket": "PR-100",
        "bundle_version": "jdg-vat-bundle-v1.0.0",
        "signer": "bob",
    }
    values.update(extra)
    return cp.make_manifest(**values)


def authorized(state, change_id):
    cp.review_change(state, change_id, "bob", "APPROVE", "legal review")
    cp.authorize_deployment(state, change_id, "carol")


def test_manifest_requires_lkg_signature_temporal_data_and_sod():
    good = manifest()
    assert cp.validate_manifest(good) == []
    bad = copy.deepcopy(good)
    bad["legal_node_ids"] = []
    bad["signature"] = "sha256:" + "0" * 64
    assert any("legal_node_id" in error for error in cp.validate_manifest(bad))
    assert any("signature" in error for error in cp.validate_manifest(bad))


def test_change_roundtrip_has_four_eyes_rollout_and_complete_traceability():
    state = cp.load_state(Path("/tmp/nonexistent-control-plane-state.json"))
    change_id = cp.submit_change(state, manifest(), "alice")
    authorized(state, change_id)
    cp.record_rollout(state, change_id, "CANARY", "carol", rollout_pct=5)
    cp.record_rollout(state, change_id, "SHADOW_COMPARE", "carol", delta_pct=1.2)
    cp.record_rollout(state, change_id, "RAMPED", "carol", rollout_pct=25)
    cp.record_rollout(state, change_id, "SOAK", "carol", soak_hours=24)
    cp.record_rollout(state, change_id, "ACTIVE", "carol", quality=99.0, error_rate=0.1)
    cp.link_law_event(state, change_id, "AMD-1", "ISSUE-1", "PR-100")
    cp.link_bundle_and_verdicts(state, change_id, "jdg-vat-bundle-v1.0.0", ["DC-1"])
    result = cp.validate_state(state, publication_gate=True)
    assert result["status"] == "PASS"
    assert state["changes"][change_id]["status"] == "ACTIVE"
    assert state["production_mutation_policy"] == "FORBIDDEN"
    assert len(state["audit_events"]) >= 8


def test_sod_and_fail_closed_rollout_guards():
    state = cp.load_state(Path("/tmp/nonexistent-control-plane-state.json"))
    change_id = cp.submit_change(state, manifest(), "alice")
    with pytest.raises(ValueError, match="cannot be the author"):
        cp.review_change(state, change_id, "alice")
    cp.review_change(state, change_id, "bob")
    with pytest.raises(ValueError, match="differ from reviewer"):
        cp.authorize_deployment(state, change_id, "bob")
    cp.authorize_deployment(state, change_id, "carol")
    with pytest.raises(ValueError, match="delta"):
        cp.record_rollout(state, change_id, "SHADOW_COMPARE", "carol", delta_pct=2.01)
    assert state["changes"][change_id]["status"] == "BLOCKED_ROLLOUT"


def test_auto_rollback_preserves_previous_version_and_audit():
    state = cp.load_state(Path("/tmp/nonexistent-control-plane-state.json"))
    change_id = cp.submit_change(state, manifest("ROLLBACK", supersedes="0.9.0", reason="quality regression"), "alice")
    authorized(state, change_id)
    cp.auto_rollback(state, change_id, "carol", "error rate exceeded")
    change = state["changes"][change_id]
    assert change["status"] == "ROLLED_BACK"
    assert change["rollback"]["target_version"] == "0.9.0"
    assert any(event["event"] == "AUTO_ROLLBACK" for event in state["audit_events"])


def test_deprecate_retire_purge_is_append_only_and_requires_zero_references():
    state = cp.load_state(Path("/tmp/nonexistent-control-plane-state.json"))
    dep_id = cp.submit_change(state, manifest("DEPRECATE", current_status="ACTIVE", reason="new version"), "alice")
    authorized(state, dep_id)
    cp.apply_lifecycle_operation(state, dep_id, "carol")
    assert state["changes"][dep_id]["status"] == "DEPRECATED"

    retire_id = cp.submit_change(state, manifest("RETIRE", current_status="DEPRECATED", reason="grace period ended"), "alice")
    authorized(state, retire_id)
    cp.apply_lifecycle_operation(state, retire_id, "carol")
    assert state["changes"][retire_id]["status"] == "RETIRED"

    blocked_id = cp.submit_change(state, manifest("PURGE", current_status="RETIRED", active_references=1, reason="purge request"), "alice")
    authorized(state, blocked_id)
    with pytest.raises(ValueError, match="zero active references"):
        cp.apply_lifecycle_operation(state, blocked_id, "carol")

    purge_id = cp.submit_change(state, manifest("PURGE", current_status="RETIRED", active_references=0, reason="purge request"), "alice")
    authorized(state, purge_id)
    cp.apply_lifecycle_operation(state, purge_id, "carol")
    assert state["changes"][purge_id]["status"] == "PURGED"
    assert state["changes"][purge_id]["manifest"]["rule_id"] == "jdg.vat.example.r1"
    assert any(event["event"] == "LIFECYCLE_PURGE" for event in state["audit_events"])


def test_declarative_routes_never_write_production_directly():
    data_plan = cp.plan_declarative_change("Stawka VAT od 2027-01-01: 23% -> 8%")
    law_plan = cp.plan_declarative_change("Nowelizacja ustawy o VAT art. 113")
    assert data_plan["route"] == "DATA_SERVICE"
    assert law_plan["route"] == "LAW_RADAR_AND_RULE_LIFECYCLE"
    assert data_plan["production_direct_write"] is False
    with pytest.raises(ValueError):
        cp.plan_declarative_change("nieznana prośba")


def test_state_tampering_and_bootstrap_are_visible_and_fail_closed(tmp_path):
    state = cp.load_state(tmp_path / "state.json")
    change_id = cp.submit_change(state, manifest(), "alice")
    state["changes"][change_id]["manifest"]["title"] = "tampered"
    assert cp.validate_state(state)["status"] == "FAIL"
    registry = tmp_path / "rule_registry.json"
    registry.write_text(json.dumps({"one": {"versions": []}, "two": {"versions": []}}), encoding="utf-8")
    cp.bootstrap_state(state, registry)
    assert state["bootstrap"]["legacy_registry_entries"] == 2
    assert state["bootstrap"]["migration_status"] == "LEGACY_ENTRIES_REQUIRE_MANIFEST_REVIEW"
