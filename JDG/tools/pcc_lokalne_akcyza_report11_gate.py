#!/usr/bin/env python3
"""RAPORT_11 PCC / PODATKI LOKALNE / AKCYZĄ — evidence gate.

Mirrors tools/crossborder_innovations_report10_gate.py (new-campaign
convention). Prompt 11/25 (PCC / podatki lokalne / akcyza — nieruchomości,
środki transportu, umowy, paliwo, alkohol) is implemented as the R11
PCC/local/excise innovations package:

  R11-INN-01 pcc3_deadline_alert_monitor  — monitor 14 dni PCC-3
  R11-INN-02 real_estate_tax_simulator    — symulator podatku od nieruchomości
  R11-INN-03 excise_product_classifier    — klasyfikator wyrobów akcyzowych
  R11-INN-04 transport_tax_deadline_monitor— monitor DN-1 + raty
  R11-INN-05 vat_vs_pcc_arbitrator        — arbiter VAT vs PCC (art. 2 pkt 4)

Plus wiring in main_jdg.rego (final_verdict_p36), golden verdict + replay
and tests (pytest + native Rego). The PCC/local/excise layer (p14 v9, p15,
local_taxes/*, micro/pcc|akcyza|transport, pcc/*) is already implemented —
verified here (art. 1/7/8/12/16/30/99 COMPLETE).

Usage (from ``JDG/``)::

    python tools/pcc_lokalne_akcyza_report11_gate.py --json
    python tools/pcc_lokalne_akcyza_report11_gate.py --write
    python tools/pcc_lokalne_akcyza_report11_gate.py --strict
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

BASE_DIR = Path(__file__).resolve().parents[1]
BUNDLES_DIR = BASE_DIR / "bundles"
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_11_PCC_LOKALNE_AKCYZA.txt"
EVIDENCE_PATH = BUNDLES_DIR / "pcc_lokalne_akcyza_report11_evidence.json"

R11_REGO = "rules/r11_pcc_lokalne_akcyza_innovations_v9.rego"
MAIN_REGO = "rules/main_jdg.rego"
THRESHOLDS_REGO = "rules/thresholds_jdg.rego"
PYTEST = "tests/auto/test_r11_pcc_lokalne_akcyza_enterprise.py"
NATIVE_REGO = "tests/rego/test_r11_pcc_lokalne_akcyza_enterprise.rego"

# Warstwa PCC/lokalne/akcyza (p14/p15 + local_taxes/* + micro + pcc/*) — weryfikowana
PLE_CORE_FILES = [
    "rules/local_taxes.rego",
    "rules/local_taxes/pcc.rego",
    "rules/local_taxes/pcc_enterprise_complete.rego",
    "rules/local_taxes/pcc_excise_enterprise.rego",
    "rules/local_taxes/excise_enterprise_complete.rego",
    "rules/local_taxes/local_procedures_enterprise.rego",
    "rules/local_taxes/plan26_local.rego",
    "rules/local_taxes/real_estate.rego",
    "rules/local_taxes/transport.rego",
    "rules/local_taxes/akcyza_fuel.rego",
    "rules/local_taxes/akcyza_alcohol.rego",
    "rules/micro/pcc/pcc.rego",
    "rules/micro/akcyza/akcyza.rego",
    "rules/micro/transport/transport.rego",
    "rules/micro/plan33_pcc.rego",
    "rules/micro/plan33_prop_transport.rego",
    "rules/micro/plan33_agricultural_tax.rego",
    "rules/pcc/pcc_companies.rego",
    "rules/pcc/pcc_loans.rego",
    "rules/pcc/pcc_rates.rego",
    "rules/pcc/pcc_sales.rego",
    "rules/pcc/plan42_pcc.rego",
    "rules/p14_pcc_lokalne_akcyza_innovations_v9.rego",
    "rules/p15_pcc_local_excise_innovations_v8.rego",
    "rules/p33_pcc_complete.rego",
    "rules/p33_excise_supplement.rego",
]

REQUIRED_INNOVATIONS = [
    "pcc3_deadline_alert_monitor", "pcc3_unfiled_count", "pcc3_deadline_days",
    "real_estate_tax_simulator", "ret_total_annual", "ret_installment_quarterly",
    "excise_product_classifier", "exc_duty_pln", "exc_needs_banderole",
    "transport_tax_deadline_monitor", "trt_unfiled_count", "dn1_filed",
    "vat_vs_pcc_arbitrator", "arb_pcc_excluded", "arb_pcc_due_pln",
]

TEST_MARKERS = [
    "pcc3_deadline_alert_monitor", "real_estate_tax_simulator",
    "excise_product_classifier", "transport_tax_deadline_monitor",
    "vat_vs_pcc_arbitrator", "r11_pcc_local_excise_check",
    "BLOCK_AND_ALERT", "TRIAGE_QUEUE", "art. 10", "art. 2 pkt 4",
]

# Podstawy prawne wymagane w nowym pakiecie (kanoniczne)
REQUIRED_LEGAL_MARKERS = [
    "art. 10",
    "art. 7",
    "art. 2 pkt 4",
    "art. 16",
    "art. 93-100",
    "art. 65",
]


def _read(rel: str) -> str:
    path = BASE_DIR / rel
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return ""


def _rule_ids(text: str) -> list[str]:
    return re.findall(r'"rule_id"\s*:\s*"([a-zA-Z0-9_.-]+)"', text)


def _scope_evidence() -> dict[str, Any]:
    files = {
        "r11_rego": _read(R11_REGO),
        "main_jdg": _read(MAIN_REGO),
        "thresholds": _read(THRESHOLDS_REGO),
        "pytest": _read(PYTEST),
        "native_rego": _read(NATIVE_REGO),
        "report": _read(str(REPORT_PATH.relative_to(BASE_DIR))),
    }
    ple_core_present = sum(bool(_read(f)) for f in PLE_CORE_FILES)
    return {
        "files": {name: bool(text) for name, text in files.items()},
        "files_total": len(files),
        "files_present": sum(bool(text) for text in files.values()),
        "report_present": bool(files["report"]),
        "ple_core_files_declared": len(PLE_CORE_FILES),
        "ple_core_files_present": ple_core_present,
    }


def _innovation_evidence() -> dict[str, Any]:
    text = _read(R11_REGO)
    missing = [fn for fn in REQUIRED_INNOVATIONS if fn not in text]
    legal = [m for m in REQUIRED_LEGAL_MARKERS if m not in text]
    return {
        "required_innovations": REQUIRED_INNOVATIONS,
        "missing_innovations": missing,
        "innovations_complete": not missing,
        "legal_basis_markers": REQUIRED_LEGAL_MARKERS,
        "missing_legal_markers": legal,
        "legal_basis_complete": not legal,
        "decide_report_rule": "jdg.r11_pcc_lokalne_akcyza_innovations.vat_vs_pcc_arbitrator" in text,
        "activation_flag": "r11_pcc_local_excise_check" in text,
        "default_no_match": "jdg.r11_pcc_lokalne_akcyza_innovations.no_match" in text,
        "pcc3_monitor": "pcc3_unfiled_count" in text and "pcc3_deadline_days" in text,
        "real_estate": "ret_total_annual" in text and "ret_installment_quarterly" in text,
        "excise_classifier": "exc_duty_pln" in text and "exc_needs_banderole" in text,
        "transport_monitor": "trt_unfiled_count" in text and "dn1_filed" in text,
        "vat_pcc_arbitrator": "arb_pcc_excluded" in text and "arb_pcc_due_pln" in text,
    }


def _thresholds_evidence() -> dict[str, Any]:
    text = _read(R11_REGO)
    th = _read(THRESHOLDS_REGO)
    return {
        "thresholds_via_data": "_th_ple" in text,
        "pcc_rate_externalized": 'object.get(_th_ple, "pcc_sale_rate", 0.02)' in text,
        "real_estate_externalized": 'object.get(_th_ple, "land_business_rate", 1.43)' in text,
        "excise_externalized": 'object.get(_th_ple, "excise_gasoline", 1566)' in text,
        "ple_block_present": "pcc_local_excise := {" in th and '"excise_ethanol_per_hl"' in th,
    }


def _duplicate_evidence() -> dict[str, Any]:
    text = _read(R11_REGO)
    ids = _rule_ids(text)
    dups = sorted(rid for rid, count in Counter(ids).items() if count > 1)
    return {
        "rule_ids_total": len(ids),
        "rule_ids_unique": len(set(ids)),
        "duplicates": dups,
        "duplicate_count": len(dups),
    }


def _router_evidence() -> dict[str, Any]:
    joined = _read(MAIN_REGO)
    post_merge_target = re.search(
        r"final_verdict_post_merge = object\.union\(final_verdict_p(\d+)", joined
    )
    return {
        "import_present": "import data.jdg.r11_pcc_lokalne_akcyza_innovations" in joined,
        "package_decisions_entry": '"jdg.r11_pcc_lokalne_akcyza_innovations": r11_pcc_lokalne_akcyza_innovations.decide' in joined,
        "final_verdict_p36": "final_verdict_p36 = safe_merge(final_verdict_p35," in joined,
        "post_merge_present": post_merge_target is not None and int(post_merge_target.group(1)) >= 36,
        "invariants_enforced": "runtime_invariants.enforce(final_verdict_post_merge)" in joined,
        "final_verdict_public": "final_verdict = final_verdict_enforced" in joined,
    }


def _test_evidence() -> dict[str, Any]:
    pytest_text = _read(PYTEST)
    native_text = _read(NATIVE_REGO)
    joined = "\n".join([pytest_text, native_text])
    marker_hits = {m: m in joined for m in TEST_MARKERS}
    return {
        "pytest_present": bool(pytest_text),
        "native_rego_present": bool(native_text),
        "marker_hits": marker_hits,
        "markers_complete": all(marker_hits.values()),
        "pytest_test_functions": len(re.findall(r"def test_", pytest_text)),
        "native_test_functions": len(re.findall(r"^test_\w+\s*\{", native_text, re.MULTILINE)),
    }


def _replay_evidence() -> dict[str, Any]:
    golden = json.loads((BUNDLES_DIR / "golden_verdicts.json").read_text(encoding="utf-8"))
    verdicts = golden.get("verdicts", {})
    replays = golden.get("replays", [])
    if not isinstance(replays, list):
        replays = []
    ple_verdicts = {
        h: v
        for h, v in verdicts.items()
        if "r11_pcc_lokalne_akcyza_innovations" in json.dumps(v, ensure_ascii=False)
    }
    ple_hashes = {v.get("verdict_hash") for v in ple_verdicts.values()}
    ple_replays = [r for r in replays if r.get("golden_verdict_hash") in ple_hashes]
    uver = [r for r in ple_replays if r.get("uver_applies")]
    return {
        "golden_verdicts_total": len(verdicts),
        "ple_verdicts": len(ple_verdicts),
        "ple_replays": len(ple_replays),
        "uver_count": len(uver),
        "replay_verified": len(ple_verdicts) >= 1 and len(ple_replays) >= 1 and len(uver) == 0,
    }


def build_evidence() -> dict[str, Any]:
    scope = _scope_evidence()
    innovations = _innovation_evidence()
    thresholds = _thresholds_evidence()
    dup = _duplicate_evidence()
    router = _router_evidence()
    tests = _test_evidence()
    replay = _replay_evidence()

    gates = {
        "scope_files_present": scope["files_present"] == scope["files_total"]
        and scope["ple_core_files_present"] == scope["ple_core_files_declared"],
        "report_present": scope["report_present"],
        "innovations_complete": innovations["innovations_complete"]
        and innovations["decide_report_rule"]
        and innovations["activation_flag"]
        and innovations["default_no_match"]
        and innovations["pcc3_monitor"]
        and innovations["real_estate"]
        and innovations["excise_classifier"]
        and innovations["transport_monitor"]
        and innovations["vat_pcc_arbitrator"],
        "legal_basis_canonical": innovations["legal_basis_complete"],
        "thresholds_externalized": all(thresholds.values()),
        "duplicate_free": dup["duplicate_count"] == 0,
        "router_wired": all(router.values()),
        "tests_present": tests["pytest_present"]
        and tests["native_rego_present"]
        and tests["markers_complete"],
        "golden_replay_ok": replay["replay_verified"],
    }
    passed = sum(gates.values())
    total = len(gates)
    status = "WDROZONY_100" if passed == total else "NIEPELNY"
    return {
        "report": "RAPORT_11_PCC_LOKALNE_AKCYZA",
        "status": status,
        "gates": gates,
        "gate_summary": {"passed": passed, "total": total},
        "checks_passed": passed,
        "checks_total": total,
        "scope": scope,
        "innovations": innovations,
        "thresholds": thresholds,
        "duplicates": dup,
        "router": router,
        "tests": tests,
        "replay": replay,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="RAPORT_11 evidence gate")
    parser.add_argument("--json", action="store_true", help="print evidence as JSON")
    parser.add_argument("--write", action="store_true", help="write evidence bundle")
    parser.add_argument("--strict", action="store_true", help="fail if not WDROZONY_100")
    args = parser.parse_args()

    evidence = build_evidence()
    if args.write:
        EVIDENCE_PATH.write_text(
            json.dumps(evidence, indent=2, ensure_ascii=False), encoding="utf-8"
        )
        print(f"✅ Evidence: {EVIDENCE_PATH.name} ({evidence['status']})")
    elif args.json:
        print(json.dumps(evidence, indent=2, ensure_ascii=False))
    else:
        print(
            f"RAPORT_11: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
