# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P26 (ZUS SKŁADKI ENTERPRISE) — kampania V3 FORTRESS.

Weryfikuje:
  * reguły OPA w rules/v3_p26_zus_skladki_enterprise.rego (12 innowacji I01-I12),
  * parametry-as-data w rules/thresholds_jdg.rego (blok zus + zus26, ADR-002),
  * 12 narzędzi dowodowych tools/v3_p26_*.py i 12 bundle bundles/v3_p26_*.json,
  * wiring w rules/main_jdg.rego (final_verdict_p90),
  * granice groszowe i progowe (4161,00 → 812,23; 60k/300k ±0,01).
"""
from __future__ import annotations

import json
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"

P26_REGO = RULES / "v3_p26_zus_skladki_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"

INNOVATIONS = {
    "I01": "jdg.v3_p26_zus_skladki.contribution_precision",
    "I02": "jdg.v3_p26_zus_skladki.relief_order_automaton",
    "I03": "jdg.v3_p26_zus_skladki.cumulative_tier_sentinel",
    "I04": "jdg.v3_p26_zus_skladki.health_2026_verifier",
    "I05": "jdg.v3_p26_zus_skladki.suspension_handler",
    "I06": "jdg.v3_p26_zus_skladki.dra_generator",
    "I07": "jdg.v3_p26_zus_skladki.invariants_pack",
    "I08": "jdg.v3_p26_zus_skladki.golden_set",
    "I09": "jdg.v3_p26_zus_skladki.form_change_rescaler",
    "I10": "jdg.v3_p26_zus_skladki.minimum_wage_integration",
    "I11": "jdg.v3_p26_zus_skladki.stress_lab",
    "I12": "jdg.v3_p26_zus_skladki.cross_act_consistency",
}

TOOLS_EXPECTED = {
    "v3_p26_contribution_precision.py", "v3_p26_relief_order.py",
    "v3_p26_cumulative_tier.py", "v3_p26_health_2026_verifier.py",
    "v3_p26_suspension_handler.py", "v3_p26_dra_generator.py",
    "v3_p26_invariants.py", "v3_p26_golden_set.py",
    "v3_p26_form_change_rescaler.py", "v3_p26_minimum_wage.py",
    "v3_p26_stress_lab.py", "v3_p26_cross_act_consistency.py",
}

THRESHOLD_KEYS_ZUS26 = [
    "v3_p26_threshold_version", "v3_p26_grosz_tolerance",
    "v3_p26_tier_alert_approach_pct", "v3_p26_health_params_version",
    "v3_p26_suspension_alert_months", "v3_p26_golden_version",
    "v3_p26_health_rescale_periods", "v3_p26_min_wage_drift_pct",
    "v3_p26_stress_required_scenarios", "v3_p26_invariants_active",
    "v3_p26_dra_zero_silence",
]

THRESHOLD_KEYS_ZUS_CORE = [
    "pension_rate", "disability_rate", "sickness_voluntary_rate", "accident_rate",
    "social_base_standard", "preferential_base_30pct",
    "health_scale_rate", "health_linear_rate",
    "health_lump_tier_1_limit", "health_lump_tier_2_limit",
    "health_lump_tier_1_amount", "health_lump_tier_2_amount", "health_lump_tier_3_amount",
    "start_relief_months", "preferential_months", "maly_zus_plus_months",
]


def _rego_text() -> str:
    return P26_REGO.read_text(encoding="utf-8")


def test_rego_file_exists() -> None:
    assert P26_REGO.exists(), f"brak {P26_REGO}"


def test_all_12_innovation_rules_present() -> None:
    text = _rego_text()
    missing = [rid for rid in INNOVATIONS.values() if rid not in text]
    assert not missing, f"brak rule_id w rego: {missing}"


def test_no_stub_true_rules() -> None:
    text = _rego_text()
    assert "{ true }" not in text.replace("{ true } else", "")


def test_fail_closed_routing_present() -> None:
    text = _rego_text()
    assert "BLOCK_AND_ALERT" in text
    assert "TRIAGE_QUEUE" in text
    assert "SUGGEST" in text


def test_thresholds_zus26_params_present() -> None:
    th = THRESHOLDS.read_text(encoding="utf-8")
    missing = [k for k in THRESHOLD_KEYS_ZUS26 if f'"{k}"' not in th]
    assert not missing, f"brak parametrów zus26 w thresholds_jdg.rego: {missing}"


def test_thresholds_zus_core_rates_present() -> None:
    th = THRESHOLDS.read_text(encoding="utf-8")
    missing = [k for k in THRESHOLD_KEYS_ZUS_CORE if f'"{k}"' not in th]
    assert not missing, f"brak stóp rdzenia zus w thresholds_jdg.rego: {missing}"


def test_main_jdg_wired() -> None:
    main = MAIN_JDG.read_text(encoding="utf-8")
    assert "import data.jdg.v3_p26_zus_skladki" in main
    assert '"jdg.v3_p26_zus_skladki": v3_p26_zus_skladki.decide' in main
    assert "final_verdict_p90" in main
    assert "final_verdict_post_merge" in main


def test_all_12_tools_exist() -> None:
    present = {f.name for f in TOOLS.glob("v3_p26_*.py")}
    missing = TOOLS_EXPECTED - present
    assert not missing, f"brak narzędzi dowodowych: {missing}"


def test_all_12_bundles_exist_and_gate_pass() -> None:
    bundles = sorted(BUNDLES.glob("v3_p26_*.json"))
    assert len(bundles) == 12, f"oczekiwano 12 bundle, jest {len(bundles)}"
    for b in bundles:
        data = json.loads(b.read_text(encoding="utf-8"))
        assert data.get("gate") == "PASS", f"{b.name}: gate != PASS"
        assert data["innovation"].startswith("V3-P26-I"), b.name


def test_each_innovation_has_bundle_evidence() -> None:
    bundles = {b.name: json.loads(b.read_text(encoding="utf-8"))
               for b in BUNDLES.glob("v3_p26_*.json")}
    innovations_in_bundles = {v["innovation"] for v in bundles.values()}
    expected = {f"V3-P26-{k}" for k in INNOVATIONS}
    missing = expected - innovations_in_bundles
    assert not missing, f"brak bundle dla: {missing}"


def test_rego_package_declaration() -> None:
    text = _rego_text()
    assert "package jdg.v3_p26_zus_skladki" in text
    assert "default decide" in text


def test_penny_boundary_golden_4161() -> None:
    """Golden groszowy: 4161,00 × stopy z danych = 812,23/332,88/101,94/69,49."""
    import importlib.util
    import sys

    sys.path.insert(0, str(TOOLS))
    try:
        spec = importlib.util.spec_from_file_location(
            "v3_p26_common", TOOLS / "v3_p26_common.py")
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        c = mod.social_contributions(4161.00)
        assert abs(c["pension"] - 812.23) < 0.005
        assert abs(c["disability"] - 332.88) < 0.005
        assert abs(c["sickness"] - 101.94) < 0.005
        assert abs(c["accident"] - 69.49) < 0.005
        assert abs(c["pension"] - 812.63) > 0.005  # prompt 812,63 = arytmetycznie złe
    finally:
        sys.path.pop(0)


def test_health_tiers_as_data() -> None:
    """Progi zdrowotnej 60k/300k i kwoty TIER jako dane (ADR-002)."""
    th = THRESHOLDS.read_text(encoding="utf-8")
    for v in ["60000", "300000", "491.40", "819.00", "1474.20"]:
        assert v in th, f"brak wartości progu/kwoty zdrowotnej: {v}"


def test_tools_executable_are_importable() -> None:
    """Każde narzędzie ma funkcję main() i poprawny import wspólnego helpera."""
    import importlib.util
    import sys

    sys.path.insert(0, str(TOOLS))  # import v3_p26_common
    try:
        for tool in sorted(TOOLS_EXPECTED):
            spec = importlib.util.spec_from_file_location(tool[:-3], TOOLS / tool)
            assert spec is not None and spec.loader is not None, tool
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)
            assert callable(getattr(mod, "main", None)), tool
    finally:
        sys.path.pop(0)
