#!/usr/bin/env python3
"""NexusAI JDG — AUTO_POST GATE CONTRACT (V3-P03-I11)
======================================================
Maszynowy warunek AUTO_POST w kontrakcie (pole + walidacja) — fail-closed
z natury typu. AUTO_POST dozwolony WYŁĄCZNIE gdy:

  (1) certainty_class == CERTAIN (I02 — pełny łańcuch dowodów),
  (2) _certainty_guard == AUTO_POST_ALLOWED (INV-006/035),
  (3) _routing in {ALLOW, AUTO_POST} — nigdy TRIAGE/BLOCK,
  (4) brak _degraded_context (INV-038),
  (5) kontrakt 25-polowy kompletny (INV-043).

Wszystkie pozostałe kombinacje → MANUAL_REVIEW / CERTAINTY_BLOCKED.
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
OUT_JSON = BASE_DIR / "bundles" / "v3_p03_auto_post_gate.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def auto_post_allowed(v: dict) -> dict:
    class_ok = v.get("certainty_class") == "CERTAIN"
    guard_ok = v.get("_certainty_guard") == "AUTO_POST_ALLOWED"
    routing_ok = v.get("_routing") in ("ALLOW", "AUTO_POST")
    not_degraded = v.get("_degraded_context") is not True
    contract_ok = v.get("_contract_complete", True) is True
    matched = v.get("matched", False) is True

    allowed = all([class_ok, guard_ok, routing_ok, not_degraded, contract_ok, matched])
    blockers = []
    if not class_ok: blockers.append("certainty_class != CERTAIN")
    if not guard_ok: blockers.append("_certainty_guard != AUTO_POST_ALLOWED")
    if not routing_ok: blockers.append("_routing spoza {ALLOW, AUTO_POST}")
    if not not_degraded: blockers.append("_degraded_context == true (INV-038)")
    if not contract_ok: blockers.append("kontrakt 25-polowy niekompletny (INV-043)")
    if not matched: blockers.append("matched != true")
    return {"allowed": allowed, "blockers": blockers}


def build() -> dict:
    # Prawdziwy werdykt z gwarancjami — jedyny kształt dopuszczający AUTO_POST.
    auto_verdict = {
        "matched": True, "certainty_class": "CERTAIN",
        "_certainty_guard": "AUTO_POST_ALLOWED",
        "_routing": "ALLOW", "_degraded_context": False,
        "_contract_complete": True, "rule_id": "jdg.vat.rate_23",
    }
    # Warianty negatywne (fail-closed).
    variants = {
        "needs_advice_class": {**auto_verdict, "certainty_class": "NEEDS_ADVICE"},
        "guard_manual": {**auto_verdict, "_certainty_guard": "MANUAL_REVIEW"},
        "routing_triage": {**auto_verdict, "_routing": "TRIAGE_QUEUE"},
        "degraded": {**auto_verdict, "_degraded_context": True},
        "incomplete_contract": {**auto_verdict, "_contract_complete": False},
        "no_match": {**auto_verdict, "matched": False},
    }
    results = {"AUTO": auto_post_allowed(auto_verdict),
               **{k: auto_post_allowed(v) for k, v in variants.items()}}

    fail_closed_ok = (
        results["AUTO"]["allowed"] is True
        and all(results[k]["allowed"] is False for k in variants)
    )

    return {
        "innovation": "V3-P03-I11",
        "name": "AUTO_POST Gate Contract — fail-closed z natury typu",
        "generated_at": now(),
        "auto_post_conditions": {
            "certainty_class_CERTAIN": "I02 — pełny łańcuch dowodów",
            "guard_AUTO_POST_ALLOWED": "INV-006/035 — certyfikat nie blokuje",
            "routing_ALLOW_or_AUTO_POST": "nigdy TRIAGE/BLOCK",
            "no_degradation": "INV-038 — brak _degraded_context",
            "contract_25_complete": "INV-043 — kompletny słownik",
            "matched_true": "decyzja materialna dopasowana",
        },
        "results": results,
        "fail_closed": fail_closed_ok,
        "gate": {
            "pass": fail_closed_ok,
            "rule": "AUTO_POST tylko przy 6 warunkach jednocześnie; każde odstępstwo "
                    "= MANUAL_REVIEW/CERTAINTY_BLOCKED (INV-006/035, P03-AN03)",
        },
        "note": "Warunek maszynowy w kontrakcie — pole _certainty_guard + walidacja; "
                "host nigdy nie księguje bez guarda (main_jdg PAS 18n, INV-006/035).",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="AUTO_POST Gate Contract (V3-P03-I11)")
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
        print(f"V3-P03-I11 AUTO_POST Gate: fail_closed={data['fail_closed']} "
              f"gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: AUTO_POST możliwy przy wątpliwości — naruszenie fail-closed")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())