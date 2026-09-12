#!/usr/bin/env python3
"""NexusAI JDG — V3-P50-I05 DEAD TOOL ARCHIVE — procedura archiwizacji.

Narzędzie martwe (prompt P50 Sekcja 10 I05; P41; P43 DR) → archiwizacja do
katalogu archive/ z README powodu → usunięcie po v3_p50_archive_cycles cyklach
CI bez sprzeciwu. Twarde delete bez archiwum = BLOCK (rollback niemożliwy).

Definicja narzędzia martwego (honesty):
  * plik tools/*.py, który nie jest importowany przez żaden inny moduł
    (skan importów w JDG/**/*.py + tests/**), nie jest wymieniony w żadnym
    teście (nazwa pliku w tests/**), i nie ma własnego __main__ uruchamianego
    przez bramki (wzmianka w tools/*.py gate/runner),
  * wyłączenie: narzędzia-listy (v3_p45_tool_inventory), crossref i prompty
    kampanii (archiwum wejściowe promptu P50 Sekcja 6).

Zasada: licznik martwych NIE narzuca twardego delete — generuje listę do
procedury I05 (decyzja człowieka 4-eyes przy usunięciu, Q04 konwencja P49).
Wyjście: bundles/v3_p50_dead_tool_archive.json.
"""
from __future__ import annotations

import re
from pathlib import Path

from v3_p48_common import REPO_ROOT
from v3_p50_common import BUNDLES_DIR, write_p50_bundle
from v3_p49_common import utcnow_iso

JDG_ROOT = REPO_ROOT / "JDG"
TOOLS_DIR = JDG_ROOT / "tools"
TESTS_DIR = JDG_ROOT / "tests"
ARCHIVE_DIR = JDG_ROOT / "archive"
IMPORT_RE = re.compile(r'^\s*(?:import|from)\s+([A-Za-z_][A-Za-z0-9_]*)', re.M)


def _module_imports(path: Path) -> set[str]:
    try:
        src = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return set()
    return set(IMPORT_RE.findall(src))


def main() -> int:
    tool_files = sorted(TOOLS_DIR.glob("*.py")) if TOOLS_DIR.exists() else []
    tool_names = {p.stem for p in tool_files}

    # graf importów: kto kogo importuje (wszędzie w JDG) — korpus testów
    # wczytany RAZ (nie per narzędzie; ryzyko O(tools×tests) odczytów)
    all_py = sorted(JDG_ROOT.rglob("*.py"))
    test_corpus_names: set[str] = set()
    test_corpus_src: list[str] = []
    if TESTS_DIR.exists():
        for tp in TESTS_DIR.rglob("*.py"):
            test_corpus_names.add(tp.stem)
            try:
                test_corpus_src.append(tp.read_text(encoding="utf-8",
                                                    errors="replace"))
            except OSError:
                continue
    tests_blob = "\n".join(test_corpus_src)

    imported_by: dict[str, set[str]] = {name: set() for name in tool_names}
    referenced_in: dict[str, set[str]] = {name: set() for name in tool_names}
    for py in all_py:
        try:
            src = py.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        mods = _module_imports(py)
        for name in tool_names:
            if name in mods and py.stem != name:
                imported_by[name].add(py.stem)
            # wzmianka w teście / bramce / rejestrze (string match)
            if name != py.stem and name in src:
                referenced_in[name].add(py.stem)

    dead, alive = [], []
    for name in sorted(tool_names):
        has_tests = (name in tests_blob or name in test_corpus_names)
        referenced = bool(imported_by[name] or referenced_in[name]
                          or has_tests)
        (alive if referenced else dead).append(name)

    archived = []
    if ARCHIVE_DIR.exists():
        archived = [p.name for p in sorted(ARCHIVE_DIR.iterdir())
                    if p.suffix == ".py"]

    routing = ("BLOCK_AND_ALERT" if not tool_files
               else ("TRIAGE_QUEUE" if len(dead) > len(archived)
                     else "AUTO_FILE"))
    metrics = {
        "tools_total": len(tool_names),
        "tools_referenced": len(alive),
        "dead_tools": len(dead),
        "archived": len(archived),
        "hard_deletes": 0,
        "archive_cycles": 2,
        "routing": routing,
    }
    evidence = {
        "dead_tools_list": dead[:100],
        "archived_list": archived[:50],
        "procedure": ("I05: martwe narzędzie → archive/ + README powodu → "
                      "usunięcie po v3_p50_archive_cycles cyklach CI bez "
                      "sprzeciwu; twarde delete = BLOCK (rollback P43). "
                      "Lista dead_tools = KANDYDACI do procedury (decyzja "
                      "4-eyes), nie automatyczne usuwanie."),
        "scanned_at": utcnow_iso(),
    }
    write_p50_bundle("dead_tool_archive", "V3-P50-I05", metrics, evidence)
    print(f"[V3-P50-I05] tools={len(tool_names)} alive={len(alive)} "
          f"dead={len(dead)} archived={len(archived)} routing={routing}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
