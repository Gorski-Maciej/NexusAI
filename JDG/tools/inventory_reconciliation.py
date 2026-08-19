#!/usr/bin/env python3
"""Inventory and truth-reconciliation gate for JDG ETAP_01.

The scanner treats the repository as evidence, while README/MANIFEST/plan
numbers are declarations to reconcile. It never deletes files or rewrites
history. Findings are deliberately classified as confirmed facts or review
candidates; a heuristic is never promoted to a fact.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime, timezone
from functools import lru_cache
from pathlib import Path
from typing import Iterable

REPO_ROOT = Path(__file__).resolve().parents[2]
JDG_ROOT = REPO_ROOT / "JDG"
CANONICAL_RULES = JDG_ROOT / "rules"
POLICIES_ROOT = REPO_ROOT / "policies"
DEFAULT_OUTPUT = JDG_ROOT / "bundles" / "inventory_manifest.json"
IGNORED_PARTS = {"__pycache__", ".hypothesis", ".benchmarks", ".pytest_cache", ".git"}
TEXT_SUFFIXES = {
    ".py", ".rego", ".md", ".txt", ".yaml", ".yml", ".json", ".sql", ".sh",
    ".toml", ".ini", ".cfg", ".html", ".css", ".js", ".xml", ".csv",
}
RULE_ID_RE = re.compile(r'["\']rule_id["\']\s*:\s*["\']([^"\']+)["\']')
PACKAGE_RE = re.compile(r"^\s*package\s+([A-Za-z0-9_.]+)", re.MULTILINE)
DATA_IMPORT_RE = re.compile(r"^\s*import\s+data\.([A-Za-z0-9_.]+)", re.MULTILINE)
STUB_RE = re.compile(r":=\s*\{\s*true\s*\}", re.IGNORECASE)
DECLARED_NUMBER_RE = re.compile(r"(?P<number>\d[\d _.,]*)")


@dataclass(frozen=True)
class RuleOccurrence:
    rule_id: str
    path: str
    line: int
    package: str
    layer: str

    def as_dict(self) -> dict:
        return {
            "rule_id": self.rule_id,
            "path": self.path,
            "line": self.line,
            "package": self.package,
            "layer": self.layer,
        }


def _ignored(path: Path) -> bool:
    return any(part in IGNORED_PARTS for part in path.parts)


def _relative(path: Path) -> str:
    """Return a stable repository path, or a test-fixture path outside it."""
    try:
        return path.resolve().relative_to(REPO_ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def _files(root: Path, suffix: str | None = None) -> list[Path]:
    if not root.exists():
        return []
    paths = [p for p in root.rglob("*") if p.is_file() and not _ignored(p)]
    if suffix is not None:
        paths = [p for p in paths if p.suffix == suffix]
    return sorted(paths)


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _line_count(path: Path) -> int:
    """Count text lines without opening binary bundles or media artifacts."""
    if path.suffix.lower() not in TEXT_SUFFIXES:
        return 0
    return _read(path).count("\\n") + (1 if path.stat().st_size else 0)


def _line_number(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def _package(text: str) -> str:
    match = PACKAGE_RE.search(text)
    return match.group(1) if match else "unknown"


def _layer(path: Path) -> str:
    relative = _relative(path)
    if relative.startswith("JDG/rules/"):
        return "canonical_rules"
    if relative.startswith("policies/"):
        return "policies_mirror"
    return "other"


def _text(path: Path, contents: dict[Path, str] | None = None) -> str:
    return contents[path] if contents is not None and path in contents else _read(path)


def _rule_occurrences(paths: Iterable[Path], contents: dict[Path, str] | None = None) -> list[RuleOccurrence]:
    occurrences: list[RuleOccurrence] = []
    for path in paths:
        text = _text(path, contents)
        package = _package(text)
        layer = _layer(path)
        for match in RULE_ID_RE.finditer(text):
            occurrences.append(RuleOccurrence(
                rule_id=match.group(1),
                path=_relative(path),
                line=_line_number(text, match.start()),
                package=package,
                layer=layer,
            ))
    return occurrences


def _duplicate_groups(occurrences: Iterable[RuleOccurrence], layer: str | None = None) -> dict:
    groups: dict[str, list[RuleOccurrence]] = defaultdict(list)
    for occurrence in occurrences:
        if layer is None or occurrence.layer == layer:
            groups[occurrence.rule_id].append(occurrence)
    return {
        rule_id: [item.as_dict() for item in items]
        for rule_id, items in sorted(groups.items()) if len(items) > 1
    }


def _stub_candidates(paths: Iterable[Path], contents: dict[Path, str] | None = None) -> list[dict]:
    findings: list[dict] = []
    for path in paths:
        text = _text(path, contents)
        for match in STUB_RE.finditer(text):
            findings.append({
                "path": _relative(path),
                "line": _line_number(text, match.start()),
                "kind": "stub_candidate",
                "evidence": match.group(0),
                "classification": "REVIEW_CANDIDATE",
            })
    return findings


def _package_import_findings(
    paths: Iterable[Path], packages: set[str], contents: dict[Path, str] | None = None,
) -> list[dict]:
    findings: list[dict] = []
    for path in paths:
        text = _text(path, contents)
        for match in DATA_IMPORT_RE.finditer(text):
            imported = match.group(1)
            if imported.startswith("jdg.") and imported not in packages:
                findings.append({
                    "path": _relative(path),
                    "line": _line_number(text, match.start()),
                    "import": f"data.{imported}",
                    "classification": "CONFIRMED_MISSING_PACKAGE",
                })
    return findings


def _routed_package_candidates(
    paths: Iterable[Path], packages: set[str], contents: dict[Path, str] | None = None,
) -> list[dict]:
    main = CANONICAL_RULES / "main_jdg.rego"
    router_text = _text(main, contents) if main.exists() else ""
    findings: list[dict] = []
    for path in paths:
        if path == main:
            continue
        package = _package(_text(path, contents))
        if package == "unknown" or package not in packages:
            continue
        if package not in router_text:
            findings.append({
                "path": _relative(path),
                "package": package,
                "classification": "UNLOADED_CANDIDATE",
                "evidence": "package name absent from main_jdg.rego; bundle loading is not inferred",
            })
    return findings


def _dead_rule_candidates(
    occurrences: list[RuleOccurrence],
    paths: Iterable[Path],
    unloaded_packages: set[str] | None = None,
) -> list[dict]:
    del paths  # occurrences are already the complete scanned evidence set.
    unloaded_packages = unloaded_packages or set()
    result = []
    for occurrence in occurrences:
        if occurrence.layer == "canonical_rules" and occurrence.package in unloaded_packages:
            result.append({
                "rule_id": occurrence.rule_id,
                "path": occurrence.path,
                "line": occurrence.line,
                "classification": "DEAD_RULE_CANDIDATE",
                "evidence": "rule_id appears once; runtime reachability requires semantic/router test",
            })
    return result


def _declared_counts() -> dict:
    """Extract declarations without pretending they equal repository truth."""
    sources = {
        "JDG/README.md": REPO_ROOT / "JDG" / "README.md",
        "JDG/MANIFEST.md": REPO_ROOT / "JDG" / "MANIFEST.md",
        "JDG/docs/INWENTARYZACJA_PLIKOW.md": REPO_ROOT / "JDG" / "docs" / "INWENTARYZACJA_PLIKOW.md",
        "JDG/docs/KATALOG_REGUL.md": REPO_ROOT / "JDG" / "docs" / "KATALOG_REGUL.md",
        "JDG/docs/KATALOG_NARZEDZI.md": REPO_ROOT / "JDG" / "docs" / "KATALOG_NARZEDZI.md",
        "JDG/bundles/manifest.json": REPO_ROOT / "JDG" / "bundles" / "manifest.json",
        "JDG/unified_plan_progress.yaml": REPO_ROOT / "JDG" / "unified_plan_progress.yaml",
    }
    declarations: dict[str, list[dict]] = defaultdict(list)
    patterns = {
        "rego_files": re.compile(r"(?P<number>\d[\d _]*)\s*(?:plików|plikow|files)\s*(?:Rego|\.rego)", re.I),
        "rule_ids": re.compile(r"(?P<number>\d[\d _]*)\s*(?:unikalnych\s+)?rule_id", re.I),
        "tools": re.compile(r"(?P<number>\d[\d _]*)\s*(?:narzędzi|narzedzi|tools)", re.I),
    }
    for name, path in sources.items():
        if not path.exists():
            continue
        text = _read(path)
        for metric, pattern in patterns.items():
            for match in pattern.finditer(text):
                raw = match.group("number").replace(" ", "").replace("_", "").replace(",", "")
                try:
                    value = int(raw)
                except ValueError:
                    continue
                declarations[metric].append({"source": name, "value": value})
    return dict(declarations)


def _file_record(path: Path) -> dict:
    text = _read(path)
    return {
        "path": _relative(path),
        "bytes": path.stat().st_size,
        "lines": text.count("\n") + (1 if text else 0),
        "sha256": _sha256(path),
        "suffix": path.suffix,
    }


@lru_cache(maxsize=1)
def build_inventory() -> dict:
    canonical_rego = _files(CANONICAL_RULES, ".rego")
    mirror_rego = _files(POLICIES_ROOT, ".rego")
    all_rego = canonical_rego + mirror_rego
    all_jdg_files = _files(JDG_ROOT)
    policy_files = _files(POLICIES_ROOT)
    rego_text = {path: _read(path) for path in all_rego}
    occurrences = _rule_occurrences(all_rego, rego_text)
    canonical_duplicates = _duplicate_groups(occurrences, "canonical_rules")
    mirror_duplicates = _duplicate_groups(occurrences, "policies_mirror")
    canonical_ids = {o.rule_id for o in occurrences if o.layer == "canonical_rules"}
    mirror_ids = {o.rule_id for o in occurrences if o.layer == "policies_mirror"}
    packages = {_package(text) for text in rego_text.values()}
    packages.discard("unknown")
    tests = [p for p in all_jdg_files if p.name.startswith("test_") or "test" in p.name.lower()]
    tools = _files(JDG_ROOT / "tools", ".py")
    migrations = _files(JDG_ROOT / "migrations", ".sql")
    unloaded_candidates = _routed_package_candidates(canonical_rego, packages, rego_text)
    unloaded_packages = {item["package"] for item in unloaded_candidates}
    dead_candidates = _dead_rule_candidates(occurrences, all_rego, unloaded_packages)
    missing_imports = _package_import_findings(all_rego, packages, rego_text)
    artifacts = [p for p in all_jdg_files if p.suffix in {".json", ".yaml", ".yml", ".md", ".sh", ".txt"}]
    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "generator": "JDG/tools/inventory_reconciliation.py",
        "source_of_truth": "repository_scan",
        "files": {
            "jdg_total": len(all_jdg_files),
            "policies_total": len(policy_files),
            "rego_canonical": len(canonical_rego),
            "rego_mirror": len(mirror_rego),
            "tests": len(tests),
            "tools": len(tools),
            "migrations": len(migrations),
            "artifacts": len(artifacts),
        },
        "file_index": [_relative(p) for p in all_jdg_files + policy_files],
        "lines": {
            "jdg_total": None,
            "policies_total": None,
            "note": "Nie czytano ponownie wszystkich artefaktów binarnych; linie dowodowe są podane przy findings.",
        },
        "rules": {
            "canonical_occurrences": sum(1 for o in occurrences if o.layer == "canonical_rules"),
            "canonical_unique_rule_ids": len(canonical_ids),
            "canonical_duplicate_groups": canonical_duplicates,
            "mirror_occurrences": sum(1 for o in occurrences if o.layer == "policies_mirror"),
            "mirror_unique_rule_ids": len(mirror_ids),
            "mirror_duplicate_groups": mirror_duplicates,
            "cross_layer_rule_ids": sorted(canonical_ids & mirror_ids),
            "occurrences": [o.as_dict() for o in occurrences],
        },
        "packages": sorted(packages),
        "tests_index": [_relative(p) for p in tests],
        "tools_index": [_relative(p) for p in tools],
        "migrations_index": [_relative(p) for p in migrations],
        "artifacts_index": [_relative(p) for p in artifacts],
        "findings": {
            "stub_candidates": _stub_candidates(canonical_rego, rego_text),
            "dead_rule_candidates": dead_candidates,
            "unloaded_package_candidates": unloaded_candidates,
            "missing_package_imports": missing_imports,
        },
        "declarations": _declared_counts(),
        "reconciliation": {
            "declared_values_are_evidence": False,
            "canonical_layer": "JDG/rules",
            "mirror_layer": "policies",
            "history_policy": "append_only",
            "safe_cleanup": "no_delete_without_zero_references_and_review",
        },
        "rule_registry_schema": {
            "required": [
                "rule_id", "title", "legal_basis", "valid_from", "valid_to", "owner",
                "domain", "version", "status", "content_hash", "tests", "thresholds",
                "impact_rules", "source_file",
            ],
            "status_enum": ["SHADOW", "CANDIDATE", "ACTIVE", "DEPRECATED", "RETIRED", "PURGED", "SUSPENDED"],
            "temporal_rule": "valid_from <= valid_to; adjacent versions cannot overlap",
        },
        "review_policy": {
            "confirmed_facts": "repository scan only",
            "heuristics": "must remain REVIEW_CANDIDATE until semantic test confirms",
            "purge": "forbidden in this stage",
        },
    }
    return report


def reconcile(report: dict) -> list[dict]:
    """Return blocking discrepancies only; heuristic candidates are reported separately."""
    findings: list[dict] = []
    rules = report["rules"]
    if not rules["canonical_duplicate_groups"] == {}:
        findings.append({
            "id": "R-001",
            "kind": "duplicate_rule_id",
            "severity": "BLOCK",
            "count": len(rules["canonical_duplicate_groups"]),
            "evidence": "JDG/rules scan",
        })
    if report["findings"]["missing_package_imports"]:
        findings.append({
            "id": "R-002",
            "kind": "missing_package_import",
            "severity": "BLOCK",
            "count": len(report["findings"]["missing_package_imports"]),
            "evidence": "Rego import data.* vs scanned packages",
        })
    if report["files"]["rego_canonical"] == 0:
        findings.append({"id": "R-003", "kind": "empty_canonical_rules", "severity": "BLOCK"})
    return findings


def write_manifest(report: dict, output: Path = DEFAULT_OUTPUT) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="JDG ETAP_01 inventory reconciliation")
    parser.add_argument("--json", action="store_true", help="print the full scan")
    parser.add_argument("--write", action="store_true", help="write the authoritative scan manifest")
    parser.add_argument("--strict", action="store_true", help="return non-zero on blocking discrepancies")
    args = parser.parse_args(argv)
    report = build_inventory()
    blocking = reconcile(report)
    if args.write:
        write_manifest(report)
    if args.json:
        print(json.dumps({"inventory": report, "blocking_findings": blocking}, ensure_ascii=False, indent=2))
    else:
        print(json.dumps({
            "source_of_truth": report["source_of_truth"],
            "canonical_rego_files": report["files"]["rego_canonical"],
            "canonical_rule_ids": report["rules"]["canonical_unique_rule_ids"],
            "canonical_duplicate_groups": len(report["rules"]["canonical_duplicate_groups"]),
            "stub_candidates": len(report["findings"]["stub_candidates"]),
            "dead_rule_candidates": len(report["findings"]["dead_rule_candidates"]),
            "unloaded_package_candidates": len(report["findings"]["unloaded_package_candidates"]),
            "missing_package_imports": len(report["findings"]["missing_package_imports"]),
            "blocking_findings": blocking,
        }, ensure_ascii=False, indent=2))
    return 1 if args.strict and blocking else 0


if __name__ == "__main__":
    sys.exit(main())
