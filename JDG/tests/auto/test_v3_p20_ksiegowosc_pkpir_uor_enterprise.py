# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P20 (PKPiR / UoR / AMORTYZACJA / LEASING ENTERPRISE) — kampania V3 FORTRESS.

Weryfikuje:
  * reguły OPA w rules/v3_p20_ksiegowosc_pkpir_uor_enterprise.rego (12 innowacji I01-I12),
  * parametry-as-data w rules/thresholds_jdg.rego (ADR-002),
  * 12 narzędzi dowodowych tools/v3_p20_*.py i 12 bundle bundles/v3_p20_*.json,
  * wiring w rules/main_jdg.rego (final_verdict_p87).
"""

from __future__ import annotations

import json
import sys
from importlib import util as importlib_util
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"

# Dwa względem repo:
#   1) reguły V3-P20 enterprise,
#   2) verifier V3-P20 (ten plik).
P20_REGO = RULES / "v3_p20_ksiegowosc_pkpir_uor_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"

INNOVATIONS = {
    "I01": "jdg.v3_p20_ksiegowosc_pkpir_uor.pkpir_schema_validator",
    "I02": "jdg.v3_p20_ksiegowosc_pkpir_uor.remanent_chain_engine",
    "I03": "jdg.v3_p20_ksiegowosc_pkpir_uor.nkup_boundary_engine",
    "I04": "jdg.v3_p20_ksiegowosc_pkpir_uor.one_time_deprecation_sentinel",
    "I05": "jdg.v3_p20_ksiegowosc_pkpir_uor.kst_rates_as_data",
    "I06": "jdg.v3_p20_ksiegowosc_pkpir_uor.leasing_split_engine",
    "I07": "jdg.v3_p20_ksiegowosc_pkpir_uor.pkpir_to_uor_transition",
    "I08": "jdg.v3_p20_ksiegowosc_pkpir_uor.year_end_closing_chain",
    "I09": "jdg.v3_p20_ksiegowosc_pkpir_uor.double_entry_consistency_gate",
    "I10": "jdg.v3_p20_ksiegowosc_pkpir_uor.bookkeeping_golden_set",
    "I11": "jdg.v3_p20_ksiegowosc_pkpir_uor.bookkeeping_invariants_pack",
    "I12": "jdg.v3_p20_ksiegowosc_pkpir_uor.document_checklist_generator",
}

TOOLS_EXPECTED = {
    "v3_p20_pkpir_schema_validator.py",
    "v3_p20_remanent_chain_engine.py",
    "v3_p20_nkup_boundary_engine.py",
    "v3_p20_one_time_deprecation_sentinel.py",
    "v3_p20_kst_rates_as_data.py",
    "v3_p20_leasing_split_engine.py",
    "v3_p20_pkpir_to_uor_transition.py",
    "v3_p20_year_end_closing_chain.py",
    "v3_p20_double_entry_consistency_gate.py",
    "v3_p20_bookkeeping_golden_set.py",
    "v3_p20_bookkeeping_invariants_pack.py",
    "v3_p20_document_checklist_generator.py",
}

THRESHOLD_KEYS = [
    "v3_p20_threshold_version",
    "kst_rates",
    "kst_version",
    "depreciation_limits",
    "leasing_limits",
    "nkup_limits",
    "pkpir_columns",
    "kst_group_1_rate",
    "kst_group_2_rate",
    "kst_group_3_rate",
    "kst_group_4_rate",
    "kst_group_5_rate",
    "kst_group_6_rate",
    "kst_group_7_rate",
    "kst_group_8_rate",
    "kst_group_9_rate",
    "one_time_depreciation_limit_eur",
    "car_leasing_limit_150000",
    "uor_threshold_eur",
    "golden_version",
    "bookkeeping_invariants_active",
    "pkpir_column_count_minimum",
]


def _rego_text() -> str:
    return P20_REGO.read_text(encoding="utf-8")


def test_rego_file_exists() -> None:
    assert P20_REGO.exists(), f"brak {P20_REGO}"


def test_all_12_innovation_rules_present() -> None:
    text = _rego_text()
    missing = [rid for rid in INNOVATIONS.values() if rid not in text]
    assert not missing, f"brak rule_id w rego: {missing}"


def test_no_stub_true_rules() -> None:
    text = _rego_text()
    # explicit stub { true } without else ścieżki
    assert "{ true }\n" not in text
    # placeholder strtoupper stub pattern z P19
    assert "true } else := {" not in text or "BRAK_ŚCIEŻKI" in text


def test_fail_closed_routing_present() -> None:
    text = _rego_text()
    assert "BLOCK_AND_ALERT" in text
    assert "TRIAGE_QUEUE" in text
    assert "SUGGEST" in text or "no_auto_post" in text
    assert "default decide" in text


def test_thresholds_params_present() -> None:
    th = THRESHOLDS.read_text(encoding="utf-8")
    missing = [k for k in THRESHOLD_KEYS if f'"{k}"' not in th]
    assert not missing, f"brak parametrów P20 w thresholds_jdg.rego: {missing}"


def test_legal_limits_reused_as_data() -> None:
    th = THRESHOLDS.read_text(encoding="utf-8")
    for k in (
        "kst_group_1_rate",
        "kst_group_3_rate",
        "kst_group_5_rate",
        "kst_group_7_rate",
    ):
        assert f'"{k}"' in th, f"brak reużywanego parametru {k} (ADR-002)"


def test_main_jdg_wired() -> None:
    main = MAIN_JDG.read_text(encoding="utf-8")
    # driver P20 musi być zaimportowany w main
    assert "import data.jdg.v3_p20_ksiegowosc" in main or (
        "v3_p20_ksiegowosc" in main
    ), "brak importu jdg.v3_p20_ksiegowosc w main_jdg.rego"
    assert 'jdg.v3_p20_ksiegowosc' in main or (
        "v3_p20_ksiegowosc" in main
    ), "brak rejestracji pakietu P20 w main_jdg.rego"
    assert "final_verdict_p87" in main or "final_verdict" in main


def test_all_12_tools_exist() -> None:
    present = {f.name for f in TOOLS.glob("v3_p20_*.py")}
    missing = TOOLS_EXPECTED - present
    assert not missing, f"brak narzędzi dowodowych: {missing}"


def test_all_12_bundles_exist_and_gate_pass() -> None:
    bundles = sorted(BUNDLES.glob("v3_p20_*.json"))
    assert len(bundles) == 12, f"oczekiwano 12 bundle, jest {len(bundles)}"
    for b in bundles:
        data = json.loads(b.read_text(encoding="utf-8"))
        assert data.get("gate") == "PASS", f"{b.name}: gate != PASS"
        assert data["innovation"].startswith("V3-P20-I"), b.name


def test_each_innovation_has_bundle_evidence() -> None:
    bundles = {
        b.name: json.loads(b.read_text(encoding="utf-8"))
        for b in BUNDLES.glob("v3_p20_*.json")
    }
    innovations_in_bundles = {v["innovation"] for v in bundles.values()}
    expected = {f"V3-P20-{k}" for k in INNOVATIONS}
    missing = expected - innovations_in_bundles
    assert not missing, f"brak bundle dla: {missing}"


def test_rego_package_declaration() -> None:
    text = _rego_text()
    assert "package jdg.v3_p20_ksiegowosc_pkpir_uor" in text
    assert "default decide" in text


def test_tools_executable_are_importable() -> None:
    """Każde narzędzie ma funkcję main() i poprawny import wspólnego helpera."""
    sys.path.insert(0, str(TOOLS))  # import v3_p20_common
    try:
        for tool in sorted(TOOLS_EXPECTED):
            spec = importlib_util.spec_from_file_location(
                tool[:-3], TOOLS / tool
            )
            assert spec is not None and spec.loader is not None, tool
            mod = importlib_util.module_from_spec(spec)
            spec.loader.exec_module(mod)
            assert callable(getattr(mod, "main", None)), tool
    finally:
        sys.path.pop(0)
