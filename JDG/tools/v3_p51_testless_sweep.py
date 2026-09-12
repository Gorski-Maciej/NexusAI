#!/usr/bin/env python3
"""NexusAI JDG — V3-P51-I09 TESTLESS RULE SWEEP — klasa pustyni „reguła bez
testu" (najszybsza do domknięcia) + „test bez reguły" (ghost).

Rejestruje per domena: reguły kanoniczne bez natywnego testu Rego (baza UVR
z canon jako kontekst), testy odwołujące się do rule_id bez pokrycia
kanonicznego (ghost testy), plan domknięcia generatorem testów (P36).
Rozszerza canon (UVR globalne) o wymiar per-domena i ghost-testy — nie
duplikuje coverage_unifier.
"""
from __future__ import annotations

import re
from collections import Counter

from v3_p51_common import (COVERAGE_CANON, RULES_DIR, TESTS_REGO_DIR,
                           read_json, write_p51_bundle)

RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
TEST_ID_RE = re.compile(r'"(jdg\.[A-Za-z0-9_.]+)"')


def _collect_rules() -> dict:
    per_domain = Counter()
    all_ids = set()
    for fp in RULES_DIR.rglob("*.rego"):
        try:
            txt = fp.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        ids = RULE_ID_RE.findall(txt)
        for rid in ids:
            dom = rid.split(".")[1] if rid.count(".") >= 2 else "other"
            per_domain[dom] += 1
        all_ids.update(ids)
    return per_domain, all_ids


def _collect_tested() -> set:
    ids = set()
    if not TESTS_REGO_DIR.exists():
        return ids
    for fp in TESTS_REGO_DIR.rglob("*.rego"):
        try:
            txt = fp.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for tid in TEST_ID_RE.findall(txt):
            if tid.count(".") < 2:
                continue
            if ".test." in tid or tid.split(".")[2].endswith("_test"):
                continue
            ids.add(tid)
    return ids


def main() -> int:
    per_domain, all_ids = _collect_rules()
    tested = _collect_tested()
    ghost_tests = sorted(t for t in tested
                         if t not in all_ids and ".test." not in t)
    untested_by_domain = {d: {"rules_total": n,
                              "untested": None}
                          for d, n in per_domain.items()}
    # Honesty: per-domena nie umiemy przypisać testu bez mapowania pakiet→
    # test-file; raportujemy globalnie UVR z canon jako baza i testless
    # count z tego skanu (reguły kanoniczne bez żadnej wzmianki w tests/rego).
    untested_total = len(all_ids - tested)
    canon = read_json(COVERAGE_CANON) or {}
    uvr_canon = (canon.get("denominators") or {}).get(
        "rules_untested_by_native_rego")
    metrics = {
        "analysis": "testless_sweep",
        "routing": "TRIAGE_QUEUE" if (untested_total > 0 or ghost_tests)
                   else "AUTO_FILE",
        "rules_scanned": len(all_ids),
        "rules_without_test": untested_total,
        "ghost_tests": len(ghost_tests),
        "uvr_canon_context": uvr_canon,
        "domains": len(per_domain),
    }
    write_p51_bundle("testless_sweep", "V3-P51-I09", metrics, {
        "untested_by_domain": untested_by_domain,
        "ghost_tests_sample": ghost_tests[:30],
        "plan": "generator testów (P36) domyka rule_no_test szybciej niż "
                "pisanie reguł; ghost testy → usunięcie albo re-wiring.",
        "note": "UVR canon = reguły dowodne bez testu natywnego (mianownik "
                "inny niż ten skan — kontekst, nie porównanie wprost).",
    })
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
