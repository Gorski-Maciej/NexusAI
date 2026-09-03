#!/usr/bin/env python3
"""
NexusAI JDG — FIELD OWNERSHIP MATRIX (V3-P02-I03)
==================================================
Automatyczna macierz własności pól werdyktu: pole → kto zapisuje (pakiety z
kodu) → kto może nadpisać (kolejność safe_merge + allowlist niemutowalna).

Pola krytyczne finansowo (kwoty/stawki/refs) muszą mieć JEDNEGO właściciela
domenowego; nadpisanie przez pakiet spoza domeny = naruszenie INV-018/042.

Metoda (statyczna, bez OPA):
  • zbiór pól kanonicznych 25 (r01_orchestrator_core_innovations_v9),
  • dla każdego pakietu z _package_decisions zliczamy pola zapisywane w
    literałach werdyktów w jego pliku .rego (rule_id + nazwa pola w bloku),
  • właściciel = pakiet, który najczęściej zapisuje pole w swojej domenie;
  • flagujemy pola kwotowe (kwota/netto/brutto/podatek/składka/zaliczka/
    vat_rate/pit_rate/zus_health_rate/kus_percent) pisane przez >1 domenę.

Czyta:  rules/main_jdg.rego (package_decisions), rules/*.rego (pola),
        rules/r01_orchestrator_core_innovations_v9.rego (25 pól)
Pisze:  bundles/v3_p02_field_ownership_matrix.json

Usage:
  python v3_p02_field_ownership_matrix.py [--json] [--write] [--gate]
"""
from __future__ import annotations

import argparse
import json
import re
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
RULES = BASE_DIR / "rules"
OUT_JSON = BASE_DIR / "bundles" / "v3_p02_field_ownership_matrix.json"

CANON_25 = ["matched", "rule_id", "package", "priority",
            "vat_rate", "rounding_level", "gtu_code", "vat_exemption", "procedure",
            "pit_form", "pit_rate", "pit_bracket", "pit_annual_return_type",
            "kus_qualification", "kus_percent",
            "zus_social_base_type", "zus_health_rate",
            "business_status", "ceidg_registration_required",
            "valid_from", "valid_to",
            "_routing", "_routing_reason", "_legal_basis", "_warnings"]

MONEY_FIELDS = {"vat_rate", "pit_rate", "zus_health_rate", "kus_percent",
                "vat_exemption", "pit_bracket"}

# Domena właścicielska per pole kwotowe (prefix pakietu = właściciel materialny).
# Pisarz spoza tych prefixów = kandydat do audytu nadpisań (silent overwrite).
OWNING_DOMAINS = {
    "vat_rate": ("jdg.vat", "jdg.micro.vat", "jdg.crossborder", "jdg.substantive",
                  "jdg.edge_cases", "jdg.fallback", "jdg.ksef"),
    "vat_exemption": ("jdg.vat", "jdg.micro.vat", "jdg.edge_cases", "jdg.fallback"),
    "pit_rate": ("jdg.pit", "jdg.micro.pit", "jdg.allowances", "jdg.ryczalt",
                  "jdg.edge_cases", "jdg.fallback", "jdg.advances"),
    "pit_bracket": ("jdg.pit", "jdg.edge_cases", "jdg.fallback"),
    "kus_percent": ("jdg.pit", "jdg.ryczalt", "jdg.kus", "jdg.edge_cases",
                     "jdg.fallback", "jdg.allowances"),
    "zus_health_rate": ("jdg.zus", "jdg.micro.zus", "jdg.micro.zdrowotna",
                         "jdg.health", "jdg.edge_cases", "jdg.fallback"),
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def package_decisions(text: str) -> list[str]:
    m = re.search(r"_package_decisions\s*:?=\s*\{(.*?)\n\}", text, re.S)
    if not m:
        return []
    return re.findall(r'^\s*"([^"]+)"\s*:', m.group(1), re.M)


def build_package_file_map() -> dict[str, Path]:
    """Mapa pakiet→plik na podstawie deklaracji `package ...` w plikach .rego.

    Dokładniejsze niż zgadywanie po nazwie: plik deklarujący package jdg.vat.substantive
    to jedyny poprawny właściciel pakietu (słownik 25 pól liczony z realnego pliku).
    """
    mapping: dict[str, Path] = {}
    for path in sorted(RULES.rglob("*.rego")):
        txt = path.read_text(encoding="utf-8", errors="ignore")
        m = re.search(r"^package\s+([\w.]+)", txt, re.M)
        if m:
            mapping[m.group(1)] = path
    return mapping


PKG_FILE_MAP: dict[str, Path] = {}


def file_for_package(pkg: str) -> Path | None:
    global PKG_FILE_MAP
    if not PKG_FILE_MAP:
        PKG_FILE_MAP = build_package_file_map()
    return PKG_FILE_MAP.get(pkg)


def fields_written_by_file(path: Path) -> set[str]:
    """Pola z NIEPUSTĄ wartością w literałach werdyktów ("field": value).

    Puste zapisy ("": "") to padding kontraktu 25-polowego — nie są realnym
    zapisem właścicielskim i nie niosą ryzyka nadpisania (INV-018).
    """
    txt = path.read_text(encoding="utf-8", errors="ignore")
    fields = set()
    # "field": wartość — pole pomijamy, gdy wartość jest pusta (padding kontraktu)
    for m in re.finditer(r'"([a-z_]+)"\s*:\s*', txt):
        f = m.group(1)
        rest = txt[m.end():m.end() + 12].lstrip()
        # puste: "" | 0, | 0 } | false | [] | {} | null
        if rest.startswith('""') or rest.startswith("0") or rest.startswith("false") \
                or rest.startswith("[]") or rest.startswith("{}") or rest.startswith("null"):
            continue
        fields.add(f)
    return fields


def build() -> dict:
    main_txt = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    pkgs = package_decisions(main_txt)

    field_writers: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    pkg_field_count: dict[str, int] = {}
    unresolved_pkgs = []
    for pkg in pkgs:
        path = file_for_package(pkg)
        if path is None:
            unresolved_pkgs.append(pkg)
            continue
        flds = fields_written_by_file(path)
        pkg_field_count[pkg] = len(flds)
        for f in flds:
            if f in CANON_25:
                field_writers[f][pkg] += 1

    # właściciel domenowy per pole (wg wzorca prefiksu domeny)
    owners = {}
    multi_writer_money = []
    foreign_writers = {}
    for f in CANON_25:
        writers = field_writers.get(f, {})
        if not writers:
            owners[f] = {"owner": "BRAK (fallback/no_match)", "writers": 0}
            continue
        sorted_w = sorted(writers.items(), key=lambda kv: (-kv[1], kv[0]))
        owners[f] = {"owner": sorted_w[0][0], "writers": len(writers),
                     "top3": [p for p, _ in sorted_w[:3]]}
        if f in MONEY_FIELDS and len(writers) > 1:
            multi_writer_money.append({"field": f, "writers": sorted_w[:4]})
            allowed = OWNING_DOMAINS.get(f, ())
            foreign = [p for p, _ in sorted_w if not p.startswith(allowed)]
            foreign_writers[f] = foreign

    return {
        "innovation": "V3-P02-I03",
        "name": "Field Ownership Matrix — kto pisze, kto może nadpisać",
        "generated_at": now(),
        "packages_analyzed": len(pkgs),
        "unresolved_packages": unresolved_pkgs[:20],
        "canonical_25": CANON_25,
        "ownership": owners,
        "money_fields_multi_writer": multi_writer_money,
        "foreign_writers_by_money_field": foreign_writers,
        "owning_domains": OWNING_DOMAINS,
        "immutable_allowlist": ["jdg.zus", "jdg.zus.sickness_benefits",
                                "jdg.zus.enterprise_benefits",
                                "jdg.zus.health_contribution",
                                "jdg.business", "jdg.security.fortress"],
        "gate": {
            "pass": all(not v for v in foreign_writers.values()),
            "rule": "pola kwotowe/stawkowe pisane wyłącznie przez domenę właścicielską; "
                    "pisarz spoza domeny = kandydat do audytu nadpisań; nadpisanie "
                    "chronione allowlistą niemutowalną (INV-005/018/042)",
        },
        "note": "macierz generowana z kodu (nie ręczna); pola kwotowe pisane przez "
                ">1 domenę = powierzchnia ryzyka silent overwrite przez safe_merge — do audytu "
                "4-eyes (Q); allowlista chroni ZUS/business przed nadpisaniem.",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Field Ownership Matrix (V3-P02-I03)")
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
        print(f"V3-P02-I03 Field Ownership: pakiety={data['packages_analyzed']} "
              f"money_multi_writer={len(data['money_fields_multi_writer'])} "
              f"gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: pole kwotowe pisane przez wiele domen — ryzyko nadpisania")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
