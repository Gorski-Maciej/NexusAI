# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P19 (PCC / LOKALNE / BDO-CBAM ENTERPRISE) — kampania V3 FORTRESS.

Weryfikuje:
  * reguły OPA w rules/v3_p19_pcc_akcyza_bdo_enterprise.rego (12 innowacji I01-I12),
  * parametry-as-data w rules/thresholds_jdg.rego (ADR-002),
  * 12 narzędzi dowodowych tools/v3_p19_*.py i 12 bundle bundles/v3_p19_*.json,
  * wiring w rules/main_jdg.rego (final_verdict_p87).
"""
from __future__ import annotations

import json
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"

P19_REGO = RULES / "v3_p19_pcc_akcyza_bdo_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"

INNOVATIONS = {
    "I01": "jdg.v3_p19_pcc_akcyza_bdo.pcc_matrix",
    "I02": "jdg.v3_p19_pcc_akcyza_bdo.gmina_rates_validator",
    "I03": "jdg.v3_p19_pcc_akcyza_bdo.mpp_pcc_exclusion_gate",
    "I04": "jdg.v3_p19_pcc_akcyza_bdo.local_tax_calendar_pack",
    "I05": "jdg.v3_p19_pcc_akcyza_bdo.bdo_qualifier",
    "I06": "jdg.v3_p19_pcc_akcyza_bdo.ewc_code_library",
    "I07": "jdg.v3_p19_pcc_akcyza_bdo.waste_fee_calculator",
    "I08": "jdg.v3_p19_pcc_akcyza_bdo.cbam_architectural_decision",
    "I09": "jdg.v3_p19_pcc_akcyza_bdo.pcc_golden_set",
    "I10": "jdg.v3_p19_pcc_akcyza_bdo.local_tax_invariants",
    "I11": "jdg.v3_p19_pcc_akcyza_bdo.instalment_reminder",
    "I12": "jdg.v3_p19_pcc_akcyza_bdo.explanation_pack",
}

TOOLS_EXPECTED = {
    "v3_p19_pcc_matrix.py", "v3_p19_gmina_rates_validator.py",
    "v3_p19_mpp_pcc_exclusion.py", "v3_p19_local_tax_calendar.py",
    "v3_p19_bdo_qualifier.py", "v3_p19_ewc_library.py",
    "v3_p19_waste_fee.py", "v3_p19_cbam_monitor.py",
    "v3_p19_golden_set.py", "v3_p19_invariants.py",
    "v3_p19_instalment_reminder.py", "v3_p19_explanation_pack.py",
}

THRESHOLD_KEYS = [
    "v3_p19_threshold_version", "v3_p19_property_installments",
    "v3_p19_transport_due", "v3_p19_zero_silence_escalation_days",
    "v3_p19_statutory_limit_check", "v3_p19_mpp_pcc_exclusion",
    "v3_p19_loan_exemption_limit", "v3_p19_bdo_waste_threshold_kg",
    "v3_p19_bdo_packaging_active", "v3_p19_weee_seller_registration",
    "v3_p19_waste_fee_per_kg_pln", "v3_p19_ewc_library_version",
    "v3_p19_cbam_monitor_active", "v3_p19_cbam_goods",
    "v3_p19_golden_version", "v3_p19_invariants_active",
    "v3_p19_bdo_report_due", "v3_p19_pcc3_form",
]


def _rego_text() -> str:
    return P19_REGO.read_text(encoding="utf-8")


def test_rego_file_exists() -> None:
    assert P19_REGO.exists(), f"brak {P19_REGO}"


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
    assert "BLOCK_AND_ALERT" in text
    assert "TRIAGE_QUEUE" in text
    assert "SUGGEST" in text or "no_auto_post" in text
    assert "default decide" in text


def test_thresholds_params_present() -> None:
    th = THRESHOLDS.read_text(encoding="utf-8")
    missing = [k for k in THRESHOLD_KEYS if f'"{k}"' not in th]
    assert not missing, f"brak parametrów P19 w thresholds_jdg.rego: {missing}"


def test_legal_limits_reused_as_data() -> None:
    th = THRESHOLDS.read_text(encoding="utf-8")
    for k in ("pcc_sale_rate", "pcc_loan_rate", "pcc_company_rate",
              "land_business_rate", "building_business_rate"):
        assert f'"{k}"' in th, f"brak reużywanego parametru {k} (ADR-002)"


def test_main_jdg_wired() -> None:
    main = MAIN_JDG.read_text(encoding="utf-8")
    assert "import data.jdg.v3_p19_pcc_akcyza_bdo" in main
    assert '"jdg.v3_p19_pcc_akcyza_bdo": v3_p19_pcc_akcyza_bdo.decide' in main
    assert "final_verdict_p87" in main
    assert "final_verdict_post_merge" in main


def test_all_12_tools_exist() -> None:
    present = {f.name for f in TOOLS.glob("v3_p19_*.py")}
    missing = TOOLS_EXPECTED - present
    assert not missing, f"brak narzędzi dowodowych: {missing}"


def test_all_12_bundles_exist_and_gate_pass() -> None:
    bundles = sorted(BUNDLES.glob("v3_p19_*.json"))
    assert len(bundles) == 12, f"oczekiwano 12 bundle, jest {len(bundles)}"
    for b in bundles:
        data = json.loads(b.read_text(encoding="utf-8"))
        assert data.get("gate") == "PASS", f"{b.name}: gate != PASS"
        assert data["innovation"].startswith("V3-P19-I"), b.name


def test_each_innovation_has_bundle_evidence() -> None:
    bundles = {b.name: json.loads(b.read_text(encoding="utf-8"))
               for b in BUNDLES.glob("v3_p19_*.json")}
    innovations_in_bundles = {v["innovation"] for v in bundles.values()}
    expected = {f"V3-P19-{k}" for k in INNOVATIONS}
    missing = expected - innovations_in_bundles
    assert not missing, f"brak bundle dla: {missing}"


def test_rego_package_declaration() -> None:
    text = _rego_text()
    assert "package jdg.v3_p19_pcc_akcyza_bdo" in text
    assert "default decide" in text


def test_tools_executable_are_importable() -> None:
    """Każde narzędzie ma funkcję main() i poprawny import wspólnego helpera."""
    import importlib.util
    import sys

    sys.path.insert(0, str(TOOLS))  # import v3_p19_common
    try:
        for tool in TOOLS_EXPECTED:
            spec = importlib.util.spec_from_file_location(tool[:-3], TOOLS / tool)
            assert spec is not None and spec.loader is not None, tool
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)
            assert callable(getattr(mod, "main", None)), tool
    finally:
        sys.path.pop(0)
