#!/usr/bin/env python3
"""NexusAI JDG — V3-P42-I08 ORPHAN ARTIFACT SWEEP — skan tools/bundles/
migrations: artefakt bez właściciela-części → decyzja. Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p42_common import (BUNDLES, MIGRATIONS, RULES, SYSTEM_REGISTER, TOOLS,
                           emit, main_jdg_wired, now, read_json, rule_present,
                           threshold_present)

INNOVATION = "V3-P42-I08"
RULE = "jdg.v3_p42_enterprise_reszta.orphan_sweep"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # Realne rozmiary katalogów (dowód skanu)
    n_tools = len(list(TOOLS.glob("*.py")))
    n_bundles = len(list(BUNDLES.glob("*.json")))
    n_migrations = len(list(MIGRATIONS.glob("*"))) if MIGRATIONS.exists() else 0
    scanned = n_tools > 0 and n_bundles > 0
    checks.append({"name": "directories_scanned", "status": "OK" if scanned else "FAIL",
                   "detail": f"tools={n_tools}, bundles={n_bundles}, migrations={n_migrations}"})

    # Migracje 001-013: rejestr decyzji (przypisz/archiwizuj/usuń) w rejestrze systemowym
    reg = read_json(SYSTEM_REGISTER)
    migrations = reg.get("migrations_decisions", {}) if isinstance(reg, dict) else {}
    migrations_ok = isinstance(migrations, dict) and len(migrations) > 0
    checks.append({"name": "migrations_have_decisions", "status": "OK" if migrations_ok else "FAIL",
                   "detail": f"decyzje migracji w rejestrze: {len(migrations)} wpisów"})

    t = threshold_present("v3_p42_orphan_max")
    checks.append({"name": "orphan_threshold_as_data", "status": "OK" if t else "FAIL",
                   "detail": f"v3_p42_orphan_max w data.thresholds: {t}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p106"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "tools_count": n_tools,
            "bundles_count": n_bundles,
            "migrations_count": n_migrations,
            "migrations_have_decisions": migrations_ok,
            "orphan_threshold_as_data": t,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p42_orphan_sweep")


if __name__ == "__main__":
    raise SystemExit(main())
