#!/usr/bin/env python3
"""Find unterminated triple-quoted string in pdfium.py"""
with open('nexus_ai/core/pdfium.py', 'r') as f:
    lines = f.read().split('\n')

in_string = False
string_start_line = 0
total = 0

TRIPLE = '"""'

for i, line in enumerate(lines):
    idx = 0
    while True:
        pos = line.find(TRIPLE, idx)
        if pos == -1:
            break
        total += 1
        if in_string:
            in_string = False
        else:
            in_string = True
            string_start_line = i + 1
        idx = pos + 3

print(f'Total triple-quote count: {total}')
print(f'Is odd count: {total % 2 == 1}')

if in_string:
    print(f'UNTERMINATED STRING STARTED AT LINE {string_start_line}')
    print('Context around start:')
    for j in range(max(0, string_start_line-2), min(len(lines), string_start_line+8)):
        marker = ' >>>' if j+1 == string_start_line else '    '
        print(f'{marker} {j+1}: {lines[j]}')
else:
    print('All triple-quoted strings are properly closed!')
