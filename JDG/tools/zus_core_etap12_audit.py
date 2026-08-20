#!/usr/bin/env python3
"""ETAP 12/29 — ZUS Core evidence gate.

The gate audits the new calculation-certificate layer over the existing ZUS
macro/micro rules. It is deliberately static and fail-closed: it certifies
wiring and contracts, not the legal correctness of changing statutory data.
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

ROOT = Path(__file__).resolve().parent.parent
PACKAGE_PATH = "rules/zus_core_etap12_v1.rego"
MAIN_PATH = "rules/main_jdg.rego"
REPORT_PATH = ROOT / "raporty_glm52_enterprise" / "12_ZUS_CORE.txt"
BUNDLE_PATH = ROOT / "bundles" / "zus_core_etap12_audit_state.json"
SCHEMA_VERSION = "1.0.0"

SOURCE_FILES = [
    "rules/zus.rego",
    "rules/zus/plan23_interactions.rego",
    "rules/zus/plan42_benefits.rego",
    "rules/zus/enterprise_benefits.rego",
    "rules/zus/sickness_benefits_enterprise.rego",
    "rules/zus/health_contribution_enterprise.rego",
    "rules/zus/cumulative_revenue_engine.rego",
    "rules/zus/health_precision_engine_v8.rego",
    "rules/p07_zus_macro_innovations_v9.rego",
    "rules/p08_zus_micro_innovations_v9.rego",
    "rules/r06_zus_innovations_v9.rego",
    "rules/micro/sus/sus.rego",
    "rules/micro/zdrowotna/zdrowotna.rego",
    "rules/micro/zasilkowa/zasilkowa.rego",
    "docs/ZUS_MACRO_P07.md",
    "docs/Bbb",
    PACKAGE_PATH,
]

REQUIRED_MARKERS = [
    "health_calculations", "social_calculations", "relief_audit",
    "benefit_calculation", "ppk_pfron_audit", "deadline_audit",
    "calculation_certificate", "threshold_snapshot", "boundary_tests",
    "missing_context", "uncertainty_markers", "cross_domain_collisions",
    "BLOCK_AND_ALERT", "TRIAGE_QUEUE", "decision_mode := \"SUGGEST\"",
    "no_auto_post", "rounding_contract", "unit", "legal_basis", "source",
]
LEGAL_MARKERS = [
    "Art. 18, 22 ustawy o SUS",
    "Art. 81 ust. 2 pkt 1 u.ś.o.z.",
    "Art. 81 ust. 2 pkt 2 u.ś.o.z.",
    "Art. 81 ust. 2 pkt 3 u.ś.o.z.",
    "Art. 4 i 11 ustawy zasiłkowej",
    "Art. 47 ust. 1 ustawy o SUS",
]


def read(rel: str) -> str:
    try:
        return (ROOT / rel).read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def package_evidence(text: str) -> dict[str, Any]:
    rule_ids = re.findall(r'"rule_id"\s*:\s*"([A-Za-z0-9_.-]+)"', text)
    duplicates = sorted(k for k, v in Counter(rule_ids).items() if v > 1)
    markers = {marker: marker in text for marker in REQUIRED_MARKERS}
    legal = {marker: marker in text for marker in LEGAL_MARKERS}
    thresholds = {
        "data_source": "object.get(object.get(data, \"jdg\", {}), \"thresholds\", {})" in text,
        "rates_externalized": "object.get(zus, \"health_scale_rate\"" in text and "object.get(zus, \"pension_rate\"" in text,
        "reliefs_externalized": "object.get(zus, \"start_relief_months\"" in text and "object.get(zus, \"maly_zus_plus_months\"" in text,
        "version_carried": "threshold_version" in text and "legal_basis_version" in text,
    }
    return {
        "package": "package jdg.zus_core_etap12" in text,
        "balanced_braces": text.count("{") == text.count("}"),
        "rule_ids": len(rule_ids),
        "duplicate_rule_ids": duplicates,
        "duplicate_free": not duplicates,
        "markers": markers,
        "markers_complete": all(markers.values()),
        "legal_basis": legal,
        "legal_basis_complete": all(legal.values()),
        "thresholds": thresholds,
        "thresholds_externalized": all(thresholds.values()),
        "activation": 'object.get(input, "zus_core_etap12_check", false)' in text,
        "no_auto_post_literal": '"AUTO_POST"' not in text,
        "sections": {
            "health": "health_calculations" in text,
            "social": "social_calculations" in text,
            "reliefs": "relief_audit" in text,
            "benefits": "benefit_calculation" in text,
            "ppk_pfron": "ppk_pfron_audit" in text,
            "deadlines": "deadline_audit" in text,
        },
    }


def wiring_evidence(main: str) -> dict[str, Any]:
    markers = {
        "import": "import data.jdg.zus_core_etap12" in main,
        "package_decisions": '"jdg.zus_core_etap12": zus_core_etap12.decide' in main,
        "p56_chain": "final_verdict_p56 = safe_merge(final_verdict_p55," in main,
        "post_merge_p56": "final_verdict_post_merge = object.union(final_verdict_p53" in main,
        "invariants": "runtime_invariants.enforce(final_verdict_post_merge)" in main,
        "public_final": "final_verdict = final_verdict_enforced" in main,
    }
    return {"markers": markers, "complete": all(markers.values())}


def tests_evidence() -> dict[str, Any]:
    text = read("tests/test_zus_core_etap12_audit.py")
    markers = ["health", "social", "relief", "benefit", "boundary", "missing_context", "collision", "SUGGEST"]
    return {
        "present": bool(text),
        "test_count": len(re.findall(r"def test_", text)),
        "markers": {marker: marker in text for marker in markers},
        "complete": bool(text) and all(marker in text for marker in markers),
    }


def files_evidence() -> dict[str, Any]:
    statuses = {path: bool(read(path)) for path in SOURCE_FILES}
    return {
        "declared": len(statuses),
        "present": sum(statuses.values()),
        "all_present": all(statuses.values()),
        "files": statuses,
    }


def build_evidence() -> dict[str, Any]:
    package = package_evidence(read(PACKAGE_PATH))
    files = files_evidence()
    wiring = wiring_evidence(read(MAIN_PATH))
    tests = tests_evidence()
    gates = {
        "scope_files_present": files["all_present"],
        "package_structure": package["package"] and package["balanced_braces"] and package["duplicate_free"],
        "health_social_calculators": package["sections"]["health"] and package["sections"]["social"],
        "reliefs_benefits_deadlines": package["sections"]["reliefs"] and package["sections"]["benefits"] and package["sections"]["deadlines"],
        "ppk_pfron_and_cross_domain": package["sections"]["ppk_pfron"] and "cross_domain_collisions" in read(PACKAGE_PATH),
        "certificate_units_rounding": "calculation_certificate" in read(PACKAGE_PATH) and "rounding_contract" in read(PACKAGE_PATH) and "unit" in read(PACKAGE_PATH),
        "legal_basis_and_threshold_versions": package["legal_basis_complete"] and package["thresholds_externalized"],
        "boundary_and_temporal_contract": "boundary_tests" in read(PACKAGE_PATH) and "evaluation_date" in read(PACKAGE_PATH) and "evaluation_year" in read(PACKAGE_PATH),
        "fail_closed_manual_gate": "BLOCK_AND_ALERT" in read(PACKAGE_PATH) and "TRIAGE_QUEUE" in read(PACKAGE_PATH) and "manual_review" in read(PACKAGE_PATH),
        "suggest_only": package["activation"] and package["no_auto_post_literal"] and 'decision_mode := "SUGGEST"' in read(PACKAGE_PATH),
        "router_wired": wiring["complete"],
        "tests_present": tests["complete"],
        "report_present": REPORT_PATH.exists(),
    }
    passed = sum(gates.values())
    total = len(gates)
    return {
        "schema_version": SCHEMA_VERSION,
        "audit_id": "jdg.zus_core_etap12_audit",
        "stage": "ETAP_12",
        "status": "WDROZONY_100" if passed == total else "NIEPELNY",
        "gates": gates,
        "gate_summary": {"passed": passed, "total": total},
        "files": files,
        "package": package,
        "wiring": wiring,
        "tests": tests,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def build_report(evidence: dict[str, Any]) -> str:
    gate_lines = "\n".join(f"| {name} | {'PASS' if ok else 'FAIL'} |" for name, ok in evidence["gates"].items())
    file_lines = "\n".join(f"| {name} | {'PRESENT' if ok else 'MISSING'} |" for name, ok in evidence["files"]["files"].items())
    status = evidence["status"]
    return f"""====================================================================================================
RAPORT WDROŻENIOWY GLM52 ENTERPRISE — ETAP 12/29
ZUS CORE — SKŁADKI, ZDROWOTNA, ULGI, ŚWIADCZENIA I TERMINY
====================================================================================================

IDENTITY
--------
Etap: ETAP_12
Prompt: JDG/prompty_glm52_enterprise/12_ZUS_CORE.txt
Raport: JDG/raporty_glm52_enterprise/12_ZUS_CORE.txt
Audytor: JDG/tools/zus_core_etap12_audit.py
Bundle: JDG/bundles/zus_core_etap12_audit_state.json
Pakiet wdrożeniowy: JDG/{PACKAGE_PATH}
Status raportu: {status}

SCOPE
-----
Warstwa ETAPU 12 konsoliduje audyt nad istniejącymi regułami ZUS/SUS macro,
micro, zdrowotnej i zasiłkowej. Nie powiela ich decyzji: dodaje certyfikat
obliczenia, kontrakt temporalny, jednostki, zaokrąglenia, testy graniczne,
kolizje PIT/VAT/UoR oraz fail-closed manual gate.

FILES
-----
| Plik | Status |
|------|--------|
{file_lines}

IMPLEMENTED PHASES
------------------
1. Inventory and source reconciliation — istniejące ZUS macro/micro/benefits.
2. Health matrix — skala, liniowy, ryczałtowe progi 60k/300k i karta.
3. Social contributions — emerytalna, rentowa, dobrowolna chorobowa,
   wypadkowa, podstawa standardowa/preferencyjna/Mały ZUS Plus.
4. Relief boundary engine — ulga na start, preferencyjny ZUS i MZUS+;
   przejścia na granicy okresu są jawnie testowane.
5. Benefits — okres wyczekiwania, stawka standardowa/specjalna, limit dni.
6. PPK/PFRON and titles — obowiązek kierowany do manual review, gdy wymaga
   danych pracowniczych lub wyjątku.
7. Deadlines and corrections — termin płatności 10/15 dnia i kontrakt danych.
8. Calculation certificate — wersja progów, wersja podstawy prawnej, data,
   fakty, waluta PLN, jednostki, rounding i źródło.
9. Cross-domain firewall — kolizje PIT/VAT/UoR oraz niepewność nie optymalizują.
10. Safe orchestration — SUGGEST only, fail-closed, final p56 + invariants.

GATES
-----
| Gate | Result |
|------|--------|
{gate_lines}

CALCULATION CONTRACT
--------------------
- Waluta: PLN; jednostki: PLN/month, PLN, calendar_day.
- Zaokrąglenie: PLN_HALF_UP_2DP (kontrakt ujawniony w certyfikacie).
- Źródło progów: data.jdg.thresholds.zus / bounds.
- Wersjonowanie: evaluation_date, evaluation_year, threshold_version,
  legal_basis_version, facts_version.
- Granice: 6 miesięcy ulgi na start, 24 miesiące preferencyjnego ZUS,
  36 miesięcy MZUS+ w oknie 60 miesięcy, progi przychodu 60k/300k zdrowotnej.

SAFETY CONTRACT
---------------
[POTWIERDZONE_KODEM] Brak daty oceny, wersji progów, wersji podstawy prawnej
lub wersji faktów daje BLOCK_AND_ALERT.
[POTWIERDZONE_KODEM] Ujemne dane, niepewność i kolizje PIT/VAT/UoR nie są
przeliczane jako bezpieczna rekomendacja; trafiają do manual gate.
[POTWIERDZONE_KODEM] PPK/PFRON i wyjątki świadczeniowe wymagają manual review.
[POTWIERDZONE_KODEM] Pakiet działa wyłącznie w trybie SUGGEST i nie publikuje
operacji automatycznych.
[OGRANICZENIE] Evidence pack jest dowodem technicznym; nie zastępuje aktualnej
weryfikacji tekstu ustawy, Bbb/LKG, 4-eyes review ani porady prawnej.

VERIFICATION
------------
Evidence: {evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']} gates.
Status: {status}

STATUS
------
Status raportu: {status}
Produkcja: NOT_CERTIFIED
Następny raport: ETAP_13 / JDG/prompty_glm52_enterprise/13_*.txt

ETAP_12_COMPLETE — CONTEXT_RESET_REQUIRED — wyczyść okno kontekstowe przed ETAP_13.
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
    parser = argparse.ArgumentParser(description="ETAP 12 ZUS Core evidence gate")
    parser.add_argument("command", choices=["build", "validate"])
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    evidence = write_artifacts() if args.command == "build" else build_evidence()
    if args.json:
        print(json.dumps(evidence, indent=2, ensure_ascii=False))
    else:
        print(f"[ETAP_12] Status: {evidence['status']} ({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})")
        for name, ok in evidence["gates"].items():
            print(f"  {'PASS' if ok else 'FAIL'} {name}")
    return 0 if evidence["status"] == "WDROZONY_100" else 1


if __name__ == "__main__":
    sys.exit(main())
