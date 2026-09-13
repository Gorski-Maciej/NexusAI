#!/usr/bin/env python3
"""
NexusAI JDG — V3-P62 PRZEPŁYWY PIENIĘŻNE — COMMON (konwencja P51–P61).
Pomocnicze: czytniki PRAWDZIWYCH źródeł warstwy płatności/cashflow
(bundles/v3_p55_payment_priority.json, v3_p55_pre_payment_gate.json,
v3_p57_{dedup,worm,chaos,tenant_isolation,reconciliation}.json,
v3_p17_interest_precision_engine.json, v3_p19_instalment_reminder.json,
rules/cashflow_tax_predictor_enterprise.rego, rules/banking_automation_
enterprise.rego, tools/zus_calendar.py, tools/worm_storage.py,
tools/v3_p32_two_phase_close.py) + odczyt progów ADR-002 z
thresholds_jdg.rego (jedno źródło prawdy — silniki czytają TE SAME klucze
co Rego P62).
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
BUNDLES = JDG_ROOT / "bundles"
DOCS_DIR = JDG_ROOT / "docs"
TOOLS_DIR = JDG_ROOT / "tools"
RULES_DIR = JDG_ROOT / "rules"
TESTS_AUTO = JDG_ROOT / "tests" / "auto"
THRESHOLDS_REGO = RULES_DIR / "thresholds_jdg.rego"
MAIN_JDG_REGO = RULES_DIR / "main_jdg.rego"

# PRAWDZIWE artefakty warstwy płatności/cashflow (rozszerzane, nie dublowane):
P55_PRIORITY = BUNDLES / "v3_p55_payment_priority.json"        # P55-I08
P55_PRE_GATE = BUNDLES / "v3_p55_pre_payment_gate.json"        # P55-I12
P57_DEDUP = BUNDLES / "v3_p57_dedup.json"                      # P57 dedup
P57_WORM = BUNDLES / "v3_p57_worm.json"                        # P57 WORM
P57_CHAOS = BUNDLES / "v3_p57_chaos.json"                      # P57 chaos
P57_TENANT = BUNDLES / "v3_p57_tenant_isolation.json"          # P57 izolacja
P57_RECON = BUNDLES / "v3_p57_reconciliation.json"             # P57-I07
P17_INTEREST = BUNDLES / "v3_p17_interest_precision_engine.json"  # P17-I01
P19_REMINDER = BUNDLES / "v3_p19_instalment_reminder.json"     # P19
CASHFLOW_PREDICTOR_REGO = RULES_DIR / "cashflow_tax_predictor_enterprise.rego"
VAT_CASHFLOW_REGO = RULES_DIR / "vat_cashflow_predictor_enterprise.rego"
BANKING_REGO = RULES_DIR / "banking_automation_enterprise.rego"
ZUS_CALENDAR = TOOLS_DIR / "zus_calendar.py"
WORM_STORAGE = TOOLS_DIR / "worm_storage.py"
TWO_PHASE_CLOSE = TOOLS_DIR / "v3_p32_two_phase_close.py"


def read_text(path: Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8", errors="replace")


def read_json(path: Path):
    if not path.exists():
        return None
    try:
        return json.loads(read_text(path))
    except json.JSONDecodeError:
        return None


def write_json(path: Path, payload) -> bool:
    try:
        path.write_text(json.dumps(payload, ensure_ascii=False, indent=2),
                        encoding="utf-8")
        return True
    except OSError:
        return False


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def read_threshold(key: str):
    """Progi ADR-002 z thresholds_jdg.rego — to samo źródło co Rego P62.
    Obsługuje: listy stringów, stringi, bool, int, float."""
    src = read_text(THRESHOLDS_REGO)
    m = re.search(
        rf'"{key}"\s*:\s*(\[[^\]]*\]|"(?:[^"\\]|\\.)*"|true|false|-?\d+(?:\.\d+)?)',
        src)
    if not m:
        return None
    raw = m.group(1)
    if raw.startswith("["): 
        items = re.findall(r'"([^"]+)"', raw)
        return items if items else None
    if raw.startswith('"'):
        return raw[1:-1]
    if raw == "true":
        return True
    if raw == "false":
        return False
    return float(raw) if "." in raw else int(raw)


def bundle_gate(path: Path) -> str | None:
    """Bramka z bundla (gate top-level lub result.gate — konwencja P54–P61)."""
    d = read_json(path)
    if isinstance(d, dict):
        if isinstance(d.get("gate"), str):
            return d["gate"]
        res = d.get("result")
        if isinstance(res, dict) and isinstance(res.get("gate"), str):
            return res["gate"]
    return None


def audit_header(analyses: dict) -> dict:
    return {
        "schema": "jdg.v3_p62.cashflow.audit.v1",
        "part": "P62",
        "slug": "PRZEPYWY_PIENIEZNE",
        "generated_at": None,
        "analyses": analyses,
    }
