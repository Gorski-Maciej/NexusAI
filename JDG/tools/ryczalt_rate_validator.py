#!/usr/bin/env python3
"""P13 rate consistency gate: thresholds_jdg.rego versus Rego rule sources."""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

try:
    from .p13_thresholds import LEGAL_RATES, THRESHOLDS_PATH, load_thresholds
except ImportError:  # direct ``python JDG/tools/...py`` invocation
    from p13_thresholds import LEGAL_RATES, THRESHOLDS_PATH, load_thresholds

ROOT = Path(__file__).resolve().parents[1]
RATE_KEYS = {
    3.0: "ryczalt_rate_3_pct",
    5.5: "ryczalt_rate_55_pct",
    8.5: "ryczalt_rate_85_pct",
    10.0: "ryczalt_rate_10_pct",
    12.0: "ryczalt_rate_12_pct",
    12.5: "ryczalt_rate_125_pct",
    14.0: "ryczalt_rate_14_pct",
    15.0: "ryczalt_rate_15_pct",
    17.0: "ryczalt_rate_17_pct",
}
RULE_FILES = (
    ROOT / "rules" / "micro" / "ryczalt" / "ryczalt.rego",
    ROOT / "rules" / "micro" / "plan33_ryc.rego",
    ROOT / "rules" / "p13_ryczalt_cykl_zycia_innovations_v9.rego",
    ROOT / "rules" / "r12_ryczalt_cykl_zycia_innovations_v9.rego",
)


def _threshold_values(path: Path) -> dict[str, float]:
    text = path.read_text(encoding="utf-8")
    return {
        key: float(value)
        for key, value in re.findall(
            r'"(ryczalt_rate_[0-9]+(?:5)?_pct)"\s*:\s*(0?\.\d+)', text
        )
    }


def _rego_rates(paths: tuple[Path, ...] = RULE_FILES) -> set[float]:
    rates: set[float] = set()
    for path in paths:
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        for raw in re.findall(r'(?<![\d.])(\d+(?:[.,]5)?)\s*%', text):
            rates.add(float(raw.replace(",", ".")))
        for raw in re.findall(r'"(?:rate|ryczalt_rate)"\s*:\s*"(\d+(?:[.,]5)?)%"', text):
            rates.add(float(raw.replace(",", ".")))
    return rates


def validate_rates(thresholds_path: Path = THRESHOLDS_PATH) -> dict:
    """Return a machine-readable PASS/FAIL report for the P13 rate registry."""
    threshold_values = _threshold_values(thresholds_path)
    source = load_thresholds(thresholds_path)
    found_in_rego = _rego_rates()
    checks = {}
    for rate in LEGAL_RATES:
        key = RATE_KEYS[rate]
        configured = threshold_values.get(key)
        checks[f"{rate:g}%"] = {
            "threshold_key": key,
            "threshold_value": configured,
            "threshold_matches": configured is not None and abs(configured - rate / 100) < 1e-12,
            "rego_present": rate in found_in_rego,
        }
    errors = [
        f"{label}: " + ", ".join(k for k, ok in value.items() if k.endswith("matches") or k == "rego_present" and not ok)
        for label, value in checks.items()
        if not value["threshold_matches"] or not value["rego_present"]
    ]
    return {
        "status": "PASS" if not errors else "FAIL",
        "rates_checked": len(checks),
        "checks": checks,
        "errors": errors,
        "threshold_source": source.source,
        "threshold_source_sha256": source.source_sha256,
        "rego_rates_found": sorted(found_in_rego),
        "legal_basis": "art. 12 ust. 1 ustawy o zryczałtowanym podatku dochodowym",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    result = validate_rates()
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(f"RYCZAŁT RATE GATE: {result['status']} ({result['rates_checked']} stawek)")
        for error in result["errors"]:
            print(f"  FAIL: {error}")
    return 0 if result["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
