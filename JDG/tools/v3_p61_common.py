#!/usr/bin/env python3
"""
NexusAI JDG — V3-P61 INTEGRACJE DOMKNIĘCIE — COMMON (konwencja P51–P60).
Pomocnicze: czytniki PRAWDZIWYCH źródeł warstwy integracji (ksef_outbox.py,
ksef_offline_queue.py, fx_rate_engine.py + bundles/fx_provenance.json,
isap_crawler.py + cache, v3_p57_reconciliation.json, v3_p49 breaker +
thresholds_jdg.rego, v3_p54 attestation, v3_p16 chaos drill, v3_p58 runbook/
SLO, bundles/metrics.json P37) + odczyt progów ADR-002 z thresholds_jdg.rego
(jedno źródło prawdy — silniki czytają TE SAME klucze co Rego).
"""
from __future__ import annotations

import hashlib
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

# PRAWDZIWE artefakty warstwy integracji (rozszerzane, nie dublowane):
FX_PROVENANCE = BUNDLES / "fx_provenance.json"                 # P52/P53
P57_RECONCILIATION = BUNDLES / "v3_p57_reconciliation.json"    # P57-I07
P54_ATTESTATION = BUNDLES / "v3_p54_integration_attestation.json"  # P54-I12
P54_OUTBOX_PROOF = BUNDLES / "v3_p54_idempotent_outbox.json"   # P54-I06
P16_CHAOS_DRILL = BUNDLES / "v3_p16_chaos_ksef_drill.json"     # P43/P16-I09
P16_ZERO_LOSS = BUNDLES / "v3_p16_zero_loss_queue.json"        # P16-I02
P58_RUNBOOK = BUNDLES / "v3_p58_runbook_contract.json"         # P58-I07
P58_SLO_DOMAINS = BUNDLES / "v3_p58_slo_domains.json"          # P58-I12
METRICS_JSON = BUNDLES / "metrics.json"                        # P37 SLO
KSEF_OUTBOX_TOOL = TOOLS_DIR / "ksef_outbox.py"
KSEF_OFFLINE_QUEUE_TOOL = TOOLS_DIR / "ksef_offline_queue.py"
FX_RATE_ENGINE = TOOLS_DIR / "fx_rate_engine.py"
ISAP_CRAWLER = TOOLS_DIR / "isap_crawler.py"
ISAP_CACHE_DIR = TOOLS_DIR / ".isap_cache"
CIRCUIT_BREAKER = TOOLS_DIR / "v3_p49_circuit_breaker.py"
CACHE_MANIFEST = BUNDLES / "v3_p61_cache_manifest.json"        # I05 (wynik)
INTEGRATION_REGISTRY = BUNDLES / "v3_p61_integration_registry.json"  # I08/I09


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


def file_age_days(path: Path) -> float | None:
    if not path.exists():
        return None
    mtime = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc)
    return round((datetime.now(timezone.utc) - mtime).total_seconds() / 86400, 2)


def sha256_obj(obj) -> str:
    """Deterministyczna checksuma rekordu danych referencyjnych (I03)."""
    canonical = json.dumps(obj, sort_keys=True, ensure_ascii=False,
                           separators=(",", ":"))
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()[:16]


def read_threshold(key: str):
    """Progi ADR-002 z thresholds_jdg.rego — to samo źródło co Rego P61."""
    src = read_text(THRESHOLDS_REGO)
    m = re.search(rf'"{key}"\s*:\s*(\[[^\]]*\]|true|false|-?\d+(?:\.\d+)?)', src)
    if not m:
        return None
    raw = m.group(1)
    if raw.startswith("["):
        items = re.findall(r'"([^"]+)"', raw)
        return items if items else None
    if raw == "true":
        return True
    if raw == "false":
        return False
    return float(raw) if "." in raw else int(raw)


def audit_header(analyses: dict) -> dict:
    return {
        "schema": "jdg.v3_p61.integrations.audit.v1",
        "part": "P61",
        "slug": "INTEGRACJE_DOMKNIECIE",
        "generated_at": None,
        "analyses": analyses,
    }
