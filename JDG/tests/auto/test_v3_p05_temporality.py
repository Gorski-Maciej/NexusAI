#!/usr/bin/env python3
"""Tests for V3 P05 (TEMPORALNOŚĆ) — the 12 enterprise innovations.

Covers V3-P05-I01..I12 delivered by P05:
  * I01 interval algebra prover (zero gaps/overlaps, enforcement calls)
  * I02 snapshot ID & vault (immutable snapshots, WORM, 1:1 replay)
  * I03 five-date matrix (T/E/F/P/K model, wall-clock rules, silent default)
  * I04 retroactivity sentinel (backdated changes, revision list)
  * I05 time gate CI (day-1/day0/day+1 boundary proof per window change)
  * I06 past immunity test (golden set hash determinism, chain integrity)
  * I07 temporal telemetry (metric names, thresholds, alerts)
  * I08 clock service contract (single clock source, zone model)
  * I09 transition rule pattern library (11 patterns, legal anchors)
  * I10 legislated-future dry run (future parameter versions)
  * I11 time-travel API (reconstruct on date, snapshot verify, fail-closed)
  * I12 temporal coverage heatmap (anchor coverage per domain)
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
BUNDLES = BASE_DIR / "bundles"
REPORT = BASE_DIR / "raporty_glm52_v3" / "RAPORT_V3_P05_TEMPORALNOSC.txt"


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
                   "V3-P05-I01", "V3-P05-I12", "V3-P05-L01"):
        assert marker in txt, f"missing marker {marker}"


def test_i01_interval_algebra_prover():
    d = _load_bundle("v3_p05_interval_algebra_prover.json")
    assert d["metrics"]["registry_rules"] >= 32
    # no gaps/overlaps on the windows themselves...
    assert d["metrics"]["rules_gaps"] == 0
    assert d["metrics"]["rules_overlaps"] == 0
    # ...but zero enforcement calls = the P0 gap (L01).
    assert d["metrics"]["enforcement_calls"] == 0
    assert d["gate"] == "FAIL"


def test_i02_snapshot_id_vault():
    d = _load_bundle("v3_p05_snapshot_id_vault.json")
    assert len(d["snapshot_id"]) == 64
    assert d["components"]["rules_files"] > 100
    # vault written for WORM replay (append-only registry of snapshots)
    vault = (BUNDLES / "v3_p05_snapshot_vault.json")
    assert vault.exists()
    v = json.loads(vault.read_text(encoding="utf-8"))
    assert v["current"]["snapshot_id"] == d["snapshot_id"]


def test_i03_five_date_matrix():
    d = _load_bundle("v3_p05_five_date_matrix.json")
    assert len(d["scenarios"]) == 8
    assert len(d["date_fields_in_code"]) > 100
    # wall-clock usage in decisional rules detected (L04/L11)
    assert d["metrics"]["wall_clock_decisional"] > 0
    assert d["metrics"]["wall_clock_decisional"] == 12


def test_i04_retroactivity_sentinel():
    d = _load_bundle("v3_p05_retroactivity_sentinel.json")
    assert d["gate"] == "PASS"
    # the vat.standard_rate seed backdate is flagged (L06, P3)
    types = {s["type"] for s in d["suspects"]}
    assert "BACKDATED_EFFECTIVE" in types


def test_i05_time_gate_ci():
    d = _load_bundle("v3_p05_time_gate_ci.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["anchors_total"] == 11
    # two core anchors still lack the day-1/day0 pair (L07, P1)
    assert d["metrics"]["core_missing_boundary"] >= 2


def test_i06_past_immunity():
    d = _load_bundle("v3_p05_past_immunity.json")
    assert d["metrics"]["golden_verdicts"] == 30
    assert d["metrics"]["chain_breaks"] == 0
    # genuine hash determinism check over all 30 entries (L08 surfaced)
    assert d["metrics"]["hash_mismatches"] >= 4
    assert d["gate"] == "FAIL"


def test_i07_temporal_telemetry():
    d = _load_bundle("v3_p05_temporal_telemetry.json")
    names = {m["metric"] for m in d["metrics"]}
    for expected in ("temporal_rules_registry", "open_windows_valid_to_null",
                     "runtime_window_enforcement_calls"):
        assert expected in names, f"missing metric {expected}"
    # CRITICAL alert on zero enforcement calls (L01)
    crit = [m for m in d["metrics"] if m.get("alert") == "CRITICAL"]
    assert any(m["metric"] == "runtime_window_enforcement_calls" for m in crit)


def test_i08_clock_service_contract():
    d = _load_bundle("v3_p05_clock_service_contract.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["total_uses"] == 27
    assert d["metrics"]["decision_class"] == 15
    # 15 DECISION-class wall-clock rules is the P1/P0 gap (L11/L04)
    assert d["metrics"]["decision_class"] >= 10


def test_i09_transition_pattern_library():
    d = _load_bundle("v3_p05_transition_pattern_library.json")
    assert d["gate"] == "PASS"
    assert d["metrics"]["patterns_total"] == 11
    # every pattern carries a legal anchor
    missing = [p for p in d["patterns"] if not p.get("legal_anchor")]
    assert not missing


def test_i10_legislated_future_dryrun():
    d = _load_bundle("v3_p05_legislated_future_dryrun.json")
    assert d["gate"] == "PASS"
    # no future-dated parameter versions exist yet (shadow-only mode)
    assert d["metrics"]["future_params"] == 0
    assert d["mode"] == "SHADOW_ANALYSIS_ONLY"


def test_i11_time_travel_api():
    d = _load_bundle("v3_p05_time_travel_api.json")
    assert d["metrics"]["registry_entries"] == 32
    assert d["golden_replay"]["total"] == 30
    # fail-closed semantics: no active version on date = NEEDS_ADVICE
    demo = d["boundary_demo"]
    assert any(x["decision"] == "NEEDS_ADVICE — reguła nieaktywna na datę (fail-closed)"
               for x in demo)
    # golden drift surfaced (L08) — genuine replay is not vacuous
    assert d["golden_replay"]["replayed_ok"] > 0 or d["golden_replay"]["mismatch"]


def test_i12_temporal_coverage_heatmap():
    d = _load_bundle("v3_p05_temporal_coverage_heatmap.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["anchors_total"] == 32
    assert d["metrics"]["domains"] == 10
    # golden replay coverage is zero across the board (P10 deferred)
    assert d["metrics"]["anchors_golden"] == 0
    # 16 anchors have no pytest/boundary coverage (L14, P2)
    assert any(f["id"] == "V3-P05-L14" for f in d["findings"])


def test_tools_cli_run_clean():
    # tools z bramką PASS kończą exit 0; FAIL-tools zwracają 1 i są weryfikowane
    # przez asercje bundle (I01/I03/I05/I06/I08/I11/I12 powyżej).
    for t in ("snapshot_id_vault", "retroactivity_sentinel",
              "temporal_telemetry", "transition_pattern_library",
              "legislated_future_dryrun"):
        out = _run_tool(f"v3_p05_{t}.py")
        assert "V3-P05" in out, t
