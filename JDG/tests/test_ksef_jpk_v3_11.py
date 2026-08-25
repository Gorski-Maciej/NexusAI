"""Kampania V3, część 11 — testy kontraktowe bramki ksef_jpk_v3_gate.

Pokrycie:
- gate PASS (wiring 20 pakietów, duplikaty, thresholds, kontrakt v3_11),
- evidence bundle bundles/ksef_jpk_v3_audit_11.json,
- klucze progów ksef_jpk_edeklaracje w thresholds_jdg.rego (+ wersjonowanie),
- natywny artefakt Rego tests/rego/test_native_ksef_jpk_v3_11.rego.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GATE = ROOT / "tools" / "ksef_jpk_v3_gate.py"
EVIDENCE = ROOT / "bundles" / "ksef_jpk_v3_audit_11.json"
NATIVE = ROOT / "tests" / "rego" / "test_native_ksef_jpk_v3_11.rego"


def run_gate() -> dict:
    result = subprocess.run(
        [sys.executable, str(GATE), "--json"],
        capture_output=True, text=True, check=False,
    )
    assert result.returncode == 0, f"gate FAIL:\n{result.stdout}\n{result.stderr}"
    return json.loads(result.stdout)


def test_gate_pass() -> None:
    report = run_gate()
    assert report["gate_status"] == "PASS"
    assert report["errors"] == []


def test_all_domain_files_exist_with_packages() -> None:
    report = run_gate()
    existing = [f for f in report["files_audited"] if f.get("exists")]
    assert len(existing) == len(report["files_audited"]) == 20
    for fa in existing:
        assert fa["package"], f"{fa['file']}: brak package"


def test_no_duplicate_rule_ids() -> None:
    report = run_gate()
    for fa in report["files_audited"]:
        if fa.get("exists"):
            assert fa["duplicates_in_file"] == [], fa["file"]
    assert report["cross_file_duplicates"] == []


def test_orphan_packages_are_now_wired() -> None:
    report = run_gate()
    assert len(report["wiring"]["wired"]) == report["wiring"]["required"] == 20
    assert report["wiring"]["unwired"] == []
    main_text = (ROOT / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    for pkg in ["jdg.ksef_innovations", "jdg.ksef_outbox", "jdg.ksef_offline_queue",
                "jdg.ksef_sandbox", "jdg.ksef_upo_tracker", "jdg.ksef_receipt_digest",
                "jdg.ksef_sanction_monitor", "jdg.jpk_corrections", "jdg.jpk_kr_st",
                "jdg.edelivery_gateway", "jdg.enterprise.edelivery_gateway",
                "jdg.esig_auto", "jdg.enterprise.wis_autorequester", "jdg.ksef_jpk.v3_11"]:
        assert f'"{pkg}"' in main_text


def test_ksef_jpk_threshold_keys() -> None:
    report = run_gate()
    assert report["thresholds"]["missing"] == []
    th_text = (ROOT / "rules" / "thresholds_jdg.rego").read_text(encoding="utf-8")
    for key in ["ksef_mandatory_from", "ksef_offline_grace_days",
                "ksef_sanction_max_pln", "ksef_upo_deadline_days",
                "edelivery_mandatory_from", "wis_expiry_critical_days",
                "threshold_version"]:
        assert f'"{key}"' in th_text
    assert '"threshold_version": "ksef-jpk-2026.08"' in th_text


def test_v3_11_contract_markers() -> None:
    report = run_gate()
    assert report["v3_11_contract"]["all_pass"]
    text = (ROOT / "rules" / "ksef_jpk" / "v3_11_enterprise.rego").read_text(encoding="utf-8")
    assert '"rule_id": "jdg.ksef_jpk.v3_11.no_match"' in text
    assert "fail_closed_decision" in text
    for rid in ["ksef_mandatory_gate", "offline_queue_guard", "upo_validation_guard",
                "edelivery_address_guard", "b2c_without_nip_handler",
                "jpk_ksef_reconcile", "wis_expiry_watcher", "domain_certificate"]:
        assert f"jdg.ksef_jpk.v3_11.{rid}" in text


def test_evidence_bundle_written() -> None:
    run_gate()
    data = json.loads(EVIDENCE.read_text(encoding="utf-8"))
    assert data["tool"] == "ksef_jpk_v3_gate"
    assert data["gate_status"] == "PASS"
    assert data["kampania"].startswith("V3 część 11")


def test_native_rego_artifact_exists() -> None:
    text = NATIVE.read_text(encoding="utf-8")
    assert "package tests.test_native_ksef_jpk_v3_11" in text
    for tid in ["T01", "T02", "T03", "T04", "T05", "T06", "T07", "T08", "T09", "T10", "T11", "T12"]:
        assert f"# {tid}:" in text
