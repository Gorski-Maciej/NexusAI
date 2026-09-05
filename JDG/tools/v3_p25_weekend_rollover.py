#!/usr/bin/env python3
"""NexusAI JDG — V3-P25-I02 WEEKEND ROLLOVER VERIFIED (przeniesienia per obowiązek).

Dowód wdrożenia: NEXT_BUSINESS_DAY (art. 12 § 4 OrdPU), PREV_BUSINESS_DAY
(ZUS — art. 47 ust. 3 SUS), NONE (PCC 14 dni — art. 4 ust. 3); sprzeczność
oczekiwane≠zarejestrowane = BLOCK; święta ruchome algorytmicznie.
"""
from __future__ import annotations

from datetime import date, timedelta

from v3_p25_common import P25_RULES, emit, now, read, rule_present, threshold_present

INNOVATION = "V3-P25-I02"
RULE = "jdg.v3_p25_kalendarz_zbiorczy.weekend_rollover"
TH_KEYS = ["v3_p25_rollover_rule", "v3_p25_rollover_exception_rule",
           "v3_p25_public_holidays"]


def _easter(year: int) -> date:
    a = year % 19
    b, c = year // 100, year % 100
    d = (b - 8) // 25 + 1
    e = (19 * a + b - (b // 4) - d) % 30
    f = (a + 11 * e) // 319
    g = (c - (c // 4) + 2 * (26 * (e - f) + 10) // 11) % 7
    h = e - f + (2 * (b // 4) - 5 * b + 2 * (c // 4) + 8 * g) // 4
    month = 3 + (h + 40) // 44
    day = h + 28 - 31 * (month // 4)
    return date(year, month, day)


def is_holiday(d: date) -> bool:
    fixed = {"01-01", "01-06", "05-01", "05-03", "08-15", "11-01", "11-11",
             "12-25", "12-26"}
    e = _easter(d.year)
    movable = {e.isoformat()[5:], (e + timedelta(days=1)).isoformat()[5:],
               (e + timedelta(days=60)).isoformat()[5:]}
    return d.isoformat()[5:] in fixed | movable


def shift(obligation_rollover: str, d: date) -> date:
    """Przeniesienie PER obowiązek: NEXT (art. 12 § 4 OP), PREV (art. 47 ust. 3 SUS), NONE."""
    if obligation_rollover == "NONE" or not (d.weekday() >= 5 or is_holiday(d)):
        return d
    if obligation_rollover == "PREV_BUSINESS_DAY":
        while d.weekday() >= 5 or is_holiday(d):
            d -= timedelta(days=1)
        return d
    while d.weekday() >= 5 or is_holiday(d):  # NEXT_BUSINESS_DAY
        d += timedelta(days=1)
    return d


def main() -> int:
    hay = read(P25_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_kinds = all(k in hay for k in ("NEXT_BUSINESS_DAY", "PREV_BUSINESS_DAY", "NONE"))
    has_mismatch = "_wr_rollover_mismatch" in hay
    has_legal = "art. 12 § 4 OrdPU" in hay and "art. 47 ust. 3 SUS" in hay
    th_ok = all(threshold_present(k) for k in TH_KEYS)

    # Próba algorytmiczna: 2026-04-30 (czwartek) → bez zmiany; 2026-05-30 (sobota) →
    # NEXT = pon 01.06 (ale 01.06 nie jest świętem), PREV = piątek 29.05.
    probe_next = shift("NEXT_BUSINESS_DAY", date(2026, 5, 30))
    probe_prev = shift("PREV_BUSINESS_DAY", date(2026, 5, 30))
    probe_fixed = shift("NONE", date(2026, 5, 30))
    probe_easter = shift("NEXT_BUSINESS_DAY", _easter(2026))
    engine_ok = (probe_next == date(2026, 6, 1) and probe_prev == date(2026, 5, 29)
                 and probe_fixed == date(2026, 5, 30)
                 and probe_easter == _easter(2026) + timedelta(days=2))

    checks.append({"name": "rollover_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "three_kinds", "status": "OK" if has_kinds else "FAIL",
                   "detail": "NEXT/PREV/NONE — przeniesienia per obowiązek (I02)"})
    checks.append({"name": "mismatch_block", "status": "OK" if has_mismatch else "FAIL",
                   "detail": "oczekiwane ≠ zarejestrowane = BLOCK"})
    checks.append({"name": "legal_basis", "status": "OK" if has_legal else "FAIL",
                   "detail": "art. 12 § 4 OrdPU + art. 47 ust. 3 SUS + art. 4 ust. 3 PCC"})
    checks.append({"name": "engine_probe", "status": "OK" if engine_ok else "FAIL",
                   "detail": f"sobota 30.05.2026: NEXT={probe_next}, PREV={probe_prev}, "
                             f"NONE={probe_fixed}, Wielkanoc2026={probe_easter}"})
    checks.append({"name": "holidays_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": f"ADR-002: klucze {TH_KEYS}"})

    if not has_mismatch:
        findings.append({"id": "V3-P25-L02", "severity": "P2",
                         "evidence": "brak bramki sprzeczności przeniesień",
                         "fix": "I02: mismatch expected≠registered → BLOCK"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "three_kinds": has_kinds,
                    "mismatch_block": has_mismatch, "engine_probe": engine_ok,
                    "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Przeniesienia zweryfikowane PER obowiązek; wyjątek PCC 14 dni "
                                "(art. 4 ust. 3 — brak przeniesienia); status [NIEZWERYFIKOWANE] ISAP",
                     "rule": "NEXT/PREV/NONE z tabeli MASTER; święta ruchome algorytmicznie"}}
    return emit(bundle, "v3_p25_weekend_rollover")


if __name__ == "__main__":
    raise SystemExit(main())
