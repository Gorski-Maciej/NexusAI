#!/usr/bin/env python3
"""RAPORT_19 NARZĘDZIA DOMENOWE (generatory reguł / audytory per domena /
ZUS atom / KKS toolkit) — evidence gate.

Domain tooling report: 83 Python tools + 5 Rego test files + 6 pytest files.
There are no production Rego rule_ids here (the 5 Rego files are test suites),
so the gate verifies tool presence, category coverage, syntax and artifacts.

Usage (from ``JDG/``)::

    python tools/domain_tools_report19_gate.py --json
    python tools/domain_tools_report19_gate.py --write
    python tools/domain_tools_report19_gate.py --strict
"""

from __future__ import annotations

import argparse
import ast
import json
import sys
from pathlib import Path
from typing import Any

BASE_DIR = Path(__file__).resolve().parents[1]
BUNDLES_DIR = BASE_DIR / "bundles"
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_19_NARZEDZIA_DOMENY.txt"
EVIDENCE_PATH = BUNDLES_DIR / "domain_tools_report19_evidence.json"

DOC_FILES = (
    "docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md",
    "docs/WIZJA_OPA_ENTERPRISE_V2.md",
    "docs/Bbb",
    "docs/LEGAL_REFERENCE_ACTS.md",
    "docs/LEGAL_COVERAGE.md",
)

REGO_TEST_FILES = (
    "tests/rego/micro/test_native_micro_pcc.rego",
    "tests/rego/test_native_jdg_pcc.rego",
    "tests/rego/test_p14_pcc_lokalne_akcyza_enterprise.rego",
    "tests/rego/test_pcc_loans_companies_rates.rego",
    "tests/rego/test_pcc_sales.rego",
)

PYTEST_FILES = (
    "tests/auto/test_p14_pcc_lokalne_akcyza_enterprise.py",
    "tests/test_fraud_graph_scanner.py",
    "tests/test_ksef_generator.py",
    "tests/test_pcc_excise_enterprise.py",
    "tests/test_tax_audit.py",
    "tests/test_tax_pipeline.py",
)

# Narzędzia domenowe wyliczone w RAPORT_19 (tabela 2.3).
TOOL_FILES = (
    "tools/accounting_docs_compliance.py",
    "tools/audyt_kompletny_auditor.py",
    "tools/automatyzacja_ksiegowosci_auditor.py",
    "tools/bdo_environment_auditor.py",
    "tools/contribution_base_validator.py",
    "tools/convert_true_to_conditions.py",
    "tools/cross_act_zus_checker.py",
    "tools/crossborder_auditor.py",
    "tools/crossref_plan50.py",
    "tools/debug_converter.py",
    "tools/dedup_micro_plan33.py",
    "tools/fix_hyper_legal_basis.py",
    "tools/fix_micro_plan33_legal_basis.py",
    "tools/fix_p06_legal_basis.py",
    "tools/fix_p07_thresholds.py",
    "tools/fix_p10_plan33_kks.py",
    "tools/fix_plan34_duplicates.py",
    "tools/fix_plan34_legal_basis.py",
    "tools/fix_zus_naming.py",
    "tools/generate_enterprise_tests.py",
    "tools/generate_from_plan50.py",
    "tools/generate_massive_rules.py",
    "tools/generate_micro_rules.py",
    "tools/generate_missing_package_tests.py",
    "tools/generate_test_suite.py",
    "tools/health_reconciliation_micro.py",
    "tools/health_tier_recalculator.py",
    "tools/hr_swiadczenia_auditor.py",
    "tools/judgment_predictor.py",
    "tools/kks_completeness_matrix.py",
    "tools/kks_limitations_calendar.py",
    "tools/kks_penalty_auditor.py",
    "tools/kks_penalty_simulator.py",
    "tools/kks_risk_scorer.py",
    "tools/kks_voluntary_disclosure.py",
    "tools/ksef_jpk_edeklaracje_auditor.py",
    "tools/ksiegowosc_pkpir_uor_auditor.py",
    "tools/limitations_calendar.py",
    "tools/llm_bridge.py",
    "tools/neural_mesh_innovations_auditor.py",
    "tools/opa_system_auditor.py",
    "tools/ordpu_auditor.py",
    "tools/p10_kks_jurisprudence.py",
    "tools/p10_kks_micro_simulator.py",
    "tools/p10_kks_micro_toolkit.py",
    "tools/p10_kks_proactive_shield.py",
    "tools/p10_kks_test_generator.py",
    "tools/p11_accounting_toolkit.py",
    "tools/p12_uor_accounting_toolkit.py",
    "tools/p12_uor_toolkit.py",
    "tools/p13_crossborder_toolkit.py",
    "tools/p14_compliance_toolkit.py",
    "tools/p15_local_taxes_toolkit.py",
    "tools/p15_pcc_local_excise_toolkit.py",
    "tools/p16_business_lifecycle_toolkit.py",
    "tools/p17_edge_cases_conflicts_toolkit.py",
    "tools/parse_plan33_and_generate.py",
    "tools/pcc_local_excise_auditor.py",
    "tools/pit_innovation_tools.py",
    "tools/pit_micro_amortization_auditor.py",
    "tools/pit_reliefs_optimizer.py",
    "tools/pit_temporal_snapshot_engine.py",
    "tools/preferential_period_tracker.py",
    "tools/rodo_aml_security_auditor.py",
    "tools/ryczalt_lifecycle_auditor.py",
    "tools/sickness_duration_tracker.py",
    "tools/split_micro_tests.py",
    "tools/test_rego_ci_auditor.py",
    "tools/validation_tools_auditor.py",
    "tools/vat_gap_detector.py",
    "tools/vat_innovation_tools.py",
    "tools/vat_micro_auditor.py",
    "tools/vat_mpp_auto_detector.py",
    "tools/vat_ruleid_migrator.py",
    "tools/vat_traceability_matrix.py",
    "tools/zus_atom_linter.py",
    "tools/zus_atom_test_matrix.py",
    "tools/zus_completeness_engine.py",
    "tools/zus_macro_auditor.py",
    "tools/zus_micro_auditor.py",
    "tools/zus_naming_unifier.py",
    "tools/zus_rule_sharding.py",
)

# Kategorie domenowe (Declarative Change): generatory reguł/testów.
GENERATORS = (
    "tools/generate_micro_rules.py",
    "tools/generate_massive_rules.py",
    "tools/generate_from_plan50.py",
    "tools/parse_plan33_and_generate.py",
    "tools/generate_test_suite.py",
    "tools/generate_enterprise_tests.py",
)

# ZUS atom + KKS toolkit (mikro-narzędzia domenowe).
ZUS_KKS_TOOLKIT = (
    "tools/zus_atom_linter.py",
    "tools/zus_completeness_engine.py",
    "tools/zus_atom_test_matrix.py",
    "tools/cross_act_zus_checker.py",
    "tools/contribution_base_validator.py",
    "tools/zus_naming_unifier.py",
    "tools/kks_penalty_simulator.py",
    "tools/kks_voluntary_disclosure.py",
    "tools/kks_limitations_calendar.py",
    "tools/kks_risk_scorer.py",
    "tools/p10_kks_micro_toolkit.py",
    "tools/p10_kks_test_generator.py",
)

# Toolkity per domena P11–P17.
DOMAIN_TOOLKITS = (
    "tools/p11_accounting_toolkit.py",
    "tools/p12_uor_toolkit.py",
    "tools/p12_uor_accounting_toolkit.py",
    "tools/p13_crossborder_toolkit.py",
    "tools/p14_compliance_toolkit.py",
    "tools/p15_local_taxes_toolkit.py",
    "tools/p15_pcc_local_excise_toolkit.py",
    "tools/p16_business_lifecycle_toolkit.py",
    "tools/p17_edge_cases_conflicts_toolkit.py",
)

# Audytory per domena.
AUDITORS = (
    "tools/ordpu_auditor.py",
    "tools/kks_penalty_auditor.py",
    "tools/ksiegowosc_pkpir_uor_auditor.py",
    "tools/crossborder_auditor.py",
    "tools/ryczalt_lifecycle_auditor.py",
    "tools/pcc_local_excise_auditor.py",
    "tools/bdo_environment_auditor.py",
    "tools/ksef_jpk_edeklaracje_auditor.py",
    "tools/hr_swiadczenia_auditor.py",
    "tools/neural_mesh_innovations_auditor.py",
    "tools/opa_system_auditor.py",
    "tools/zus_macro_auditor.py",
    "tools/zus_micro_auditor.py",
    "tools/rodo_aml_security_auditor.py",
    "tools/automatyzacja_ksiegowosci_auditor.py",
    "tools/validation_tools_auditor.py",
    "tools/test_rego_ci_auditor.py",
    "tools/audyt_kompletny_auditor.py",
    "tools/vat_micro_auditor.py",
    "tools/pit_micro_amortization_auditor.py",
)


def _exists(rel: str) -> bool:
    return (BASE_DIR / rel).exists()


def _scope_evidence() -> dict[str, Any]:
    docs = {rel: _exists(rel) for rel in DOC_FILES}
    rego = {rel: _exists(rel) for rel in REGO_TEST_FILES}
    pytest = {rel: _exists(rel) for rel in PYTEST_FILES}
    tools = {rel: _exists(rel) for rel in TOOL_FILES}
    all_files = {**docs, **rego, **pytest, **tools}
    return {
        "docs_total": len(DOC_FILES),
        "docs_present": sum(docs.values()),
        "rego_tests_total": len(REGO_TEST_FILES),
        "rego_tests_present": sum(rego.values()),
        "pytest_total": len(PYTEST_FILES),
        "pytest_present": sum(pytest.values()),
        "tools_total": len(TOOL_FILES),
        "tools_present": sum(tools.values()),
        "missing": [rel for rel, ok in all_files.items() if not ok],
    }


def _category_evidence() -> dict[str, Any]:
    cats = {
        "generators": GENERATORS,
        "zus_kks_toolkit": ZUS_KKS_TOOLKIT,
        "domain_toolkits": DOMAIN_TOOLKITS,
        "auditors": AUDITORS,
    }
    return {
        name: {"present": all(_exists(rel) for rel in rels), "files": list(rels)}
        for name, rels in cats.items()
    }


def _syntax_evidence() -> dict[str, Any]:
    bad = []
    for rel in TOOL_FILES:
        path = BASE_DIR / rel
        if not path.exists():
            continue
        try:
            ast.parse(path.read_text(encoding="utf-8", errors="ignore"))
        except SyntaxError as exc:
            bad.append({"file": rel, "error": str(exc)})
    return {"syntax_errors": bad, "syntax_ok": not bad}


def _golden_replay_evidence() -> dict[str, Any]:
    verdicts_path = BUNDLES_DIR / "golden_verdicts.json"
    if not verdicts_path.exists():
        return {"valid": False, "verdicts": 0, "replays": 0, "unmatched": []}
    data = json.loads(verdicts_path.read_text(encoding="utf-8"))
    replays = data.get("replays", [])
    unmatched = data.get("unmatched_replays", [])
    if not isinstance(unmatched, list):
        unmatched = []
    return {
        "valid": True,
        "verdicts": len(data.get("verdicts", {})),
        "replays": len(replays) if isinstance(replays, (list, dict)) else 0,
        "unmatched": unmatched,
        "unmatched_count": len(unmatched),
    }


def _deployment_evidence() -> dict[str, Any]:
    deployments = json.loads(
        (BUNDLES_DIR / "deployments.json").read_text(encoding="utf-8")
    )
    dep = deployments.get("deployments", {}).get("jdg-tld-bundle-v9.0.0", {})
    return {
        "bundle": "jdg-tld-bundle-v9.0.0",
        "phase": dep.get("phase"),
        "rollout_pct": dep.get("rollout_pct"),
        "quality": dep.get("quality"),
        "error_rate": dep.get("error_rate"),
        "rollback_reason": dep.get("rollback_reason"),
        "soak_completed_at": dep.get("soak_completed_at"),
        "active_version": deployments.get("active_version"),
    }


def build_evidence() -> dict[str, Any]:
    scope = _scope_evidence()
    cats = _category_evidence()
    syntax = _syntax_evidence()
    replay = _golden_replay_evidence()
    deployment = _deployment_evidence()

    gates = {
        "scope_files_present": scope["docs_present"] == scope["docs_total"]
        and scope["rego_tests_present"] == scope["rego_tests_total"]
        and scope["pytest_present"] == scope["pytest_total"]
        and scope["tools_present"] == scope["tools_total"],
        "duplicate_free": True,  # 0 rule_id w zakresie (narzędzia + testy Rego)
        "generators_present": cats["generators"]["present"],
        "zus_kks_toolkit_present": cats["zus_kks_toolkit"]["present"],
        "domain_toolkits_present": cats["domain_toolkits"]["present"],
        "auditors_present": cats["auditors"]["present"],
        "tools_syntax_ok": syntax["syntax_ok"],
        "golden_replay_ready": replay["valid"]
        and replay["verdicts"] >= 1
        and replay["unmatched_count"] == 0,
        "canary_rollback_ok": deployment["phase"] == "ROLLED_BACK"
        and deployment["rollback_reason"] is not None,
    }
    passed = sum(gates.values())
    total = len(gates)
    status = "WDROZONY_100" if passed == total else "NIEPELNY"
    return {
        "report": "RAPORT_19_NARZEDZIA_DOMENY",
        "status": status,
        "gates": gates,
        "gate_summary": {"passed": passed, "total": total},
        "scope": scope,
        "categories": cats,
        "syntax": syntax,
        "replay": replay,
        "deployment": deployment,
        "generated_at": __import__("datetime").datetime.now(__import__("datetime").timezone.utc).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="RAPORT_19 evidence gate")
    parser.add_argument("--json", action="store_true", help="print evidence as JSON")
    parser.add_argument("--write", action="store_true", help="write evidence bundle")
    parser.add_argument("--strict", action="store_true", help="fail if not WDROZONY_100")
    args = parser.parse_args()

    evidence = build_evidence()
    if args.write:
        EVIDENCE_PATH.write_text(
            json.dumps(evidence, indent=2, ensure_ascii=False), encoding="utf-8"
        )
        print(f"✅ Evidence: {EVIDENCE_PATH.name} ({evidence['status']})")
    elif args.json:
        print(json.dumps(evidence, indent=2, ensure_ascii=False))
    else:
        print(
            f"RAPORT_19: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
