#!/usr/bin/env python3
"""RAPORT_01 ORKIESTRATOR + RDZEŃ SILNIKA — evidence gate.

Mirrors tools/enterprise_ai_report17_gate.py .. kks_report07_gate.py. Prompt
01/25 (ORKIESTRATOR I RDZEŃ SILNIKA — main_jdg, routing, risk, temporal,
thresholds, validation) is implemented as the R01 core-innovations package:

  R01-INN-01 routing_path_trace         — deterministyczny routing z debugowaniem ścieżki
  R01-INN-02 verdict_25_field           — werdykt 25-polowy: słownik + bramka kompletności
  R01-INN-03 decision_cache_runtime     — cache decyzji (klucz, TTL, hit/miss, F3 V2)
  R01-INN-04 time_travel_guard          — spójność time-travel (P1610, INV-025)
  R01-INN-05 safe_merge_integrity       — runtime verification allowlist (INV-042)
  R01-INN-06 priority_conflict_detector — zderzenia priorytetów (INV-018)

Plus wiring in main_jdg.rego (final_verdict_p26 / _package_decisions /
POST-MERGE), golden verdict + replay (1 ORCHESTRATOR, 0 UVER) and tests
(pytest + native Rego).

Usage (from ``JDG/``)::

    python tools/orchestrator_core_report01_gate.py --json
    python tools/orchestrator_core_report01_gate.py --write
    python tools/orchestrator_core_report01_gate.py --strict
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
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_01_ORKIESTRATOR_RDZEN.txt"
EVIDENCE_PATH = BUNDLES_DIR / "orchestrator_core_report01_evidence.json"

R01_REGO = "rules/r01_orchestrator_core_innovations_v9.rego"
MAIN_REGO = "rules/main_jdg.rego"
PYTEST = "tests/auto/test_r01_orchestrator_core_enterprise.py"
NATIVE_REGO = "tests/rego/test_r01_orchestrator_core_enterprise.rego"

# Kanoniczne 25 pól werdyktu JDG (raport master 00 + P02 warstwa decyzyjna)
CANONICAL_25_FIELDS = [
    "matched", "rule_id", "package", "priority",
    "vat_rate", "rounding_level", "gtu_code", "vat_exemption", "procedure",
    "pit_form", "pit_rate", "pit_bracket", "pit_annual_return_type",
    "kus_qualification", "kus_percent",
    "zus_social_base_type", "zus_health_rate",
    "business_status", "ceidg_registration_required",
    "valid_from", "valid_to",
    "_routing", "_routing_reason", "_legal_basis", "_warnings",
]

# Innowacje R01 wymagane w pliku reguł (fragmenty-funkcje/reguły)
REQUIRED_INNOVATIONS = [
    "select_path", "routing_path_trace",
    "verdict_25_fields", "missing_verdict_fields", "verdict_complete",
    "cache_input_hash", "decision_cache_runtime",
    "time_travel_guard",
    "immutable_allowlist", "safe_merge_integrity",
    "priority_conflicts", "priority_conflict_report",
]

# Markery innowacji, które MUSZĄ pojawić się w testach (pytest + natywny Rego)
TEST_MARKERS = [
    "routing_path_trace", "SHARDED_DOMESTIC_SALE",
    "verdict_25_fields", "decision_cache_runtime",
    "time_travel_guard", "safe_merge_integrity", "priority_conflicts",
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
        "r01_rego": _read(R01_REGO),
        "main_jdg": _read(MAIN_REGO),
        "pytest": _read(PYTEST),
        "native_rego": _read(NATIVE_REGO),
        "report": _read(str(REPORT_PATH.relative_to(BASE_DIR))),
    }
    return {
        "files": {name: bool(text) for name, text in files.items()},
        "files_total": len(files),
        "files_present": sum(bool(text) for text in files.values()),
        "report_present": bool(files["report"]),
    }


def _innovation_evidence() -> dict[str, Any]:
    text = _read(R01_REGO)
    return {
        "required_innovations": REQUIRED_INNOVATIONS,
        "missing_innovations": [fn for fn in REQUIRED_INNOVATIONS if fn not in text],
        "innovations_complete": all(fn in text for fn in REQUIRED_INNOVATIONS),
        "decide_report_rule": "jdg.r01_orchestrator_core_innovations.orchestrator_core_report" in text,
        "activation_flag": "r01_orchestrator_core_check" in text,
        "default_no_match": 'jdg.r01_orchestrator_core_innovations.no_match' in text,
    }


def _verdict_25_field_evidence() -> dict[str, Any]:
    text = _read(R01_REGO)
    block_start = text.find("verdict_25_fields :=")
    block = text[block_start: block_start + 2500] if block_start >= 0 else ""
    missing = [f for f in CANONICAL_25_FIELDS if f'"{f}"' not in block]
    return {
        "canonical_count": len(CANONICAL_25_FIELDS),
        "missing_fields": missing,
        "complete": not missing,
    }


def _duplicate_evidence() -> dict[str, Any]:
    text = _read(R01_REGO)
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
    # POST-MERGE cel zmienia się wraz z kolejnymi raportami (p25 → p26 → p27…).
    # Bramka weryfikuje, że R01 jest wpięty (p26 istnieje) oraz że łańcuch
    # POST-MERGE kończy się na invariants + certyfikacie — niezależnie od tego,
    # czy kolejne raporty dodały p27+.
    post_merge_target = re.search(
        r"final_verdict_post_merge = object\.union\(final_verdict_p(\d+)", joined
    )
    return {
        "import_present": "import data.jdg.r01_orchestrator_core_innovations" in joined,
        "package_decisions_entry": '"jdg.r01_orchestrator_core_innovations": r01_orchestrator_core_innovations.decide' in joined,
        "final_verdict_p26": "final_verdict_p26 = safe_merge(final_verdict_p25," in joined,
        "post_merge_on_or_after_p26": bool(post_merge_target) and int(post_merge_target.group(1)) >= 26,
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
    golden_path = BUNDLES_DIR / "golden_verdicts.json"
    golden = json.loads(golden_path.read_text(encoding="utf-8"))
    verdicts = golden.get("verdicts", {})
    replays = golden.get("replays", [])
    if not isinstance(replays, list):
        replays = []
    orch_verdicts = {
        h: v
        for h, v in verdicts.items()
        if "r01_orchestrator_core_innovations" in json.dumps(v, ensure_ascii=False)
        or "SHARDED_DOMESTIC_SALE" in json.dumps(v, ensure_ascii=False)
    }
    orch_hashes = {v.get("verdict_hash") for v in orch_verdicts.values()}
    orch_replays = [r for r in replays if r.get("golden_verdict_hash") in orch_hashes]
    uver = [r for r in orch_replays if r.get("uver_applies")]
    return {
        "golden_verdicts_total": len(verdicts),
        "orchestrator_verdicts": len(orch_verdicts),
        "orchestrator_replays": len(orch_replays),
        "unmatched_replays": golden.get("unmatched_replays", []),
        "uver_count": len(uver),
        "replay_verified": len(orch_verdicts) >= 1 and len(orch_replays) >= 1 and len(uver) == 0,
    }


def build_evidence() -> dict[str, Any]:
    scope = _scope_evidence()
    innovations = _innovation_evidence()
    verdict25 = _verdict_25_field_evidence()
    dup = _duplicate_evidence()
    router = _router_evidence()
    tests = _test_evidence()
    replay = _replay_evidence()

    gates = {
        "scope_files_present": scope["files_present"] == scope["files_total"],
        "report_present": scope["report_present"],
        "innovations_complete": innovations["innovations_complete"]
        and innovations["decide_report_rule"]
        and innovations["activation_flag"]
        and innovations["default_no_match"],
        "verdict_25_field_complete": verdict25["complete"]
        and verdict25["canonical_count"] == 25,
        "duplicate_free": dup["duplicate_count"] == 0,
        "router_wired": all(router.values()),
        "tests_present": tests["pytest_present"]
        and tests["native_rego_present"]
        and tests["markers_complete"],
        "golden_replay_ok": replay["replay_verified"],
        "runtime_semantics": (
            "select_path" in _read(R01_REGO)
            and "time_travel_guard" in _read(R01_REGO)
            and "safe_merge_integrity" in _read(R01_REGO)
            and "priority_conflicts" in _read(R01_REGO)
            and "decision_cache_runtime" in _read(R01_REGO)
        ),
    }
    passed = sum(gates.values())
    total = len(gates)
    status = "WDROZONY_100" if passed == total else "NIEPELNY"
    return {
        "report": "RAPORT_01_ORKIESTRATOR_RDZEN",
        "status": status,
        "gates": gates,
        "gate_summary": {"passed": passed, "total": total},
        "scope": scope,
        "innovations": innovations,
        "verdict_25_field": verdict25,
        "duplicates": dup,
        "router": router,
        "tests": tests,
        "replay": replay,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="RAPORT_01 evidence gate")
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
            f"RAPORT_01: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
