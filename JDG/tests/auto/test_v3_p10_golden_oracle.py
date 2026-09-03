#!/usr/bin/env python3
"""Tests for V3 P10 (GOLDEN_ORACLE) — the 12 enterprise innovations.

Covers V3-P10-I01..I12 delivered by P10:
  * I01 golden vault WORM (immutable set, hash chain, append-only artifact)
  * I02 delta autopsy pipeline (classification → legal justification → verdict)
  * I03 merge oracle gate (CI blocks merge while UVR>0 or delta unjudged)
  * I04 formal proof matrix (invariant → method → status → CI hook)
  * I05 Z3 translation harness (Rego→SMT with unverifiable-fragment report)
  * I06 dual-node consensus (verdict hash on ≥2 nodes; divergence = degrade)
  * I07 oracle health dashboard (coverage, % justified, age, regen freq)
  * I08 independent oracle validator (anti self-fulfilling)
  * I09 golden coverage planner (domain coverage closure plan)
  * I10 retro-delta explorer (historical deltas with justifications)
  * I11 oracle export & seal (crypto seal for external audit)
  * I12 delta regression radar (early warning of rule drift)
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
BUNDLES = BASE_DIR / "bundles"
REPORT = BASE_DIR / "raporty_glm52_v3" / "RAPORT_V3_P10_GOLDEN_ORACLE.txt"
KONTRAKT = BASE_DIR / "docs" / "V3_P10_GOLDEN_ORACLE_KONTRAKT.md"


def _load_bundle(name: str) -> dict:
    return json.loads((BUNDLES / name).read_text(encoding="utf-8"))


def test_report_and_kontrakt_exist():
    assert REPORT.exists()
    assert KONTRAKT.exists()
    txt = REPORT.read_text(encoding="utf-8")
    assert "WDROŻONY_100" in txt
    for marker in ("9.01 EXECUTIVE SUMMARY", "9.06 REJESTR LUK",
                   "9.07 INNOWACJE ENTERPRISE", "9.08 KONTRAKT WYJŚCIOWY",
                   "V3-P10-I01", "V3-P10-I12", "V3-P10-L01"):
        assert marker in txt, f"missing marker {marker}"


def test_i01_golden_vault_worm():
    d = _load_bundle("v3_p10_golden_vault_worm.json")
    assert d["innovation"] == "V3-P10-I01"
    assert d["metrics"]["verdict_count"] >= 20
    assert d["metrics"]["schema_version"] == 2
    assert d["metrics"]["append_only_vault"] is False  # luka L01 — brak artefaktu WORM
    assert any(f["id"] == "V3-P10-L01" for f in d["findings"])


def test_i02_delta_autopsy_pipeline():
    d = _load_bundle("v3_p10_delta_autopsy_pipeline.json")
    assert d["innovation"] == "V3-P10-I02"
    assert d["metrics"]["classifier"] is True
    assert d["metrics"]["diff_p08_source"] is True  # v3_p08_legal_diff_schema.json istnieje
    assert d["metrics"]["diff_p08_read"] is False    # autojustify nie czyta diffu automatycznie
    assert any(f["id"] == "V3-P10-L02" for f in d["findings"])


def test_i03_merge_oracle_gate():
    d = _load_bundle("v3_p10_merge_oracle_gate.json")
    assert d["innovation"] == "V3-P10-I03"
    assert d["gate"] == "FAIL"
    assert d["metrics"]["golden_in_ci"] is True
    assert d["metrics"]["blocking"] is False  # L03 — wywołanie z || true (miękkie)
    assert any(f["id"] == "V3-P10-L03" and f["severity"] == "P0"
               for f in d["findings"])


def test_i04_formal_proof_matrix():
    d = _load_bundle("v3_p10_formal_proof_matrix.json")
    assert d["innovation"] == "V3-P10-I04"
    assert d["metrics"]["inv_total"] >= 15
    assert len(d["matrix"]) >= 15
    for row in d["matrix"]:
        assert row["method"] in ("SMT", "PROPERTY", "FUZZ")
        assert row["status"] in ("PROVEN", "UNVERIFIED")
    assert any(f["id"] == "V3-P10-L04" for f in d["findings"])


def test_i05_z3_translation_harness():
    d = _load_bundle("v3_p10_z3_translation_harness.json")
    assert d["innovation"] == "V3-P10-I05"
    assert d["metrics"]["formalizable_count"] >= 5
    assert d["metrics"]["unverifiable_classes"] >= 3
    assert "INV-003" in d["formalizable"]
    assert any("agregacje" in u or "ciągów" in u for u in d["unverifiable"])


def test_i06_dual_node_consensus():
    d = _load_bundle("v3_p10_dual_node_consensus.json")
    assert d["innovation"] == "V3-P10-I06"
    assert d["gate"] == "FAIL"
    assert d["metrics"]["differential_tool"] is True
    assert any(f["id"] == "V3-P10-L06" for f in d["findings"])


def test_i07_oracle_health_dashboard():
    d = _load_bundle("v3_p10_oracle_health_dashboard.json")
    assert d["innovation"] == "V3-P10-I07"
    assert d["metrics"]["verdict_count"] >= 20
    assert d["metrics"]["domain_count"] >= 10
    assert d["health"]["score_0_100"] > 0
    assert any(f["id"] == "V3-P10-L07" for f in d["findings"])


def test_i08_independent_oracle_validator():
    d = _load_bundle("v3_p10_independent_oracle_validator.json")
    assert d["innovation"] == "V3-P10-I08"
    assert d["gate"] == "PASS"
    assert d["metrics"]["verdict_count"] >= 20
    assert d["metrics"]["expert_ratio"] > 0.0


def test_i09_golden_coverage_planner():
    d = _load_bundle("v3_p10_golden_coverage_planner.json")
    assert d["innovation"] == "V3-P10-I09"
    assert d["gate"] == "FAIL"
    assert d["metrics"]["packages_total"] >= 50
    assert 0.0 <= d["metrics"]["coverage_pct"] <= 100.0
    assert any(f["id"] == "V3-P10-L09" for f in d["findings"])


def test_i10_retro_delta_explorer():
    d = _load_bundle("v3_p10_retro_delta_explorer.json")
    assert d["innovation"] == "V3-P10-I10"
    assert d["gate"] == "FAIL"
    assert d["metrics"]["annotated_records"] == 0
    assert any(f["id"] == "V3-P10-L10" for f in d["findings"])


def test_i11_oracle_export_seal():
    d = _load_bundle("v3_p10_oracle_export_seal.json")
    assert d["innovation"] == "V3-P10-I11"
    assert d["gate"] == "PASS"
    exp = d["export"]
    assert exp["seal_algorithm"] == "sha256-merkle-v1"
    assert len(exp["seal"]) == 64
    assert len(exp["merkle_root"]) == 64
    assert exp["verdict_count"] >= 20


def test_i12_delta_regression_radar():
    d = _load_bundle("v3_p10_delta_regression_radar.json")
    assert d["innovation"] == "V3-P10-I12"
    assert d["gate"] == "FAIL"
    assert d["metrics"]["uvr_alarm_threshold"] > 0
    assert d["metrics"]["radar_level"] in ("GREEN", "AMBER", "RED")
    assert any(f["id"] == "V3-P10-L12" for f in d["findings"])


def test_tools_cli_run_clean():
    # all 12 P10 tools run clean (exit 0/1 by gate; bundles written)
    for t in ("golden_vault_worm", "delta_autopsy_pipeline", "merge_oracle_gate",
              "formal_proof_matrix", "z3_translation_harness", "dual_node_consensus",
              "oracle_health_dashboard", "independent_oracle_validator",
              "golden_coverage_planner", "retro_delta_explorer",
              "oracle_export_seal", "delta_regression_radar"):
        out = subprocess.run(
            [sys.executable, str(BASE_DIR / "tools" / f"v3_p10_{t}.py")],
            capture_output=True, text=True, cwd=str(BASE_DIR), check=False,
        )
        assert "V3-P10" in out.stdout, f"{t}: {out.stdout} {out.stderr}"
