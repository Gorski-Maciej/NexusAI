#!/usr/bin/env python3
"""
NexusAI JDG — V3 CANONICAL SNAPSHOT ENGINE (P00-I01)
=====================================================
Zamrożenie baseline liczbowego modułu JDG na moment P00: hash plików,
liczby rule_id per katalog, pakiety, testy, narzędzia, migracje, bundle.
Snapshot ma wersję i datę — kolejne części mogą robić re-ewaluację
różnicową (diff względem baseline) zamiast zgadywać stan.

Usage:
  python v3_snapshot_engine.py              # skan + podsumowanie
  python v3_snapshot_engine.py --json       # JSON na stdout
  python v3_snapshot_engine.py --write      # zapis bundles/v3_canonical_snapshot.json
  python v3_snapshot_engine.py --diff OLD NEW  # różnicowa re-ewaluacja snapshotów
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
JDG_ROOT = Path(__file__).resolve().parents[1]
RULES_DIR = JDG_ROOT / "rules"
TESTS_DIR = JDG_ROOT / "tests"
TOOLS_DIR = JDG_ROOT / "tools"
BUNDLES_DIR = JDG_ROOT / "bundles"
MIGRATIONS_DIR = JDG_ROOT / "migrations"
DOCS_DIR = JDG_ROOT / "docs"
POLICIES_ROOT = REPO_ROOT / "policies"
OUT_JSON = BUNDLES_DIR / "v3_canonical_snapshot.json"

RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
PACKAGE_RE = re.compile(r"^\s*package\s+([A-Za-z0-9_.]+)", re.MULTILINE)
STUB_RE = re.compile(r":=\s*\{\s*true\s*\}", re.IGNORECASE)


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    h.update(path.read_bytes())
    return h.hexdigest()


def count_rule_ids(path: Path) -> tuple[int, int]:
    """Zwraca (liczba wystąpień rule_id, liczba unikalnych)."""
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return 0, 0
    ids = RULE_ID_RE.findall(text)
    return len(ids), len(set(ids))


def package_of(path: Path) -> str:
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return "unknown"
    m = PACKAGE_RE.search(text)
    return m.group(1) if m else "unknown"


def scan_dir(root: Path, suffix: str) -> list[dict]:
    out = []
    if not root.exists():
        return out
    for path in sorted(root.rglob(f"*{suffix}")):
        if "__pycache__" in path.parts or ".git" in path.parts:
            continue
        rel = path.relative_to(JDG_ROOT).as_posix()
        out.append({
            "path": rel,
            "bytes": path.stat().st_size,
            "sha256": sha256(path),
        })
    return out


def build_snapshot() -> dict:
    rego_files = scan_dir(RULES_DIR, ".rego")
    per_dir: dict[str, dict] = {}
    rule_total, rule_unique_total = 0, 0
    packages: set[str] = set()
    stub_count = 0
    for f in rego_files:
        path = JDG_ROOT / f["path"]
        d = path.parent.relative_to(JDG_ROOT).as_posix()
        occ, uniq = count_rule_ids(path)
        rule_total += occ
        rule_unique_total += uniq
        pkg = package_of(path)
        if pkg != "unknown":
            packages.add(pkg)
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
            stub_count += len(STUB_RE.findall(text))
        except Exception:
            pass
        entry = per_dir.setdefault(d, {"files": 0, "rule_id_occurrences": 0, "rule_id_unique": 0})
        entry["files"] += 1
        entry["rule_id_occurrences"] += occ
        entry["rule_id_unique"] += uniq

    pytest_files = scan_dir(TESTS_DIR, ".py")
    rego_tests = [p for p in scan_dir(TESTS_DIR, ".rego")]
    tools_files = [p for p in scan_dir(TOOLS_DIR, ".py")]
    bundles_files = [p for p in scan_dir(BUNDLES_DIR, ".json")]
    migrations_files = [p for p in scan_dir(MIGRATIONS_DIR, ".sql")]
    docs_files = [p for p in scan_dir(DOCS_DIR, ".md")]
    policies_files = scan_dir_policies()

    return {
        "schema_version": "1.0.0",
        "snapshot_version": "P00-BASELINE-001",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "generator": "JDG/tools/v3_snapshot_engine.py",
        "scope": "JDG/rules + JDG/tests + JDG/tools + JDG/bundles + JDG/migrations + JDG/docs + policies/",
        "counts": {
            "rego_files": len(rego_files),
            "rego_rule_id_occurrences": rule_total,
            "rego_rule_id_unique": rule_unique_total,
            "rego_packages": len(packages),
            "rego_stub_candidates": stub_count,
            "pytest_files": len(pytest_files),
            "native_rego_tests": len(rego_tests),
            "tools_py": len(tools_files),
            "bundles_json": len(bundles_files),
            "migrations_sql": len(migrations_files),
            "docs_md": len(docs_files),
            "policies_rego": len(policies_files),
        },
        "per_directory": {k: v for k, v in sorted(per_dir.items())},
        "packages_sample": sorted(packages)[:200],
        "policies_rego_files": [f["path"] for f in policies_files][:500],
        "file_hashes": {f["path"]: f["sha256"] for f in rego_files},
        "tests_index": [f["path"] for f in pytest_files],
        "tools_index": [f["path"] for f in tools_files],
        "bundles_index": [f["path"] for f in bundles_files],
        "migrations_index": [f["path"] for f in migrations_files],
    }


def scan_dir_policies() -> list[dict]:
    out = []
    if not POLICIES_ROOT.exists():
        return out
    for path in sorted(POLICIES_ROOT.rglob("*.rego")):
        out.append({
            "path": path.relative_to(REPO_ROOT).as_posix(),
            "bytes": path.stat().st_size,
            "sha256": sha256(path),
        })
    return out


def diff_snapshots(old: dict, new: dict) -> dict:
    o, n = old["counts"], new["counts"]
    changes = {}
    for k in sorted(set(o) | set(n)):
        ov, nv = o.get(k), n.get(k)
        if ov != nv:
            changes[k] = {"old": ov, "new": nv, "delta": (nv - ov) if isinstance(ov, int) and isinstance(nv, int) else None}
    old_hashes = old.get("file_hashes", {})
    new_hashes = new.get("file_hashes", {})
    added = sorted(set(new_hashes) - set(old_hashes))
    removed = sorted(set(old_hashes) - set(new_hashes))
    changed = sorted(p for p in set(old_hashes) & set(new_hashes) if old_hashes[p] != new_hashes[p])
    return {
        "snapshot_old": old.get("snapshot_version"),
        "snapshot_new": new.get("snapshot_version"),
        "count_changes": changes,
        "files_added": added,
        "files_removed": removed,
        "files_changed": changed,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="V3 Canonical Snapshot Engine")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--diff", nargs=2, metavar=("OLD", "NEW"), help="różnicowa re-ewaluacja dwóch snapshotów (ścieżki JSON)")
    args = parser.parse_args()

    if args.diff:
        old = json.loads(Path(args.diff[0]).read_text(encoding="utf-8"))
        new = json.loads(Path(args.diff[1]).read_text(encoding="utf-8"))
        print(json.dumps(diff_snapshots(old, new), ensure_ascii=False, indent=2))
        return 0

    snapshot = build_snapshot()
    if args.write:
        OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
        OUT_JSON.write_text(json.dumps(snapshot, ensure_ascii=False, indent=2), encoding="utf-8")
    if args.json:
        print(json.dumps(snapshot, ensure_ascii=False, indent=2))
    else:
        c = snapshot["counts"]
        print(f"V3 SNAPSHOT {snapshot['snapshot_version']} ({snapshot['generated_at'][:10]}):")
        print(f"  pliki .rego (rules/): {c['rego_files']}")
        print(f"  rule_id (wystąpienia / unikalne): {c['rego_rule_id_occurrences']} / {c['rego_rule_id_unique']}")
        print(f"  pakiety Rego: {c['rego_packages']}")
        print(f"  stuby {{true}} (kandydaci): {c['rego_stub_candidates']}")
        print(f"  pytest: {c['pytest_files']} | natywne Rego: {c['native_rego_tests']} | narzędzia: {c['tools_py']}")
        print(f"  bundles JSON: {c['bundles_json']} | migracje SQL: {c['migrations_sql']} | docs MD: {c['docs_md']}")
        print(f"  policies/ (mirror) .rego: {c['policies_rego']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())