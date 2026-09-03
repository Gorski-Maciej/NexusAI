#!/usr/bin/env python3
"""
NexusAI JDG — V3-P08-I05 IMPACT MATRIX AUTO-BUILDER
====================================================
Diff prawny → dotknięte reguły/parametry/werdykty z priorytetami i
szacunkiem pracy. Automat: każda wykryta zmiana (crawler/drift) generuje
macierz wpływu bez ręcznego CLI.

Usage:
  python tools/v3_p08_impact_matrix.py
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
    # istniejące narzędzie: law_impact_matrix.py (CLI analyze/report) — czy auto?
    impact_src = (TOOLS / "law_impact_matrix.py").read_text(encoding="utf-8")
    crawler_src = (TOOLS / "isap_crawler.py").read_text(encoding="utf-8")
    pipeline_src = (TOOLS / "isap_rule_update_pipeline.py").read_text(encoding="utf-8")

    auto_wired = ("law_impact_matrix" in crawler_src) or ("law_impact_matrix" in pipeline_src)
    manual_cli = "analyze" in impact_src
    has_effort = "effort" in impact_src or "szacunek" in impact_src or "estimat" in impact_src

    checks.append({"name": "auto_build_from_detection", "status": "OK" if auto_wired else "FAIL",
                   "detail": "macierz budowana ręcznie przez CLI, brak auto-wywołania z "
                             "crawlera/driftu"})
    checks.append({"name": "impact_matrix_exists", "status": "OK" if manual_cli else "FAIL",
                   "detail": "law_impact_matrix.py z analizą diff (CLI manualne)"})
    checks.append({"name": "effort_estimate", "status": "OK" if has_effort else "FAIL",
                   "detail": "brak szacunku pracy (osobogodzin) per dotknięta reguła"})

    # realne dotknięte reguły wg drift alarm
    alarm_md = (BASE / "reports" / "isap_drift_alarm.md")
    affected = None
    if alarm_md.exists():
        m = re.search(r"Reguł dotkniętych:\s*(\d+)", alarm_md.read_text(encoding="utf-8"))
        if m:
            affected = int(m.group(1))

    findings.append({"id": "V3-P08-L05", "severity": "P1",
                     "evidence": "law_impact_matrix.py działa tylko przez ręczne CLI "
                                 "(analyze --diff); isap_crawler/isap_rule_update_pipeline nie "
                                 "wywołują macierzy automatycznie; brak szacunku pracy; "
                                 f"drift alarm: {affected or '?'} dotkniętych reguł bez "
                                 "automatycznej macierzy",
                     "fix": "I05 Impact Matrix Auto-Builder: hook po detekcji zmiany → "
                            "macierz (reguła×priorytet×osobogodziny) do kalendarza i P10"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P08-I05", "generated_at": now(), "gate": gate,
        "metrics": {"auto_wired": auto_wired, "manual_cli": manual_cli,
                    "has_effort_estimate": has_effort, "affected_rules": affected},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P08-I04 (lead time na bazie macierzy), P10 (golden na bazie "
                                "macierzy), P07 (SHADOW z macierzy), P06 (parametry z macierzy)",
                     "rule": "każda zmiana → macierz z priorytetem i szacunkiem przed "
                             "planowaniem SHADOW"},
    }
    (BUNDLES / "v3_p08_impact_matrix.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P08-I05] gate={gate} auto={auto_wired} manual={manual_cli} "
          f"effort={has_effort}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
