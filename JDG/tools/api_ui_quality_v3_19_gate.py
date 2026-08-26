#!/usr/bin/env python3
"""V3-19 API + CONTROL PLANE + UI / CENTRUM DECYZJI — evidence gate.

Przeprowadź głębokie myślenie i przeprowadź głęboką analizę przed zmianą progów:
gate nie serwuje API ani nie obsługuje UI — bramkuje WYNIKI audytu specyfikacji,
authZ i cyklu życia control plane (evidence) względem kontraktu api_ui_quality_v3_19.
OPA check/test pozostaje osobną bramką CI.
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
EVIDENCE = ROOT / "bundles" / "api_ui_v3_audit_19.json"
REPORT = ROOT / "raporty_enterprise_v3" / "19_API_UI.txt"

SCOPE = [
    # API spec + dokumentacja + audyt spójności
    "api/openapi.yaml",
    "docs/API_REFERENCJA.md",
    "tools/api_spec_consistency.py",
    # Control Plane lifecycle
    "tools/control_plane_lifecycle.py",
    "tools/rule_lifecycle_manager.py",
    "tools/declarative_change.py",
    "docs/CONTROL_PLANE_RULE_LIFECYCLE.md",
    # UI / centrum decyzji
    "docs/PODRECZNIK_UZYTKOWNIKA.md",
    # Kontrakt jakościowy + infrastruktura + testy
    "rules/api_ui/quality_v3_19.rego",
    "rules/thresholds_jdg.rego",
    "rules/main_jdg.rego",
    "tests/test_api_ui_quality_v3_19.py",
    "tests/rego/test_native_api_ui_quality_v3_19.rego",
]

REQUIRED_RULE_MARKERS = [
    "api_ok", "consistency_ok", "authz_ok", "decision_center_ok", "lifecycle_ok",
    "declarative_ok", "resilience_ok", "versioning_ok", "temporal_valid",
    "BLOCK_AND_ALERT", "TRIAGE_QUEUE", "no_auto_post", "DECOUPLED",
]
REQUIRED_LEGAL = ["OrdPU", "PIT", "VAT", "RODO"]
REQUIRED_SNAPSHOT_KEYS = [
    "threshold_version", "registry_version", "legal_basis_version", "valid_from", "valid_to",
    "min_api_endpoints", "max_documented_only_gaps", "min_soak_hours", "required_decision_modes",
]
REQUIRED_OPENAPI_MARKERS = [
    "IdempotencyKey", "x-api-versioning", "x-rbac", "x-sod", "BearerAuth",
    "breaking_changes", "x-rate-limit", "/jdg/ready", "/jdg/health",
    "AUTO_POST", "SUGGEST", "ASK_USER",
]


def read(rel: str) -> str:
    try:
        return (ROOT / rel).read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return ""


def rule_ids(text: str) -> list[str]:
    return re.findall(r'"rule_id"\s*:\s*"([A-Za-z0-9_.-]+)"', text)


def audit_scope() -> dict[str, Any]:
    files = {rel: bool(read(rel)) for rel in SCOPE}
    return {
        "files_total": len(files),
        "files_present": sum(files.values()),
        "missing": [rel for rel, present in files.items() if not present],
        "scope_complete": all(files.values()),
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
    contract = read("rules/api_ui/quality_v3_19.rego")
    thresholds = read("rules/thresholds_jdg.rego")
    main = read("rules/main_jdg.rego")
    markers = {marker: marker in contract for marker in REQUIRED_RULE_MARKERS}
    snap_idx = thresholds.find("api_ui_quality_v3_19 := {")
    snapshot_block = thresholds[snap_idx:].split("\n}")[0] if snap_idx >= 0 else ""
    modes = {"AUTO_POST", "SUGGEST", "ASK_USER"}
    modes_in_snapshot = all(mode in snapshot_block for mode in modes)
    return {
        "contract_markers": markers,
        "contract_complete": all(markers.values()),
        "snapshot_present": "api_ui_quality_v3_19 := {" in thresholds,
        "snapshot_versioned": all(key in snapshot_block for key in REQUIRED_SNAPSHOT_KEYS) and modes_in_snapshot,
        "import_present": "import data.jdg.api_ui.quality_v3_19 as api_ui_quality_v3_19" in main,
        "p79_present": "final_verdict_p79 = safe_merge(final_verdict_p78" in main,
        "post_merge_anchor_current": bool(re.search(r"final_verdict_post_merge = safe_merge\(\s*\{\"_routing_context\": routing_context\},\s*final_verdict_(p7[4-9]|p8[0-5])", main)),
        "no_auto_post_guard": '"no_auto_post": true' in contract,
    }


def audit_api_spec() -> dict[str, Any]:
    openapi = read("api/openapi.yaml")
    consistency_tool = read("tools/api_spec_consistency.py")
    markers = {marker: marker in openapi for marker in REQUIRED_OPENAPI_MARKERS}
    evidence = {}
    ev_path = ROOT / "bundles" / "api_spec_consistency.json"
    if ev_path.exists():
        try:
            evidence = json.loads(ev_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            evidence = {}
    return {
        "openapi_markers": markers,
        "openapi_markers_complete": all(markers.values()),
        "consistency_audit_wired": "PATH_ARTIFACTS" in consistency_tool and "DOCUMENTED_ONLY" in consistency_tool,
        "spec_paths_implemented": evidence.get("implemented", 0),
        "spec_gap_count": evidence.get("gap_count", 99999),
        "spec_no_gaps": evidence.get("gap_count", 99999) == 0 and evidence.get("markers_complete", False),
    }


def audit_control_plane() -> dict[str, Any]:
    cpl = read("tools/control_plane_lifecycle.py")
    rlm = read("tools/rule_lifecycle_manager.py")
    dc = read("tools/declarative_change.py")
    doc = read("docs/CONTROL_PLANE_RULE_LIFECYCLE.md")
    return {
        "lifecycle_stages": all(stage in (cpl.upper() + doc.upper()) for stage in ["PENDING_REVIEW", "REVIEW", "AUTHORIZE", "CANARY", "SHADOW_COMPARE", "RAMPED", "SOAK", "ACTIVE"]),
        "four_eyes_sod": ("author" in cpl.lower() and "reviewer" in cpl.lower()) or "separation of duties" in doc.lower(),
        "rollback_supported": "ROLLBACK" in cpl.upper(),
        "rule_lifecycle_ops": all(op in rlm for op in ["register", "promote", "suspend", "deprecate", "retire"]),
        "declarative_wizard": all(cmd in dc for cmd in ["plan", "execute", "template"]),
        "declarative_dry_run_default": "--execute-data" in dc,
        "declarative_never_automated": "never_automated" in dc,
    }


def audit_decision_center() -> dict[str, Any]:
    handbook = read("docs/PODRECZNIK_UZYTKOWNIKA.md").upper()
    openapi = read("api/openapi.yaml").upper()
    refdoc = read("docs/API_REFERENCJA.md").upper()
    joined = handbook + openapi + refdoc
    modes = {mode: mode in joined for mode in ["AUTO_POST", "SUGGEST", "ASK_USER", "NEEDS_ADVICE"]}
    return {
        "modes": modes,
        "modes_documented": all(modes.values()),
        "certainty_guard_mentioned": "CERTAINTY_BLOCKED" in joined or "NEEDS_ADVICE" in joined,
    }


def audit_tests() -> dict[str, Any]:
    pytest_text = read("tests/test_api_ui_quality_v3_19.py")
    native_text = read("tests/rego/test_native_api_ui_quality_v3_19.rego")
    joined = pytest_text + native_text
    required = ["full_contract", "fail_closed", "decision_center", "authz", "resilience", "no_auto_post"]
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
    spec = audit_api_spec()
    cp = audit_control_plane()
    dc = audit_decision_center()
    tests = audit_tests()
    opa = opa_check()
    gates = {
        "scope_complete": scope["scope_complete"],
        "metadata_complete": metadata["duplicate_free"] and metadata["legal_markers_complete"] and metadata["empty_legal_basis"] == 0,
        "contract_complete": contract["contract_complete"] and contract["snapshot_present"] and contract["snapshot_versioned"],
        "router_wired": contract["import_present"] and contract["p79_present"] and contract["post_merge_anchor_current"],
        "api_spec_complete": spec["openapi_markers_complete"] and spec["consistency_audit_wired"] and spec["spec_no_gaps"],
        "control_plane_complete": all(cp.values()),
        "decision_center_documented": dc["modes_documented"] and dc["certainty_guard_mentioned"],
        "artifacts_and_tests_ready": tests["tests_complete"] and REPORT.exists() and REGISTRY.exists(),
    }
    passed = sum(gates.values())
    return {
        "report": "V3-19_API_UI",
        "status": "WDROZONY_100" if passed == len(gates) else "NIEPELNY",
        "gates": gates,
        "gate_summary": {"passed": passed, "total": len(gates)},
        "scope": scope,
        "metadata": metadata,
        "contract": contract,
        "api_spec": spec,
        "control_plane": cp,
        "decision_center": dc,
        "tests": tests,
        "opa": opa,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="API/UI/control plane V3-19 evidence gate")
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
        print(f"V3-19 API_UI gate: {passed}/{total} PASS ({evidence['status']})")
    failed = [name for name, ok in evidence["gates"].items() if not ok]
    if failed:
        print(f"FAILED gates: {', '.join(failed)}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
