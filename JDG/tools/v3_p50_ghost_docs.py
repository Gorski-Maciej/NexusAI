#!/usr/bin/env python3
"""NexusAI JDG — V3-P50-I07 GHOST DOC DETECTOR — dokumenty-widma.

Dokumenty odwołujące się do nieistniejących plików/reguł (prompt P50
Sekcja 10 I07; P41 dokumentacja; AP „dokumenty-widma").

Metoda (honesty — precyzyjne wzorce, nie żadne odwołanie):
  * ścieżki kodu w docs/**/*.md: `JDG/...`, `rules/...rego`, `tools/....py`,
    `bundles/...json`, `tests/...` — sprawdzenie istnienia względem repo root
    albo JDG root (ścieżki z anchorami liniowymi `:123` / `#L123` okaleczane),
  * odwołania do rule_id `jdg.x.y[.z]` w docs/**/*.md — sprawdzenie w kanonie
    rule_id (ekstrakcja z rules/** + rejestry) — ghost gdy brak w kanonie.

Wyłączenia (false-positive control): linki zewnętrzne (http), ścieżki
generyczne wewnątrz bloków kodu z placeholderami <>, przykłady oznaczone
„np." / „example". Rejestr ghostów → korekta P41 (poprawka odwołania),
nie automatyczne usuwanie dokumentów.
Wyjście: bundles/v3_p50_ghost_docs.json.
"""
from __future__ import annotations

import re
from pathlib import Path

from v3_p48_common import REPO_ROOT
from v3_p50_common import JDG_ROOT, RULES_DIR, write_p50_bundle
from v3_p49_common import utcnow_iso

DOCS_DIRS = (JDG_ROOT / "docs", REPO_ROOT / "docs")

PATH_RES = (
    re.compile(r'`?(?:JDG/)?(rules/[A-Za-z0-9_/.-]+\.rego)`?'),
    re.compile(r'`?(?:JDG/)?(tools/[A-Za-z0-9_/.-]+\.py)`?'),
    re.compile(r'`?(?:JDG/)?(bundles/[A-Za-z0-9_/.-]+\.json)`?'),
    re.compile(r'`?(?:JDG/)?(docs/[A-Za-z0-9_/.-]+\.(?:md|txt|rego))`?'),
    re.compile(r'`?(?:JDG/)?(tests/[A-Za-z0-9_/.-]+\.(?:py|rego))`?'),
)
RULE_ID_RE = re.compile(r'`?(jdg\.[a-z0-9_]+(?:\.[a-z0-9_]+)+)`?')
LINE_ANCHOR_RE = re.compile(r'[:#]L?\d+$')
CODE_FENCE_RE = re.compile(r"```.*?```", re.S)


def _canon_rule_ids() -> set[str]:
    ids: set[str] = set()
    for _, p in RULES_DIR.items() if isinstance(RULES_DIR, dict) else []:
        pass
    for p in RULES_DIR_PATH.rglob("*.rego"):
        src = p.read_text(encoding="utf-8", errors="replace")
        for m in re.finditer(r'"(jdg\.[a-zA-Z0-9_.]+)"', src):
            ids.add(m.group(1))
    # rejestry
    for reg in (JDG_ROOT / "bundles" / "rule_registry.json",):
        if reg.exists():
            for m in re.finditer(r'"(jdg\.[a-zA-Z0-9_.]+)"',
                                 reg.read_text(encoding="utf-8",
                                               errors="replace")):
                ids.add(m.group(1))
    return ids


RULES_DIR_PATH = JDG_ROOT / "rules"


def _docs_files() -> list[Path]:
    files: list[Path] = []
    for d in DOCS_DIRS:
        if d.exists():
            files.extend(sorted(d.rglob("*.md")))
    return files


def _resolve(rel: str) -> Path | None:
    rel = LINE_ANCHOR_RE.sub("", rel.strip().lstrip("`").rstrip("`").strip())
    if "<" in rel or "..." in rel or "*" in rel:
        return None
    for base in (REPO_ROOT, JDG_ROOT):
        cand = (base / rel).resolve()
        if cand.exists():
            return cand
        # relatywnie do JDG gdy ścieżka bez prefiksu
        cand2 = (JDG_ROOT / rel).resolve()
        if cand2.exists():
            return cand2
    return None


def main() -> int:
    canon_ids = _canon_rule_ids()
    ghosts: list[dict] = []
    docs_scanned = 0
    for doc in _docs_files():
        docs_scanned += 1
        src = doc.read_text(encoding="utf-8", errors="replace")
        # bloki kodu z placeholderami pomijane (przykłady, nie odwołania)
        prose = CODE_FENCE_RE.sub("", src)
        rel_doc = str(doc.relative_to(REPO_ROOT))
        for rex in PATH_RES:
            for m in rex.finditer(prose):
                rel = m.group(1)
                if "<" in rel or "..." in rel:
                    continue
                if _resolve(rel) is None:
                    ghosts.append({"doc": rel_doc, "kind": "path",
                                   "ref": rel})
        for m in RULE_ID_RE.finditer(prose):
            rid = m.group(1)
            if rid not in canon_ids and not rid.endswith((".no_match",
                                                          ".thresholds_missing")):
                # heurystyka anty-FP: prefiks pakietu musi istnieć w kanonie
                pkg = rid.rsplit(".", 1)[0]
                if pkg not in canon_ids:
                    ghosts.append({"doc": rel_doc, "kind": "rule_id",
                                   "ref": rid})

    # deduplikacja (ten sam ref w wielu docsach = 1 wpis z licznikiem docsów)
    dedup: dict[tuple, dict] = {}
    for g in ghosts:
        k = (g["kind"], g["ref"])
        if k in dedup:
            dedup[k]["docs"].append(g["doc"])
        else:
            dedup[k] = {**g, "docs": [g["doc"]]}
    ghosts = sorted(dedup.values(), key=lambda g: (g["kind"], g["ref"]))

    corrected = 0  # baseline: korekty P41 dopiero po rejestrze
    routing = ("AUTO_FILE" if not ghosts else "TRIAGE_QUEUE")
    metrics = {
        "docs_scanned": docs_scanned,
        "ghost_references": len(ghosts),
        "corrected": corrected,
        "ghost_max": 10,
        "routing": routing,
    }
    evidence = {
        "ghosts_sample": [{**g, "docs": g["docs"][:5]} for g in ghosts[:80]],
        "canon_rule_ids": len(canon_ids),
        "note": ("I07: dokumenty-widma = ścieżki/reguły w docs bez pokrycia "
                 "w repo. Anty-FP: bloki kodu z przykładami pomijane, anchor "
                 "liniowy okaleczany, heurystyka prefiksu pakietu dla "
                 "rule_id. Korekta przez P41 (poprawa odwołania), nie "
                 "automatyczne usuwanie dokumentów."),
        "scanned_at": utcnow_iso(),
    }
    write_p50_bundle("ghost_docs", "V3-P50-I07", metrics, evidence)
    print(f"[V3-P50-I07] docs={docs_scanned} ghosts={len(ghosts)} "
          f"routing={routing}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
