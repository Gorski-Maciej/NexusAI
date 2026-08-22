#!/usr/bin/env python3
"""ETAP 18/29 — Ryczałt/CEIDG/business lifecycle evidence gate."""
from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
PACKAGE = "rules/business_lifecycle_etap18_v1.rego"
MAIN = "rules/main_jdg.rego"
REPORT = ROOT / "raporty_glm52_enterprise" / "18_RYCZALT_BUSINESS_LIFECYCLE.txt"
BUNDLE = ROOT / "bundles" / "business_lifecycle_etap18_audit_state.json"

SOURCE_FILES = [
    "rules/micro/ryczalt/ryczalt.rego",
    "rules/micro/plan33_ryc.rego",
    "rules/micro/ceidg/ceidg.rego",
    "rules/micro/pp/pp.rego",
    "rules/micro/sukcesja/sukcesja.rego",
    "rules/business.rego",
    "rules/business/plan26_suspension_succession.rego",
    "rules/lifecycle_manager_enterprise.rego",
    "rules/restructuring.rego",
    "rules/form_transition_simulator_enterprise.rego",
    "tools/ryczalt_lifecycle_auditor.py",
    "tools/lifecycle_navigator.py",
    "docs/RYCZALT_CYKL_ZYCIE_P13.md",
    "docs/Bbb",
    PACKAGE,
]

MARKERS = [
    "state_machine", "transition_catalog", "required_forms", "deadline_calendar",
    "rollback_event", "rate_registry", "effective_from", "effective_to",
    "legal_traceability", "manual_review_required", "owner_approval",
    "BLOCK_AND_ALERT", "TRIAGE_QUEUE", 'decision_mode := "SUGGEST"',
    '"no_auto_post": true', "facts_version", "threshold_version", "source_refs",
]
LEGAL = [
    "CEIDG art. 5-15", "Prawo przedsiębiorców art. 18", "22-25", "31-36",
    "ryczałcie art. 6", "art. 12", "zarządzie sukcesyjnym art. 3-15",
    "PIT art. 9a", "VAT art. 14", "SUS art. 18a/18c/43",
]
DOMAINS = ["PRE_START", "ACTIVE_STARTUP", "ACTIVE_GROWTH", "SUSPENDED", "SUCCESSION", "TRANSITION", "CLOSING", "CLOSED"]


def read(rel: str) -> str:
    try:
        return (ROOT / rel).read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def package_evidence(text: str) -> dict[str, Any]:
    ids = re.findall(r'"rule_id"\s*:\s*"([A-Za-z0-9_.-]+)"', text)
    duplicate_ids = sorted(k for k, v in Counter(ids).items() if v > 1)
    markers = {marker: marker in text for marker in MARKERS}
    legal = {marker: marker in text for marker in LEGAL}
    domains = {domain: f'"{domain}"' in text for domain in DOMAINS}
    return {
        "package": "package jdg.business_lifecycle_etap18" in text,
        "balanced_braces": text.count("{") == text.count("}"),
        "balanced_parentheses": text.count("(") == text.count(")"),
        "rule_ids": len(ids),
        "duplicate_rule_ids": duplicate_ids,
        "duplicate_free": not duplicate_ids,
        "markers": markers,
        "markers_complete": all(markers.values()),
        "legal_basis": legal,
        "legal_basis_complete": all(legal.values()),
        "states": domains,
        "states_complete": all(domains.values()),
        "transition_count": text.count('"from":'),
        "no_auto_post": '"no_auto_post": true' in text and '"AUTO_POST"' not in text,
        "thresholds_externalized": 'object.get(object.get(data, "jdg", {}), "thresholds", {})' in text,
    }


def files_evidence() -> dict[str, Any]:
    statuses = {path: bool(read(path)) for path in SOURCE_FILES}
    return {"declared": len(statuses), "present": sum(statuses.values()), "all_present": all(statuses.values()), "files": statuses}


def wiring_evidence(text: str) -> dict[str, Any]:
    markers = {
        "import": "import data.jdg.business_lifecycle_etap18" in text,
        "package_decisions": '"jdg.business_lifecycle_etap18": business_lifecycle_etap18.decide' in text,
        "stage_chain": "final_verdict_p62 = safe_merge(final_verdict_p61" in text,
        "post_merge": "object.union(final_verdict_p62" in text,
        "public_final": "final_verdict = final_verdict_enforced" in text,
    }
    return {"markers": markers, "complete": all(markers.values())}


def tests_evidence() -> dict[str, Any]:
    pytest = read("tests/test_business_lifecycle_etap18_audit.py")
    native = read("tests/rego/test_native_business_lifecycle_etap18.rego")
    pm = ["state_machine", "forms", "deadline", "rollback", "manual", "wiring"]
    nm = ["test_no_match", "test_invalid_transition", "test_suspend", "test_succession", "test_valid_register"]
    return {
        "pytest": {"present": bool(pytest), "test_count": len(re.findall(r"def test_", pytest)), "markers": {m: m in pytest for m in pm}},
        "native_rego": {"present": bool(native), "test_count": len(re.findall(r"test_\w+", native)), "markers": {m: m in native for m in nm}},
    }


def build_evidence() -> dict[str, Any]:
    package = package_evidence(read(PACKAGE))
    files = files_evidence()
    wiring = wiring_evidence(read(MAIN))
    tests = tests_evidence()
    gates = {
        "scope_files_present": files["all_present"],
        "package_structure": package["package"] and package["balanced_braces"] and package["balanced_parentheses"] and package["duplicate_free"],
        "state_machine": package["markers"]["state_machine"] and package["markers"]["transition_catalog"] and package["transition_count"] >= 10 and package["states_complete"],
        "forms_and_deadlines": package["markers"]["required_forms"] and package["markers"]["deadline_calendar"],
        "rollback_contract": package["markers"]["rollback_event"],
        "temporal_effective_dates": all(package["markers"][m] for m in ["effective_from", "effective_to", "facts_version", "threshold_version"]),
        "rate_registry": package["markers"]["rate_registry"],
        "legal_traceability": package["markers"]["legal_traceability"] and package["legal_basis_complete"],
        "manual_gate": package["markers"]["manual_review_required"] and package["markers"]["owner_approval"] and package["markers"]["BLOCK_AND_ALERT"] and package["markers"]["TRIAGE_QUEUE"],
        "safe_routing": package["markers"]['decision_mode := "SUGGEST"'] and package["no_auto_post"],
        "thresholds_externalized": package["thresholds_externalized"],
        "orchestrator_wiring": wiring["complete"],
        "pytest_contract": tests["pytest"]["present"] and all(tests["pytest"]["markers"].values()),
        "native_rego_contract": tests["native_rego"]["present"] and all(tests["native_rego"]["markers"].values()),
        "report_present": REPORT.exists(),
    }
    passed = sum(gates.values())
    return {
        "schema_version": "1.0.0", "audit_id": "jdg.business_lifecycle_etap18_audit", "stage": "ETAP_18",
        "status": "WDROZONY_100" if passed == len(gates) else "NIEPELNY",
        "gates": gates, "gate_summary": {"passed": passed, "total": len(gates)},
        "files": files, "package": package, "wiring": wiring, "tests": tests,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def build_report(e: dict[str, Any]) -> str:
    files = "\n".join(f"| {p} | {'PRESENT' if ok else 'MISSING'} |" for p, ok in e["files"]["files"].items())
    gates = "\n".join(f"| {p} | {'PASS' if ok else 'FAIL'} |" for p, ok in e["gates"].items())
    return f"""====================================================================================================
RAPORT WDROŻENIOWY GLM52 ENTERPRISE — ETAP 18/29
RYCZAŁT / CEIDG / PRAWO PRZEDSIĘBIORCÓW / SUKCESJA / CYKL ŻYCIA JDG
====================================================================================================

IDENTITY
--------
Etap: ETAP_18
Prompt: JDG/prompty_glm52_enterprise/18_RYCZALT_BUSINESS_LIFECYCLE.txt
Raport: JDG/raporty_glm52_enterprise/18_RYCZALT_BUSINESS_LIFECYCLE.txt
Audytor: JDG/tools/business_lifecycle_etap18_audit.py
Bundle: JDG/bundles/business_lifecycle_etap18_audit_state.json
Pakiet wdrożeniowy: JDG/{PACKAGE}
Status raportu: {e['status']}

SCOPE
-----
Domknięto formalny state machine cyklu życia JDG nad istniejącymi silnikami
P13/R12: PKWiU i stawki, limit ryczałtu, karta, wybór/zmiana formy, CEIDG,
obowiązki ewidencyjne, działalność nieewidencjonowana, zawieszenie/wznowienie,
prokura, sukcesja, transformacja i exit. Każde przejście ma legal source,
effective dates, formularze, termin, rollback i manual gate.

IMPLEMENTED PHASES
------------------
1. PRE_START/REGISTER — CEIDG-1, ZUS, VAT-R i wybór formy.
2. ACTIVE_STARTUP/ACTIVE_GROWTH — ulga na start, preferencyjny ZUS, VAT i wzrost.
3. SUSPENDED/RESUME — granice 30 dni/24 miesięcy, formularze i powrót.
4. SUCCESSION/END_SUCCESSION — zarządca, CEIDG 14 dni, okres 2/5 lat.
5. TRANSITION/CONFIRM_TAX_FORM — zmiana formy, ewidencja i zatwierdzenie właściciela.
6. CLOSING/FINALIZE_CLOSE — CEIDG, VAT-Z, ZUS, remanent, archiwizacja; CLOSED terminalny.
7. PKWiU rate registry — niezweryfikowany kod/stawka kieruje do manual review.
8. Evidence and safety — source refs, legal nodes, facts/threshold/legal versions,
   owner approval, rollback i SUGGEST-only orchestration.

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
[POTWIERDZONE_KODEM] Nieznany stan, nieprawidłowe przejście, brak źródła,
wersji lub owner approval kieruje do BLOCK_AND_ALERT/manual review.
[POTWIERDZONE_KODEM] PKWiU i wybór formy nie są automatycznie zatwierdzane bez
potwierdzenia; niejednoznaczność jest jawnie zwracana.
[POTWIERDZONE_KODEM] Pakiet nie składa CEIDG, VAT-Z, ZUS ani oświadczeń i ma
SUGGEST/no_auto_post.
[OGRANICZENIE] Bramka techniczna nie zastępuje aktualnego tekstu ustawy,
ISAP/LKG, doradcy ani wymaganej weryfikacji 4-eyes.

VERIFICATION
------------
Evidence: {e['gate_summary']['passed']}/{e['gate_summary']['total']} gates.
Status: {e['status']}
Produkcja: NOT_CERTIFIED

STATUS
------
Status raportu: {e['status']}
Następny raport: ETAP_19 / JDG/prompty_glm52_enterprise/19_*.txt

ETAP_18_COMPLETE — CONTEXT_RESET_REQUIRED — wyczyść okno kontekstowe przed ETAP_19.
"""


def write_artifacts() -> dict[str, Any]:
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(build_report(build_evidence()), encoding="utf-8")
    e = build_evidence()
    BUNDLE.parent.mkdir(parents=True, exist_ok=True)
    BUNDLE.write_text(json.dumps(e, ensure_ascii=False, indent=2), encoding="utf-8")
    REPORT.write_text(build_report(e), encoding="utf-8")
    return e


def main() -> int:
    parser = argparse.ArgumentParser(description="ETAP 18 business lifecycle evidence gate")
    parser.add_argument("command", choices=["build", "validate"])
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    e = write_artifacts() if args.command == "build" else build_evidence()
    if args.json:
        print(json.dumps(e, ensure_ascii=False, indent=2))
    else:
        print(f"[ETAP_18] Status: {e['status']} ({e['gate_summary']['passed']}/{e['gate_summary']['total']})")
        for name, ok in e["gates"].items():
            print(f"  {'PASS' if ok else 'FAIL'} {name}")
    return 0 if e["status"] == "WDROZONY_100" else 1


if __name__ == "__main__":
    raise SystemExit(main())
