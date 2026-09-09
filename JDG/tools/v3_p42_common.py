#!/usr/bin/env python3
"""NexusAI JDG — V3-P42 shared evidence helper (kampania V3 FORTRESS).

Wspólne narzędzia dla 12 tooli dowodowych V3-P42-I01..I12: skan reguł w
rules/v3_p42_enterprise_reszta.rego, skan parametrów w
rules/thresholds_jdg.rego (blok v3_p42), wiring main_jdg (final_verdict_p106)
i zapis bundle dowodowych do bundles/.
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
RULES = BASE / "rules"
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"
TESTS = BASE / "tests"
DOCS = BASE / "docs"
MIGRATIONS = BASE / "migrations"

P42_RULES = RULES / "v3_p42_enterprise_reszta.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"
SYSTEM_REGISTER = BUNDLES / "v3_p42_system_register.json"

# Narzędzia z listy Sekcji 6 promptu P42 (dowody wejściowe — istnieją, mierzone)
HEALTH_TIER_ENGINE = TOOLS / "health_tier_engine.py"
HEALTH_TIER_RECALC = TOOLS / "health_tier_recalculator.py"
RYCZALT_ZUS_HARMONIZER = TOOLS / "ryczalt_zus_health_harmonizer.py"
HEALTH_RECONCILIATION = TOOLS / "health_reconciliation_micro.py"
SMT_Z3 = TOOLS / "smt_z3_verification.py"
WORM_STORAGE = TOOLS / "worm_storage.py"
STR_GENERATOR = TOOLS / "str_generator.py"
PROVENANCE_DNA = TOOLS / "rule_provenance_dna.py"
COVERAGE_UNIFIER = TOOLS / "coverage_unifier.py"
ZERO_DEFECT_CERT = TOOLS / "zero_defect_certification.py"

COVERAGE_CANON = BUNDLES / "coverage_canon.json"
LEGAL_GRAPH = BUNDLES / "legal_graph.json"
RULE_REGISTRY = BUNDLES / "rule_registry.json"
HEALTHY_VERSIONS = BUNDLES / "healthy_versions.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def read_json(path: Path):
    """Wczytaj JSON albo {} gdy plik nie istnieje/uszkodzony (fail-closed: {})."""
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8", errors="ignore"))
    except json.JSONDecodeError:
        return {}


def rule_present(rule_id: str, hay: str | None = None) -> bool:
    hay = hay if hay is not None else read(P42_RULES)
    return rule_id in hay


def threshold_present(key: str, hay: str | None = None) -> bool:
    hay = hay if hay is not None else read(THRESHOLDS)
    return re.search(rf'"{re.escape(key)}"\s*:', hay) is not None


def main_jdg_wired(alias: str = "v3_p42_enterprise_reszta") -> bool:
    main = read(MAIN_JDG)
    return (f"import data.jdg.{alias} as {alias}" in main
            and f'"jdg.{alias}": {alias}.decide' in main
            and "final_verdict_p106" in main)


def emit(bundle: dict, name: str) -> int:
    (BUNDLES / f"{name}.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    gate = bundle.get("gate", "FAIL")
    print(f"[{bundle.get('innovation', name)}] gate={gate} "
          f"checks={len(bundle.get('checks', []))} findings={len(bundle.get('findings', []))}")
    return 1 if gate == "FAIL" else 0
