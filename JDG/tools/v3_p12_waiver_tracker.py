#!/usr/bin/env python3
"""
NexusAI JDG — V3-P12-I11 EXEMPTION WAIVER TRACKER
===================================================
Śledzenie rezygnacji/powrotu ze zwolnienia podmiotowego z temporalnością:
rezygnacja (VAT-R, art. 44), utrata po przekroczeniu limitu (art. 113 ust. 11 —
zakaz ponownego zwolnienia przez 2 lata), powrót. Sprawdza: reguły utraty/
rezygnacji w plikach VAT, okres 2 lat, temporalność.

Usage:
  python tools/v3_p12_waiver_tracker.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
RULES = BASE / "rules"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    vat_files = (list(RULES.glob("vat/*.rego")) + list(RULES.glob("micro/vat/*.rego"))
                 + [p for p in RULES.glob("*.rego") if "vat" in p.name])
    vat_hay = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                        for p in vat_files if p.exists())
    params = json.loads((BUNDLES / "thresholds_data.json").read_text(encoding="utf-8")).get("parameters", {})

    # 1. Reguła utraty zwolnienia (P141: jdg.vat.substantive.exemption_loss_2_years)
    #    — faktyczny stan: istnieje w substantive.rego (art. 113 ust. 14)
    loss_rule = re.findall(r'"rule_id"\s*:\s*"jdg\.[^"]*(?:exemption_loss|loss_after)[^"]*"',
                           vat_hay)
    has_p141 = "jdg.vat.substantive.exemption_loss_2_years" in vat_hay
    # 2. Temporalność utraty (rok utraty → zakaz do końca N+2)
    has_temporal = "suspended_until" in vat_hay and "suspended_years" in vat_hay
    # 3. Reguła rezygnacji dobrowolnej (art. 44 VAT — dobrowolna rezygnacja)
    voluntary_waiver = bool(re.search(r"rezygnacj.{0,80}(?:zwolnien|VAT-R)|VAT-R.{0,80}rezygnacj",
                                      vat_hay, re.I))
    # 4. Parametryzacja okna (2 lata jako parametr?) — fakty: 2 jest w treści reguły
    window_param = {k: v for k, v in params.items()
                    if "113" in k or "exemption" in k or "loss" in k or "2y" in k}
    has_2y_as_data = "vat_exemption_suspended_years" in vat_hay and \
        any(k in vat_hay for k in ("data.thresholds", "data.parameters"))
    # 5. Ostrzeżenie użytkownikowi (warnings)
    has_warning = bool(re.search(r"_warnings.*(?:UTRATA|2 LATA|2 lata)", vat_hay, re.I | re.S))

    checks.append({"name": "loss_rule",
                   "status": "OK" if has_p141 else "FAIL",
                   "detail": f"reguła utraty zwolnienia (P141 exemption_loss_2_years): {has_p141}"})
    checks.append({"name": "temporal_tracking",
                   "status": "OK" if has_temporal else "FAIL",
                   "detail": f"temporalność utraty (suspended_until/suspended_years): {has_temporal}"})
    checks.append({"name": "window_as_data",
                   "status": "OK" if (window_param or has_2y_as_data) else "FAIL",
                   "detail": f"okno jako dane: {window_param or has_2y_as_data}"})
    checks.append({"name": "voluntary_waiver",
                   "status": "OK" if voluntary_waiver else "FAIL",
                   "detail": f"rezygnacja dobrowolna (VAT-R): {voluntary_waiver}"})

    if not has_p141:
        findings.append({"id": "V3-P12-L11", "severity": "P0",
                         "evidence": "brak reguły utraty zwolnienia podmiotowego na 2 lata "
                                     "w plikach VAT",
                         "fix": "I11: Exemption Waiver Tracker — reguła utraty z temporalnością"})
    elif not (window_param or has_2y_as_data):
        findings.append({"id": "V3-P12-L11b", "severity": "P2",
                         "evidence": "okno zakazu (2 lata = vat_exemption_suspended_years) "
                                     "jest literałem w treści reguły P141 (substantive.rego), "
                                     "nie daną z data.thresholds (ADR-002/P06) — zmiana okresu "
                                     "wymaga edycji rego",
                         "fix": "I11: okno jako parametr vat.exemption_suspended_years"})
    if not voluntary_waiver:
        findings.append({"id": "V3-P12-L11c", "severity": "P3",
                         "evidence": "brak jawnej obsługi dobrowolnej rezygnacji (VAT-R) w "
                                     "plikach VAT — sprawdzić w P07 lifecycle",
                         "fix": "I11: śledzenie rezygnacji dobrowolnej z datą"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P12-I11", "generated_at": now(), "gate": gate,
        "metrics": {"loss_rule": has_p141, "temporal_tracking": has_temporal,
                    "window_as_data": bool(window_param or has_2y_as_data),
                    "window_params": window_param, "voluntary_waiver": voluntary_waiver,
                    "user_warning": has_warning},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P05 (temporalność), P07 (lifecycle), P44",
                     "rule": "utrata zwolnienia (art. 113 ust. 11) śledzona temporalnie z "
                             "okresem zakazu; przekroczenie = warning + zakaz powrotu"}}
    (BUNDLES / "v3_p12_waiver_tracker.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P12-I11] gate={gate} loss_rule={has_p141} window_data={bool(window_param or has_2y_as_data)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
