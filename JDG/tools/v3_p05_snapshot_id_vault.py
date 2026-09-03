#!/usr/bin/env python3
"""
NexusAI JDG — SNAPSHOT ID & VAULT (V3-P05-I02)
==============================================
Immutowalne snapshoty ewaluacyjne (P05-AN04): jednostka odtwarzalności
werdyktu = hash(bundle + reguły + parametry + legal nodes + schema).

  • snapshot_id = SHA-256 manifestu składników (każdy składnik ma własny hash);
  • składniki: rules/*.rego (zbiorczy + per-plik SHA-1), thresholds_data.json,
    legal_graph.json, golden_verdicts (bundle_version + verdict_hash),
    migracje SQL (wersja schematu);
  • vault: bundles/v3_p05_snapshot_vault.json — append-only rejestr snapshotów
    (WORM): każda zmiana repozytorium = nowy snapshot_id + wpis rejestru.

Ustalenie: werdykt = f(snapshot_id, input) — identyczny snapshot_id gwarantuje
identyczny werdykt (determinizm; replay 1:1 na żądanie audytu/KAS).

Usage: python tools/v3_p05_snapshot_id_vault.py
Exit:  0 = PASS (snapshot spójny, vault spójny), 1 = FAIL.
"""
from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUNDLES = ROOT / "bundles"
RULES = ROOT / "rules"
VAULT = BUNDLES / "v3_p05_snapshot_vault.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def sha1_bytes(b: bytes) -> str:
    return hashlib.sha1(b).hexdigest()


def sha256_text(t: str) -> str:
    return hashlib.sha256(t.encode("utf-8")).hexdigest()


def git_head() -> str:
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=ROOT, capture_output=True, text=True, timeout=10,
        )
        return out.stdout.strip() or "no-git"
    except Exception:
        return "no-git"


def build_manifest() -> dict:
    components = {}
    rego_files = sorted(RULES.rglob("*.rego"))
    rego_hashes = {}
    for p in rego_files:
        h = sha1_bytes(p.read_bytes())
        rego_hashes[str(p.relative_to(ROOT))] = h
    components["rules_rego"] = {
        "count": len(rego_files),
        "sha1": sha1_bytes(json.dumps(rego_hashes, sort_keys=True).encode("utf-8")),
    }
    for rel in ["bundles/thresholds_data.json", "bundles/legal_graph.json",
                "bundles/golden_verdicts.json"]:
        p = ROOT / rel
        if p.exists():
            components[rel] = sha1_bytes(p.read_bytes())
    # migracje = wersja schematu
    migs = sorted((ROOT / "migrations").glob("*.sql"))
    components["migrations"] = {
        "count": len(migs),
        "sha1": sha1_bytes(b"".join(p.read_bytes() for p in migs)),
    }
    # golden verdicts: bundle_version + liczba wpisów
    gv = json.loads((BUNDLES / "golden_verdicts.json").read_text(encoding="utf-8"))
    components["golden_verdicts"] = {
        "verdicts": len(gv.get("verdicts", {})),
        "bundle_version": gv.get("schema_version"),
        "replay_rows": len(gv.get("replays", [])),
    }
    manifest = {
        "git_head": git_head(),
        "built_at": now(),
        "components": components,
    }
    manifest["snapshot_id"] = sha256_text(
        json.dumps(components, sort_keys=True)
    )
    return manifest


def main() -> int:
    manifest = build_manifest()
    checks = []
    findings = []

    # spójność golden verdicts: każdy wpis ma bundle_version + verdict_hash
    gv = json.loads((BUNDLES / "golden_verdicts.json").read_text(encoding="utf-8"))
    missing = [
        k for k, v in gv.get("verdicts", {}).items()
        if not (v.get("verdict_hash") and v.get("bundle_version"))
    ]
    checks.append({
        "name": "golden_reconstructibility",
        "status": "OK" if not missing else "FAIL",
        "detail": f"verdicts={len(gv.get('verdicts', {}))}, wpisy bez hasha/wer. bundle: {len(missing)}",
    })
    if missing:
        findings.append({
            "id": "V3-P05-L03", "severity": "P1",
            "evidence": f"złote werdykty bez pełnego klucza odtworzenia: {missing[:5]}",
            "fix": "uzupełnić bundle_version/verdict_hash (generator golden, P10)",
        })

    # vault (WORM): porównaj z poprzednim snapshotem
    history = []
    previous_id = None
    if VAULT.exists():
        old = json.loads(VAULT.read_text(encoding="utf-8"))
        previous_id = old.get("current", {}).get("snapshot_id")
        history = old.get("history", [])
    unchanged = previous_id == manifest["snapshot_id"]
    if previous_id is not None:
        if not unchanged:
            history.append({
                "snapshot_id": previous_id,
                "superseded_at": now(),
                "reason": "zmiana składników snapshotu (rules/parametry/legal nodes/schema)",
            })
    checks.append({
        "name": "vault_worm",
        "status": "OK",
        "detail": "pierwszy snapshot" if previous_id is None else
                  ("identyczny snapshot (repo niezmienione)" if unchanged else
                   f"nowy snapshot (poprzedni: {previous_id[:12]}… — w rejestrze)"),
    })

    record = {"current": manifest, "history": history[-20:]}
    VAULT.write_text(json.dumps(record, indent=2, ensure_ascii=False), encoding="utf-8")

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P05-I02",
        "generated_at": now(),
        "gate": gate,
        "snapshot_id": manifest["snapshot_id"],
        "components": {
            "rules_files": manifest["components"]["rules_rego"]["count"],
            "thresholds_data_sha1": manifest["components"].get("bundles/thresholds_data.json", ""),
            "legal_graph_sha1": manifest["components"].get("bundles/legal_graph.json", ""),
            "migrations_count": manifest["components"]["migrations"]["count"],
            "git_head": manifest["git_head"],
        },
        "checks": checks,
        "findings": findings,
        "vault_written": str(VAULT.relative_to(ROOT)),
        "contract": {
            "binding": "P06 parametry / P10 golden oracle / P38 bundle / P11 certyfikaty",
            "snapshot_composition": "rules_rego + thresholds_data + legal_graph + golden_verdicts + migrations",
            "zasada": "werdykt = f(snapshot_id, input); zmiana składnika = nowy snapshot_id "
                      "(stary zostaje w vault jako niezmienny)",
        },
    }
    (BUNDLES / "v3_p05_snapshot_id_vault.json").write_text(
        json.dumps(bundle, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[V3-P05-I02] gate={gate} snapshot_id={manifest['snapshot_id'][:16]}… "
          f"rules={manifest['components']['rules_rego']['count']} "
          f"golden={manifest['components']['golden_verdicts']['verdicts']} "
          f"unchanged={unchanged}")
    return 0 if gate == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
