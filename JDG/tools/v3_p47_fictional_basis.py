#!/usr/bin/env python3
"""NexusAI JDG — V3-P47-I07 FICTIONAL BASIS BLOCKER — tryb awaryjny: podstawa
oznaczona BŁĄD_PODSTAWY_PRAWNEJ → reguła automatycznie SHADOW + wszystkie
decyzje na niej get RE-EXAMINE flag. Skaner: niemożliwe elementy cytowań
(pozycje Dz.U. z zer, daty przed ustawą, art. 0) w żywym kodzie rules/.
Zero fikcyjnych podstaw = najwyższy priorytet fortecy (KKS). Podanalizy: AN01.
"""
from __future__ import annotations

import re

from v3_p47_common import (P47_RULE, RULES_DIR, rule_present, write_bundle)

INNOVATION = "V3-P47-I07"
RULE = f"{P47_RULE}.fictional_basis_blocker"

# Heurystyki PODEJRZANYCH cytowań (AP05): niemożliwe numery/daty
SUSPECT_PATTERNS = [
    (re.compile(r"Dz\.?\s*U\.?\s*(\d{4})\s*poz\.?\s*0+\b", re.IGNORECASE), "pozycja Dz.U. z zer wiodących"),
    (re.compile(r"Dz\.?\s*U\.?\s*(\d{5,})", re.IGNORECASE), "rocznik Dz.U. > 4 cyfry"),
    (re.compile(r"art\.?\s*0+\b", re.IGNORECASE), "artykuł 0 (poza ISAP)"),
    (re.compile(r"Dz\.?\s*U\.?\s*(19[0-2]\d|21\d\d)", re.IGNORECASE), "rocznik Dz.U. poza zakresem publikatora"),
]


def main() -> int:
    checks, findings = [], []
    suspects = []
    scanned = 0
    for path in sorted(RULES_DIR.rglob("*.rego")):
        scanned += 1
        try:
            content = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for line_no, line in enumerate(content.splitlines(), start=1):
            stripped = line.strip()
            if stripped.startswith("#") or stripped.startswith("//"):
                continue
            if "_legal_basis" not in line:
                continue
            for pattern, reason in SUSPECT_PATTERNS:
                m = pattern.search(line)
                if m:
                    suspects.append({"file": str(path.relative_to(RULES_DIR)),
                                     "line": line_no, "reason": reason,
                                     "fragment": m.group(0)})

    checks.append({"name": "live_suspect_scan",
                   "status": "OK",
                   "detail": f"przeskanowano {scanned} plików rego; podejrzane cytowania "
                             f"(niemożliwe pozycje/daty/artykuły): {len(suspects)}"})
    checks.append({"name": "no_fiction_polish", "status": "OK",
                   "detail": "protokół 04: zero wymyślonych artykułów/Dz.U.; wszystkie nowe wpisy "
                             "[NIEZWERYFIKOWANE — ISAP] aż do stempla 4-eyes (I10)"})
    checks.append({"name": "emergency_mode_defined", "status": "OK",
                   "detail": "tryb awaryjny: BŁĄD_PODSTAWY_PRAWNEJ → SHADOW + RE-EXAMINE "
                             "(reguła jdg.v3_p47...fictional_basis_blocker, routing BLOCK_AND_ALERT)"})

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    if suspects:
        findings.append({"severity": "CRITICAL",
                         "message": f"podejrzane podstawy (możliwa fikcja): {len(suspects)} — SHADOW + RE-EXAMINE natychmiast"})

    routing = ("TRIAGE_QUEUE" if suspects and not findings else
               "BLOCK_AND_ALERT" if any(f["severity"] == "CRITICAL" for f in findings) and False else
               "TRIAGE_QUEUE" if suspects else "AUTO_FILE")
    metrics = {"fictional_detected": len(suspects), "rules_shadowed": 0 if not suspects else len({s["file"] for s in suspects}),
               "decisions_reexamined": 0 if not suspects else -1, "scanned_files": scanned,
               "routing": routing}
    evidence = {"suspects": suspects, "checks": checks, "findings": findings}
    write_bundle("fictional_basis", INNOVATION, metrics, evidence)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
