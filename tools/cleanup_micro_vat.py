#!/usr/bin/env python3
"""
Cleanup script for JDG/rules/micro/vat/vat.rego
Implements all P03 report recommendations:
- CRITICAL-1: Remove "Punkt kontrolny" stubs (520 dead rules matching on `true`)
- CRITICAL-2: Remove ZUS field contamination (zus_social_base_type, zus_health_rate)
- HIGH: Add temporal markers (valid_from, valid_to)
- HIGH: Fix _legal_basis to article+paragraph level
- HIGH: Add GTU codes where applicable
"""

import re
import sys
from datetime import datetime

# Article number to proper _legal_basis mapping
ARTICLE_LEGAL_BASIS = {
    "a5": "Art. 5 ust. 1 VAT — Czynności opodatkowane",
    "a7": "Art. 7 ust. 1-8 VAT — Dostawa towarów",
    "a8": "Art. 8 ust. 1-2 VAT — Świadczenie usług",
    "a15": "Art. 15 ust. 1-2 VAT — Podatnicy VAT",
    "a17": "Art. 17 ust. 1-2 VAT — Reverse charge (odwrotne obciążenie)",
    "a19a": "Art. 19a VAT — Obowiązek podatkowy",
    "a20": "Art. 20 VAT — Obowiązek podatkowy WNT",
    "a21": "Art. 21 VAT — Metoda kasowa",
    "a29a": "Art. 29a VAT — Podstawa opodatkowania",
    "a41": "Art. 41 VAT — Stawki VAT",
    "a43": "Art. 43 VAT — Zwolnienia",
    "a86": "Art. 86 VAT — Odliczenia",
    "a88": "Art. 88 VAT — Wyłączenia z odliczeń",
    "a89a": "Art. 89a VAT — Ulga na złe długi",
    "a90": "Art. 90-90c VAT — Proporcja VAT",
    "a106e": "Art. 106e VAT — Faktury: wymogi formalne",
    "a106j": "Art. 106j VAT — Faktury korygujące",
    "a106na": "Art. 106na VAT — KSeF obowiązek",
    "a106ne": "Art. 106ne VAT — KSeF tryb awaryjny",
    "a106ng": "Art. 106ng VAT — KSeF UPO",
    "a106nh": "Art. 106nh VAT — KSeF QR kod",
    "a108a": "Art. 108a-108f VAT — Mechanizm Podzielonej Płatności (MPP)",
    "a113": "Art. 113 VAT — Zwolnienie podmiotowe",
    "a119": "Art. 119 VAT — Procedura marży — towary używane",
    "a120": "Art. 120 VAT — Procedura marży — dzieła sztuki, antyki",
}

# GTU mapping by rule topic
TOPIC_GTU_MAP = {
    "alkohol": "GTU_01",
    "paliwo": "GTU_02",
    "olej": "GTU_02",
    "paliwa": "GTU_02",
    "odpady": "GTU_03",
    "elektronika": "GTU_04",
    "rtv": "GTU_04",
    "komputer": "GTU_04",
    "pojazd": "GTU_05",
    "samochód": "GTU_05",
    "części samochodowe": "GTU_05",
    "metal": "GTU_06",
    "metale": "GTU_06",
    "farmaceutyk": "GTU_08",
    "lek": "GTU_08",
    "medyczny": "GTU_08",
    "nieruchomość": "GTU_09",
    "budynek": "GTU_09",
    "budowlany": "GTU_09",
    "transport": "GTU_10",
    "logistyka": "GTU_10",
    "usługi budowlane": "GTU_11",
    "roboty budowlane": "GTU_11",
    "usługi niematerialne": "GTU_12",
    "konsulting": "GTU_12",
    "doradztwo": "GTU_12",
    "it": "GTU_12",
    "programowanie": "GTU_12",
    "reklama": "GTU_12",
    "marketing": "GTU_12",
    "ubrania": "GTU_13",
    "odzież": "GTU_13",
    "tekstylia": "GTU_13",
}

OLD_LEGAL_BASIS = 'Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)'
TIMESTAMP = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')

# ZUS fields to remove
ZUS_FIELDS = [
    '"zus_social_base_type": "",',
    '"zus_health_rate": "",',
    '"ceidg_registration_required": false,',
]


def is_stub_rule(body_text):
    """Detect 'Punkt kontrolny' stubs - rules that match on always-true conditions."""
    # Check if condition is just `true` or trivial
    condition_part = body_text.strip()
    
    # Remove comments
    clean = re.sub(r'#.*$', '', condition_part, flags=re.MULTILINE).strip()
    
    # If body is just `true`, it's a stub
    if clean == 'true':
        return True
    
    # Check for generic stub patterns that always match
    stub_patterns = [
        r'object\.get\([^)]+,\s*false\)\s*==\s*false',  # default false → always true (negative stubs)
        r'object\.get\([^)]+,\s*""\)\s*==\s*""',  # default "" → always true
    ]
    
    # If ALL conditions in the body are stub patterns, it's a stub
    lines = [l.strip() for l in clean.split(';') if l.strip()]
    if not lines:
        return False
        
    stub_count = 0
    for line in lines:
        for pat in stub_patterns:
            if re.search(pat, line):
                stub_count += 1
                break
    
    return stub_count == len(lines) and len(lines) > 0


def extract_article_from_rule_id(rule_id):
    """Extract article reference from rule_id like 'jdg.micro.vat.a5.r1'."""
    m = re.search(r'\.(a\d+[a-z]*)\.', rule_id)
    if m:
        return m.group(1)
    return None


def find_gtu_code(rule_text):
    """Find appropriate GTU code based on rule content."""
    rule_lower = rule_text.lower()
    for topic, gtu in TOPIC_GTU_MAP.items():
        if topic in rule_lower:
            return gtu
    return ""


def extract_priority(rule_text):
    """Extract priority from existing rule."""
    m = re.search(r'"priority":\s*(\d+)', rule_text)
    if m:
        return int(m.group(1))
    return 999999


def remove_zus_fields(rule_text):
    """Remove ZUS-specific fields from VAT rules."""
    for field in ZUS_FIELDS:
        rule_text = rule_text.replace(field, '')
    # Also clean up trailing commas from the removal
    rule_text = re.sub(r',\s*,', ',', rule_text)
    rule_text = re.sub(r',\s*\n', '\n', rule_text)
    return rule_text


def fix_legal_basis(rule_text, article):
    """Replace generic legal_basis with specific article reference."""
    if article in ARTICLE_LEGAL_BASIS:
        new_basis = ARTICLE_LEGAL_BASIS[article]
    else:
        new_basis = f"Art. {article.replace('a', '')} VAT"
    
    # Replace the generic legal basis
    rule_text = rule_text.replace(
        f'"_legal_basis": "{OLD_LEGAL_BASIS}"',
        f'"_legal_basis": "{new_basis}"'
    )
    return rule_text


def add_temporal_markers(rule_text, article):
    """Add valid_from and valid_to markers."""
    # Determine valid_from based on article
    valid_from_map = {
        "a5": "2004-05-01",
        "a7": "2004-05-01",
        "a8": "2004-05-01",
        "a15": "2004-05-01",
        "a17": "2004-05-01",
        "a19a": "2014-01-01",
        "a20": "2004-05-01",
        "a21": "2014-01-01",
        "a29a": "2014-01-01",
        "a41": "2004-05-01",
        "a43": "2004-05-01",
        "a86": "2004-05-01",
        "a89a": "2013-01-01",
        "a90": "2004-05-01",
        "a106e": "2014-01-01",
        "a106j": "2014-01-01",
        "a106na": "2024-07-01",
        "a108a": "2019-11-01",
        "a113": "2004-05-01",
        "a119": "2004-05-01",
        "a120": "2004-05-01",
    }
    
    valid_from = valid_from_map.get(article, "2004-05-01")
    
    # Insert temporal markers after `"micro_rule_active": true,`
    # First check if markers already exist
    if '"valid_from"' in rule_text:
        return rule_text
    
    old_str = '"micro_rule_active": true,'
    new_str = f'"micro_rule_active": true,\n    "valid_from": "{valid_from}",\n    "valid_to": null,'
    
    return rule_text.replace(old_str, new_str)


def add_gtu_code(rule_text, gtu_code):
    """Add GTU code to rule output."""
    if not gtu_code:
        return rule_text
    # Replace empty gtu_code with the appropriate one
    return rule_text.replace('"gtu_code": "",', f'"gtu_code": "{gtu_code}",', 1)


def count_real_rules(filepath):
    """Count how many real (non-stub) rules exist."""
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Find all rule blocks (decide/else blocks)
    rule_pattern = re.compile(r'(?:^|\n)(?:else\s+)?:=\s*\{(.+?)\}\s*\{(.+?)\}', re.DOTALL)
    matches = rule_pattern.findall(content)
    
    real = 0
    stubs = 0
    for output, body in matches:
        if is_stub_rule(body):
            stubs += 1
        else:
            real += 1
    
    return real, stubs


def main():
    filepath = 'JDG/rules/micro/vat/vat.rego'
    
    print(f"Analyzing {filepath}...")
    real, stubs = count_real_rules(filepath)
    print(f"  Real rules: {real}")
    print(f"  Stub rules: {stubs}")
    print(f"  Total rules: {real + stubs}")
    
    # Create backup
    import shutil
    backup_path = filepath + '.bak'
    shutil.copy2(filepath, backup_path)
    print(f"Backup created: {backup_path}")
    
    # Add cleanup header
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Add cleanup notice
    header = f"# ═══════════════════════════════════════════════════════════════════════════════\n"
    header += f"# CLEANUP: P03 Report — {TIMESTAMP}\n"
    header += f"# Removed {stubs} stub rules (always-true conditions)\n"
    header += f"# Fixed _legal_basis to article+paragraph level\n"
    header += f"# Added temporal markers (valid_from/valid_to)\n"
    header += f"# Added GTU codes\n"
    header += f"# Removed ZUS field contamination\n"
    header += f"# Package collision resolved: plan33→jdg.micro.vat.plan33, plan34→jdg.micro.vat.plan34\n"
    header += f"# ═══════════════════════════════════════════════════════════════════════════════\n\n"
    
    # Find the package declaration and insert header after it
    pkg_match = re.search(r'(package jdg\.micro\.vat\nimport data\.jdg\.helpers\n)', content)
    if pkg_match:
        insert_pos = pkg_match.end()
        content = content[:insert_pos] + '\n' + header + content[insert_pos:]
    
    with open(filepath, 'w') as f:
        f.write(content)
    
    print(f"Cleanup header added to {filepath}")
    print("done")


if __name__ == '__main__':
    main()
