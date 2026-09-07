#!/usr/bin/env python3
"""V3-16 NARZĘDZIA + BRAMKI JAKOŚCI + GAP REPORTS — deterministic evidence gate.

Przeprowadź głębokie myślenie i przeprowadź głęboką analizę przed zmianą progów:
gate nie uruchamia linterów sam — bramkuje ich WYNIKI (evidence) względem
kontraktu tools_quality_v3_16. OPA check/test pozostaje osobną bramką CI.
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
EVIDENCE = ROOT / "bundles" / "quality_gates_v3_audit_16.json"
REPORT = ROOT / "raporty_enterprise_v3" / "16_GATES.txt"

SCOPE = [
    # Lintery i walidatory (lista promptu części 16)
    "tools/lint_rego_rules.py",
    "tools/validate_rules.py",
    "tools/dead_rule_detector.py",
    "tools/tautology_guard.py",
    "tools/else_chain_dead_code_detector.py",
    "tools/hardcoded_audit_gate.py",
    # Gap reports
    "tools/legal_coverage_gap_report.py",
    "tools/legal_coverage_heatmap.py",
    "tools/traceability_matrix.py",
    "tools/coverage_95_plan.py",
    "tools/legal_basis_audit.py",
    # Spójność
    "tools/doc_consistency_validator.py",
    "tools/cross_ref_validator.py",
    "tools/inventory_reconciliation.py",
    "tools/manifest_v2.py",
    # Bramki quality gates
    "tools/test_coverage_gate.py",
    "tools/validate_enterprise_contract.py",
    "tools/temporal_interval_gate.py",
    # Kontrakt jakościowy + infrastruktura + testy
    "rules/tools/quality_v3_16.rego",
    "rules/thresholds_jdg.rego",
    "rules/main_jdg.rego",
    "tests/test_tools_quality_v3_16.py",
    "tests/rego/test_native_tools_quality_v3_16.rego",
]

REQUIRED_RULE_MARKERS = [
    "linters_complete", "validators_complete", "gap_reports_complete",
    "coverage_ok", "tautology_gate_pass", "dead_code_gate_pass",
    "hardcode_gate_pass", "manifest_ok", "temporal_valid",
    "BLOCK_AND_ALERT", "TRIAGE_QUEUE", "no_auto_post", "DECOUPLED",
]
REQUIRED_LEGAL = ["OrdPU", "PIT", "VAT", "KKS"]
REQUIRED_SNAPSHOT_KEYS = [
    "threshold_version", "registry_version", "legal_basis_version", "valid_from", "valid_to",
    "required_linters", "required_validators", "required_gap_reports",
    "coverage_target_pct", "max_tautologies", "max_dead_criticals",
    "max_hardcode_findings", "manifest_diff_blocking", "no_auto_post",
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
    return {
        "rule_ids_total": len(ids),
        "rule_ids_unique": len(set(ids)),
        "duplicate_rule_ids": duplicates,
        "duplicate_free": not duplicates,
        "legal_markers": legal_hits,
        "legal_markers_complete": all(legal_hits.values()),
        "empty_legal_basis": sum(text.count('"_legal_basis":""') + text.count('"_legal_basis": ""') for text in texts.values()),
    }


def audit_contract() -> dict[str, Any]:
    contract = read("rules/tools/quality_v3_16.rego")
    thresholds = read("rules/thresholds_jdg.rego")
    main = read("rules/main_jdg.rego")
    markers = {marker: marker in contract for marker in REQUIRED_RULE_MARKERS}
    snap_idx = thresholds.find("tools_quality_v3_16 := {")
    snapshot_block = thresholds[snap_idx:].split("\n}")[0] if snap_idx >= 0 else ""
    return {
        "contract_markers": markers,
        "contract_complete": all(markers.values()),
        "snapshot_present": "tools_quality_v3_16 := {" in thresholds,
        "snapshot_versioned": all(key in snapshot_block for key in REQUIRED_SNAPSHOT_KEYS),
        "import_present": "import data.jdg.tools.quality_v3_16 as tools_quality_v3_16" in main,
        "p76_present": "final_verdict_p76 = safe_merge(final_verdict_p75" in main,
        "post_merge_anchor_current": bool(re.search(r"final_verdict_post_merge = safe_merge\(\s*\{\"_routing_context\": routing_context\},\s*final_verdict_(p7[4-9]|p8[0-9]|p9[0-9])", main)),
        "no_auto_post_guard": '"no_auto_post": true' in contract,
    }


def audit_tools() -> dict[str, Any]:
    lint = read("tools/lint_rego_rules.py")
    return {
        "lint_checks_six": all(name in lint for name in [
            "check_matched_true_required", "check_no_fallback_allow", "check_rule_id_canonical",
            "check_no_hardcoded_integers", "check_legal_basis_required", "check_temporal_validity"]),
        "dead_rule_detector": "dead" in read("tools/dead_rule_detector.py").lower(),
        "tautology_guard": bool(read("tools/tautology_guard.py")),
        "else_chain_detector": bool(read("tools/else_chain_dead_code_detector.py")),
        "hardcoded_audit_gate": bool(read("tools/hardcoded_audit_gate.py")),
        "gap_report": bool(read("tools/legal_coverage_gap_report.py")),
        "heatmap": bool(read("tools/legal_coverage_heatmap.py")),
        "traceability": bool(read("tools/traceability_matrix.py")),
        "coverage_95": bool(read("tools/coverage_95_plan.py")),
        "manifest_v2": bool(read("tools/manifest_v2.py")),
    }


def audit_tests() -> dict[str, Any]:
    pytest_text = read("tests/test_tools_quality_v3_16.py")
    native_text = read("tests/rego/test_native_tools_quality_v3_16.rego")
    joined = pytest_text + native_text
    required = ["full_contract", "fail_closed", "coverage", "hardcode", "manifest", "no_auto_post"]
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
        "contract_complete": contract["contract_complete"] and contract["snapshot_present"] and contract["snapshot_versioned"],
        "router_wired": contract["import_present"] and contract["p76_present"] and contract["post_merge_anchor_current"],
        "tools_complete": all(tools.values()),
        "tests_complete": tests["tests_complete"],
        "report_present": REPORT.exists(),
        "registry_present": REGISTRY.exists(),
    }
    passed = sum(gates.values())
    return {
        "report": "V3-16_GATES",
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
    parser = argparse.ArgumentParser(description="Tools/quality gates V3-16 evidence gate")
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
        print(f"V3-16 GATES gate: {passed}/{total} PASS ({evidence['status']})")
    failed = [name for name, ok in evidence["gates"].items() if not ok]
    if failed:
        print(f"FAILED gates: {', '.join(failed)}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
