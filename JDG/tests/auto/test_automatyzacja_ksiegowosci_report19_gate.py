"""Contract tests for PROMPT_19 accounting automation evidence."""
from __future__ import annotations

import json
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(BASE_DIR / "tools"))

import automatyzacja_ksiegowosci_report19_gate as gate


def test_prompt19_gate_is_complete():
    evidence = gate.build_evidence()
    assert evidence["status"] == "WDROZONY_100", evidence
    assert evidence["gate_summary"] == {"passed": 12, "total": 12}


def test_scope_and_modules_are_complete():
    evidence = gate.build_evidence()
    assert evidence["scope"]["all_present"] is True
    assert evidence["modules"]["complete"] is True
    assert evidence["modules"]["total_rule_ids"] >= 300


def test_all_innovations_and_roadmap_are_wired():
    package = gate.build_evidence()["package"]
    assert all(package["innovation_markers"].values())
    assert all(package["innovation_rules"].values())
    assert all(package["roadmap_rules"].values())
    assert package["roadmap_object"] is True


def test_safety_and_orchestrator_contract():
    safety = gate.build_evidence()["safety"]
    assert safety["complete"] is True, safety
    assert safety["checks"]["block_never_auto_post"] is True
    assert safety["checks"]["post_merge_enforced"] is True


def test_tests_syntax_and_replay():
    evidence = gate.build_evidence()
    assert evidence["syntax"]["syntax_ok"] is True
    assert evidence["tests"]["complete"] is True
    assert evidence["tests"]["pytest_count"] >= 40
    assert evidence["replay"]["valid"] is True
    assert evidence["replay"]["unmatched"] == 0


def test_rollback_is_fail_closed_and_evidence_is_consistent():
    evidence = gate.build_evidence()
    assert evidence["deployment"]["phase"] == "ROLLED_BACK"
    assert evidence["deployment"]["production_status"] == "NOT_CERTIFIED"
    bundle = BASE_DIR / "bundles" / "automatyzacja_ksiegowosci_report19_evidence.json"
    assert bundle.exists()
    stored = json.loads(bundle.read_text(encoding="utf-8"))
    assert stored["status"] == "WDROZONY_100"
    assert stored["gate_summary"] == {"passed": 12, "total": 12}
