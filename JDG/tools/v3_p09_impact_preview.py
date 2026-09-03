#!/usr/bin/env python3
"""
NexusAI JDG — V3-P09-I05 IMPACT PREVIEW
=========================================
Przed zatwierdzeniem: szacunek wpływu deklaracji na portfel decyzji (replay).
Dla zmiany stawki/progu: ile decyzji/werdyktów zmieni wynik, w których
domenach, z priorytetem. Bez replayu portfela = decyzja w ciemno.

Usage:
  python tools/v3_p09_impact_preview.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"
RULES = BASE / "rules"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    dc = (TOOLS / "declarative_change.py").read_text(encoding="utf-8")
    sim = (TOOLS / "law_amendment_simulator.py").read_text(encoding="utf-8")
    registry = json.loads((BUNDLES / "rule_registry.json").read_text(encoding="utf-8"))

    # ile reguł zarejestrowanych vs w kodzie
    rules_code = 0
    for p in RULES.rglob("*.rego"):
        txt = p.read_text(encoding="utf-8", errors="ignore")
        rules_code += len(re.findall(r'"rule_id"\s*:\s*"jdg\.', txt))
    registered = len(registry)
    replay_calls = ("replay" in dc.lower())
    has_sim = "law_amendment_simulator" in dc

    checks.append({"name": "portfolio_replay", "status": "FAIL" if not replay_calls else "OK",
                   "detail": "declarative_change.py nie uruchamia replayu portfela przed "
                             "zatwierdzeniem (tylko wymienia w planie)"})
    checks.append({"name": "simulator_wired", "status": "FAIL" if not has_sim else "OK",
                   "detail": "law_amendment_simulator (co-jeśli) nie jest wołany z "
                             "declarative_change.py"})

    findings.append({"id": "V3-P09-L05", "severity": "P1",
                     "evidence": f"rejestr prowadzi {registered} reguł, w kodzie ~"
                                 f"{rules_code} rule_id; law_amendment_simulator.py (162 "
                                 "wiersze, co-jeśli na werdyktach) istnieje, ale "
                                 "declarative_change.py go nie wywołuje — zatwierdzający "
                                 "nie widzi wpływu zmiany na portfel decyzji przed podpisem",
                     "fix": "I05 Impact Preview: przed 4-eyes uruchom replay (simulator) na "
                            "historycznym portfelu → raport zmienionych werdyktów + priorytet"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P09-I05", "generated_at": now(), "gate": gate,
        "metrics": {"registered_rules": registered, "code_rule_ids": rules_code,
                    "replay_wired": replay_calls, "simulator_wired": has_sim},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P09-I06 (4-eyes po impact), P10 (golden delta), P37 "
                                "(metryki wpływu)",
                     "rule": "4-eyes niemożliwy bez raportu impact preview w deklaracji"}}
    (BUNDLES / "v3_p09_impact_preview.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P09-I05] gate={gate} registered={registered} code={rules_code}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
