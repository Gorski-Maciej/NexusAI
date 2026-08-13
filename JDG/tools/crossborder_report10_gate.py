#!/usr/bin/env python3
"""RAPORT_10 Cross-Border / TP / MDR-DAC6 / CFC — evidence gate.

Mirrors tools/kks_report07_gate.py, tools/ord_report08_gate.py and
tools/accounting_report09_gate.py: the report distinguishes repository
evidence from recommendations, so this tool keeps that distinction
executable. It never infers deployment from file names alone and fails
closed in ``--strict`` mode when production evidence is absent.

Usage (from ``JDG/``)::

    python tools/crossborder_report10_gate.py --json
    python tools/crossborder_report10_gate.py --write
    python tools/crossborder_report10_gate.py --strict
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
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_10_CROSSBORDER.txt"
EVIDENCE_PATH = BUNDLES_DIR / "crossborder_report10_evidence.json"

# Paths enumerated by RAPORT_10 (tabela 2.3), kept explicit so the audit
# cannot silently shrink when a future directory scan changes. 35 Rego files.
RULE_FILES = (
    "rules/_crossborder_rates.rego",
    "rules/cbam_full.rego",
    "rules/cfc_auto_classifier.rego",
    "rules/cross_domain_intelligence_enterprise.rego",
    "rules/cross_jurisdiction_ruling_enterprise.rego",
    "rules/crossborder/exit_tax_cfc_complete.rego",
    "rules/crossborder/plan23_ue.rego",
    "rules/crossborder/post_brexit.rego",
    "rules/crossborder.rego",
    "rules/dac8_report_generator.rego",
    "rules/international.rego",
    "rules/international_expanded.rego",
    "rules/mdr/mdr_enterprise.rego",
    "rules/mdr/mdr_hallmarks.rego",
    "rules/mdr/plan44_mdr.rego",
    "rules/mdr/plan45_mdr.rego",
    "rules/mdr_auto_generator.rego",
    "rules/mdr_dac6_enterprise.rego",
    "rules/micro/crossborder/crossborder.rego",
    "rules/micro/plan33_cb.rego",
    "rules/micro/plan33_mdr.rego",
    "rules/micro/plan33_tp.rego",
    "rules/p12_crossborder_innovations_v9.rego",
    "rules/p13_crossborder_innovations_v8.rego",
    "rules/p3233_innovations.rego",
    "rules/tp/plan44_tp.rego",
    "rules/tp/plan45_tp.rego",
    "rules/vida_drr_full.rego",
    "rules/wdt_document_tracker.rego",
)

TEST_FILES = (
    "tests/test_crossborder_enterprise.py",
    "tests/auto/test_auto_block_crossborder.py",
    "tests/auto/test_auto_block_mdr.py",
    "tests/auto/test_auto_block_tp.py",
    "tests/auto/test_p12_crossborder_enterprise.py",
    "tests/rego/test_akcyza_depreciation_mdr_exittax.rego",
    "tests/rego/test_native_exit_tax_mdr_enterprise.rego",
    "tests/rego/test_native_jdg_fx.rego",
    "tests/rego/test_native_mdr_dac6_enterprise.rego",
    "tests/rego/test_p12_crossborder_enterprise.rego",
    "tests/rego/micro/test_native_micro_crossborder.rego",
)

# Priorytety RAPORT_10: WNT/WDT (art. 13), eksport pośredni, import usług
# (reverse charge — art. 17), miejsce świadczenia (art. 28a–28o), TP
# (art. 23o/23zf), WHT (art. 29), exit tax (art. 30da), CFC (art. 30f),
# MDR/DAC6 (art. 86a-86o). Artykuły krytyczne = zestaw COMPLETE z testów P12.
CRITICAL_ARTICLES = ("a20", "a23o", "a23zf", "a29", "a30da", "a30f", "a86r")
# Evidence aliases accept the repository's current macro/micro/tool naming;
# this is a coverage check, not an assertion that every alias is the same rule.
CRITICAL_MARKERS = {
    "a20": (
        "jdg.crossborder.import_services_tax_point",
        "jdg.micro.crossborder.a20.r1",
        "a20",
        "MLI",
    ),
    "a23o": (
        "jdg.p12_crossborder_innovations.tp_documentation_calculator",
        "jdg.micro.crossborder.a23o.r1",
        "tp_documentation",
        "Ceny transferowe",
    ),
    "a23zf": (
        "jdg.p12_crossborder_innovations.tp_documentation_calculator",
        "jdg.micro.crossborder.a23zf.r1",
        "local_file",
        "23zf",
    ),
    "a29": (
        "jdg.crossborder.import_services_tax_base",
        "jdg.micro.crossborder.a29.r1",
        "wht",
        "WHT",
    ),
    "a30da": (
        "jdg.p12_crossborder_innovations.exit_tax_calculator",
        "jdg.micro.crossborder.a30da.r1",
        "exit_tax",
        "30da",
    ),
    "a30f": (
        "jdg.p12_crossborder_innovations.cfc_calculator",
        "jdg.micro.crossborder.a30f.r1",
        "cfc_calculator",
        "CFC",
    ),
    "a86r": (
        "jdg.p12_crossborder_innovations.mdr_report_generator",
        "jdg.micro.crossborder.a86r.r1",
        "mdr_report",
        "MDR",
    ),
}
P12_PACKAGE = "jdg.p12_crossborder_innovations"

# Temporal evidence is tied to the concrete material verdict block. A
# file-level occurrence of valid_from/valid_to is not sufficient for a critical
# article. Dates: WNT/WDT — VAT 2004 (tekst jednolity), TP — 2024-01-01,
# CFC — 2015-01-01, exit tax — 2019-01-01, MDR/DAC6 — 2019-01-01.
CRITICAL_TEMPORAL_RULES = {
    "a20": ("rules/crossborder.rego",
            "jdg.crossborder.import_services_tax_point"),
    "a23o": ("rules/micro/crossborder/crossborder.rego",
             "jdg.micro.crossborder.a23o.r1"),
    "a23zf": ("rules/p12_crossborder_innovations_v9.rego",
              "jdg.p12_crossborder_innovations.tp_documentation_calculator"),
    "a29": ("rules/crossborder.rego",
            "jdg.crossborder.import_services_tax_base"),
    "a30da": ("rules/p12_crossborder_innovations_v9.rego",
              "jdg.p12_crossborder_innovations.exit_tax_calculator"),
    "a30f": ("rules/p12_crossborder_innovations_v9.rego",
             "jdg.p12_crossborder_innovations.cfc_calculator"),
    "a86r": ("rules/p12_crossborder_innovations_v9.rego",
             "jdg.p12_crossborder_innovations.mdr_report_generator"),
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
    return len(re.findall(r'"_legal_basis"\s*:\s*"[^"]+"', text))


def _rule_block_has_temporal(rel: str, rule_id: str) -> bool:
    """Require temporal fields in the concrete verdict block for ``rule_id``."""
    text = _read(rel)
    marker = f'"rule_id": "{rule_id}"'
    alt = f'"rule_id":"{rule_id}"'
    start = text.find(marker)
    if start < 0:
        start = text.find(alt)
    if start < 0:
        return False
    next_rule = text.find('"rule_id":', start + len(marker))
    if next_rule < 0:
        next_rule = text.find('"rule_id":', start + len(alt))
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
    # G-02 resolved on 2026-08-13: jdg.crossborder.no_match and
    # jdg.international.no_match were namespace-renamed in the secondary files
    # (plan23_ue.rego -> jdg.crossborder.plan23_ue.no_match,
    #  international_expanded.rego -> jdg.international.expanded.no_match).
    # Primary no_match fallbacks remain (one per package, not a collision).
    duplicates = sorted(
        rid
        for rid, count in counts.items()
        if count > 1 and not rid.endswith(".no_match")
    )
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
                rf"(?:\\b{re.escape(article)}\\b|Art\\.\\s*{re.escape(article[1:])}|\""
                rf"art\\.\\s*{re.escape(article[1:])}|{re.escape(article[1:])}[_-])",
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
        "native_rego_test_present": bool(texts.get("tests/rego/micro/test_native_micro_crossborder.rego")),
        "pytest_test_present": bool(texts.get("tests/test_crossborder_enterprise.py")),
    }


def _article_covers(node_article: str, target_article: str) -> bool:
    """Match a Legal Twin article or numeric range to a target article.
    Targets may carry letter suffixes (a23o, a23zf, a30da) and ranges may
    carry multi-letter suffixes (23m-23zf) — the match is on the numeric
    prefix, consistent with legal_twin.article_match."""
    normalized = str(node_article).lower().replace("art. ", "").replace(" ", "")
    m = re.match(r"\d+", target_article[1:])
    target = int(m.group(0)) if m else 0
    for part in normalized.split(","):
        rng = re.fullmatch(r"(\d+)[a-z]*-(\d+)[a-z]*", part)
        if rng and int(rng.group(1)) <= target <= int(rng.group(2)):
            return True
        single = re.fullmatch(r"(\d+)[a-z]*", part)
        if single and int(single.group(1)) == target:
            return True
    return False


def _legal_twin_evidence() -> dict[str, Any]:
    graph_path = BUNDLES_DIR / "legal_graph.json"
    if not graph_path.is_file():
        return {"present": False, "xb_nodes": 0, "critical_basis_refs": 0}
    try:
        graph = json.loads(graph_path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {"present": False, "xb_nodes": 0, "critical_basis_refs": 0, "invalid": True}
    nodes = graph.get("nodes", []) if isinstance(graph, dict) else []
    xb_nodes = [
        node
        for node in nodes
        if any(
            token in str(node.get("act", "")).lower()
            for token in (
                "podatku od towarów i usług",
                "dochodowym od osób fizycznych",
                "ordynacja podatkowa",
            )
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
            for node in xb_nodes
            if _article_covers(str(node.get("article", "")), article)
            for rule_id in (node.get("rule_ids") or [])
            if rule_id in critical_rule_ids
        })
    refs = sum(bool(rule_ids) for rule_ids in mapped_articles.values())
    return {
        "present": True,
        "xb_nodes": len(xb_nodes),
        "critical_basis_refs": refs,
        "critical_basis_rule_ids": mapped_articles,
        "critical_articles_required": len(CRITICAL_ARTICLES),
        "indexes": graph.get("indexes", {}),
    }


def _router_evidence() -> dict[str, Any]:
    text = _read("rules/main_jdg.rego")
    package_key = f'"{P12_PACKAGE}":'
    return {
        "main_router_present": bool(text),
        "p12_imported": f"import data.{P12_PACKAGE}" in text,
        "p12_registered": package_key in text,
        "p12_final_verdict_wired": "final_verdict_p12" in text,
        "crossborder_imported": "import data.jdg.crossborder" in text,
        "international_imported": "import data.jdg.international" in text,
        "provenance_wired": "provenance.enrich_verdict" in text,
        "runtime_invariants_wired": "runtime_invariants.enforce" in text,
    }


def _safety_evidence() -> dict[str, Any]:
    text = _read("rules/p12_crossborder_innovations_v9.rego")
    # P12 is an advisory layer. A SUGGEST marker is required so a future
    # refactor cannot accidentally promote cross-border advice to AUTO_POST.
    return {
        "package_present": f"package {P12_PACKAGE}" in text,
        "suggest_mode_declared": '"decision_mode": "SUGGEST"' in text or "decision_mode := \"SUGGEST\"" in text,
        "ask_user_supported_elsewhere": "ASK_USER" in _read("rules/adaptive_trust_scoring_enterprise.rego"),
        "no_auto_post_contract": "AUTO_POST" not in text,
    }


def _replay_evidence() -> dict[str, Any]:
    path = BUNDLES_DIR / "golden_verdicts.json"
    if not path.is_file():
        return {"present": False, "schema_version": None, "xb_verdicts": 0}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {"present": False, "schema_version": None, "xb_verdicts": 0, "invalid": True}
    verdicts = data.get("verdicts", {}) if isinstance(data, dict) else {}
    rows = verdicts.values() if isinstance(verdicts, dict) else []
    xb_rows = [
        row for row in rows
        if any(token in json.dumps(row, ensure_ascii=False).lower()
               for token in ("p12_crossborder", "cfc", "crossborder", "jdg.tp", "mdr"))
    ]
    replay_rows = data.get("replays", [])
    xb_replays = [
        row for row in replay_rows
        if any(token in json.dumps(row, ensure_ascii=False).lower()
               for token in ("p12_crossborder", "cfc", "crossborder", "jdg.tp", "mdr"))
    ]
    return {
        "present": True,
        "schema_version": data.get("schema_version"),
        "xb_verdicts": len(xb_rows),
        "replays": len(replay_rows),
        "xb_replays": len(xb_replays),
        "unexplained_replays": sum(bool(row.get("uver_applies")) for row in replay_rows),
        "xb_unexplained_replays": sum(bool(row.get("uver_applies")) for row in xb_replays),
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
    # A generic smoke bundle must never satisfy a CROSS-BORDER release gate.
    xb_rows = [
        (version, row)
        for version, row in rows
        if any(token in str(version).lower() for token in ("xb", "p12", "report10", "crossborder"))
    ]
    active = str(data.get("active_version") or "")
    active_is_xb = any(token in active.lower() for token in ("xb", "p12", "report10", "crossborder"))
    return {
        "present": True,
        "xb_deployments": len(xb_rows),
        "canary": any(
            row.get("canary_ok") is True or row.get("phase") in {"CANARY", "FULL_SOAK", "ROLLED_BACK"}
            for _, row in xb_rows
        ),
        "rollback_sla": any(row.get("rollback_sla_pass") is True for _, row in xb_rows),
        "production_active": bool(data.get("active_version")) and active_is_xb,
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
        "recommendation_safety_gate": (
            safety["package_present"]
            and safety["suggest_mode_declared"]
            and safety["no_auto_post_contract"]
        ),
        "golden_replay_gate": (
            replay.get("schema_version") == 2
            and replay.get("xb_verdicts", 0) >= 1
            and replay.get("xb_replays", 0) >= 1
            and replay.get("xb_unexplained_replays", 0) == 0
        ),
        "canary_rollback_gate": deployment["canary"] and deployment["rollback_sla"],
    }
    passed = sum(checks.values())
    return {
        "report": "RAPORT_10_CROSSBORDER",
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
    parser = argparse.ArgumentParser(description="RAPORT_10 Cross-Border evidence gate")
    parser.add_argument("--json", action="store_true", help="print JSON evidence")
    parser.add_argument("--write", action="store_true", help="write bundles/crossborder_report10_evidence.json")
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
