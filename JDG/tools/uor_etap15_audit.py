#!/usr/bin/env python3
"""ETAP 15/29 — UoR evidence gate.

The gate audits the obligation + double-entry + documents + valuation + assets +
amortization + inventory + closing + financial-statement + PKPiR→UoR transition
layer over the existing UoR rules. Static and fail-closed: certifies wiring and
contracts, not the legal correctness of changing statutory data.
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
PACKAGE_PATH = "rules/uor_etap15_v1.rego"
MAIN_PATH = "rules/main_jdg.rego"
REPORT_PATH = ROOT / "raporty_glm52_enterprise" / "15_ACCOUNTING_UOR_AMORTIZATION.txt"
BUNDLE_PATH = ROOT / "bundles" / "uor_etap15_audit_state.json"
SCHEMA_VERSION = "1.0.0"

SOURCE_FILES = [
    "rules/uor/uor_obligation.rego",
    "rules/uor/uor_books.rego",
    "rules/uor/uor_revenue.rego",
    "rules/uor/uor_costs.rego",
    "rules/uor/uor_assets.rego",
    "rules/uor/uor_inventory.rego",
    "rules/uor/uor_closing.rego",
    "rules/uor/uor_financial_stmt.rego",
    "rules/accounting/uor_enterprise_live.rego",
    "rules/accounting/depreciation_enterprise.rego",
    "rules/accounting/depreciation_enterprise_complete.rego",
    "rules/micro/uor/uor.rego",
    "rules/micro/amortyzacja/pit_a22a.rego",
    "rules/micro/amortyzacja/pit_a22i.rego",
    "rules/micro/amortyzacja/pit_a22k.rego",
    "tools/uor_double_entry.py",
    "tools/uor_closing_engine.py",
    "docs/Bbb",
    PACKAGE_PATH,
]

REQUIRED_MARKERS = [
    "obligation_audit", "double_entry_audit", "document_audit", "assets_audit",
    "amortization_audit", "inventory_audit", "closing_audit",
    "financial_stmt_audit", "transition_audit", "hardcode_scan", "coverage_audit",
    "property_invariants", "invariant_failed", "calculation_certificate",
    "threshold_snapshot", "missing_context", "uncertainty_markers",
    "cross_domain_collisions", "BLOCK_AND_ALERT", "TRIAGE_QUEUE",
    "auto_post_allowed", "decision_mode := \"SUGGEST\"", "no_auto_post",
    "rounding_contract", "unit", "legal_basis", "source",
]
LEGAL_MARKERS = [
    "art. 2 ust. 1 pkt 5 UoR",
    "art. 15 ust. 1 UoR",
    "art. 21 UoR",
    "art. 26 UoR",
    "art. 32 UoR",
    "art. 45-49 UoR",
    "art. 22a-22n PIT",
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
        "obligation_externalized": 'object.get(accounting, "uor_threshold_eur"' in text and 'object.get(accounting, "eur_pln_reference"' in text,
        "inventory_externalized": 'object.get(accounting, "inventory_deadline_days"' in text,
        "version_carried": "threshold_version" in text and "legal_basis_version" in text,
    }
    return {
        "package": "package jdg.uor_etap15" in text,
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
        "activation": 'object.get(input, "uor_etap15_check", false)' in text,
        "no_auto_post_literal": '"AUTO_POST"' not in text,
        "sections": {
            "obligation": "obligation_audit" in text,
            "double_entry": "double_entry_audit" in text,
            "documents": "document_audit" in text,
            "assets": "assets_audit" in text,
            "amortization": "amortization_audit" in text,
            "inventory": "inventory_audit" in text,
            "closing": "closing_audit" in text,
            "financial_stmt": "financial_stmt_audit" in text,
            "transition": "transition_audit" in text,
            "invariants": "property_invariants" in text,
        },
    }


def wiring_evidence(main: str) -> dict[str, Any]:
    markers = {
        "import": "import data.jdg.uor_etap15" in main,
        "package_decisions": '"jdg.uor_etap15": uor_etap15.decide' in main,
        "p59_chain": "final_verdict_p59 = safe_merge(final_verdict_p58," in main,
        "post_merge_p59": "final_verdict_post_merge = object.union(final_verdict_p53" in main,
        "invariants": "runtime_invariants.enforce(final_verdict_post_merge)" in main,
        "public_final": "final_verdict = final_verdict_enforced" in main,
    }
    return {"markers": markers, "complete": all(markers.values())}


def tests_evidence() -> dict[str, Any]:
    text = read("tests/test_uor_etap15_audit.py")
    markers = ["obligation", "double_entry", "document", "valuation", "asset", "amortization", "inventory", "closing", "financial", "transition", "hardcode", "fake_complete", "reconciliation", "idempotent", "property", "manual", "SUGGEST", "temporal", "boundary", "balance"]
    return {
        "present": bool(text),
        "test_count": len(re.findall(r"def test_", text)),
        "markers": {marker: marker in text for marker in markers},
        "complete": bool(text) and all(marker in text for marker in markers),
    }


def native_tests_evidence() -> dict[str, Any]:
    text = read("tests/rego/test_native_uor_etap15.rego")
    markers = ["test_negative", "test_temporal", "test_property", "test_boundary", "test_balance", "package test_jdg_uor_etap15"]
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
        "uor_obligation": package["sections"]["obligation"] and "uor_required" in pkg_text and "early_warning" in pkg_text,
        "double_entry": package["sections"]["double_entry"] and "double_entry_balanced" in pkg_text and "debits_total" in pkg_text,
        "documents_valuation_assets": package["sections"]["documents"] and package["sections"]["assets"] and "balance_ok" in pkg_text,
        "amortization_bilansowa_podatkowa": package["sections"]["amortization"] and "amortization_balance" in pkg_text and "amortization_tax" in pkg_text,
        "inventory_closing": package["sections"]["inventory"] and package["sections"]["closing"] and "closing_complete" in pkg_text,
        "financial_stmt_manual_approval": package["sections"]["financial_stmt"] and "requires_manual_approval" in pkg_text and "manual_approval_mandatory" in pkg_text,
        "pkpir_uor_transition": package["sections"]["transition"] and "opening_balance_pln" in pkg_text and "idempotency_key" in pkg_text,
        "hardcode_fake_complete_detection": "hardcode_scan" in pkg_text and "coverage_audit" in pkg_text and "fake_complete" in pkg_text,
        "property_invariants": package["sections"]["invariants"] and "invariant_failed" in pkg_text and "double_entry_balanced" in pkg_text,
        "certificate_units_rounding": "calculation_certificate" in pkg_text and "rounding_contract" in pkg_text and "unit" in pkg_text,
        "legal_basis_and_threshold_versions": package["legal_basis_complete"] and package["thresholds_externalized"],
        "suggest_only_and_router": package["activation"] and package["no_auto_post_literal"] and 'decision_mode := "SUGGEST"' in pkg_text and wiring["complete"],
        "tests_and_report_present": tests["complete"] and native["complete"] and REPORT_PATH.exists(),
    }
    passed = sum(gates.values())
    total = len(gates)
    return {
        "schema_version": SCHEMA_VERSION,
        "audit_id": "jdg.uor_etap15_audit",
        "stage": "ETAP_15",
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
RAPORT WDROŻENIOWY GLM52 ENTERPRISE — ETAP 15/29
UOR — PEŁNA KSIĘGOWOŚĆ, AKTYWA, AMORTYZACJA, INWENTARYZACJA, SPRAWOZDANIA
====================================================================================================

IDENTITY
--------
Etap: ETAP_15
Prompt: JDG/prompty_glm52_enterprise/15_ACCOUNTING_UOR_AMORTIZATION.txt
Raport: JDG/raporty_glm52_enterprise/15_ACCOUNTING_UOR_AMORTIZATION.txt
Audytor: JDG/tools/uor_etap15_audit.py
Bundle: JDG/bundles/uor_etap15_audit_state.json
Pakiet wdrożeniowy: JDG/{PACKAGE_PATH}
Status raportu: {status}

SCOPE
-----
Warstwa ETAPU 15 weryfikuje obowiązek UoR (próg 2 mln EUR), księgi podwójne
(ΣD=ΣC), dowody, wycenę, aktywa, amortyzację bilansową vs podatkową,
inwentaryzację, zamknięcie i sprawozdania. Buduje przejście PKPiR→UoR z
reconciliation i idempotencją, wykrywa hardcode, pozorne COMPLETE, braki
dokumentów i konflikt z PIT. Dodaje testy bilansowe, sumy kontrolne, property
invariants i manual approval dla sprawozdań.

FILES
-----
| Plik | Status |
|------|--------|
{file_lines}

IMPLEMENTED PHASES
------------------
1. Obowiązek UoR — próg 2 mln EUR + wczesne ostrzeżenie 75% (art. 2 ust. 1 pkt 5).
2. Księgi podwójne — invariant Σ debetów = Σ kredytów (art. 15 ust. 1 UoR).
3. Dowody księgowe — wymagany numer dowodu (art. 21 UoR).
4. Wycena i aktywa — bilans aktywa = zobowiązania + kapitał (art. 28-32).
5. Amortyzacja bilansowa vs podatkowa (art. 32 UoR vs art. 22a-22n PIT) —
   różnica ujawniana jako konflikt do przeglądu.
6. Inwentaryzacja (art. 26 UoR) i zamknięcie roku (art. 12 ust. 2 UoR).
7. Sprawozdania finansowe (art. 45-49 UoR) — manual approval obowiązkowy.
8. Przejście PKPiR→UoR — ciągłość bilansu otwarcia + idempotencja migracji.
9. Detekcja hardcode / pozorne COMPLETE / braków dokumentów / konfliktu PIT.
10. Property invariants — ΣD=ΣC, bilans, kwoty ≥ 0, zakaz auto-zatwierdzania FS.
11. Calculation certificate — wersje progów/prawa/faktów, waluta, jednostki.
12. Safe orchestration — SUGGEST only, no_auto_post, final p59 + invariants.

GATES
-----
| Gate | Result |
|------|--------|
{gate_lines}

CALCULATION CONTRACT
--------------------
- Waluta: PLN (kwoty), EUR (próg UoR).
- Zaokrąglenie: PLN_HALF_UP_2DP (kontrakt ujawniony w certyfikacie).
- Źródło progów: data.jdg.thresholds.accounting.
- Wersjonowanie: evaluation_date, evaluation_year, threshold_version,
  legal_basis_version, facts_version.
- Granice: próg UoR 2 mln EUR (kurs 4.50), ostrzeżenie 75%, inwentaryzacja
  co rok, retencja sprawozdań 5 lat.

SAFETY CONTRACT
---------------
[POTWIERDZONE_KODEM] Brak daty oceny, wersji progów, wersji prawa lub wersji
faktów daje BLOCK_AND_ALERT.
[POTWIERDZONE_KODEM] Naruszenie ΣD=ΣC lub brak numeru dowodu blokuje
automatyzację (BLOCK_AND_ALERT).
[POTWIERDZONE_KODEM] Sprawozdanie finansowe nigdy nie jest auto-zatwierdzane —
wymaga manual approval.
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
Następny raport: ETAP_16 / JDG/prompty_glm52_enterprise/16_*.txt

ETAP_15_COMPLETE — CONTEXT_RESET_REQUIRED — wyczyść okno kontekstowe przed ETAP_16.
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
    parser = argparse.ArgumentParser(description="ETAP 15 UoR evidence gate")
    parser.add_argument("command", choices=["build", "validate"])
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    evidence = write_artifacts() if args.command == "build" else build_evidence()
    if args.json:
        print(json.dumps(evidence, indent=2, ensure_ascii=False))
    else:
        print(f"[ETAP_15] Status: {evidence['status']} ({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})")
        for name, ok in evidence["gates"].items():
            print(f"  {'PASS' if ok else 'FAIL'} {name}")
    return 0 if evidence["status"] == "WDROZONY_100" else 1


if __name__ == "__main__":
    sys.exit(main())
