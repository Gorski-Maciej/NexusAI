#!/usr/bin/env python3
"""Tests for V3 P04 (INVARIANTY RUNTIME) — the 12 enterprise innovations.

Covers V3-P04-I01..I12 delivered by P04:
  * I01 constitution catalog (42 INV, enforcement states, runtime gaps)
  * I02 zero-latency invariant index (budget < 5% p95, early-exit)
  * I03 violation autopsy (BLOCK → alarm → revert → incident → post-mortem)
  * I04 dual-node consensus (differential eval, quorum ≥ 2/3)
  * I05 invariant mutation testing (mutations must break invariants)
  * I06 graceful degrade map (violation → NEEDS_ADVICE, no silent)
  * I07 constitutional freeze (2×/24h → FROZEN, 4-eyes unblock)
  * I08 invariant provenance (verdict carries executed invariants)
  * I09 legal invariant registry (INV bound to legal_node P01)
  * I10 negative test generator (skeletons for violation tests)
  * I11 runtime cost ledger (per-invariant cost, hotspots)
  * I12 chaos constitution drill (weekly BLOCK+revert drill)
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
BUNDLES = BASE_DIR / "bundles"
REPORT = BASE_DIR / "raporty_glm52_v3" / "RAPORT_V3_P04_INVARIANTY_RUNTIME.txt"


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
                   "V3-P04-I01", "V3-P04-I12", "V3-P04-L01"):
        assert marker in txt, f"missing marker {marker}"


def test_i01_constitution_catalog():
    d = _load_bundle("v3_p04_constitution_catalog.json")
    assert d["catalog_total"] == 42
    # 22 enforced in runtime _failed_invariants.
    assert d["runtime_enforced_count"] == 22
    # Real gap: 7 RUNTIME/BLOCK invariants without runtime enforcement (L01).
    assert d["gap_count"] == 7
    states = {r["id"]: r["execution_state"] for r in d["rows"]}
    assert states["INV-001"] == "ENFORCED"
    assert states["INV-008"] == "NO_IMPL"
    assert states["INV-012"] == "DEAD_ENTRY"
    assert states["INV-029"] == "DEFERRED"
    assert d["gate"]["pass"] is False


def test_i02_zero_latency_index():
    d = _load_bundle("v3_p04_zero_latency_index.json")
    assert d["within_budget"] is True
    assert d["early_exit_ok"] is True
    assert d["early_exit"]["checks_to_first_block"] <= 3
    assert d["cost_reduction_pct"] > 0
    assert d["gate"]["pass"] is True


def test_i03_violation_autopsy():
    d = _load_bundle("v3_p04_violation_autopsy.json")
    assert d["protocol"] == ["BLOCK", "ALARM", "AUTO_REVERT", "INCIDENT", "POST_MORTEM_AUTO"]
    assert len(d["autopsies"]) == 3
    # AUTO_REVERT incidents are P0.
    assert d["autopsies"][0]["severity"] == "P0"
    assert d["autopsies"][0]["responsible_component"] == "reguła VAT"
    assert d["gate"]["pass"] is True


def test_i04_dual_node_consensus():
    d = _load_bundle("v3_p04_dual_node_consensus.json")
    assert d["nodes_total"] == 3
    # node-b diverges (vat_rate 0.08 vs 0.23) → divergence detected.
    assert d["divergence_detected"] is True
    assert d["nodes_matched"] == 2
    assert d["quorum_ok"] is True  # 2/3 ≥ 2/3
    assert d["gate"]["pass"] is True


def test_i05_mutation_testing():
    d = _load_bundle("v3_p04_mutation_testing.json")
    assert d["mutations_total"] >= 20
    assert d["undetected_mutations"] == []
    assert d["coverage_pct"] == 100.0
    assert d["gate"]["pass"] is True


def test_i06_graceful_degrade_map():
    d = _load_bundle("v3_p04_graceful_degrade_map.json")
    assert d["runtime_invariants_count"] == 29
    assert d["classify_consistency"] is True
    assert d["silent_transitions"] == []
    # BLOCK enforcement → NEEDS_ADVICE + CERTAINTY_BLOCKED (fail-closed).
    block_rows = [r for r in d["rows"] if r["enforcement"] == "BLOCK"]
    assert all(r["resulting_class"] == "NEEDS_ADVICE" for r in block_rows)
    assert all(r["auto_post_possible"] is False for r in d["rows"])
    assert d["gate"]["pass"] is True


def test_i07_constitutional_freeze():
    d = _load_bundle("v3_p04_constitutional_freeze.json")
    assert d["policy"]["freeze_threshold"] == 2
    assert d["frozen_domains"] == ["jdg.vat"]
    assert d["domain_states"]["jdg.zus"]["state"] == "WATCH"
    assert d["domain_states"]["jdg.vat"]["auto_post"] == "DISABLED"
    assert d["gate"]["pass"] is True


def test_i08_invariant_provenance():
    d = _load_bundle("v3_p04_invariant_provenance.json")
    assert d["runtime_enforced_count"] == 22
    v = d["verdict_with_invariant_execution"]
    assert v["_invariant_execution"]["catalog_version"] == "v1.0"
    assert v["_invariant_execution"]["failed_count"] == 0
    assert v["_invariant_execution"]["checked_count"] == 23  # 22 + INV-002
    assert d["gate"]["pass"] is True


def test_i09_legal_invariant_registry():
    d = _load_bundle("v3_p04_legal_invariant_registry.json")
    # 7 legal invariants required by law are NOT yet in runtime catalog (L02).
    assert d["missing_legal_count"] == 7
    missing_nodes = {e["legal_node"] for e in d["missing_legal_invariants"]}
    assert "PL/vat/art/86" in missing_nodes
    assert "PL/pit/art/27" in missing_nodes
    assert d["gate"]["pass"] is False


def test_i10_negative_test_generator():
    d = _load_bundle("v3_p04_negative_test_generator.json")
    assert d["generated_count"] == 22
    assert "test_inv_001_block" in {t["test_name"] for t in d["generated_tests"]}
    assert "def test_inv_001_block" in d["skeleton_pytest"]
    assert d["gate"]["pass"] is True


def test_i11_runtime_cost_ledger():
    d = _load_bundle("v3_p04_runtime_cost_ledger.json")
    assert len(d["rows"]) == 42
    assert d["total_cost_model"] > 0
    assert d["runtime_cost_model"] > 0
    assert d["gate"]["pass"] is True


def test_i12_chaos_drill():
    d = _load_bundle("v3_p04_chaos_drill.json")
    assert d["drills_total"] == 4
    assert d["drills_passed"] == 4
    assert d["success_pct"] == 100.0
    assert d["slo_met"] is True
    assert all(x["audit_kept"] for x in d["drills"])
    assert d["gate"]["pass"] is True


def test_tools_cli_run_clean():
    for t in (
        "v3_p04_constitution_catalog.py", "v3_p04_violation_autopsy.py",
        "v3_p04_dual_node_consensus.py", "v3_p04_mutation_testing.py",
        "v3_p04_constitutional_freeze.py", "v3_p04_chaos_drill.py",
    ):
        out = _run_tool(t)
        assert "gate_pass" in out, t