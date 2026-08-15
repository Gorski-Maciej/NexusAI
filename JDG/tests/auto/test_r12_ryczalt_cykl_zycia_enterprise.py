"""RAPORT_12 — RYCZAŁT / CEIDG / CYKL ŻYCIA — pytest suite.

Prompt 12/25 is implemented as the R12 ryczałt/cykl życia innovations package
(rules/r12_ryczalt_cykl_zycia_innovations_v9.rego) wired into main_jdg.rego
(final_verdict_p37). Tests mirror the R01..R11 conventions:

  R12-INN-01 ryczalt_limit_monitor       — monitor limitu 2 mln EUR (art. 6)
  R12-INN-02 pkwiu_rate_classifier       — klasyfikator PKWiU → stawka (art. 12)
  R12-INN-03 lifecycle_phase_planner     — planner faz cyklu życia JDG
  R12-INN-04 succession_deadline_monitor — monitor terminów sukcesji (u.z.s.)
  R12-INN-05 tax_form_arbitrator         — arbiter formy opodatkowania
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]
R12_REGO = BASE_DIR / "rules" / "r12_ryczalt_cykl_zycia_innovations_v9.rego"
MAIN_REGO = BASE_DIR / "rules" / "main_jdg.rego"
THRESHOLDS_REGO = BASE_DIR / "rules" / "thresholds_jdg.rego"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


_PKG = "jdg.r12_ryczalt_cykl_zycia_innovations"


def _extract_decide_block(src: str, short_id: str) -> str:
    full_id = f"{_PKG}.{short_id}"
    idx = src.find(f'"{full_id}"')
    assert idx != -1, f"rule_id {full_id} not found"
    return src[max(0, idx - 4000): idx + 4000]


# ── Struktura ─────────────────────────────────────────────────────────────────

def test_r12_file_exists_and_has_package():
    src = _read(R12_REGO)
    m = re.search(r"^package\s+([\w.]+)", src, re.M)
    assert m is not None
    assert m.group(1) == "jdg.r12_ryczalt_cykl_zycia_innovations"


def test_r12_braces_balanced():
    src = _read(R12_REGO)
    assert src.count("{") == src.count("}")


def test_r12_rule_ids_unique_and_namespaced():
    src = _read(R12_REGO)
    ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', src)
    assert len(ids) == len(set(ids)), f"duplicate rule_ids: {ids}"
    for rid in ids:
        assert rid.startswith("jdg.r12_ryczalt_cykl_zycia_innovations."), rid
    assert len(ids) == 6


def test_r12_no_hardcoded_thresholds():
    src = _read(R12_REGO)
    assert 'object.get(object.get(data, "jdg", {}), "thresholds", {})' in src
    assert "_th_bl" in src


def test_r12_no_match_default_present():
    src = _read(R12_REGO)
    assert '"rule_id": "jdg.r12_ryczalt_cykl_zycia_innovations.no_match"' in src


def test_r12_legal_basis_present_on_each_innovation():
    src = _read(R12_REGO)
    for rid in [
        "ryczalt_limit_monitor",
        "pkwiu_rate_classifier",
        "lifecycle_phase_planner",
        "succession_deadline_monitor",
        "tax_form_arbitrator",
    ]:
        block = _extract_decide_block(src, rid)
        assert '"_legal_basis"' in block, rid
        assert "valid_from" in block, rid


def test_r12_business_lifecycle_thresholds_block_present():
    src = _read(THRESHOLDS_REGO)
    assert "business_lifecycle := {" in src
    assert '"ryczalt_limit_eur"' in src
    assert '"ryczalt_rate_min"' in src
    assert '"succession_ceidg_days"' in src


def test_r12_main_router_wired_p37():
    src = _read(MAIN_REGO)
    assert "import data.jdg.r12_ryczalt_cykl_zycia_innovations" in src
    assert '"jdg.r12_ryczalt_cykl_zycia_innovations": r12_ryczalt_cykl_zycia_innovations.decide' in src
    assert "final_verdict_p37 = safe_merge(final_verdict_p36" in src
    assert "final_verdict_post_merge = object.union(final_verdict_p42" in src


# ── R12-INN-01: ryczalt_limit_monitor ────────────────────────────────────────

def test_inn01_ryczalt_limit_three_levels():
    src = _read(R12_REGO)
    assert "ryczalt_limit_monitor" in src
    assert "RED" in src and "AMBER" in src and "GREEN" in src
    assert "rl_limit_pct" in src
    assert 'object.get(_th_bl, "ryczalt_limit_eur", 2000000)' in src
    assert "art. 6" in src


# ── R12-INN-02: pkwiu_rate_classifier ────────────────────────────────────────

def test_inn02_pkwiu_classifier():
    src = _read(R12_REGO)
    assert "pkwiu_rate_classifier" in src
    assert "pk_expected_rate" in src
    assert "pk_rate_mismatch" in src
    assert 'object.get(_th_bl, "ryczalt_rate_min", 0.03)' in src
    assert 'object.get(_th_bl, "ryczalt_rate_max", 0.25)' in src
    assert "art. 12" in src


# ── R12-INN-03: lifecycle_phase_planner ──────────────────────────────────────

def test_inn03_lifecycle_planner():
    src = _read(R12_REGO)
    assert "lifecycle_phase_planner" in src
    assert "lc_phase" in src
    assert "lc_missing_steps" in src
    assert "ULGA_NA_START" in src and "PREFERENCYJNY_ZUS" in src


# ── R12-INN-04: succession_deadline_monitor ──────────────────────────────────

def test_inn04_succession_monitor():
    src = _read(R12_REGO)
    assert "succession_deadline_monitor" in src
    assert "sc_unfiled_count" in src
    assert "sc_ceidg_days" in src
    assert 'object.get(_th_bl, "succession_ceidg_days", 14)' in src
    assert "art. 3-15" in src


# ── R12-INN-05: tax_form_arbitrator ──────────────────────────────────────────

def test_inn05_tax_form_arbitrator():
    src = _read(R12_REGO)
    assert "tax_form_arbitrator" in src
    assert "tf_recommended_form" in src
    assert "tf_suspension_recommend" in src
    assert "RYCZALT" in src and "LINIOWY" in src and "SKALA" in src
    assert "art. 22-25" in src


# ── Inwarianty łańcucha (chain-position agnostic) ────────────────────────────

def test_invariants_after_r12():
    src = _read(MAIN_REGO)
    assert "final_verdict_post_merge = object.union(final_verdict_p42" in src
    assert "final_verdict_enforced = object.union(final_verdict_post_merge" in src
    assert "_decision_certificate" in src or "decision_certificate" in src
    assert "_certainty_guard" in src
