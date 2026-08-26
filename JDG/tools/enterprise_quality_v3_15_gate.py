#!/usr/bin/env python3
"""V3-15 ENTERPRISE S1-S24 / NEURAL MESH / SCORING — deterministic evidence gate.

Przeprowadź głębokie myślenie i przeprowadź głęboką analizę przed zmianą progów:
gate nie udaje pełnej weryfikacji prawnej — sprawdza kompletność kontraktu
S1-S24, kalibrację scoringu, graf mesh, traceability i artefakty. OPA
check/test pozostaje osobną bramką CI, gdy CLI jest dostępne.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "bundles" / "enterprise_v3_registry.json"
EVIDENCE = ROOT / "bundles" / "enterprise_v3_audit_15.json"
REPORT = ROOT / "raporty_enterprise_v3" / "15_ENTERPRISE.txt"

SCOPE = [
    # Warstwa Enterprise / Neural Mesh / Scoring (lista promptu części 15)
    "rules/hyper_plan45_meta_enterprise.rego",
    "rules/enterprise_ai_neural_etap23_v1.rego",
    "rules/neural_mesh_v2_enterprise.rego",
    "rules/decision_scoring_enterprise.rego",
    "rules/cross_domain_intelligence_enterprise.rego",
    "rules/cross_domain_red_team_etap27_v1.rego",
    "rules/tax_optimization_enterprise.rego",
    "rules/neural_rule_mesh_enterprise.rego",
    "rules/decision_composer_enterprise.rego",
    # Kontrakt jakościowy V3-15 + infrastruktura
    "rules/enterprise/quality_v3_15.rego",
    "rules/thresholds_jdg.rego",
    "rules/main_jdg.rego",
    # Narzędzia Enterprise
    "tools/autonomous_tax_strategy.py",
    "tools/cross_domain_red_team_etap27_audit.py",
    "tools/penalty_calculator.py",
    "tools/decision_quality_monitor.py",
    # Testy
    "tests/test_enterprise_quality_v3_15.py",
    "tests/rego/test_native_enterprise_quality_v3_15.rego",
]

REQUIRED_RULE_MARKERS = [
    "initiative_registry_complete", "source_complete", "temporal_valid",
    "scoring_calibrated", "score_range_valid", "mesh_complete",
    "mesh_conflict_free", "composer_complete", "red_team_complete",
    "BLOCK_AND_ALERT", "TRIAGE_QUEUE", "no_auto_post", "DECOUPLED",
]
REQUIRED_LEGAL = ["PIT", "VAT", "OrdPU", "KKS", "SUS", "RODO"]
REQUIRED_INITIATIVE_IDS = [f"S{n}" for n in range(1, 25)]
REQUIRED_SNAPSHOT_KEYS = [
    "threshold_version", "registry_version", "legal_basis_version", "valid_from", "valid_to",
    "score_auto_post_min", "score_suggest_min", "score_abstain_max",
    "calibration_min_samples", "calibration_accuracy_min", "calibration_brier_max",
    "min_mesh_nodes", "min_mesh_edges", "min_red_team_scenarios",
    "no_auto_post", "manual_review_required",
]


def read(rel: str) -> str:
    try:
        return (ROOT / rel).read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return ""


def rule_ids(text: str) -> list[str]:
    return re.findall(r'"rule_id"\s*:\s*"([A-Za-z0-9_.-]+)"', text)


def audit_scope() -> dict[str, Any]:
    files = {rel: bool(read(rel)) for rel in SCOPE}
    return {
        "files_total": len(files),
        "files_present": sum(files.values()),
        "missing": [rel for rel, present in files.items() if not present],
        "scope_complete": all(files.values()),
    }


def audit_metadata() -> dict[str, Any]:
    texts = {rel: read(rel) for rel in SCOPE if rel.endswith(".rego")}
    ids = [rid for text in texts.values() for rid in rule_ids(text)]
    duplicates = sorted(rid for rid, count in Counter(ids).items() if count > 1)
    legal_hits = {marker: any(marker in text for text in texts.values()) for marker in REQUIRED_LEGAL}
    contract = texts.get("rules/enterprise/quality_v3_15.rego", "")
    # Rejestr S1-S24 jest generowany deklaratywnie (sprintf + numbers.range(1, 24)).
    s_range_present = bool(re.search(r"numbers\.range\(\s*1\s*,\s*24\s*\)", contract)) and 'sprintf("S%d"' in contract
    initiative_ids_present = set(REQUIRED_INITIATIVE_IDS) if s_range_present else {rid for rid in REQUIRED_INITIATIVE_IDS if f'"{rid}"' in contract}
    return {
        "rule_ids_total": len(ids),
        "rule_ids_unique": len(set(ids)),
        "duplicate_rule_ids": duplicates,
        "duplicate_free": not duplicates,
        "legal_markers": legal_hits,
        "legal_markers_complete": all(legal_hits.values()),
        "empty_legal_basis": sum(text.count('"_legal_basis":""') + text.count('"_legal_basis": ""') for text in texts.values()),
        "stub_lines": sum(len(re.findall(r"\}\s*\{\s*true\s*\}", text)) for text in texts.values()),
        "s1_s24_ids_in_contract": sorted(initiative_ids_present),
        "s1_s24_complete": len(initiative_ids_present) == 24,
    }


def audit_contract() -> dict[str, Any]:
    contract = read("rules/enterprise/quality_v3_15.rego")
    thresholds = read("rules/thresholds_jdg.rego")
    main = read("rules/main_jdg.rego")
    markers = {marker: marker in contract for marker in REQUIRED_RULE_MARKERS}
    snapshot_block = thresholds.split('enterprise_quality_v3_15 := {')[1].split("\n}")[0] if 'enterprise_quality_v3_15 := {' in thresholds else ""
    return {
        "contract_markers": markers,
        "contract_complete": all(markers.values()),
        "snapshot_present": "enterprise_quality_v3_15 := {" in thresholds,
        "snapshot_versioned": all(key in snapshot_block for key in REQUIRED_SNAPSHOT_KEYS),
        "import_present": "import data.jdg.enterprise.quality_v3_15 as enterprise_quality_v3_15" in main,
        "p75_present": "final_verdict_p75 = safe_merge(final_verdict_p74" in main,
        "post_merge_uses_p75": "final_verdict_p75\n" in main or "final_verdict_p75)" in main or "final_verdict_p75," in main,
        "no_auto_post_guard": '"no_auto_post": true' in contract,
    }


def audit_tools() -> dict[str, Any]:
    return {
        "autonomous_tax_strategy": bool(read("tools/autonomous_tax_strategy.py")),
        "red_team_audit": bool(read("tools/cross_domain_red_team_etap27_audit.py")),
        "penalty_calculator": bool(read("tools/penalty_calculator.py")),
        "decision_quality_monitor": bool(read("tools/decision_quality_monitor.py")),
    }


def audit_tests() -> dict[str, Any]:
    pytest_text = read("tests/test_enterprise_quality_v3_15.py")
    native_text = read("tests/rego/test_native_enterprise_quality_v3_15.rego")
    joined = pytest_text + native_text
    required = ["full_contract", "fail_closed", "calibration", "mesh", "red_team", "no_auto_post"]
    hits = {marker: marker.lower() in joined.lower() for marker in required}
    return {
        "pytest_present": bool(pytest_text),
        "native_rego_present": bool(native_text),
        "markers": hits,
        "tests_complete": all(hits.values()),
        "pytest_functions": len(re.findall(r"def test_", pytest_text)),
    }


def opa_check() -> dict[str, Any]:
    try:
        proc = subprocess.run(["opa", "check", "-b", str(ROOT / "rules")], cwd=ROOT, text=True, capture_output=True, timeout=30)
    except (OSError, subprocess.SubprocessError):
        return {"available": False, "passed": None, "message": "OPA CLI unavailable locally; CI gate required."}
    return {"available": True, "passed": proc.returncode == 0, "message": (proc.stdout + proc.stderr)[-4000:]}


def build() -> dict[str, Any]:
    scope = audit_scope()
    metadata = audit_metadata()
    contract = audit_contract()
    tools = audit_tools()
    tests = audit_tests()
    opa = opa_check()
    gates = {
        "scope_complete": scope["scope_complete"],
        "metadata_complete": metadata["duplicate_free"] and metadata["legal_markers_complete"] and metadata["empty_legal_basis"] == 0,
        "s1_s24_complete": metadata["s1_s24_complete"],
        "contract_complete": contract["contract_complete"] and contract["snapshot_present"] and contract["snapshot_versioned"],
        "router_wired": contract["import_present"] and contract["p75_present"] and contract["post_merge_uses_p75"],
        "tools_complete": all(tools.values()),
        "tests_complete": tests["tests_complete"],
        "report_present": REPORT.exists(),
        "registry_present": REGISTRY.exists(),
    }
    passed = sum(gates.values())
    return {
        "report": "V3-15_ENTERPRISE",
        "status": "WDROZONY_100" if passed == len(gates) else "NIEPELNY",
        "gates": gates,
        "gate_summary": {"passed": passed, "total": len(gates)},
        "scope": scope,
        "metadata": metadata,
        "contract": contract,
        "tools": tools,
        "tests": tests,
        "opa": opa,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    evidence = build()
    if args.write:
        EVIDENCE.write_text(json.dumps(evidence, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"Evidence: {EVIDENCE.relative_to(ROOT)} ({evidence['status']})")
    elif args.json:
        print(json.dumps(evidence, indent=2, ensure_ascii=False))
    else:
        passed = evidence["gate_summary"]["passed"]
        total = evidence["gate_summary"]["total"]
        print(f"V3-15 ENTERPRISE gate: {passed}/{total} PASS ({evidence['status']})")
    failed = [name for name, ok in evidence["gates"].items() if not ok]
    if failed:
        print(f"FAILED gates: {', '.join(failed)}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
