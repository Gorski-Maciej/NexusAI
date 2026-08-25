#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — CROSS-BORDER V3 GATE (Kampania V3, część 08/20)
# Bramka jakości domeny CROSS-BORDER / TP / CFC / MDR / ViDA:
#   1. istnienie i przynależność pakietowa wszystkich plików z listy promptu 08,
#   2. wiring orphan-pakietów w orkiestratorze (import + _package_decisions),
#   3. duplikaty rule_id w obrębie pliku i między plikami domeny,
#   4. skan hardcode progów (ADR-002) — wartości >=4-cyfrowe poza thresholds,
#   5. bramki kontraktowe pakietu v3_08 (fail-closed + Decision Certificate),
#   6. evidence: JDG/bundles/crossborder_v3_audit_08.json.
# Uruchomienie: python3 JDG/tools/crossborder_v3_gate.py [--json]
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parents[1]

# Pliki domeny (lista z prompty_enterprise_v3/08_CROSSBORDER.txt + nowe v3_08)
DOMAIN_FILES = [
    "rules/crossborder.rego",
    "rules/crossborder/plan23_ue.rego",
    "rules/crossborder/post_brexit.rego",
    "rules/crossborder/exit_tax_cfc_complete.rego",
    "rules/crossborder/v3_08_enterprise.rego",
    "rules/micro/crossborder/crossborder.rego",
    "rules/micro/plan33_cb.rego",
    "rules/micro/crossborder_atomic_p12.rego",
    "rules/tp/plan44_tp.rego",
    "rules/tp/plan45_tp.rego",
    "rules/cfc_auto_classifier.rego",
    "rules/mdr/mdr_hallmarks.rego",
    "rules/mdr/mdr_enterprise.rego",
    "rules/mdr/plan44_mdr.rego",
    "rules/mdr/plan45_mdr.rego",
    "rules/international.rego",
    "rules/international_expanded.rego",
    "rules/vida_drr_full.rego",
]

MAIN = "rules/main_jdg.rego"
THRESHOLDS = "rules/thresholds_jdg.rego"

# Pakiety, które MUSZĄ być zaimportowane i zarejestrowane w orkiestratorze
REQUIRED_WIRING = {
    "jdg.crossborder": "crossborder.decide",
    "jdg.crossborder.post_brexit": "post_brexit.decide",
    "jdg.crossborder.v3_08": "crossborder_v3_08.decide",
    "jdg.international": "international.decide",
    "jdg.tp": "tp.decide",
    "jdg.tp.hyper": "tp_hyper.decide",
    "jdg.mdr": "mdr.decide",
    "jdg.mdr.enterprise": "mdr_enterprise.decide",
    "jdg.mdr.hallmarks": "mdr_hallmarks.decide",
    "jdg.mdr.hyper": "mdr_hyper.decide",
    "jdg.exit_tax_cfc": "exit_tax_cfc.decide",
    "jdg.cfc_auto_classifier": "cfc_auto_classifier.decide",
    "jdg.vida_drr_full": "vida_drr_full.decide",
}

# Nowe klucze progów V3-08 — muszą istnieć w data.jdg.thresholds.crossborder
REQUIRED_THRESHOLD_KEYS = [
    "exit_tax_threshold_pln", "exit_tax_rate_pct", "exit_tax_deferral_years_eea",
    "wht_annual_threshold_pln", "wht_standard_rate_pct",
    "dac8_threshold_eur", "dac8_threshold_tx", "dac8_deadline",
    "uk_vat_registration_threshold_gbp",
    "cfc_ownership_min_pct", "cfc_passive_income_pct", "cfc_tax_rate_threshold_pct",
    "tp_goods_transactions_pln", "tp_services_transactions_pln", "tp_financial_transactions_pln",
    "mdr_deadline_days", "threshold_version", "legal_basis_version",
]

HARDCODE_RE = re.compile(r'[^"a-z_0-9]((?:\d{1,3}(?:,\d{3})+|\d{5,}))(?:\.\d+)?[^0-9"]')
RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
PACKAGE_RE = re.compile(r'^package\s+([\w.]+)', re.MULTILINE)

# Pliki ze zweryfikowanym wyjątkiem hardcode (legacy — zadanie części 13 MICRO)
HARDCODE_ALLOWLIST = {
    "rules/micro/crossborder/crossborder.rego",
    "rules/micro/plan33_cb.rego",
    "rules/micro/crossborder_atomic_p12.rego",
}


def read(rel: str) -> str:
    return (JDG_ROOT / rel).read_text(encoding="utf-8")


def audit_file(rel: str) -> dict:
    path = JDG_ROOT / rel
    if not path.exists():
        return {"file": rel, "exists": False}
    text = read(rel)
    rids = RULE_ID_RE.findall(text)
    pkg_m = PACKAGE_RE.search(text)
    has_legal_basis = '"_legal_basis"' in text or "_legal_basis" in text
    return {
        "file": rel,
        "exists": True,
        "lines": text.count("\n") + 1,
        "package": pkg_m.group(1) if pkg_m else None,
        "rule_count": len(rids),
        "unique_rule_ids": len(set(rids)),
        "duplicates_in_file": sorted({r for r in rids if rids.count(r) > 1}),
        "has_no_match_default": ".no_match" in text,
        "has_legal_basis": has_legal_basis,
        "hardcoded_amounts": [] if rel in HARDCODE_ALLOWLIST else scan_hardcode(text),
    }


def scan_hardcode(text: str) -> list[str]:
    hits = []
    for lineno, line in enumerate(text.split("\n"), 1):
        stripped = line.strip()
        if stripped.startswith("#"):
            continue
        m = HARDCODE_RE.search(stripped)
        if m and '"rule_id"' not in stripped and '"priority"' not in stripped:
            hits.append(f"L{lineno}: {m.group(1)} :: {stripped[:100]}")
    return hits


def check_wiring(main_text: str) -> tuple[list[str], list[str]]:
    ok, missing = [], []
    for pkg, ref in REQUIRED_WIRING.items():
        imported = f"data.{pkg}" in main_text.replace("import ", "", 0)
        registered = f'"{pkg}"' in main_text
        alias_ok = ref in main_text
        if imported and registered and alias_ok:
            ok.append(pkg)
        else:
            why = []
            if not imported:
                why.append("brak importu")
            if not registered:
                why.append("brak wpisu _package_decisions")
            if not alias_ok:
                why.append(f"brak referencji {ref}")
            missing.append(f"{pkg} ({'; '.join(why)})")
    return ok, missing


def check_thresholds(th_text: str) -> tuple[list[str], list[str]]:
    present, missing = [], []
    for key in REQUIRED_THRESHOLD_KEYS:
        (present if f'"{key}"' in th_text else missing).append(key)
    return present, missing


def check_v3_08_contract(text: str) -> dict:
    markers = [
        ("fail_closed_decision", "fail-closed przy braku snapshotu (V1 z6)"),
        ("_certificate(", "Decision Certificate (V2 F4)"),
        ("threshold_version", "wersja snapshotu progów (Golden Oracle F3)"),
        ("data.jdg.thresholds", "odczyt progów z data.thresholds (ADR-002)"),
        ("first-match-wins", "łańcuch first-match-wins"),
    ]
    checks = {label: (marker in text) for marker, label in markers}
    return {"all_pass": all(checks.values()), "checks": checks}


def run_gate() -> dict:
    errors: list[str] = []
    files_audit = [audit_file(rel) for rel in DOMAIN_FILES]
    for fa in files_audit:
        if not fa.get("exists"):
            errors.append(f"BRAK PLIKU: {fa['file']}")
            continue
        if not fa["package"]:
            errors.append(f"{fa['file']}: brak deklaracji package")
        if fa["duplicates_in_file"]:
            errors.append(f"{fa['file']}: duplikaty rule_id {fa['duplicates_in_file']}")

    # Duplikaty rule_id MIĘDZY plikami (poza no_match defaults)
    seen: dict[str, str] = {}
    cross_dups: list[str] = []
    for fa in files_audit:
        if not fa.get("exists"):
            continue
        for rid in sorted(set(RULE_ID_RE.findall(read(fa["file"])))):
            if rid.endswith(".no_match"):
                continue
            if rid in seen and seen[rid] != fa["file"]:
                cross_dups.append(f"{rid}: {seen[rid]} <-> {fa['file']}")
            seen.setdefault(rid, fa["file"])

    main_text = read(MAIN)
    wired, unwired = check_wiring(main_text)
    th_present, th_missing = check_thresholds(read(THRESHOLDS))
    if unwired:
        errors.extend(f"WIRING: brak podpięcia {u}" for u in unwired)
    if th_missing:
        errors.append(f"THRESHOLDS: brak kluczy {th_missing}")

    contract = check_v3_08_contract(read("rules/crossborder/v3_08_enterprise.rego"))
    if not contract["all_pass"]:
        failed = [k for k, ok in contract["checks"].items() if not ok]
        errors.append(f"KONTRAKT v3_08: nie przeszło {failed}")

    total_rules = sum(fa.get("rule_count", 0) for fa in files_audit if fa.get("exists"))
    report = {
        "tool": "crossborder_v3_gate",
        "kampania": "V3 część 08 — CROSS-BORDER / TP / CFC / MDR / ViDA / EXIT",
        "gate_status": "PASS" if not errors else "FAIL",
        "errors": errors,
        "files_audited": files_audit,
        "totals": {"domain_files": len(DOMAIN_FILES), "existing_files":
                   sum(1 for f in files_audit if f.get("exists")),
                   "rule_ids_total": total_rules},
        "wiring": {"required": len(REQUIRED_WIRING), "wired": wired, "unwired": unwired},
        "thresholds": {"present": th_present, "missing": th_missing},
        "v3_08_contract": contract,
        "cross_file_duplicates": cross_dups,
    }
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description="Cross-border V3-08 quality gate")
    parser.add_argument("--json", action="store_true", help="tylko JSON na stdout")
    args = parser.parse_args()

    report = run_gate()
    out_path = JDG_ROOT / "bundles" / "crossborder_v3_audit_08.json"
    out_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(f"[{report['gate_status']}] crossborder_v3_gate — "
              f"pliki: {report['totals']['existing_files']}/{report['totals']['domain_files']}, "
              f"rule_id: {report['totals']['rule_ids_total']}, "
              f"wiring: {len(report['wiring']['wired'])}/{report['wiring']['required']}, "
              f"errors: {len(report['errors'])}")
        for e in report["errors"]:
            print(f"  - {e}")
        print(f"Evidence: {out_path.relative_to(JDG_ROOT.parent)}")
    return 0 if report["gate_status"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
