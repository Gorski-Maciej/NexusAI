#!/usr/bin/env python3
"""Fix the last syntax error - brute force approach."""
with open('nexus_ai/core/pdfium.py', 'r') as f:
    content = f.read()

lines = content.split('\n')

# Find unterminated string by counting quotes
in_str = False
start_line = 0
for i, line in enumerate(lines):
    j = 0
    while True:
        idx = line.find('"""', j)
        if idx < 0:
            break
        in_str = not in_str
        if in_str:
            start_line = i + 1
        j = idx + 3

print(f'Unterminated string starts at line: {start_line}')
print(f'Total lines: {len(lines)}')

if in_str and start_line > 0:
    # Read context around the problem
    print(f'\nContext around line {start_line}:')
    for n in range(max(0, start_line-3), min(len(lines), start_line+6)):
        marker = ' >>>' if n+1 == start_line else '    '
        print(f'{marker} {n+1}: {lines[n]}')
    
    # The first """ at the start_line is actually closing a previous unterminated string
    # The real problem is BEFORE start_line
    # Let me find the REAL start by looking before start_line
    real_in_str = False
    real_start = 0
    for i in range(start_line - 1):  # Only check lines BEFORE start_line
        line = lines[i]
        j = 0
        while True:
            idx = line.find('"""', j)
            if idx < 0:
                break
            real_in_str = not real_in_str
            if real_in_str:
                real_start = i + 1
            j = idx + 3
    
    if real_in_str:
        print(f'\nREAL unterminated string started at line: {real_start}')
        print(f'Context around real start:')
        for n in range(max(0, real_start-3), min(len(lines), real_start+8)):
            marker = ' >>>' if n+1 == real_start else '    '
            print(f'{marker} {n+1}: {lines[n]}')
    else:
        print(f'\nAll strings before line {start_line} are balanced.')
        print(f'The """ at line {start_line} opens a string that is never closed.')
        print('This is the NOT the real problem - it means an unterminated string ended here,')
        print('and the closing """ of this docstring opens a new unterminated string.')
        print(f'The REAL problem is BEFORE line {start_line}.')
