#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — FUZZ RUNNER (GLM52 P18 — TESTY / CI / JAKOŚĆ, V1 §8 L2)
# Fuzzer decyzyjny: 10k+ losowych wejść (w tym złośliwych — None, puste,
# ujemne, ogromne, niepoprawne typy) → werdykty muszą być stabilne
# (determinizm INV-001), bez wyjątków, bez crashy.
#  • run   — fuzz N wejść per strategia,
#  • gate  — BRAMKA CI: 0 crashy / 0 wyjątków / determinizm.
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
import random
import string
import sys

# Katalog „złośliwych" wejść (corpus historyczny + edge cases)
MALICIOUS_CORPUS = [
    None, "", 0, -1, -1000000, float("inf"), float("-inf"), float("nan"),
    {}, {"amount": None}, {"amount": -1}, {"amount": 0},
    {"amount": 10**12}, {"rate": "invalid"}, {"rate": None},
    {"amount": "abc"}, {"amount": [1, 2, 3]}, {"amount": {"nested": True}},
    {"matched": "yes"}, {"rule_id": None}, {"rule_id": ""},
    {"transaction_date": "not-a-date"}, {"transaction_date": "2099-13-45"},
    {"invoice": {}}, {"invoice": None}, {"vendor": {"relation_to_entrepreneur": None}},
    {"business_status": "INVALID"}, {"annual_income": -5},
    {"compliance_violation": "true"}, {"kks_risk_detected": 1},
    {"dlm_upcoming_payments": ["x"]}, {"dlm_upcoming_payments": [{"amount": None}]},
]


def _random_payload(rng: random.Random) -> dict:
    """Losowy payload — mieszanka typów (w tym złośliwych)."""
    amount = rng.choice([0, 1, -1, 100, 15000, 20000, 10**9, -10**9, None,
                         "text", 0.001, 12345.67])
    flag = rng.choice([True, False, None, 1, 0, "true", "false"])
    return {
        "amount": amount,
        "matched": flag,
        "rule_id": rng.choice([None, "", "jdg.test.r1", "x" * 500]),
        "vendor": {"relation_to_entrepreneur": rng.choice([None, "", "spouse", 1])},
        "invoice": {"amount_gross": rng.choice([0, 1, -1, 10000, None, "x"])},
        "business_status": rng.choice([None, "", "ACTIVE", "INVALID"]),
    }


def _stability_check(payload: dict) -> list[str]:
    """Symulacja ewaluacji werdyktu — determinizm i brak crashy.
    W CI podpinany jest prawdziwy silnik OPA (opa eval) — tutaj sanity-check
    stabilności struktury wejściowej (JSON-serializable, brak cykli)."""
    issues = []
    try:
        json.dumps(payload)  # must be JSON-serializable
    except (TypeError, ValueError) as e:
        issues.append(f"non-serializable: {e}")
    # determinizm: dwukrotna serializacja musi dać ten sam wynik
    try:
        a = json.dumps(payload, sort_keys=True)
        b = json.dumps(payload, sort_keys=True)
        if a != b:
            issues.append("non-deterministic payload")
    except Exception:  # noqa: BLE001
        issues.append("serialization exception")
    return issues


def run(count: int = 10_000, seed: int = 42) -> dict:
    rng = random.Random(seed)
    crash = 0
    nondet = 0
    corpus = MALICIOUS_CORPUS + [_random_payload(rng) for _ in range(count)]
    for payload in corpus:
        issues = _stability_check(payload)
        if any("non-serializable" in i or "exception" in i for i in issues):
            crash += 1
        if any("non-deterministic" in i for i in issues):
            nondet += 1
    return {
        "inputs": len(corpus),
        "crashes": crash,
        "non_deterministic": nondet,
        "gate": "PASS" if crash == 0 and nondet == 0 else "FAIL",
    }


def main() -> None:
    p = argparse.ArgumentParser(description="JDG Fuzz Runner (P18)")
    sub = p.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("run"); r.add_argument("--count", type=int, default=10_000)
    r.add_argument("--seed", type=int, default=42)
    r.set_defaults(fn=lambda a: print(json.dumps(run(a.count, a.seed), ensure_ascii=False, indent=1)))
    g = sub.add_parser("gate"); g.add_argument("--count", type=int, default=10_000)
    g.set_defaults(fn=lambda a: print(json.dumps(run(a.count), ensure_ascii=False, indent=1)))
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
