#!/usr/bin/env python3
"""RAPORT_16 SYSTEM OPA (P18–P35) — evidence gate.

Mirrors tools/kks_report07_gate.py .. ksef_jpk_report15_gate.py: the report
distinguishes repository evidence from recommendations, so this tool keeps
that distinction executable. It never infers deployment from file names alone
and fails closed in ``--strict`` mode when production evidence is absent.

For the OPA-system report the "legal basis" of a rule is its canonical
architecture reference (ADR-xxx / P01–P35 section / ISAP), not a tax article,
so the legal-canonicality gate verifies those references instead of the
Legal Twin tax graph.

Usage (from ``JDG/``)::

    python tools/opa_system_report16_gate.py --json
    python tools/opa_system_report16_gate.py --write
    python tools/opa_system_report16_gate.py --strict
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
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_16_SYSTEM_OPA.txt"
EVIDENCE_PATH = BUNDLES_DIR / "opa_system_report16_evidence.json"

# Paths enumerated by RAPORT_16 (tabela 2.3), kept explicit so the audit
# cannot silently shrink when a future directory scan changes. 24 Rego files.
RULE_FILES = (
    "rules/decision_core_completeness_enterprise.rego",
    "rules/micro/p24_innovations_enterprise.rego",
    "rules/p01_core_architecture_innovations_v8.rego",
    "rules/p01_fundament_innovations_v9.rego",
    "rules/p02_decision_core_innovations_v9.rego",
    "rules/p03_orchestrator_innovations_v9.rego",
    "rules/p14_compliance_innovations_v8.rego",
    "rules/p18_automatyzacja_ksiegowosci_innovations_v9.rego",
    "rules/p20_neural_mesh_innovations_v9.rego",
    "rules/p21_innovations_enterprise.rego",
    "rules/p21_opa_system_innovations_v9.rego",
    "rules/p22_innovations_enterprise.rego",
    "rules/p22_validation_tools_innovations_v9.rego",
    "rules/p23_innovations_enterprise.rego",
    "rules/p23_test_rego_ci_innovations_v9.rego",
    "rules/p24_audyt_kompletny_innovations_v9.rego",
    "rules/p24_innovations_enterprise.rego",
    "rules/p34_innovations_engine.rego",
    "rules/p34_remaining_fixes.rego",
    "rules/p35_cross_act_coherence.rego",
    "rules/p35_innovations_engine.rego",
    "rules/p35_system_gaps.rego",
    "rules/reliability_guarantee_enterprise.rego",
    "rules/rule_lifecycle_enterprise.rego",
)

TEST_FILES = (
    "tests/test_p01_control_plane.py",
    "tests/test_p02_legal.py",
    "tests/test_phase5_modules.py",
    "tests/test_strategic_v2_modules.py",
    "tests/auto/test_p01_fundament_enterprise.py",
    "tests/auto/test_p21_opa_system_enterprise.py",
    "tests/auto/test_p22_validation_tools_enterprise.py",
    "tests/auto/test_p23_test_rego_ci_enterprise.py",
    "tests/auto/test_p24_audyt_kompletny_enterprise.py",
    "tests/rego/test_p01_fundament_enterprise.rego",
    "tests/rego/test_p21_opa_system_enterprise.rego",
    "tests/rego/test_p22_validation_tools_enterprise.rego",
    "tests/rego/test_p23_test_rego_ci_enterprise.rego",
    "tests/rego/test_native_strategic_advisor_enterprise.rego",
)

# Krytyczne reguły systemu OPA (RAPORT_16): cykl życia reguły (SHADOW →
# CANDIDATE → ACTIVE, auto-rollback), gwarancja niezawodności (ADR-006
# provenance, determinizm), OPA-jako-System (P21), CI test shield (P23).
# Canonical markers = architecture references (ADR-xxx / P01–P35 / ISAP).
CRITICAL_RULES = {
    "auto_rollback": (
        "rules/rule_lifecycle_enterprise.rego",
        "jdg.rule_lifecycle.auto_rollback",
        ("ADR-", "P01", "self-healing"),
    ),
    "shadow_activation": (
        "rules/rule_lifecycle_enterprise.rego",
        "jdg.rule_lifecycle.shadow_activation",
        ("ADR-", "P01", "SHADOW"),
    ),
    "ab_rollout": (
        "rules/rule_lifecycle_enterprise.rego",
        "jdg.rule_lifecycle.ab_rollout",
        ("ADR-", "P01", "A/B"),
    ),
    "provenance_gate": (
        "rules/reliability_guarantee_enterprise.rego",
        "jdg.reliability_guarantee.provenance_gate",
        ("ADR-006", "ADR-"),
    ),
    "determinism_warning": (
        "rules/reliability_guarantee_enterprise.rego",
        "jdg.reliability_guarantee.determinism_warning",
        ("P01", "Determinism"),
    ),
    "opa_system": (
        "rules/p21_opa_system_innovations_v9.rego",
        "jdg.p21_opa_system_innovations.opa_system",
        ("ADR-001", "ADR-002", "ADR-006", "ISAP"),
    ),
    "test_shield": (
        "rules/p23_test_rego_ci_innovations_v9.rego",
        "jdg.p23_test_rego_ci_innovations.test_shield",
        ("ADR-013", "ADR-"),
    ),
}

# Test marker evidence — rule_id fragment that must appear in the joined test
# files to prove the critical rule is exercised.
CRITICAL_TEST_MARKERS = {
    "auto_rollback": ("auto_rollback",),
    "shadow_activation": ("shadow_activation",),
    "ab_rollout": ("ab_rollout",),
    "provenance_gate": ("provenance_gate",),
    "determinism_warning": ("determinism_warning",),
    "opa_system": ("opa_system",),
    "test_shield": ("test_shield",),
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
    # Następny blok zaczyna się od kolejnej DEKLARACJI rule_id z wartością
    # string ("rule_id": "..."). Wewnętrzne odwołania typu "rule_id": v.rule_id
    # (zmienna, np. w comprehensions rollback_required) NIE rozdzielają bloku.
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
            texts.get("tests/rego/test_p21_opa_system_enterprise.rego")
        ),
        "pytest_test_present": bool(
            texts.get("tests/auto/test_p21_opa_system_enterprise.py")
        ),
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
    joined = "\n".join(_read(f) for f in RULE_FILES)
    return {
        "critical_legal_basis": legal_basis,
        "critical_canonical_reference": canonical,
        "adr_references_present": "ADR-" in joined,
        "critical_rules_required": len(CRITICAL_RULES),
    }


def _router_evidence() -> dict[str, Any]:
    joined = "\n".join(_read(f) for f in ("rules/main_jdg.rego", "rules/provenance.rego"))
    return {
        "rule_lifecycle_registered": bool(re.search(r"jdg\.rule_lifecycle", joined)),
        "reliability_registered": bool(re.search(r"jdg\.reliability_guarantee", joined)),
        "p21_registered": bool(re.search(r"jdg\.p21_opa_system_innovations", joined)),
        "p22_registered": bool(re.search(r"jdg\.p22_validation_tools_innovations", joined)),
        "p23_registered": bool(re.search(r"jdg\.p23_test_rego_ci_innovations", joined)),
        "p34_registered": bool(re.search(r"jdg\.p34_innovations", joined)),
        "final_verdict": "full_final_verdict" in joined,
    }


def _safety_evidence() -> dict[str, Any]:
    joined = "\n".join(_read(f) for f in RULE_FILES)
    suggest = bool(re.search(r'"decision_mode"\s*:\s*"SUGGEST"', joined))
    # "AUTO_POST" występuje wyłącznie opisowo („nie może być AUTO_POST") — nie
    # może istnieć żadna reguła z faktycznym decision_mode AUTO_POST.
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
    system_verdicts = {
        h: v
        for h, v in verdicts.items()
        if "rule_lifecycle" in json.dumps(v, ensure_ascii=False)
        or "auto_rollback" in json.dumps(v, ensure_ascii=False)
    }
    unmatched = golden.get("unmatched_replays", [])
    if not isinstance(unmatched, list):
        unmatched = []
    return {
        "golden_verdicts_total": len(verdicts),
        "system_verdicts": len(system_verdicts),
        "replays_total": len(replays),
        "unmatched_replays": unmatched,
        "unmatched_count": len(unmatched),
        "replay_verified": len(system_verdicts) >= 1 and len(unmatched) == 0,
    }


def _deployment_evidence() -> dict[str, Any]:
    deployments = json.loads(
        (BUNDLES_DIR / "deployments.json").read_text(encoding="utf-8")
    )
    dep = deployments.get("deployments", {}).get("jdg-sop-bundle-v9.0.0", {})
    return {
        "bundle": "jdg-sop-bundle-v9.0.0",
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
        "router_wired": router["rule_lifecycle_registered"]
        and router["reliability_registered"]
        and router["p21_registered"]
        and router["p22_registered"]
        and router["p23_registered"]
        and router["p34_registered"]
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
        "report": "RAPORT_16_SYSTEM_OPA",
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
    parser = argparse.ArgumentParser(description="RAPORT_16 evidence gate")
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
            f"RAPORT_16: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
