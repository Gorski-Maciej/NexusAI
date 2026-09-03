#!/usr/bin/env python3
"""NexusAI JDG — CONSTITUTION CATALOG (V3-P04-I01)
===================================================
Wersjonowany katalog niezmienników z ADR, właścicielem, testem i statusem
egzekucji. Czyta katalog INV z runtime_invariants_enterprise.rego i zestawia
z faktycznie egzekwowanymi w evaluate() — wykrywa luki egzekucji (P04-AN02).

  • katalog (id, opis, poziom, egzekucja, domena, podstawa prawna);
  • egzekucja runtime: evaluate() / _failed_invariants() vs katalog;
  • luka = INV w katalogu bez reguły _inv_violated w runtime (BLOCK nie działa).
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
OUT_JSON = BASE_DIR / "bundles" / "v3_p04_constitution_catalog.json"

# Domena + podstawa prawna per INV (P04-AN01) — semantyka konstytucyjna.
INV_DOMAIN = {
    "INV-001": ("VAT", "Art. 41 VAT — stawki {0,5,8,23,ZW,NP,OO}"),
    "INV-002": ("KONTRAKT", "P03 — 25-polowy kontrakt werdyktu (INV-043)"),
    "INV-003": ("KWOTY", "VAT/PIT/ZUS — kwoty >= 0 (P04-AN10)"),
    "INV-005": ("NIEMUTOWALNE", "P02 — allowlista niemutowalna ZUS/business"),
    "INV-006": ("FAIL_CLOSED", "P03 — CERTAINTY_BLOCKED nigdy AUTO_POST"),
    "INV-007": ("TEMPORALNOŚĆ", "P05 — valid_from <= valid_to"),
    "INV-008": ("PARAMETRY", "ADR-002 — parametry z data.thresholds.*"),
    "INV-009": ("LEGAL_REFS", "P01/P03 — _legal_basis obecne dla decyzji materialnej"),
    "INV-012": ("KWOTY", "zaokrąglenie do groszy (INV groszowy)"),
    "INV-018": ("NIEMUTOWALNE", "brak sprzecznych werdyktów domeny"),
    "INV-020": ("RUNTIME", "routing context kompletny (O(1))"),
    "INV-021": ("KWOTY", "brutto >= netto (P04-AN10)"),
    "INV-030": ("PROVENANCE", "bundle/rule/threshold_version w proweniencji"),
    "INV-032": ("CERTAINTY", "certainty_class ∈ {CERTAIN, CONDITIONAL, NEEDS_ADVICE}"),
    "INV-035": ("FAIL_CLOSED", "BLOCK_AND_ALERT -> brak AUTO_POST"),
    "INV-036": ("RUNTIME", "routing_context: entity_status + evaluation_date"),
    "INV-037": ("TEMPORALNOŚĆ", "zero luk + zero nakładek okien ważności"),
    "INV-038": ("DEGRADACJA", "degradacja nie może być CERTAIN"),
    "INV-039": ("PROVENANCE", "provenance path >= 1 krok"),
    "INV-042": ("NIEMUTOWALNE", "werdykt niemutowalny nie nadpisany"),
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def extract_catalog(rego_text: str) -> list[dict]:
    m = re.search(r"catalog\s*:=\s*\[(.*?)\n\]", rego_text, re.S)
    if not m:
        return []
    raw = m.group(1)
    return [
        {"id": i, "description": d, "level": l, "enforcement": e}
        for i, d, l, e in re.findall(
            r'\{"id":\s*"(INV-\d+)",\s*"description":\s*"([^"]+)",\s*"level":\s*"([^"]+)",\s*"enforcement":\s*"([^"]+)"\}',
            raw,
        )
    ]


def extract_runtime_enforced(rego_text: str) -> set[str]:
    """INV z listą w _failed_invariants (faktycznie sprawdzane w runtime)."""
    m = re.search(r"_failed_invariants\(v\) = failed \{.*?some id in \{(.*?)\}\n", rego_text, re.S)
    if not m:
        return set()
    return set(re.findall(r'"(INV-\d+)"', m.group(1)))


def extract_implemented(rego_text: str) -> set[str]:
    """INV z regułami _inv_violated (implementacja kontroli)."""
    return set(re.findall(r'_inv_violated\("(INV-\d+)"', rego_text))


def build() -> dict:
    rego = (BASE_DIR / "rules" / "audit" / "runtime_invariants_enterprise.rego").read_text(encoding="utf-8")
    catalog = extract_catalog(rego)
    runtime_enforced = extract_runtime_enforced(rego)
    implemented = extract_implemented(rego)

    rows = []
    for inv in catalog:
        inv["runtime_enforced"] = inv["id"] in runtime_enforced
        inv["implemented"] = inv["id"] in implemented
        domain, legal = INV_DOMAIN.get(inv["id"], ("OGÓLNE", "strukturalny/universalny"))
        inv["domain"] = domain
        inv["legal_basis"] = legal
        inv["test_negative"] = f"test_inv_{inv['id'].lower().replace('-', '_')}_block"
        # Klasyfikacja stanu egzekucji (P04-AN02):
        #   ENFORCED     — w _failed_invariants I z klauzulą _inv_violated (działa BLOCK);
        #   NO_IMPL      — RUNTIME/BLOCK w katalogu, ale BEZ klauzuli kontroli (luka P0);
        #   DEAD_ENTRY   — w _failed_invariants, ale bez klauzuli (nigdy nie odpali — cicha dziura);
        #   DEFERRED     — ma klauzulę, ale świadomie poza _failed (post-certyfikacja/CI,
        #                  np. INV-029/031 decision_hash wg komentarza w rego);
        #   CATALOG_ONLY — BUILD/STATISTICAL/ALERT (CI lub monitoring, nie runtime BLOCK).
        if inv["level"] == "RUNTIME" and inv["enforcement"] == "BLOCK":
            if inv["runtime_enforced"] and inv["implemented"]:
                state = "ENFORCED"
            elif inv["runtime_enforced"] and not inv["implemented"]:
                state = "DEAD_ENTRY"
            elif not inv["runtime_enforced"] and inv["implemented"]:
                state = "DEFERRED"
            else:
                state = "NO_IMPL"
        else:
            state = "CATALOG_ONLY"
        inv["execution_state"] = state
        rows.append(inv)

    gaps = [r for r in rows if r["execution_state"] in ("NO_IMPL", "DEAD_ENTRY")]
    return {
        "innovation": "V3-P04-I01",
        "name": "Constitution Catalog — wersjonowany katalog niezmienników (P04-AN01/AN02)",
        "generated_at": now(),
        "catalog_total": len(rows),
        "runtime_enforced_count": len(runtime_enforced),
        "implemented_count": len(implemented),
        "rows": rows,
        "gaps": gaps,
        "gap_count": len(gaps),
        "versioning": "zmiana katalogu = ADR + nowa wersja (P04-AN12); właściciel: "
                      "warstwa konstytucyjna; test negatywny obowiązkowy (P04-AN06)",
        "gate": {
            "pass": len(gaps) == 0,
            "rule": "każdy INV katalogowy z poziomem RUNTIME/BLOCK musi mieć implementację "
                    "_inv_violated + być w _failed_invariants (P04-AN02) — inaczej BLOCK nie działa",
        },
        "note": "Realna luka: katalog 40 INV (27 RUNTIME) ale _failed_invariants sprawdza "
                "tylko 22 — 5 INV RUNTIME/BLOCK bez egzekucji runtime (L01).",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Constitution Catalog (V3-P04-I01)")
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
        print(f"V3-P04-I01 Constitution Catalog: katalog={data['catalog_total']} "
              f"runtime_enforced={data['runtime_enforced_count']} "
              f"gaps={data['gap_count']} gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: INV katalogowe bez egzekucji runtime")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())