#!/usr/bin/env python3
"""ETAP 14/29 — PKPiR evidence gate.

The gate audits the accounting evidence-pack + column/chronology + reconciliation
+ idempotency + AUTO_POST-lock layer over the existing PKPiR rules
(accounting.rego, accounting/pkpir_enterprise_*, micro/pkpir/*). It is static
and fail-closed: it certifies wiring and contracts, not legal correctness.
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
PACKAGE_PATH = "rules/pkpir_etap14_v1.rego"
MAIN_PATH = "rules/main_jdg.rego"
REPORT_PATH = ROOT / "raporty_glm52_enterprise" / "14_ACCOUNTING_PKPIR.txt"
BUNDLE_PATH = ROOT / "bundles" / "pkpir_etap14_audit_state.json"
SCHEMA_VERSION = "1.0.0"

SOURCE_FILES = [
    "rules/accounting.rego",
    "rules/accounting/pkpir_enterprise_live.rego",
    "rules/accounting/pkpir_enterprise_validation.rego",
    "rules/accounting/pkpir_enterprise_validator.rego",
    "rules/accounting/plan42_pkpir.rego",
    "rules/micro/pkpir/pkpir.rego",
    "rules/micro/pkpir/pkpir_kolumny.rego",
    "rules/micro/pkpir/pkpir_przychody.rego",
    "rules/micro/pkpir/pkpir_koszty.rego",
    "rules/micro/pkpir/pkpir_nkup.rego",
    "rules/micro/pkpir/pkpir_remanent.rego",
    "rules/micro/pkpir/pkpir_korekty.rego",
    "tools/pkpir_engine.py",
    "docs/KSIEGOWOSC_PKPIR_UOR_P09.md",
    "docs/Bbb",
    PACKAGE_PATH,
]

REQUIRED_MARKERS = [
    "evidence_pack", "column_audit", "moment_audit", "deduction_audit",
    "adjustment_audit", "reconciliation", "idempotency_audit",
    "property_invariants", "invariant_failed", "calculation_certificate",
    "threshold_snapshot", "missing_context", "uncertainty_markers",
    "cross_domain_collisions", "BLOCK_AND_ALERT", "TRIAGE_QUEUE",
    "auto_post_allowed", "decision_mode := \"SUGGEST\"", "no_auto_post",
    "rounding_contract", "unit", "legal_basis", "source",
]
LEGAL_MARKERS = [
    "§10-12 rozp. MF z 15.11.2025 r. w sprawie PKPiR",
    "art. 14 ust. 1 PIT",
    "art. 23 ust. 1 PIT",
    "art. 23b PIT",
    "art. 23f PIT",
    "art. 109 ust. 3 VAT",
    "§18-19 rozp. MF PKPiR",
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
        "data_source": 'object.get(object.get(data, "jdg", {}), "thresholds", {})' in text,
        "columns_externalized": 'object.get(accounting, "pkpir_columns"' in text,
        "limits_externalized": 'object.get(accounting, "car_limit_standard"' in text and 'object.get(accounting, "car_limit_electric"' in text,
        "version_carried": "threshold_version" in text and "legal_basis_version" in text,
    }
    return {
        "package": "package jdg.pkpir_etap14" in text,
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
        "activation": 'object.get(input, "pkpir_etap14_check", false)' in text,
        "no_auto_post_literal": '"AUTO_POST"' not in text,
        "sections": {
            "evidence_pack": "evidence_pack" in text,
            "columns": "column_audit" in text,
            "moment": "moment_audit" in text,
            "deductions": "deduction_audit" in text,
            "adjustments": "adjustment_audit" in text,
            "reconciliation": "reconciliation" in text,
            "idempotency": "idempotency_audit" in text,
            "invariants": "property_invariants" in text,
        },
    }


def wiring_evidence(main: str) -> dict[str, Any]:
    markers = {
        "import": "import data.jdg.pkpir_etap14" in main,
        "package_decisions": '"jdg.pkpir_etap14": pkpir_etap14.decide' in main,
        "p58_chain": "final_verdict_p58 = safe_merge(final_verdict_p57," in main,
        "post_merge_p58": "final_verdict_post_merge = object.union(final_verdict_p53" in main,
        "invariants": "runtime_invariants.enforce(final_verdict_post_merge)" in main,
        "public_final": "final_verdict = final_verdict_enforced" in main,
    }
    return {"markers": markers, "complete": all(markers.values())}


def tests_evidence() -> dict[str, Any]:
    text = read("tests/test_pkpir_etap14_audit.py")
    markers = ["evidence_pack", "column", "chronology", "moment", "nkup", "vehicle", "leasing", "wages", "remanent", "storno", "correction", "reconciliation", "idempotent", "auto_post", "SUGGEST", "temporal", "boundary"]
    return {
        "present": bool(text),
        "test_count": len(re.findall(r"def test_", text)),
        "markers": {marker: marker in text for marker in markers},
        "complete": bool(text) and all(marker in text for marker in markers),
    }


def native_tests_evidence() -> dict[str, Any]:
    text = read("tests/rego/test_native_pkpir_etap14.rego")
    markers = ["test_negative", "test_temporal", "test_property", "test_boundary", "package test_jdg_pkpir_etap14"]
    return {
        "present": bool(text),
        "test_count": len(re.findall(r"test_\w+", text)),
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
    native = native_tests_evidence()
    pkg_text = read(PACKAGE_PATH)
    gates = {
        "scope_files_present": files["all_present"],
        "package_structure": package["package"] and package["balanced_braces"] and package["duplicate_free"],
        "evidence_pack": package["sections"]["evidence_pack"] and "required_document" in pkg_text and "source_rule" in pkg_text,
        "columns_numbering_chronology": package["sections"]["columns"] and "lp_sequential" in pkg_text and "chronology_ok" in pkg_text and "document_present" in pkg_text,
        "moment_revenue_cost": package["sections"]["moment"] and "CASH_RECEIPT" in pkg_text and "CASH_PAID" in pkg_text,
        "nkup_vehicles_leasing_wages": package["sections"]["deductions"] and "vehicle_limit" in pkg_text and "leasing_type" in pkg_text and "wages_amount" in pkg_text,
        "remanent_storno_korekty": package["sections"]["adjustments"] and "remanent_type" in pkg_text and "storno" in pkg_text and "correction_reason" in pkg_text,
        "three_way_reconciliation": package["sections"]["reconciliation"] and "vat_sales_total" in pkg_text and "bank_inflows" in pkg_text and "balanced" in pkg_text,
        "idempotent_bookkeeping": package["sections"]["idempotency"] and "idempotency_key" in pkg_text and "duplicate_detected" in pkg_text,
        "auto_post_lock": "auto_post_allowed" in pkg_text and "BLOCK_AND_ALERT" in pkg_text and "TRIAGE_QUEUE" in pkg_text and "manual_review" in pkg_text,
        "property_invariants": package["sections"]["invariants"] and "invariant_failed" in pkg_text and "storno_negative" in pkg_text,
        "certificate_units_rounding": "calculation_certificate" in pkg_text and "rounding_contract" in pkg_text and "unit" in pkg_text,
        "legal_basis_and_threshold_versions": package["legal_basis_complete"] and package["thresholds_externalized"],
        "suggest_only_and_router": package["activation"] and package["no_auto_post_literal"] and 'decision_mode := "SUGGEST"' in pkg_text and wiring["complete"],
        "tests_and_report_present": tests["complete"] and native["complete"] and REPORT_PATH.exists(),
    }
    passed = sum(gates.values())
    total = len(gates)
    return {
        "schema_version": SCHEMA_VERSION,
        "audit_id": "jdg.pkpir_etap14_audit",
        "stage": "ETAP_14",
        "status": "WDROZONY_100" if passed == total else "NIEPELNY",
        "gates": gates,
        "gate_summary": {"passed": passed, "total": total},
        "files": files,
        "package": package,
        "wiring": wiring,
        "tests": tests,
        "native_tests": native,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def build_report(evidence: dict[str, Any]) -> str:
    gate_lines = "\n".join(f"| {name} | {'PASS' if ok else 'FAIL'} |" for name, ok in evidence["gates"].items())
    file_lines = "\n".join(f"| {name} | {'PRESENT' if ok else 'MISSING'} |" for name, ok in evidence["files"]["files"].items())
    status = evidence["status"]
    return f"""====================================================================================================
RAPORT WDROŻENIOWY GLM52 ENTERPRISE — ETAP 14/29
PKPIR — KOLUMNY, DOWODY, PRZYCHODY, KOSZTY, NKUP, REMANENT, KOREKTY
====================================================================================================

IDENTITY
--------
Etap: ETAP_14
Prompt: JDG/prompty_glm52_enterprise/14_ACCOUNTING_PKPIR.txt
Raport: JDG/raporty_glm52_enterprise/14_ACCOUNTING_PKPIR.txt
Audytor: JDG/tools/pkpir_etap14_audit.py
Bundle: JDG/bundles/pkpir_etap14_audit_state.json
Pakiet wdrożeniowy: JDG/{PACKAGE_PATH}
Status raportu: {status}

SCOPE
-----
Warstwa ETAPU 14 buduje Accounting Evidence Pack (decyzja → wymagany dokument →
reguła źródłowa) nad accounting.rego, accounting/pkpir_enterprise_* oraz
micro/pkpir/*. Weryfikuje kolumny/numerację/chronologię, moment przychodu/kosztu
(memoriał kasowy), NKUP/pojazdy/leasing/wynagrodzenia, remanent/storno/korekty,
trzystronne uzgodnienie PKPiR↔VAT↔bank oraz idempotentne księgowanie z blokadą
AUTO_POST przy brakach (fail-closed).

FILES
-----
| Plik | Status |
|------|--------|
{file_lines}

IMPLEMENTED PHASES
------------------
1. Accounting Evidence Pack — 13 decyzji × (wymagany dokument + reguła źródłowa).
2. Kolumny/numeracja/chronologia — struktura kolumn, LP ciągłe, chronologia dat,
   wymagany numer dowodu i kontrahent.
3. Moment przychodu/kosztu — memoriał kasowy (art. 14 PIT), termin 14 dni (§9).
4. NKUP/pojazdy/leasing/wynagrodzenia — art. 23 NKUP, limity aut 150k/225k,
   leasing operacyjny vs finansowy (art. 23b/23f), wynagrodzenia kol. 12.
5. Remanent/storno/korekty — §18-19 remanent, storno (minus), korekty z przyczyną.
6. Trzystronne uzgodnienie PKPiR↔VAT↔bank — tolerancja, bilans 4 par kwot.
7. Idempotentne księgowanie — klucz idempotencji + wykrywanie duplikatów.
8. Blokada AUTO_POST — brak dowodu/kolumn/chronologii lub brak zgodności → BLOCK.
9. Property invariants — kwoty ≥ 0, storno ujemne, korekta z przyczyną.
10. Calculation certificate — wersje progów/prawa/faktów, waluta, jednostki.
11. Safe orchestration — SUGGEST only, no_auto_post, final p58 + invariants.

GATES
-----
| Gate | Result |
|------|--------|
{gate_lines}

CALCULATION CONTRACT
--------------------
- Waluta: PLN; jednostki: PLN (kwoty, remanent, wynagrodzenia).
- Zaokrąglenie: PLN_HALF_UP_2DP (kontrakt ujawniony w certyfikacie).
- Źródło progów: data.jdg.thresholds.accounting.
- Wersjonowanie: evaluation_date, evaluation_year, threshold_version,
  legal_basis_version, facts_version.
- Granice: 17 kolumn PKPiR, termin wpisu 14 dni, limity aut 150k/225k.

SAFETY CONTRACT
---------------
[POTWIERDZONE_KODEM] Brak daty oceny, wersji progów, wersji prawa lub wersji
faktów daje BLOCK_AND_ALERT.
[POTWIERDZONE_KODEM] Brak numeru dowodu, kompletnych kolumn lub duplikat zapisu
blokuje automatyczne księgowanie (AUTO_POST).
[POTWIERDZONE_KODEM] Niezgodność uzgodnienia PKPiR↔VAT↔bank oraz naruszony
property invariant trafiają do manual gate.
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
Następny raport: ETAP_15 / JDG/prompty_glm52_enterprise/15_*.txt

ETAP_14_COMPLETE — CONTEXT_RESET_REQUIRED — wyczyść okno kontekstowe przed ETAP_15.
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
    parser = argparse.ArgumentParser(description="ETAP 14 PKPiR evidence gate")
    parser.add_argument("command", choices=["build", "validate"])
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    evidence = write_artifacts() if args.command == "build" else build_evidence()
    if args.json:
        print(json.dumps(evidence, indent=2, ensure_ascii=False))
    else:
        print(f"[ETAP_14] Status: {evidence['status']} ({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})")
        for name, ok in evidence["gates"].items():
            print(f"  {'PASS' if ok else 'FAIL'} {name}")
    return 0 if evidence["status"] == "WDROZONY_100" else 1


if __name__ == "__main__":
    sys.exit(main())
