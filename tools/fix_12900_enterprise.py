#!/usr/bin/env python3
"""
Fix hardcoded 12900 → thresholds.limits.health_linear_deduction_limit in 11 enterprise files.
Replaces integer literal 12900 with the thresholds reference where appropriate.
"""

import re
import os
import shutil

FILES = [
    "JDG/rules/annual_declaration_enterprise.rego",
    "JDG/rules/banking_automation_enterprise.rego",
    "JDG/rules/cashflow_tax_predictor_enterprise.rego",
    "JDG/rules/cross_domain_intelligence_enterprise.rego",
    "JDG/rules/edge_cases.rego",
    "JDG/rules/form_optimizer_enterprise.rego",
    "JDG/rules/form_transition_simulator_enterprise.rego",
    "JDG/rules/neural_rule_mesh_enterprise.rego",
    "JDG/rules/strategic_advisor_enterprise.rego",
    "JDG/rules/tax_optimization_enterprise.rego",
    "JDG/rules/zus.rego",
]

THRESHOLDS_REF = "thresholds.limits.health_linear_deduction_limit"

# Patterns to replace 12900 with thresholds reference
# We want to replace 12900 when it's used as the health_linear_deduction_limit
REPLACEMENTS = [
    # min([expr, 12900]) → min([expr, thresholds.limits.health_linear_deduction_limit])
    (r'min\(\[([^]]+),\s*12900\s*\]\)', r'min([\1, ' + THRESHOLDS_REF + r'])'),
    # min([expr, 12900 / 12]) → min([expr, thresholds.limits.health_linear_deduction_limit / 12])
    (r'min\(\[([^]]+),\s*12900\s*/\s*12\s*\]\)', r'min([\1, ' + THRESHOLDS_REF + r' / 12])'),
    # 12900 as a standalone value in health context
    (r'"(?:zus_health_annual_deduction_limit|zus_health_annual_limit|relief_limit|relief_deductible|limit_value)"\s*[:=]\s*12900\b', 
     lambda m: m.group(0).replace('12900', THRESHOLDS_REF)),
]

def fix_file(filepath):
    if not os.path.exists(filepath):
        print(f"  SKIP: {filepath} not found")
        return 0
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    original = content
    count = 0
    
    for pattern, replacement in REPLACEMENTS:
        new_content, n = re.subn(pattern, replacement, content)
        if n > 0:
            count += n
            content = new_content
    
    if count > 0:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"  FIXED: {filepath} ({count} replacements)")
    else:
        print(f"  OK: {filepath} (no changes needed)")
    
    return count


total = 0
for f in FILES:
    total += fix_file(f)

print(f"\nTotal replacements: {total}")
