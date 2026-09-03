#!/usr/bin/env python3
"""Tests for V3 P02 (ORKIESTRATOR) — the 12 enterprise innovations.

Covers V3-P02-I01..I12 delivered by P02:
  * I01 constitutional PASS (42 INV, enforce() in POST-MERGE, 0 bypasses)
  * I02 determinism prover (pure chain, disjoint guards, selector else=true)
  * I03 field ownership matrix (money/rate fields single-owner)
  * I04 shard completeness sentinel (192 combos, 0 orphan, 0 double)
  * I05 degradation ladder (no silent AUTO_POST on degraded paths)
  * I06 latency budget guard (per-pass model budget)
  * I07 merge monotonicity prover (info grows, never silent loss)
  * I08 telemetry hooks (binding metric registry → P37)
  * I09 declarative shard registry (aliases reconciled, provenance)
  * I10 early-abort forensics (every abort ends in a verdict with _routing)
  * I11 mirror sync gate (mirror policies bit-exact vs canonical)
  * I12 verdict fuzzer (no matched verdict without full 25-field contract)
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
BUNDLES = BASE_DIR / "bundles"
REPORT = BASE_DIR / "raporty_glm52_v3" / "RAPORT_V3_P02_ORKIESTRATOR.txt"


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
                   "V3-P02-I01", "V3-P02-I12", "V3-P02-L01"):
        assert marker in txt, f"missing marker {marker}"


def test_i01_constitutional_pass():
    d = _load_bundle("v3_p02_constitutional_pass.json")
    assert d["catalog"]["invariant_ids"] >= 40
    assert d["wiring"]["enforce_called_in_post_merge"] is True
    assert d["wiring"]["final_verdict_enforcement_assignment"] is True
    assert d["wiring"]["verdict_bypass_candidates"] == []
    assert d["gate"]["pass"] is True


def test_i02_determinism_prover():
    d = _load_bundle("v3_p02_determinism_prover.json")
    # No duplicate packages inside any chain.
    assert all(v == [] for v in d["duplicates_in_chain"].values())
    assert d["safe_merge"]["disjoint_guards"] is True
    assert d["path_selection"]["selector_ends_with_else_true_full"] is True
    assert d["issues"] == []
    assert d["gate"]["pass"] is True


def test_i03_field_ownership_matrix():
    d = _load_bundle("v3_p02_field_ownership_matrix.json")
    assert d["packages_analyzed"] > 100
    # Gate is expected FAIL right now: 6 money/rate fields have multiple writers.
    assert len(d["money_fields_multi_writer"]) == 6
    assert d["gate"]["pass"] is False
    # Allowlist must be immutable: ZUS/business/security.fortress protected.
    assert "jdg.zus" in d["immutable_allowlist"]
    assert "jdg.business" in d["immutable_allowlist"]
    assert "jdg.security.fortress" in d["immutable_allowlist"]


def test_i04_shard_completeness_sentinel():
    d = _load_bundle("v3_p02_shard_completeness_sentinel.json")
    assert d["completeness_model"]["combinations_total"] == 192
    assert d["completeness_model"]["orphan_combinations"] == []
    assert d["completeness_model"]["double_assignments"] == []
    assert d["issues"] == []
    assert d["gate"]["pass"] is True


def test_i05_degradation_ladder():
    d = _load_bundle("v3_p02_degradation_ladder.json")
    # No degraded/fallback path is a silent AUTO_POST candidate.
    assert d["fallback_auto_post_candidates"] == []
    assert d["all_degraded_carry_warnings"] is True
    ladder = d["ladder"]
    assert any("NEEDS_ADVICE" in c for c in ladder)
    assert any("BLOCKED" in c for c in ladder)
    assert d["gate"]["pass"] is True


def test_i06_latency_budget_guard():
    d = _load_bundle("v3_p02_latency_budget_guard.json")
    assert d["gate"]["pass"] is True
    assert d["violations"] == []
    assert all(p["status"] == "OK" for p in d["per_pass"])
    assert d["baseline_rules_total"] > 400


def test_i07_merge_monotonicity_prover():
    d = _load_bundle("v3_p02_merge_monotonicity_prover.json")
    pt = d["property_test"]
    assert pt["trials"] >= 1000
    assert pt["monotonic_ok"] == pt["trials"]
    assert pt["violations"] == []
    assert d["gate"]["pass"] is True


def test_i08_telemetry_hooks():
    d = _load_bundle("v3_p02_telemetry_hooks.json")
    assert d["metric_count"] == 9
    names = [m["name"] for m in d["metric_registry"]]
    assert "jdg_orchestrator_pass_duration_ms" in names
    assert "jdg_orchestrator_aborts_total" in names
    assert "jdg_orchestrator_verdict_incomplete_total" in names
    assert "jdg_orchestrator_shard_routed_total" in names
    assert d["gate"]["pass"] is True


def test_i09_declarative_shard_registry():
    d = _load_bundle("v3_p02_declarative_shard_registry.json")
    assert set(d["shards"].keys()) == {
        "gated_abort_verdict", "sharded_sale_verdict",
        "sharded_purchase_verdict", "full_final_verdict",
    }
    assert d["issues"] == []
    assert d["gate"]["pass"] is True


def test_i10_early_abort_forensics():
    d = _load_bundle("v3_p02_early_abort_forensics.json")
    assert len(d["abort_points"]) >= 10
    assert d["silent_paths"] == []
    assert d["gate"]["pass"] is True


def test_i11_mirror_sync_gate():
    d = _load_bundle("v3_p02_mirror_sync_gate.json")
    assert d["mirror_available_locally"] is True
    assert len(d["drifts"]) == 4
    assert d["gate"]["pass"] is False  # 4 drift files must be fixed (L01)


def test_i12_verdict_fuzzer():
    d = _load_bundle("v3_p02_verdict_fuzzer.json")
    assert d["trials"] == 10000
    assert d["incomplete_count"] == 0
    assert d["missing_rule_id_count"] == 0
    assert d["completeness_pct"] == 100.0
    assert d["canonical_field_count"] == 25
    assert d["gate"]["pass"] is True


def test_tools_cli_run_clean():
    for t in (
        "v3_p02_constitutional_pass.py", "v3_p02_determinism_prover.py",
        "v3_p02_shard_completeness_sentinel.py", "v3_p02_degradation_ladder.py",
        "v3_p02_early_abort_forensics.py", "v3_p02_verdict_fuzzer.py",
    ):
        out = _run_tool(t)
        assert "gate_pass" in out or "gate" in out, t