"""RAPORT_14 — RODO / AML-CBDD / BDO / ŚRODOWISKO — pytest suite.

Prompt 14/25 is implemented as the R14 RODO/AML/BDO innovations package
(rules/r14_rodo_aml_bdo_innovations_v9.rego) wired into main_jdg.rego
(final_verdict_p39). Tests mirror the R01..R13 conventions:

  R14-INN-01 rodo_register_monitor       — rejestr czynności (art. 30 RODO)
  R14-INN-02 aml_transaction_risk_scorer — scoring transakcji AML (art. 34)
  R14-INN-03 rodo_sanction_calculator    — sankcje RODO (art. 83)
  R14-INN-04 str_gijf_deadline_monitor   — monitor STR/GIIF (art. 74-80)
  R14-INN-05 bdo_obligation_monitor      — monitor obowiązków BDO (art. 49-53)
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]
R14_REGO = BASE_DIR / "rules" / "r14_rodo_aml_bdo_innovations_v9.rego"
MAIN_REGO = BASE_DIR / "rules" / "main_jdg.rego"
THRESHOLDS_REGO = BASE_DIR / "rules" / "thresholds_jdg.rego"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


_PKG = "jdg.r14_rodo_aml_bdo_innovations"


def _extract_decide_block(src: str, short_id: str) -> str:
    full_id = f"{_PKG}.{short_id}"
    idx = src.find(f'"{full_id}"')
    assert idx != -1, f"rule_id {full_id} not found"
    return src[max(0, idx - 4000): idx + 4000]


# ── Struktura ─────────────────────────────────────────────────────────────────

def test_r14_file_exists_and_has_package():
    src = _read(R14_REGO)
    m = re.search(r"^package\s+([\w.]+)", src, re.M)
    assert m is not None
    assert m.group(1) == "jdg.r14_rodo_aml_bdo_innovations"


def test_r14_braces_balanced():
    src = _read(R14_REGO)
    assert src.count("{") == src.count("}")


def test_r14_rule_ids_unique_and_namespaced():
    src = _read(R14_REGO)
    ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', src)
    assert len(ids) == len(set(ids)), f"duplicate rule_ids: {ids}"
    for rid in ids:
        assert rid.startswith("jdg.r14_rodo_aml_bdo_innovations."), rid
    assert len(ids) == 6


def test_r14_no_hardcoded_thresholds():
    src = _read(R14_REGO)
    assert 'object.get(object.get(data, "jdg", {}), "thresholds", {})' in src
    assert "_th_rab" in src


def test_r14_no_match_default_present():
    src = _read(R14_REGO)
    assert '"rule_id": "jdg.r14_rodo_aml_bdo_innovations.no_match"' in src


def test_r14_legal_basis_present_on_each_innovation():
    src = _read(R14_REGO)
    for rid in [
        "rodo_register_monitor",
        "aml_transaction_risk_scorer",
        "rodo_sanction_calculator",
        "str_gijf_deadline_monitor",
        "bdo_obligation_monitor",
    ]:
        block = _extract_decide_block(src, rid)
        assert '"_legal_basis"' in block, rid
        assert "valid_from" in block, rid


def test_r14_rodo_aml_bdo_thresholds_block_present():
    src = _read(THRESHOLDS_REGO)
    assert "rodo_aml_bdo := {" in src
    assert '"rodo_sanction_max_eur"' in src
    assert '"aml_threshold_eur"' in src
    assert '"bdo_registration_days"' in src


def test_r14_main_router_wired_p39():
    src = _read(MAIN_REGO)
    assert "import data.jdg.r14_rodo_aml_bdo_innovations" in src
    assert '"jdg.r14_rodo_aml_bdo_innovations": r14_rodo_aml_bdo_innovations.decide' in src
    assert "final_verdict_p39 = safe_merge(final_verdict_p38" in src
    assert "final_verdict_post_merge = object.union(final_verdict_p39" in src


# ── R14-INN-01: rodo_register_monitor ────────────────────────────────────────

def test_inn01_rodo_register():
    src = _read(R14_REGO)
    assert "rodo_register_monitor" in src
    assert "rg_incomplete" in src
    assert "rg_data_categories_count" in src
    assert "art. 30" in src


# ── R14-INN-02: aml_transaction_risk_scorer ──────────────────────────────────

def test_inn02_aml_scorer():
    src = _read(R14_REGO)
    assert "aml_transaction_risk_scorer" in src
    assert "at_risk_score" in src
    assert "at_high_risk" in src
    assert 'object.get(_th_rab, "aml_threshold_eur", 15000)' in src
    assert "art. 34" in src


# ── R14-INN-03: rodo_sanction_calculator ─────────────────────────────────────

def test_inn03_rodo_sanction():
    src = _read(R14_REGO)
    assert "rodo_sanction_calculator" in src
    assert "rb_upper_tier" in src
    assert "rb_max_sanction_eur" in src
    assert 'object.get(_th_rab, "rodo_sanction_max_eur", 20000000)' in src
    assert "art. 83" in src


# ── R14-INN-04: str_gijf_deadline_monitor ────────────────────────────────────

def test_inn04_str_gijf():
    src = _read(R14_REGO)
    assert "str_gijf_deadline_monitor" in src
    assert "sm_unfiled_count" in src
    assert "sm_str_deadline_days" in src
    assert "art. 74" in src


# ── R14-INN-05: bdo_obligation_monitor ───────────────────────────────────────

def test_inn05_bdo_monitor():
    src = _read(R14_REGO)
    assert "bdo_obligation_monitor" in src
    assert "bd_unfiled_count" in src
    assert "bd_kpo_electronic" in src
    assert "art. 49" in src


# ── Inwarianty łańcucha (chain-position agnostic) ────────────────────────────

def test_invariants_after_r14():
    src = _read(MAIN_REGO)
    assert "final_verdict_post_merge = object.union(final_verdict_p39" in src
    assert "final_verdict_enforced = object.union(final_verdict_post_merge" in src
    assert "_decision_certificate" in src or "decision_certificate" in src
    assert "_certainty_guard" in src
