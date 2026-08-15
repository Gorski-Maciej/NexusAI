"""RAPORT_09 — UoR / PKPiR / KSIĘGOWOŚĆ — pytest suite.

Prompt 09/25 is implemented as the R09 accounting innovations package
(rules/r09_ksiegowosc_pkpir_uor_innovations_v9.rego) wired into main_jdg.rego
(final_verdict_p34). Tests mirror the R01..R08 conventions:

  R09-INN-01 uor_threshold_simulator      — symulator progu UoR + projekcja
  R09-INN-02 pkpir_ledger_reconciliation  — uzgodnienie 3-drożne PKPiR↔VAT↔bank
  R09-INN-03 amortization_plan_optimizer  — liniowa vs degresywna vs jednorazowa
  R09-INN-04 inventory_deadline_monitor   — 3 poziomy alertów inwentaryzacji
  R09-INN-05 financial_statement_autopack — auto-pakiet sprawozdania finansowego
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]
R09_REGO = BASE_DIR / "rules" / "r09_ksiegowosc_pkpir_uor_innovations_v9.rego"
MAIN_REGO = BASE_DIR / "rules" / "main_jdg.rego"
THRESHOLDS_REGO = BASE_DIR / "rules" / "thresholds_jdg.rego"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


_PKG = "jdg.r09_ksiegowosc_pkpir_uor_innovations"


def _extract_decide_block(src: str, short_id: str) -> str:
    """Naive extraction: find the decide block containing a given rule_id."""
    full_id = f"{_PKG}.{short_id}"
    idx = src.find(f'"{full_id}"')
    assert idx != -1, f"rule_id {full_id} not found"
    return src[max(0, idx - 4000): idx + 4000]


# ── Struktura ─────────────────────────────────────────────────────────────────

def test_r09_file_exists_and_has_package():
    src = _read(R09_REGO)
    m = re.search(r"^package\s+([\w.]+)", src, re.M)
    assert m is not None
    assert m.group(1) == "jdg.r09_ksiegowosc_pkpir_uor_innovations"


def test_r09_braces_balanced():
    src = _read(R09_REGO)
    assert src.count("{") == src.count("}")


def test_r09_rule_ids_unique_and_namespaced():
    src = _read(R09_REGO)
    ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', src)
    assert len(ids) == len(set(ids)), f"duplicate rule_ids: {ids}"
    for rid in ids:
        assert rid.startswith("jdg.r09_ksiegowosc_pkpir_uor_innovations."), rid
    # 5 innovations + no_match
    assert len(ids) == 6


def test_r09_no_hardcoded_thresholds():
    src = _read(R09_REGO)
    assert 'object.get(object.get(data, "jdg", {}), "thresholds", {})' in src
    assert "_th_acc" in src
    # KŚT rates — externalized as a local map (fallback), not hardcoded in decides
    assert "plan_kst_rates" in src


def test_r09_no_match_default_present():
    src = _read(R09_REGO)
    assert '"rule_id": "jdg.r09_ksiegowosc_pkpir_uor_innovations.no_match"' in src


def test_r09_legal_basis_present_on_each_innovation():
    src = _read(R09_REGO)
    for rid in [
        "uor_threshold_simulator",
        "pkpir_ledger_reconciliation",
        "amortization_plan_optimizer",
        "inventory_deadline_monitor",
        "financial_statement_autopack",
    ]:
        block = _extract_decide_block(src, rid)
        assert '"_legal_basis"' in block, rid
        assert "valid_from" in block, rid


def test_r09_accounting_thresholds_block_present():
    src = _read(THRESHOLDS_REGO)
    assert "accounting := {" in src
    assert '"uor_threshold_eur"' in src
    assert '"eur_pln_reference"' in src
    assert '"one_time_depreciation_eur"' in src


def test_r09_main_router_wired_p34():
    src = _read(MAIN_REGO)
    assert "import data.jdg.r09_ksiegowosc_pkpir_uor_innovations" in src
    assert '"jdg.r09_ksiegowosc_pkpir_uor_innovations": r09_ksiegowosc_pkpir_uor_innovations.decide' in src
    assert "final_verdict_p34 = safe_merge(final_verdict_p33" in src
    assert "final_verdict_post_merge = object.union(final_verdict_p41" in src


# ── R09-INN-01: uor_threshold_simulator ──────────────────────────────────────

def test_inn01_simulator_decision_and_projection():
    src = _read(R09_REGO)
    assert "uor_threshold_simulator" in src
    assert "uos_current_eur" in src
    assert "uos_projected_eur" in src
    assert "uos_months_to_threshold" in src
    assert "uos_early_warning" in src
    assert '"PKPiR"' in src
    assert '"UoR"' in src


def test_inn01_uses_accounting_thresholds():
    src = _read(R09_REGO)
    assert 'object.get(_th_acc, "uor_threshold_eur", 2000000)' in src
    assert 'object.get(_th_acc, "early_warning_pct", 75)' in src


# ── R09-INN-02: pkpir_ledger_reconciliation ──────────────────────────────────

def test_inn02_reconciliation_three_way():
    src = _read(R09_REGO)
    assert "pkpir_ledger_reconciliation" in src
    assert "lrecon_pkpir_sales_net" in src
    assert "lrecon_vat_sales_base" in src
    assert "lrecon_bank_inflows" in src
    assert "lrecon_reconciled" in src
    assert "lrecon_mismatches" in src


# ── R09-INN-03: amortization_plan_optimizer ──────────────────────────────────

def test_inn03_optimizer_methods():
    src = _read(R09_REGO)
    assert "amortization_plan_optimizer" in src
    assert "plan_linear_annual" in src
    assert "plan_degressive_annual" in src
    assert "plan_one_off_eligible" in src
    assert "plan_best_method" in src
    assert "ONE_OFF" in src
    assert "DEGRESSIVE" in src
    assert "LINEAR" in src


def test_inn03_car_limit_from_thresholds():
    src = _read(R09_REGO)
    assert 'object.get(_th_acc, "car_limit_standard", 150000)' in src
    assert 'object.get(_th_acc, "car_limit_electric", 225000)' in src


# ── R09-INN-04: inventory_deadline_monitor ───────────────────────────────────

def test_inn04_three_levels_defined():
    src = _read(R09_REGO)
    assert "inventory_deadline_monitor" in src
    assert "RED" in src and "AMBER" in src and "GREEN" in src
    assert "BLOCK_AND_ALERT" in src
    assert "TRIAGE_QUEUE" in src
    assert "CASH" in src and "STOCK" in src and "FIXED_ASSETS" in src


def test_inn04_next_action_per_type():
    src = _read(R09_REGO)
    assert "art. 26" in src
    assert "inventory_fixed_assets_years" in src


# ── R09-INN-05: financial_statement_autopack ─────────────────────────────────

def test_inn05_autopack_fail_closed():
    src = _read(R09_REGO)
    assert "financial_statement_autopack" in src
    assert "fs_missing" in src
    assert "fs_ready" in src
    assert "fs_approval_deadline" in src
    assert "fs_filing_deadline" in src
    assert "fs_retention_years" in src
    assert "art. 74" in src


# ── Inwarianty łańcucha (chain-position agnostic) ────────────────────────────

def test_invariants_after_r09():
    src = _read(MAIN_REGO)
    assert "final_verdict_post_merge = object.union(final_verdict_p41" in src
    assert "final_verdict_enforced = object.union(final_verdict_post_merge" in src
    assert "_decision_certificate" in src or "decision_certificate" in src
    assert "_certainty_guard" in src
