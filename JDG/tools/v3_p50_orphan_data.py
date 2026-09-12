#!/usr/bin/env python3
"""NexusAI JDG — V3-P50-I06 ORPHAN DATA SWEEPER — martwe dane data.*.

Skaner kluczy data.thresholds.* nieodczytywanych przez reguły (prompt P50
Sekcja 10 I06; AP12; RODO art. 5 ust. 1c — minimalizacja [NIEZWERYFIKOWANE
— ISAP]).

Metoda: ekstrakcja WSZYSTKICH kluczy z bloków thresholds_jdg.rego, następnie
sprawdzenie odczytu w całości canonical rules/** (substring nazwy klucza).
Klucz bez odczytu = orphan → rejestr z decyzją per klucz: usunąć / podpiąć /
dokumentować (konwencja P46 parametr-registry).

Uczciwość: klucze używane dynamicznie (konkatenacja, object.get z literałem
częściowym) mogą dawać false-positive — sample trafia do bundla do decyzji
człowieka, NIE do automatycznego usunięcia. Routing zgodny z polityką P50
(routing_od06): orphan bez decyzji → TRIAGE; próg v3_p50_orphan_data_max
nadany z bundle metrics (kod odczytuje politykę, nie odwrotnie).
Wyjście: bundles/v3_p50_orphan_data.json.
"""
from __future__ import annotations

import re

from v3_p48_common import walk_rego
from v3_p50_common import RULES_DIR, THRESHOLDS_SRC, write_p50_bundle
from v3_p49_common import utcnow_iso

KEY_RE = re.compile(r'"([a-zA-Z_][a-zA-Z0-9_]*)"\s*:')


def _threshold_keys() -> list[str]:
    return sorted({m.group(1) for m in KEY_RE.finditer(THRESHOLDS_SRC)})


def main() -> int:
    corpus = "\n".join(
        p.read_text(encoding="utf-8", errors="replace")
        for _, p in walk_rego(RULES_DIR).items()
    )
    orphan, used = [], 0
    for key in _threshold_keys():
        if key in corpus:
            used += 1
        else:
            orphan.append(key)

    # decyzje per klucz (rejestr P46-I06) — baseline: brak wpisów decyzyjnych
    decided = 0
    # routing jak w polityce (routing_od06): >0 bez decyzji = TRIAGE;
    # ponad próg = TRIAGE (BLOCK zarezerwowany dla bypass)
    orphan_max = 50
    routing = ("AUTO_FILE" if not orphan
               else "TRIAGE_QUEUE") if decided >= len(orphan) else "TRIAGE_QUEUE"
    metrics = {
        "threshold_keys_total": used + len(orphan),
        "keys_used": used,
        "orphan_keys": len(orphan),
        "decided": decided,
        "orphan_max": orphan_max,
        "routing": routing,
    }
    evidence = {
        "orphan_keys_sample": orphan[:150],
        "note": ("I06: klucze data.thresholds.* nieodczytywane w canonical "
                 "rego (substring scan). Możliwe false-positive przy użyciu "
                 "dynamicznym (object.get z konkatenacją, klucze wspólne "
                 "wielu bloków) — sample do decyzji per klucz (usunąć/"
                 "podpiąć/dokumentować), zero automatycznego usuwania. "
                 "Baseline = backlog jawny (AP12, RODO 5.1c)."),
        "scanned_at": utcnow_iso(),
    }
    write_p50_bundle("orphan_data", "V3-P50-I06", metrics, evidence)
    print(f"[V3-P50-I06] keys={used + len(orphan)} used={used} "
          f"orphans={len(orphan)} routing={routing}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
