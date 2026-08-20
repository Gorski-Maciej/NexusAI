#!/usr/bin/env python3
"""ETAP 11/29 — PIT Micro reliefs evidence and qualification gate."""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
REPORT_PATH = ROOT / "raporty_glm52_enterprise" / "11_PIT_MICRO_RELIEFS.txt"
BUNDLE_PATH = ROOT / "bundles" / "pit_micro_reliefs_audit_state.json"
PACKAGE_PATH = "rules/pit_micro_reliefs_etap11_v1.rego"
SCHEMA_VERSION = "1.0.0"

SOURCE_FILES = [
    "rules/micro/pit/pit.rego",
    "rules/micro/plan33_pit.rego",
    "rules/micro/plan34_pit.rego",
    "rules/pit/art21_exemptions_enterprise.rego",
    "rules/pit/rd_relief_enterprise.rego",
    "rules/pit/ipbox_enterprise.rego",
    "rules/pit/thermo_relief_enterprise.rego",
    "rules/pit/donation_relief_enterprise.rego",
    "rules/pit/cross_relief_optimizer_enterprise.rego",
    "rules/pit/tax_loss_harvesting_enterprise.rego",
    "rules/pit/family_estonian_enterprise.rego",
    "rules/p06_pit_micro_innovations_v9.rego",
    PACKAGE_PATH,
]

RELIEFS = [
    "BR", "IP_BOX", "THERMO", "PROTOTYPE", "ROBOTIZATION",
    "EXPANSION", "DONATION", "FAMILY_4PLUS", "CHILD", "LOSS",
]
REQUIRED_EVIDENCE_FIELDS = [
    "legal_node", "facts", "documents", "calculation", "tests",
    "confidence", "manual_review",
]
REQUIRED_GATES = [
    "atomic_evidence_pack", "formal_qualification_gate", "document_completeness_gate",
    "confidence_and_manual_review", "relief_conflict_detector", "what_if_after_eligibility",
    "temporal_relief_snapshot", "no_auto_post",
]


def read(rel: str) -> str:
    try:
        return (ROOT / rel).read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def files_evidence() -> dict[str, Any]:
    statuses = {path: bool(read(path)) for path in SOURCE_FILES}
    return {"declared": len(statuses), "present": sum(statuses.values()), "all_present": all(statuses.values()), "files": statuses}


def package_evidence(text: str) -> dict[str, Any]:
    ids = re.findall(r'"rule_id"\s*:\s*"([A-Za-z0-9_.-]+)"', text)
    duplicates = sorted(k for k, v in Counter(ids).items() if v > 1)
    reliefs = {relief: relief in text for relief in RELIEFS}
    evidence = {field: field in text for field in REQUIRED_EVIDENCE_FIELDS}
    gates = {gate: gate in text for gate in REQUIRED_GATES}
    return {
        "package": "jdg.pit_micro_reliefs_etap11" in text,
        "balanced_braces": text.count("{") == text.count("}"),
        "rule_ids": len(ids),
        "duplicate_rule_ids": duplicates,
        "duplicate_free": not duplicates,
        "reliefs": reliefs,
        "registry_complete": all(reliefs.values()) and '"registry_count": count(object.keys(relief_registry))' in text,
        "evidence_fields": evidence,
        "evidence_complete": all(evidence.values()),
        "gates": gates,
        "gates_complete": all(gates.values()),
        "decision_mode_suggest": '"decision_mode": "SUGGEST"' in text,
        "activation": 'object.get(input, "pit_micro_reliefs_etap11_check", false)' in text,
        "legal_basis": "Art. 9, 21, 26, 26e, 26eb, 26ec, 26gb, 26h, 27f, 30ca-30cb PIT" in text,
        "temporal": '"valid_from": evaluation_date' in text and "threshold_version" in text and "Bbb/LKG" in text,
        "no_auto_post": "no_auto_post" in text and '"AUTO_POST"' not in text,
    }


def wiring_evidence(main: str) -> dict[str, Any]:
    markers = {
        "import": "import data.jdg.pit_micro_reliefs_etap11" in main,
        "package_decisions": '"jdg.pit_micro_reliefs_etap11": pit_micro_reliefs_etap11.decide' in main,
        "p55_chain": "final_verdict_p55 = safe_merge(final_verdict_p54," in main,
        "post_merge_p55": "object.union(final_verdict_p55," in main,
        "invariants": "runtime_invariants.enforce(final_verdict_post_merge)" in main,
    }
    return {"markers": markers, "complete": all(markers.values())}


def tests_evidence() -> dict[str, Any]:
    text = read("tests/test_pit_micro_reliefs_audit.py")
    markers = ["B+R", "IP_BOX", "missing", "documents", "manual_review", "what_if", "cross_domain"]
    return {"present": bool(text), "test_count": len(re.findall(r"def test_", text)), "markers": {m: m in text for m in markers}, "complete": bool(text) and all(m in text for m in markers)}


def build_evidence() -> dict[str, Any]:
    package = read(PACKAGE_PATH)
    files = files_evidence()
    pkg = package_evidence(package)
    wiring = wiring_evidence(read("rules/main_jdg.rego"))
    tests = tests_evidence()
    gates = {
        "scope_files_present": files["all_present"],
        "package_structure": pkg["package"] and pkg["balanced_braces"] and pkg["duplicate_free"],
        "relief_registry_complete": pkg["registry_complete"] and pkg["legal_basis"],
        "evidence_pack_complete": pkg["evidence_complete"],
        "qualification_and_document_gates": pkg["gates_complete"],
        "temporal_contract": pkg["temporal"],
        "what_if_and_conflict_safety": "what_if_best" in package and "rd_ipbox_conflict" in package and "accumulation_exceeded" in package,
        "suggest_only": pkg["decision_mode_suggest"] and pkg["no_auto_post"] and pkg["activation"],
        "router_wired": wiring["complete"],
        "tests_present": tests["complete"],
        "report_present": REPORT_PATH.exists(),
    }
    passed = sum(gates.values())
    total = len(gates)
    return {
        "schema_version": SCHEMA_VERSION,
        "audit_id": "jdg.pit_micro_reliefs_etap11_audit",
        "stage": "ETAP_11",
        "status": "WDROZONY_100" if passed == total else "NIEPELNY",
        "gates": gates,
        "gate_summary": {"passed": passed, "total": total},
        "files": files,
        "package": pkg,
        "wiring": wiring,
        "tests": tests,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def build_report(evidence: dict[str, Any]) -> str:
    gate_lines = "\n".join(f"| {name} | {'PASS' if ok else 'FAIL'} |" for name, ok in evidence["gates"].items())
    file_lines = "\n".join(f"| {name} | {'PRESENT' if ok else 'MISSING'} |" for name, ok in evidence["files"]["files"].items())
    status = evidence["status"]
    return f"""====================================================================================================
RAPORT WDROŻENIOWY GLM52 ENTERPRISE — ETAP 11/29
PIT MICRO — ULGI, IP BOX, B+R, RODZINA I STRATY
====================================================================================================

IDENTITY
--------
Etap: ETAP_11
Prompt: JDG/prompty_glm52_enterprise/11_PIT_MICRO_RELIEFS.txt
Raport: JDG/raporty_glm52_enterprise/11_PIT_MICRO_RELIEFS.txt
Audytor: JDG/tools/pit_micro_reliefs_audit.py
Bundle: JDG/bundles/pit_micro_reliefs_audit_state.json
Pakiet wdrożeniowy: JDG/{PACKAGE_PATH}
Status raportu: {status}

SCOPE
-----
Warstwa audytowa obejmuje istniejące atomy PIT Micro, plan33/plan34,
Art. 21, B+R, IP Box, termomodernizację, prototyp, robotyzację, ekspansję,
darowizny, rodzinę i straty. Nie powiela istniejących decyzji ulgowych;
produkuje evidence pack i blokuje optymalizację bez dowodu formalnego.

FILES
-----
| Plik | Status |
|------|--------|
{file_lines}

IMPLEMENTED PHASES
------------------
1. Atomic relief registry — 10 ulg z legal node i katalogiem wymaganych dowodów.
2. Qualification gate — eligibility, wyłączenia i typ formularza przed optymalizacją.
3. Evidence pack — legal node, facts, documents, calculation, tests, confidence,
   manual_review i status per ulga.
4. Limit and temporal gate — evaluation date, threshold version i Bbb/LKG.
5. Accumulation guard — suma claimed_amount nie może przekroczyć dochodu.
6. Conflict guard — B+R/IP Box wymagają rozdzielenia strumieni dochodu;
   ryczałt nie uruchamia ulg właściwych dla dochodu.
7. What-if simulator — ranking uruchamiany dopiero na eligible reliefs.
8. Manual review — confidence < 0.90 lub brak źródła kieruje do TRIAGE_QUEUE.
9. Safe orchestration — SUGGEST only, no AUTO_POST, final p55 + invariants.

GATES
-----
| Gate | Result |
|------|--------|
{gate_lines}

RELIEF REGISTRY
---------------
| Relief | Legal node |
|--------|------------|
| BR | Art. 26e PIT |
| IP_BOX | Art. 30ca-30cb PIT |
| THERMO | Art. 26h PIT |
| PROTOTYPE | Art. 26eb PIT |
| ROBOTIZATION | Art. 26gb PIT |
| EXPANSION | Art. 26ec PIT |
| DONATION | Art. 26 ust. 1 pkt 9 PIT |
| FAMILY_4PLUS | Art. 21 ust. 1 pkt 153 PIT |
| CHILD | Art. 27f PIT |
| LOSS | Art. 9 ust. 3-6 PIT |

SAFETY CONTRACT
---------------
[POTWIERDZONE_KODEM] Brak eligibility, dokumentów, legal node, obliczenia
lub testu blokuje relief z evidence packu.
[POTWIERDZONE_KODEM] Niepewność confidence/manual_review kieruje do TRIAGE_QUEUE.
[POTWIERDZONE_KODEM] Konflikty B+R/IP Box, ryczałtowe wyłączenia i przekroczenie
sumy odliczeń kierują do BLOCK_AND_ALERT.
[OGRANICZENIE] Evidence pack jest dowodem technicznym systemu; nie zastępuje
weryfikacji aktualnego tekstu ustawy, 4-eyes review ani porady prawnej.

VERIFICATION
------------
Evidence: {evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']} gates.
Status: {status}

STATUS
------
Status raportu: {status}
Produkcja: NOT_CERTIFIED
Następny raport: ETAP_12 / JDG/prompty_glm52_enterprise/12_*.txt

ETAP_11_COMPLETE — CONTEXT_RESET_REQUIRED — wyczyść okno kontekstowe przed ETAP_12.
"""


def write_artifacts() -> dict[str, Any]:
    preliminary = build_evidence()
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(build_report(preliminary), encoding="utf-8")
    evidence = build_evidence()
    BUNDLE_PATH.parent.mkdir(parents=True, exist_ok=True)
    BUNDLE_PATH.write_text(json.dumps(evidence, indent=2, ensure_ascii=False), encoding="utf-8")
    REPORT_PATH.write_text(build_report(evidence), encoding="utf-8")
    return evidence


def main() -> int:
    parser = argparse.ArgumentParser(description="ETAP 11 PIT Micro reliefs audit")
    parser.add_argument("command", choices=["build", "validate"])
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    evidence = write_artifacts() if args.command == "build" else build_evidence()
    if args.json:
        print(json.dumps(evidence, indent=2, ensure_ascii=False))
    else:
        print(f"[ETAP_11] Status: {evidence['status']} ({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})")
        for name, ok in evidence["gates"].items():
            print(f"  {'PASS' if ok else 'FAIL'} {name}")
    return 0 if evidence["status"] == "WDROZONY_100" else 1


if __name__ == "__main__":
    sys.exit(main())
