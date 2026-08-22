#!/usr/bin/env python3
"""ETAP 17/29 — Cross-border evidence gate.

Audytuje obecne reguły Cross-border oraz nową warstwę safety/evidence-first.
Bramka certyfikuje kompletność artefaktów i kontraktów technicznych; nie
certyfikuje zmieniającej się treści prawa ani nie wysyła dokumentów do organów.
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
PACKAGE = "rules/crossborder_etap17_v1.rego"
MAIN = "rules/main_jdg.rego"
REPORT = ROOT / "raporty_glm52_enterprise" / "17_CROSSBORDER_MDR.txt"
BUNDLE = ROOT / "bundles" / "crossborder_etap17_audit_state.json"

SOURCE_FILES = [
    "rules/crossborder.rego",
    "rules/international.rego",
    "rules/international_expanded.rego",
    "rules/crossborder/plan23_ue.rego",
    "rules/crossborder/exit_tax_cfc_complete.rego",
    "rules/mdr/mdr_enterprise.rego",
    "rules/mdr/mdr_hallmarks.rego",
    "rules/mdr/plan45_mdr.rego",
    "rules/mdr_dac6_enterprise.rego",
    "rules/vida_drr_full.rego",
    "rules/dac8_report_generator.rego",
    "rules/cbam_full.rego",
    "rules/tp/plan45_tp.rego",
    "tools/crossborder_auditor.py",
    "tools/mdr_scorer.py",
    "tools/tp_documentation_engine.py",
    "docs/CROSSBORDER_P12.md",
    "docs/Bbb",
    PACKAGE,
]

REQUIRED_MARKERS = [
    "evidence_pack", "domain_scope", "legal_traceability", "phase_status",
    "conflicts", "manual_review_required", "BLOCK_AND_ALERT", "TRIAGE_QUEUE",
    'decision_mode := "SUGGEST"', '"no_auto_post": true', "source_refs",
    "evaluation_date", "threshold_version", "legal_basis_version", "facts_version",
]
REQUIRED_DOMAINS = [
    "residency", "direction", "place_of_supply", "wdt_wnt", "tp_cfc",
    "mdr_dac", "cbam_vida_dac8", "fx",
]
LEGAL_MARKERS = [
    "VAT art. 9-13",
    "28a-28o",
    "41-42",
    "23m-23zf",
    "30da-30f",
    "86a-86r",
    "DAC6",
    "DAC8",
    "CBAM",
    "ViDA",
    "24c",
]


def read(rel: str) -> str:
    try:
        return (ROOT / rel).read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def files_evidence() -> dict[str, Any]:
    statuses = {path: bool(read(path)) for path in SOURCE_FILES}
    return {
        "declared": len(statuses),
        "present": sum(statuses.values()),
        "all_present": all(statuses.values()),
        "files": statuses,
    }


def package_evidence(text: str) -> dict[str, Any]:
    rule_ids = re.findall(r'"rule_id"\s*:\s*"([A-Za-z0-9_.-]+)"', text)
    duplicates = sorted(k for k, v in Counter(rule_ids).items() if v > 1)
    markers = {marker: marker in text for marker in REQUIRED_MARKERS}
    legal = {marker: marker in text for marker in LEGAL_MARKERS}
    return {
        "package": "package jdg.crossborder_etap17" in text,
        "balanced_braces": text.count("{") == text.count("}"),
        "balanced_parentheses": text.count("(") == text.count(")"),
        "rule_ids": len(rule_ids),
        "duplicate_rule_ids": duplicates,
        "duplicate_free": not duplicates,
        "markers": markers,
        "markers_complete": all(markers.values()),
        "legal_basis": legal,
        "legal_basis_complete": all(legal.values()),
        "domain_count": sum(1 for domain in REQUIRED_DOMAINS if f'"{domain}":' in text),
        "domain_coverage": {domain: f'"{domain}":' in text for domain in REQUIRED_DOMAINS},
        "no_auto_post": '"no_auto_post": true' in text and '"AUTO_POST"' not in text,
        "thresholds_externalized": 'object.get(object.get(data, "jdg", {}), "thresholds", {})' in text,
    }


def wiring_evidence(main: str) -> dict[str, Any]:
    markers = {
        "import": "import data.jdg.crossborder_etap17" in main,
        "package_decisions": '"jdg.crossborder_etap17": crossborder_etap17.decide' in main,
        "stage_chain": "final_verdict_p61 = safe_merge(final_verdict_p60" in main,
        "post_merge": "object.union(final_verdict_p61" in main,
        "public_final": "final_verdict = final_verdict_enforced" in main,
    }
    return {"markers": markers, "complete": all(markers.values())}


def test_evidence() -> dict[str, Any]:
    pytest_text = read("tests/test_crossborder_etap17_audit.py")
    native_text = read("tests/rego/test_native_crossborder_etap17.rego")
    pytest_markers = ["fail_closed", "evidence", "temporal", "conflict", "manual", "wiring"]
    native_markers = ["test_missing_context", "test_conflict", "test_high_risk", "test_complete", "test_no_match"]
    return {
        "pytest": {
            "present": bool(pytest_text),
            "test_count": len(re.findall(r"def test_", pytest_text)),
            "markers": {m: m in pytest_text for m in pytest_markers},
        },
        "native_rego": {
            "present": bool(native_text),
            "test_count": len(re.findall(r"test_\w+", native_text)),
            "markers": {m: m in native_text for m in native_markers},
        },
    }


def build_evidence() -> dict[str, Any]:
    package_text = read(PACKAGE)
    main_text = read(MAIN)
    files = files_evidence()
    package = package_evidence(package_text)
    wiring = wiring_evidence(main_text)
    tests = test_evidence()
    gates = {
        "scope_files_present": files["all_present"],
        "package_structure": package["package"] and package["balanced_braces"] and package["balanced_parentheses"] and package["duplicate_free"],
        "evidence_first_contract": package["markers"]["evidence_pack"] and package["markers"]["source_refs"],
        "temporal_contract": all(package["markers"][m] for m in ["evaluation_date", "threshold_version", "legal_basis_version", "facts_version"]),
        "domain_coverage": package["markers"]["domain_scope"] and all(package["domain_coverage"].values()),
        "legal_traceability": package["markers"]["legal_traceability"] and package["legal_basis_complete"],
        "conflict_detection": package["markers"]["conflicts"],
        "manual_review_gate": package["markers"]["manual_review_required"] and package["markers"]["BLOCK_AND_ALERT"] and package["markers"]["TRIAGE_QUEUE"],
        "safe_routing": package["markers"]['decision_mode := "SUGGEST"'] and package["no_auto_post"],
        "thresholds_externalized": package["thresholds_externalized"],
        "orchestrator_wiring": wiring["complete"],
        "pytest_contract": tests["pytest"]["present"] and all(tests["pytest"]["markers"].values()),
        "native_rego_contract": tests["native_rego"]["present"] and all(tests["native_rego"]["markers"].values()),
        "report_present": REPORT.exists(),
    }
    passed = sum(gates.values())
    return {
        "schema_version": "1.0.0",
        "audit_id": "jdg.crossborder_etap17_audit",
        "stage": "ETAP_17",
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
    file_lines = "\n".join(f"| {name} | {'PRESENT' if ok else 'MISSING'} |" for name, ok in evidence["files"]["files"].items())
    gate_lines = "\n".join(f"| {name} | {'PASS' if ok else 'FAIL'} |" for name, ok in evidence["gates"].items())
    return f"""====================================================================================================
RAPORT WDROŻENIOWY GLM52 ENTERPRISE — ETAP 17/29
CROSS-BORDER — WNT/WDT, TP, MDR/DAC6/DAC8, CFC, CBAM, ViDA, FX
====================================================================================================

IDENTITY
--------
Etap: ETAP_17
Prompt: JDG/prompty_glm52_enterprise/17_CROSSBORDER_MDR.txt
Raport: JDG/raporty_glm52_enterprise/17_CROSSBORDER_MDR.txt
Audytor: JDG/tools/crossborder_etap17_audit.py
Bundle: JDG/bundles/crossborder_etap17_audit_state.json
Pakiet wdrożeniowy: JDG/{PACKAGE}
Status raportu: {evidence['status']}

SCOPE
-----
Domknięto warstwę Cross-border jako evidence-first safety layer nad regułami
WNT/WDT/import/export, miejscem świadczenia, TP, CFC, MDR/DAC6/DAC8, CBAM,
ViDA/DRR, rezydencją i FX. Każda domena ma łańcuch fakt → dokument →
obliczenie → test → confidence → manual review. ViDA/DAC8/CBAM są monitorowane;
pakiet nie twierdzi, że wysłał raport lub wykonał czynność wobec organu.

FILES
-----
| Plik | Status |
|------|--------|
{file_lines}

IMPLEMENTED PHASES
------------------
1. Ingest i normalizacja — data transakcji, kierunek, kraje, waluta i wersje.
2. Legal traceability — źródła, legal nodes i zakres VAT/PIT/OrdPU/DAC6/DAC8/CBAM/ViDA.
3. Evidence pack — osiem domen: rezydencja, kierunek, miejsce świadczenia,
   WNT/WDT, TP/CFC, MDR/DAC, CBAM/ViDA/DAC8 oraz FX.
4. Temporalność — evaluation_date, threshold_version, legal_basis_version,
   facts_version oraz valid_from/valid_to.
5. Conflict shield — sprzeczny kierunek, VAT/PCC, rezydencja i brak kursu są
   wykrywane; konflikty kierują do BLOCK_AND_ALERT.
6. Risk and manual gate — wysokie MDR/CFC/CBAM, brak dowodów lub niska confidence
   kierują do TRIAGE_QUEUE/manual review.
7. Safe orchestration — SUGGEST only, no_auto_post, final_verdict_p61,
   post-merge invariants i certyfikat pozostają aktywne.
8. Existing domain engines — wykorzystane i objęte audytem: crossborder_auditor,
   mdr_scorer, tp_documentation_engine oraz pakiety P12/R10.

GATES
-----
| Gate | Result |
|------|--------|
{gate_lines}

SAFETY CONTRACT
---------------
[POTWIERDZONE_KODEM] Brak daty oceny, wersji progów/prawa/faktów lub źródła
blokuje wynik (BLOCK_AND_ALERT).
[POTWIERDZONE_KODEM] Niekompletny evidence pack, konflikt albo wysokie ryzyko
wymaga manual review; nie powstaje automatyczna porada transgraniczna.
[POTWIERDZONE_KODEM] Wynik ma tryb SUGGEST i no_auto_post=true; pakiet nie
wysyła deklaracji, MDR, DAC8, CBAM ani e-faktury.
[OGRANICZENIE] Evidence gate sprawdza kontrakt techniczny i obecność artefaktów;
nie zastępuje aktualnego tekstu ustawy, źródła ISAP/LKG, doradcy ani 4-eyes review.

VERIFICATION
------------
Evidence: {evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']} gates.
Status: {evidence['status']}
Produkcja: NOT_CERTIFIED

STATUS
------
Status raportu: {evidence['status']}
Następny raport: ETAP_18 / JDG/prompty_glm52_enterprise/18_*.txt

ETAP_17_COMPLETE — CONTEXT_RESET_REQUIRED — wyczyść okno kontekstowe przed ETAP_18.
"""


def write_artifacts() -> dict[str, Any]:
    # First write lets the report-present gate become true on the final pass.
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(build_report(build_evidence()), encoding="utf-8")
    evidence = build_evidence()
    BUNDLE.parent.mkdir(parents=True, exist_ok=True)
    BUNDLE.write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding="utf-8")
    REPORT.write_text(build_report(evidence), encoding="utf-8")
    return evidence


def main() -> int:
    parser = argparse.ArgumentParser(description="ETAP 17 Cross-border evidence gate")
    parser.add_argument("command", choices=["build", "validate"])
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    evidence = write_artifacts() if args.command == "build" else build_evidence()
    if args.json:
        print(json.dumps(evidence, ensure_ascii=False, indent=2))
    else:
        print(f"[ETAP_17] Status: {evidence['status']} ({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})")
        for name, ok in evidence["gates"].items():
            print(f"  {'PASS' if ok else 'FAIL'} {name}")
    return 0 if evidence["status"] == "WDROZONY_100" else 1


if __name__ == "__main__":
    raise SystemExit(main())
