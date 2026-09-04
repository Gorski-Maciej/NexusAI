# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P15 (CROSS-BORDER ENTERPRISE) — kampania V3 FORTRESS.

Weryfikuje:
  * reguły OPA w rules/v3_p15_crossborder_enterprise.rego (12 innowacji I01-I12),
  * parametry-as-data w rules/thresholds_jdg.rego (ADR-002),
  * 12 narzędzi dowodowych tools/v3_p15_*.py i 12 bundle bundies/v3_p15_*.json,
  * wiring w rules/main_jdg.rego (final_verdict_p81).
"""
from __future__ import annotations

import json
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"

P15_REGO = RULES / "v3_p15_crossborder_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"

INNOVATIONS = {
    "I01": "jdg.v3_p15_crossborder.place_of_supply_matrix",
    "I02": "jdg.v3_p15_crossborder.eu_vat_rates_feed",
    "I03": "jdg.v3_p15_crossborder.residency_advisor",
    "I04": "jdg.v3_p15_crossborder.fx_precision_engine",
    "I05": "jdg.v3_p15_crossborder.tp_threshold_sentinel",
    "I06": "jdg.v3_p15_crossborder.mdr_hallmark_scorer",
    "I07": "jdg.v3_p15_crossborder.exit_tax_early_warning",
    "I08": "jdg.v3_p15_crossborder.crossborder_golden_set",
    "I09": "jdg.v3_p15_crossborder.oss_decision_advisor",
    "I10": "jdg.v3_p15_crossborder.distance_selling_tracker",
    "I11": "jdg.v3_p15_crossborder.crossborder_invariants",
    "I12": "jdg.v3_p15_crossborder.currency_consistency_gate",
}

TOOLS_EXPECTED = {
    "v3_p15_place_of_supply_matrix.py", "v3_p15_eu_vat_rates_feed.py",
    "v3_p15_residency_advisor.py", "v3_p15_fx_precision_engine.py",
    "v3_p15_tp_threshold_sentinel.py", "v3_p15_mdr_hallmark_scorer.py",
    "v3_p15_exit_tax_early_warning.py", "v3_p15_golden_set.py",
    "v3_p15_oss_advisor.py", "v3_p15_distance_selling_tracker.py",
    "v3_p15_crossborder_invariants.py", "v3_p15_currency_consistency_gate.py",
}

THRESHOLD_KEYS = [
    "pos_b2b_rule", "pos_b2c_rule", "pos_real_estate_rule", "pos_restaurant_rule",
    "pos_accommodation_rule", "pos_digital_b2c_rule", "eu_vat_rates_feed_source",
    "eu_vat_rates_version", "fx_rounding_rule", "fx_rounding_scale",
    "fx_use_previous_day_rate", "tp_monitoring_alert_days", "mdr_human_review_required",
    "mdr_reporting_deadline_days", "exit_tax_early_warning_days", "golden_set_min_verdicts",
    "oss_distance_selling_threshold_eur", "oss_annual_threshold_eur",
    "distance_selling_limit_eur", "wdt_invariant_required", "fx_d1_invariant_required",
    "import_services_rc_required", "currency_consistency_required",
    "v3_p15_threshold_version",
]


def _rego_text() -> str:
    return P15_REGO.read_text(encoding="utf-8")


def test_rego_file_exists() -> None:
    assert P15_REGO.exists(), f"brak {P15_REGO}"


def test_all_12_innovation_rules_present() -> None:
    text = _rego_text()
    missing = [rid for rid in INNOVATIONS.values() if rid not in text]
    assert not missing, f"brak rule_id w rego: {missing}"


def test_no_stub_true_rules() -> None:
    text = _rego_text()
    # stub wzorzec: "decide := {...} { true }" udający pokrycie
    assert "true } else := {" not in text or "BRAK_ŚCIEŻKI" in text
    assert "{ true }" not in text.replace("{ true } else", "")


def test_fail_closed_routing_present() -> None:
    text = _rego_text()
    assert "NEEDS_ADVICE" in text
    assert "BLOCK_AND_ALERT" in text
    assert "no_auto_post" in text or "SUGGEST" in text


def test_thresholds_params_present() -> None:
    th = THRESHOLDS.read_text(encoding="utf-8")
    missing = [k for k in THRESHOLD_KEYS if f'"{k}"' not in th]
    assert not missing, f"brak parametrów P15 w thresholds_jdg.rego: {missing}"


def test_main_jdg_wired() -> None:
    main = MAIN_JDG.read_text(encoding="utf-8")
    assert "import data.jdg.v3_p15_crossborder" in main
    assert '"jdg.v3_p15_crossborder": v3_p15_crossborder.decide' in main
    assert "final_verdict_p81" in main
    assert "final_verdict_post_merge" in main


def test_all_12_tools_exist() -> None:
    present = {f.name for f in TOOLS.glob("v3_p15_*.py")}
    missing = TOOLS_EXPECTED - present
    assert not missing, f"brak narzędzi dowodowych: {missing}"


def test_all_12_bundles_exist_and_gate_pass() -> None:
    bundles = sorted(BUNDLES.glob("v3_p15_*.json"))
    assert len(bundles) == 12, f"oczekiwano 12 bundle, jest {len(bundles)}"
    for b in bundles:
        data = json.loads(b.read_text(encoding="utf-8"))
        assert data.get("gate") == "PASS", f"{b.name}: gate != PASS"
        assert data["innovation"].startswith("V3-P15-I"), b.name


def test_each_innovation_has_bundle_evidence() -> None:
    bundles = {b.name: json.loads(b.read_text(encoding="utf-8"))
               for b in BUNDLES.glob("v3_p15_*.json")}
    innovations_in_bundles = {v["innovation"] for v in bundles.values()}
    expected = {f"V3-P15-{k}" for k in INNOVATIONS}
    missing = expected - innovations_in_bundles
    assert not missing, f"brak bundle dla: {missing}"


def test_rego_package_declaration() -> None:
    text = _rego_text()
    assert "package jdg.v3_p15_crossborder" in text
    assert "default decide" in text


def test_tools_executable_are_importable() -> None:
    """Każde narzędzie ma funkcję main() i poprawny import wspólnego helpera."""
    import importlib.util
    import sys

    sys.path.insert(0, str(TOOLS))  # import v3_p15_common
    try:
        for tool in TOOLS_EXPECTED:
            spec = importlib.util.spec_from_file_location(tool[:-3], TOOLS / tool)
            assert spec is not None and spec.loader is not None, tool
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)
            assert callable(getattr(mod, "main", None)), tool
    finally:
        sys.path.pop(0)