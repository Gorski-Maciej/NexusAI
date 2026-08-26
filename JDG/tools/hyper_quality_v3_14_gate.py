#!/usr/bin/env python3
"""V3-14 HYPER CTX Plan44/45 — deterministic evidence gate.

Gate nie udaje pełnej weryfikacji prawnej: sprawdza kompletność kontraktu,
traceability i artefaktów. OPA check/test pozostaje osobną bramką CI, gdy CLI
jest dostępne.
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
EVIDENCE = ROOT / "bundles" / "hyper_quality_v3_audit_14.json"
REPORT = ROOT / "raporty_enterprise_v3" / "14_HYPER_CTX.txt"

SCOPE = [
    "rules/jdg/hyper/general/plan45.rego",
    "rules/jdg/hyper/deadlines/plan45.rego",
    "rules/jdg/hyper/limits/plan45.rego",
    "rules/jdg/hyper/sanctions/plan45.rego",
    "rules/jdg/hyper/mdr/plan45.rego",
    "rules/jdg/hyper/fx/plan45.rego",
    "rules/jdg/hyper/audit/plan45.rego",
    "rules/jdg/hyper/family/plan45.rego",
    "rules/jdg/hyper/force_majeure/plan45.rego",
    "rules/jdg/hyper/edelivery/plan45.rego",
    "rules/jdg/hyper/procurement/plan45.rego",
    "rules/jdg/hyper/solidarity/plan45.rego",
    "rules/jdg/hyper/wis/plan45.rego",
    "rules/calendar/plan44_calendar.rego",
    "rules/calendar/plan45_calendar.rego",
    "rules/conviction/plan44_conviction.rego",
    "rules/conviction/plan45_conviction.rego",
    "rules/edelivery/plan44_edelivery.rego",
    "rules/family/plan44_family.rego",
    "rules/fx/plan44_fx.rego",
    "rules/insurance/plan44_insurance.rego",
    "rules/hyper/quality_v3_14.rego",
    "rules/main_jdg.rego",
    "rules/thresholds_jdg.rego",
    "tools/deadline_engine.py",
    "tools/legal_change_calendar.py",
    "tools/limits_registry.py",
    "tools/sanction_calculator.py",
    "tools/hyper_quality.py",
    "tests/test_hyper_plan45_enterprise.py",
    "tests/test_hyper_quality_v3_14.py",
    "tests/rego/test_native_hyper_quality_v3_14.rego",
]

REQUIRED_RULE_MARKERS = [
    "registry_complete", "source_complete", "temporal_valid", "deadline_complete",
    "limits_complete", "sanction_complete", "force_majeure_complete",
    "fx_complete", "edelivery_complete", "graph_complete", "binding_complete",
    "BLOCK_AND_ALERT", "TRIAGE_QUEUE", "no_auto_post", "DECOUPLED",
]
REQUIRED_LEGAL = ["OrdPU", "PIT", "VAT", "SUS", "MDR", "eIDAS"]


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
        "empty_legal_basis": sum(text.count('"_legal_basis":""') for text in texts.values()),
        "stub_lines": sum(len(re.findall(r"\}\s*\{\s*true\s*\}", text)) for text in texts.values()),
    }


def audit_contract() -> dict[str, Any]:
    contract = read("rules/hyper/quality_v3_14.rego")
    thresholds = read("rules/thresholds_jdg.rego")
    main = read("rules/main_jdg.rego")
    markers = {marker: marker in contract for marker in REQUIRED_RULE_MARKERS}
    return {
        "contract_markers": markers,
        "contract_complete": all(markers.values()),
        "snapshot_present": "hyper_quality_v3_14 := {" in thresholds,
        "snapshot_versioned": all(key in thresholds for key in ["threshold_version", "registry_version", "valid_from", "valid_to"]),
        "import_present": "import data.jdg.hyper.quality_v3_14" in main,
        "p74_present": "final_verdict_p74 = safe_merge(final_verdict_p73" in main,
        "post_merge_uses_p74": bool(re.search(r"final_verdict_(p7[4-9]|p8[0-5])\n\)", main)),
        "no_auto_post_guard": '"no_auto_post": true' in contract,
    }


def audit_tests() -> dict[str, Any]:
    joined = read("tests/test_hyper_quality_v3_14.py") + read("tests/rego/test_native_hyper_quality_v3_14.rego")
    required = ["full_contract", "fail_closed", "temporal", "deadline", "limit", "sanction", "no_auto_post"]
    hits = {marker: marker in joined for marker in required}
    return {
        "pytest_present": bool(read("tests/test_hyper_quality_v3_14.py")),
        "native_rego_present": bool(read("tests/rego/test_native_hyper_quality_v3_14.rego")),
        "markers": hits,
        "tests_complete": all(hits.values()),
        "pytest_functions": len(re.findall(r"def test_", read("tests/test_hyper_quality_v3_14.py"))),
    }


def audit_tools() -> dict[str, Any]:
    return {
        "deadline_engine": "next_working_day" in read("tools/deadline_engine.py") and "OBLIGATIONS" in read("tools/deadline_engine.py"),
        "legal_calendar": "LEAD_TARGET_DAYS" in read("tools/legal_change_calendar.py"),
        "limits_registry": "ALERT_RATIO" in read("tools/limits_registry.py"),
        "sanction_calculator": "MITIGATION" in read("tools/sanction_calculator.py"),
        "hyper_quality": "duplicate" in read("tools/hyper_quality.py").lower(),
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
    tests = audit_tests()
    tools = audit_tools()
    opa = opa_check()
    gates = {
        "scope_complete": scope["scope_complete"],
        "metadata_complete": metadata["duplicate_free"] and metadata["legal_markers_complete"] and metadata["empty_legal_basis"] == 0,
        "contract_complete": contract["contract_complete"] and contract["snapshot_present"] and contract["snapshot_versioned"],
        "router_wired": contract["import_present"] and contract["p74_present"] and contract["post_merge_uses_p74"],
        "tests_complete": tests["tests_complete"],
        "tools_complete": all(tools.values()),
        "report_present": REPORT.exists(),
        "registry_present": REGISTRY.exists(),
    }
    passed = sum(gates.values())
    return {
        "report": "V3-14_HYPER_CTX",
        "status": "WDROZONY_100" if passed == len(gates) else "NIEPELNY",
        "gates": gates,
        "gate_summary": {"passed": passed, "total": len(gates)},
        "scope": scope,
        "metadata": metadata,
        "contract": contract,
        "tests": tests,
        "tools": tools,
        "opa": opa,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()
    evidence = build()
    if args.write:
        EVIDENCE.write_text(json.dumps(evidence, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"Evidence: {EVIDENCE.relative_to(ROOT)} ({evidence['status']})")
    elif args.json:
        print(json.dumps(evidence, indent=2, ensure_ascii=False))
    else:
        print(f"V3-14: {evidence['status']} ({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})")
        for name, ok in evidence["gates"].items():
            print(f"  {'PASS' if ok else 'FAIL'} {name}")
    return 1 if args.strict and evidence["status"] != "WDROZONY_100" else 0


if __name__ == "__main__":
    sys.exit(main())
