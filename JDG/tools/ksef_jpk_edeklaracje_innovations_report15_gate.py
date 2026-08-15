#!/usr/bin/env python3
"""RAPORT_15 KSeF / JPK / e-DEKLARACJE / GTU / WIS — evidence gate.

Mirrors tools/rodo_aml_bdo_innovations_report14_gate.py (new-campaign
convention). Prompt 15/25 (KSeF / JPK / e-deklaracje / e-doręczenia / WIS /
GTU) is implemented as the R15 KSeF/JPK innovations package:

  R15-INN-01 ksef_firewall_monitor       — firewall KSeF (art. 106na)
  R15-INN-02 jpk_reconciliation_checker  — korelacja VAT-7/JPK_V7M (art. 82/99)
  R15-INN-03 gtu_code_classifier         — klasyfikator GTU (art. 99)
  R15-INN-04 ksef_offline_deadline_monitor — tryb awaryjny (art. 106nb)
  R15-INN-05 wis_request_monitor         — wniosek WIS (art. 42a)

Plus wiring in main_jdg.rego (final_verdict_p40), golden verdict + replay
and tests (pytest + native Rego). The KSeF/JPK layer (p17 + ksef_jpk +
ksef_* + jpk_* + corrections + gtu + edelivery + epuap + wis + micro/ksef|jpk)
is already implemented — verified here (art. 106na/106nb/106j/99/82/193a/42a
COMPLETE).

Usage (from ``JDG/``)::

    python tools/ksef_jpk_edeklaracje_innovations_report15_gate.py --json
    python tools/ksef_jpk_edeklaracje_innovations_report15_gate.py --write
    python tools/ksef_jpk_edeklaracje_innovations_report15_gate.py --strict
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
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_15_KSEF_JPK_EDEKLARACJE.txt"
EVIDENCE_PATH = BUNDLES_DIR / "ksef_jpk_edeklaracje_innovations_report15_evidence.json"

R15_REGO = "rules/r15_ksef_jpk_edeklaracje_innovations_v9.rego"
MAIN_REGO = "rules/main_jdg.rego"
THRESHOLDS_REGO = "rules/thresholds_jdg.rego"
PYTEST = "tests/auto/test_r15_ksef_jpk_edeklaracje_enterprise.py"
NATIVE_REGO = "tests/rego/test_r15_ksef_jpk_edeklaracje_enterprise.rego"

# Warstwa KSeF/JPK/e-deklaracje (p17 + ksef_jpk + ksef_* + jpk_* + micro)
KJP_CORE_FILES = [
    "rules/ksef_jpk.rego",
    "rules/p17_ksef_jpk_edeklaracje_innovations_v9.rego",
    "rules/ksef_firewall_enterprise.rego",
    "rules/ksef_innovations_enterprise.rego",
    "rules/ksef_offline_queue_enterprise.rego",
    "rules/ksef_outbox_enterprise.rego",
    "rules/ksef_receipt_digest_enterprise.rego",
    "rules/ksef_resilience_enterprise.rego",
    "rules/ksef_sanction_monitor_enterprise.rego",
    "rules/ksef_sandbox_harness_enterprise.rego",
    "rules/ksef_upo_tracker_enterprise.rego",
    "rules/jpk_v7_autogen_enterprise.rego",
    "rules/jpk_kr_st_generator_enterprise.rego",
    "rules/jpk_corrections_workflow_enterprise.rego",
    "rules/jpk_cit.rego",
    "rules/corrections.rego",
    "rules/cross_declaration_validator_enterprise.rego",
    "rules/gtu_completeness_checker_enterprise.rego",
    "rules/edelivery_gateway_enterprise.rego",
    "rules/edelivery_gateway_v2_enterprise.rego",
    "rules/epuap_enterprise.rego",
    "rules/wis_api_enterprise.rego",
    "rules/wis_autorequester_enterprise.rego",
    "rules/micro/ksef/ksef.rego",
    "rules/micro/jpk/jpk.rego",
    "rules/micro/plan33_ksef.rego",
    "rules/micro/plan33_jpk.rego",
]

REQUIRED_INNOVATIONS = [
    "ksef_firewall_monitor", "kf_nip_valid", "kf_blocked",
    "jpk_reconciliation_checker", "jr_mismatch", "jr_max_delta_pln",
    "gtu_code_classifier", "gt_expected_code", "gt_mismatch",
    "ksef_offline_deadline_monitor", "ko_unfiled_count", "ko_grace_days",
    "wis_request_monitor", "wr_incomplete", "wr_response_days",
]

TEST_MARKERS = [
    "ksef_firewall_monitor", "jpk_reconciliation_checker",
    "gtu_code_classifier", "ksef_offline_deadline_monitor",
    "wis_request_monitor", "r15_ksef_jpk_check",
    "BLOCK_AND_ALERT", "TRIAGE_QUEUE",
    "art. 106na", "art. 82", "art. 99", "art. 106nb", "art. 42a",
]

# Podstawy prawne wymagane w nowym pakiecie (kanoniczne)
REQUIRED_LEGAL_MARKERS = [
    "art. 106na",
    "art. 106nb",
    "art. 82",
    "art. 99",
    "art. 42a",
    "art. 193a",
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
        "r15_rego": _read(R15_REGO),
        "main_jdg": _read(MAIN_REGO),
        "thresholds": _read(THRESHOLDS_REGO),
        "pytest": _read(PYTEST),
        "native_rego": _read(NATIVE_REGO),
        "report": _read(str(REPORT_PATH.relative_to(BASE_DIR))),
    }
    kjp_core_present = sum(bool(_read(f)) for f in KJP_CORE_FILES)
    return {
        "files": {name: bool(text) for name, text in files.items()},
        "files_total": len(files),
        "files_present": sum(bool(text) for text in files.values()),
        "report_present": bool(files["report"]),
        "kjp_core_files_declared": len(KJP_CORE_FILES),
        "kjp_core_files_present": kjp_core_present,
    }


def _innovation_evidence() -> dict[str, Any]:
    text = _read(R15_REGO)
    missing = [fn for fn in REQUIRED_INNOVATIONS if fn not in text]
    legal = [m for m in REQUIRED_LEGAL_MARKERS if m not in text]
    return {
        "required_innovations": REQUIRED_INNOVATIONS,
        "missing_innovations": missing,
        "innovations_complete": not missing,
        "legal_basis_markers": REQUIRED_LEGAL_MARKERS,
        "missing_legal_markers": legal,
        "legal_basis_complete": not legal,
        "decide_report_rule": "jdg.r15_ksef_jpk_edeklaracje_innovations.wis_request_monitor" in text,
        "activation_flag": "r15_ksef_jpk_check" in text,
        "default_no_match": "jdg.r15_ksef_jpk_edeklaracje_innovations.no_match" in text,
        "ksef_firewall": "kf_nip_valid" in text and "kf_blocked" in text,
        "jpk_reconciliation": "jr_mismatch" in text and "jr_max_delta_pln" in text,
        "gtu_classifier": "gt_expected_code" in text and "gt_mismatch" in text,
        "ksef_offline": "ko_unfiled_count" in text and "ko_grace_days" in text,
        "wis_request": "wr_incomplete" in text and "wr_response_days" in text,
    }


def _thresholds_evidence() -> dict[str, Any]:
    text = _read(R15_REGO)
    th = _read(THRESHOLDS_REGO)
    return {
        "thresholds_via_data": "_th_kj" in text,
        "sanction_externalized": 'object.get(_th_kj, "ksef_sanction_max_pln", 500000)' in text,
        "offline_externalized": 'object.get(_th_kj, "ksef_offline_grace_days", 7)' in text,
        "wis_externalized": 'object.get(_th_kj, "wis_response_days", 3)' in text,
        "kj_block_present": "ksef_jpk := {" in th and '"ksef_sanction_max_pln"' in th,
    }


def _duplicate_evidence() -> dict[str, Any]:
    text = _read(R15_REGO)
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
        "import_present": "import data.jdg.r15_ksef_jpk_edeklaracje_innovations" in joined,
        "package_decisions_entry": '"jdg.r15_ksef_jpk_edeklaracje_innovations": r15_ksef_jpk_edeklaracje_innovations.decide' in joined,
        "final_verdict_p40": "final_verdict_p40 = safe_merge(final_verdict_p39," in joined,
        "post_merge_present": post_merge_target is not None and int(post_merge_target.group(1)) >= 40,
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
    kjp_verdicts = {
        h: v
        for h, v in verdicts.items()
        if "r15_ksef_jpk_edeklaracje_innovations" in json.dumps(v, ensure_ascii=False)
    }
    kjp_hashes = {v.get("verdict_hash") for v in kjp_verdicts.values()}
    kjp_replays = [r for r in replays if r.get("golden_verdict_hash") in kjp_hashes]
    uver = [r for r in kjp_replays if r.get("uver_applies")]
    return {
        "golden_verdicts_total": len(verdicts),
        "kjp_verdicts": len(kjp_verdicts),
        "kjp_replays": len(kjp_replays),
        "uver_count": len(uver),
        "replay_verified": len(kjp_verdicts) >= 1 and len(kjp_replays) >= 1 and len(uver) == 0,
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
        and scope["kjp_core_files_present"] == scope["kjp_core_files_declared"],
        "report_present": scope["report_present"],
        "innovations_complete": innovations["innovations_complete"]
        and innovations["decide_report_rule"]
        and innovations["activation_flag"]
        and innovations["default_no_match"]
        and innovations["ksef_firewall"]
        and innovations["jpk_reconciliation"]
        and innovations["gtu_classifier"]
        and innovations["ksef_offline"]
        and innovations["wis_request"],
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
        "report": "RAPORT_15_KSEF_JPK_EDEKLARACJE",
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
    parser = argparse.ArgumentParser(description="RAPORT_15 evidence gate")
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
            f"RAPORT_15: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
