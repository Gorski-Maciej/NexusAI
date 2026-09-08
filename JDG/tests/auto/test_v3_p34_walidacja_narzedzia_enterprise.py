# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P34 (WALIDACJA NARZĘDZI — WALIDACJA JAKO GOVERNANCE)
— kampania V3 FORTRESS.

Weryfikuje:
  * reguły OPA w rules/v3_p34_walidacja_narzedzia_enterprise.rego (12 analiz I01-I12),
  * parametry-as-data w rules/thresholds_jdg.rego (blok v3_p34, ADR-002/P06, P05),
  * wiring w rules/main_jdg.rego (final_verdict_p98),
  * 12 narzędzi dowodowych tools/v3_p34_*.py i 12 bundli bundles/v3_p34_*.json,
  * spójność z legacy: walidatory rdzenia z sekcji 6.1-6.4 promptu (istnienie),
    kontrakty P03/P04 (werdykt, invarianty), P07 (lifecycle/auto-fix PR),
    P08 (Law Radar), P33 (SMT/Z3 w semantic diff),
  * granice: DAG L1-L5 jako dane, fuzz min 1000, mirror unchecked 0,
    doc unanchored 0, heatmap stale 1 dzień / drop 5 punktów.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"

P34_REGO = RULES / "v3_p34_walidacja_narzedzia_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"

INNOVATIONS = {
    "I01": "jdg.v3_p34_walidacja_narzedzia.validation_dag",
    "I02": "jdg.v3_p34_walidacja_narzedzia.semantic_diff",
    "I03": "jdg.v3_p34_walidacja_narzedzia.legal_basis_linter",
    "I04": "jdg.v3_p34_walidacja_narzedzia.tautology_fuzzing",
    "I05": "jdg.v3_p34_walidacja_narzedzia.cross_write_detector",
    "I06": "jdg.v3_p34_walidacja_narzedzia.mirror_semantic_parity",
    "I07": "jdg.v3_p34_walidacja_narzedzia.doc_numbers_invariant",
    "I08": "jdg.v3_p34_walidacja_narzedzia.auto_fix_four_eyes",
    "I09": "jdg.v3_p34_walidacja_narzedzia.validation_as_service",
    "I10": "jdg.v3_p34_walidacja_narzedzia.coverage_heatmap_continuous",
    "I11": "jdg.v3_p34_walidacja_narzedzia.validation_snapshot",
    "I12": "jdg.v3_p34_walidacja_narzedzia.exception_register",
}

ANALYSES = [
    "validation_dag", "semantic_diff", "legal_basis_linter", "tautology_fuzzing",
    "cross_write_detector", "mirror_semantic_parity", "doc_numbers_invariant",
    "auto_fix_four_eyes", "validation_as_service", "coverage_heatmap_continuous",
    "validation_snapshot", "exception_register",
]

TOOLS_EXPECTED = {
    "v3_p34_validation_dag.py", "v3_p34_semantic_diff.py",
    "v3_p34_legal_basis_linter.py", "v3_p34_tautology_fuzzing.py",
    "v3_p34_cross_write_detector.py", "v3_p34_mirror_semantic_parity.py",
    "v3_p34_doc_numbers_invariant.py", "v3_p34_auto_fix_four_eyes.py",
    "v3_p34_validation_as_service.py", "v3_p34_coverage_heatmap.py",
    "v3_p34_validation_snapshot.py", "v3_p34_exception_register.py",
}

# Walidatory rdzenia z sekcji 6.1-6.4 promptu P34 (istnienie = dowód)
CORE_VALIDATOR_TOOLS = [
    "validate_rules.py", "lint_rego_rules.py", "convert_true_to_conditions.py",
    "tautology_guard.py", "else_chain_dead_code_detector.py",
    "dead_rule_detector.py", "hardcoded_audit.py", "debug_converter.py",
    "validate_legal_basis.py", "validate_legal_basis_v2.py",
    "validate_p24_legal_basis.py", "temporal_interval_gate.py",
    "isap_crawler.py", "isap_rule_update_pipeline.py", "isap_drift_alarm.py",
    "legal_change_impact_analyzer.py", "cross_ref_validator.py",
    "cross_package_conflict_detector.py", "doc_consistency_validator.py",
    "traceability_matrix.py", "vat_traceability_matrix.py",
    "adr_auto_proposer.py", "initiative_numbering_auditor.py",
    "rule_impact_simulator.py", "verify_verdict_invariants.py",
    "validate_enterprise_contract.py", "temporal_drift_detector.py",
    "legal_coverage_heatmap.py", "migration_impact_analyzer.py",
]

THRESHOLD_KEYS_V3P34 = [
    "v3_p34_threshold_version", "legal_basis_version", "valid_from",
    "v3_p34_dag_levels", "v3_p34_fuzz_min_inputs",
    "v3_p34_mirror_unchecked_max", "v3_p34_doc_unanchored_max",
    "v3_p34_heatmap_max_stale_days", "v3_p34_coverage_drop_block",
]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def _thresholds_block() -> str:
    src = _read(THRESHOLDS)
    i = src.find("v3_p34 := {")
    assert i >= 0, "brak bloku v3_p34 w thresholds_jdg.rego"
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


# ── Pakiet V3-P34 ─────────────────────────────────────────────────────────────

def test_p34_rego_exists_and_structured():
    src = _read(P34_REGO)
    assert src, "brak rules/v3_p34_walidacja_narzedzia_enterprise.rego"
    assert "package jdg.v3_p34_walidacja_narzedzia" in src
    assert src.count("{") == src.count("}"), "nierównoważne nawiasy"
    rule_ids = re.findall(r'"rule_id": "([^"]+)"', src)
    assert len(rule_ids) == len(set(rule_ids)), "duplikaty rule_id w pakiecie P34"


def test_p34_all_12_innovations_present():
    src = _read(P34_REGO)
    for iid, rid in INNOVATIONS.items():
        assert rid in src, f"brak reguły {iid}: {rid}"


def test_p34_decide_chain_covers_all_analyses():
    src = _read(P34_REGO)
    chain = src.split("decide := fail_closed_decision")[1]
    for iid, rid in INNOVATIONS.items():
        rule_name = rid.rsplit(".", 1)[1]
        assert f"{rule_name}_decision" in chain, f"brak reguły {iid} w łańcuchu decide"
    assert chain.count("else :=") >= len(ANALYSES), "niekompletny else-chain decide"


def test_p34_fail_closed_no_silent_auto_post():
    src = _read(P34_REGO)
    assert "fail_closed_decision" in src
    assert "_snapshot_ok" in src
    assert '"_routing": "BLOCK_AND_ALERT"' in src
    assert "no_match" in src
    for m in re.finditer(r"\{\s*true\s*\}", src):
        prefix = src[:m.start()].rstrip().splitlines()[-1]
        assert "else" in prefix, (
            f"AP01: samodzielny stub bez else w P34 (kontekst: {prefix!r})")


def test_p34_public_rule_count():
    src = _read(P34_REGO)
    rule_ids = re.findall(
        r'"rule_id": "jdg\.v3_p34_walidacja_narzedzia\.[a-z_]+"', src)
    assert len(rule_ids) >= 12, "za mało reguł publicznych w pakiecie"


# ── Parametry jako dane (ADR-002/P06) + okno temporalne (P05) ─────────────────

def test_v3p34_block_complete():
    block = _thresholds_block()
    for key in THRESHOLD_KEYS_V3P34:
        assert f'"{key}"' in block, f"brak klucza {key} v3_p34"
    assert '"valid_from"' in block, "brak okna temporalnego (P05)"


def test_v3p34_dag_levels_as_data():
    block = _thresholds_block()
    m = re.search(r'"v3_p34_dag_levels":\s*\[([^\]]*)\]', block)
    assert m, "brak v3_p34_dag_levels"
    levels = re.findall(r'"([A-Za-z_0-9]+)"', m.group(1))
    assert levels == ["L1_syntax", "L2_lint", "L3_tests", "L4_semantic", "L5_legal"], \
        f"poziomy DAG zmienione: {levels}"


def test_v3p34_governance_limits():
    block = _thresholds_block()
    assert '"v3_p34_fuzz_min_inputs": 1000' in block, "fuzz min 1000 (I04)"
    assert '"v3_p34_mirror_unchecked_max": 0' in block, "mirror unchecked 0 (I06)"
    assert '"v3_p34_doc_unanchored_max": 0' in block, "doc unanchored 0 (I07)"
    assert '"v3_p34_heatmap_max_stale_days": 1' in block, "heatmap stale 1 dzień (I10)"
    assert '"v3_p34_coverage_drop_block": 5' in block, "spadek pokrycia 5 pkt (I10)"


# ── Wiring main_jdg ───────────────────────────────────────────────────────────

def test_main_jdg_wired_p98():
    src = _read(MAIN_JDG)
    assert "import data.jdg.v3_p34_walidacja_narzedzia as v3_p34_walidacja_narzedzia" in src
    assert '"jdg.v3_p34_walidacja_narzedzia": v3_p34_walidacja_narzedzia.decide' in src
    assert "final_verdict_p98 = safe_merge(final_verdict_p97" in src
    assert "final_verdict_post_merge = safe_merge(" in src
    assert "final_verdict_p98\n)" in src or "safe_merge(final_verdict_p98," in src


# ── Spójność z legacy (walidatory rdzenia, kontrakty P03/P04/P07/P08/P33) ─────

def test_p34_threshold_version_consistency():
    rego = _read(P34_REGO)
    assert "data.jdg.thresholds.v3_p34" in rego, \
        "pakiet P34 nie podpięty pod snapshot progów"
    assert "v3_p34_threshold_version" in rego, \
        "brak odczytu threshold_version w pakiecie P34"


def test_legacy_contracts_honored():
    src = _read(P34_REGO)
    assert "SMT" in src or "smt" in src        # kontrakt P33-I01 (semantic diff)
    assert "P08" in src or "Law Radar" in src  # kontrakt P08 (heatmapa)
    assert "4-eyes" in src or "four_eyes" in src  # kontrakt P07 (auto-fix PR)
    assert "NEEDS_ADVICE" in src or "TRIAGE" in src  # fail-closed P04


def test_core_validator_tools_exist():
    missing = [t for t in CORE_VALIDATOR_TOOLS if not (TOOLS / t).exists()]
    assert not missing, f"brak walidatorów rdzenia: {missing}"


# ── Narzędzia dowodowe i bundle ───────────────────────────────────────────────

def test_p34_tools_present():
    for name in sorted(TOOLS_EXPECTED):
        assert (TOOLS / name).exists(), f"brak tools/{name}"


def test_p34_bundles_all_pass():
    for name in sorted(TOOLS_EXPECTED):
        bundle = BUNDLES / (name.replace(".py", ".json"))
        assert bundle.exists(), f"brak bundles/{bundle.name}"
        data = _read(bundle)
        assert '"gate": "PASS"' in data, f"gate FAIL: {bundle.name}"


def test_p34_bundle_innovations_match_tools():
    for name in sorted(TOOLS_EXPECTED):
        bpath = BUNDLES / (name.replace(".py", ".json"))
        data = json.loads(_read(bpath))
        iid = data["innovation"]
        assert re.fullmatch(r"V3-P34-I\d{2}", iid), f"błędny ID innowacji: {iid}"
        assert iid in _read(P34_REGO), f"{iid} nie ma reguły w pakiecie"
