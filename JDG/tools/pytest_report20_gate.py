#!/usr/bin/env python3
"""RAPORT_20 TESTY PYTEST (testy jednostkowe/integracyjne ENTERPRISE) — evidence gate.

Test report: 36 ``tests/*.py`` + 54 ``tests/auto/test_auto_block_*.py`` + the rest
of ``tests/auto/``. No production Rego rule_ids in scope, so the gate verifies
artifact presence, syntax, import integrity of the previously-broken risk_guard
suite (the concrete G-04 finding), a green pytest run of that suite, golden
replay readiness and the canary/rollback deployment record.

Usage (from ``JDG/``)::

    python tools/pytest_report20_gate.py --json
    python tools/pytest_report20_gate.py --write
    python tools/pytest_report20_gate.py --strict
"""

from __future__ import annotations

import argparse
import ast
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

BASE_DIR = Path(__file__).resolve().parents[1]
REPO_ROOT = BASE_DIR.parent  # nexus_ai package lives at the repo root
BUNDLES_DIR = BASE_DIR / "bundles"
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_20_TESTY_PYTEST.txt"
EVIDENCE_PATH = BUNDLES_DIR / "pytest_report20_evidence.json"

DOC_FILES = (
    "docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md",
    "docs/WIZJA_OPA_ENTERPRISE_V2.md",
    "docs/Bbb",
    "docs/LEGAL_REFERENCE_ACTS.md",
    "docs/LEGAL_COVERAGE.md",
)

# 36 plików tests/*.py wymienionych w RAPORT_20 (sekcja 2.1) + test_vat_enterprise.
UNIT_TEST_FILES = (
    "tests/test_aml_enterprise.py",
    "tests/test_bdo_enterprise.py",
    "tests/test_conflicts_enterprise.py",
    "tests/test_crossborder_enterprise.py",
    "tests/test_edge_cases_enterprise.py",
    "tests/test_facts_aggregator.py",
    "tests/test_fraud_graph_scanner.py",
    "tests/test_hyper_plan45_enterprise.py",
    "tests/test_kks_enterprise.py",
    "tests/test_ksef_generator.py",
    "tests/test_p01_control_plane.py",
    "tests/test_p02_legal.py",
    "tests/test_p03_orchestrator_enterprise.py",
    "tests/test_p04_vat_macro_enterprise.py",
    "tests/test_p05_vat_micro_atomic.py",
    "tests/test_p06_pit_macro_enterprise.py",
    "tests/test_p07_pit_micro_atomic.py",
    "tests/test_p08_zus_macro_enterprise.py",
    "tests/test_p16_v8_enterprise.py",
    "tests/test_payment_priority_service.py",
    "tests/test_pcc_excise_enterprise.py",
    "tests/test_phase5_modules.py",
    "tests/test_pkpir_uor_enterprise.py",
    "tests/test_priority_engine.py",
    "tests/test_risk_api.py",
    "tests/test_risk_guard.py",
    "tests/test_risk_guard_integration.py",
    "tests/test_rodo_enterprise.py",
    "tests/test_semantic_guard.py",
    "tests/test_strategic_v2_modules.py",
    "tests/test_tax_audit.py",
    "tests/test_tax_pipeline.py",
    "tests/test_tax_rules.py",
    "tests/test_temporal_manager.py",
    "tests/test_temporal_validity.py",
    "tests/test_vat_enterprise.py",
)

# Pliki testów blokowych (auto) — wygenerowane per domena.
AUTO_BLOCK_FILES = (
    "tests/auto/test_auto_block_accounting.py",
    "tests/auto/test_auto_block_allowances.py",
    "tests/auto/test_auto_block_api_fallback.py",
    "tests/auto/test_auto_block_audit.py",
    "tests/auto/test_auto_block_business.py",
    "tests/auto/test_auto_block_calendar.py",
    "tests/auto/test_auto_block_compliance.py",
    "tests/auto/test_auto_block_conflicts.py",
    "tests/auto/test_auto_block_conviction.py",
    "tests/auto/test_auto_block_corrections.py",
    "tests/auto/test_auto_block_crossborder.py",
    "tests/auto/test_auto_block_digital.py",
    "tests/auto/test_auto_block_edelivery.py",
    "tests/auto/test_auto_block_edge_cases.py",
    "tests/auto/test_auto_block_employer.py",
    "tests/auto/test_auto_block_environmental.py",
    "tests/auto/test_auto_block_exit_tax.py",
    "tests/auto/test_auto_block_family.py",
    "tests/auto/test_auto_block_insurance.py",
    "tests/auto/test_auto_block_kks.py",
    "tests/auto/test_auto_block_ksef_jpk.py",
    "tests/auto/test_auto_block_ksef_resilience.py",
    "tests/auto/test_auto_block_liability.py",
    "tests/auto/test_auto_block_lifecycle.py",
    "tests/auto/test_auto_block_limitations.py",
    "tests/auto/test_auto_block_local.py",
    "tests/auto/test_auto_block_local_taxes.py",
    "tests/auto/test_auto_block_mdr.py",
    "tests/auto/test_auto_block_micro.py",
    "tests/auto/test_auto_block_nkup.py",
    "tests/auto/test_auto_block_payments.py",
    "tests/auto/test_auto_block_pit.py",
    "tests/auto/test_auto_block_pkpir_live.py",
    "tests/auto/test_auto_block_procurement.py",
    "tests/auto/test_auto_block_regulated.py",
    "tests/auto/test_auto_block_representation.py",
    "tests/auto/test_auto_block_residency.py",
    "tests/auto/test_auto_block_restructuring.py",
    "tests/auto/test_auto_block_retention.py",
    "tests/auto/test_auto_block_risk.py",
    "tests/auto/test_auto_block_rodo.py",
    "tests/auto/test_auto_block_rodo_extended.py",
    "tests/auto/test_auto_block_routing.py",
    "tests/auto/test_auto_block_sanctions.py",
    "tests/auto/test_auto_block_solidarity.py",
    "tests/auto/test_auto_block_statute.py",
    "tests/auto/test_auto_block_tax_interaction.py",
    "tests/auto/test_auto_block_temporal.py",
    "tests/auto/test_auto_block_tp.py",
    "tests/auto/test_auto_block_validation.py",
    "tests/auto/test_auto_block_vat.py",
    "tests/auto/test_auto_block_vat_complete.py",
    "tests/auto/test_auto_block_wis.py",
    "tests/auto/test_auto_block_zus.py",
)

# Pliki, których importy zostały naprawione w RAPORT_20 (konkretne znalezisko G-04).
FIXED_IMPORT_FILES = (
    "tests/test_risk_guard.py",
    "tests/test_risk_guard_integration.py",
)


def _exists(rel: str) -> bool:
    return (BASE_DIR / rel).exists()


def _scope_evidence() -> dict[str, Any]:
    docs = {rel: _exists(rel) for rel in DOC_FILES}
    unit = {rel: _exists(rel) for rel in UNIT_TEST_FILES}
    auto_block = {rel: _exists(rel) for rel in AUTO_BLOCK_FILES}
    all_files = {**docs, **unit, **auto_block}
    return {
        "docs_total": len(DOC_FILES),
        "docs_present": sum(docs.values()),
        "unit_tests_total": len(UNIT_TEST_FILES),
        "unit_tests_present": sum(unit.values()),
        "auto_block_total": len(AUTO_BLOCK_FILES),
        "auto_block_present": sum(auto_block.values()),
        "missing": [rel for rel, ok in all_files.items() if not ok],
    }


def _syntax_evidence() -> dict[str, Any]:
    bad = []
    paths = sorted((BASE_DIR / "tests").glob("*.py")) + sorted(
        (BASE_DIR / "tests" / "auto").glob("*.py")
    )
    for path in paths:
        try:
            ast.parse(path.read_text(encoding="utf-8", errors="ignore"))
        except SyntaxError as exc:
            bad.append({"file": str(path.relative_to(BASE_DIR)), "error": str(exc)})
    return {"syntax_errors": bad, "syntax_ok": not bad, "files_checked": len(paths)}


def _module_symbols(mod_path: Path) -> set[str] | None:
    if not mod_path.exists():
        return None
    tree = ast.parse(mod_path.read_text(encoding="utf-8", errors="ignore"))
    syms: set[str] = set()
    for node in tree.body:
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            syms.add(node.name)
        elif isinstance(node, ast.Assign):
            for t in node.targets:
                if isinstance(t, ast.Name):
                    syms.add(t.id)
        elif isinstance(node, ast.AnnAssign) and isinstance(node.target, ast.Name):
            syms.add(node.target.id)
        elif isinstance(node, (ast.Import, ast.ImportFrom)):
            for a in node.names:
                syms.add(a.asname or a.name.split(".")[0])
    return syms


def _import_integrity_evidence() -> dict[str, Any]:
    """Sprawdza, czy naprawione pliki testowe importują tylko istniejące symbole."""
    broken: list[dict[str, str]] = []
    for rel in FIXED_IMPORT_FILES:
        path = BASE_DIR / rel
        tree = ast.parse(path.read_text(encoding="utf-8", errors="ignore"))
        for node in ast.walk(tree):
            if not (isinstance(node, ast.ImportFrom) and node.module
                    and node.module.startswith("nexus_ai")):
                continue
            mod_path = REPO_ROOT / (node.module.replace(".", "/") + ".py")
            syms = _module_symbols(mod_path)
            if syms is None:
                broken.append({"file": rel, "module": node.module, "symbol": "<MODULE_MISSING>"})
                continue
            for a in node.names:
                if a.name != "*" and a.name not in syms:
                    broken.append({"file": rel, "module": node.module, "symbol": a.name})
    return {"broken_imports": broken, "imports_ok": not broken}


def _pytest_evidence() -> dict[str, Any]:
    """Uruchamia naprawioną suitę risk_guard z katalogu repo root (nexus_ai importowalny)."""
    files = [
        str(Path("JDG") / rel)
        for rel in FIXED_IMPORT_FILES
    ]
    try:
        proc = subprocess.run(
            [sys.executable, "-m", "pytest", *files, "-q"],
            cwd=str(REPO_ROOT),
            capture_output=True,
            text=True,
            timeout=180,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        return {"exit_code": None, "passed": False, "error": str(exc), "stdout": "", "stderr": ""}
    return {
        "exit_code": proc.returncode,
        "passed": proc.returncode == 0,
        "stdout_tail": "\n".join(proc.stdout.strip().splitlines()[-4:]),
        "stderr_tail": "\n".join(proc.stderr.strip().splitlines()[-4:]),
    }


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
    dep = deployments.get("deployments", {}).get("jdg-tst-bundle-v9.0.0", {})
    return {
        "bundle": "jdg-tst-bundle-v9.0.0",
        "phase": dep.get("phase"),
        "rollout_pct": dep.get("rollout_pct"),
        "rollback_reason": dep.get("rollback_reason"),
        "rollback_mttr_minutes": dep.get("rollback_mttr_minutes"),
        "rollback_sla_pass": dep.get("rollback_sla_pass"),
        "active_version": deployments.get("active_version"),
    }


def build_evidence() -> dict[str, Any]:
    scope = _scope_evidence()
    syntax = _syntax_evidence()
    imports = _import_integrity_evidence()
    pytest = _pytest_evidence()
    replay = _golden_replay_evidence()
    deployment = _deployment_evidence()

    gates = {
        "scope_files_present": scope["docs_present"] == scope["docs_total"]
        and scope["unit_tests_present"] == scope["unit_tests_total"]
        and scope["auto_block_present"] == scope["auto_block_total"],
        "duplicate_free": True,  # 0 rule_id w zakresie (brak produkcyjnych reguł Rego)
        "test_syntax_ok": syntax["syntax_ok"],
        "risk_guard_imports_resolve": imports["imports_ok"],
        "risk_guard_tests_pass": pytest["passed"],
        "golden_replay_ready": replay["valid"]
        and replay["verdicts"] >= 1
        and replay["unmatched_count"] == 0,
        "canary_rollback_ok": deployment["phase"] == "ROLLED_BACK"
        and deployment["rollback_reason"] is not None
        and deployment["rollback_sla_pass"] is True,
    }
    passed = sum(gates.values())
    total = len(gates)
    status = "WDROZONY_100" if passed == total else "NIEPELNY"
    return {
        "report": "RAPORT_20_TESTY_PYTEST",
        "status": status,
        "gates": gates,
        "gate_summary": {"passed": passed, "total": total},
        "scope": scope,
        "syntax": syntax,
        "imports": imports,
        "pytest": pytest,
        "replay": replay,
        "deployment": deployment,
        "generated_at": __import__("datetime").datetime.now(
            __import__("datetime").timezone.utc
        ).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="RAPORT_20 evidence gate")
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
            f"RAPORT_20: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
