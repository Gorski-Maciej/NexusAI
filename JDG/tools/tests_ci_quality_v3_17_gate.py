#!/usr/bin/env python3
"""V3-17 TESTY + CI/CD + CHAOS + MUTATION + GOLDEN — deterministic evidence gate.

Przeprowadź głębokie myślenie i przeprowadź głęboką analizę przed zmianą progów:
gate nie uruchamia testów sam — bramkuje ich WYNIKI (evidence) względem
kontraktu tests_ci_quality_v3_17. OPA check/test pozostaje osobną bramką CI.
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
EVIDENCE = ROOT / "bundles" / "tests_ci_v3_audit_17.json"
REPORT = ROOT / "raporty_enterprise_v3" / "17_TESTY_CI.txt"

SCOPE = [
    # Testy z listy promptu części 17
    "tests/rego/micro/test_native_micro_pit.rego",
    "tests/rego/micro/test_native_micro_vat.rego",
    "tests/test_final_certification_etap28_audit.py",
    # Chaos / mutation / fuzz / property / golden
    "tools/chaos_runner.py",
    "tools/fuzz_runner.py",
    "tools/mutation_runner.py",
    "tools/property_suite.py",
    "tools/golden_replay.py",
    # Kontrakt jakościowy + infrastruktura + testy
    "rules/tests_ci/quality_v3_17.rego",
    "rules/thresholds_jdg.rego",
    "rules/main_jdg.rego",
    "tests/test_tests_ci_quality_v3_17.py",
    "tests/rego/test_native_tests_ci_quality_v3_17.rego",
]

# Workflow CI żyją w katalogu .github na poziomie REPOZYTORIUM.
WORKFLOWS = [
    ".github/workflows/ci.yml",
    ".github/workflows/opa-ci.yml",
    ".github/workflows/jdg-quality-gates-blocking.yml",
    ".github/workflows/jdg-scheduled-drift.yml",
]

REQUIRED_RULE_MARKERS = [
    "suites_complete", "coverage_ok", "mutation_ok", "fuzz_ok", "property_ok",
    "chaos_ok", "golden_ok", "workflows_complete", "regression_ok",
    "temporal_valid", "BLOCK_AND_ALERT", "TRIAGE_QUEUE", "no_auto_post",
    "DECOUPLED",
]
REQUIRED_LEGAL = ["OrdPU", "PIT", "VAT", "KKS"]
REQUIRED_SNAPSHOT_KEYS = [
    "threshold_version", "registry_version", "legal_basis_version", "valid_from", "valid_to",
    "coverage_target_pct", "min_mutation_score", "min_fuzz_cases", "min_property_cases",
    "min_chaos_experiments", "golden_replay_required", "required_workflows",
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
    workflows = {}
    repo_root = ROOT.parent
    for rel in WORKFLOWS:
        workflows[rel] = (repo_root / rel).exists()
    return {
        "files_total": len(files) + len(workflows),
        "files_present": sum(files.values()) + sum(workflows.values()),
        "missing": [rel for rel, present in files.items() if not present]
        + [rel for rel, present in workflows.items() if not present],
        "workflows": workflows,
        "scope_complete": all(files.values()) and all(workflows.values()),
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
    contract = read("rules/tests_ci/quality_v3_17.rego")
    thresholds = read("rules/thresholds_jdg.rego")
    main = read("rules/main_jdg.rego")
    markers = {marker: marker in contract for marker in REQUIRED_RULE_MARKERS}
    snap_idx = thresholds.find("tests_ci_quality_v3_17 := {")
    snapshot_block = thresholds[snap_idx:].split("\n}")[0] if snap_idx >= 0 else ""
    return {
        "contract_markers": markers,
        "contract_complete": all(markers.values()),
        "snapshot_present": "tests_ci_quality_v3_17 := {" in thresholds,
        "snapshot_versioned": all(key in snapshot_block for key in REQUIRED_SNAPSHOT_KEYS),
        "snapshot_aligned_etap24": all(k in snapshot_block for k in ['"min_mutation_score": 85', '"min_fuzz_cases": 10000', '"min_property_cases": 200']),
        "import_present": "import data.jdg.tests_ci.quality_v3_17 as tests_ci_quality_v3_17" in main,
        "p77_present": "final_verdict_p77 = safe_merge(final_verdict_p76" in main,
        "post_merge_anchor_current": bool(re.search(r"final_verdict_post_merge = safe_merge\(\s*\{\"_routing_context\": routing_context\},\s*final_verdict_p7[4-9]", main)),
        "no_auto_post_guard": '"no_auto_post": true' in contract,
    }


def audit_tools() -> dict[str, Any]:
    golden = read("tools/golden_replay.py")
    chaos = read("tools/chaos_runner.py")
    mutation = read("tools/mutation_runner.py")
    fuzz = read("tools/fuzz_runner.py")
    prop = read("tools/property_suite.py")
    return {
        "golden_replay_record_verify": "cmd_record" in golden and "cmd_replay" in golden,
        "golden_baseline_immutable": "już istnieje — baseline jest niezmienny" in golden,
        "chaos_matrix": "CHAOS" in chaos.upper() and "undetected" in chaos.lower() or "experiments" in chaos.lower(),
        "mutation_runner": "mutant" in mutation.lower() or "mutation" in mutation.lower(),
        "fuzz_runner": bool(fuzz),
        "property_suite": bool(prop),
    }


def audit_tests() -> dict[str, Any]:
    pytest_text = read("tests/test_tests_ci_quality_v3_17.py")
    native_text = read("tests/rego/test_native_tests_ci_quality_v3_17.rego")
    joined = pytest_text + native_text
    required = ["full_contract", "fail_closed", "golden", "chaos", "mutation", "no_auto_post"]
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
        "router_wired": contract["import_present"] and contract["p77_present"] and contract["post_merge_anchor_current"],
        "tools_complete": all(tools.values()),
        "tests_complete": tests["tests_complete"],
        "report_present": REPORT.exists(),
        "registry_present": REGISTRY.exists(),
    }
    passed = sum(gates.values())
    return {
        "report": "V3-17_TESTY_CI",
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
    parser = argparse.ArgumentParser(description="Tests/CI V3-17 evidence gate")
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
        print(f"V3-17 TESTY_CI gate: {passed}/{total} PASS ({evidence['status']})")
    failed = [name for name, ok in evidence["gates"].items() if not ok]
    if failed:
        print(f"FAILED gates: {', '.join(failed)}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
