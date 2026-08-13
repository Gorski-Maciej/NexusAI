#!/usr/bin/env python3
"""RAPORT_14 RODO / AML-CBDD / BDO / ŚRODOWISKO / SEKURYTYZACJA — evidence gate.

Mirrors tools/kks_report07_gate.py .. hyper_report13_gate.py: the report
distinguishes repository evidence from recommendations, so this tool keeps
that distinction executable. It never infers deployment from file names alone
and fails closed in ``--strict`` mode when production evidence is absent.

Usage (from ``JDG/``)::

    python tools/rodo_aml_bdo_report14_gate.py --json
    python tools/rodo_aml_bdo_report14_gate.py --write
    python tools/rodo_aml_bdo_report14_gate.py --strict
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
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_14_RODO_AML_BDO.txt"
EVIDENCE_PATH = BUNDLES_DIR / "rodo_aml_bdo_report14_evidence.json"

# Paths enumerated by RAPORT_14 (tabela 2.3), kept explicit so the audit
# cannot silently shrink when a future directory scan changes. 28 Rego files.
RULE_FILES = (
    "rules/compliance/aml_enterprise.rego",
    "rules/environmental/bdo_enterprise.rego",
    "rules/environmental.rego",
    "rules/micro/aml/aml.rego",
    "rules/micro/aml/aml_cbdd.rego",
    "rules/micro/aml/aml_ryzyko.rego",
    "rules/micro/aml/aml_str_gif.rego",
    "rules/micro/aml/aml_transakcje.rego",
    "rules/micro/bdo/bdo_ewc.rego",
    "rules/micro/bdo/bdo_ewidencja.rego",
    "rules/micro/bdo/bdo_rejestracja.rego",
    "rules/micro/bdo/bdo_transport.rego",
    "rules/micro/bdo/bdo_weee_baterie.rego",
    "rules/micro/bdo/bdo_zezwolenia.rego",
    "rules/micro/plan33_rodo.rego",
    "rules/micro/rodo/rodo.rego",
    "rules/micro/rodo/rodo_ai_marketing.rego",
    "rules/micro/rodo/rodo_erasure.rego",
    "rules/micro/rodo/rodo_podprocesorzy.rego",
    "rules/micro/rodo/rodo_sankcje.rego",
    "rules/micro/rodo/rodo_zatrudnienie.rego",
    "rules/micro/srodowisko/srodowisko.rego",
    "rules/p15_srodowisko_bdo_innovations_v9.rego",
    "rules/p16_rodo_aml_security_innovations_v9.rego",
    "rules/rodo/plan42_rodo.rego",
    "rules/rodo.rego",
    "rules/rodo_extended.rego",
    "rules/security/security_fortress_v8.rego",
)

TEST_FILES = (
    "tests/test_aml_enterprise.py",
    "tests/test_bdo_enterprise.py",
    "tests/test_rodo_enterprise.py",
    "tests/auto/test_auto_block_rodo.py",
    "tests/auto/test_auto_block_rodo_extended.py",
    "tests/auto/test_p15_srodowisko_bdo_enterprise.py",
    "tests/auto/test_p16_rodo_aml_security_enterprise.py",
    "tests/rego/test_p15_srodowisko_bdo_enterprise.rego",
    "tests/rego/test_p16_rodo_aml_security_enterprise.rego",
    "tests/rego/micro/test_native_micro_aml.rego",
    "tests/rego/micro/test_native_micro_bdo.rego",
    "tests/rego/micro/test_native_micro_rodo.rego",
)

# Priorytety RAPORT_14: rejestr czynności (Art. 30 RODO), prawo do usunięcia
# (Art. 17), podprocesorzy (Art. 28), sankcje (Art. 83), obowiązki AML
# (transakcje > 15 000 EUR Art. 34, STR/GIIF Art. 74-80), BDO (rejestracja
# Art. 49-53 UoO).
CRITICAL_ARTICLES = ("a17", "a28", "a30", "a83", "a34", "a74", "a49")
# Evidence aliases accept the repository's current macro/micro/tool naming.
CRITICAL_MARKERS = {
    "a17": (
        "jdg.rodo_extended.erasure_automation",
        "erasure",
        "Art. 17 RODO",
        "usunięcie",
    ),
    "a28": (
        "jdg.rodo_extended.subprocessor_chain_audit",
        "jdg.p16_rodo_aml_security_innovations.subprocessor_saas_map",
        "subprocessor",
        "Art. 28",
    ),
    "a30": (
        "jdg.p16_rodo_aml_security_innovations.rodo_register_automation",
        "rodo_register_automation",
        "rejestr czynności",
        "Art. 30",
    ),
    "a83": (
        "jdg.p16_rodo_aml_security_innovations.rodo_sanctions_calculator",
        "jdg.rodo_extended.sanctions_uodo",
        "Art. 83",
        "sankcj",
    ),
    "a34": (
        "jdg.p16_rodo_aml_security_innovations.aml_risk_scoring_transaction",
        "aml_risk_scoring_transaction",
        "Art. 34",
        "15000",
    ),
    "a74": (
        "jdg.p16_rodo_aml_security_innovations.str_gijf_auto_submission",
        "str_gijf",
        "Art. 74",
        "GIIF",
    ),
    "a49": (
        "jdg.p15_srodowisko_bdo_innovations.bdo_registration_detector",
        "bdo_registration_detector",
        "Art. 49",
        "rejestracja BDO",
    ),
}

# Temporal evidence is tied to the concrete material verdict block. Dates:
# RODO obowiązuje od 2018-05-25, ustawa AML od 2018-07-13, ustawa o odpadach
# (BDO) od 2013-01-23.
CRITICAL_TEMPORAL_RULES = {
    "a17": ("rules/rodo_extended.rego",
            "jdg.rodo_extended.erasure_automation"),
    "a28": ("rules/rodo_extended.rego",
            "jdg.rodo_extended.subprocessor_chain_audit"),
    "a30": ("rules/p16_rodo_aml_security_innovations_v9.rego",
            "jdg.p16_rodo_aml_security_innovations.rodo_register_automation"),
    "a83": ("rules/rodo_extended.rego",
            "jdg.rodo_extended.sanctions_uodo"),
    "a34": ("rules/p16_rodo_aml_security_innovations_v9.rego",
            "jdg.p16_rodo_aml_security_innovations.aml_risk_scoring_transaction"),
    "a74": ("rules/p16_rodo_aml_security_innovations_v9.rego",
            "jdg.p16_rodo_aml_security_innovations.str_gijf_auto_submission"),
    "a49": ("rules/p15_srodowisko_bdo_innovations_v9.rego",
            "jdg.p15_srodowisko_bdo_innovations.bdo_registration_detector"),
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
    # RAPORT_14 raportował 2 duplikaty (jdg.micro.rodo.no_match,
    # jdg.rodo.no_match); po namespace-rename (plan33_no_match / plan42_no_match)
    # pozostało 0 kolizji.
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
                rf"(?:\b{re.escape(article)}\b|Art\.\s*{re.escape(article[1:])}|"
                rf"{re.escape(article[1:])}[_-])",
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
            texts.get("tests/rego/test_p16_rodo_aml_security_enterprise.rego")
        ),
        "pytest_test_present": bool(
            texts.get("tests/auto/test_p16_rodo_aml_security_enterprise.py")
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
    p16_present = bool(re.search(r"jdg\.p16_rodo_aml_security_innovations", joined))
    p15_present = bool(re.search(r"jdg\.p15_srodowisko_bdo_innovations", joined))
    rodo_present = bool(re.search(r"jdg\.rodo", joined))
    fortress_present = bool(re.search(r"jdg\.security\.fortress", joined))
    final_verdict = "full_final_verdict" in joined
    return {
        "router_files": list(router_files),
        "p16_package_registered": p16_present,
        "p15_package_registered": p15_present,
        "rodo_package_registered": rodo_present,
        "security_fortress_registered": fortress_present,
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
    rodo_verdicts = {
        h: v
        for h, v in verdicts.items()
        if "rodo" in json.dumps(v, ensure_ascii=False).lower()
        or "83" in json.dumps(v, ensure_ascii=False)
        or "sanctions" in json.dumps(v, ensure_ascii=False).lower()
    }
    unmatched = golden.get("unmatched_replays", [])
    if not isinstance(unmatched, list):
        unmatched = []
    return {
        "golden_verdicts_total": len(verdicts),
        "rodo_verdicts": len(rodo_verdicts),
        "replays_total": len(replays),
        "unmatched_replays": unmatched,
        "unmatched_count": len(unmatched),
        "replay_verified": len(rodo_verdicts) >= 1 and len(unmatched) == 0,
    }


def _deployment_evidence() -> dict[str, Any]:
    deployments = json.loads(
        (BUNDLES_DIR / "deployments.json").read_text(encoding="utf-8")
    )
    dep = deployments.get("deployments", {}).get("jdg-rab-bundle-v9.0.0", {})
    return {
        "bundle": "jdg-rab-bundle-v9.0.0",
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
        "router_wired": router["p16_package_registered"]
        and router["p15_package_registered"]
        and router["rodo_package_registered"]
        and router["security_fortress_registered"]
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
        "report": "RAPORT_14_RODO_AML_BDO",
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
    parser = argparse.ArgumentParser(description="RAPORT_14 evidence gate")
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
            f"RAPORT_14: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
