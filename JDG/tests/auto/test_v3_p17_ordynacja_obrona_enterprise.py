# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P17 (ORDYNACJA OBRONA ENTERPRISE) — kampania V3 FORTRESS.

Weryfikuje:
  * reguły OPA w rules/v3_p17_ordynacja_obrona_enterprise.rego (12 innowacji I01-I12),
  * parametry-as-data w rules/thresholds_jdg.rego (ADR-002),
  * 12 narzędzi dowodowych tools/v3_p17_*.py i 12 bundle bundles/v3_p17_*.json,
  * wiring w rules/main_jdg.rego (final_verdict_p85).
"""
from __future__ import annotations

import json
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"

P17_REGO = RULES / "v3_p17_ordynacja_obrona_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"

INNOVATIONS = {
    "I01": "jdg.v3_p17_ordynacja_obrona.interest_precision_engine",
    "I02": "jdg.v3_p17_ordynacja_obrona.limitation_sentinel",
    "I03": "jdg.v3_p17_ordynacja_obrona.gaar_shield_framework",
    "I04": "jdg.v3_p17_ordynacja_obrona.procedural_deadline_constitution",
    "I05": "jdg.v3_p17_ordynacja_obrona.active_correction_advisor",
    "I06": "jdg.v3_p17_ordynacja_obrona.aud_benefit_tracker",
    "I07": "jdg.v3_p17_ordynacja_obrona.ruling_autodrafter_4eyes",
    "I08": "jdg.v3_p17_ordynacja_obrona.proceeding_timeline",
    "I09": "jdg.v3_p17_ordynacja_obrona.defense_packet_generator",
    "I10": "jdg.v3_p17_ordynacja_obrona.interpretation_library",
    "I11": "jdg.v3_p17_ordynacja_obrona.ord_invariants_pack",
    "I12": "jdg.v3_p17_ordynacja_obrona.litigation_stress_lab",
}

TOOLS_EXPECTED = {
    "v3_p17_interest_precision_engine.py", "v3_p17_limitation_sentinel.py",
    "v3_p17_gaar_shield.py", "v3_p17_deadline_constitution.py",
    "v3_p17_correction_advisor.py", "v3_p17_aud_tracker.py",
    "v3_p17_ruling_4eyes.py", "v3_p17_proceeding_timeline.py",
    "v3_p17_defense_packet.py", "v3_p17_interpretation_library.py",
    "v3_p17_ord_invariants.py", "v3_p17_litigation_stress_lab.py",
}

THRESHOLD_KEYS = [
    "v3_p17_threshold_version", "v3_p17_interest_rate_annual",
    "v3_p17_interest_rates_valid_from", "v3_p17_interest_capitalization",
    "v3_p17_statute_years", "v3_p17_statute_end_rule",
    "v3_p17_limitation_alert_days", "v3_p17_suspension_max_events",
    "v3_p17_gaar_mae_threshold_pln", "v3_p17_deadline_statement_days",
    "v3_p17_appeal_days", "v3_p17_wsa_days", "v3_p17_zero_silence_escalation_days",
    "v3_p17_aud_reduced_rate_pct", "v3_p17_aud_full_rate_pct",
    "v3_p17_ruling_4eyes_required", "v3_p17_interpretation_law_change_sentinel",
    "v3_p17_invariants_active", "v3_p17_stress_scenarios",
]


def _rego_text() -> str:
    return P17_REGO.read_text(encoding="utf-8")


def test_rego_file_exists() -> None:
    assert P17_REGO.exists(), f"brak {P17_REGO}"


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
    assert not missing, f"brak parametrów P17 w thresholds_jdg.rego: {missing}"


def test_main_jdg_wired() -> None:
    main = MAIN_JDG.read_text(encoding="utf-8")
    assert "import data.jdg.v3_p17_ordynacja_obrona" in main
    assert '"jdg.v3_p17_ordynacja_obrona": v3_p17_ordynacja_obrona.decide' in main
    assert "final_verdict_p85" in main
    assert "final_verdict_post_merge" in main


def test_all_12_tools_exist() -> None:
    present = {f.name for f in TOOLS.glob("v3_p17_*.py")}
    missing = TOOLS_EXPECTED - present
    assert not missing, f"brak narzędzi dowodowych: {missing}"


def test_all_12_bundles_exist_and_gate_pass() -> None:
    bundles = sorted(BUNDLES.glob("v3_p17_*.json"))
    assert len(bundles) == 12, f"oczekiwano 12 bundle, jest {len(bundles)}"
    for b in bundles:
        data = json.loads(b.read_text(encoding="utf-8"))
        assert data.get("gate") == "PASS", f"{b.name}: gate != PASS"
        assert data["innovation"].startswith("V3-P17-I"), b.name


def test_each_innovation_has_bundle_evidence() -> None:
    bundles = {b.name: json.loads(b.read_text(encoding="utf-8"))
               for b in BUNDLES.glob("v3_p17_*.json")}
    innovations_in_bundles = {v["innovation"] for v in bundles.values()}
    expected = {f"V3-P17-{k}" for k in INNOVATIONS}
    missing = expected - innovations_in_bundles
    assert not missing, f"brak bundle dla: {missing}"


def test_rego_package_declaration() -> None:
    text = _rego_text()
    assert "package jdg.v3_p17_ordynacja_obrona" in text
    assert "default decide" in text


def test_tools_executable_are_importable() -> None:
    """Każde narzędzie ma funkcję main() i poprawny import wspólnego helpera."""
    import importlib.util
    import sys

    sys.path.insert(0, str(TOOLS))  # import v3_p17_common
    try:
        for tool in TOOLS_EXPECTED:
            spec = importlib.util.spec_from_file_location(tool[:-3], TOOLS / tool)
            assert spec is not None and spec.loader is not None, tool
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)
            assert callable(getattr(mod, "main", None)), tool
    finally:
        sys.path.pop(0)
