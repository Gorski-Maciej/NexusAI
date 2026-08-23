#!/usr/bin/env python3
"""Evidence gate for RAPORT_17 Hyper Plan45 and Enterprise Contexts."""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

BASE_DIR = Path(__file__).resolve().parents[1]
BUNDLES_DIR = BASE_DIR / "bundles"
PROMPT = "prompty_glm52_enterprise/PROMPT_17_HYPER_PLAN45.txt"
REPORT = "raporty_glm52_enterprise/RAPORT_17_HYPER_PLAN45.txt"
PACKAGE = "rules/hyper_enterprise_contexts_etap22_v1.rego"
META = "rules/hyper_plan45_meta_enterprise.rego"
R13 = "rules/r13_hyper_konteksty_innovations_v9.rego"
MAIN = "rules/main_jdg.rego"
THRESHOLDS = "rules/thresholds_jdg.rego"
AUDIT = "tools/hyper_enterprise_contexts_etap22_audit.py"
PYTEST = "tests/test_hyper_enterprise_contexts_etap22_audit.py"
NATIVE = "tests/rego/test_native_hyper_enterprise_contexts_etap22.rego"
BUNDLE = BUNDLES_DIR / "hyper_plan45_report17_evidence.json"

CORE_FILES = [
    "rules/jdg/hyper/general/plan45.rego", "rules/jdg/hyper/deadlines/plan45.rego",
    "rules/jdg/hyper/limits/plan45.rego", "rules/jdg/hyper/mdr/plan45.rego",
    "rules/jdg/hyper/sanctions/plan45.rego", "rules/jdg/hyper/audit/plan45.rego",
    "rules/jdg/hyper/fx/plan45.rego", "rules/jdg/hyper/wis/plan45.rego",
    "rules/jdg/hyper/edelivery/plan45.rego", "rules/jdg/hyper/misc/plan45.rego",
    "rules/jdg/hyper/family/plan45.rego", "rules/jdg/hyper/force_majeure/plan45.rego",
    "rules/jdg/hyper/procurement/plan45.rego", "rules/jdg/hyper/solidarity/plan45.rego",
    "rules/advertising/plan45_advertising.rego", "rules/calendar/plan45_calendar.rego",
    "rules/conviction/plan45_conviction.rego", "rules/esig/plan45_esig.rego",
    "rules/insurance/plan45_insurance.rego", "rules/payments/plan45_payments.rego",
    "rules/procurement/plan45_procurement.rego", "rules/regulated/plan45_regulated.rego",
    "rules/residency/plan45_residency.rego", "rules/seasonal/plan45_seasonal.rego",
    "rules/solidarity/plan45_solidarity.rego", "rules/taxfree/plan45_taxfree.rego",
    "rules/hyper_plan45_meta_enterprise.rego", R13, PACKAGE,
    "tools/deadline_engine.py", "tools/limits_registry.py", "tools/sanction_calculator.py",
    "tools/hyper_quality.py", AUDIT, PYTEST, NATIVE,
]

MARKERS = [
    "context_catalog", "context_registry_complete", "output_contract_complete", "input_hash",
    "evidence_ref", "test_ref", "recipient", "deadline_engine", "limits_registry",
    "dependency_graph", "conflict_detector", "priority_validation", "territorial_validation",
    "mdr_complete", "sanctions_complete", "fx_complete", "wis_complete", "edelivery_complete",
    "manual_review_required", "BLOCK_AND_ALERT", "TRIAGE_QUEUE", 'decision_mode := "SUGGEST"',
    '"no_auto_post": true', "valid_from", "valid_to", "facts_version", "threshold_version",
]
LEGAL = ["PIT art. 30ca", "30h", "45", "OrdPU art. 12", "126", "MDR", "eIDAS", "doręczeniach elektronicznych", "KKS"]


def read(rel: str) -> str:
    try:
        return (BASE_DIR / rel).read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def build_evidence() -> dict[str, Any]:
    package = read(PACKAGE)
    statuses = {rel: bool(read(rel)) for rel in CORE_FILES}
    ids = re.findall(r'"rule_id"\s*:\s*"([A-Za-z0-9_.-]+)"', "\n".join(read(rel) for rel in CORE_FILES if rel.endswith(".rego")))
    duplicates = sorted(rid for rid, count in Counter(ids).items() if count > 1)
    main = read(MAIN)
    thresholds = read(THRESHOLDS)
    markers = {m: m in package for m in MARKERS}
    legal = {m: m in package for m in LEGAL}
    try:
        golden = json.loads((BUNDLES_DIR / "golden_verdicts.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        golden = {}
    verdicts = golden.get("verdicts", {})
    replays = golden.get("replays", [])
    if not isinstance(replays, list):
        replays = []
    selected = [v for v in verdicts.values() if "hyper" in json.dumps(v, ensure_ascii=False).lower() or "solidarity" in json.dumps(v, ensure_ascii=False).lower()]
    unmatched = golden.get("unmatched_replays", [])
    if not isinstance(unmatched, list):
        unmatched = []
    try:
        deployments = json.loads((BUNDLES_DIR / "deployments.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        deployments = {}
    dep = deployments.get("deployments", {}).get("jdg-hp-bundle-v9.0.0", {})
    gates = {
        "prompt_and_report_present": bool(read(PROMPT)) and bool(read(REPORT)),
        "core_scope_complete": all(statuses.values()),
        "package_contract": package.startswith("#") and "package jdg.hyper_enterprise_contexts_etap22" in package and package.count("{") == package.count("}") and not duplicates and all(markers.values()),
        "legal_traceability": all(legal.values()),
        "thresholds_externalized": 'object.get(object.get(data, "jdg", {}), "thresholds", {})' in package and "hyper_enterprise_contexts_etap22 := {" in thresholds,
        "router_wired": all(x in main for x in ["import data.jdg.hyper_enterprise_contexts_etap22", '"jdg.hyper_enterprise_contexts_etap22": hyper_enterprise_contexts_etap22.decide', "final_verdict_p66 = safe_merge(final_verdict_p65", "object.union(final_verdict_p66", "final_verdict = final_verdict_enforced"]),
        "tests_present": bool(read(PYTEST)) and bool(read(NATIVE)) and bool(read(AUDIT)),
        "golden_replay_ok": bool(selected) and not unmatched,
        "rollback_fail_closed": dep.get("phase") == "ROLLED_BACK" and bool(dep.get("rollback_reason")),
    }
    passed = sum(gates.values())
    return {
        "report": "RAPORT_17_HYPER_PLAN45",
        "status": "WDROZONY_100" if passed == len(gates) else "NIEPELNY",
        "gates": gates,
        "gate_summary": {"passed": passed, "total": len(gates)},
        "scope": {"declared": len(statuses), "present": sum(statuses.values()), "all_present": all(statuses.values()), "files": statuses},
        "package": {"rule_ids": len(ids), "unique_rule_ids": len(set(ids)), "duplicates": duplicates, "markers": markers, "legal": legal},
        "replay": {"selected_verdicts": len(selected), "replays": len(replays), "unmatched": len(unmatched)},
        "deployment": {"phase": dep.get("phase"), "rollback_reason": dep.get("rollback_reason"), "active_version": deployments.get("active_version")},
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="RAPORT_17 Hyper Plan45 evidence gate")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()
    evidence = build_evidence()
    if args.write:
        BUNDLE.write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Evidence: {BUNDLE.name} ({evidence['status']})")
    elif args.json:
        print(json.dumps(evidence, ensure_ascii=False, indent=2))
    else:
        print(f"RAPORT_17: {evidence['status']} ({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})")
        for name, ok in evidence["gates"].items():
            print(f"  {'PASS' if ok else 'FAIL'} {name}")
    return 0 if not args.strict or evidence["status"] == "WDROZONY_100" else 1


if __name__ == "__main__":
    sys.exit(main())
