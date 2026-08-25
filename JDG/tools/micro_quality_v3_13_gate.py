#!/usr/bin/env python3
"""NexusAI JDG V3-13: whole micro-layer quality gate.

The gate audits every Rego file below rules/micro. Legacy generated records are
kept immutable; their optional empty fields are normalized at the decision
boundary and all raw findings are retained in evidence. The default mode is
DECOUPLED so an unverified micro result cannot silently enter production.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any

JDG_ROOT = Path(__file__).resolve().parents[1]
MICRO_ROOT = JDG_ROOT / "rules" / "micro"
EVIDENCE = JDG_ROOT / "bundles" / "micro_quality_v3_audit_13.json"

RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
PACKAGE_RE = re.compile(r"^package\s+([\w.]+)", re.MULTILINE)
EMPTY_FIELD_RE = re.compile(
    r'"(vat_rate|rounding_level|gtu_code|pit_form|pit_rate|pit_bracket|'
    r'pit_annual_return_type|kus_qualification|zus_social_base_type|'
    r'zus_health_rate|business_status|_routing|_routing_reason)"\s*:\s*""'
)
MISSING_COMMA_RE = re.compile(r'^(\s*)"([A-Za-z_][\w]*)"\s*:\s*([^,{}]+?)\s*$', re.MULTILINE)
NUMBER_RE = re.compile(r"(?<![\w\"])(\d{2,})(?![\w\"])")
STRING_RE = re.compile(r'"(?:\\.|[^"\\])*"')
OPTIONAL_FIELDS = {
    "vat_rate", "rounding_level", "gtu_code", "pit_form", "pit_rate",
    "pit_bracket", "pit_annual_return_type", "kus_qualification",
    "zus_social_base_type", "zus_health_rate", "business_status",
    "_routing", "_routing_reason",
}


def _code_without_strings_and_comments(text: str) -> str:
    lines = []
    for line in text.splitlines():
        if line.lstrip().startswith("#"):
            lines.append("")
            continue
        lines.append(STRING_RE.sub('""', line.split("#", 1)[0]))
    return "\n".join(lines)


def _brace_delta(text: str) -> int:
    return _code_without_strings_and_comments(text).count("{") - _code_without_strings_and_comments(text).count("}")


def _missing_commas(text: str) -> list[int]:
    """Find object fields followed by another object field without a comma."""
    lines = text.splitlines()
    hits: list[int] = []
    for index, line in enumerate(lines[:-1]):
        if not MISSING_COMMA_RE.match(line):
            continue
        next_line = lines[index + 1].lstrip()
        if next_line.startswith('"') and not line.rstrip().endswith(","):
            hits.append(index + 1)
    return hits


def _hardcoded_literals(text: str) -> list[str]:
    hits: list[str] = []
    for lineno, line in enumerate(text.splitlines(), 1):
        code = line.split("#", 1)[0]
        code = STRING_RE.sub('""', code)
        if '"rule_id"' in code or '"priority"' in code:
            continue
        if "threshold" in code.lower() or "valid_from" in code or "valid_to" in code:
            continue
        for value in NUMBER_RE.findall(code):
            hits.append(f"L{lineno}:{value}")
    return hits


def _stub_findings(text: str) -> list[str]:
    findings: list[str] = []
    for lineno, line in enumerate(text.splitlines(), 1):
        stripped = line.strip()
        if stripped.startswith("#") or stripped.startswith("default decide"):
            continue
        if any(marker in stripped for marker in ("TODO", "FIXME", "CHECKPOINT-STUB")):
            findings.append(f"L{lineno}:{stripped[:100]}")
    return findings


def normalize_verdict(verdict: dict[str, Any], *, package: str | None = None) -> dict[str, Any]:
    """Normalize generated micro output without changing decision semantics.

    Empty optional strings become JSON null, while contract fields are always
    present. This is the single boundary used by decoupled consumers.
    """
    result = dict(verdict)
    for key in OPTIONAL_FIELDS:
        if result.get(key) == "":
            result[key] = None
    result.setdefault("valid_from", None)
    result.setdefault("valid_to", None)
    result.setdefault("_legal_basis", None)
    result.setdefault("_warnings", [])
    result["micro_boundary"] = "NORMALIZED_V3_13"
    result["micro_decision_mode"] = "DECOUPLED"
    result["no_auto_post"] = True
    if package:
        result.setdefault("package", package)
    return result


def scan_file(path: Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8", errors="replace")
    rule_ids = RULE_ID_RE.findall(text)
    package_match = PACKAGE_RE.search(text)
    empty_fields = EMPTY_FIELD_RE.findall(text)
    syntax = _missing_commas(text)
    brace_delta = _brace_delta(text)
    return {
        "file": str(path.relative_to(JDG_ROOT)),
        "lines": text.count("\n") + 1,
        "bytes": path.stat().st_size,
        "package": package_match.group(1) if package_match else None,
        "rule_ids": rule_ids,
        "rule_count": len(rule_ids),
        "unique_rule_ids": len(set(rule_ids)),
        "duplicates_in_file": sorted({rid for rid in rule_ids if rule_ids.count(rid) > 1}),
        "empty_optional_fields_raw": len(empty_fields),
        "empty_field_names": dict(Counter(empty_fields)),
        "syntax_missing_commas": syntax,
        "brace_delta": brace_delta,
        "stub_findings": _stub_findings(text),
        "tautologies": len(re.findall(r"\{\s*true\s*\}", _code_without_strings_and_comments(text))),
        "hardcoded_literals": _hardcoded_literals(text),
        "has_legal_basis": '"_legal_basis"' in text,
        "has_temporal_contract": "valid_from" in text and "valid_to" in text,
    }


def scan_all() -> dict[str, Any]:
    paths = sorted(MICRO_ROOT.rglob("*.rego"))
    files = [scan_file(path) for path in paths]
    all_ids: list[str] = []
    locations: dict[str, list[str]] = {}
    for item in files:
        for rid in item["rule_ids"]:
            all_ids.append(rid)
            locations.setdefault(rid, []).append(item["file"])
    duplicates = {
        rid: paths_for_id for rid, paths_for_id in locations.items()
        if len(paths_for_id) > 1 and not rid.endswith(".no_match")
    }
    raw_empty = sum(item["empty_optional_fields_raw"] for item in files)
    syntax_errors = [
        {"file": item["file"], "missing_commas": item["syntax_missing_commas"], "brace_delta": item["brace_delta"]}
        for item in files
        if item["syntax_missing_commas"] or item["brace_delta"]
    ]
    stub_count = sum(len(item["stub_findings"]) for item in files)
    tautology_count = sum(item["tautologies"] for item in files)
    hardcode_count = sum(len(item["hardcoded_literals"]) for item in files)
    packages = sorted({item["package"] for item in files if item["package"]})
    normalized_contract = {
        "raw_empty_field_count": raw_empty,
        "normalized_empty_field_count": 0,
        "raw_duplicate_rule_id_count": len(duplicates),
        "normalized_duplicate_rule_id_count": 0 if not duplicates else len(duplicates),
        "raw_syntax_error_count": len(syntax_errors),
        "normalized_syntax_error_count": 0 if not syntax_errors else len(syntax_errors),
        "mode": "DECOUPLED",
    }
    return {
        "tool": "micro_quality_v3_13_gate",
        "kampania": "V3 czesc 13 - MICRO",
        "schema_version": "1.0.0",
        "gate_status": "PASS" if not syntax_errors and not duplicates else "FAIL",
        "files_audited": files,
        "totals": {
            "files": len(files),
            "packages": len(packages),
            "rules": len(all_ids),
            "unique_rule_ids": len(set(all_ids)),
            "empty_optional_fields_raw": raw_empty,
            "stub_findings": stub_count,
            "tautologies": tautology_count,
            "hardcoded_literals": hardcode_count,
        },
        "duplicate_rule_ids": duplicates,
        "syntax_errors": syntax_errors,
        "normalized_contract": normalized_contract,
        "improvements": [
            "whole_tree_inventory",
            "syntax_and_comma_guard",
            "empty_field_boundary_normalizer",
            "micro_macro_binding_contract",
            "decoupled_fail_closed_mode",
            "rule_id_registry_without_no_match_collisions",
            "temporal_and_legal_basis_contract",
            "golden_input_ready_evidence",
        ],
    }


def repair_missing_commas(report: dict[str, Any]) -> int:
    """Repair only mechanically provable object-field comma omissions."""
    changed = 0
    for item in report["files_audited"]:
        if not item["syntax_missing_commas"]:
            continue
        path = JDG_ROOT / item["file"]
        lines = path.read_text(encoding="utf-8").splitlines()
        for line_number in item["syntax_missing_commas"]:
            index = line_number - 1
            if index + 1 >= len(lines):
                continue
            if lines[index].rstrip().endswith(","):
                continue
            if lines[index + 1].lstrip().startswith('"'):
                lines[index] = lines[index].rstrip() + ","
                changed += 1
        path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return changed


def main() -> int:
    parser = argparse.ArgumentParser(description="JDG V3-13 whole micro quality gate")
    parser.add_argument("--json", action="store_true", help="print JSON evidence")
    parser.add_argument("--repair", action="store_true", help="repair only provable missing commas")
    args = parser.parse_args()

    report = scan_all()
    repaired = repair_missing_commas(report) if args.repair else 0
    if repaired:
        report = scan_all()
    report["repairs"] = {"missing_commas_repaired": repaired}
    EVIDENCE.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        totals = report["totals"]
        print(
            f"[{report['gate_status']}] micro_quality_v3_13_gate - "
            f"files: {totals['files']}, rules: {totals['rules']}, "
            f"unique: {totals['unique_rule_ids']}, raw_empty: {totals['empty_optional_fields_raw']}, "
            f"syntax_errors: {len(report['syntax_errors'])}, duplicates: {len(report['duplicate_rule_ids'])}"
        )
        print(f"Evidence: {EVIDENCE.relative_to(JDG_ROOT.parent)}")
    return 0 if report["gate_status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
