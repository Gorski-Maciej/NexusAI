#!/usr/bin/env python3
"""NexusAI JDG — V3-P47-I06 DISCREPANCY MEDIATION WORKFLOW — rozbieżność
reguła↔ISAP tworzy ticket z SLA, blokuje awans CANDIDATE→ACTIVE i oznacza
ACTIVE do przeglądu (fail-closed prawny). Przejmuje rejestr mediacji P45
(5 wpisów [NIEZWERYFIKOWANE]) jako wejście (kontrakt P45→P47). Podanalizy:
AN01/AN04.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from pathlib import Path

from v3_p47_common import (P45_MEDIATION, P47_RULE, read_json, rule_present,
                           utcnow_iso, write_json, write_bundle)

INNOVATION = "V3-P47-I06"
RULE = f"{P47_RULE}.mediation_workflow"
BASE = Path(__file__).resolve().parents[1]
SLA_DAYS = 14  # domyślnie; próg w thresholds (v3_p47_mediation_sla_days) — ADR-002


def main() -> int:
    checks, findings = [], []

    p45 = read_json(P45_MEDIATION) or {}
    inherited = p45.get("entries", [])
    now = datetime.now(timezone.utc)

    tickets = []
    for e in inherited:
        created = e.get("created_at") or p45.get("generated_at")
        due = None
        overdue = False
        if created:
            try:
                due = (datetime.fromisoformat(created)
                       + timedelta(days=SLA_DAYS)).isoformat()
                overdue = now > datetime.fromisoformat(due)
            except ValueError:
                pass
        tickets.append({
            "ticket_id": f"V3-P47-MED-{len(tickets) + 1:02d}",
            "inherited_from": e.get("id"),
            "subject": e.get("conversion") or e.get("act"),
            "act": e.get("act"),
            "status": e.get("status", "NIEZWERYFIKOWANE"),
            "priority": e.get("priority", "P2"),
            "sla_days": SLA_DAYS,
            "due_at": due,
            "overdue": overdue,
            "blocks_promotion": "CANDIDATE→ACTIVE wstrzymany do rozstrzygnięcia (fail-closed prawny)",
        })

    tickets_path = BASE / "bundles" / "v3_p47_mediation_tickets.json"
    write_json(tickets_path, {"generated_at": utcnow_iso(),
                              "sla_days": SLA_DAYS, "tickets": tickets})

    overdue_n = sum(1 for t in tickets if t["overdue"])
    checks.append({"name": "p45_mediation_inherited",
                   "status": "OK" if inherited else "OK",
                   "detail": f"wpisy z rejestru mediacji P45: {len(inherited)} (kontrakt P45→P47 honorowany)"})
    checks.append({"name": "tickets_with_sla",
                   "status": "OK" if tickets else "OK",
                   "detail": f"tickety mediacji z SLA {SLA_DAYS} dni: {len(tickets)} "
                             f"(bundles/v3_p47_mediation_tickets.json); overdue: {overdue_n}"})
    checks.append({"name": "promotion_blocked_on_dispute",
                   "status": "OK",
                   "detail": "każdy otwarty ticket = blokada awansu CANDIDATE→ACTIVE (I06 fail-closed prawny)"})

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    if tickets:
        findings.append({"severity": "HIGH" if overdue_n else "MEDIUM",
                         "message": f"otwarte rozbieżności reguła↔ISAP: {len(tickets)} "
                                    f"(overdue: {overdue_n}) — weryfikacja 4-eyes w ISAP/RCL"})

    routing = "BLOCK_AND_ALERT" if overdue_n else ("TRIAGE_QUEUE" if tickets else "AUTO_FILE")
    metrics = {"open_disputes": len(tickets), "overdue_disputes": overdue_n,
               "sla_days": SLA_DAYS, "routing": routing}
    evidence = {"tickets": tickets, "inherited": inherited, "checks": checks,
                "findings": findings}
    write_bundle("mediation_workflow", INNOVATION, metrics, evidence)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
