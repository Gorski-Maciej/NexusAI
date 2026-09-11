#!/usr/bin/env python3
"""NexusAI JDG — V3-P48-I04 DRIFT HEATMAP — mapa cieplna dryfu per pakiet,
cel 0 dla wszystkich pakietów (podanalizy AN01/AN04). Trend: porównanie z
poprzednim zapisem heatmapy (backlog rosnący = TRIAGE).
"""
from __future__ import annotations

from v3_p48_common import (BUNDLES_DIR, drift_by_package, measure_drift,
                           read_json, rule_present, write_bundle, write_json)

INNOVATION = "V3-P48-I04"
RULE = "jdg.v3_p48_mirror_sync.drift_heatmap"
DRIFT_BLOCK_PCT = 20.0  # fallback; runtime czyta data.jdg.thresholds.v3_p48
HEATMAP_PATH = BUNDLES_DIR / "v3_p48_drift_heatmap.json"


def main() -> int:
    drift = measure_drift()
    pkgs = drift_by_package(drift)

    prev = read_json(HEATMAP_PATH) or {}
    prev_pkgs = {p["package"]: p for p in prev.get("packages", [])
                 if isinstance(p, dict) and "package" in p}

    rows = []
    for pkg, d in pkgs.items():
        prev_row = prev_pkgs.get(pkg, {})
        prev_dirty = prev_row.get("dirty", d["textual"] + d["semantic"] + d["missing"])
        dirty = d["textual"] + d["semantic"] + d["missing"]
        rows.append({
            "package": pkg,
            "total": d["total"],
            "clean": d["clean"],
            "textual": d["textual"],
            "semantic": d["semantic"],
            "missing": d["missing"],
            "orphan": d.get("orphan", 0),
            "dirty": dirty,
            "drift_pct": d["drift_pct"],
            "dirty_prev": prev_dirty,
            "trend": "rising" if dirty > prev_dirty else ("falling" if dirty < prev_dirty else "flat"),
        })

    packages_total = len(rows)
    packages_clean = sum(1 for r in rows if r["dirty"] == 0)
    worst = max((r["drift_pct"] for r in rows), default=0.0)
    trend_rising = any(r["trend"] == "rising" for r in rows)

    write_json(HEATMAP_PATH, {"generated_at": __import__("v3_p48_common").utcnow_iso(),
                              "packages": rows})

    has_rule = rule_present(RULE)
    checks = [
        {"name": "heatmap_generated", "status": "OK",
         "detail": f"pakiety: {packages_total}, czyste: {packages_clean}, "
                   f"najgorszy dryf: {worst}% (próg blokady {DRIFT_BLOCK_PCT}%)"},
        {"name": "worst_drift_gate", "status": "OK" if worst <= DRIFT_BLOCK_PCT else "BLOCK",
         "detail": f"najgorszy pakiet {worst}% vs próg {DRIFT_BLOCK_PCT}%"},
        {"name": "trend", "status": "OK" if not trend_rising else "TRIAGE",
         "detail": "trend rosnący — backlog naprawy rośnie" if trend_rising else
                   "trend nie rosnący (flat/falling)"},
        {"name": "rule_present", "status": "OK" if has_rule else "FAIL",
         "detail": f"reguła {RULE}: {has_rule}"},
    ]
    findings = []
    if worst > DRIFT_BLOCK_PCT:
        findings.append({"severity": "HIGH",
                         "message": f"dryf pakietu {worst}% > próg blokady — deploy z mirror ZABLOKOWANY"})
    if trend_rising:
        findings.append({"severity": "MEDIUM", "message": "trend dryfu rosnący — przyspieszyć naprawy"})

    routing = "BLOCK_AND_ALERT" if worst > DRIFT_BLOCK_PCT else (
        "TRIAGE_QUEUE" if (trend_rising or packages_clean < packages_total) else "AUTO_FILE")
    metrics = {
        "packages_total": packages_total,
        "packages_clean": packages_clean,
        "worst_package_drift": worst,
        "trend_rising": trend_rising,
        "target_pct": 100.0,
        "routing": routing,
    }
    evidence = {"heatmap_top": rows[:60], "checks": checks, "findings": findings}
    write_bundle("drift_heatmap", INNOVATION, metrics, evidence)
    print(f"[{INNOVATION}] routing={routing} packages={packages_total} "
          f"clean={packages_clean} worst={worst}% trend_rising={trend_rising}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
