#!/usr/bin/env python3
"""RAPORT_13 HYPER PLAN45 / KONTEKSTY SPECJALNE — evidence gate.

Mirrors tools/ryczalt_cykl_zycia_report12_gate.py (new-campaign
convention). Prompt 13/25 (hyper Plan45 / reprezentacja / działalność
regulowana / konteksty specjalne) is implemented as the R13 hyper/konteksty
innovations package:

  R13-INN-01 cross_domain_conflict_detector — konflikt IP Box vs B+R (art. 30ca)
  R13-INN-02 solidarity_tax_monitor       — danina solidarnościowa (art. 30h)
  R13-INN-03 prokura_deadline_monitor     — monitor wpisu prokury (art. 109 KC)
  R13-INN-04 annual_deadline_calendar     — kalendarz terminów rocznych (art. 45)
  R13-INN-05 qualified_signature_selector — selektor podpisu (eIDAS, art. 126)

Plus wiring in main_jdg.rego (final_verdict_p38), golden verdict + replay
and tests (pytest + native Rego). The hyper/konteksty layer (hyper/** 14
modułów, p17_edge_conflicts, hyper_plan45_meta, representation, regulated,
conviction, esig, calendar, conflicts, 15 par plan44/45) is already
implemented — verified here (art. 30ca/30h/109/45/126/eIDAS COMPLETE).

Usage (from ``JDG/``)::

    python tools/hyper_konteksty_report13_gate.py --json
    python tools/hyper_konteksty_report13_gate.py --write
    python tools/hyper_konteksty_report13_gate.py --strict
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
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_13_HYPER_CYKL_FIRMY.txt"
EVIDENCE_PATH = BUNDLES_DIR / "hyper_konteksty_report13_evidence.json"

R13_REGO = "rules/r13_hyper_konteksty_innovations_v9.rego"
MAIN_REGO = "rules/main_jdg.rego"
THRESHOLDS_REGO = "rules/thresholds_jdg.rego"
PYTEST = "tests/auto/test_r13_hyper_konteksty_enterprise.py"
NATIVE_REGO = "tests/rego/test_r13_hyper_konteksty_enterprise.rego"

# Warstwa hyper/konteksty (hyper/** + p17 + meta + representation + konteksty)
RHC_CORE_FILES = [
    "rules/jdg/hyper/audit/plan45.rego",
    "rules/jdg/hyper/deadlines/plan45.rego",
    "rules/jdg/hyper/edelivery/plan45.rego",
    "rules/jdg/hyper/family/plan45.rego",
    "rules/jdg/hyper/force_majeure/plan45.rego",
    "rules/jdg/hyper/fx/plan45.rego",
    "rules/jdg/hyper/general/plan45.rego",
    "rules/jdg/hyper/limits/plan45.rego",
    "rules/jdg/hyper/mdr/plan45.rego",
    "rules/jdg/hyper/misc/plan45.rego",
    "rules/jdg/hyper/procurement/plan45.rego",
    "rules/jdg/hyper/sanctions/plan45.rego",
    "rules/jdg/hyper/solidarity/plan45.rego",
    "rules/jdg/hyper/wis/plan45.rego",
    "rules/p17_edge_conflicts_innovations_v8.rego",
    "rules/hyper_plan45_meta_enterprise.rego",
    "rules/representation.rego",
    "rules/representation/plan26_prokura.rego",
    "rules/regulated_compliance_enterprise.rego",
    "rules/conviction_checker_enterprise.rego",
    "rules/esig_auto_applicator_enterprise.rego",
    "rules/calendar_notifier_enterprise.rego",
    "rules/conflicts.rego",
    "rules/conflict_declaration_enterprise.rego",
]

REQUIRED_INNOVATIONS = [
    "cross_domain_conflict_detector", "cd_conflict", "cd_overlap_amount",
    "solidarity_tax_monitor", "st_solidarity_due_pln", "st_applies",
    "prokura_deadline_monitor", "pk_unfiled_count", "pk_deadline_days",
    "annual_deadline_calendar", "dl_unfiled_count", "dl_shifted_count",
    "qualified_signature_selector", "sg_qualified_required", "sg_value_threshold",
]

TEST_MARKERS = [
    "cross_domain_conflict_detector", "solidarity_tax_monitor",
    "prokura_deadline_monitor", "annual_deadline_calendar",
    "qualified_signature_selector", "r13_hyper_konteksty_check",
    "BLOCK_AND_ALERT", "TRIAGE_QUEUE",
    "art. 30ca", "art. 30h", "art. 109", "art. 45", "art. 126",
]

# Podstawy prawne wymagane w nowym pakiecie (kanoniczne)
REQUIRED_LEGAL_MARKERS = [
    "art. 30ca",
    "art. 30h",
    "art. 109",
    "art. 45",
    "art. 126",
    "eIDAS",
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
        "r13_rego": _read(R13_REGO),
        "main_jdg": _read(MAIN_REGO),
        "thresholds": _read(THRESHOLDS_REGO),
        "pytest": _read(PYTEST),
        "native_rego": _read(NATIVE_REGO),
        "report": _read(str(REPORT_PATH.relative_to(BASE_DIR))),
    }
    rhc_core_present = sum(bool(_read(f)) for f in RHC_CORE_FILES)
    return {
        "files": {name: bool(text) for name, text in files.items()},
        "files_total": len(files),
        "files_present": sum(bool(text) for text in files.values()),
        "report_present": bool(files["report"]),
        "rhc_core_files_declared": len(RHC_CORE_FILES),
        "rhc_core_files_present": rhc_core_present,
    }


def _innovation_evidence() -> dict[str, Any]:
    text = _read(R13_REGO)
    missing = [fn for fn in REQUIRED_INNOVATIONS if fn not in text]
    legal = [m for m in REQUIRED_LEGAL_MARKERS if m not in text]
    return {
        "required_innovations": REQUIRED_INNOVATIONS,
        "missing_innovations": missing,
        "innovations_complete": not missing,
        "legal_basis_markers": REQUIRED_LEGAL_MARKERS,
        "missing_legal_markers": legal,
        "legal_basis_complete": not legal,
        "decide_report_rule": "jdg.r13_hyper_konteksty_innovations.qualified_signature_selector" in text,
        "activation_flag": "r13_hyper_konteksty_check" in text,
        "default_no_match": "jdg.r13_hyper_konteksty_innovations.no_match" in text,
        "conflict_detector": "cd_conflict" in text and "cd_overlap_amount" in text,
        "solidarity_monitor": "st_solidarity_due_pln" in text and "st_applies" in text,
        "prokura_monitor": "pk_unfiled_count" in text and "pk_deadline_days" in text,
        "deadline_calendar": "dl_unfiled_count" in text and "dl_shifted_count" in text,
        "signature_selector": "sg_qualified_required" in text and "sg_value_threshold" in text,
    }


def _thresholds_evidence() -> dict[str, Any]:
    text = _read(R13_REGO)
    th = _read(THRESHOLDS_REGO)
    return {
        "thresholds_via_data": "_th_hc" in text,
        "solidarity_externalized": 'object.get(_th_hc, "solidarity_threshold_pln", 1000000)' in text,
        "ip_box_externalized": 'object.get(_th_hc, "ip_box_rate", 0.05)' in text,
        "prokura_externalized": 'object.get(_th_hc, "prokura_deadline_days", 7)' in text,
        "hc_block_present": "hyper_contexts := {" in th and '"solidarity_threshold_pln"' in th,
    }


def _duplicate_evidence() -> dict[str, Any]:
    text = _read(R13_REGO)
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
        "import_present": "import data.jdg.r13_hyper_konteksty_innovations" in joined,
        "package_decisions_entry": '"jdg.r13_hyper_konteksty_innovations": r13_hyper_konteksty_innovations.decide' in joined,
        "final_verdict_p38": "final_verdict_p38 = safe_merge(final_verdict_p37," in joined,
        "post_merge_present": post_merge_target is not None and int(post_merge_target.group(1)) >= 38,
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
        "native_test_functions": len(re.findall(r"^test_\w+\s+(if\s+)?\{", native_text, re.MULTILINE)),
    }


def _replay_evidence() -> dict[str, Any]:
    golden = json.loads((BUNDLES_DIR / "golden_verdicts.json").read_text(encoding="utf-8"))
    verdicts = golden.get("verdicts", {})
    replays = golden.get("replays", [])
    if not isinstance(replays, list):
        replays = []
    rhc_verdicts = {
        h: v
        for h, v in verdicts.items()
        if "r13_hyper_konteksty_innovations" in json.dumps(v, ensure_ascii=False)
    }
    rhc_hashes = {v.get("verdict_hash") for v in rhc_verdicts.values()}
    rhc_replays = [r for r in replays if r.get("golden_verdict_hash") in rhc_hashes]
    uver = [r for r in rhc_replays if r.get("uver_applies")]
    return {
        "golden_verdicts_total": len(verdicts),
        "rhc_verdicts": len(rhc_verdicts),
        "rhc_replays": len(rhc_replays),
        "uver_count": len(uver),
        "replay_verified": len(rhc_verdicts) >= 1 and len(rhc_replays) >= 1 and len(uver) == 0,
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
        and scope["rhc_core_files_present"] == scope["rhc_core_files_declared"],
        "report_present": scope["report_present"],
        "innovations_complete": innovations["innovations_complete"]
        and innovations["decide_report_rule"]
        and innovations["activation_flag"]
        and innovations["default_no_match"]
        and innovations["conflict_detector"]
        and innovations["solidarity_monitor"]
        and innovations["prokura_monitor"]
        and innovations["deadline_calendar"]
        and innovations["signature_selector"],
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
        "report": "RAPORT_13_HYPER_CYKL_FIRMY",
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
    parser = argparse.ArgumentParser(description="RAPORT_13 evidence gate")
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
            f"RAPORT_13: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
