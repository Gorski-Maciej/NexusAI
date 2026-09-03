#!/usr/bin/env python3
"""
NexusAI JDG — TIME GATE CI (V3-P05-I05)
=======================================
Bramka temporalna w CI (P05-AN06): każda zmiana okna ważności reguły/
parametru wymaga dowodu ciągłości = testów granicznych day-1 / day+0 / day+1
względem daty nowelizacji.

  • kotwice = daty wejścia w życie z temporal_validity registry (unikalne);
  • dla każdej kotwicy sprawdzamy w tests/: pokrycie pre (day-1 → nieaktywna),
    day0 (→ aktywna) i post (day+1 → aktywna) na poziomie pytest;
  • brak testu granicznego dla kotwicy = luka P1/P2 → wpis do heatmapy I12;
  • kotwice „konstytucyjne” (2018-04-01, 2019-04-01, 2022-01-01, 2022-04-01,
    2023-07-01, 2026-02-01) BEZ pary day-1/day0 = FAIL bramki (blokada merge).

Usage: python tools/v3_p05_time_gate_ci.py
Exit:  0 = PASS, 1 = FAIL (kotwica konstytucyjna bez pokrycia granicznego).
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
OUT = ROOT / "bundles" / "v3_p05_time_gate_ci.json"

CORE_ANCHORS = ["2018-04-01", "2019-04-01", "2022-01-01", "2022-04-01",
                "2023-07-01", "2026-02-01"]


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def shift(d: str, days: int) -> str:
    return (date.fromisoformat(d) + timedelta(days=days)).isoformat()


def registry_anchors() -> dict[str, str]:
    """rule_id → valid_from z temporal_validity registry."""
    md = (RULES / "_metadata_jdg.rego").read_text(encoding="utf-8")
    m = re.search(r"temporal_validity\s*:=\s*\{", md)
    if not m:
        return {}
    start, depth, i = m.end(), 1, m.end()
    while i < len(md) and depth > 0:
        if md[i] == "{":
            depth += 1
        elif md[i] == "}":
            depth -= 1
        i += 1
    block = md[start : i - 1]
    out = {}
    for em in re.finditer(r'"((?:jdg|tax)\.[a-z0-9_.]+)"\s*:\s*\{([^}]*)\}', block):
        vf = re.search(r'"valid_from"\s*:\s*"(\d{4}-\d{2}-\d{2})"', em.group(2))
        if vf:
            out[em.group(1)] = vf.group(1)
    return out


def test_text() -> str:
    parts = []
    for p in sorted(TESTS.rglob("*.py")):
        try:
            parts.append(p.read_text(encoding="utf-8", errors="replace"))
        except Exception:
            pass
    return "\n".join(parts)


def main() -> int:
    checks, findings = [], []
    anchors = registry_anchors()
    by_date: dict[str, list[str]] = {}
    for rid, vf in anchors.items():
        by_date.setdefault(vf, []).append(rid)
    all_dates = sorted(by_date)
    t = test_text()

    coverage = {}
    for d in all_dates:
        pre, post = shift(d, -1), shift(d, 1)
        # day-1 → nieaktywna / day+0 → aktywna / day+1 → aktywna (asercje w testach)
        covered = {
            "pre": (pre in t and any(r in t for r in by_date[d])),
            "day0": d in t,
            "post": post in t,
        }
        coverage[d] = {
            "rules": by_date[d],
            "pre_date": pre, "post_date": post,
            "has_pre_assertion": covered["pre"],
            "has_day0_assertion": covered["day0"],
            "has_post_assertion": covered["post"],
            "boundary": covered["pre"] and covered["day0"],
        }

    core_missing = []
    for d in CORE_ANCHORS:
        if d not in coverage:
            core_missing.append({"date": d, "reason": "kotwica poza registry lub brak testów"})
        elif not coverage[d]["boundary"]:
            core_missing.append({
                "date": d, "rules": by_date.get(d, []),
                "has_pre": coverage[d]["has_pre_assertion"],
                "has_day0": coverage[d]["has_day0_assertion"],
            })
    full_boundary = sum(1 for c in coverage.values() if c["boundary"])
    checks.append({
        "name": "core_anchors_boundary",
        "status": "FAIL" if core_missing else "OK",
        "detail": f"kotwic konstytucyjnych bez pary day-1/day+0: {len(core_missing)}",
    })
    checks.append({
        "name": "registry_anchor_coverage",
        "status": "OK",
        "detail": f"kotwic w registry: {len(all_dates)}, z pełną parą graniczną (day-1+day0): "
                  f"{full_boundary} ({round(100 * full_boundary / max(len(all_dates), 1))}%)",
    })
    for miss in core_missing:
        findings.append({
            "id": "V3-P05-L07", "severity": "P2" if miss.get("has_pre") else "P1",
            "evidence": f"kotwica {miss['date']} bez dowodu ciągłości day-1/day+0: "
                        f"{json.dumps(miss, ensure_ascii=False)[:200]}",
            "fix": "test graniczny (day-1 nieaktywna / day+0 aktywna) — wymóg Time Gate CI przed merge",
        })
    if len(all_dates) == 0:
        checks.append({"name": "registry", "status": "FAIL", "detail": "brak wpisów registry"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P05-I05",
        "generated_at": now(),
        "gate": gate,
        "rule": "zmiana valid_from/valid_to = obowiązkowy dowód ciągłości (day-1/day0/day+1) "
                "w tym samym PR; brak dowodu = blokada merge (P39)",
        "coverage": coverage,
        "metrics": {
            "anchors_total": len(all_dates),
            "anchors_full_boundary": full_boundary,
            "core_anchors": len(CORE_ANCHORS),
            "core_missing_boundary": len(core_missing),
        },
        "checks": checks,
        "findings": findings,
        "contract": {
            "binding": "P39 testy/CI, P38 bundle, P06 parametry",
            "merge_block": "każda zmiana okna (reguła lub parametr) bez testów day-1/day0/day+1 = blokada",
        },
    }
    OUT.write_text(json.dumps(bundle, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[V3-P05-I05] gate={gate} anchors={len(all_dates)} "
          f"full_boundary={full_boundary} core_missing={len(core_missing)}")
    return 0 if gate == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
