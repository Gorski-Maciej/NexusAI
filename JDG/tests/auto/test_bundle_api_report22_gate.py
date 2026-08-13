#!/usr/bin/env python3
"""Tests for the RAPORT_22 evidence gate (BUNDLE / API / MIGRACJE)."""

import json
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(BASE_DIR / "tools"))

import bundle_api_report22_gate as gate


def test_gate_reaches_wdrozony_100():
    ev = gate.build_evidence()
    assert ev["status"] == "WDROZONY_100", f"expected WDROZONY_100, got {ev['status']}"
    assert ev["gate_summary"]["passed"] == ev["gate_summary"]["total"] == 7


def test_scope_files_present():
    scope = gate.build_evidence()["scope"]
    assert scope["docs_present"] == scope["docs_total"] == 5
    assert scope["bundles_present"] == scope["bundles_total"] == 23
    assert scope["api_present"] == scope["api_total"] == 1
    assert scope["migrations_present"] == scope["migrations_total"] == 3
    assert scope["tests_present"] == scope["tests_total"] == 5
    assert scope["missing"] == []


def test_manifest_consistent():
    manifest = gate.build_evidence()["manifest"]
    assert manifest["consistent"] is True, f"mismatches: {manifest['mismatches']}"
    assert manifest["mismatches"] == {}


def test_rule_registry_populated():
    registry = gate.build_evidence()["rule_registry"]
    assert registry["populated"] is True
    assert registry["rule_ids"] >= 1
    assert registry["active"] >= 1


def test_bundle_signing_supported():
    signature = gate.build_evidence()["bundle_signature"]
    assert signature["all"] is True
    assert signature["signing_supported"] is True
    assert signature["sbom_supported"] is True


def test_migrations_present():
    migrations = gate.build_evidence()["migrations"]
    assert migrations["has_rule_store"] is True
    assert len(migrations["tables_found"]) >= 1


def test_golden_replay_ready():
    replay = gate.build_evidence()["replay"]
    assert replay["valid"] is True
    assert replay["verdicts"] >= 1
    assert replay["unmatched_count"] == 0


def test_canary_rollback():
    dep = gate.build_evidence()["deployment"]
    assert dep["phase"] == "ROLLED_BACK"
    assert dep["rollback_reason"] is not None
    assert dep["rollback_sla_pass"] is True


def test_evidence_bundle_written_and_consistent():
    ev_path = BASE_DIR / "bundles" / "bundle_api_report22_evidence.json"
    assert ev_path.exists(), "evidence bundle not written"
    data = json.loads(ev_path.read_text(encoding="utf-8"))
    assert data["status"] == "WDROZONY_100"
    assert data["gate_summary"]["passed"] == 7
