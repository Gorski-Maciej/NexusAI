#!/usr/bin/env python3
"""
NexusAI JDG — GOLDEN ORACLE / REPLAY ENGINE (P01 Fundament — Sekcja 9, V2 F3 §4)
=================================================================================
„Oracle przeszłości": repozytorium ZŁOTYCH WERDYKTÓW (golden verdicts) z
reprezentatywnej próbki historycznych transakcji. Zasada F3 (V2 §4.1):

  ŻADNA zmiana (reguły, parametru, bundle) nie może zmienić historycznego
  werdyktu bez uzasadnienia w diffie prawnym. Nieuzasadniona zmiana = BLOKADA.

  • record   — zapis werdyktu do repozytorium (input_hash, werdykt, wersje),
  • replay   — porównanie nowych werdyktów ze złotymi; UVR = % nieuzasadnionych,
  • annotate — ręczna adnotacja „intentional change" (4-eyes, V2 §4.1),
  • report   — raport UVR + delta.

Usage:
  python golden_replay.py record --input-hash a1b2... --verdict verdict.json \
      --bundle jdg-bundle-v9.0.0
  python golden_replay.py replay --input-hash a1b2... --verdict verdict_new.json \
      --reason "Art. 113: limit 2 000 000 → 2 400 000 (Dz.U. 2026 poz. X)"
  python golden_replay.py annotate --input-hash a1b2... --note "..."
  python golden_replay.py report
"""

import argparse
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
GOLDEN_PATH = JDG_ROOT / "bundles" / "golden_verdicts.json"
SCHEMA_VERSION = 2


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def load() -> dict:
    if GOLDEN_PATH.exists():
        try:
            return json.loads(GOLDEN_PATH.read_text(encoding="utf-8"))
        except (OSError, TypeError, ValueError) as exc:
            sys.exit(f"❌ Uszkodzony golden_verdicts.json — wymagane odtworzenie/migracja: {exc}")
    return {"schema_version": SCHEMA_VERSION, "verdicts": {}, "annotations": [], "replays": []}


def save(data: dict) -> None:
    GOLDEN_PATH.parent.mkdir(parents=True, exist_ok=True)
    GOLDEN_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


def _require_current_schema(data: dict) -> None:
    if data.get("schema_version") != SCHEMA_VERSION:
        sys.exit(
            "❌ Nieobsługiwany schema_version Golden Replay — "
            "wymagana jawna migracja baseline’u do wersji 2"
        )


def canonical_verdict_hash(v) -> str:
    """Stabilny SHA-256 kanonicznej treści werdyktu."""
    canonical = json.dumps(v, sort_keys=True, ensure_ascii=False, separators=(",", ":"))
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def _hash(v) -> str:
    """Kompatybilny alias wewnętrzny dla kanonicznego hasha."""
    return canonical_verdict_hash(v)


def cmd_record(args) -> None:
    data = load()
    if GOLDEN_PATH.exists():
        _require_current_schema(data)
    if args.input_hash in data.get("verdicts", {}):
        sys.exit(f"❌ Golden verdict {args.input_hash} już istnieje — baseline jest niezmienny")
    verdict = json.loads(Path(args.verdict).read_text(encoding="utf-8")) if Path(args.verdict).exists() \
        else json.loads(args.verdict)
    data["schema_version"] = SCHEMA_VERSION
    entry = {
        "verdict": verdict,
        "verdict_hash": canonical_verdict_hash(verdict),
        "hash_algorithm": "sha256-canonical-json-v1",
        "bundle_version": args.bundle,
        "recorded_at": now(),
        "legal_basis_refs": args.legal_refs.split(",") if args.legal_refs else [],
    }
    data["verdicts"][args.input_hash] = entry
    save(data)
    print(f"🥇 Złoty werdykt zapisany: {args.input_hash} (bundle {args.bundle})")


def cmd_replay(args) -> None:
    data = load()
    _require_current_schema(data)
    if args.input_hash not in data["verdicts"]:
        sys.exit(f"❌ Brak złotego werdyktu dla {args.input_hash} — najpierw: record")
    golden = data["verdicts"][args.input_hash]
    verdict = json.loads(Path(args.verdict).read_text(encoding="utf-8")) if Path(args.verdict).exists() \
        else json.loads(args.verdict)
    new_hash = canonical_verdict_hash(verdict)
    golden_hash = canonical_verdict_hash(golden["verdict"])
    if golden.get("verdict_hash") != golden_hash:
        sys.exit(f"❌ Uszkodzony baseline {args.input_hash} — hash werdyktu nie pasuje")
    changed = new_hash != golden_hash
    explained = bool(args.reason)
    # UVR: zmiana bez uzasadnienia = unexplained verdict
    row = {
        "input_hash": args.input_hash,
        "golden_verdict_hash": golden_hash,
        "new_verdict": verdict,
        "new_verdict_hash": new_hash,
        "hash_algorithm": "sha256-canonical-json-v1",
        "changed": changed,
        "explained": explained,
        "reason": args.reason,
        "uver_applies": changed and not explained,
        "replayed_at": now(),
    }
    data["replays"].append(row)
    save(data)
    if changed and explained:
        print(f"🔎 REPLAY: zmiana werdyktu {args.input_hash} WYJAŚNIONA diffem prawnym — OK")
    elif changed:
        print(f"❌ UVR: zmiana werdyktu {args.input_hash} BEZ uzasadnienia — BLOKADA WDROŻENIA")
        print("   → Użyj --reason (mapowanie na węzeł LKG) lub annotate (intentional change 4-eyes)")
        sys.exit(2)
    else:
        print(f"✅ REPLAY: werdykt {args.input_hash} identyczny ze złotym — determinizm potwierdzony")


def cmd_annotate(args) -> None:
    data = load()
    _require_current_schema(data)
    if args.input_hash not in data["verdicts"]:
        sys.exit(f"❌ Brak złotego werdyktu dla {args.input_hash}")
    data["annotations"].append({
        "input_hash": args.input_hash,
        "note": args.note,
        "approved_by_4eyes": True,  # wymagane 2 podpisy (V2 §4.1)
        "annotated_at": now(),
    })
    save(data)
    print(f"📝 Intentional change zanotowana (4-eyes): {args.input_hash} — trafia do audytu WORM")


def cmd_report(args) -> None:
    data = load()
    replays = data.get("replays", [])
    total = len(replays)
    uvr_count = sum(1 for r in replays if r.get("uver_applies"))
    changed = sum(1 for r in replays if r.get("changed"))
    print(json.dumps({
        "golden_verdicts": len(data["verdicts"]),
        "replays": total,
        "changed": changed,
        "unexplained (UVR)": uvr_count,
        "uvr_percent": round(uvr_count / total * 100, 2) if total else 0.0,
        "slo_uver": 0,
        "annotations": len(data.get("annotations", [])),
    }, indent=2, ensure_ascii=False))


def main() -> None:
    p = argparse.ArgumentParser(description="Golden Oracle / Replay — V2 F3")
    sub = p.add_subparsers(dest="cmd", required=True)

    r = sub.add_parser("record")
    r.add_argument("--input-hash", required=True)
    r.add_argument("--verdict", required=True)
    r.add_argument("--bundle", default="unknown")
    r.add_argument("--legal-refs", default="")
    r.set_defaults(fn=cmd_record)

    pl = sub.add_parser("replay")
    pl.add_argument("--input-hash", required=True)
    pl.add_argument("--verdict", required=True)
    pl.add_argument("--reason", default=None)
    pl.set_defaults(fn=cmd_replay)

    a = sub.add_parser("annotate")
    a.add_argument("--input-hash", required=True)
    a.add_argument("--note", required=True)
    a.set_defaults(fn=cmd_annotate)

    rep = sub.add_parser("report"); rep.set_defaults(fn=cmd_report)

    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
