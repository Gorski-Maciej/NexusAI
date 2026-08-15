#!/usr/bin/env python3
"""RAPORT_17 ENTERPRISE AI — evidence gate.

Mirrors tools/system_opa_innovations_report16_gate.py (new-campaign
convention). Prompt 17/25 (Enterprise AI — inteligencja systemu wokół
deterministycznego silnika OPA) is implemented as the R17 Enterprise AI
innovations package:

  R17-INN-01 adaptive_trust_monitor          — Trust Score → tryb decyzyjny
  R17-INN-02 neural_mesh_confidence_monitor  — pewność synapse + konflikty
  R17-INN-03 cashflow_forecast_monitor       — prognoza 90 dni + płynność
  R17-INN-04 banking_psd2_monitor            — split payment MPP (art. 108a)
  R17-INN-05 legislative_change_monitor      — vacatio legis (art. 4 OrdPU)

Plus wiring in main_jdg.rego (final_verdict_p42), golden verdict + replay
and tests (pytest + native Rego). The Enterprise AI layer (adaptive_trust +
neural_mesh (+v2) + banking + cashflow + strategic_advisor (+roadmap) +
legislative_monitor (+impact) + form_optimizer + hyper_plan45_meta +
decision_composer) is already implemented — verified here (Trust Score
0.92/0.75 AUTO_POST/SUGGEST/ASK_USER, synapse knowledge graph, MPP art. 108a,
prognoza 90 dni art. 44/103/47, vacatio legis art. 4 OrdPU COMPLETE).

Usage (from ``JDG/``)::

    python tools/enterprise_ai_innovations_report17_gate.py --json
    python tools/enterprise_ai_innovations_report17_gate.py --write
    python tools/enterprise_ai_innovations_report17_gate.py --strict
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
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_17_ENTERPRISE_AI.txt"
EVIDENCE_PATH = BUNDLES_DIR / "enterprise_ai_innovations_report17_evidence.json"

R17_REGO = "rules/r17_enterprise_ai_innovations_v9.rego"
MAIN_REGO = "rules/main_jdg.rego"
THRESHOLDS_REGO = "rules/thresholds_jdg.rego"
PYTEST = "tests/auto/test_r17_enterprise_ai_enterprise.py"
NATIVE_REGO = "tests/rego/test_r17_enterprise_ai_enterprise.rego"

# Warstwa Enterprise AI (adaptive_trust + neural_mesh (+v2) + banking +
# cashflow + strategic + legislative + form_optimizer + meta + composer)
EAI_CORE_FILES = [
    "rules/adaptive_trust_scoring_enterprise.rego",
    "rules/neural_rule_mesh_enterprise.rego",
    "rules/neural_mesh_v2_enterprise.rego",
    "rules/banking_automation_enterprise.rego",
    "rules/cashflow_tax_predictor_enterprise.rego",
    "rules/strategic_advisor_enterprise.rego",
    "rules/strategic_roadmap_enterprise.rego",
    "rules/legislative_monitor_enterprise.rego",
    "rules/legislative_impact_analyzer_enterprise.rego",
    "rules/form_optimizer_enterprise.rego",
    "rules/hyper_plan45_meta_enterprise.rego",
    "rules/decision_composer_enterprise.rego",
]

REQUIRED_INNOVATIONS = [
    "adaptive_trust_monitor", "at_mode", "at_trust_score",
    "neural_mesh_confidence_monitor", "nm_reliable", "nm_effective",
    "cashflow_forecast_monitor", "cf_gap_alert", "cf_buffer_ok",
    "banking_psd2_monitor", "bk_split_required", "bk_iban_valid",
    "legislative_change_monitor", "lg_high_impact", "lg_vacatio_compliant",
]

TEST_MARKERS = [
    "adaptive_trust_monitor", "neural_mesh_confidence_monitor",
    "cashflow_forecast_monitor", "banking_psd2_monitor",
    "legislative_change_monitor", "r17_enterprise_ai_check",
    "BLOCK_AND_ALERT", "TRIAGE_QUEUE",
    "AUTO_POST", "ASK_USER",
    "art. 108a", "art. 44", "art. 4",
]

# Podstawy prawne wymagane w nowym pakiecie (kanoniczne)
REQUIRED_LEGAL_MARKERS = [
    "art. 108a",
    "art. 44",
    "art. 103",
    "art. 47",
    "art. 4",
    "PSD2",
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
        "r17_rego": _read(R17_REGO),
        "main_jdg": _read(MAIN_REGO),
        "thresholds": _read(THRESHOLDS_REGO),
        "pytest": _read(PYTEST),
        "native_rego": _read(NATIVE_REGO),
        "report": _read(str(REPORT_PATH.relative_to(BASE_DIR))),
    }
    eai_core_present = sum(bool(_read(f)) for f in EAI_CORE_FILES)
    return {
        "files": {name: bool(text) for name, text in files.items()},
        "files_total": len(files),
        "files_present": sum(bool(text) for text in files.values()),
        "report_present": bool(files["report"]),
        "eai_core_files_declared": len(EAI_CORE_FILES),
        "eai_core_files_present": eai_core_present,
    }


def _innovation_evidence() -> dict[str, Any]:
    text = _read(R17_REGO)
    missing = [fn for fn in REQUIRED_INNOVATIONS if fn not in text]
    legal = [m for m in REQUIRED_LEGAL_MARKERS if m not in text]
    return {
        "required_innovations": REQUIRED_INNOVATIONS,
        "missing_innovations": missing,
        "innovations_complete": not missing,
        "legal_basis_markers": REQUIRED_LEGAL_MARKERS,
        "missing_legal_markers": legal,
        "legal_basis_complete": not legal,
        "decide_report_rule": "jdg.r17_enterprise_ai_innovations.legislative_change_monitor" in text,
        "activation_flag": "r17_enterprise_ai_check" in text,
        "default_no_match": "jdg.r17_enterprise_ai_innovations.no_match" in text,
        "adaptive_trust": "at_mode" in text and "at_trust_score" in text,
        "neural_mesh": "nm_reliable" in text and "nm_effective" in text,
        "cashflow": "cf_gap_alert" in text and "cf_buffer_ok" in text,
        "banking": "bk_split_required" in text and "bk_iban_valid" in text,
        "legislative": "lg_high_impact" in text and "lg_vacatio_compliant" in text,
    }


def _thresholds_evidence() -> dict[str, Any]:
    text = _read(R17_REGO)
    th = _read(THRESHOLDS_REGO)
    return {
        "thresholds_via_data": "_th_ai" in text,
        "trust_externalized": 'object.get(_th_ai, "trust_auto_post_min", 0.92)' in text,
        "mesh_externalized": 'object.get(_th_ai, "mesh_confidence_min", 0.5)' in text,
        "split_payment_externalized": 'object.get(_th_ai, "split_payment_threshold_pln", 15000)' in text,
        "eai_block_present": "enterprise_ai := {" in th and '"trust_auto_post_min"' in th,
    }


def _duplicate_evidence() -> dict[str, Any]:
    text = _read(R17_REGO)
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
        "import_present": "import data.jdg.r17_enterprise_ai_innovations" in joined,
        "package_decisions_entry": '"jdg.r17_enterprise_ai_innovations": r17_enterprise_ai_innovations.decide' in joined,
        "final_verdict_p42": "final_verdict_p42 = safe_merge(final_verdict_p41," in joined,
        "post_merge_present": post_merge_target is not None and int(post_merge_target.group(1)) >= 42,
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
    eai_verdicts = {
        h: v
        for h, v in verdicts.items()
        if "r17_enterprise_ai_innovations" in json.dumps(v, ensure_ascii=False)
    }
    eai_hashes = {v.get("verdict_hash") for v in eai_verdicts.values()}
    eai_replays = [r for r in replays if r.get("golden_verdict_hash") in eai_hashes]
    uver = [r for r in eai_replays if r.get("uver_applies")]
    return {
        "golden_verdicts_total": len(verdicts),
        "eai_verdicts": len(eai_verdicts),
        "eai_replays": len(eai_replays),
        "uver_count": len(uver),
        "replay_verified": len(eai_verdicts) >= 1 and len(eai_replays) >= 1 and len(uver) == 0,
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
        and scope["eai_core_files_present"] == scope["eai_core_files_declared"],
        "report_present": scope["report_present"],
        "innovations_complete": innovations["innovations_complete"]
        and innovations["decide_report_rule"]
        and innovations["activation_flag"]
        and innovations["default_no_match"]
        and innovations["adaptive_trust"]
        and innovations["neural_mesh"]
        and innovations["cashflow"]
        and innovations["banking"]
        and innovations["legislative"],
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
        "report": "RAPORT_17_ENTERPRISE_AI",
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
    parser = argparse.ArgumentParser(description="RAPORT_17 evidence gate")
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
            f"RAPORT_17: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
