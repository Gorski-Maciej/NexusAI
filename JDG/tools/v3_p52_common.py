#!/usr/bin/env python3
"""NexusAI JDG — V3-P52 COMMON — szkielet narzędzi granice groszowe/waluty/zaokrąglenia.

Rozszerza (nie duplikuje) v3_p51_common: ten sam szkielet bundle, prefiks
v3_p52_ (jedno źródło prawdy P00, protokół 08 P45 — zero dryfu prefiksów).
gate=PASS = dowód ZAPISANY i spójny; decyzja AUTO_POST/TRIAGE/BLOCK żyje w
metrics.routing i jest egzekwowana przez politykę jdg.v3_p52_penny_granularity
(decide else-chain, fail-closed).
"""
from __future__ import annotations

from v3_p51_common import (BUNDLES_DIR, BASE, DOCS_DIR, JDG_ROOT, POLICIES_DIR,
                           REPO_ROOT, RULES_DIR, THRESHOLDS_SRC, TOOLS_DIR,
                           read_json, rule_present, utcnow_iso, write_json)

P52_REGO = RULES_DIR / "v3_p52_penny_granularity.rego"
P52_RULE = "jdg.v3_p52_penny_granularity"
P52_THRESHOLDS_KEY = "v3_p52"
P52_REGO_MIRROR = POLICIES_DIR / "v3_p52_penny_granularity.rego"
TESTS_REGO_DIR = BASE / "tests" / "rego"

# Pliki arytmetyczne Sekcji 6 promptu P52 (ścieżki względem JDG/)
ARITH_TOOLS = [
    "vat_rate_engine.py", "zus_calculator.py", "zus_zasilkowa_calculator.py",
    "sanction_calculator.py", "kks_penalty_simulator.py",
    "tax_form_whatif_simulator.py", "p13_crossborder_toolkit.py",
    "jpk_validator.py", "jpk_generator.py",
]
THRESHOLDS_DATA = BUNDLES_DIR / "thresholds_data.json"
FX_RULES = ["r10_crossborder_innovations_v9.rego", "v3_p27_cfc_exit_mdr_enterprise.rego"]


def p52_rule_present(rule_id: str) -> bool:
    return rule_present(rule_id)


def write_p52_bundle(name: str, innovation: str, metrics: dict, evidence: dict):
    """Zapisz bundle dowodowy v3_p52_<name>.json (konwencja P48–P51)."""
    bundle = {
        "innovation": innovation,
        "generated_at": utcnow_iso(),
        "gate": "PASS",
        "metrics": metrics,
        "evidence": evidence,
    }
    out = BUNDLES_DIR / f"v3_p52_{name}.json"
    write_json(out, bundle)
    print(f"[V3-P52] {innovation}: {out.name} gate=PASS")
    return bundle
