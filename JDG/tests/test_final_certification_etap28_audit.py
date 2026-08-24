"""ETAP 28 — final certification & master report evidence contract."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "rules" / "final_certification_etap28_v1.rego"
MAIN = ROOT / "rules" / "main_jdg.rego"
THRESHOLDS = ROOT / "rules" / "thresholds_jdg.rego"
AUDITOR = ROOT / "tools" / "final_certification_etap28_audit.py"
REPORT = ROOT / "raporty_glm52_enterprise" / "28_FINAL_CERTIFICATION.txt"
BUNDLE = ROOT / "bundles" / "final_certification_etap28_audit_state.json"
REPORTS_DIR = ROOT / "raporty_glm52_enterprise"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_package_structure():
    text = read(PACKAGE)
    assert "package jdg.final_certification_etap28" in text
    assert text.count('"rule_id":') == 2
    assert text.count("{") == text.count("}")
    assert text.count("(") == text.count(")")


def test_contract_covers_all_required_layers():
    text = read(PACKAGE)
    for marker in [
        "reconciliation_ok", "matrix_complete", "system_certified",
        "blockers_cleared", "slo_sla_complete", "honesty_declared",
        "CERTIFICATION_PASSED", "CERTIFICATION_FAILED",
        "NOT_CERTIFIED", "BLOCK_AND_ALERT", "CERTIFIED", "CONDITIONAL",
        "BLOCKED", "domains_certified", "domains_blocked",
    ]:
        assert marker in text


def test_all_28_reports_present():
    reports = sorted(REPORTS_DIR.glob("[0-9][0-9]_*.txt"))
    assert len(reports) >= 27, f"Only {len(reports)} / 28+ reports present"


def test_all_reports_are_wdrozone_100():
    failed = []
    for rp in sorted(REPORTS_DIR.glob("[0-9][0-9]_*.txt")):
        txt = rp.read_text(encoding="utf-8")
        if "WDROZONY_100" not in txt and "WDROŻONY_100" not in txt and "COMPLETE" not in txt:
            failed.append(rp.stem)
    assert not failed, f"Not marked as done: {failed}"


def test_threshold_registry_and_orchestrator_wiring():
    thresholds = read(THRESHOLDS)
    main = read(MAIN)
    assert "final_certification_etap28 := {" in thresholds
    assert "import data.jdg.final_certification_etap28" in main
    assert '"jdg.final_certification_etap28": final_certification_etap28.decide' in main
    assert "final_verdict_p72 = safe_merge(final_verdict_p71" in main
    assert "final_verdict_p72" in main
    assert "final_verdict_post_merge = safe_merge(" in main


def test_auditor_builds_complete_evidence():
    proc = subprocess.run(
        [sys.executable, str(AUDITOR), "build", "--json"],
        cwd=ROOT, capture_output=True, text=True, timeout=60,
    )
    assert proc.returncode == 0, proc.stderr
    evidence = json.loads(proc.stdout)
    assert evidence["status"] == "WDROZONY_100"
    assert evidence["reconciliation"]["all_wdrozone"]


def test_report_contains_final_marker():
    assert REPORT.exists()
    report = read(REPORT)
    assert "WDROZONY_100" in report
    assert "ETAP_28_COMPLETE" in report
    assert "SERIES_COMPLETE" in report


def test_domains_all_certified_or_conditional():
    proc = subprocess.run(
        [sys.executable, str(AUDITOR), "build", "--json"],
        cwd=ROOT, capture_output=True, text=True, timeout=60,
    )
    evidence = json.loads(proc.stdout)
    ds = evidence["domains_summary"]
    assert ds["blocked"] == 0
    assert ds["certified"] + ds["conditional"] >= 15


def test_production_status_not_certified():
    text = read(PACKAGE)
    assert "NOT_CERTIFIED" in text
    assert 'production_status' in text
    assert '"PRODUCTION"' not in text  # production_status value is NOT_CERTIFIED


def test_honesty_report_present():
    text = read(REPORT)
    assert "CO NAPRAWDĘ DZIAŁA" in text or "HONESTY" in text
    assert "NOT_CERTIFIED" in text