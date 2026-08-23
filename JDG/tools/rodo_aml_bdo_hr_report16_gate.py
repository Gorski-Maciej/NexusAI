#!/usr/bin/env python3
"""Evidence gate for RAPORT_16 RODO / AML / BDO / HR.

The gate separates repository evidence from production certification. It checks
that the Prompt 16 scope is present, the ETAP 21 control package is wired, and
all decisions remain guidance-only and fail-closed.
"""
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
PROMPT = "prompty_glm52_enterprise/PROMPT_16_RODO_AML_BDO_HR.txt"
REPORT = "raporty_glm52_enterprise/RAPORT_16_RODO_AML_BDO_HR.txt"
PACKAGE = "rules/rodo_aml_bdo_hr_etap21_v1.rego"
MAIN = "rules/main_jdg.rego"
THRESHOLDS = "rules/thresholds_jdg.rego"
PYTEST = "tests/test_rodo_aml_bdo_hr_etap21_audit.py"
NATIVE = "tests/rego/test_native_rodo_aml_bdo_hr_etap21.rego"
BUNDLE = BUNDLES_DIR / "rodo_aml_bdo_hr_report16_evidence.json"

SCOPE_FILES = [
    "rules/rodo.rego", "rules/rodo_extended.rego", "rules/rodo/plan42_rodo.rego",
    "rules/rodo_aml_bdo_hr_etap21_v1.rego", "rules/micro/rodo/rodo.rego",
    "rules/micro/rodo/rodo_ai_marketing.rego", "rules/micro/rodo/rodo_erasure.rego",
    "rules/micro/rodo/rodo_podprocesorzy.rego", "rules/micro/rodo/rodo_sankcje.rego",
    "rules/micro/rodo/rodo_zatrudnienie.rego", "rules/micro/rodo_aml_bdo_atomic_p15.rego",
    "rules/micro/aml/aml.rego", "rules/micro/aml/aml_cbdd.rego",
    "rules/micro/aml/aml_ryzyko.rego", "rules/micro/aml/aml_str_gif.rego",
    "rules/micro/aml/aml_transakcje.rego", "rules/micro/bdo/bdo_ewc.rego",
    "rules/micro/bdo/bdo_ewidencja.rego", "rules/micro/bdo/bdo_rejestracja.rego",
    "rules/micro/bdo/bdo_transport.rego", "rules/micro/bdo/bdo_weee_baterie.rego",
    "rules/micro/bdo/bdo_zezwolenia.rego", "rules/micro/plan33_rodo.rego",
    "rules/micro/srodowisko/srodowisko.rego", "rules/micro/transport/transport.rego",
    "rules/employer.rego", "rules/mpips.rego", "rules/ppk_pfron_enterprise.rego",
    "rules/p16_rodo_aml_security_innovations_v9.rego",
    "rules/p19_hr_swiadczenia_innovations_v9.rego",
    "rules/r14_rodo_aml_bdo_innovations_v9.rego",
    "rules/p15_srodowisko_bdo_innovations_v9.rego",
    "tools/erasure_engine.py", "tools/rodo_aml_bdo_quality.py",
    "tools/rodo_register_generator.py", "tools/aml_cbdd_engine.py",
    "tools/str_generator.py", "tools/bdo_ewidencja_engine.py",
    "tools/rodo_aml_security_auditor.py", "tools/rodo_aml_bdo_hr_etap21_audit.py",
    "tools/ewc_classifier.py", "tests/test_rodo_aml_bdo_hr_etap21_audit.py",
    "tests/test_rodo_enterprise.py", "tests/test_aml_enterprise.py",
    "tests/test_bdo_enterprise.py", "docs/RODO_AML_BEZPIECZENSTWO_P16.md",
]

REQUIRED_MARKERS = [
    "privacy_by_design", "rodo_basis_complete", "consent_complete", "retention_complete",
    "rights_workflow_complete", "breach_complete", "ubo_complete", "cdd_complete",
    "sanctions_screening_complete", "str_required", "str_complete",
    "bdo_registration_complete", "kpo_complete", "ewc_complete", "waste_transport_complete",
    "waste_record_complete", "employment_complete", "payroll_complete", "ppk_complete",
    "pfron_complete", "evidence_chain", "context_complete", "source_complete",
    "manual_review_required", "compliance_guidance_only", "tax_decision", "stub_detector",
    "BLOCK_AND_ALERT", "TRIAGE_QUEUE", 'decision_mode := "SUGGEST"', '"no_auto_post": true',
    "valid_from", "valid_to", "facts_version", "threshold_version",
]

LEGAL_MARKERS = [
    "RODO art. 5", "RODO art. 17", "u.AML art. 74-80", "UoO art. 66-70",
    "KP art. 85", "ustawa o PPK", "ustawa o PFRON",
]


def read(rel: str) -> str:
    try:
        return (BASE_DIR / rel).read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def package_evidence() -> dict[str, Any]:
    text = read(PACKAGE)
    ids = re.findall(r'"rule_id"\s*:\s*"([A-Za-z0-9_.-]+)"', text)
    markers = {marker: marker in text for marker in REQUIRED_MARKERS}
    legal = {marker: marker in text for marker in LEGAL_MARKERS}
    return {
        "present": bool(text),
        "package": "package jdg.rodo_aml_bdo_hr_etap21" in text,
        "balanced": text.count("{") == text.count("}") and text.count("(") == text.count(")"),
        "rule_ids": len(ids),
        "duplicate_rule_ids": sorted(rid for rid, n in Counter(ids).items() if n > 1),
        "markers": markers,
        "legal_basis": legal,
        "thresholds_externalized": 'object.get(object.get(data, "jdg", {}), "thresholds", {})' in text,
        "no_auto_post": '"no_auto_post": true' in text and '"AUTO_POST"' not in text,
    }


def scope_evidence() -> dict[str, Any]:
    statuses = {path: bool(read(path)) for path in SCOPE_FILES}
    return {
        "declared": len(statuses),
        "present": sum(statuses.values()),
        "all_present": all(statuses.values()),
        "files": statuses,
    }


def wiring_evidence() -> dict[str, Any]:
    text = read(MAIN)
    markers = {
        "import": "import data.jdg.rodo_aml_bdo_hr_etap21" in text,
        "package_decisions": '"jdg.rodo_aml_bdo_hr_etap21": rodo_aml_bdo_hr_etap21.decide' in text,
        "stage_chain": "final_verdict_p65 = safe_merge(final_verdict_p64" in text,
        "post_merge": "object.union(final_verdict_p65" in text,
        "public_final": "final_verdict = final_verdict_enforced" in text,
    }
    return {"markers": markers, "complete": all(markers.values())}


def tests_evidence() -> dict[str, Any]:
    pytest = read(PYTEST)
    native = read(NATIVE)
    return {
        "pytest_present": bool(pytest),
        "pytest_functions": len(re.findall(r"def test_", pytest)),
        "native_present": bool(native),
        "native_functions": len(re.findall(r"^test_\w+", native, re.MULTILINE)),
        "audit_present": bool(read("tools/rodo_aml_bdo_hr_etap21_audit.py")),
    }


def replay_evidence() -> dict[str, Any]:
    try:
        golden = json.loads((BUNDLES_DIR / "golden_verdicts.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {"verdicts": 0, "replays": 0, "unmatched": 0, "verified": False}
    verdicts = golden.get("verdicts", {})
    replays = golden.get("replays", [])
    if not isinstance(replays, list):
        replays = []
    selected = [v for v in verdicts.values() if "rodo" in json.dumps(v, ensure_ascii=False).lower() or "aml" in json.dumps(v, ensure_ascii=False).lower() or "bdo" in json.dumps(v, ensure_ascii=False).lower()]
    unmatched = golden.get("unmatched_replays", [])
    if not isinstance(unmatched, list):
        unmatched = []
    return {"verdicts": len(selected), "replays": len(replays), "unmatched": len(unmatched), "verified": bool(selected) and not unmatched}


def deployment_evidence() -> dict[str, Any]:
    try:
        deployments = json.loads((BUNDLES_DIR / "deployments.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        deployments = {}
    dep = deployments.get("deployments", {}).get("jdg-rab-bundle-v9.0.0", {})
    return {"phase": dep.get("phase"), "rollback_reason": dep.get("rollback_reason"), "active_version": deployments.get("active_version")}


def build_evidence() -> dict[str, Any]:
    scope = scope_evidence()
    package = package_evidence()
    wiring = wiring_evidence()
    tests = tests_evidence()
    replay = replay_evidence()
    deployment = deployment_evidence()
    gates = {
        "prompt_and_report_present": bool(read(PROMPT)) and bool(read(REPORT)),
        "scope_complete": scope["all_present"],
        "package_complete": package["present"] and package["package"] and package["balanced"] and not package["duplicate_rule_ids"] and all(package["markers"].values()),
        "legal_traceability": all(package["legal_basis"].values()),
        "thresholds_externalized": package["thresholds_externalized"] and "rodo_aml_bdo_hr_etap21 := {" in read(THRESHOLDS),
        "router_wired": wiring["complete"],
        "tests_present": tests["pytest_present"] and tests["native_present"] and tests["audit_present"],
        "golden_replay_ok": replay["verified"],
        "rollback_fail_closed": deployment["phase"] == "ROLLED_BACK" and bool(deployment["rollback_reason"]),
    }
    passed = sum(gates.values())
    return {
        "report": "RAPORT_16_RODO_AML_BDO_HR",
        "status": "WDROZONY_100" if passed == len(gates) else "NIEPELNY",
        "gates": gates,
        "gate_summary": {"passed": passed, "total": len(gates)},
        "scope": scope,
        "package": package,
        "wiring": wiring,
        "tests": tests,
        "replay": replay,
        "deployment": deployment,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="RAPORT_16 RODO/AML/BDO/HR evidence gate")
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
        print(f"RAPORT_16: {evidence['status']} ({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})")
        for name, ok in evidence["gates"].items():
            print(f"  {'PASS' if ok else 'FAIL'} {name}")
    return 0 if not args.strict or evidence["status"] == "WDROZONY_100" else 1


if __name__ == "__main__":
    sys.exit(main())
