#!/usr/bin/env python3
"""
NexusAI JDG — V3-P63 RBAC, MULTI-TENANT I DANE — COMMON (konwencja P51–P62).
Pomocnicze: czytniki PRAWDZIWYCH źródeł warstwy dostępu i danych
(bundles/v3_p40_rbac_minimization.json, v3_p40_api_audit_worm.json,
v3_p57_tenant_isolation.json, v3_p57_rate_governor.json, v3_p58_privacy.json,
v3_p42_retention_calculator.json, v3_p33_federated_privacy_guard.json,
v3_p44_owner_attestation.json, v3_p47_human_stamps.json, v3_p25_tenant_
calendar.json, rules/rodo_extended.rego, migrations/*.sql,
tools/rodo_register_generator.py, docs/ROLE_MAPS.md) + odczyt progów ADR-002
z thresholds_jdg.rego (jedno źródło prawdy — silniki czytają TE SAME klucze
co Rego P63; parser obsługuje listy/stringi/bool/int/float — lekcja z P62).
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
MIGRATIONS_DIR = JDG_ROOT / "migrations"
THRESHOLDS_REGO = RULES_DIR / "thresholds_jdg.rego"
MAIN_JDG_REGO = RULES_DIR / "main_jdg.rego"

# PRAWDZIWE artefakty warstwy dostępu i danych (rozszerzane, nie dublowane):
P40_RBAC = BUNDLES / "v3_p40_rbac_minimization.json"           # P40-I04
P40_AUDIT_WORM = BUNDLES / "v3_p40_api_audit_worm.json"        # P40-I05
P57_TENANT = BUNDLES / "v3_p57_tenant_isolation.json"          # P57-I11
P57_GOVERNOR = BUNDLES / "v3_p57_rate_governor.json"           # P57-I12
P58_PRIVACY = BUNDLES / "v3_p58_privacy.json"                  # P58-I11
P42_RETENTION = BUNDLES / "v3_p42_retention_calculator.json"   # P42-I04
P33_PRIVACY_GUARD = BUNDLES / "v3_p33_federated_privacy_guard.json"  # P33-I10
P44_ATTESTATION = BUNDLES / "v3_p44_owner_attestation.json"    # P44-I11
P47_STAMPS = BUNDLES / "v3_p47_human_stamps.json"              # P47-I10
P25_TENANT_CAL = BUNDLES / "v3_p25_tenant_calendar.json"       # P25-I07
RODO_EXTENDED_REGO = RULES_DIR / "rodo_extended.rego"
RODO_REGISTER_TOOL = TOOLS_DIR / "rodo_register_generator.py"
ROLE_MAPS_DOC = DOCS_DIR / "ROLE_MAPS.md"
P60_ROLE_MAPS = BUNDLES / "v3_p60_role_maps.json"


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
    """Progi ADR-002 z thresholds_jdg.rego — to samo źródło co Rego P63.
    Obsługuje: listy stringów, stringi, bool, int, float (lekcja z P62)."""
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
    """Bramka z bundla (gate top-level lub result.gate — konwencja P54–P62)."""
    d = read_json(path)
    if isinstance(d, dict):
        if isinstance(d.get("gate"), str):
            return d["gate"]
        res = d.get("result")
        if isinstance(res, dict) and isinstance(res.get("gate"), str):
            return res["gate"]
    return None


def bundle_metrics(path: Path) -> dict:
    """Metryki z bundla konwencji P32/P40/P42 (metrics/checks) lub P54+ (result)."""
    d = read_json(path) or {}
    return d.get("metrics", d.get("result", d))


def audit_header(analyses: dict) -> dict:
    return {
        "schema": "jdg.v3_p63.rbac.audit.v1",
        "part": "P63",
        "slug": "RBAC_MULTITENANT",
        "generated_at": None,
        "analyses": analyses,
    }
