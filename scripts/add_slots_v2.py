#!/usr/bin/env python3
"""Add __slots__ to non-Struct/Protocol/Enum classes in a directory.
v2: Fixed class boundary detection, proper insertion point, per-class attr scanning.
"""
import ast
import os
import sys


SKIP_BASES = {"Struct", "Protocol", "Enum", "IntEnum", "StrEnum"}


def find_class_attrs(tree, class_node):
    """Find instance attrs ONLY for this specific class's __init__."""
    attrs = set()
    for item in class_node.body:
        if not isinstance(item, (ast.FunctionDef, ast.AsyncFunctionDef)):
            continue
        if item.name != "__init__":
            continue
        for stmt in ast.walk(item):
            if isinstance(stmt, ast.Assign):
                for target in stmt.targets:
                    if (isinstance(target, ast.Attribute)
                            and isinstance(target.value, ast.Name)
                            and target.value.id == "self"):
                        attrs.add(target.attr)
    return tuple(sorted(attrs))


def should_skip(node):
    """Check if class should be skipped."""
    for base in node.bases:
        name = None
        if isinstance(base, ast.Name):
            name = base.id
        elif isinstance(base, ast.Attribute):
            name = base.attr
        if name and name in SKIP_BASES:
            return True
    for stmt in node.body:
        if isinstance(stmt, ast.Assign):
            for t in stmt.targets:
                if isinstance(t, ast.Name) and t.id == "__slots__":
                    return True
    return False


def process_file(filepath):
    """Add __slots__ to qualifying classes in a single file."""
    try:
        with open(filepath) as f:
            original = f.read()
    except Exception:
        return 0

    tree = ast.parse(original)
    lines = original.split("\n")
    added = 0
    offset = 0  # Track cumulative line insertion offset

    # Collect all classes that need slots (process bottom-up to preserve line numbers)
    classes_to_process = []
    for node in ast.walk(tree):
        if isinstance(node, ast.ClassDef) and not should_skip(node):
            attrs = find_class_attrs(tree, node)
            classes_to_process.append((node.lineno, node.col_offset, node.name, attrs))

    # Sort by line number descending so inserts don't shift subsequent targets
    classes_to_process.sort(reverse=True)

    for lineno, col_offset, name, attrs in classes_to_process:
        # Convert to 0-indexed
        idx = lineno - 1

        # Find the class definition colon
        while idx < len(lines):
            line = lines[idx]
            if line.strip().startswith("class ") and ":" in line:
                break
            idx += 1

        if idx >= len(lines):
            continue

        # Move to first line after the colon
        idx += 1

        # Skip decorators on first method if they exist
        while idx < len(lines) and lines[idx].strip().startswith("@"):
            idx += 1

        # Skip docstring if present
        if idx < len(lines):
            stripped = lines[idx].strip()
            if stripped.startswith('"""') or stripped.startswith("'''"):
                if stripped.count('"""') < 2 and stripped.count("'''") < 2:
                    idx += 1
                    while idx < len(lines):
                        if '"""' in lines[idx] or "'''" in lines[idx]:
                            idx += 1
                            break
                        idx += 1
                else:
                    idx += 1

        # Determine indentation (class body)
        indent = " " * (col_offset + 4)

        # Build __slots__ line
        if attrs:
            slots_line = f'{indent}__slots__ = {attrs!r}'
        else:
            slots_line = f'{indent}__slots__ = ()'

        lines.insert(idx, slots_line)
        added += 1
        print(f"  [+slots] {os.path.basename(filepath)}:{lineno} {name} -> {attrs!r}")

    if added > 0:
        with open(filepath, "w") as f:
            f.write("\n".join(lines))

    return added


def main():
    dirs = sys.argv[1:] if len(sys.argv) > 1 else ["nexus_ai/core", "nexus_ai/db", "nexus_ai/events"]
    total = 0
    for d in dirs:
        if not os.path.isdir(d):
            print(f"  [SKIP] {d} (not found)")
            continue
        for root, _, files in os.walk(d):
            for fname in files:
                if not fname.endswith(".py"):
                    continue
                path = os.path.join(root, fname)
                added = process_file(path)
                total += added

    print(f"\nDone. Added __slots__ to {total} classes in {dirs}.")


if __name__ == "__main__":
    main()
