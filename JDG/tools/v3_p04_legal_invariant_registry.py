#!/usr/bin/env python3
"""NexusAI JDG — LEGAL INVARIANT REGISTRY (V3-P04-I09)
=======================================================
Niezmienniki podpięte pod legal_node (P01) — zmiana przepisu sugeruje przegląd
niezmiennika. Łączy katalog INV z aktami prawnymi (macierz prawo↔niezmiennik).

  • powiązanie: INV → akt/artykuł (legal_node ref wg P01: PL/<akt>/art/<art>);
  • przegląd: zmiana węzła prawnego (nowelizacja) → sugerowany review INV;
  • kompletność: każdy INV ma przypisany węzeł prawny lub tag STRUKTURALNY.
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
OUT_JSON = BASE_DIR / "bundles" / "v3_p04_legal_invariant_registry.json"

# INV → legal_node (P01: PL/<akt>/art/<art>) albo STRUKTURALNY.
INV_LEGAL = {
    "INV-001": "PL/vat/art/41",          # stawki VAT
    "INV-002": "STRUKTURALNY",           # kontrakt 25 pól (P03)
    "INV-003": "STRUKTURALNY",           # unikalność rule_id
    "INV-005": "STRUKTURALNY",           # allowlista niemutowalna (P02)
    "INV-006": "STRUKTURALNY",           # fail-closed AUTO_POST (P03)
    "INV-007": "STRUKTURALNY",           # temporalność (P05)
    "INV-008": "STRUKTURALNY",           # ADR-002 parametry-as-data
    "INV-009": "STRUKTURALNY",           # legal refs (P01/P03)
    "INV-012": "PL/ord/art/56",          # kwoty groszowe (odsetki ≥ 0)
    "INV-018": "STRUKTURALNY",           # konflikty domen
    "INV-020": "STRUKTURALNY",           # routing context
    "INV-021": "PL/ord/art/56",          # brutto ≥ netto
    "INV-030": "STRUKTURALNY",           # provenance wersje
    "INV-032": "STRUKTURALNY",           # klasy pewności (F4 V2 §5.2)
    "INV-035": "STRUKTURALNY",           # fail-closed BLOCK
    "INV-036": "STRUKTURALNY",           # routing context
    "INV-037": "PL/vat/art/106na",       # okna temporalne KSeF
    "INV-038": "STRUKTURALNY",           # degradacja
    "INV-039": "STRUKTURALNY",           # provenance path
    "INV-042": "STRUKTURALNY",           # niemutowalność
}
# Dodatkowe niezmienniki prawne z Sekcji 8 P04 (P04-AN10).
LEGAL_INV_EXTRA = [
    {"invariant": "INV-L01", "domain": "VAT", "legal_node": "PL/vat/art/86",
     "description": "odliczenia ≤ podatek należny (VAT art. 86)", "present": False},
    {"invariant": "INV-L02", "domain": "PIT", "legal_node": "PL/pit/art/27",
     "description": "podatek ≥ 0 (PIT art. 27)", "present": False},
    {"invariant": "INV-L03", "domain": "PIT", "legal_node": "PL/pit/art/26",
     "description": "odliczenia ≤ dochód (PIT art. 26)", "present": False},
    {"invariant": "INV-L04", "domain": "ZUS", "legal_node": "PL/zus/art/22",
     "description": "stopy składkowe jako zakresy (ZUS art. 22)", "present": False},
    {"invariant": "INV-L05", "domain": "ZUS", "legal_node": "PL/zdrowotne/art/79",
     "description": "składka zdrowotna ≥ 0 i progi (art. 79-81)", "present": False},
    {"invariant": "INV-L06", "domain": "ORD", "legal_node": "PL/ord/art/57",
     "description": "zakaz dyrektywy wewnętrznej — determinizm (art. 57)", "present": False},
    {"invariant": "INV-L07", "domain": "UOR", "legal_node": "PL/uor/art/7",
     "description": "zasada podwójnego zapisu — niezmiennik bilansowy (art. 7)", "present": False},
]


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def build() -> dict:
    rows = []
    structural = []
    for inv, node in sorted(INV_LEGAL.items()):
        rows.append({"invariant": inv, "legal_node": node,
                     "kind": "STRUCTURAL" if node == "STRUKTURALNY" else "LEGAL"})
        if node == "STRUKTURALNY":
            structural.append(inv)

    missing_legal = [e for e in LEGAL_INV_EXTRA if not e["present"]]
    return {
        "innovation": "V3-P04-I09",
        "name": "Legal Invariant Registry — INV podpięte pod legal_node (P01)",
        "generated_at": now(),
        "registry": rows,
        "legal_linked_count": len(rows) - len(structural),
        "structural_count": len(structural),
        "legal_invariants_required_by_law": LEGAL_INV_EXTRA,
        "missing_legal_invariants": missing_legal,
        "missing_legal_count": len(missing_legal),
        "review_rule": "zmiana węzła prawnego (nowelizacja, P01 Law Radar) → sugerowany "
                       "przegląd powiązanego INV (P04-AN09/I09)",
        "gate": {
            "pass": len(missing_legal) == 0,
            "rule": "wszystkie niezmienniki wymuszone prawem (Sekcja 8 P04) obecne w "
                    "katalogu — P04-AN10; brak = luka prawna",
        },
        "note": "Realna luka: 7 niezmienników prawnych (VAT art. 86, PIT art. 27/26, "
                "ZUS art. 22, zdrowotne art. 79-81, OrdPU art. 57, UoR art. 7) NIE są "
                "jeszcze w katalogu runtime (L02) — do dodania z testami negatywnymi.",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Legal Invariant Registry (V3-P04-I09)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--gate", action="store_true")
    args = ap.parse_args()

    data = build()
    if args.write:
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano {OUT_JSON.relative_to(BASE_DIR)}")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(f"V3-P04-I09 Legal Invariant Registry: legal={data['legal_linked_count']} "
              f"missing_legal={data['missing_legal_count']} gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: brak niezmienników wymuszonych prawem w katalogu")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())