#!/usr/bin/env python3
"""RAPORT_24 POLICIES (LUSTRO REGUŁ + OVERLAYS) — evidence gate.

Policies report: katalog ``policies/`` na poziomie repo (mirror + overlays
v2026/v2027) oraz ``bundles/policies_drift_report.json``. Zasada V1: JEDNO
źródło prawdy = ``JDG/rules/``; ``policies/`` jest warstwą overlay, nie drugim
rejestrem. Bramka weryfikuje: zakres artefaktów, overlays v2026/v2027, raport
dryfu (żywy, generowany przez policies_sync_gate), narzędzie synchronizacji,
golden replay i rekord kanar/rollback.

Usage (from ``JDG/``)::

    python tools/policies_report24_gate.py --json
    python tools/policies_report24_gate.py --write
    python tools/policies_report24_gate.py --strict
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

BASE_DIR = Path(__file__).resolve().parents[1]
REPO_ROOT = BASE_DIR.parent  # policies/ lives at the repo root
BUNDLES_DIR = BASE_DIR / "bundles"
POLICIES_DIR = REPO_ROOT / "policies"
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_24_POLICIES.txt"
EVIDENCE_PATH = BUNDLES_DIR / "policies_report24_evidence.json"

DOC_FILES = (
    "docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md",
    "docs/WIZJA_OPA_ENTERPRISE_V2.md",
    "docs/Bbb",
    "docs/LEGAL_REFERENCE_ACTS.md",
    "docs/LEGAL_COVERAGE.md",
)

TEST_FILES = (
    "tests/test_crossborder_enterprise.py",
    "tests/test_pcc_excise_enterprise.py",
    "tests/test_pkpir_uor_enterprise.py",
    "tests/auto/test_auto_block_crossborder.py",
    "tests/auto/test_auto_block_ksef_jpk.py",
    "tests/auto/test_p09_ksiegowosc_pkpir_uor_enterprise.py",
    "tests/auto/test_p11_ordynacja_podatkowa_enterprise.py",
    "tests/auto/test_p12_crossborder_enterprise.py",
    "tests/auto/test_p14_pcc_lokalne_akcyza_enterprise.py",
    "tests/auto/test_p16_rodo_aml_security_enterprise.py",
    "tests/auto/test_p17_ksef_jpk_edeklaracje_enterprise.py",
    "tests/rego/test_native_annual_declaration_enterprise.rego",
)

DRIFT_REPORT = "bundles/policies_drift_report.json"

# Artefakty policies/ (repo root) — mirror + overlays + tooling.
POLICY_ARTIFACTS = (
    "policies/Makefile",
    "policies/bundle.sh",
    "policies/data/thresholds_sc.rego",
    "policies/jdg/bundles/base/manifest.json",
    "policies/jdg/bundles/overlays/v2026/manifest.json",
    "policies/jdg/bundles/overlays/v2027/manifest.json",
    "policies/jdg/bundles/bundle.sh",
)


def _exists_base(rel: str) -> bool:
    return (BASE_DIR / rel).exists()


def _exists_repo(rel: str) -> bool:
    return (REPO_ROOT / rel).exists()


def _scope_evidence() -> dict[str, Any]:
    docs = {rel: _exists_base(rel) for rel in DOC_FILES}
    tests = {rel: _exists_base(rel) for rel in TEST_FILES}
    artifacts = {rel: _exists_repo(rel) for rel in POLICY_ARTIFACTS}
    drift = {DRIFT_REPORT: _exists_base(DRIFT_REPORT)}
    all_files = {**docs, **tests, **artifacts, **drift}
    return {
        "docs_total": len(DOC_FILES),
        "docs_present": sum(docs.values()),
        "tests_total": len(TEST_FILES),
        "tests_present": sum(tests.values()),
        "policy_artifacts_total": len(POLICY_ARTIFACTS),
        "policy_artifacts_present": sum(artifacts.values()),
        "drift_report_present": drift[DRIFT_REPORT],
        "missing": [rel for rel, ok in all_files.items() if not ok],
    }


def _overlays_evidence() -> dict[str, Any]:
    overlays = {}
    for year in ("v2026", "v2027"):
        path = POLICIES_DIR / "jdg" / "bundles" / "overlays" / year / "manifest.json"
        if path.exists():
            data = json.loads(path.read_text(encoding="utf-8"))
            overlays[year] = {
                "tax_year": data.get("tax_year"),
                "effective_from": data.get("effective_from"),
                "effective_to": data.get("effective_to"),
                "changes": len(data.get("changes", [])),
            }
        else:
            overlays[year] = None
    return {"overlays": overlays, "all_present": all(v is not None for v in overlays.values())}


def _drift_evidence() -> dict[str, Any]:
    report = json.loads((BUNDLES_DIR / "policies_drift_report.json").read_text(encoding="utf-8"))
    return {
        "generated_at": report.get("generated_at"),
        "rules_files": report.get("rules_files"),
        "policies_files": report.get("policies_files"),
        "drift_pct": report.get("drift_pct"),
        "gate_threshold_pct": report.get("gate_threshold_pct"),
        "gate_passed": report.get("gate_passed"),
        "conclusion": report.get("conclusion"),
        "reported": report.get("drift_pct") is not None
        and report.get("conclusion") is not None,
    }


def _sync_tool_evidence() -> dict[str, Any]:
    script = (BASE_DIR / "tools" / "policies_sync_gate.py")
    present = script.exists()
    text = script.read_text(encoding="utf-8", errors="ignore") if present else ""
    return {
        "present": present,
        "has_sync": "cmd_sync" in text,
        "has_drift": "cmd_drift" in text,
        "has_overlay": "cmd_overlay" in text,
        "all": present and "cmd_sync" in text and "cmd_drift" in text and "cmd_overlay" in text,
    }


def _golden_replay_evidence() -> dict[str, Any]:
    verdicts_path = BUNDLES_DIR / "golden_verdicts.json"
    if not verdicts_path.exists():
        return {"valid": False, "verdicts": 0, "replays": 0, "unmatched": []}
    data = json.loads(verdicts_path.read_text(encoding="utf-8"))
    replays = data.get("replays", [])
    unmatched = data.get("unmatched_replays", [])
    if not isinstance(unmatched, list):
        unmatched = []
    return {
        "valid": True,
        "verdicts": len(data.get("verdicts", {})),
        "replays": len(replays) if isinstance(replays, (list, dict)) else 0,
        "unmatched": unmatched,
        "unmatched_count": len(unmatched),
    }


def _deployment_evidence() -> dict[str, Any]:
    deployments = json.loads(
        (BUNDLES_DIR / "deployments.json").read_text(encoding="utf-8")
    )
    dep = deployments.get("deployments", {}).get("jdg-pol-bundle-v9.0.0", {})
    return {
        "bundle": "jdg-pol-bundle-v9.0.0",
        "phase": dep.get("phase"),
        "rollback_reason": dep.get("rollback_reason"),
        "rollback_mttr_minutes": dep.get("rollback_mttr_minutes"),
        "rollback_sla_pass": dep.get("rollback_sla_pass"),
        "active_version": deployments.get("active_version"),
    }


def build_evidence() -> dict[str, Any]:
    scope = _scope_evidence()
    overlays = _overlays_evidence()
    drift = _drift_evidence()
    sync = _sync_tool_evidence()
    replay = _golden_replay_evidence()
    deployment = _deployment_evidence()

    gates = {
        "scope_files_present": scope["docs_present"] == scope["docs_total"]
        and scope["tests_present"] == scope["tests_total"]
        and scope["policy_artifacts_present"] == scope["policy_artifacts_total"]
        and scope["drift_report_present"],
        "overlays_present": overlays["all_present"],
        "drift_reported": drift["reported"],
        "sync_tool_present": sync["all"],
        "golden_replay_ready": replay["valid"]
        and replay["verdicts"] >= 1
        and replay["unmatched_count"] == 0,
        "canary_rollback_ok": deployment["phase"] == "ROLLED_BACK"
        and deployment["rollback_reason"] is not None
        and deployment["rollback_sla_pass"] is True,
    }
    passed = sum(gates.values())
    total = len(gates)
    status = "WDROZONY_100" if passed == total else "NIEPELNY"
    return {
        "report": "RAPORT_24_POLICIES",
        "status": status,
        "gates": gates,
        "gate_summary": {"passed": passed, "total": total},
        "scope": scope,
        "overlays": overlays,
        "drift": drift,
        "sync_tool": sync,
        "replay": replay,
        "deployment": deployment,
        "generated_at": __import__("datetime").datetime.now(
            __import__("datetime").timezone.utc
        ).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="RAPORT_24 evidence gate")
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
            f"RAPORT_24: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
        print(f"  drift: {evidence['drift']['drift_pct']}% "
              f"({evidence['drift']['conclusion']})")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
