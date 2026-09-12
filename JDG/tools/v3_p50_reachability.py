#!/usr/bin/env python3
"""NexusAI JDG — V3-P50-I11 RULE REACHABILITY MAP — zero reguł bez wejścia.

Mapa: routing orkiestratora (main_jdg) → reguły osiągalne → ścieżki
wywołania (prompt P50 Sekcja 10 I11; P02; dead_rule_detector).

Metoda (statyczna, deterministyczna):
  * korzeń: package jdg.main (rules/main_jdg.rego),
  * graf: import data.jdg.X as Y w pliku pakietu P → krawędź P → X;
    krawędzie budowane per PLIK (plik definiuje package, importy łączą
    pakiety), odwiedzone pliki = reachable set,
  * rule_id osiągalny = rule_id w pliku osiągalnym; unreachable = rule_id
    w plikach spoza zbioru osiągalnych (dead code — podpiąć albo
    zarchiwizować; decyzja per reguła, I05-analogia dla reguł).

Anty-FP: pakiety testowe (*_test) i pliki testowe pomijane (nie są produk-
cyjnymi punktami wejścia); rejestry danych (thresholds) = dane, nie reguły.
Wyjście: bundles/v3_p50_reachability.json.
"""
from __future__ import annotations

import re
from collections import defaultdict, deque

from v3_p48_common import walk_rego
from v3_p50_common import RULES_DIR, write_p50_bundle
from v3_p49_common import utcnow_iso

PKG_RE = re.compile(r"^package\s+([a-zA-Z0-9_.]+)", re.M)
IMPORT_RE = re.compile(r"^\s*import\s+data\.([a-zA-Z0-9_.]+)", re.M)
RULE_ID_RE = re.compile(r'"rule_id"\s*[:=]\s*"([a-zA-Z0-9_.]+)"')
_BOILER = (".no_match", ".fallback", ".thresholds_missing",
           ".packages_missing", ".default")
ENTRY_PACKAGE = "jdg.main"


def main() -> int:
    files = walk_rego(RULES_DIR)
    file_pkg: dict[str, str] = {}
    pkg_files: dict[str, set[str]] = defaultdict(set)
    file_imports: dict[str, set[str]] = {}
    file_rule_ids: dict[str, list[str]] = {}

    for rel, path in files.items():
        src = path.read_text(encoding="utf-8", errors="replace")
        m = PKG_RE.search(src)
        pkg = m.group(1) if m else "(none)"
        if pkg.endswith("_test") or "/test_" in rel or "tests/" in rel:
            continue  # testy nie są produkcyjnym punktem wejścia
        file_pkg[rel] = pkg
        pkg_files[pkg].add(rel)
        file_imports[rel] = set(IMPORT_RE.findall(src))
        file_rule_ids[rel] = [r for r in RULE_ID_RE.findall(src)
                              if not r.endswith(_BOILER)]

    # BFS od pakietu wejściowego po krawędziach importów (file → file)
    roots = sorted(pkg_files.get(ENTRY_PACKAGE, set()))
    visited: set[str] = set()
    q = deque(roots)
    while q:
        rel = q.popleft()
        if rel in visited:
            continue
        visited.add(rel)
        for imp in file_imports.get(rel, ()):
            for tgt in pkg_files.get(imp, ()):
                if tgt not in visited:
                    q.append(tgt)

    reachable_ids: set[str] = set()
    unreachable_ids: set[str] = set()
    for rel, ids in file_rule_ids.items():
        if rel in visited:
            reachable_ids.update(ids)
        else:
            unreachable_ids.update(ids)

    total = len(reachable_ids) + len(unreachable_ids)
    unreachable = len(unreachable_ids)
    unreachable_max = 100
    routing = ("TRIAGE_QUEUE" if unreachable > unreachable_max
               else ("TRIAGE_QUEUE" if total == 0 else "AUTO_FILE"))
    metrics = {
        "files_production": len(file_pkg),
        "files_reachable": len(visited),
        "rules_total": total,
        "rules_reachable": len(reachable_ids),
        "rules_unreachable": unreachable,
        "unreachable_max": unreachable_max,
        "routing": routing,
    }
    evidence = {
        "entry_package": ENTRY_PACKAGE,
        "unreachable_files_sample": sorted(set(file_rule_ids) - visited)[:40],
        "unreachable_ids_sample": sorted(unreachable_ids)[:80],
        "note": ("I11: statyczna mapa osiągalności — import-file graph BFS "
                 "od package jdg.main. Anty-FP: pakiety testowe pominięte; "
                 "dane (thresholds) nie są regułami. Unreachable = dead "
                 "code → per reguła: podpiąć do routing (P02) albo "
                 "zarchiwizować (procedura I05). Rego dynamiczny (object.get "
                 "po nazwie pakietu) może dawać FP — sample do decyzji."),
        "scanned_at": utcnow_iso(),
    }
    write_p50_bundle("reachability", "V3-P50-I11", metrics, evidence)
    print(f"[V3-P50-I11] files={len(file_pkg)} reachable_files={len(visited)} "
          f"rules={total} unreachable={unreachable} routing={routing}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
