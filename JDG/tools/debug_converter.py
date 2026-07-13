#!/usr/bin/env python3
"""Debug why convert_true_to_conditions is not modifying hyper/general/plan45.rego"""
import re

filepath = "JDG/rules/jdg/hyper/general/plan45.rego"

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

package_match = re.search(r'^package\s+(\S+)', content, re.MULTILINE)
package = package_match.group(1) if package_match else ""

lines = content.split('\n')
print(f"Total lines: {len(lines)}, package: {package}")

matched_count = 0
true_count = 0
converted = 0

i = 0
while i < len(lines):
    line = lines[i]
    m = re.match(r'^(decide|else)\s*:=\s*(\{.*?\})\s*\{\s*$', line)
    
    if m:
        matched_count += 1
        # Check next 2 lines
        if i + 2 < len(lines):
            l1 = lines[i+1].strip()
            l2 = lines[i+2].strip()
            if l1 == 'true':
                true_count += 1
                if l2 == '}':
                    converted += 1
                    if matched_count <= 3:
                        print(f"Line {i}: WOULD CONVERT rule (next: '{l1}', then: '{l2}')")
                else:
                    if matched_count <= 3:
                        print(f"Line {i}: HAS true but wrong close: l1='{l1}', l2='{l2}'")
            else:
                if matched_count <= 3:
                    print(f"Line {i}: NO true stub: l1='{l1}', l2='{l2}'")
        else:
            if matched_count <= 3:
                print(f"Line {i}: NOT ENOUGH LINES after (EOF)")
        i += 3  # skip past the body
    else:
        i += 1

print(f"\nRegex matches: {matched_count}")
print(f"True stubs found: {true_count}")
print(f"Would convert: {converted}")
print(f"Unconverted (true but no closing brace): {true_count - converted}")
