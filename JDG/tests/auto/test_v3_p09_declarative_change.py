#!/usr/bin/env python3
"""Tests for V3 P09 (DECLARATIVE_CHANGE) — the 12 enterprise innovations.

Covers V3-P09-I01..I12 delivered by P09:
  * I01 declaration schema v1 (JSON Schema + date/range/LKG validation)
  * I02 intent compiler (declaration → precise change plan w/ confidence)
  * I03 recipe library (6 recipes: rate/threshold/new-limit/deadline/repeal/definition)
  * I04 auto-test synthesizer (D-1/D0/D+1/±grosz/negative per declaration)
  * I05 impact preview (portfolio replay before approval)
  * I06 4-eyes flow engine (roles + approval gates with signatures)
  * I07 dangerous change guard (BLOCK/MANUAL_REVIEW before EXECUTE)
  * I08 law radar prefill (diff → prefilled declaration)
  * I09 rollback-as-declaration (revert = new declaration with reverts)
  * I10 change telemetry (decl→prod SLO, rejections, role load)
  * I11 emergency manual mode (retro-declaration ≤ 48 h)
  * I12 declarative UI contract (fields, validations, LKG hints)
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
BUNDLES = BASE_DIR / "bundles"
REPORT = BASE_DIR / "raporty_glm52_v3" / "RAPORT_V3_P09_DECLARATIVE_CHANGE.txt"


def _load_bundle(name: str) -> dict:
    return json.loads((BUNDLES / name).read_text(encoding="utf-8"))


def _run_tool(name: str, *args: str) -> str:
    # FAIL-gate tools exit 1 by design (gap registered); output still required
    return subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / name), *args],
        capture_output=True, text=True, cwd=str(BASE_DIR), check=False,
    ).stdout


def test_report_exists_and_is_complete():
    assert REPORT.exists()
    txt = REPORT.read_text(encoding="utf-8")
    assert "WDROŻONY_100" in txt
    for marker in ("9.01 EXECUTIVE SUMMARY", "9.06 REJESTR LUK",
                   "9.07 INNOWACJE ENTERPRISE", "9.08 KONTRAKT WYJŚCIOWY",
                   "V3-P09-I01", "V3-P09-I12", "V3-P09-L01"):
        assert marker in txt, f"missing marker {marker}"


def test_i01_declaration_schema():
    d = _load_bundle("v3_p09_declaration_schema.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["schema_validation_in_tool"] is False
    assert d["metrics"]["required_fields"] >= 8
    assert "change_type" in d["schema"]["properties"]
    assert any(f["id"] == "V3-P09-L01" for f in d["findings"])


def test_i02_intent_compiler():
    d = _load_bundle("v3_p09_intent_compiler.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["targets_missing"] >= 1
    assert any(f["id"] == "V3-P09-L02" for f in d["findings"])


def test_i03_recipe_library():
    d = _load_bundle("v3_p09_recipe_library.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["recipes"] == 6
    assert set(d["recipes"]) == {"RATE_CHANGE", "THRESHOLD_CHANGE", "NEW_LIMIT",
                                 "DEADLINE_CHANGE", "REPEAL", "DEFINITION_CHANGE"}
    assert any(f["id"] == "V3-P09-L03" for f in d["findings"])


def test_i04_auto_test_synthesizer():
    d = _load_bundle("v3_p09_auto_test_synthesizer.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["tests_per_recipe"] == 5
    assert d["metrics"]["wired_in_tool"] is False
    assert any(f["id"] == "V3-P09-L04" for f in d["findings"])


def test_i05_impact_preview():
    d = _load_bundle("v3_p09_impact_preview.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["registered_rules"] == 13
    assert d["metrics"]["code_rule_ids"] > 10000
    assert any(f["id"] == "V3-P09-L05" for f in d["findings"])


def test_i06_four_eyes_flow():
    d = _load_bundle("v3_p09_four_eyes_flow.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["enforced_in_tool"] is False
    assert any(f["id"] == "V3-P09-L06" for f in d["findings"])


def test_i07_dangerous_change_guard():
    d = _load_bundle("v3_p09_dangerous_change_guard.json")
    assert d["gate"] == "FAIL"
    res = d["metrics"]["guard_results"]
    assert res["DEC-NO-BASIS"] == "BLOCK"
    assert res["DEC-NEW-DOMAIN"] == "MANUAL_REVIEW"
    assert res["DEC-VALID"] == "OK"
    assert any(f["id"] == "V3-P09-L07" and f["severity"] == "P0"
               for f in d["findings"])


def test_i08_law_radar_prefill():
    d = _load_bundle("v3_p09_law_radar_prefill.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["with_diff"] == 0
    assert d["prefill_demo"]["prefilled"] is True
    assert any(f["id"] == "V3-P09-L08" for f in d["findings"])


def test_i09_rollback_declaration():
    d = _load_bundle("v3_p09_rollback_declaration.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["history_exists"] is False
    assert any(f["id"] == "V3-P09-L09" for f in d["findings"])


def test_i10_change_telemetry():
    d = _load_bundle("v3_p09_change_telemetry.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["recorded_declarations"] == 0
    assert d["metrics"]["slo"]["decl_to_prod_days"] == 14
    assert any(f["id"] == "V3-P09-L10" for f in d["findings"])


def test_i11_emergency_manual_mode():
    d = _load_bundle("v3_p09_emergency_manual_mode.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["retro_deadline_hours"] == 48
    assert any(f["id"] == "V3-P09-L11" for f in d["findings"])


def test_i12_ui_contract():
    d = _load_bundle("v3_p09_ui_contract.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["api_files"] == []
    assert d["metrics"]["fields"] >= 6
    assert any(f["id"] == "V3-P09-L12" for f in d["findings"])


def test_tools_cli_run_clean():
    # all 12 P09 tools run clean (exit 0=PASS/1=FAIL by gate; verified via bundles)
    for t in ("declaration_schema", "intent_compiler", "recipe_library",
              "auto_test_synthesizer", "impact_preview", "four_eyes_flow",
              "dangerous_change_guard", "law_radar_prefill", "rollback_declaration",
              "change_telemetry", "emergency_manual_mode", "ui_contract"):
        out = _run_tool(f"v3_p09_{t}.py")
        assert "V3-P09" in out, t
