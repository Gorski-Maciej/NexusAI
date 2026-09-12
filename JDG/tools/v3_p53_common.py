#!/usr/bin/env python3
"""
NexusAI JDG — V3-P53 TEMPORALNOŚĆ DOMKNIĘCIE — COMMON (konwencja P51/P52).
Pomocnicze: odczyt bundli dowodowych, parysert okien temporalnych, siatka day-0.
"""
from __future__ import annotations

import json
from datetime import date, timedelta
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
BUNDLES = JDG_ROOT / "bundles"
RULES_DIR = JDG_ROOT / "rules"

VALID_FROM_RE = None  # lazily compiled by engines needing regex


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


def day_grid(valid_from: str, valid_to):
    """Siatka day-0: dzień przed granicą, dzień graniczny, dzień po (I02)."""
    vf = date.fromisoformat(valid_from)
    days = {"day_minus_1": (vf - timedelta(days=1)).isoformat(),
            "day_0": vf.isoformat()}
    if valid_to:
        vt = date.fromisoformat(valid_to)
        days["valid_to"] = vt.isoformat()
        days["day_plus_1"] = (vt + timedelta(days=1)).isoformat()
    return days


def window_state(windows, on_date: str) -> str:
    """Stan okna na datę: ACTIVE / EXPIRED (akt wygasł → NEEDS_ADVICE) / NONE."""
    hits = [w for w in windows
            if (not w.get("valid_from") or w["valid_from"] <= on_date)
            and (not w.get("valid_to") or on_date <= w["valid_to"])]
    if hits:
        return "ACTIVE"
    past = [w for w in windows if w.get("valid_to") and on_date > w["valid_to"]]
    return "EXPIRED" if past else "NONE"


def audit_header(analyses: dict) -> dict:
    """Wspólny szkielet bundla dowodowego P53 (gate=PASS przy spełnieniu progów)."""
    return {
        "schema": "jdg.v3_p53.temporal.audit.v1",
        "part": "P53",
        "slug": "TEMPORALNOSC_DOMKNIECIE",
        "generated_at": None,  # wypełnia runner
        "analyses": analyses,
    }
