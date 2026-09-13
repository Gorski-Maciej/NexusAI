#!/usr/bin/env python3
"""
NexusAI JDG — V3-P58 OBSERWOWALNOŚĆ DOMKNIĘCIE — COMMON (konwencja P51–P57).
Pomocnicze: czytniki PRAWDZIWYCH źródeł telemetrii (decision_certificates.json
P11 — telemetria bez podwójnej instrumentacji; metrics.json P37; deployments.json
P38; bundli P52; KALENDARZ_ZMIAN_PRAWNYCH P25/P47) + odczyt progów ADR-002
z thresholds_jdg.rego (jedno źródło prawdy — silniki czytają TE SAME klucze co
Rego).
"""
from __future__ import annotations

import importlib.util
import json
import re
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
BUNDLES = JDG_ROOT / "bundles"
RULES_DIR = JDG_ROOT / "rules"
DOCS_DIR = JDG_ROOT / "docs"
TOOLS_DIR = JDG_ROOT / "tools"

# Prawdziwe źródła telemetrii (sekcja 6 promptu P58) — rozszerzane, nie duplikowane.
CERTIFICATES_JSON = BUNDLES / "decision_certificates.json"
METRICS_JSON = BUNDLES / "metrics.json"
DEPLOYMENTS_JSON = BUNDLES / "deployments.json"
P52_DRIFT_JSON = BUNDLES / "v3_p52_drift_telemetry.json"
KALENDARZ = DOCS_DIR / "KALENDARZ_ZMIAN_PRAWNYCH.md"
THRESHOLDS_REGO = RULES_DIR / "thresholds_jdg.rego"
ENTERPRISE_CONTRACT = BUNDLES / "enterprise_operating_contract.json"


def read_json(path: Path):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except Exception:
        return None


def write_json(path: Path, payload) -> bool:
    try:
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        Path(path).write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
        return True
    except Exception:
        return False


def read_text(path: Path) -> str:
    try:
        return Path(path).read_text(encoding="utf-8")
    except Exception:
        return ""


def now_iso() -> str:
    from datetime import datetime, timezone
    return datetime.now(timezone.utc).isoformat()


def load_tool_module(name: str, path: Path):
    """Załaduj istniejące narzędzie jako moduł (kontrakt: rozszerzaj, nie kopiuj)."""
    if not path.exists():
        return None
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(mod)
        return mod
    except Exception:
        return None


# ── Odczyt progów ADR-002 z thresholds_jdg.rego (jedno źródło prawdy) ─────────
def _thresholds_text() -> str:
    return read_text(THRESHOLDS_REGO)


def read_threshold_str(key: str) -> str | None:
    m = re.search(rf'"{key}":\s*"([^"]+)"', _thresholds_text())
    return m.group(1) if m else None


def read_threshold_int(key: str) -> int | None:
    m = re.search(rf'"{key}":\s*(\d+)', _thresholds_text())
    return int(m.group(1)) if m else None


def read_threshold_list(key: str) -> list:
    m = re.search(rf'"{key}":\s*\[([^\]]*)\]', _thresholds_text())
    if not m:
        return []
    return re.findall(r'"([^"]+)"', m.group(1))


def load_certificates() -> list:
    """Certyfikaty decyzji P11 — JEDYNE źródło telemetrii decyzji (bez podwójnej
    instrumentacji; kontrakt 11.1 promptu P58)."""
    d = read_json(CERTIFICATES_JSON) or {}
    certs = d.get("certificates", {})
    if isinstance(certs, dict):
        return list(certs.values())
    return list(certs)


def cert_domain(cert: dict) -> str:
    """Domena decyzji z rule_id (konwencja: jdg.<pakiet>.<reguła>)."""
    rid = ((cert.get("decision") or {}).get("rule_id")) or ""
    parts = rid.split(".")
    return parts[1] if len(parts) > 2 else (parts[0] if parts else "unknown")


def audit_header(analyses: dict) -> dict:
    return {
        "schema": "jdg.v3_p58.observability.audit.v1",
        "part": "P58",
        "slug": "OBSERWOWALNOSC_DOMKNIECIE",
        "generated_at": None,  # wypełnia silnik
        "analyses": analyses,
    }
