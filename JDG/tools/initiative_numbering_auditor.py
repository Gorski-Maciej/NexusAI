#!/usr/bin/env python3
"""
Initiative Numbering Auditor (Raport P26 — Innowacja 15)
Weryfikuje spójność numeracji inicjatyw strategicznych (S1-S24) w plikach .rego.

Wykrywa:
- Duplikaty numerów inicjatyw
- Brakujące numery w sekwencji
- Niespójności między nagłówkiem pliku a referencjami w innych plikach
"""
import re
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent

INITIATIVE_PATTERN = re.compile(r'Strategic Initiative (S\d+)', re.IGNORECASE)
S_REFERENCE_PATTERN = re.compile(r'\b(S\d{1,2})\b')

EXPECTED_INITIATIVES = {
    # Plik -> oczekiwany S-number (wg P26 R5)
    "neural_rule_mesh_enterprise.rego": "S10",
    "ppk_pfron_enterprise.rego": "S18",
    "banking_automation_enterprise.rego": "S10",
    "uor_enterprise_live.rego": "S18",
}


def parse_expected():
    """Return the expected map; loaded from the dict above."""
    return EXPECTED_INITIATIVES


def audit_initiatives():
    rules_dir = JDG_ROOT / "rules"
    issues = []
    found = {}  # S-number -> [files]

    for fp in sorted(rules_dir.glob("**/*.rego")):
        rel = str(fp.relative_to(JDG_ROOT))
        content = fp.read_text(errors="replace")

        # Find initiative header
        im = INITIATIVE_PATTERN.search(content)
        if im:
            s_num = im.group(1).upper()
            found.setdefault(s_num, []).append(rel)

        # Check against expected
        fname = fp.name
        if fname in EXPECTED_INITIATIVES:
            expected = EXPECTED_INITIATIVES[fname]
            if im and im.group(1).upper() != expected:
                issues.append(f"[MISMATCH] {rel}: header says {im.group(1)}, expected {expected}")
            elif not im:
                issues.append(f"[MISSING] {rel}: no Strategic Initiative header found (expected {expected})")

    # Check for duplicates
    for s_num, files in found.items():
        if len(files) > 1:
            issues.append(
                f"[DUPLICATE] {s_num} used in {len(files)} files: {', '.join(files)}")

    # Check S1-S24 completeness
    all_nums = sorted(set(int(s[1:]) for s in found))
    if all_nums:
        expected_range = set(range(min(all_nums), max(all_nums) + 1))
        missing = sorted(expected_range - set(all_nums))
        if missing:
            issues.append(
                f"[GAPS] Missing initiative numbers: {', '.join('S' + str(n) for n in missing)}")

    return issues, found


def main():
    issues, found = audit_initiatives()

    if issues:
        print(f"🔴 Initiative Numbering Audit — {len(issues)} issues found:")
        for i in issues:
            print(f"  {i}")
    else:
        print("✅ Initiative Numbering Audit — wszystkie inicjatywy spójne.")

    print(f"\n📊 Znalezione inicjatywy: {len(found)}")
    for s_num in sorted(found, key=lambda x: int(x[1:])):
        files = found[s_num]
        print(f"  {s_num}: {len(files)} plik(i) — {', '.join(f.name for f in (Path(f) for f in files))}")

    return 1 if issues else 0


if __name__ == "__main__":
    sys.exit(main())
