#!/usr/bin/env python3
"""
Remove "Punkt kontrolny" stubs from JDG/rules/micro/vat/vat.rego.
Stubs are rules with always-true conditions (object.get default == false, etc.)
Keeps only real rules with meaningful conditions.
"""

import re
import shutil
from datetime import datetime, timezone

filepath = 'JDG/rules/micro/vat/vat.rego'
backup = filepath + '.bak_stubs_removed'

def is_meaningful_condition(body):
    """Check if a rule body has meaningful conditions beyond stubs."""
    clean = re.sub(r'#.*$', '', body, flags=re.MULTILINE).strip()
    lines = [l.strip() for l in clean.split(';') if l.strip()]
    
    if not lines:
        return False
    
    # If body is just `true`, it's a stub
    if clean == 'true':
        return False
    
    # Count meaningful vs stub conditions
    meaningful = 0
    stub = 0
    
    for line in lines:
        # Meaningful conditions (not default-false checks)
        if re.search(r'==\s*"(?!")[^"]+"', line):  # string equality with non-empty string
            meaningful += 1
        elif re.search(r'>\s*\d+', line):  # numeric comparison
            meaningful += 1
        elif re.search(r'<\s*\d+', line):
            meaningful += 1
        elif re.search(r'!=', line):
            meaningful += 1
        elif re.search(r'not\s', line):
            meaningful += 1
        elif re.search(r'\.business_type\s*==', line):  # semi-real eligibility check
            meaningful += 1
        elif re.search(r'object\.get\([^,]+,\s*false\)\s*==\s*false', line):  # always true
            stub += 1
        elif re.search(r'object\.get\([^,]+,\s*""\)\s*==\s*""', line):  # always true
            stub += 1
        elif re.search(r'object\.get\([^,]+,\s*false\)\s*==\s*true', line):  # always false
            stub += 1
        elif re.search(r'object\.get\([^,]+,\s*true\)\s*==\s*false', line):  # always false
            stub += 1
        else:
            meaningful += 1  # unknown pattern, keep it
    
    return meaningful > 0


def extract_rules(content):
    """Extract all rule blocks with their bodies."""
    # Pattern: matches `decide := { ... } { ... }` and `else := { ... } { ... }`
    pattern = re.compile(
        r'((?:^|\n)(?:# [^\n]*\n)*?(?:else\s+)?:=\s*\{[^}]*(?:\{[^}]*\}[^}]*)*\})\s*\{([^}]*(?:\{[^}]*\}[^}]*)*)\}',
        re.DOTALL
    )
    
    rules = []
    for m in pattern.finditer(content):
        full_match = m.group(0)
        body = m.group(2)
        rules.append((full_match, body, m.start(), m.end()))
    
    return rules


def process_file():
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Backup
    shutil.copy2(filepath, backup)
    print(f"Backup: {backup}")
    
    # Find all rules
    rules = extract_rules(content)
    print(f"Total rules found: {len(rules)}")
    
    # Identify stubs
    stubs = []
    real = []
    for full_match, body, start, end in rules:
        if is_meaningful_condition(body):
            real.append((full_match, body, start, end))
        else:
            stubs.append((full_match, body, start, end))
    
    print(f"Real rules: {len(real)}")
    print(f"Stubs to remove: {len(stubs)}")
    
    if len(stubs) == 0:
        print("No stubs found. Nothing to do.")
        return
    
    # Remove stubs from content (working backwards to preserve positions)
    new_content = content
    for _, _, start, end in reversed(stubs):
        new_content = new_content[:start] + new_content[end:]
    
    # Clean up multiple blank lines
    new_content = re.sub(r'\n{4,}', '\n\n\n', new_content)
    
    # Add transformation header
    tm = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    header = (
        f"# ════════════════════════════════════════════════════════════════════════════════\n"
        f"# P03 STUB REMOVAL: {tm}\n"
        f"#   Removed {len(stubs)} stub rules (always-true conditions)\n"
        f"#   Kept {len(real)} real rules\n"
        f"#   Backup: {backup}\n"
        f"# ════════════════════════════════════════════════════════════════════════════════\n"
    )
    
    pkg_pos = new_content.find('import data.jdg.helpers\n')
    if pkg_pos >= 0:
        insert_at = pkg_pos + len('import data.jdg.helpers\n')
        new_content = new_content[:insert_at] + '\n' + header + new_content[insert_at:]
    
    with open(filepath, 'w') as f:
        f.write(new_content)
    
    # Count final lines
    final_lines = len(new_content.split('\n'))
    orig_lines = len(content.split('\n'))
    print(f"Original: {orig_lines} lines → Final: {final_lines} lines ({orig_lines - final_lines} removed)")
    print("done")


if __name__ == '__main__':
    process_file()
