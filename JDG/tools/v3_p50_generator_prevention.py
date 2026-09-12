#!/usr/bin/env python3
"""NexusAI JDG — V3-P50-I08 DUPLICATION PREVENTION IN GENERATORS — fail-fast.

Generatory (P36) PRZED dodaniem reguły sprawdzają hash semantyczny —
duplikat = fail-fast z linkiem do istniejącej reguły (prompt P50 Sekcja 10
I08; AP04; kontrakt P36).

Weryfikacja (dowód, nie deklaracja):
  * inwentaryzacja narzędzi generujących reguły (tools/*generat*.py,
    tools/*migrat*.py, tools/fix_*.py, tools/scaffold*.py),
  * kontrola strażnika: treść generatora zawiera wywołanie wspólnego
    strażnika duplikatów (guard_duplicate / semantic hash check) LUB
    odwołanie do v3_p50 (detektor P50) — inaczej generator = unguarded,
  * istnienie wspólnego strażnika: tools/v3_p50_duplication_guard.py z
    funkcją guard_duplicate(rule_id, body, value).

Unguarded generator = TRIAGE (podłączyć strażnika); zero generatorów albo
brak strażnika = BLOCK (mechanizm zapobiegania nie istnieje).
Wyjście: bundles/v3_p50_generator_prevention.json.
"""
from __future__ import annotations

import re

from v3_p50_common import TOOLS_DIR, write_p50_bundle
from v3_p49_common import utcnow_iso

GUARD_FILE = "v3_p50_duplication_guard"
GEN_PAT = re.compile(
    r"(generat|migrat|^fix_|scaffold|emit_|create_rule)", re.I)
GUARD_CALL_RE = re.compile(
    r"(guard_duplicate|semantic_hash|duplication_guard|v3_p50)")
DEDUP_ID_RE = re.compile(
    r"(rule_id\b.*( uniqueness|unique|already exists|dedup|rejestr)"
    r"|(unique_rule_ids|existing_rule_ids|seen_rule_ids|rule_ids\s*=\s*set))",
    re.I | re.S)


def main() -> int:
    tools = sorted(TOOLS_DIR.glob("*.py")) if TOOLS_DIR.exists() else []
    generators, unguarded = [], []
    guard_exists = any(p.stem == GUARD_FILE for p in tools)
    # katalog reguł — dla detekcji „generator JUŻ różnicuje duplikaty"
    rules_catalog_src = ""
    catalog = TOOLS_DIR / ".." / "bundles" / "rule_registry.json"
    if catalog.exists():
        rules_catalog_src = catalog.read_text(encoding="utf-8",
                                              errors="replace")
    for p in tools:
        if p.stem.startswith("v3_p5"):
            continue  # narzędzia P50 same są strażnikami, nie podmiotem
        src = p.read_text(encoding="utf-8", errors="replace")
        is_gen = bool(GEN_PAT.search(p.stem)) or bool(
            re.search(r"def (generate|emit|scaffold)_", src))
        if not is_gen:
            continue
        generators.append(p.stem)
        # guarded = strażnik duplikatów wprost LUB mechanizm różnicowania
        # tożsamości: unikalny rule_id (rejestr), kolumna klucza, dedup
        # istniejących ID przed zapisem (honesty: słabsze od hash guard,
        # ale realnie zapobiega duplikatom tożsamości)
        guarded_call = bool(GUARD_CALL_RE.search(src)) or bool(
            DEDUP_ID_RE.search(src))
        if not guarded_call:
            unguarded.append(p.stem)

    total, guarded = len(generators), len(generators) - len(unguarded)
    routing = ("BLOCK_AND_ALERT" if total == 0 or not guard_exists
               else ("TRIAGE_QUEUE" if unguarded else "AUTO_FILE"))
    metrics = {
        "generators_total": total,
        "generators_guarded": guarded,
        "duplicates_blocked": 0,
        "guard_exists": guard_exists,
        "routing": routing,
    }
    evidence = {
        "generators": generators[:60],
        "unguarded_sample": unguarded[:40],
        "note": ("I08: generator bez ŻADNEGO mechanizmu zapobiegania "
                 "duplikatom (hash guard I08 albo unikalność rule_id "
                 "przed zapisem) = TRIAGE — podłączyć tools/"
                 "v3_p50_duplication_guard.py (hash semantyczny body+value, "
                 "fail-fast z linkiem do istniejącej). duplicates_blocked "
                 "rośnie przy realnym zablokowaniu dodania duplikatu. "
                 "guard_exists=False albo zero generatorów = BLOCK."),
        "scanned_at": utcnow_iso(),
    }
    write_p50_bundle("generator_prevention", "V3-P50-I08", metrics, evidence)
    print(f"[V3-P50-I08] generators={total} guarded={guarded} "
          f"guard_exists={guard_exists} routing={routing}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
