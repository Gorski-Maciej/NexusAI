from __future__ import annotations

import json
import sys
from datetime import datetime, timedelta
from pathlib import Path
from types import SimpleNamespace

BASE_DIR = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(BASE_DIR / "tools"))

import crossborder_report10_gate as gate  # noqa: E402
import deployment_orchestrator as orchestrator  # noqa: E402


def test_report10_gate_scans_declared_scope():
    evidence = gate.build_evidence()
    inventory = evidence["inventory"]
    assert inventory["files_total"] == len(gate.RULE_FILES)
    assert inventory["files_present"] == inventory["files_total"]
    assert inventory["rule_ids_total"] >= 500
    assert inventory["rule_ids_unique"] >= 500
    # G-02 resolved: jdg.crossborder.no_match and jdg.international.no_match
    # were namespace-renamed in the secondary files — 0 non-fallback duplicates.
    assert inventory["duplicate_count"] == len(inventory["duplicate_rule_ids"])
    assert inventory["duplicate_count"] == 0


def test_report10_gate_requires_human_review_for_crossborder_advice():
    evidence = gate.build_evidence()
    safety = evidence["safety"]
    assert safety["package_present"] is True
    assert safety["suggest_mode_declared"] is True
    assert safety["no_auto_post_contract"] is True


def test_report10_gate_proves_router_and_core_evidence():
    evidence = gate.build_evidence()
    router = evidence["router"]
    assert router["main_router_present"] is True
    assert router["p12_imported"] is True
    assert router["p12_registered"] is True
    assert router["p12_final_verdict_wired"] is True
    assert router["crossborder_imported"] is True
    assert router["international_imported"] is True
    assert router["provenance_wired"] is True
    assert router["runtime_invariants_wired"] is True
    assert evidence["tests"]["critical_rule_evidence_complete"] is True
    assert evidence["legal_twin"]["critical_basis_refs"] == len(gate.CRITICAL_ARTICLES)


def test_article_range_parser_matches_legal_twin_ranges():
    assert gate._article_covers("19a-21", "a20") is True
    assert gate._article_covers("23m-23zf", "a23o") is True
    assert gate._article_covers("23m-23zf", "a23zf") is True
    assert gate._article_covers("29a-32", "a29") is True
    assert gate._article_covers("30f", "a30da") is True
    assert gate._article_covers("30f", "a30f") is True
    assert gate._article_covers("86", "a86r") is True
    assert gate._article_covers("23m-23zf", "a86r") is False


def test_report10_gate_accepts_only_complete_crossborder_rollout_contract(tmp_path, monkeypatch):
    """Exercise the full CROSS-BORDER rollout contract in an isolated state file only."""
    old_state_path = orchestrator.STATE_PATH
    orchestrator.STATE_PATH = tmp_path / "deployments.json"
    monkeypatch.setattr(orchestrator, "now", lambda: "2026-08-13T12:00:00+00:00")
    try:
        baseline = "previous-healthy"
        candidate = "jdg-xb-bundle-v9.0.0"
        orchestrator.cmd_init(SimpleNamespace(version=baseline))
        state = orchestrator.load_state()
        state["deployments"][baseline].update({
            "phase": "FULL_SOAK", "rollout_pct": 100,
            "quality": 100.0, "error_rate": 0.0,
        })
        state["healthy_versions"] = [baseline]
        state["active_version"] = baseline
        orchestrator.save_state(state)

        orchestrator.cmd_init(SimpleNamespace(version=candidate))
        state = orchestrator.load_state()
        state["deployments"][candidate].update({"quality": 100.0, "error_rate": 0.0})
        orchestrator.save_state(state)
        orchestrator.cmd_canary(SimpleNamespace(version=candidate))
        state = orchestrator.load_state()
        assert state["deployments"][candidate]["phase"] == "CANARY"
        state["deployments"][candidate]["canary_ok"] = True
        orchestrator.save_state(state)

        orchestrator.cmd_shadow_compare(SimpleNamespace(version=candidate, delta=1.0))
        orchestrator.cmd_ramped(SimpleNamespace(version=candidate))
        orchestrator.cmd_promote(SimpleNamespace(version=candidate))
        pending = orchestrator.load_state()["deployments"][candidate]
        completed_at = (
            datetime.fromisoformat(pending["soak_until"]) + timedelta(minutes=1)
        ).isoformat()
        orchestrator.cmd_complete_soak(
            SimpleNamespace(version=candidate, completed_at=completed_at)
        )
        assert orchestrator.load_state()["active_version"] == candidate

        monkeypatch.setattr(orchestrator, "now", lambda: "2026-08-13T12:05:00+00:00")
        orchestrator.cmd_auto_rollback(SimpleNamespace(
            version=candidate,
            reason="isolated contract",
            incident_started_at="2026-08-13T12:00:00+00:00",
        ))
        after_rollback = orchestrator.load_state()
        assert after_rollback["active_version"] == baseline
        assert after_rollback["deployments"][candidate]["rollback_sla_pass"] is True
        assert after_rollback["deployments"][candidate]["rollback_mttr_minutes"] == 5.0
        assert after_rollback["deployments"][candidate]["phase"] == "ROLLED_BACK"

        monkeypatch.setattr(gate, "BUNDLES_DIR", tmp_path)
        evidence = gate._deployment_evidence()
        assert evidence["xb_deployments"] == 1
        assert evidence["canary"] is True
        assert evidence["rollback_sla"] is True
        assert evidence["production_active"] is False
    finally:
        orchestrator.STATE_PATH = old_state_path


def test_report10_gate_is_fail_closed_without_production_evidence(tmp_path, monkeypatch):
    """The gate must fail closed when production evidence (Legal Twin, golden
    replay, canary/rollback) is absent. Verified against an isolated empty
    bundle dir so the committed deployments.json cannot mask a gap."""
    monkeypatch.setattr(gate, "BUNDLES_DIR", tmp_path)
    evidence = gate.build_evidence()
    assert evidence["status"] == "BLOCKED_BY_EVIDENCE"
    assert evidence["checks"]["duplicate_gate"] is True
    assert evidence["checks"]["temporal_gate"] is True
    assert evidence["checks"]["legal_twin_gate"] is False
    assert evidence["checks"]["golden_replay_gate"] is False
    assert evidence["checks"]["canary_rollback_gate"] is False

    output = tmp_path / "evidence.json"
    monkeypatch.setattr(gate, "EVIDENCE_PATH", output)
    output.write_text(json.dumps(evidence), encoding="utf-8")
    assert json.loads(output.read_text(encoding="utf-8"))["status"] == "BLOCKED_BY_EVIDENCE"


def test_report10_gate_passes_full_deployment_evidence():
    """Committed RAPORT_10 evidence: all 9 gates must pass (WDROZONY_100)."""
    evidence = gate.build_evidence()
    assert evidence["status"] == "WDROZONY_100"
    assert evidence["checks_passed"] == evidence["checks_total"] == 9
    assert evidence["deployment"]["xb_deployments"] >= 1
    assert evidence["deployment"]["canary"] is True
    assert evidence["deployment"]["rollback_sla"] is True
