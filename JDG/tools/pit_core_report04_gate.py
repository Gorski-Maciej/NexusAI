#!/usr/bin/env python3
"""RAPORT_04 PIT — CORE (MACRO) + ULGI — evidence gate.

Mirrors tools/vat_micro_report03_gate.py .. enterprise_ai_report17_gate.py.
Prompt 04/25 (PIT — CORE (MACRO) + ULGI — skala, liniowy, KUP, NKUP,
amortyzacja, ulgi Art. 21–26h, IP Box) is implemented as the R04 PIT
core-innovations package:

  R04-INN-01 relief_whatif_simulator         — 3-drogowy symulator „co by było
                                               gdyby": B+R (26e) vs IP Box (30ca)
                                               vs robotyzacja (26gb)
  R04-INN-02 amortization_one_off_100k       — jednorazowa amortyzacja art. 22k
                                               ust. 7-12 (mały podatnik, 100k)
  R04-INN-03 low_value_asset_amortization    — niskocenne środki trwałe art. 22f
                                               ust. 3 (próg 10 000 zł)
  R04-INN-04 health_contribution_optimizer   — kalkulator optymalnej składki
                                               zdrowotnej wg formy

Plus wiring in main_jdg.rego (final_verdict_p29), golden verdict + replay
and tests (pytest + native Rego). The PIT core/macro layer (forms, KUP/NKUP,
amortyzacja, ulgi 26e/26h/30ca, PIT-0 art. 21 pkt 148-154, straty, P05/P06
innowacje) is already implemented — verified here.

Usage (from ``JDG/``)::

    python tools/pit_core_report04_gate.py --json
    python tools/pit_core_report04_gate.py --write
    python tools/pit_core_report04_gate.py --strict
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
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_04_PIT_CORE.txt"
EVIDENCE_PATH = BUNDLES_DIR / "pit_core_report04_evidence.json"

R04_REGO = "rules/r04_pit_core_innovations_v9.rego"
MAIN_REGO = "rules/main_jdg.rego"
PYTEST = "tests/auto/test_r04_pit_core_enterprise.py"
NATIVE_REGO = "tests/rego/test_r04_pit_core_enterprise.rego"

# Warstwa PIT Core/Macro (P04-P07 + rules/pit/* + allowances) — weryfikowana
PIT_CORE_FILES = [
    "rules/pit/forms.rego",
    "rules/pit/kup.rego",
    "rules/pit/kup_extended.rego",
    "rules/pit/exemptions.rego",
    "rules/pit/advances_returns.rego",
    "rules/pit/transitions.rego",
    "rules/pit/art21_exemptions_enterprise.rego",
    "rules/pit/ipbox_enterprise.rego",
    "rules/pit/rd_relief_enterprise.rego",
    "rules/pit/thermo_relief_enterprise.rego",
    "rules/pit/donation_relief_enterprise.rego",
    "rules/pit/cross_relief_optimizer_enterprise.rego",
    "rules/pit/tax_loss_harvesting_enterprise.rego",
    "rules/pit/tax_form_transition_intelligence.rego",
    "rules/pit/missing_reliefs_enterprise.rego",
    "rules/pit/declaration_extensions_enterprise.rego",
    "rules/allowances.rego",
    "rules/nkup_enterprise_complete.rego",
    "rules/p05_pit_macro_innovations_v9.rego",
    "rules/p06_pit_macro_enterprise_v9.rego",
    "rules/p07_pit_micro_atomic_v9.rego",
]

REQUIRED_INNOVATIONS = [
    "relief_whatif_simulator", "br_saving", "ipbox_saving", "robot_saving",
    "best_relief", "amortization_one_off_100k", "one_off_100k_limit",
    "low_value_asset_amortization", "low_value_threshold",
    "health_contribution_optimizer", "best_form", "health_scale", "health_lump",
]

TEST_MARKERS = [
    "relief_whatif_simulator", "amortization_one_off_100k",
    "low_value_asset_amortization", "health_contribution_optimizer",
    "ROBOTIZATION", "one_off_deduction", "best_form", "r04_pit_core_check",
]

# Podstawy prawne wymagane w nowym pakiecie (kanoniczne)
REQUIRED_LEGAL_MARKERS = [
    "Art. 22k ust. 7-12 PIT",
    "Art. 22f ust. 3 PIT",
    "Art. 26e + Art. 26gb + Art. 30ca PIT",
    "Art. 27, 30c PIT",
    "Dz.U. 2025 poz. 789",
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
        "r04_rego": _read(R04_REGO),
        "main_jdg": _read(MAIN_REGO),
        "pytest": _read(PYTEST),
        "native_rego": _read(NATIVE_REGO),
        "report": _read(str(REPORT_PATH.relative_to(BASE_DIR))),
    }
    pit_core_present = sum(bool(_read(f)) for f in PIT_CORE_FILES)
    return {
        "files": {name: bool(text) for name, text in files.items()},
        "files_total": len(files),
        "files_present": sum(bool(text) for text in files.values()),
        "report_present": bool(files["report"]),
        "pit_core_files_declared": len(PIT_CORE_FILES),
        "pit_core_files_present": pit_core_present,
    }


def _innovation_evidence() -> dict[str, Any]:
    text = _read(R04_REGO)
    missing = [fn for fn in REQUIRED_INNOVATIONS if fn not in text]
    legal = [m for m in REQUIRED_LEGAL_MARKERS if m not in text]
    return {
        "required_innovations": REQUIRED_INNOVATIONS,
        "missing_innovations": missing,
        "innovations_complete": not missing,
        "legal_basis_markers": REQUIRED_LEGAL_MARKERS,
        "missing_legal_markers": legal,
        "legal_basis_complete": not legal,
        "decide_report_rule": "jdg.r04_pit_core_innovations.pit_core_report" in text,
        "activation_flag": "r04_pit_core_check" in text,
        "default_no_match": "jdg.r04_pit_core_innovations.no_match" in text,
        "three_way_comparator": "robot_saving" in text and "best_relief" in text,
    }


def _thresholds_evidence() -> dict[str, Any]:
    text = _read(R04_REGO)
    return {
        "thresholds_via_data": "data.jdg.thresholds.pit" in text or "_th_pit" in text,
        "one_off_limit_externalized": 'object.get(_th_pit, "one_off_depreciation_limit", 100000)' in text,
        "low_value_externalized": 'object.get(_th_pit, "low_value_asset_threshold", 10000)' in text,
        "rates_externalized": "ipbox_rate" in text and "robotization_rate" in text,
    }


def _duplicate_evidence() -> dict[str, Any]:
    text = _read(R04_REGO)
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
    # POST-MERGE cel zmienia się wraz z kolejnymi raportami (p28 → p29 → p30…).
    # Bramka weryfikuje, że R04 jest wpięty (p29 istnieje) oraz że łańcuch
    # POST-MERGE kończy się na invariants + certyfikacie.
    post_merge_target = re.search(
        r"final_verdict_post_merge = object\.union\(final_verdict_p(\d+)", joined
    )
    return {
        "import_present": "import data.jdg.r04_pit_core_innovations" in joined,
        "package_decisions_entry": '"jdg.r04_pit_core_innovations": r04_pit_core_innovations.decide' in joined,
        "final_verdict_p29": "final_verdict_p29 = safe_merge(final_verdict_p28," in joined,
        "post_merge_present": post_merge_target is not None and int(post_merge_target.group(1)) >= 29,
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
    pit_verdicts = {
        h: v
        for h, v in verdicts.items()
        if "r04_pit_core_innovations" in json.dumps(v, ensure_ascii=False)
    }
    pit_hashes = {v.get("verdict_hash") for v in pit_verdicts.values()}
    pit_replays = [r for r in replays if r.get("golden_verdict_hash") in pit_hashes]
    uver = [r for r in pit_replays if r.get("uver_applies")]
    return {
        "golden_verdicts_total": len(verdicts),
        "pit_core_verdicts": len(pit_verdicts),
        "pit_core_replays": len(pit_replays),
        "uver_count": len(uver),
        "replay_verified": len(pit_verdicts) >= 1 and len(pit_replays) >= 1 and len(uver) == 0,
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
        and scope["pit_core_files_present"] == scope["pit_core_files_declared"],
        "report_present": scope["report_present"],
        "innovations_complete": innovations["innovations_complete"]
        and innovations["decide_report_rule"]
        and innovations["activation_flag"]
        and innovations["default_no_match"]
        and innovations["three_way_comparator"],
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
        "report": "RAPORT_04_PIT_CORE",
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
    parser = argparse.ArgumentParser(description="RAPORT_04 evidence gate")
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
            f"RAPORT_04: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
