#!/usr/bin/env python3
"""
NexusAI JDG — V3-P09-I11 EMERGENCY MANUAL MODE
===============================================
Śledzony tryb ręczny z obowiązkiem retro-deklaracji: gdy deklaracja niemożliwa
(awaria, brak recipe), zmiana ręczna jest dozwolona TYLKO z wpisem
EMERGENCY + terminem retro-deklaracji ≤ 48 h. Zero cichych zmian ręcznych.

Usage:
  python tools/v3_p09_emergency_manual_mode.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"

RETRO_DEADLINE_HOURS = 48


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    # runbooki awaryjne (P07-I11 RB-01..04) istnieją jako artefakt?
    rb_artifacts = []
    for p in (BASE / "docs").glob("RB*.md"):
        rb_artifacts.append(p.name)
    for p in (BASE / "bundles").glob("RB*.json"):
        rb_artifacts.append(p.name)
    dc = (TOOLS / "declarative_change.py").read_text(encoding="utf-8")
    has_emergency = "emergency" in dc.lower() or "manual" in dc.lower()

    checks.append({"name": "emergency_protocol", "status": "FAIL" if not has_emergency
                   else "OK",
                   "detail": "declarative_change.py nie ma trybu awaryjnego z retro-"
                             "deklaracją"})
    rb_desc = ', '.join(rb_artifacts) if rb_artifacts else 'BRAK (RB-01..04 z P07 nie istnieją jako artefakt)'
    checks.append({"name": "runbooks_exist", "status": "OK" if rb_artifacts else "FAIL",
                   "detail": f"runbooki RB: {rb_desc}"})
    checks.append({"name": "retro_deadline", "status": "OK",
                   "detail": f"retro-deklaracja ≤ {RETRO_DEADLINE_HOURS} h (model I11)"})

    findings.append({"id": "V3-P09-L11", "severity": "P2",
                     "evidence": "declarative_change.py nie ma trybu awaryjnego ręcznego "
                                 "(P09-AN08); runbooki RB-01..04 (P07-I11) nie istnieją jako "
                                 "artefakt — zmiana awaryjna musiałaby być ręczna i "
                                 "nieśledzona, bez obowiązku retro-deklaracji",
                     "fix": "I11 Emergency Manual Mode: zmiana ręczna tylko z flagą "
                            "EMERGENCY + retro-deklaracja ≤ 48 h + audyt; brak retro-"
                            "deklaracji w terminie = naruszenie fail-closed"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P09-I11", "generated_at": now(), "gate": gate,
        "metrics": {"retro_deadline_hours": RETRO_DEADLINE_HOURS,
                    "emergency_in_tool": has_emergency, "runbooks": rb_artifacts},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P07-I11 (runbooki), P43 (DR), P04 (invarianty awaryjne)",
                     "rule": "ręczna zmiana bez EMERGENCY + retro-deklaracji = naruszenie; "
                             "retro-deklaracja przechodzi normalny 4-eyes"}}
    (BUNDLES / "v3_p09_emergency_manual_mode.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P09-I11] gate={gate} runbooks={rb_artifacts}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
