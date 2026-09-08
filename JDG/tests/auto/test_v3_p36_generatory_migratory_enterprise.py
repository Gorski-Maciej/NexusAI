# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P36 (GENERATORY MIGRATORY — TRANSFORMACJE JAKO TRANSAKCJE)
— kampania V3 FORTRESS.

Weryfikuje:
  * reguły OPA w rules/v3_p36_generatory_migratory_enterprise.rego (12 analiz I01-I12),
  * parametry-as-data w rules/thresholds_jdg.rego (blok v3_p36, ADR-002/P06, P05),
  * wiring w rules/main_jdg.rego (final_verdict_p100),
  * 12 narzędzi dowodowych tools/v3_p36_*.py i 12 bundli bundles/v3_p36_*.json,
  * spójność z legacy: generatory/migratory z sekcji 6.1-6.3 promptu (istnienie),
    kontrakty P00 (kanon nazewniczy), P03/P04 (werdykt, invarianty), P07
    (lifecycle), P10 (golden replay), P29 (bramki/idempotencja), P33 (AI w tym
    samym pipeline), P34 (DAG L1-L5 jako auto-walidacja), P39/P48 (mirror sync),
  * granice: replay drift 0, orphans 0, pokrycie granic 100%, required fields,
    idempotencja wymagana.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"

P36_REGO = RULES / "v3_p36_generatory_migratory_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"

INNOVATIONS = {
    "I01": "jdg.v3_p36_generatory_migratory.transform_transaction",
    "I02": "jdg.v3_p36_generatory_migratory.idempotency_certificate",
    "I03": "jdg.v3_p36_generatory_migratory.plan_to_rules",
    "I04": "jdg.v3_p36_generatory_migratory.migration_ledger",
    "I05": "jdg.v3_p36_generatory_migratory.guard_rails",
    "I06": "jdg.v3_p36_generatory_migratory.golden_replay_post_migration",
    "I07": "jdg.v3_p36_generatory_migratory.mirror_aware_apply",
    "I08": "jdg.v3_p36_generatory_migratory.boundary_test_generator",
    "I09": "jdg.v3_p36_generatory_migratory.dry_run_report",
    "I10": "jdg.v3_p36_generatory_migratory.naming_convention_enforcer",
    "I11": "jdg.v3_p36_generatory_migratory.migration_as_data",
    "I12": "jdg.v3_p36_generatory_migratory.zero_orphan_guarantee",
}

ANALYSES = [
    "transform_transaction", "idempotency_certificate", "plan_to_rules",
    "migration_ledger", "guard_rails", "golden_replay_post_migration",
    "mirror_aware_apply", "boundary_test_generator", "dry_run_report",
    "naming_convention_enforcer", "migration_as_data", "zero_orphan_guarantee",
]

TOOLS_EXPECTED = {
    "v3_p36_transform_transaction.py", "v3_p36_idempotency_certificate.py",
    "v3_p36_plan_to_rules.py", "v3_p36_migration_ledger.py",
    "v3_p36_guard_rails.py", "v3_p36_golden_replay_post_migration.py",
    "v3_p36_mirror_aware_apply.py", "v3_p36_boundary_test_generator.py",
    "v3_p36_dry_run_report.py", "v3_p36_naming_convention_enforcer.py",
    "v3_p36_migration_as_data.py", "v3_p36_zero_orphan_guarantee.py",
}

# Generatory i migratory z sekcji 6.1-6.3 promptu P36 (istnienie = dowód)
CORE_GENERATOR_TOOLS = [
    "generate_micro_rules.py", "generate_massive_rules.py",
    "parse_plan33_and_generate.py", "generate_from_plan50.py",
    "crossref_plan50.py", "dedup_micro_plan33.py",
    "fix_p00_duplicates.py", "fix_p00_legal_basis_closure.py",
    "fix_plan34_duplicates.py", "fix_plan34_legal_basis.py",
    "fix_p06_legal_basis.py", "fix_p07_thresholds.py",
    "fix_hyper_legal_basis.py", "fix_micro_plan33_legal_basis.py",
    "fix_p10_plan33_kks.py", "fix_zus_naming.py",
    "vat_ruleid_migrator.py", "rule_lifecycle_manager.py",
    "convert_true_to_conditions.py", "generate_test_suite.py",
    "generate_missing_package_tests.py", "generate_enterprise_tests.py",
    "split_micro_tests.py", "generate_manifest.py", "manifest_v2.py",
    "generate_coverage_report.py", "generate_glm52_prompty.py",
    "generate_v3_prompty.py", "verify_glm52_campaign.py",
]

# Kontrakty wejściowe P36 z promptu (Sekcja 11.1)
CONTRACT_MENTIONS = ["P00", "P34", "P10", "P29", "P33"]

THRESHOLD_KEYS_V3P36 = [
    "v3_p36_threshold_version", "legal_basis_version", "valid_from",
    "v3_p36_idempotency_required", "v3_p36_rule_without_test_max",
    "v3_p36_generator_required_fields", "v3_p36_guard_rail_violations_max",
    "v3_p36_replay_drift_max", "v3_p36_mirror_divergence_max",
    "v3_p36_boundary_rules_min_covered", "v3_p36_orphans_max",
]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def _thresholds_block() -> str:
    src = _read(THRESHOLDS)
    i = src.find("v3_p36 := {")
    assert i >= 0, "brak bloku v3_p36 w thresholds_jdg.rego"
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


# ── Pakiet V3-P36 ─────────────────────────────────────────────────────────────

def test_p36_rego_exists_and_structured():
    src = _read(P36_REGO)
    assert src, "brak rules/v3_p36_generatory_migratory_enterprise.rego"
    assert "package jdg.v3_p36_generatory_migratory" in src
    assert src.count("{") == src.count("}"), "nierównoważne nawiasy"
    rule_ids = re.findall(r'"rule_id": "([^"]+)"', src)
    assert len(rule_ids) == len(set(rule_ids)), "duplikaty rule_id w pakiecie P36"


def test_p36_all_12_innovations_present():
    src = _read(P36_REGO)
    for iid, rid in INNOVATIONS.items():
        assert rid in src, f"brak reguły {iid}: {rid}"


def test_p36_decide_chain_covers_all_analyses():
    src = _read(P36_REGO)
    chain = src.split("decide := fail_closed_decision")[1]
    for iid, rid in INNOVATIONS.items():
        rule_name = rid.rsplit(".", 1)[1]
        assert f"{rule_name}_decision" in chain, f"brak reguły {iid} w łańcuchu decide"
    assert chain.count("else :=") >= len(ANALYSES), "niekompletny else-chain decide"


def test_p36_fail_closed_no_silent_auto_post():
    src = _read(P36_REGO)
    assert "fail_closed_decision" in src
    assert "_snapshot_ok" in src
    assert '"_routing": "BLOCK_AND_ALERT"' in src
    assert "no_match" in src
    for m in re.finditer(r"\{\s*true\s*\}", src):
        prefix = src[:m.start()].rstrip().splitlines()[-1]
        assert "else" in prefix, (
            f"AP01: samodzielny stub bez else w P36 (kontekst: {prefix!r})")


def test_p36_public_rule_count():
    src = _read(P36_REGO)
    rule_ids = re.findall(
        r'"rule_id": "jdg\.v3_p36_generatory_migratory\.[a-z_]+"', src)
    assert len(rule_ids) >= 12, "za mało reguł publicznych w pakiecie"


def test_p36_innovation_ids_in_header():
    src = _read(P36_REGO)
    for i in range(1, 13):
        assert f"V3-P36-I{i:02d}" in src, f"brak ID V3-P36-I{i:02d} w nagłówku pakietu"


# ── Parametry jako dane (ADR-002/P06) + okno temporalne (P05) ─────────────────

def test_v3p36_block_complete():
    block = _thresholds_block()
    for key in THRESHOLD_KEYS_V3P36:
        assert f'"{key}"' in block, f"brak klucza {key} v3_p36"
    assert '"valid_from"' in block, "brak okna temporalnego (P05)"


def test_v3p36_governance_limits():
    block = _thresholds_block()
    assert '"v3_p36_idempotency_required": true' in block, "idempotencja wymagana (I02)"
    assert '"v3_p36_rule_without_test_max": 0' in block, "reguła bez testu = BLOCK (I03)"
    assert '"v3_p36_generator_required_fields"' in block, "wymagane pola generatora (I05)"
    assert '"v3_p36_replay_drift_max": 0' in block, "dryf replay = 0 (I06)"
    assert '"v3_p36_mirror_divergence_max": 0' in block, "dryf mirror = 0 (I07)"
    assert '"v3_p36_boundary_rules_min_covered": 100' in block, "pokrycie granic 100% (I08)"
    assert '"v3_p36_orphans_max": 0' in block, "zero-orphan (I12)"
    assert '"no_auto_post": true' in block, "fail-closed P04"


# ── Wiring main_jdg ───────────────────────────────────────────────────────────

def test_main_jdg_wired_p100():
    src = _read(MAIN_JDG)
    assert "import data.jdg.v3_p36_generatory_migratory as v3_p36_generatory_migratory" in src
    assert '"jdg.v3_p36_generatory_migratory": v3_p36_generatory_migratory.decide' in src
    assert "final_verdict_p100 = safe_merge(final_verdict_p99" in src
    assert "final_verdict_post_merge = safe_merge(" in src
    assert "final_verdict_p100\n)" in src or "safe_merge(final_verdict_p100," in src


# ── Spójność z legacy (generatory rdzenia, kontrakty P00/P03/P04/P07/P10/P29/P33/P34/P39/P48) ──

def test_p36_threshold_version_consistency():
    rego = _read(P36_REGO)
    assert "data.jdg.thresholds.v3_p36" in rego, \
        "pakiet P36 nie podpięty pod snapshot progów"
    assert "v3_p36_threshold_version" in rego, \
        "brak odczytu threshold_version w pakiecie P36"


def test_legacy_contracts_honored():
    src = _read(P36_REGO)
    for contract in CONTRACT_MENTIONS:
        assert contract in src, f"brak odwołania do kontraktu {contract} w pakiecie P36"
    assert "NEEDS_ADVICE" in src or "TRIAGE" in src  # fail-closed P04


def test_core_generator_tools_exist():
    missing = [t for t in CORE_GENERATOR_TOOLS if not (TOOLS / t).exists()]
    assert not missing, f"brak generatorów/migratorów rdzenia: {missing}"


def test_core_plans_exist():
    for plan in ["unified_plan_v8.yaml", "unified_plan_progress.yaml"]:
        assert (BASE / plan).exists(), f"brak planu unifikacyjnego: {plan}"


def test_core_developer_guide_exists():
    assert (BASE / "docs" / "OPA_REGO_DEVELOPER_GUIDE.md").exists(), \
        "brak docs/OPA_REGO_DEVELOPER_GUIDE.md"


# ── Narzędzia dowodowe i bundle ───────────────────────────────────────────────

def test_p36_tools_present():
    for name in sorted(TOOLS_EXPECTED):
        assert (TOOLS / name).exists(), f"brak tools/{name}"


def test_p36_bundles_all_pass():
    for name in sorted(TOOLS_EXPECTED):
        bundle = BUNDLES / (name.replace(".py", ".json"))
        assert bundle.exists(), f"brak bundles/{bundle.name}"
        data = _read(bundle)
        assert '"gate": "PASS"' in data, f"gate FAIL: {bundle.name}"


def test_p36_bundle_innovations_match_tools():
    for name in sorted(TOOLS_EXPECTED):
        bpath = BUNDLES / (name.replace(".py", ".json"))
        data = json.loads(_read(bpath))
        iid = data["innovation"]
        assert re.fullmatch(r"V3-P36-I\d{2}", iid), f"błędny ID innowacji: {iid}"
        assert iid in _read(P36_REGO), f"{iid} nie ma reguły w pakiecie"
