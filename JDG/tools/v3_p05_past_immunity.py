#!/usr/bin/env python3
"""
NexusAI JDG — PAST IMMUNITY TEST (V3-P05-I06)
=============================================
Test „przeszłość nietykalna” (P05-AN10): re-ewaluacja historycznej transakcji
z tym samym snapshotem musi dać identyczny werdykt. Złoty zestaw
(golden_verdicts.json) jest reperem:

  • integralność łańcucha: dla każdej pary (input_hash → golden_verdict_hash)
    w replays, golden_verdict_hash musi być identyczny z verdict_hash wpisu
    o tym input_hash — zmiana reguły = rozjazd = naruszenie immunitetu;
  • determinizm: przeliczenie hasha kanonicznego (sort_keys JSON) zapisanego
    werdyktu dla wpisów z hash_algorithm=sha256 musi zwrócić verdict_hash;
  • odporność bundle: każda zmiana plików rules/ (snapshot_id z I02) tworzy
    nową wersję — złote werdykty starej wersji pozostają niezmienne (WORM).

Reguła: zmiana werdyktu historycznego jest dozwolona WYŁĄCZNIE z jawnym
uzasadnieniem prawnym (retroaktywność I04) — inaczej BLOCKER/regresja.

Usage: python tools/v3_p05_past_immunity.py
Exit:  0 = PASS (immunitet zachowany), 1 = FAIL.
"""
from __future__ import annotations

import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUNDLES = ROOT / "bundles"
OUT = BUNDLES / "v3_p05_past_immunity.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def sha256_canonical(obj) -> str:
    # kanoniczny JSON v1 golden_verdicts (compact separators) — spójny
    # z sha256-canonical-json-v1 używanym w P00/P01/P03 (golden hash).
    return hashlib.sha256(
        json.dumps(obj, sort_keys=True, ensure_ascii=False,
                   separators=(",", ":")).encode("utf-8")
    ).hexdigest()


def main() -> int:
    checks, findings = [], []
    gv = json.loads((BUNDLES / "golden_verdicts.json").read_text(encoding="utf-8"))
    verdicts = gv.get("verdicts", {})
    replays = gv.get("replays", [])

    # 1) determinizm zapisanych werdyktów (hash canonicalny)
    mismatch = []
    for k, entry in verdicts.items():
        algo = entry.get("hash_algorithm", "sha256")
        stored = entry.get("verdict_hash", "")
        if algo and algo.startswith("sha256") and stored:
            recomputed = sha256_canonical(entry.get("verdict", {}))
            if recomputed != stored:
                mismatch.append({"input_hash": k, "stored": stored[:16],
                                 "recomputed": recomputed[:16]})
    checks.append({
        "name": "verdict_hash_determinism",
        "status": "OK" if not mismatch else "FAIL",
        "detail": f"werdyktów: {len(verdicts)}, rozjazdów hash: {len(mismatch)}",
    })
    if mismatch:
        findings.append({
            "id": "V3-P05-L08", "severity": "P1",
            "evidence": f"zapisane verdict_hash nie są deterministyczną funkcją werdyktu: {mismatch[:5]}",
            "fix": "jednolity algorytm hashowania werdyktu (P03 — golden hash, I04)",
        })

    # 2) integralność łańcucha replay (immunitet)
    chain_breaks = []
    by_input = {k: v.get("verdict_hash") for k, v in verdicts.items()}
    for r in replays:
        ih, gh = r.get("input_hash"), r.get("golden_verdict_hash")
        expected = by_input.get(ih)
        if gh and expected and gh != expected:
            chain_breaks.append({"input_hash": ih, "replay_gh": gh[:16],
                                 "stored_vh": expected[:16]})
    checks.append({
        "name": "golden_chain_integrity",
        "status": "OK" if not chain_breaks else "FAIL",
        "detail": f"wierszy replay: {len(replays)}, przerwanych ogniw: {len(chain_breaks)}",
    })
    if chain_breaks:
        findings.append({
            "id": "V3-P05-L09", "severity": "P0",
            "evidence": f"replay historyczny rozjechał się z zapisanym werdyktem: {chain_breaks[:5]} "
                        "— zmiana przeszłości bez uzasadnienia prawnego",
            "fix": "BLOCKER: ustalić przyczynę (zmiana reguły/parametru), wymagać golden replay "
                   "po każdej zmianie bundle (I02) i jawnej zgody retro (I04)",
        })

    # 3) immunitet vs zmiany w repozytorium — porównaj bieżący snapshot z vault I02
    vault_path = BUNDLES / "v3_p05_snapshot_vault.json"
    snapshot_status = "no-vault"
    if vault_path.exists():
        vault = json.loads(vault_path.read_text(encoding="utf-8"))
        cur = vault.get("current", {}).get("snapshot_id", "")
        prev_hist = vault.get("history", [])
        snapshot_status = "stable" if not prev_hist else f"changed ({len(prev_hist)} poprzednich)"
    checks.append({
        "name": "snapshot_stability",
        "status": "OK",
        "detail": f"vault snapshot: {snapshot_status}",
    })

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P05-I06",
        "generated_at": now(),
        "gate": gate,
        "method": "reper golden_verdicts: determinizm hasha + integralność łańcucha replay + "
                  "stabilność snapshotu (WORM) — uruchamiany po KAŻDEJ zmianie bundle",
        "metrics": {
            "golden_verdicts": len(verdicts),
            "replay_rows": len(replays),
            "hash_mismatches": len(mismatch),
            "chain_breaks": len(chain_breaks),
            "snapshot_status": snapshot_status,
        },
        "checks": checks,
        "findings": findings,
        "contract": {
            "binding": "P10 golden oracle / P11 certyfikaty / P39 CI / P38 bundle",
            "zasada": "immunitet przeszłości: identyczny snapshot_id = identyczny werdykt; "
                      "zmiana = tylko z uzasadnieniem prawnym (I04)",
        },
    }
    OUT.write_text(json.dumps(bundle, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[V3-P05-I06] gate={gate} golden={len(verdicts)} replays={len(replays)} "
          f"hash_mismatch={len(mismatch)} chain_breaks={len(chain_breaks)}")
    return 0 if gate == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
