# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P16 (KSeF/JPK ENTERPRISE) — kampania V3 FORTRESS.

Weryfikuje:
  * reguły OPA w rules/v3_p16_ksef_jpk_enterprise.rego (12 innowacji I01-I12),
  * parametry-as-data w rules/thresholds_jdg.rego (ADR-002),
  * 12 narzędzi dowodowych tools/v3_p16_*.py i 12 bundle bundles/v3_p16_*.json,
  * wiring w rules/main_jdg.rego (final_verdict_p84).
"""
from __future__ import annotations

import json
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"

P16_REGO = RULES / "v3_p16_ksef_jpk_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"

INNOVATIONS = {
    "I01": "jdg.v3_p16_ksef_jpk.ksef_session_orchestrator",
    "I02": "jdg.v3_p16_ksef_jpk.zero_loss_offline_queue",
    "I03": "jdg.v3_p16_ksef_jpk.upo_sentinel",
    "I04": "jdg.v3_p16_ksef_jpk.pre_send_firewall",
    "I05": "jdg.v3_p16_ksef_jpk.deadline_constitution",
    "I06": "jdg.v3_p16_ksef_jpk.jpk_field_contract",
    "I07": "jdg.v3_p16_ksef_jpk.idempotent_corrections",
    "I08": "jdg.v3_p16_ksef_jpk.sandbox_ci_rig",
    "I09": "jdg.v3_p16_ksef_jpk.chaos_ksef_drill",
    "I10": "jdg.v3_p16_ksef_jpk.edelivery_chain",
    "I11": "jdg.v3_p16_ksef_jpk.penalty_exposure_monitor",
    "I12": "jdg.v3_p16_ksef_jpk.ksef_jpk_golden_set",
}

TOOLS_EXPECTED = {
    "v3_p16_session_orchestrator.py", "v3_p16_zero_loss_queue.py",
    "v3_p16_upo_sentinel.py", "v3_p16_pre_send_firewall.py",
    "v3_p16_deadline_constitution.py", "v3_p16_jpk_field_contract.py",
    "v3_p16_idempotent_corrections.py", "v3_p16_sandbox_ci_rig.py",
    "v3_p16_chaos_ksef_drill.py", "v3_p16_edelivery_chain.py",
    "v3_p16_penalty_exposure.py", "v3_p16_golden_set.py",
}

THRESHOLD_KEYS = [
    "v3_p16_threshold_version", "v3_p16_session_max_retries",
    "v3_p16_offline_window_hours", "v3_p16_wal_required",
    "v3_p16_offline_rpo_hours", "v3_p16_offline_rto_hours",
    "v3_p16_upo_timeout_hours", "v3_p16_upo_escalation_hours",
    "v3_p16_edelivery_status_timeout_hours", "v3_p16_sandbox_cadence_days",
    "v3_p16_chaos_drill_hours", "v3_p16_golden_set_version",
    "v3_p16_deadlines",
]


def _rego_text() -> str:
    return P16_REGO.read_text(encoding="utf-8")


def test_rego_file_exists() -> None:
    assert P16_REGO.exists(), f"brak {P16_REGO}"


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
    assert not missing, f"brak parametrów P16 w thresholds_jdg.rego: {missing}"


def test_main_jdg_wired() -> None:
    main = MAIN_JDG.read_text(encoding="utf-8")
    assert "import data.jdg.v3_p16_ksef_jpk" in main
    assert '"jdg.v3_p16_ksef_jpk": v3_p16_ksef_jpk.decide' in main
    assert "final_verdict_p84" in main
    assert "final_verdict_post_merge" in main


def test_all_12_tools_exist() -> None:
    present = {f.name for f in TOOLS.glob("v3_p16_*.py")}
    missing = TOOLS_EXPECTED - present
    assert not missing, f"brak narzędzi dowodowych: {missing}"


def test_all_12_bundles_exist_and_gate_pass() -> None:
    bundles = sorted(BUNDLES.glob("v3_p16_*.json"))
    assert len(bundles) == 12, f"oczekiwano 12 bundle, jest {len(bundles)}"
    for b in bundles:
        data = json.loads(b.read_text(encoding="utf-8"))
        assert data.get("gate") == "PASS", f"{b.name}: gate != PASS"
        assert data["innovation"].startswith("V3-P16-I"), b.name


def test_each_innovation_has_bundle_evidence() -> None:
    bundles = {b.name: json.loads(b.read_text(encoding="utf-8"))
               for b in BUNDLES.glob("v3_p16_*.json")}
    innovations_in_bundles = {v["innovation"] for v in bundles.values()}
    expected = {f"V3-P16-{k}" for k in INNOVATIONS}
    missing = expected - innovations_in_bundles
    assert not missing, f"brak bundle dla: {missing}"


def test_rego_package_declaration() -> None:
    text = _rego_text()
    assert "package jdg.v3_p16_ksef_jpk" in text
    assert "default decide" in text


def test_tools_executable_are_importable() -> None:
    """Każde narzędzie ma funkcję main() i poprawny import wspólnego helpera."""
    import importlib.util
    import sys

    sys.path.insert(0, str(TOOLS))  # import v3_p16_common
    try:
        for tool in TOOLS_EXPECTED:
            spec = importlib.util.spec_from_file_location(tool[:-3], TOOLS / tool)
            assert spec is not None and spec.loader is not None, tool
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)
            assert callable(getattr(mod, "main", None)), tool
    finally:
        sys.path.pop(0)
