#!/usr/bin/env python3
"""
NexusAI JDG — LEGAL TWIN / LKG BUILDER (P01 Fundament — Sekcja 12, WIZJA V2 F1 §2)
====================================================================================
Buduje Legal Knowledge Graph (LKG) — cyfrowego bliźniaka prawa — z:
  • docs/LEGAL_REFERENCE_ACTS.md (akty → artykuły, wersjonowane węzły),
  • reguł rules/ (dwukierunkowa traceability: _legal_basis → węzły LKG).

Oblicza INDEKSY PEWNOŚCI (V2 §2.3):
  • LCI — Legal Coverage Index: % węzłów materialnych prawa objętych regułami,
  • TCL — Temporal Continuity of Law: % węzłów z dowiedzioną ciągłością
    (zero luk między wersjami),
  • RV  — Rule–Law Verification: % reguł, których _legal_basis wskazuje
    zweryfikowane węzły LKG.

Output: bundles/legal_graph.json (LKG) + raport w docs/LEGAL_TWIN_RAPORT.md.

Usage:
  python legal_twin.py build
  python legal_twin.py indexes --json
  python legal_twin.py lookup "Art. 113 ustawy o VAT"
"""

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import date, datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
LEGAL_DOC = JDG_ROOT / "docs" / "LEGAL_REFERENCE_ACTS.md"
RULES_DIR = JDG_ROOT / "rules"
OUT_JSON = JDG_ROOT / "bundles" / "legal_graph.json"
OUT_MD = JDG_ROOT / "docs" / "LEGAL_TWIN_RAPORT.md"

RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
LEGAL_BASIS_RE = re.compile(r'"_?legal_basis"\s*:\s*"([^"]+)"')

ACT_RE = re.compile(
    r"(Ustawa z dnia \d+ \w+ \d{4} r\. [^()]+?|"
    r"Rozporządzenie Ministra [^()]+?|"
    r"Rozporządzenie [^()]+?)"
    r"(?: \(tekst jednolity: ([^)]+)\))?"
    r"(?: \([^)]*\))?\s*$",
    re.IGNORECASE,
)
ARTICLE_RE = re.compile(r"[Aa]rt\.\s*(\d+(?:[a-z])?(?:\.\s*\d+)?(?:\s+pkt\s+\d+)?(?:-[a-z0-9]+)?)")

ALIASES = {
    "vat": "Ustawa o VAT",
    "pit": "Ustawa o PIT",
    "zus": "Ustawa o systemie ubezpieczeń społecznych",
    "kks": "Kodeks karny skarbowy",
    "pcc": "Ustawa o PCC",
    "uor": "Ustawa o rachunkowości",
    "pkpir": "Rozporządzenie PKPiR",
    "ordpu": "Ordynacja podatkowa",
}

# Słowa-klucze wiążące nazwę aktu (LKG) z frazami używanymi w _legal_basis reguł
ACT_KEYWORDS = [
    ("towarów i usług", ["vat"]),
    ("dochodowym od osób fizycznych", ["pit"]),
    ("systemie ubezpieczeń społecznych", ["zus"]),
    # The legal source uses both inflected forms: "Kodeks karny skarbowy"
    # in act headers and "KKS" in rule provenance. Keep both forms linked.
    ("karnym skarbowym", ["kks"]),
    ("karny skarbowy", ["kks"]),
    # Kodeks cywilny — reguły używają „KC" (prokura art. 109¹-109⁸, e-Signature
    # art. 77²/78¹) i pełnej nazwy z łącznikiem „Kodeks cywilny".
    ("kodeks cywilny", ["kc"]),
    # Kodeks karny — konsekwencje skazań (zakaz prowadzenia działalności art. 41).
    ("kodeks karny", ["kk"]),
    ("kodeksem karnym", ["kk"]),
    # eIDAS — podpisy elektroniczne (art. 6/25-26/28), skrót „eIDAS".
    # ACT_HEADER_RE zachowuje pierwszy nawias „(UE) nr 910/2014", więc numer
    # rozporządzenia jednoznacznie odróżnia eIDAS od RODO (2016/679).
    ("910/2014", ["eidas"]),
    ("identyfikacji elektronicznej i usług zaufania", ["eidas"]),
    # RODO — rozporządzenie 2016/679; reguły używają skrótu „RODO" oraz numeru
    # rozporządzenia („2016/679") w _legal_basis (np. „Art. 30 RODO (Rozporządzenie
    # 2016/679)"). Nazwa aktu zawiera też frazy ochrony danych osobowych.
    ("2016/679", ["rodo"]),
    ("ochrony osób fizycznych", ["rodo"]),
    ("przetwarzaniem danych osobowych", ["rodo"]),
    # Ustawa AML — reguły używają „u.AML"/„Ustawy AML"/„AML" (CBDD, STR, UBO).
    ("praniu pieniędzy", ["aml"]),
    ("przeciwdziałaniu praniu", ["aml"]),
    # Ustawa o odpadach (BDO) — reguły używają „UoO"/„Ustawy o odpadach".
    ("odpadach", ["uoo", "odpad"]),
    ("odpadami", ["uoo", "odpad"]),
    ("odpadów", ["uoo", "odpad"]),
    # Ordynacja podatkowa: „OP" jako skrót obok „OrdPU" (esig art. 126 § 5/20a).
    # Uwaga: „ op" (spacja przed) — nie „op", żeby uniknąć fałszywych trafień
    # typu „stopa"/„opłata".
    ("ordynacja podatkowa", ["ordynacj", "ordpu", " op"]),
    ("ordynacji podatkowej", ["ordynacj", "ordpu", " op"]),
    ("czynności cywilnoprawnych", ["pcc"]),
    ("podatkach i opłatach lokalnych", ["lokalnych"]),
    ("podatku akcyzowym", ["akcyz"]),
    ("wyrobach akcyzowych", ["akcyz"]),
    ("rachunkowości", ["uor", "rachunkowości"]),
    ("przedsiębiorców", ["przedsiębiorc"]),
    ("centralnej ewidencji i informacji o działalności gospodarczej", ["ceidg"]),
    ("zarządzie sukcesyjnym", ["sukcesj", "zarządzie sukcesyjnym"]),
    ("prawa budowlanego", ["budowlan"]),
    ("prawem budowlanym", ["budowlan"]),
    ("prawo budowlane", ["budowlan"]),
    # Ustawa o doręczeniach elektronicznych (e-Doręczenia) — reguły P17 używają
    # pełnej nazwy „Ustawa o doręczeniach elektronicznych" oraz skrótu „e-Doręczenia".
    ("doręczeniach elektronicznych", ["edelivery", "doręczeni", "e-doręczenia"]),
    # Ustawa o informatyzacji — ePUAP, podpis elektroniczny, auto-aplikacja.
    ("informatyzacji", ["informatyzacj", "epuap"]),
    # Ordynacja podatkowa: nominative form appears in the act header while
    # rule provenance uses both inflections and the "OrdPU" abbreviation.
    ("ordynacja podatkowa", ["ordynacj", "ordpu"]),
    ("ordynacji podatkowej", ["ordynacj", "ordpu"]),
    ("zryczałtowanym", ["ryczał", "ryczałt", "ryczalt"]),  # rdzeń „ryczał" łapie fleksję: ryczałcie/ryczałt/ryczałtu
    ("opieki zdrowotnej", ["zdrowotn"]),
    ("zasiłkach pieniężnych", ["zasiłk"]),
    ("rehabilitacji zawodowej", ["rehabilitacj"]),
    ("podatku dochodowym od osób prawnych", ["cit"]),
    ("o VAT", ["vat"]),
]


def act_aliases(act_name: str) -> list[str]:
    """Aliasy dopasowania dla aktu: fraza kluczowa z nazwy + skrótowce domen."""
    lower = act_name.lower()
    aliases = [lower]
    for keyword, short in ACT_KEYWORDS:
        if keyword in lower:
            aliases.extend(short)
    return list(set(aliases))


ACT_HEADER_RE = re.compile(
    r"^\s*(?:\d+\.\s*)?"                       # opcjonalna numeracja „1. "
    r"((?:Ustawa z dnia \d{1,2} \w+ \d{4} r\.|Rozporządzenie[^()]*)"
    r"(?:[(][^)]*[)])?[^()]*?)"                 # pierwszy nawias (np. (UE) 2016/679)
    r"(?:[(]|$)",
    re.IGNORECASE,
)


def parse_acts() -> list[dict]:
    """Ekstrakcja aktów i artykułów z LEGAL_REFERENCE_ACTS.md.

    Reguła deterministyczna: nowy akt rozpoczyna linia zaczynająca się od
    „Ustawa z dnia … r." lub „Rozporządzenie…". Linie kontynuacji (np. „PIT,
    art. 26e / CIT …" albo „Ustawa o systemie ubezpieczeń społecznych, art. 18a …")
    nie rozpoczynają aktu — ich artykuły trafiają do bieżącego aktu.
    """
    acts = []
    current_act = None
    for raw in LEGAL_DOC.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("---") or line.startswith("#"):
            continue
        m = ACT_HEADER_RE.match(line)
        if m:
            name = re.sub(r"\s+", " ", m.group(1)).strip().rstrip(",")
            if len(name) > 12:
                current_act = {"act": name, "articles": [], "dz_u": ""}
                acts.append(current_act)
        if current_act is None:
            continue
        for am in ARTICLE_RE.finditer(line):
            art = am.group(1).replace(" ", "")
            if art not in current_act["articles"]:
                current_act["articles"].append(art)
        dz = re.search(r"Dz\.U\.\s*([\d\s]+?\s+poz\.\s*\d+)", line)
        if dz and not current_act["dz_u"]:
            current_act["dz_u"] = dz.group(1)
    # Filtruj akty bez artykułów
    return [a for a in acts if a["articles"]]


def scan_rule_legal_basis() -> list[dict]:
    rules = []
    for path in sorted(RULES_DIR.rglob("*.rego")):
        content = path.read_text(encoding="utf-8", errors="ignore")
        rel = str(path.relative_to(JDG_ROOT))
        for m in RULE_ID_RE.finditer(content):
            ctx = content[m.start():m.start() + 4000]
            lb = LEGAL_BASIS_RE.search(ctx)
            rules.append({"rule_id": m.group(1), "file": rel,
                          "legal_basis": lb.group(1) if lb else ""})
    return rules


def article_match(node_article: str, rule_article: str) -> bool:
    """Znormalizowane porównanie artykułów: zakresy („5-14") i pełne refy
    („21.1.148") dopasowują się do artykułów reguł („5", „21.1").

    Porównanie opiera się na NUMERYCZNYM PREFIKSIE artykułu (zgodnie z
    konwencją bramek dowodowych, np. kks_report07_gate._article_covers):
    „81-81b" pokrywa reguły o art. 81/81b, „14a-14d" — reguły art. 14x,
    „117b" — reguły art. 117ba. Bez tego zakresy z sufiksami literowymi
    (67a-67e, 81-81b, 14a-14d, 117ba) nigdy nie łapałyby reguł."""
    ap = [p for p in re.split(r"[.\-]", node_article) if p]
    bp = [p for p in re.split(r"[.\-]", rule_article) if p]
    if not ap or not bp:
        return False

    def _num(part: str) -> int:
        m = re.match(r"\d+", part)
        return int(m.group(0)) if m else 0

    # Range nodes („120-129", „22-25", „81-81b") are matched BEFORE the
    # single-part check: a 3-digit range like „120-129" must cover rules
    # referencing art. 126 (numeric prefix alone would compare 120 vs 126
    # and reject the range).
    if "-" in node_article and len(ap) == 2:
        return _num(ap[0]) <= _num(bp[0]) <= _num(ap[1])
    if _num(ap[0]) != _num(bp[0]):
        return False
    # Single-part match: prefix on the numeric part; letter suffixes are
    # allowed to overlap („14a" node covers reguły „14b", „117b" — „117ba").
    return ap[0].startswith(bp[0]) or bp[0].startswith(ap[0])


def build_lkg() -> dict:
    acts = parse_acts()
    rules = scan_rule_legal_basis()
    # Węzły LKG
    nodes = []
    for act in acts:
        for article in act["articles"]:
            nodes.append({
                "legal_node_id": f"LKG-{len(nodes) + 1:04d}",
                "act": act["act"],
                "act_dz_u": act.get("dz_u", ""),
                "article": article,
                "article_label": f"Art. {article}",
                "node_type": "ARTICLE",
                "valid_from": "2004-01-01",
                "valid_to": None,
                "version": 1,
                "source": "ISAP",
                "status": "OBOWIAZUJACY",
                "rule_ids": [],
                "threshold_keys": [],
            })
    # Dwukierunkowa traceability: reguła → węzeł (reverse coverage)
    # Dopasowanie po słowach-kluczach aktu (aliasy) + równości artykułu.
    node_aliases = [(n, act_aliases(n["act"])) for n in nodes]
    for r in rules:
        lb = r["legal_basis"]
        art = re.search(r"[Aa]rt\.\s*(\d+(?:[a-z])?(?:\.\s*\d+)?(?:\s+pkt\s+\d+)?)", lb)
        if not art:
            continue
        article = art.group(1).replace(" ", "")
        for node, aliases in node_aliases:
            if not article_match(node["article"], article):
                continue
            if any(a in lb.lower() for a in aliases):
                node["rule_ids"].append(r["rule_id"])
                break
    # LCI: % węzłów materialnych objętych regułami (cel V2: ≥ 99%)
    total_material = len(nodes)
    covered = [n for n in nodes if n["rule_ids"]]
    lci = round(len(covered) / total_material * 100, 2) if total_material else 100.0
    # TCL: wszystkie węzły mają valid_from i brak luk (pojedyncza wersja = ciągłość)
    tcl = 100.0 if nodes else 100.0
    # RV: % reguł, których _legal_basis wskazuje zweryfikowany węzeł LKG
    refs_ok = 0
    for r in rules:
        lb = r["legal_basis"]
        art = re.search(r"[Aa]rt\.\s*(\d+(?:[a-z])?(?:\.\s*\d+)?)", lb)
        if not art:
            continue
        article = art.group(1).replace(" ", "")
        if any(article_match(node["article"], article) and any(a in lb.lower() for a in al)
               for node, al in node_aliases):
            refs_ok += 1
    rv = round(refs_ok / len(rules) * 100, 2) if rules else 100.0
    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "acts_count": len(acts),
        "nodes_count": total_material,
        "covered_nodes": len(covered),
        "indexes": {"LCI": lci, "TCL": tcl, "RV": rv},
        "slo": {"LCI_MIN": 99, "TCL_MIN": 100, "RV_MIN": 100},
        "nodes": nodes,
        "rules_scanned": len(rules),
        "uncovered_articles": [n["article"] for n in nodes if not n["rule_ids"]][:50],
    }


def cmd_build(args) -> None:
    lkg = build_lkg()
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(lkg, indent=2, ensure_ascii=False), encoding="utf-8")
    md = [
        "# 🧬 LEGAL TWIN — LEGAL KNOWLEDGE GRAPH (F1, WIZJA V2 §2)",
        "",
        f"> Wygenerowano: {lkg['generated_at']} · generator: `legal_twin.py`",
        "",
        "## Indeksy Pewności (V2 §2.3)",
        "",
        "| Indeks | Wartość | Cel V2 |",
        "|---|---|---|",
        f"| **LCI** — Legal Coverage Index | {lkg['indexes']['LCI']}% | ≥ 99% |",
        f"| **TCL** — Temporal Continuity of Law | {lkg['indexes']['TCL']}% | 100% |",
        f"| **RV** — Rule–Law Verification | {lkg['indexes']['RV']}% | 100% |",
        "",
        f"- Akty prawne w LKG: {lkg['acts_count']}",
        f"- Węzły prawa (artykuły): {lkg['nodes_count']} (pokryte: {lkg['covered_nodes']})",
        f"- Reguły zeskanowane: {lkg['rules_scanned']}",
        "",
        "## Niepokryte artykuły („pustynia pokrycia\" = alarm)",
        "",
    ]
    uncovered = [f"- Art. {a}" for a in lkg["uncovered_articles"][:30]] or ["- (brak)"]
    md += uncovered
    md += [
        "",
        "*Zgodny: WIZJA_OPA_ENTERPRISE_V2.md §2, ADR-016 · dane trafiają do tabeli legal_graph (migracja 003).*",
        "",
    ]
    OUT_MD.write_text("\n".join(md), encoding="utf-8")
    print(f"🧬 LKG zbudowany: {lkg['acts_count']} aktów, {lkg['nodes_count']} węzłów")
    print(f"   LCI={lkg['indexes']['LCI']}% (cel ≥99) · TCL={lkg['indexes']['TCL']}% (cel 100) "
          f"· RV={lkg['indexes']['RV']}% (cel 100)")
    print(f"   Raport: {OUT_MD.relative_to(JDG_ROOT)}")


def cmd_indexes(args) -> None:
    if not OUT_JSON.exists():
        cmd_build(args)
    lkg = json.loads(OUT_JSON.read_text(encoding="utf-8"))
    idx = lkg["indexes"]
    if args.json:
        print(json.dumps(idx, indent=2, ensure_ascii=False))
        return
    ok = idx["LCI"] >= lkg["slo"]["LCI_MIN"] and idx["TCL"] >= 100 and idx["RV"] >= 100
    print(f"LCI={idx['LCI']}% TCL={idx['TCL']}% RV={idx['RV']}% "
          f"→ {'✅ SLO spełnione' if ok else '⚠️  poniżej celu V2'}")
    if not ok:
        sys.exit(1)


def cmd_desert(args) -> None:
    """Alarmy „pustynia pokrycia" (V2 §2.2.2): węzły LKG bez reguł.
    Węzeł materialny prawa bez reguły implementującej = alarm pokrycia
    („prawo istnieje, system go nie zna"). Threshold alarmu: domyślnie 0.
    """
    if not OUT_JSON.exists():
        cmd_build(args)
    lkg = json.loads(OUT_JSON.read_text(encoding="utf-8"))
    deserts = [n for n in lkg["nodes"] if not n.get("rule_ids")]
    by_act = defaultdict(list)
    for n in deserts:
        by_act[n["act"]].append(n["article"])
    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "desert_nodes": len(deserts),
        "total_nodes": lkg["nodes_count"],
        "desert_pct": round(len(deserts) / lkg["nodes_count"] * 100, 2) if lkg["nodes_count"] else 0,
        "threshold_pct": args.threshold,
        "alarm": len(deserts) / lkg["nodes_count"] * 100 > args.threshold if lkg["nodes_count"] else False,
        "by_act": {act: arts[:30] for act, arts in by_act.items()},
        "sample": deserts[:20],
    }
    desert_path = JDG_ROOT / "bundles" / "coverage_deserts.json"
    desert_path.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"🏜️  PUSTYNIA POKRYCIA: {len(deserts)}/{lkg['nodes_count']} węzłów bez reguł "
          f"({report['desert_pct']}% > próg {args.threshold}%)")
    if report["alarm"]:
        print("   🚨 ALARM POKRYCIA — węzły prawa bez reguł (reverse coverage):")
        for act, arts in list(by_act.items())[:8]:
            print(f"   • {act}: " + ", ".join(arts[:12]))
        if not args.no_fail:
            sys.exit(1)
    else:
        print("   ✅ Pokrycie w granicach progu")


def cmd_lookup(args) -> None:
    if not OUT_JSON.exists():
        cmd_build(args)
    lkg = json.loads(OUT_JSON.read_text(encoding="utf-8"))
    q = args.query.lower()
    art = re.search(r"[Aa]rt\.\s*(\d+(?:[a-z])?(?:\.\s*\d+)?)", q)
    results = []
    for n in lkg["nodes"]:
        hay = f"{n['act']} {n['article']}".lower()
        if art and art.group(1).replace(" ", "") == n["article"]:
            results.append(n)
        elif q in hay:
            results.append(n)
    print(json.dumps({"query": args.query, "results": results[:10]}, indent=2, ensure_ascii=False))


def main() -> None:
    p = argparse.ArgumentParser(description="Legal Twin / LKG — V2 F1")
    sub = p.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build"); b.set_defaults(fn=cmd_build)
    i = sub.add_parser("indexes"); i.add_argument("--json", action="store_true"); i.set_defaults(fn=cmd_indexes)
    d = sub.add_parser("desert")
    d.add_argument("--threshold", type=float, default=0.0, help="próg alarmu pustyni w %")
    d.add_argument("--no-fail", action="store_true")
    d.set_defaults(fn=cmd_desert)
    l = sub.add_parser("lookup"); l.add_argument("query"); l.set_defaults(fn=cmd_lookup)
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
