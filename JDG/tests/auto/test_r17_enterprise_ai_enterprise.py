"""RAPORT_17 — ENTERPRISE AI (inteligencja systemu) — pytest suite.

Prompt 17/25 is implemented as the R17 Enterprise AI innovations package
(rules/r17_enterprise_ai_innovations_v9.rego) wired into main_jdg.rego
(final_verdict_p42). Tests mirror the R01..R16 conventions:

  R17-INN-01 adaptive_trust_monitor          — Trust Score → tryb decyzyjny
  R17-INN-02 neural_mesh_confidence_monitor  — pewność synapse + konflikty
  R17-INN-03 cashflow_forecast_monitor       — prognoza 90 dni + płynność
  R17-INN-04 banking_psd2_monitor            — split payment MPP (art. 108a)
  R17-INN-05 legislative_change_monitor      — vacatio legis (art. 4 OrdPU)
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]
R17_REGO = BASE_DIR / "rules" / "r17_enterprise_ai_innovations_v9.rego"
MAIN_REGO = BASE_DIR / "rules" / "main_jdg.rego"
THRESHOLDS_REGO = BASE_DIR / "rules" / "thresholds_jdg.rego"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


_PKG = "jdg.r17_enterprise_ai_innovations"


def _extract_decide_block(src: str, short_id: str) -> str:
    full_id = f"{_PKG}.{short_id}"
    idx = src.find(f'"{full_id}"')
    assert idx != -1, f"rule_id {full_id} not found"
    return src[max(0, idx - 4000): idx + 4000]


# ── Struktura ─────────────────────────────────────────────────────────────────

def test_r17_file_exists_and_has_package():
    src = _read(R17_REGO)
    m = re.search(r"^package\s+([\w.]+)", src, re.M)
    assert m is not None
    assert m.group(1) == "jdg.r17_enterprise_ai_innovations"


def test_r17_braces_balanced():
    src = _read(R17_REGO)
    assert src.count("{") == src.count("}")


def test_r17_rule_ids_unique_and_namespaced():
    src = _read(R17_REGO)
    ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', src)
    assert len(ids) == len(set(ids)), f"duplicate rule_ids: {ids}"
    for rid in ids:
        assert rid.startswith("jdg.r17_enterprise_ai_innovations."), rid
    assert len(ids) == 6


def test_r17_no_hardcoded_thresholds():
    src = _read(R17_REGO)
    assert 'object.get(object.get(data, "jdg", {}), "thresholds", {})' in src
    assert "_th_ai" in src


def test_r17_no_match_default_present():
    src = _read(R17_REGO)
    assert '"rule_id": "jdg.r17_enterprise_ai_innovations.no_match"' in src


def test_r17_legal_basis_present_on_each_innovation():
    src = _read(R17_REGO)
    for rid in [
        "adaptive_trust_monitor",
        "neural_mesh_confidence_monitor",
        "cashflow_forecast_monitor",
        "banking_psd2_monitor",
        "legislative_change_monitor",
    ]:
        block = _extract_decide_block(src, rid)
        assert '"_legal_basis"' in block, rid
        assert "valid_from" in block, rid


def test_r17_enterprise_ai_thresholds_block_present():
    src = _read(THRESHOLDS_REGO)
    assert "enterprise_ai := {" in src
    assert '"trust_auto_post_min"' in src
    assert '"mesh_confidence_min"' in src
    assert '"split_payment_threshold_pln"' in src


def test_r17_main_router_wired_p42():
    src = _read(MAIN_REGO)
    assert "import data.jdg.r17_enterprise_ai_innovations" in src
    assert '"jdg.r17_enterprise_ai_innovations": r17_enterprise_ai_innovations.decide' in src
    assert "final_verdict_p42 = safe_merge(final_verdict_p41" in src
    assert "final_verdict_post_merge = object.union(final_verdict_p51" in src


# ── R17-INN-01: adaptive_trust_monitor ───────────────────────────────────────

def test_inn01_adaptive_trust():
    src = _read(R17_REGO)
    assert "adaptive_trust_monitor" in src
    assert "at_mode" in src
    assert "at_trust_score" in src
    assert 'object.get(_th_ai, "trust_auto_post_min", 0.92)' in src
    assert "AUTO_POST" in src


# ── R17-INN-02: neural_mesh_confidence_monitor ───────────────────────────────

def test_inn02_neural_mesh():
    src = _read(R17_REGO)
    assert "neural_mesh_confidence_monitor" in src
    assert "nm_effective" in src
    assert "nm_reliable" in src
    assert 'object.get(_th_ai, "mesh_confidence_min", 0.5)' in src


# ── R17-INN-03: cashflow_forecast_monitor ────────────────────────────────────

def test_inn03_cashflow():
    src = _read(R17_REGO)
    assert "cashflow_forecast_monitor" in src
    assert "cf_gap_alert" in src
    assert "cf_buffer_ok" in src
    assert 'object.get(_th_ai, "forecast_horizon_days", 90)' in src
    assert "art. 44" in src


# ── R17-INN-04: banking_psd2_monitor ─────────────────────────────────────────

def test_inn04_banking():
    src = _read(R17_REGO)
    assert "banking_psd2_monitor" in src
    assert "bk_split_required" in src
    assert "bk_iban_valid" in src
    assert 'object.get(_th_ai, "split_payment_threshold_pln", 15000)' in src
    assert "art. 108a" in src


# ── R17-INN-05: legislative_change_monitor ───────────────────────────────────

def test_inn05_legislative():
    src = _read(R17_REGO)
    assert "legislative_change_monitor" in src
    assert "lg_high_impact" in src
    assert "lg_vacatio_compliant" in src
    assert 'object.get(_th_ai, "vacatio_legis_days", 14)' in src
    assert "art. 4" in src


# ── Inwarianty łańcucha (chain-position agnostic) ────────────────────────────

def test_invariants_after_r17():
    src = _read(MAIN_REGO)
    assert "final_verdict_post_merge = object.union(final_verdict_p51" in src
    assert "final_verdict_enforced = object.union(final_verdict_post_merge" in src
    assert "_decision_certificate" in src or "decision_certificate" in src
    assert "_certainty_guard" in src
