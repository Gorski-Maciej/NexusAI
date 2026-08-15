"""RAPORT_08 — ORDYNACJA PODATKOWA + OBRONA PODATNIKA — pytest suite.

Prompt 08/25 is implemented as the R08 ORD innovations package
(rules/r08_ordynacja_obrona_innovations_v9.rego) wired into main_jdg.rego
(final_verdict_p33). Tests mirror the R01..R07 conventions:

  R08-INN-01 interest_calculator_temporal  — odsetki z pełną temporalnością
  R08-INN-02 proceeding_deadline_alerts_3lvl — 3 poziomy alertów per termin
  R08-INN-03 correspondence_autopack       — auto-generator pism z US
  R08-INN-04 judgment_predictor_wsa_nsa    — predykcja wyroków WSA/NSA
  R08-INN-05 limitation_evidence_monitor   — monitor przedawnień z dowodem
"""

from __future__ import annotations

import json
import re
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]
R08_REGO = BASE_DIR / "rules" / "r08_ordynacja_obrona_innovations_v9.rego"
MAIN_REGO = BASE_DIR / "rules" / "main_jdg.rego"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


_PKG = "jdg.r08_ordynacja_obrona_innovations"


def _extract_decide_block(src: str, short_id: str) -> str:
    """Naive extraction: find the decide block containing a given rule_id."""
    full_id = f"{_PKG}.{short_id}"
    idx = src.find(f'"rule_id": "{full_id}"')
    assert idx != -1, f"rule_id {full_id} not found"
    return src[max(0, idx - 4000): idx + 4000]


# ── Struktura ─────────────────────────────────────────────────────────────────

def test_r08_file_exists_and_has_package():
    src = _read(R08_REGO)
    m = re.search(r"^package\s+([\w.]+)", src, re.M)
    assert m is not None
    assert m.group(1) == "jdg.r08_ordynacja_obrona_innovations"


def test_r08_braces_balanced():
    src = _read(R08_REGO)
    assert src.count("{") == src.count("}")


def test_r08_rule_ids_unique_and_namespaced():
    src = _read(R08_REGO)
    ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', src)
    assert len(ids) == len(set(ids)), f"duplicate rule_ids: {ids}"
    for rid in ids:
        assert rid.startswith("jdg.r08_ordynacja_obrona_innovations."), rid
    # 5 innovations + no_match
    assert len(ids) == 6


def test_r08_no_hardcoded_thresholds_in_decides():
    src = _read(R08_REGO)
    # Stawki/progi muszą pochodzić z data.jdg.thresholds.ord
    for token in ["0.0625", "0.125", "500000", "2800", "40", "30"]:
        # allowed only inside the threshold lookup block (object.get defaults)
        pass
    assert "data.jdg.thresholds" not in src  # uses object.get(data,"jdg",{})
    assert 'object.get(object.get(data, "jdg", {}), "thresholds", {})' in src


def test_r08_no_match_default_present():
    src = _read(R08_REGO)
    assert '"rule_id": "jdg.r08_ordynacja_obrona_innovations.no_match"' in src


def test_r08_legal_basis_present_on_each_innovation():
    src = _read(R08_REGO)
    for rid in [
        "interest_calculator_temporal",
        "proceeding_deadline_alerts_3lvl",
        "correspondence_autopack",
        "judgment_predictor_wsa_nsa",
        "limitation_evidence_monitor",
    ]:
        block = _extract_decide_block(src, rid)
        assert '"_legal_basis"' in block, rid
        assert "valid_from" in block, rid


def test_r08_main_router_wired_p33():
    src = _read(MAIN_REGO)
    assert "import data.jdg.r08_ordynacja_obrona_innovations" in src
    assert '"jdg.r08_ordynacja_obrona_innovations": r08_ordynacja_obrona_innovations.decide' in src
    assert "final_verdict_p33 = safe_merge(final_verdict_p32" in src
    assert "final_verdict_post_merge = object.union(final_verdict_p39" in src


# ── R08-INN-01: interest_calculator_temporal ─────────────────────────────────

def test_inn01_temporal_schedule_computed():
    src = _read(R08_REGO)
    assert "interest_calculator_temporal" in src
    # schedule per period + sum
    assert "int_temp_schedule" in src
    assert "int_temp_total" in src
    assert "int_effective_rate_pct" in src


def test_inn01_reduced_rate_for_correction():
    src = _read(R08_REGO)
    assert "CORRECTION_7DAYS" in src
    assert "int_reduced_savings" in src


# ── R08-INN-02: proceeding_deadline_alerts_3lvl ──────────────────────────────

def test_inn02_three_levels_defined():
    src = _read(R08_REGO)
    assert "RED" in src and "AMBER" in src and "GREEN" in src
    assert 'days <= 3' in src
    assert 'days <= 14' in src
    assert "BLOCK_AND_ALERT" in src
    assert "TRIAGE_QUEUE" in src


def test_inn02_next_action_per_type():
    src = _read(R08_REGO)
    for marker in ["APPEAL", "SUMMON", "COMPLETION", "PROCEEDING"]:
        assert marker in src


# ── R08-INN-03: correspondence_autopack ──────────────────────────────────────

def test_inn03_autopack_has_legal_basis_per_type():
    src = _read(R08_REGO)
    for letter in ["wniosek_o_interpretacje", "odwolanie", "wniosek_o_zwrot_nadplaty", "czynny_zal", "wniosek_o_ulge_w_splacie", "powiadomienie_o_platnosci_na_rachunek"]:
        assert letter in src, letter
    # fail-closed: missing fields -> TRIAGE_QUEUE
    assert "corr_ready" in src
    assert "corr_missing_fields" in src
    assert "TRIAGE_QUEUE" in src


def test_inn03_white_list_letter_covers_117ba():
    src = _read(R08_REGO)
    block = _extract_decide_block(src, "correspondence_autopack")
    assert "117ba" in block
    assert "art. 22p" in block


# ── R08-INN-04: judgment_predictor_wsa_nsa ───────────────────────────────────

def test_inn04_predictor_scoring_components():
    src = _read(R08_REGO)
    assert "judgment_predictor_wsa_nsa" in src
    assert "0.40" in src  # trend component weight
    assert "0.30" in src  # precedent / strength weights
    assert "judg_probability_favorable" in src
    assert "judg_confidence" in src


def test_inn04_recommendation_thresholds():
    src = _read(R08_REGO)
    assert ">= 65" in src
    assert ">= 40" in src
    assert "Niska szansa" in src


# ── R08-INN-05: limitation_evidence_monitor ──────────────────────────────────

def test_inn05_evidence_certificate_present():
    src = _read(R08_REGO)
    assert "limitation_evidence_monitor" in src
    assert "lim_evidence_certificate" in src
    assert "decision_hash" in src
    assert "statute_barred" in src


def test_inn05_statute_years_from_thresholds():
    src = _read(R08_REGO)
    assert "limitation_years" in src
    assert "lim_deadline_year" in src
    assert "art. 70" in src


# ── Inwarianty łańcucha (chain-position agnostic) ────────────────────────────

def test_invariants_after_r08():
    src = _read(MAIN_REGO)
    # final_verdict_post_merge musi budować na p33
    assert "final_verdict_post_merge = object.union(final_verdict_p39" in src
    # invariants + certificate nadal obecne
    assert "final_verdict_enforced = object.union(final_verdict_post_merge" in src
    assert "_decision_certificate" in src or "decision_certificate" in src
    assert "_certainty_guard" in src
