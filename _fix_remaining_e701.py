"""Fix remaining E701 (colon) and E702 (semicolon) errors in specific files."""
import re
import subprocess

files = [
    "nexus_ai/core/nats_utils.py",
    "nexus_ai/pipeline/ocr_consensus.py",
    "nexus_ai/events/jetstream_bus.py",
    "nexus_ai/services/facts_aggregator.py",
]

for filepath in files:
    with open(filepath, "r") as f:
        content = f.read()

    lines = content.split("\n")
    fixed_lines = []
    changes = 0

    for i, line in enumerate(lines):
        # Skip non-code lines
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            fixed_lines.append(line)
            continue
            
        # Fix E702: semicolons separating statements (but not in strings/comments)
        # Pattern: statement; statement
        # Be careful not to break semicolons inside string literals
        
        # Check if line has multiple statements separated by ;
        # We need to handle cases like:
        #   x = 1; y = 2
        #   try: something; return True
        #   if x: return True
        
        # Simple E702 fixes: semicolons that clearly separate assignments
        if ";" in line and not line.strip().startswith("#"):
            # Check if it's a simple semicolon separation (not in strings)
            # We'll split on ; and check each part
            
            # Count quotes to handle semicolons inside strings
            in_double = False
            in_single = False
            semicolon_positions = []
            
            for j, ch in enumerate(line):
                if ch == '"' and not in_single:
                    in_double = not in_double
                elif ch == "'" and not in_double:
                    in_single = not in_single
                elif ch == ";" and not in_double and not in_single:
                    semicolon_positions.append(j)
            
            if semicolon_positions:
                # Split line at semicolons, creating continuation lines
                parts = []
                last_pos = 0
                for pos in semicolon_positions:
                    parts.append(line[last_pos:pos].strip())
                    last_pos = pos + 1
                parts.append(line[last_pos:].strip())
                
                # Check if this is a clear case of multiple statements
                # Avoid fixing semicolons in list/dict literals or for loops
                if len(parts) >= 2:
                    indent = line[:len(line) - len(line.lstrip())]
                    # Create continuation lines
                    fixed_lines.append(indent + parts[0])
                    for part in parts[1:]:
                        fixed_lines.append(indent + part)
                    changes += 1
                    continue
        
        # Fix E701: colon after if/for/while/def/class with body on same line
        # Pattern: if x: do_something()
        # Pattern: for x in y: do_something()
        # Pattern: def foo(): pass
        
        # More careful approach: detect compound statements
        compound_match = re.match(r"^(\s*)(if |elif |else:|for |while |def |class |with |try:|except |finally:|async def |async for |async with )(.*)", line)
        if compound_match:
            indent = compound_match.group(1)
            keyword = compound_match.group(2)
            rest = compound_match.group(3)
            
            # Check if there's a body after the colon (compound statement)
            # e.g., if x: return True -> should be split
            # But NOT: if x:\n (that's already multi-line)
            
            if ":" in rest:
                colon_pos = rest.find(":")
                after_colon = rest[colon_pos+1:].strip()
                condition_part = rest[:colon_pos+1]
                
                # Only fix if there's actual code after the colon (not just a comment)
                if after_colon and not after_colon.startswith("#"):
                    # Split into header + body
                    fixed_lines.append(indent + keyword + condition_part)
                    fixed_lines.append(indent + "    " + after_colon)
                    changes += 1
                    continue
        
        fixed_lines.append(line)
    
    new_content = "\n".join(fixed_lines)
    
    if changes > 0:
        with open(filepath, "w") as f:
            f.write(new_content)
        print(f"{filepath}: {changes} fixes applied")
    else:
        print(f"{filepath}: no changes needed")

# Now run ruff to verify
result = subprocess.run(
    ["ruff", "check", "--select", "E701,E702", "nexus_ai/", "--statistics"],
    capture_output=True, text=True
)
print(f"\nRemaining E701/E702 errors:")
print(result.stdout or result.stderr)
