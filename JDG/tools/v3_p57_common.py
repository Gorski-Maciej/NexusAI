#!/usr/bin/env python3
"""
NexusAI JDG — V3-P57 INGEST DANYCH — COMMON (konwencja P51–P56).
Pomocnicze: odczyt bundli dowodowych, ładowanie narzędzi rdzenia jako modułów
(rozszerzamy, nie duplikujemy), odczyt progów ADR-002 z thresholds_jdg.rego
(jedno źródło prawdy — silniki czytają TE SAME klucze co Rego).
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

# Narzędzia rdzenia (sekcja 6 promptu P57) — rozszerzane przez silniki.
WORM_STORAGE = TOOLS_DIR / "worm_storage.py"
KSEF_OFFLINE_QUEUE = TOOLS_DIR / "ksef_offline_queue.py"
KSEF_OUTBOX = TOOLS_DIR / "ksef_outbox.py"
ORCH_CONTRACT = DOCS_DIR / "ORCHESTRATOR_DATA_CONTRACT.md"
P32_RULES = RULES_DIR / "v3_p32_ksiegowosc_automation.rego"
THRESHOLDS_REGO = RULES_DIR / "thresholds_jdg.rego"


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
    try:
        return THRESHOLDS_REGO.read_text(encoding="utf-8")
    except Exception:
        return ""


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


def audit_header(analyses: dict) -> dict:
    return {
        "schema": "jdg.v3_p57.ingest.audit.v1",
        "part": "P57",
        "slug": "INGEST_DANYCH",
        "generated_at": None,  # wypełnia silnik
        "analyses": analyses,
    }
