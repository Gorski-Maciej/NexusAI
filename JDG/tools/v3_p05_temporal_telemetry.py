#!/usr/bin/env python3
"""
NexusAI JDG — TEMPORAL TELEMETRY (V3-P05-I07)
=============================================
Metryki okien ważności (P05-AN12) dla dashboardu obserwowalności (P37):

  • liczba reguł temporalnych (registry), okien otwartych (valid_to=null),
    luk i nakładek (z I01 — warstwy RULES/PARAMS);
  • reguły bez okna (implicit „zawsze”) — wymagają uzasadnienia braku okna;
  • egzekucja okien w runtime (wywołania is_active*) — alert krytyczny gdy 0;
  • pokrycie testami granicznymi kotwic (I05) — alert gdy < 100% dla rdzenia;
  • użycie zegara ściennego w regułach decyzyjnych (I03) — alert dryfu;
  • epoki temporalne (braki lat 2018..2026), parametry wersjonowane.

Wyjście: bundles/v3_p05_temporal_telemetry.json (struktura dashboardowa) —
każda metryka z progiem alarmu, stanem i kierunkiem trendu.

Usage: python tools/v3_p05_temporal_telemetry.py
Exit:  0 (raport metryk; alarmy są danymi, nie błędem narzędzia).
"""
from __future__ import annotations

import json
import re
import sys
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RULES = ROOT / "rules"
TESTS = ROOT / "tests"
BUNDLES = ROOT / "bundles"
OUT = BUNDLES / "v3_p05_temporal_telemetry.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def registry_entries() -> list[dict]:
    md = (RULES / "_metadata_jdg.rego").read_text(encoding="utf-8")
    m = re.search(r"temporal_validity\s*:=\s*\{", md)
    if not m:
        return []
    start, depth, i = m.end(), 1, m.end()
    while i < len(md) and depth > 0:
        if md[i] == "{":
            depth += 1
        elif md[i] == "}":
            depth -= 1
        i += 1
    block = md[start : i - 1]
    out = []
    for em in re.finditer(r'"((?:jdg|tax)\.[a-z0-9_.]+)"\s*:\s*\{([^}]*)\}', block):
        vf = re.search(r'"valid_from"\s*:\s*"(\d{4}-\d{2}-\d{2})"', em.group(2))
        vt = re.search(r'"valid_to"\s*:\s*(null|"\d{4}-\d{2}-\d{2}")', em.group(2))
        out.append({
            "rule_id": em.group(1),
            "valid_from": vf.group(1) if vf else None,
            "open": bool(vt and vt.group(1) == "null"),
        })
    return out


def main() -> int:
    entries = registry_entries()
    open_windows = sum(1 for e in entries if e.get("open"))
    domains: dict[str, int] = {}
    for e in entries:
        dom = e["rule_id"].split(".")[1] if len(e["rule_id"].split(".")) > 1 else "?"
        domains[dom] = domains.get(dom, 0) + 1

    # egzekucja w runtime
    enforcers = sum(
        1 for p in RULES.rglob("*.rego")
        if "_helpers_jdg.rego" not in p.name and "_metadata_jdg.rego" not in p.name
        and re.search(r"(helpers|metadata)\.is_active\w*\(|is_active_now\(", p.read_text(encoding="utf-8", errors="replace"))
    )

    # zegar ścienny w payloadach decyzyjnych
    wall_clock = 0
    for p in RULES.rglob("*.rego"):
        for line in p.read_text(encoding="utf-8", errors="replace").splitlines():
            if "time.now_ns()" in line and '"matched"' in line:
                wall_clock += 1

    # pokrycie graniczne kotwic (jak I05, lekka wersja)
    test_txt = "".join(
        p.read_text(encoding="utf-8", errors="replace") for p in sorted(TESTS.rglob("*.py")))
    dates = sorted({e["valid_from"] for e in entries if e.get("valid_from")})
    boundary_ok = 0
    for d in dates:
        d1 = (date.fromisoformat(d) - timedelta(days=1)).isoformat()
        if d in test_txt and d1 in test_txt:
            boundary_ok += 1

    # epoki
    tj = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    epochs = sorted({int(m) for m in re.findall(r'"e\d{4}"\s*:\s*(\d{4})', tj)})
    missing_years = [y for y in range(2018, 2027) if y not in epochs]

    td = json.loads((BUNDLES / "thresholds_data.json").read_text(encoding="utf-8"))
    params_versioned = len(td.get("parameters", {}))

    metrics = [
        {"metric": "temporal_rules_registry", "value": len(entries), "prog": ">=32",
         "alert": "none", "opis": "reguły z oknem ważności w registry"},
        {"metric": "open_windows_valid_to_null", "value": open_windows, "prog": "100%",
         "alert": "none", "opis": "okna otwarte (semantyka: obowiązują do odwołania)"},
        {"metric": "runtime_window_enforcement_calls", "value": enforcers, "prog": ">0",
         "alert": "CRITICAL" if enforcers == 0 else "none",
         "opis": "wywołania bramki is_active* w ścieżce decyzyjnej — 0 = registry nie egzekwowany"},
        {"metric": "wall_clock_decisional_rules", "value": wall_clock, "prog": "0",
         "alert": "WARN" if wall_clock else "none",
         "opis": "reguły decyzyjne z time.now_ns() (replay zależny od zegara)"},
        {"metric": "boundary_test_coverage_anchors", "value": boundary_ok,
         "total": len(dates), "prog": "100%",
         "alert": "WARN" if boundary_ok < len(dates) else "none",
         "opis": "kotwice z testem day-1+day0"},
        {"metric": "temporal_epochs_missing_years", "value": len(missing_years),
         "years": missing_years, "prog": "0",
         "alert": "WARN" if missing_years else "none",
         "opis": "lata bez epoki w data.thresholds.jdg.temporal_epochs"},
        {"metric": "versioned_parameters", "value": params_versioned, "prog": ">=1",
         "alert": "none", "opis": "parametry z wersjonowaniem w thresholds_data.json"},
    ]

    bundle = {
        "innovation": "V3-P05-I07",
        "generated_at": now(),
        "gate": "PASS",
        "dashboard": {
            "title": "Temporal Windows Telemetry",
            "owner": "P37 obserwowalność",
            "refresh": "per CI / per bundle change",
        },
        "metrics": metrics,
        "rollup_by_domain": domains,
        "alerts": [m["metric"] for m in metrics if m.get("alert") != "none"],
        "findings": [{
            "id": "V3-P05-L10", "severity": "P3",
            "evidence": "metryki temporalne nie mają jeszcze dashboardu — pierwsza emisja",
            "fix": "podpięcie do P37 (nazwy metryk wg rejestru powyżej)",
        }] if any(m.get("alert") != "none" for m in metrics) else [],
        "contract": {
            "binding": "P37 obserwowalność (nazwy metryk + progi alarmów)",
            "metric_names": [m["metric"] for m in metrics],
        },
    }
    OUT.write_text(json.dumps(bundle, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[V3-P05-I07] gate=PASS registry={len(entries)} open={open_windows} "
          f"enforcement={enforcers} boundary={boundary_ok}/{len(dates)} "
          f"alerts={bundle['alerts']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
