"""Kampania V3, część 10 — testy kontraktowe bramki pcc_lokalne_v3_gate.

Pokrycie:
- gate PASS (wiring 15 pakietów, duplikaty, thresholds, kontrakt v3_10),
- evidence bundle bundles/pcc_lokalne_v3_audit_10.json,
- klucze progów pcc_local_excise w thresholds_jdg.rego (+ wersjonowanie),
- natywny artefakt Rego tests/rego/test_native_pcc_v3_10.rego.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GATE = ROOT / "tools" / "pcc_lokalne_v3_gate.py"
EVIDENCE = ROOT / "bundles" / "pcc_lokalne_v3_audit_10.json"
NATIVE = ROOT / "tests" / "rego" / "test_native_pcc_v3_10.rego"


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
    assert len(existing) == len(report["files_audited"]) == 15
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
    assert len(report["wiring"]["wired"]) == report["wiring"]["required"] == 15
    assert report["wiring"]["unwired"] == []
    main_text = (ROOT / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    for pkg in ["jdg.local_taxes.pcc", "jdg.local_taxes.real_estate",
                "jdg.local_taxes.transport", "jdg.local_taxes.plan26",
                "jdg.akcyza.alcohol_tobacco", "jdg.akcyza.fuel_energy",
                "jdg.local.enterprise", "jdg.local_taxes.v3_10"]:
        assert f'"{pkg}"' in main_text


def test_pcc_local_excise_threshold_keys() -> None:
    report = run_gate()
    assert report["thresholds"]["missing"] == []
    th_text = (ROOT / "rules" / "thresholds_jdg.rego").read_text(encoding="utf-8")
    for key in ["pcc_sale_rate", "pcc_family_loan_limit", "pcc_exemption_limit",
                "pcc3_deadline_days", "transport_dn1_deadline_days",
                "excise_gasoline", "excise_ethanol_per_hl"]:
        assert f'"{key}"' in th_text
    assert '"threshold_version": "pcc-local-2026.08"' in th_text


def test_v3_10_contract_markers() -> None:
    report = run_gate()
    assert report["v3_10_contract"]["all_pass"]
    text = (ROOT / "rules" / "local_taxes" / "v3_10_enterprise.rego").read_text(encoding="utf-8")
    assert '"rule_id": "jdg.local_taxes.v3_10.no_match"' in text
    assert "fail_closed_decision" in text
    for rid in ["pcc_rate_engine", "pcc3_deadline_guard", "real_estate_max_rate_validator",
                "dn1_deadline_guard", "excise_rate_check", "excise_vat_shortcut",
                "local_taxes_certificate"]:
        assert f"jdg.local_taxes.v3_10.{rid}" in text


def test_evidence_bundle_written() -> None:
    run_gate()
    data = json.loads(EVIDENCE.read_text(encoding="utf-8"))
    assert data["tool"] == "pcc_lokalne_v3_gate"
    assert data["gate_status"] == "PASS"
    assert data["kampania"].startswith("V3 część 10")


def test_native_rego_artifact_exists() -> None:
    text = NATIVE.read_text(encoding="utf-8")
    assert "package tests.test_native_pcc_v3_10" in text
    for tid in ["T01", "T02", "T03", "T04", "T05", "T06", "T07", "T08", "T09", "T10", "T11", "T12"]:
        assert f"# {tid}:" in text
