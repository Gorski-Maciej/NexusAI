#!/usr/bin/env python3
"""NexusAI JDG — V3-P50 COMMON — szkielet narzędzi dead code / duplikaty.

Rozszerza (nie duplikuje) v3_p48_common/v3_p49_common: ten sam szkielet
bundle, prefiks v3_p50_ (jedno źródło prawdy P00). gate=PASS = dowód
ZAPISANY i spójny; decyzja TRIAGE/BLOCK żyje w metrics.routing.
"""
from __future__ import annotations

from v3_p48_common import (BUNDLES_DIR, BASE, POLICIES_DIR, REPO_ROOT,
                           RULES_DIR, THRESHOLDS_REGO, read_json, utcnow_iso,
                           write_json)

P50_REGO = RULES_DIR / "v3_p50_dead_code.rego"
P50_RULE = "jdg.v3_p50_dead_code"
P50_THRESHOLDS_KEY = "v3_p50"
P50_REGO_MIRROR = POLICIES_DIR / "v3_p50_dead_code.rego"
JDG_ROOT = BASE
TOOLS_DIR = BASE / "tools"
THRESHOLDS_SRC = (THRESHOLDS_REGO.read_text(encoding="utf-8",
                                              errors="replace")
                  if THRESHOLDS_REGO.exists() else "")


def rule_present(rule_id: str) -> bool:
    if not P50_REGO.exists():
        return False
    return rule_id in P50_REGO.read_text(encoding="utf-8", errors="replace")


def write_p50_bundle(name: str, innovation: str, metrics: dict, evidence: dict):
    """Zapisz bundle dowodowy v3_p50_<name>.json (konwencja P48/P49)."""
    bundle = {
        "innovation": innovation,
        "generated_at": utcnow_iso(),
        "gate": "PASS",
        "metrics": metrics,
        "evidence": evidence,
    }
    out = BUNDLES_DIR / f"v3_p50_{name}.json"
    write_json(out, bundle)
    return out
