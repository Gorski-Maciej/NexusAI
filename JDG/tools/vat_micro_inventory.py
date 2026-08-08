#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — VAT MICRO INVENTORY (P05 GLM52 — atomowe reguły per artykuł)
═══════════════════════════════════════════════════════════════════════════════
Micro-mesh audit tool dla warstwy micro VAT:

  [1] mapa atomowa   — ARTYKUŁ × rule_id × plik × status (COMPLETE/PARTIAL/STUB)
  [2] duplikaty      — rule_id powtórzone w warstwie VAT micro (MANIFEST: 369)
  [3] stuby/szkielety— matched:false, CHECKPOINT-STUB, „Punkt kontrolny", puste treści
  [4] zero-hardcode  — literały liczbowe w regułach (stawki, limity, terminy)
  [5] temporalność   — reguły z valid_from/valid_to
  [6] else-chain     — reguły z else (First-Match-Wins) / tautologie

Użycie:  python3 tools/vat_micro_inventory.py [--json bundles/vat_micro_inventory.json] [--gate-stubs N]
Wyście:  raport tekstowy + opcjonalny JSON (do CI / raportu P05).
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES = JDG_ROOT / "rules"

# Warstwa micro VAT — pliki źródłowe prawdy (P05)
VAT_MICRO_FILES = [
    "micro/vat/vat.rego",
    "micro/plan33_vat.rego",
    "micro/plan34_vat.rego",
    "micro/vat/ksef_micro.rego",
    "micro/vat/margin_scheme_micro.rego",
    "micro/vat/place_of_supply_micro.rego",
    "micro/vat/proportion_vat.rego",
    "micro/vat/wdt_export_import.rego",
    "p03_vat_micro_innovations_v8.rego",
    "p04_vat_micro_innovations_v9.rego",
]

RULE_ID_RE = re.compile(r'rule_id"\s*:\s*"([^"]+)"')
ARTICLE_RE = re.compile(r"Art\.\s*(\d+[a-z]?(?:\s*ust\.\s*\d+[a-z]?)?)", re.IGNORECASE)
# Liczby TYLKO poza literałami string (usuń "..." i komentarze przed dopasowaniem)
STRING_LITERAL_RE = re.compile(r'"[^"]*"')
NUMBER_RE = re.compile(r"(?<![\w\"])(\d{2,})(?![\w\"])")
CHECKPOINT_MARKERS = ["CHECKPOINT-STUB", "Punkt kontrolny"]
# Uwaga: `default decide` z matched:false to POPRAWNE reguły no_match — NIE stuby
STUB_MARKERS = ["matched\":false", "STUB", "TODO", "FIXME"]
# Wykluczenia opisów: linie zawierające te tokeny NIE są stubami
STUB_EXCLUDE_TOKENS = ["\"innovation\""]
ELSE_RE = re.compile(r"^\s*else(?:\s*:=\s*[^{]+)?\s*\{", re.MULTILINE)
# Tautologie: { true } NIE poprzedzone else (catch-all jest DOZWOLONY)
TAUTOLOGY_RE = re.compile(r"\{\s*true\s*\}")
EMPTY_BODY_RE = re.compile(r"\{\s*\}")


def _count_tautologies(text: str) -> int:
    """Liczba { true } NIE będących catch-all (nie poprzedzone else :=)."""
    n = 0
    for m in TAUTOLOGY_RE.finditer(text):
        prefix = text[max(0, m.start() - 40):m.start()]
        if "else :=" in prefix or "} else" in prefix:
            continue  # catch-all — dozwolony wzorzec
        n += 1
    return n

# 30 kluczowych artykułów wg promptu P05 (sekcja 5 audytu zgodności)
KEY_ARTICLES_30 = ["5", "7", "8", "15", "17", "19a", "20", "21", "28b", "29a",
                   "41", "43", "86", "86a", "87", "88", "89a", "89b", "90", "91",
                   "96", "99", "103", "106a", "106e", "106i", "106n", "108a",
                   "113", "120"]


def _base_article(a: str) -> str:
    """'86a ust. 1' → '86a' (odcina sufiksy ust./pkt)."""
    return a.split(" ust.")[0].strip()


def scan_file(path: Path) -> dict:
    """Skan pojedynczego pliku Rego: reguły, art., liczby, temporalność, else."""
    text = path.read_text(encoding="utf-8", errors="replace")
    rule_ids = RULE_ID_RE.findall(text)
    articles = sorted(set(ARTICLE_RE.findall(text)))
    # Temporalność
    temporal = bool(re.search(r"valid_from|valid_to|temporal", text, re.IGNORECASE))
    else_chains = len(ELSE_RE.findall(text))
    # Stuby — PRAWDZIWE (puste/tautologiczne ciała reguł) vs komentarze-dokumentacja
    stubs = []          # prawdziwe stuby (w ciele reguły)
    checkpoint_notes = 0  # komentarze „Punkt kontrolny" (mapa pokrycia — NIE stuby)
    for i, ln in enumerate(text.splitlines(), 1):
        stripped = ln.strip()
        if any(m in stripped for m in CHECKPOINT_MARKERS) and stripped.startswith("#"):
            checkpoint_notes += 1
            continue
        if stripped.startswith("default decide") or stripped.startswith("#"):
            continue  # default no_match / komentarze — NIE stuby
        if '"innovation"' in stripped:
            continue  # opis innowacji (np. INN01_STUB_DETECTOR) — NIE stub
        # prawdziwy stub: linia reguły (nie komentarz) z markerem stub
        if any(m in stripped for m in STUB_MARKERS):
            stubs.append((i, stripped[:120]))
    # tautologie { true } i puste ciała { } poza komentarzami (heurystyka)
    tautologies = _count_tautologies(text)
    empty_bodies = len(EMPTY_BODY_RE.findall(text))
    # Hardcode — liczby ≥ 2 cyfry poza komentarzami I POZA LITERAŁAMI STRING
    # (wyklucza daty/rule_id w "..." — zero szumu)
    hardcoded = Counter()
    for ln in text.splitlines():
        s = STRING_LITERAL_RE.sub("\"\"", ln.split("#")[0])
        if "rule_id" in s or "priority" in s or "threshold" in s:
            continue
        for num in NUMBER_RE.findall(s):
            hardcoded[num] += 1
    return {
        "file": str(path.relative_to(JDG_ROOT)),
        "size_bytes": path.stat().st_size,
        "rule_ids": rule_ids,
        "rule_count": len(rule_ids),
        "unique_rule_ids": len(set(rule_ids)),
        "articles": articles,
        "article_count": len(articles),
        "temporal": temporal,
        "else_chains": else_chains,
        "stubs": stubs,
        "checkpoint_notes": checkpoint_notes,
        "tautologies": tautologies,
        "empty_bodies": empty_bodies,
        "hardcoded": dict(hardcoded.most_common(25)),
    }


def scan_all() -> dict:
    files = []
    all_ids = []
    stub_files = []
    article_sets = {}  # plik -> set artykułów (bazowych)
    for rel in VAT_MICRO_FILES:
        p = RULES / rel
        if not p.exists():
            files.append({"file": rel, "error": "BRAK PLIKU"})
            continue
        info = scan_file(p)
        files.append(info)
        all_ids.extend(info["rule_ids"])
        article_sets[rel] = {_base_article(a) for a in info["articles"]}
        if info["stubs"]:
            stub_files.append({"file": rel, "stubs": len(info["stubs"])})

    id_counter = Counter(all_ids)
    duplicates = {rid: c for rid, c in id_counter.items() if c > 1}

    # Mapa pokrycia dla 30 kluczowych artykułów (P05-INN-04/09):
    #   COMPLETE — w vat.rego lub dedykowanym pliku micro
    #   PARTIAL  — tylko w plan33/plan34/inn (uzupełniające)
    #   MISSING  — brak
    core = article_sets.get("micro/vat/vat.rego", set())
    dedicated = set()
    for rel in ["micro/vat/ksef_micro.rego", "micro/vat/margin_scheme_micro.rego",
                "micro/vat/place_of_supply_micro.rego", "micro/vat/proportion_vat.rego",
                "micro/vat/wdt_export_import.rego"]:
        dedicated |= article_sets.get(rel, set())
    supplementary = set()
    for rel in ["micro/plan33_vat.rego", "micro/plan34_vat.rego",
                "p03_vat_micro_innovations_v8.rego", "p04_vat_micro_innovations_v9.rego"]:
        supplementary |= article_sets.get(rel, set())

    coverage = {}
    for art in KEY_ARTICLES_30:
        if art in core or art in dedicated:
            coverage[art] = "COMPLETE"
        elif art in supplementary:
            coverage[art] = "PARTIAL"
        else:
            coverage[art] = "MISSING"

    return {
        "files": files,
        "total_rules": len(all_ids),
        "unique_rules": len(set(all_ids)),
        "duplicate_ids": duplicates,
        "duplicate_count": sum(1 for c in duplicates.values() if c > 1),
        "stub_files": stub_files,
        "total_stubs": sum(len(f["stubs"]) for f in files if "stubs" in f),
        "total_checkpoints": sum(f.get("checkpoint_notes", 0) for f in files),
        "total_tautologies": sum(f.get("tautologies", 0) for f in files),
        "total_else_chains": sum(f.get("else_chains", 0) for f in files if "else_chains" in f),
        "coverage": coverage,
    }


def render_text(report: dict) -> str:
    lines = []
    lines.append("=" * 78)
    lines.append(" VAT MICRO INVENTORY — P05 GLM52 (atomowe reguły per artykuł)")
    lines.append("=" * 78)
    lines.append("")
    for f in report["files"]:
        if "error" in f:
            lines.append(f"  [BRAK] {f['file']}")
            continue
        lines.append(f"  {f['file']}")
    lines.append(f"    reguły: {f['rule_count']} (unikalne: {f['unique_rule_ids']}) | "
                 f"artykuły: {f['article_count']} | else-chain: {f['else_chains']} | "
                 f"temporalność: {'TAK' if f['temporal'] else 'NIE'} | "
                 f"stuby: {len(f['stubs'])} | tautologie: {f.get('tautologies', 0)}")
    lines.append("")
    lines.append(f"  SUMA: {report['total_rules']} reguł, {report['unique_rules']} unikalnych, "
                 f"{report['duplicate_count']} duplikatów rule_id, {report['total_stubs']} stubów, "
                 f"{report['total_checkpoints']} markerów „Punkt kontrolny\" (komentarze), "
                 f"{report['total_tautologies']} tautologii (catch-all wykluczone)")
    cov = report.get("coverage", {})
    if cov:
        comp = [a for a, s in cov.items() if s == "COMPLETE"]
        part = [a for a, s in cov.items() if s == "PARTIAL"]
        miss = [a for a, s in cov.items() if s == "MISSING"]
        lines.append(f"  POKRYCIE 30 KLUCZOWYCH ARTYKUŁÓW: COMPLETE {len(comp)} | "
                     f"PARTIAL {len(part)} | MISSING {len(miss)}")
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
    # Top hardcoded
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
    ap = argparse.ArgumentParser(description="VAT micro inventory (P05)")
    ap.add_argument("--json", default="", help="Zapisz raport JSON")
    ap.add_argument("--gate-stubs", type=int, default=0,
                    help="Bramka CI: exit 1 gdy liczba stubów > N")
    args = ap.parse_args()

    report = scan_all()
    text = render_text(report)
    print(text)

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
