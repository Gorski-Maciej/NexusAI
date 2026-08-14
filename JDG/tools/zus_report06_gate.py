#!/usr/bin/env python3
"""RAPORT_06 ZUS/SUS — evidence gate.

Mirrors tools/pit_enterprise_report05_gate.py .. enterprise_ai_report17_gate.py.
Prompt 06/25 (ZUS/SUS — składki, ulgi (start/preferencyjny/Mały ZUS+),
zdrowotna, zasiłki, PPK/PFRON, HR) is implemented as the R06 ZUS
innovations package:

  R06-INN-01 health_whatif_4form — kalkulator składki zdrowotnej 4-formowy
                                    (skala 9% / liniowy 4,9% / ryczałt 4,9%
                                    z progami 60/100/180% / karta 9%)
  R06-INN-02 zus_relief_tracker  — tracker ulg ZUS (art. 18a/18c) z alarmami
                                    terminów (start 6m / preferencyjny 24m /
                                    Mały ZUS+ 36m)
  R06-INN-03 sus_a6a             — domknięcie pustyni zus_micro_inventory
                                    (art. 6a MISSING — opieka nad dzieckiem)

Plus wiring in main_jdg.rego (final_verdict_p31), golden verdict + replay
and tests (pytest + native Rego). The ZUS layer (zus.rego, zus/*,
micro/sus, micro/zdrowotna, micro/zasilkowa, p07/p08 innovations, employer,
ppk_pfron, solidarity) is already implemented — verified here.

Usage (from ``JDG/``)::

    python tools/zus_report06_gate.py --json
    python tools/zus_report06_gate.py --write
    python tools/zus_report06_gate.py --strict
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
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_06_ZUS.txt"
EVIDENCE_PATH = BUNDLES_DIR / "zus_report06_evidence.json"

R06_REGO = "rules/r06_zus_innovations_v9.rego"
MAIN_REGO = "rules/main_jdg.rego"
PYTEST = "tests/auto/test_r06_zus_enterprise.py"
NATIVE_REGO = "tests/rego/test_r06_zus_enterprise.rego"

# Warstwa ZUS (P07/P08 + zus/* + micro) — weryfikowana
ZUS_CORE_FILES = [
    "rules/zus.rego",
    "rules/employer.rego",
    "rules/mpips.rego",
    "rules/ppk_pfron_enterprise.rego",
    "rules/solidarity_auto_calc_enterprise.rego",
    "rules/insurance_tracker_enterprise.rego",
    "rules/p19_hr_swiadczenia_innovations_v9.rego",
    "rules/zus/health_contribution_enterprise.rego",
    "rules/zus/health_precision_engine_v8.rego",
    "rules/zus/cumulative_revenue_engine.rego",
    "rules/zus/zus_extensions_enterprise.rego",
    "rules/zus/sickness_benefits_enterprise.rego",
    "rules/p07_zus_macro_innovations_v9.rego",
    "rules/p08_zus_macro_enterprise_v9.rego",
    "rules/p08_zus_micro_innovations_v9.rego",
    "rules/micro/sus/sus.rego",
    "rules/micro/zdrowotna/zdrowotna.rego",
    "rules/micro/zasilkowa/zasilkowa.rego",
]

REQUIRED_INNOVATIONS = [
    "health_whatif_4form", "scale_annual", "linear_annual", "lump_annual",
    "card_annual", "best_form", "lump_base_multiplier",
    "zus_relief_tracker", "remaining_months", "EXPIRING", "EXPIRED",
    "ULGA_START", "PREFERENCYJNY", "MALY_ZUS_PLUS",
    "sus_a6a", "personal_child_care", "other_parent_insured",
]

TEST_MARKERS = [
    "health_whatif_4form", "zus_relief_tracker", "sus_a6a",
    "ULGA_START", "MALY_ZUS_PLUS", "best_form", "r06_zus_check",
]

# Podstawy prawne wymagane w nowym pakiecie (kanoniczne)
REQUIRED_LEGAL_MARKERS = [
    "Art. 81 ustawy o świadczeniach opieki zdrowotnej (Dz.U. 2025 poz. 890)",
    "Art. 18a i 18c ustawy o SUS (Dz.U. 2025 poz. 345)",
    "Art. 6a ust. 1-3 ustawy o SUS (Dz.U. 2025 poz. 345)",
    "rozp. MPiPS ws. podstawy wymiaru (2025-12-30)",
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
        "r06_rego": _read(R06_REGO),
        "main_jdg": _read(MAIN_REGO),
        "pytest": _read(PYTEST),
        "native_rego": _read(NATIVE_REGO),
        "report": _read(str(REPORT_PATH.relative_to(BASE_DIR))),
    }
    zus_core_present = sum(bool(_read(f)) for f in ZUS_CORE_FILES)
    return {
        "files": {name: bool(text) for name, text in files.items()},
        "files_total": len(files),
        "files_present": sum(bool(text) for text in files.values()),
        "report_present": bool(files["report"]),
        "zus_core_files_declared": len(ZUS_CORE_FILES),
        "zus_core_files_present": zus_core_present,
    }


def _innovation_evidence() -> dict[str, Any]:
    text = _read(R06_REGO)
    missing = [fn for fn in REQUIRED_INNOVATIONS if fn not in text]
    legal = [m for m in REQUIRED_LEGAL_MARKERS if m not in text]
    return {
        "required_innovations": REQUIRED_INNOVATIONS,
        "missing_innovations": missing,
        "innovations_complete": not missing,
        "legal_basis_markers": REQUIRED_LEGAL_MARKERS,
        "missing_legal_markers": legal,
        "legal_basis_complete": not legal,
        "decide_report_rule": "jdg.r06_zus_innovations.zus_report" in text,
        "activation_flag": "r06_zus_check" in text,
        "default_no_match": "jdg.r06_zus_innovations.no_match" in text,
        "four_form_comparator": "card_annual" in text and "lump_base_multiplier" in text,
        "desert_a6a_closed": "sus_a6a" in text and "personal_child_care" in text,
    }


def _thresholds_evidence() -> dict[str, Any]:
    text = _read(R06_REGO)
    return {
        "thresholds_via_data": "_th_zus" in text,
        "rates_externalized": "health_linear_rate" in text and "health_lump_rate" in text and "health_card_rate" in text,
        "deduction_limit_externalized": 'object.get(_th_zus, "health_linear_deduction_limit", 14100)' in text,
        "relief_months_externalized": 'object.get(_th_zus, "ulga_start_months", 6)' in text and 'object.get(_th_zus, "maly_zus_plus_months", 36)' in text,
    }


def _duplicate_evidence() -> dict[str, Any]:
    text = _read(R06_REGO)
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
    # POST-MERGE cel zmienia się wraz z kolejnymi raportami (p30 → p31 → p32…).
    post_merge_target = re.search(
        r"final_verdict_post_merge = object\.union\(final_verdict_p(\d+)", joined
    )
    return {
        "import_present": "import data.jdg.r06_zus_innovations" in joined,
        "package_decisions_entry": '"jdg.r06_zus_innovations": r06_zus_innovations.decide' in joined,
        "final_verdict_p31": "final_verdict_p31 = safe_merge(final_verdict_p30," in joined,
        "post_merge_present": post_merge_target is not None and int(post_merge_target.group(1)) >= 31,
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
    zus_verdicts = {
        h: v
        for h, v in verdicts.items()
        if "r06_zus_innovations" in json.dumps(v, ensure_ascii=False)
    }
    zus_hashes = {v.get("verdict_hash") for v in zus_verdicts.values()}
    zus_replays = [r for r in replays if r.get("golden_verdict_hash") in zus_hashes]
    uver = [r for r in zus_replays if r.get("uver_applies")]
    return {
        "golden_verdicts_total": len(verdicts),
        "zus_verdicts": len(zus_verdicts),
        "zus_replays": len(zus_replays),
        "uver_count": len(uver),
        "replay_verified": len(zus_verdicts) >= 1 and len(zus_replays) >= 1 and len(uver) == 0,
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
        and scope["zus_core_files_present"] == scope["zus_core_files_declared"],
        "report_present": scope["report_present"],
        "innovations_complete": innovations["innovations_complete"]
        and innovations["decide_report_rule"]
        and innovations["activation_flag"]
        and innovations["default_no_match"]
        and innovations["four_form_comparator"]
        and innovations["desert_a6a_closed"],
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
        "report": "RAPORT_06_ZUS",
        "status": status,
        "gates": gates,
        "gate_summary": {"passed": passed, "total": total},
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
    parser = argparse.ArgumentParser(description="RAPORT_06 evidence gate")
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
            f"RAPORT_06: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
