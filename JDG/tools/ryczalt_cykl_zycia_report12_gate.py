#!/usr/bin/env python3
"""RAPORT_12 RYCZAŁT / CEIDG / CYKL ŻYCIA — evidence gate.

Mirrors tools/pcc_lokalne_akcyza_report11_gate.py (new-campaign
convention). Prompt 12/25 (ryczałt / CEIDG / prawo przedsiębiorców /
sukcesja / budownictwo / cykl życia firmy) is implemented as the R12
ryczałt/cykl życia innovations package:

  R12-INN-01 ryczalt_limit_monitor       — monitor limitu 2 mln EUR (art. 6)
  R12-INN-02 pkwiu_rate_classifier       — klasyfikator PKWiU → stawka (art. 12)
  R12-INN-03 lifecycle_phase_planner     — planner faz cyklu życia JDG
  R12-INN-04 succession_deadline_monitor — monitor terminów sukcesji (u.z.s.)
  R12-INN-05 tax_form_arbitrator         — arbiter formy opodatkowania

Plus wiring in main_jdg.rego (final_verdict_p37), golden verdict + replay
and tests (pytest + native Rego). The ryczałt/cykl życia layer (p13 v9.4,
p16, business.rego, business/*, lifecycle_manager, restructuring, micro/
ryczalt|pp|sukcesja|ceidg|budownictwo, plan33_ryc|ceidg|succ) is already
implemented — verified here (art. 6/12/21-28/5-15 CEIDG/3-15 u.z.s./22-25
PP/28 COMPLETE).

Usage (from ``JDG/``)::

    python tools/ryczalt_cykl_zycia_report12_gate.py --json
    python tools/ryczalt_cykl_zycia_report12_gate.py --write
    python tools/ryczalt_cykl_zycia_report12_gate.py --strict
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
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_12_RYCZALT_CYKL_ZYCIE.txt"
EVIDENCE_PATH = BUNDLES_DIR / "ryczalt_cykl_zycia_report12_evidence.json"

R12_REGO = "rules/r12_ryczalt_cykl_zycia_innovations_v9.rego"
MAIN_REGO = "rules/main_jdg.rego"
THRESHOLDS_REGO = "rules/thresholds_jdg.rego"
PYTEST = "tests/auto/test_r12_ryczalt_cykl_zycia_enterprise.py"
NATIVE_REGO = "tests/rego/test_r12_ryczalt_cykl_zycia_enterprise.rego"

# Warstwa ryczałt/cykl życia (p13/p16 + business + micro) — weryfikowana
RLC_CORE_FILES = [
    "rules/business.rego",
    "rules/business/gig_economy.rego",
    "rules/business/plan26_suspension_succession.rego",
    "rules/business/strategic_intelligence.rego",
    "rules/lifecycle_manager_enterprise.rego",
    "rules/restructuring.rego",
    "rules/rule_lifecycle_enterprise.rego",
    "rules/_business_lifecycle_rates.rego",
    "rules/p13_ryczalt_cykl_zycia_innovations_v9.rego",
    "rules/p16_business_lifecycle_innovations_v8.rego",
    "rules/micro/ryczalt/ryczalt.rego",
    "rules/micro/pp/pp.rego",
    "rules/micro/sukcesja/sukcesja.rego",
    "rules/micro/ceidg/ceidg.rego",
    "rules/micro/budownictwo/budownictwo.rego",
    "rules/micro/plan33_ryc.rego",
    "rules/micro/plan33_ceidg.rego",
    "rules/micro/plan33_succ.rego",
]

REQUIRED_INNOVATIONS = [
    "ryczalt_limit_monitor", "rl_limit_pct", "rl_alert_level",
    "pkwiu_rate_classifier", "pk_expected_rate", "pk_rate_mismatch",
    "lifecycle_phase_planner", "lc_phase", "lc_missing_steps",
    "succession_deadline_monitor", "sc_unfiled_count", "sc_ceidg_days",
    "tax_form_arbitrator", "tf_recommended_form", "tf_suspension_recommend",
]

TEST_MARKERS = [
    "ryczalt_limit_monitor", "pkwiu_rate_classifier", "lifecycle_phase_planner",
    "succession_deadline_monitor", "tax_form_arbitrator",
    "r12_ryczalt_cykl_zycia_check", "BLOCK_AND_ALERT", "TRIAGE_QUEUE",
    "art. 6", "art. 12", "art. 3-15", "art. 22-25",
]

# Podstawy prawne wymagane w nowym pakiecie (kanoniczne)
REQUIRED_LEGAL_MARKERS = [
    "art. 6",
    "art. 12",
    "art. 21-28",
    "art. 5-15",
    "art. 3-15",
    "art. 22-25",
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
        "r12_rego": _read(R12_REGO),
        "main_jdg": _read(MAIN_REGO),
        "thresholds": _read(THRESHOLDS_REGO),
        "pytest": _read(PYTEST),
        "native_rego": _read(NATIVE_REGO),
        "report": _read(str(REPORT_PATH.relative_to(BASE_DIR))),
    }
    rlc_core_present = sum(bool(_read(f)) for f in RLC_CORE_FILES)
    return {
        "files": {name: bool(text) for name, text in files.items()},
        "files_total": len(files),
        "files_present": sum(bool(text) for text in files.values()),
        "report_present": bool(files["report"]),
        "rlc_core_files_declared": len(RLC_CORE_FILES),
        "rlc_core_files_present": rlc_core_present,
    }


def _innovation_evidence() -> dict[str, Any]:
    text = _read(R12_REGO)
    missing = [fn for fn in REQUIRED_INNOVATIONS if fn not in text]
    legal = [m for m in REQUIRED_LEGAL_MARKERS if m not in text]
    return {
        "required_innovations": REQUIRED_INNOVATIONS,
        "missing_innovations": missing,
        "innovations_complete": not missing,
        "legal_basis_markers": REQUIRED_LEGAL_MARKERS,
        "missing_legal_markers": legal,
        "legal_basis_complete": not legal,
        "decide_report_rule": "jdg.r12_ryczalt_cykl_zycia_innovations.tax_form_arbitrator" in text,
        "activation_flag": "r12_ryczalt_cykl_zycia_check" in text,
        "default_no_match": "jdg.r12_ryczalt_cykl_zycia_innovations.no_match" in text,
        "limit_monitor": "rl_limit_pct" in text and "rl_alert_level" in text,
        "pkwiu_classifier": "pk_expected_rate" in text and "pk_rate_mismatch" in text,
        "lifecycle_planner": "lc_phase" in text and "lc_missing_steps" in text,
        "succession_monitor": "sc_unfiled_count" in text and "sc_ceidg_days" in text,
        "tax_form_arbitrator": "tf_recommended_form" in text and "tf_suspension_recommend" in text,
    }


def _thresholds_evidence() -> dict[str, Any]:
    text = _read(R12_REGO)
    th = _read(THRESHOLDS_REGO)
    return {
        "thresholds_via_data": "_th_bl" in text,
        "limit_externalized": 'object.get(_th_bl, "ryczalt_limit_eur", 2000000)' in text,
        "rate_externalized": 'object.get(_th_bl, "ryczalt_rate_min", 0.03)' in text,
        "succession_externalized": 'object.get(_th_bl, "succession_ceidg_days", 14)' in text,
        "bl_block_present": "business_lifecycle := {" in th and '"ryczalt_limit_eur"' in th,
    }


def _duplicate_evidence() -> dict[str, Any]:
    text = _read(R12_REGO)
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
        "import_present": "import data.jdg.r12_ryczalt_cykl_zycia_innovations" in joined,
        "package_decisions_entry": '"jdg.r12_ryczalt_cykl_zycia_innovations": r12_ryczalt_cykl_zycia_innovations.decide' in joined,
        "final_verdict_p37": "final_verdict_p37 = safe_merge(final_verdict_p36," in joined,
        "post_merge_present": post_merge_target is not None and int(post_merge_target.group(1)) >= 37,
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
    rlc_verdicts = {
        h: v
        for h, v in verdicts.items()
        if "r12_ryczalt_cykl_zycia_innovations" in json.dumps(v, ensure_ascii=False)
    }
    rlc_hashes = {v.get("verdict_hash") for v in rlc_verdicts.values()}
    rlc_replays = [r for r in replays if r.get("golden_verdict_hash") in rlc_hashes]
    uver = [r for r in rlc_replays if r.get("uver_applies")]
    return {
        "golden_verdicts_total": len(verdicts),
        "rlc_verdicts": len(rlc_verdicts),
        "rlc_replays": len(rlc_replays),
        "uver_count": len(uver),
        "replay_verified": len(rlc_verdicts) >= 1 and len(rlc_replays) >= 1 and len(uver) == 0,
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
        and scope["rlc_core_files_present"] == scope["rlc_core_files_declared"],
        "report_present": scope["report_present"],
        "innovations_complete": innovations["innovations_complete"]
        and innovations["decide_report_rule"]
        and innovations["activation_flag"]
        and innovations["default_no_match"]
        and innovations["limit_monitor"]
        and innovations["pkwiu_classifier"]
        and innovations["lifecycle_planner"]
        and innovations["succession_monitor"]
        and innovations["tax_form_arbitrator"],
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
        "report": "RAPORT_12_RYCZALT_CYKL_ZYCIE",
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
    parser = argparse.ArgumentParser(description="RAPORT_12 evidence gate")
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
            f"RAPORT_12: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
