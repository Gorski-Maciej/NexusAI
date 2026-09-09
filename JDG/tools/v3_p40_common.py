#!/usr/bin/env python3
"""NexusAI JDG — V3-P40 shared evidence helper (kampania V3 FORTRESS).

Wspólne narzędzia dla 12 tooli dowodowych V3-P40-I01..I12: skan reguł w
rules/v3_p40_api_dane_ui_enterprise.rego, skan parametrów w
rules/thresholds_jdg.rego (blok v3_p40), wiring main_jdg (final_verdict_p104)
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

P40_RULES = RULES / "v3_p40_api_dane_ui_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"
API_CONTRACT = BUNDLES / "v3_p40_api_contract.json"
CERT_SERVICE = TOOLS / "certificate_service.py"

# Ścieżki z listy Sekcja 6 promptu P40 (dowody wejściowe)
OPENAPI = BASE / "api" / "openapi.yaml"
ORCH_CONTRACT = DOCS / "ORCHESTRATOR_DATA_CONTRACT.md"
API_REF = DOCS / "API_REFERENCJA.md"
API_MD = DOCS / "api.md"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def read_json(path: Path):
    """Wczytaj JSON albo {} gdy plik nie istnieje/uszkodzony (fail-closed: {}).
    """
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8", errors="ignore"))
    except json.JSONDecodeError:
        return {}


def rule_present(rule_id: str, hay: str | None = None) -> bool:
    hay = hay if hay is not None else read(P40_RULES)
    return rule_id in hay


def threshold_present(key: str, hay: str | None = None) -> bool:
    hay = hay if hay is not None else read(THRESHOLDS)
    return re.search(rf'"{re.escape(key)}"\s*:', hay) is not None


def main_jdg_wired(alias: str = "v3_p40_api_dane_ui") -> bool:
    main = read(MAIN_JDG)
    return (f"import data.jdg.{alias} as {alias}" in main
            and f'"jdg.{alias}": {alias}.decide' in main
            and "final_verdict_p104" in main)


def emit(bundle: dict, name: str) -> int:
    (BUNDLES / f"{name}.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    gate = bundle.get("gate", "FAIL")
    print(f"[{bundle.get('innovation', name)}] gate={gate} "
          f"checks={len(bundle.get('checks', []))} findings={len(bundle.get('findings', []))}")
    return 1 if gate == "FAIL" else 0
