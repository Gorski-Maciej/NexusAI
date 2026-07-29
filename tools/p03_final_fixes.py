#!/usr/bin/env python3
"""
P03 Final Fixes for JDG/rules/micro/vat/vat.rego:
1. Remove ZUS fields (zus_social_base_type, zus_health_rate) — 1,091 each
2. Add GTU codes based on rule content — 1,091 empty gtu_code fields
"""

import re
import shutil

filepath = 'JDG/rules/micro/vat/vat.rego'

# GTU mapping by keywords in rule content
GTU_KEYWORDS = [
    (r'alkohol|tyto[ńn]|wyrob.*akcyzow', 'GTU_01'),
    (r'paliw|olej.*nap', 'GTU_02'),
    (r'odpad[óo]w|odpadami|mieci', 'GTU_03'),
    (r'elektronik|rtv|agd|komputer|laptop', 'GTU_04'),
    (r'pojazd|samoch[óo]d|motocykl|środek transportu', 'GTU_05'),
    (r'metal|stal|z[łl]om', 'GTU_06'),
    (r'farmaceuty|lek[ui]|medyczn|sprz[ęe]t.*med', 'GTU_08'),
    (r'nieruchomo|budyn|budowlan|grunt[ów]|lokal', 'GTU_09'),
    (r'transport|logistyk|spedycj|przew[óo]z', 'GTU_10'),
    (r'robot.*budowlan|us[łl]ug.*budowlan|remontow', 'GTU_11'),
    (r'niematerialn|konsulting|doradztw|programow|reklam|marketing|it[^a-z]|hosting|saas', 'GTU_12'),
    (r'odzie[żz]|ubran|tekstyli|obuwi', 'GTU_13'),
]

def find_gtu(rule_text):
    """Find the best GTU code for a rule based on its content."""
    text = rule_text.lower()
    for pattern, gtu in GTU_KEYWORDS:
        if re.search(pattern, text):
            return gtu
    return None

def process_file():
    with open(filepath, 'r') as f:
        content = f.read()
    
    original_lines = len(content.split('\n'))
    
    # 1. Remove ZUS fields
    zus_before_social = content.count('"zus_social_base_type": "",')
    zus_before_health = content.count('"zus_health_rate": "",')
    
    # Remove the ZUS field lines (they're always on their own line with trailing comma)
    content = content.replace('"zus_social_base_type": "",\n', '')
    content = content.replace('"zus_health_rate": "",\n', '')
    
    # Also handle cases where they might be followed by spaces
    content = re.sub(r'\s*"zus_social_base_type":\s*"",?\s*\n', '', content)
    content = re.sub(r'\s*"zus_health_rate":\s*"",?\s*\n', '', content)
    
    zus_after_social = content.count('"zus_social_base_type"')
    zus_after_health = content.count('"zus_health_rate"')
    
    # 2. Add GTU codes
    gtu_added = 0
    lines = content.split('\n')
    new_lines = []
    
    for line in lines:
        if '"gtu_code": "",' in line:
            # Try to find GTU based on line context
            # The gtu_code line appears in rule body, need broader context
            # Look for keywords in nearby warning/routing lines
            new_lines.append(line)  # Keep unchanged for now
            # We'll do a second pass using rule-level context
        else:
            new_lines.append(line)
    
    # Second pass: process in rule blocks to get full context
    content = '\n'.join(new_lines)
    rule_blocks = re.split(r'(?=\n(?:else\s+)?:=)', content)
    fixed_blocks = []
    
    for block in rule_blocks:
        if '"gtu_code": "",' in block:
            gtu = find_gtu(block)
            if gtu:
                block = block.replace('"gtu_code": "",', f'"gtu_code": "{gtu}",', 1)
                gtu_added += 1
        fixed_blocks.append(block)
    
    content = ''.join(fixed_blocks)
    
    # 3. Clean up double blank lines
    content = re.sub(r'\n{4,}', '\n\n\n', content)
    
    final_lines = len(content.split('\n'))
    
    # Save
    with open(filepath, 'w') as f:
        f.write(content)
    
    print(f"ZUS fields removed:")
    print(f"  zus_social_base_type: {zus_before_social} → {zus_after_social}")
    print(f"  zus_health_rate: {zus_before_health} → {zus_after_health}")
    print(f"GTU codes added: {gtu_added}")
    print(f"Lines: {original_lines} → {final_lines} ({original_lines - final_lines} removed)")
    print("done")


process_file()
