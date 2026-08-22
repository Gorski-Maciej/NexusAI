"""ETAP 27 — cross-domain red team, integration, resilience evidence contract."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "rules" / "cross_domain_red_team_etap27_v1.rego"
MAIN = ROOT / "rules" / "main_jdg.rego"
THRESHOLDS = ROOT / "rules" / "thresholds_jdg.rego"
AUDITOR = ROOT / "tools" / "cross_domain_red_team_etap27_audit.py"
REPORT = ROOT / "raporty_glm52_enterprise" / "27_CROSS_DOMAIN_RED_TEAM.txt"
BUNDLE = ROOT / "bundles" / "cross_domain_red_team_etap27_audit_state.json"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_package_structure_and_no_placeholder_rules():
    text = read(PACKAGE)
    assert "package jdg.cross_domain_red_team_etap27" in text
    assert text.count('"rule_id":') == 2
    assert text.count("{") == text.count("}")
    assert text.count("(") == text.count(")")


def test_contract_covers_all_required_layers():
    text = read(PACKAGE)
    for marker in [
        "conflict_registry_complete", "attack_catalog_complete",
        "chaos_matrix_complete", "temporal_boundary_complete",
        "fraud_scenarios_complete", "fail_closed_proof_complete",
        "auto_post_guard_complete", "contract_tests_complete",
        "tools_verified_complete",
        "RED_TEAM_DEFEATED", "RED_TEAM_VULNERABLE",
        "BLOCK_AND_ALERT", "TRIAGE_QUEUE",
        "auto_post_blocked_on_error", "manual_review_hard_block",
        "decision_mode_suggest_only",
    ]:
        assert marker in text


def test_conflict_and_chaos_tools_exist():
    for tool in [
        "cross_package_conflict_detector.py", "chaos_runner.py",
        "chaos_engineering.py", "fraud_graph_scanner.py",
        "predictive_audit_shield.py", "rule_impact_simulator.py",
    ]:
        p = ROOT / "tools" / tool
        assert p.exists(), tool


def test_security_fortress_and_cross_act_rules_exist():
    for rule in [
        "rules/security/security_fortress_v8.rego",
        "rules/p35_cross_act_coherence.rego",
        "rules/p35_system_gaps.rego",
        "rules/conflicts.rego", "rules/edge_cases.rego",
        "rules/risk.rego",
    ]:
        assert (ROOT / rule).exists(), rule


def test_threshold_registry_and_orchestrator_wiring():
    thresholds = read(THRESHOLDS)
    main = read(MAIN)
    assert "cross_domain_red_team_etap27 := {" in thresholds
    for marker in ["min_conflict_pairs", "min_attack_scenarios",
                   "min_chaos_experiments", "auto_post_always_blocked_on_error"]:
        assert marker in thresholds
    assert "import data.jdg.cross_domain_red_team_etap27" in main
    assert '"jdg.cross_domain_red_team_etap27": cross_domain_red_team_etap27.decide' in main
    assert "final_verdict_p71 = safe_merge(final_verdict_p70" in main
    assert "object.union(final_verdict_p71" in main


def test_fail_closed_and_auto_post_guard():
    text = read(PACKAGE)
    assert "fail_closed_proof_complete" in text
    assert "auto_post_blocked_on_error" in text
    assert "manual_review_hard_block" in text
    assert "decision_mode_suggest_only" in text
    assert "no_auto_post" in text


def test_chaos_runner_has_required_experiments():
    cr = read(ROOT / "tools" / "chaos_runner.py")
    for exp in ["CORRUPT_BUNDLE", "EMPTY_THRESHOLDS", "KSEF_OFFLINE_72H"]:
        assert exp in cr


def test_auditor_builds_complete_evidence():
    proc = subprocess.run(
        [sys.executable, str(AUDITOR), "build", "--json"],
        cwd=ROOT, capture_output=True, text=True, timeout=60,
    )
    assert proc.returncode == 0, proc.stderr
    evidence = json.loads(proc.stdout)
    assert evidence["status"] == "WDROZONY_100"


def test_report_and_bundle_consistent():
    assert REPORT.exists()
    assert BUNDLE.exists()
    report = read(REPORT)
    bundle_data = json.loads(read(BUNDLE))
    assert "WDROZONY_100" in report
    assert "ETAP_27_COMPLETE" in report
    assert bundle_data["status"] == "WDROZONY_100"


def test_no_match_and_fail_closed_defaults():
    text = read(PACKAGE)
    assert "default decide := {" in text
    assert '"rule_id": "jdg.cross_domain_red_team_etap27.no_match"' in text
    assert '"no_auto_post": true' in text


def test_fraud_and_temporal_coverage():
    text = read(PACKAGE)
    for marker in ["empty_invoice", "shell_company", "circular_trade",
                   "carousel_vat", "transfer_pricing",
                   "day_minus_1", "day_zero", "day_plus_1",
                   "mid_period_law_change"]:
        assert marker in text