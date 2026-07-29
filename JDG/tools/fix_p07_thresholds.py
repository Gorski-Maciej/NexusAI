#!/usr/bin/env python3
"""P07 Batch Fix: Update hardcoded ZUS defaults in health_contribution_enterprise.rego.

Fixes:
- min_wage: 4666 → 4800 PLN (2026 value)
- Ryczalt tier defaults: 419.46/699.11/1258.39 → 491.40/819.00/1474.20
- Warning message: 12900 → 14100 PLN (deduction limit)
- Warning message: 419.46/699.11/1258.39 → 491.40/819.00/1474.20

Run: python JDG/tools/fix_p07_thresholds.py
"""

import re

def fix_health_contribution(filepath: str) -> dict:
    """Update hardcoded defaults and warning messages."""
    with open(filepath, "r") as f:
        content = f.read()

    fixes = {
        "min_wage_default": 0,
        "ryczalt_tiers": 0,
        "warning_deduction_limit": 0,
        "warning_tiers": 0,
    }

    # Fix 1: min_wage hardcoded default 4666 → 4800
    count = content.count("minimum_wage_gross\", 4666)")
    content = content.replace("minimum_wage_gross\", 4666)", "minimum_wage_gross\", 4800)")
    fixes["min_wage_default"] = count

    # Fix 2: ryczalt tier defaults in object.get
    count2 = content.count("health_lump_tier_1_amount\", 419.46)")
    content = content.replace("health_lump_tier_1_amount\", 419.46)", "health_lump_tier_1_amount\", 491.40)")
    fixes["ryczalt_tiers"] += count2
    count3 = content.count("health_lump_tier_2_amount\", 699.11)")
    content = content.replace("health_lump_tier_2_amount\", 699.11)", "health_lump_tier_2_amount\", 819.00)")
    fixes["ryczalt_tiers"] += count3
    count4 = content.count("health_lump_tier_3_amount\", 1258.39)")
    content = content.replace("health_lump_tier_3_amount\", 1258.39)", "health_lump_tier_3_amount\", 1474.20)")
    fixes["ryczalt_tiers"] += count4

    # Fix 3: Warning message — deduction limit 12900 → 14100
    content = content.replace("Limit: 12 900 PLN.", "Limit: 14 100 PLN.")
    content = content.replace("Limit: 12 900 PLN", "Limit: 14 100 PLN")
    content = content.replace("12 900 PLN/rok", "14 100 PLN/rok")

    # Fix 4: Warning message — ryczalt tiers 419.46/699.11/1 258.39 → 491.40/819.00/1474.20
    content = content.replace("419.46 PLN/mies", "491.40 PLN/mies")
    content = content.replace("699.11 PLN/mies", "819.00 PLN/mies")
    content = content.replace("1 258.39 PLN/mies", "1 474.20 PLN/mies")

    with open(filepath, "w") as f:
        f.write(content)

    return fixes


if __name__ == "__main__":
    path = "JDG/rules/zus/health_contribution_enterprise.rego"
    print(f"Fixing hardcoded thresholds in {path}...")
    fixes = fix_health_contribution(path)
    print(f"✅ min_wage defaults updated: {fixes['min_wage_default']}")
    print(f"✅ Ryczalt tier defaults updated: {fixes['ryczalt_tiers']}")
    print(f"✅ Warning messages updated (12900→14100, tiers→2026)")
    print("\nDone! Verify with: grep '4666\\|419\\.46\\|699\\.11\\|1258\\.39' JDG/rules/zus/health_contribution_enterprise.rego")
