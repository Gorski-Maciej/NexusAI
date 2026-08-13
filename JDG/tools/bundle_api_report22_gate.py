#!/usr/bin/env python3
"""RAPORT_22 BUNDLE / API / MIGRACJE — evidence gate.

Bundle/API/migrations report: bundles/*.json + bundle.sh, api/openapi.yaml,
migrations/001..003_*.sql. Weryfikuje obecność artefaktów, spójność metryk
manifestu z rzeczywistą zawartością rules/ (L2), niepusty rule_registry.json,
obecność migracji RuleStore, golden replay i rekord kanar/rollback.

Usage (from ``JDG/``)::

    python tools/bundle_api_report22_gate.py --json
    python tools/bundle_api_report22_gate.py --write
    python tools/bundle_api_report22_gate.py --strict
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

BASE_DIR = Path(__file__).resolve().parents[1]
BUNDLES_DIR = BASE_DIR / "bundles"
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_22_BUNDLE_API_MIGRACJE.txt"
EVIDENCE_PATH = BUNDLES_DIR / "bundle_api_report22_evidence.json"

DOC_FILES = (
    "docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md",
    "docs/WIZJA_OPA_ENTERPRISE_V2.md",
    "docs/Bbb",
    "docs/LEGAL_REFERENCE_ACTS.md",
    "docs/LEGAL_COVERAGE.md",
)

BUNDLE_FILES = (
    "bundles/bundle.sh",
    "bundles/manifest.json",
    "bundles/manifest_v2.json",
    "bundles/policy_registry.json",
    "bundles/legal_graph.json",
    "bundles/thresholds_data.json",
    "bundles/deployments.json",
    "bundles/impact_matrix.json",
    "bundles/law_radar.json",
    "bundles/policies_drift_report.json",
    "bundles/healthy_versions.json",
    "bundles/rule_registry.json",
    "bundles/legal_reference_canon.json",
    "bundles/legal_basis_audit.json",
    "bundles/legal_coverage_gaps.json",
    "bundles/legal_basis_v2_report.json",
    "bundles/coverage_deserts.json",
    "bundles/legal_change_calendar.json",
    "bundles/accounting_compliance.json",
    "bundles/hardcoded_audit.json",
    "bundles/vat_micro_inventory.json",
    "bundles/pit_micro_inventory.json",
    "bundles/zus_micro_inventory.json",
)

API_FILES = ("api/openapi.yaml",)

MIGRATION_FILES = (
    "migrations/001_jdg_rule_store.sql",
    "migrations/002_jdg_enterprise_v7.sql",
    "migrations/003_jdg_v8_legal_twin.sql",
)

TEST_FILES = (
    "tests/test_p01_control_plane.py",
    "tests/test_risk_api.py",
    "tests/test_tax_pipeline.py",
    "tests/auto/test_p01_fundament_enterprise.py",
    "tests/rego/test_p01_fundament_enterprise.rego",
)

_RULEID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
_MATCHED_TRUE_RE = re.compile(r'"matched"\s*:\s*true')


def _exists(rel: str) -> bool:
    return (BASE_DIR / rel).exists()


def _scope_evidence() -> dict[str, Any]:
    docs = {rel: _exists(rel) for rel in DOC_FILES}
    bundles = {rel: _exists(rel) for rel in BUNDLE_FILES}
    api = {rel: _exists(rel) for rel in API_FILES}
    migrations = {rel: _exists(rel) for rel in MIGRATION_FILES}
    tests = {rel: _exists(rel) for rel in TEST_FILES}
    all_files = {**docs, **bundles, **api, **migrations, **tests}
    return {
        "docs_total": len(DOC_FILES),
        "docs_present": sum(docs.values()),
        "bundles_total": len(BUNDLE_FILES),
        "bundles_present": sum(bundles.values()),
        "api_total": len(API_FILES),
        "api_present": sum(api.values()),
        "migrations_total": len(MIGRATION_FILES),
        "migrations_present": sum(migrations.values()),
        "tests_total": len(TEST_FILES),
        "tests_present": sum(tests.values()),
        "missing": [rel for rel, ok in all_files.items() if not ok],
    }


def _manifest_evidence() -> dict[str, Any]:
    """L2: spójność metryk manifestu z rzeczywistą zawartością rules/."""
    manifest = json.loads((BUNDLES_DIR / "manifest.json").read_text(encoding="utf-8"))
    meta = manifest.get("metadata", {})

    files = sorted((BASE_DIR / "rules").rglob("*.rego"))
    occurrences = 0
    uniq: set[str] = set()
    matched_files = 0
    for path in files:
        text = path.read_text(encoding="utf-8", errors="ignore")
        ids = _RULEID_RE.findall(text)
        occurrences += len(ids)
        uniq.update(ids)
        if _MATCHED_TRUE_RE.search(text):
            matched_files += 1

    actual = {
        "files_count": len(files),
        "rules_count": occurrences,
        "unique_rule_ids": len(uniq),
        "files_with_matched_true": matched_files,
    }
    declared = {
        "files_count": meta.get("files_count"),
        "rules_count": meta.get("rules_count"),
        "unique_rule_ids": meta.get("unique_rule_ids"),
        "files_with_matched_true": meta.get("files_with_matched_true"),
    }
    mismatches = {k: {"declared": declared[k], "actual": actual[k]}
                  for k in actual if declared[k] != actual[k]}
    return {
        "actual": actual,
        "declared": declared,
        "mismatches": mismatches,
        "consistent": not mismatches,
    }


def _rule_registry_evidence() -> dict[str, Any]:
    registry = json.loads((BUNDLES_DIR / "rule_registry.json").read_text(encoding="utf-8"))
    rule_ids = list(registry.keys())
    active = []
    for rid, entry in registry.items():
        for v in entry.get("versions", []):
            if v.get("status") == "ACTIVE":
                active.append(rid)
                break
    return {
        "rule_ids": len(rule_ids),
        "active": len(active),
        "populated": len(rule_ids) > 0 and len(active) > 0,
    }


def _bundle_signature_evidence() -> dict[str, Any]:
    """Bundle signing (HSM): bundle.sh musi zawierać podpisywanie + weryfikację."""
    script = (BUNDLES_DIR / "bundle.sh").read_text(encoding="utf-8", errors="ignore")
    has_sign = "opa sign" in script and "signing_key" in script
    has_verify = "VERIFY" in script or "verify" in script.lower()
    has_sbom = "SBOM" in script and "sha256" in script.lower()
    return {"signing_supported": has_sign, "verification_supported": has_verify,
            "sbom_supported": has_sbom, "all": has_sign and has_verify and has_sbom}


def _migrations_evidence() -> dict[str, Any]:
    tables: set[str] = set()
    for rel in MIGRATION_FILES:
        text = (BASE_DIR / rel).read_text(encoding="utf-8", errors="ignore")
        tables.update(re.findall(r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?["\w.]+', text, re.I))
    return {"tables_found": sorted(tables), "has_rule_store": any(
        "rule" in t.lower() or "legal" in t.lower() for t in tables)}


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
    dep = deployments.get("deployments", {}).get("jdg-bap-bundle-v9.0.0", {})
    return {
        "bundle": "jdg-bap-bundle-v9.0.0",
        "phase": dep.get("phase"),
        "rollback_reason": dep.get("rollback_reason"),
        "rollback_mttr_minutes": dep.get("rollback_mttr_minutes"),
        "rollback_sla_pass": dep.get("rollback_sla_pass"),
        "active_version": deployments.get("active_version"),
    }


def build_evidence() -> dict[str, Any]:
    scope = _scope_evidence()
    manifest = _manifest_evidence()
    registry = _rule_registry_evidence()
    signature = _bundle_signature_evidence()
    migrations = _migrations_evidence()
    replay = _golden_replay_evidence()
    deployment = _deployment_evidence()

    gates = {
        "scope_files_present": scope["docs_present"] == scope["docs_total"]
        and scope["bundles_present"] == scope["bundles_total"]
        and scope["api_present"] == scope["api_total"]
        and scope["migrations_present"] == scope["migrations_total"]
        and scope["tests_present"] == scope["tests_total"],
        "manifest_consistent": manifest["consistent"],
        "rule_registry_populated": registry["populated"],
        "bundle_signing_supported": signature["all"],
        "migrations_present": scope["migrations_present"] == scope["migrations_total"]
        and migrations["has_rule_store"],
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
        "report": "RAPORT_22_BUNDLE_API_MIGRACJE",
        "status": status,
        "gates": gates,
        "gate_summary": {"passed": passed, "total": total},
        "scope": scope,
        "manifest": manifest,
        "rule_registry": registry,
        "bundle_signature": signature,
        "migrations": migrations,
        "replay": replay,
        "deployment": deployment,
        "generated_at": __import__("datetime").datetime.now(
            __import__("datetime").timezone.utc
        ).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="RAPORT_22 evidence gate")
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
            f"RAPORT_22: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
