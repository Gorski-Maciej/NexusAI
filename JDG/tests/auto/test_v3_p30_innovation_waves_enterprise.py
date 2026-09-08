# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P30 (FALE INNOWACJI — 24 GATE'Y RAPORTÓW R01-R24)
— kampania V3 FORTRESS.

Weryfikuje:
  * reguły OPA w rules/v3_p30_innovation_waves_enterprise.rego (12 innowacji I01-I12),
  * parametry-as-data w rules/thresholds_jdg.rego (blok v3_p30, ADR-002/P06, P05),
  * wiring w rules/main_jdg.rego (final_verdict_p94),
  * 12 narzędzi dowodowych tools/v3_p30_*.py i 12 bundli bundles/v3_p30_*.json,
  * spójność z legacy: 24 gate'y raportów R01-R24 (istnienie), kontrakt P29
    (bramki jakości), P08 (Law Radar), P10 (Golden Oracle),
  * granice: fałszywe DONE, adopt-rate 60%, budżet 20 reguł, 4-eyes dla krytycznych.
"""
from __future__ import annotations

import re
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"

P30_REGO = RULES / "v3_p30_innovation_waves_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"

INNOVATIONS = {
    "I01": "jdg.v3_p30_innovation_waves.deployment_registry",
    "I02": "jdg.v3_p30_innovation_waves.adopt_rate_dashboard",
    "I03": "jdg.v3_p30_innovation_waves.semantic_deployment_diff",
    "I04": "jdg.v3_p30_innovation_waves.v4_selection_contract",
    "I05": "jdg.v3_p30_innovation_waves.recommendation_pr_traceability",
    "I06": "jdg.v3_p30_innovation_waves.facade_wind_down",
    "I07": "jdg.v3_p30_innovation_waves.recommendation_risk_triage",
    "I08": "jdg.v3_p30_innovation_waves.golden_replay",
    "I09": "jdg.v3_p30_innovation_waves.deployment_budget",
    "I10": "jdg.v3_p30_innovation_waves.data_driven_changelog",
    "I11": "jdg.v3_p30_innovation_waves.conflicting_deployment_detector",
    "I12": "jdg.v3_p30_innovation_waves.law_radar_loop_closure",
}

ANALYSES = [
    "deployment_registry", "adopt_rate_dashboard", "semantic_deployment_diff",
    "v4_selection_contract", "recommendation_pr_traceability",
    "facade_wind_down", "recommendation_risk_triage", "golden_replay",
    "deployment_budget", "data_driven_changelog",
    "conflicting_deployment_detector", "law_radar_loop_closure",
]

TOOLS_EXPECTED = {
    "v3_p30_deployment_registry.py", "v3_p30_adopt_rate.py",
    "v3_p30_semantic_diff.py", "v3_p30_v4_selection.py",
    "v3_p30_pr_traceability.py", "v3_p30_facade_winddown.py",
    "v3_p30_risk_triage.py", "v3_p30_golden_replay.py",
    "v3_p30_deployment_budget.py", "v3_p30_changelog.py",
    "v3_p30_conflict_detector.py", "v3_p30_law_radar_loop.py",
}

THRESHOLD_KEYS_V3P30 = [
    "v3_p30_threshold_version", "legal_basis_version", "valid_from",
    "v3_p30_adopt_rate_min_pct", "v3_p30_v4_high_roi_min",
    "v3_p30_max_rules_per_deployment", "v3_p30_registry_statuses",
    "v3_p30_risk_classes",
]

# 24 gate'y raportów R01-R24 z promptu P30 (istnienie = dowód)
GATES_R01_R24 = [
    "orchestrator_core_report01_gate.py",
    "vat_core_report02_gate.py",
    "vat_micro_report03_gate.py",
    "pit_core_report04_gate.py",
    "pit_enterprise_report05_gate.py",
    "zus_report06_gate.py",
    "kks_report07_gate.py",
    "ordynacja_obrona_report08_gate.py",
    "ksiegowosc_report09_gate.py",
    "crossborder_innovations_report10_gate.py",
    "pcc_lokalne_akcyza_report11_gate.py",
    "ryczalt_cykl_zycia_report12_gate.py",
    "hyper_konteksty_report13_gate.py",
    "rodo_aml_bdo_innovations_report14_gate.py",
    "ksef_jpk_v3_gate.py",
    "opa_system_report16_gate.py",
    "system_opa_innovations_report16_gate.py",
    "enterprise_ai_report17_gate.py",
    "enterprise_ai_neural_report18_gate.py",
    "tools_system_report18_gate.py",
    "automatyzacja_ksiegowosci_report19_gate.py",
    "system_opa_control_plane_report20_gate.py",
    "native_rego_report21_gate.py",
    "bundle_api_report22_gate.py",
    "policies_mirror_report22_gate.py",
    "documentation_report23_gate.py",
    "forteca_report24_gate.py",
    "legal_twin_report24_gate.py",
    "policies_report24_gate.py",
    "pytest_report20_gate.py",
]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


# ── Pakiet V3-P30 ─────────────────────────────────────────────────────────────

def test_p30_rego_exists_and_structured():
    src = _read(P30_REGO)
    assert src, "brak rules/v3_p30_innovation_waves_enterprise.rego"
    assert "package jdg.v3_p30_innovation_waves" in src
    assert src.count("{") == src.count("}"), "nierównoważne nawiasy"
    rule_ids = re.findall(r'"rule_id": "([^"]+)"', src)
    assert len(rule_ids) == len(set(rule_ids)), "duplikaty rule_id w pakiecie P30"


def test_p30_all_12_innovations_present():
    src = _read(P30_REGO)
    for iid, rid in INNOVATIONS.items():
        assert rid in src, f"brak reguły {iid}: {rid}"


def test_p30_decide_chain_covers_all_analyses():
    src = _read(P30_REGO)
    chain = src.split("decide := fail_closed_decision")[1]
    for analysis in ANALYSES:
        assert analysis in chain or analysis in src, f"brak analizy {analysis}"
    assert chain.count("else :=") >= len(ANALYSES), "niekompletny else-chain decide"


def test_p30_fail_closed_no_silent_auto_post():
    src = _read(P30_REGO)
    assert "fail_closed_decision" in src
    assert "_snapshot_ok" in src
    assert '\"_routing\": \"BLOCK_AND_ALERT\"' in src
    assert "no_match" in src
    for m in re.finditer(r"\{\s*true\s*\}", src):
        prefix = src[:m.start()].rstrip().splitlines()[-1]
        assert "else" in prefix, (
            f"AP01: samodzielny stub bez else w P30 (kontekst: {prefix!r})")


# ── Parametry jako dane (ADR-002/P06) + okno temporalne (P05) ─────────────────

def test_v3p30_block_complete():
    src = _read(THRESHOLDS)
    assert "v3_p30 := {" in src
    i = src.find("v3_p30 := {")
    depth, end = 0, -1
    for j in range(i, len(src)):
        if src[j] == "{":
            depth += 1
        elif src[j] == "}":
            depth -= 1
            if depth == 0:
                end = j
                break
    block = src[i:end]
    for key in THRESHOLD_KEYS_V3P30:
        assert f'"{key}"' in block, f"brak klucza {key} w v3_p30"
    assert '"valid_from"' in block, "brak okna temporalnego (P05)"


# ── Wiring main_jdg ───────────────────────────────────────────────────────────

def test_main_jdg_wired_p94():
    src = _read(MAIN_JDG)
    assert "import data.jdg.v3_p30_innovation_waves as v3_p30_innovation_waves" in src
    assert '"jdg.v3_p30_innovation_waves": v3_p30_innovation_waves.decide' in src
    assert "final_verdict_p94 = safe_merge(final_verdict_p93" in src
    assert "final_verdict_post_merge = safe_merge(" in src
    assert "final_verdict_p94\n)" in src or "safe_merge(final_verdict_p94," in src


# ── Spójność z legacy (24 gate'y R01-R24, kontrakty P29/P08/P10) ─────────────

def test_report_gates_exist():
    missing = [g for g in GATES_R01_R24 if not (TOOLS / g).exists()]
    assert not missing, f"brak gate'ów raportów: {missing}"


def test_legacy_contracts_honored():
    src = _read(P30_REGO)
    assert "golden_replay" in src          # P10
    assert "law_radar" in src              # P08
    assert "deployment_registry" in src    # kanon P00


def test_p30_public_rule_count():
    src = _read(P30_REGO)
    rule_ids = re.findall(r'"rule_id": "jdg\.v3_p30_innovation_waves\.[a-z_]+"', src)
    assert len(rule_ids) >= 12, "za mało reguł publicznych w pakiecie"


# ── Narzędzia dowodowe i bundle ───────────────────────────────────────────────

def test_p30_tools_present():
    for name in TOOLS_EXPECTED:
        assert (TOOLS / name).exists(), f"brak tools/{name}"


def test_p30_bundles_all_pass():
    for name in TOOLS_EXPECTED:
        bundle = BUNDLES / (name.replace(".py", ".json"))
        assert bundle.exists(), f"brak bundles/{bundle.name}"
        data = _read(bundle)
        assert '"gate": "PASS"' in data, f"gate FAIL: {bundle.name}"


# ── Granice progowe (merge-blocking) ──────────────────────────────────────────

def test_adopt_rate_threshold():
    thresholds = _read(THRESHOLDS)
    assert '"v3_p30_adopt_rate_min_pct": 60' in thresholds


def test_deployment_budget_limit():
    thresholds = _read(THRESHOLDS)
    assert '"v3_p30_max_rules_per_deployment": 20' in thresholds


def test_registry_statuses_and_risk_classes():
    thresholds = _read(THRESHOLDS)
    assert '"v3_p30_registry_statuses"' in thresholds
    assert '"v3_p30_risk_classes"' in thresholds


def test_fake_done_probes():
    src = _read(P30_REGO)
    assert "_fake_done" in src
    assert "test_green" in src
    assert "artifact" in src