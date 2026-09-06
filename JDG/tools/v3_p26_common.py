#!/usr/bin/env python3
"""NexusAI JDG — V3-P26 shared evidence helper (kampania V3 FORTRESS).

Wspólne narzędzia dla 12 tooli dowodowych V3-P26-I01..I12: czytanie plików,
skan reguł w rules/v3_p26_zus_skladki_enterprise.rego, skan parametrów w
rules/thresholds_jdg.rego (blok zus = stawki rdzenia, zus26 = governance),
wspólna matematyka groszowa (mirror rego) i zapis bundle dowodowych do bundles/.
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
RULES = BASE / "rules"
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"

P26_RULES = RULES / "v3_p26_zus_skladki_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"

# Stopy/podstawy rdzenia (blok zus) — mirror wartości jako dane (ADR-002)
ZUS_CORE = {
    "pension_rate": 0.1952,
    "disability_rate": 0.08,
    "sickness_voluntary_rate": 0.0245,
    "accident_rate": 0.0167,
    "social_base_standard": 5204.40,
    "preferential_base_30pct": 1440.00,
    "health_scale_rate": 0.09,
    "health_linear_rate": 0.049,
    "health_lump_tier_1_limit": 60000,
    "health_lump_tier_2_limit": 300000,
    "health_lump_tier_1_amount": 491.40,
    "health_lump_tier_2_amount": 819.00,
    "health_lump_tier_3_amount": 1474.20,
    "start_relief_months": 6,
    "preferential_months": 24,
    "maly_zus_plus_months": 36,
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def rule_present(rule_id: str, hay: str | None = None) -> bool:
    hay = hay if hay is not None else read(P26_RULES)
    return rule_id in hay


def threshold_present(key: str, hay: str | None = None) -> bool:
    hay = hay if hay is not None else read(THRESHOLDS)
    return re.search(rf'"{re.escape(key)}"\s*:', hay) is not None


def core_rate_present(key: str, hay: str | None = None) -> bool:
    """Stopa/podstawa rdzenia w bloku zus (jedno źródło prawdy stawek)."""
    hay = hay if hay is not None else read(THRESHOLDS)
    return re.search(rf'"{re.escape(key)}"\s*:', hay) is not None


def thresholds_missing(keys: list[str], hay: str | None = None) -> list[str]:
    hay = hay if hay is not None else read(THRESHOLDS)
    return [k for k in keys if not threshold_present(k, hay)]


def main_jdg_wired(alias: str = "v3_p26_zus_skladki") -> bool:
    main = read(MAIN_JDG)
    return (f"import data.jdg.{alias} as {alias}" in main
            and f'"jdg.{alias}": {alias}.decide' in main
            and "final_verdict_p90" in main)


def grosze(x: float) -> float:
    """Zaokrąglenie do grosza (half-up) — mirror _grosze z rego."""
    from math import floor
    return floor((x * 100) + 0.5) / 100


def social_contributions(base: float) -> dict:
    """Mirror silnika I01: podstawa → 4 składki → total (grosze)."""
    return {
        "pension": grosze(base * ZUS_CORE["pension_rate"]),
        "disability": grosze(base * ZUS_CORE["disability_rate"]),
        "sickness": grosze(base * ZUS_CORE["sickness_voluntary_rate"]),
        "accident": grosze(base * ZUS_CORE["accident_rate"]),
    }


def emit(bundle: dict, name: str) -> int:
    (BUNDLES / f"{name}.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    gate = bundle.get("gate", "FAIL")
    print(f"[{bundle.get('innovation', name)}] gate={gate} "
          f"checks={len(bundle.get('checks', []))} findings={len(bundle.get('findings', []))}")
    return 1 if gate == "FAIL" else 0
