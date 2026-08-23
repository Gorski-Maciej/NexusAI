#!/usr/bin/env python3
"""Evidence gate for RAPORT_18 Enterprise AI / Neural Mesh."""
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
PROMPT = "prompty_glm52_enterprise/PROMPT_18_ENTERPRISE_AI_NEURAL.txt"
REPORT = "raporty_glm52_enterprise/RAPORT_18_ENTERPRISE_AI_NEURAL.txt"
PACKAGE = "rules/enterprise_ai_neural_etap23_v1.rego"
MAIN = "rules/main_jdg.rego"
THRESHOLDS = "rules/thresholds_jdg.rego"
AUDIT = "tools/enterprise_ai_neural_etap23_audit.py"
PYTEST = "tests/test_enterprise_ai_neural_etap23_audit.py"
NATIVE = "tests/rego/test_native_enterprise_ai_neural_etap23.rego"
BUNDLE = BUNDLES_DIR / "enterprise_ai_neural_report18_evidence.json"

CORE_FILES = [
    PACKAGE, MAIN, THRESHOLDS,
    "rules/adaptive_trust_scoring_enterprise.rego", "rules/neural_rule_mesh_enterprise.rego",
    "rules/neural_mesh_v2_enterprise.rego", "rules/cashflow_tax_predictor_enterprise.rego",
    "rules/banking_automation_enterprise.rego", "rules/strategic_advisor_enterprise.rego",
    "rules/legislative_monitor_enterprise.rego", "rules/r17_enterprise_ai_innovations_v9.rego",
    "tools/decision_quality_monitor.py", "tools/adaptive_trust_score.py",
    "tools/neural_mesh_innovations_auditor.py", AUDIT, PYTEST, NATIVE,
    "docs/NEURAL_MESH_INNOWACJE_P20.md", "docs/PEWNOSC_DASHBOARD.md",
]

MARKERS = [
    "context_complete", "source_complete", "prediction_separation", "prediction_evidence",
    "calibration_complete", "drift_ok", "quality_complete", "bias_safety_complete",
    "explainability_complete", "llm_safe", "feedback_complete", "cashflow_complete",
    "banking_complete", "manual_review_required", "legal_verdict_authority",
    "DETERMINISTIC_REGO", "ADVISORY_ONLY", "BLOCK_AND_ALERT", "TRIAGE_QUEUE",
    "decision_mode := \"SUGGEST\"", "no_auto_post", "valid_from", "valid_to",
    "facts_version", "threshold_version", "input_hash", "source_refs", "legal_nodes",
]
LEGAL = ["RODO art. 5", "RODO art. 22", "RODO art. 25", "PIT art. 44", "VAT art. 103", "OrdPU art. 4", "PSD2", "ADR-006", "ADR-022"]


def read(rel: str) -> str:
    try:
        return (BASE_DIR / rel).read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def build_evidence() -> dict[str, Any]:
    package = read(PACKAGE)
    statuses = {rel: bool(read(rel)) for rel in CORE_FILES}
    ids = re.findall(r'"rule_id"\s*:\s*"([A-Za-z0-9_.-]+)"', package)
    duplicates = sorted(rid for rid, count in Counter(ids).items() if count > 1)
    markers = {m: m in package for m in MARKERS}
    legal = {m: m in package for m in LEGAL}
    main = read(MAIN)
    thresholds = read(THRESHOLDS)
    try:
        golden = json.loads((BUNDLES_DIR / "golden_verdicts.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        golden = {}
    verdicts = golden.get("verdicts", {})
    replays = golden.get("replays", [])
    if not isinstance(replays, list):
        replays = []
    selected = [v for v in verdicts.values() if "adaptive_trust" in json.dumps(v, ensure_ascii=False) or "neural" in json.dumps(v, ensure_ascii=False).lower() or "ai" in json.dumps(v, ensure_ascii=False).lower()]
    unmatched = golden.get("unmatched_replays", [])
    if not isinstance(unmatched, list):
        unmatched = []
    try:
        deployments = json.loads((BUNDLES_DIR / "deployments.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        deployments = {}
    dep = deployments.get("deployments", {}).get("jdg-eai-bundle-v9.0.0", {})
    gates = {
        "prompt_and_report_present": bool(read(PROMPT)) and bool(read(REPORT)),
        "scope_complete": all(statuses.values()),
        "package_contract": "package jdg.enterprise_ai_neural_etap23" in package and package.count("{") == package.count("}") and package.count("(") == package.count(")") and not duplicates and all(markers.values()),
        "legal_traceability": all(legal.values()),
        "prediction_separation": '"legal_verdict_authority": "DETERMINISTIC_REGO"' in package and '"prediction_role": "ADVISORY_ONLY"' in package and '"ai_may_decide_legal": true' not in package,
        "quality_and_safety": all(markers[m] for m in ["calibration_complete", "drift_ok", "quality_complete", "bias_safety_complete", "explainability_complete", "llm_safe"]),
        "domain_feedback_controls": all(markers[m] for m in ["feedback_complete", "cashflow_complete", "banking_complete"]),
        "router_wired": all(x in main for x in ["import data.jdg.enterprise_ai_neural_etap23", '"jdg.enterprise_ai_neural_etap23": enterprise_ai_neural_etap23.decide', "final_verdict_p67 = safe_merge(final_verdict_p66", "object.union(final_verdict_p67", "final_verdict = final_verdict_enforced"]),
        "thresholds_externalized": "enterprise_ai_neural_etap23 := {" in thresholds and "calibration_min_samples" in thresholds and "max_population_stability_index" in thresholds,
        "tests_and_replay": bool(read(PYTEST)) and bool(read(NATIVE)) and bool(read(AUDIT)) and bool(selected) and not unmatched,
        "rollback_fail_closed": dep.get("phase") == "ROLLED_BACK" and bool(dep.get("rollback_reason")),
    }
    passed = sum(gates.values())
    return {
        "report": "RAPORT_18_ENTERPRISE_AI_NEURAL",
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
    parser = argparse.ArgumentParser(description="RAPORT_18 Enterprise AI evidence gate")
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
        print(f"RAPORT_18: {evidence['status']} ({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})")
        for name, ok in evidence["gates"].items():
            print(f"  {'PASS' if ok else 'FAIL'} {name}")
    return 0 if not args.strict or evidence["status"] == "WDROZONY_100" else 1


if __name__ == "__main__":
    sys.exit(main())
