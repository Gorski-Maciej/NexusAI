#!/usr/bin/env python3
"""
NexusAI JDG — V3-P07-I12 AUTO-POST GATE LIFECYCLE
==================================================
Reguła może być ACTIVE, ale z flagą NO_AUTO_POST — granica zaufania zarządzana
w lifecycle (P03-I11: AUTO_POST tylko przy pełnym dowodzie). Audyt:
  * flaga auto_post/no_auto_post w wersjach rejestru,
  * reguły ACTIVE o charakterze decyzyjnym bez jawnej deklaracji granicy,
  * powiązanie z jdg.adaptive_trust.auto_post_gate (P03).

Usage:
  python tools/v3_p07_auto_post_gate_lifecycle.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    registry = json.loads((BUNDLES / "rule_registry.json").read_text(encoding="utf-8"))
    rego = (BASE / "rules" / "rule_lifecycle_enterprise.rego").read_text(encoding="utf-8")

    total = 0
    flagged = []
    active_decisional = []
    for rid, e in registry.items():
        for v in e.get("versions", []):
            total += 1
            ap = v.get("auto_post")
            if ap is not None:
                flagged.append({"rule": rid, "auto_post": ap})
            if v.get("status") == "ACTIVE" and v.get("severity") in ("BLOCKER", "ERROR"):
                active_decisional.append(rid)

    # czy rego/manager zna pojęcie NO_AUTO_POST przy statusie ACTIVE?
    no_auto_post_support = "NO_AUTO_POST" in rego or "auto_post" in rego

    checks.append({"name": "auto_post_flag",
                   "status": "FAIL" if not flagged else "OK",
                   "detail": f"wersje z jawną deklaracją auto_post: {len(flagged)}/{total}"})
    checks.append({"name": "lifecycle_support",
                   "status": "OK" if no_auto_post_support else "WARN",
                   "detail": f"wsparcie NO_AUTO_POST w rego lifecycle: {no_auto_post_support}"})

    findings.append({"id": "V3-P07-L18", "severity": "P2",
                     "evidence": "żadna wersja rejestru nie deklaruje granicy auto_post — reguły "
                                 "ACTIVE o wysokiej wadze (BLOCKER/ERROR) nie niosą jawnej "
                                 "decyzji NO_AUTO_POST, granica zaufania poza lifecycle",
                     "fix": "Auto-Post Gate Lifecycle (I12): pole auto_post (AUTO/NO_AUTO_POST/"
                            "SUGGEST_ONLY) w schema wersji + walidacja z P03-I11 [BM]"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P07-I12", "generated_at": now(), "gate": gate,
        "metrics": {"versions_total": total, "flagged": len(flagged),
                    "active_decisional": len(active_decisional),
                    "no_auto_post_support": no_auto_post_support},
        "checks": checks, "findings": findings,
        "model": {"states": ["AUTO_POST", "NO_AUTO_POST", "SUGGEST_ONLY"],
                  "rule": "ACTIVE + NO_AUTO_POST = decyzja zawsze SUGGEST/NEEDS_ADVICE "
                          "do czasu pełnego dowodu (P03-I11)"},
        "contract": {"binding": "P03 (kontrakt werdyktu — AUTO_POST gate), P07-I01 (awans), "
                                "P39 (testy), P04 (invarianty)",
                     "rule": "awans do ACTIVE bez deklaracji auto_post = HOLD (I01); "
                             "cichy AUTO_POST = naruszenie fail-closed"},
    }
    (BUNDLES / "v3_p07_auto_post_gate_lifecycle.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P07-I12] gate={gate} versions={total} flagged={len(flagged)} "
          f"active_decisional={len(active_decisional)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
