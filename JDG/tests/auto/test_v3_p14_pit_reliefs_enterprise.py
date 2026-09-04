# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P14 (PIT ULGI / FORMY / OPTYMALIZACJA) — kampania V3 FORTRESS.

Weryfikuje:
  * reguły OPA w rules/v3_p14_pit_reliefs_enterprise.rego (innowacje I01-I12),
  * parametry-as-data w rules/thresholds_jdg.rego (ADR-002 — limity roczne
    v3_p14_relief_limits z valid_from, P05/P06),
  * 12 narzędzi dowodowych tools/v3_p14_*.py i 12 bundle bundles/v3_p14_*.json,
  * wiring w rules/main_jdg.rego (final_verdict_p83).
"""
from __future__ import annotations

import json
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"

P14_REGO = RULES / "v3_p14_pit_reliefs_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"

INNOVATIONS = {
    "I01": "jdg.v3_p14_pit_reliefs.reliefs_matrix_complete",
    "I02": "jdg.v3_p14_pit_reliefs.limit_as_data_engine",
    "I03": "jdg.v3_p14_pit_reliefs.nexus_ratio_auditor",
    "I04": "jdg.v3_p14_pit_reliefs.relief_order_optimizer",
    "I05": "jdg.v3_p14_pit_reliefs.form_changer_proactive",
    "I06": "jdg.v3_p14_pit_reliefs.form_simulator_12m",
    "I07": "jdg.v3_p14_pit_reliefs.loss_harvesting_planner",
    "I08": "jdg.v3_p14_pit_reliefs.relief_documentation_pack",
    "I09": "jdg.v3_p14_pit_reliefs.relief_expiry_sentinel",
    "I10": "jdg.v3_p14_pit_reliefs.relief_golden_set",
    "I11": "jdg.v3_p14_pit_reliefs.multi_relief_conflict_detector",
    "I12": "jdg.v3_p14_pit_reliefs.relief_explanation_engine",
}

TOOLS_EXPECTED = {
    "v3_p14_reliefs_matrix.py", "v3_p14_limits_as_data.py",
    "v3_p14_nexus_ratio.py", "v3_p14_relief_order.py",
    "v3_p14_form_changer.py", "v3_p14_form_simulator.py",
    "v3_p14_loss_harvesting.py", "v3_p14_doc_pack.py",
    "v3_p14_expiry_sentinel.py", "v3_p14_golden_set.py",
    "v3_p14_conflict_detector.py", "v3_p14_explanation.py",
}

THRESHOLD_KEYS = [
    "v3_p14_relief_limits", "v3_p14_threshold_version",
    "pit_relief_shared_limit", "pit_thermo_limit", "rehab_car_limit",
    "young_relief_max_age", "return_work_relief_years",
    "ip_box_nexus_full_ratio", "ip_box_nexus_partial_ratio",
    "robotization_relief_last_year", "relief_expiry_alert_months",
    "donation_limit_pct", "loss_carry_forward_years", "loss_carry_forward_max_pct",
    "scale_low_rate", "scale_high_rate", "scale_threshold", "tax_free_amount",
    "linear_rate", "ip_box_rate", "lump_sum_generic_rate",
]

RELIEF_LIMIT_IDS = ["young", "return_work", "family_4plus", "senior",
                    "thermo", "rehab_car", "internet"]


def _rego_text() -> str:
    return P14_REGO.read_text(encoding="utf-8")


def test_rego_file_exists() -> None:
    assert P14_REGO.exists(), f"brak {P14_REGO}"


def test_all_12_innovation_rules_present() -> None:
    text = _rego_text()
    missing = [rid for rid in INNOVATIONS.values() if rid not in text]
    assert not missing, f"brak rule_id w rego: {missing}"


def test_no_stub_true_rules() -> None:
    text = _rego_text()
    assert "{ true } else :=" not in text
    assert "{ true }" not in text.replace("{ true } else", "")


def test_fail_closed_routing_present() -> None:
    text = _rego_text()
    assert "NEEDS_ADVICE" in text
    assert "BLOCK_AND_ALERT" in text
    assert "TRIAGE_QUEUE" in text


def test_thresholds_params_present() -> None:
    th = THRESHOLDS.read_text(encoding="utf-8")
    missing = [k for k in THRESHOLD_KEYS if f'"{k}"' not in th]
    assert not missing, f"brak parametrów P14 w thresholds_jdg.rego: {missing}"


def test_relief_limits_are_versioned_data() -> None:
    th = THRESHOLDS.read_text(encoding="utf-8")
    assert '"v3_p14_relief_limits"' in th
    for rid in RELIEF_LIMIT_IDS:
        assert f'"{rid}":' in th, f"brak wpisu {rid} w v3_p14_relief_limits"
    assert "valid_from" in th, "limity roczne muszą mieć valid_from (P05/P06)"


def test_reliefs_catalog_in_rego() -> None:
    text = _rego_text()
    assert "reliefs_catalog" in text
    for rid in ["thermo", "rd_relief", "ip_box", "rehab_car", "young",
                "return_work", "donation"]:
        assert f'"{rid}"' in text, f"brak ulgi {rid} w katalogu rego"


def test_main_jdg_wired() -> None:
    main = MAIN_JDG.read_text(encoding="utf-8")
    assert "import data.jdg.v3_p14_pit_reliefs" in main
    assert '"jdg.v3_p14_pit_reliefs": v3_p14_pit_reliefs.decide' in main
    assert "final_verdict_p83" in main
    assert "final_verdict_post_merge" in main


def test_all_12_tools_exist() -> None:
    present = {f.name for f in TOOLS.glob("v3_p14_*.py")}
    missing = TOOLS_EXPECTED - present
    assert not missing, f"brak narzędzi dowodowych: {missing}"


def test_all_12_bundles_exist_and_gate_pass() -> None:
    bundles = sorted(BUNDLES.glob("v3_p14_*.json"))
    assert len(bundles) == 12, f"oczekiwano 12 bundle, jest {len(bundles)}"
    for b in bundles:
        data = json.loads(b.read_text(encoding="utf-8"))
        assert data.get("gate") == "PASS", f"{b.name}: gate != PASS"
        assert data["innovation"].startswith("V3-P14-I"), b.name


def test_each_innovation_has_bundle_evidence() -> None:
    bundles = {b.name: json.loads(b.read_text(encoding="utf-8"))
               for b in BUNDLES.glob("v3_p14_*.json")}
    innovations_in_bundles = {v["innovation"] for v in bundles.values()}
    expected = {f"V3-P14-{k}" for k in INNOVATIONS}
    missing = expected - innovations_in_bundles
    assert not missing, f"brak bundle dla: {missing}"


def test_rego_package_declaration() -> None:
    text = _rego_text()
    assert "package jdg.v3_p14_pit_reliefs" in text
    assert "default decide" in text
    assert "fail_closed_decision" in text


def test_activation_key_v3_p14_check() -> None:
    text = _rego_text()
    assert "v3_p14_check" in text
    assert "no_match" in text


def test_tools_executable_are_importable() -> None:
    """Każde narzędzie ma funkcję main() i poprawny import wspólnego helpera."""
    import importlib.util
    import sys

    sys.path.insert(0, str(TOOLS))  # import v3_p14_common
    try:
        for tool in TOOLS_EXPECTED:
            spec = importlib.util.spec_from_file_location(tool[:-3], TOOLS / tool)
            assert spec is not None and spec.loader is not None, tool
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)
            assert callable(getattr(mod, "main", None)), tool
    finally:
        sys.path.pop(0)
