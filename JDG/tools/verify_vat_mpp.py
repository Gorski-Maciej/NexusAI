#!/usr/bin/env python3
"""
NexusAI JDG — VAT MPP/SPLIT PAYMENT VERIFIER (P02 RAPORT_02)
=============================================================
Weryfikacja kompletności reguł MPP (Mechanizm Podzielonej Płatności)
zgodnie z art. 108a–108f VAT. Bramka CI: FAIL przy brakujących regułach.

Sprawdza:
  1. Próg MPP (15 000 zł) z externalizacji thresholds.misc
  2. Załącznik 15 CN codes + usługi budowlane
  3. Sankcje 30% (art. 108a ust. 5-7)
  4. Solidarna odpowiedzialność (art. 108b ust. 1)
  5. BLOCK_AND_ALERT przy braku MPP

Usage:
  python verify_vat_mpp.py [--gate] [--json]
"""

import argparse
import json
import re
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"

REQUIRED_PATTERNS = {
    "mpp_threshold": [r"mpp_threshold", r"15.?000", r"15000"],
    "annex15_cn": [r"annex15", r"załącznik.?15", r"cn.?code", r"CN"],
    "sanction_30pct": [r"sanc(?:je|ja|ja_30)", r"30%", r"108a.*ust.*5"],
    "solidary_liability": [r"solidarn[aą]", r"108b", r"solidary_liability"],
    "block_and_alert": [r"BLOCK_AND_ALERT"],
    "auto_mark_trigger": [r"auto_mark_trigger", r"ANNEX15"],
}


def scan_mpp_rules() -> dict:
    results = {}
    for pattern_name, patterns in REQUIRED_PATTERNS.items():
        found = False
        for path in RULES_DIR.rglob("*.rego"):
            if ".bak" in path.name or "backup" in path.name.lower():
                continue
            content = path.read_text(encoding="utf-8", errors="ignore")
            if any(re.search(p, content, re.IGNORECASE) for p in patterns):
                found = True
                break
        results[pattern_name] = found
    return results


def main() -> None:
    p = argparse.ArgumentParser(description="VAT MPP Verifier — P02 RAPORT_02")
    p.add_argument("--gate", action="store_true")
    p.add_argument("--json", action="store_true")
    args = p.parse_args()

    results = scan_mpp_rules()
    missing = [k for k, v in results.items() if not v]

    if args.json:
        print(json.dumps({"mpp_checks": results, "missing": missing}, indent=2))
        return

    print("🔍 VAT MPP VERIFICATION:")
    for k, v in results.items():
        status = "✅" if v else "❌"
        print(f"  {status} {k}")

    if missing:
        print(f"\n❌ MISSING: {', '.join(missing)}")
        if args.gate:
            sys.exit(1)
    else:
        print("\n✅ ALL MPP CHECKS PASSED")
        if args.gate:
            sys.exit(0)


if __name__ == "__main__":
    main()
