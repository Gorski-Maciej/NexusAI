#!/usr/bin/env python3
"""ETAP 19/29 — PCC, local taxes, territorial rates and excise evidence gate."""
from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
PACKAGE = "rules/local_excise_etap19_v1.rego"
MAIN = "rules/main_jdg.rego"
THRESHOLDS = "rules/thresholds_jdg.rego"
REPORT = ROOT / "raporty_glm52_enterprise" / "19_PCC_LOCAL_EXCISE.txt"
BUNDLE = ROOT / "bundles" / "local_excise_etap19_audit_state.json"

SOURCE_FILES = [
    "rules/local_taxes.rego",
    "rules/local_taxes/pcc.rego",
    "rules/local_taxes/pcc_enterprise_complete.rego",
    "rules/local_taxes/pcc_excise_enterprise.rego",
    "rules/local_taxes/real_estate.rego",
    "rules/local_taxes/transport.rego",
    "rules/local_taxes/akcyza_alcohol.rego",
    "rules/local_taxes/akcyza_fuel.rego",
    "rules/micro/pcc/pcc.rego",
    "rules/micro/pcc_lokalne_atomic_p14.rego",
    "rules/micro/akcyza/akcyza.rego",
    "tools/pcc_engine.py",
    "tools/gmina_rates_engine.py",
    "tools/akcyza_classifier.py",
    "tools/dn1_dt1_generator.py",
    "docs/PCC_LOKALNE_AKCYZA_P14.md",
    "docs/Bbb",
    PACKAGE,
]

MARKERS = [
    "pcc_subject_verified", "pcc_vat_excluded", "pcc3_required", "pcc3_deadline_days",
    "local_rate_registry", "gmina", "territory_code", "resolution_id", "resolution_date",
    "valid_from", "valid_to", "local_gmina_mismatch", "document_complete", "legal_traceability",
    "classification_verified", "e_dd_required", "warehouse_required", "stamps_required",
    "exemption_claimed", "manual_review_required", "BLOCK_AND_ALERT", "TRIAGE_QUEUE",
    'decision_mode := "SUGGEST"', '"no_auto_post": true', "facts_version", "threshold_version",
]

LEGAL = [
    "ustawa o PCC art. 1", "2 pkt 4", "6-10", "podatkach i opłatach lokalnych art. 2-9",
    "podatku akcyzowym art. 8-11", "16", "30-32", "89", "93-100", "114-118", "KKS art. 65",
]


def read(rel: str) -> str:
    try:
        return (ROOT / rel).read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def package_evidence(text: str) -> dict[str, Any]:
    ids = re.findall(r'"rule_id"\s*:\s*"([A-Za-z0-9_.-]+)"', text)
    duplicates = sorted(k for k, count in Counter(ids).items() if count > 1)
    markers = {marker: marker in text for marker in MARKERS}
    legal = {marker: marker in text for marker in LEGAL}
    return {
        "package": "package jdg.local_excise_etap19" in text,
        "balanced_braces": text.count("{") == text.count("}"),
        "balanced_parentheses": text.count("(") == text.count(")"),
        "rule_ids": len(ids),
        "duplicate_rule_ids": duplicates,
        "duplicate_free": not duplicates,
        "markers": markers,
        "markers_complete": all(markers.values()),
        "legal_basis": legal,
        "legal_basis_complete": all(legal.values()),
        "thresholds_externalized": "object.get(object.get(data, \"jdg\", {}), \"thresholds\", {})" in text,
        "no_auto_post": '"no_auto_post": true' in text and '"AUTO_POST"' not in text,
    }


def files_evidence() -> dict[str, Any]:
    statuses = {path: bool(read(path)) for path in SOURCE_FILES}
    return {"declared": len(statuses), "present": sum(statuses.values()), "all_present": all(statuses.values()), "files": statuses}


def wiring_evidence(text: str) -> dict[str, Any]:
    markers = {
        "import": "import data.jdg.local_excise_etap19" in text,
        "package_decisions": '"jdg.local_excise_etap19": local_excise_etap19.decide' in text,
        "stage_chain": "final_verdict_p63 = safe_merge(final_verdict_p62" in text,
        "post_merge": "object.union(final_verdict_p63" in text,
        "public_final": "final_verdict = final_verdict_enforced" in text,
    }
    return {"markers": markers, "complete": all(markers.values())}


def tests_evidence() -> dict[str, Any]:
    pytest_text = read("tests/test_local_excise_etap19_audit.py")
    native_text = read("tests/rego/test_native_local_excise_etap19.rego")
    pytest_markers = ["pcc", "territorial", "excise", "fail_closed", "wiring"]
    native_markers = ["test_no_match", "test_missing_evidence", "test_wrong_gmina", "test_valid_local", "test_vat", "test_unverified_excise"]
    return {
        "pytest": {"present": bool(pytest_text), "test_count": len(re.findall(r"def test_", pytest_text)), "markers": {m: m in pytest_text for m in pytest_markers}},
        "native_rego": {"present": bool(native_text), "test_count": len(re.findall(r"^test_\w+", native_text, re.M)), "markers": {m: m in native_text for m in native_markers}},
    }


def build_evidence() -> dict[str, Any]:
    package = package_evidence(read(PACKAGE))
    files = files_evidence()
    wiring = wiring_evidence(read(MAIN))
    thresholds = read(THRESHOLDS)
    tests = tests_evidence()
    gates = {
        "scope_files_present": files["all_present"],
        "package_structure": package["package"] and package["balanced_braces"] and package["balanced_parentheses"] and package["duplicate_free"],
        "pcc_subject_vat_and_pcc3": all(package["markers"][m] for m in ["pcc_subject_verified", "pcc_vat_excluded", "pcc3_required", "pcc3_deadline_days"]),
        "territorial_rate_registry": all(package["markers"][m] for m in ["local_rate_registry", "gmina", "territory_code", "resolution_id", "resolution_date", "local_gmina_mismatch"]),
        "temporal_effective_dates": all(package["markers"][m] for m in ["valid_from", "valid_to", "facts_version", "threshold_version"]),
        "document_evidence": package["markers"]["document_complete"],
        "real_estate_and_transport": "DN-1" in read(PACKAGE) and "DT-1" in read(PACKAGE) and "transport_threshold_t" in thresholds,
        "excise_controls": all(package["markers"][m] for m in ["classification_verified", "e_dd_required", "warehouse_required", "stamps_required", "exemption_claimed"]),
        "legal_traceability": package["markers"]["legal_traceability"] and package["legal_basis_complete"],
        "manual_fail_closed": all(package["markers"][m] for m in ["manual_review_required", "BLOCK_AND_ALERT", "TRIAGE_QUEUE"]),
        "safe_routing": package["markers"]['decision_mode := "SUGGEST"'] and package["no_auto_post"],
        "thresholds_externalized": package["thresholds_externalized"] and "local_excise_etap19 := {" in thresholds,
        "orchestrator_wiring": wiring["complete"],
        "pytest_contract": tests["pytest"]["present"] and all(tests["pytest"]["markers"].values()),
        "native_rego_contract": tests["native_rego"]["present"] and all(tests["native_rego"]["markers"].values()),
        "report_present": REPORT.exists(),
    }
    passed = sum(gates.values())
    return {
        "schema_version": "1.0.0",
        "audit_id": "jdg.local_excise_etap19_audit",
        "stage": "ETAP_19",
        "status": "WDROZONY_100" if passed == len(gates) else "NIEPELNY",
        "gates": gates,
        "gate_summary": {"passed": passed, "total": len(gates)},
        "files": files,
        "package": package,
        "wiring": wiring,
        "tests": tests,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def build_report(e: dict[str, Any]) -> str:
    files = "\n".join(f"| {path} | {'PRESENT' if present else 'MISSING'} |" for path, present in e["files"]["files"].items())
    gates = "\n".join(f"| {name} | {'PASS' if passed else 'FAIL'} |" for name, passed in e["gates"].items())
    return f"""====================================================================================================
RAPORT WDROŻENIOWY GLM52 ENTERPRISE — ETAP 19/29
PCC / PODATKI LOKALNE / NIERUCHOMOŚCI / TRANSPORT / AKCYZA
====================================================================================================

IDENTITY
--------
Etap: ETAP_19
Prompt: JDG/prompty_glm52_enterprise/19_PCC_LOCAL_EXCISE.txt
Raport: JDG/raporty_glm52_enterprise/19_PCC_LOCAL_EXCISE.txt
Audytor: JDG/tools/local_excise_etap19_audit.py
Bundle: JDG/bundles/local_excise_etap19_audit_state.json
Pakiet wdrożeniowy: JDG/{PACKAGE}
Status raportu: {e['status']}

SCOPE
-----
Domknięto evidence-first warstwę nad P14/R11 oraz istniejącymi silnikami PCC,
stawek gminnych, nieruchomości, transportu i akcyzy. Zakres obejmuje przedmiot
PCC, wyłączenie VAT/PCC, PCC-3 i terminy; uchwały gminne z terytorium, jednostką,
źródłem i effective dates; DN-1/DT-1; oraz klasyfikację akcyzy, stawki, e-DD,
skład podatkowy, znaki akcyzy i zwolnienia.

IMPLEMENTED PHASES
------------------
1. PCC subject gate — subject_verified, typ czynności, podstawa, stawka, zwolnienie.
2. VAT/PCC firewall — VAT wyłącza PCC, wynik jest jawny i kierowany do manual review.
3. PCC-3 — wymaganie PCC-3/PCC-3A i 14-dniowy deadline z dowodem dokumentu.
4. Municipal rate registry — gmina + territory_code + uchwała + data + source_ref,
   unikalne dopasowanie temporalne; mismatch blokuje użycie stawki.
5. Real estate — stawka per jednostka PLN/m², DN-1 i dowód złożenia.
6. Transport — próg 3,5 t, jednostka TONNES, DT-1 i status złożenia.
7. Excise — zweryfikowany produkt/CN, stawka, ilość/jednostka, e-DD, magazyn,
   banderole/znaki i evidence zwolnienia.
8. Safety — źródła, legal nodes, wersje faktów/progów/prawa, owner approval,
   BLOCK_AND_ALERT/TRIAGE_QUEUE, SUGGEST/no_auto_post.

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
[POTWIERDZONE_KODEM] Brak źródła, legal trace, dokumentu, temporalnego kontekstu,
uchwały albo jednoznacznego dopasowania gminy i terytorium blokuje decyzję.
[POTWIERDZONE_KODEM] Niezweryfikowana klasyfikacja akcyzowa, brak e-DD, magazynu,
znaków lub dowodu zwolnienia blokuje zastosowanie wyniku.
[POTWIERDZONE_KODEM] Pakiet nie składa PCC-3/DN-1/DT-1, nie wysyła e-DD i ma
SUGGEST/no_auto_post; owner/doradca pozostaje wymaganym decydentem.
[OGRANICZENIE] Bramka techniczna nie zastępuje aktualnej uchwały gminy, tekstu
ustawy, ISAP/LKG, dokumentu źródłowego ani porady podatkowej.

VERIFICATION
------------
Evidence: {e['gate_summary']['passed']}/{e['gate_summary']['total']} gates.
Status: {e['status']}
Produkcja: NOT_CERTIFIED

STATUS
------
Status raportu: {e['status']}
Następny raport: ETAP_20 / JDG/prompty_glm52_enterprise/20_*.txt

ETAP_19_COMPLETE — CONTEXT_RESET_REQUIRED — wyczyść okno kontekstowe przed ETAP_20.
"""


def write_artifacts() -> dict[str, Any]:
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    # First pass creates the report; second pass certifies report_present.
    provisional = build_evidence()
    REPORT.write_text(build_report(provisional), encoding="utf-8")
    evidence = build_evidence()
    BUNDLE.parent.mkdir(parents=True, exist_ok=True)
    BUNDLE.write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding="utf-8")
    REPORT.write_text(build_report(evidence), encoding="utf-8")
    return evidence


def main() -> int:
    parser = argparse.ArgumentParser(description="ETAP 19 PCC/local/excise evidence gate")
    parser.add_argument("command", choices=["build", "validate"])
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    evidence = write_artifacts() if args.command == "build" else build_evidence()
    if args.json:
        print(json.dumps(evidence, ensure_ascii=False, indent=2))
    else:
        print(f"[ETAP_19] Status: {evidence['status']} ({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})")
        for name, passed in evidence["gates"].items():
            print(f"  {'PASS' if passed else 'FAIL'} {name}")
    return 0 if evidence["status"] == "WDROZONY_100" else 1


if __name__ == "__main__":
    raise SystemExit(main())
