"""RAPORT_15 — KSeF / JPK / e-DEKLARACJE / GTU / WIS — pytest suite.

Prompt 15/25 is implemented as the R15 KSeF/JPK innovations package
(rules/r15_ksef_jpk_edeklaracje_innovations_v9.rego) wired into main_jdg.rego
(final_verdict_p42). Tests mirror the R01..R14 conventions:

  R15-INN-01 ksef_firewall_monitor       — firewall KSeF (art. 106na)
  R15-INN-02 jpk_reconciliation_checker  — korelacja VAT-7/JPK_V7M (art. 82/99)
  R15-INN-03 gtu_code_classifier         — klasyfikator GTU (art. 99)
  R15-INN-04 ksef_offline_deadline_monitor — tryb awaryjny (art. 106nb)
  R15-INN-05 wis_request_monitor         — wniosek WIS (art. 42a)
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]
R15_REGO = BASE_DIR / "rules" / "r15_ksef_jpk_edeklaracje_innovations_v9.rego"
MAIN_REGO = BASE_DIR / "rules" / "main_jdg.rego"
THRESHOLDS_REGO = BASE_DIR / "rules" / "thresholds_jdg.rego"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


_PKG = "jdg.r15_ksef_jpk_edeklaracje_innovations"


def _extract_decide_block(src: str, short_id: str) -> str:
    full_id = f"{_PKG}.{short_id}"
    idx = src.find(f'"{full_id}"')
    assert idx != -1, f"rule_id {full_id} not found"
    return src[max(0, idx - 4000): idx + 4000]


# ── Struktura ─────────────────────────────────────────────────────────────────

def test_r15_file_exists_and_has_package():
    src = _read(R15_REGO)
    m = re.search(r"^package\s+([\w.]+)", src, re.M)
    assert m is not None
    assert m.group(1) == "jdg.r15_ksef_jpk_edeklaracje_innovations"


def test_r15_braces_balanced():
    src = _read(R15_REGO)
    assert src.count("{") == src.count("}")


def test_r15_rule_ids_unique_and_namespaced():
    src = _read(R15_REGO)
    ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', src)
    assert len(ids) == len(set(ids)), f"duplicate rule_ids: {ids}"
    for rid in ids:
        assert rid.startswith("jdg.r15_ksef_jpk_edeklaracje_innovations."), rid
    assert len(ids) == 6


def test_r15_no_hardcoded_thresholds():
    src = _read(R15_REGO)
    assert 'object.get(object.get(data, "jdg", {}), "thresholds", {})' in src
    assert "_th_kj" in src


def test_r15_no_match_default_present():
    src = _read(R15_REGO)
    assert '"rule_id": "jdg.r15_ksef_jpk_edeklaracje_innovations.no_match"' in src


def test_r15_legal_basis_present_on_each_innovation():
    src = _read(R15_REGO)
    for rid in [
        "ksef_firewall_monitor",
        "jpk_reconciliation_checker",
        "gtu_code_classifier",
        "ksef_offline_deadline_monitor",
        "wis_request_monitor",
    ]:
        block = _extract_decide_block(src, rid)
        assert '"_legal_basis"' in block, rid
        assert "valid_from" in block, rid


def test_r15_ksef_jpk_thresholds_block_present():
    src = _read(THRESHOLDS_REGO)
    assert "ksef_jpk := {" in src
    assert '"ksef_sanction_max_pln"' in src
    assert '"ksef_offline_grace_days"' in src
    assert '"wis_response_days"' in src


def test_r15_main_router_wired_p40():
    src = _read(MAIN_REGO)
    assert "import data.jdg.r15_ksef_jpk_edeklaracje_innovations" in src
    assert '"jdg.r15_ksef_jpk_edeklaracje_innovations": r15_ksef_jpk_edeklaracje_innovations.decide' in src
    assert "final_verdict_p42 = safe_merge(final_verdict_p41" in src
    assert "final_verdict_post_merge = object.union(final_verdict_p42" in src


# ── R15-INN-01: ksef_firewall_monitor ────────────────────────────────────────

def test_inn01_ksef_firewall():
    src = _read(R15_REGO)
    assert "ksef_firewall_monitor" in src
    assert "kf_nip_valid" in src
    assert "kf_blocked" in src
    assert 'object.get(_th_kj, "ksef_sanction_max_pln", 500000)' in src
    assert "art. 106na" in src


# ── R15-INN-02: jpk_reconciliation_checker ───────────────────────────────────

def test_inn02_jpk_reconciliation():
    src = _read(R15_REGO)
    assert "jpk_reconciliation_checker" in src
    assert "jr_mismatch" in src
    assert "jr_max_delta_pln" in src
    assert "art. 82" in src
    assert "art. 99" in src


# ── R15-INN-03: gtu_code_classifier ──────────────────────────────────────────

def test_inn03_gtu_classifier():
    src = _read(R15_REGO)
    assert "gtu_code_classifier" in src
    assert "gt_expected_code" in src
    assert "gt_mismatch" in src
    assert "GTU_01" in src and "GTU_02" in src


# ── R15-INN-04: ksef_offline_deadline_monitor ────────────────────────────────

def test_inn04_ksef_offline():
    src = _read(R15_REGO)
    assert "ksef_offline_deadline_monitor" in src
    assert "ko_unfiled_count" in src
    assert "ko_grace_days" in src
    assert 'object.get(_th_kj, "ksef_offline_grace_days", 7)' in src
    assert "art. 106nb" in src


# ── R15-INN-05: wis_request_monitor ──────────────────────────────────────────

def test_inn05_wis_request():
    src = _read(R15_REGO)
    assert "wis_request_monitor" in src
    assert "wr_incomplete" in src
    assert "wr_response_days" in src
    assert "art. 42a" in src


# ── Inwarianty łańcucha (chain-position agnostic) ────────────────────────────

def test_invariants_after_r15():
    src = _read(MAIN_REGO)
    assert "final_verdict_post_merge = object.union(final_verdict_p42" in src
    assert "final_verdict_enforced = object.union(final_verdict_post_merge" in src
    assert "_decision_certificate" in src or "decision_certificate" in src
    assert "_certainty_guard" in src
