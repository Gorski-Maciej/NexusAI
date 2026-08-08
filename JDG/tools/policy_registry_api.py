#!/usr/bin/env python3
"""
NexusAI JDG — POLICY REGISTRY API (P01 Fundament — Sekcja 5, V1 §2.1, L1)
==========================================================================
Realny katalog reguł (analog endpointu `/v1/rules` control plane) budowany z
rzeczywistej zawartości `rules/` — a nie z deklaracji. Każdy wpis rejestru
zawiera: rule_id, plik, pakiet, legal_basis, priorytet, routing, status
(ACTIVE/SHADOW/… wg rule_registry.json), wersję semver, owner/domain
(wg manifestu cyklu życia), checksum SHA-256 pliku oraz datę obowiązywania.

Integracja: statusy i wersje pobierane z bundles/rule_registry.json
(rule_lifecycle_manager.py v2) — JEDEN rejestr, jedna prawda (V1 §1).

Usage:
  python policy_registry_api.py build                 # pełny skan → bundles/policy_registry.json
  python policy_registry_api.py search --query vat --domain vat
  python policy_registry_api.py get jdg.vat.a113.r1
  python policy_registry_api.py stats
  python policy_registry_api.py export --format json
"""

import argparse
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"
REGISTRY_PATH = JDG_ROOT / "bundles" / "rule_registry.json"
OUT_PATH = JDG_ROOT / "bundles" / "policy_registry.json"

RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
LEGAL_BASIS_RE = re.compile(r'"_?legal_basis"\s*:\s*"([^"]+)"')
PRIORITY_RE = re.compile(r'"priority"\s*:\s*(\d+)')
ROUTING_RE = re.compile(r'"routing"\s*:\s*"([^"]+)"')
MATCHED_RE = re.compile(r'"matched"\s*:\s*(true|false)')


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    h.update(path.read_bytes())
    return h.hexdigest()


def package_of(filepath: Path) -> str:
    """Pakiet Rego z pierwszych linii pliku (package ...)."""
    try:
        for line in filepath.read_text(encoding="utf-8", errors="ignore").splitlines()[:20]:
            m = re.match(r"^\s*package\s+([\w.]+)", line)
            if m:
                return m.group(1)
    except Exception:  # noqa: BLE001
        pass
    return "unknown"


def load_lifecycle_statuses() -> dict:
    statuses = defaultdict(list)
    versions = defaultdict(list)
    if REGISTRY_PATH.exists():
        registry = json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))
        for rule_id, entry in registry.items():
            for v in entry.get("versions", []):
                statuses[rule_id].append(v.get("status", "ACTIVE"))
                versions[rule_id].append(v.get("version"))
    return {"statuses": dict(statuses), "versions": dict(versions)}


def scan_all() -> list[dict]:
    lifecycle = load_lifecycle_statuses()
    registry = []
    for path in sorted(RULES_DIR.rglob("*.rego")):
        rel = str(path.relative_to(JDG_ROOT))
        content = path.read_text(encoding="utf-8", errors="ignore")
        for m in RULE_ID_RE.finditer(content):
            ctx = content[m.start():m.start() + 4000]
            lb = LEGAL_BASIS_RE.search(ctx)
            pr = PRIORITY_RE.search(ctx)
            rt = ROUTING_RE.search(ctx)
            mt = MATCHED_RE.search(ctx)
            rule_id = m.group(1)
            statuses = lifecycle["statuses"].get(rule_id)
            entry = {
                "rule_id": rule_id,
                "file": rel,
                "package": package_of(path),
                "legal_basis": lb.group(1) if lb else "",
                "priority": int(pr.group(1)) if pr else 0,
                "routing": rt.group(1) if rt else "",
                "matched": mt.group(1) == "true" if mt else None,
                "status": statuses[-1] if statuses else "ACTIVE",
                "version": lifecycle["versions"].get(rule_id, [None])[-1],
                "checksum_sha256": sha256(path),
            }
            registry.append(entry)
    return registry


def build(args) -> None:
    entries = scan_all()
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "api": "policy-registry/v1",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "total_rules": len(entries),
        "rules": entries,
    }
    OUT_PATH.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"✅ Policy Registry: {len(entries)} reguł zapisano w {OUT_PATH.relative_to(JDG_ROOT)}")
    print(f"   (analog GET /v1/rules — katalog, wersje, metadane, owner, status)")


def _load():
    if not OUT_PATH.exists():
        build(argparse.Namespace())
    return json.loads(OUT_PATH.read_text(encoding="utf-8"))


def search(args) -> None:
    payload = _load()
    q = (args.query or "").lower()
    results = []
    for r in payload["rules"]:
        hay = json.dumps(r, ensure_ascii=False).lower()
        if args.domain and r.get("package", "").lower().find(args.domain.lower()) < 0:
            continue
        if q and q not in hay:
            continue
        results.append(r)
    print(json.dumps({"query": args.query, "results_count": len(results),
                      "results": results[: args.limit]}, indent=2, ensure_ascii=False))


def get_rule(args) -> None:
    payload = _load()
    for r in payload["rules"]:
        if r["rule_id"] == args.rule_id:
            print(json.dumps(r, indent=2, ensure_ascii=False))
            return
    sys.exit(f"❌ Brak reguły {args.rule_id} w rejestrze")


def stats(args) -> None:
    payload = _load()
    rules = payload["rules"]
    by_status = Counter(r.get("status", "ACTIVE") for r in rules)
    by_package = Counter(r.get("package", "?") for r in rules)
    with_legal_basis = sum(1 for r in rules if r.get("legal_basis"))
    print(json.dumps({
        "total_rules": len(rules),
        "by_status": dict(by_status),
        "packages": len(by_package),
        "top_packages": dict(by_package.most_common(10)),
        "rules_with_legal_basis": with_legal_basis,
        "rules_without_legal_basis": len(rules) - with_legal_basis,
        "rv_metric_percent": round(with_legal_basis / len(rules) * 100, 2) if rules else 0,
    }, indent=2, ensure_ascii=False))


def export(args) -> None:
    payload = _load()
    if args.format == "json":
        print(json.dumps(payload, indent=2, ensure_ascii=False))
    else:
        sys.exit(f"❌ Format {args.format} nieobsługiwany (json)")


def main() -> None:
    p = argparse.ArgumentParser(description="Policy Registry API — katalog reguł (V1 §2.1)")
    sub = p.add_subparsers(dest="cmd", required=True)

    b = sub.add_parser("build"); b.set_defaults(fn=build)
    s = sub.add_parser("search")
    s.add_argument("--query", default="")
    s.add_argument("--domain", default=None)
    s.add_argument("--limit", type=int, default=50)
    s.set_defaults(fn=search)
    g = sub.add_parser("get"); g.add_argument("rule_id"); g.set_defaults(fn=get_rule)
    st = sub.add_parser("stats"); st.set_defaults(fn=stats)
    e = sub.add_parser("export"); e.add_argument("--format", default="json"); e.set_defaults(fn=export)

    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
