"""Shared P13 threshold registry reader.

The Rego threshold file is the source of truth. Python tools use these values
for calculations and expose the source path/hash in their results.
"""
from __future__ import annotations

import hashlib
import re
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
THRESHOLDS_PATH = ROOT / "rules" / "thresholds_jdg.rego"


@dataclass(frozen=True)
class P13Thresholds:
    limit_eur: float
    eur_pln: float
    warning_pct: float
    min_wage_pln: float
    unregistered_pct: float
    suspension_max_months: int
    suspension_min_days: int
    ceidg_days: int
    succession_days: int
    source: str
    source_sha256: str

    @property
    def limit_pln(self) -> float:
        return self.limit_eur * self.eur_pln


def _read_number(text: str, key: str, default: float) -> float:
    match = re.search(rf'"{re.escape(key)}"\s*:\s*([-+]?\d+(?:\.\d+)?)', text)
    return float(match.group(1)) if match else default


def load_thresholds(path: Path = THRESHOLDS_PATH) -> P13Thresholds:
    """Load P13 values from the business_lifecycle object in thresholds_jdg.rego."""
    text = path.read_text(encoding="utf-8")
    return P13Thresholds(
        limit_eur=_read_number(text, "ryczalt_limit_eur", 2_000_000),
        eur_pln=_read_number(text, "eur_pln_reference", 4.30),
        warning_pct=_read_number(text, "ryczalt_warning_pct", 75),
        min_wage_pln=_read_number(text, "min_wage_pln", 4_800),
        unregistered_pct=_read_number(text, "unregistered_min_wage_pct", 0.5) * 100
        if _read_number(text, "unregistered_min_wage_pct", 0.5) <= 1
        else _read_number(text, "unregistered_min_wage_pct", 50),
        suspension_max_months=int(_read_number(text, "suspension_max_months", 24)),
        suspension_min_days=int(_read_number(text, "suspension_min_days", 30)),
        ceidg_days=int(_read_number(text, "ceidg_registration_days", 7)),
        succession_days=int(_read_number(text, "succession_appointment_days", 14)),
        source=str(path.relative_to(ROOT)),
        source_sha256=hashlib.sha256(text.encode("utf-8")).hexdigest(),
    )


LEGAL_RATES = (3.0, 5.5, 8.5, 10.0, 12.0, 12.5, 14.0, 15.0, 17.0)


def normalize_rate(value: float | str) -> float:
    """Normalize decimal or Polish percentage notation to a percentage number."""
    if isinstance(value, str):
        value = value.strip().replace("%", "").replace(",", ".")
    number = float(value)
    return number * 100 if 0 < number < 1 else number
