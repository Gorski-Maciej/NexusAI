#!/usr/bin/env python3
"""
NexusAI JDG — V3-P54 KSEF/JPK DOMKNIĘCIE — COMMON (konwencja P51–P53).
Pomocnicze: odczyt bundli dowodowych, parser outbox/kolejki offline KSeF,
siatka deadline'ów, hash idempotencji.
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
BUNDLES = JDG_ROOT / "bundles"
RULES_DIR = JDG_ROOT / "rules"
DOCS_DIR = JDG_ROOT / "docs"

KALENDARZ = DOCS_DIR / "KALENDARZ_ZMIAN_PRAWNYCH.md"
OUTBOX_TOOL = JDG_ROOT / "tools" / "ksef_outbox.py"
OFFLINE_TOOL = JDG_ROOT / "tools" / "ksef_offline_queue.py"
JPK_VALIDATOR = JDG_ROOT / "tools" / "jpk_validator.py"
JPK_GENERATOR = JDG_ROOT / "tools" / "jpk_generator.py"


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
    return datetime.now(timezone.utc).isoformat()


def gate(analyses: dict, failures: list) -> str:
    """gate=PASS tylko gdy zero niepowodzeń (konwencja P51–P53)."""
    return "FAIL" if failures else "PASS"


def audit_header(analyses: dict) -> dict:
    """Wspólny szkielet bundla dowodowego P54."""
    return {
        "schema": "jdg.v3_p54.ksef_jpk.audit.v1",
        "part": "P54",
        "slug": "KSEF_JPK_DOMKNIECIE",
        "generated_at": now_iso(),  # wypełnia silnik
        "analyses": analyses,
    }
