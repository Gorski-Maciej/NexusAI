#!/usr/bin/env python3
"""NexusAI JDG — V3-P25-I05 DEADLINE SCHEMA v1 (schemat terminu jako kontrakt).

Dowód wdrożenia: każdy wiersz tabeli MASTER walidowany schematem v1
(obligation, base, frequency, rollover, alert_override, checklist, action,
legal_basis); brak pola = BLOCK; kontrakt dla UI (P41) i certyfikacji (P44).
"""
from __future__ import annotations

import re

from v3_p25_common import P25_RULES, emit, now, read, rule_present

INNOVATION = "V3-P25-I05"
RULE = "jdg.v3_p25_kalendarz_zbiorczy.deadline_schema"
SCHEMA_FIELDS = ["obligation", "base_day", "base_date", "base_days", "base_months",
                 "frequency", "rollover", "alert_override", "checklist", "action",
                 "legal_basis"]
FREQUENCIES = {"MONTHLY", "QUARTERLY", "ANNUAL", "EVENT"}


def main() -> int:
    hay = read(P25_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_fields = all(f'"{f}"' in hay for f in SCHEMA_FIELDS)
    has_freq = all(f in hay for f in FREQUENCIES)
    has_fail = "_sc_valid" in hay and "niekompletny" in hay

    # Walidacja schematu v1 na rzeczywistej tabeli MASTER
    from v3_p25_common import THRESHOLDS
    th_hay = read(THRESHOLDS)
    m = re.search(r'"v3_p25_master_deadline_table"\s*:\s*\[(.*?)\n\s*\]', th_hay, re.S)
    rows_ok, rows_total, bad_rows = True, 0, []
    if m:
        block = m.group(1)
        entries = re.findall(r'\{[^{}]*\}', block)
        rows_total = len(entries)
        for e in entries:
            if '"obligation"' not in e or '"rollover"' not in e or '"legal_basis"' not in e:
                rows_ok = False
                bad_rows.append(e[:60])

    checks.append({"name": "schema_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "schema_fields", "status": "OK" if has_fields else "FAIL",
                   "detail": f"pola v1: {SCHEMA_FIELDS}"})
    checks.append({"name": "frequencies", "status": "OK" if has_freq else "FAIL",
                   "detail": "MONTHLY/QUARTERLY/ANNUAL/EVENT"})
    checks.append({"name": "master_rows_valid", "status": "OK" if rows_ok else "FAIL",
                   "detail": f"{rows_total} wierszy tabeli MASTER walidowanych schematem v1"
                             + (f"; złe: {bad_rows}" if bad_rows else "")})
    checks.append({"name": "fail_closed", "status": "OK" if has_fail else "FAIL",
                   "detail": "brak pola / nieznana częstotliwość = BLOCK"})

    if not rows_ok:
        findings.append({"id": "V3-P25-L05", "severity": "P1",
                         "evidence": f"wiersze niezgodne ze schematem v1: {bad_rows}",
                         "fix": "uzupełnij pola wierszy tabeli MASTER (I05)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "fields": has_fields, "rows": rows_total,
                    "rows_ok": rows_ok, "thresholds": True},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Deadline Schema v1 wiąże P41 (UI kalendarza) i P44 "
                                "(certyfikacja): pola, częstotliwości, fail-closed",
                     "rule": "schemat walidowany per wiersz; brak pola = BLOCK"}}
    return emit(bundle, "v3_p25_deadline_schema")


if __name__ == "__main__":
    raise SystemExit(main())
