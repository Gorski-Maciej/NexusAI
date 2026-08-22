"""ETAP 24 — tests, CI and zero-defect evidence contract."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "rules" / "tests_ci_quality_etap24_v1.rego"
MAIN = ROOT / "rules" / "main_jdg.rego"
THRESHOLDS = ROOT / "rules" / "thresholds_jdg.rego"
WORKFLOW = ROOT / ".github" / "workflows" / "jdg-quality.yml"
AUDITOR = ROOT / "tools" / "tests_ci_quality_etap24_audit.py"
REPORT = ROOT / "raporty_glm52_enterprise" / "24_TESTS_CI_QUALITY.txt"
BUNDLE = ROOT / "bundles" / "tests_ci_quality_etap24_audit_state.json"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_package_structure_and_no_placeholder_rules():
    text = read(PACKAGE)
    assert "package jdg.tests_ci_quality_etap24" in text
    assert text.count('"rule_id":') == 2
    assert text.count("{") == text.count("}")
    assert text.count("(") == text.count(")")
    assert "assert " + "True" not in text


def test_quality_contract_covers_all_required_layers():
    text = read(PACKAGE)
    for marker in [
        "scope_complete", "static_gates_complete", "property_complete", "mutation_complete",
        "fuzz_complete", "boundary_complete", "coverage_complete", "regression_complete",
        "golden_complete", "chaos_complete", "security_complete", "dr_complete",
        "fail_on_empty", "manual_review_required", "BLOCK_AND_ALERT", "TRIAGE_QUEUE",
        "reproducibility_seed", "run_hash", "evidence_refs",
    ]:
        assert marker in text


def test_workflow_is_fail_closed():
    text = read(WORKFLOW)
    assert "|| true" not in text
    assert "opa check rules/ -b" in text
    assert "opa test tests/rego/ -v --fail-on-empty" in text
    assert "needs: [lint-and-validate, tests, golden, bundle]" in text


def test_no_assert_true_placeholders_remain():
    files = list((ROOT / "tests").rglob("*.py"))
    needle = "assert " + "True"
    offenders = [str(path) for path in files if needle in read(path)]
    assert offenders == offenders[:0], f"placeholder assertions: {offenders}"


def test_threshold_registry_and_orchestrator_wiring():
    thresholds = read(THRESHOLDS)
    main = read(MAIN)
    assert "tests_ci_quality_etap24 := {" in thresholds
    for marker in ["min_coverage_pct", "min_critical_coverage_pct", "min_mutation_pct", "min_fuzz_cases", "fail_on_empty", "required_gates"]:
        assert marker in thresholds
    assert "import data.jdg.tests_ci_quality_etap24" in main
    assert '"jdg.tests_ci_quality_etap24": tests_ci_quality_etap24.decide' in main
    assert "final_verdict_p68 = safe_merge(final_verdict_p67" in main
    assert "object.union(final_verdict_p68" in main
    assert "final_verdict = final_verdict_enforced" in main


def test_auditor_builds_complete_evidence():
    proc = subprocess.run(
        [sys.executable, str(AUDITOR), "build", "--json"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
        timeout=30,
    )
    assert proc.returncode == 0, proc.stderr
    evidence = json.loads(proc.stdout)
    assert evidence["status"] == "WDROZONY_100"
    assert evidence["gate_summary"] == {"passed": 16, "total": 16}
    assert evidence["workflow"]["ignored_failure_count"] == 0
    assert evidence["false_positive_scan"]["no_assert_true"] is True


def test_report_and_bundle_consistent():
    assert REPORT.exists()
    assert BUNDLE.exists()
    report = read(REPORT)
    bundle = json.loads(read(BUNDLE))
    assert "WDROZONY_100" in report
    assert "ETAP_24_COMPLETE" in report
    assert bundle["status"] == "WDROZONY_100"
    assert bundle["gate_summary"] == {"passed": 16, "total": 16}
    assert bundle["gates"]["orchestrator_wiring"] is True


def test_mutation_fuzz_security_and_dr_controls_are_declared():
    """Cover mutation, fuzz, security and disaster recovery evidence."""
    text = read(PACKAGE)
    for marker in ["mutation_complete", "fuzz_complete", "security_complete", "dr_complete"]:
        assert marker in text
    assert "--fail-on-empty" in read(WORKFLOW)


def test_quality_tools_have_non_empty_entrypoints():
    for relative in [
        "tools/validate_rules.py", "tools/lint_rego_rules.py", "tools/test_coverage_gate.py",
        "tools/property_suite.py", "tools/fuzz_runner.py", "tools/mutation_runner.py",
        "tools/golden_replay.py", "tools/chaos_runner.py",
    ]:
        text = read(ROOT / relative)
        assert "def main" in text, relative
        assert len(text.strip()) > 500, relative
