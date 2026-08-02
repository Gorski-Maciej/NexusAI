# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — VAT Rule ID Migrator (P29 N2)
# ═══════════════════════════════════════════════════════════════════════════════
# Migruje 102+ reguł z jdg.final.a* → jdg.vat.micro.* w JDG/rules/micro/vat/vat.rego
# ADR-008 compliance: naprawia niezgodność rule_id z konwencją nazewniczą.
# Uruchom: python JDG/tools/vat_ruleid_migrator.py [--dry-run] [--backup]
# ═══════════════════════════════════════════════════════════════════════════════

import re
import sys
import os
import shutil
from pathlib import Path
from datetime import datetime

# Mapa migracji: jdg.final.aXXX → jdg.vat.micro.artXXX
# Na podstawie struktury "Art. XXX → Punkt kontrolny" z komentarzy w vat.rego
RULE_ID_PATTERN = re.compile(r'jdg\.final\.a(\d+)\.u(\d+)\.p(\d+)')

def generate_new_rule_id(match: re.Match) -> str:
    """Konwertuj jdg.final.a100.u1.p1 → jdg.vat.micro.art100.rule1_1"""
    article = match.group(1)
    unit = match.group(2)
    point = match.group(3)
    return f"jdg.vat.micro.art{article}.rule{unit}_{point}"

def migrate_file(filepath: str, dry_run: bool = False) -> tuple[int, list[str]]:
    """Migruj wszystkie rule_id w pliku z jdg.final.a* na jdg.vat.micro.art*"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    matches = RULE_ID_PATTERN.findall(content)
    changes = []

    def replace_rule_id(match):
        old = match.group(0)
        new = generate_new_rule_id(match)
        changes.append(f"  {old} → {new}")
        return new

    if not dry_run:
        new_content = RULE_ID_PATTERN.sub(replace_rule_id, content)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
    else:
        for m in RULE_ID_PATTERN.finditer(content):
            changes.append(f"  {m.group(0)} → {generate_new_rule_id(m)}")

    return len(matches), changes

def create_backup(filepath: str):
    """Utwórz kopię zapasową pliku przed migracją"""
    backup_path = f"{filepath}.bak_migration_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    shutil.copy2(filepath, backup_path)
    print(f"Backup: {backup_path}")

if __name__ == '__main__':
    dry_run = '--dry-run' in sys.argv
    do_backup = '--backup' in sys.argv

    target_file = 'JDG/rules/micro/vat/vat.rego'

    if not os.path.exists(target_file):
        print(f"ERROR: {target_file} not found")
        sys.exit(1)

    print(f"{'[DRY-RUN] ' if dry_run else ''}Migrating rule_ids in {target_file}")
    print(f"Pattern: jdg.final.aXXX.uY.pZ → jdg.vat.micro.artXXX.ruleY_Z")
    print()

    if not dry_run and do_backup:
        create_backup(target_file)

    count, changes = migrate_file(target_file, dry_run)

    if dry_run:
        print(f"Would migrate {count} rule_ids:")
    else:
        print(f"Migrated {count} rule_ids:")

    for change in changes[:20]:
        print(change)

    if len(changes) > 20:
        print(f"  ... and {len(changes) - 20} more")

    print(f"\nTotal: {count} rule_ids {'would be' if dry_run else ''} migrated")
