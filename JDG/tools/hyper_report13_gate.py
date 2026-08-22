#!/usr/bin/env python3
"""RAPORT_13 Hyper PLAN45 / Reprezentacja / Działalność regulowana /
Konteksty specjalne — evidence gate.

Mirrors tools/kks_report07_gate.py .. lifecycle_report12_gate.py: the report
distinguishes repository evidence from recommendations, so this tool keeps
that distinction executable. It never infers deployment from file names alone
and fails closed in ``--strict`` mode when production evidence is absent.

Usage (from ``JDG/``)::

    python tools/hyper_report13_gate.py --json
    python tools/hyper_report13_gate.py --write
    python tools/hyper_report13_gate.py --strict
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
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_13_HYPER_CYKL_FIRMY.txt"
EVIDENCE_PATH = BUNDLES_DIR / "hyper_report13_evidence.json"

# Paths enumerated by RAPORT_13 (tabela 2.3), kept explicit so the audit
# cannot silently shrink when a future directory scan changes. 54 Rego files.
RULE_FILES = (
    "rules/_edge_cases_conflicts_rates.rego",
    "rules/advertising/plan44_advertising.rego",
    "rules/advertising/plan45_advertising.rego",
    "rules/calendar/plan44_calendar.rego",
    "rules/calendar/plan45_calendar.rego",
    "rules/calendar_notifier_enterprise.rego",
    "rules/conflict_declaration_enterprise.rego",
    "rules/conflicts.rego",
    "rules/conviction/plan44_conviction.rego",
    "rules/conviction/plan45_conviction.rego",
    "rules/conviction_checker_enterprise.rego",
    "rules/esig/plan44_esig.rego",
    "rules/esig/plan45_esig.rego",
    "rules/esig_auto_applicator_enterprise.rego",
    "rules/family/plan44_family.rego",
    "rules/family/plan45_family.rego",
    "rules/force_majeure/plan44_force_majeure.rego",
    "rules/force_majeure/plan45_force_majeure.rego",
    "rules/fx/plan44_fx.rego",
    "rules/fx/plan45_fx.rego",
    "rules/insurance/plan44_insurance.rego",
    "rules/insurance/plan45_insurance.rego",
    "rules/jdg/hyper/audit/plan45.rego",
    "rules/jdg/hyper/deadlines/plan45.rego",
    "rules/jdg/hyper/edelivery/plan45.rego",
    "rules/jdg/hyper/family/plan45.rego",
    "rules/jdg/hyper/force_majeure/plan45.rego",
    "rules/jdg/hyper/fx/plan45.rego",
    "rules/jdg/hyper/general/plan45.rego",
    "rules/jdg/hyper/limits/plan45.rego",
    "rules/jdg/hyper/mdr/plan45.rego",
    "rules/jdg/hyper/misc/plan45.rego",
    "rules/jdg/hyper/procurement/plan45.rego",
    "rules/jdg/hyper/sanctions/plan45.rego",
    "rules/jdg/hyper/solidarity/plan45.rego",
    "rules/jdg/hyper/wis/plan45.rego",
    "rules/p17_edge_conflicts_innovations_v8.rego",
    "rules/payments/plan44_payments.rego",
    "rules/payments/plan45_payments.rego",
    "rules/procurement/plan44_procurement.rego",
    "rules/procurement/plan45_procurement.rego",
    "rules/regulated/plan44_regulated.rego",
    "rules/regulated/plan45_regulated.rego",
    "rules/regulated_compliance_enterprise.rego",
    "rules/representation.rego",
    "rules/representation/plan26_prokura.rego",
    "rules/residency/plan44_residency.rego",
    "rules/residency/plan45_residency.rego",
    "rules/seasonal/plan44_seasonal.rego",
    "rules/seasonal/plan45_seasonal.rego",
    "rules/solidarity/plan44_solidarity.rego",
    "rules/solidarity/plan45_solidarity.rego",
    "rules/taxfree/plan44_taxfree.rego",
    "rules/taxfree/plan45_taxfree.rego",
)

TEST_FILES = (
    "tests/test_conflicts_enterprise.py",
    "tests/test_edge_cases_enterprise.py",
    "tests/test_hyper_plan45_enterprise.py",
    "tests/test_phase5_modules.py",
    "tests/test_strategic_v2_modules.py",
    "tests/auto/test_auto_block_calendar.py",
    "tests/auto/test_auto_block_conflicts.py",
    "tests/auto/test_auto_block_conviction.py",
    "tests/auto/test_auto_block_edge_cases.py",
    "tests/auto/test_auto_block_edelivery.py",
    "tests/auto/test_auto_block_family.py",
    "tests/auto/test_auto_block_insurance.py",
    "tests/auto/test_auto_block_payments.py",
    "tests/auto/test_auto_block_procurement.py",
    "tests/auto/test_auto_block_regulated.py",
    "tests/auto/test_auto_block_representation.py",
    "tests/auto/test_auto_block_residency.py",
    "tests/auto/test_auto_block_solidarity.py",
    "tests/rego/test_native_hyper_plan45_meta_enterprise.rego",
    "tests/rego/test_native_jdg_esig.rego",
    "tests/rego/test_native_esig_auto_applicator_enterprise.rego",
    "tests/rego/test_native_edelivery_gateway_enterprise.rego",
    "tests/rego/test_native_strategic_advisor_enterprise.rego",
)

# Priorytety RAPORT_13: konflikty międzydomenowe (IP Box vs B+R — art. 30ca
# PIT), danina solidarnościowa (art. 30h PIT), prokura (art. 109¹-109⁸ KC),
# konsekwencje skazań (art. 41 KK), podpis kwalifikowany (eIDAS art. 25-26,
# art. 126 § 5 OP), terminy roczne (art. 45 PIT).
# Artykuły krytyczne = zestaw COMPLETE z testów P13/P17 + pokrycie plan45.
CRITICAL_ARTICLES = ("a30ca", "a30h", "a109", "a41", "e25", "a126", "a45")
# Evidence aliases accept the repository's current macro/micro/tool naming.
CRITICAL_MARKERS = {
    "a30ca": (
        "jdg.conflicts.ip_box_vs_rd_same_income",
        "ip_box_vs_rd",
        "30ca",
        "IP Box",
    ),
    "a30h": (
        "jdg.solidarity.hyper.threshold_1m",
        "threshold_1m",
        "30h",
        "danina solidarnościowa",
    ),
    "a109": (
        "jdg.representation.prokura_self_employed",
        "jdg.representation.prokura_joint",
        "prokura",
        "109",
    ),
    "a41": (
        "jdg.conviction.hyper.business_ban_art41kk",
        "business_ban_art41kk",
        "41 KK",
        "zakaz prowadzenia działalności",
    ),
    "e25": (
        "jdg.esig_auto.signature_selector",
        "jdg.esig.qualified_signature_requirement",
        "eIDAS",
        "signature_selector",
    ),
    "a126": (
        "jdg.esig.qualified_signature_requirement",
        "jdg.esig.hyper.qualified_exceptions",
        "qualified_exceptions",
        "eIDAS",
    ),
    "a45": (
        "jdg.calendar.hyper.pit_annual_return_30april",
        "jdg.r13_hyper_konteksty_innovations.annual_deadline_calendar",
        "pit_annual_return_30april",
        "30 kwietnia",
        "zeznanie roczne",
    ),
}
P17_PACKAGE = "jdg.p17_innovations"

# Temporal evidence is tied to the concrete material verdict block. Dates:
# Kodeks cywilny 1965-01-01, PIT zeznania roczne 1992-01-01, Kodeks karny
# 1998-09-01, eIDAS 2016-07-01, IP Box/danina solidarnościowa 2019-01-01.
CRITICAL_TEMPORAL_RULES = {
    "a30ca": ("rules/conflicts.rego",
              "jdg.conflicts.ip_box_vs_rd_same_income"),
    "a30h": ("rules/solidarity/plan45_solidarity.rego",
             "jdg.solidarity.hyper.threshold_1m"),
    "a109": ("rules/representation/plan26_prokura.rego",
             "jdg.representation.prokura_self_employed"),
    "a41": ("rules/conviction/plan45_conviction.rego",
            "jdg.conviction.hyper.business_ban_art41kk"),
    "e25": ("rules/esig_auto_applicator_enterprise.rego",
            "jdg.esig_auto.signature_selector"),
    "a126": ("rules/esig/plan44_esig.rego",
             "jdg.esig.qualified_signature_requirement"),
    "a45": ("rules/calendar/plan45_calendar.rego",
            "jdg.calendar.hyper.pit_annual_return_30april"),
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
    return len(re.findall(r'"_?legal_basis"\s*:\s*"[^"]+"', text))


def _rule_block_has_temporal(rel: str, rule_id: str) -> bool:
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
                "package_declared": bool(re.search(r"^package\s+", text, re.MULTILINE)),
            }
        )
    counts = Counter(all_ids)
    # RAPORT_13 reports 0 duplicates in scope; verified 2026-08-13:
    # 1269 rule_id / 1269 unique.
    duplicates = sorted(rid for rid, count in counts.items() if count > 1)
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
        "native_rego_test_present": bool(
            texts.get("tests/rego/test_native_hyper_plan45_meta_enterprise.rego")
        ),
        "pytest_test_present": bool(texts.get("tests/test_hyper_plan45_enterprise.py")),
    }


def _article_covers(node_article: str, target_article: str) -> bool:
    """Match a Legal Twin article or numeric range to a target article."""
    normalized = str(node_article).lower().replace("art. ", "").replace(" ", "")
    m = re.match(r"\d+", target_article[1:])
    target = int(m.group(0)) if m else 0
    for part in normalized.split(","):
        part = part.strip()
        rng = re.fullmatch(r"(\d+)[a-z]*-(\d+)[a-z]*", part)
        if rng:
            if int(rng.group(1)) <= target <= int(rng.group(2)):
                return True
            continue
        single = re.fullmatch(r"(\d+)[a-z]*", part)
        if single and int(single.group(1)) == target:
            return True
    return False


def _legal_twin_evidence() -> dict[str, Any]:
    graph = json.loads((BUNDLES_DIR / "legal_graph.json").read_text(encoding="utf-8"))
    nodes = graph.get("nodes", [])
    marker_by_article: dict[str, list[str]] = {}
    for article, candidates in CRITICAL_MARKERS.items():
        marker_by_article[article] = [
            rid
            for node in nodes
            for rid in node.get("rule_ids", [])
            if _article_covers(str(node.get("article", "")), article)
            and any(c in rid for c in candidates)
        ]
    node_articles = {
        article: [
            {
                "legal_node_id": node.get("legal_node_id"),
                "act": node.get("act"),
                "article": node.get("article"),
                "rule_count": len(node.get("rule_ids", [])),
            }
            for node in nodes
            if any(c in rid for rid in node.get("rule_ids", []) for c in candidates)
            and _article_covers(str(node.get("article", "")), article)
        ]
        for article, candidates in CRITICAL_MARKERS.items()
    }
    return {
        "nodes_count": graph.get("nodes_count"),
        "covered_nodes": graph.get("covered_nodes"),
        "indexes": graph.get("indexes"),
        "critical_articles_with_rules": {
            article: bool(marker_by_article.get(article))
            for article in CRITICAL_ARTICLES
        },
        "critical_rule_ids_in_graph": marker_by_article,
        "critical_node_articles": node_articles,
        "critical_articles_required": len(CRITICAL_ARTICLES),
    }


def _router_evidence() -> dict[str, Any]:
    router_files = (
        "rules/main_jdg.rego",
        "rules/router.rego",
        "rules/router_v2.rego",
        "rules/provenance.rego",
    )
    joined = "\n".join(_read(f) for f in router_files)
    p17_present = bool(re.search(rf"{re.escape(P17_PACKAGE)}", joined))
    final_verdict = "full_final_verdict" in joined
    hyper_present = "jdg.hyper_plan45_meta" in joined or "hyper_plan45" in joined
    conflicts_present = "jdg.conflicts" in joined
    return {
        "router_files": list(router_files),
        "p17_package_registered": p17_present,
        "hyper_meta_registered": hyper_present,
        "conflicts_registered": conflicts_present,
        "final_verdict": final_verdict,
        "provenance_joined": bool(joined),
    }


def _safety_evidence() -> dict[str, Any]:
    joined = "\n".join(_read(f) for f in RULE_FILES)
    suggest = bool(re.search(r'"decision_mode"\s*:\s*"SUGGEST"', joined))
    no_auto_post = "AUTO_POST" not in joined
    return {
        "suggest_mode_present": suggest,
        "no_auto_post": no_auto_post,
    }


def _replay_evidence() -> dict[str, Any]:
    golden = json.loads(
        (BUNDLES_DIR / "golden_verdicts.json").read_text(encoding="utf-8")
    )
    verdicts = golden.get("verdicts", {})
    replays = golden.get("replays", {})
    hp_verdicts = {
        h: v
        for h, v in verdicts.items()
        if "solidarity" in json.dumps(v, ensure_ascii=False).lower()
        or "30h" in json.dumps(v, ensure_ascii=False)
    }
    unmatched = golden.get("unmatched_replays", [])
    if not isinstance(unmatched, list):
        unmatched = []
    return {
        "golden_verdicts_total": len(verdicts),
        "hyper_verdicts": len(hp_verdicts),
        "replays_total": len(replays),
        "unmatched_replays": unmatched,
        "unmatched_count": len(unmatched),
        "replay_verified": len(hp_verdicts) >= 1 and len(unmatched) == 0,
    }


def _deployment_evidence() -> dict[str, Any]:
    deployments = json.loads(
        (BUNDLES_DIR / "deployments.json").read_text(encoding="utf-8")
    )
    dep = deployments.get("deployments", {}).get("jdg-hp-bundle-v9.0.0", {})
    return {
        "bundle": "jdg-hp-bundle-v9.0.0",
        "phase": dep.get("phase"),
        "rollout_pct": dep.get("rollout_pct"),
        "quality": dep.get("quality"),
        "error_rate": dep.get("error_rate"),
        "rollback_reason": dep.get("rollback_reason"),
        "soak_completed_at": dep.get("soak_completed_at"),
        "active_version": deployments.get("active_version"),
    }


def build_evidence() -> dict[str, Any]:
    inventory = _file_inventory()
    test = _test_evidence()
    legal_twin = _legal_twin_evidence()
    router = _router_evidence()
    safety = _safety_evidence()
    replay = _replay_evidence()
    deployment = _deployment_evidence()

    gates = {
        "scope_files_present": inventory["files_present"] == inventory["files_total"],
        "duplicate_free": inventory["duplicate_count"] == 0,
        "critical_tests_mapped": test["critical_rule_evidence_complete"],
        "critical_temporal": inventory["critical_temporal_rule_count"]
        >= len(CRITICAL_MARKERS),
        "legal_twin_critical": all(
            legal_twin["critical_articles_with_rules"].values()
        )
        and legal_twin.get("critical_articles_required") == len(CRITICAL_ARTICLES),
        "router_wired": router["p17_package_registered"]
        and router["hyper_meta_registered"]
        and router["conflicts_registered"]
        and router["final_verdict"],
        "safety_suggest": safety["suggest_mode_present"]
        and safety["no_auto_post"],
        "golden_replay_ok": replay["replay_verified"],
        "canary_rollback_ok": deployment["phase"] == "ROLLED_BACK"
        and deployment["rollback_reason"] is not None,
    }
    passed = sum(gates.values())
    total = len(gates)
    status = "WDROZONY_100" if passed == total else "NIEPELNY"
    return {
        "report": "RAPORT_13_HYPER_CYKL_FIRMY",
        "status": status,
        "gates": gates,
        "gate_summary": {"passed": passed, "total": total},
        "inventory": inventory,
        "test_evidence": test,
        "legal_twin": legal_twin,
        "router": router,
        "safety": safety,
        "replay": replay,
        "deployment": deployment,
        "generated_at": __import__("datetime").datetime.now(__import__("datetime").timezone.utc).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="RAPORT_13 evidence gate")
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
            f"RAPORT_13: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
