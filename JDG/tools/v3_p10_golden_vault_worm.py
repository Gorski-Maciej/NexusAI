#!/usr/bin/env python3
"""
NexusAI JDG — V3-P10-I01 GOLDEN VAULT WORM
============================================
Audyt „skarbca złotych werdyktów": czy golden set jest przechowywany w trybie
niemodyfikowalnym (append-only, WORM) z łańcuchem hashy i wersjami? Zasada
V2/F3: przeszłość jest nietykalna — każda zmiana historycznego werdyktu musi
być nową wersją, nigdy nadpisaniem.

Analizuje: bundles/golden_verdicts.json (schemat, liczba, per-record hash,
bundle_version, recorded_at) oraz obecność artefaktu łańcucha/archiwum.

Usage:
  python tools/v3_p10_golden_vault_worm.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
GOLDEN = BUNDLES / "golden_verdicts.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    verdicts, schema, versions = {}, None, set()
    oldest = newest = None
    if GOLDEN.exists():
        d = json.loads(GOLDEN.read_text(encoding="utf-8"))
        verdicts = d.get("verdicts", {})
        recs = list(verdicts.values())
        schema = d.get("schema_version")
        hashes = [r.get("verdict_hash") for r in recs]
        recorded = [r.get("recorded_at") for r in recs]
        versions = {r.get("bundle_version") for r in recs}
        oldest = min(recorded) if recorded else None
        newest = max(recorded) if recorded else None

        # łańcuch hash-y (Merkle-ish): każdy rekord ma verdict_hash
        chain_ok = all(h for h in hashes) and len(hashes) == len(recs) and len(verdicts) > 0
        multi_version = len(versions) >= 2

        # archiwum WORM: artefakty append-only (NIE własne bundle analityczne v3_p10_*)
        # i NIE inne ledger-e (campaign/deployments to nie golden vault)
        vault_candidates = sorted(
            p.name for p in BUNDLES.glob("*.json")
            if not p.name.startswith("v3_p10_")
            and any(k in p.name for k in ("golden_vault", "oracle_vault",
                                          "golden_archive", "vault_worm", "worm_vault")))
        append_only = bool(vault_candidates)

        checks.append({"name": "set_exists", "status": "OK" if verdicts else "FAIL",
                       "detail": f"golden_verdicts.json: {len(verdicts)} werdyktów, schema v{schema}"})
        checks.append({"name": "per_record_hash", "status": "OK" if chain_ok else "FAIL",
                       "detail": f"każdy rekord ma verdict_hash={chain_ok}"})
        checks.append({"name": "multi_version", "status": "OK" if multi_version else "FAIL",
                       "detail": f"bundle_version w setcie: {len(versions)} unikalnych"})
        checks.append({"name": "append_only_vault", "status": "OK" if append_only else "FAIL",
                       "detail": f"artefakt WORM/append-only: {vault_candidates}"})

        if not append_only:
            findings.append({
                "id": "V3-P10-L01", "severity": "P1",
                "evidence": f"golden_verdicts.json to pojedynczy mutowalny plik ({len(verdicts)} "
                            f"rekordów, {len(versions)} wersji bundle) — brak artefaktu WORM "
                            "(append-only vault / hash chain / archiwum wersji)",
                "fix": "I01: Golden Vault WORM — osobny append-only rejestr wersji setu "
                       "(snapshot + hash chain + seal), golden_verdicts.json tylko do odczytu"})
    else:
        checks = [{"name": "set_exists", "status": "FAIL",
                   "detail": "bundles/golden_verdicts.json nie istnieje"}]
        findings = [{"id": "V3-P10-L01", "severity": "P1",
                     "evidence": "brak pliku golden_verdicts.json",
                     "fix": "I01: utworzyć golden set i vault append-only"}]

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P10-I01",
        "name": "Golden Vault WORM — nietykalność golden set",
        "generated_at": now(),
        "gate": gate,
        "metrics": {
            "verdict_count": len(verdicts),
            "schema_version": schema,
            "multi_version": len(versions) >= 2,
            "append_only_vault": any(
                c["name"] == "append_only_vault" and c["status"] == "OK" for c in checks),
            "oldest_recorded_at": oldest, "newest_recorded_at": newest,
        },
        "checks": checks,
        "findings": findings,
        "contract": {
            "binding": "P10 (golden oracle) → P38 (deploy), P43 (WORM/DR), P44 (certyfikacja)",
            "rule": "golden set jest niemodyfikowalny; zmiana = nowa wersja z nowym hashem i "
                    "uzasadnieniem (V2/F3)"},
    }
    (BUNDLES / "v3_p10_golden_vault_worm.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P10-I01] gate={gate} verdicts={len(verdicts)} "
          f"vault={bundle['metrics']['append_only_vault']}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
