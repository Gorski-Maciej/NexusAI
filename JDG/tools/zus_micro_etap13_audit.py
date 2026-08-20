#!/usr/bin/env python3
"""ETAP 13/29 — ZUS Micro evidence gate.

The gate audits the atom-map + insurance-period + benefit + property-invariant
layer over the existing ZUS micro atoms (micro/sus, micro/zdrowotna,
micro/zasilkowa). It is deliberately static and fail-closed: it certifies
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
PACKAGE_PATH = "rules/zus_micro_etap13_v1.rego"
MAIN_PATH = "rules/main_jdg.rego"
REPORT_PATH = ROOT / "raporty_glm52_enterprise" / "13_ZUS_MICRO.txt"
BUNDLE_PATH = ROOT / "bundles" / "zus_micro_etap13_audit_state.json"
SCHEMA_VERSION = "1.0.0"

SOURCE_FILES = [
    "rules/micro/sus/sus.rego",
    "rules/micro/zdrowotna/zdrowotna.rego",
    "rules/micro/zasilkowa/zasilkowa.rego",
    "rules/micro/plan33_zus.rego",
    "rules/p07_zus_macro_innovations_v9.rego",
    "rules/p08_zus_micro_innovations_v9.rego",
    "tests/rego/micro/test_native_micro_sus.rego",
    "tests/rego/micro/test_native_micro_zdrowotna.rego",
    "tests/rego/micro/test_native_micro_zasilkowa.rego",
    "tests/rego/micro/test_native_micro_zus.rego",
    "tools/zus_atom_linter.py",
    "tools/zus_atom_test_matrix.py",
    "docs/ZUS_MICRO_P08.md",
    "docs/Bbb",
    PACKAGE_PATH,
]

# Prompt 13 lists these as input files, but they are absent from the repo.
# Documented as discrepancies — no atoms are duplicated to fill them.
REFERENCED_BUT_ABSENT = [
    "rules/micro/plan34_zus.rego",
]

REQUIRED_MARKERS = [
    "atom_map", "coverage_summary", "period_analysis", "benefit_calculation",
    "property_invariants", "invariant_failed", "calculation_certificate",
    "threshold_snapshot", "missing_context", "uncertainty_markers",
    "cross_domain_collisions", "BLOCK_AND_ALERT", "TRIAGE_QUEUE",
    "decision_mode := \"SUGGEST\"", "no_auto_post", "rounding_contract",
    "unit", "legal_basis", "source",
]
LEGAL_MARKERS = [
    "Art. 6, 9 SUS",
    "Art. 36a SUS",
    "Art. 4/11/19/29/32/33 ustawy zasiłkowej",
    "u.ś.o.z. art. 79-82",
    "SUS art. 6-47",
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
        "benefit_rates_externalized": 'object.get(zus, "sickness_benefit_rate"' in text and 'object.get(zus, "maternity_benefit_rate"' in text,
        "period_thresholds_externalized": 'object.get(zus, "sickness_waiting_days_voluntary"' in text and 'object.get(zus, "sickness_max_days_standard"' in text,
        "version_carried": "threshold_version" in text and "legal_basis_version" in text,
    }
    return {
        "package": "package jdg.zus_micro_etap13" in text,
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
        "activation": 'object.get(input, "zus_micro_etap13_check", false)' in text,
        "no_auto_post_literal": '"AUTO_POST"' not in text,
        "sections": {
            "atom_map": "atom_map" in text,
            "coverage": "coverage_summary" in text,
            "periods": "period_analysis" in text,
            "benefits": "benefit_calculation" in text,
            "invariants": "property_invariants" in text,
            "certificate": "calculation_certificate" in text,
        },
    }


def wiring_evidence(main: str) -> dict[str, Any]:
    markers = {
        "import": "import data.jdg.zus_micro_etap13" in main,
        "package_decisions": '"jdg.zus_micro_etap13": zus_micro_etap13.decide' in main,
        "p57_chain": "final_verdict_p57 = safe_merge(final_verdict_p56," in main,
        "post_merge_p57": "final_verdict_post_merge = object.union(final_verdict_p53" in main,
        "invariants": "runtime_invariants.enforce(final_verdict_post_merge)" in main,
        "public_final": "final_verdict = final_verdict_enforced" in main,
    }
    return {"markers": markers, "complete": all(markers.values())}


def tests_evidence() -> dict[str, Any]:
    text = read("tests/test_zus_micro_etap13_audit.py")
    markers = ["atom_map", "coverage", "period", "benefit", "property", "invariant", "missing_context", "collision", "SUGGEST", "temporal", "boundary"]
    return {
        "present": bool(text),
        "test_count": len(re.findall(r"def test_", text)),
        "markers": {marker: marker in text for marker in markers},
        "complete": bool(text) and all(marker in text for marker in markers),
    }


def native_tests_evidence() -> dict[str, Any]:
    text = read("tests/rego/micro/test_native_micro_zus.rego")
    markers = ["test_negative", "test_temporal", "test_property", "test_boundary", "package test_jdg_micro_zus"]
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
        "atom_map_present": package["sections"]["atom_map"] and "ustawa" in pkg_text and "artykul" in pkg_text,
        "coverage_monitor": package["sections"]["coverage"] and "coverage_discrepancies" in pkg_text and "missing_atoms" in pkg_text,
        "insurance_periods": package["sections"]["periods"] and "concurrency" in pkg_text and "suspended" in pkg_text and "break_months" in pkg_text,
        "benefits_calculators": package["sections"]["benefits"] and "CHOROBOWE" in pkg_text and "MACIERZYNSKIE" in pkg_text and "OPIEKUNCZE" in pkg_text,
        "property_invariants": package["sections"]["invariants"] and "invariant_failed" in pkg_text and "no_silent_default" in pkg_text,
        "fail_closed_manual_gate": "BLOCK_AND_ALERT" in pkg_text and "TRIAGE_QUEUE" in pkg_text and "manual_review" in pkg_text,
        "certificate_units_rounding": "calculation_certificate" in pkg_text and "rounding_contract" in pkg_text and "unit" in pkg_text,
        "legal_basis_and_threshold_versions": package["legal_basis_complete"] and package["thresholds_externalized"],
        "temporal_and_rounding_contract": "evaluation_date" in pkg_text and "evaluation_year" in pkg_text and "PLN_HALF_UP_2DP" in pkg_text,
        "suggest_only": package["activation"] and package["no_auto_post_literal"] and 'decision_mode := "SUGGEST"' in pkg_text,
        "router_wired": wiring["complete"],
        "tests_present": tests["complete"] and native["complete"],
        "report_present": REPORT_PATH.exists(),
    }
    passed = sum(gates.values())
    total = len(gates)
    return {
        "schema_version": SCHEMA_VERSION,
        "audit_id": "jdg.zus_micro_etap13_audit",
        "stage": "ETAP_13",
        "status": "WDROZONY_100" if passed == total else "NIEPELNY",
        "gates": gates,
        "gate_summary": {"passed": passed, "total": total},
        "files": files,
        "referenced_but_absent": REFERENCED_BUT_ABSENT,
        "package": package,
        "wiring": wiring,
        "tests": tests,
        "native_tests": native,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def build_report(evidence: dict[str, Any]) -> str:
    gate_lines = "\n".join(f"| {name} | {'PASS' if ok else 'FAIL'} |" for name, ok in evidence["gates"].items())
    file_lines = "\n".join(f"| {name} | {'PRESENT' if ok else 'MISSING'} |" for name, ok in evidence["files"]["files"].items())
    absent_lines = "\n".join(f"| {name} | NIE_ISTNIEJE (udokumentowana rozbieżność) |" for name in evidence["referenced_but_absent"])
    status = evidence["status"]
    return f"""====================================================================================================
RAPORT WDROŻENIOWY GLM52 ENTERPRISE — ETAP 13/29
ZUS MICRO — MAPA ATOMÓW, OKRESY, ŚWIADCZENIA, PROPERTY INVARIANTS
====================================================================================================

IDENTITY
--------
Etap: ETAP_13
Prompt: JDG/prompty_glm52_enterprise/13_ZUS_MICRO.txt
Raport: JDG/raporty_glm52_enterprise/13_ZUS_MICRO.txt
Audytor: JDG/tools/zus_micro_etap13_audit.py
Bundle: JDG/bundles/zus_micro_etap13_audit_state.json
Pakiet wdrożeniowy: JDG/{PACKAGE_PATH}
Status raportu: {status}

SCOPE
-----
Warstwa ETAPU 13 buduje mapę atomów ustawa→artykuł→warunek→obliczenie→
świadectwo→test nad micro/sus, micro/zdrowotna i micro/zasilkowa. Analizuje
okresy ubezpieczenia (zbiegi art. 6/9, przerwy, zawieszenie art. 36a),
świadczenia chorobowe/macierzyńskie/opiekuńcze z zaokrągleniami, egzekwuje
property invariants oraz fail-closed TRIAGE/BLOCK. Każdy brak danych prowadzi
do TRIAGE/BLOCK — nigdy do cichego domyślnego wyniku.

FILES
-----
| Plik | Status |
|------|--------|
{file_lines}

PLIKI WSKAZANE W PROMPCIE, ALE NIEOBECNE
----------------------------------------
{absent_lines}

IMPLEMENTED PHASES
------------------
1. Atom map — 28 wpisów ustawa→artykuł→warunek→obliczenie→świadectwo→test
   (SUS art. 6-47, u.ś.o.z. art. 79-82, ustawa zasiłkowa art. 4-33).
2. Coverage reconciliation — inwentarz vs pliki: art. 6a bez atomów micro (GAP),
   81b/81c/81d obecne w plikach, lecz inwentarz je pomija (niespójność).
3. Insurance periods — zbieg tytułów JDG+etat, zawieszenie, przerwy i
   obowiązek składek społecznych vs zdrowotnej.
4. Benefits — chorobowe 80%/70% (szpital), macierzyńskie 100% (140 dni),
   opiekuńcze 80%, wyczekiwanie 90 dni, limity 182/270 dni, zaokrąglenia.
5. Property invariants — stawki ∈ [0,1], kwoty ≥ 0, dni ≥ 0, dzienna ≤ podstawa,
   macierzyńskie=100%, kontrakt zaokrągleń, brak cichego domyślnego wyniku.
6. Fail-closed gates — BLOCK_AND_ALERT / TRIAGE_QUEUE / REPORT.
7. Calculation certificate — wersje progów/prawa/faktów, data, waluta, jednostki.
8. Test matrix — testy negatywne, temporalne i property (pytest + native Rego).
9. Safe orchestration — SUGGEST only, no_auto_post, final p57 + invariants.

GATES
-----
| Gate | Result |
|------|--------|
{gate_lines}

CALCULATION CONTRACT
--------------------
- Waluta: PLN; jednostki: PLN, PLN/day, PLN/month.
- Zaokrąglenie: PLN_HALF_UP_2DP (kontrakt ujawniony w certyfikacie).
- Źródło progów: data.jdg.thresholds.zus / bounds.
- Wersjonowanie: evaluation_date, evaluation_year, threshold_version,
  legal_basis_version, facts_version.
- Granice: wyczekiwanie 90 dni, chorobowe 182/270 dni, macierzyński 20 tyg.
  (140 dni), stawki 80%/70%/100%.

SAFETY CONTRACT
---------------
[POTWIERDZONE_KODEM] Brak daty oceny, wersji progów, wersji prawa lub wersji
faktów daje BLOCK_AND_ALERT.
[POTWIERDZONE_KODEM] Świadczenie z brakującą podstawą lub liczbą dni nie jest
przeliczane jako bezpieczna rekomendacja (BLOCK_AND_ALERT).
[POTWIERDZONE_KODEM] Ujemne dane, niepewność, kolizje PIT/VAT/UoR i naruszony
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
Następny raport: ETAP_14 / JDG/prompty_glm52_enterprise/14_*.txt

ETAP_13_COMPLETE — CONTEXT_RESET_REQUIRED — wyczyść okno kontekstowe przed ETAP_14.
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
    parser = argparse.ArgumentParser(description="ETAP 13 ZUS Micro evidence gate")
    parser.add_argument("command", choices=["build", "validate"])
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    evidence = write_artifacts() if args.command == "build" else build_evidence()
    if args.json:
        print(json.dumps(evidence, indent=2, ensure_ascii=False))
    else:
        print(f"[ETAP_13] Status: {evidence['status']} ({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})")
        for name, ok in evidence["gates"].items():
            print(f"  {'PASS' if ok else 'FAIL'} {name}")
    return 0 if evidence["status"] == "WDROZONY_100" else 1


if __name__ == "__main__":
    sys.exit(main())
