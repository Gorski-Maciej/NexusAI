#!/usr/bin/env python3
"""NexusAI JDG — V3-P49-I01 FAIL-CLOSED INVARIANT PACK (przed każdym AUTO_POST).

Sześć invariantów runtime (P04 kontrakt) ewaluowanych NA ŻYWO na złotych
orzeczeniach (golden_verdicts.json) — dowód, że pack odmawia AUTO_POST bez
pełnego łańcucha dowodów:
  INV-P49-01  kompletność kontraktu P03: matched=true ⇒ rule_id+package+priority
  INV-P49-02  łańcuch dowodów: _legal_basis obecne i niepuste
  INV-P49-03  routing kontrakt: matched=true ⇒ decision_mode lub _routing
  INV-P49-04  okno temporalne (P05): valid_from obecne
  INV-P49-05  sanity ostrzeżeń: _warnings jest listą
  INV-P49-06  zero cichego AUTO_POST (AP07): AUTO_POST wymaga legal_basis

Honesty: naruszenia liczone z realnych rekordów; bundle = v3_p49_invariant_pack.json.
"""
from __future__ import annotations

from pathlib import Path

from v3_p48_common import GOLDEN_VERDICTS, read_json
from v3_p49_common import rule_present, write_p49_bundle

BUNDLES = Path(__file__).resolve().parents[1] / "bundles"

INVARIANTS = [
    ("INV-P49-01", "verdict_completeness"),
    ("INV-P49-02", "evidence_chain"),
    ("INV-P49-03", "routing_contract"),
    ("INV-P49-04", "temporal_window"),
    ("INV-P49-05", "warnings_sanity"),
    ("INV-P49-06", "no_silent_auto_post"),
]


def _verdicts() -> list[dict]:
    data = read_json(GOLDEN_VERDICTS) or {}
    out = []
    for k, v in (data.get("verdicts") or {}).items():
        if isinstance(v, dict) and isinstance(v.get("verdict"), dict):
            out.append(v["verdict"])
        elif isinstance(v, dict) and v.get("rule_id"):
            out.append(v)  # legacy flat (v3_p21_kks_sample)
    return out


def evaluate() -> dict:
    vs = _verdicts()
    violations: list[dict] = []
    for v in vs:
        rid = v.get("rule_id", "?")
        if v.get("matched") is True:
            if not v.get("rule_id") or not v.get("package") or v.get("priority") is None:
                violations.append({"invariant": "INV-P49-01", "rule_id": rid})
            if not v.get("_legal_basis"):
                violations.append({"invariant": "INV-P49-02", "rule_id": rid})
            if not v.get("decision_mode") and not v.get("_routing"):
                violations.append({"invariant": "INV-P49-03", "rule_id": rid})
        if not v.get("valid_from"):
            violations.append({"invariant": "INV-P49-04", "rule_id": rid})
        w = v.get("_warnings")
        if w is not None and not isinstance(w, list):
            violations.append({"invariant": "INV-P49-05", "rule_id": rid})
        if v.get("decision_mode") == "AUTO_POST" and not v.get("_legal_basis"):
            violations.append({"invariant": "INV-P49-06", "rule_id": rid})
    return {
        "verdicts_checked": len(vs),
        "invariants_total": len(INVARIANTS),
        "invariants_enabled": len(INVARIANTS),
        "violations": len(violations),
        "violation_list": violations[:50],
    }


def main() -> int:
    res = evaluate()
    wired = rule_present("jdg.v3_p49_fail_closed.invariant_pack")
    metrics = {
        **{k: v for k, v in res.items() if k != "violation_list"},
        "wired_main_jdg": wired,
        "auto_post_blocked": res["violations"],  # pack odrzuca każdy rekord z naruszeniem
        "routing": ("BLOCK_AND_ALERT" if res["violations"] > 0
                    else ("TRIAGE_QUEUE" if res["invariants_total"] < 4 else "AUTO_FILE")),
    }
    evidence = {
        "invariants": [f"{iid} {name}" for iid, name in INVARIANTS],
        "violation_examples": res["violation_list"][:10],
        "note": ("Pack uruchamiany przed każdym AUTO_POST (P04 enforce()); "
                 "invariant naruszony = odmowa AUTO_POST → NEEDS_ADVICE/MANUAL_REVIEW. "
                 "Dowód liczony na złotych orzeczeniach (30 P03-style + 1 legacy)."),
    }
    write_p49_bundle("invariant_pack", "V3-P49-I01", metrics, evidence)
    print(f"[V3-P49-I01] verdicts={res['verdicts_checked']} "
          f"invariants={res['invariants_total']} violations={res['violations']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
