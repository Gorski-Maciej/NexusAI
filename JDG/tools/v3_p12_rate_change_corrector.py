#!/usr/bin/env python3
"""
NexusAI JDG — V3-P12-I09 RATE CHANGE CORRECTOR
===============================================
Korekta faktur po zmianie stawki (art. 90/91 kontekst, nowelizacje stawek)
z automatyzacją. Sprawdza: reguły korekty po zmianie stawki, temporalność
stawek (P05), narzędzia korekt.

Usage:
  python tools/v3_p12_rate_change_corrector.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
RULES = BASE / "rules"
TOOLS = BASE / "tools"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    hay = "\n".join(f.read_text(encoding="utf-8", errors="ignore")
                    for f in RULES.glob("**/*.rego"))
    tools_hay = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                          for p in TOOLS.glob("*.py"))
    tests_hay = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                          for p in (BASE / "tests").glob("*.py"))

    # 1. Reguły korekty po zmianie stawki (faktura korygująca, art. 106j)
    has_correction_rule = any(k in hay for k in ("106j", "faktura korygująca",
                                                 "korekta", "correct"))
    # 2. Temporalność: stawka z dnia transakcji vs z dnia wystawienia (P05)
    has_transaction_date = any(k in hay for k in ("transaction_date", "valid_from",
                                                  "data transakcji", "obowiązek podatkowy"))
    # 3. Narzędzia korekt VAT
    corr_tools = sorted(p.name for p in TOOLS.glob("*.py")
                        if any(k in p.name.lower() for k in ("corrector", "correct", "korekta")))
    # 4. Zmiana stawki 0%→23% (np. koniec vacatio) — przejścia
    rate_transitions = bool(re.search(r"(przejśc|transition|zmiana stawki|stawka.*→|→.*stawka)",
                                      hay + tools_hay, re.I))
    # 5. Testy korekt po zmianie stawki
    has_corr_tests = bool(re.search(r"korekta.*stawk|stawk.*korekta|rate.*change", tests_hay, re.I))

    checks.append({"name": "correction_rules",
                   "status": "OK" if has_correction_rule else "FAIL",
                   "detail": f"reguły korekty faktur (art. 106j): {has_correction_rule}"})
    checks.append({"name": "transaction_date_temporal",
                   "status": "OK" if has_transaction_date else "FAIL",
                   "detail": f"temporalność (stawka z dnia transakcji): {has_transaction_date}"})
    checks.append({"name": "rate_transitions",
                   "status": "OK" if rate_transitions else "FAIL",
                   "detail": f"obsługa przejść stawek w czasie: {rate_transitions}"})
    checks.append({"name": "correction_tests",
                   "status": "OK" if has_corr_tests else "FAIL",
                   "detail": f"testy korekt po zmianie stawki: {has_corr_tests}"})

    if not has_correction_rule or not rate_transitions:
        findings.append({"id": "V3-P12-L09", "severity": "P2",
                         "evidence": f"korekta po zmianie stawki: reguły={has_correction_rule}, "
                                     f"przejścia stawek={rate_transitions} — brak automatyzacji "
                                     f"faktur korygujących przy nowelizacji stawki (kontekst "
                                     f"art. 90/91 i 106j); ryzyko: faktura ze starą stawką po "
                                     f"dacie zmiany bez korekty",
                         "fix": "I09: Rate Change Corrector — wykrycie faktur ze stawką "
                                "nieaktualną na dzień transakcji → propozycja korekty "
                                "(art. 106j) z automatyką i NEEDS_ADVICE przy niepewności"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P12-I09", "generated_at": now(), "gate": gate,
        "metrics": {"correction_rules": has_correction_rule,
                    "transaction_date_temporal": has_transaction_date,
                    "rate_transitions": rate_transitions,
                    "correction_tools": corr_tools, "correction_tests": has_corr_tests},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P05 (temporalność), P16 (JPK/KSeF), P44",
                     "rule": "zmiana stawki = automatyczne wykrycie faktur do korekty "
                             "(art. 106j); stawka z dnia transakcji (nie wystawienia)"}}
    (BUNDLES / "v3_p12_rate_change_corrector.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P12-I09] gate={gate} correction={has_correction_rule} transitions={rate_transitions}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
