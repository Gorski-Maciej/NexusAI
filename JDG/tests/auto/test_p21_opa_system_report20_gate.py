"""Contract tests for campaign PROMPT_20 System OPA / Control Plane."""
from __future__ import annotations

import json
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(BASE_DIR / "tools"))

import system_opa_control_plane_report20_gate as gate


def test_prompt20_gate_is_complete():
    evidence = gate.build_evidence()
    assert evidence["status"] == "WDROZONY_100", evidence
    assert evidence["gate_summary"] == {"passed": 14, "total": 14}


def test_scope_and_infrastructure_are_complete():
    evidence = gate.build_evidence()
    assert evidence["scope"]["all_present"] is True
    assert evidence["scope"]["migration_count"] >= 13
    assert evidence["infrastructure"]["complete"] is True


def test_p21_is_advisory_and_complete():
    package = gate.build_evidence()["package"]
    assert package["innovations_complete"] is True
    assert package["decision_mode_suggest"] is True
    assert package["no_auto_post"] is True
    assert package["default_no_match"] is True


def test_api_migrations_and_legal_pipeline():
    evidence = gate.build_evidence()
    assert evidence["api"]["complete"] is True
    assert evidence["migrations"]["complete"] is True
    assert evidence["legal_pipeline"]["complete"] is True


def test_replay_and_production_honesty():
    evidence = gate.build_evidence()
    replay = evidence["replay_deployment"]
    assert replay["golden_valid"] is True
    assert replay["golden_verdicts"] >= 1
    assert replay["unmatched"] == 0
    assert replay["rollback_fail_closed"] is True
    assert replay["production_status"] == "NOT_CERTIFIED"


def test_written_bundle_matches_live_gate():
    bundle = BASE_DIR / "bundles" / "system_opa_control_plane_report20_evidence.json"
    assert bundle.exists()
    stored = json.loads(bundle.read_text(encoding="utf-8"))
    live = gate.build_evidence()
    assert stored["status"] == live["status"] == "WDROZONY_100"
    assert stored["gate_summary"] == live["gate_summary"] == {"passed": 14, "total": 14}
