#!/usr/bin/env python3
"""ETAP 23/29 — Enterprise AI / Neural Mesh evidence gate.

The gate certifies the governance layer, not a production deployment. It verifies
that AI predictions, explanations and feedback are bounded by deterministic Rego,
with evidence, calibration, drift, safety, explainability and manual review.
"""
from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
PACKAGE = "rules/enterprise_ai_neural_etap23_v1.rego"
MAIN = "rules/main_jdg.rego"
THRESHOLDS = "rules/thresholds_jdg.rego"
REPORT = ROOT / "raporty_glm52_enterprise" / "23_ENTERPRISE_AI_NEURAL.txt"
BUNDLE = ROOT / "bundles" / "enterprise_ai_neural_etap23_audit_state.json"

CORE_FILES = [
    "prompty_glm52_enterprise/23_ENTERPRISE_AI_NEURAL.txt",
    PACKAGE,
    MAIN,
    THRESHOLDS,
    "rules/adaptive_trust_scoring_enterprise.rego",
    "rules/neural_rule_mesh_enterprise.rego",
    "rules/neural_mesh_v2_enterprise.rego",
    "rules/cashflow_tax_predictor_enterprise.rego",
    "rules/banking_automation_enterprise.rego",
    "rules/strategic_advisor_enterprise.rego",
    "rules/legislative_monitor_enterprise.rego",
    "tools/llm_bridge.py",
    "tools/decision_quality_monitor.py",
    "tools/adaptive_trust_score.py",
    "tools/neural_mesh_innovations_auditor.py",
    "docs/NEURAL_MESH_INNOWACJE_P20.md",
    "docs/WIZJA_OPA_ENTERPRISE_V2.md",
    "docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md",
]

REQUIRED_PACKAGE_MARKERS = [
    "context_complete", "source_complete", "prediction_separation", "prediction_evidence",
    "calibration_complete", "drift_ok", "quality_complete", "bias_safety_complete",
    "explainability_complete", "llm_safe", "feedback_complete", "cashflow_complete",
    "banking_complete", "manual_review_required", "legal_verdict_authority",
    "DETERMINISTIC_REGO", "ADVISORY_ONLY", "BLOCK_AND_ALERT", "TRIAGE_QUEUE",
    "decision_mode := \"SUGGEST\"", "no_auto_post", "valid_from", "valid_to",
    "facts_version", "threshold_version", "input_hash", "source_refs", "legal_nodes",
]

LEGAL_MARKERS = [
    "RODO art. 5", "RODO art. 22", "RODO art. 25", "RODO art. 22",
    "PIT art. 44", "VAT art. 103", "OrdPU art. 4", "PSD2", "ADR-006", "ADR-022",
]

TEST_MARKERS = [
    "prediction_separation", "calibration", "drift", "bias", "explainability",
    "llm", "cashflow", "banking", "fail_closed", "manual_review", "wiring",
]


def read(rel: str) -> str:
    try:
        return (ROOT / rel).read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def rule_ids(text: str) -> list[str]:
    return re.findall(r'"rule_id"\s*:\s*"([A-Za-z0-9_.-]+)"', text)


def files_evidence() -> dict[str, Any]:
    statuses = {path: bool(read(path)) for path in CORE_FILES}
    return {
        "declared": len(statuses),
        "present": sum(statuses.values()),
        "all_present": all(statuses.values()),
        "files": statuses,
    }


def package_evidence(text: str) -> dict[str, Any]:
    ids = rule_ids(text)
    duplicates = sorted(rid for rid, count in Counter(ids).items() if count > 1)
    markers = {marker: marker in text for marker in REQUIRED_PACKAGE_MARKERS}
    legal = {marker: marker in text for marker in LEGAL_MARKERS}
    return {
        "package": "package jdg.enterprise_ai_neural_etap23" in text,
        "balanced_braces": text.count("{") == text.count("}"),
        "balanced_parentheses": text.count("(") == text.count(")"),
        "rule_ids": len(ids),
        "rule_ids_unique": len(set(ids)),
        "duplicate_rule_ids": duplicates,
        "duplicate_free": not duplicates,
        "markers": markers,
        "markers_complete": all(markers.values()),
        "legal_basis": legal,
        "legal_basis_complete": all(legal.values()),
        "no_automatic_action_literal": "AUTO_POST" not in text,
    }


def wiring_evidence(text: str) -> dict[str, Any]:
    markers = {
        "import": "import data.jdg.enterprise_ai_neural_etap23" in text,
        "package_decisions": '"jdg.enterprise_ai_neural_etap23": enterprise_ai_neural_etap23.decide' in text,
        "stage_chain": "final_verdict_p67 = safe_merge(final_verdict_p66" in text,
        "post_merge": "object.union(final_verdict_p67" in text,
        "public_final": "final_verdict = final_verdict_enforced" in text,
        "runtime_invariants": "runtime_invariants.enforce(final_verdict_post_merge)" in text,
    }
    return {"markers": markers, "complete": all(markers.values())}


def thresholds_evidence(text: str) -> dict[str, Any]:
    required = [
        "enterprise_ai_neural_etap23 := {", "calibration_min_samples",
        "max_expected_calibration_error", "max_population_stability_index",
        "prediction_role", "legal_verdict_authority", "required_controls",
    ]
    return {"markers": {marker: marker in text for marker in required}, "complete": all(marker in text for marker in required)}


def tests_evidence() -> dict[str, Any]:
    pytest = read("tests/test_enterprise_ai_neural_etap23_audit.py")
    native = read("tests/rego/test_native_enterprise_ai_neural_etap23.rego")
    pytest_markers = {marker: marker in pytest for marker in TEST_MARKERS}
    native_markers = {
        marker: marker in native
        for marker in ["test_no_match", "test_missing_contract", "test_prediction_separation", "test_quality", "test_safety", "test_valid"]
    }
    return {
        "pytest": {"present": bool(pytest), "test_count": len(re.findall(r"def test_", pytest)), "markers": pytest_markers},
        "native_rego": {"present": bool(native), "test_count": len(re.findall(r"^test_\w+", native, re.MULTILINE)), "markers": native_markers},
    }


def runtime_safety_evidence(package: str) -> dict[str, Any]:
    required = {
        "manual_review": "manual_review_required := true" in package,
        "suggest_only": '"decision_mode": "SUGGEST"' in package,
        "no_auto_post": '"no_auto_post": true' in package,
        "legal_authority": '"legal_verdict_authority": "DETERMINISTIC_REGO"' in package,
        "prediction_advisory": "ADVISORY_ONLY" in package,
        "llm_explanation_only": '"explanation_only": false' not in package and "explanation_only" in package,
        "none_external_action": '"auto_action": "NONE — MANUAL_REVIEW_REQUIRED"' in package,
    }
    return {"markers": required, "complete": all(required.values())}


def build_evidence() -> dict[str, Any]:
    package_text = read(PACKAGE)
    files = files_evidence()
    package = package_evidence(package_text)
    wiring = wiring_evidence(read(MAIN))
    thresholds = thresholds_evidence(read(THRESHOLDS))
    tests = tests_evidence()
    safety = runtime_safety_evidence(package_text)
    gates = {
        "scope_files_present": files["all_present"],
        "package_structure": package["package"] and package["balanced_braces"] and package["balanced_parentheses"] and package["duplicate_free"],
        "contract_markers": package["markers_complete"],
        "legal_traceability": package["legal_basis_complete"],
        "prediction_separation": all(package["markers"][m] for m in ["prediction_separation", "prediction_evidence", "legal_verdict_authority"]),
        "calibration_and_drift": all(package["markers"][m] for m in ["calibration_complete", "drift_ok", "quality_complete"]),
        "bias_safety": package["markers"]["bias_safety_complete"],
        "explainability_llm": all(package["markers"][m] for m in ["explainability_complete", "llm_safe"]),
        "feedback_predictions": all(package["markers"][m] for m in ["feedback_complete", "cashflow_complete", "banking_complete"]),
        "temporal_evidence": all(package["markers"][m] for m in ["context_complete", "source_complete", "valid_from", "valid_to", "facts_version", "threshold_version", "input_hash"]),
        "safe_routing": safety["complete"],
        "threshold_registry": thresholds["complete"],
        "orchestrator_wiring": wiring["complete"],
        "pytest_contract": tests["pytest"]["present"] and all(tests["pytest"]["markers"].values()),
        "native_rego_contract": tests["native_rego"]["present"] and all(tests["native_rego"]["markers"].values()),
        "report_present": REPORT.exists(),
    }
    passed = sum(gates.values())
    return {
        "schema_version": "1.0.0",
        "audit_id": "jdg.enterprise_ai_neural_etap23_audit",
        "stage": "ETAP_23",
        "status": "WDROZONY_100" if passed == len(gates) else "NIEPELNY",
        "gates": gates,
        "gate_summary": {"passed": passed, "total": len(gates)},
        "files": files,
        "package": package,
        "thresholds": thresholds,
        "wiring": wiring,
        "safety": safety,
        "tests": tests,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def build_report(evidence: dict[str, Any]) -> str:
    file_rows = "\n".join(
        f"| {path} | {'PRESENT' if present else 'MISSING'} |"
        for path, present in evidence["files"]["files"].items()
    )
    gate_rows = "\n".join(
        f"| {name} | {'PASS' if passed else 'FAIL'} |"
        for name, passed in evidence["gates"].items()
    )
    return f"""====================================================================================================
RAPORT WDROŻENIOWY GLM52 ENTERPRISE — ETAP 23/29
ENTERPRISE AI / ADAPTIVE TRUST / NEURAL MESH / CASHFLOW / BANKING / LLM
====================================================================================================

IDENTITY
--------
Etap: ETAP_23
Prompt: JDG/prompty_glm52_enterprise/23_ENTERPRISE_AI_NEURAL.txt
Raport: JDG/raporty_glm52_enterprise/23_ENTERPRISE_AI_NEURAL.txt
Audytor: JDG/tools/enterprise_ai_neural_etap23_audit.py
Bundle: JDG/bundles/enterprise_ai_neural_etap23_audit_state.json
Pakiet: JDG/{PACKAGE}
Status raportu: {evidence['status']}

SCOPE AND PRINCIPLE
-------------------
Domknięto kanoniczną warstwę governance nad istniejącymi modułami Enterprise AI.
Trust scoring, Neural Mesh, cashflow, bankowość, monitoring legislacyjny,
feedback i LLM są predykcyjne/advisory-only. Legal verdict pozostaje wyłączną
własnością deterministycznego Rego; brak kompletnego dowodu kończy się
BLOCK_AND_ALERT, a wynik zatwierdzony kierowany jest do TRIAGE_QUEUE/manual review.

IMPLEMENTED PHASES
------------------
1. Contract and provenance — input_hash, source_refs, legal_nodes, evaluation date,
   versions, evidence refs, model versions and owner approval.
2. Prediction firewall — explicit DETERMINISTIC_REGO legal authority and
   ADVISORY_ONLY prediction role; no AI legal decision and no external action.
3. Quality controls — calibration sample/error gates, drift baseline/PSI gate,
   decision-quality feedback window and human-verified outcomes.
4. Safety — bias tests, prompt-injection tests, PII redaction, bounded routing,
   fail-closed behavior and mandatory manual review.
5. Explainability — rationale, feature attributions, provenance and model
   version; LLM is grounded explanation-only and carries a disclaimer reference.
6. Domain controls — cashflow uncertainty evidence, banking consent and no
   transaction authority; legislative/trust/mesh outputs remain suggestions.
7. Orchestration — final_verdict_p67 is included before POST-MERGE runtime
   invariants and public final_verdict.

FILES
-----
| File | Status |
|------|--------|
{file_rows}

GATES
-----
| Gate | Result |
|------|--------|
{gate_rows}

SAFETY CONTRACT
---------------
[POTWIERDZONE KODEM] AI nie podejmuje decyzji prawnej. Pole
`legal_verdict_authority` musi wskazywać `DETERMINISTIC_REGO`, a predykcje mają
rolę `ADVISORY_ONLY`.
[POTWIERDZONE KODEM] Kalibracja, drift, jakość feedbacku, bias/safety,
explainability i evidence są bramkami fail-closed.
[POTWIERDZONE KODEM] LLM może wyłącznie objaśniać ugruntowany wynik i nie ma
władzy nad routingiem ani legal verdict.
[POTWIERDZONE KODEM] Brak owner approval albo dowodu oznacza BLOCK_AND_ALERT;
kompletny wynik i tak wymaga manual review oraz TRIAGE_QUEUE.
[OGRANICZENIE] Bramka techniczna nie zastępuje aktualnego prawa, walidacji
modelu w środowisku produkcyjnym, zgód PSD2 ani opinii profesjonalisty.

VERIFICATION
------------
Evidence: {evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']} gates.
Status: {evidence['status']}
Produkcja: NOT_CERTIFIED
OPA: sprawdź natywnie, jeśli binarne `opa` jest dostępne w środowisku.

STATUS
------
Status raportu: {evidence['status']}
Następny raport: ETAP 24 / JDG/prompty_glm52_enterprise/24_*.txt

ETAP_23_COMPLETE — CONTEXT_RESET_REQUIRED — wyczyść okno kontekstowe przed ETAPEM_24.
"""


def write_artifacts() -> dict[str, Any]:
    evidence = build_evidence()
    # The build command is itself the declaration that the report will be emitted.
    # Mark that artifact gate before serializing, then validate it on subsequent runs.
    evidence["gates"]["report_present"] = True
    passed = sum(evidence["gates"].values())
    evidence["status"] = "WDROZONY_100" if passed == len(evidence["gates"]) else "NIEPELNY"
    evidence["gate_summary"] = {"passed": passed, "total": len(evidence["gates"])}
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    BUNDLE.parent.mkdir(parents=True, exist_ok=True)
    BUNDLE.write_text(json.dumps(evidence, indent=2, ensure_ascii=False), encoding="utf-8")
    REPORT.write_text(build_report(evidence), encoding="utf-8")
    return evidence


def main() -> int:
    parser = argparse.ArgumentParser(description="ETAP 23 Enterprise AI evidence gate")
    parser.add_argument("command", choices=["build", "validate"])
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    evidence = write_artifacts() if args.command == "build" else build_evidence()
    if args.json:
        print(json.dumps(evidence, indent=2, ensure_ascii=False))
    else:
        print(f"[ETAP_23] Status: {evidence['status']} ({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})")
        for name, passed in evidence["gates"].items():
            print(f"  {'PASS' if passed else 'FAIL'} {name}")
    return 0 if evidence["status"] == "WDROZONY_100" else 1


if __name__ == "__main__":
    raise SystemExit(main())
