#!/usr/bin/env python3
"""Fix duplicate rule_ids in plan34 micro-rule files by regenerating with dedup."""
import re, os
from collections import defaultdict, OrderedDict
from datetime import datetime

# Read Plan OPA 34
with open('Plan OPA/34_JDG_DEFINITIVE_REGO_PLAN.md', 'r') as f:
    content = f.read()

# Extract all micro-rule table rows
table_rows = re.findall(
    r'\|\s*`(jdg\.([a-z_]+)\.[a-z]\d+[a-z_]*\.r\d+)`\s*\|\s*([^|]+)\|\s*([^|]+)\|\s*([^|]*)\|',
    content
)

print(f"Table rows: {len(table_rows)}")

# Deduplicate by rule_id (keep first occurrence)
by_domain = defaultdict(OrderedDict)
for row in table_rows:
    rid, domain, name, condition, result = row
    rid = rid.strip()
    name = name.strip()
    condition = condition.strip()
    result = result.strip()
    
    if rid in by_domain[domain]:
        continue  # Skip duplicate
    
    parts = rid.rsplit('.r', 1)
    rule_num = int(parts[1]) if parts[1].isdigit() else 1
    
    art_match = re.search(r'\.a(\d+[a-z]*)', rid)
    art_num = 0
    if art_match:
        try:
            art_str = art_match.group(1)
            art_num = int(re.sub(r'[a-z]', '', art_str)) * 100
        except:
            art_num = 99000
    
    priority = art_num + rule_num
    
    by_domain[domain][rid] = {
        'rid': rid, 'name': name, 'condition': condition,
        'result': result, 'priority': priority
    }

unique_total = sum(len(v) for v in by_domain.values())
print(f"Unique rules after dedup: {unique_total}")

# Delete old files and regenerate
import glob
for old in glob.glob('JDG/rules/micro/plan34_*.rego'):
    os.remove(old)
    print(f"  Deleted: {old}")

total_generated = 0
for domain, rules_dict in sorted(by_domain.items()):
    rules = sorted(rules_dict.values(), key=lambda x: x['priority'])
    
    package = f"jdg.micro.{domain}"
    filepath = f"JDG/rules/micro/plan34_{domain}.rego"
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    
    lines = []
    lines.append(f'# Generated from Plan OPA 34 — Micro-rules for jdg.{domain}')
    lines.append(f'# {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}')
    lines.append(f'# Rules: {len(rules)} (deduplicated)')
    lines.append(f'')
    lines.append(f'package {package}')
    lines.append(f'')
    lines.append(f'default decide := {{"matched":false,"rule_id":"{package}.no_match","package":"{package}","priority":99999}}')
    lines.append('')
    
    for i, rule in enumerate(rules):
        kw = "decide" if i == 0 else "else"
        rid = rule['rid']
        name = rule['name']
        cond = rule['condition'][:150]
        result = rule['result'][:150]
        priority = rule['priority']
        
        verdict = f'  {{"matched":true,"rule_id":"{rid}","package":"{package}","priority":{priority},'
        verdict += f'"vat_rate":"","rounding_level":"","gtu_code":"",'
        verdict += f'"pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",'
        verdict += f'"kus_qualification":"","kus_percent":0,'
        verdict += f'"zus_social_base_type":"","zus_health_rate":"",'
        verdict += f'"business_status":"",'
        verdict += f'"_routing":"","_routing_reason":"{cond}","_legal_basis":"","_warnings":[]'
        verdict += '}'
        
        lines.append(f'# {rid} — {name}: {cond} → {result}')
        lines.append(f'{kw} := {verdict} {{')
        lines.append(f'    true')
        lines.append(f'}}')
        lines.append('')
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    
    print(f"  ✅ {filepath}: {len(rules)} rules")
    total_generated += len(rules)

print(f"\n=== SUMMARY ===")
print(f"Total micro-rules generated: {total_generated}")
print(f"Files created: {len(by_domain)}")
