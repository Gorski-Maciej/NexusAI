#!/usr/bin/env python3
"""RAPORT_09 UoR/PKPiR (Księgowość) — evidence gate.

Mirrors tools/kks_report07_gate.py and tools/ord_report08_gate.py: the report
distinguishes repository evidence from recommendations, so this tool keeps
that distinction executable. It never infers deployment from file names alone
and fails closed in ``--strict`` mode when production evidence is absent.

Usage (from ``JDG/``)::

    python tools/accounting_report09_gate.py --json
    python tools/accounting_report09_gate.py --write
    python tools/accounting_report09_gate.py --strict
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
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_09_UOR_KSIEGOWOSC.txt"
EVIDENCE_PATH = BUNDLES_DIR / "accounting_report09_evidence.json"

# Paths enumerated by RAPORT_09 (tabela 2.3), kept explicit so the audit
# cannot silently shrink when a future directory scan changes.
RULE_FILES = (
    "rules/_pkpir_rates.rego",
    "rules/_uor_rates.rego",
    "rules/accounting/depreciation_enterprise.rego",
    "rules/accounting/depreciation_enterprise_complete.rego",
    "rules/accounting/pkpir_enterprise_live.rego",
    "rules/accounting/pkpir_enterprise_validation.rego",
    "rules/accounting/pkpir_enterprise_validator.rego",
    "rules/accounting/plan23_leasing.rego",
    "rules/accounting/plan42_pkpir.rego",
    "rules/accounting/uor_enterprise_live.rego",
    "rules/accounting.rego",
    "rules/micro/amortyzacja/pit_a22a.rego",
    "rules/micro/amortyzacja/pit_a22i.rego",
    "rules/micro/amortyzacja/pit_a22k.rego",
    "rules/micro/amortyzacja/pit_a22n.rego",
    "rules/micro/pkpir/pkpir.rego",
    "rules/micro/pkpir/pkpir_kolumny.rego",
    "rules/micro/pkpir/pkpir_korekty.rego",
    "rules/micro/pkpir/pkpir_koszty.rego",
    "rules/micro/pkpir/pkpir_nkup.rego",
    "rules/micro/pkpir/pkpir_przychody.rego",
    "rules/micro/pkpir/pkpir_remanent.rego",
    "rules/micro/plan33_uor.rego",
    "rules/micro/uor/uor.rego",
    "rules/p09_ksiegowosc_pkpir_uor_innovations_v9.rego",
    "rules/p11_accounting_pkpir_innovations_v8.rego",
    "rules/p12_uor_innovations_v8.rego",
    "rules/p18_automatyzacja_ksiegowosci_innovations_v9.rego",
    "rules/p33_uor_supplement.rego",
    "rules/pkpir_to_uor_transformer.rego",
    "rules/uor/plan42_uor.rego",
    "rules/uor/uor_assets.rego",
    "rules/uor/uor_books.rego",
    "rules/uor/uor_closing.rego",
    "rules/uor/uor_costs.rego",
    "rules/uor/uor_financial_stmt.rego",
    "rules/uor/uor_inventory.rego",
    "rules/uor/uor_obligation.rego",
    "rules/uor/uor_revenue.rego",
)

TEST_FILES = (
    "tests/test_pkpir_uor_enterprise.py",
    "tests/auto/test_auto_block_accounting.py",
    "tests/auto/test_auto_block_pkpir_live.py",
    "tests/auto/test_p09_ksiegowosc_pkpir_uor_enterprise.py",
    "tests/rego/test_native_jdg_uor.rego",
    "tests/rego/test_p09_ksiegowosc_pkpir_uor_enterprise.rego",
    "tests/rego/test_uor_books.rego",
    "tests/rego/test_uor_inventory_closing_fs.rego",
    "tests/rego/test_uor_live_adapter.rego",
    "tests/rego/test_uor_obligation.rego",
    "tests/rego/test_uor_revenue_costs_assets.rego",
    "tests/rego/micro/test_native_micro_pkpir.rego",
    "tests/rego/micro/test_native_micro_uor.rego",
)

# Priorytety RAPORT_09: progi pełnej księgowości (UoR art. 2 — 2 000 000 EUR),
# amortyzacja PIT (art. 22a/22i/22k — KŚT, limity), inwentaryzacja (UoR art. 26),
# amortyzacja bilansowa vs podatkowa (UoR art. 32).
CRITICAL_ARTICLES = ("a2", "a22a", "a22i", "a22k", "a26", "a32")
# Evidence aliases accept the repository's current macro/micro/tool naming;
# this is a coverage check, not an assertion that every alias is the same rule.
CRITICAL_MARKERS = {
    "a2": (
        "jdg.uor_live.full_accounting_obligation_check",
        "jdg.micro.uor.a2.r1",
        "uor_full_accounting_required",
        "full_accounting_obligation",
    ),
    "a22a": (
        "jdg.pit.depreciation.a22a.r1",
        "jdg.micro.amort_a22a.r1",
        "depreciation_method",
        "depreciation",
    ),
    "a22i": (
        "jdg.micro.amort_a22i.r1",
        "jdg.pit.depreciation.a22i",
        "liniowa",
        "LINEAR",
    ),
    "a22k": (
        "jdg.micro.amort_a22k.r1",
        "jdg.pit.depreciation.a22k",
        "one_time",
        "ONE_OFF",
    ),
    "a26": (
        "jdg.uor_live.inventory_obligation_check",
        "jdg.micro.uor.a26.r1",
        "inwentaryz",
        "inventory_obligation",
    ),
    "a32": (
        "jdg.p09_ksiegowosc_pkpir_uor_innovations.amortization_dual_calculator",
        "jdg.micro.uor.a32.r1",
        "amortization_dual",
        "kst_depreciation",
    ),
}
P09_PACKAGE = "jdg.p09_ksiegowosc_pkpir_uor_innovations"

# Temporal evidence is tied to the concrete material verdict block. A
# file-level occurrence of valid_from/valid_to is not sufficient for a critical
# article. Dates: aktualne teksty jednolite (UoR Dz.U. 2025 poz. 567; PIT).
CRITICAL_TEMPORAL_RULES = {
    "a2": ("rules/accounting/uor_enterprise_live.rego",
           "jdg.uor_live.full_accounting_obligation_check"),
    "a22a": ("rules/accounting/depreciation_enterprise_complete.rego",
             "jdg.pit.depreciation.a22a.r1"),
    "a22i": ("rules/micro/amortyzacja/pit_a22i.rego",
             "jdg.micro.amort_a22i.r1"),
    "a22k": ("rules/micro/amortyzacja/pit_a22k.rego",
             "jdg.micro.amort_a22k.r1"),
    "a26": ("rules/accounting/uor_enterprise_live.rego",
            "jdg.uor_live.inventory_obligation_check"),
    "a32": ("rules/p09_ksiegowosc_pkpir_uor_innovations_v9.rego",
            "jdg.p09_ksiegowosc_pkpir_uor_innovations.amortization_dual_calculator"),
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
    # G-02 resolved on 2026-08-13: the two cross-file collisions
    # (pkpir_col1_sequential, pkpir_col8_other_revenue) were namespace-renamed
    # to jdg.accounting.pkpir_validation.*. Only .no_match fallbacks remain.
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
        "native_rego_test_present": bool(texts.get("tests/rego/test_native_jdg_uor.rego")),
        "pytest_test_present": bool(texts.get("tests/test_pkpir_uor_enterprise.py")),
    }


def _article_covers(node_article: str, target_article: str) -> bool:
    """Match a Legal Twin article or numeric range to a target article.
    Targets may carry letter suffixes (a22a, a22i) — the match is on the
    numeric prefix, consistent with legal_twin.article_match."""
    normalized = str(node_article).lower().replace("art. ", "").replace(" ", "")
    m = re.match(r"\d+", target_article[1:])
    target = int(m.group(0)) if m else 0
    for part in normalized.split(","):
        rng = re.fullmatch(r"(\d+)(?:[a-z])?-(?:(\d+))[a-z]?", part)
        if rng and int(rng.group(1)) <= target <= int(rng.group(2)):
            return True
        single = re.fullmatch(r"(\d+)(?:[a-z])?", part)
        if single and int(single.group(1)) == target:
            return True
    return False


def _legal_twin_evidence() -> dict[str, Any]:
    graph_path = BUNDLES_DIR / "legal_graph.json"
    if not graph_path.is_file():
        return {"present": False, "acc_nodes": 0, "critical_basis_refs": 0}
    try:
        graph = json.loads(graph_path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {"present": False, "acc_nodes": 0, "critical_basis_refs": 0, "invalid": True}
    nodes = graph.get("nodes", []) if isinstance(graph, dict) else []
    acc_nodes = [
        node
        for node in nodes
        if any(
            phrase in str(node.get("act", "")).lower()
            for phrase in ("o rachunkowości", "rachunkowości")
        )
        or "dochodowym od osób fizycznych" in str(node.get("act", "")).lower()
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
            for node in acc_nodes
            if _article_covers(str(node.get("article", "")), article)
            for rule_id in (node.get("rule_ids") or [])
            if rule_id in critical_rule_ids
        })
    refs = sum(bool(rule_ids) for rule_ids in mapped_articles.values())
    return {
        "present": True,
        "acc_nodes": len(acc_nodes),
        "critical_basis_refs": refs,
        "critical_basis_rule_ids": mapped_articles,
        "critical_articles_required": len(CRITICAL_ARTICLES),
        "indexes": graph.get("indexes", {}),
    }


def _router_evidence() -> dict[str, Any]:
    text = _read("rules/main_jdg.rego")
    package_key = f'"{P09_PACKAGE}":'
    return {
        "main_router_present": bool(text),
        "p09_imported": f"import data.{P09_PACKAGE}" in text,
        "p09_registered": package_key in text,
        "p09_final_verdict_wired": "final_verdict_p09" in text,
        "provenance_wired": "provenance.enrich_verdict" in text,
        "runtime_invariants_wired": "runtime_invariants.enforce" in text,
    }


def _safety_evidence() -> dict[str, Any]:
    text = _read("rules/p09_ksiegowosc_pkpir_uor_innovations_v9.rego")
    # P09 is an advisory layer. A SUGGEST marker is required so a future
    # refactor cannot accidentally promote accounting advice to AUTO_POST.
    return {
        "package_present": f"package {P09_PACKAGE}" in text,
        "suggest_mode_declared": '"decision_mode": "SUGGEST"' in text or "decision_mode := \"SUGGEST\"" in text,
        "ask_user_supported_elsewhere": "ASK_USER" in _read("rules/adaptive_trust_scoring_enterprise.rego"),
        "no_auto_post_contract": "AUTO_POST" not in text,
    }


def _replay_evidence() -> dict[str, Any]:
    path = BUNDLES_DIR / "golden_verdicts.json"
    if not path.is_file():
        return {"present": False, "schema_version": None, "acc_verdicts": 0}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {"present": False, "schema_version": None, "acc_verdicts": 0, "invalid": True}
    verdicts = data.get("verdicts", {}) if isinstance(data, dict) else {}
    rows = verdicts.values() if isinstance(verdicts, dict) else []
    acc_rows = [
        row for row in rows
        if any(token in json.dumps(row, ensure_ascii=False).lower()
               for token in ("jdg.uor", "pkpir", "accounting", "uor_live"))
    ]
    replay_rows = data.get("replays", [])
    acc_replays = [
        row for row in replay_rows
        if any(token in json.dumps(row, ensure_ascii=False).lower()
               for token in ("jdg.uor", "pkpir", "accounting", "uor_live"))
    ]
    return {
        "present": True,
        "schema_version": data.get("schema_version"),
        "acc_verdicts": len(acc_rows),
        "replays": len(replay_rows),
        "acc_replays": len(acc_replays),
        "unexplained_replays": sum(bool(row.get("uver_applies")) for row in replay_rows),
        "acc_unexplained_replays": sum(bool(row.get("uver_applies")) for row in acc_replays),
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
    # A generic smoke bundle must never satisfy an ACCOUNTING release gate.
    acc_rows = [
        (version, row)
        for version, row in rows
        if any(token in str(version).lower() for token in ("acc", "p09", "report09"))
    ]
    active = str(data.get("active_version") or "")
    active_is_acc = any(token in active.lower() for token in ("acc", "p09", "report09"))
    return {
        "present": True,
        "acc_deployments": len(acc_rows),
        "canary": any(
            row.get("canary_ok") is True or row.get("phase") in {"CANARY", "FULL_SOAK"}
            for _, row in acc_rows
        ),
        "rollback_sla": any(row.get("rollback_sla_pass") is True for _, row in acc_rows),
        "production_active": bool(data.get("active_version")) and active_is_acc,
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
            and replay.get("acc_verdicts", 0) >= 1
            and replay.get("acc_replays", 0) >= 1
            and replay.get("acc_unexplained_replays", 0) == 0
        ),
        "canary_rollback_gate": deployment["canary"] and deployment["rollback_sla"],
    }
    passed = sum(checks.values())
    return {
        "report": "RAPORT_09_UOR_KSIEGOWOSC",
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
    parser = argparse.ArgumentParser(description="RAPORT_09 UoR/PKPiR evidence gate")
    parser.add_argument("--json", action="store_true", help="print JSON evidence")
    parser.add_argument("--write", action="store_true", help="write bundles/accounting_report09_evidence.json")
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
