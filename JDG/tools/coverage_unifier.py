#!/usr/bin/env python3
"""
NexusAI JDG — COVERAGE UNIFIER (AD-01: HARMONIZACJA METRYK POKRYCIA)
====================================================================
Jedno, kanoniczne źródło prawdy metryk pokrycia modułu JDG. Naprawia rozjazd
liczb między trzema nieporównywalnymi raportami:
  • COVERAGE_REPORT.md   — Doc 50: punkty prawne (stare, 8%),
  • reverse_coverage     — LKG: węzły materialne (LCI 71,43%),
  • MANIFEST.md          — struktura: bloki matched:true (91/100).

Definicje kanoniczne (coverage ontology — jeden model danych, ten sam co
Legal Twin / legal_graph.json):
  • WĘZEŁ PRAWNY   = (act, article, version) z legal_graph.json (node_type ARTICLE).
  • POKRYCIE WĘZŁA = węzeł materialny ma co najmniej JEDNĄ regułę DOWODNĄ
                     w tej samej domenie (domain) i z pasującym artykułem.
  • REGUŁA DOWODNA = matched:true ORAZ niepusty _legal_basis.
  • SZKIELET       = blok matched:true BEZ _legal_basis — NIE liczy się jako
                     pokrycie (flag `skeleton: true`).
  • fallback/no_match = reguła z matched:false lub rule_id kończącym się na
                     `.no_match` — świadomej decyzji nie liczymy jako pokrycia.

Metryki kanoniczne (każda z JAWNYM mianownikiem i datą pomiaru):
  • LCI  (Legal Coverage Index) = węzły materialne pokryte / węzły materialne × 100
  • TCL  (Traceability Completeness) = reguły dowodne z _legal_basis / reguły dowodne × 100
  • RV   (Rule Validity) = reguły dowodne / (reguły dowodne + szkielety) × 100
  • UVR  (Unverified Rules) = liczba reguł dowodnych, których rule_id NIE
         występuje w natywnych testach Rego (tests/rego)
  • DOC50 = pokrycie wg COVERAGE_REPORT.md (stary, zapisany do porównania)
  • STRUCT = Completeness Score z MANIFEST.md (zapisany do porównania)

Dopasowanie reguła→węzeł LKG: po domenie rule_id (z aliasami) + artykule
z `_legal_basis`. Domeny LKG bez reguł w tym samym obszarze pozostają lukami.

Wyjścia:
  • bundles/coverage_canon.json          — dane kanoniczne (machine-readable)
  • docs/COVERAGE_CANON.md               — raport kanoniczny (czytelny)
  • status: EXIT 0 gdy policzone, EXIT 1 gdy błąd; opcja --check wymaga LCI>=95,
    TCL>=100, RV>=100, UVR==0 (bramka CI klasy Enterprise).

Usage:
  python coverage_unifier.py [--scan] [--report] [--check] [--quiet]
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"
TESTS_DIR = JDG_ROOT / "tests"
GRAPH_PATH = JDG_ROOT / "bundles" / "legal_graph.json"
CANON_PATH = JDG_ROOT / "bundles" / "coverage_canon.json"
REPORT_PATH = JDG_ROOT / "docs" / "COVERAGE_CANON.md"

# ── Wzorce strukturalne ─────────────────────────────────────────────────────
RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
BASIS_RE = re.compile(r'"_legal_basis"\s*:\s*"([^"]*)"')
MATCHED_RE = re.compile(r'"matched"\s*:\s*(true|false)')
PRIORITY_RE = re.compile(r'"priority"\s*:\s*(\d+)')
VALID_FROM_RE = re.compile(r'"valid_from"\s*:\s*"([^"]+)"')

# Aliasy domen rule_id → domeny LKG (legal_graph.json)
DOMAIN_ALIASES = {
    "vat": "vat",
    "micro": None,          # rozpakowywane: micro.vat -> vat
    "pit": "pit",
    "kks": "kks",
    "ord": "ordpu",
    "ordpu": "ordpu",
    "uor": "uor",
    "accounting": "uor",
    "pkpir": "pkpir",
    "zus": "zus",
    "sus": "zus",
    "zdr": "zus",
    "zdrowotna": "zus",
    "business": "business",
    "pp": "business",
    "ceidg": "business",
    "suk": "business",
    "sukcesja": "business",
    "representation": "business",
    "prokura": "business",
    "ksef": "ksef",
    "jpk": "ksef",
    "ksef_jpk": "ksef",
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _balanced_block(text: str, start: int) -> str:
    """Zwraca blok klamrowy zaczynający się w `start` (wskaźnik na `{`)."""
    depth = 0
    i = start
    while i < len(text):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return text[start : i + 1]
        i += 1
    return text[start : i + 1]


def scan_rules() -> list[dict]:
    """Skanuje rules/ i zwraca metadane każdego bloku decide/else z rule_id."""
    rules: list[dict] = []
    for path in sorted(RULES_DIR.rglob("*.rego")):
        text = path.read_text(encoding="utf-8", errors="replace")
        for m in re.finditer(r"\b(?:decide|else)\s*:=\s*\{", text):
            block = _balanced_block(text, text.index("{", m.start()))
            rid_m = RULE_ID_RE.search(block)
            if not rid_m:
                continue
            matched_m = MATCHED_RE.search(block)
            basis_m = BASIS_RE.search(block)
            prio_m = PRIORITY_RE.search(block)
            vf_m = VALID_FROM_RE.search(block)
            rid = rid_m.group(1)
            matched = matched_m.group(1) == "true" if matched_m else False
            legal_basis = basis_m.group(1).strip() if basis_m else ""
            rel = path.relative_to(JDG_ROOT)
            rules.append({
                "rule_id": rid,
                "file": str(rel),
                "matched": matched,
                "legal_basis": legal_basis,
                "priority": int(prio_m.group(1)) if prio_m else 0,
                "valid_from": vf_m.group(1) if vf_m else "",
            })
    return rules


def rule_domain(rule_id: str) -> str | None:
    """Domena rule_id (po aliasach) → domena LKG."""
    parts = rule_id.split(".")
    if len(parts) < 2:
        return None
    if parts[1] == "micro" and len(parts) > 2:
        dom = parts[2]
    else:
        dom = parts[1]
    return DOMAIN_ALIASES.get(dom, dom)


def is_no_match_rule(rule: dict) -> bool:
    """Reguła świadomego braku decyzji (fallback) — nie liczy się jako pokrycie."""
    rid = rule["rule_id"]
    return (not rule["matched"]) or rid.endswith(".no_match") or rid.endswith("no_match")


def is_skeleton(rule: dict) -> bool:
    """Szkielet: matched:true, ale bez _legal_basis — nie liczy się jako pokrycie."""
    return rule["matched"] and not rule["legal_basis"]


def is_evidence_backed(rule: dict) -> bool:
    return rule["matched"] and bool(rule["legal_basis"])


def load_graph() -> dict:
    if GRAPH_PATH.exists():
        return json.loads(GRAPH_PATH.read_text(encoding="utf-8"))
    return {"nodes": [], "indexes": {}}


def _article_from_basis(basis: str) -> str | None:
    m = re.search(r"(?:Art\.|art\.)\s*([\da-zA-Z]+(?:-[\da-zA-Z]+)?)", basis)
    if not m:
        return None
    return m.group(1).split("-")[0]


def _node_article_matches(node_article: str, basis_article: str) -> bool:
    """Węzeł '4-5' pasuje do podstawy 'Art. 4' (zakres zawiera artykuł)."""
    if not node_article or not basis_article:
        return False
    parts = [p.strip() for p in str(node_article).replace(" ", "").split(",")]
    for part in parts:
        rng = part.split("-")
        lo = rng[0]
        hi = rng[1] if len(rng) > 1 else rng[0]
        try:
            blo = int(re.sub(r"\D", "", lo) or 0)
            bhi = int(re.sub(r"\D", "", hi) or blo)
            bar = int(re.sub(r"\D", "", basis_article) or 0)
        except ValueError:
            continue
        if blo <= bar <= bhi:
            return True
    return False


def compute_metrics(rules: list[dict], graph: dict, doc50: dict | None = None,
                    manifest: dict | None = None) -> dict:
    """Oblicza metryki kanoniczne z jawnym mianownikiem."""
    total = len(rules)
    no_match = [r for r in rules if is_no_match_rule(r)]
    actionable = [r for r in rules if not is_no_match_rule(r)]
    skeletons = [r for r in actionable if is_skeleton(r)]
    evidence = [r for r in actionable if is_evidence_backed(r)]

    with_basis = [r for r in evidence if r["legal_basis"]]
    # testy natywne Rego istniejące w tests/rego
    test_ids = set()
    if TESTS_DIR.exists():
        for p in sorted((TESTS_DIR / "rego").rglob("*.rego")):
            test_ids.update(RULE_ID_RE.findall(p.read_text(encoding="utf-8", errors="replace")))
    untested = [r for r in evidence if r["rule_id"] not in test_ids]

    # LKG: dopasowanie po domenie + artykule
    nodes = graph.get("nodes", [])
    material = [n for n in nodes if n.get("material")]
    covered_node_ids: set[str] = set()
    node_cover: dict[str, list[str]] = defaultdict(list)
    for r in evidence:
        dom = rule_domain(r["rule_id"])
        art = _article_from_basis(r["legal_basis"])
        if not dom or not art:
            continue
        for n in material:
            if n.get("domain") != dom:
                continue
            if not _node_article_matches(str(n.get("article", "")), art):
                continue
            node_cover[n["legal_node_id"]].append(r["rule_id"])
            covered_node_ids.add(n["legal_node_id"])

    lci = round(len(covered_node_ids) / len(material) * 100, 2) if material else 100.0
    tcl = round(len(with_basis) / len(evidence) * 100, 2) if evidence else 100.0
    rv = round(len(evidence) / (len(evidence) + len(skeletons)) * 100, 2) if (evidence or skeletons) else 100.0

    return {
        "generated_at": now(),
        "denominators": {
            "rules_total": total,
            "rules_no_match": len(no_match),
            "rules_actionable": len(actionable),
            "rules_skeleton": len(skeletons),
            "rules_evidence_backed": len(evidence),
            "rules_with_legal_basis": len(with_basis),
            "rules_untested_by_native_rego": len(untested),
            "lkg_nodes": len(nodes),
            "lkg_material_nodes": len(material),
            "lkg_covered_material_nodes": len(covered_node_ids),
        },
        "metrics": {
            "LCI": lci,
            "TCL": tcl,
            "RV": rv,
            "UVR": len(untested),
            "DOC50": doc50.get("coverage_pct") if doc50 else None,
            "STRUCT": manifest.get("completeness_score") if manifest else None,
        },
        "by_domain": _domain_breakdown(evidence, skeletons, material, node_cover),
        "skeletons": sorted(s["rule_id"] for s in skeletons),
        "uncovered_material_nodes": sorted(
            (n.get("legal_node_id"), n.get("act"), str(n.get("article")))
            for n in material if n["legal_node_id"] not in covered_node_ids
        )[:100],
        "reconciliation": {
            "explanation": (
                "DOC50 (punkty Doc 50), LCI (węzły LKG) i STRUCT (bloki matched:true) "
                "mierzą RÓŻNE byty i nie są porównywalne wprost. LCI jest metryką "
                "kanoniczną: materialne węzły prawne pokryte dowodną regułą."
            ),
            "doc50_note": "COVERAGE_REPORT.md liczy punkty prawne z planu Doc 50 (archiwalny).",
            "struct_note": "MANIFEST.md liczy bloki matched:true (struktura, nie prawo).",
        },
    }


def _domain_breakdown(evidence, skeletons, material, node_cover) -> dict:
    domains: dict[str, dict] = defaultdict(lambda: {"evidence": 0, "skeletons": 0,
                                                    "lkg_material": 0, "lkg_covered": 0})
    for r in evidence:
        d = rule_domain(r["rule_id"]) or "other"
        domains[d]["evidence"] += 1
    for r in skeletons:
        d = rule_domain(r["rule_id"]) or "other"
        domains[d]["skeletons"] += 1
    for n in material:
        d = n.get("domain") or "other"
        domains[d]["lkg_material"] += 1
        if node_cover.get(n["legal_node_id"]):
            domains[d]["lkg_covered"] += 1
    return dict(sorted(domains.items()))


def load_doc50() -> dict | None:
    """Odczytuje deklarowaną wartość DOC50 z COVERAGE_REPORT.md (jeśli istnieje)."""
    p = JDG_ROOT / "COVERAGE_REPORT.md"
    if not p.exists():
        return None
    m = re.search(r"Pokrytych / zmapowanych \*\*(\d+)\*\* \((\d+)%\)", p.read_text(encoding="utf-8", errors="replace"))
    if m:
        return {"coverage_pct": int(m.group(2))}
    return None


def load_manifest() -> dict | None:
    p = JDG_ROOT / "MANIFEST.md"
    if not p.exists():
        return None
    m = re.search(r"Completeness Score:.*?(\d+)/100", p.read_text(encoding="utf-8", errors="replace"))
    if m:
        return {"completeness_score": int(m.group(1))}
    return None


def build() -> dict:
    rules = scan_rules()
    graph = load_graph()
    metrics = compute_metrics(rules, graph, load_doc50(), load_manifest())
    CANON_PATH.parent.mkdir(parents=True, exist_ok=True)
    CANON_PATH.write_text(json.dumps(metrics, indent=2, ensure_ascii=False), encoding="utf-8")
    return metrics


def render_report(m: dict) -> str:
    d = m["denominators"]
    met = m["metrics"]
    rows = []
    for dom, info in m["by_domain"].items():
        lci_d = round(info["lkg_covered"] / info["lkg_material"] * 100, 1) if info["lkg_material"] else 0
        rows.append(f"| {dom} | {info['evidence']} | {info['skeletons']} | {info['lkg_covered']}/{info['lkg_material']} ({lci_d}%) |")
    skel_rows = "\n".join(f"- `{s}`" for s in m["skeletons"][:50]) or "- brak"
    unc_rows = "\n".join(f"- {nid} — {act} art. {art}" for nid, act, art in m["uncovered_material_nodes"][:50]) or "- brak"
    return f"""# 📐 CANONICAL COVERAGE REPORT — JDG (AD-01)

> **Generowane:** {m['generated_at']} · narzędzie: `tools/coverage_unifier.py`
> **Zasada:** jedna metryka kanoniczna (LCI na węzłach LKG), jawne mianowniki,
> data pomiaru, rozróżnienie reguła dowodna ↔ szkielet.

## Metryki kanoniczne

| Metryka | Wartość | Mianownik |
|---|---|---|
| **LCI** (Legal Coverage Index) | **{met['LCI']}%** | {d['lkg_covered_material_nodes']}/{d['lkg_material_nodes']} węzłów materialnych |
| **TCL** (Traceability Completeness) | **{met['TCL']}%** | {d['rules_with_legal_basis']}/{d['rules_evidence_backed']} reguł dowodnych |
| **RV** (Rule Validity) | **{met['RV']}%** | {d['rules_evidence_backed']}/({d['rules_evidence_backed']}+{d['rules_skeleton']}) |
| **UVR** (Unverified Rules) | **{met['UVR']}** | reguły dowodne bez natywnego testu Rego |
| DOC50 (archiwalny) | {met['DOC50']}% | punkty Doc 50 — inny byt, nieporównywalny |
| STRUCT (MANIFEST) | {met['STRUCT']}/100 | bloki matched:true — inny byt, nieporównywalny |

## Rekoncyliacja

{m['reconciliation']['explanation']}
- {m['reconciliation']['doc50_note']}
- {m['reconciliation']['struct_note']}

## Struktura reguł

| Kategoria | Liczba |
|---|---:|
| Reguły łącznie | {d['rules_total']} |
| no_match / fallback | {d['rules_no_match']} |
| Do decyzji (actionable) | {d['rules_actionable']} |
| **Dowodne** (matched + _legal_basis) | **{d['rules_evidence_backed']}** |
| Szkielety (matched bez podstawy) | {d['rules_skeleton']} |
| Bez testu natywnego Rego | {d['rules_untested_by_native_rego']} |

## Pokrycie wg domeny

| Domena | Reguły dowodne | Szkielety | Węzły LKG pokryte |
|---|---|---:|---:|
{chr(10).join(rows)}

## Szkielety (nie liczone jako pokrycie)

{skel_rows}

## Węzły materialne LKG bez reguły dowodnej (luki)

{unc_rows}

---
*Wygenerowano automatycznie — `python JDG/tools/coverage_unifier.py --report`*
*Standard: LCI ≥ 95% · TCL = 100% · RV = 100% · UVR = 0 (bramka `--check`)*
"""


def main() -> int:
    p = argparse.ArgumentParser(description="Canonical Coverage Unifier — AD-01")
    p.add_argument("--scan", action="store_true", help="policz i zapisz coverage_canon.json")
    p.add_argument("--report", action="store_true", help="wygeneruj docs/COVERAGE_CANON.md")
    p.add_argument("--check", action="store_true", help="bramka CI: LCI>=95, TCL>=100, RV>=100, UVR==0")
    p.add_argument("--quiet", action="store_true")
    args = p.parse_args()

    m = build()
    if args.report:
        REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
        REPORT_PATH.write_text(render_report(m), encoding="utf-8")
        if not args.quiet:
            print(f"📄 Raport kanoniczny: {REPORT_PATH.relative_to(JDG_ROOT)}")
    met = m["metrics"]
    d = m["denominators"]
    if not args.quiet:
        print(f"LCI={met['LCI']}% TCL={met['TCL']}% RV={met['RV']}% UVR={met['UVR']} "
              f"(dowodne={d['rules_evidence_backed']}, szkielety={d['rules_skeleton']}, "
              f"węzły={d['lkg_covered_material_nodes']}/{d['lkg_material_nodes']})")
        print(f"✅ coverage_canon.json: {CANON_PATH.relative_to(JDG_ROOT)}")
    if args.check:
        ok = (met["LCI"] >= 95 and met["TCL"] >= 100 and met["RV"] >= 100 and met["UVR"] == 0)
        if not args.quiet:
            print("GATE: " + ("PASS" if ok else "FAIL (wymagane LCI>=95, TCL=100, RV=100, UVR=0)"))
        return 0 if ok else 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
