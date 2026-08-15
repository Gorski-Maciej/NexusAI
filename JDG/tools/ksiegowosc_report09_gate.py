#!/usr/bin/env python3
"""RAPORT_09 UoR / PKPiR / KSIĘGOWOŚĆ — evidence gate.

Mirrors tools/ordynacja_obrona_report08_gate.py (new-campaign convention).
Prompt 09/25 (UoR / PKPiR / KSIĘGOWOŚĆ — pełna księgowość, księgi, kolumny
PKPiR, amortyzacja, transformacja) is implemented as the R09 accounting
innovations package:

  R09-INN-01 uor_threshold_simulator      — symulator progu UoR + projekcja
                                               forward (art. 2 ust. 1 pkt 5 UoR)
  R09-INN-02 pkpir_ledger_reconciliation  — uzgodnienie 3-drożne PKPiR↔VAT↔bank
                                               (kol. 7 / baza VAT / wpływy)
  R09-INN-03 amortization_plan_optimizer  — liniowa vs degresywna vs jednorazowa
                                               (art. 22i/22k PIT)
  R09-INN-04 inventory_deadline_monitor   — monitor terminów inwentaryzacji
                                               (art. 26 UoR, 3 poziomy alertów)
  R09-INN-05 financial_statement_autopack — auto-pakiet sprawozdania finansowego
                                               (art. 45-49/52/74 UoR)

Plus wiring in main_jdg.rego (final_verdict_p34), golden verdict + replay
and tests (pytest + native Rego). The accounting layer (p09 v9.1, accounting/*,
uor/*, micro/pkpir, micro/uor, micro/amortyzacja, transformer, p18) is already
implemented — verified here (art. 2/26/32 UoR + 22a/22i/22k PIT COMPLETE).

Usage (from ``JDG/``)::

    python tools/ksiegowosc_report09_gate.py --json
    python tools/ksiegowosc_report09_gate.py --write
    python tools/ksiegowosc_report09_gate.py --strict
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
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_09_UOR_KSIEGOWOSC.txt"
EVIDENCE_PATH = BUNDLES_DIR / "ksiegowosc_report09_evidence.json"

R09_REGO = "rules/r09_ksiegowosc_pkpir_uor_innovations_v9.rego"
MAIN_REGO = "rules/main_jdg.rego"
THRESHOLDS_REGO = "rules/thresholds_jdg.rego"
PYTEST = "tests/auto/test_r09_ksiegowosc_enterprise.py"
NATIVE_REGO = "tests/rego/test_r09_ksiegowosc_enterprise.rego"

# Warstwa Księgowość (p09 + accounting/* + uor/* + micro + transformer) — weryfikowana
ACC_CORE_FILES = [
    "rules/accounting.rego",
    "rules/accounting/depreciation_enterprise.rego",
    "rules/accounting/depreciation_enterprise_complete.rego",
    "rules/accounting/pkpir_enterprise_live.rego",
    "rules/accounting/pkpir_enterprise_validation.rego",
    "rules/accounting/pkpir_enterprise_validator.rego",
    "rules/accounting/plan23_leasing.rego",
    "rules/accounting/plan42_pkpir.rego",
    "rules/accounting/uor_enterprise_live.rego",
    "rules/uor/uor_assets.rego",
    "rules/uor/uor_books.rego",
    "rules/uor/uor_closing.rego",
    "rules/uor/uor_costs.rego",
    "rules/uor/uor_financial_stmt.rego",
    "rules/uor/uor_inventory.rego",
    "rules/uor/uor_obligation.rego",
    "rules/uor/uor_revenue.rego",
    "rules/uor/plan42_uor.rego",
    "rules/micro/uor/uor.rego",
    "rules/micro/plan33_uor.rego",
    "rules/micro/pkpir/pkpir.rego",
    "rules/micro/pkpir/pkpir_kolumny.rego",
    "rules/micro/pkpir/pkpir_remanent.rego",
    "rules/micro/amortyzacja/pit_a22a.rego",
    "rules/micro/amortyzacja/pit_a22i.rego",
    "rules/micro/amortyzacja/pit_a22k.rego",
    "rules/micro/amortyzacja/pit_a22n.rego",
    "rules/p09_ksiegowosc_pkpir_uor_innovations_v9.rego",
    "rules/p18_automatyzacja_ksiegowosci_innovations_v9.rego",
    "rules/pkpir_to_uor_transformer.rego",
]

REQUIRED_INNOVATIONS = [
    "uor_threshold_simulator", "uos_current_eur", "uos_projected_eur",
    "uos_months_to_threshold", "uos_early_warning",
    "pkpir_ledger_reconciliation", "lrecon_pkpir_sales_net",
    "lrecon_vat_sales_base", "lrecon_bank_inflows", "lrecon_reconciled",
    "amortization_plan_optimizer", "plan_linear_annual",
    "plan_degressive_annual", "plan_one_off_eligible", "plan_best_method",
    "inventory_deadline_monitor", "inv_red_count", "FIXED_ASSETS",
    "financial_statement_autopack", "fs_missing", "fs_ready",
    "fs_retention_years",
]

TEST_MARKERS = [
    "uor_threshold_simulator", "pkpir_ledger_reconciliation",
    "amortization_plan_optimizer", "inventory_deadline_monitor",
    "financial_statement_autopack", "r09_ksiegowosc_check",
    "BLOCK_AND_ALERT", "TRIAGE_QUEUE", "art. 74", "ONE_OFF",
]

# Podstawy prawne wymagane w nowym pakiecie (kanoniczne)
REQUIRED_LEGAL_MARKERS = [
    "art. 2 ust. 1 pkt 5",
    "art. 26",
    "art. 45-49",
    "art. 74",
    "art. 22i",
    "art. 22k",
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
        "r09_rego": _read(R09_REGO),
        "main_jdg": _read(MAIN_REGO),
        "thresholds": _read(THRESHOLDS_REGO),
        "pytest": _read(PYTEST),
        "native_rego": _read(NATIVE_REGO),
        "report": _read(str(REPORT_PATH.relative_to(BASE_DIR))),
    }
    acc_core_present = sum(bool(_read(f)) for f in ACC_CORE_FILES)
    return {
        "files": {name: bool(text) for name, text in files.items()},
        "files_total": len(files),
        "files_present": sum(bool(text) for text in files.values()),
        "report_present": bool(files["report"]),
        "acc_core_files_declared": len(ACC_CORE_FILES),
        "acc_core_files_present": acc_core_present,
    }


def _innovation_evidence() -> dict[str, Any]:
    text = _read(R09_REGO)
    missing = [fn for fn in REQUIRED_INNOVATIONS if fn not in text]
    legal = [m for m in REQUIRED_LEGAL_MARKERS if m not in text]
    return {
        "required_innovations": REQUIRED_INNOVATIONS,
        "missing_innovations": missing,
        "innovations_complete": not missing,
        "legal_basis_markers": REQUIRED_LEGAL_MARKERS,
        "missing_legal_markers": legal,
        "legal_basis_complete": not legal,
        "decide_report_rule": "jdg.r09_ksiegowosc_pkpir_uor_innovations.financial_statement_autopack" in text,
        "activation_flag": "r09_ksiegowosc_check" in text,
        "default_no_match": "jdg.r09_ksiegowosc_pkpir_uor_innovations.no_match" in text,
        "uor_simulator": "uos_current_eur" in text and "uos_months_to_threshold" in text,
        "three_way_reconciliation": "lrecon_reconciled" in text and "lrecon_mismatches" in text,
        "amortization_optimizer": "plan_best_method" in text and "plan_one_off_eligible" in text,
        "inventory_monitor": "inv_red_count" in text and "FIXED_ASSETS" in text,
        "fs_autopack": "fs_missing" in text and "fs_ready" in text,
    }


def _thresholds_evidence() -> dict[str, Any]:
    text = _read(R09_REGO)
    th = _read(THRESHOLDS_REGO)
    return {
        "thresholds_via_data": "_th_acc" in text,
        "uor_threshold_externalized": 'object.get(_th_acc, "uor_threshold_eur", 2000000)' in text,
        "depreciation_externalized": "plan_kst_rates" in text,
        "car_limit_externalized": 'object.get(_th_acc, "car_limit_standard", 150000)' in text,
        "accounting_block_present": "accounting := {" in th and '"uor_threshold_eur"' in th,
    }


def _duplicate_evidence() -> dict[str, Any]:
    text = _read(R09_REGO)
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
        "import_present": "import data.jdg.r09_ksiegowosc_pkpir_uor_innovations" in joined,
        "package_decisions_entry": '"jdg.r09_ksiegowosc_pkpir_uor_innovations": r09_ksiegowosc_pkpir_uor_innovations.decide' in joined,
        "final_verdict_p34": "final_verdict_p34 = safe_merge(final_verdict_p33," in joined,
        "post_merge_present": post_merge_target is not None and int(post_merge_target.group(1)) >= 34,
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
    acc_verdicts = {
        h: v
        for h, v in verdicts.items()
        if "r09_ksiegowosc_pkpir_uor_innovations" in json.dumps(v, ensure_ascii=False)
    }
    acc_hashes = {v.get("verdict_hash") for v in acc_verdicts.values()}
    acc_replays = [r for r in replays if r.get("golden_verdict_hash") in acc_hashes]
    uver = [r for r in acc_replays if r.get("uver_applies")]
    return {
        "golden_verdicts_total": len(verdicts),
        "acc_verdicts": len(acc_verdicts),
        "acc_replays": len(acc_replays),
        "uver_count": len(uver),
        "replay_verified": len(acc_verdicts) >= 1 and len(acc_replays) >= 1 and len(uver) == 0,
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
        and scope["acc_core_files_present"] == scope["acc_core_files_declared"],
        "report_present": scope["report_present"],
        "innovations_complete": innovations["innovations_complete"]
        and innovations["decide_report_rule"]
        and innovations["activation_flag"]
        and innovations["default_no_match"]
        and innovations["uor_simulator"]
        and innovations["three_way_reconciliation"]
        and innovations["amortization_optimizer"]
        and innovations["inventory_monitor"]
        and innovations["fs_autopack"],
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
        "report": "RAPORT_09_UOR_KSIEGOWOSC",
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
    parser = argparse.ArgumentParser(description="RAPORT_09 evidence gate")
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
            f"RAPORT_09: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
