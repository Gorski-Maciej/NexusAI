#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — PIT MICRO INVENTORY (P07 GLM52 — atomowe reguły + amortyzacja)
═══════════════════════════════════════════════════════════════════════════════
Micro-mesh audit tool dla warstwy micro PIT:

  [1] mapa atomowa   — ARTYKUŁ × rule_id × plik × status (COMPLETE/PARTIAL/STUB)
  [2] duplikaty      — rule_id powtórzone w warstwie PIT micro
  [3] stuby/szkielety— matched:false, CHECKPOINT-STUB, „Punkt kontrolny", puste treści
  [4] zero-hardcode  — literały liczbowe w regułach (stawki, limity, terminy)
  [5] temporalność   — reguły z valid_from/valid_to
  [6] else-chain     — reguły z else (First-Match-Wins) / tautologie
  [7] AUDYT KŚT      — stawki amortyzacyjne w pit_a22*.rego vs załącznik KŚT

Użycie:  python3 tools/pit_micro_inventory.py [--json bundles/pit_micro_inventory.json] [--gate-stubs N]
Wyście:  raport tekstowy + opcjonalny JSON (do CI / raportu P07).
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

# Warstwa micro PIT — pliki źródłowe prawdy (P07)
PIT_MICRO_FILES = [
    "micro/pit/pit.rego",
    "micro/plan33_pit.rego",
    "micro/plan34_pit.rego",
    "micro/amortyzacja/pit_a22a.rego",
    "micro/amortyzacja/pit_a22i.rego",
    "micro/amortyzacja/pit_a22k.rego",
    "micro/amortyzacja/pit_a22n.rego",
    "p06_pit_micro_innovations_v8.rego",
    "p06_pit_micro_innovations_v9.rego",
    "p07_pit_micro_atomic_v9.rego",
    "nkup_enterprise_complete.rego",
    "exit_tax_mdr_enterprise.rego",
]

# Dedicated files (głęboka warstwa amortyzacji + NKUP + P07 atomic)
DEDICATED_FILES = [
    "micro/amortyzacja/pit_a22a.rego",
    "micro/amortyzacja/pit_a22i.rego",
    "micro/amortyzacja/pit_a22k.rego",
    "micro/amortyzacja/pit_a22n.rego",
    "p07_pit_micro_atomic_v9.rego",
    "nkup_enterprise_complete.rego",
    "exit_tax_mdr_enterprise.rego",
]

# Uzupełniające (plan33/34 + innowacje)
SUPPLEMENTARY_FILES = [
    "micro/plan33_pit.rego",
    "micro/plan34_pit.rego",
    "p06_pit_micro_innovations_v8.rego",
    "p06_pit_micro_innovations_v9.rego",
]

RULE_ID_RE = re.compile(r'rule_id"\s*:\s*"([^"]+)"')
# Komentarze mapy atomowej pit.rego: # jdg.micro.pit.a21.ust1 ...  lub  # jdg.micro.amort_a22a.r1
MICRO_ID_RE = re.compile(r"#\s*(jdg\.micro\.[a-z0-9_.]+)")
ARTICLE_RE = re.compile(r"Art\.\s*(\d+[a-z]{0,2}(?:[a-z]|(?=\s*ust\.))?)", re.IGNORECASE)
ARTICLE_RE_FULL = re.compile(r"Art\.\s*(\d+[a-z]{0,2})", re.IGNORECASE)
# Liczby TYLKO poza literałami string (usuń "..." i komentarze przed dopasowaniem)
STRING_LITERAL_RE = re.compile(r'"[^"]*"')
NUMBER_RE = re.compile(r"(?<![\\w\"])(\\d{2,})(?![\\w\"])")
CHECKPOINT_MARKERS = ["CHECKPOINT-STUB", "Punkt kontrolny"]
STUB_MARKERS = ["matched\":false", "STUB", "TODO", "FIXME"]
STUB_EXCLUDE_TOKENS = ["\"innovation\"", "STUB_DETECTOR", "STUB_GUARD"]
ELSE_RE = re.compile(r"^\s*else(?:\s*:=\s*[^{]+)?\s*\{", re.MULTILINE)
TAUTOLOGY_RE = re.compile(r"\{\s*true\s*\}")
EMPTY_BODY_RE = re.compile(r"\{\s*\}")

# Kluczowe artykuły PIT wg promptu P07 (sekcja 2 + 5 + 6 + 7)
KEY_ARTICLES_PIT = [
    "10", "14", "21", "22", "22a", "22b", "22c", "22d", "22e", "22f",
    "22g", "22h", "22i", "22j", "22k", "22l", "22m", "22n", "23", "24",
    "24a", "26", "26b", "26e", "26eb", "26gb", "26ec", "26h", "27", "30c",
    "30ca", "30da", "44", "45",
]

# Stawki KŚT wg załącznika do rozporządzenia (grupa → stawka %)
KST_RATES = {
    "1": 1.5, "2": 2.5, "3": 4.5, "4": 4.5, "5": 7.0, "6": 10.0,
    "7": 10.0, "8": 20.0, "9": 20.0, "10": 25.0,
}


def _base_article(a: str) -> str:
    """'22a ust. 1' → '22a' (odcina sufiksy ust./pkt)."""
    return a.split(" ust.")[0].strip().lower()


def scan_file(path: Path) -> dict:
    """Skan pojedynczego pliku Rego: reguły, art., liczby, temporalność, else."""
    text = path.read_text(encoding="utf-8", errors="replace")
    rule_ids = RULE_ID_RE.findall(text)
    # Identyfikatory micro w komentarzach (mapa atomowa pit.rego)
    micro_ids = MICRO_ID_RE.findall(text)
    articles = sorted({_base_article(a) for a in ARTICLE_RE_FULL.findall(text)})
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

    # Poprawka 2026-08-22 (PROMPT_05): odcinamy komentarze i literały stringowe
    # oraz pomijamy domyślne wartości FUNKCJI pomocniczych (np. `else = 0.0`,
    # `max_coeff = 1.4 { true }`) — liczone są wyłącznie tautologie reguł
    # decyzyjnych (najbliższe ':=' bez prefiksu else).
    code_only = re.sub(r"#.*$", "", text, flags=re.M)
    code_only = STRING_LITERAL_RE.sub('""', code_only)
    tautologies = 0
    for m in TAUTOLOGY_RE.finditer(code_only):
        eq = code_only.rfind(":=", 0, m.start())
        head = code_only[max(0, eq - 10):eq] if eq >= 0 else ""
        if "else" in head:
            continue  # legalny catch-all else-chain
        # tautologia decyzyjna tylko gdy blok ma werdykt (matched) —
        # agregacje pomocnicze (np. total_years := ... { true }) NIE są tautologiami
        if "matched" not in code_only[eq:m.start()]:
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
        "hardcoded": dict(hardcoded.most_common(25)),
    }


def audit_kst() -> dict:
    """Audyt stawek KŚT — jakie stawki liczbowe występują w plikach amortyzacji."""
    found = Counter()
    details = {}
    for rel in ["micro/amortyzacja/pit_a22a.rego", "micro/amortyzacja/pit_a22i.rego",
                "micro/amortyzacja/pit_a22k.rego", "micro/amortyzacja/pit_a22n.rego"]:
        p = RULES / rel
        if not p.exists():
            continue
        text = p.read_text(encoding="utf-8", errors="replace")
        # stawki procentowe jak "10" "20" "25" w kontekście amortyzacji
        rates = re.findall(r'"?(\d{1,2}(?:[.,]\d)?)%"?', text)
        rates += re.findall(r"\b(?:rate|stawka|pct)\b[\"']?\s*[:=]\s*[\"']?(\d{1,2}(?:[.,]\d)?)", text, re.IGNORECASE)
        found.update(r for r in rates if float(r.replace(",", ".")) > 0)
        details[rel] = sorted(set(rates))
    missing = [g for g, r in KST_RATES.items() if f"{r:g}" not in found and f"{r:g}%" not in str(details)]
    return {
        "rates_found": dict(found.most_common(15)),
        "kst_reference": KST_RATES,
        "missing_rates": missing,
        "details": details,
    }


def scan_all() -> dict:
    files = []
    all_ids = []
    stub_files = []
    article_sets = {}
    for rel in PIT_MICRO_FILES:
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

    id_counter = Counter(all_ids)
    # `*.no_match` to standardowy `default decide` w KAŻDYM pakiecie — nie duplikat
    duplicates = {rid: c for rid, c in id_counter.items()
                  if c > 1 and not rid.endswith(".no_match")}

    core = article_sets.get("micro/pit/pit.rego", set())
    dedicated = set()
    for rel in DEDICATED_FILES:
        dedicated |= article_sets.get(rel, set())
    supplementary = set()
    for rel in SUPPLEMENTARY_FILES:
        supplementary |= article_sets.get(rel, set())

    coverage = {}
    for art in KEY_ARTICLES_PIT:
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
        "duplicate_count": len(duplicates),
        "stub_files": stub_files,
        "total_stubs": sum(len(f["stubs"]) for f in files if "stubs" in f),
        "total_checkpoints": sum(f.get("checkpoint_notes", 0) for f in files),
        "total_tautologies": sum(f.get("tautologies", 0) for f in files),
        "total_else_chains": sum(f.get("else_chains", 0) for f in files if "else_chains" in f),
        "total_micro_ids": sum(len(set(f.get("micro_ids", []))) for f in files),
        "coverage": coverage,
        "kst_audit": audit_kst(),
    }


def render_text(report: dict) -> str:
    lines = []
    lines.append("=" * 78)
    lines.append(" PIT MICRO INVENTORY — P07 GLM52 (atomowe reguły + amortyzacja + NKUP)")
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
        part = [a for a, s in cov.items() if s == "PARTIAL"]
        miss = [a for a, s in cov.items() if s == "MISSING"]
        lines.append(f"  POKRYCIE {len(cov)} KLUCZOWYCH ARTYKUŁÓW PIT: COMPLETE {len(comp)} | "
                     f"PARTIAL {len(part)} | MISSING {len(miss)}")
        if miss:
            lines.append(f"    MISSING: {', '.join(miss)}")
    kst = report.get("kst_audit", {})
    if kst:
        lines.append(f"  AUDYT KŚT: znalezione stawki: {len(kst.get('rates_found', {}))} | "
                     f"brakujące wg załącznika: {len(kst.get('missing_rates', []))} "
                     f"(grupy {kst.get('missing_rates', [])})")
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
    ap = argparse.ArgumentParser(description="PIT micro inventory (P07)")
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
