#!/usr/bin/env python3
"""NexusAI JDG — V3-P48 MERGE GATE — bramka CI synchronizacji mirror policies.

Kontrakt bramki (spójny z P45/P46/P47):
  * BLOCK tylko GENUINIE NOWE naruszenia (dryf semantyczny mirror vs canonical,
    sygnatury treściowe, nie numery linii — lekcja P46),
  * istniejące naruszenia = backlog (TRIAGE), nie blokada merge,
  * niezaraportowany dryf semantyczny = BLOCK natychmiast (AP11),
  * --all = pełny audyt backlogu (bez blokady merge).
Usage: python tools/v3_p48_gate.py [--all]
"""
from __future__ import annotations

import argparse
import json

from v3_p48_common import (BUNDLES_DIR, measure_drift, read_json, utcnow_iso,
                           write_json)


def signatures(existing: dict) -> set[str]:
    sigs = set()
    for v in existing.get("violations", []):
        sigs.add(f'{v.get("file")}::{v.get("signature")}')
    return sigs


def collect_violations() -> list[dict]:
    """Dryf semantyczny = naruszenie; sygnatura = SHA-256 z sortowanych nazw
    deklaracji różnicujących się (treściowa, stabilna wobec wstawiania linii)."""
    from v3_p48_common import POLICIES_DIR, RULES_DIR, semantic_signature
    drift = measure_drift()
    violations = []
    rules = {str(p.relative_to(RULES_DIR)): p for p in sorted(RULES_DIR.rglob("*.rego"))}
    pols = {str(p.relative_to(POLICIES_DIR)): p for p in sorted(POLICIES_DIR.rglob("*.rego"))}
    for rel in drift["semantic_diffs"]:
        sig_a = semantic_signature(rules[rel].read_text(encoding="utf-8", errors="replace"))
        sig_b = semantic_signature(pols[rel].read_text(encoding="utf-8", errors="replace"))
        diff_names = "|".join(sorted(sig_a ^ sig_b))[:200]
        import hashlib
        sig = hashlib.sha256(f"{rel}::{diff_names}".encode()).hexdigest()[:16]
        violations.append({"file": rel, "kind": "semantic_drift",
                           "signature": sig,
                           "only_canonical": len(sig_a - sig_b),
                           "only_mirror": len(sig_b - sig_a)})
    for rel in drift["only_rules"]:
        sig = hashlib.sha256(f"{rel}::missing_in_mirror".encode()).hexdigest()[:16]
        violations.append({"file": rel, "kind": "missing_in_mirror", "signature": sig})
    return violations


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--all", action="store_true",
                        help="pełny audyt backlogu dryfu (bez blokady merge)")
    args = parser.parse_args()

    baseline_path = BUNDLES_DIR / "v3_p48_gate_state.json"
    baseline = read_json(baseline_path)
    first_adoption = baseline is None  # pierwsze uruchomienie: adoptuj istniejący dryf
    baseline = baseline or {"violations": []}
    known = signatures(baseline)

    violations = collect_violations()
    by_key = {f'{v["file"]}::{v["signature"]}': v for v in violations}
    if first_adoption:
        new = []  # adoptacja początkowa: istniejący dryf = backlog, nie blokada
    else:
        new = [v for k, v in by_key.items() if k not in known]

    state = {"violations": list(by_key.values())}
    write_json(baseline_path, state)

    if args.all:
        result = {"mode": "FULL_AUDIT", "total_violations": len(by_key),
                  "new_violations": 0, "verdict": "AUDIT_ONLY"}
        print(json.dumps(result, ensure_ascii=False))
        write_json(BUNDLES_DIR / "v3_p48_gate_full_audit.json",
                   {"generated_at": utcnow_iso(), "gate": "PASS", **result,
                    "violations": list(by_key.values())[:200]})
        return 0

    verdict = "BLOCK" if new else "PASS"
    result = {"mode": "MERGE_GATE", "first_adoption": first_adoption,
              "known_violations": len(known & set(by_key)),
              "backlog_violations": len(by_key),
              "new_violations": len(new), "verdict": verdict,
              "new": new[:20]}
    write_json(BUNDLES_DIR / "v3_p48_gate_merge.json",
               {"generated_at": utcnow_iso(),
                "gate": "PASS" if verdict == "PASS" else "FAIL", **result})
    print(json.dumps(result, ensure_ascii=False))
    return 1 if verdict == "BLOCK" else 0


if __name__ == "__main__":
    raise SystemExit(main())
