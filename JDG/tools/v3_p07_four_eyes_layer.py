#!/usr/bin/env python3
"""
NexusAI JDG — V3-P07-I05 4-EYES ENFORCEMENT LAYER
==================================================
Techniczne wymuszenie separacji ról w pipeline (autor ≠ recenzent ≠ operator)
z podpisami. Audyt:
  * rejestr reguł (rule_registry.json) — pola owner/reviewed_by/operator,
  * migracja 007 (policy_change_reviews, control_plane_audit) — model SQL,
  * control_plane_lifecycle.py + test (SoD, roundtrip 4-eyes) — istnieje,
  * deployments.json — podpisy operacji.
Rozdźwięk: warstwa control-plane (SQL/testy) modeluje 4-eyes, ale operacyjny
rejestr JSON (register/promote/suspend) nie zapisuje ról ani podpisów.

Usage:
  python tools/v3_p07_four_eyes_layer.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"

ROLES = ["author", "reviewer", "reviewed_by", "operator", "approved_by"]


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    registry = json.loads((BUNDLES / "rule_registry.json").read_text(encoding="utf-8"))
    depl = json.loads((BUNDLES / "deployments.json").read_text(encoding="utf-8"))

    # role w wersjach rejestru
    vers = [v for e in registry.values() for v in e.get("versions", [])]
    with_roles = sum(1 for v in vers if any(r in v for r in ROLES))
    distinct_owners = {v.get("owner") for v in vers}

    # role w deploymentach
    depl_roles = {k: [r for r in ROLES if r in e] for k, e in depl.get("deployments", {}).items()}
    depl_signed = sum(1 for rs in depl_roles.values() if rs)

    # model SQL 007
    sql = (BASE / "migrations" / "007_jdg_v12_control_plane_lifecycle.sql").read_text(
        encoding="utf-8")
    sql_four_eyes = "policy_change_reviews" in sql and "control_plane_audit" in sql
    # testy 4-eyes
    tests = (BASE / "tests" / "test_control_plane_lifecycle.py").read_text(encoding="utf-8")
    test_four_eyes = "four_eyes" in tests

    checks.append({"name": "registry_role_fields",
                   "status": "FAIL" if with_roles < len(vers) else "OK",
                   "detail": f"wersje z polami ról: {with_roles}/{len(vers)}; "
                             f"unikalni ownerzy: {distinct_owners or 'BRAK'}"})
    checks.append({"name": "deployments_signed",
                   "status": "FAIL" if depl_signed < len(depl.get("deployments", {})) else "OK",
                   "detail": f"deploymenty z podpisem roli: {depl_signed}/"
                             f"{len(depl.get('deployments', {}))}"})
    checks.append({"name": "sql_model_4eyes",
                   "status": "OK" if sql_four_eyes else "FAIL",
                   "detail": f"migracja 007: policy_change_reviews + control_plane_audit = "
                             f"{sql_four_eyes}"})
    checks.append({"name": "control_plane_tests",
                   "status": "OK" if test_four_eyes else "FAIL",
                   "detail": f"test SoD/4-eyes control plane: {test_four_eyes}"})

    findings.append({"id": "V3-P07-L04", "severity": "P1",
                     "evidence": "rozdźwięk 4-eyes: control plane (SQL 007 + testy) modeluje "
                                 "policy_change_reviews/audit, ale operacyjny rule_registry.json "
                                 "i deployments.json nie niosą ról/podpisów — narzędzia JSON "
                                 "(register/promote/suspend) omijają warstwę 4-eyes",
                     "fix": "4-Eyes Enforcement Layer (I05): podpisy ról w rekordach operacji "
                            "(author→reviewer→operator) + bramka CI wymagająca reviewed_by ≠ "
                            "owner przed awansem [BM]"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P07-I05", "generated_at": now(), "gate": gate,
        "metrics": {"registry_versions": len(vers), "with_role_fields": with_roles,
                    "deployments": len(depl.get("deployments", {})),
                    "deployments_signed": depl_signed,
                    "sql_4eyes_model": sql_four_eyes,
                    "distinct_owners": sorted(distinct_owners)},
        "checks": checks, "findings": findings,
        "model": {"separation": "author ≠ reviewer ≠ operator",
                  "record": "version.owner (autor) + review.approved_by (recenzent) + "
                            "operation.operator (operator)",
                  "gate": "awans bez reviewed_by ≠ owner = blokada [BM]"},
        "contract": {"binding": "P38 (deployment), P40 (jakość), P44 (certyfikacja), P39 (CI), "
                                "P07-I01 (awans)",
                     "rule": "operacja lifecycle bez podpisu operatora = wpis do control_plane_audit "
                             "jako naruszenie"},
    }
    (BUNDLES / "v3_p07_four_eyes_layer.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P07-I05] gate={gate} vers={len(vers)} with_roles={with_roles} "
          f"depl_signed={depl_signed}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
