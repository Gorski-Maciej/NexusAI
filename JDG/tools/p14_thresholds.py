"""Shared P14 threshold registry reader.

The Rego threshold registry is authoritative; Python calculators consume the
same values and expose the source hash for auditability.
"""
from __future__ import annotations

import hashlib
import re
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
THRESHOLDS_PATH = ROOT / "rules" / "thresholds_jdg.rego"


@dataclass(frozen=True)
class P14Thresholds:
    pcc_sale_rate: float
    pcc_loan_rate: float
    pcc_company_rate: float
    pcc_mortgage_rate: float
    pcc_exemption_limit: float
    pcc_family_loan_limit: float
    pcc3_deadline_days: int
    land_business_rate: float
    building_business_rate: float
    dn1_deadline_days: int
    transport_threshold_t: float
    excise_gasoline: float
    excise_diesel: float
    excise_lpg: float
    excise_ethanol_per_hl: float
    excise_beer_per_plato: float
    excise_wine_per_hl: float
    source: str
    source_sha256: str


def _value(text: str, key: str, default: float) -> float:
    match = re.search(rf'"{re.escape(key)}"\s*:\s*([-+]?\d+(?:\.\d+)?)', text)
    return float(match.group(1)) if match else default


def load_thresholds(path: Path = THRESHOLDS_PATH) -> P14Thresholds:
    text = path.read_text(encoding="utf-8")
    return P14Thresholds(
        pcc_sale_rate=_value(text, "pcc_sale_rate", 0.02),
        pcc_loan_rate=_value(text, "pcc_loan_rate", 0.005),
        pcc_company_rate=_value(text, "pcc_company_rate", 0.005),
        pcc_mortgage_rate=_value(text, "pcc_mortgage_rate", 0.001),
        pcc_exemption_limit=_value(text, "pcc_exemption_limit", 1000),
        pcc_family_loan_limit=_value(text, "pcc_family_loan_limit", 36120),
        pcc3_deadline_days=int(_value(text, "pcc3_deadline_days", 14)),
        land_business_rate=_value(text, "land_business_rate", 1.43),
        building_business_rate=_value(text, "building_business_rate", 33.10),
        dn1_deadline_days=int(_value(text, "transport_dn1_deadline_days", 14)),
        transport_threshold_t=_value(text, "transport_threshold_t", 3.5),
        excise_gasoline=_value(text, "excise_gasoline", 1566),
        excise_diesel=_value(text, "excise_diesel", 1206),
        excise_lpg=_value(text, "excise_lpg", 695),
        excise_ethanol_per_hl=_value(text, "excise_ethanol_per_hl", 6900),
        excise_beer_per_plato=_value(text, "excise_beer_per_plato", 8.57),
        excise_wine_per_hl=_value(text, "excise_wine_per_hl", 185),
        source=str(path.relative_to(ROOT)),
        source_sha256=hashlib.sha256(text.encode("utf-8")).hexdigest(),
    )
