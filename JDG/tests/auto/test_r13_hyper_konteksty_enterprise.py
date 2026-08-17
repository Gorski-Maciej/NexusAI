"""RAPORT_13 — HYPER PLAN45 / KONTEKSTY SPECJALNE — pytest suite.

Prompt 13/25 is implemented as the R13 hyper/konteksty innovations package
(rules/r13_hyper_konteksty_innovations_v9.rego) wired into main_jdg.rego
(final_verdict_p38). Tests mirror the R01..R12 conventions:

  R13-INN-01 cross_domain_conflict_detector — konflikt IP Box vs B+R (art. 30ca)
  R13-INN-02 solidarity_tax_monitor       — danina solidarnościowa (art. 30h)
  R13-INN-03 prokura_deadline_monitor     — monitor wpisu prokury (art. 109 KC)
  R13-INN-04 annual_deadline_calendar     — kalendarz terminów rocznych (art. 45)
  R13-INN-05 qualified_signature_selector — selektor podpisu (eIDAS, art. 126)
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]
R13_REGO = BASE_DIR / "rules" / "r13_hyper_konteksty_innovations_v9.rego"
MAIN_REGO = BASE_DIR / "rules" / "main_jdg.rego"
THRESHOLDS_REGO = BASE_DIR / "rules" / "thresholds_jdg.rego"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


_PKG = "jdg.r13_hyper_konteksty_innovations"


def _extract_decide_block(src: str, short_id: str) -> str:
    full_id = f"{_PKG}.{short_id}"
    idx = src.find(f'"{full_id}"')
    assert idx != -1, f"rule_id {full_id} not found"
    return src[max(0, idx - 4000): idx + 4000]


# ── Struktura ─────────────────────────────────────────────────────────────────

def test_r13_file_exists_and_has_package():
    src = _read(R13_REGO)
    m = re.search(r"^package\s+([\w.]+)", src, re.M)
    assert m is not None
    assert m.group(1) == "jdg.r13_hyper_konteksty_innovations"


def test_r13_braces_balanced():
    src = _read(R13_REGO)
    assert src.count("{") == src.count("}")


def test_r13_rule_ids_unique_and_namespaced():
    src = _read(R13_REGO)
    ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', src)
    assert len(ids) == len(set(ids)), f"duplicate rule_ids: {ids}"
    for rid in ids:
        assert rid.startswith("jdg.r13_hyper_konteksty_innovations."), rid
    assert len(ids) == 6


def test_r13_no_hardcoded_thresholds():
    src = _read(R13_REGO)
    assert 'object.get(object.get(data, "jdg", {}), "thresholds", {})' in src
    assert "_th_hc" in src


def test_r13_no_match_default_present():
    src = _read(R13_REGO)
    assert '"rule_id": "jdg.r13_hyper_konteksty_innovations.no_match"' in src


def test_r13_legal_basis_present_on_each_innovation():
    src = _read(R13_REGO)
    for rid in [
        "cross_domain_conflict_detector",
        "solidarity_tax_monitor",
        "prokura_deadline_monitor",
        "annual_deadline_calendar",
        "qualified_signature_selector",
    ]:
        block = _extract_decide_block(src, rid)
        assert '"_legal_basis"' in block, rid
        assert "valid_from" in block, rid


def test_r13_hyper_contexts_thresholds_block_present():
    src = _read(THRESHOLDS_REGO)
    assert "hyper_contexts := {" in src
    assert '"solidarity_threshold_pln"' in src
    assert '"ip_box_rate"' in src
    assert '"prokura_deadline_days"' in src


def test_r13_main_router_wired_p38():
    src = _read(MAIN_REGO)
    assert "import data.jdg.r13_hyper_konteksty_innovations" in src
    assert '"jdg.r13_hyper_konteksty_innovations": r13_hyper_konteksty_innovations.decide' in src
    assert "final_verdict_p38 = safe_merge(final_verdict_p37" in src
    assert "final_verdict_post_merge = object.union(final_verdict_p45" in src


# ── R13-INN-01: cross_domain_conflict_detector ───────────────────────────────

def test_inn01_conflict_detector():
    src = _read(R13_REGO)
    assert "cross_domain_conflict_detector" in src
    assert "cd_conflict" in src
    assert "cd_overlap_amount" in src
    assert 'object.get(_th_hc, "ip_box_rate", 0.05)' in src
    assert "art. 30ca" in src


# ── R13-INN-02: solidarity_tax_monitor ───────────────────────────────────────

def test_inn02_solidarity_monitor():
    src = _read(R13_REGO)
    assert "solidarity_tax_monitor" in src
    assert "st_solidarity_due_pln" in src
    assert "st_applies" in src
    assert 'object.get(_th_hc, "solidarity_threshold_pln", 1000000)' in src
    assert "art. 30h" in src


# ── R13-INN-03: prokura_deadline_monitor ─────────────────────────────────────

def test_inn03_prokura_monitor():
    src = _read(R13_REGO)
    assert "prokura_deadline_monitor" in src
    assert "pk_unfiled_count" in src
    assert "SAMOISTNA" in src
    assert 'object.get(_th_hc, "prokura_deadline_days", 7)' in src
    assert "art. 109" in src


# ── R13-INN-04: annual_deadline_calendar ─────────────────────────────────────

def test_inn04_deadline_calendar():
    src = _read(R13_REGO)
    assert "annual_deadline_calendar" in src
    assert "dl_unfiled_count" in src
    assert "dl_shifted_count" in src
    assert 'object.get(_th_hc, "pit_annual_deadline", "04-30")' in src
    assert "art. 45" in src


# ── R13-INN-05: qualified_signature_selector ────────────────────────────────

def test_inn05_signature_selector():
    src = _read(R13_REGO)
    assert "qualified_signature_selector" in src
    assert "sg_qualified_required" in src
    assert "PEŁNOMOCNICTWO" in src
    assert "eIDAS" in src
    assert "art. 126" in src


# ── Inwarianty łańcucha (chain-position agnostic) ────────────────────────────

def test_invariants_after_r13():
    src = _read(MAIN_REGO)
    assert "final_verdict_post_merge = object.union(final_verdict_p45" in src
    assert "final_verdict_enforced = object.union(final_verdict_post_merge" in src
    assert "_decision_certificate" in src or "decision_certificate" in src
    assert "_certainty_guard" in src
