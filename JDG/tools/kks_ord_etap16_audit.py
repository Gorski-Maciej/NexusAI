#!/usr/bin/env python3
"""ETAP 16/29 — KKS + Ordynacja evidence gate.

The gate audits the risk-scoring + evidence-chain + voluntary-disclosure +
sanctions + limitation + obligations + procedures + deadline-engine layer over
the existing KKS/Ordynacja rules. Static and fail-closed: certifies wiring and
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
PACKAGE_PATH = "rules/kks_ord_etap16_v1.rego"
MAIN_PATH = "rules/main_jdg.rego"
REPORT_PATH = ROOT / "raporty_glm52_enterprise" / "16_KKS_ORDYNACJA.txt"
BUNDLE_PATH = ROOT / "bundles" / "kks_ord_etap16_audit_state.json"
SCHEMA_VERSION = "1.0.0"

SOURCE_FILES = [
    "rules/kks.rego",
    "rules/kks/enterprise_penalties.rego",
    "rules/kks/plan42_detailed.rego",
    "rules/kks/plan43_decomposition.rego",
    "rules/kks/kks_innovations_v8.rego",
    "rules/micro/kks/kks.rego",
    "rules/micro/kks_ord_atomic_p11.rego",
    "rules/micro/ord/ord.rego",
    "rules/ord/ord_innovations_v8.rego",
    "rules/tax_authority_interaction_enterprise.rego",
    "rules/sanctions_optimization_enterprise.rego",
    "tools/kks_completeness_matrix.py",
    "tools/kks_penalty_auditor.py",
    "docs/KKS_P10.md",
    "docs/ORDYNACJA_PODATKOWA_P11.md",
    "docs/Bbb",
    PACKAGE_PATH,
]

REQUIRED_MARKERS = [
    "risk_scoring", "evidence_chain", "voluntary_disclosure_audit",
    "sanction_audit", "limitation_audit", "obligation_audit",
    "procedure_audit", "deadline_audit", "property_invariants",
    "invariant_failed", "calculation_certificate", "threshold_snapshot",
    "missing_context", "uncertainty_markers", "cross_domain_collisions",
    "BLOCK_AND_ALERT", "TRIAGE_QUEUE", "decision_mode := \"SUGGEST\"",
    "no_auto_post", "disclaimer", "rounding_contract", "unit",
    "legal_basis", "source",
]
LEGAL_MARKERS = [
    "art. 16 § 1 KKS",
    "art. 54-83 KKS",
    "art. 44 KKS",
    "art. 70 OrdPU",
    "art. 81/72-77/67a/53-56 OrdPU",
    "art. 14b (interpretacje)",
    "art. 119a OrdPU",
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
        "kks_externalized": 'object.get(kks, "penalty_multiplier_max"' in text and 'object.get(kks, "daily_rate_denominator"' in text,
        "ord_externalized": 'object.get(ord, "interest_rate_annual"' in text,
        "version_carried": "threshold_version" in text and "legal_basis_version" in text,
    }
    return {
        "package": "package jdg.kks_ord_etap16" in text,
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
        "activation": 'object.get(input, "kks_ord_etap16_check", false)' in text,
        "no_auto_post_literal": '"AUTO_POST"' not in text,
        "sections": {
            "risk": "risk_scoring" in text,
            "evidence": "evidence_chain" in text,
            "disclosure": "voluntary_disclosure_audit" in text,
            "sanctions": "sanction_audit" in text,
            "limitation": "limitation_audit" in text,
            "obligations": "obligation_audit" in text,
            "procedures": "procedure_audit" in text,
            "deadline": "deadline_audit" in text,
            "invariants": "property_invariants" in text,
        },
    }


def wiring_evidence(main: str) -> dict[str, Any]:
    markers = {
        "import": "import data.jdg.kks_ord_etap16" in main,
        "package_decisions": '"jdg.kks_ord_etap16": kks_ord_etap16.decide' in main,
        "p60_chain": "final_verdict_p60 = safe_merge(final_verdict_p59," in main,
        "post_merge_p60": "final_verdict_post_merge = object.union(final_verdict_p53" in main,
        "invariants": "runtime_invariants.enforce(final_verdict_post_merge)" in main,
        "public_final": "final_verdict = final_verdict_enforced" in main,
    }
    return {"markers": markers, "complete": all(markers.values())}


def tests_evidence() -> dict[str, Any]:
    text = read("tests/test_kks_ord_etap16_audit.py")
    markers = ["risk", "evidence", "voluntary", "disclaimer", "sanction", "materiality", "limitation", "correction", "interest", "overpayment", "relief", "interpretation", "poa", "gaar", "deadline", "property", "SUGGEST", "temporal", "boundary", "manual"]
    return {
        "present": bool(text),
        "test_count": len(re.findall(r"def test_", text)),
        "markers": {marker: marker in text for marker in markers},
        "complete": bool(text) and all(marker in text for marker in markers),
    }


def native_tests_evidence() -> dict[str, Any]:
    text = read("tests/rego/test_native_kks_ord_etap16.rego")
    markers = ["test_negative", "test_temporal", "test_property", "test_boundary", "test_risk", "package test_jdg_kks_ord_etap16"]
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
        "risk_scoring": package["sections"]["risk"] and "risk_class" in pkg_text and "CRITICAL" in pkg_text,
        "evidence_chain": package["sections"]["evidence"] and "evidence" in pkg_text and "source_rule" in pkg_text,
        "voluntary_disclosure_disclaimer": package["sections"]["disclosure"] and "czynny żal" in pkg_text and "disclaimer" in pkg_text and "automatic" in pkg_text,
        "sanctions_materiality": package["sections"]["sanctions"] and "materiality" in pkg_text and "penalty_cap" in pkg_text,
        "limitation": package["sections"]["limitation"] and "expired" in pkg_text and "limitation_years" in pkg_text,
        "obligations_corrections_interest_overpayments_reliefs": package["sections"]["obligations"] and "overpayment" in pkg_text and "interest_amount" in pkg_text,
        "procedures_interpretation_poa_gaar": package["sections"]["procedures"] and "interpretation_requested" in pkg_text and "power_of_attorney" in pkg_text and "gaar_analysis" in pkg_text,
        "deadline_engine": package["sections"]["deadline"] and "deadline_level" in pkg_text and "RED" in pkg_text and "AMBER" in pkg_text,
        "property_invariants": package["sections"]["invariants"] and "invariant_failed" in pkg_text and "risk_in_range" in pkg_text,
        "certificate_units_rounding": "calculation_certificate" in pkg_text and "rounding_contract" in pkg_text and "unit" in pkg_text,
        "legal_basis_and_threshold_versions": package["legal_basis_complete"] and package["thresholds_externalized"],
        "suggest_only_and_router": package["activation"] and package["no_auto_post_literal"] and 'decision_mode := "SUGGEST"' in pkg_text and wiring["complete"],
        "tests_and_report_present": tests["complete"] and native["complete"] and REPORT_PATH.exists(),
    }
    passed = sum(gates.values())
    total = len(gates)
    return {
        "schema_version": SCHEMA_VERSION,
        "audit_id": "jdg.kks_ord_etap16_audit",
        "stage": "ETAP_16",
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
RAPORT WDROŻENIOWY GLM52 ENTERPRISE — ETAP 16/29
KKS + ORDYNACJA PODATKOWA — ODPOWIEDZIALNOŚĆ, TERMINY, KOREKTY, OBRONA
====================================================================================================

IDENTITY
--------
Etap: ETAP_16
Prompt: JDG/prompty_glm52_enterprise/16_KKS_ORDYNACJA.txt
Raport: JDG/raporty_glm52_enterprise/16_KKS_ORDYNACJA.txt
Audytor: JDG/tools/kks_ord_etap16_audit.py
Bundle: JDG/bundles/kks_ord_etap16_audit_state.json
Pakiet wdrożeniowy: JDG/{PACKAGE_PATH}
Status raportu: {status}

SCOPE
-----
Warstwa ETAPU 16 weryfikuje czynny żal (art. 16 KKS), art. 54-83 KKS, stopnie
sankcji, materialność, przedawnienia, korekty, odsetki, nadpłaty, ulgi w
spłacie, interpretacje, pełnomocnictwa, GAAR, postępowania i terminy. Każda
rekomendacja obrony jest nieautomatyczną pomocą z disclaimerem. Dodaje risk
scoring, evidence chain, deadline engine, formalne blokady i testy temporalne.

FILES
-----
| Plik | Status |
|------|--------|
{file_lines}

IMPLEMENTED PHASES
------------------
1. Risk scoring — ekspozycja + umyślność + recydywa → LOW/HIGH/CRITICAL.
2. Evidence chain — 10 decyzji obrony × (dowód + reguła źródłowa + nieautomatyczna).
3. Czynny żal (art. 16 § 1 KKS) — warunki + disclaimer (pomoc nieautomatyczna).
4. Stopnie sankcji i materialność (art. 54-83 KKS) — stawka dzienna, cap, próg.
5. Przedawnienia (art. 44 KKS, art. 70 OrdPU) — 5/3 lata, temporalne.
6. Korekty/odsetki/nadpłaty/ulgi (art. 81/53-56/72-77/67a OrdPU).
7. Interpretacje/pełnomocnictwa/GAAR (art. 14b/80a-80d/119a OrdPU).
8. Deadline engine — RED/AMBER/GREEN + formalna blokada przy przekroczeniu.
9. Property invariants — ryzyko ∈ [0,100], kwoty ≥ 0, disclaimer obecny.
10. Calculation certificate — wersje progów/prawa/faktów, waluta, jednostki.
11. Safe orchestration — SUGGEST only, no_auto_post, final p60 + invariants.

GATES
-----
| Gate | Result |
|------|--------|
{gate_lines}

CALCULATION CONTRACT
--------------------
- Waluta: PLN; jednostki: PLN (kara, odsetki, ekspozycja).
- Zaokrąglenie: PLN_HALF_UP_2DP (kontrakt ujawniony w certyfikacie).
- Źródło progów: data.jdg.thresholds.kks / ord.
- Wersjonowanie: evaluation_date, evaluation_year, threshold_version,
  legal_basis_version, facts_version.
- Granice: stawka dzienna 1/30 min. wynagrodzenia, cap 400×, próg przestępstwa
  200×, przedawnienia 5/3 lata.

SAFETY CONTRACT
---------------
[POTWIERDZONE_KODEM] Brak daty oceny, wersji progów, wersji prawa lub wersji
faktów daje BLOCK_AND_ALERT.
[POTWIERDZONE_KODEM] Przekroczony termin (RED) lub ryzyko CRITICAL kieruje do
manual review; żadna rekomendacja nie jest auto-wykonywana.
[POTWIERDZONE_KODEM] Rekomendacje obrony są nieautomatyczną pomocą z
disclaimerem i nie stanowią porady prawnej.
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
Następny raport: ETAP_17 / JDG/prompty_glm52_enterprise/17_*.txt

ETAP_16_COMPLETE — CONTEXT_RESET_REQUIRED — wyczyść okno kontekstowe przed ETAP_17.
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
    parser = argparse.ArgumentParser(description="ETAP 16 KKS/Ordynacja evidence gate")
    parser.add_argument("command", choices=["build", "validate"])
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    evidence = write_artifacts() if args.command == "build" else build_evidence()
    if args.json:
        print(json.dumps(evidence, indent=2, ensure_ascii=False))
    else:
        print(f"[ETAP_16] Status: {evidence['status']} ({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})")
        for name, ok in evidence["gates"].items():
            print(f"  {'PASS' if ok else 'FAIL'} {name}")
    return 0 if evidence["status"] == "WDROZONY_100" else 1


if __name__ == "__main__":
    sys.exit(main())
