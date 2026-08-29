#!/usr/bin/env python3
"""
NexusAI JDG — DIFFERENTIAL EVALUATION (V2 F3 §4.4, PROMPT 21 CONTROL PLANE)
============================================================================
Porównanie werdyktów z ≥ 2 węzłów OPA (repliki) dla tego samego inputu.
Determinizm silnika (ADR-001) wymaga, aby hash kanoniczny werdyktu był
IDENTYCZNY na wszystkich węzłach przy tej samej wersji bundle.

  • compare  — porównaj werdykt lokalny z wynikami N węzłów (JSON lub plik),
    zwróć divergence (różnica hashów) z wyjaśnieniem pierwszego pola różnicy,
  • check    — bramka CI: FAIL gdy jakikolwiek węzeł odbiega od większości
    (quorum ≥ 2/3) albo brak quorum,
  • record   — zapis sesji różnicowej do bundles/differential_sessions.json
    (append-only, WORM-ready).

Fail-closed: brak danych z węzła = węzeł nieuczestniczący (nie zdrowy).
Zgodność: WIZJA_OPA_ENTERPRISE_V2.md §4.4, INV-030 (provenance bundle_version).

Usage:
  python differential_evaluation.py compare --verdict verdict.json --nodes node-a.json node-b.json
  python differential_evaluation.py check --verdict verdict.json --nodes node-a.json node-b.json --bundle jdg-bundle-v9.1.0
  python differential_evaluation.py record --session diff-001
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

JDG_ROOT = Path(__file__).resolve().parent.parent
SESSIONS_PATH = JDG_ROOT / "bundles" / "differential_sessions.json"

MIN_NODES = 2
QUORUM = 2 / 3


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def canonical_hash(value: Any) -> str:
    payload = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def _load_verdict(source: str) -> dict:
    """Załaduj werdykt z pliku JSON albo inline JSON."""
    path = Path(source)
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    return json.loads(source)


def _load_sessions() -> dict:
    if SESSIONS_PATH.exists():
        return json.loads(SESSIONS_PATH.read_text(encoding="utf-8"))
    return {"schema_version": "1.0.0", "sessions": []}


def _save_sessions(data: dict) -> None:
    SESSIONS_PATH.parent.mkdir(parents=True, exist_ok=True)
    SESSIONS_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


def compare(verdict: dict, node_verdicts: list[tuple[str, dict]]) -> dict:
    """Porównaj werdykt referencyjny z werdyktami węzłów."""
    ref_hash = canonical_hash(verdict)
    rows = []
    for node, v in node_verdicts:
        h = canonical_hash(v)
        rows.append({
            "node": node,
            "hash": h,
            "match": h == ref_hash,
            "bundle_version": v.get("_provenance_tree", {}).get("bundle_version")
            if isinstance(v.get("_provenance_tree"), dict) else None,
            "first_diff_field": _first_diff(verdict, v),
        })
    matched = sum(1 for r in rows if r["match"])
    total = len(rows)
    agreement = matched / total if total else 0.0
    return {
        "reference_hash": ref_hash,
        "nodes": rows,
        "nodes_total": total,
        "nodes_matched": matched,
        "agreement_pct": round(agreement * 100, 2),
        "quorum_ok": total >= MIN_NODES and agreement >= QUORUM,
        "deterministic": total >= MIN_NODES and matched == total,
        "fail_closed": "Węzły bez danych = nieuczestniczące; quorum < 2/3 = brak decyzji",
    }


def _first_diff(a: dict, b: dict) -> str | None:
    """Pierwsze pole (kolejność kanoniczna), które różni werdykty."""
    keys = sorted(set(a) | set(b))
    for key in keys:
        if a.get(key) != b.get(key):
            return key
    return None


def cmd_compare(args) -> None:
    verdict = _load_verdict(args.verdict)
    node_verdicts = [(name, _load_verdict(path)) for name, path in zip(args.node_names, args.nodes)]
    result = compare(verdict, node_verdicts)
    print(json.dumps(result, indent=2, ensure_ascii=False))
    if not result["quorum_ok"]:
        sys.exit(2)


def cmd_check(args) -> None:
    """Bramka CI — wymaga determinizmu (wszystkie węzły = hash referencyjny)."""
    verdict = _load_verdict(args.verdict)
    node_verdicts = [(name, _load_verdict(path)) for name, path in zip(args.node_names, args.nodes)]
    result = compare(verdict, node_verdicts)
    issues = []
    for row in result["nodes"]:
        if not row["match"]:
            issues.append(f"{row['node']}: hash {row['hash'][:16]} ≠ ref "
                          f"(pierwsza różnica: {row['first_diff_field']})")
        if row["bundle_version"] and args.bundle and row["bundle_version"] != args.bundle:
            issues.append(f"{row['node']}: bundle_version {row['bundle_version']} ≠ {args.bundle}")
    if issues:
        print(f"❌ DIFFERENTIAL CHECK — divergence: {len(issues)} problemów")
        for i in issues:
            print(f"   • {i}")
        sys.exit(1)
    print(f"✅ DIFFERENTIAL CHECK: {result['nodes_total']} węzłów, determinizm potwierdzony "
          f"(agreement {result['agreement_pct']}%, quorum OK)")
    _record(args.session or "auto", result)


def _record(session: str, result: dict) -> None:
    data = _load_sessions()
    data["sessions"].append({
        "session_id": session,
        "at": now(),
        "result": {k: v for k, v in result.items() if k != "nodes"},
        "nodes": [{"node": r["node"], "hash": r["hash"], "match": r["match"]}
                  for r in result["nodes"]],
    })
    _save_sessions(data)


def cmd_record(args) -> None:
    verdict = _load_verdict(args.verdict)
    node_verdicts = [(name, _load_verdict(path)) for name, path in zip(args.node_names, args.nodes)]
    result = compare(verdict, node_verdicts)
    _record(args.session, result)
    print(f"✅ Sesja różnicowa zapisana: {args.session} "
          f"(agreement {result['agreement_pct']}%, determinizm {result['deterministic']})")


def main() -> None:
    p = argparse.ArgumentParser(description="Differential Evaluation — V2 F3 §4.4")
    sub = p.add_subparsers(dest="cmd", required=True)

    def _node_args(sp) -> None:
        sp.add_argument("--verdict", required=True, help="werdykt referencyjny (JSON lub plik)")
        sp.add_argument("--nodes", nargs="+", required=True, help="werdykty z węzłów (pliki)")
        sp.add_argument("--node-names", nargs="+", default=None,
                        help="nazwy węzłów (domyślnie node-1..N)")

    c = sub.add_parser("compare"); _node_args(c); c.set_defaults(fn=cmd_compare)
    k = sub.add_parser("check"); _node_args(k)
    k.add_argument("--bundle", default=None); k.add_argument("--session", default=None)
    k.set_defaults(fn=cmd_check)
    r = sub.add_parser("record"); _node_args(r)
    r.add_argument("--session", required=True); r.set_defaults(fn=cmd_record)

    args = p.parse_args()
    if args.node_names is None:
        args.node_names = [f"node-{i}" for i in range(1, len(args.nodes) + 1)]
    if len(args.node_names) != len(args.nodes):
        sys.exit("❌ --node-names musi odpowiadać liczbie --nodes")
    args.fn(args)


if __name__ == "__main__":
    main()
