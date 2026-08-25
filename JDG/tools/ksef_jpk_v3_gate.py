#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — KSEF + JPK + E-DORĘCZENIA V3 GATE (Kampania V3, część 11/20)
#   1. istnienie i przynależność pakietowa plików z listy promptu 11 (+ v3_11),
#   2. wiring 20 pakietów domeny w orkiestratorze,
#   3. duplikaty rule_id w obrębie pliku i między plikami domeny,
#   4. skan hardcode progów (ADR-002) — poza allowlist micro/legacy (część 13),
#   5. kontrakt pakietu v3_11 (fail-closed + Decision Certificate + thresholds),
#   6. evidence: JDG/bundles/ksef_jpk_v3_audit_11.json.
# Uruchomienie: python3 JDG/tools/ksef_jpk_v3_gate.py [--json]
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parents[1]

DOMAIN_FILES = [
    # KSeF (prompt 11, ★)
    "rules/ksef_innovations_enterprise.rego",
    "rules/ksef_outbox_enterprise.rego",
    "rules/ksef_offline_queue_enterprise.rego",
    "rules/ksef_sandbox_harness_enterprise.rego",
    "rules/ksef_upo_tracker_enterprise.rego",
    "rules/ksef_receipt_digest_enterprise.rego",
    "rules/ksef_sanction_monitor_enterprise.rego",
    # JPK
    "rules/jpk_v7_autogen_enterprise.rego",
    "rules/jpk_corrections_workflow_enterprise.rego",
    "rules/jpk_kr_st_generator_enterprise.rego",
    "rules/jpk_cit.rego",
    "rules/micro/jpk/jpk.rego",
    "rules/micro/plan33_jpk.rego",
    # E-deklaracje i doręczenia
    "rules/edelivery_gateway_enterprise.rego",
    "rules/edelivery_gateway_v2_enterprise.rego",
    "rules/epuap_enterprise.rego",
    "rules/esig_auto_applicator_enterprise.rego",
    "rules/wis_autorequester_enterprise.rego",
    "rules/wis_api_enterprise.rego",
    # Nowy pakiet kampanii V3
    "rules/ksef_jpk/v3_11_enterprise.rego",
]

MAIN = "rules/main_jdg.rego"
THRESHOLDS = "rules/thresholds_jdg.rego"

REQUIRED_WIRING = {
    "jdg.ksef_innovations": "ksef_innov.decide",
    "jdg.ksef_outbox": "ksef_outbox.decide",
    "jdg.ksef_offline_queue": "ksef_offq.decide",
    "jdg.ksef_sandbox": "ksef_sandbox.decide",
    "jdg.ksef_upo_tracker": "ksef_upo.decide",
    "jdg.ksef_receipt_digest": "ksef_digest.decide",
    "jdg.ksef_sanction_monitor": "ksef_sanction.decide",
    "jdg.jpk_v7_autogen": "jpk_v7_autogen.decide",
    "jdg.jpk_corrections": "jpk_corrections.decide",
    "jdg.jpk_kr_st": "jpk_kr_st.decide",
    "jdg.jpk_cit": "jpk_cit.decide",
    "jdg.micro.jpk": "micro_jpk_full.decide",
    "jdg.micro.jpk.plan33": "micro_jpk_plan33.decide",
    "jdg.edelivery_gateway": "edelivery_gw.decide",
    "jdg.enterprise.edelivery_gateway": "edelivery_gw2.decide",
    "jdg.epuap": "epuap.decide",
    "jdg.esig_auto": "esig_auto.decide",
    "jdg.enterprise.wis_autorequester": "wis_auto.decide",
    "jdg.wis_api": "wis_api.decide",
    "jdg.ksef_jpk.v3_11": "ksef_jpk_v3_11.decide",
}

REQUIRED_THRESHOLD_KEYS = [
    "threshold_version", "legal_basis_version",
    "ksef_mandatory_from", "ksef_offline_grace_days", "ksef_sanction_max_pln",
    "ksef_sanction_70_cap_pln", "ksef_sanction_50_cap_pln",
    "ksef_zaw_nr_penalty_pln", "ksef_queue_warning_hours",
    "ksef_outbox_priority_threshold_pln", "ksef_upo_deadline_days",
    "jpk_v7_deadline_day", "jpk_ksef_penalty_per_invoice",
    "jpk_kr_discrepancy_alert_pln",
    "wis_application_fee_pln", "wis_expiry_warning_days", "wis_expiry_critical_days",
    "edelivery_mandatory_from", "wis_response_days", "ksef_sandbox",
]

HARDCODE_RE = re.compile(r'[^"a-z_0-9]((?:\d{1,3}(?:,\d{3})+|\d{5,}))(?:\.\d+)?[^0-9"]')
RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
PACKAGE_RE = re.compile(r'^package\s+([\w.]+)', re.MULTILINE)

# Allowlist hardcode: pliki micro + enterprise LEGACY — eksternalizacja progów
# to zadanie części 13 (MICRO)/16 (narzędzia); wartości prawnych NIE zmieniamy
# bez zatwierdzenia właściciela domeny.
HARDCODE_ALLOWLIST = {
    "rules/micro/jpk/jpk.rego",
    "rules/micro/plan33_jpk.rego",
    "rules/ksef_innovations_enterprise.rego",
    "rules/ksef_outbox_enterprise.rego",
    "rules/ksef_offline_queue_enterprise.rego",
    "rules/ksef_sandbox_harness_enterprise.rego",
    "rules/ksef_upo_tracker_enterprise.rego",
    "rules/ksef_receipt_digest_enterprise.rego",
    "rules/ksef_sanction_monitor_enterprise.rego",
    "rules/jpk_v7_autogen_enterprise.rego",
    "rules/jpk_corrections_workflow_enterprise.rego",
    "rules/jpk_kr_st_generator_enterprise.rego",
    "rules/edelivery_gateway_enterprise.rego",
    "rules/edelivery_gateway_v2_enterprise.rego",
    "rules/esig_auto_applicator_enterprise.rego",
    "rules/wis_autorequester_enterprise.rego",
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
        # Odczyt z thresholds z inline-fallbackiem jest zgodny z ADR-002.
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


def check_v3_11_contract(text: str) -> dict:
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

    contract = check_v3_11_contract(read("rules/ksef_jpk/v3_11_enterprise.rego"))
    if not contract["all_pass"]:
        failed = [k for k, passed in contract["checks"].items() if not passed]
        errors.append(f"KONTRAKT v3_11: nie przeszło {failed}")

    total_rules = sum(fa.get("rule_count", 0) for fa in files_audit if fa.get("exists"))
    return {
        "tool": "ksef_jpk_v3_gate",
        "kampania": "V3 część 11 — KSEF + BIAŁA LISTA + E-DORĘCZENIA + ePUAP + WIS + ESIG",
        "gate_status": "PASS" if not errors else "FAIL",
        "errors": errors,
        "files_audited": files_audit,
        "totals": {"domain_files": len(DOMAIN_FILES),
                   "existing_files": sum(1 for f in files_audit if f.get("exists")),
                   "rule_ids_total": total_rules},
        "wiring": {"required": len(REQUIRED_WIRING), "wired": wired, "unwired": unwired},
        "thresholds": {"present": th_present, "missing": th_missing},
        "v3_11_contract": contract,
        "cross_file_duplicates": cross_dups,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="KSeF/JPK/e-Doręczenia V3-11 quality gate")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = run_gate()
    out_path = JDG_ROOT / "bundles" / "ksef_jpk_v3_audit_11.json"
    out_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(f"[{report['gate_status']}] ksef_jpk_v3_gate — "
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
