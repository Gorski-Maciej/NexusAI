#!/usr/bin/env python3
"""NexusAI JDG — V3-P50-I08 DUPLICATION GUARD — wspólny strażnik generatorów.

API dla generatorów reguł (P36) i narzędzi migracyjnych:

    from v3_p50_duplication_guard import guard_duplicate, semantic_hash

    guard_duplicate("jdg.vat.my_rule", body_ast_or_src, value)  # raises

  * semantic_hash(body, value) — kanoniczny hash (warunki + skutek), ten sam
    algorytm co detektor I01 (maskowanie stringów; tożsamość jdg.* nie
    różnicuje), więc hash pokrywa się z bundlem v3_p50_semantic_duplicates,
  * guard_duplicate(...) — DuplicationError z linkiem do istniejącej reguły
    (fail-fast PRZED zapisem pliku; generator ma obowiązek wywołać przed
    emitowaniem reguły — kontrakt P36/P50-I08).

Wyjście rejestru hashy: bundles/v3_p50_semantic_hash_index.json
(rule_id → fp) — indeks zasilany z ostatniego przebiegu detektora I01.
"""
from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

from v3_p48_common import RULES_DIR, walk_rego

JDG_STR_RE = re.compile(r"^jdg\.[A-Za-z0-9_.]+$")
INDEX_PATH = Path(__file__).resolve().parents[1] / "bundles" / \
    "v3_p50_semantic_hash_index.json"


class DuplicationError(RuntimeError):
    """Podniesiony, gdy nowa reguła duplikuje istniejącą (fail-fast I08)."""


def mask_term(t):
    """Kanonizacja AST/tekstu: stringi → '§' (tożsamość jdg.* → 'ID')."""
    if isinstance(t, dict):
        typ = t.get("type")
        if typ == "string":
            v = str(t.get("value", ""))
            return {"t": "s", "v": "ID" if JDG_STR_RE.match(v) else "§"}
        if typ in ("number", "boolean", "null"):
            return {"t": typ[:1], "v": t.get("value")}
        return {k: mask_term(v) for k, v in t.items()
                if k not in ("location", "index", "generated", "file")}
    if isinstance(t, list):
        return [mask_term(x) for x in t]
    if isinstance(t, str):
        return "ID" if JDG_STR_RE.match(t) else "§"
    return t


def semantic_hash(body, value) -> str:
    """Hash semantyczny reguły (algorytm zgodny z detektorem I01)."""
    h = hashlib.sha256
    bh = h(json.dumps(mask_term(body), sort_keys=True,
                     ensure_ascii=False).encode()).hexdigest()[:24]
    vh = h(json.dumps(mask_term(value), sort_keys=True,
                     ensure_ascii=False).encode()).hexdigest()[:24]
    return f"{bh}:{vh}"


def load_index() -> dict[str, dict]:
    return json.loads(INDEX_PATH.read_text(encoding="utf-8")) \
        if INDEX_PATH.exists() else {}


def guard_duplicate(rule_id: str, body, value) -> str:
    """Fail-fast: DuplicationError z linkiem do istniejącej reguły."""
    fp = semantic_hash(body, value)
    index = load_index()
    hit = index.get(fp)
    if hit and hit.get("rule_id") != rule_id:
        raise DuplicationError(
            f"[V3-P50-I08] Duplikat semantyczny: '{rule_id}' == "
            f"'{hit.get('rule_id')}' ({hit.get('file')}); fp={fp}. "
            f"Zamiast nowej reguły: referencja/consolidacja (I04/I09).")
    return fp


def rebuild_index_from_rules() -> int:
    """Odbuduj indeks hashy z canonical rego (tekstowy fallback bez OPA:
    hash treści deklaracji reguły; spójny metodą maskowania)."""
    index: dict[str, dict] = {}
    n = 0
    for rel, path in walk_rego(RULES_DIR).items():
        src = path.read_text(encoding="utf-8", errors="replace")
        for m in re.finditer(r'"rule_id"\s*[:=]\s*"([^"]+)"', src):
            fp = semantic_hash({"t": "src", "v": rel}, m.group(1))
            # indeks per rule_id (tekstowy); pełny hash AST z I01 w bundlu
            index[f"by-id:{m.group(1)}"] = {"rule_id": m.group(1),
                                            "file": rel, "fp": fp}
            n += 1
    INDEX_PATH.write_text(json.dumps(index, ensure_ascii=False, indent=2)
                          + "\n", encoding="utf-8")
    return n


if __name__ == "__main__":
    print(f"rebuilt entries: {rebuild_index_from_rules()}")
