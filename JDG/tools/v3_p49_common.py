#!/usr/bin/env python3
"""NexusAI JDG — V3-P49 COMMON — wspólny szkielet narzędzi domknięcia fail-closed.

Rozszerza (nie duplikuje) v3_p48_common: ten sam szkielet bundle, prefiks
v3_p49_ (jedno źródło prawdy P00; zero dryfu konwencji P48). Konwencja
gate=PASS = dowód ZAPISANY i spójny; decyzja TRIAGE/BLOCK żyje w metrics.routing.
"""
from __future__ import annotations

from v3_p48_common import (BUNDLES_DIR, RULES_DIR, read_json, utcnow_iso,
                           write_json)

P49_REGO = RULES_DIR / "v3_p49_fail_closed.rego"
P49_RULE = "jdg.v3_p49_fail_closed"
P49_THRESHOLDS_KEY = "v3_p49"


def rule_present(rule_id: str) -> bool:
    if not P49_REGO.exists():
        return False
    return rule_id in P49_REGO.read_text(encoding="utf-8", errors="replace")


def write_p49_bundle(name: str, innovation: str, metrics: dict, evidence: dict):
    """Zapisz bundle dowodowy v3_p49_<name>.json (konwencja P48 gate=PASS)."""
    bundle = {
        "innovation": innovation,
        "generated_at": utcnow_iso(),
        "gate": "PASS",
        "metrics": metrics,
        "evidence": evidence,
    }
    out = BUNDLES_DIR / f"v3_p49_{name}.json"
    write_json(out, bundle)
    return out
