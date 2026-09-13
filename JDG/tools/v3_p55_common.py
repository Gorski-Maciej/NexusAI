#!/usr/bin/env python3
"""
NexusAI JDG — V3-P55 ZUS DOMKNIĘCIE — COMMON (konwencja P51–P54).
Pomocnicze: odczyt bundli dowodowych, ładowanie narzędzi rdzenia ZUS jako
modułów (rozszerzamy, nie duplikujemy), siatki day-0 dla granic ulg.
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

# Narzędzia rdzenia (sekcja 6.1 promptu P55) — rozszerzane przez silniki.
ZUS_CALCULATOR = TOOLS_DIR / "zus_calculator.py"
ZASILKOWA_CALC = TOOLS_DIR / "zus_zasilkowa_calculator.py"
ZUS_CALENDAR = TOOLS_DIR / "zus_calendar.py"
SICKNESS_TRACKER = TOOLS_DIR / "sickness_duration_tracker.py"
PREFERENTIAL_TRACKER = TOOLS_DIR / "preferential_period_tracker.py"
BASE_VALIDATOR = TOOLS_DIR / "contribution_base_validator.py"
HEALTH_HARMONIZER = TOOLS_DIR / "ryczalt_zus_health_harmonizer.py"
TIER_ENGINE = TOOLS_DIR / "zdrowotna_tier_engine.py"
ATOM_MATRIX = TOOLS_DIR / "zus_atom_test_matrix.py"
ATOM_LINTER = TOOLS_DIR / "zus_atom_linter.py"
COMPLETENESS_ENGINE = TOOLS_DIR / "zus_completeness_engine.py"
RULE_SHARDING = TOOLS_DIR / "zus_rule_sharding.py"

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
        "schema": "jdg.v3_p55.zus.audit.v1",
        "part": "P55",
        "slug": "ZUS_DOMKNIECIE",
        "generated_at": None,  # wypełnia silnik
        "analyses": analyses,
    }
