#!/usr/bin/env python3
"""NexusAI JDG — V3-P48 COMMON — wspólny szkielet narzędzi synchronizacji mirror
policies (zero dryfu canonical↔mirror).

Konwencje (honoruje kontrakty P45/P46/P47/P39/P37):
  * każdy silnik I01–I12 pisze JEDEN bundle: bundles/v3_p48_<nazwa>.json,
  * bundle: {"innovation": "V3-P48-Ixx", "generated_at": ISO-8601 UTC,
             "gate": "PASS", "metrics": {...}, "evidence": {...}},
  * gate=PASS oznacza: narzędzie URUCHOMIONE i dowód ZAPISANY (spójny),
    nie "zero problemów" — decyzja TRIAGE/BLOCK jest w metrics.routing,
  * liczniki z realnych plików repozytorium (honesty: zero fantazji liczb);
    dryf mierzony na żywo z JDG/rules/ vs policies/ (jedno źródło prawdy P00).
"""
from __future__ import annotations

import hashlib
import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]
RULES_DIR = BASE / "rules"
BUNDLES_DIR = BASE / "bundles"
DOCS_DIR = BASE / "docs"
REPO_ROOT = BASE.parent
POLICIES_DIR = REPO_ROOT / "policies"  # mirror na poziomie repo (NexusAI/policies)

P47_MEDIATION = BUNDLES_DIR / "v3_p47_mediation_tickets.json"
P45_MIGRATION_LEDGER = BUNDLES_DIR / "v3_p45_migration_ledger.json"
P46_REGISTRY = BUNDLES_DIR / "v3_p46_parameter_registry.json"
THRESHOLDS_REGO = RULES_DIR / "thresholds_jdg.rego"
P48_REGO = RULES_DIR / "v3_p48_mirror_sync.rego"
P48_RULE = "jdg.v3_p48_mirror_sync"
SYNC_MANIFEST = POLICIES_DIR / ".sync_manifest_v2.json"

# Rejestry lifecycle/deploy (jedno źródło prawdy; P48 rozszerza, nie duplikuje)
RULE_REGISTRY = BUNDLES_DIR / "rule_registry.json"
DEPLOYMENTS = BUNDLES_DIR / "deployments.json"
GOLDEN_VERDICTS = BUNDLES_DIR / "golden_verdicts.json"


def utcnow_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def read_json(path: Path, default=None):
    if not path.exists():
        return default
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return default


def write_json(path: Path, data) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n",
                    encoding="utf-8")


def write_bundle(name: str, innovation: str, metrics: dict, evidence: dict) -> Path:
    """Zapisz bundle dowodowy v3_p48_<name>.json z gate=PASS (dowód zapisany)."""
    bundle = {
        "innovation": innovation,
        "generated_at": utcnow_iso(),
        "gate": "PASS",
        "metrics": metrics,
        "evidence": evidence,
    }
    out = BUNDLES_DIR / f"v3_p48_{name}.json"
    write_json(out, bundle)
    return out


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def strip_comments_and_blank(source: str) -> str:
    """Usuń komentarze # (poza stringami) i puste linie — normalizacja tekstowa.

    Wynik porównujemy per plik: identyczny = różnica wyłącznie kosmetyczna
    (komentarze/nagłówki), różny = kandydat dryfu semantycznego (potwierdzany
    przez porównanie deklaracji i przypisań rego).
    """
    out_lines = []
    for line in source.splitlines():
        res = []
        instr = False
        esc = False
        for ch in line:
            if instr:
                res.append(ch)
                if esc:
                    esc = False
                elif ch == "\\":
                    esc = True
                elif ch == '"':
                    instr = False
            elif ch == '"':
                instr = True
                res.append(ch)
            elif ch == "#":
                break
            else:
                res.append(ch)
        stripped = "".join(res).strip()
        if stripped:
            out_lines.append(stripped)
    return "\n".join(out_lines)


DECL_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*(?::=|=)\s*", re.MULTILINE)
RULE_ID_RE = re.compile(r'"rule_id"\s*[:=]\s*"([^"]+)"')
_STRING_LIT_RE = re.compile(r'"(?:[^"\\]|\\.)*"')


def decl_names(source: str) -> set[str]:
    return set(DECL_RE.findall(strip_comments_and_blank(source)))


def semantic_fingerprint(source: str) -> str:
    """Odcisk semantyczny: kod bez komentarzy/pustych linii, treść literałów
    string zmaskowana (komunikaty nie są semantyką), wartości liczbowe
    zachowane (zmiana progu/stawki = dryf semantyczny).

    To nie jest pełny parser AST Rego (OPA niedostępny w środowisku — konwencja
    R21/P47: kontrola strukturalna zamiast opa check), ale wyłapuje realny dryf:
    dodane/usunięte deklaracje, zmienione warunki i progi. Zmiana wyłącznie
    komentarzy/nagłówków nie zmienia odcisku (dryf tekstowy, dozwolony I02).
    """
    body = strip_comments_and_blank(source)
    body = _STRING_LIT_RE.sub('"§"', body)
    return "\n".join(ln.strip() for ln in body.splitlines() if ln.strip())

# kompatybilność nazw (narzędzia I02/bramka)
semantic_signature = decl_names


def walk_rego(directory: Path) -> dict[str, Path]:
    if not directory.exists():
        return {}
    return {str(p.relative_to(directory)): p
            for p in sorted(directory.rglob("*.rego"))}


def measure_drift() -> dict:
    """Pomiar dryfu canonical (JDG/rules) vs mirror (policies/).

    Kategorie (prompt P48 5.1 / kryterium 19):
      identical        — SHA-256 identyczne,
      textual_diffs    — treść różna, sygnatury semantyczne identyczne
                         (komentarze/nagłówki),
      semantic_diffs   — sygnatury semantyczne różne (realny dryf),
      only_rules       — pliki tylko w canonical (mirror zalega),
      only_policies    — pliki tylko w mirror (osierocone legacy).
    """
    rules = walk_rego(RULES_DIR)
    policies = walk_rego(POLICIES_DIR)
    common = set(rules) & set(policies)
    identical, textual, semantic = [], [], []
    for rel in sorted(common):
        a = rules[rel].read_text(encoding="utf-8", errors="replace")
        b = policies[rel].read_text(encoding="utf-8", errors="replace")
        if sha256(rules[rel]) == sha256(policies[rel]):
            identical.append(rel)
            continue
        if semantic_fingerprint(a) == semantic_fingerprint(b):
            textual.append(rel)
        else:
            semantic.append(rel)
    only_rules = sorted(set(rules) - set(policies))
    only_policies = sorted(set(policies) - set(rules))
    total = len(rules)
    drift_abs = len(textual) + len(semantic) + len(only_rules)
    return {
        "rules_files": total,
        "policies_files": len(policies),
        "common": len(common),
        "identical": identical,
        "textual_diffs": textual,
        "semantic_diffs": semantic,
        "only_rules": only_rules,
        "only_policies": only_policies,
        "drift_files": drift_abs,
        "drift_pct": round(drift_abs / total * 100.0, 2) if total else 0.0,
    }


def drift_by_package(drift: dict) -> dict[str, dict]:
    """Rozbicie dryfu per pakiet (pierwszy poziom katalogu; korzeń = '(root)')."""
    packages: dict[str, dict] = {}
    all_files = (drift["identical"] + drift["textual_diffs"]
                 + drift["semantic_diffs"] + drift["only_rules"])
    for rel in all_files:
        pkg = rel.split("/", 1)[0] if "/" in rel else "(root)"
        d = packages.setdefault(pkg, {"total": 0, "clean": 0, "textual": 0,
                                      "semantic": 0, "missing": 0})
        d["total"] += 1
        if rel in drift["identical"]:
            d["clean"] += 1
        elif rel in drift["textual_diffs"]:
            d["textual"] += 1
        elif rel in drift["semantic_diffs"]:
            d["semantic"] += 1
        else:
            d["missing"] += 1
    # pakiety osierocone (tylko w mirror) — bez odpowiednika w canonical
    for rel in drift["only_policies"]:
        pkg = rel.split("/", 1)[0] if "/" in rel else "(root)"
        d = packages.setdefault(pkg, {"total": 0, "clean": 0, "textual": 0,
                                      "semantic": 0, "missing": 0})
        d["orphan"] = d.get("orphan", 0) + 1
    # drift_pct liczony PO dodaniu osieroconych (każdy pakiet ma pełny zestaw kluczy)
    for d in packages.values():
        dirty = d["textual"] + d["semantic"] + d["missing"]
        total = d["total"] or d.get("orphan", 0)
        d["drift_pct"] = round(100.0 * dirty / total, 2) if total else 0.0
        if d["total"] == 0:
            d["drift_pct"] = 100.0  # pakiet wyłącznie osierocony = pełny dryf
    return dict(sorted(packages.items()))


def extract_threshold_block(block_name: str) -> str | None:
    """Wydziel blok <nazwa> := { ... } z thresholds_jdg.rego (konwencja P46/P47)."""
    if not THRESHOLDS_REGO.exists():
        return None
    src = THRESHOLDS_REGO.read_text(encoding="utf-8", errors="replace")
    m = re.search(rf"^{block_name}\s*:=\s*\{{", src, re.MULTILINE)
    if not m:
        return None
    start = m.end() - 1
    depth = 0
    instr = False
    esc = False
    i = start
    while i < len(src):
        c = src[i]
        if instr:
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                instr = False
        elif c == '"':
            instr = True
        elif c == "#":
            j = src.find("\n", i)
            i = j if j != -1 else len(src)
            continue
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return src[start:i + 1]
        i += 1
    return None


def rule_present(rule_id: str) -> bool:
    if not P48_REGO.exists():
        return False
    return rule_id in P48_REGO.read_text(encoding="utf-8", errors="replace")


def sync_manifest_age_days() -> tuple[bool, float | None]:
    """Wiek manifestu synchronizacji mirror (dni) — I01."""
    meta = read_json(SYNC_MANIFEST)
    if not meta or not meta.get("last_sync"):
        return False, None
    try:
        last = datetime.fromisoformat(str(meta["last_sync"]))
        age = (datetime.now(timezone.utc) - last.astimezone(timezone.utc)).total_seconds() / 86400.0
        return True, round(age, 2)
    except ValueError:
        return False, None
