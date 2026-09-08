# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P33 (WARSTWA AI ENTERPRISE — NEURAL MESH, LLM BRIDGE I
HUMAN-IN-THE-LOOP) — kampania V3 FORTRESS.

Weryfikuje:
  * reguły OPA w rules/v3_p33_neural_mesh_ai_enterprise.rego (12 analiz I01-I12),
  * parametry-as-data w rules/thresholds_jdg.rego (blok v3_p33, ADR-002/P06, P05),
  * wiring w rules/main_jdg.rego (final_verdict_p97),
  * 12 narzędzi dowodowych tools/v3_p33_*.py i 12 bundli bundles/v3_p33_*.json,
  * spójność z legacy: narzędzia AI rdzenia z sekcji 6.1 promptu (istnienie),
    kontrakty P03/P04 (werdykt, invarianty), P07 (lifecycle), P10 (golden replay),
  * granice: sandbox read_only, k=5 mesh, budżet 1M tokenów / 500 PLN,
    percentyl 80, red-team min. 3 kategorie, rok PQ 2030.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"

P33_REGO = RULES / "v3_p33_neural_mesh_ai_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"

INNOVATIONS = {
    "I01": "jdg.v3_p33_neural_mesh_ai.ai_proposal_pipeline",
    "I02": "jdg.v3_p33_neural_mesh_ai.ai_sandbox_permissions",
    "I03": "jdg.v3_p33_neural_mesh_ai.legal_hallucination_guard",
    "I04": "jdg.v3_p33_neural_mesh_ai.prompt_audit_ledger",
    "I05": "jdg.v3_p33_neural_mesh_ai.red_team_prompt_suite",
    "I06": "jdg.v3_p33_neural_mesh_ai.trust_score_telemetry",
    "I07": "jdg.v3_p33_neural_mesh_ai.digital_twin_synthetic",
    "I08": "jdg.v3_p33_neural_mesh_ai.cost_governor",
    "I09": "jdg.v3_p33_neural_mesh_ai.explain_first_ui",
    "I10": "jdg.v3_p33_neural_mesh_ai.federated_privacy_guard",
    "I11": "jdg.v3_p33_neural_mesh_ai.quantum_safe_plan",
    "I12": "jdg.v3_p33_neural_mesh_ai.ai_triage_needs_advice",
}

ANALYSES = [
    "ai_proposal_pipeline", "ai_sandbox_permissions", "legal_hallucination_guard",
    "prompt_audit_ledger", "red_team_prompt_suite", "trust_score_telemetry",
    "digital_twin_synthetic", "cost_governor", "explain_first_ui",
    "federated_privacy_guard", "quantum_safe_plan", "ai_triage_needs_advice",
]

TOOLS_EXPECTED = {
    "v3_p33_ai_proposal_pipeline.py", "v3_p33_ai_sandbox_permissions.py",
    "v3_p33_legal_hallucination_guard.py", "v3_p33_prompt_audit_ledger.py",
    "v3_p33_red_team_prompt_suite.py", "v3_p33_trust_score_telemetry.py",
    "v3_p33_digital_twin_synthetic.py", "v3_p33_cost_governor.py",
    "v3_p33_explain_first_ui.py", "v3_p33_federated_privacy_guard.py",
    "v3_p33_quantum_safe_plan.py", "v3_p33_ai_triage_needs_advice.py",
}

# Narzędzia AI rdzenia z sekcji 6.1/6.2 promptu P33 (istnienie = dowód)
CORE_AI_TOOLS = [
    "llm_bridge.py", "ai_augmented_rule_generator.py", "judgment_predictor.py",
    "smt_z3_verification.py", "autonomous_tax_strategy.py",
    "adaptive_trust_score.py", "neural_mesh_innovations_auditor.py",
    "str_generator.py", "digital_twin_simulator.py", "chaos_engineering.py",
    "chaos_runner.py", "holographic_viz.py", "federated_tax_mesh.py",
    "blockchain_audit_trail.py", "quantum_safe_encryption.py",
    "self_healing_engine.py", "worm_storage.py",
]

THRESHOLD_KEYS_V3P33 = [
    "v3_p33_threshold_version", "legal_basis_version", "valid_from",
    "v3_p33_pipeline_stages", "v3_p33_ai_sandbox_mode",
    "v3_p33_isap_verification_required", "v3_p33_prompt_ledger_worm",
    "v3_p33_prompt_ledger_checksum_alg", "v3_p33_red_team_min_categories",
    "v3_p33_ai_gate_required", "v3_p33_twin_synthetic_only",
    "v3_p33_token_budget", "v3_p33_cost_limit_pln",
    "v3_p33_explanation_required", "v3_p33_mesh_aggregates_only",
    "v3_p33_mesh_min_k", "v3_p33_mesh_aggregate_violation_max",
    "v3_p33_quantum_migration_year", "v3_p33_judgment_min_percentile",
]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def _thresholds_block() -> str:
    src = _read(THRESHOLDS)
    i = src.find("v3_p33 := {")
    assert i >= 0, "brak bloku v3_p33 w thresholds_jdg.rego"
    depth, end = 0, -1
    for j in range(i, len(src)):
        if src[j] == "{":
            depth += 1
        elif src[j] == "}":
            depth -= 1
            if depth == 0:
                end = j
                break
    return src[i:end]


# ── Pakiet V3-P33 ─────────────────────────────────────────────────────────────

def test_p33_rego_exists_and_structured():
    src = _read(P33_REGO)
    assert src, "brak rules/v3_p33_neural_mesh_ai_enterprise.rego"
    assert "package jdg.v3_p33_neural_mesh_ai" in src
    assert src.count("{") == src.count("}"), "nierównoważne nawiasy"
    rule_ids = re.findall(r'"rule_id": "([^"]+)"', src)
    assert len(rule_ids) == len(set(rule_ids)), "duplikaty rule_id w pakiecie P33"


def test_p33_all_12_innovations_present():
    src = _read(P33_REGO)
    for iid, rid in INNOVATIONS.items():
        assert rid in src, f"brak reguły {iid}: {rid}"


def test_p33_decide_chain_covers_all_analyses():
    src = _read(P33_REGO)
    chain = src.split("decide := fail_closed_decision")[1]
    for iid, rid in INNOVATIONS.items():
        rule_name = rid.rsplit(".", 1)[1]
        assert f"{rule_name}_decision" in chain, f"brak reguły {iid} w łańcuchu decide"
    assert chain.count("else :=") >= len(ANALYSES), "niekompletny else-chain decide"


def test_p33_fail_closed_no_silent_auto_post():
    src = _read(P33_REGO)
    assert "fail_closed_decision" in src
    assert "_snapshot_ok" in src
    assert '"_routing": "BLOCK_AND_ALERT"' in src
    assert "no_match" in src
    for m in re.finditer(r"\{\s*true\s*\}", src):
        prefix = src[:m.start()].rstrip().splitlines()[-1]
        assert "else" in prefix, (
            f"AP01: samodzielny stub bez else w P33 (kontekst: {prefix!r})")


def test_p33_public_rule_count():
    src = _read(P33_REGO)
    rule_ids = re.findall(
        r'"rule_id": "jdg\.v3_p33_neural_mesh_ai\.[a-z_]+"', src)
    assert len(rule_ids) >= 12, "za mało reguł publicznych w pakiecie"


# ── Parametry jako dane (ADR-002/P06) + okno temporalne (P05) ─────────────────

def test_v3p33_block_complete():
    block = _thresholds_block()
    for key in THRESHOLD_KEYS_V3P33:
        assert f'"{key}"' in block, f"brak klucza {key} v3_p33"
    assert '"valid_from"' in block, "brak okna temporalnego (P05)"


def test_v3p33_pipeline_stages_as_data():
    block = _thresholds_block()
    m = re.search(r'"v3_p33_pipeline_stages":\s*\[([^\]]*)\]', block)
    assert m, "brak v3_p33_pipeline_stages"
    stages = re.findall(r'"([a-z_0-9]+)"', m.group(1))
    assert stages == ["llm_output", "syntax_validate", "smt_z3_proof",
                      "golden_replay", "four_eyes", "shadow"], \
        f"ścieżka awansu AI zmieniona: {stages}"


def test_v3p33_sandbox_defaults():
    block = _thresholds_block()
    assert '"v3_p33_ai_sandbox_mode": "read_only"' in block, \
        "sandbox AI ma domyślnie read_only (I02)"
    assert '"v3_p33_mesh_min_k": 5' in block, "k-anonymity = 5 (I10)"
    assert '"v3_p33_token_budget": 1000000' in block, "budżet tokenów (I08)"
    assert '"v3_p33_cost_limit_pln": 500' in block, "limit kosztu PLN (I08)"
    assert '"v3_p33_judgment_min_percentile": 80' in block, "percentyl triage (I12)"
    assert '"v3_p33_quantum_migration_year": 2030' in block, "rok PQ (I11)"
    assert '"v3_p33_red_team_min_categories": 3' in block, "min. kategorie red-team (I05)"


# ── Wiring main_jdg ───────────────────────────────────────────────────────────

def test_main_jdg_wired_p97():
    src = _read(MAIN_JDG)
    assert "import data.jdg.v3_p33_neural_mesh_ai as v3_p33_neural_mesh_ai" in src
    assert '"jdg.v3_p33_neural_mesh_ai": v3_p33_neural_mesh_ai.decide' in src
    assert "final_verdict_p97 = safe_merge(final_verdict_p96" in src
    assert "final_verdict_post_merge = safe_merge(" in src
    assert "final_verdict_p97\n)" in src or "safe_merge(final_verdict_p97," in src


# ── Spójność z legacy (narzędzia rdzenia, kontrakty P03/P04/P07/P10) ──────────

def test_p33_threshold_version_consistency():
    rego = _read(P33_REGO)
    assert "data.jdg.thresholds.v3_p33" in rego, \
        "pakiet P33 nie podpięty pod snapshot progów"
    assert "v3_p33_threshold_version" in rego, \
        "brak odczytu threshold_version w pakiecie P33"


def test_legacy_contracts_honored():
    src = _read(P33_REGO)
    assert "SHADOW" in src or "shadow" in src      # kontrakt P07 (lifecycle)
    assert "golden replay" in src or "golden_replay" in src  # kontrakt P10
    assert "NEEDS_ADVICE" in src or "TRIAGE" in src  # fail-closed P04
    assert "AUTO_POST" in src                       # cel nadrzędny (AI nie AUTO_POST)


def test_core_ai_tools_exist():
    missing = [t for t in CORE_AI_TOOLS if not (TOOLS / t).exists()]
    assert not missing, f"brak narzędzi AI rdzenia: {missing}"


# ── Narzędzia dowodowe i bundle ───────────────────────────────────────────────

def test_p33_tools_present():
    for name in sorted(TOOLS_EXPECTED):
        assert (TOOLS / name).exists(), f"brak tools/{name}"


def test_p33_bundles_all_pass():
    for name in sorted(TOOLS_EXPECTED):
        bundle = BUNDLES / (name.replace(".py", ".json"))
        assert bundle.exists(), f"brak bundles/{bundle.name}"
        data = _read(bundle)
        assert '"gate": "PASS"' in data, f"gate FAIL: {bundle.name}"


def test_p33_bundle_innovations_match_tools():
    for name in sorted(TOOLS_EXPECTED):
        bpath = BUNDLES / (name.replace(".py", ".json"))
        data = json.loads(_read(bpath))
        iid = data["innovation"]
        assert re.fullmatch(r"V3-P33-I\d{2}", iid), f"błędny ID innowacji: {iid}"
        assert iid in _read(P33_REGO), f"{iid} nie ma reguły w pakiecie"
