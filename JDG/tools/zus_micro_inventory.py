#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — ZUS MICRO INVENTORY (P08 GLM52 — ZUS + zdrowotna + zasiłki)
═══════════════════════════════════════════════════════════════════════════════
Micro-mesh audit tool dla warstwy micro ZUS:

  [1] mapa atomowa   — ARTYKUŁ × rule_id × plik × status (COMPLETE/PARTIAL/STUB)
  [2] duplikaty      — rule_id powtórzone w warstwie ZUS micro
  [3] stuby/szkielety— matched:false, CHECKPOINT-STUB, „Punkt kontrolny", puste treści
  [4] zero-hardcode  — literały liczbowe w regułach (stawki, limity, terminy)
  [5] temporalność   — reguły z valid_from/valid_to
  [6] else-chain     — reguły z else (First-Match-Wins) / tautologie
  [7] AUDYT ZDROWOTNEJ — progi TIER 1/2/3 i stawki 9%/4.9% w plikach micro

Użycie:  python3 tools/zus_micro_inventory.py [--json bundles/zus_micro_inventory.json] [--gate-stubs N]
Wyście:  raport tekstowy + opcjonalny JSON (do CI / raportu P08).
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES = JDG_ROOT / "rules"

# Warstwa micro ZUS — pliki źródłowe prawdy (P09: konsolidacja plan33/34↔sus,
# usunięcie stubów sus_a*/zdrowotna_a*/zasilkowa_a* — zero duplikatów, INV-018)
ZUS_MICRO_FILES = [
    "micro/sus/sus.rego",
    "micro/zdrowotna/zdrowotna.rego",
    "micro/zasilkowa/zasilkowa.rego",
    "micro/plan33_zus.rego",
    "micro/_zus_micro_rates.rego",
    "micro/zus_micro_atomic_p09.rego",
    "p07_zus_macro_innovations_v9.rego",
    "p08_zus_micro_innovations_v9.rego",
]

# Dedicated files (głęboka warstwa: sus/zdrowotna/zasilkowa + innowacje)
DEDICATED_FILES = [
    "micro/sus/sus.rego",
    "micro/zdrowotna/zdrowotna.rego",
    "micro/zasilkowa/zasilkowa.rego",
    "micro/_zus_micro_rates.rego",
    "micro/zus_micro_atomic_p09.rego",
    "p07_zus_macro_innovations_v9.rego",
    "p08_zus_micro_innovations_v9.rego",
]

RULE_ID_RE = re.compile(r'rule_id"\s*:\s*"([^"]+)"')
MICRO_ID_RE = re.compile(r"#\s*(jdg\.micro\.[a-z0-9_.]+)")
ARTICLE_RE_FULL = re.compile(r"Art\.\s*(\d+[a-z]{0,2})", re.IGNORECASE)
STRING_LITERAL_RE = re.compile(r'"[^"]*"')
NUMBER_RE = re.compile(r"(?<![\\w\"])(\\d{2,})(?![\\w\"])")
CHECKPOINT_MARKERS = ["CHECKPOINT-STUB", "Punkt kontrolny"]
STUB_MARKERS = ["matched\":false", "STUB", "TODO", "FIXME"]
STUB_EXCLUDE_TOKENS = ["\"innovation\"", "STUB_DETECTOR", "STUB_GUARD"]
ELSE_RE = re.compile(r"^\s*else(?:\s*:=\s*[^{]+)?\s*\{", re.MULTILINE)
TAUTOLOGY_RE = re.compile(r"\{\s*true\s*\}")
EMPTY_BODY_RE = re.compile(r"\{\s*\}")

# Kluczowe artykuły ZUS wg promptu P08 (sekcja 2)
KEY_ARTICLES_ZUS = [
    # SUS
    "6", "6a", "6b", "9", "11", "13", "14", "18", "18a", "18c",
    "19", "22", "24", "36", "40", "47",
    # Zdrowotna (ustawa o świadczeniach opieki zdrowotnej)
    "79", "81", "81b", "81c", "81d", "82",
    # Zasiłkowa
    "19", "29", "32", "33",
]

# Kluczowe progi zdrowotne do weryfikacji w plikach (P08 sekcja 3)
HEALTH_TIERS = {
    "tier_1_limit": 60000,
    "tier_2_limit": 300000,
    "tier_1_multiplier": 0.60,
    "tier_2_multiplier": 1.00,
    "tier_3_multiplier": 1.80,
    "scale_rate": 0.09,
    "linear_rate": 0.049,
}


def _base_article(a: str) -> str:
    return a.split(" ust.")[0].strip().lower()

# Artykuł z nazwy pliku: sus_a18c.rego → "18c", zdrowotna_a81b.rego → "81b"
FILE_ARTICLE_RE = re.compile(r"(?:sus|zdrowotna|zasilkowa)_a(\d+[a-z]{0,2})\.rego$")


def scan_file(path: Path) -> dict:
    text = path.read_text(encoding="utf-8", errors="replace")
    rule_ids = RULE_ID_RE.findall(text)
    micro_ids = MICRO_ID_RE.findall(text)
    articles = sorted({_base_article(a) for a in ARTICLE_RE_FULL.findall(text)})
    # Artykuły z nazwy pliku (per-art pliki micro nie mają „Art. X" w tekście)
    fm = FILE_ARTICLE_RE.search(path.name)
    if fm:
        articles.append(fm.group(1))
    articles = sorted(set(articles))
    temporal = bool(re.search(r"valid_from|valid_to|temporal", text, re.IGNORECASE))
    else_chains = len(ELSE_RE.findall(text))

    stubs = []
    checkpoint_notes = 0
    for i, ln in enumerate(text.splitlines(), 1):
        stripped = ln.strip()
        if any(m in stripped for m in CHECKPOINT_MARKERS) and stripped.startswith("#"):
            checkpoint_notes += 1
            continue
        if stripped.startswith("default decide") or stripped.startswith("#"):
            continue
        if any(t in stripped for t in STUB_EXCLUDE_TOKENS):
            continue
        if any(m in stripped for m in STUB_MARKERS):
            stubs.append((i, stripped[:120]))

    tautologies = 0
    for m in TAUTOLOGY_RE.finditer(text):
        prefix = text[max(0, m.start() - 40):m.start()]
        if "else :=" in prefix or "} else" in prefix:
            continue
        tautologies += 1

    empty_bodies = len(EMPTY_BODY_RE.findall(text))
    hardcoded = Counter()
    for ln in text.splitlines():
        s = STRING_LITERAL_RE.sub("\"\"", ln.split("#")[0])
        if "rule_id" in s or "priority" in s or "threshold" in s:
            continue
        for num in NUMBER_RE.findall(s):
            hardcoded[num] += 1

    # Audyt zdrowotnej — progi TIER obecne w pliku?
    health_tiers_found = {}
    for tier_key, val in HEALTH_TIERS.items():
        health_tiers_found[tier_key] = any(
            str(val).replace(".", "") in re.sub(r"\s", "", ln.split("#")[0])
            for ln in text.splitlines()
        )

    return {
        "file": str(path.relative_to(JDG_ROOT)),
        "size_bytes": path.stat().st_size,
        "rule_ids": rule_ids,
        "micro_ids": micro_ids,
        "rule_count": len(rule_ids),
        "unique_rule_ids": len(set(rule_ids)),
        "micro_count": len(set(micro_ids)),
        "articles": articles,
        "article_count": len(articles),
        "temporal": temporal,
        "else_chains": else_chains,
        "stubs": stubs,
        "checkpoint_notes": checkpoint_notes,
        "tautologies": tautologies,
        "empty_bodies": empty_bodies,
        "health_tiers_found": health_tiers_found,
        "hardcoded": dict(hardcoded.most_common(25)),
    }


def scan_all() -> dict:
    files = []
    all_ids = []
    stub_files = []
    article_sets = {}
    health_tiers_merged = {}
    for rel in ZUS_MICRO_FILES:
        p = RULES / rel
        if not p.exists():
            files.append({"file": rel, "error": "BRAK PLIKU"})
            continue
        info = scan_file(p)
        files.append(info)
        all_ids.extend(info["rule_ids"])
        article_sets[rel] = set(info["articles"])
        if info["stubs"]:
            stub_files.append({"file": rel, "stubs": len(info["stubs"])})
        for k, v in info.get("health_tiers_found", {}).items():
            health_tiers_merged[k] = health_tiers_merged.get(k, False) or v

    id_counter = Counter(all_ids)
    duplicates = {rid: c for rid, c in id_counter.items()
                  if c > 1 and not rid.endswith(".no_match")}

    core = set()
    dedicated = set()
    for rel in ZUS_MICRO_FILES:
        s = article_sets.get(rel, set())
        if rel in DEDICATED_FILES:
            dedicated |= s
        elif rel.startswith("micro/"):
            core |= s
        else:
            dedicated |= s

    coverage = {}
    for art in KEY_ARTICLES_ZUS:
        if art in core or art in dedicated:
            coverage[art] = "COMPLETE"
        else:
            coverage[art] = "MISSING"

    return {
        "files": files,
        "total_rules": len(all_ids),
        "unique_rules": len(set(all_ids)),
        "duplicate_ids": duplicates,
        "duplicate_count": len(duplicates),
        "stub_files": stub_files,
        "total_stubs": sum(len(f["stubs"]) for f in files if "stubs" in f),
        "total_checkpoints": sum(f.get("checkpoint_notes", 0) for f in files),
        "total_tautologies": sum(f.get("tautologies", 0) for f in files),
        "total_else_chains": sum(f.get("else_chains", 0) for f in files if "else_chains" in f),
        "total_micro_ids": sum(len(set(f.get("micro_ids", []))) for f in files),
        "coverage": coverage,
        "health_tiers": health_tiers_merged,
        "health_tier_reference": HEALTH_TIERS,
    }


def render_text(report: dict) -> str:
    lines = []
    lines.append("=" * 78)
    lines.append(" ZUS MICRO INVENTORY — P08 GLM52 (ZUS + zdrowotna + zasiłki)")
    lines.append("=" * 78)
    lines.append("")
    for f in report["files"]:
        if "error" in f:
            lines.append(f"  [BRAK] {f['file']}")
            continue
        lines.append(f"  {f['file']}")
        lines.append(f"    reguły: {f['rule_count']} (unikalne: {f['unique_rule_ids']}) | "
                     f"mapa micro: {f['micro_count']} | artykuły: {f['article_count']} | "
                     f"else-chain: {f['else_chains']} | temporalność: {'TAK' if f['temporal'] else 'NIE'} | "
                     f"stuby: {len(f['stubs'])} | tautologie: {f.get('tautologies', 0)}")
    lines.append("")
    lines.append(f"  SUMA: {report['total_rules']} reguł, {report['unique_rules']} unikalnych, "
                 f"{report['duplicate_count']} duplikatów rule_id, {report['total_stubs']} stubów, "
                 f"{report['total_checkpoints']} markerów „Punkt kontrolny\" (komentarze), "
                 f"{report['total_tautologies']} tautologii (catch-all wykluczone)")
    cov = report.get("coverage", {})
    if cov:
        comp = [a for a, s in cov.items() if s == "COMPLETE"]
        miss = [a for a, s in cov.items() if s == "MISSING"]
        lines.append(f"  POKRYCIE {len(cov)} KLUCZOWYCH ARTYKUŁÓW ZUS: COMPLETE {len(comp)} | "
                     f"MISSING {len(miss)}")
        if miss:
            lines.append(f"    MISSING: {', '.join(miss)}")
    ht = report.get("health_tiers", {})
    if ht:
        missing_tiers = [k for k, v in ht.items() if not v]
        lines.append(f"  AUDYT ZDROWOTNEJ: progi/stawki znalezione w warstwie micro: "
                     f"{len(ht) - len(missing_tiers)}/{len(ht)} | brak: {missing_tiers}")
    lines.append("")
    if report["duplicate_ids"]:
        lines.append("  DUPLIKATY rule_id (do naprawy):")
        for rid, c in sorted(report["duplicate_ids"].items()):
            lines.append(f"    {rid} × {c}")
    lines.append("")
    if report["stub_files"]:
        lines.append("  STUBY wg pliku:")
        for sf in report["stub_files"]:
            lines.append(f"    {sf['file']}: {sf['stubs']}")
    lines.append("")
    lines.append("  TOP-10 HARDCODE (literały liczbowe w regułach):")
    merged = Counter()
    for f in report["files"]:
        if "hardcoded" in f:
            for k, v in f["hardcoded"].items():
                merged[k] += v
    for k, v in merged.most_common(10):
        lines.append(f"    {k} × {v}")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser(description="ZUS micro inventory (P08)")
    ap.add_argument("--json", default="", help="Zapisz raport JSON")
    ap.add_argument("--gate-stubs", type=int, default=0,
                    help="Bramka CI: exit 1 gdy liczba stubów > N")
    args = ap.parse_args()

    report = scan_all()
    print(render_text(report))

    if args.json:
        out = JDG_ROOT / args.json
        out.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"JSON → {out}")

    if args.gate_stubs and report["total_stubs"] > args.gate_stubs:
        print(f"BRAMKA STUBÓW: {report['total_stubs']} > {args.gate_stubs} → BLOKADA", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
