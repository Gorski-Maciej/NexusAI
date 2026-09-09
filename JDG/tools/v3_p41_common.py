#!/usr/bin/env python3
"""NexusAI JDG — V3-P41 shared evidence helper (kampania V3 FORTRESS).

Wspólne narzędzia dla 12 tooli dowodowych V3-P41-I01..I12: skan reguł w
rules/v3_p41_dokumentacja_enterprise.rego, skan parametrów w
rules/thresholds_jdg.rego (blok v3_p41), wiring main_jdg (final_verdict_p105)
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

P41_RULES = RULES / "v3_p41_dokumentacja_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"
DOC_REGISTRY = BUNDLES / "v3_p41_doc_registry.json"
DOC_VALIDATOR = TOOLS / "doc_consistency_validator.py"
WORKFLOW = BASE / ".github" / "workflows" / "jdg-quality.yml"
RUNBOOKS = DOCS / "runbooks"

# Dokumenty z listy Sekcja 6 promptu P41 (dowody wejściowe)
HOLY1 = DOCS / "ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md"
HOLY2 = DOCS / "WIZJA_OPA_ENTERPRISE_V2.md"
ARCH_PL = DOCS / "ARCHITEKTURA.md"
ARCH_EN = DOCS / "ARCHITECTURE.md"
GLOSSARY = DOCS / "SLOWNIK_REFERENCJI_PRAWNYCH.md"
LEGAL_ACTS = DOCS / "LEGAL_REFERENCE_ACTS.md"
LEGAL_REGISTRY = DOCS / "LEGAL_SOURCE_REGISTRY.md"
BBB = DOCS / "Bbb"
KATALOG_REGUL = DOCS / "KATALOG_REGUL.md"
MANIFEST_2_0 = DOCS / "MANIFEST_2_0.md"

SECTION6_DOCS = [
    "ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md", "WIZJA_OPA_ENTERPRISE_V2.md",
    "ARCHITEKTURA.md", "ARCHITECTURE.md", "STRUKTURA_PROJEKTU.md",
    "MANIFEST_2_0.md", "UNIFIED_PLAN.md", "ANALIZA_STANU_OPA_JAKO_SYSTEM.md",
    "DEVELOPER_GUIDE.md", "OPA_REGO_DEVELOPER_GUIDE.md",
    "PODRECZNIK_UZYTKOWNIKA.md", "API_REFERENCJA.md", "FAQ.md",
    "NARZEDZIA_WALIDACJI_P22.md", "KATALOG_NARZEDZI.md", "KATALOG_REGUL.md",
    "SLOWNIK_REFERENCJI_PRAWNYCH.md", "LEGAL_REFERENCE_ACTS.md",
    "LEGAL_SOURCE_REGISTRY.md", "KALENDARZ_ZMIAN_PRAWNYCH.md",
    "ZGODNOSC_PRAWNA.md", "ZGODNOSC_DOKUMENTY_KSIEGOWE.md", "Bbb",
    "AUDYT_PODSTAW_PRAWNYCH.md",
]


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
    hay = hay if hay is not None else read(P41_RULES)
    return rule_id in hay


def threshold_present(key: str, hay: str | None = None) -> bool:
    hay = hay if hay is not None else read(THRESHOLDS)
    return re.search(rf'"{re.escape(key)}"\s*:', hay) is not None


def main_jdg_wired(alias: str = "v3_p41_dokumentacja") -> bool:
    main = read(MAIN_JDG)
    return (f"import data.jdg.{alias} as {alias}" in main
            and f'"jdg.{alias}": {alias}.decide' in main
            and "final_verdict_p105" in main)


def emit(bundle: dict, name: str) -> int:
    (BUNDLES / f"{name}.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    gate = bundle.get("gate", "FAIL")
    print(f"[{bundle.get('innovation', name)}] gate={gate} "
          f"checks={len(bundle.get('checks', []))} findings={len(bundle.get('findings', []))}")
    return 1 if gate == "FAIL" else 0
