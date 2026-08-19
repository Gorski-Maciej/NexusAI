#!/usr/bin/env python3
"""JDG Legal Source Registry — ETAP 02.

This module deliberately separates repository metadata from verified external law.
It never claims that a citation is current merely because it appears in a text file.
The ``build`` command creates candidate records from the canonical catalogue and
attaches auditable provenance, hashes and effective-interval claims. Publication is
fail-closed until two distinct reviewers approve a record backed by an official
source snapshot.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

JDG_ROOT = Path(__file__).resolve().parent.parent
CANON_PATH = JDG_ROOT / "bundles" / "legal_reference_canon.json"
GRAPH_PATH = JDG_ROOT / "bundles" / "legal_graph.json"
REGISTRY_PATH = JDG_ROOT / "bundles" / "legal_source_registry.json"
OUT_REPORT = JDG_ROOT / "docs" / "LEGAL_SOURCE_REGISTRY.md"

SCHEMA_VERSION = "1.0.0"
POLISH_MONTHS = {
    "stycznia": 1, "lutego": 2, "marca": 3, "kwietnia": 4,
    "maja": 5, "czerwca": 6, "lipca": 7, "sierpnia": 8,
    "września": 9, "października": 10, "listopada": 11, "grudnia": 12,
}


def _jsonable(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def record_hash(record: dict[str, Any]) -> str:
    """Hash only the immutable source identity and claims, never the hash itself."""
    payload = {k: v for k, v in record.items() if k not in {"source_hash", "record_hash"}}
    return "sha256:" + hashlib.sha256(_jsonable(payload).encode("utf-8")).hexdigest()


def _slug(text: str) -> str:
    value = text.lower().replace("ł", "l").replace("ą", "a").replace("ę", "e")
    value = value.replace("ś", "s").replace("ć", "c").replace("ź", "z").replace("ż", "z")
    value = value.replace("ó", "o").replace("ń", "n")
    return re.sub(r"[^a-z0-9]+", "_", value).strip("_")


def _enactment_date(full_name: str) -> str | None:
    match = re.search(r"z dnia (\d{1,2}) ([a-ząćęłńóśźż]+) (\d{4}) r\.?", full_name.lower())
    if not match or match.group(2) not in POLISH_MONTHS:
        return None
    day, month, year = int(match.group(1)), POLISH_MONTHS[match.group(2)], int(match.group(3))
    return f"{year:04d}-{month:02d}-{day:02d}"


def _source_provenance(index: int) -> list[dict[str, Any]]:
    return [
        {
            "source_type": "canonical_catalogue",
            "path": "JDG/bundles/legal_reference_canon.json",
            "locator": f"acts[{index}]",
            "retrieved_at": None,
        },
        {
            "source_type": "repository_document",
            "path": "JDG/docs/Bbb.md",
            "locator": "catalogue_reference",
            "retrieved_at": None,
        },
        {
            "source_type": "official_feed",
            "system": "ISAP",
            "url": "https://isap.sejm.gov.pl",
            "retrieved_at": None,
            "verification": "REQUIRES_EXTERNAL_SNAPSHOT",
        },
    ]


def _record(index: int, act: dict[str, Any]) -> dict[str, Any]:
    canonical_short = act["canonical_short"]
    valid_from = _enactment_date(act.get("full_name", ""))
    record: dict[str, Any] = {
        "source_record_id": f"LSR-{index + 1:04d}",
        "act_key": "jdg.legal." + _slug(canonical_short),
        "canonical_short": canonical_short,
        "full_name": act["full_name"],
        "publication": {
            "citation": act["dz_u"],
            "journal": "Dz.U." if "Dz.U. UE" not in act["dz_u"] else "Dz.U. UE",
            "official_identifier": act["dz_u"],
        },
        "domain": act["domain"],
        "keywords": sorted(set(act["keywords"])),
        "effective_interval": {
            "valid_from": valid_from,
            "valid_to": None,
            "precision": "ACT_ENACTMENT_DATE" if valid_from else "UNKNOWN",
            "claim_status": "UNVERIFIED_EXTERNAL",
        },
        "source_hash": None,
        "hash_scope": "canonical_record_metadata_not_official_text",
        "provenance": _source_provenance(index),
        "confidence": 0.55,
        "confidence_label": "REPOSITORY_CANDIDATE",
        "verification": {
            "official_snapshot_hash": None,
            "official_snapshot_uri": None,
            "verified_at": None,
            "verified_by": [],
            "review_state": "PENDING_4_EYES",
        },
        "publication_state": "BLOCKED_UNVERIFIED",
    }
    record["source_hash"] = record_hash(record)
    return record


def _act_tokens(text: str) -> set[str]:
    value = text.lower()
    tokens = set()
    for key, words in {
        "vat": ("vat", "towarów i usług"),
        "pit": ("pit", "dochodowym od osób fizycznych"),
        "cit": ("cit", "osób prawnych"),
        "rycz": ("ryczał", "ryczalt", "zryczałtowanym"),
        "ord": ("ordynacj",),
        "kks": ("kks", "karny skarbowy", "karnym skarbowym"),
        "zus": ("zus", "ubezpieczeń społecznych", "zdrowotnej", "zasiłk"),
        "uor": ("rachunkowości", "uor", "pkpir"),
        "business": ("przedsiębiorc", "ceidg", "sukcesj"),
        "pcc": ("pcc", "czynności cywilnoprawnych"),
        "local": ("lokalnych", "podatku rolnym"),
        "excise": ("akcyz"),
        "bdo": ("bdo", "odpad"),
        "rodo": ("rodo", "2016/679", "danych osobowych"),
        "aml": ("aml", "praniu pieniędzy"),
        "ksef": ("ksef", "e-faktur"),
        "edelivery": ("doręczeń", "edoreczenia", "edelivery"),
        "hr": ("kodeks pracy", "rehabilitacj"),
        "construction": ("budowlan"),
        "transport": ("transporcie drogowym"),
        "crossborder": ("dewiz"),
        "energy": ("energetyczn",),
    }.items():
        if any(word in value for word in words):
            tokens.add(key)
    return tokens


def _record_for_node(node_act: str, records: list[dict[str, Any]]) -> dict[str, Any] | None:
    node_tokens = _act_tokens(node_act)
    candidates = []
    for record in records:
        haystack = " ".join([
            record["canonical_short"], record["full_name"], record["domain"],
            " ".join(record["keywords"]),
        ])
        overlap = len(node_tokens & _act_tokens(haystack))
        if overlap:
            candidates.append((overlap, record))
    return max(candidates, key=lambda item: item[0])[1] if candidates else None


def build_registry() -> dict[str, Any]:
    canon = json.loads(CANON_PATH.read_text(encoding="utf-8"))
    records = [_record(i, act) for i, act in enumerate(canon.get("acts", []))]
    graph = json.loads(GRAPH_PATH.read_text(encoding="utf-8")) if GRAPH_PATH.exists() else {"nodes": []}
    nodes = []
    orphan_nodes = []
    for node in graph.get("nodes", []):
        source = _record_for_node(node.get("act", ""), records)
        effective = {
            "valid_from": node.get("valid_from"),
            "valid_to": node.get("valid_to"),
            "claim_status": "INHERITED_UNVERIFIED_LKG",
        }
        enriched = {
            "legal_node_id": node.get("legal_node_id"),
            "source_record_id": source["source_record_id"] if source else None,
            "source_hash": source["source_hash"] if source else None,
            "act": node.get("act"),
            "article": node.get("article"),
            "node_type": node.get("node_type", "ARTICLE"),
            "effective_interval": effective,
            "version": node.get("version", 1),
            "status": node.get("status", "UNVERIFIED"),
            "rule_ids": node.get("rule_ids", []),
            "provenance": [{
                "source_type": "legal_graph",
                "path": "JDG/bundles/legal_graph.json",
                "locator": node.get("legal_node_id"),
            }],
            "confidence": source["confidence"] if source else 0.0,
            "confidence_label": "INHERITED_UNVERIFIED" if source else "ORPHANED_SOURCE",
        }
        nodes.append(enriched)
        if source is None:
            orphan_nodes.append(enriched["legal_node_id"])
    review_queue = [
        {
            "source_record_id": record["source_record_id"],
            "review_state": "PENDING_4_EYES",
            "required_approvals": 2,
            "approvals": [],
            "publication_blocked": True,
        }
        for record in records
    ]
    registry = {
        "schema_version": SCHEMA_VERSION,
        "registry_id": "jdg.legal_source_registry",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source_of_truth": "JDG/bundles/legal_reference_canon.json",
        "records": records,
        "legal_nodes": nodes,
        "review_queue": review_queue,
        "publication_policy": {
            "mode": "FAIL_CLOSED",
            "requires_official_snapshot": True,
            "requires_two_distinct_reviewers": True,
            "allows_repository_text_as_sole_evidence": False,
            "blocked_states": ["UNVERIFIED_EXTERNAL", "PENDING_4_EYES", "ORPHANED_SOURCE"],
        },
        "integrity": {
            "record_count": len(records),
            "legal_node_count": len(nodes),
            "orphan_node_count": len(orphan_nodes),
            "orphan_node_ids": orphan_nodes,
        },
    }
    return registry


def _parse_date(value: Any, field: str, issues: list[str], allow_null: bool = True):
    if value is None and allow_null:
        return None
    if not isinstance(value, str):
        issues.append(f"{field}: must be ISO date or null")
        return None
    try:
        datetime.strptime(value, "%Y-%m-%d")
    except ValueError:
        issues.append(f"{field}: invalid ISO date {value!r}")
    return value


def validate_registry(registry: dict[str, Any], publication_gate: bool = False) -> dict[str, Any]:
    issues: list[str] = []
    warnings: list[str] = []
    records = registry.get("records", [])
    ids = [record.get("source_record_id") for record in records]
    if len(ids) != len(set(ids)):
        issues.append("duplicate source_record_id")
    record_map = {}
    for record in records:
        rid = record.get("source_record_id", "<missing>")
        record_map[rid] = record
        required = ("source_record_id", "act_key", "canonical_short", "full_name",
                    "publication", "domain", "keywords", "effective_interval",
                    "source_hash", "hash_scope", "provenance", "confidence",
                    "verification", "publication_state")
        for key in required:
            if key not in record:
                issues.append(f"{rid}: missing {key}")
        if record.get("source_hash") != record_hash(record):
            issues.append(f"{rid}: source_hash mismatch")
        confidence = record.get("confidence")
        if not isinstance(confidence, (int, float)) or not 0 <= confidence <= 1:
            issues.append(f"{rid}: confidence outside [0,1]")
        interval = record.get("effective_interval", {})
        start = _parse_date(interval.get("valid_from"), f"{rid}.valid_from", issues)
        end = _parse_date(interval.get("valid_to"), f"{rid}.valid_to", issues)
        if start and end and start > end:
            issues.append(f"{rid}: valid_from after valid_to")
        if not record.get("provenance"):
            issues.append(f"{rid}: empty provenance")
        for provenance in record.get("provenance", []):
            path = provenance.get("path")
            if path and not (JDG_ROOT.parent / path).exists():
                issues.append(f"{rid}: provenance path does not exist: {path}")
        verification = record.get("verification", {})
        if verification.get("review_state") != "PENDING_4_EYES":
            warnings.append(f"{rid}: review state is not pending")
        if publication_gate and record.get("publication_state") != "PUBLISHED":
            issues.append(f"{rid}: publication blocked ({record.get('publication_state')})")
        if publication_gate and not verification.get("official_snapshot_hash"):
            issues.append(f"{rid}: missing official snapshot hash")

    for node in registry.get("legal_nodes", []):
        rid = node.get("source_record_id")
        if rid is None:
            warnings.append(f"{node.get('legal_node_id')}: orphaned source")
            if publication_gate:
                issues.append(f"{node.get('legal_node_id')}: orphaned source")
            continue
        record = record_map.get(rid)
        if not record:
            issues.append(f"{node.get('legal_node_id')}: unknown source_record_id {rid}")
        elif node.get("source_hash") != record.get("source_hash"):
            issues.append(f"{node.get('legal_node_id')}: source hash does not match record")
        interval = node.get("effective_interval", {})
        _parse_date(interval.get("valid_from"), f"{node.get('legal_node_id')}.valid_from", issues)
        _parse_date(interval.get("valid_to"), f"{node.get('legal_node_id')}.valid_to", issues)

    queue_map = {entry.get("source_record_id"): entry for entry in registry.get("review_queue", [])}
    for rid in ids:
        entry = queue_map.get(rid)
        if not entry:
            issues.append(f"{rid}: missing review queue entry")
            continue
        approvals = entry.get("approvals", [])
        reviewers = [a.get("reviewer") for a in approvals]
        if len(reviewers) != len(set(reviewers)):
            issues.append(f"{rid}: duplicate reviewers violate 4-eyes")
        if publication_gate and len(approvals) < 2:
            issues.append(f"{rid}: fewer than two approvals")
        if publication_gate and len(approvals) >= 2:
            if not all(approval.get("decision") == "APPROVE" for approval in approvals):
                issues.append(f"{rid}: not all reviewers approved")
            if any(approval.get("reviewed_hash") != record_map[rid].get("source_hash")
                   for approval in approvals):
                issues.append(f"{rid}: review used stale source hash")

    return {
        "status": "PASS" if not issues else "FAIL",
        "publication_gate": publication_gate,
        "issues": issues,
        "warnings": warnings,
        "records": len(records),
        "legal_nodes": len(registry.get("legal_nodes", [])),
        "pending_review": sum(
            1 for record in records
            if record.get("verification", {}).get("review_state") == "PENDING_4_EYES"
        ),
    }


def append_review(
    registry: dict[str, Any],
    source_record_id: str,
    reviewer: str,
    decision: str,
    reviewed_hash: str,
    comment: str = "",
    official_snapshot_hash: str | None = None,
) -> dict[str, Any]:
    """Append one immutable review without allowing self-approval or stale hashes."""
    if decision not in {"APPROVE", "REJECT", "REQUEST_CHANGES"}:
        raise ValueError("decision must be APPROVE, REJECT or REQUEST_CHANGES")
    record = next((r for r in registry.get("records", [])
                   if r.get("source_record_id") == source_record_id), None)
    queue = next((q for q in registry.get("review_queue", [])
                  if q.get("source_record_id") == source_record_id), None)
    if record is None or queue is None:
        raise KeyError(source_record_id)
    if reviewed_hash != record.get("source_hash"):
        raise ValueError("reviewed_hash does not match current source_hash")
    if any(a.get("reviewer") == reviewer for a in queue.get("approvals", [])):
        raise ValueError("reviewer has already reviewed this source hash")
    queue.setdefault("approvals", []).append({
        "reviewer": reviewer,
        "decision": decision,
        "reviewed_hash": reviewed_hash,
        "comment": comment,
    })
    if official_snapshot_hash:
        record.setdefault("verification", {})["official_snapshot_hash"] = official_snapshot_hash
    approvals = queue["approvals"]
    if len(approvals) >= 2 and all(a.get("decision") == "APPROVE" for a in approvals):
        record["verification"]["review_state"] = "APPROVED"
        record["publication_state"] = "READY_FOR_PUBLISH"
        queue["review_state"] = "APPROVED"
    return registry


def diff_registries(before: dict[str, Any], after: dict[str, Any]) -> dict[str, Any]:
    old = {r["source_record_id"]: r for r in before.get("records", [])}
    new = {r["source_record_id"]: r for r in after.get("records", [])}
    added = sorted(set(new) - set(old))
    removed = sorted(set(old) - set(new))
    changed = []
    for rid in sorted(set(old) & set(new)):
        if old[rid].get("source_hash") != new[rid].get("source_hash"):
            changed.append({
                "source_record_id": rid,
                "old_hash": old[rid].get("source_hash"),
                "new_hash": new[rid].get("source_hash"),
                "requires_4_eyes_review": True,
            })
    return {
        "schema_version": "1.0.0",
        "comparison": {"before": before.get("registry_id"), "after": after.get("registry_id")},
        "added": added,
        "removed": removed,
        "changed": changed,
        "publication_gate": "BLOCKED_UNTIL_REVIEW",
    }


def write_registry(registry: dict[str, Any]) -> None:
    REGISTRY_PATH.write_text(json.dumps(registry, indent=2, ensure_ascii=False), encoding="utf-8")


def write_report(registry: dict[str, Any], validation: dict[str, Any]) -> None:
    integrity = registry.get("integrity", {})
    lines = [
        "# Legal Source Registry — ETAP 02",
        "",
        f"> Generator: `JDG/tools/legal_source_registry.py` · schema `{registry.get('schema_version')}`",
        "> Status danych: kandydaci repozytoryjni; brak fikcyjnej certyfikacji aktualności prawa.",
        "",
        "## Model",
        "",
        "- `source_record_id` — stabilny identyfikator źródła.",
        "- `source_hash` — SHA-256 metadanych rekordu; nie jest hashem oficjalnego tekstu ustawy.",
        "- `effective_interval` — jawny interwał z oznaczeniem `UNVERIFIED_EXTERNAL`.",
        "- `provenance` — ścieżka katalog → dokument → wymagany feed oficjalny.",
        "- `confidence` — pewność kandydata repozytoryjnego, nie opinia prawna.",
        "- `legal_nodes` — węzły LKG z referencją do rekordu źródłowego i propagowanym hashem.",
        "",
        "## 4-eyes i publikacja",
        "",
        "Publikacja jest blokowana do czasu dostarczenia hashy oficjalnego snapshotu, "
        "dwóch różnych recenzentów oraz zatwierdzenia interwału i diffu prawnego.",
        "",
        "## Wynik budowy",
        "",
        f"- Rekordy źródeł: {integrity.get('record_count', 0)}",
        f"- Węzły Legal Twin: {integrity.get('legal_node_count', 0)}",
        f"- Węzły bez dopasowanego rekordu: {integrity.get('orphan_node_count', 0)}",
        f"- Walidacja strukturalna: **{validation['status']}**",
        f"- Rekordy oczekujące na 4-eyes: {validation.get('pending_review', 0)}",
        "",
        "## Ograniczenia",
        "",
        "- Repozytorium nie zawiera pobranych, podpisanych tekstów ISAP/RCL; pipeline nie może ich wymyślić.",
        "- Część `legal_graph.json` ma historyczne lub niezweryfikowane interwały; pozostają jawnie oznaczone.",
        "- `PUBLISHED` jest niedostępny bez zewnętrznego snapshotu i dwóch niezależnych akceptacji.",
        "",
    ]
    OUT_REPORT.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="JDG Legal Source Registry — ETAP 02")
    sub = parser.add_subparsers(dest="command", required=True)
    build = sub.add_parser("build")
    build.set_defaults(fn="build")
    validate = sub.add_parser("validate")
    validate.add_argument("--publication-gate", action="store_true")
    validate.set_defaults(fn="validate")
    diff = sub.add_parser("diff")
    diff.add_argument("--before", required=True)
    diff.add_argument("--after", required=True)
    diff.set_defaults(fn="diff")
    review = sub.add_parser("review")
    review.add_argument("--record-id", required=True)
    review.add_argument("--reviewer", required=True)
    review.add_argument("--decision", required=True, choices=["APPROVE", "REJECT", "REQUEST_CHANGES"])
    review.add_argument("--reviewed-hash", required=True)
    review.add_argument("--comment", default="")
    review.add_argument("--official-snapshot-hash", default=None)
    review.set_defaults(fn="review")
    args = parser.parse_args()

    if args.fn == "build":
        registry = build_registry()
        write_registry(registry)
        result = validate_registry(registry)
        write_report(registry, result)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return
    if args.fn == "validate":
        if not REGISTRY_PATH.exists():
            print("FAIL: registry does not exist", file=sys.stderr)
            raise SystemExit(1)
        registry = json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))
        result = validate_registry(registry, publication_gate=args.publication_gate)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        raise SystemExit(0 if result["status"] == "PASS" else 1)
    if args.fn == "review":
        if not REGISTRY_PATH.exists():
            print("FAIL: registry does not exist", file=sys.stderr)
            raise SystemExit(1)
        current = json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))
        try:
            append_review(current, args.record_id, args.reviewer, args.decision,
                          args.reviewed_hash, args.comment, args.official_snapshot_hash)
        except (KeyError, ValueError) as exc:
            print(f"FAIL: {exc}", file=sys.stderr)
            raise SystemExit(1)
        write_registry(current)
        print(json.dumps({"status": "RECORDED", "record_id": args.record_id}, ensure_ascii=False))
        return
    before = json.loads(Path(args.before).read_text(encoding="utf-8"))
    after = json.loads(Path(args.after).read_text(encoding="utf-8"))
    print(json.dumps(diff_registries(before, after), ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
