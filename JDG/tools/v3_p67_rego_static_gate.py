#!/usr/bin/env python3
"""
NexusAI JDG — V3-P67 SELF-LEARNING — BRAMKA STATYCZNA REGO (konwencja P65–P66).
Waliduje (gdy brak OPA CLI): (1) wszystkie 12 kluczy I01–I12 używanych w Rego,
(2) progi v3_p67_* w thresholds_jdg.rego (ADR-002; flaga v3_p67_check to klucz
aktywacyjny inputu, nie próg), (3) wiring final_verdict_p131 w main_jdg.rego,
(4) synchronizację mirror policies/v3_p67_self_learning.rego.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

RULES = Path(__file__).resolve().parent.parent / "rules"
MIRROR = Path(__file__).resolve().parent.parent.parent / "policies"

POLICY = RULES / "v3_p67_self_learning.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN = RULES / "main_jdg.rego"
MIRROR_POLICY = MIRROR / "v3_p67_self_learning.rego"

KEYS = [f"I{n:02d}" for n in range(1, 13)]
FLAG = "v3_p67_check"


def main() -> int:
    errors = []
    policy = POLICY.read_text(encoding="utf-8")
    thresholds = THRESHOLDS.read_text(encoding="utf-8")
    main_src = MAIN.read_text(encoding="utf-8")

    for k in KEYS:
        if k not in policy:
            errors.append(f"brak klucza {k} w {POLICY.name}")

    p67_keys = set(re.findall(r'"(v3_p67_[A-Za-z0-9_]+)"', thresholds))
    if not p67_keys:
        errors.append("brak bloku v3_p67 w thresholds_jdg.rego (ADR-002)")
    for k in ("v3_p67_clusters_min", "v3_p67_data_sources_min",
              "v3_p67_replay_cases_min", "v3_p67_curriculum_roi_min"):
        if k not in p67_keys:
            errors.append(f"brak progu {k} w thresholds (ADR-002)")

    if "final_verdict_p131" not in main_src or "v3_p67_self_learning.decide" not in main_src:
        errors.append("brak wiringu final_verdict_p131 w main_jdg.rego")

    if MIRROR_POLICY.exists():
        if MIRROR_POLICY.read_text(encoding="utf-8") != policy:
            errors.append("mirror policies/v3_p67_self_learning.rego dryfuje vs canonical")
    else:
        errors.append("brak mirror policies/v3_p67_self_learning.rego")

    if errors:
        for e in errors:
            print(f"FAIL: {e}")
        return 1
    print("PASS: P67 static gate (12 kluczy I01–I12, progi ADR-002, wiring p131, mirror sync)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
