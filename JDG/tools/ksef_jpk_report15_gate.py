#!/usr/bin/env python3
"""RAPORT_15 KSeF / JPK / e-DEKLARACJE / e-DORĘCZENIA / WIS / GTU — evidence gate.

Mirrors tools/kks_report07_gate.py .. rodo_aml_bdo_report14_gate.py: the report
distinguishes repository evidence from recommendations, so this tool keeps
that distinction executable. It never infers deployment from file names alone
and fails closed in ``--strict`` mode when production evidence is absent.

Usage (from ``JDG/``)::

    python tools/ksef_jpk_report15_gate.py --json
    python tools/ksef_jpk_report15_gate.py --write
    python tools/ksef_jpk_report15_gate.py --strict
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
REPORT_PATH = BASE_DIR / "raporty_glm52_enterprise" / "RAPORT_15_KSEF_JPK.txt"
EVIDENCE_PATH = BUNDLES_DIR / "ksef_jpk_report15_evidence.json"

# Paths enumerated by RAPORT_15 (tabela 2.3), kept explicit so the audit
# cannot silently shrink when a future directory scan changes. 33 Rego files.
RULE_FILES = (
    "rules/_compliance_rates.rego",
    "rules/corrections.rego",
    "rules/cross_declaration_validator_enterprise.rego",
    "rules/edelivery/plan44_edelivery.rego",
    "rules/edelivery/plan45_edelivery.rego",
    "rules/edelivery_gateway_enterprise.rego",
    "rules/edelivery_gateway_v2_enterprise.rego",
    "rules/epuap_enterprise.rego",
    "rules/gtu_completeness_checker_enterprise.rego",
    "rules/jpk/plan26_deadlines.rego",
    "rules/jpk_cit.rego",
    "rules/jpk_corrections_workflow_enterprise.rego",
    "rules/jpk_kr_st_generator_enterprise.rego",
    "rules/jpk_v7_autogen_enterprise.rego",
    "rules/ksef_firewall_enterprise.rego",
    "rules/ksef_innovations_enterprise.rego",
    "rules/ksef_jpk.rego",
    "rules/ksef_offline_queue_enterprise.rego",
    "rules/ksef_outbox_enterprise.rego",
    "rules/ksef_receipt_digest_enterprise.rego",
    "rules/ksef_resilience_enterprise.rego",
    "rules/ksef_sanction_monitor_enterprise.rego",
    "rules/ksef_sandbox_harness_enterprise.rego",
    "rules/ksef_upo_tracker_enterprise.rego",
    "rules/micro/jpk/jpk.rego",
    "rules/micro/ksef/ksef.rego",
    "rules/micro/plan33_jpk.rego",
    "rules/micro/plan33_ksef.rego",
    "rules/p17_ksef_jpk_edeklaracje_innovations_v9.rego",
    "rules/wis/plan44_wis.rego",
    "rules/wis/plan45_wis.rego",
    "rules/wis_api_enterprise.rego",
    "rules/wis_autorequester_enterprise.rego",
)

TEST_FILES = (
    "tests/test_ksef_generator.py",
    "tests/auto/test_auto_block_edelivery.py",
    "tests/auto/test_auto_block_ksef_jpk.py",
    "tests/auto/test_auto_block_ksef_resilience.py",
    "tests/auto/test_auto_block_wis.py",
    "tests/auto/test_p17_ksef_jpk_edeklaracje_enterprise.py",
    "tests/rego/test_p17_ksef_jpk_edeklaracje_enterprise.rego",
    "tests/rego/test_native_p00_legal_coverage_enterprise.rego",
    "tests/rego/test_native_edelivery_gateway_enterprise.rego",
    "tests/rego/test_native_gtu_completeness_checker_enterprise.rego",
    "tests/rego/test_native_jdg_jpk.rego",
    "tests/rego/test_native_jpk_corrections_workflow_enterprise.rego",
    "tests/rego/test_native_jpk_kr_st_generator_enterprise.rego",
    "tests/rego/test_native_jpk_v7_autogen_enterprise.rego",
    "tests/rego/test_native_ksef_sanction_monitor_enterprise.rego",
    "tests/rego/test_native_wis_api_enterprise.rego",
)

# Priorytety RAPORT_15: KSeF 2.0 (art. 106na-106nq VAT, obowiązek 01.02.2026,
# sankcje do 500 000 zł), JPK_V7M (art. 99 VAT), JPK_PKPIR (art. 193a OrdPU),
# WIS (art. 42a VAT), korekty KSeF (art. 106j VAT), JPK_V7 (art. 82 ust. 1b VAT),
# tryb awaryjny KSeF (art. 106nb ust. 5-6 VAT).
CRITICAL_ARTICLES = ("106na", "99", "193a", "42a", "106j", "82", "106nb")
# Evidence aliases accept the repository's current macro/micro/tool naming.
CRITICAL_MARKERS = {
    "106na": (
        "jdg.ksef_jpk.ksef_mandatory",
        "ksef_mandatory",
        "Art. 106na",
    ),
    "99": (
        "jdg.ksef_jpk.jpk_v7m",
        "jpk_v7m",
        "Art. 99",
    ),
    "193a": (
        "jdg.ksef_jpk.jpk_pkpir",
        "jpk_pkpir",
        "Art. 193a",
    ),
    "42a": (
        "jdg.p17_ksef_jpk_edeklaracje_innovations.wis_auto_requester",
        "wis_auto_requester",
        "Art. 42a",
    ),
    "106j": (
        "jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_corrections_e2e",
        "ksef_corrections_e2e",
        "Art. 106j",
    ),
    "82": (
        "jdg.p17_ksef_jpk_edeklaracje_innovations.jpk_v7_auto_generator",
        "jpk_v7_auto_generator",
        "Art. 82",
    ),
    "106nb": (
        "jdg.ksef_jpk.ksef_offline_recovery",
        "ksef_offline_recovery",
        "Art. 106nb",
    ),
}

# Temporal evidence is tied to the concrete material verdict block. Dates:
# KSeF obowiązkowy od 2026-02-01, JPK_V7M od 2020-10-01, JPK_PKPIR (art. 193a
# OrdPU) od 2016-07-01, WIS od 2019-11-01, korekty KSeF (art. 106j) od
# 2014-01-01, JPK_V7 (art. 82) od 2016-01-01, tryb awaryjny od 2026-02-01.
CRITICAL_TEMPORAL_RULES = {
    "106na": ("rules/ksef_jpk.rego",
              "jdg.ksef_jpk.ksef_mandatory"),
    "99": ("rules/ksef_jpk.rego",
           "jdg.ksef_jpk.jpk_v7m"),
    "193a": ("rules/ksef_jpk.rego",
             "jdg.ksef_jpk.jpk_pkpir"),
    "42a": ("rules/p17_ksef_jpk_edeklaracje_innovations_v9.rego",
            "jdg.p17_ksef_jpk_edeklaracje_innovations.wis_auto_requester"),
    "106j": ("rules/p17_ksef_jpk_edeklaracje_innovations_v9.rego",
             "jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_corrections_e2e"),
    "82": ("rules/p17_ksef_jpk_edeklaracje_innovations_v9.rego",
           "jdg.p17_ksef_jpk_edeklaracje_innovations.jpk_v7_auto_generator"),
    "106nb": ("rules/ksef_jpk.rego",
              "jdg.ksef_jpk.ksef_offline_recovery"),
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
    # RAPORT_15 raportował 2 duplikaty (jdg.micro.jpk.no_match,
    # jdg.micro.ksef.no_match); po namespace-rename (plan33_no_match) pozostało
    # 0 kolizji.
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
                rf"(?:\b{re.escape(article)}\b|Art\.\s*{re.escape(article[1:])}|\b"
                rf"{re.escape(article[1:])}\b)",
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
        "critical_rule_marker_aliases": {k: list(v) for k, v in CRITICAL_MARKERS.items()},
        "critical_articles_referenced": article_hits,
        "critical_rule_evidence_complete": all(marker_hits.values()),
        "native_rego_test_present": bool(
            texts.get("tests/rego/test_p17_ksef_jpk_edeklaracje_enterprise.rego")
        ),
        "pytest_test_present": bool(
            texts.get("tests/auto/test_p17_ksef_jpk_edeklaracje_enterprise.py")
        ),
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
    covered = {
        article: any(
            _article_covers(str(n.get("article", "")), article) and n.get("rule_ids")
            for n in nodes
        )
        for article in CRITICAL_ARTICLES
    }
    all_rule_ids = {rid for n in nodes for rid in n.get("rule_ids", [])}
    marker_present = {
        article: any(any(c in rid for c in candidates) for rid in all_rule_ids)
        for article, candidates in CRITICAL_MARKERS.items()
    }
    node_articles = {
        article: [
            {
                "legal_node_id": n.get("legal_node_id"),
                "act": n.get("act"),
                "article": n.get("article"),
                "rule_count": len(n.get("rule_ids", [])),
            }
            for n in nodes
            if _article_covers(str(n.get("article", "")), article)
            and n.get("rule_ids")
        ]
        for article in CRITICAL_ARTICLES
    }
    return {
        "nodes_count": graph.get("nodes_count"),
        "covered_nodes": graph.get("covered_nodes"),
        "indexes": graph.get("indexes"),
        "critical_articles_with_rules": covered,
        "critical_markers_in_graph": marker_present,
        "critical_node_articles": node_articles,
        "critical_articles_required": len(CRITICAL_ARTICLES),
    }


def _router_evidence() -> dict[str, Any]:
    router_files = (
        "rules/main_jdg.rego",
        "rules/provenance.rego",
    )
    joined = "\n".join(_read(f) for f in router_files)
    ksef_jpk_present = bool(re.search(r"jdg\.ksef_jpk", joined))
    jpk_v7_present = bool(re.search(r"jdg\.jpk_v7_autogen", joined))
    wis_api_present = bool(re.search(r"jdg\.wis_api", joined))
    epuap_present = bool(re.search(r"jdg\.epuap", joined))
    p17_present = bool(re.search(r"jdg\.p17_ksef_jpk_edeklaracje_innovations", joined))
    final_verdict = "full_final_verdict" in joined
    return {
        "router_files": list(router_files),
        "ksef_jpk_registered": ksef_jpk_present,
        "jpk_v7_autogen_registered": jpk_v7_present,
        "wis_api_registered": wis_api_present,
        "epuap_registered": epuap_present,
        "p17_package_registered": p17_present,
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
    if not isinstance(replays, (list, dict)):
        replays = []
    ksef_verdicts = {
        h: v
        for h, v in verdicts.items()
        if "ksef" in json.dumps(v, ensure_ascii=False).lower()
        or "jpk" in json.dumps(v, ensure_ascii=False).lower()
        or "106na" in json.dumps(v, ensure_ascii=False)
    }
    unmatched = golden.get("unmatched_replays", [])
    if not isinstance(unmatched, list):
        unmatched = []
    return {
        "golden_verdicts_total": len(verdicts),
        "ksef_verdicts": len(ksef_verdicts),
        "replays_total": len(replays),
        "unmatched_replays": unmatched,
        "unmatched_count": len(unmatched),
        "replay_verified": len(ksef_verdicts) >= 1 and len(unmatched) == 0,
    }


def _deployment_evidence() -> dict[str, Any]:
    deployments = json.loads(
        (BUNDLES_DIR / "deployments.json").read_text(encoding="utf-8")
    )
    dep = deployments.get("deployments", {}).get("jdg-kjp-bundle-v9.0.0", {})
    return {
        "bundle": "jdg-kjp-bundle-v9.0.0",
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
        and all(legal_twin["critical_markers_in_graph"].values())
        and legal_twin.get("critical_articles_required") == len(CRITICAL_ARTICLES),
        "router_wired": router["ksef_jpk_registered"]
        and router["jpk_v7_autogen_registered"]
        and router["wis_api_registered"]
        and router["epuap_registered"]
        and router["p17_package_registered"]
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
        "report": "RAPORT_15_KSEF_JPK_DEKLARACJE",
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
    parser = argparse.ArgumentParser(description="RAPORT_15 evidence gate")
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
            f"RAPORT_15: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
