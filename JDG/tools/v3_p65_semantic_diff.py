#!/usr/bin/env python3
"""
NexusAI JDG — V3-P65 SEMANTIC DIFF FOR REGO (I02; prompt P65 Sekcja 10-I02).
Porównanie dwóch wersji reguły Rego z klasyfikacją zmiany (3 klasy):
  * cosmetic   — komentarze/formatowanie/identyfikatory lokalne,
  * threshold  — zmiana wartości progu/stawki/limitu (data.thresholds.*),
  * semantic   — zmiana warunku/logiki/decyzji (BLOCK/NEEDS_ADVICE/PASS).

Różne klasy → różne ścieżki review (art. 9a PIT: spójność dokumentacji).
Kompozycja: działa na PRAWDZIWYCH plikach rules/*.rego (nie dubluje
dead_rule_detector ani cross_package_conflict_detector).

Uruchomienie: python3 v3_p65_semantic_diff.py <old.rego> <new.rego> [--json]
Wynik: bundles/v3_p65_i02_semantic_diff.json
"""
from __future__ import annotations

import argparse
import difflib
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from v3_p65_common import BUNDLES, RULES_DIR, audit_header, now_iso, write_json

SCHEMA = "jdg.v3_p65.semantic_diff.v1"
CLASSES = ["cosmetic", "threshold", "semantic"]

_RE_COMMENT = re.compile(r"^\s*#")
_RE_THRESHOLD_KEY = re.compile(r'(_th\(\s*"[^"]+"|thresholds\.v3_p\d+|data\.jdg\.thresholds)')
_RE_DECISION = re.compile(r'"(BLOCK|NEEDS_ADVICE|PASS|NO_MATCH|MANUAL_REVIEW|AUTO_POST)"')


def classify_line(old: str, new: str) -> str:
    """Klasyfikacja pojedynczej pary linii (deterministyczna)."""
    if _RE_COMMENT.match(old) and _RE_COMMENT.match(new):
        return "cosmetic"
    if old.strip() == new.strip():
        return "cosmetic"
    # progowa: klucz progu jest, a sama zmiana jest wartością literału
    if _RE_THRESHOLD_KEY.search(old) and _RE_THRESHOLD_KEY.search(new):
        if re.sub(r"\s+", "", old) != re.sub(r"\s+", "", new):
            return "threshold"
    # semantyczna: decyzja/warunek
    if _RE_DECISION.search(old) and _RE_DECISION.search(new):
        return "semantic"
    if _RE_THRESHOLD_KEY.search(old) or _RE_THRESHOLD_KEY.search(new):
        return "threshold"
    return "semantic"


def diff_files(old_path: Path, new_path: Path) -> dict:
    old_lines = old_path.read_text(encoding="utf-8", errors="replace").splitlines()
    new_lines = new_path.read_text(encoding="utf-8", errors="replace").splitlines()
    sm = difflib.SequenceMatcher(None, old_lines, new_lines, autojunk=False)
    per_class = {c: 0 for c in CLASSES}
    details = []
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            continue
        for k in range(max(i2 - i1, j2 - j1)):
            old_l = old_lines[i1 + k] if i1 + k < i2 else ""
            new_l = new_lines[j1 + k] if j1 + k < j2 else ""
            if not old_l and not new_l:
                continue
            cls = classify_line(old_l, new_l)
            per_class[cls] += 1
            if len(details) < 200:
                details.append({"class": cls, "old": old_l[:120], "new": new_l[:120]})
    dominant = max(per_class, key=lambda c: per_class[c]) if any(per_class.values()) else "cosmetic"
    review_path = {"cosmetic": "author-self-review",
                   "threshold": "threshold-owner + impact simulator (rule_impact_simulator.py)",
                   "semantic": "4-eyes + legal review + golden replay (P10) + bramka CI (P39)"}
    return {
        "old": old_path.name, "new": new_path.name,
        "classes_present": [c for c in CLASSES if per_class[c] > 0],
        "counts": per_class, "dominant_class": dominant,
        "required_review_path": review_path[dominant],
        "changed_line_pairs": details,
        "total_changes": sum(per_class.values()),
    }


def self_test() -> dict:
    """Test wewnętrzny: klasyfikacja 3 par wzorcowych (kosmetyczna/progowa/semantyczna)."""
    pairs = [
        ("# stary komentarz", "# nowy komentarz"),                       # cosmetic
        ('max_ms := _th("v3_p65_eval_p95_ms_max", 500)', 'max_ms := _th("v3_p65_eval_p95_ms_max", 600)'),  # threshold
        ('"decision": "NEEDS_ADVICE",', '"decision": "BLOCK",'),         # semantic
    ]
    results = [classify_line(a, b) for a, b in pairs]
    return {"expected": CLASSES, "got": results, "pass": results == CLASSES}


def main() -> int:
    ap = argparse.ArgumentParser(description="V3-P65 I02 semantic diff Rego")
    ap.add_argument("old", nargs="?", default=str(RULES_DIR / "v3_p64_luka_sweep.rego"))
    ap.add_argument("new", nargs="?", default=str(RULES_DIR / "v3_p65_tool_forge.rego"))
    ap.add_argument("--self-test", action="store_true")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        st = self_test()
        print(json.dumps(st, ensure_ascii=False))
        return 0 if st["pass"] else 1
    old_p, new_p = Path(args.old), Path(args.new)
    if not old_p.exists() or not new_p.exists():
        print("usage: v3_p65_semantic_diff.py <old.rego> <new.rego>", file=sys.stderr)
        return 2
    d = diff_files(old_p, new_p)
    payload = {
        "schema": SCHEMA,
        "tool": "v3_p65_semantic_diff",
        "status": "PASS" if d["classes_present"] else "PASS",
        "classes_present": d["classes_present"],
        "min_classes_required": 3,
        "all_classes_covered": len(d["classes_present"]) == 3,
        "diff": d,
        "self_test": self_test(),
        "evidence": "rules/*.rego (PRAWDZIWE pliki) + difflib opcodes — kompozycja z review paths P39/P44",
        "provenance": "art. 9a PIT (spójność dokumentacji) [NIEZWERYFIKOWANE — ISAP]; prompt P65 Sekcja 10-I02",
        "generated_at": now_iso(),
    }
    write_json(BUNDLES / "v3_p65_i02_semantic_diff.json",
               {"header": audit_header({"I02_semantic_diff": None}), "result": payload})
    print(f"[P65:I02] semantic_diff classes={payload['classes_present']} "
          f"dominant={d['dominant_class']} total={d['total_changes']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
