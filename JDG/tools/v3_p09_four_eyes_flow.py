#!/usr/bin/env python3
"""
NexusAI JDG — V3-P09-I06 4-EYES FLOW ENGINE
============================================
Techniczne wymuszenie ról i bramek zatwierdzeń z podpisami: deklaracja musi
przejść DRAFT → REVIEW (autor ≠ recenzent) → APPROVE (4-eyes) → EXECUTE.
Role: declared_by (autor), reviewer_1, reviewer_2 — rozłączne.

Usage:
  python tools/v3_p09_four_eyes_flow.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"

FLOW = ["DRAFT", "REVIEW_1", "REVIEW_2", "APPROVED", "EXECUTED", "ROLLED_BACK"]


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    dc = (TOOLS / "declarative_change.py").read_text(encoding="utf-8")
    registry = json.loads((BUNDLES / "rule_registry.json").read_text(encoding="utf-8"))

    # role w rejestrze
    roles = set()
    for rid, v in registry.items():
        for ver in v.get("versions", []):
            if ver.get("owner"):
                roles.add(f"owner:{ver['owner']}")
            for k in ("author", "reviewer"):
                if ver.get(k):
                    roles.add(f"{k}:{ver[k]}")
    has_four_eyes_in_dc = "review" in dc.lower() and "author" in dc.lower()

    checks.append({"name": "flow_states", "status": "OK",
                   "detail": f"model przepływu: {' → '.join(FLOW)}"})
    checks.append({"name": "enforced_in_tool", "status": "FAIL" if not has_four_eyes_in_dc
                   else "OK",
                   "detail": "declarative_change.py nie wymusza ról (brak author/reviewer "
                             "w przepływie execute)"})
    checks.append({"name": "registry_roles", "status": "FAIL" if len(roles) < 2 else "OK",
                   "detail": f"role w rejestrze: {roles or 'BRAK (tylko owner)'} — model SQL "
                             "007 (policy_change_reviews) istnieje, JSON go omija"})

    findings.append({"id": "V3-P09-L06", "severity": "P1",
                     "evidence": f"rejestr: role={roles or 'tylko owner=policy-engineer'}; "
                                 "declarative_change.py execute zapisuje zmianę bez bramki "
                                 "4-eyes (flaga --execute-data wystarcza); migracja 007 ma "
                                 "policy_change_reviews — warstwa JSON jej nie używa",
                     "fix": "I06 4-Eyes Flow Engine: DRAFT→REVIEW_1→REVIEW_2→APPROVED z "
                            "rozłącznymi rolami i podpisami (hash); EXECUTE tylko po "
                            "APPROVED"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P09-I06", "generated_at": now(), "gate": gate,
        "metrics": {"flow_states": FLOW, "enforced_in_tool": has_four_eyes_in_dc,
                    "registry_roles": sorted(roles)},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P07 (4-eyes awansu), P43 (RBAC), P39 (bramki CI), "
                                "migracja 007",
                     "rule": "żadna deklaracja nie przechodzi do EXECUTE bez 2 rozłącznych "
                             "podpisów; autor ≠ obaj recenzenci"}}
    (BUNDLES / "v3_p09_four_eyes_flow.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P09-I06] gate={gate} roles={sorted(roles) or 'none'}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
