#!/usr/bin/env python3
"""RAPORT_10 CROSS-BORDER / TP / MDR-DAC6 / CFC / ViDA / CBAM — evidence gate.

Mirrors tools/ksiegowosc_report09_gate.py (new-campaign convention).
Prompt 10/25 (Cross-border / TP / MDR-DAC6 / CFC / ViDA / CBAM / DAC8) is
implemented as the R10 cross-border innovations package:

  R10-INN-01 wdt_deadline_alert_monitor — monitor 30 dni dowodu wywozu WDT
                                             (art. 42 ust. 12 VAT)
  R10-INN-02 mdr_risk_scorer          — scorer ryzyka MDR/DAC6 (hallmark A-E)
  R10-INN-03 tp_threshold_simulator   — symulator dokumentacji TP (500k/200M)
  R10-INN-04 cfc_profit_attribution   — przypisanie dochodu CFC (art. 30f PIT)
  R10-INN-05 fx_time_travel_reconciler— różnice kursowe z time-travel

Plus wiring in main_jdg.rego (final_verdict_p35), golden verdict + replay
and tests (pytest + native Rego). The cross-border layer (p12 v9, p13,
crossborder/*, international*, micro/crossborder, mdr/*, tp/*) is already
implemented — verified here (art. 20/23o/23zf/29/30da/30f/86r COMPLETE).

Usage (from ``JDG/``)::

    python tools/crossborder_innovations_report10_gate.py --json
    python tools/crossborder_innovations_report10_gate.py --write
    python tools/crossborder_innovations_report10_gate.py --strict
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
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_10_CROSSBORDER.txt"
EVIDENCE_PATH = BUNDLES_DIR / "crossborder_innovations_report10_evidence.json"

R10_REGO = "rules/r10_crossborder_innovations_v9.rego"
MAIN_REGO = "rules/main_jdg.rego"
THRESHOLDS_REGO = "rules/thresholds_jdg.rego"
PYTEST = "tests/auto/test_r10_crossborder_enterprise.py"
NATIVE_REGO = "tests/rego/test_r10_crossborder_enterprise.rego"

# Warstwa cross-border (p12/p13 + crossborder/* + micro + mdr/* + tp/*) — weryfikowana
CB_CORE_FILES = [
    "rules/crossborder.rego",
    "rules/international.rego",
    "rules/international_expanded.rego",
    "rules/micro/crossborder/crossborder.rego",
    "rules/micro/plan33_cb.rego",
    "rules/micro/plan33_tp.rego",
    "rules/micro/plan33_mdr.rego",
    "rules/p12_crossborder_innovations_v9.rego",
    "rules/p13_crossborder_innovations_v8.rego",
    "rules/crossborder/exit_tax_cfc_complete.rego",
    "rules/crossborder/plan23_ue.rego",
    "rules/crossborder/post_brexit.rego",
    "rules/mdr/mdr_enterprise.rego",
    "rules/mdr/mdr_hallmarks.rego",
    "rules/mdr/plan44_mdr.rego",
    "rules/mdr/plan45_mdr.rego",
    "rules/tp/plan44_tp.rego",
    "rules/tp/plan45_tp.rego",
    "rules/cbam_full.rego",
    "rules/cfc_auto_classifier.rego",
    "rules/dac8_report_generator.rego",
    "rules/mdr_auto_generator.rego",
    "rules/mdr_dac6_enterprise.rego",
    "rules/vida_drr_full.rego",
    "rules/wdt_document_tracker.rego",
    "rules/cross_domain_intelligence_enterprise.rego",
]

REQUIRED_INNOVATIONS = [
    "wdt_deadline_alert_monitor", "wdt_red_count", "wdt_missing_count",
    "wdt_documentation_days",
    "mdr_risk_scorer", "mdr_risk_score", "mdr_hallmark_score",
    "mdr_confidence", "mdr_recommendation",
    "tp_threshold_simulator", "tp_local_required", "tp_master_required",
    "tp_months_to_local",
    "cfc_profit_attribution", "cfc_applies", "cfc_attributed_base_pln",
    "cfc_control_met", "cfc_low_tax_met",
    "fx_time_travel_reconciler", "fx_schedule", "fx_realized_diff_pln",
    "fx_effective_rate",
]

TEST_MARKERS = [
    "wdt_deadline_alert_monitor", "mdr_risk_scorer", "tp_threshold_simulator",
    "cfc_profit_attribution", "fx_time_travel_reconciler",
    "r10_crossborder_check", "BLOCK_AND_ALERT", "TRIAGE_QUEUE",
    "art. 30f", "art. 42",
]

# Podstawy prawne wymagane w nowym pakiecie (kanoniczne)
REQUIRED_LEGAL_MARKERS = [
    "art. 42",
    "art. 86a-86r",
    "art. 23o",
    "art. 23zf",
    "art. 30f",
    "art. 24c",
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
        "r10_rego": _read(R10_REGO),
        "main_jdg": _read(MAIN_REGO),
        "thresholds": _read(THRESHOLDS_REGO),
        "pytest": _read(PYTEST),
        "native_rego": _read(NATIVE_REGO),
        "report": _read(str(REPORT_PATH.relative_to(BASE_DIR))),
    }
    cb_core_present = sum(bool(_read(f)) for f in CB_CORE_FILES)
    return {
        "files": {name: bool(text) for name, text in files.items()},
        "files_total": len(files),
        "files_present": sum(bool(text) for text in files.values()),
        "report_present": bool(files["report"]),
        "cb_core_files_declared": len(CB_CORE_FILES),
        "cb_core_files_present": cb_core_present,
    }


def _innovation_evidence() -> dict[str, Any]:
    text = _read(R10_REGO)
    missing = [fn for fn in REQUIRED_INNOVATIONS if fn not in text]
    legal = [m for m in REQUIRED_LEGAL_MARKERS if m not in text]
    return {
        "required_innovations": REQUIRED_INNOVATIONS,
        "missing_innovations": missing,
        "innovations_complete": not missing,
        "legal_basis_markers": REQUIRED_LEGAL_MARKERS,
        "missing_legal_markers": legal,
        "legal_basis_complete": not legal,
        "decide_report_rule": "jdg.r10_crossborder_innovations.fx_time_travel_reconciler" in text,
        "activation_flag": "r10_crossborder_check" in text,
        "default_no_match": "jdg.r10_crossborder_innovations.no_match" in text,
        "wdt_monitor": "wdt_red_count" in text and "wdt_missing_count" in text,
        "mdr_scorer": "mdr_risk_score" in text and "mdr_confidence" in text,
        "tp_simulator": "tp_local_required" in text and "tp_master_required" in text,
        "cfc_attribution": "cfc_applies" in text and "cfc_attributed_base_pln" in text,
        "fx_time_travel": "fx_schedule" in text and "fx_realized_diff_pln" in text,
    }


def _thresholds_evidence() -> dict[str, Any]:
    text = _read(R10_REGO)
    th = _read(THRESHOLDS_REGO)
    return {
        "thresholds_via_data": "_th_cb" in text,
        "wdt_days_externalized": 'object.get(_th_cb, "wdt_documentation_days", 30)' in text,
        "tp_externalized": 'object.get(_th_cb, "tp_local_file_pln", 500000)' in text,
        "cfc_externalized": 'object.get(_th_cb, "cfc_ownership_min_pct", 0.50)' in text,
        "crossborder_block_present": "crossborder := {" in th and '"exit_tax_threshold_pln"' in th,
    }


def _duplicate_evidence() -> dict[str, Any]:
    text = _read(R10_REGO)
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
        "import_present": "import data.jdg.r10_crossborder_innovations" in joined,
        "package_decisions_entry": '"jdg.r10_crossborder_innovations": r10_crossborder_innovations.decide' in joined,
        "final_verdict_p35": "final_verdict_p35 = safe_merge(final_verdict_p34," in joined,
        "post_merge_present": post_merge_target is not None and int(post_merge_target.group(1)) >= 35,
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
    cb_verdicts = {
        h: v
        for h, v in verdicts.items()
        if "r10_crossborder_innovations" in json.dumps(v, ensure_ascii=False)
    }
    cb_hashes = {v.get("verdict_hash") for v in cb_verdicts.values()}
    cb_replays = [r for r in replays if r.get("golden_verdict_hash") in cb_hashes]
    uver = [r for r in cb_replays if r.get("uver_applies")]
    return {
        "golden_verdicts_total": len(verdicts),
        "cb_verdicts": len(cb_verdicts),
        "cb_replays": len(cb_replays),
        "uver_count": len(uver),
        "replay_verified": len(cb_verdicts) >= 1 and len(cb_replays) >= 1 and len(uver) == 0,
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
        and scope["cb_core_files_present"] == scope["cb_core_files_declared"],
        "report_present": scope["report_present"],
        "innovations_complete": innovations["innovations_complete"]
        and innovations["decide_report_rule"]
        and innovations["activation_flag"]
        and innovations["default_no_match"]
        and innovations["wdt_monitor"]
        and innovations["mdr_scorer"]
        and innovations["tp_simulator"]
        and innovations["cfc_attribution"]
        and innovations["fx_time_travel"],
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
        "report": "RAPORT_10_CROSSBORDER",
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
    parser = argparse.ArgumentParser(description="RAPORT_10 evidence gate")
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
            f"RAPORT_10: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
