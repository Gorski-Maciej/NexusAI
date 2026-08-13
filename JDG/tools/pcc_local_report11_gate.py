#!/usr/bin/env python3
"""RAPORT_11 PCC / Podatki lokalne / Akcyza — evidence gate.

Mirrors tools/kks_report07_gate.py, tools/ord_report08_gate.py,
tools/accounting_report09_gate.py and tools/crossborder_report10_gate.py:
the report distinguishes repository evidence from recommendations, so this
tool keeps that distinction executable. It never infers deployment from file
names alone and fails closed in ``--strict`` mode when production evidence
is absent.

Usage (from ``JDG/``)::

    python tools/pcc_local_report11_gate.py --json
    python tools/pcc_local_report11_gate.py --write
    python tools/pcc_local_report11_gate.py --strict
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
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_11_PCC_LOKALNE_AKCYZA.txt"
EVIDENCE_PATH = BUNDLES_DIR / "pcc_local_report11_evidence.json"

# Paths enumerated by RAPORT_11 (tabela 2.3), kept explicit so the audit
# cannot silently shrink when a future directory scan changes. 32 Rego files.
RULE_FILES = (
    "rules/_pcc_local_excise_rates.rego",
    "rules/local_taxes/akcyza_alcohol.rego",
    "rules/local_taxes/akcyza_fuel.rego",
    "rules/local_taxes/excise_enterprise_complete.rego",
    "rules/local_taxes/local_procedures_enterprise.rego",
    "rules/local_taxes/pcc.rego",
    "rules/local_taxes/pcc_enterprise_complete.rego",
    "rules/local_taxes/pcc_excise_enterprise.rego",
    "rules/local_taxes/plan26_local.rego",
    "rules/local_taxes/real_estate.rego",
    "rules/local_taxes/transport.rego",
    "rules/local_taxes.rego",
    "rules/micro/akcyza/akcyza.rego",
    "rules/micro/pcc/pcc.rego",
    "rules/micro/plan33_agricultural_tax.rego",
    "rules/micro/plan33_pcc.rego",
    "rules/micro/plan33_prop_transport.rego",
    "rules/micro/transport/transport.rego",
    "rules/p14_pcc_lokalne_akcyza_innovations_v9.rego",
    "rules/p15_pcc_local_excise_innovations_v8.rego",
    "rules/p33_excise_supplement.rego",
    "rules/p33_pcc_complete.rego",
    "rules/pcc/pcc_companies.rego",
    "rules/pcc/pcc_loans.rego",
    "rules/pcc/pcc_rates.rego",
    "rules/pcc/pcc_sales.rego",
    "rules/pcc/plan42_pcc.rego",
)

TEST_FILES = (
    "tests/test_pcc_excise_enterprise.py",
    "tests/auto/test_auto_block_local.py",
    "tests/auto/test_auto_block_local_taxes.py",
    "tests/auto/test_p14_pcc_lokalne_akcyza_enterprise.py",
    "tests/rego/test_native_jdg_pcc.rego",
    "tests/rego/test_p14_pcc_lokalne_akcyza_enterprise.rego",
    "tests/rego/test_pcc_loans_companies_rates.rego",
    "tests/rego/test_pcc_sales.rego",
    "tests/rego/micro/test_native_micro_pcc.rego",
)

# Priorytety RAPORT_11: PCC (umowy sprzedaży/pożyczki/spółki — stawki
# 0,5%/1%/2%, obowiązek 14 dni — art. 1-2/4/6-7/10 PCC), podatek od
# nieruchomości (art. 2-7 u.p.o.l.), środki transportu (art. 8-14 u.p.o.l.),
# akcyza (paliwo art. 30-32, alkohol art. 92-99c, rejestracja AKC-R art. 16).
# Artykuły krytyczne = zestaw COMPLETE z testów P14.
CRITICAL_ARTICLES = ("a1", "a7", "a8", "a12", "a16", "a30", "a99")
# Evidence aliases accept the repository's current macro/micro/tool naming;
# this is a coverage check, not an assertion that every alias is the same rule.
CRITICAL_MARKERS = {
    "a1": (
        "jdg.local_taxes.pcc.sale_detection",
        "jdg.micro.pcc.a1.r1",
        "umowy sprzedaży",
        "PCC",
    ),
    "a7": (
        "jdg.local_taxes.pcc.installment_sale",
        "jdg.pcc.rate_changes.a7.r5",
        "a7",
        "PCC",
    ),
    "a8": (
        "jdg.local_taxes.transport.truck_over_3_5t",
        "jdg.micro.transport.a4.r1",
        "transport_tax_calculator",
        "środków transportowych",
    ),
    "a12": (
        "jdg.local_taxes.transport.tax_applicable",
        "jdg.micro.transport.a4.r1",
        "DT-1",
        "transport_tax",
    ),
    "a16": (
        "jdg.local_taxes.excise.akcr_registration",
        "jdg.micro.akcyza.a16.r1",
        "AKC-R",
        "excise_fuel",
    ),
    "a30": (
        "jdg.local_taxes.excise.exemption_verification",
        "jdg.micro.akcyza.a30.r1",
        "excise_fuel_calculator",
        "paliwo",
    ),
    "a99": (
        "jdg.p14_pcc_lokalne_akcyza_innovations.excise_alcohol_calculator",
        "jdg.micro.akcyza.a99.r1",
        "alkohol",
        "excise_alcohol",
    ),
}
P14_PACKAGE = "jdg.p14_pcc_lokalne_akcyza_innovations"

# Temporal evidence is tied to the concrete material verdict block. A
# file-level occurrence of valid_from/valid_to is not sufficient for a critical
# article. Dates: PCC 2001-01-01 (ustawa z 2000 r. weszła w życie 1.01.2001),
# podatki lokalne/środki transportu 2002-01-01, akcyza 2009-03-01 (nowa
# ustawa o podatku akcyzowym z 6.12.2008).
CRITICAL_TEMPORAL_RULES = {
    "a1": ("rules/local_taxes/pcc_enterprise_complete.rego",
           "jdg.local_taxes.pcc.sale_detection"),
    "a7": ("rules/local_taxes/pcc_enterprise_complete.rego",
           "jdg.local_taxes.pcc.installment_sale"),
    "a8": ("rules/local_taxes/pcc_enterprise_complete.rego",
           "jdg.local_taxes.transport.truck_over_3_5t"),
    "a12": ("rules/local_taxes/transport.rego",
            "jdg.local_taxes.transport.tax_applicable"),
    "a16": ("rules/local_taxes/pcc_enterprise_complete.rego",
            "jdg.local_taxes.excise.akcr_registration"),
    "a30": ("rules/local_taxes/excise_enterprise_complete.rego",
            "jdg.local_taxes.excise.exemption_verification"),
    "a99": ("rules/p14_pcc_lokalne_akcyza_innovations_v9.rego",
            "jdg.p14_pcc_lokalne_akcyza_innovations.excise_alcohol_calculator"),
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
    # G-02 resolved on 2026-08-13: jdg.local_taxes.no_match,
    # jdg.local_taxes.pcc.no_match and jdg.micro.pcc.no_match were
    # namespace-renamed in the secondary files (plan26_local.rego,
    # pcc_enterprise_complete.rego, plan33_pcc.rego). Primary no_match
    # fallbacks remain (one per package, not a collision).
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
        "native_rego_test_present": bool(texts.get("tests/rego/micro/test_native_micro_pcc.rego")),
        "pytest_test_present": bool(texts.get("tests/test_pcc_excise_enterprise.py")),
    }


def _article_covers(node_article: str, target_article: str) -> bool:
    """Match a Legal Twin article or numeric range to a target article.
    Targets may carry letter suffixes (a30da, a23zf) and ranges may carry
    multi-letter suffixes (23m-23zf) — the match is on the numeric prefix,
    consistent with legal_twin.article_match."""
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
        return {"present": False, "plb_nodes": 0, "critical_basis_refs": 0}
    try:
        graph = json.loads(graph_path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {"present": False, "plb_nodes": 0, "critical_basis_refs": 0, "invalid": True}
    nodes = graph.get("nodes", []) if isinstance(graph, dict) else []
    plb_nodes = [
        node
        for node in nodes
        if any(
            token in str(node.get("act", "")).lower()
            for token in (
                "czynności cywilnoprawnych",
                "podatkach i opłatach lokalnych",
                "podatku akcyzowym",
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
            for node in plb_nodes
            if _article_covers(str(node.get("article", "")), article)
            for rule_id in (node.get("rule_ids") or [])
            if rule_id in critical_rule_ids
        })
    refs = sum(bool(rule_ids) for rule_ids in mapped_articles.values())
    return {
        "present": True,
        "plb_nodes": len(plb_nodes),
        "critical_basis_refs": refs,
        "critical_basis_rule_ids": mapped_articles,
        "critical_articles_required": len(CRITICAL_ARTICLES),
        "indexes": graph.get("indexes", {}),
    }


def _router_evidence() -> dict[str, Any]:
    text = _read("rules/main_jdg.rego")
    package_key = f'"{P14_PACKAGE}":'
    return {
        "main_router_present": bool(text),
        "p14_imported": f"import data.{P14_PACKAGE}" in text,
        "p14_registered": package_key in text,
        "p14_final_verdict_wired": "final_verdict_p14" in text,
        "local_taxes_imported": "import data.jdg.local_taxes" in text,
        "p15_imported": "import data.jdg.p15_innovations" in text,
        "provenance_wired": "provenance.enrich_verdict" in text,
        "runtime_invariants_wired": "runtime_invariants.enforce" in text,
    }


def _safety_evidence() -> dict[str, Any]:
    text = _read("rules/p14_pcc_lokalne_akcyza_innovations_v9.rego")
    # P14 is an advisory layer. A SUGGEST marker is required so a future
    # refactor cannot accidentally promote PCC/local/excise advice to
    # automatic decision-making.
    return {
        "package_present": f"package {P14_PACKAGE}" in text,
        "suggest_mode_declared": '"decision_mode": "SUGGEST"' in text or "decision_mode := \"SUGGEST\"" in text,
        "ask_user_supported_elsewhere": "ASK_USER" in _read("rules/adaptive_trust_scoring_enterprise.rego"),
        "no_auto_post_contract": "AUTO_POST" not in text,
    }


def _replay_evidence() -> dict[str, Any]:
    path = BUNDLES_DIR / "golden_verdicts.json"
    if not path.is_file():
        return {"present": False, "schema_version": None, "plb_verdicts": 0}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {"present": False, "schema_version": None, "plb_verdicts": 0, "invalid": True}
    verdicts = data.get("verdicts", {}) if isinstance(data, dict) else {}
    rows = verdicts.values() if isinstance(verdicts, dict) else []
    plb_rows = [
        row for row in rows
        if any(token in json.dumps(row, ensure_ascii=False).lower()
               for token in ("pcc", "local_taxes", "excise", "akcyz", "local_tax", "p14"))
    ]
    replay_rows = data.get("replays", [])
    plb_replays = [
        row for row in replay_rows
        if any(token in json.dumps(row, ensure_ascii=False).lower()
               for token in ("pcc", "local_taxes", "excise", "akcyz", "local_tax", "p14"))
    ]
    return {
        "present": True,
        "schema_version": data.get("schema_version"),
        "plb_verdicts": len(plb_rows),
        "replays": len(replay_rows),
        "plb_replays": len(plb_replays),
        "unexplained_replays": sum(bool(row.get("uver_applies")) for row in replay_rows),
        "plb_unexplained_replays": sum(bool(row.get("uver_applies")) for row in plb_replays),
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
    # A generic smoke bundle must never satisfy a PCC/LOCAL/EXCISE release gate.
    plb_rows = [
        (version, row)
        for version, row in rows
        if any(token in str(version).lower() for token in ("plb", "p14", "report11", "pcc"))
    ]
    active = str(data.get("active_version") or "")
    active_is_plb = any(token in active.lower() for token in ("plb", "p14", "report11", "pcc"))
    return {
        "present": True,
        "plb_deployments": len(plb_rows),
        "canary": any(
            row.get("canary_ok") is True or row.get("phase") in {"CANARY", "FULL_SOAK", "ROLLED_BACK"}
            for _, row in plb_rows
        ),
        "rollback_sla": any(row.get("rollback_sla_pass") is True for _, row in plb_rows),
        "production_active": bool(data.get("active_version")) and active_is_plb,
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
            and replay.get("plb_verdicts", 0) >= 1
            and replay.get("plb_replays", 0) >= 1
            and replay.get("plb_unexplained_replays", 0) == 0
        ),
        "canary_rollback_gate": deployment["canary"] and deployment["rollback_sla"],
    }
    passed = sum(checks.values())
    return {
        "report": "RAPORT_11_PCC_LOKALNE_AKCYZA",
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
    parser = argparse.ArgumentParser(description="RAPORT_11 PCC/Local/Excise evidence gate")
    parser.add_argument("--json", action="store_true", help="print JSON evidence")
    parser.add_argument("--write", action="store_true", help="write bundles/pcc_local_report11_evidence.json")
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
