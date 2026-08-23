#!/usr/bin/env python3
"""ETAP 21/29 — RODO/AML/BDO/HR evidence gate."""
from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
PACKAGE = "rules/rodo_aml_bdo_hr_etap21_v1.rego"
MAIN = "rules/main_jdg.rego"
THRESHOLDS = "rules/thresholds_jdg.rego"
REPORT = ROOT / "raporty_glm52_enterprise" / "21_RODO_AML_BDO_HR.txt"
BUNDLE = ROOT / "bundles" / "rodo_aml_bdo_hr_etap21_audit_state.json"

SOURCE_FILES = [
    "prompty_glm52_enterprise/PROMPT_16_RODO_AML_BDO_HR.txt",
    "rules/rodo.rego",
    "rules/rodo_extended.rego",
    "rules/micro/rodo/rodo.rego",
    "rules/micro/rodo/rodo_erasure.rego",
    "rules/micro/rodo/rodo_podprocesorzy.rego",
    "rules/micro/aml/aml.rego",
    "rules/micro/aml/aml_cbdd.rego",
    "rules/compliance/aml_enterprise.rego",
    "rules/environmental.rego",
    "rules/environmental/bdo_enterprise.rego",
    "rules/micro/bdo/bdo_ewidencja.rego",
    "rules/employer.rego",
    "rules/ppk_pfron_enterprise.rego",
    "rules/p19_hr_swiadczenia_innovations_v9.rego",
    "rules/p16_rodo_aml_security_innovations_v9.rego",
    "rules/r14_rodo_aml_bdo_innovations_v9.rego",
    "tools/rodo_aml_security_auditor.py",
    "tools/bdo_environment_auditor.py",
    "tools/hr_swiadczenia_auditor.py",
    "docs/RODO_AML_BEZPIECZENSTWO_P16.md",
    "docs/SRODOWISKO_BDO_P15.md",
    "docs/HR_SWIADCZENIA_P19.md",
    "docs/Bbb",
    PACKAGE,
]

MARKERS = [
    "privacy_by_design", "rodo_basis_complete", "consent_complete", "retention_complete",
    "rights_workflow_complete", "breach_complete", "ubo_complete", "cdd_complete",
    "sanctions_screening_complete", "str_required", "str_complete",
    "bdo_registration_complete", "kpo_complete", "ewc_complete", "waste_transport_complete",
    "waste_record_complete", "employment_complete", "payroll_complete", "ppk_complete",
    "pfron_complete", "evidence_chain", "context_complete", "source_complete",
    "manual_review_required", "compliance_guidance_only", "tax_decision", "stub_detector",
    "BLOCK_AND_ALERT", "TRIAGE_QUEUE", 'decision_mode := "SUGGEST"',
    '"no_auto_post": true', "valid_from", "valid_to", "facts_version", "threshold_version",
]

LEGAL_MARKERS = [
    "RODO art. 5", "RODO art. 17", "u.AML art. 74-80", "UoO art. 66-70",
    "KP art. 85", "ustawa o PPK", "ustawa o PFRON",
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
        "package": "package jdg.rodo_aml_bdo_hr_etap21" in text,
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
        "import": "import data.jdg.rodo_aml_bdo_hr_etap21" in text,
        "package_decisions": '"jdg.rodo_aml_bdo_hr_etap21": rodo_aml_bdo_hr_etap21.decide' in text,
        "stage_chain": "final_verdict_p65 = safe_merge(final_verdict_p64" in text,
        "post_merge": "object.union(final_verdict_p65" in text,
        "public_final": "final_verdict = final_verdict_enforced" in text,
    }
    return {"markers": markers, "complete": all(markers.values())}


def tests_evidence() -> dict[str, Any]:
    pytest = read("tests/test_rodo_aml_bdo_hr_etap21_audit.py")
    native = read("tests/rego/test_native_rodo_aml_bdo_hr_etap21.rego")
    pytest_markers = ["privacy", "aml", "bdo", "hr", "fail_closed", "wiring"]
    native_markers = ["test_no_match", "test_missing_evidence", "test_privacy", "test_aml", "test_bdo", "test_hr"]
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
        "rodo_privacy_by_design": all(package["markers"][m] for m in ["privacy_by_design", "rodo_basis_complete", "consent_complete", "retention_complete", "rights_workflow_complete", "breach_complete"]),
        "aml_ubo_cbdd_str": all(package["markers"][m] for m in ["ubo_complete", "cdd_complete", "sanctions_screening_complete", "str_required", "str_complete"]),
        "bdo_kpo_ewc_transport": all(package["markers"][m] for m in ["bdo_registration_complete", "kpo_complete", "ewc_complete", "waste_transport_complete", "waste_record_complete"]),
        "hr_ppk_pfron": all(package["markers"][m] for m in ["employment_complete", "payroll_complete", "ppk_complete", "pfron_complete"]),
        "evidence_temporal_versions": all(package["markers"][m] for m in ["evidence_chain", "context_complete", "source_complete", "valid_from", "valid_to", "facts_version", "threshold_version"]),
        "legal_traceability": package["legal_basis_complete"],
        "manual_compliance_guidance": all(package["markers"][m] for m in ["manual_review_required", "compliance_guidance_only", "tax_decision"]),
        "stub_detection_fail_closed": all(package["markers"][m] for m in ["stub_detector", "BLOCK_AND_ALERT", "TRIAGE_QUEUE"]),
        "safe_routing": package["markers"]['decision_mode := "SUGGEST"'] and package["no_auto_post"],
        "thresholds_externalized": package["thresholds_externalized"] and "rodo_aml_bdo_hr_etap21 := {" in thresholds,
        "orchestrator_wiring": wiring["complete"],
        "pytest_contract": tests["pytest"]["present"] and all(tests["pytest"]["markers"].values()),
        "native_rego_contract": tests["native_rego"]["present"] and all(tests["native_rego"]["markers"].values()),
        "report_present": REPORT.exists(),
    }
    passed = sum(gates.values())
    return {
        "schema_version": "1.0.0",
        "audit_id": "jdg.rodo_aml_bdo_hr_etap21_audit",
        "stage": "ETAP_21",
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
RAPORT WDROŻENIOWY GLM52 ENTERPRISE — ETAP 21/29
RODO / AML-CBDD / BDO / ŚRODOWISKO / PRACODAWCA / HR / PPK / PFRON
====================================================================================================

IDENTITY
--------
Etap: ETAP_21
Prompt: JDG/prompty_glm52_enterprise/PROMPT_16_RODO_AML_BDO_HR.txt
Raport: JDG/raporty_glm52_enterprise/21_RODO_AML_BDO_HR.txt
Audytor: JDG/tools/rodo_aml_bdo_hr_etap21_audit.py
Bundle: JDG/bundles/rodo_aml_bdo_hr_etap21_audit_state.json
Pakiet wdrożeniowy: JDG/{PACKAGE}
Status raportu: {evidence['status']}

SCOPE
-----
Domknięto kanoniczną warstwę evidence-first nad P15/P16/R14/P19. Zakres
obejmuje privacy-by-design, podstawy i zgody RODO, retencję, prawa osób,
naruszenia, AML/CBDD, UBO, screening i STR/GIIF, BDO/KPO/EWC/transport,
dokumentację zatrudnienia, płace, PPK i PFRON.

IMPLEMENTED PHASES
------------------
1. RODO — podstawa, cel, kategorie danych, zgoda, minimalizacja, ograniczenie
   celu, redakcja PII, retencja, prawa osób i tracker naruszeń 72h.
2. AML/CBDD — UBO z progiem udziałów i źródłem, poziom CDD, screening,
   próg transakcji, wykrywanie STR i dowód referencji GIIF.
3. BDO — rejestracja, numer, KPO, kod EWC z weryfikacją, transport odpadów,
   przewoźnik i ewidencja masy/jednostki.
4. HR — dokument zatrudnienia, okres płacowy, uzgodnienie ZUS/PIT,
   status PPK i obowiązek PFRON zależny od liczby pracowników.
5. Evidence and safety — źródła, legal nodes, wersje faktów/progów/prawa,
   wykrywanie stubów, manual approval, guidance-only i BLOCK_AND_ALERT/
   TRIAGE_QUEUE z SUGGEST/no_auto_post.

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
[POTWIERDZONE_KODEM] Brak podstawy, zgody, minimalizacji, retencji, dowodu
naruszenia, UBO/CBDD/STR, rejestracji BDO, KPO/EWC, dokumentu HR lub wersji
blokuje wynik fail-closed.
[POTWIERDZONE_KODEM] Raporty AML/RODO wymagają manual approval. Wynik nie jest
decyzją podatkową ani kadrową; pakiet dostarcza wyłącznie compliance guidance.
[POTWIERDZONE_KODEM] Pakiet nie wysyła STR/GIIF, KPO, zgłoszeń BDO, wypłat ani
nie publikuje PII. `auto_action=NONE` i `no_auto_post=true`.
[OGRANICZENIE] Bramka techniczna nie zastępuje aktualnej ustawy, rejestru,
listy sankcyjnej, UODO/GIIF/BDO, dokumentacji pracowniczej ani porady eksperta.

VERIFICATION
------------
Evidence: {evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']} gates.
Status: {evidence['status']}
Produkcja: NOT_CERTIFIED

STATUS
------
Status raportu: {evidence['status']}
Następny raport: Prompt 17 / JDG/prompty_glm52_enterprise/PROMPT_17_HYPER_PLAN45.txt

ETAP_21_COMPLETE — CONTEXT_RESET_REQUIRED — wyczyść okno kontekstowe przed ETAPEM_22.
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
    parser = argparse.ArgumentParser(description="ETAP 21 RODO/AML/BDO/HR evidence gate")
    parser.add_argument("command", choices=["build", "validate"])
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    evidence = write_artifacts() if args.command == "build" else build_evidence()
    if args.json:
        print(json.dumps(evidence, ensure_ascii=False, indent=2))
    else:
        print(f"[ETAP_21] Status: {evidence['status']} ({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})")
        for name, passed in evidence["gates"].items():
            print(f"  {'PASS' if passed else 'FAIL'} {name}")
    return 0 if evidence["status"] == "WDROZONY_100" else 1


if __name__ == "__main__":
    raise SystemExit(main())
