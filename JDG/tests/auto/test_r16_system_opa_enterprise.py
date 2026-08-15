"""RAPORT_16 — SYSTEM OPA (P18–P35) — pytest suite.

Prompt 16/25 is implemented as the R16 System OPA innovations package
(rules/r16_system_opa_innovations_v9.rego) wired into main_jdg.rego
(final_verdict_p41). Tests mirror the R01..R15 conventions:

  R16-INN-01 rule_lifecycle_monitor          — cykl życia reguły + rollback
  R16-INN-02 validation_quality_monitor      — jakość walidacji (zero-defect)
  R16-INN-03 test_shield_monitor             — tarcza CI (mutation ≥70%)
  R16-INN-04 reliability_determinism_monitor — niezawodność/determinizm
  R16-INN-05 isap_pipeline_monitor           — pipeline ISAP (SLA)
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]
R16_REGO = BASE_DIR / "rules" / "r16_system_opa_innovations_v9.rego"
MAIN_REGO = BASE_DIR / "rules" / "main_jdg.rego"
THRESHOLDS_REGO = BASE_DIR / "rules" / "thresholds_jdg.rego"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


_PKG = "jdg.r16_system_opa_innovations"


def _extract_decide_block(src: str, short_id: str) -> str:
    full_id = f"{_PKG}.{short_id}"
    idx = src.find(f'"{full_id}"')
    assert idx != -1, f"rule_id {full_id} not found"
    return src[max(0, idx - 4000): idx + 4000]


# ── Struktura ─────────────────────────────────────────────────────────────────

def test_r16_file_exists_and_has_package():
    src = _read(R16_REGO)
    m = re.search(r"^package\s+([\w.]+)", src, re.M)
    assert m is not None
    assert m.group(1) == "jdg.r16_system_opa_innovations"


def test_r16_braces_balanced():
    src = _read(R16_REGO)
    assert src.count("{") == src.count("}")


def test_r16_rule_ids_unique_and_namespaced():
    src = _read(R16_REGO)
    ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', src)
    assert len(ids) == len(set(ids)), f"duplicate rule_ids: {ids}"
    for rid in ids:
        assert rid.startswith("jdg.r16_system_opa_innovations."), rid
    assert len(ids) == 6


def test_r16_no_hardcoded_thresholds():
    src = _read(R16_REGO)
    assert 'object.get(object.get(data, "jdg", {}), "thresholds", {})' in src
    assert "_th_so" in src


def test_r16_no_match_default_present():
    src = _read(R16_REGO)
    assert '"rule_id": "jdg.r16_system_opa_innovations.no_match"' in src


def test_r16_legal_basis_present_on_each_innovation():
    src = _read(R16_REGO)
    for rid in [
        "rule_lifecycle_monitor",
        "validation_quality_monitor",
        "test_shield_monitor",
        "reliability_determinism_monitor",
        "isap_pipeline_monitor",
    ]:
        block = _extract_decide_block(src, rid)
        assert '"_legal_basis"' in block, rid
        assert "valid_from" in block, rid


def test_r16_system_opa_thresholds_block_present():
    src = _read(THRESHOLDS_REGO)
    assert "system_opa := {" in src
    assert '"rollback_error_threshold"' in src
    assert '"mutation_score_min"' in src
    assert '"isap_sla_hours"' in src


def test_r16_main_router_wired_p41():
    src = _read(MAIN_REGO)
    assert "import data.jdg.r16_system_opa_innovations" in src
    assert '"jdg.r16_system_opa_innovations": r16_system_opa_innovations.decide' in src
    assert "final_verdict_p41 = safe_merge(final_verdict_p40" in src
    assert "final_verdict_post_merge = object.union(final_verdict_p41" in src


# ── R16-INN-01: rule_lifecycle_monitor ───────────────────────────────────────

def test_inn01_lifecycle():
    src = _read(R16_REGO)
    assert "rule_lifecycle_monitor" in src
    assert "rl_should_rollback" in src
    assert "rl_phase" in src
    assert 'object.get(_th_so, "rollback_error_threshold", 0.01)' in src
    assert "ADR-016" in src


# ── R16-INN-02: validation_quality_monitor ───────────────────────────────────

def test_inn02_validation_quality():
    src = _read(R16_REGO)
    assert "validation_quality_monitor" in src
    assert "vq_zero_defect" in src
    assert "vq_defects" in src
    assert 'object.get(_th_so, "hardcoded_threshold", 10)' in src
    assert "ADR-006" in src


# ── R16-INN-03: test_shield_monitor ──────────────────────────────────────────

def test_inn03_test_shield():
    src = _read(R16_REGO)
    assert "test_shield_monitor" in src
    assert "ts_shield_ok" in src
    assert "ts_mutation_ok" in src
    assert 'object.get(_th_so, "mutation_score_min", 70)' in src
    assert "ADR-022" in src


# ── R16-INN-04: reliability_determinism_monitor ──────────────────────────────

def test_inn04_reliability():
    src = _read(R16_REGO)
    assert "reliability_determinism_monitor" in src
    assert "rb_reliable" in src
    assert "rb_provenance_ok" in src
    assert "ADR-006" in src


# ── R16-INN-05: isap_pipeline_monitor ────────────────────────────────────────

def test_inn05_isap_pipeline():
    src = _read(R16_REGO)
    assert "isap_pipeline_monitor" in src
    assert "ip_sla_breach" in src
    assert "ip_sla_hours" in src
    assert 'object.get(_th_so, "isap_sla_hours", 24)' in src
    assert "ADR-002" in src
    assert "ISAP" in src


# ── Inwarianty łańcucha (chain-position agnostic) ────────────────────────────

def test_invariants_after_r16():
    src = _read(MAIN_REGO)
    assert "final_verdict_post_merge = object.union(final_verdict_p41" in src
    assert "final_verdict_enforced = object.union(final_verdict_post_merge" in src
    assert "_decision_certificate" in src or "decision_certificate" in src
    assert "_certainty_guard" in src
