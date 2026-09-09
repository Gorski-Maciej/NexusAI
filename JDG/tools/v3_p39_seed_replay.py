#!/usr/bin/env python3
"""NexusAI JDG — V3-P39-I11 SEED-REPLAY DETERMINISM — każdy test z losowością
zapisuje seed; CI replays po awarii 1:1. Podanalizy: AN02.
"""
from __future__ import annotations

import json

from v3_p39_common import emit, main_jdg_wired, now, read, rule_present

INNOVATION = "V3-P39-I11"
RULE = "jdg.v3_p39_testy_ci.seed_replay"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    strategy = json.loads(read(__import__("v3_p39_common").TEST_STRATEGY)) if read(__import__("v3_p39_common").TEST_STRATEGY) else {}
    sr = strategy.get("seed_replay", {})
    ok_sr = sr.get("seed_recorded") is True and sr.get("replay_on_failure") is True
    checks.append({"name": "seed_replay_convention_as_data", "status": "OK" if ok_sr else "FAIL",
                   "detail": f"seed_replay: seed_recorded={sr.get('seed_recorded')}, replay={sr.get('replay_on_failure')}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p103"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "seed_replay_convention_ok": ok_sr,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p39_seed_replay")


if __name__ == "__main__":
    raise SystemExit(main())
