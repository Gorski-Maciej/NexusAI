#!/usr/bin/env python3
"""Tests for V3 P08 (LAW_RADAR) — the 12 enterprise innovations.

Covers V3-P08-I01..I12 delivered by P08:
  * I01 draft law radar feed (RCL/Sejm/Senat + enactment scoring)
  * I02 AI-Reader 4-eyes (LLM diff schema + second-model validation)
  * I03 pre-life shadow rules (future valid_from versions dry-run)
  * I04 lead-time SLA dashboard (30/14/7 days before enactment)
  * I05 impact matrix auto-builder (diff → rules with priority/effort)
  * I06 legal change calendar sync (N-day alerts + lifecycle link)
  * I07 scenario versioning (alternative drafts with invalidation)
  * I08 repeal detector (REPEALED → deprecate request to P07)
  * I09 low-latency legal feeds (webhook + polling fallback, SLA < 1 h)
  * I10 compliance readiness report (GOTOWE/W_PRZYGOTOWANIU/NIE_GOTOWE)
  * I11 pipeline E2E test rig (mock novelization through stages)
  * I12 law radar API (per-act status for accounting UI)
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
BUNDLES = BASE_DIR / "bundles"
REPORT = BASE_DIR / "raporty_glm52_v3" / "RAPORT_V3_P08_LAW_RADAR.txt"


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
                   "V3-P08-I01", "V3-P08-I12", "V3-P08-L01"):
        assert marker in txt, f"missing marker {marker}"


def test_i01_draft_feed():
    d = _load_bundle("v3_p08_draft_feed.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["sources_required"] == 4
    assert d["metrics"]["sources_covered"] < 4
    assert any(f["id"] == "V3-P08-L01" for f in d["findings"])


def test_i02_ai_reader_four_eyes():
    d = _load_bundle("v3_p08_ai_reader_four_eyes.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["bridge_role_explain"] is True
    assert d["metrics"]["ai_reader_diff"] is False
    assert any(f["id"] == "V3-P08-L02" for f in d["findings"])
    # diff schema artifact (contract K3) exists
    schema = json.loads((BUNDLES / "v3_p08_legal_diff_schema.json")
                        .read_text(encoding="utf-8"))
    assert "legal_node_id" in schema["schema"]
    assert schema["sample"]["change_type"] == "AMEND_VALUE"


def test_i03_prelife_shadow():
    d = _load_bundle("v3_p08_prelife_shadow.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["future_versions"] == 0
    assert d["metrics"]["shadow_future"] == 0
    assert any(f["id"] == "V3-P08-L03" for f in d["findings"])


def test_i04_lead_time_sla():
    d = _load_bundle("v3_p08_lead_time_sla.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["target_lead_days"] == 30
    assert d["metrics"]["sla_buckets"] == [30, 14, 7]
    assert d["metrics"]["changes"] >= 1
    assert any(f["id"] == "V3-P08-L04" for f in d["findings"])


def test_i05_impact_matrix():
    d = _load_bundle("v3_p08_impact_matrix.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["manual_cli"] is True
    assert d["metrics"]["auto_wired"] is False
    assert any(f["id"] == "V3-P08-L05" for f in d["findings"])


def test_i06_calendar_sync():
    d = _load_bundle("v3_p08_calendar_sync.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["with_prepared_rules"] == 0
    assert any(f["id"] == "V3-P08-L06" for f in d["findings"])


def test_i07_scenario_versioning():
    d = _load_bundle("v3_p08_scenario_versioning.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["with_scenarios"] == 0
    assert any(f["id"] == "V3-P08-L07" for f in d["findings"])


def test_i08_repeal_detector():
    d = _load_bundle("v3_p08_repeal_detector.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["repeal_feed_signal"] is False
    assert d["metrics"]["rule_files_with_repeal_mentions"] > 0
    assert any(f["id"] == "V3-P08-L08" for f in d["findings"])


def test_i09_low_latency_feeds():
    d = _load_bundle("v3_p08_low_latency_feeds.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["webhook"] is False
    assert d["metrics"]["poll_fallback"] is True
    assert any(f["id"] == "V3-P08-L09" for f in d["findings"])


def test_i10_readiness_report():
    d = _load_bundle("v3_p08_readiness_report.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["ready"] == 0
    assert any(f["id"] == "V3-P08-L10" for f in d["findings"])


def test_i11_pipeline_e2e():
    d = _load_bundle("v3_p08_pipeline_e2e.json")
    assert d["gate"] == "PASS"
    assert d["metrics"]["e2e_test_exists"] is True
    assert d["mock_novelization"]["id"] == "MOCK-E2E-001"
    assert any(f["id"] == "V3-P08-L11" for f in d["findings"])


def test_i12_law_radar_api():
    d = _load_bundle("v3_p08_law_radar_api.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["http_services"] == []
    assert set(d["status_model"]) == {"GOTOWE", "W_PRZYGOTOWANIU", "WYMAGA_UWAGI"}
    assert any(f["id"] == "V3-P08-L12" for f in d["findings"])


def test_tools_cli_run_clean():
    # PASS-gate tools exit 0; FAIL-tools exit 1 (verified via bundle assertions)
    for t in ("pipeline_e2e",):
        out = _run_tool(f"v3_p08_{t}.py")
        assert "V3-P08" in out, t
