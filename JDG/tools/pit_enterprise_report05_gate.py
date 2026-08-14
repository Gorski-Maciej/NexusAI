#!/usr/bin/env python3
"""RAPORT_05 PIT — ENTERPRISE — evidence gate.

Mirrors tools/pit_core_report04_gate.py .. enterprise_ai_report17_gate.py.
Prompt 05/25 (PIT — ENTERPRISE — deklaracje PIT-36/36L/28, estoński CIT,
exit tax, transformacje, optymalizacja) is implemented as the R05 PIT
enterprise-innovations package:

  R05-INN-01 annual_autopilot          — autopilot roczny z Decision
                                         Certificate (F4: decision_hash,
                                         bundle/rule/threshold wersje)
  R05-INN-02 form_transition_3y        — symulator formy z prognozą 3-letnią
                                         (skala/liniowy/ryczałt/estoński CIT)
  R05-INN-03 strategic_decision_score  — scoring decyzji strategicznych
                                         z podstawą prawną (0-100 + risk)
  R05-INN-04 jpk_harmonization         — harmonizacja deklaracji rocznej
                                         z JPK_CIT i JPK_V7M

Plus wiring in main_jdg.rego (final_verdict_p30), golden verdict + replay
and tests (pytest + native Rego). The PIT enterprise layer (annual_declaration,
estonian_cit, exit_tax_mdr, form_transition_simulator, tax_optimization,
decision_scoring, p16_autoform) is already implemented — verified here.

Usage (from ``JDG/``)::

    python tools/pit_enterprise_report05_gate.py --json
    python tools/pit_enterprise_report05_gate.py --write
    python tools/pit_enterprise_report05_gate.py --strict
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
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_05_PIT_ENTERPRISE.txt"
EVIDENCE_PATH = BUNDLES_DIR / "pit_enterprise_report05_evidence.json"

R05_REGO = "rules/r05_pit_enterprise_innovations_v9.rego"
MAIN_REGO = "rules/main_jdg.rego"
PYTEST = "tests/auto/test_r05_pit_enterprise_enterprise.py"
NATIVE_REGO = "tests/rego/test_r05_pit_enterprise_enterprise.rego"

# Warstwa PIT Enterprise (P05-P16 + enterprise) — weryfikowana
PIT_ENTERPRISE_FILES = [
    "rules/annual_declaration_enterprise.rego",
    "rules/form_transition_simulator_enterprise.rego",
    "rules/p16_autoform_generator_enterprise.rego",
    "rules/p16_estonian_cit_enterprise.rego",
    "rules/p16_entrepreneur_test_enterprise.rego",
    "rules/p16_enhanced_sca_enterprise.rego",
    "rules/exit_tax_mdr_enterprise.rego",
    "rules/tax_optimization_enterprise.rego",
    "rules/decision_scoring_enterprise.rego",
    "rules/form_optimizer_enterprise.rego",
    "rules/jpk_cit.rego",
]

REQUIRED_INNOVATIONS = [
    "annual_autopilot", "decision_certificate", "decision_hash",
    "expected_declaration", "form_transition_3y", "cumulative_tax_3y",
    "best_form_3y", "strategic_decision_score", "score_0_100", "risk_level",
    "jpk_harmonization", "revenue_delta", "revenue_consistent",
]

TEST_MARKERS = [
    "annual_autopilot", "form_transition_3y", "strategic_decision_score",
    "jpk_harmonization", "decision_certificate", "best_form_3y",
    "r05_pit_enterprise_check", "PIT-36", "PIT-36L", "PIT-28",
]

# Podstawy prawne wymagane w nowym pakiecie (kanoniczne)
REQUIRED_LEGAL_MARKERS = [
    "Art. 44, 45 PIT",
    "Art. 9a, 27, 30c PIT",
    "rozporządzenie MF ws. wzorów zeznań PIT (2025-12-30)",
    "Dz.U. 2025 poz. 789",
    "JPK_CIT",
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
        "r05_rego": _read(R05_REGO),
        "main_jdg": _read(MAIN_REGO),
        "pytest": _read(PYTEST),
        "native_rego": _read(NATIVE_REGO),
        "report": _read(str(REPORT_PATH.relative_to(BASE_DIR))),
    }
    pit_ent_present = sum(bool(_read(f)) for f in PIT_ENTERPRISE_FILES)
    return {
        "files": {name: bool(text) for name, text in files.items()},
        "files_total": len(files),
        "files_present": sum(bool(text) for text in files.values()),
        "report_present": bool(files["report"]),
        "pit_enterprise_files_declared": len(PIT_ENTERPRISE_FILES),
        "pit_enterprise_files_present": pit_ent_present,
    }


def _innovation_evidence() -> dict[str, Any]:
    text = _read(R05_REGO)
    missing = [fn for fn in REQUIRED_INNOVATIONS if fn not in text]
    legal = [m for m in REQUIRED_LEGAL_MARKERS if m not in text]
    return {
        "required_innovations": REQUIRED_INNOVATIONS,
        "missing_innovations": missing,
        "innovations_complete": not missing,
        "legal_basis_markers": REQUIRED_LEGAL_MARKERS,
        "missing_legal_markers": legal,
        "legal_basis_complete": not legal,
        "decide_report_rule": "jdg.r05_pit_enterprise_innovations.pit_enterprise_report" in text,
        "activation_flag": "r05_pit_enterprise_check" in text,
        "default_no_match": "jdg.r05_pit_enterprise_innovations.no_match" in text,
        "certificate_f4": "decision_certificate" in text and "hash_algorithm" in text and "bundle_version" in text,
        "three_year_forecast": "cumulative_tax_3y" in text and "best_form_3y" in text,
    }


def _thresholds_evidence() -> dict[str, Any]:
    text = _read(R05_REGO)
    return {
        "thresholds_via_data": "_th_pit" in text,
        "rates_externalized": "scale_lower_rate" in text and "linear_rate" in text and "estonian_cit_rate" in text,
        "tax_reducing_externalized": 'object.get(_th_pit, "tax_reducing_amount", 3600)' in text,
        "jpk_tolerance_externalized": 'object.get(_th_pit, "jpk_tolerance_pln", 100)' in text,
    }


def _duplicate_evidence() -> dict[str, Any]:
    text = _read(R05_REGO)
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
    # POST-MERGE cel zmienia się wraz z kolejnymi raportami (p29 → p30 → p31…).
    post_merge_target = re.search(
        r"final_verdict_post_merge = object\.union\(final_verdict_p(\d+)", joined
    )
    return {
        "import_present": "import data.jdg.r05_pit_enterprise_innovations" in joined,
        "package_decisions_entry": '"jdg.r05_pit_enterprise_innovations": r05_pit_enterprise_innovations.decide' in joined,
        "final_verdict_p30": "final_verdict_p30 = safe_merge(final_verdict_p29," in joined,
        "post_merge_present": post_merge_target is not None and int(post_merge_target.group(1)) >= 30,
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
        if "r05_pit_enterprise_innovations" in json.dumps(v, ensure_ascii=False)
    }
    pit_hashes = {v.get("verdict_hash") for v in pit_verdicts.values()}
    pit_replays = [r for r in replays if r.get("golden_verdict_hash") in pit_hashes]
    uver = [r for r in pit_replays if r.get("uver_applies")]
    return {
        "golden_verdicts_total": len(verdicts),
        "pit_enterprise_verdicts": len(pit_verdicts),
        "pit_enterprise_replays": len(pit_replays),
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
        and scope["pit_enterprise_files_present"] == scope["pit_enterprise_files_declared"],
        "report_present": scope["report_present"],
        "innovations_complete": innovations["innovations_complete"]
        and innovations["decide_report_rule"]
        and innovations["activation_flag"]
        and innovations["default_no_match"]
        and innovations["certificate_f4"]
        and innovations["three_year_forecast"],
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
        "report": "RAPORT_05_PIT_ENTERPRISE",
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
    parser = argparse.ArgumentParser(description="RAPORT_05 evidence gate")
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
            f"RAPORT_05: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
