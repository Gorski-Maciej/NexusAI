#!/usr/bin/env python3
"""
NexusAI JDG — DATA / THRESHOLD SERVICE (P01 Fundament — Sekcja 5, V1 §7, V2 §8)
================================================================================
Wersjonowany store parametrów (stawki, progi, limity, terminy, kursy, mapy).
Zmiana parametru = zmiana DANYCH, nie kodu (ADR-002 dokończenie, V1 §1.2):

  • set      — nowa wersja parametru (value, valid_from, valid_to, source_act,
    changed_by) z WALIDACJĄ zakresu (min/max/typ) — hot-reload < 1 min,
  • get      — odczyt z time-travel: wartość obowiązująca w danej dacie
    (Art. 3 OrdPU — prawo wg daty transakcji),
  • history  — pełna historia wersji parametru,
  • export   — JSON dla OPA Data API (data.thresholds.jdg.*) bez budowy bundle,
  • validate — walidacja wszystkich parametrów (zakres + ciągłość czasowa:
    zero luk, zero nakładek — V1 §6.4).

Usage:
  python data_service.py set vat.standard_rate --value 0.23 --valid_from 2026-01-01 \
      --min 0 --max 1 --source-act "Art. 41 ustawy o VAT"
  python data_service.py get vat.standard_rate --as-of 2026-03-01
  python data_service.py export
  python data_service.py validate
"""

import argparse
import json
import re
import sys
from datetime import date, datetime
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
DATA_PATH = JDG_ROOT / "bundles" / "thresholds_data.json"
EXPORT_PATH = JDG_ROOT / "bundles" / "thresholds_export.json"

TYPES = {"number": float, "string": str, "bool": lambda v: str(v).lower() in ("1", "true", "yes")}


def load() -> dict:
    if DATA_PATH.exists():
        return json.loads(DATA_PATH.read_text(encoding="utf-8"))
    return {"parameters": {}, "changed_by_audit": []}


def save(data: dict) -> None:
    DATA_PATH.parent.mkdir(parents=True, exist_ok=True)
    DATA_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


def _parse_value(raw: str, ptype: str):
    conv = TYPES.get(ptype, str)
    return conv(raw)


def cmd_set(args) -> None:
    data = load()
    params = data["parameters"]
    # nowa wersja czasowa (valid_from/valid_to) to normalny tryb pracy —
    # rejestr przechowuje pełną historię wersji parametru (time-travel)
    versions = params.setdefault(args.key, {"versions": []})["versions"]
    # Walidacja zakresu (V1 §7: stawka/prog/limit w dozwolonym zakresie)
    value = _parse_value(args.value, args.type)
    if args.min is not None and value < _parse_value(args.min, args.type):
        sys.exit(f"❌ {args.key} = {value} < min {args.min}")
    if args.max is not None and value > _parse_value(args.max, args.type):
        sys.exit(f"❌ {args.key} = {value} > max {args.max}")
    if args.valid_to and args.valid_to < args.valid_from:
        sys.exit(f"❌ valid_to ({args.valid_to}) < valid_from ({args.valid_from})")
    versions.append({
        "value": value,
        "type": args.type,
        "valid_from": args.valid_from,
        "valid_to": args.valid_to,
        "source_act": args.source_act,
        "changed_by": args.changed_by,
        "changed_at": datetime.now().isoformat(timespec="seconds"),
    })
    versions.sort(key=lambda v: v["valid_from"])
    data["parameters"][args.key]["schema"] = {"min": args.min, "max": args.max, "type": args.type}
    data["changed_by_audit"].append({
        "key": args.key, "value": value, "changed_by": args.changed_by,
        "at": datetime.now().isoformat(timespec="seconds"), "source_act": args.source_act,
    })
    save(data)
    print(f"✅ {args.key} = {value} [{args.type}] od {args.valid_from}"
          f"{' do ' + args.valid_to if args.valid_to else ''} · {args.source_act} · {args.changed_by}")
    print("   → HOT-RELOAD gotowy: export do OPA Data API bez budowy bundle (< 1 min)")


def cmd_get(args) -> None:
    data = load()
    if args.key not in data["parameters"]:
        sys.exit(f"❌ Brak parametru {args.key} — użyj: python data_service.py set ...")
    as_of = args.as_of or date.today().isoformat()
    found = None
    for v in data["parameters"][args.key]["versions"]:
        if v["valid_from"] <= as_of and (v["valid_to"] is None or v["valid_to"] >= as_of):
            found = v
            break
    if found is None:
        sys.exit(f"❌ Brak wersji {args.key} obowiązującej na {as_of} (luka czasowa)")
    print(json.dumps({"key": args.key, "as_of": as_of, **found}, indent=2, ensure_ascii=False))


def cmd_history(args) -> None:
    data = load()
    if args.key not in data["parameters"]:
        sys.exit(f"❌ Brak parametru {args.key}")
    print(json.dumps(data["parameters"][args.key], indent=2, ensure_ascii=False))


def cmd_export(args) -> None:
    data = load()
    payload = {"thresholds": data["parameters"],
               "generated_at": datetime.now().isoformat(timespec="seconds"),
               "target": "data.thresholds.jdg.* (OPA Data API — hot-reload)"}
    EXPORT_PATH.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"✅ Eksport: {EXPORT_PATH.relative_to(JDG_ROOT)} — "
          f"{len(data['parameters'])} parametrów (bez rekompilacji bundle)")


def cmd_validate(args) -> None:
    data = load()
    problems = []
    for key, entry in data["parameters"].items():
        versions = entry.get("versions", [])
        schema = entry.get("schema", {})
        for v in versions:
            if schema.get("min") is not None and v["value"] < schema["min"]:
                problems.append(f"{key}: {v['value']} < min {schema['min']} (wersja {v['valid_from']})")
            if schema.get("max") is not None and v["value"] > schema["max"]:
                problems.append(f"{key}: {v['value']} > max {schema['max']} (wersja {v['valid_from']})")
        for a, b in zip(versions, versions[1:]):
            a_to = a.get("valid_to") or "9999-12-31"
            if a_to >= b["valid_from"]:
                problems.append(f"{key}: NAKŁADKA {a['valid_from']}..{a_to} vs {b['valid_from']}")
            if a_to < b["valid_from"]:
                problems.append(f"{key}: LUKA {a_to} → {b['valid_from']}")
    if problems:
        print(f"❌ Walidacja: {len(problems)} problemów")
        for p in problems:
            print(f"   • {p}")
        sys.exit(2)
    print(f"✅ Walidacja danych: {len(data['parameters'])} parametrów, "
          "zero nakładek, zero luk, zakresy OK — time-travel gotowy")


def main() -> None:
    p = argparse.ArgumentParser(description="Data/Threshold Service — V1 §7, V2 §8")
    sub = p.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("set")
    s.add_argument("key")
    s.add_argument("--value", required=True)
    s.add_argument("--type", choices=sorted(TYPES), default="number")
    s.add_argument("--valid_from", default=date.today().isoformat())
    s.add_argument("--valid_to", default=None)
    s.add_argument("--min", default=None)
    s.add_argument("--max", default=None)
    s.add_argument("--source-act", default="")
    s.add_argument("--changed-by", default="system")
    s.add_argument("--force", action="store_true")
    s.set_defaults(fn=cmd_set)

    g = sub.add_parser("get")
    g.add_argument("key"); g.add_argument("--as-of", default=None)
    g.set_defaults(fn=cmd_get)

    h = sub.add_parser("history"); h.add_argument("key"); h.set_defaults(fn=cmd_history)
    e = sub.add_parser("export"); e.set_defaults(fn=cmd_export)
    v = sub.add_parser("validate"); v.set_defaults(fn=cmd_validate)

    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
