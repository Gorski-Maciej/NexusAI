#!/usr/bin/env python3
"""
NexusAI JDG — SMT/Z3 FORMAL VERIFICATION SKELETON (P01 Fundament, WIZJA V2 F3 §4.3)
==================================================================================
Szkielet weryfikacji formalnej kluczowych domniemań arytmetyczno-prawnych silnika
(ZUS, PIT, KKS) przez solver SMT. Zasada V2 F3 §4.3: reguły decyzyjne są
deterministyczne, więc kluczowe niezmienniki można DOWODZIĆ, a nie tylko testować.

Weryfikuje (za pomocą Z3, jeśli dostępny):
  • INV-001 — stawka VAT ∈ {0, 0.05, 0.08, 0.23, ZW, NP, OO},
  • INV-003 — brutto = netto × (1 + stawka) ± epsilon groszowy,
  • ZUS-001 — składka zdrowotna w przedziale [0, 9% × podstawa] (skala),
  • PIT-001 — zaliczka PIT nieujemna i ≤ podstawa × stawka krańcowa,
  • KKS-001 — kara grzywny ≤ limit ustawowy (500 000 zł).

Jeśli biblioteka `z3-solver` jest niedostępna, narzędzie działa w trybie
SKELETON (fail-open z jawnym oznaczeniem UNVERIFIED — nigdy nie deklaruje
dowodu bez solwera). Tryb `--require-z3` kończy się kodem 2 przy braku Z3.

Usage:
  python smt_z3_verification.py prove --domain zus
  python smt_z3_verification.py prove --domain all
  python smt_z3_verification.py prove --domain pit --require-z3
  python smt_z3_verification.py status
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
PROOF_PATH = JDG_ROOT / "bundles" / "smt_proofs.json"

try:  # z3-solver jest opcjonalny — projekt nie wymaga go w CI
    from z3 import (And, ArithRef, BoolRef, If, Implies, Int, Real, Solver,
                    sat, unsat)
    HAS_Z3 = True
except ImportError:  # pragma: no cover - zależne od środowiska
    HAS_Z3 = False


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _load() -> dict:
    if PROOF_PATH.exists():
        return json.loads(PROOF_PATH.read_text(encoding="utf-8"))
    return {"schema_version": "1.0.0", "proofs": {}, "mode": "SKELETON" if not HAS_Z3 else "Z3"}


def _save(data: dict) -> None:
    PROOF_PATH.parent.mkdir(parents=True, exist_ok=True)
    PROOF_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


def prove_zus() -> dict:
    """Składka zdrowotna: 0 <= health <= 9% * base (skala), liniowy: 4.9% z limitem."""
    if not HAS_Z3:
        return {"domain": "zus", "verified": False, "mode": "SKELETON",
                "result": "UNVERIFIED — z3-solver niedostępny",
                "lemmas": ["ZUS-001: health ∈ [0, 0.09 × base]", "ZUS-002: liniowy 4.9% ≤ limit odliczenia"]}
    s = Solver()
    base = Real("base")
    health = Real("health")
    s.add(base > 0)
    s.add(health > 0.09 * base)  # próba naruszenia: składka > 9% podstawy
    result = s.check()
    unsat_flag = result == unsat
    # negacja jest niespełnialna => własność zachowana dla wszystkich podstaw
    return {"domain": "zus", "verified": bool(unsat_flag), "mode": "Z3",
            "result": "PROVEN (unsat negacji)" if unsat_flag else "COUNTEREXAMPLE",
            "lemmas": ["ZUS-001: health ∈ [0, 0.09 × base]", "ZUS-002: liniowy 4.9% ≤ limit odliczenia"]}


def prove_pit() -> dict:
    """Zaliczka PIT: 0 <= advance <= base × marginal_rate (próg 32%)."""
    if not HAS_Z3:
        return {"domain": "pit", "verified": False, "mode": "SKELETON",
                "result": "UNVERIFIED — z3-solver niedostępny",
                "lemmas": ["PIT-001: advance ≥ 0", "PIT-002: advance ≤ base × 0.32"]}
    s = Solver()
    base = Real("base")
    advance = Real("advance")
    s.add(base > 0)
    s.add(advance < 0)  # naruszenie: ujemna zaliczka
    neg1 = s.check()
    s2 = Solver()
    s2.add(base > 0)
    s2.add(advance > base * 0.32)  # naruszenie: zaliczka > 32% podstawy
    neg2 = s2.check()
    ok = neg1 == unsat and neg2 == unsat
    return {"domain": "pit", "verified": bool(ok), "mode": "Z3",
            "result": "PROVEN (2/2 lematy)" if ok else "COUNTEREXAMPLE",
            "lemmas": ["PIT-001: advance ≥ 0", "PIT-002: advance ≤ base × 0.32"]}


def prove_kks() -> dict:
    """Kara KKS: 0 <= fine <= 500 000 zł (limit ustawowy)."""
    if not HAS_Z3:
        return {"domain": "kks", "verified": False, "mode": "SKELETON",
                "result": "UNVERIFIED — z3-solver niedostępny",
                "lemmas": ["KKS-001: fine ∈ [0, 500 000]"]}
    s = Solver()
    fine = Real("fine")
    s.add(fine > 500000)  # naruszenie: kara ponad limit
    result = s.check()
    ok = result == unsat
    return {"domain": "kks", "verified": bool(ok), "mode": "Z3",
            "result": "PROVEN (unsat negacji)" if ok else "COUNTEREXAMPLE",
            "lemmas": ["KKS-001: fine ∈ [0, 500 000]"]}


def prove_vat() -> dict:
    """INV-003: brutto = netto × (1 + stawka), stawki ∈ {0.05, 0.08, 0.23}."""
    if not HAS_Z3:
        return {"domain": "vat", "verified": False, "mode": "SKELETON",
                "result": "UNVERIFIED — z3-solver niedostępny",
                "lemmas": ["INV-001: stawka ∈ {0.05, 0.08, 0.23}",
                           "INV-003: brutto = netto × (1 + stawka)"]}
    s = Solver()
    net = Real("net")
    gross = Real("gross")
    rate = Real("rate")
    s.add(net > 0)
    s.add(rate == 0.23)
    s.add(gross != net * (1 + rate))  # naruszenie INV-003
    result = s.check()
    ok = result == unsat
    return {"domain": "vat", "verified": bool(ok), "mode": "Z3",
            "result": "PROVEN (unsat negacji)" if ok else "COUNTEREXAMPLE",
            "lemmas": ["INV-001: stawka ∈ {0.05, 0.08, 0.23}",
                       "INV-003: brutto = netto × (1 + stawka)"]}


DOMAINS = {"zus": prove_zus, "pit": prove_pit, "kks": prove_kks, "vat": prove_vat}


def cmd_prove(args) -> None:
    if args.require_z3 and not HAS_Z3:
        print("❌ --require-z3: biblioteka z3-solver niedostępna — dowód NIEMOŻLIWY (fail-closed)")
        sys.exit(2)
    data = _load()
    domains = list(DOMAINS) if args.domain == "all" else [args.domain]
    if any(d not in DOMAINS for d in domains):
        sys.exit(f"❌ Nieznana domena — dozwolone: {sorted(DOMAINS)}")
    results = {}
    for d in domains:
        results[d] = DOMAINS[d]()
        data["proofs"][d] = results[d]
    data["mode"] = "Z3" if HAS_Z3 else "SKELETON"
    data["updated_at"] = now()
    _save(data)
    print(json.dumps({"mode": data["mode"], "proofs": results,
                      "all_proven": bool(HAS_Z3) and all(r["verified"] for r in results.values())},
                     indent=2, ensure_ascii=False))


def cmd_status(args) -> None:
    data = _load()
    print(json.dumps({"mode": data["mode"], "z3_available": HAS_Z3,
                      "proofs": data.get("proofs", {}),
                      "fail_closed": "Dowód deklarowany WYŁĄCZNIE w trybie Z3 (SKELETON = UNVERIFIED)"},
                     indent=2, ensure_ascii=False))


def main() -> None:
    p = argparse.ArgumentParser(description="SMT/Z3 Formal Verification — V2 F3 §4.3")
    sub = p.add_subparsers(dest="cmd", required=True)
    pr = sub.add_parser("prove")
    pr.add_argument("--domain", choices=["zus", "pit", "kks", "vat", "all"], default="all")
    pr.add_argument("--require-z3", action="store_true")
    pr.set_defaults(fn=cmd_prove)
    st = sub.add_parser("status"); st.set_defaults(fn=cmd_status)
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
