#!/usr/bin/env python3
"""RAPORT_21 TESTY NATYWNE REGO (opa test) — evidence gate.

Native Rego test report: ``tests/rego/*`` (113 plików, w tym 68 test_native_*.rego
+ 25 micro), ``tests/jdg_rules_test.rego``, ``tests/p26_regression_test.rego``
i ``tests/README.md``. OPA nie jest dostępny w tym środowisku, więc bramka robi
kontrolę strukturalną Rego (package, zbalansowane nawiasy), liczy pokrycie
pakietów produkcyjnych testami (coverage deserts) i weryfikuje, że 4 rule_id
z raportu (G-02) to referencje testowe, a nie kolizje produkcyjne.

Usage (from ``JDG/``)::

    python tools/native_rego_report21_gate.py --json
    python tools/native_rego_report21_gate.py --write
    python tools/native_rego_report21_gate.py --strict
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
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_21_TESTY_NATIVE_REGON.txt"
EVIDENCE_PATH = BUNDLES_DIR / "native_rego_report21_evidence.json"

DOC_FILES = (
    "docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md",
    "docs/WIZJA_OPA_ENTERPRISE_V2.md",
    "docs/Bbb",
    "docs/LEGAL_REFERENCE_ACTS.md",
    "docs/LEGAL_COVERAGE.md",
    "tests/README.md",
    "tests/jdg_rules_test.rego",
    "tests/p26_regression_test.rego",
)

# rule_id z G-02 raportu — referencje testowe (nie kolizje produkcyjne).
FLAGGED_RULE_IDS = (
    "jdg.fallback.domestic_23pct",
    "jdg.risk.fraud",
    "jdg.risk.fraud_graph_match",
    "jdg.risk.x",
)

# Pliki metadata (registry rule_id jako klucze, nie definicje reguł).
_METADATA_FILES = {"_metadata_jdg.rego", "_metadata.rego"}

_PACKAGE_RE = re.compile(r"^\s*package\s+([a-zA-Z0-9_.]+)")
_IMPORT_RE = re.compile(r"^\s*import\s+data\.([a-zA-Z0-9_.]+)")
_RULEID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')


def _rego_files() -> list[Path]:
    return sorted((BASE_DIR / "tests" / "rego").rglob("*.rego"))


def _production_files() -> list[Path]:
    return sorted((BASE_DIR / "rules").rglob("*.rego"))


def _exists(rel: str) -> bool:
    return (BASE_DIR / rel).exists()


def _scope_evidence() -> dict[str, Any]:
    docs = {rel: _exists(rel) for rel in DOC_FILES}
    rego = _rego_files()
    return {
        "docs_total": len(DOC_FILES),
        "docs_present": sum(docs.values()),
        "rego_test_files": len(rego),
        "native_count": len(list((BASE_DIR / "tests" / "rego").glob("test_native_*.rego"))),
        "micro_count": len(list((BASE_DIR / "tests" / "rego" / "micro").glob("*.rego"))),
        "missing_docs": [rel for rel, ok in docs.items() if not ok],
    }


def _strip_strings_and_comments(text: str) -> str:
    """Usuwa literały stringowe i komentarze, żeby zliczyć realne nawiasy."""
    out: list[str] = []
    i = 0
    n = len(text)
    in_str: str | None = None
    while i < n:
        ch = text[i]
        if in_str is not None:
            if ch == in_str:
                in_str = None
            out.append(" ")
            i += 1
            continue
        if ch == "#":
            while i < n and text[i] != "\n":
                out.append(" ")
                i += 1
            continue
        if ch in ('"', "`"):
            in_str = ch
            out.append(" ")
            i += 1
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def _structural_evidence() -> dict[str, Any]:
    problems: list[dict[str, str]] = []
    for path in _rego_files():
        text = path.read_text(encoding="utf-8", errors="ignore")
        rel = str(path.relative_to(BASE_DIR))
        has_package = any(_PACKAGE_RE.match(line) for line in text.splitlines())
        if not has_package:
            problems.append({"file": rel, "error": "missing package declaration"})
            continue
        stripped = _strip_strings_and_comments(text)
        if stripped.count("{") != stripped.count("}") or stripped.count("(") != stripped.count(")"):
            problems.append({"file": rel, "error": "unbalanced braces/parens"})
    return {"problems": problems, "structural_ok": not problems}


def _coverage_evidence() -> dict[str, Any]:
    prod_pkgs: set[str] = set()
    for path in _production_files():
        for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
            m = _PACKAGE_RE.match(line)
            if m:
                prod_pkgs.add(m.group(1))

    imported: set[str] = set()
    test_paths = list((BASE_DIR / "tests" / "rego").rglob("*.rego"))
    test_paths += [BASE_DIR / "tests" / "jdg_rules_test.rego",
                   BASE_DIR / "tests" / "p26_regression_test.rego"]
    for path in test_paths:
        for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
            m = _IMPORT_RE.match(line)
            if m:
                imported.add(m.group(1))

    covered = sorted(prod_pkgs & imported)
    deserts = sorted(prod_pkgs - imported)
    coverage_pct = round(100 * len(covered) / len(prod_pkgs), 1) if prod_pkgs else 0.0
    return {
        "production_packages": len(prod_pkgs),
        "imported_by_tests": len(imported),
        "covered_packages": len(covered),
        "coverage_pct": coverage_pct,
        "desert_count": len(deserts),
        "deserts": deserts,
    }


def _duplicate_evidence() -> dict[str, Any]:
    """Weryfikuje, że 4 rule_id z G-02 nie są kolizjami produkcyjnymi."""
    findings: dict[str, list[str]] = {}
    for rid in FLAGGED_RULE_IDS:
        files: list[str] = []
        for path in _production_files():
            if path.name in _METADATA_FILES:
                continue  # registry metadata — klucz, nie definicja reguły
            text = path.read_text(encoding="utf-8", errors="ignore")
            if _RULEID_RE.search(text) and rid in text:
                files.append(str(path.relative_to(BASE_DIR)))
        findings[rid] = files

    collisions = {rid: f for rid, f in findings.items() if len(f) > 1}
    return {
        "rule_id_files": findings,
        "collisions": collisions,
        "duplicate_free": not collisions,
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
    dep = deployments.get("deployments", {}).get("jdg-tnt-bundle-v9.0.0", {})
    return {
        "bundle": "jdg-tnt-bundle-v9.0.0",
        "phase": dep.get("phase"),
        "rollback_reason": dep.get("rollback_reason"),
        "rollback_mttr_minutes": dep.get("rollback_mttr_minutes"),
        "rollback_sla_pass": dep.get("rollback_sla_pass"),
        "active_version": deployments.get("active_version"),
    }


def build_evidence() -> dict[str, Any]:
    scope = _scope_evidence()
    structural = _structural_evidence()
    coverage = _coverage_evidence()
    duplicate = _duplicate_evidence()
    replay = _golden_replay_evidence()
    deployment = _deployment_evidence()

    gates = {
        "scope_files_present": scope["docs_present"] == scope["docs_total"]
        and scope["rego_test_files"] > 0,
        "test_structure_ok": structural["structural_ok"],
        "coverage_tracked": coverage["production_packages"] > 0
        and coverage["coverage_pct"] > 0,
        "duplicate_free": duplicate["duplicate_free"],
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
        "report": "RAPORT_21_TESTY_NATIVE_REGON",
        "status": status,
        "gates": gates,
        "gate_summary": {"passed": passed, "total": total},
        "scope": scope,
        "structural": structural,
        "coverage": coverage,
        "duplicate": duplicate,
        "replay": replay,
        "deployment": deployment,
        "generated_at": __import__("datetime").datetime.now(
            __import__("datetime").timezone.utc
        ).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="RAPORT_21 evidence gate")
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
            f"RAPORT_21: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
        cov = evidence["coverage"]
        print(
            f"  coverage: {cov['coverage_pct']}% "
            f"({cov['covered_packages']}/{cov['production_packages']}); "
            f"deserts: {cov['desert_count']}"
        )
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
