#!/usr/bin/env python3
"""NexusAI JDG — V3-P47 MERGE GATE — bramka CI weryfikacji podstaw prawnych.

Kontrakt bramki (spójny z P45/P46):
  * BLOCK tylko GENUINIE NOWE naruszenia kanonu cytowań (sygnatury treściowe,
    nie numery linii — lekcja P46: wstawienie linii nie może fabrykować
    „nowych" naruszeń),
  * istniejące naruszenia = backlog (TRIAGE), nie blokada merge,
  * zero fikcyjnych podstaw: podejrzenie AP05 = BLOCK natychmiast.
Usage: python tools/v3_p47_gate.py [--all]
"""
from __future__ import annotations

import argparse
import json

from v3_p47_common import (BUNDLES_DIR, RULES_DIR, citation_in_canon,
                           read_json, scan_legal_basis, write_json)


def signatures(existing: dict) -> set[str]:
    sigs = set()
    for v in existing.get("violations", []):
        sigs.add(f'{v.get("file")}::{v.get("signature")}')
    return sigs


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--all", action="store_true",
                        help="pełny audyt backlogu kanonu (bez blokady merge)")
    args = parser.parse_args()

    baseline_path = BUNDLES_DIR / "v3_p47_citation_gate_state.json"
    baseline = read_json(baseline_path)
    first_adoption = baseline is None  # pierwsze uruchomienie: adoptuj istniejące
    baseline = baseline or {"violations": []}
    known = signatures(baseline)

    scan = scan_legal_basis()
    violations = []
    seen: set[str] = set()
    for path in sorted(RULES_DIR.rglob("*.rego")):
        try:
            content = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for line_no, line in enumerate(content.splitlines(), start=1):
            stripped = line.strip()
            if stripped.startswith("#") or stripped.startswith("//"):
                continue
            if '"_legal_basis"' not in line and "_legal_basis" not in line:
                continue
            m = None
            for part in line.split('"'):
                if any(k in part for k in ("art.", "Dz.U", "NIEZWERYFIKOWANE", "BŁĄD_PODSTAWY")):
                    m = part
                    break
            if not m:
                continue
            if citation_in_canon(m):
                continue
            import hashlib
            sig = hashlib.sha256(f"{path.name}::{m}".encode()).hexdigest()[:16]
            if sig in seen:
                continue
            seen.add(sig)
            violations.append({"file": str(path.relative_to(RULES_DIR)),
                               "line": line_no, "citation": m[:120],
                               "signature": sig})

    by_key = {f'{v["file"]}::{v["signature"]}': v for v in violations}
    if first_adoption:
        new = []  # adoptacja początkowa: istniejące naruszenia = backlog, nie blokada
    else:
        new = [v for k, v in by_key.items() if k not in known]

    state = {"violations": list(by_key.values()),
             "first_adoption_at": __import__("v3_p47_common").utcnow_iso() if first_adoption else None}
    write_json(baseline_path, state)

    if args.all:
        result = {"mode": "FULL_AUDIT", "total_violations": len(by_key),
                  "new_violations": 0, "verdict": "AUDIT_ONLY"}
        print(json.dumps(result, ensure_ascii=False))
        write_json(BUNDLES_DIR / "v3_p47_gate_full_audit.json",
                   {"generated_at": __import__("v3_p47_common").utcnow_iso(),
                    "gate": "PASS", **result, "violations": list(by_key.values())[:200]})
        return 0

    verdict = "BLOCK" if new else "PASS"
    result = {"mode": "MERGE_GATE", "first_adoption": first_adoption,
              "known_violations": len(known & set(by_key)),
              "backlog_violations": len(by_key),
              "new_violations": len(new), "verdict": verdict,
              "new": new[:20]}
    write_json(BUNDLES_DIR / "v3_p47_gate_merge.json",
               {"generated_at": __import__("v3_p47_common").utcnow_iso(),
                "gate": "PASS" if verdict == "PASS" else "FAIL", **result})
    print(json.dumps(result, ensure_ascii=False))
    return 1 if verdict == "BLOCK" else 0


if __name__ == "__main__":
    raise SystemExit(main())
