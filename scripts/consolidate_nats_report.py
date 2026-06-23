#!/usr/bin/env python3
"""
Consolidate NATS KV Store and NATS Object Store into parent NATS technology.
Removes separate entries, updates descriptions, and renumbers items.
"""

import re

FILE = "RAPORT_TECHNOLOGII_NEXUSAI.txt"

with open(FILE, "r") as f:
    lines = f.readlines()

# Lines to remove (exact matches for the standalone entries)
lines_to_remove = {
    "  42. NATS KV Store                       [A]  — Klucz-wartość na NATS (core/nats_kv_store.py)\n",
    "  43. NATS Object Store                   [A]  — Object storage na NATS (core/nats_object_store.py)\n",
    "  93. NATS KV Store                      [A]  — Rozproszony cache klucz-wartość\n",
}

# Also update the NATS Server description to emphasize built-in features
new_nats_server_line = "  41. NATS Server >=2.10                  [A]  — Message broker (JetStream z wbudowanym KV Store i Object Store)\n"
old_nats_server_line = "  41. NATS Server >=2.10                  [A]  — Message broker (JetStream, KV Store, Object Store)\n"

# Filter out lines to remove
filtered_lines = []
items_removed = 0
for line in lines:
    if line in lines_to_remove:
        items_removed += 1
        continue
    if line == old_nats_server_line:
        filtered_lines.append(new_nats_server_line)
        continue
    filtered_lines.append(line)

# Now renumber all items with pattern "  XX. "
# After removing 2 items from positions 42-43 and 1 item from position 93,
# all items after 43 shift by -2, and items after 93 shift by an additional -1
# Wait, after the first removal at positions 42-43, what was 93 becomes 91.
# Then removing that makes items after 91 shift by -1 more.
# Net: items 44-92 (original) shift -2, items 94+ (original) shift -3.

# Actually, much simpler approach: just find all numbered lines and rebuild numbering
def renumber_item(match):
    """Renumber a matched item line based on current position."""
    return f"  {match.group(1)}. "

# Parse all lines, assign new sequential numbers
result_lines = []
item_counter = 0
for line in filtered_lines:
    # Match lines like "  42. " at the beginning
    m = re.match(r"^  (\d+)\. ", line)
    if m:
        item_counter += 1
        # Replace the number with new counter, preserving the rest
        new_line = re.sub(r"^  \d+\. ", f"  {item_counter}. ", line)
        result_lines.append(new_line)
    else:
        result_lines.append(line)

# Update statistics: reduce total technologies count
result_content = "".join(result_lines)
# Update the total count: was ~327, now ~325 (removed 2 duplicate entries)
result_content = result_content.replace(
    "  ŁĄCZNIE UNIKALNYCH TECHNOLOGII:     ~327\n",
    "  ŁĄCZNIE UNIKALNYCH TECHNOLOGII:     ~325\n",
)
# Update active technologies count: was ~210, now ~208
result_content = result_content.replace(
    "  TECHNOLOGIE AKTYWNE [A]:            ~210\n",
    "  TECHNOLOGIE AKTYWNE [A]:            ~208\n",
)

with open(FILE, "w") as f:
    f.write(result_content)

print(f"Processed {FILE}:")
print(f"  - Removed {items_removed} lines")
print(f"  - Renumbered {item_counter} items")
print(f"  - Updated NATS Server description")
print(f"  - Updated statistics")
