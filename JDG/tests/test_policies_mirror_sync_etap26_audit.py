"""ETAP 26 — policies mirror/overlay sync governance evidence contract."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "rules" / "policies_mirror_sync_etap26_v1.rego"
MAIN = ROOT / "rules" / "main_jdg.rego"
THRESHOLDS = ROOT / "rules" / "thresholds_jdg.rego"
AUDITOR = ROOT / "tools" / "policies_mirror_sync_etap26_audit.py"
REPORT = ROOT / "raporty_glm52_enterprise" / "26_POLICIES_MIRROR_SYNC.txt"
BUNDLE = ROOT / "bundles" / "policies_mirror_sync_etap26_audit_state.json"
SYNC_GATE = ROOT / "tools" / "policies_sync_gate.py"
OVERLAY_ENGINE = ROOT / "tools" / "overlay_engine.py"
POLICIES_README = ROOT.parent / "policies" / "README.md"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_package_structure_and_no_placeholder_rules():
    text = read(PACKAGE)
    assert "package jdg.policies_mirror_sync_etap26" in text
    assert text.count('"rule_id":') == 2
    assert text.count("{") == text.count("}")
    assert text.count("(") == text.count(")")


def test_contract_covers_all_required_layers():
    text = read(PACKAGE)
    for marker in [
        "source_of_truth_declared", "mirror_synced", "hash_parity_complete",
        "decision_parity_complete", "legal_parity_complete",
        "overlays_complete", "overlays_tcl_100", "overlays_no_ghosts",
        "experimental_marked", "no_silent_change",
        "BLOCK_AND_ALERT", "TRIAGE_QUEUE", "MIRROR_SYNCED", "MIRROR_DRIFT",
    ]:
        assert marker in text


def test_sync_gate_has_hash_contract_legal_parity_commands():
    text = read(SYNC_GATE)
    for cmd in ["hash-parity", "contract", "legal-parity", "drift", "sync"]:
        assert cmd in text
    assert "JDG/rules/" in text
    assert "single source of truth" in text


def test_overlay_engine_and_generator_checks_tcl_and_ghosts():
    eng = read(OVERLAY_ENGINE)
    gen = read(ROOT / "tools" / "overlay_generator.py")
    assert "tcl_100" in eng
    assert "ghost_count" in gen
    assert "effective_from" in gen or "effective_from" in eng


def test_threshold_registry_and_orchestrator_wiring():
    thresholds = read(THRESHOLDS)
    main = read(MAIN)
    assert "policies_mirror_sync_etap26 := {" in thresholds
    for marker in ["max_drift_pct", "min_parity_pct", "source_of_truth",
                   "mirror_role", "required_gates"]:
        assert marker in thresholds
    assert "import data.jdg.policies_mirror_sync_etap26" in main
    assert '"jdg.policies_mirror_sync_etap26": policies_mirror_sync_etap26.decide' in main
    assert "final_verdict_p70 = safe_merge(final_verdict_p69" in main
    assert "object.union(final_verdict_p70" in main


def test_policies_readme_declares_source_of_truth_and_no_silent_change():
    text = read(POLICIES_README)
    assert "source of truth" in text
    assert "JDG/rules/" in text
    assert "mirror nie może" in text
    assert "eksperyment" in text


def test_drift_and_parity_gates_pass():
    for cmd, gate in [("drift", "0"), ("hash-parity", "0"), ("contract", "0"), ("legal-parity", "0")]:
        proc = subprocess.run(
            [sys.executable, str(SYNC_GATE), cmd, "--gate", gate, "--json"],
            cwd=ROOT, capture_output=True, text=True, timeout=60,
        )
        assert proc.returncode == 0, f"{cmd} failed: {proc.stderr}"
        data = json.loads(proc.stdout)
        assert data["gate_passed"] is True, f"{cmd} gate not passed"


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
    assert "ETAP_26_COMPLETE" in report
    assert bundle_data["status"] == "WDROZONY_100"


def test_overlay_manifest_v2026_and_v2027_exist():
    v2026 = ROOT.parent / "policies" / "jdg" / "bundles" / "overlays" / "v2026" / "manifest.json"
    v2027 = ROOT.parent / "policies" / "jdg" / "bundles" / "overlays" / "v2027" / "manifest.json"
    assert v2026.exists()
    assert v2027.exists()
    m26 = json.loads(read(v2026))
    assert m26["tax_year"] == 2026
    assert m26["effective_from"] == "2026-01-01"


def test_no_silent_change_and_experimental_variants_manifest():
    """The mirror README must enforce the no-silent-change and experimental-variant rules."""
    text = read(POLICIES_README)
    assert "no-silent-change" in text.lower() or "nie może cicho" in text.lower()
    assert "EXPERIMENTAL" in text