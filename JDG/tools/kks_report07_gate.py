#!/usr/bin/env python3
"""RAPORT_07 KKS — evidence gate and coverage dashboard.

The report explicitly distinguishes repository evidence from recommendations.
This tool keeps that distinction executable: it never infers deployment from
file names alone and fails closed in ``--strict`` mode when production evidence
is absent.

Usage (from ``JDG/``)::

    python tools/kks_report07_gate.py --json
    python tools/kks_report07_gate.py --write
    python tools/kks_report07_gate.py --strict
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
RULES_DIR = BASE_DIR / "rules"
TESTS_DIR = BASE_DIR / "tests"
BUNDLES_DIR = BASE_DIR / "bundles"
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_07_KKS.txt"
EVIDENCE_PATH = BUNDLES_DIR / "kks_report07_evidence.json"

# Paths enumerated by RAPORT_07, kept explicit so the audit cannot silently
# shrink when a future directory scan changes.
RULE_FILES = (
    "rules/kks.rego",
    "rules/_kks_micro_rates.rego",
    "rules/kks/_kks_macro_rates.rego",
    "rules/kks/enterprise_penalties.rego",
    "rules/kks/kks_innovations_v8.rego",
    "rules/kks/plan42_detailed.rego",
    "rules/kks/plan43_decomposition.rego",
    "rules/kks/plan44_kks_conviction.rego",
    "rules/micro/kks/kks.rego",
    "rules/micro/plan33_kks.rego",
    "rules/p09_kks_macro_innovations_v8.rego",
    "rules/p10_kks_innovations_v9.rego",
    "rules/p10_kks_micro_innovations_v8.rego",
    "rules/p33_ordpu_kks_supplement.rego",
    "rules/risk/plan26_kks.rego",
    "rules/gaar_shield_enterprise.rego",
    "rules/penalty_ai_enterprise.rego",
    "rules/sanctions_optimization_enterprise.rego",
    "rules/sanctions_supplements_enterprise.rego",
    "rules/kks/kks_extensions_enterprise.rego",
)

TEST_FILES = (
    "tests/test_kks_enterprise.py",
    "tests/auto/test_auto_block_kks.py",
    "tests/auto/test_p10_kks_enterprise.py",
    "tests/rego/test_p10_kks_enterprise.rego",
    "tests/rego/micro/test_native_micro_kks.rego",
)

CRITICAL_ARTICLES = ("a16", "a44", "a54", "a56", "a57", "a62")
# Evidence aliases accept the repository's current macro/micro/tool naming;
# this is a coverage check, not an assertion that every alias is the same rule.
CRITICAL_MARKERS = {
    "a16": ("jdg.kks.voluntary_disclosure_art16", "voluntary_disclosure", "disclosure_assistant"),
    "a44": ("jdg.kks.statute_of_limitations_art44", "limitation_calendar", "statute_of_limitations"),
    "a54": (
        "jdg.kks.tax_evasion_elements_art54_p1",
        "jdg.kks.tax_evasion_significant_art54_p2",
        "jdg.kks.tax_evasion_concealed_business_art54_p3",
        "tax_evasion",
        "art54",
    ),
    "a56": ("jdg.kks.unreliable_pkpir_art56", "unreliable_pkpir_art56", "art56"),
    "a57": ("jdg.kks.unreliable_vat_evidence_art57", "unreliable_vat_evidence_art57", "art57"),
    "a62": ("jdg.kks.empty_invoice_art62", "empty_invoice_art62", "empty_invoices"),
}
P10_PACKAGE = "jdg.p10_kks_innovations"

# Temporal evidence is tied to the concrete material verdict block. A file-level
# occurrence of valid_from/valid_to is not sufficient for a critical article.
CRITICAL_TEMPORAL_RULES = {
    "a16": ("rules/p10_kks_innovations_v9.rego", "jdg.p10_kks_innovations.voluntary_disclosure_audit"),
    "a44": ("rules/p10_kks_innovations_v9.rego", "jdg.p10_kks_innovations.limitation_calendar"),
    # The penalty gradation verdict explicitly contains the material matrix for
    # these articles, so one temporal contract covers each listed article.
    "a54": ("rules/p10_kks_innovations_v9.rego", "jdg.p10_kks_innovations.penalty_gradation_audit"),
    "a56": ("rules/p10_kks_innovations_v9.rego", "jdg.p10_kks_innovations.penalty_gradation_audit"),
    "a57": ("rules/p10_kks_innovations_v9.rego", "jdg.p10_kks_innovations.penalty_gradation_audit"),
    "a62": ("rules/p10_kks_innovations_v9.rego", "jdg.p10_kks_innovations.penalty_gradation_audit"),
}


def _read(rel: str) -> str:
    path = BASE_DIR / rel
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return ""


def _existing(rel_paths: tuple[str, ...]) -> list[str]:
    return [rel for rel in rel_paths if (BASE_DIR / rel).is_file()]


def _rule_ids(text: str) -> list[str]:
    return re.findall(r'"rule_id"\s*:\s*"([a-zA-Z0-9_.-]+)"', text)


def _legal_basis_count(text: str) -> int:
    return len(re.findall(r'"_legal_basis"\s*:\s*"[^"]+"', text))


def _rule_block_has_temporal(rel: str, rule_id: str) -> bool:
    """Require temporal fields in the concrete verdict block for ``rule_id``."""
    text = _read(rel)
    marker = f'"rule_id": "{rule_id}"'
    start = text.find(marker)
    if start < 0:
        return False
    next_rule = text.find('"rule_id":', start + len(marker))
    block = text[start: next_rule if next_rule >= 0 else len(text)]
    return '"valid_from"' in block and '"valid_to"' in block


def _critical_temporal_evidence() -> dict[str, bool]:
    return {
        article: _rule_block_has_temporal(rel, rule_id)
        for article, (rel, rule_id) in CRITICAL_TEMPORAL_RULES.items()
    }


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
        "critical_temporal_rule_count": sum(
            1
            for marker in CRITICAL_MARKERS.values()
            if any(candidate in text for candidate in marker)
            and "valid_from" in text
            and "valid_to" in text
        ),
                "package_declared": bool(re.search(r"^package\s+", text, re.MULTILINE)),
            }
        )
    counts = Counter(all_ids)
    duplicates = sorted(rid for rid, count in counts.items() if count > 1 and not rid.endswith(".no_match"))
    critical_temporal = _critical_temporal_evidence()
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
        article: any(candidate in joined for candidate in candidates)
        for article, candidates in CRITICAL_MARKERS.items()
    }
    article_hits = {
        article: bool(
            re.search(
                rf"(?:\b{re.escape(article)}\b|Art\.\s*{re.escape(article[1:])}|"
                rf"art\.\s*{re.escape(article[1:])}|{re.escape(article[1:])}[_-])",
                joined,
                re.IGNORECASE,
            )
        )
        for article in CRITICAL_ARTICLES
    }
    return {
        "files_declared": len(TEST_FILES),
        "files_present": sum(bool(text) for text in texts.values()),
        "critical_rule_markers": marker_hits,
        "critical_rule_marker_aliases": {key: list(value) for key, value in CRITICAL_MARKERS.items()},
        "critical_articles_referenced": article_hits,
        "critical_rule_evidence_complete": all(marker_hits.values()),
        "native_rego_test_present": bool(texts.get("tests/rego/test_p10_kks_enterprise.rego")),
        "pytest_test_present": bool(texts.get("tests/auto/test_p10_kks_enterprise.py")),
    }


def _article_covers(node_article: str, target_article: str) -> bool:
    """Match a Legal Twin article or numeric range to a target article."""
    normalized = str(node_article).lower().replace("art. ", "").replace(" ", "")
    target = int(target_article[1:])
    for part in normalized.split(","):
        match = re.fullmatch(r"(\d+)(?:[a-z])?-(\d+)(?:[a-z])?", part)
        if match and int(match.group(1)) <= target <= int(match.group(2)):
            return True
        match = re.fullmatch(r"(\d+)(?:[a-z])?", part)
        if match and int(match.group(1)) == target:
            return True
    return False


def _legal_twin_evidence() -> dict[str, Any]:
    graph_path = BUNDLES_DIR / "legal_graph.json"
    if not graph_path.is_file():
        return {"present": False, "kks_nodes": 0, "critical_basis_refs": 0}
    try:
        graph = json.loads(graph_path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {"present": False, "kks_nodes": 0, "critical_basis_refs": 0, "invalid": True}
    nodes = graph.get("nodes", []) if isinstance(graph, dict) else []
    kks_nodes = [
        node
        for node in nodes
        if any(
            phrase in str(node.get("act", "")).lower()
            for phrase in ("kodeks karny skarbow", "kodeksu karnego skarbow")
        )
    ]
    critical_rule_ids = {
        candidate
        for candidates in CRITICAL_MARKERS.values()
        for candidate in candidates
        if candidate.startswith("jdg.")
    }
    mapped_articles: dict[str, list[str]] = {}
    for article in CRITICAL_ARTICLES:
        mapped_articles[article] = sorted({
            rule_id
            for node in kks_nodes
            if _article_covers(str(node.get("article", "")), article)
            for rule_id in (node.get("rule_ids") or [])
            if rule_id in critical_rule_ids
        })
    refs = sum(bool(rule_ids) for rule_ids in mapped_articles.values())
    return {
        "present": True,
        "kks_nodes": len(kks_nodes),
        "critical_basis_refs": refs,
        "critical_basis_rule_ids": mapped_articles,
        "critical_articles_required": len(CRITICAL_ARTICLES),
        "indexes": graph.get("indexes", {}),
    }


def _router_evidence() -> dict[str, Any]:
    text = _read("rules/main_jdg.rego")
    package_key = f'"{P10_PACKAGE}":'
    return {
        "main_router_present": bool(text),
        "p10_imported": f"import data.{P10_PACKAGE}" in text,
        "p10_registered": package_key in text,
        "p10_final_verdict_wired": "final_verdict_p10" in text,
        "provenance_wired": "provenance.enrich_verdict" in text,
        "runtime_invariants_wired": "runtime_invariants.enforce" in text,
    }


def _safety_evidence() -> dict[str, Any]:
    text = _read("rules/p10_kks_innovations_v9.rego")
    # P10 is an advisory layer. A SUGGEST marker is required so a future
    # refactor cannot accidentally promote criminal-liability advice to AUTO_POST.
    return {
        "package_present": f"package {P10_PACKAGE}" in text,
        "suggest_mode_declared": '"decision_mode": "SUGGEST"' in text or "decision_mode := \"SUGGEST\"" in text,
        "ask_user_supported_elsewhere": "ASK_USER" in _read("rules/adaptive_trust_scoring_enterprise.rego"),
        "no_auto_post_contract": "AUTO_POST" not in text,
    }


def _replay_evidence() -> dict[str, Any]:
    path = BUNDLES_DIR / "golden_verdicts.json"
    if not path.is_file():
        return {"present": False, "schema_version": None, "kks_verdicts": 0}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {"present": False, "schema_version": None, "kks_verdicts": 0, "invalid": True}
    verdicts = data.get("verdicts", {}) if isinstance(data, dict) else {}
    rows = verdicts.values() if isinstance(verdicts, dict) else []
    kks = sum("kks" in json.dumps(row, ensure_ascii=False).lower() for row in rows)
    replay_rows = data.get("replays", [])
    kks_replays = [
        row
        for row in replay_rows
        if "kks" in json.dumps(row, ensure_ascii=False).lower()
    ]
    return {
        "present": True,
        "schema_version": data.get("schema_version"),
        "kks_verdicts": kks,
        "replays": len(replay_rows),
        "kks_replays": len(kks_replays),
        "unexplained_replays": sum(bool(row.get("uver_applies")) for row in replay_rows),
        "kks_unexplained_replays": sum(bool(row.get("uver_applies")) for row in kks_replays),
    }


def _deployment_evidence() -> dict[str, Any]:
    path = BUNDLES_DIR / "deployments.json"
    if not path.is_file():
        return {"present": False, "canary": False, "rollback_sla": False, "production_active": False}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {"present": False, "invalid": True, "canary": False, "rollback_sla": False, "production_active": False}
    deployments = data.get("deployments", {})
    rows = list(deployments.items()) if isinstance(deployments, dict) else []
    # A generic smoke bundle must never satisfy a KKS release gate. The
    # deployment version/name must explicitly carry the KKS report identity.
    kks_rows = [
        (version, row)
        for version, row in rows
        if any(token in str(version).lower() for token in ("kks", "p10", "report07"))
    ]
    active = str(data.get("active_version") or "")
    active_is_kks = any(token in active.lower() for token in ("kks", "p10", "report07"))
    return {
        "present": True,
        "kks_deployments": len(kks_rows),
        "canary": any(
            row.get("canary_ok") is True or row.get("phase") in {"CANARY", "FULL_SOAK"}
            for _, row in kks_rows
        ),
        "rollback_sla": any(row.get("rollback_sla_pass") is True for _, row in kks_rows),
        "production_active": bool(data.get("active_version")) and active_is_kks,
        "active_version": data.get("active_version"),
    }


def build_evidence() -> dict[str, Any]:
    inventory = _file_inventory()
    tests = _test_evidence()
    legal_twin = _legal_twin_evidence()
    router = _router_evidence()
    safety = _safety_evidence()
    replay = _replay_evidence()
    deployment = _deployment_evidence()

    checks = {
        "all_report_rule_files_present": inventory["files_present"] == inventory["files_total"],
        "duplicate_gate": inventory["duplicate_count"] == 0,
        "critical_tests_mapped": tests["critical_rule_evidence_complete"],
        "temporal_gate": inventory["critical_temporal_rule_count"] >= len(CRITICAL_MARKERS),
        "legal_twin_gate": (
            legal_twin.get("present", False)
            and legal_twin.get("critical_basis_refs", 0) >= len(CRITICAL_ARTICLES)
        ),
        "router_gate": all(router.values()),
        # ASK_USER support is reported diagnostically; the mandatory safety
        # contract for this package is SUGGEST + human review + no AUTO_POST.
        "recommendation_safety_gate": (
            safety["package_present"]
            and safety["suggest_mode_declared"]
            and safety["no_auto_post_contract"]
        ),
        "golden_replay_gate": (
            replay.get("schema_version") == 2
            and replay.get("kks_verdicts", 0) >= 1
            and replay.get("kks_replays", 0) >= 1
            and replay.get("kks_unexplained_replays", 0) == 0
        ),
        "canary_rollback_gate": deployment["canary"] and deployment["rollback_sla"],
    }
    passed = sum(checks.values())
    return {
        "report": "RAPORT_07_KKS",
        "method": "evidence-first; no inference from filenames",
        "inventory": inventory,
        "tests": tests,
        "legal_twin": legal_twin,
        "router": router,
        "safety": safety,
        "golden_replay": replay,
        "deployment": deployment,
        "checks": checks,
        "checks_passed": passed,
        "checks_total": len(checks),
        "status": "WDROZONY_100" if passed == len(checks) else "BLOCKED_BY_EVIDENCE",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="RAPORT_07 KKS evidence gate")
    parser.add_argument("--json", action="store_true", help="print JSON evidence")
    parser.add_argument("--write", action="store_true", help="write bundles/kks_report07_evidence.json")
    parser.add_argument("--strict", action="store_true", help="return non-zero unless every gate passes")
    args = parser.parse_args()

    evidence = build_evidence()
    if args.write:
        EVIDENCE_PATH.write_text(json.dumps(evidence, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    if args.json or not args.strict:
        print(json.dumps(evidence, indent=2, ensure_ascii=False))
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
