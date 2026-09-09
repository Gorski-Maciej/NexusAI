# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P39 (TESTY I CI — NATYWNE REGO, PYTEST, GOLDEN, FUZZ I
BRAMKI BLOKUJĄCE) — kampania V3 FORTRESS.

Weryfikuje:
  * reguły OPA w rules/v3_p39_testy_ci_enterprise.rego (12 analiz I01-I12),
  * parametry-as-data w rules/thresholds_jdg.rego (blok v3_p39, ADR-002/P06, P05),
  * wiring w rules/main_jdg.rego (final_verdict_p103),
  * 12 narzędzi dowodowych tools/v3_p39_*.py i 12 bundli bundles/v3_p39_*.json,
  * kontrakt strategii testowej jako dane (bundles/v3_p39_test_strategy.json:
    piramida L1-L7, niezmienniki, kwarantanna flaków, pinowanie kontraktów,
    seed-replay, impact map, bramki merge),
  * spójność z rdzeniem: golden_verdicts (P10), eval_baseline (P37),
    benchmark gate (P37), workflow CI (jdg-quality.yml), coverage rdzeń
    (test_coverage_gate.py / COVERAGE_REPORT.md), kontrakty P34/P37/P10/P05/
    P29/P02/P33/P36.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"
TESTS = BASE / "tests"

P39_REGO = RULES / "v3_p39_testy_ci_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"
TEST_STRATEGY = BUNDLES / "v3_p39_test_strategy.json"
WORKFLOW = BASE / ".github" / "workflows" / "jdg-quality.yml"

INNOVATIONS = {
    "I01": "jdg.v3_p39_testy_ci.test_matrix",
    "I02": "jdg.v3_p39_testy_ci.golden_replay_gate",
    "I03": "jdg.v3_p39_testy_ci.temporal_pairs",
    "I04": "jdg.v3_p39_testy_ci.negative_first",
    "I05": "jdg.v3_p39_testy_ci.property_invariants",
    "I06": "jdg.v3_p39_testy_ci.mutation_testing",
    "I07": "jdg.v3_p39_testy_ci.flake_quarantine",
    "I08": "jdg.v3_p39_testy_ci.contract_pinning",
    "I09": "jdg.v3_p39_testy_ci.coverage_by_act",
    "I10": "jdg.v3_p39_testy_ci.performance_budget",
    "I11": "jdg.v3_p39_testy_ci.seed_replay",
    "I12": "jdg.v3_p39_testy_ci.impact_map",
}

ANALYSES = [
    "test_matrix", "golden_replay_gate", "temporal_pairs", "negative_first",
    "property_invariants", "mutation_testing", "flake_quarantine",
    "contract_pinning", "coverage_by_act", "performance_budget",
    "seed_replay", "impact_map",
]

TOOLS_EXPECTED = {
    "v3_p39_test_matrix.py", "v3_p39_golden_replay_gate.py",
    "v3_p39_temporal_pairs.py", "v3_p39_negative_first.py",
    "v3_p39_property_invariants.py", "v3_p39_mutation_testing.py",
    "v3_p39_flake_quarantine.py", "v3_p39_contract_pinning.py",
    "v3_p39_coverage_by_act.py", "v3_p39_performance_budget.py",
    "v3_p39_seed_replay.py", "v3_p39_impact_map.py",
}

THRESHOLD_KEYS_V3P39 = [
    "v3_p39_threshold_version", "legal_basis_version", "valid_from",
    "v3_p39_matrix_coverage_min_pct", "v3_p39_mutation_score_min_pct",
    "v3_p39_act_coverage_min_pct", "v3_p39_benchmark_regression_max_pct",
    "v3_p39_impact_map_max_stale_days",
]

CONTRACT_MENTIONS = ["P02", "P03", "P05", "P10", "P11", "P29", "P33", "P34", "P36", "P37", "P38", "P44"]

# Rdzeń z kampanii (istnienie = dowód; P39 rozszerza, nie duplikuje)
CORE_ARTIFACTS = [
    "tools/test_coverage_gate.py", "tools/test_rego_ci_auditor.py",
    "tools/coverage_95_plan.py", "COVERAGE_REPORT.md",
    ".github/workflows/jdg-quality.yml",
]
CORE_DATA = ["bundles/golden_verdicts.json", ".benchmarks/eval_baseline.json"]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def _thresholds_block() -> str:
    src = _read(THRESHOLDS)
    i = src.find("v3_p39 := {")
    assert i >= 0, "brak bloku v3_p39 w thresholds_jdg.rego"
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


# ── Pakiet V3-P39 ─────────────────────────────────────────────────────────────

def test_p39_rego_exists_and_structured():
    src = _read(P39_REGO)
    assert src, "brak rules/v3_p39_testy_ci_enterprise.rego"
    assert "package jdg.v3_p39_testy_ci" in src
    assert src.count("{") == src.count("}"), "nierównoważne nawiasy"
    rule_ids = re.findall(r'"rule_id": "([^"]+)"', src)
    assert len(rule_ids) == len(set(rule_ids)), "duplikaty rule_id w pakiecie P39"


def test_p39_all_12_innovations_present():
    src = _read(P39_REGO)
    for iid, rid in INNOVATIONS.items():
        assert rid in src, f"brak reguły {iid}: {rid}"


def test_p39_decide_chain_covers_all_analyses():
    src = _read(P39_REGO)
    chain = src.split("decide := fail_closed_decision")[1]
    for iid, rid in INNOVATIONS.items():
        rule_name = rid.rsplit(".", 1)[1]
        # test_matrix -> act_matrix (bez prefiksu test_ — kolizja z discovery OPA)
        if rule_name == "test_matrix":
            assert "act_matrix_decision" in chain, f"brak reguły {iid} w łańcuchu decide"
        else:
            assert f"{rule_name}_decision" in chain, f"brak reguły {iid} w łańcuchu decide"
    assert chain.count("else :=") >= len(ANALYSES), "niekompletny else-chain decide"


def test_p39_fail_closed_no_silent_auto_post():
    src = _read(P39_REGO)
    assert "fail_closed_decision" in src
    assert "_snapshot_ok" in src
    assert '"_routing": "BLOCK_AND_ALERT"' in src
    assert "no_match" in src
    for m in re.finditer(r"\{\s*true\s*\}", src):
        prefix = src[:m.start()].rstrip().splitlines()[-1]
        assert "else" in prefix, (
            f"AP01: samodzielny stub bez else w P39 (kontekst: {prefix!r})")


def test_p39_public_rule_count():
    src = _read(P39_REGO)
    rule_ids = re.findall(
        r'"rule_id": "jdg\.v3_p39_testy_ci\.[a-z_]+"', src)
    assert len(rule_ids) >= 12, "za mało reguł publicznych w pakiecie"


def test_p39_innovation_ids_in_header():
    src = _read(P39_REGO)
    for i in range(1, 13):
        assert f"V3-P39-I{i:02d}" in src, f"brak ID V3-P39-I{i:02d} w nagłówku pakietu"


def test_p39_no_test_prefix_rule_names():
    """Reguły decyzyjne nie mogą zaczynać się od test_ (kolizja z discovery
    testów OPA — reguła byłaby uruchamiana jako test)."""
    src = _read(P39_REGO)
    rule_names = re.findall(r"^([a-z_]+)_decision :=", src, re.M)
    for name in rule_names:
        assert not name.startswith("test"), (
            f"AP06: reguła {name}_decision koliduje z discovery testów OPA")


# ── Parametry jako dane (ADR-002/P06) + okno temporalne (P05) ─────────────────

def test_v3p39_block_complete():
    block = _thresholds_block()
    for key in THRESHOLD_KEYS_V3P39:
        assert f'"{key}"' in block, f"brak klucza {key} v3_p39"
    assert '"valid_from"' in block, "brak okna temporalnego (P05)"


def test_v3p39_governance_limits():
    block = _thresholds_block()
    assert '"v3_p39_mutation_score_min_pct": 85' in block, "czułość mutacyjna 85% (I06, spójna z P29/v3_17)"
    assert '"v3_p39_act_coverage_min_pct": 90' in block, "pokrycie per akt 90% (I09)"
    assert '"v3_p39_benchmark_regression_max_pct": 10' in block, "regresja benchmarku max 10% (I10, spójna z P37)"
    assert '"no_auto_post": true' in block, "fail-closed P04"


# ── Kontrakt strategii testowej jako dane ─────────────────────────────────────

def _strategy() -> dict:
    raw = _read(TEST_STRATEGY)
    assert raw, "brak bundles/v3_p39_test_strategy.json"
    return json.loads(raw)


def test_pyramid_complete():
    s = _strategy()
    levels = {lvl["level"] for lvl in s.get("test_pyramid", [])}
    assert levels == {"L1", "L2", "L3", "L4", "L5", "L6", "L7"}, \
        f"piramida niekompletna: {levels}"
    for lvl in s["test_pyramid"]:
        for key in ("scope", "runs", "threshold", "blocks_merge"):
            assert key in lvl, f"poziom {lvl['level']} bez pola {key}"


def test_pyramid_merge_gates():
    s = _strategy()
    gates = s.get("merge_gates", [])
    assert any("golden" in g for g in gates), "golden jako bramka merge (I02)"
    assert any("benchmark" in g for g in gates), "benchmark jako bramka merge (I10)"
    assert any("negatyw" in g for g in gates), "asercje negatywne jako bramka (I04)"


def test_invariants_pack_as_data():
    s = _strategy()
    inv = s.get("invariants_pack", [])
    assert len(inv) >= 4, "pakiet niezmienników pusty (I05 BLOCK)"


def test_quarantine_pinning_seed_impact_conventions():
    s = _strategy()
    fq = s.get("flake_quarantine", {})
    assert fq.get("separate_job") is True and fq.get("repair_deadline_days"), "kwarantanna z terminem (I07)"
    pin = s.get("contract_pinning", {})
    assert pin.get("verdict_schema_pinned") is True, "pin schematu werdyktu (I08)"
    assert pin.get("certificate_schema_pinned") is True, "pin schematu certyfikatu (I08)"
    sr = s.get("seed_replay", {})
    assert sr.get("seed_recorded") is True and sr.get("replay_on_failure") is True, "seed-replay (I11)"
    im = s.get("impact_map", {})
    assert im.get("source") == "P02_routing_registry", "impact map z routingu P02 (I12)"
    assert im.get("golden_always_runs") is True, "golden zawsze na PR (I12)"


# ── Wiring main_jdg ───────────────────────────────────────────────────────────

def test_main_jdg_wired_p103():
    src = _read(MAIN_JDG)
    assert "import data.jdg.v3_p39_testy_ci as v3_p39_testy_ci" in src
    assert '"jdg.v3_p39_testy_ci": v3_p39_testy_ci.decide' in src
    assert "final_verdict_p103 = safe_merge(final_verdict_p102" in src
    assert "final_verdict_post_merge = safe_merge(" in src
    assert "final_verdict_p103\n)" in src or "safe_merge(final_verdict_p103," in src


# ── Spójność z rdzeniem i kontraktami ─────────────────────────────────────────

def test_p39_threshold_version_consistency():
    rego = _read(P39_REGO)
    assert "data.jdg.thresholds.v3_p39" in rego, \
        "pakiet P39 nie podpięty pod snapshot progów"
    assert "v3_p39_threshold_version" in rego, \
        "brak odczytu threshold_version w pakiecie P39"


def test_contracts_honored():
    src = _read(P39_REGO)
    for contract in CONTRACT_MENTIONS:
        assert contract in src, f"brak odwołania do kontraktu {contract} w pakiecie P39"
    assert "NEEDS_ADVICE" in src or "TRIAGE" in src  # fail-closed P04


def test_core_artifacts_exist():
    missing = [a for a in CORE_ARTIFACTS if not (BASE / a).exists()]
    assert not missing, f"brak artefaktów rdzenia (rozszerzamy, nie duplikujemy): {missing}"


def test_core_data_exist():
    missing = [a for a in CORE_DATA if not (BASE / a).exists()]
    assert not missing, f"brak danych rdzenia: {missing}"


def test_ci_workflow_has_opa_tests():
    wf = _read(WORKFLOW)
    assert "opa test" in wf, "workflow CI nie uruchamia opa test (I02 bramka PR)"
    assert "pytest" in wf or "python -m pytest" in wf, "workflow CI nie uruchamia pytest"


# ── Narzędzia dowodowe i bundle ───────────────────────────────────────────────

def test_p39_tools_present():
    for name in sorted(TOOLS_EXPECTED):
        assert (TOOLS / name).exists(), f"brak tools/{name}"


def test_p39_bundles_all_pass():
    for name in sorted(TOOLS_EXPECTED):
        bundle = BUNDLES / (name.replace(".py", ".json"))
        assert bundle.exists(), f"brak bundles/{bundle.name}"
        data = _read(bundle)
        assert '"gate": "PASS"' in data, f"gate FAIL: {bundle.name}"


def test_p39_bundle_innovations_match_tools():
    for name in sorted(TOOLS_EXPECTED):
        bpath = BUNDLES / (name.replace(".py", ".json"))
        data = json.loads(_read(bpath))
        iid = data["innovation"]
        assert re.fullmatch(r"V3-P39-I\d{2}", iid), f"błędny ID innowacji: {iid}"
        assert iid in _read(P39_REGO), f"{iid} nie ma reguły w pakiecie"
