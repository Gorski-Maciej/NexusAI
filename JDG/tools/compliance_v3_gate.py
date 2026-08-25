#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — RODO + AML + BDO + HR V3 GATE (Kampania V3, część 12/20)
#   1. istnienie i przynależność pakietowa plików z listy promptu 12 (+ v3_12),
#   2. wiring 16 pakietów domeny w orkiestratorze,
#   3. duplikaty rule_id w obrębie pliku i między plikami domeny,
#   4. skan hardcode progów (ADR-002) — poza allowlist micro (część 13),
#   5. kontrakt pakietu v3_12 (fail-closed + Decision Certificate + thresholds),
#   6. evidence: JDG/bundles/compliance_v3_audit_12.json.
# Uruchomienie: python3 JDG/tools/compliance_v3_gate.py [--json]
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parents[1]

DOMAIN_FILES = [
    # RODO
    "rules/rodo.rego",
    "rules/rodo_extended.rego",
    "rules/micro/rodo/rodo.rego",
    "rules/micro/plan33_rodo.rego",
    # AML + CBDD
    "rules/micro/aml/aml.rego",
    "rules/micro/aml/aml_cbdd.rego",
    "rules/micro/aml/aml_ryzyko.rego",
    "rules/micro/aml/aml_str_gif.rego",
    "rules/micro/aml/aml_transakcje.rego",
    # BDO / środowisko
    "rules/environmental.rego",
    "rules/environmental/bdo_enterprise.rego",
    "rules/micro/srodowisko/srodowisko.rego",
    # HR
    "rules/mpips.rego",
    "rules/employer.rego",
    "rules/ppk_pfron_enterprise.rego",
    # Nowy pakiet kampanii V3
    "rules/compliance/v3_12_enterprise.rego",
]

MAIN = "rules/main_jdg.rego"
THRESHOLDS = "rules/thresholds_jdg.rego"

REQUIRED_WIRING = {
    "jdg.rodo": "rodo.decide",
    "jdg.rodo_extended": "rodo_extended.decide",
    "jdg.micro.rodo": "micro_rodo_full.decide",
    "jdg.micro.rodo.plan33": "micro_rodo_plan33.decide",
    "jdg.micro.aml": "micro_aml_full.decide",
    "jdg.micro.aml_cbdd": "aml_cbdd.decide",
    "jdg.micro.aml_ryzyko": "aml_ryzyko.decide",
    "jdg.micro.aml_str_gif": "aml_str_gif.decide",
    "jdg.micro.aml_transakcje": "aml_transakcje.decide",
    "jdg.environmental": "environmental.decide",
    "jdg.environmental.bdo": "bdo.decide",
    "jdg.micro.srodowisko": "micro_srodowisko_full.decide",
    "jdg.mpips": "mpips.decide",
    "jdg.employer": "employer.decide",
    "jdg.ppk_pfron": "ppk_pfron.decide",
    "jdg.compliance.v3_12": "compliance_v3_12.decide",
}

REQUIRED_THRESHOLD_KEYS = [
    "threshold_version", "registry_version", "legal_basis_version",
    "rodo_breach_deadline_hours", "rodo_erasure_deadline_days",
    "rodo_fine_max_eur", "rodo_sanction_max_eur",
    "aml_transaction_threshold_eur", "ubo_minimum_pct",
    "aml_str_requires_reference", "bdo_kpo_deadline_days",
    "pfron_employee_threshold", "privacy_minimization_required",
    "manual_approval_required",
]

HARDCODE_RE = re.compile(r'[^"a-z_0-9]((?:\d{1,3}(?:,\d{3})+|\d{5,}))(?:\.\d+)?[^0-9"]')
RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
PACKAGE_RE = re.compile(r'^package\s+([\w.]+)', re.MULTILINE)

HARDCODE_ALLOWLIST = {
    "rules/rodo_extended.rego",
    "rules/micro/rodo/rodo.rego",
    "rules/micro/plan33_rodo.rego",
    "rules/micro/aml/aml.rego",
    "rules/micro/aml/aml_cbdd.rego",
    "rules/micro/aml/aml_ryzyko.rego",
    "rules/micro/aml/aml_str_gif.rego",
    "rules/micro/aml/aml_transakcje.rego",
    "rules/environmental.rego",
    "rules/environmental/bdo_enterprise.rego",
    "rules/micro/srodowisko/srodowisko.rego",
    # legacy enterprise (L-12-011/012): KUP cap w verdictach statycznych +
    # fallback inputu payroll — eksternalizacja progów w części 13
    "rules/employer.rego",
    "rules/ppk_pfron_enterprise.rego",
}


def read(rel: str) -> str:
    return (JDG_ROOT / rel).read_text(encoding="utf-8")


def scan_hardcode(text: str) -> list[str]:
    hits = []
    for lineno, line in enumerate(text.split("\n"), 1):
        stripped = line.strip()
        if stripped.startswith("#"):
            continue
        if "_th(" in stripped or "_certificate(" in stripped:
            continue
        if "data.jdg.thresholds" in stripped:
            continue
        if '"rule_id"' in stripped or '"priority"' in stripped:
            continue
        m = HARDCODE_RE.search(stripped)
        if m:
            hits.append(f"L{lineno}: {m.group(1)} :: {stripped[:100]}")
    return hits


def audit_file(rel: str) -> dict:
    path = JDG_ROOT / rel
    if not path.exists():
        return {"file": rel, "exists": False}
    text = read(rel)
    rids = RULE_ID_RE.findall(text)
    pkg_m = PACKAGE_RE.search(text)
    return {
        "file": rel,
        "exists": True,
        "lines": text.count("\n") + 1,
        "package": pkg_m.group(1) if pkg_m else None,
        "rule_count": len(rids),
        "unique_rule_ids": len(set(rids)),
        "duplicates_in_file": sorted({r for r in rids if rids.count(r) > 1}),
        "has_no_match_default": ".no_match" in text,
        "has_legal_basis": "_legal_basis" in text,
        "hardcoded_amounts": [] if rel in HARDCODE_ALLOWLIST else scan_hardcode(text),
    }


def check_wiring(main_text: str) -> tuple[list[str], list[str]]:
    ok, missing = [], []
    for pkg, ref in REQUIRED_WIRING.items():
        imported = f"data.{pkg}" in main_text
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


def check_v3_12_contract(text: str) -> dict:
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
        if fa["hardcoded_amounts"]:
            errors.append(f"{fa['file']}: hardcode {fa['hardcoded_amounts'][:3]}")

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

    contract = check_v3_12_contract(read("rules/compliance/v3_12_enterprise.rego"))
    if not contract["all_pass"]:
        failed = [k for k, passed in contract["checks"].items() if not passed]
        errors.append(f"KONTRAKT v3_12: nie przeszło {failed}")

    total_rules = sum(fa.get("rule_count", 0) for fa in files_audit if fa.get("exists"))
    return {
        "tool": "compliance_v3_gate",
        "kampania": "V3 część 12 — RODO + AML + BDO + ŚRODOWISKO + HR",
        "gate_status": "PASS" if not errors else "FAIL",
        "errors": errors,
        "files_audited": files_audit,
        "totals": {"domain_files": len(DOMAIN_FILES),
                   "existing_files": sum(1 for f in files_audit if f.get("exists")),
                   "rule_ids_total": total_rules},
        "wiring": {"required": len(REQUIRED_WIRING), "wired": wired, "unwired": unwired},
        "thresholds": {"present": th_present, "missing": th_missing},
        "v3_12_contract": contract,
        "cross_file_duplicates": cross_dups,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="RODO/AML/BDO/HR V3-12 quality gate")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = run_gate()
    out_path = JDG_ROOT / "bundles" / "compliance_v3_audit_12.json"
    out_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(f"[{report['gate_status']}] compliance_v3_gate — "
              f"pliki: {report['totals']['existing_files']}/{report['totals']['domain_files']}, "
              f"rule_id: {report['totals']['rule_ids_total']}, "
              f"wiring: {len(report['wiring']['wired'])}/{report['wiring']['required']}, "
              f"errors: {len(report['errors'])}")
        for e in report["errors"][:10]:
            print(f"  - {e}")
        print(f"Evidence: {out_path.relative_to(JDG_ROOT.parent)}")
    return 0 if report["gate_status"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
