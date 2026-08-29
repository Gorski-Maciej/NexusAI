"""Acceptance tests for PROMPT_21 Control Plane infrastructure (F1–F6)."""
from __future__ import annotations

import json
from pathlib import Path

import pytest

JDG_ROOT = Path(__file__).resolve().parent.parent
import sys

sys.path.insert(0, str(JDG_ROOT / "tools"))

import differential_evaluation as de  # noqa: E402
import law_amendment_simulator as sim  # noqa: E402
import smt_z3_verification as smt  # noqa: E402
import worm_storage as worm  # noqa: E402


VERDICT = {"matched": True, "rule_id": "jdg.vat.example.r1", "vat_rate": 0.23,
           "net_amount": 100.0, "vat_amount": 23.0, "gross_amount": 123.0,
           "_provenance_tree": {"bundle_version": "jdg-bundle-v9.1.0"}}


def test_smt_z3_skeleton_never_declares_proof_without_solver():
    """Fail-open SKELETON: UNVERIFIED bez Z3, PROVEN tylko z solwerem."""
    if smt.HAS_Z3:
        result = smt.prove_zus()
        assert result["verified"] is True
        assert result["mode"] == "Z3"
        assert result["result"].startswith("PROVEN")
    else:
        result = smt.prove_pit()
        assert result["verified"] is False
        assert result["mode"] == "SKELETON"
        assert result["result"] == "UNVERIFIED — z3-solver niedostępny"


def test_differential_evaluation_detects_divergence_and_quorum():
    """F3 §4.4: identyczne hashe = determinizm; rozjazd = divergence + quorum."""
    node_a = dict(VERDICT)
    node_b = dict(VERDICT)
    result = de.compare(VERDICT, [("node-a", node_a), ("node-b", node_b)])
    assert result["deterministic"] is True
    assert result["quorum_ok"] is True
    assert result["nodes_matched"] == 2

    node_b["vat_rate"] = 0.08
    result = de.compare(VERDICT, [("node-a", node_a), ("node-b", node_b)])
    assert result["deterministic"] is False
    assert result["nodes_matched"] == 1
    assert result["nodes"][1]["first_diff_field"] == "vat_rate"
    assert result["quorum_ok"] is False  # 1/2 < 2/3


def test_worm_storage_is_append_only_and_tamper_evident(tmp_path):
    """V1 §11: append-only, łańcuch hashów, merkle root; modyfikacja wykryta."""
    worm.WORM_PATH = tmp_path / "worm_audit.json"
    first = worm.write_record({"event": "CHANGE_SUBMITTED", "change_id": "CHG-00000001"})
    second = worm.write_record({"event": "DEPLOYMENT_AUTHORIZED", "change_id": "CHG-00000001"})
    assert second["prev_hash"] == first["record_hash"]
    assert worm.verify_chain()["verified"] is True

    data = json.loads((tmp_path / "worm_audit.json").read_text(encoding="utf-8"))
    data["records"][0]["payload"]["event"] = "TAMPERED"
    (tmp_path / "worm_audit.json").write_text(json.dumps(data), encoding="utf-8")
    result = worm.verify_chain()
    assert result["verified"] is False
    assert any("record_hash" in issue for issue in result["issues"])


def test_law_amendment_simulator_projects_impact_in_shadow_mode():
    """V2 F5 §6.3: symulacja „co gdyby prawo weszło wczoraj\" — SHADOW_ONLY."""
    verdicts = [
        {**VERDICT, "rule_id": "jdg.vat.exemption.limit_200k", "limit_amount": 200000},
        {**VERDICT, "rule_id": "jdg.vat.exemption.limit_200k", "limit_amount": 150000},
        {**VERDICT, "rule_id": "jdg.vat.other.rule", "limit_amount": 200000},
    ]
    result = sim.simulate("Podniesienie limitu zwolnienia VAT", "jdg.vat.exemption.limit_200k",
                          "limit_amount", 200000, 240000, verdicts)
    assert result["verdicts_matching_rule"] == 2
    assert result["verdicts_impacted"] == 2
    assert result["impact_pct"] == 100.0
    assert result["mode"] == "SHADOW_ANALYSIS_ONLY"
    assert "declarative_change" in result["recommendation"]


def test_report21_gate_produces_evidence_and_full_gates():
    """Bramka raportu 21: 14/14 bramek i status WDROZONY_100."""
    import control_plane_report21_gate as gate

    evidence = gate.build_evidence()
    assert evidence["status"] == "WDROZONY_100", evidence["gate_summary"]
    assert evidence["gate_summary"]["passed"] == evidence["gate_summary"]["total"] == 14
    assert evidence["genius_ideas"]["implemented"] == 12
    assert evidence["production_status"] == "NOT_CERTIFIED"
    assert evidence["scope"]["all_present"] is True
    assert evidence["syntax"]["syntax_ok"] is True
