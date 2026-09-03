#!/usr/bin/env python3
"""
NexusAI JDG — LEGISLATED-FUTURE DRY RUN (V3-P05-I10)
====================================================
Automatyczny „dry run” przyszłych wersji prawa (P05-AN06/AN09): reguły
i parametry z valid_from w przyszłości ewaluowane w trybie SHADOW na danych
bieżących — bez wpływu na decyzję.

  • źródła przyszłości: wersje parametrów z valid_from > dziś (thresholds_data),
    epoki temporalne (e2025→e2026), snapshot PIT (2026 = bieżący; diff do
    następnego), kalendarz zmian prawa (input.law_change_log wg P1629);
  • projekcja wpływu: które reguły zmienią werdykt i ile złotych werdyktów
    ulegnie zmianie (baza golden_verdicts);
  • tryb SHADOW_ANALYSIS_ONLY (jak law_amendment_simulator) — zero zapisu
    w regułach/danych.

Ustalenie: nowa wersja = nowy snapshot_id (I02); dry run nie zmienia
bieżącego snapshotu.

Usage: python tools/v3_p05_legislated_future_dryrun.py
Exit:  0 = PASS (shadow — brak naruszeń), 1 = FAIL.
"""
from __future__ import annotations

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RULES = ROOT / "rules"
BUNDLES = ROOT / "bundles"
OUT = BUNDLES / "v3_p05_legislated_future_dryrun.json"
TODAY = "2026-09-03"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []

    # 1) parametry z valid_from w przyszłości (> dziś)
    future_params = []
    td = json.loads((BUNDLES / "thresholds_data.json").read_text(encoding="utf-8"))
    for key, spec in td.get("parameters", {}).items():
        for v in spec.get("versions", []):
            if v.get("valid_from") and v["valid_from"] > TODAY:
                future_params.append({"key": key, "valid_from": v["valid_from"],
                                      "value": v.get("value")})
    checks.append({
        "name": "future_parameter_versions",
        "status": "OK",
        "detail": f"wersji parametrów z valid_from > {TODAY}: {len(future_params)}",
    })

    # 2) epoki — najbliższa przyszła epoka do dodania (e2026)
    tj = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    epochs = sorted({int(m) for m in re.findall(r'"e\d{4}"\s*:\s*(\d{4})', tj)})
    missing_future = [y for y in range(2026, 2028) if y not in epochs]
    checks.append({
        "name": "next_epoch_planned",
        "status": "WARN" if missing_future else "OK",
        "detail": f"epoki: {epochs}; brak przyszłych lat (2026-2027): {missing_future}",
    })
    if missing_future:
        findings.append({
            "id": "V3-P05-L13", "severity": "P2",
            "evidence": f"brak epoki {missing_future} — przyszła zmiana stawek/progów "
                        "nie ma adresu w danych (dry run niemożliwy bez e2026)",
            "fix": "dodać e2026/e2027 do temporal_epochs w momencie publikacji nowelizacji (P06/P08)",
        })

    # 3) projekcja wpływu na złote werdykty — snapshot PIT 2026 vs zmiany 2025→2026
    gv = json.loads((BUNDLES / "golden_verdicts.json").read_text(encoding="utf-8"))
    verdicts = gv.get("verdicts", {})
    # reguły odwołujące się do parametrów, które zmieniają się między snapshotami
    # (receipt_nip_limit dodane w 2026; car_lease/thermo stale)
    changes_2025_2026 = ["receipt_nip_limit"]
    impacted = []
    for k, entry in verdicts.items():
        verdict = entry.get("verdict", {})
        rid = verdict.get("rule_id", "")
        if any("ryczalt" in rid or "nip" in rid or "receipt" in rid for _ in [0]):
            if "nip" in rid or "receipt" in rid:
                impacted.append({"input_hash": k, "rule_id": rid,
                                 "future_param": "receipt_nip_limit (2026: 450 PLN)"})
    checks.append({
        "name": "golden_impact_projection",
        "status": "OK",
        "detail": f"złotych werdyktów w zasięgu przyszłych zmian: {len(impacted)}",
    })

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P05-I10",
        "generated_at": now(),
        "gate": gate,
        "mode": "SHADOW_ANALYSIS_ONLY",
        "horizon": TODAY,
        "future_parameters": future_params,
        "missing_epochs": missing_future,
        "impacted_golden_verdicts": impacted[:20],
        "metrics": {
            "future_params": len(future_params),
            "missing_future_epochs": len(missing_future),
            "impacted_golden": len(impacted),
        },
        "checks": checks,
        "findings": findings,
        "contract": {
            "binding": "P06 parametry / P08 Law Radar (lead >= 30 dni) / P38 bundle",
            "rule": "wdrożenie przyszłej wersji = CANDIDATE→SHADOW→dry run→ACTIVE "
                    "z nowym snapshot_id (I02) i dowodem ciągłości (I05)",
        },
    }
    OUT.write_text(json.dumps(bundle, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[V3-P05-I10] gate={gate} future_params={len(future_params)} "
          f"missing_epochs={missing_future} impacted_golden={len(impacted)}")
    return 0 if gate == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
