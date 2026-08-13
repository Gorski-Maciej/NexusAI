#!/usr/bin/env python3
"""RAPORT_17 ENTERPRISE AI (Neural Mesh / Adaptive Trust / PSD2) — evidence gate.

Mirrors tools/kks_report07_gate.py .. opa_system_report16_gate.py. Boundary rule
from the report is enforced: intelligence may recommend, warn and roll back, but
the evaluative decision stays in deterministic Rego — so the gate asserts
decision_mode SUGGEST (never decision_mode AUTO_POST) on the critical AI rules.

Usage (from ``JDG/``)::

    python tools/enterprise_ai_report17_gate.py --json
    python tools/enterprise_ai_report17_gate.py --write
    python tools/enterprise_ai_report17_gate.py --strict
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any

BASE_DIR = Path(__file__).resolve().parents[1]
BUNDLES_DIR = BASE_DIR / "bundles"
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_17_ENTERPRISE_AI.txt"
EVIDENCE_PATH = BUNDLES_DIR / "enterprise_ai_report17_evidence.json"

# Paths enumerated by RAPORT_17 (tabela 2.3), kept explicit so the audit
# cannot silently shrink when a future directory scan changes. 12 Rego files.
RULE_FILES = (
    "rules/adaptive_trust_scoring_enterprise.rego",
    "rules/banking_automation_enterprise.rego",
    "rules/cashflow_tax_predictor_enterprise.rego",
    "rules/decision_composer_enterprise.rego",
    "rules/form_optimizer_enterprise.rego",
    "rules/hyper_plan45_meta_enterprise.rego",
    "rules/legislative_impact_analyzer_enterprise.rego",
    "rules/legislative_monitor_enterprise.rego",
    "rules/neural_mesh_v2_enterprise.rego",
    "rules/neural_rule_mesh_enterprise.rego",
    "rules/strategic_advisor_enterprise.rego",
    "rules/strategic_roadmap_enterprise.rego",
)

TEST_FILES = (
    "tests/test_p16_v8_enterprise.py",
    "tests/test_strategic_v2_modules.py",
    "tests/rego/test_p02_decision_core_enterprise.rego",
    "tests/rego/test_native_neural_rule_mesh_enterprise.rego",
    "tests/rego/test_native_banking_automation_enterprise.rego",
    "tests/rego/test_native_cashflow_tax_predictor_enterprise.rego",
    "tests/rego/test_native_strategic_advisor_enterprise.rego",
    "tests/rego/test_native_legislative_monitor_enterprise.rego",
    "tests/rego/test_native_cross_domain_intelligence_enterprise.rego",
)

# Krytyczne reguły warstwy ENTERPRISE AI. Canonical markers = legal/architecture
# reference (P02/Neural Mesh/tax article/PSD2/OrdPU) present in the rule block.
CRITICAL_RULES = {
    "auto_post_gate": (
        "rules/adaptive_trust_scoring_enterprise.rego",
        "jdg.adaptive_trust.auto_post_gate",
        ("P02", "Adaptive Trust", "risk.rego"),
    ),
    "suggest_gate": (
        "rules/adaptive_trust_scoring_enterprise.rego",
        "jdg.adaptive_trust.suggest_gate",
        ("P02", "Adaptive Trust"),
    ),
    "global_domain_health": (
        "rules/neural_rule_mesh_enterprise.rego",
        "jdg.neural_mesh.global_domain_health",
        ("Neural Mesh", "domain health"),
    ),
    "split_payment_preparation": (
        "rules/banking_automation_enterprise.rego",
        "jdg.banking.split_payment_preparation",
        ("Art. 108a", "MPP"),
    ),
    "tax_liability_forecast_90d": (
        "rules/cashflow_tax_predictor_enterprise.rego",
        "jdg.cashflow.tax_liability_forecast_90d",
        ("Art. 44", "Art. 103", "Art. 47"),
    ),
    "transformation_jdg_to_spzoo": (
        "rules/strategic_advisor_enterprise.rego",
        "jdg.strategic.transformation_jdg_to_spzoo",
        ("Art. 551-584", "Art. 30c PIT"),
    ),
    "change_detection": (
        "rules/legislative_monitor_enterprise.rego",
        "jdg.legislative.change_detection",
        ("Art. 4 OrdPU", "vacatio legis"),
    ),
}

# Test marker evidence — rule_id fragment that must appear in the joined test
# files to prove the critical rule is exercised.
CRITICAL_TEST_MARKERS = {
    "auto_post_gate": ("auto_post_gate",),
    "suggest_gate": ("suggest_gate",),
    "global_domain_health": ("global_domain_health",),
    "split_payment_preparation": ("split_payment_preparation",),
    "tax_liability_forecast_90d": ("tax_liability_forecast_90d",),
    "transformation_jdg_to_spzoo": ("transformation_jdg_to_spzoo",),
    "change_detection": ("change_detection",),
}


def _read(rel: str) -> str:
    path = BASE_DIR / rel
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return ""


def _rule_ids(text: str) -> list[str]:
    return re.findall(r'"rule_id"\s*:\s*"([a-zA-Z0-9_.-]+)"', text)


def _legal_basis_count(text: str) -> int:
    return len(re.findall(r'"_?legal_basis"\s*:\s*"[^"]+"', text))


def _rule_block(rel: str, rule_id: str) -> str:
    text = _read(rel)
    marker = f'"rule_id": "{rule_id}"'
    alt = f'"rule_id":"{rule_id}"'
    start = text.find(marker)
    if start < 0:
        start = text.find(alt)
    if start < 0:
        return ""
    m = re.search(r'"rule_id"\s*:\s*"', text[start + len(marker):])
    next_rule = start + len(marker) + m.start() if m else -1
    return text[start: next_rule if next_rule >= 0 else len(text)]


def _rule_block_has_temporal(rel: str, rule_id: str) -> bool:
    block = _rule_block(rel, rule_id)
    return '"valid_from"' in block and '"valid_to"' in block


def _rule_block_has_legal_basis(rel: str, rule_id: str) -> bool:
    block = _rule_block(rel, rule_id)
    return re.search(r'"_?legal_basis"\s*:\s*"[^"]+"', block) is not None


def _rule_block_has_canonical(rel: str, rule_id: str, markers: tuple[str, ...]) -> bool:
    block = _rule_block(rel, rule_id)
    return any(m in block for m in markers)


def _file_inventory() -> dict[str, Any]:
    files = []
    all_ids: list[str] = []
    for rel in RULE_FILES:
        text = _read(rel)
        ids = _rule_ids(text)
        all_ids.extend(ids)
        files.append(
            {
                "path": rel,
                "exists": bool(text),
                "rule_id_count": len(ids),
                "legal_basis_count": _legal_basis_count(text),
                "temporal": "valid_from" in text and "valid_to" in text,
                "package_declared": bool(re.search(r"^package\s+", text, re.MULTILINE)),
            }
        )
    counts = Counter(all_ids)
    duplicates = sorted(rid for rid, count in counts.items() if count > 1)
    critical_temporal = {
        name: _rule_block_has_temporal(rel, rule_id)
        for name, (rel, rule_id, _markers) in CRITICAL_RULES.items()
    }
    return {
        "files": files,
        "files_total": len(RULE_FILES),
        "files_present": sum(item["exists"] for item in files),
        "rule_ids_total": len(all_ids),
        "rule_ids_unique": len(set(all_ids)),
        "duplicate_rule_ids": duplicates,
        "duplicate_count": len(duplicates),
        "temporal_files": sum(item["temporal"] for item in files),
        "critical_temporal_rule_count": sum(critical_temporal.values()),
        "critical_temporal_evidence": critical_temporal,
        "temporal_coverage_pct": round(
            sum(item["temporal"] for item in files) / len(files) * 100, 2
        )
        if files
        else 0.0,
    }


def _test_evidence() -> dict[str, Any]:
    texts = {rel: _read(rel) for rel in TEST_FILES}
    joined = "\n".join(texts.values())
    marker_hits = {
        name: any(candidate in joined for candidate in candidates)
        for name, candidates in CRITICAL_TEST_MARKERS.items()
    }
    return {
        "files_declared": len(TEST_FILES),
        "files_present": sum(bool(text) for text in texts.values()),
        "critical_rule_markers": marker_hits,
        "critical_rule_evidence_complete": all(marker_hits.values()),
        "native_rego_test_present": bool(
            texts.get("tests/rego/test_native_banking_automation_enterprise.rego")
        ),
        "pytest_test_present": bool(texts.get("tests/test_strategic_v2_modules.py")),
    }


def _legal_canonical_evidence() -> dict[str, Any]:
    legal_basis = {
        name: _rule_block_has_legal_basis(rel, rule_id)
        for name, (rel, rule_id, _markers) in CRITICAL_RULES.items()
    }
    canonical = {
        name: _rule_block_has_canonical(rel, rule_id, markers)
        for name, (rel, rule_id, markers) in CRITICAL_RULES.items()
    }
    return {
        "critical_legal_basis": legal_basis,
        "critical_canonical_reference": canonical,
        "critical_rules_required": len(CRITICAL_RULES),
    }


def _router_evidence() -> dict[str, Any]:
    joined = "\n".join(_read(f) for f in ("rules/main_jdg.rego", "rules/provenance.rego"))
    return {
        "adaptive_trust_registered": bool(re.search(r"jdg\.adaptive_trust", joined)),
        "neural_mesh_registered": bool(re.search(r"jdg\.neural_mesh", joined)),
        "banking_registered": bool(re.search(r"jdg\.banking", joined)),
        "cashflow_registered": bool(re.search(r"jdg\.cashflow_predictor", joined)),
        "strategic_registered": bool(re.search(r"jdg\.strategic_advisor", joined)),
        "legislative_registered": bool(re.search(r"jdg\.legislative_monitor", joined)),
        "final_verdict": "full_final_verdict" in joined,
    }


def _safety_evidence() -> dict[str, Any]:
    joined = "\n".join(_read(f) for f in RULE_FILES)
    suggest = bool(re.search(r'"decision_mode"\s*:\s*"SUGGEST"', joined))
    # Reguła graniczna: inteligencja może rekomendować AUTO_POST (jako _routing),
    # ale decision_mode nie może być AUTO_POST — decyzja zostaje SUGGEST.
    auto_post_mode = bool(re.search(r'"decision_mode"\s*:\s*"AUTO_POST"', joined))
    return {
        "suggest_mode_present": suggest,
        "auto_post_mode_present": auto_post_mode,
        "no_auto_post_mode": not auto_post_mode,
    }


def _replay_evidence() -> dict[str, Any]:
    golden = json.loads(
        (BUNDLES_DIR / "golden_verdicts.json").read_text(encoding="utf-8")
    )
    verdicts = golden.get("verdicts", {})
    replays = golden.get("replays", {})
    if not isinstance(replays, (list, dict)):
        replays = []
    ai_verdicts = {
        h: v
        for h, v in verdicts.items()
        if "adaptive_trust" in json.dumps(v, ensure_ascii=False)
        or "auto_post_gate" in json.dumps(v, ensure_ascii=False)
    }
    unmatched = golden.get("unmatched_replays", [])
    if not isinstance(unmatched, list):
        unmatched = []
    return {
        "golden_verdicts_total": len(verdicts),
        "ai_verdicts": len(ai_verdicts),
        "replays_total": len(replays),
        "unmatched_replays": unmatched,
        "unmatched_count": len(unmatched),
        "replay_verified": len(ai_verdicts) >= 1 and len(unmatched) == 0,
    }


def _deployment_evidence() -> dict[str, Any]:
    deployments = json.loads(
        (BUNDLES_DIR / "deployments.json").read_text(encoding="utf-8")
    )
    dep = deployments.get("deployments", {}).get("jdg-eai-bundle-v9.0.0", {})
    return {
        "bundle": "jdg-eai-bundle-v9.0.0",
        "phase": dep.get("phase"),
        "rollout_pct": dep.get("rollout_pct"),
        "quality": dep.get("quality"),
        "error_rate": dep.get("error_rate"),
        "rollback_reason": dep.get("rollback_reason"),
        "soak_completed_at": dep.get("soak_completed_at"),
        "active_version": deployments.get("active_version"),
    }


def build_evidence() -> dict[str, Any]:
    inventory = _file_inventory()
    test = _test_evidence()
    legal = _legal_canonical_evidence()
    router = _router_evidence()
    safety = _safety_evidence()
    replay = _replay_evidence()
    deployment = _deployment_evidence()

    gates = {
        "scope_files_present": inventory["files_present"] == inventory["files_total"],
        "duplicate_free": inventory["duplicate_count"] == 0,
        "critical_tests_mapped": test["critical_rule_evidence_complete"],
        "critical_temporal": inventory["critical_temporal_rule_count"]
        >= len(CRITICAL_RULES),
        "legal_basis_canonical": all(legal["critical_legal_basis"].values())
        and all(legal["critical_canonical_reference"].values())
        and legal["critical_rules_required"] == len(CRITICAL_RULES),
        "router_wired": router["adaptive_trust_registered"]
        and router["neural_mesh_registered"]
        and router["banking_registered"]
        and router["cashflow_registered"]
        and router["strategic_registered"]
        and router["legislative_registered"]
        and router["final_verdict"],
        "safety_suggest": safety["suggest_mode_present"]
        and safety["no_auto_post_mode"],
        "golden_replay_ok": replay["replay_verified"],
        "canary_rollback_ok": deployment["phase"] == "ROLLED_BACK"
        and deployment["rollback_reason"] is not None,
    }
    passed = sum(gates.values())
    total = len(gates)
    status = "WDROZONY_100" if passed == total else "NIEPELNY"
    return {
        "report": "RAPORT_17_ENTERPRISE_AI",
        "status": status,
        "gates": gates,
        "gate_summary": {"passed": passed, "total": total},
        "inventory": inventory,
        "test_evidence": test,
        "legal_canonical": legal,
        "router": router,
        "safety": safety,
        "replay": replay,
        "deployment": deployment,
        "generated_at": __import__("datetime").datetime.now(__import__("datetime").timezone.utc).isoformat(),
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
