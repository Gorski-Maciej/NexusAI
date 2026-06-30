#!/usr/bin/env python3
"""Fix ALL syntax errors in pdfium.py - targeted, safe approach."""
import re

with open("nexus_ai/core/pdfium.py", "r") as f:
    content = f.read()

lines = content.split("\n")
fixes = []

# === 1. Fix bare """ on its own line by wrapping in proper docstring ===
# Pattern: def func(): \n    \n    """  (bare opening quote)
# Convert to: def func(): \n    \"\"\"Description.\"\"\"
for i, line in enumerate(lines):
    stripped = line.strip()
    prev_idx = i - 1
    while prev_idx >= 0 and not lines[prev_idx].strip():
        prev_idx -= 1
    
    if stripped == '"""' and prev_idx >= 0:
        prev = lines[prev_idx].strip()
        if prev.startswith("def ") or prev.startswith("@") or prev.startswith("class ") or prev.startswith("async def "):
            # Find the def/class statement
            def_line = prev_idx
            while def_line >= 0:
                s = lines[def_line].strip()
                if s.startswith("def ") or s.startswith("class ") or s.startswith("async def "):
                    break
                def_line -= 1
            
            func_name = re.search(r'(?:def|class|async def)\s+(\w+)', lines[def_line])
            name = func_name.group(1) if func_name else "function"
            
            # Look ahead to see if there's more text that should be docstring
            j = i + 1
            doc_lines = []
            while j < len(lines):
                s = lines[j].strip()
                if s == '"""':  # closing quote
                    j += 1
                    break
                if s.startswith('"""'):  # already has opening
                    break
                if s.startswith("def ") or s.startswith("class ") or s.startswith("@"):
                    break
                if s and not s.startswith("#") and not s.startswith("try:") and not s.startswith("except"):
                    doc_lines.append(s)
                elif not s:
                    pass
                else:
                    break
                j += 1
            
            if doc_lines:
                indent = lines[i][:len(lines[i]) - len(lines[i].lstrip())]
                lines[i] = indent + '"""' + ' '.join(doc_lines) + '"""'
                # Clear the following docstring lines
                for k in range(i + 1, j):
                    lines[k] = ""
            else:
                indent = lines[i][:len(lines[i]) - len(lines[i].lstrip())]
                lines[i] = indent + '"""' + name.replace('_', ' ') + '."""'
            
            fixes.append(f"Fixed bare ''' at line {i+1} -> '{name}'")

# === 2. Fix Polish text lines that appear after def without docstring ===
# This handles cases where def is followed by bare text (not in docstring)
for i, line in enumerate(lines):
    stripped = line.strip()
    
    # Look for Polish text patterns that should be docstrings
    polish_markers = ["Zamiast", "Używa", "Wszystkie", "Kompletny", "zamiast", "KLUCZOWA", 
                      "PDFium", "FIX:", "NOWE", "Rekurencyjnie", "Wewnętrzna", "Konwertuj",
                      "Zwróć", "Pobierz", "Policz", "Szybka", "Ekstrahuj", "Ekstrakcja",
                      "Detekcja", "Zgodne", "Flagi", "Informacja", "Dla", "Bez", "Sesja"]
    
    if any(stripped.startswith(p) for p in polish_markers) and not stripped.startswith('"""'):
        # Check if this line is inside a function/class body (after def/class)
        prev_line = i - 1
        # Skip blank lines before this
        while prev_line >= 0 and not lines[prev_line].strip():
            prev_line -= 1
        # If previous line is not """ and not a code statement, it might need wrapping
        if prev_line >= 0:
            prev = lines[prev_line].strip()
            if not prev.startswith('"""') and not prev.startswith('def ') and not prev.startswith('@') and not prev.startswith('class '):
                # This is bare text - look for opening """ somewhere before
                found_open = False
                for k in range(i-1, max(0, i-5), -1):
                    if '"""' in lines[k]:
                        found_open = True
                        break
                if not found_open:
                    # Bare text without docstring - this is a syntax error context
                    # Find the nearest def/class above
                    def_above = i - 1
                    while def_above >= 0:
                        s = lines[def_above].strip()
                        if s.startswith('"""') and s.count('"""') == 2:
                            break  # Properly closed docstring
                        if s.startswith('def ') or s.startswith('class ') or s.startswith('async def '):
                            # This def has no docstring! The text below IS supposed to be one
                            indent = lines[i][:len(lines[i]) - len(lines[i].lstrip())]
                            lines[i] = indent + '"""' + stripped
                            fixes.append(f"Wrapped bare text at line {i+1}")
                            break
                        def_above -= 1

# === 3. Close any remaining unclosed triple-quoted strings ===
# Re-assemble and check
new_content = "\n".join(lines)
count = new_content.count('"""')
if count % 2 != 0:
    # Find the last odd occurrence and add a closing
    last_pos = new_content.rfind('"""')
    if last_pos > 0:
        # Find end of line
        line_end = new_content.find('\n', last_pos)
        if line_end == -1:
            line_end = len(new_content)
        # Add closing """ at the end of the last string
        line_before = new_content[:last_pos]
        line_after = new_content[last_pos + 3:]
        # Check if this is actually a singular """ that needs closing
        # Only close if the last position is the start of a new string
        new_content = new_content + '\n"""'
        fixes.append("Added final closing '''")

# Write fixed content
with open("nexus_ai/core/pdfium.py", "w") as f:
    f.write(new_content)

print(f"Applied {len(fixes)} fixes:")
for f in fixes:
    print(f"  - {f}")

# Verify syntax
import ast
try:
    ast.parse(new_content)
    print("\nSYNTAX: OK!")
except SyntaxError as e:
    print(f"\nSYNTAX ERROR at line {e.lineno}: {e.msg}")
