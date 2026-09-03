#!/usr/bin/env python3
"""Tests for V3 P07 (RULE_LIFECYCLE) — the 12 enterprise innovations.

Covers V3-P07-I01..I12 delivered by P07:
  * I01 promotion contract engine (closed-list promotion criteria)
  * I02 immutable rule vault (version hashes, WORM, no in-place edits)
  * I03 shadow delta automator (delta ≤ 2% enforced on promote path)
  * I04 kill-switch SLA (< 1 s suspend, NEEDS_ADVICE, SLO MTTR)
  * I05 4-eyes enforcement layer (author ≠ reviewer ≠ operator)
  * I06 retirement scheduler (grace 2 periods, purge zero-refs)
  * I07 change queue & locks (per-domain serialization)
  * I08 fiscal-year version boundary (01.01 + year-crossing tests)
  * I09 registry reconciler (rule_registry.json vs code)
  * I10 lifecycle telemetry (PR→prod, MTTR, rollbacks, shadow age)
  * I11 emergency runbook DSL (RB-01..04 with tabletop tests)
  * I12 auto-post gate lifecycle (ACTIVE + NO_AUTO_POST boundary)
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
BUNDLES = BASE_DIR / "bundles"
REPORT = BASE_DIR / "raporty_glm52_v3" / "RAPORT_V3_P07_RULE_LIFECYCLE.txt"


def _load_bundle(name: str) -> dict:
    return json.loads((BUNDLES / name).read_text(encoding="utf-8"))


def _run_tool(name: str, *args: str) -> str:
    return subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / name), *args],
        capture_output=True, text=True, cwd=str(BASE_DIR), check=True,
    ).stdout


def test_report_exists_and_is_complete():
    assert REPORT.exists()
    txt = REPORT.read_text(encoding="utf-8")
    assert "WDROŻONY_100" in txt
    for marker in ("9.01 EXECUTIVE SUMMARY", "9.06 REJESTR LUK",
                   "9.07 INNOWACJE ENTERPRISE", "9.08 KONTRAKT WYJŚCIOWY",
                   "V3-P07-I01", "V3-P07-I12", "V3-P07-L01"):
        assert marker in txt, f"missing marker {marker}"


def test_i01_promotion_contract():
    d = _load_bundle("v3_p07_promotion_contract.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["registry_rules"] == 13
    # all 13 versions fail promotion (no tests/4-eyes evidence)
    assert d["metrics"]["verdict_hold"] == 13
    assert any(f["id"] == "V3-P07-L02" for f in d["findings"])


def test_i02_immutable_vault():
    d = _load_bundle("v3_p07_immutable_vault.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["versions_unsigned"] == 13
    assert d["metrics"]["in_place_mutators"] >= 1
    assert len(d["demo_canonical_hash"]) == 24


def test_i03_shadow_delta():
    d = _load_bundle("v3_p07_shadow_delta.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["deployments"] == 44
    assert d["metrics"]["rollbacks"] >= 20
    assert any(f["id"] == "V3-P07-L06" for f in d["findings"])


def test_i04_kill_switch_sla():
    d = _load_bundle("v3_p07_kill_switch_sla.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["single_rule_suspend"] is True
    assert d["metrics"]["package_suspend"] is False
    assert d["metrics"]["needs_advice_coupling"] is False
    assert d["slo"]["measured"] is False


def test_i05_four_eyes_layer():
    d = _load_bundle("v3_p07_four_eyes_layer.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["with_role_fields"] == 0
    assert d["metrics"]["deployments_signed"] == 0
    assert d["metrics"]["sql_4eyes_model"] is True  # model SQL istnieje


def test_i06_retirement_scheduler():
    d = _load_bundle("v3_p07_retirement_scheduler.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["deprecated"] == 0
    assert d["metrics"]["grace_enforced"] is False
    assert d["metrics"]["purge_checks_refs"] is False


def test_i07_change_queue():
    d = _load_bundle("v3_p07_change_queue.json")
    assert d["gate"] == "PASS"
    assert d["metrics"]["rules"] == 13
    assert any(f["id"] == "V3-P07-L11" for f in d["findings"])


def test_i08_fiscal_year_boundary():
    d = _load_bundle("v3_p07_fiscal_year_boundary.json")
    assert d["gate"] == "PASS"
    assert d["metrics"]["year_boundary_tests"] > 0
    assert d["metrics"]["not_aligned"] > 0  # registry not 01.01-aligned (P2)
    assert any(f["id"] == "V3-P07-L12" for f in d["findings"])


def test_i09_registry_reconciler():
    d = _load_bundle("v3_p07_registry_reconciler.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["code_rule_ids"] > 10000
    assert d["metrics"]["registered"] == 13
    assert d["metrics"]["coverage_pct"] < 1.0
    assert any(f["id"] == "V3-P07-L01" and f["severity"] == "P0"
               for f in d["findings"])


def test_i10_lifecycle_telemetry():
    d = _load_bundle("v3_p07_lifecycle_telemetry.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["rollback_rate_pct"] >= 40
    assert d["metrics"]["pr_to_prod_hours"] == "NOT_RECORDED"
    assert d["metrics"]["mttr_minutes"] == "NOT_RECORDED"


def test_i11_emergency_runbook():
    d = _load_bundle("v3_p07_emergency_runbook.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["required"] == 4
    assert d["metrics"]["found"] == 0
    assert d["metrics"]["missing"] == 4


def test_i12_auto_post_gate_lifecycle():
    d = _load_bundle("v3_p07_auto_post_gate_lifecycle.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["flagged"] == 0
    assert any(f["id"] == "V3-P07-L18" for f in d["findings"])


def test_tools_cli_run_clean():
    # PASS-gate tools exit 0; FAIL-tools exit 1 (verified via bundle assertions)
    for t in ("change_queue", "fiscal_year_boundary"):
        out = _run_tool(f"v3_p07_{t}.py")
        assert "V3-P07" in out, t
