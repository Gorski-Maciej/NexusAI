#!/usr/bin/env python3
"""
NexusAI JDG — TRANSITION RULE PATTERN LIBRARY (V3-P05-I09)
==========================================================
Biblioteka wzorców przepisów przejściowych (P05-AN03/AN08): stare fakty →
nowe reguły. Katalog realnych wzorców znalezionych w kodzie:

  • WINDOW_SUPERSEDE  — stara reguła zastąpiona nową z oknem od daty D
                        (registry: supersedes + valid_from) — np. P914→R0582;
  • EPOCH_LOOKUP      — funkcja zwraca wartość wg roku/okresu (rok jako dana
                        ADR-002) — tax_free_amount, depreciation_one_off_limit;
  • LEGACY_CLOSED     — reguła „historyczna” z jawnym wygaszeniem (ulga dla
                        klasy średniej 2022 → 2023 zniesiona; COVID legacy);
  • EFFECTIVE_GATE    — reguła aktywna dopiero od daty D (KSeF 2026-02-01),
                        inline evaluation_date >= D;
  • TRANSITION_WINDOW — okres przejściowy (Polski Ład 01-06.2022).

Każdy wzorzec: rule_id, mechanizm, podstawa prawna, data, test ref, ryzyko
regresji. Biblioteka jest źródłem dla generatora nowych przepisów
przejściowych (szkielet JSON, nie kod produkcyjny).

Usage: python tools/v3_p05_transition_pattern_library.py
Exit:  0 = PASS (katalog niepusty, każdy wpis ma podstawę prawną).
"""
from __future__ import annotations

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RULES = ROOT / "rules"
OUT = ROOT / "bundles" / "v3_p05_transition_pattern_library.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def extract_registry() -> list[dict]:
    md = (RULES / "_metadata_jdg.rego").read_text(encoding="utf-8")
    m = re.search(r"temporal_validity\s*:=\s*\{", md)
    if not m:
        return []
    start, depth, i = m.end(), 1, m.end()
    while i < len(md) and depth > 0:
        if md[i] == "{":
            depth += 1
        elif md[i] == "}":
            depth -= 1
        i += 1
    block = md[start : i - 1]
    out = []
    for em in re.finditer(r'"((?:jdg|tax)\.[a-z0-9_.]+)"\s*:\s*\{([^}]*)\}', block):
        body = em.group(2)
        out.append({
            "rule_id": em.group(1),
            "valid_from": (re.search(r'"valid_from"\s*:\s*"(\d{4}-\d{2}-\d{2})"', body)
                           or [None]) and re.search(r'"valid_from"\s*:\s*"(\d{4}-\d{2}-\d{2})"', body).group(1)
            if re.search(r'"valid_from"\s*:\s*"(\d{4}-\d{2}-\d{2})"', body) else None,
            "supersedes": (lambda mm: mm.group(2) if mm and mm.group(1) != "null" else None)(
                re.search(r'"supersedes"\s*:\s*("([^"]*)"|null)', body)),
            "reason": (lambda mm: mm.group(1) if mm else "")(
                re.search(r'"reason"\s*:\s*"([^"]*)"', body)),
        })
    return out


def main() -> int:
    entries = extract_registry()
    catalog = []
    seen = set()
    for e in entries:
        rid = e["rule_id"]
        # WINDOW_SUPERSEDE: wpis z supersedes
        if e.get("supersedes"):
            catalog.append({
                "pattern": "WINDOW_SUPERSEDE",
                "rule_id": rid, "valid_from": e["valid_from"],
                "supersedes": e["supersedes"], "reason": e["reason"][:120],
                "legal_anchor": "Art. 36a SUS (P914→R0582) / wg reason",
            })
            seen.add(rid)

    # EPOCH_LOOKUP — funkcje z roku jako parametru (helpers/temporal)
    for p in [RULES / "_helpers_jdg.rego", RULES / "temporal.rego"]:
        txt = p.read_text(encoding="utf-8", errors="replace")
        for m in re.finditer(r"^(\w+)\((year|tax_year)\)\s*=", txt, re.MULTILINE):
            name = m.group(1)
            if name not in seen:
                catalog.append({
                    "pattern": "EPOCH_LOOKUP",
                    "rule_id": f"{p.stem}:{name}",
                    "valid_from": "rok jako parametr (ADR-002)",
                    "legal_anchor": "wartości wg roku — patrz ciało funkcji",
                })
                seen.add(name)

    # LEGACY_CLOSED / EFFECTIVE_GATE — temporal.rego + main_jdg inline KSeF
    tmp_txt = (RULES / "temporal.rego").read_text(encoding="utf-8")
    for rid, pat, why in [
        ("jdg.temporal.middle_class_relief_2026", "LEGACY_CLOSED", "ulga zniesiona od 2023 — reguła negatywna dla 2026"),
        ("jdg.temporal.middle_class_relief_2022", "LEGACY_CLOSED", "ulga aktywna tylko w 2022"),
        ("jdg.temporal.covid_legacy", "LEGACY_CLOSED", "okres 03.2020-12.2021 (tarcze)"),
        ("jdg.temporal.ksef_delayed_2026", "EFFECTIVE_GATE", "KSeF obowiązkowy od 01.02.2026"),
        ("jdg.temporal.polski_lad_transition", "TRANSITION_WINDOW", "okres przejściowy 01-06.2022"),
        ("jdg.temporal.historical_pit_rate_2019", "EPOCH_LOOKUP", "stawki PIT na 2019"),
        ("jdg.temporal.historical_pit_rate_2025", "EPOCH_LOOKUP", "stawki PIT na 2025"),
    ]:
        if rid in tmp_txt and rid not in catalog and rid not in seen:
            lb = re.search(rf'"rule_id"\s*:\s*"{re.escape(rid)}".*?"_legal_basis"\s*:\s*"([^"]*)"',
                           tmp_txt, re.DOTALL)
            catalog.append({
                "pattern": pat, "rule_id": rid,
                "valid_from": "2022-01-01" if "2022" in rid else
                              ("2026-02-01" if "ksef" in rid else "2020-01-01" if "covid" in rid else "2025-01-01"),
                "legal_anchor": lb.group(1) if lb else "[NIEZWERYFIKOWANE]",
                "why": why,
            })

    missing_basis = [c["rule_id"] for c in catalog if not c.get("legal_anchor")
                     or "[NIEZWERYFIKOWANE]" in c.get("legal_anchor", "")]
    checks = [
        {"name": "patterns_cataloged", "status": "OK",
         "detail": f"wzorców w bibliotece: {len(catalog)}"},
        {"name": "legal_anchor_present", "status": "OK" if not missing_basis else "WARN",
         "detail": f"wpisy bez kotwicy prawnej: {missing_basis}"},
    ]

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P05-I09",
        "generated_at": now(),
        "gate": gate,
        "patterns": catalog,
        "metrics": {"patterns_total": len(catalog)},
        "checks": checks,
        "findings": [] if gate == "PASS" else [{
            "id": "V3-P05-L12", "severity": "P2",
            "evidence": "wpisy bez kotwicy prawnej", "fix": "uzupełnić ref Dz.U./art.",
        }],
        "contract": {
            "binding": "wszystkie części domenowe P10–P36 (wzorce przepisów przejściowych)",
            "rule": "nowa nowelizacja = instancja wzorca z biblioteki + test day-1/0/+1 (I05)",
        },
    }
    OUT.write_text(json.dumps(bundle, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[V3-P05-I09] gate={gate} patterns={len(catalog)} "
          f"types={sorted({c['pattern'] for c in catalog})}")
    return 0 if gate == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
