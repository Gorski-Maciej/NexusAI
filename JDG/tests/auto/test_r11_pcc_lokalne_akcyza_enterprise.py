"""RAPORT_11 — PCC / PODATKI LOKALNE / AKCYZĄ — pytest suite.

Prompt 11/25 is implemented as the R11 PCC/local/excise innovations package
(rules/r11_pcc_lokalne_akcyza_innovations_v9.rego) wired into main_jdg.rego
(final_verdict_p36). Tests mirror the R01..R10 conventions:

  R11-INN-01 pcc3_deadline_alert_monitor  — monitor 14 dni PCC-3
  R11-INN-02 real_estate_tax_simulator    — symulator podatku od nieruchomości
  R11-INN-03 excise_product_classifier    — klasyfikator wyrobów akcyzowych
  R11-INN-04 transport_tax_deadline_monitor— monitor DN-1 + raty
  R11-INN-05 vat_vs_pcc_arbitrator        — arbiter VAT vs PCC (art. 2 pkt 4)
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]
R11_REGO = BASE_DIR / "rules" / "r11_pcc_lokalne_akcyza_innovations_v9.rego"
MAIN_REGO = BASE_DIR / "rules" / "main_jdg.rego"
THRESHOLDS_REGO = BASE_DIR / "rules" / "thresholds_jdg.rego"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


_PKG = "jdg.r11_pcc_lokalne_akcyza_innovations"


def _extract_decide_block(src: str, short_id: str) -> str:
    """Naive extraction: find the decide block containing a given rule_id."""
    full_id = f"{_PKG}.{short_id}"
    idx = src.find(f'"{full_id}"')
    assert idx != -1, f"rule_id {full_id} not found"
    return src[max(0, idx - 4000): idx + 4000]


# ── Struktura ─────────────────────────────────────────────────────────────────

def test_r11_file_exists_and_has_package():
    src = _read(R11_REGO)
    m = re.search(r"^package\s+([\w.]+)", src, re.M)
    assert m is not None
    assert m.group(1) == "jdg.r11_pcc_lokalne_akcyza_innovations"


def test_r11_braces_balanced():
    src = _read(R11_REGO)
    assert src.count("{") == src.count("}")


def test_r11_rule_ids_unique_and_namespaced():
    src = _read(R11_REGO)
    ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', src)
    assert len(ids) == len(set(ids)), f"duplicate rule_ids: {ids}"
    for rid in ids:
        assert rid.startswith("jdg.r11_pcc_lokalne_akcyza_innovations."), rid
    assert len(ids) == 6


def test_r11_no_hardcoded_thresholds():
    src = _read(R11_REGO)
    assert 'object.get(object.get(data, "jdg", {}), "thresholds", {})' in src
    assert "_th_ple" in src


def test_r11_no_match_default_present():
    src = _read(R11_REGO)
    assert '"rule_id": "jdg.r11_pcc_lokalne_akcyza_innovations.no_match"' in src


def test_r11_legal_basis_present_on_each_innovation():
    src = _read(R11_REGO)
    for rid in [
        "pcc3_deadline_alert_monitor",
        "real_estate_tax_simulator",
        "excise_product_classifier",
        "transport_tax_deadline_monitor",
        "vat_vs_pcc_arbitrator",
    ]:
        block = _extract_decide_block(src, rid)
        assert '"_legal_basis"' in block, rid
        assert "valid_from" in block, rid


def test_r11_pcc_local_excise_thresholds_block_present():
    src = _read(THRESHOLDS_REGO)
    assert "pcc_local_excise := {" in src
    assert '"pcc_sale_rate"' in src
    assert '"excise_gasoline"' in src
    assert '"land_business_rate"' in src


def test_r11_main_router_wired_p36():
    src = _read(MAIN_REGO)
    assert "import data.jdg.r11_pcc_lokalne_akcyza_innovations" in src
    assert '"jdg.r11_pcc_lokalne_akcyza_innovations": r11_pcc_lokalne_akcyza_innovations.decide' in src
    assert "final_verdict_p36 = safe_merge(final_verdict_p35" in src
    assert "final_verdict_post_merge = object.union(final_verdict_p39" in src


# ── R11-INN-01: pcc3_deadline_alert_monitor ──────────────────────────────────

def test_inn01_pcc3_three_levels():
    src = _read(R11_REGO)
    assert "pcc3_deadline_alert_monitor" in src
    assert "RED" in src and "AMBER" in src and "GREEN" in src
    assert "pcc3_unfiled_count" in src
    assert 'object.get(_th_ple, "pcc3_deadline_days", 14)' in src
    assert "art. 10" in src


# ── R11-INN-02: real_estate_tax_simulator ────────────────────────────────────

def test_inn02_real_estate_simulator():
    src = _read(R11_REGO)
    assert "real_estate_tax_simulator" in src
    assert "ret_total_annual" in src
    assert "ret_installment_quarterly" in src
    assert 'object.get(_th_ple, "land_business_rate", 1.43)' in src
    assert 'object.get(_th_ple, "building_business_rate", 33.10)' in src


# ── R11-INN-03: excise_product_classifier ────────────────────────────────────

def test_inn03_excise_classifier():
    src = _read(R11_REGO)
    assert "excise_product_classifier" in src
    assert "exc_duty_pln" in src
    assert "exc_needs_banderole" in src
    for t in ["GASOLINE", "DIESEL", "LPG", "ETHANOL", "BEER", "WINE"]:
        assert t in src, t


# ── R11-INN-04: transport_tax_deadline_monitor ───────────────────────────────

def test_inn04_transport_monitor():
    src = _read(R11_REGO)
    assert "transport_tax_deadline_monitor" in src
    assert "trt_unfiled_count" in src
    assert "dn1_filed" in src
    assert "15.03" in src and "15.05" in src and "15.09" in src and "15.11" in src


# ── R11-INN-05: vat_vs_pcc_arbitrator ────────────────────────────────────────

def test_inn05_arbitrator():
    src = _read(R11_REGO)
    assert "vat_vs_pcc_arbitrator" in src
    assert "arb_pcc_excluded" in src
    assert "arb_pcc_due_pln" in src
    assert "art. 2 pkt 4" in src


# ── Inwarianty łańcucha (chain-position agnostic) ────────────────────────────

def test_invariants_after_r11():
    src = _read(MAIN_REGO)
    assert "final_verdict_post_merge = object.union(final_verdict_p39" in src
    assert "final_verdict_enforced = object.union(final_verdict_post_merge" in src
    assert "_decision_certificate" in src or "decision_certificate" in src
    assert "_certainty_guard" in src
