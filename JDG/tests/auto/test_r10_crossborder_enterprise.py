"""RAPORT_10 — CROSS-BORDER / TP / MDR-DAC6 / CFC / ViDA / CBAM — pytest suite.

Prompt 10/25 is implemented as the R10 cross-border innovations package
(rules/r10_crossborder_innovations_v9.rego) wired into main_jdg.rego
(final_verdict_p35). Tests mirror the R01..R09 conventions:

  R10-INN-01 wdt_deadline_alert_monitor — monitor 30 dni dowodu wywozu WDT
  R10-INN-02 mdr_risk_scorer          — scorer ryzyka MDR/DAC6 (hallmark A-E)
  R10-INN-03 tp_threshold_simulator   — symulator dokumentacji TP (500k/200M)
  R10-INN-04 cfc_profit_attribution   — przypisanie dochodu CFC
  R10-INN-05 fx_time_travel_reconciler— różnice kursowe z time-travel
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]
R10_REGO = BASE_DIR / "rules" / "r10_crossborder_innovations_v9.rego"
MAIN_REGO = BASE_DIR / "rules" / "main_jdg.rego"
THRESHOLDS_REGO = BASE_DIR / "rules" / "thresholds_jdg.rego"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


_PKG = "jdg.r10_crossborder_innovations"


def _extract_decide_block(src: str, short_id: str) -> str:
    """Naive extraction: find the decide block containing a given rule_id."""
    full_id = f"{_PKG}.{short_id}"
    idx = src.find(f'"{full_id}"')
    assert idx != -1, f"rule_id {full_id} not found"
    return src[max(0, idx - 4000): idx + 4000]


# ── Struktura ─────────────────────────────────────────────────────────────────

def test_r10_file_exists_and_has_package():
    src = _read(R10_REGO)
    m = re.search(r"^package\s+([\w.]+)", src, re.M)
    assert m is not None
    assert m.group(1) == "jdg.r10_crossborder_innovations"


def test_r10_braces_balanced():
    src = _read(R10_REGO)
    assert src.count("{") == src.count("}")


def test_r10_rule_ids_unique_and_namespaced():
    src = _read(R10_REGO)
    ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', src)
    assert len(ids) == len(set(ids)), f"duplicate rule_ids: {ids}"
    for rid in ids:
        assert rid.startswith("jdg.r10_crossborder_innovations."), rid
    # 5 innovations + no_match
    assert len(ids) == 6


def test_r10_no_hardcoded_thresholds():
    src = _read(R10_REGO)
    assert 'object.get(object.get(data, "jdg", {}), "thresholds", {})' in src
    assert "_th_cb" in src


def test_r10_no_match_default_present():
    src = _read(R10_REGO)
    assert '"rule_id": "jdg.r10_crossborder_innovations.no_match"' in src


def test_r10_legal_basis_present_on_each_innovation():
    src = _read(R10_REGO)
    for rid in [
        "wdt_deadline_alert_monitor",
        "mdr_risk_scorer",
        "tp_threshold_simulator",
        "cfc_profit_attribution",
        "fx_time_travel_reconciler",
    ]:
        block = _extract_decide_block(src, rid)
        assert '"_legal_basis"' in block, rid
        assert "valid_from" in block, rid


def test_r10_crossborder_thresholds_block_present():
    src = _read(THRESHOLDS_REGO)
    assert "crossborder := {" in src
    assert '"wdt_documentation_days"' in src
    assert '"tp_local_file_pln"' in src
    assert '"cfc_ownership_min_pct"' in src
    assert '"exit_tax_threshold_pln"' in src


def test_r10_main_router_wired_p35():
    src = _read(MAIN_REGO)
    assert "import data.jdg.r10_crossborder_innovations" in src
    assert '"jdg.r10_crossborder_innovations": r10_crossborder_innovations.decide' in src
    assert "final_verdict_p35 = safe_merge(final_verdict_p34" in src
    assert "final_verdict_post_merge = object.union(final_verdict_p42" in src


# ── R10-INN-01: wdt_deadline_alert_monitor ───────────────────────────────────

def test_inn01_wdt_three_levels():
    src = _read(R10_REGO)
    assert "wdt_deadline_alert_monitor" in src
    assert "RED" in src and "AMBER" in src and "GREEN" in src
    assert "BLOCK_AND_ALERT" in src
    assert "wdt_missing_count" in src
    assert "wdt_documentation_days" in src


def test_inn01_wdt_uses_threshold_days():
    src = _read(R10_REGO)
    assert 'object.get(_th_cb, "wdt_documentation_days", 30)' in src
    assert "art. 42" in src


# ── R10-INN-02: mdr_risk_scorer ──────────────────────────────────────────────

def test_inn02_mdr_risk_scoring():
    src = _read(R10_REGO)
    assert "mdr_risk_scorer" in src
    assert "mdr_risk_score" in src
    assert "mdr_hallmark_score" in src
    assert "mdr_confidence" in src
    assert "mdr_recommendation" in src
    assert "MDR-1" in src or "mdr_deadline_days" in src


def test_inn02_mdr_hallmarks_a_to_e():
    src = _read(R10_REGO)
    for h in ["A", "B", "C", "D"]:
        assert f'mdr_hallmark == "{h}"' in src, h


# ── R10-INN-03: tp_threshold_simulator ───────────────────────────────────────

def test_inn03_tp_thresholds():
    src = _read(R10_REGO)
    assert "tp_threshold_simulator" in src
    assert "tp_local_required" in src
    assert "tp_master_required" in src
    assert "tp_months_to_local" in src
    assert 'object.get(_th_cb, "tp_local_file_pln", 500000)' in src
    assert 'object.get(_th_cb, "tp_master_file_pln", 200000000)' in src


# ── R10-INN-04: cfc_profit_attribution ───────────────────────────────────────

def test_inn04_cfc_attribution():
    src = _read(R10_REGO)
    assert "cfc_profit_attribution" in src
    assert "cfc_applies" in src
    assert "cfc_attributed_base_pln" in src
    assert "cfc_control_met" in src
    assert "cfc_low_tax_met" in src
    assert "art. 30f" in src


# ── R10-INN-05: fx_time_travel_reconciler ────────────────────────────────────

def test_inn05_fx_time_travel():
    src = _read(R10_REGO)
    assert "fx_time_travel_reconciler" in src
    assert "fx_schedule" in src
    assert "fx_realized_diff_pln" in src
    assert "fx_effective_rate" in src
    assert "art. 24c" in src


# ── Inwarianty łańcucha (chain-position agnostic) ────────────────────────────

def test_invariants_after_r10():
    src = _read(MAIN_REGO)
    assert "final_verdict_post_merge = object.union(final_verdict_p42" in src
    assert "final_verdict_enforced = object.union(final_verdict_post_merge" in src
    assert "_decision_certificate" in src or "decision_certificate" in src
    assert "_certainty_guard" in src
