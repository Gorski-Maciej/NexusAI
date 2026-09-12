#!/usr/bin/env python3
"""NexusAI JDG — V3-P50-I01/I02/I12 SEMANTIC DUPLICATE DETECTOR (AST).

I01 (spec promptu: „hash warunków (AST)"): pełny parse OPA (`opa parse
--format=json`), dla każdej reguły hash = (warunki body + wartość/skutek),
stringi maskowane do wspólnego placeholdera (komunikaty i TOŻSAMOŚĆ jdg.* nie
różnicują) — dwie reguły różniące się wyłącznie rule_id mają identyczny hash
= duplikat zasady prawnej (AP04), niezależnie od nazw i plików.

I02 Contradiction check: para duplikatów z RÓŻNYM decision_mode w skutku =
sprzeczność (dwie interpretacje prawa na ten sam input — art. 24b OP
[NIEZWERYFIKOWANE — ISAP]; najgroźniejsza klasa → BLOCK).

I12 Duplicate burden: % reguł będących duplikatami (cel 0%).

Temporalne warianty (różne valid_from w skutku) raportowane osobno —
kandydaci do deklaracji overlay (I10), nie do ślepej konsolidacji.

Honesty: liczby z realnego parse'u; błędy parse liczone i raportowane.
Wyjście: v3_p50_semantic_duplicates.json.
"""
from __future__ import annotations

import hashlib
import json
import re
import subprocess
from collections import defaultdict
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

from v3_p48_common import RULES_DIR, walk_rego
from v3_p50_common import write_p50_bundle
from v3_p49_common import utcnow_iso

OPA = Path(__file__).resolve().parents[2] / "bin" / "opa"
OPA19 = Path(__file__).resolve().parents[2] / "bin" / "opa19"

# Boierplate defaultów (no_match/fallback) — nie są zasadami prawnymi (AP04
# dotyczy ZASAD, nie szablonów bram fail-closed).
BOILERPLATE_TAIL = (".no_match", ".fallback", ".thresholds_missing",
                    ".packages_missing", ".default")

JDG_STR_RE = re.compile(r"^jdg\.[A-Za-z0-9_.]+$")


def mask_term(t):
    """Kanonizacja podzbioru AST: stringi → '§' (tożsamość jdg.* → 'ID'),
    liczby/bool zachowane, nazwy zmiennych/ref zachowane, location USUWANE
    (linie/kolumny nie są semantyką)."""
    if isinstance(t, dict):
        typ = t.get("type")
        if typ == "string":
            v = str(t.get("value", ""))
            return {"t": "s", "v": "ID" if JDG_STR_RE.match(v) else "§"}
        if typ in ("number", "boolean", "null"):
            return {"t": typ[:1], "v": t.get("value")}
        if typ == "var":
            return {"t": "v", "v": t.get("value")}
        out = {}
        for k, v in t.items():
            if k in ("location", "index", "generated", "file"):
                continue
            out[k] = mask_term(v)
        return out
    if isinstance(t, list):
        return [mask_term(x) for x in t]
    return t


def _hash(obj) -> str:
    return hashlib.sha256(
        json.dumps(obj, sort_keys=True, ensure_ascii=False).encode()
    ).hexdigest()[:24]


def collect_jdg_strings(term, acc: list[str]):
    if isinstance(term, dict):
        if term.get("type") == "string" and JDG_STR_RE.match(str(term.get("value", ""))):
            acc.append(str(term["value"]))
        for v in term.values():
            collect_jdg_strings(v, acc)
    elif isinstance(term, list):
        for x in term:
            collect_jdg_strings(x, acc)


def _body_is_trivial(body) -> bool:
    """Puste body / body=true = wpis inwentaryzacyjny (katalog metadanych),
    nie reguła decyzyjna — poza semantyką duplikatów AP04."""
    if not isinstance(body, list) or len(body) == 0:
        return True
    if len(body) == 1:
        t = body[0]
        if isinstance(t, dict) and t.get("type") == "term":
            v = t.get("value")
            if isinstance(v, dict) and v.get("type") == "boolean" and v.get("value") is True:
                return True
        if isinstance(t, dict) and t.get("type") == "some_decl":
            return len(body) == 1
    return False


def parse_file(path) -> dict | None:
    """Parse z fallbackiem: OPA 0.68 → opa19 --v0-compatible (pliki w dialekcie
    v1 wymagają nowszego parsera); dopiero oba błędy = parse_error."""
    for binary, extra in ((OPA, []), (OPA19, ["--v0-compatible"]),
                          (OPA19, [])):
        try:
            proc = subprocess.run([str(binary), "parse", "--format=json", *extra,
                                   str(path)],
                                  capture_output=True, text=True, timeout=60)
        except (subprocess.TimeoutExpired, OSError):
            continue
        if proc.returncode == 0:
            try:
                return json.loads(proc.stdout)
            except json.JSONDecodeError:
                continue
    return None


def _pair(e):
    """Wpis obiektu AST: v1 = {"key": t, "value": t}; v0-compatible = [k, v].
    Zwróć (key_term, value_term) albo (None, None)."""
    if isinstance(e, dict):
        return e.get("key"), e.get("value")
    if isinstance(e, list) and len(e) == 2:
        return e[0], e[1]
    return None, None


def _object_entries(term):
    """Wpisy terminu obiektowego: v1 = term['exprs'], v0-compat = term['value']."""
    entries = term.get("exprs")
    if entries is None:
        entries = term.get("value")
    return entries or []


def _has_decision_contract(term, depth=0) -> bool:
    """Czy termin zawiera kontrakt decyzji (matched/decision_mode/_routing)?
    Katalogi metadanych (description/domain) — nie zasady — są pomijane."""
    if depth > 8 or not isinstance(term, dict):
        return False
    if term.get("type") == "string":
        return str(term.get("value", "")) in ("matched", "decision_mode", "_routing")
    if term.get("type") == "object":
        for e in _object_entries(term):
            k, v = _pair(e)
            if _has_decision_contract(k, depth + 1):
                return True
            if _has_decision_contract(v, depth + 1):
                return True
    return False


def _raw_scan(term) -> str:
    try:
        return json.dumps(term)
    except Exception:
        return ""


def _find_string_field(term, field: str, depth=0) -> str | None:
    """Rekurencyjny walker AST: wartość string pola o kluczu `field`
    (np. decision_mode / valid_from). Obsługuje oba kształty AST (v0/v1)."""
    if depth > 12 or not isinstance(term, dict):
        return None
    if term.get("type") == "object":
        for e in _object_entries(term):
            k, v = _pair(e)
            if (isinstance(k, dict) and k.get("type") == "string"
                    and str(k.get("value")) == field
                    and isinstance(v, dict) and v.get("type") == "string"):
                return str(v.get("value"))
            for sub in (k, v):
                r = _find_string_field(sub, field, depth + 1)
                if r is not None:
                    return r
    elif term.get("type") == "array":
        for el in term.get("elements") or []:
            r = _find_string_field(el, field, depth + 1)
            if r is not None:
                return r
    return None


def _mode_of(term) -> str | None:
    return _find_string_field(term, "decision_mode")


def _vf_of(term) -> str | None:
    return _find_string_field(term, "valid_from")


def extract_units(ast: dict, rel: str) -> list[dict]:
    """Jednostki semantyczne:
      * reguły skalarne (decision blocks) — fp = hash(body)+hash(value),
      * reguły obiektowe (katalogi) — PO WPISIE: fp = hash(body)+hash(member),
        wyłącznie gdy wpis ma kontrakt decyzji (katalogi metadanych bez
        kontraktu pomijane — to inwentarz, nie zasady AP04)."""
    units: list[dict] = []
    for rule in ast.get("rules", []):
        if _body_is_trivial(rule.get("body", [])):
            continue
        body_h = _hash(mask_term(rule.get("body", [])))
        head = rule.get("head", {})
        value = head.get("value") or head.get("key")
        if value is None:
            continue
        if isinstance(value, dict) and value.get("type") == "object":
            if not _has_decision_contract(value):
                continue  # katalog metadanych — nie zasada prawna
            for e in _object_entries(value):
                key_t, mem_val = _pair(e)
                if not isinstance(key_t, dict) or key_t.get("type") != "string":
                    continue
                rid = str(key_t.get("value", ""))
                if not rid.startswith("jdg."):
                    continue
                units.append({
                    "rule_id": rid, "file": rel,
                    "fp": f"{body_h}:{_hash(mask_term(mem_val))}",
                    "decision_mode": _mode_of(mem_val),
                    "valid_from": _vf_of(mem_val),
                })
            continue
        ids: list[str] = []
        collect_jdg_strings(value, ids)
        value_h = _hash(mask_term(value))
        if ids:
            # reguła decyzyjna: jedna jednostka na unikalne rule_id w skutku
            seen: set[str] = set()
            for rid in ids:
                if rid in seen:
                    continue
                seen.add(rid)
                units.append({
                    "rule_id": rid, "file": rel,
                    "fp": f"{body_h}:{value_h}",
                    "decision_mode": _mode_of(value),
                    "valid_from": _vf_of(value),
                })
        else:
            units.append({
                "rule_id": f"(anon:{head.get('name', '?')}@{rel})",
                "file": rel, "fp": f"{body_h}:{value_h}", "anon": True,
            })
    return units


def _parse_one(args):
    """Worker puli: (rel, path) → (rel, ast|None) + sample błędu."""
    rel, path = args
    ast = parse_file(path)
    err = None
    if ast is None:
        try:
            proc = subprocess.run([str(OPA), "parse", str(path)],
                                  capture_output=True, text=True, timeout=30)
            msg = (proc.stderr or "").strip().splitlines()
            err = msg[0][:120] if msg else "unknown"
        except (subprocess.TimeoutExpired, OSError):
            err = "timeout/os-error"
    return rel, ast, err


def main() -> int:
    files = walk_rego(RULES_DIR)
    all_units: list[dict] = []
    parse_errors = 0
    parse_error_files: list[str] = []
    error_kinds: dict[str, int] = defaultdict(int)
    items = sorted(files.items())
    with ProcessPoolExecutor(max_workers=8) as pool:
        for rel, ast, err in pool.map(_parse_one, items):
            if ast is None:
                parse_errors += 1
                parse_error_files.append(rel)
                if err:
                    error_kinds[err] += 1
                continue
            all_units.extend(extract_units(ast, rel))

    by_fp: dict[str, list[dict]] = defaultdict(list)
    total_rules = 0
    for u in all_units:
        if u.get("anon"):
            continue
        total_rules += 1
        by_fp[u["fp"]].append(u)

    duplicate_pairs, contradictory, temporal_variants = [], [], []
    for fp, group in by_fp.items():
        if len(group) < 2:
            continue
        for i in range(len(group)):
            for j in range(i + 1, len(group)):
                a, b = group[i], group[j]
                if a["rule_id"] == b["rule_id"]:
                    continue
                if a["rule_id"].endswith(BOILERPLATE_TAIL) or b["rule_id"].endswith(BOILERPLATE_TAIL):
                    continue
                # kontener-nadzorca vs człon (prefiks) = przestrzeń nazw,
                # nie duplikat zasady (AP04 dotyczy ZASAD)
                if a["rule_id"].startswith(b["rule_id"]) or b["rule_id"].startswith(a["rule_id"]):
                    continue
                # tylko jednostki z kontraktem decyzji (tryb znany po obu
                # stronach) — inwentarz bez decision_mode poza AP04
                ma, mb = a.get("decision_mode"), b.get("decision_mode")
                if not (ma and mb):
                    continue
                pair = {
                    "a": {"rule_id": a["rule_id"], "file": a["file"],
                          "decision_mode": ma, "valid_from": a.get("valid_from")},
                    "b": {"rule_id": b["rule_id"], "file": b["file"],
                          "decision_mode": mb, "valid_from": b.get("valid_from")},
                    "fp": fp,
                }
                # I02: różny tryb decyzji w identycznej zasadzie = sprzeczność
                if ma != mb:
                    pair["contradictory"] = True
                    contradictory.append(pair)
                # I10: różne valid_from = wariant temporalny (overlay, nie scalanie)
                elif a.get("valid_from") and b.get("valid_from") \
                        and a["valid_from"] != b["valid_from"]:
                    pair["class"] = "temporal_variant"
                    temporal_variants.append(pair)
                else:
                    pair["class"] = "semantic_duplicate"
                    duplicate_pairs.append(pair)

    dup_rules = len({p["a"]["rule_id"] for p in duplicate_pairs}
                    | {p["b"]["rule_id"] for p in duplicate_pairs})
    burden = round(dup_rules * 100.0 / total_rules, 4) if total_rules else 0.0

    metrics = {
        "rules_total": total_rules,
        "parse_errors": parse_errors,
        "duplicate_pairs": len(duplicate_pairs),
        "contradictory_pairs": len(contradictory),
        "temporal_variant_pairs": len(temporal_variants),
        "duplicate_rules": dup_rules,
        "burden_pct": burden,
        "method": "opa-parse-ast (hash warunków+skutku, stringi maskowane)",
        "routing": ("BLOCK_AND_ALERT" if contradictory
                    else ("TRIAGE_QUEUE" if duplicate_pairs else "AUTO_FILE")),
    }
    evidence = {
        "duplicate_pairs_sample": duplicate_pairs[:60],
        "contradictory_pairs": contradictory[:40],
        "temporal_variants_sample": temporal_variants[:40],
        "parse_error_files_sample": parse_error_files[:80],
        "parse_error_kinds": dict(sorted(error_kinds.items(),
                                         key=lambda kv: -kv[1])[:12]),
        "note": ("I01: hash (body+value) z OPA AST (fallback opa19 --v0-"
                 "compatible dla dialektu v1); stringi maskowane — tożsamość "
                 "(rule_id/package) nie różnicuje, więc identyczna zasada pod "
                 "różnymi rule_id = duplikat. Reguły o pustym body (wpisy "
                 "katalogów metadanych) i boierplate defaultów pominięte — "
                 "to nie są zasady prawne (AP04). I02: różny decision_mode "
                 "w grupie = sprzeczność (BLOCK). Temporalne warianty → "
                 "overlay I10. Baseline = backlog jawny."),
        "scanned_at": utcnow_iso(),
    }
    write_p50_bundle("semantic_duplicates", "V3-P50-I01+I02+I12", metrics, evidence)
    print(f"[V3-P50-I01] rules={total_rules} parse_errors={parse_errors} "
          f"dup_pairs={len(duplicate_pairs)} contradictions={len(contradictory)} "
          f"burden={burden}%")
    if parse_errors:
        print(f"[V3-P50-I01][BACKLOG] {parse_errors} plików poza analizą AST "
              f"(parse error — rejestr w evidence.parse_error_files_sample)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
