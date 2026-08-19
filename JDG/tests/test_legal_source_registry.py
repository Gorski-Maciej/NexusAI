"""Acceptance tests for ETAP 02 Legal Source Records."""
from __future__ import annotations

import copy
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(JDG_ROOT / "tools"))

import legal_source_registry as registry  # noqa: E402


def test_build_has_versioned_records_and_lkg_provenance():
    data = registry.build_registry()
    result = registry.validate_registry(data)

    assert result["status"] == "PASS"
    assert data["schema_version"] == "1.0.0"
    assert len(data["records"]) >= 20
    assert data["integrity"]["legal_node_count"] == len(data["legal_nodes"])
    for record in data["records"]:
        assert record["source_record_id"].startswith("LSR-")
        assert record["source_hash"] == registry.record_hash(record)
        assert record["hash_scope"] != "official_text"
        assert record["effective_interval"]["claim_status"] == "UNVERIFIED_EXTERNAL"
        assert record["provenance"]
        assert record["verification"]["review_state"] == "PENDING_4_EYES"
        assert record["publication_state"] == "BLOCKED_UNVERIFIED"


def test_tampered_source_hash_fails_closed():
    data = registry.build_registry()
    data["records"][0]["full_name"] += " — tampered"
    result = registry.validate_registry(data)
    assert result["status"] == "FAIL"
    assert any("source_hash mismatch" in issue for issue in result["issues"])


def test_invalid_interval_fails_closed():
    data = registry.build_registry()
    data["records"][0]["effective_interval"] = {
        "valid_from": "2027-01-01",
        "valid_to": "2026-01-01",
        "claim_status": "UNVERIFIED_EXTERNAL",
    }
    data["records"][0]["source_hash"] = registry.record_hash(data["records"][0])
    result = registry.validate_registry(data)
    assert result["status"] == "FAIL"
    assert any("valid_from after valid_to" in issue for issue in result["issues"])


def test_publication_requires_official_snapshot_and_two_distinct_reviewers():
    data = registry.build_registry()
    record = data["records"][0]
    queue = data["review_queue"][0]
    record["publication_state"] = "PUBLISHED"
    record["verification"]["review_state"] = "APPROVED"
    result = registry.validate_registry(data, publication_gate=True)
    assert result["status"] == "FAIL"
    assert any("official snapshot" in issue for issue in result["issues"])
    assert any("fewer than two approvals" in issue for issue in result["issues"])

    queue["approvals"] = [
        {"reviewer": "alice", "decision": "APPROVE"},
        {"reviewer": "bob", "decision": "APPROVE"},
    ]
    record["verification"]["official_snapshot_hash"] = "sha256:official"
    result = registry.validate_registry(data, publication_gate=True)
    assert result["status"] == "FAIL"  # publication_state is not enough: hash/approval must match policy


def test_same_reviewer_cannot_satisfy_four_eyes():
    data = registry.build_registry()
    queue = data["review_queue"][0]
    queue["approvals"] = [
        {"reviewer": "alice", "decision": "APPROVE"},
        {"reviewer": "alice", "decision": "APPROVE"},
    ]
    result = registry.validate_registry(data)
    assert result["status"] == "FAIL"
    assert any("duplicate reviewers" in issue for issue in result["issues"])


def test_append_review_requires_current_hash_and_distinct_reviewers():
    data = registry.build_registry()
    record = data["records"][0]
    source_hash = record["source_hash"]
    registry.append_review(data, record["source_record_id"], "alice", "APPROVE", source_hash)
    registry.append_review(
        data, record["source_record_id"], "bob", "APPROVE", source_hash,
        official_snapshot_hash="sha256:official",
    )
    assert record["verification"]["review_state"] == "APPROVED"
    assert record["publication_state"] == "READY_FOR_PUBLISH"
    try:
        registry.append_review(data, record["source_record_id"], "alice", "APPROVE", source_hash)
    except ValueError as exc:
        assert "already reviewed" in str(exc)
    else:
        raise AssertionError("duplicate reviewer was accepted")


def test_diff_marks_changed_record_for_review():
    before = registry.build_registry()
    after = copy.deepcopy(before)
    after["records"][0]["publication"]["citation"] = "Dz.U. TEST poz. 1"
    after["records"][0]["source_hash"] = registry.record_hash(after["records"][0])
    diff = registry.diff_registries(before, after)
    assert diff["added"] == []
    assert diff["removed"] == []
    assert diff["changed"][0]["requires_4_eyes_review"] is True
    assert diff["publication_gate"] == "BLOCKED_UNTIL_REVIEW"
