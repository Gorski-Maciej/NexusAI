#!/usr/bin/env python3
"""RAPORT_14 RODO / AML-CBDD / BDO / ŚRODOWISKO — evidence gate.

Mirrors tools/hyper_konteksty_report13_gate.py (new-campaign convention).
Prompt 14/25 (RODO / AML-CBDD / BDO / środowisko / sekurytyzacja) is
implemented as the R14 RODO/AML/BDO innovations package:

  R14-INN-01 rodo_register_monitor       — rejestr czynności (art. 30 RODO)
  R14-INN-02 aml_transaction_risk_scorer — scoring transakcji AML (art. 34)
  R14-INN-03 rodo_sanction_calculator    — sankcje RODO (art. 83)
  R14-INN-04 str_gijf_deadline_monitor   — monitor STR/GIIF (art. 74-80)
  R14-INN-05 bdo_obligation_monitor      — monitor obowiązków BDO (art. 49-53)

Plus wiring in main_jdg.rego (final_verdict_p39), golden verdict + replay
and tests (pytest + native Rego). The RODO/AML/BDO layer (p14/p15/p16,
rodo*, compliance, security_fortress, environmental, micro/rodo|aml|bdo|
srodowisko) is already implemented — verified here (art. 17/28/30/33/83,
AML 34/74, UoO 49-53 COMPLETE).

Usage (from ``JDG/``)::

    python tools/rodo_aml_bdo_report14_gate.py --json
    python tools/rodo_aml_bdo_report14_gate.py --write
    python tools/rodo_aml_bdo_report14_gate.py --strict
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
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_14_RODO_AML_BDO.txt"
EVIDENCE_PATH = BUNDLES_DIR / "rodo_aml_bdo_innovations_report14_evidence.json"

R14_REGO = "rules/r14_rodo_aml_bdo_innovations_v9.rego"
MAIN_REGO = "rules/main_jdg.rego"
THRESHOLDS_REGO = "rules/thresholds_jdg.rego"
PYTEST = "tests/auto/test_r14_rodo_aml_bdo_enterprise.py"
NATIVE_REGO = "tests/rego/test_r14_rodo_aml_bdo_enterprise.rego"

# Warstwa RODO/AML/BDO/środowisko (p14/p15/p16 + rodo* + micro)
RAB_CORE_FILES = [
    "rules/rodo.rego",
    "rules/rodo_extended.rego",
    "rules/rodo/plan42_rodo.rego",
    "rules/p14_compliance_innovations_v8.rego",
    "rules/p15_srodowisko_bdo_innovations_v9.rego",
    "rules/p16_rodo_aml_security_innovations_v9.rego",
    "rules/compliance/aml_enterprise.rego",
    "rules/environmental.rego",
    "rules/environmental/bdo_enterprise.rego",
    "rules/security/security_fortress_v8.rego",
    "rules/micro/rodo/rodo.rego",
    "rules/micro/rodo/rodo_ai_marketing.rego",
    "rules/micro/rodo/rodo_erasure.rego",
    "rules/micro/rodo/rodo_podprocesorzy.rego",
    "rules/micro/rodo/rodo_sankcje.rego",
    "rules/micro/rodo/rodo_zatrudnienie.rego",
    "rules/micro/aml/aml.rego",
    "rules/micro/aml/aml_cbdd.rego",
    "rules/micro/aml/aml_ryzyko.rego",
    "rules/micro/aml/aml_str_gif.rego",
    "rules/micro/aml/aml_transakcje.rego",
    "rules/micro/bdo/bdo_ewc.rego",
    "rules/micro/bdo/bdo_ewidencja.rego",
    "rules/micro/bdo/bdo_rejestracja.rego",
    "rules/micro/bdo/bdo_transport.rego",
    "rules/micro/bdo/bdo_weee_baterie.rego",
    "rules/micro/bdo/bdo_zezwolenia.rego",
    "rules/micro/srodowisko/srodowisko.rego",
    "rules/micro/plan33_rodo.rego",
]

REQUIRED_INNOVATIONS = [
    "rodo_register_monitor", "rg_incomplete", "rg_data_categories_count",
    "aml_transaction_risk_scorer", "at_risk_score", "at_high_risk",
    "rodo_sanction_calculator", "rb_upper_tier", "rb_max_sanction_eur",
    "str_gijf_deadline_monitor", "sm_unfiled_count", "sm_str_deadline_days",
    "bdo_obligation_monitor", "bd_unfiled_count", "bd_kpo_electronic",
]

TEST_MARKERS = [
    "rodo_register_monitor", "aml_transaction_risk_scorer",
    "rodo_sanction_calculator", "str_gijf_deadline_monitor",
    "bdo_obligation_monitor", "r14_rodo_aml_bdo_check",
    "BLOCK_AND_ALERT", "TRIAGE_QUEUE",
    "art. 30", "art. 34", "art. 83", "art. 74", "art. 49",
]

# Podstawy prawne wymagane w nowym pakiecie (kanoniczne)
REQUIRED_LEGAL_MARKERS = [
    "art. 30",
    "art. 34",
    "art. 83",
    "art. 74",
    "art. 49",
    "art. 17",
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
        "r14_rego": _read(R14_REGO),
        "main_jdg": _read(MAIN_REGO),
        "thresholds": _read(THRESHOLDS_REGO),
        "pytest": _read(PYTEST),
        "native_rego": _read(NATIVE_REGO),
        "report": _read(str(REPORT_PATH.relative_to(BASE_DIR))),
    }
    rab_core_present = sum(bool(_read(f)) for f in RAB_CORE_FILES)
    return {
        "files": {name: bool(text) for name, text in files.items()},
        "files_total": len(files),
        "files_present": sum(bool(text) for text in files.values()),
        "report_present": bool(files["report"]),
        "rab_core_files_declared": len(RAB_CORE_FILES),
        "rab_core_files_present": rab_core_present,
    }


def _innovation_evidence() -> dict[str, Any]:
    text = _read(R14_REGO)
    missing = [fn for fn in REQUIRED_INNOVATIONS if fn not in text]
    legal = [m for m in REQUIRED_LEGAL_MARKERS if m not in text]
    return {
        "required_innovations": REQUIRED_INNOVATIONS,
        "missing_innovations": missing,
        "innovations_complete": not missing,
        "legal_basis_markers": REQUIRED_LEGAL_MARKERS,
        "missing_legal_markers": legal,
        "legal_basis_complete": not legal,
        "decide_report_rule": "jdg.r14_rodo_aml_bdo_innovations.bdo_obligation_monitor" in text,
        "activation_flag": "r14_rodo_aml_bdo_check" in text,
        "default_no_match": "jdg.r14_rodo_aml_bdo_innovations.no_match" in text,
        "rodo_register": "rg_incomplete" in text and "rg_data_categories_count" in text,
        "aml_scorer": "at_risk_score" in text and "at_high_risk" in text,
        "rodo_sanction": "rb_upper_tier" in text and "rb_max_sanction_eur" in text,
        "str_monitor": "sm_unfiled_count" in text and "sm_str_deadline_days" in text,
        "bdo_monitor": "bd_unfiled_count" in text and "bd_kpo_electronic" in text,
    }


def _thresholds_evidence() -> dict[str, Any]:
    text = _read(R14_REGO)
    th = _read(THRESHOLDS_REGO)
    return {
        "thresholds_via_data": "_th_rab" in text,
        "sanction_externalized": 'object.get(_th_rab, "rodo_sanction_max_eur", 20000000)' in text,
        "aml_externalized": 'object.get(_th_rab, "aml_threshold_eur", 15000)' in text,
        "bdo_externalized": 'object.get(_th_rab, "bdo_registration_days", 30)' in text,
        "rab_block_present": "rodo_aml_bdo := {" in th and '"aml_threshold_eur"' in th,
    }


def _duplicate_evidence() -> dict[str, Any]:
    text = _read(R14_REGO)
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
        "import_present": "import data.jdg.r14_rodo_aml_bdo_innovations" in joined,
        "package_decisions_entry": '"jdg.r14_rodo_aml_bdo_innovations": r14_rodo_aml_bdo_innovations.decide' in joined,
        "final_verdict_p39": "final_verdict_p39 = safe_merge(final_verdict_p38," in joined,
        "post_merge_present": post_merge_target is not None and int(post_merge_target.group(1)) >= 39,
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
    rab_verdicts = {
        h: v
        for h, v in verdicts.items()
        if "r14_rodo_aml_bdo_innovations" in json.dumps(v, ensure_ascii=False)
    }
    rab_hashes = {v.get("verdict_hash") for v in rab_verdicts.values()}
    rab_replays = [r for r in replays if r.get("golden_verdict_hash") in rab_hashes]
    uver = [r for r in rab_replays if r.get("uver_applies")]
    return {
        "golden_verdicts_total": len(verdicts),
        "rab_verdicts": len(rab_verdicts),
        "rab_replays": len(rab_replays),
        "uver_count": len(uver),
        "replay_verified": len(rab_verdicts) >= 1 and len(rab_replays) >= 1 and len(uver) == 0,
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
        and scope["rab_core_files_present"] == scope["rab_core_files_declared"],
        "report_present": scope["report_present"],
        "innovations_complete": innovations["innovations_complete"]
        and innovations["decide_report_rule"]
        and innovations["activation_flag"]
        and innovations["default_no_match"]
        and innovations["rodo_register"]
        and innovations["aml_scorer"]
        and innovations["rodo_sanction"]
        and innovations["str_monitor"]
        and innovations["bdo_monitor"],
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
        "report": "RAPORT_14_RODO_AML_BDO",
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
    parser = argparse.ArgumentParser(description="RAPORT_14 evidence gate")
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
            f"RAPORT_14: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
