#!/usr/bin/env python3
"""Legal Twin traceability layer — ETAP 03.

The legacy ``legal_graph.json`` is retained as historical input. This layer adds
explicit, auditable edges instead of treating a free-form ``_legal_basis`` string
as proof. Ambiguous or missing mappings are preserved as findings and fail the
publication gate.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from collections import defaultdict
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"
TESTS_DIR = JDG_ROOT / "tests"
GRAPH_PATH = JDG_ROOT / "bundles" / "legal_graph.json"
SOURCE_REGISTRY_PATH = JDG_ROOT / "bundles" / "legal_source_registry.json"
GOLDEN_PATH = JDG_ROOT / "bundles" / "golden_verdicts.json"
OUT_PATH = JDG_ROOT / "bundles" / "legal_twin_traceability.json"
OUT_MD = JDG_ROOT / "docs" / "LEGAL_TWIN_TRACEABILITY.md"

RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
LEGAL_BASIS_RE = re.compile(r'"_legal_basis"\s*:\s*"((?:\\.|[^"\\])*)"')
PACKAGE_RE = re.compile(r"(?:^|\n)\s*package\s+([^\s]+)")
ARTICLE_REF_RE = re.compile(
    r"\b(?:art\.?|article)\s*(\d+[a-z]?(?:\s*[-–]\s*\d+[a-z]?)?)",
    re.IGNORECASE,
)
DATE_RE = re.compile(r"\b20\d{2}-\d{2}-\d{2}\b")


def _canonical_hash(value: Any) -> str:
    return "sha256:" + hashlib.sha256(
        json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    ).hexdigest()


def _num(value: str) -> int:
    match = re.match(r"\d+", value)
    return int(match.group(0)) if match else -1


def _span(value: str) -> tuple[int, int]:
    parts = re.split(r"\s*[-–]\s*", value.lower().replace(" ", ""))
    start = _num(parts[0]) if parts else -1
    end = _num(parts[-1]) if parts else start
    return start, end if end >= start else start


def article_covers(node_article: str, reference: str) -> bool:
    node_start, node_end = _span(node_article)
    ref_start, ref_end = _span(reference)
    return node_start >= 0 and ref_start >= 0 and not (node_end < ref_start or ref_end < node_start)


def _normalise(value: str) -> str:
    return re.sub(r"\s+", " ", value.lower().replace("–", "-").replace("—", "-")).strip()


def _record_hay(record: dict[str, Any]) -> str:
    return _normalise(" ".join([
        record.get("canonical_short", ""), record.get("full_name", ""),
        record.get("domain", ""), " ".join(record.get("keywords", [])),
    ]))


def _basis_mentions_record(basis: str, record: dict[str, Any]) -> bool:
    """Conservative act matching; no token means no automatic legal edge."""
    text = _normalise(basis)
    short = _normalise(record.get("canonical_short", ""))
    domain = _normalise(record.get("domain", ""))
    aliases = {
        "vat": ("vat", "towarów i usług"),
        "pit": ("pit", "dochodowym od osób fizycznych"),
        "cit": ("cit", "osób prawnych"),
        "ordpu": ("ordynacj", "ordpu"),
        "kks": ("kks", "karny skarbowy", "karnym skarbowym"),
        "zus": ("zus", "sus", "ubezpieczeń społecznych", "zdrowotnej", "zasiłk"),
        "uor": ("uor", "rachunkowości", "pkpir"),
        "business": ("przedsiębiorc", "ceidg", "sukcesj"),
        "pcc": ("pcc", "czynności cywilnoprawnych"),
        "local": ("lokalnych", "podatku rolnym"),
        "excise": ("akcyz",),
        "bdo": ("bdo", "odpad"),
        "rodo": ("rodo", "2016/679", "danych osobowych"),
        "aml": ("aml", "praniu pieniędzy"),
        "ksef": ("ksef", "e-faktur"),
        "edelivery": ("doręczeń", "edoreczenia", "edelivery"),
        "hr": ("kodeks pracy", "rehabilitacj"),
        "construction": ("budowlan",),
        "transport": ("transporcie drogowym",),
        "crossborder": ("dewiz",),
        "energy": ("energetyczn",),
    }
    if short and short in text:
        return True
    if domain in aliases and any(token in text for token in aliases[domain]):
        return True
    return any(keyword and _normalise(keyword) in text for keyword in record.get("keywords", []))


def _load_json(path: Path, default: dict[str, Any]) -> dict[str, Any]:
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8"))


def _extract_string_list(block: str, key: str) -> list[str]:
    match = re.search(rf'"{re.escape(key)}"\s*:\s*\[([^\]]*)\]', block, re.DOTALL)
    if not match:
        return []
    return re.findall(r'"((?:\\.|[^"\\])*)"', match.group(1))


def _scan_rules() -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for path in sorted(RULES_DIR.rglob("*.rego")):
        text = path.read_text(encoding="utf-8", errors="ignore")
        matches = list(RULE_ID_RE.finditer(text))
        package = (PACKAGE_RE.search(text) or ["", ""])[1]
        relative = str(path.relative_to(JDG_ROOT))
        for index, match in enumerate(matches):
            end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
            block = text[match.start():end]
            basis_match = LEGAL_BASIS_RE.search(block)
            basis = basis_match.group(1) if basis_match else ""
            rows.append({
                "rule_id": match.group(1),
                "file": relative,
                "line": text.count("\n", 0, match.start()) + 1,
                "package": package,
                "legal_basis": basis,
                "explicit_legal_basis_refs": _extract_string_list(block, "_legal_basis_refs"),
                "threshold_keys": _extract_string_list(block, "thresholds"),
                "valid_dates": sorted(set(DATE_RE.findall(block))),
            })
    return rows


def _test_index() -> dict[str, list[str]]:
    result: dict[str, set[str]] = defaultdict(set)
    for path in sorted(TESTS_DIR.rglob("*")):
        if not path.is_file() or path.suffix not in {".py", ".rego"}:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for rule_id in set(RULE_ID_RE.findall(text)) | set(re.findall(r"\bjdg\.[A-Za-z0-9_.-]+\b", text)):
            if rule_id.startswith("jdg.") and rule_id in text:
                result[rule_id].add(str(path.relative_to(JDG_ROOT)))
    return {key: sorted(value) for key, value in result.items()}


def _verdict_index() -> dict[str, list[dict[str, Any]]]:
    golden = _load_json(GOLDEN_PATH, {})
    result: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for input_hash, entry in golden.get("verdicts", {}).items():
        verdict = entry.get("verdict", {})
        rule_id = verdict.get("rule_id")
        if not rule_id:
            continue
        result[rule_id].append({
            "input_hash": input_hash,
            "verdict_hash": entry.get("verdict_hash"),
            "bundle_version": entry.get("bundle_version"),
            "transaction_date": verdict.get("transaction_date") or verdict.get("evaluation_date")
                or verdict.get("valid_from"),
            "legal_basis_refs": entry.get("legal_basis_refs", []),
        })
    return dict(result)


def _node_intervals(nodes: list[dict[str, Any]], records: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
    enriched = []
    for node in nodes:
        source = records.get(node.get("source_record_id"), {})
        node_interval = node.get("effective_interval", {})
        source_interval = source.get("effective_interval", {})
        starts = [value for value in (node_interval.get("valid_from"), source_interval.get("valid_from")) if value]
        start = max(starts) if starts else None
        end = node_interval.get("valid_to") or source_interval.get("valid_to")
        enriched.append({**node, "effective_interval": {
            "valid_from": start,
            "valid_to": end,
            "claim_status": node_interval.get("claim_status", "UNVERIFIED"),
        }})
    return enriched


def _resolve_reference(
    basis: str,
    reference: str,
    nodes: list[dict[str, Any]],
    records: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    candidates = []
    for node in nodes:
        if not article_covers(node.get("article", ""), reference):
            continue
        record = records.get(node.get("source_record_id"), {})
        if _basis_mentions_record(basis, record) or _basis_mentions_record(basis, {
            "canonical_short": node.get("act", ""),
            "full_name": node.get("act", ""),
            "domain": "", "keywords": [],
        }):
            candidates.append(node)
    # Prefer an exact article node; otherwise choose the unique narrowest
    # range. Broad historical ranges must not create false ambiguity when an
    # exact canonical node exists.
    exact = [node for node in candidates if _normalise(node.get("article", "")) == _normalise(reference)]
    if len(exact) == 1:
        selected = exact
        status = "RESOLVED"
    else:
        candidates.sort(key=lambda node: (_span(node.get("article", ""))[1] - _span(node.get("article", ""))[0], node.get("legal_node_id", "")))
        narrowest = []
        if candidates:
            width = _span(candidates[0].get("article", ""))[1] - _span(candidates[0].get("article", ""))[0]
            narrowest = [node for node in candidates if _span(node.get("article", ""))[1] - _span(node.get("article", ""))[0] == width]
        selected = narrowest if len(narrowest) == 1 else []
        status = "RESOLVED" if len(narrowest) == 1 else ("UNRESOLVED" if not candidates else "AMBIGUOUS")
    return {
        "reference": reference,
        "status": status,
        "candidate_node_ids": [node.get("legal_node_id") for node in candidates[:20]],
        "legal_node_ids": [node.get("legal_node_id") for node in selected],
        "source_record_ids": [node.get("source_record_id") for node in selected],
        "mapping_method": "canonical_act_and_article_semantic_match" if selected else "none",
    }


def build_traceability() -> dict[str, Any]:
    graph = _load_json(GRAPH_PATH, {"nodes": []})
    source_registry = _load_json(SOURCE_REGISTRY_PATH, {"records": [], "legal_nodes": []})
    records = {record.get("source_record_id"): record for record in source_registry.get("records", [])}
    nodes = _node_intervals(source_registry.get("legal_nodes") or graph.get("nodes", []), records)
    rules = _scan_rules()
    tests = _test_index()
    verdicts = _verdict_index()
    by_rule: dict[str, dict[str, Any]] = {}
    occurrences: dict[str, list[dict[str, Any]]] = defaultdict(list)
    reverse: dict[str, set[str]] = defaultdict(set)

    for rule in rules:
        rid = rule["rule_id"]
        refs = []
        basis_for_matching = rule["legal_basis"] or " ".join(rule["explicit_legal_basis_refs"])
        for match in ARTICLE_REF_RE.finditer(basis_for_matching):
            reference = re.sub(r"\s+", "", match.group(1))
            refs.append(_resolve_reference(basis_for_matching, reference, nodes, records))
        for explicit in rule["explicit_legal_basis_refs"]:
            node_id = explicit.strip()
            if node_id.startswith("LKG-"):
                exact = next((node for node in nodes if node.get("legal_node_id") == node_id), None)
                refs.append({
                    "reference": explicit,
                    "status": "RESOLVED" if exact else "UNRESOLVED",
                    "candidate_node_ids": [node_id] if exact else [],
                    "legal_node_ids": [node_id] if exact else [],
                    "source_record_ids": [exact.get("source_record_id")] if exact else [],
                    "mapping_method": "explicit_legal_basis_ref",
                })
        if not rule["legal_basis"].strip() and not rule["explicit_legal_basis_refs"]:
            mapping_status = "MISSING_SOURCE"
        elif not refs:
            mapping_status = "NO_ARTICLE_REFERENCE"
        elif all(ref["status"] == "RESOLVED" for ref in refs):
            mapping_status = "RESOLVED"
        elif any(ref["status"] == "AMBIGUOUS" for ref in refs):
            mapping_status = "AMBIGUOUS_MAPPING"
        else:
            mapping_status = "UNRESOLVED_MAPPING"
        linked_nodes = sorted({node_id for ref in refs for node_id in ref["legal_node_ids"]})
        for node_id in linked_nodes:
            reverse[node_id].add(rid)
        item = by_rule.setdefault(rid, {
            "rule_id": rid,
            "occurrences": [],
            "legal_basis": rule["legal_basis"],
            "legal_basis_variants": [],
            "legal_basis_refs": [],
            "explicit_legal_basis_refs": [],
            "legal_node_ids": [],
            "threshold_keys": [],
            "test_paths": tests.get(rid, []),
            "verdict_evidence": verdicts.get(rid, []),
            "interpretation_evidence": [],
            "mapping_status": mapping_status,
        })
        item["occurrences"].append({"file": rule["file"], "line": rule["line"], "package": rule["package"]})
        if rule["legal_basis"] and rule["legal_basis"] not in item["legal_basis_variants"]:
            item["legal_basis_variants"].append(rule["legal_basis"])
        item["legal_basis_refs"].extend(refs)
        status_rank = {"RESOLVED": 0, "NO_ARTICLE_REFERENCE": 1, "UNRESOLVED_MAPPING": 2,
                       "AMBIGUOUS_MAPPING": 3, "MISSING_SOURCE": 4}
        if status_rank.get(mapping_status, 5) > status_rank.get(item["mapping_status"], 5):
            item["mapping_status"] = mapping_status
        item["explicit_legal_basis_refs"] = sorted(
            set(item["explicit_legal_basis_refs"]) | set(rule["explicit_legal_basis_refs"])
        )
        item["legal_node_ids"] = sorted(set(item["legal_node_ids"]) | set(linked_nodes))
        item["threshold_keys"] = sorted(set(item["threshold_keys"]) | set(rule["threshold_keys"]))
        if re.search(r"\b(?:kis|interpretacj|wis|nsa|orzeczeni)\b", rule["legal_basis"], re.IGNORECASE):
            item["interpretation_evidence"].append({"type": "textual_reference", "basis": rule["legal_basis"]})
        occurrences[rid].append(rule)

    for item in by_rule.values():
        unique_refs = {}
        for ref in item["legal_basis_refs"]:
            key = json.dumps(ref, ensure_ascii=False, sort_keys=True)
            unique_refs[key] = ref
        item["legal_basis_refs"] = list(unique_refs.values())
        item["legacy_string_migration"] = {
            "source_field": "_legal_basis",
            "target_field": "_legal_basis_refs",
            "migration_status": "DERIVED_EDGE_ONLY",
            "requires_review": item["mapping_status"] != "RESOLVED",
        }

    node_rows = []
    for node in nodes:
        node_id = node.get("legal_node_id")
        rule_ids = sorted(reverse.get(node_id, set()))
        node_rows.append({
            "legal_node_id": node_id,
            "source_record_id": node.get("source_record_id"),
            "source_hash": node.get("source_hash"),
            "act": node.get("act"),
            "article": node.get("article"),
            "node_type": node.get("node_type", "ARTICLE"),
            "effective_interval": node.get("effective_interval", {}),
            "rule_ids": rule_ids,
            "threshold_keys": node.get("threshold_keys", []),
            "provenance": node.get("provenance", []),
            "confidence": node.get("confidence", 0.0),
            "coverage_status": "COVERED" if rule_ids else "DESERT",
        })

    rule_values = list(by_rule.values())
    total_refs = sum(len(item["legal_basis_refs"]) for item in rule_values)
    resolved_refs = sum(
        sum(1 for ref in item["legal_basis_refs"] if ref["status"] == "RESOLVED")
        for item in rule_values
    )
    resolved_rules = sum(1 for item in rule_values if item["mapping_status"] == "RESOLVED")
    interval_complete = sum(1 for node in node_rows if node["effective_interval"].get("valid_from"))
    metrics = {
        "LCI": round(sum(node["coverage_status"] == "COVERED" for node in node_rows) / max(len(node_rows), 1) * 100, 2),
        "TCL": round(interval_complete / max(len(node_rows), 1) * 100, 2),
        "RV": round(resolved_rules / max(len(rule_values), 1) * 100, 2),
        "UVR": round(resolved_refs / max(total_refs, 1) * 100, 2),
        "definitions": {
            "LCI": "węzły LKG z co najmniej jedną rozstrzygniętą krawędzią do reguły",
            "TCL": "węzły z kompletnym interwałem valid_from; ciągłość wersji wymaga źródeł zewnętrznych",
            "RV": "unikalne reguły, których wszystkie znalezione referencje mapują się jednoznacznie",
            "UVR": "referencje artykułów z jednoznacznym węzłem i źródłem",
        },
    }
    findings = {
        "missing_source_rules": sorted(rid for rid, item in by_rule.items() if item["mapping_status"] == "MISSING_SOURCE"),
        "no_article_reference_rules": sorted(rid for rid, item in by_rule.items() if item["mapping_status"] == "NO_ARTICLE_REFERENCE"),
        "ambiguous_mapping_rules": sorted(rid for rid, item in by_rule.items() if item["mapping_status"] == "AMBIGUOUS_MAPPING"),
        "unresolved_mapping_rules": sorted(rid for rid, item in by_rule.items() if item["mapping_status"] == "UNRESOLVED_MAPPING"),
        "coverage_deserts": [node["legal_node_id"] for node in node_rows if node["coverage_status"] == "DESERT"],
    }
    bundle = {
        "schema_version": "1.0.0",
        "traceability_id": "jdg.legal_twin.traceability",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source_graph": "JDG/bundles/legal_graph.json",
        "source_registry": "JDG/bundles/legal_source_registry.json",
        "metrics": metrics,
        "findings": findings,
        "rules": sorted(rule_values, key=lambda item: item["rule_id"]),
        "legal_nodes": sorted(node_rows, key=lambda item: item["legal_node_id"] or ""),
        "publication_policy": {
            "mode": "FAIL_CLOSED",
            "requires_resolved_mapping": True,
            "requires_source_record": True,
            "requires_official_source_verification": True,
            "requires_temporal_evidence_for_decision": True,
            "legacy_legal_basis_is_evidence": False,
        },
        "integrity_hash": None,
    }
    bundle["integrity_hash"] = _canonical_hash({key: value for key, value in bundle.items() if key != "integrity_hash"})
    return bundle


def validate_traceability(bundle: dict[str, Any], publication_gate: bool = False) -> dict[str, Any]:
    issues: list[str] = []
    warnings: list[str] = []
    nodes = bundle.get("legal_nodes", [])
    rules = bundle.get("rules", [])
    node_ids = [node.get("legal_node_id") for node in nodes]
    rule_ids = [rule.get("rule_id") for rule in rules]
    if len(node_ids) != len(set(node_ids)):
        issues.append("duplicate legal_node_id")
    if len(rule_ids) != len(set(rule_ids)):
        issues.append("duplicate unique rule rows")
    calculated = _canonical_hash({key: value for key, value in bundle.items() if key != "integrity_hash"})
    if bundle.get("integrity_hash") != calculated:
        issues.append("integrity_hash mismatch")
    node_set = set(node_ids)
    for rule in rules:
        for ref in rule.get("legal_basis_refs", []):
            for node_id in ref.get("legal_node_ids", []):
                if node_id not in node_set:
                    issues.append(f"{rule.get('rule_id')}: unknown node {node_id}")
            if ref.get("status") != "RESOLVED":
                warnings.append(f"{rule.get('rule_id')}: {ref.get('status')} {ref.get('reference')}")
        if not rule.get("test_paths"):
            warnings.append(f"{rule.get('rule_id')}: no test evidence")
    deserts = bundle.get("findings", {}).get("coverage_deserts", [])
    if deserts:
        warnings.append(f"coverage deserts: {len(deserts)}")
    if publication_gate:
        findings = bundle.get("findings", {})
        for key in ("missing_source_rules", "no_article_reference_rules", "ambiguous_mapping_rules", "unresolved_mapping_rules", "coverage_deserts"):
            if findings.get(key):
                issues.append(f"publication blocked by {key}: {len(findings[key])}")
        for node in nodes:
            if not node.get("source_record_id") or node.get("confidence", 0) < 1:
                issues.append(f"publication blocked by unverified source: {node.get('legal_node_id')}")
    return {
        "status": "PASS" if not issues else "FAIL",
        "publication_gate": publication_gate,
        "issues": issues,
        "warnings": warnings,
        "rules": len(rules),
        "legal_nodes": len(nodes),
        "metrics": bundle.get("metrics", {}).copy(),
    }


def time_travel(bundle: dict[str, Any], node_id: str, decision_date: str) -> dict[str, Any]:
    node = next((item for item in bundle.get("legal_nodes", []) if item.get("legal_node_id") == node_id), None)
    if not node:
        return {"legal_node_id": node_id, "decision_date": decision_date, "status": "NO_NODE", "exists": False}
    try:
        target = date.fromisoformat(decision_date)
        start = date.fromisoformat(node["effective_interval"]["valid_from"])
        end = date.fromisoformat(node["effective_interval"]["valid_to"]) if node["effective_interval"].get("valid_to") else None
    except (KeyError, TypeError, ValueError):
        return {"legal_node_id": node_id, "decision_date": decision_date, "status": "INSUFFICIENT_TEMPORAL_EVIDENCE", "exists": None}
    in_interval = target >= start and (end is None or target <= end)
    source_verified = False
    if node.get("confidence", 0) >= 1 and node.get("source_hash"):
        source_verified = True
    return {
        "legal_node_id": node_id,
        "decision_date": decision_date,
        "valid_from": start.isoformat(),
        "valid_to": end.isoformat() if end else None,
        "status": "PROVEN" if in_interval and source_verified else "NEEDS_SOURCE_VERIFICATION",
        "exists": True if in_interval and source_verified else None,
        "source_verified": source_verified,
    }


def write_outputs(bundle: dict[str, Any]) -> dict[str, Any]:
    result = validate_traceability(bundle)
    OUT_PATH.write_text(json.dumps(bundle, indent=2, ensure_ascii=False), encoding="utf-8")
    metrics = bundle["metrics"]
    findings = bundle["findings"]
    OUT_MD.write_text("\n".join([
        "# Legal Twin Traceability — ETAP 03",
        "",
        f"> Generator: `JDG/tools/legal_twin_traceability.py` · schema `{bundle['schema_version']}`",
        "",
        "| Metric | Value |",
        "|---|---:|",
        f"| LCI | {metrics['LCI']}% |",
        f"| TCL | {metrics['TCL']}% |",
        f"| RV | {metrics['RV']}% |",
        f"| UVR | {metrics['UVR']}% |",
        "",
        f"- Reguły: {result['rules']}",
        f"- Węzły LKG: {result['legal_nodes']}",
        f"- Pustynie pokrycia: {len(findings['coverage_deserts'])}",
        f"- Bramka strukturalna: **{result['status']}**",
        "",
        "Traceability jest dwukierunkowe: `legal_node → rule_ids` oraz `rule → legal_node_ids`.",
        "Brak źródła, niejednoznaczne mapowanie i brak dowodu temporalnego blokują publikację.",
        "",
    ]), encoding="utf-8")
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description="JDG Legal Twin traceability — ETAP 03")
    sub = parser.add_subparsers(dest="command", required=True)
    build = sub.add_parser("build")
    build.set_defaults(fn="build")
    validate = sub.add_parser("validate")
    validate.add_argument("--publication-gate", action="store_true")
    validate.set_defaults(fn="validate")
    travel = sub.add_parser("time-travel")
    travel.add_argument("--node-id", required=True)
    travel.add_argument("--date", required=True)
    travel.set_defaults(fn="time-travel")
    args = parser.parse_args()

    if args.fn == "build":
        bundle = build_traceability()
        result = write_outputs(bundle)
        print(json.dumps({
            "status": result["status"],
            "rules": result["rules"],
            "legal_nodes": result["legal_nodes"],
            "metrics": result["metrics"],
            "finding_counts": {key: len(value) for key, value in bundle["findings"].items()},
        }, ensure_ascii=False, indent=2))
        return
    bundle = _load_json(OUT_PATH, {})
    if args.fn == "validate":
        result = validate_traceability(bundle, args.publication_gate)
        # Keep the CLI bounded: large inventories can contain thousands of
        # warnings, and emitting all of them can make a non-blocking pipe fail.
        bounded = {
            key: result[key]
            for key in ("status", "publication_gate", "rules", "legal_nodes", "metrics")
        }
        bounded["issues_count"] = len(result["issues"])
        bounded["warnings_count"] = len(result["warnings"])
        bounded["issues_sample"] = result["issues"][:10]
        bounded["warnings_sample"] = result["warnings"][:10]
        print(json.dumps(bounded, ensure_ascii=False, indent=2))
        raise SystemExit(0 if result["status"] == "PASS" else 1)
    print(json.dumps(time_travel(bundle, args.node_id, args.date), ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
