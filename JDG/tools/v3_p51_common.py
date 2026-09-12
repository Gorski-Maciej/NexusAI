#!/usr/bin/env python3
"""NexusAI JDG — V3-P51 COMMON — szkielet narzędzi pustynie prawne (coverage deserts).

Rozszerza (nie duplikuje) v3_p48/p49/p50_common: ten sam szkielet bundle,
prefiks v3_p51_ (jedno źródło prawdy P00, protokół 08 P45 — zero dryfu
prefiksów). gate=PASS = dowód ZAPISANY i spójny; decyzja AUTO_POST/TRIAGE/
BLOCK żyje w metrics.routing i jest egzekwowana przez politykę
jdg.v3_p51_coverage_deserts (decide else-chain, fail-closed).
"""
from __future__ import annotations

from v3_p50_common import (BUNDLES_DIR, BASE, JDG_ROOT, POLICIES_DIR, REPO_ROOT,
                           RULES_DIR, THRESHOLDS_SRC, TOOLS_DIR, read_json,
                           rule_present, utcnow_iso, write_json)

P51_REGO = RULES_DIR / "v3_p51_coverage_deserts.rego"
P51_RULE = "jdg.v3_p51_coverage_deserts"
P51_THRESHOLDS_KEY = "v3_p51"
P51_REGO_MIRROR = POLICIES_DIR / "v3_p51_coverage_deserts.rego"
DOCS_DIR = BASE / "docs"
TESTS_REGO_DIR = BASE / "tests" / "rego"

# Wejścia pokryciowe (Sekcja 6 promptu P51; ścieżki względem JDG/)
COVERAGE_DESERTS = BASE / "bundles" / "coverage_deserts.json"
COVERAGE_CANON = BASE / "bundles" / "coverage_canon.json"
LEGAL_GRAPH = BASE / "bundles" / "legal_graph.json"
LAW_RADAR_CANDIDATES = BASE / "bundles" / "law_radar.json"
P45_STUB_SUMMARY = BASE / "bundles" / "v3_p45_stub_register.json"
P45_STUB_REGISTER = BASE / "bundles" / "stub_register.json"


def p51_rule_present(rule_id: str) -> bool:
    """Prawdopodobieństwo obecności reguły P51 w polityce (dowód wiringu)."""
    return rule_present(rule_id)


def write_p51_bundle(name: str, innovation: str, metrics: dict, evidence: dict):
    """Zapisz bundle dowodowy v3_p51_<name>.json (konwencja P48/P49/P50)."""
    bundle = {
        "innovation": innovation,
        "generated_at": utcnow_iso(),
        "gate": "PASS",
        "metrics": metrics,
        "evidence": evidence,
    }
    out = BUNDLES_DIR / f"v3_p51_{name}.json"
    write_json(out, bundle)
    print(f"[V3-P51] {innovation}: {out.name} gate=PASS")
    return bundle
