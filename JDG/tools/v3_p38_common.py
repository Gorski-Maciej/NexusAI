#!/usr/bin/env python3
"""NexusAI JDG — V3-P38 shared evidence helper (kampania V3 FORTRESS).

Wspólne narzędzia dla 12 tooli dowodowych V3-P38-I01..I12: skan reguł w
rules/v3_p38_bundle_deploy_enterprise.rego, skan parametrów w
rules/thresholds_jdg.rego (blok v3_p38), wiring main_jdg (final_verdict_p102)
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
DOCS = BASE / "docs"

P38_RULES = RULES / "v3_p38_bundle_deploy_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"
DEPLOY_CONTRACT = BUNDLES / "v3_p38_deploy_contract.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def rule_present(rule_id: str, hay: str | None = None) -> bool:
    hay = hay if hay is not None else read(P38_RULES)
    return rule_id in hay


def threshold_present(key: str, hay: str | None = None) -> bool:
    hay = hay if hay is not None else read(THRESHOLDS)
    return re.search(rf'"{re.escape(key)}"\s*:', hay) is not None


def main_jdg_wired(alias: str = "v3_p38_bundle_deploy") -> bool:
    main = read(MAIN_JDG)
    return (f"import data.jdg.{alias} as {alias}" in main
            and f'"jdg.{alias}": {alias}.decide' in main
            and "final_verdict_p102" in main)


def emit(bundle: dict, name: str) -> int:
    (BUNDLES / f"{name}.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    gate = bundle.get("gate", "FAIL")
    print(f"[{bundle.get('innovation', name)}] gate={gate} "
          f"checks={len(bundle.get('checks', []))} findings={len(bundle.get('findings', []))}")
    return 1 if gate == "FAIL" else 0
