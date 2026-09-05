#!/usr/bin/env python3
"""NexusAI JDG — V3-P25-I01 MASTER DEADLINE TABLE (jedno źródło prawdy).

Dowód wdrożenia: tabela MASTER terminów jako DANE (v3_p25_master_deadline_table),
17 obowiązków z bazą, przeniesieniem, alertami, checklistą, akcją i podstawą
prawną; nieznany obowiązek = BLOCK (fail-closed).
"""
from __future__ import annotations

import json
import re

from v3_p25_common import P25_RULES, emit, main_jdg_wired, now, read, rule_present, threshold_present

INNOVATION = "V3-P25-I01"
RULE = "jdg.v3_p25_kalendarz_zbiorczy.master_deadline_table"
TH_KEYS = ["v3_p25_master_deadline_table", "v3_p25_threshold_version"]
EXPECTED_OBLIGATIONS = 17


def main() -> int:
    hay = read(P25_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    th_ok = all(threshold_present(k) for k in TH_KEYS)

    # Tabela MASTER jako dane — parsujemy blok thresholds_jdg.rego
    th_hay = __import__("v3_p25_common").read(
        __import__("v3_p25_common").THRESHOLDS)
    rows = 0
    m = re.search(r'"v3_p25_master_deadline_table"\s*:\s*\[(.*?)\n\s*\]', th_hay, re.S)
    if m:
        rows = m.group(1).count('"obligation"')

    schema_ok = all(f in hay for f in ('"obligation"', '"base_day"', '"rollover"',
                                       '"alert_override"', '"checklist"', '"action"',
                                       '"legal_basis"'))
    fail_closed = "_mdt_unknown_flag" in hay and "pustynia kalendarza" in hay
    wired = main_jdg_wired()

    checks.append({"name": "master_table_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "table_as_data", "status": "OK" if rows >= EXPECTED_OBLIGATIONS else "FAIL",
                   "detail": f"obowiązków w tabeli MASTER: {rows} (wymagane ≥ {EXPECTED_OBLIGATIONS})"})
    checks.append({"name": "schema_v1_fields", "status": "OK" if schema_ok else "FAIL",
                   "detail": "pola schematu: obligation/base/rollover/alerts/checklist/action/legal_basis"})
    checks.append({"name": "fail_closed", "status": "OK" if fail_closed else "FAIL",
                   "detail": "nieznany obowiązek = BLOCK (pustynia kalendarza)"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": f"ADR-002: klucze {TH_KEYS}"})
    checks.append({"name": "main_jdg_wiring", "status": "OK" if wired else "FAIL",
                   "detail": "import + rejestr + final_verdict_p89"})

    if rows < EXPECTED_OBLIGATIONS:
        findings.append({"id": "V3-P25-L01", "severity": "P2",
                         "evidence": f"tabela MASTER ma {rows} wierszy (wymagane {EXPECTED_OBLIGATIONS})",
                         "fix": "dokończ inwentaryzację terminów (I01) w thresholds_jdg.rego"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "rows": rows, "schema": schema_ok,
                    "fail_closed": fail_closed, "thresholds": th_ok, "wired": wired},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Jedno źródło prawdy terminów dla P12/P14/P16/P19/P23/P26 "
                                "— konsumenci CZYTAJĄ tabelę, nie definiują własnych dat",
                     "rule": "tabela MASTER jako dane; nieznany obowiązek = BLOCK"}}
    return emit(bundle, "v3_p25_master_deadline_table")


if __name__ == "__main__":
    raise SystemExit(main())
