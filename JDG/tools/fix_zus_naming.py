#!/usr/bin/env python3
"""
NexusAI JDG — ZUS Naming Unification EXECUTOR
Maps descriptive rule_id categories to article-prefixed naming convention.
Target: jdg.zus.a*.r* / jdg.health.a*.r*
"""
import re
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
MICRO_DIR = PROJECT_ROOT / "JDG" / "rules" / "micro"

# ── plan33_zus.rego category → article mapping ──
ZUS_CATEGORY_MAP = {
    "jdg.zus.base.": "jdg.zus.a1.",
    "jdg.zus.benefit.": "jdg.zus.a2.",
    "jdg.zus.deadline.": "jdg.zus.a3.",
    "jdg.zus.rate.": "jdg.zus.a4.",
    "jdg.zus.small_plus.": "jdg.zus.a5.",
    "jdg.zus.start.": "jdg.zus.a17.",
    "jdg.zus.suspension.": "jdg.zus.a18.",
}

# ── plan33_health.rego category → article mapping ──
# IMPORTANT: order matters! More specific prefixes must come first
# to avoid greedy prefix matching (e.g. 'rate.r' before 'r')
HEALTH_CATEGORY_MAP = {
    "jdg.health.rate.r": "jdg.health.a81c.r",
    "jdg.health.annual.r": "jdg.health.a81b.r",
    "jdg.health.r": "jdg.health.a81.r",
}

def fix_file(filepath, mapping):
    """Replace rule_id prefixes in a file."""
    content = filepath.read_text(encoding="utf-8")
    original = content
    changes = 0
    
    for old_prefix, new_prefix in mapping.items():
        # Only replace in rule_id strings
        pattern = f'"rule_id":"{old_prefix}'
        replacement = f'"rule_id":"{new_prefix}'
        count = content.count(pattern)
        if count > 0:
            content = content.replace(pattern, replacement)
            changes += count
            print(f"  {old_prefix} → {new_prefix}: {count} replacements")
    
    if content != original:
        filepath.write_text(content, encoding="utf-8")
        print(f"  ✅ {filepath.name}: {changes} total changes written")
    else:
        print(f"  ⏭️  {filepath.name}: no changes needed")
    return changes

def main():
    total = 0
    
    print("═" * 60)
    print("  ZUS Naming Unification Executor")
    print("═" * 60)
    
    # Fix plan33_zus.rego
    zus_file = MICRO_DIR / "plan33_zus.rego"
    if zus_file.exists():
        print(f"\n📄 {zus_file.name}")
        total += fix_file(zus_file, ZUS_CATEGORY_MAP)
    
    # Fix plan33_health.rego
    health_file = MICRO_DIR / "plan33_health.rego"
    if health_file.exists():
        print(f"\n📄 {health_file.name}")
        total += fix_file(health_file, HEALTH_CATEGORY_MAP)
    
    print(f"\n{'═' * 60}")
    print(f"  TOTAL: {total} rule_id replacements across all files")
    print(f"{'═' * 60}")

if __name__ == "__main__":
    main()
