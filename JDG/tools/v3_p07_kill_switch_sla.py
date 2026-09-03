#!/usr/bin/env python3
"""
NexusAI JDG — V3-P07-I04 KILL-SWITCH SLA
=========================================
Pauza reguły/pakietu < 1 s (hot-reload) z audytem, alertem i automatycznym
NEEDS_ADVICE dla dotkniętych strumieni (P07-AN05). Audyt stanu:
  * pojedyncza reguła: cmd_suspend (rule_lifecycle_manager) — status SUSPENDED
    + suspend_reason + suspended_at; hot-reload < 1 s deklarowane,
  * cały pakiet/domena: BRAK operacji zbiorowej,
  * NEEDS_ADVICE dla dotkniętych decyzji: BRAK powiązania status→routing,
  * SLA MTTR ≤ 15 min / auto-rollback ≤ 5 min: brak pomiaru.

Usage:
  python tools/v3_p07_kill_switch_sla.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"

SLO_SUSPEND_S = 1.0
SLO_AUTO_ROLLBACK_MIN = 5.0
SLO_MTTR_MIN = 15.0


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    registry = json.loads((BUNDLES / "rule_registry.json").read_text(encoding="utf-8"))
    manager = (BASE / "tools" / "rule_lifecycle_manager.py").read_text(encoding="utf-8")
    rego = (BASE / "rules" / "rule_lifecycle_enterprise.rego").read_text(encoding="utf-8")

    has_suspend = "cmd_suspend" in manager and "SUSPENDED" in manager
    has_domain_suspend = bool(re.search(r"domain|package|domena", manager) and
                              re.search(r"suspend.*(all|package|domain)|(all|package|domain).*suspend",
                                        manager, re.I))
    suspended_now = sum(1 for e in registry.values()
                        for v in e.get("versions", []) if v.get("status") == "SUSPENDED")
    # NEEDS_ADVICE coupling: czy rego/manager mapuje SUSPENDED → NEEDS_ADVICE?
    needs_advice_coupling = ("SUSPENDED" in rego) and ("NEEDS_ADVICE" in rego)

    checks.append({"name": "single_rule_suspend",
                   "status": "OK" if has_suspend else "FAIL",
                   "detail": f"cmd_suspend + status SUSPENDED: {has_suspend}; "
                             f"SUSPENDED dziś: {suspended_now}"})
    checks.append({"name": "package_domain_suspend",
                   "status": "FAIL" if not has_domain_suspend else "OK",
                   "detail": f"wstrzymanie całego pakietu/domeny: "
                             f"{'istnieje' if has_domain_suspend else 'BRAK'}"})
    checks.append({"name": "needs_advice_coupling",
                   "status": "FAIL" if not needs_advice_coupling else "OK",
                   "detail": f"SUSPENDED → NEEDS_ADVICE w rego: {needs_advice_coupling}"})
    checks.append({"name": "slo_measured",
                   "status": "FAIL",
                   "detail": "SLO nie mierzone: brak znaczników czasowych operacji "
                             "(suspend→active) w rejestrze; MTTR/auto-rollback bez pomiaru"})

    findings.append({"id": "V3-P07-L09", "severity": "P1",
                     "evidence": "kill-switch istnieje dla POJEDYNCZEJ reguły (cmd_suspend), ale "
                                 "brak: (a) wstrzymania pakietu/domeny jednym ruchem, "
                                 "(b) automatycznego NEEDS_ADVICE dla strumieni dotkniętych, "
                                 "(c) pomiaru SLO < 1 s i MTTR ≤ 15 min",
                     "fix": "Kill-Switch SLA (I04): operacje zbiorowe per domena + routing "
                            "dotkniętych decyzji → NEEDS_ADVICE + znaczniki czasu operacji (P37)"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P07-I04", "generated_at": now(), "gate": gate,
        "metrics": {"suspended_now": suspended_now,
                    "single_rule_suspend": has_suspend,
                    "package_suspend": has_domain_suspend,
                    "needs_advice_coupling": needs_advice_coupling},
        "slo": {"suspend_s": SLO_SUSPEND_S, "auto_rollback_min": SLO_AUTO_ROLLBACK_MIN,
                "mttr_min": SLO_MTTR_MIN, "measured": False},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P43 (security/DR — SLO MTTR), P38 (hot-reload), P37 (metryki), "
                                "P04 (protokół naruszenia → BLOCK)",
                     "rule": "suspend < 1 s z audytem (kto/kiedy/dlaczego) + alert; "
                             "decyzje dotknięte = NEEDS_ADVICE (fail-closed)"},
    }
    (BUNDLES / "v3_p07_kill_switch_sla.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P07-I04] gate={gate} suspend_single={has_suspend} "
          f"package={has_domain_suspend} needs_advice={needs_advice_coupling}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
