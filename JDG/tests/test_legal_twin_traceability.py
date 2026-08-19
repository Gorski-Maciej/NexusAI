"""Acceptance tests for ETAP 03 Legal Twin traceability."""
from __future__ import annotations

import copy
import sys
from pathlib import Path

import pytest

JDG_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(JDG_ROOT / "tools"))

import legal_twin_traceability as twin  # noqa: E402


@pytest.fixture(scope="module")
def bundle():
    return twin.build_traceability()


def test_article_matching_handles_ranges_and_suffixes():
    assert twin.article_covers("81-81b", "81")
    assert twin.article_covers("81-81b", "81b")
    assert twin.article_covers("22a-22o", "22k")
    assert not twin.article_covers("22a-22o", "23")


def test_bundle_has_explicit_bidirectional_traceability(bundle):
    result = twin.validate_traceability(bundle)
    assert result["status"] == "PASS"
    assert result["rules"] > 1000
    assert result["legal_nodes"] > 100
    rule_map = {row["rule_id"]: row for row in bundle["rules"]}
    node_map = {row["legal_node_id"]: row for row in bundle["legal_nodes"]}
    resolved_rules = [row for row in bundle["rules"] if row["mapping_status"] == "RESOLVED"]
    assert resolved_rules
    for rule in resolved_rules[:50]:
        for node_id in rule["legal_node_ids"]:
            assert node_id in node_map
            assert rule["rule_id"] in node_map[node_id]["rule_ids"]
    for node in bundle["legal_nodes"]:
        for rule_id in node["rule_ids"][:10]:
            assert rule_id in rule_map
            assert node["legal_node_id"] in rule_map[rule_id]["legal_node_ids"]


def test_metrics_are_defined_and_deserts_are_explicit(bundle):
    metrics = bundle["metrics"]
    assert set(metrics) >= {"LCI", "TCL", "RV", "UVR", "definitions"}
    assert all(0 <= metrics[key] <= 100 for key in ("LCI", "TCL", "RV", "UVR"))
    assert bundle["findings"]["coverage_deserts"]
    assert bundle["publication_policy"]["legacy_legal_basis_is_evidence"] is False


def test_integrity_hash_and_publication_gate(bundle):
    assert twin.validate_traceability(bundle)["status"] == "PASS"
    tampered = copy.deepcopy(bundle)
    tampered["rules"][0]["legal_basis"] += " tampered"
    assert twin.validate_traceability(tampered)["status"] == "FAIL"
    publication = twin.validate_traceability(bundle, publication_gate=True)
    assert publication["status"] == "FAIL"
    assert any("publication blocked" in issue for issue in publication["issues"])


def test_time_travel_is_not_called_proof_without_verified_source(bundle):
    node = next(node for node in bundle["legal_nodes"] if node["effective_interval"].get("valid_from"))
    evidence = twin.time_travel(bundle, node["legal_node_id"], node["effective_interval"]["valid_from"])
    assert evidence["status"] == "NEEDS_SOURCE_VERIFICATION"
    assert evidence["exists"] is None
    assert evidence["source_verified"] is False


def test_missing_source_and_ambiguous_mapping_are_recorded(bundle):
    findings = bundle["findings"]
    assert "missing_source_rules" in findings
    assert "ambiguous_mapping_rules" in findings
    assert "unresolved_mapping_rules" in findings
