#!/usr/bin/env python3
"""V3-18 BUNDLES + POLICIES MIRROR + RULESTORE + MIGRACJE + DEPLOY — evidence gate.

Przeprowadź głębokie myślenie i przeprowadź głęboką analizę przed zmianą progów:
gate nie buduje ani nie wdraża bundli — bramkuje WYNIKI control plane (evidence)
względem kontraktu bundles_quality_v3_18. OPA check/test pozostaje osobną bramką CI.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "bundles" / "enterprise_v3_registry.json"
EVIDENCE = ROOT / "bundles" / "bundles_v3_audit_18.json"
REPORT = ROOT / "raporty_enterprise_v3" / "18_BUNDLES.txt"

SCOPE = [
    # Bundles
    "bundles/bundle.sh",
    # Overlays / policies
    "tools/overlay_engine.py",
    "tools/overlay_generator.py",
    # RuleStore / migracje
    "migrations/001_jdg_rule_store.sql",
    "migrations/013_jdg_v18_tools_api_rulestore_bundles.sql",
    # Narzędzia control plane
    "tools/bundle_server.py",
    "tools/deployment_orchestrator.py",
    "tools/data_service.py",
    "tools/dr_orchestrator.py",
    "tools/policies_sync_gate.py",
    # Kontrakt jakościowy + infrastruktura + testy
    "rules/bundles/quality_v3_18.rego",
    "rules/thresholds_jdg.rego",
    "rules/main_jdg.rego",
    "tests/test_bundles_quality_v3_18.py",
    "tests/rego/test_native_bundles_quality_v3_18.rego",
]

REPO_FILES = [
    "policies/README.md",  # mirror — single source of truth (repo root)
]

REQUIRED_RULE_MARKERS = [
    "bundle_ok", "verify_ok", "overlay_ok", "mirror_ok", "rulestore_ok",
    "canary_ok", "dr_ok", "temporal_valid", "BLOCK_AND_ALERT", "TRIAGE_QUEUE",
    "no_auto_post", "DECOUPLED",
]
REQUIRED_LEGAL = ["OrdPU", "PIT", "VAT", "eIDAS"]
REQUIRED_SNAPSHOT_KEYS = [
    "threshold_version", "registry_version", "legal_basis_version", "valid_from", "valid_to",
    "min_rulestore_migrations", "max_hot_reload_seconds", "max_rollback_mttr_min",
    "max_mirror_drift_pct", "max_rto_min", "max_rpo_min", "dr_game_day_max_days",
]


def read(rel: str, base: Path | None = None) -> str:
    root = base or ROOT
    try:
        return (root / rel).read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return ""


def rule_ids(text: str) -> list[str]:
    return re.findall(r'"rule_id"\s*:\s*"([A-Za-z0-9_.-]+)"', text)


def audit_scope() -> dict[str, Any]:
    files = {rel: bool(read(rel)) for rel in SCOPE}
    repo = {rel: bool(read(rel, ROOT.parent)) for rel in REPO_FILES}
    policies_count = len(list((ROOT.parent / "policies").glob("**/*.rego"))) if (ROOT.parent / "policies").exists() else 0
    all_files = {**files, **repo}
    return {
        "files_total": len(all_files),
        "files_present": sum(all_files.values()),
        "missing": [rel for rel, present in all_files.items() if not present],
        "mirror_rego_files": policies_count,
        "scope_complete": all(all_files.values()) and policies_count > 0,
    }


def audit_metadata() -> dict[str, Any]:
    texts = {rel: read(rel) for rel in SCOPE if rel.endswith(".rego")}
    ids = [rid for text in texts.values() for rid in rule_ids(text)]
    duplicates = sorted(rid for rid, count in Counter(ids).items() if count > 1)
    legal_hits = {marker: any(marker in text for text in texts.values()) for marker in REQUIRED_LEGAL}
    return {
        "rule_ids_total": len(ids),
        "rule_ids_unique": len(set(ids)),
        "duplicate_rule_ids": duplicates,
        "duplicate_free": not duplicates,
        "legal_markers": legal_hits,
        "legal_markers_complete": all(legal_hits.values()),
        "empty_legal_basis": sum(text.count('"_legal_basis":""') + text.count('"_legal_basis": ""') for text in texts.values()),
    }


def audit_contract() -> dict[str, Any]:
    contract = read("rules/bundles/quality_v3_18.rego")
    thresholds = read("rules/thresholds_jdg.rego")
    main = read("rules/main_jdg.rego")
    markers = {marker: marker in contract for marker in REQUIRED_RULE_MARKERS}
    snap_idx = thresholds.find("bundles_quality_v3_18 := {")
    snapshot_block = thresholds[snap_idx:].split("\n}")[0] if snap_idx >= 0 else ""
    return {
        "contract_markers": markers,
        "contract_complete": all(markers.values()),
        "snapshot_present": "bundles_quality_v3_18 := {" in thresholds,
        "snapshot_versioned": all(key in snapshot_block for key in REQUIRED_SNAPSHOT_KEYS),
        "import_present": "import data.jdg.bundles.quality_v3_18 as bundles_quality_v3_18" in main,
        "p78_present": "final_verdict_p78 = safe_merge(final_verdict_p77" in main,
        "post_merge_anchor_current": bool(re.search(r"final_verdict_post_merge = safe_merge\(\s*\{\"_routing_context\": routing_context\},\s*final_verdict_(p7[4-9]|p8[0-5])", main)),
        "no_auto_post_guard": '"no_auto_post": true' in contract,
    }


def audit_tools() -> dict[str, Any]:
    bsh = read("bundles/bundle.sh")
    dep = read("tools/deployment_orchestrator.py")
    dr = read("tools/dr_orchestrator.py")
    ds = read("tools/data_service.py")
    sync = read("tools/policies_sync_gate.py")
    ov = read("tools/overlay_engine.py")
    return {
        "bundle_sign_mode": '"${2:-sign}"' in bsh and "SIGN_MODE" in bsh,
        "bundle_sbom_and_signature": "SBOM_FILE" in bsh and "SIG_FILE" in bsh,
        "bundle_verify_mode": "VERIFY" in bsh.upper(),
        "bundle_count_gate": "BRAMKA" in bsh and "ABORT" in bsh,
        "deployment_canary_rollback": "CANARY" in dep.upper() and "ROLLED_BACK" in dep.upper() or "rollback" in dep.lower(),
        "dr_rto_rpo": "rto" in dr.lower() and "rpo" in dr.lower(),
        "data_service_hot_reload": "hot_reload" in ds.lower() or "hot-reload" in ds.lower(),
        "policies_sync_drift": "drift" in sync.lower() or "parity" in sync.lower(),
        "overlay_engine": bool(ov),
    }


def audit_tests() -> dict[str, Any]:
    pytest_text = read("tests/test_bundles_quality_v3_18.py")
    native_text = read("tests/rego/test_native_bundles_quality_v3_18.rego")
    joined = pytest_text + native_text
    required = ["full_contract", "fail_closed", "signature", "mirror", "canary", "no_auto_post"]
    hits = {marker: marker.lower() in joined.lower() for marker in required}
    return {
        "pytest_present": bool(pytest_text),
        "native_rego_present": bool(native_text),
        "markers": hits,
        "tests_complete": all(hits.values()),
        "pytest_functions": len(re.findall(r"def test_", pytest_text)),
    }


def opa_check() -> dict[str, Any]:
    try:
        proc = subprocess.run(["opa", "check", "-b", str(ROOT / "rules")], cwd=ROOT, text=True, capture_output=True, timeout=30)
    except (OSError, subprocess.SubprocessError):
        return {"available": False, "passed": None, "message": "OPA CLI unavailable locally; CI gate required."}
    return {"available": True, "passed": proc.returncode == 0, "message": (proc.stdout + proc.stderr)[-4000:]}


def build() -> dict[str, Any]:
    scope = audit_scope()
    metadata = audit_metadata()
    contract = audit_contract()
    tools = audit_tools()
    tests = audit_tests()
    opa = opa_check()
    gates = {
        "scope_complete": scope["scope_complete"],
        "metadata_complete": metadata["duplicate_free"] and metadata["legal_markers_complete"] and metadata["empty_legal_basis"] == 0,
        "contract_complete": contract["contract_complete"] and contract["snapshot_present"] and contract["snapshot_versioned"],
        "router_wired": contract["import_present"] and contract["p78_present"] and contract["post_merge_anchor_current"],
        "tools_complete": all(tools.values()),
        "tests_complete": tests["tests_complete"],
        "report_present": REPORT.exists(),
        "registry_present": REGISTRY.exists(),
    }
    passed = sum(gates.values())
    return {
        "report": "V3-18_BUNDLES",
        "status": "WDROZONY_100" if passed == len(gates) else "NIEPELNY",
        "gates": gates,
        "gate_summary": {"passed": passed, "total": len(gates)},
        "scope": scope,
        "metadata": metadata,
        "contract": contract,
        "tools": tools,
        "tests": tests,
        "opa": opa,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Bundles/deploy V3-18 evidence gate")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    evidence = build()
    if args.write:
        EVIDENCE.write_text(json.dumps(evidence, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"Evidence: {EVIDENCE.relative_to(ROOT)} ({evidence['status']})")
    elif args.json:
        print(json.dumps(evidence, indent=2, ensure_ascii=False))
    else:
        passed = evidence["gate_summary"]["passed"]
        total = evidence["gate_summary"]["total"]
        print(f"V3-18 BUNDLES gate: {passed}/{total} PASS ({evidence['status']})")
    failed = [name for name, ok in evidence["gates"].items() if not ok]
    if failed:
        print(f"FAILED gates: {', '.join(failed)}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
