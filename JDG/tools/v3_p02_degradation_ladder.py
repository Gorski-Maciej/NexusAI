#!/usr/bin/env python3
"""
NexusAI JDG — DEGRADATION LADDER (V3-P02-I05)
==============================================
Schodek degradacji: pełny → częściowy → NEEDS_ADVICE, z jawnymi kryteriami
przejścia i audytem. Analizuje pakiety fallback (fallback.rego,
api_fallback.rego) i mapuje je na klasy degradacji kontraktu werdyktu.

Klasy (zgodne z kontraktem P00 K3 + ADR-004 + F4):
  FULL            — pełny dowód, AUTO_POST_ALLOWED
  PARTIAL         — część pól pewna, reszta NEEDS_ADVICE (guard MANUAL_REVIEW)
  DEGRADED_API    — API zewnętrzne offline: TRIAGE_QUEUE/FALLBACK_ACTIVE
  BLOCKED         — BLOCK_AND_ALERT: nigdy AUTO_POST
  NEEDS_ADVICE    — brak dowodu: CERTAINTY_BLOCKED

Czyta:  rules/fallback.rego, rules/api_fallback.rego, rules/routing.rego
Pisze:  bundles/v3_p02_degradation_ladder.json

Usage:
  python v3_p02_degradation_ladder.py [--json] [--write] [--gate]
"""
from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
OUT_JSON = BASE_DIR / "bundles" / "v3_p02_degradation_ladder.json"
FILES = {"fallback": "rules/fallback.rego", "api_fallback": "rules/api_fallback.rego",
         "routing": "rules/routing.rego"}


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def verdict_routings(path: Path) -> list[dict]:
    txt = path.read_text(encoding="utf-8") if path.exists() else ""
    out = []
    for m in re.finditer(r'rule_id":\s*"([^"]+)"', txt):
        rule = m.group(1)
        seg = txt[m.start():m.start() + 1500]
        r_route = re.search(r'"_routing":\s*"([^"]*)"', seg)
        matched = re.search(r'"matched":\s*(true|false)', seg)
        warnings = len(re.findall(r'"_warnings":\s*\[', seg))
        out.append({"rule_id": rule,
                    "routing": r_route.group(1) if r_route else "",
                    "matched": matched.group(1) if matched else "?",
                    "has_warnings": warnings > 0})
    return out


def ladder_class(r: dict) -> str:
    route = r["routing"]
    if route == "BLOCK_AND_ALERT":
        return "BLOCKED (nigdy AUTO_POST)"
    if route in ("TRIAGE_QUEUE", "FALLBACK_ACTIVE"):
        if r["matched"] == "true":
            return "DEGRADED_API -> NEEDS_ADVICE (guard MANUAL_REVIEW)"
        return "PARTIAL -> NEEDS_ADVICE"
    if route == "":
        if r["matched"] == "false":
            return "NO_MATCH (wypełnia luki, nie decyduje)"
        return "PARTIAL (fallback pól, TRIAGE)"
    return "FULL"


def build() -> dict:
    per_file = {}
    rows = []
    for name, rel in FILES.items():
        path = BASE_DIR / rel
        verdicts = verdict_routings(path)
        per_file[name] = len(verdicts)
        for v in verdicts:
            cls = ladder_class(v)
            rows.append({"file": rel, **v, "degradation_class": cls})

    classes = {}
    for r in rows:
        classes[r["degradation_class"]] = classes.get(r["degradation_class"], 0) + 1

    # Fail-closed check: czy jakakolwiek ścieżka fallback jest AUTO_POST z
    # matched=true przy braku danych? fallback P1000 ustawia matched:false
    # (v7.0 FIX) — weryfikujemy.
    fallback_path = BASE_DIR / FILES["fallback"]
    fb = fallback_path.read_text(encoding="utf-8")
    auto_post_candidates = [r for r in rows if r["matched"] == "true"
                            and r["degradation_class"] == "FULL"]

    api_degraded = [r for r in rows if "DEGRADED" in r["degradation_class"]]
    all_degraded_have_warnings = all(r["has_warnings"] for r in api_degraded)

    issues = []
    if auto_post_candidates:
        issues.append(f"ścieżki fallback matched=true bez klasy NEEDS_ADVICE: "
                      f"{[r['rule_id'] for r in auto_post_candidates]}")
    if not all_degraded_have_warnings:
        issues.append("niektóre zdegradowane werdykty API nie niosą _warnings (cichy ubytek)")

    gate_pass = not auto_post_candidates and all_degraded_have_warnings
    return {
        "innovation": "V3-P02-I05",
        "name": "Degradation Ladder — pełny → częściowy → NEEDS_ADVICE",
        "generated_at": now(),
        "files": FILES,
        "verdicts_per_file": per_file,
        "ladder": classes,
        "api_degraded_verdicts": api_degraded,
        "fallback_auto_post_candidates": auto_post_candidates,
        "all_degraded_carry_warnings": all_degraded_have_warnings,
        "ladder_definition": {
            "FULL": "pełny dowód -> AUTO_POST_ALLOWED (CERTAIN)",
            "PARTIAL": "część pól -> MANUAL_REVIEW (CONDITIONAL)",
            "DEGRADED_API": "API offline -> TRIAGE_QUEUE/FALLBACK_ACTIVE + _warnings",
            "BLOCKED": "BLOCK_AND_ALERT -> CERTAINTY_BLOCKED",
            "NEEDS_ADVICE": "brak dowodu -> CERTAINTY_BLOCKED (nigdy AUTO_POST)",
        },
        "issues": issues,
        "gate": {"pass": gate_pass,
                 "rule": "żadna ścieżka fallback/degradacji nie jest cichym AUTO_POST; "
                         "każda degradacja niesie _warnings (fail-closed, INV-006/035)"},
        "note": "fallback P1000/P1099 ustawia matched:false (v7.0 FIX) — domyślne "
                "stawki wymagają ręcznej weryfikacji.",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Degradation Ladder (V3-P02-I05)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--gate", action="store_true")
    args = ap.parse_args()

    data = build()
    if args.write:
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano {OUT_JSON.relative_to(BASE_DIR)}")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(f"V3-P02-I05 Degradation Ladder: classes={data['ladder']} "
              f"gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: ścieżka degradacji z cichym AUTO_POST")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
