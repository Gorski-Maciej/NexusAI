# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P13 (VAT ODLICZENIA / MPP) — kampania V3 FORTRESS.

Weryfikuje:
  * reguły OPA w rules/v3_p13_vat_deductions_enterprise.rego (innowacje I01-I12),
  * parametry-as-data w rules/thresholds_jdg.rego (ADR-002),
  * 12 narzędzi dowodowych tools/v3_p13_*.py i 12 bundle bundles/v3_p13_*.json,
  * wiring w rules/main_jdg.rego (final_verdict_p82).
"""
from __future__ import annotations

import json
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"

P13_REGO = RULES / "v3_p13_vat_deductions_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"

INNOVATIONS = {
    "I01": "jdg.v3_p13_vat_deductions.deduction_rights_engine",
    "I02": "jdg.v3_p13_vat_deductions.multi_year_correction_planner",
    "I03": "jdg.v3_p13_vat_deductions.bad_debt_radar",
    "I04": "jdg.v3_p13_vat_deductions.mpp_obligation_detector",
    "I05": "jdg.v3_p13_vat_deductions.annex15_as_versioned_data",
    "I06": "jdg.v3_p13_vat_deductions.white_list_gate",
    "I07": "jdg.v3_p13_vat_deductions.fraud_signal_framework",
    "I08": "jdg.v3_p13_vat_deductions.proportion_precision_engine",
    "I09": "jdg.v3_p13_vat_deductions.vat_balance_invariants",
    "I10": "jdg.v3_p13_vat_deductions.vat_stress_lab",
    "I11": "jdg.v3_p13_vat_deductions.correction_symmetry_guard",
    "I12": "jdg.v3_p13_vat_deductions.payment_safe_pay_advisor",
}

TOOLS_EXPECTED = {
    "v3_p13_deduction_rights_engine.py", "v3_p13_multi_year_correction_planner.py",
    "v3_p13_bad_debt_radar.py", "v3_p13_mpp_obligation_detector.py",
    "v3_p13_annex15_as_versioned_data.py", "v3_p13_white_list_gate.py",
    "v3_p13_fraud_signal_framework.py", "v3_p13_proportion_precision_engine.py",
    "v3_p13_vat_balance_invariants.py", "v3_p13_vat_stress_lab.py",
    "v3_p13_correction_symmetry_guard.py", "v3_p13_payment_safe_pay_advisor.py",
}

THRESHOLD_KEYS = [
    "deduction_moment_months", "deduction_prefinancing_months",
    "car_vat_deduction_limit_standard", "car_vat_deduction_limit_ev",
    "car_vat_deduction_with_log", "car_vat_deduction_no_log",
    "multi_year_years_low_value", "multi_year_years_other", "multi_year_years_real_estate",
    "asset_correction_threshold", "bad_debt_days", "bad_debt_sanction_30pct",
    "whitelist_check_threshold_pln", "whitelist_cache_ttl_hours", "whitelist_fallback_mode",
    "fraud_score_high", "fraud_score_medium", "fraud_human_review_required",
    "proportion_min_threshold", "proportion_max_threshold",
    "mpp_mandatory_threshold", "mpp_sanction_rate",
    "annex15_cn_codes", "annex15_data_version",
    "v3_p13_threshold_version",
]


def _rego_text() -> str:
    return P13_REGO.read_text(encoding="utf-8")


def test_rego_file_exists() -> None:
    assert P13_REGO.exists(), f"brak {P13_REGO}"


def test_all_12_innovation_rules_present() -> None:
    text = _rego_text()
    missing = [rid for rid in INNOVATIONS.values() if rid not in text]
    assert not missing, f"brak rule_id w rego: {missing}"


def test_no_stub_true_rules() -> None:
    text = _rego_text()
    assert "{ true } else := {" not in text or "BRAK_ŚCIEŻKI" in text
    assert "{ true }" not in text.replace("{ true } else", "")


def test_fail_closed_routing_present() -> None:
    text = _rego_text()
    assert "NEEDS_ADVICE" in text
    assert "BLOCK_AND_ALERT" in text
    assert "no_auto_post" in text or "SUGGEST" in text


def test_thresholds_params_present() -> None:
    th = THRESHOLDS.read_text(encoding="utf-8")
    # MPP kanoniczne progi mieszkają w sekcji misc (kontrakt P13 5.3)
    missing = [k for k in THRESHOLD_KEYS if f'"{k}"' not in th]
    assert not missing, f"brak parametrów P13 w thresholds_jdg.rego: {missing}"


def test_main_jdg_wired() -> None:
    main = MAIN_JDG.read_text(encoding="utf-8")
    assert "import data.jdg.v3_p13_vat_deductions" in main
    assert '"jdg.v3_p13_vat_deductions": v3_p13_vat_deductions.decide' in main
    assert "final_verdict_p82" in main
    assert "final_verdict_post_merge" in main


def test_all_12_tools_exist() -> None:
    present = {f.name for f in TOOLS.glob("v3_p13_*.py")}
    missing = TOOLS_EXPECTED - present
    assert not missing, f"brak narzędzi dowodowych: {missing}"


def test_all_12_bundles_exist_and_gate_pass() -> None:
    bundles = sorted(BUNDLES.glob("v3_p13_*.json"))
    assert len(bundles) == 12, f"oczekiwano 12 bundle, jest {len(bundles)}"
    for b in bundles:
        data = json.loads(b.read_text(encoding="utf-8"))
        assert data.get("gate") == "PASS", f"{b.name}: gate != PASS"
        assert data["innovation"].startswith("V3-P13-I"), b.name


def test_each_innovation_has_bundle_evidence() -> None:
    bundles = {b.name: json.loads(b.read_text(encoding="utf-8"))
               for b in BUNDLES.glob("v3_p13_*.json")}
    innovations_in_bundles = {v["innovation"] for v in bundles.values()}
    expected = {f"V3-P13-{k}" for k in INNOVATIONS}
    missing = expected - innovations_in_bundles
    assert not missing, f"brak bundle dla: {missing}"


def test_rego_package_declaration() -> None:
    text = _rego_text()
    assert "package jdg.v3_p13_vat_deductions" in text
    assert "default decide" in text


def test_tools_executable_are_importable() -> None:
    """Każde narzędzie ma funkcję main() i poprawny import wspólnego helpera."""
    import importlib.util
    import sys

    sys.path.insert(0, str(TOOLS))  # import v3_p13_common
    try:
        for tool in TOOLS_EXPECTED:
            spec = importlib.util.spec_from_file_location(tool[:-3], TOOLS / tool)
            assert spec is not None and spec.loader is not None, tool
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)
            assert callable(getattr(mod, "main", None)), tool
    finally:
        sys.path.pop(0)
