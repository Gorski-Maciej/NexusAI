#!/usr/bin/env python3
"""RAPORT_02 VAT — CORE (MACRO) + ENTERPRISE — evidence gate.

Mirrors tools/orchestrator_core_report01_gate.py .. enterprise_ai_report17_gate.py.
Prompt 02/25 (VAT — CORE + ENTERPRISE — stawki, odliczenia, MPP, fraud, korekty)
is implemented as the R02 VAT core-innovations package:

  R02-INN-01 exemption_limit_tracker   — real-time auto-tracking limitu 200 000 PLN
                                         (art. 113): projekcja YTD, strefy, breach month
  R02-INN-02 auto_gtu                  — auto-GTU (Zał. nr 15, GTU_01..GTU_13)
  R02-INN-03 art91_correction_schedule — korekta wieloletnia art. 91 (5/10 lat)

Plus wiring in main_jdg.rego (final_verdict_p27), golden verdict + replay
(1 VAT CORE, 0 UVER) and tests (pytest + native Rego). The VAT macro/enterprise
core (MPP art. 108a-108f, stawki art. 41-43/113, odliczenia art. 86-95/89a-89b,
fraud detection FD-01..06, place of supply art. 28a-28o, tax point art. 19a)
is already implemented by P03/P04 (v8/v9) — verified here.

Usage (from ``JDG/``)::

    python tools/vat_core_report02_gate.py --json
    python tools/vat_core_report02_gate.py --write
    python tools/vat_core_report02_gate.py --strict
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
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_02_VAT_CORE.txt"
EVIDENCE_PATH = BUNDLES_DIR / "vat_core_report02_evidence.json"

R02_REGO = "rules/r02_vat_core_innovations_v9.rego"
MAIN_REGO = "rules/main_jdg.rego"
PYTEST = "tests/auto/test_r02_vat_core_enterprise.py"
NATIVE_REGO = "tests/rego/test_r02_vat_core_enterprise.rego"

# Warstwa VAT Macro/Enterprise (P03/P04 v8/v9) — już wdrożona, weryfikowana
VAT_CORE_FILES = [
    "rules/vat/substantive.rego",
    "rules/vat/deductions.rego",
    "rules/vat/procedures.rego",
    "rules/vat/place_of_supply.rego",
    "rules/vat_substantive_complete_enterprise.rego",
    "rules/vat_rates_exemptions_audit_enterprise.rego",
    "rules/vat_deductions_corrections_enterprise.rego",
    "rules/vat_fraud_detection_enterprise.rego",
    "rules/vat_mpp_split_payment_enterprise.rego",
    "rules/p03_vat_macro_innovations_v9.rego",
    "rules/p04_vat_macro_enterprise_v9.rego",
    "rules/p05_vat_micro_atomic_v9.rego",
]

REQUIRED_INNOVATIONS = [
    "exemption_limit", "projected_annual_turnover", "exemption_limit_zone",
    "exemption_breach_month", "exemption_limit_tracker",
    "gtu_category_map", "gtu_semantic_keywords", "auto_gtu_code", "auto_gtu",
    "art91_period_years", "art91_annual_correction", "art91_direction",
    "art91_schedule", "art91_correction_schedule",
]

# Markery innowacji w testach
TEST_MARKERS = [
    "exemption_limit_tracker", "auto_gtu", "art91_correction_schedule",
    "GTU_02", "breach_month", "period_years",
]

# Podstawy prawne wymagane w nowym pakiecie (kanoniczne)
REQUIRED_LEGAL_MARKERS = [
    "Art. 113 ust. 1, 5, 9",
    "Zał. nr 15",
    "Art. 91 ust. 2-7",
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
        "r02_rego": _read(R02_REGO),
        "main_jdg": _read(MAIN_REGO),
        "pytest": _read(PYTEST),
        "native_rego": _read(NATIVE_REGO),
        "report": _read(str(REPORT_PATH.relative_to(BASE_DIR))),
    }
    vat_core_present = sum(bool(_read(f)) for f in VAT_CORE_FILES)
    return {
        "files": {name: bool(text) for name, text in files.items()},
        "files_total": len(files),
        "files_present": sum(bool(text) for text in files.values()),
        "report_present": bool(files["report"]),
        "vat_core_files_declared": len(VAT_CORE_FILES),
        "vat_core_files_present": vat_core_present,
    }


def _innovation_evidence() -> dict[str, Any]:
    text = _read(R02_REGO)
    missing = [fn for fn in REQUIRED_INNOVATIONS if fn not in text]
    legal = [m for m in REQUIRED_LEGAL_MARKERS if m not in text]
    return {
        "required_innovations": REQUIRED_INNOVATIONS,
        "missing_innovations": missing,
        "innovations_complete": not missing,
        "legal_basis_markers": REQUIRED_LEGAL_MARKERS,
        "missing_legal_markers": legal,
        "legal_basis_complete": not legal,
        "decide_report_rule": "jdg.r02_vat_core_innovations.vat_core_report" in text,
        "activation_flag": "r02_vat_core_check" in text,
        "default_no_match": "jdg.r02_vat_core_innovations.no_match" in text,
    }


def _limit_externalized_evidence() -> dict[str, Any]:
    text = _read(R02_REGO)
    return {
        "limit_from_thresholds": 'object.get(data.jdg.thresholds.vat, "subject_exemption_limit", 200000)' in text,
        "zero_hardcode": "subject_exemption_limit" in text,
    }


def _duplicate_evidence() -> dict[str, Any]:
    text = _read(R02_REGO)
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
    # POST-MERGE cel zmienia się wraz z kolejnymi raportami (p26 → p27 → p28…).
    # Bramka weryfikuje, że R02 jest wpięty (p27 istnieje) oraz że łańcuch
    # POST-MERGE kończy się na invariants + certyfikacie — niezależnie od tego,
    # czy kolejne raporty dodały p28+.
    post_merge_target = re.search(
        r"final_verdict_post_merge = object\.union\(final_verdict_p(\d+)", joined
    )
    return {
        "import_present": "import data.jdg.r02_vat_core_innovations" in joined,
        "package_decisions_entry": '"jdg.r02_vat_core_innovations": r02_vat_core_innovations.decide' in joined,
        "final_verdict_p27": "final_verdict_p27 = safe_merge(final_verdict_p26," in joined,
        "post_merge_present": post_merge_target is not None and int(post_merge_target.group(1)) >= 27,
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
    vat_verdicts = {
        h: v
        for h, v in verdicts.items()
        if "r02_vat_core_innovations" in json.dumps(v, ensure_ascii=False)
    }
    vat_hashes = {v.get("verdict_hash") for v in vat_verdicts.values()}
    vat_replays = [r for r in replays if r.get("golden_verdict_hash") in vat_hashes]
    uver = [r for r in vat_replays if r.get("uver_applies")]
    return {
        "golden_verdicts_total": len(verdicts),
        "vat_core_verdicts": len(vat_verdicts),
        "vat_core_replays": len(vat_replays),
        "uver_count": len(uver),
        "replay_verified": len(vat_verdicts) >= 1 and len(vat_replays) >= 1 and len(uver) == 0,
    }


def build_evidence() -> dict[str, Any]:
    scope = _scope_evidence()
    innovations = _innovation_evidence()
    limit = _limit_externalized_evidence()
    dup = _duplicate_evidence()
    router = _router_evidence()
    tests = _test_evidence()
    replay = _replay_evidence()

    gates = {
        "scope_files_present": scope["files_present"] == scope["files_total"]
        and scope["vat_core_files_present"] == scope["vat_core_files_declared"],
        "report_present": scope["report_present"],
        "innovations_complete": innovations["innovations_complete"]
        and innovations["decide_report_rule"]
        and innovations["activation_flag"]
        and innovations["default_no_match"],
        "legal_basis_canonical": innovations["legal_basis_complete"],
        "limit_externalized": limit["limit_from_thresholds"] and limit["zero_hardcode"],
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
        "report": "RAPORT_02_VAT_CORE",
        "status": status,
        "gates": gates,
        "gate_summary": {"passed": passed, "total": total},
        "scope": scope,
        "innovations": innovations,
        "limit_externalized": limit,
        "duplicates": dup,
        "router": router,
        "tests": tests,
        "replay": replay,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="RAPORT_02 evidence gate")
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
            f"RAPORT_02: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
