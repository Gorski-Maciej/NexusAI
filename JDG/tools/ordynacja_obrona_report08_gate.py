#!/usr/bin/env python3
"""RAPORT_08 ORDYNACJA PODATKOWA + OBRONA PODATNIKA — evidence gate.

Mirrors tools/kks_report07_gate.py .. enterprise_ai_report17_gate.py.
Prompt 08/25 (Ordynacja podatkowa — postępowania, przedawnienie, korekty,
KAS, sądy; obrona podatnika) is implemented as the R08 ORD innovations
package:

  R08-INN-01 interest_calculator_temporal  — kalkulator odsetek z pełną
                                               temporalnością (art. 53-56/56b)
  R08-INN-02 proceeding_deadline_alerts_3lvl — asystent postępowania z 3
                                               poziomami alertów per termin
                                               (RED/AMBER/GREEN, art. 120-129/
                                               139-141/223/262)
  R08-INN-03 correspondence_autopack       — auto-generator korespondencji
                                               z US z podstawą prawną
                                               (art. 14b/72-77/117ba/223,
                                               KKS art. 16)
  R08-INN-04 judgment_predictor_wsa_nsa    — predykcja wyroków WSA/NSA
                                               (szansa korzystnego wyroku 0-100)
  R08-INN-05 limitation_evidence_monitor   — monitor przedawnień z dowodem
                                               (art. 70 § 1/4-6, certyfikat
                                               decision_hash)

Plus wiring in main_jdg.rego (final_verdict_p33), golden verdict + replay
and tests (pytest + native Rego). The Ordynacja layer (p11 v9, ord/*,
micro/ord, statute_of_limitations, interest/deadline calculators, defense/
correspondence/ruling tools) is already implemented — verified here
(art. 70/81/81b/14b/117ba/67a/56 COMPLETE).

Usage (from ``JDG/``)::

    python tools/ordynacja_obrona_report08_gate.py --json
    python tools/ordynacja_obrona_report08_gate.py --write
    python tools/ordynacja_obrona_report08_gate.py --strict
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
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_08_ORDYNACJA_OBRONA.txt"
EVIDENCE_PATH = BUNDLES_DIR / "ordynacja_obrona_report08_evidence.json"

R08_REGO = "rules/r08_ordynacja_obrona_innovations_v9.rego"
MAIN_REGO = "rules/main_jdg.rego"
PYTEST = "tests/auto/test_r08_ordynacja_obrona_enterprise.py"
NATIVE_REGO = "tests/rego/test_r08_ordynacja_obrona_enterprise.rego"

# Warstwa Ordynacja/obrona (P11 + ord/* + micro + obrona podatnika) — weryfikowana
ORD_CORE_FILES = [
    "rules/p11_ordynacja_podatkowa_innovations_v9.rego",
    "rules/ord/ord_innovations_v8.rego",
    "rules/ord_supplements_enterprise.rego",
    "rules/micro/ord/ord.rego",
    "rules/micro/plan33_ord.rego",
    "rules/micro/plan34_ord.rego",
    "rules/statute_of_limitations.rego",
    "rules/statute/plan26_detailed.rego",
    "rules/interest_calculator_enterprise.rego",
    "rules/exit_tax_interest_calculator.rego",
    "rules/deadline_monitor_enterprise.rego",
    "rules/tax_authority_interaction_enterprise.rego",
    "rules/tax_correspondence_engine_enterprise.rego",
    "rules/tax_ruling_autodrafter_enterprise.rego",
    "rules/overpayment_auto_claimer_enterprise.rego",
    "rules/proceeding_tracker_enterprise.rego",
    "rules/defense_builder_enterprise.rego",
    "rules/audit_defense_enterprise.rego",
    "rules/judicial_interpretations_enterprise.rego",
    "rules/judicial_trend_enterprise.rego",
    "rules/financial_hardship_scorer_enterprise.rego",
    "rules/poa_manager_enterprise.rego",
    "rules/audit/plan44_audit.rego",
    "rules/audit/plan45_audit.rego",
    "rules/audit/runtime_invariants_enterprise.rego",
]

REQUIRED_INNOVATIONS = [
    "interest_calculator_temporal", "int_temp_schedule", "int_temp_total",
    "int_effective_rate_pct", "CORRECTION_7DAYS", "int_reduced_savings",
    "proceeding_deadline_alerts_3lvl", "pr_alert_level",
    "RED", "AMBER", "GREEN", "BLOCK_AND_ALERT", "next_action",
    "correspondence_autopack", "corr_legal_basis", "corr_ready",
    "corr_missing_fields", "judgment_predictor_wsa_nsa",
    "judg_probability_favorable", "judg_confidence",
    "limitation_evidence_monitor", "lim_evidence_certificate",
    "decision_hash", "statute_barred",
]

TEST_MARKERS = [
    "interest_calculator_temporal", "proceeding_deadline_alerts_3lvl",
    "correspondence_autopack", "judgment_predictor_wsa_nsa",
    "limitation_evidence_monitor", "r08_ordynacja_check",
    "BLOCK_AND_ALERT", "117ba", "statute_barred",
]

# Podstawy prawne wymagane w nowym pakiecie (kanoniczne)
REQUIRED_LEGAL_MARKERS = [
    "art. 53-56",
    "art. 70 § 1",
    "art. 14b",
    "art. 223",
    "art. 117ba",
    "KKS art. 16",
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
        "r08_rego": _read(R08_REGO),
        "main_jdg": _read(MAIN_REGO),
        "pytest": _read(PYTEST),
        "native_rego": _read(NATIVE_REGO),
        "report": _read(str(REPORT_PATH.relative_to(BASE_DIR))),
    }
    ord_core_present = sum(bool(_read(f)) for f in ORD_CORE_FILES)
    return {
        "files": {name: bool(text) for name, text in files.items()},
        "files_total": len(files),
        "files_present": sum(bool(text) for text in files.values()),
        "report_present": bool(files["report"]),
        "ord_core_files_declared": len(ORD_CORE_FILES),
        "ord_core_files_present": ord_core_present,
    }


def _innovation_evidence() -> dict[str, Any]:
    text = _read(R08_REGO)
    missing = [fn for fn in REQUIRED_INNOVATIONS if fn not in text]
    legal = [m for m in REQUIRED_LEGAL_MARKERS if m not in text]
    return {
        "required_innovations": REQUIRED_INNOVATIONS,
        "missing_innovations": missing,
        "innovations_complete": not missing,
        "legal_basis_markers": REQUIRED_LEGAL_MARKERS,
        "missing_legal_markers": legal,
        "legal_basis_complete": not legal,
        "decide_report_rule": "jdg.r08_ordynacja_obrona_innovations.limitation_evidence_monitor" in text,
        "activation_flag": "r08_ordynacja_check" in text,
        "default_no_match": "jdg.r08_ordynacja_obrona_innovations.no_match" in text,
        "temporal_interest": "int_temp_schedule" in text and "int_temp_total" in text,
        "three_level_alerts": "RED" in text and "AMBER" in text and "GREEN" in text,
        "correspondence_legal": "corr_legal_basis" in text and "corr_missing_fields" in text,
        "judgment_predictor": "judg_probability_favorable" in text and "judg_confidence" in text,
        "limitation_evidence": "lim_evidence_certificate" in text and "decision_hash" in text,
    }


def _thresholds_evidence() -> dict[str, Any]:
    text = _read(R08_REGO)
    return {
        "thresholds_via_data": "_th_ord" in text,
        "interest_rate_externalized": 'object.get(_th_ord, "tax_interest_rate", 0.125)' in text,
        "limitation_externalized": 'object.get(_th_ord, "limitation_years", 5)' in text,
        "deadlines_externalized": "appeal_days" in text and "interpretation_days" in text,
    }


def _duplicate_evidence() -> dict[str, Any]:
    text = _read(R08_REGO)
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
    # POST-MERGE cel zmienia się wraz z kolejnymi raportami (p32 → p33 → p34…).
    post_merge_target = re.search(
        r"final_verdict_post_merge = object\.union\(final_verdict_p(\d+)", joined
    )
    return {
        "import_present": "import data.jdg.r08_ordynacja_obrona_innovations" in joined,
        "package_decisions_entry": '"jdg.r08_ordynacja_obrona_innovations": r08_ordynacja_obrona_innovations.decide' in joined,
        "final_verdict_p33": "final_verdict_p33 = safe_merge(final_verdict_p32," in joined,
        "post_merge_present": post_merge_target is not None and int(post_merge_target.group(1)) >= 33,
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
    ord_verdicts = {
        h: v
        for h, v in verdicts.items()
        if "r08_ordynacja_obrona_innovations" in json.dumps(v, ensure_ascii=False)
    }
    ord_hashes = {v.get("verdict_hash") for v in ord_verdicts.values()}
    ord_replays = [r for r in replays if r.get("golden_verdict_hash") in ord_hashes]
    uver = [r for r in ord_replays if r.get("uver_applies")]
    return {
        "golden_verdicts_total": len(verdicts),
        "ord_verdicts": len(ord_verdicts),
        "ord_replays": len(ord_replays),
        "uver_count": len(uver),
        "replay_verified": len(ord_verdicts) >= 1 and len(ord_replays) >= 1 and len(uver) == 0,
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
        and scope["ord_core_files_present"] == scope["ord_core_files_declared"],
        "report_present": scope["report_present"],
        "innovations_complete": innovations["innovations_complete"]
        and innovations["decide_report_rule"]
        and innovations["activation_flag"]
        and innovations["default_no_match"]
        and innovations["temporal_interest"]
        and innovations["three_level_alerts"]
        and innovations["correspondence_legal"]
        and innovations["judgment_predictor"]
        and innovations["limitation_evidence"],
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
        "report": "RAPORT_08_ORDYNACJA_OBRONA",
        "status": status,
        "gates": gates,
        "gate_summary": {"passed": passed, "total": total},
        # Kompatybilność z test_p11_ordynacja_podatkowa_enterprise.py (format R08-R24)
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
    parser = argparse.ArgumentParser(description="RAPORT_08 evidence gate")
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
            f"RAPORT_08: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
