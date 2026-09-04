# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P18 (RYCZAŁT ENTERPRISE) — kampania V3 FORTRESS.

Weryfikuje:
  * reguły OPA w rules/v3_p18_ryczalt_enterprise.rego (12 innowacji I01-I12),
  * parametry-as-data w rules/thresholds_jdg.rego (ADR-002),
  * 12 narzędzi dowodowych tools/v3_p18_*.py i 12 bundle bundles/v3_p18_*.json,
  * wiring w rules/main_jdg.rego (final_verdict_p86).
"""
from __future__ import annotations

import json
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"

P18_REGO = RULES / "v3_p18_ryczalt_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"

INNOVATIONS = {
    "I01": "jdg.v3_p18_ryczalt.rates_matrix",
    "I02": "jdg.v3_p18_ryczalt.exclusion_sentinel",
    "I03": "jdg.v3_p18_ryczalt.midyear_exclusion_handler",
    "I04": "jdg.v3_p18_ryczalt.four_form_advisor",
    "I05": "jdg.v3_p18_ryczalt.rate_split_engine",
    "I06": "jdg.v3_p18_ryczalt.year_end_correction_lab",
    "I07": "jdg.v3_p18_ryczalt.pkpir_contract",
    "I08": "jdg.v3_p18_ryczalt.pit28_autogen",
    "I09": "jdg.v3_p18_ryczalt.exclusion_registry",
    "I10": "jdg.v3_p18_ryczalt.golden_set",
    "I11": "jdg.v3_p18_ryczalt.invariants_pack",
    "I12": "jdg.v3_p18_ryczalt.explanation_engine",
}

TOOLS_EXPECTED = {
    "v3_p18_rates_matrix.py", "v3_p18_exclusion_sentinel.py",
    "v3_p18_midyear_exclusion.py", "v3_p18_four_form_advisor.py",
    "v3_p18_rate_split.py", "v3_p18_year_end_correction.py",
    "v3_p18_pkpir_contract.py", "v3_p18_pit28_autogen.py",
    "v3_p18_exclusion_registry.py", "v3_p18_golden_set.py",
    "v3_p18_invariants.py", "v3_p18_explanation.py",
}

THRESHOLD_KEYS = [
    "v3_p18_threshold_version", "v3_p18_rate_10pct", "v3_p18_rate_12_5pct",
    "v3_p18_rate_14pct", "v3_p18_rate_set", "v3_p18_rate_map_version",
    "v3_p18_rate_14pct_threshold_pln", "v3_p18_exclusion_former_employer",
    "v3_p18_exclusion_effective_mode", "v3_p18_midyear_change_deadline_days",
    "v3_p18_health_rate_pct", "v3_p18_scale_low_rate", "v3_p18_scale_high_rate",
    "v3_p18_scale_threshold_pln", "v3_p18_linear_rate", "v3_p18_karta_monthly_pln",
    "v3_p18_pit28_due", "v3_p18_contract_tolerance_pln",
    "v3_p18_golden_version", "v3_p18_invariants_active",
]


def _rego_text() -> str:
    return P18_REGO.read_text(encoding="utf-8")


def test_rego_file_exists() -> None:
    assert P18_REGO.exists(), f"brak {P18_REGO}"


def test_all_12_innovation_rules_present() -> None:
    text = _rego_text()
    missing = [rid for rid in INNOVATIONS.values() if rid not in text]
    assert not missing, f"brak rule_id w rego: {missing}"


def test_no_stub_true_rules() -> None:
    text = _rego_text()
    assert "true } else := {" not in text or "BRAK_ŚCIEŻKI" in text
    assert "{ true }" not in text.replace("{ true } else", "")


def test_fail_closed_routing_present() -> None:
    text = _rego_text()
    assert "NEEDS_ADVICE" in text or "BLOCK_AND_ALERT" in text
    assert "BLOCK_AND_ALERT" in text
    assert "SUGGEST" in text or "no_auto_post" in text


def test_thresholds_params_present() -> None:
    th = THRESHOLDS.read_text(encoding="utf-8")
    missing = [k for k in THRESHOLD_KEYS if f'"{k}"' not in th]
    assert not missing, f"brak parametrów P18 w thresholds_jdg.rego: {missing}"


def test_main_jdg_wired() -> None:
    main = MAIN_JDG.read_text(encoding="utf-8")
    assert "import data.jdg.v3_p18_ryczalt" in main
    assert '"jdg.v3_p18_ryczalt": v3_p18_ryczalt.decide' in main
    assert "final_verdict_p86" in main
    assert "final_verdict_post_merge" in main


def test_all_12_tools_exist() -> None:
    present = {f.name for f in TOOLS.glob("v3_p18_*.py")}
    missing = TOOLS_EXPECTED - present
    assert not missing, f"brak narzędzi dowodowych: {missing}"


def test_all_12_bundles_exist_and_gate_pass() -> None:
    bundles = sorted(BUNDLES.glob("v3_p18_*.json"))
    assert len(bundles) == 12, f"oczekiwano 12 bundle, jest {len(bundles)}"
    for b in bundles:
        data = json.loads(b.read_text(encoding="utf-8"))
        assert data.get("gate") == "PASS", f"{b.name}: gate != PASS"
        assert data["innovation"].startswith("V3-P18-I"), b.name


def test_each_innovation_has_bundle_evidence() -> None:
    bundles = {b.name: json.loads(b.read_text(encoding="utf-8"))
               for b in BUNDLES.glob("v3_p18_*.json")}
    innovations_in_bundles = {v["innovation"] for v in bundles.values()}
    expected = {f"V3-P18-{k}" for k in INNOVATIONS}
    missing = expected - innovations_in_bundles
    assert not missing, f"brak bundle dla: {missing}"


def test_rego_package_declaration() -> None:
    text = _rego_text()
    assert "package jdg.v3_p18_ryczalt" in text
    assert "default decide" in text


def test_tools_executable_are_importable() -> None:
    """Każde narzędzie ma funkcję main() i poprawny import wspólnego helpera."""
    import importlib.util
    import sys

    sys.path.insert(0, str(TOOLS))  # import v3_p18_common
    try:
        for tool in TOOLS_EXPECTED:
            spec = importlib.util.spec_from_file_location(tool[:-3], TOOLS / tool)
            assert spec is not None and spec.loader is not None, tool
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)
            assert callable(getattr(mod, "main", None)), tool
    finally:
        sys.path.pop(0)
