#!/usr/bin/env python3
"""Fail-closed validator for the GLM52 Enterprise operating contract.

The validator certifies only the stage-00 contract and its hand-off metadata.
It deliberately does not claim that the whole policy system is deployed or
that production telemetry exists.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
JDG_ROOT = REPO_ROOT / "JDG"
CONTRACT_PATH = JDG_ROOT / "bundles" / "enterprise_operating_contract.json"
REPORT_PATH = JDG_ROOT / "raporty_glm52_enterprise" / "00_MASTER_OPERATING_CONTRACT.txt"
STAGE_RE = re.compile(r"^ETAP_(?:0[0-9]|1[0-9]|2[0-8])$")
PROMPT_RE = re.compile(r"^JDG/prompty_glm52_enterprise/(?:0[0-9]|1[0-9]|2[0-8])_[^/]+\.txt$")
REPORT_RE = re.compile(r"^JDG/raporty_glm52_enterprise/(?:0[0-9]|1[0-9]|2[0-8])_[^/]+\.txt$")


def _load() -> dict:
    return json.loads(CONTRACT_PATH.read_text(encoding="utf-8"))


def _repo_path(relative: str) -> Path:
    return REPO_ROOT / relative


def validate(contract: dict | None = None) -> list[str]:
    """Return all violations; an empty list is the only PASS result."""
    contract = contract or _load()
    issues: list[str] = []

    if contract.get("schema_version") != "1.0.0":
        issues.append("G01: unsupported schema_version")
    if contract.get("contract_id") != "jdg.enterprise.master_operating_contract":
        issues.append("G01: invalid contract_id")
    if contract.get("stage") != "ETAP_00":
        issues.append("G01: contract must describe ETAP_00")
    if contract.get("production_activation") != "NOT_CERTIFIED":
        issues.append("G04: contract cannot certify production activation")

    stages = contract.get("dependency_map", {})
    expected = [f"ETAP_{i:02d}" for i in range(29)]
    if list(stages) != expected:
        issues.append("G01: dependency_map must contain ETAP_00..ETAP_28 in order")
    for index, stage in enumerate(expected):
        if not STAGE_RE.fullmatch(stage):
            issues.append(f"G01: invalid stage id {stage}")
        expected_dependencies = [] if index == 0 else [f"ETAP_{index - 1:02d}"]
        if stages.get(stage) != expected_dependencies:
            issues.append(f"G01: invalid dependency for {stage}")

    for source in contract.get("required_architecture_sources", []):
        if not _repo_path(source).exists():
            issues.append(f"G02: missing source {source}")

    stage = contract.get("stage_00", {})
    prompt_path = stage.get("prompt_path", "")
    report_path = stage.get("report_path", "")
    if not PROMPT_RE.fullmatch(prompt_path) or not _repo_path(prompt_path).is_file():
        issues.append(f"G01/G02: invalid or missing stage prompt {prompt_path}")
    if not REPORT_RE.fullmatch(report_path) or not _repo_path(report_path).is_file():
        issues.append(f"G01/G07: invalid or missing stage report {report_path}")
    if stage.get("status") != "WDROZONY_100":
        issues.append("G07: stage_00 status is not WDROZONY_100")

    required_fields = {
        "stage_id", "prompt_path", "report_path", "status", "implementation_scope",
        "inputs", "outputs", "dependencies", "evidence", "gates", "production_activation",
    }
    actual_fields = set(contract.get("stage_data_contract", {}).get("required_fields", []))
    missing_fields = required_fields - actual_fields
    if missing_fields:
        issues.append(f"G01: missing stage data fields {sorted(missing_fields)}")

    report = _repo_path(report_path) if report_path else REPORT_PATH
    if report.is_file():
        text = report.read_text(encoding="utf-8")
        required_sections = contract.get("report_schema", {}).get("required_sections", [])
        for section in required_sections:
            if section not in text:
                issues.append(f"G01/G07: report section missing: {section}")
        if "Status raportu: WDROŻONY_100" not in text:
            issues.append("G07: report does not carry WDROŻONY_100 status")
        if "ETAP_00_COMPLETE — CONTEXT_RESET_REQUIRED" not in text:
            issues.append("G07: required context-reset handoff marker missing")

    slo = contract.get("slo_sla", {})
    for key in (
        "decision_latency_p95_ms_domestic", "rollback_minutes", "parameter_hot_reload_minutes",
        "shadow_delta_max_percent", "duplicate_rule_ids_target", "production_stub_target",
    ):
        if key not in slo:
            issues.append(f"G01: missing SLO/SLA key {key}")
    if slo.get("duplicate_rule_ids_target") != 0 or slo.get("production_stub_target") != 0:
        issues.append("G03: duplicate/stub targets must be zero")

    gates = contract.get("pass_fail_gates", [])
    gate_ids = [gate.get("id") for gate in gates]
    if gate_ids != [f"G0{i}_{name}" for i, name in enumerate(
        ["CONTRACT_SCHEMA", "SOURCE_INVENTORY", "RULE_QUALITY", "RUNTIME_SAFETY",
         "GOLDEN_REPLAY", "PROGRESSIVE_DELIVERY", "STATUS_HANDOFF"], 1
    )]:
        issues.append("G01: pass/fail gate IDs are incomplete or out of order")
    if any(gate.get("on_fail") != "BLOCK" for gate in gates):
        issues.append("G03: every gate must be fail-closed with on_fail=BLOCK")

    return issues


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Validate GLM52 Enterprise ETAP_00 contract")
    parser.add_argument("--json", action="store_true", help="emit a machine-readable result")
    args = parser.parse_args(argv)
    issues = validate()
    result = {
        "contract": str(CONTRACT_PATH.relative_to(REPO_ROOT)),
        "stage": "ETAP_00",
        "status": "PASS" if not issues else "FAIL",
        "issues": issues,
        "production_activation": "NOT_CERTIFIED",
    }
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    elif issues:
        print("FAIL — ETAP_00 operating contract")
        for issue in issues:
            print(f"  - {issue}")
    else:
        print("PASS — ETAP_00 operating contract; production activation remains NOT_CERTIFIED")
    return 0 if not issues else 1


if __name__ == "__main__":
    sys.exit(main())
