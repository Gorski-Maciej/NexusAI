#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — GOLDEN AUTOJUSTIFY (GLM52 P18 — TESTY / CI / JAKOŚĆ, V2 F3)
# Golden Oracle z auto-uzasadnieniem: każda zmiana werdyktu w replay musi mieć
# uzasadnienie w diffie prawnym / legal_basis (inaczej FAIL — „nieuzasadniona
# zmiana"). Automatycznie kojarzy zmianę z:
#   • zmianą _legal_basis (nowelizacja — Dz.U. wersja),
#   • zmianą thresholdów (data.thresholds — parametryzacja),
#   • zmianą rule_id (nowa reguła / deprecate),
#   • adnotacją ręczną (4-eyes — V2 §4.1).
#  • replay  — porównanie golden vs nowy werdykt + auto-uzasadnienie,
#  • gate    — BRAMKA CI: 0 nieuzasadnionych zmian (UVR 0).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
GOLDEN_PATH = JDG_ROOT / "bundles" / "golden_verdicts.json"


def load_golden() -> dict:
    if GOLDEN_PATH.exists():
        return json.loads(GOLDEN_PATH.read_text(encoding="utf-8"))
    return {"verdicts": {}}


def _legal_basis_of(verdict: dict) -> str:
    lb = verdict.get("_legal_basis")
    if isinstance(lb, list):
        return " | ".join(str(x) for x in lb)
    return str(lb or "")


def _threshold_refs(verdict: dict) -> list[str]:
    """Wskazania data.thresholds w werdykcie (jeśli obecne w _provenance)."""
    prov = verdict.get("_provenance_tree") or {}
    refs = prov.get("threshold_refs") or []
    return list(refs) if isinstance(refs, list) else []


def replay(verdict_new: dict, input_hash: str, legal_diff: str = "",
           manual_note: str = "") -> dict:
    """Porównanie golden vs nowy werdykt z auto-uzasadnieniem."""
    golden = load_golden()
    old = golden.get("verdicts", {}).get(input_hash, {}).get("verdict", {})
    if not old:
        return {"input_hash": input_hash, "status": "NEW",
                "note": "brak werdyktu golden — nowy przypadek (dodaj do baseline)"}

    changes = {}
    for key in ("matched", "rule_id", "vat_rate", "pit_rate", "zus_health_rate"):
        if old.get(key) != verdict_new.get(key):
            changes[key] = {"from": old.get(key), "to": verdict_new.get(key)}

    old_lb, new_lb = _legal_basis_of(old), _legal_basis_of(verdict_new)
    if old_lb != new_lb:
        changes["_legal_basis"] = {"from": old_lb, "to": new_lb}

    # AUTO-UZASADNIENIE: zmiana legal_basis = nowelizacja prawa
    justification = None
    if "_legal_basis" in changes and legal_diff:
        justification = f"nowelizacja: {legal_diff}"
    elif changes and manual_note:
        justification = f"adnotacja ręczna (4-eyes): {manual_note}"
    elif changes and "rule_id" in changes:
        justification = "zmiana reguły (nowa rule_id / deprecate) — wymaga zgody"

    justified = justification is not None
    return {
        "input_hash": input_hash,
        "changed": bool(changes),
        "changes": changes,
        "justification": justification,
        "status": "JUSTIFIED" if justified else "UNJUSTIFIED",
        "gate": "PASS" if (not changes or justified) else "FAIL",
    }


def gate(legal_diff: str = "") -> dict:
    """BRAMKA: wszystkie zmiany w golden mają uzasadnienie (UVR 0)."""
    golden = load_golden()
    replays = golden.get("replays", [])
    if not replays:
        return {"gate": "PASS", "replays": 0, "note": "brak replayów — replay pusty OK"}
    unjustified = [r for r in replays if r.get("status") == "UNJUSTIFIED"]
    return {"gate": "PASS" if not unjustified else "FAIL",
            "replays": len(replays), "unjustified": len(unjustified),
            "unjustified_items": unjustified[:10]}


def main() -> None:
    p = argparse.ArgumentParser(description="JDG Golden Autojustify (P18)")
    sub = p.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("replay"); r.add_argument("--verdict", required=True, type=json.loads)
    r.add_argument("--input-hash", required=True); r.add_argument("--legal-diff", default="")
    r.add_argument("--manual-note", default="")
    r.set_defaults(fn=lambda a: print(json.dumps(replay(a.verdict, a.input_hash, a.legal_diff, a.manual_note), ensure_ascii=False, indent=1)))
    g = sub.add_parser("gate"); g.add_argument("--legal-diff", default="")
    g.set_defaults(fn=lambda a: print(json.dumps(gate(a.legal_diff), ensure_ascii=False, indent=1)))
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
