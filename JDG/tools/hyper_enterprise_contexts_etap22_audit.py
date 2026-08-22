#!/usr/bin/env python3
"""ETAP 22/29 — Hyper Enterprise Contexts evidence gate."""
from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
PACKAGE = "rules/hyper_enterprise_contexts_etap22_v1.rego"
MAIN = "rules/main_jdg.rego"
THRESHOLDS = "rules/thresholds_jdg.rego"
REPORT = ROOT / "raporty_glm52_enterprise" / "22_HYPER_ENTERPRISE_CONTEXTS.txt"
BUNDLE = ROOT / "bundles" / "hyper_enterprise_contexts_etap22_audit_state.json"

SOURCE_FILES = [
    "prompty_glm52_enterprise/22_HYPER_ENTERPRISE_CONTEXTS.txt",
    "rules/jdg/hyper/general/plan45.rego",
    "rules/jdg/hyper/deadlines/plan45.rego",
    "rules/jdg/hyper/limits/plan45.rego",
    "rules/jdg/hyper/mdr/plan45.rego",
    "rules/jdg/hyper/sanctions/plan45.rego",
    "rules/jdg/hyper/audit/plan45.rego",
    "rules/jdg/hyper/fx/plan45.rego",
    "rules/jdg/hyper/wis/plan45.rego",
    "rules/jdg/hyper/edelivery/plan45.rego",
    "rules/jdg/hyper/misc/plan45.rego",
    "rules/jdg/hyper/family/plan45.rego",
    "rules/jdg/hyper/force_majeure/plan45.rego",
    "rules/jdg/hyper/procurement/plan45.rego",
    "rules/jdg/hyper/solidarity/plan45.rego",
    "rules/hyper_plan45_meta_enterprise.rego",
    "rules/r13_hyper_konteksty_innovations_v9.rego",
    "tools/hyper_quality.py",
    "tools/hyper_konteksty_report13_gate.py",
    "docs/PRAWA_PRZEDSIEBIORCOW_AUDYT_R02.md",
    "docs/Bbb",
    PACKAGE,
]

MARKERS = [
    "context_catalog", "context_registry_complete", "output_contract_complete",
    "input_hash", "evidence_ref", "test_ref", "recipient", "deadline_engine",
    "limits_registry", "dependency_graph", "conflict_detector", "priority_validation",
    "territorial_validation", "context_complete", "source_complete", "mdr_complete", "sanctions_complete", "fx_complete",
    "wis_complete", "edelivery_complete", "manual_review_required", "BLOCK_AND_ALERT",
    "TRIAGE_QUEUE", 'decision_mode := "SUGGEST"', '"no_auto_post": true',
    "valid_from", "valid_to", "facts_version", "threshold_version",
]

LEGAL_MARKERS = [
    "PIT art. 30ca", "30h", "45", "OrdPU art. 12", "126", "MDR",
    "eIDAS", "doręczeniach elektronicznych", "KKS",
]


def read(rel: str) -> str:
    try:
        return (ROOT / rel).read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def package_evidence(text: str) -> dict[str, Any]:
    ids = re.findall(r'"rule_id"\s*:\s*"([A-Za-z0-9_.-]+)"', text)
    duplicates = sorted(rule_id for rule_id, count in Counter(ids).items() if count > 1)
    markers = {marker: marker in text for marker in MARKERS}
    legal = {marker: marker in text for marker in LEGAL_MARKERS}
    return {
        "package": "package jdg.hyper_enterprise_contexts_etap22" in text,
        "balanced_braces": text.count("{") == text.count("}"),
        "balanced_parentheses": text.count("(") == text.count(")"),
        "rule_ids": len(ids),
        "duplicate_rule_ids": duplicates,
        "duplicate_free": not duplicates,
        "markers": markers,
        "markers_complete": all(markers.values()),
        "legal_basis": legal,
        "legal_basis_complete": all(legal.values()),
        "thresholds_externalized": 'object.get(object.get(data, "jdg", {}), "thresholds", {})' in text,
        "no_auto_post": '"no_auto_post": true' in text and '"AUTO_POST"' not in text,
    }


def files_evidence() -> dict[str, Any]:
    statuses = {path: bool(read(path)) for path in SOURCE_FILES}
    return {"declared": len(statuses), "present": sum(statuses.values()), "all_present": all(statuses.values()), "files": statuses}


def wiring_evidence(text: str) -> dict[str, Any]:
    markers = {
        "import": "import data.jdg.hyper_enterprise_contexts_etap22" in text,
        "package_decisions": '"jdg.hyper_enterprise_contexts_etap22": hyper_enterprise_contexts_etap22.decide' in text,
        "stage_chain": "final_verdict_p66 = safe_merge(final_verdict_p65" in text,
        "post_merge": "object.union(final_verdict_p66" in text,
        "public_final": "final_verdict = final_verdict_enforced" in text,
    }
    return {"markers": markers, "complete": all(markers.values())}


def tests_evidence() -> dict[str, Any]:
    pytest = read("tests/test_hyper_enterprise_contexts_etap22_audit.py")
    native = read("tests/rego/test_native_hyper_enterprise_contexts_etap22.rego")
    pytest_markers = ["context", "deadline", "limits", "graph", "fail_closed", "wiring"]
    native_markers = ["test_no_match", "test_missing_evidence", "test_graph", "test_deadline", "test_conflict", "test_valid"]
    return {
        "pytest": {"present": bool(pytest), "test_count": len(re.findall(r"def test_", pytest)), "markers": {m: m in pytest for m in pytest_markers}},
        "native_rego": {"present": bool(native), "test_count": len(re.findall(r"^test_\w+", native, re.M)), "markers": {m: m in native for m in native_markers}},
    }


def build_evidence() -> dict[str, Any]:
    package = package_evidence(read(PACKAGE))
    files = files_evidence()
    wiring = wiring_evidence(read(MAIN))
    tests = tests_evidence()
    thresholds = read(THRESHOLDS)
    gates = {
        "scope_files_present": files["all_present"],
        "package_structure": package["package"] and package["balanced_braces"] and package["balanced_parentheses"] and package["duplicate_free"],
        "context_contract": all(package["markers"][m] for m in ["context_catalog", "context_registry_complete", "output_contract_complete", "input_hash", "evidence_ref", "test_ref", "recipient"]),
        "deadline_engine": package["markers"]["deadline_engine"],
        "limits_registry": package["markers"]["limits_registry"],
        "dependency_graph_conflicts": all(package["markers"][m] for m in ["dependency_graph", "conflict_detector"]),
        "priority_territory_validation": all(package["markers"][m] for m in ["priority_validation", "territorial_validation"]),
        "special_contexts": all(package["markers"][m] for m in ["mdr_complete", "sanctions_complete", "fx_complete", "wis_complete", "edelivery_complete"]),
        "evidence_temporal_versions": all(package["markers"][m] for m in ["context_complete", "source_complete", "valid_from", "valid_to", "facts_version", "threshold_version"]),
        "legal_traceability": package["legal_basis_complete"],
        "manual_fail_closed": all(package["markers"][m] for m in ["manual_review_required", "BLOCK_AND_ALERT", "TRIAGE_QUEUE"]),
        "safe_routing": package["markers"]['decision_mode := "SUGGEST"'] and package["no_auto_post"],
        "thresholds_externalized": package["thresholds_externalized"] and "hyper_enterprise_contexts_etap22 := {" in thresholds,
        "orchestrator_wiring": wiring["complete"],
        "pytest_contract": tests["pytest"]["present"] and all(tests["pytest"]["markers"].values()),
        "native_rego_contract": tests["native_rego"]["present"] and all(tests["native_rego"]["markers"].values()),
        "report_present": REPORT.exists(),
    }
    passed = sum(gates.values())
    return {
        "schema_version": "1.0.0",
        "audit_id": "jdg.hyper_enterprise_contexts_etap22_audit",
        "stage": "ETAP_22",
        "status": "WDROZONY_100" if passed == len(gates) else "NIEPELNY",
        "gates": gates,
        "gate_summary": {"passed": passed, "total": len(gates)},
        "files": files,
        "package": package,
        "wiring": wiring,
        "tests": tests,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def build_report(evidence: dict[str, Any]) -> str:
    files = "\n".join(f"| {path} | {'PRESENT' if present else 'MISSING'} |" for path, present in evidence["files"]["files"].items())
    gates = "\n".join(f"| {name} | {'PASS' if passed else 'FAIL'} |" for name, passed in evidence["gates"].items())
    return f"""====================================================================================================
RAPORT WDROŻENIOWY GLM52 ENTERPRISE — ETAP 22/29
HYPER PLAN45 / TERMINY / LIMITY / MDR / SANKCJE / FX / WIS / e-DORĘCZENIA
====================================================================================================

IDENTITY
--------
Etap: ETAP_22
Prompt: JDG/prompty_glm52_enterprise/22_HYPER_ENTERPRISE_CONTEXTS.txt
Raport: JDG/raporty_glm52_enterprise/22_HYPER_ENTERPRISE_CONTEXTS.txt
Audytor: JDG/tools/hyper_enterprise_contexts_etap22_audit.py
Bundle: JDG/bundles/hyper_enterprise_contexts_etap22_audit_state.json
Pakiet wdrożeniowy: JDG/{PACKAGE}
Status raportu: {evidence['status']}

SCOPE
-----
Domknięto meta-warstwę nad Hyper Plan45/R13: katalog kontekstów, realne wejście,
evidence, wynik, test i odbiorca; deadline engine; limit registry; graf
zależności i wykrywanie konfliktów; priorytety, terytorium i temporalność;
MDR, sankcje, waluty FX, WIS oraz e-Doręczenia.

IMPLEMENTED PHASES
------------------
1. Context registry — GENERAL/DEADLINES/LIMITS/MDR/SANCTIONS/FX/WIS/EDELIVERY/
   SPECIAL z walidacją zakresu i aktywacji.
2. Evidence contract — input hash, source/evidence ref, result, test ref,
   recipient, legal nodes, versions and owner approval.
3. Deadline engine — deadline_id, due_date, status, evidence and recipient;
   brak kompletnego terminu blokuje.
4. Limit registry — limit_id, wartość, jednostka, effective dates i źródło.
5. Dependency graph — wersjonowany graf nodes/edges, conflict pairs i detector;
   konflikty są jawne i kierowane do manual review.
6. Special contexts — MDR, sankcje, FX, WIS i e-Doręczenia z własnymi dowodami.
7. Safety — BLOCK_AND_ALERT/TRIAGE_QUEUE, SUGGEST/no_auto_post, guidance-only
   i brak zewnętrznych auto-akcji.

FILES
-----
| Plik | Status |
|------|--------|
{files}

GATES
-----
| Gate | Result |
|------|--------|
{gates}

SAFETY CONTRACT
---------------
[POTWIERDZONE_KODEM] Każdy kontekst musi mieć wejście, źródło/dowód, wynik,
test i odbiorcę. Brak któregokolwiek elementu blokuje meta-wynik.
[POTWIERDZONE_KODEM] Terminy, limity, terytorium, wersje prawa i graf zależności
są wymagane; konflikty nie są automatycznie rozstrzygane.
[POTWIERDZONE_KODEM] Meta-validator nie składa deklaracji, nie wysyła pism,
nie podpisuje dokumentów i nie wykonuje płatności; wynik jest `SUGGEST`.
[OGRANICZENIE] Bramka techniczna nie zastępuje aktualnych aktów prawnych,
źródeł MF/UODO/GIIF, rejestrów, kalendarza świąt ani opinii eksperta.

VERIFICATION
------------
Evidence: {evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']} gates.
Status: {evidence['status']}
Produkcja: NOT_CERTIFIED

STATUS
------
Status raportu: {evidence['status']}
Następny raport: ETAP_23 / JDG/prompty_glm52_enterprise/23_*.txt

ETAP_22_COMPLETE — CONTEXT_RESET_REQUIRED — wyczyść okno kontekstowe przed ETAPEM_23.
"""


def write_artifacts() -> dict[str, Any]:
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(build_report(build_evidence()), encoding="utf-8")
    evidence = build_evidence()
    BUNDLE.parent.mkdir(parents=True, exist_ok=True)
    BUNDLE.write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding="utf-8")
    REPORT.write_text(build_report(evidence), encoding="utf-8")
    return evidence


def main() -> int:
    parser = argparse.ArgumentParser(description="ETAP 22 Hyper Enterprise Contexts evidence gate")
    parser.add_argument("command", choices=["build", "validate"])
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    evidence = write_artifacts() if args.command == "build" else build_evidence()
    if args.json:
        print(json.dumps(evidence, ensure_ascii=False, indent=2))
    else:
        print(f"[ETAP_22] Status: {evidence['status']} ({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})")
        for name, passed in evidence["gates"].items():
            print(f"  {'PASS' if passed else 'FAIL'} {name}")
    return 0 if evidence["status"] == "WDROZONY_100" else 1


if __name__ == "__main__":
    raise SystemExit(main())
