#!/usr/bin/env python3
"""
NexusAI JDG — V3-P56 VAT/PIT SZCZEGÓŁY — COMMON (konwencja P51–P55).
Pomocnicze: odczyt bundli dowodowych, ładowanie narzędzi rdzenia VAT/PIT jako
modułów (rozszerzamy, nie duplikujemy), siatki day-0 dla granic okien danych.
"""
from __future__ import annotations

import importlib.util
import json
from datetime import date, timedelta
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
BUNDLES = JDG_ROOT / "bundles"
RULES_DIR = JDG_ROOT / "rules"
DOCS_DIR = JDG_ROOT / "docs"
TOOLS_DIR = JDG_ROOT / "tools"

# Narzędzia rdzenia (sekcja 6 promptu P56) — rozszerzane przez silniki.
VAT_REGO = RULES_DIR / "micro" / "vat" / "vat.rego"
VAT_RATE_ENGINE = TOOLS_DIR / "vat_rate_engine.py"
VAT_MPP_DETECTOR = TOOLS_DIR / "vat_mpp_auto_detector.py"
CROSSBORDER_TOOLKIT = TOOLS_DIR / "p13_crossborder_toolkit.py"
VAT_GAP_DETECTOR = TOOLS_DIR / "vat_gap_detector.py"
VAT_INNOVATION = TOOLS_DIR / "vat_innovation_tools.py"
PIT_TEMPORAL = TOOLS_DIR / "pit_temporal_snapshot_engine.py"
PIT_INNOVATION = TOOLS_DIR / "pit_innovation_tools.py"
WHATIF_SIMULATOR = TOOLS_DIR / "tax_form_whatif_simulator.py"
UOR_TOOLKIT = TOOLS_DIR / "p12_uor_toolkit.py"
UOR_ACCOUNTING = TOOLS_DIR / "p12_uor_accounting_toolkit.py"

KALENDARZ = DOCS_DIR / "KALENDARZ_ZMIAN_PRAWNYCH.md"


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


def day_grid(day_of_month: int, year: int, month: int) -> dict:
    """Siatka day-0 dla terminu miesięcznego (dzień przed/termin/dzień po)."""
    base = date(year, month, day_of_month)
    return {"day_minus_1": (base - timedelta(days=1)).isoformat(),
            "day_0": base.isoformat(),
            "day_plus_1": (base + timedelta(days=1)).isoformat()}


def audit_header(analyses: dict) -> dict:
    return {
        "schema": "jdg.v3_p56.vat_pit.audit.v1",
        "part": "P56",
        "slug": "VAT_PIT_SZCZEGOLY",
        "generated_at": None,  # wypełnia silnik
        "analyses": analyses,
    }
