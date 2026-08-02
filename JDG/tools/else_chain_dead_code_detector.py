#!/usr/bin/env python3
"""
Else-Chain Dead Code Detector (Raport P26 — Innowacja 13)
Wykrywa martwy kod w else-chainach Rego:
- Kolejne reguły z identycznymi triggerami
- Reguły z { true } bez CHECKPOINT-STUB
- Reguły, które nigdy nie zostaną osiągnięte (zasłonięte przez wcześniejszą z { true })
"""
import re
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent


def extract_condition(block_text):
    """Extract the condition between last { and } in a rule block."""
    # Find the condition block (last { ... } before end)
    matches = list(re.finditer(r'\{\s*\n([^}]*?)\n\s*\}', block_text, re.DOTALL))
    if matches:
        return matches[-1].group(1).strip()
    return ""


def normalize_condition(cond):
    """Normalize condition for comparison."""
    # Remove comments, normalize whitespace
    cond = re.sub(r'#.*$', '', cond, flags=re.MULTILINE)
    cond = re.sub(r'\s+', ' ', cond).strip()
    return cond


def analyze_else_chain(filepath):
    content = Path(filepath).read_text(errors="replace")
    lines = content.split("\n")

    # Find all rule blocks (decide/else := { ... } { condition })
    blocks = []
    current_block = None

    for i, line in enumerate(lines):
        stripped = line.strip()
        if re.match(r'(?:else\s+)?:=\s*\{', stripped) or stripped == ":={" or stripped.startswith(":={"):
            if current_block:
                blocks.append(current_block)
            current_block = {"start": i + 1, "lines": [line], "is_else": "else" in stripped.split(":=")[0]}
        elif current_block:
            current_block["lines"].append(line)
            if stripped == "}" and current_block["lines"][-2].strip().startswith("{"):
                blocks.append(current_block)
                current_block = None

    if current_block:
        blocks.append(current_block)

    issues = []
    prev_cond = None

    for block in blocks:
        block_text = "\n".join(block["lines"])
        rule_id_m = re.search(r'"rule_id"\s*:\s*"([^"]+)"', block_text)
        rule_id = rule_id_m.group(1) if rule_id_m else "unknown"

        cond = extract_condition(block_text)
        norm_cond = normalize_condition(cond)

        # Check for { true } without CHECKPOINT-STUB
        if norm_cond == "true":
            has_stub = "CHECKPOINT-STUB" in block_text
            if not has_stub:
                issues.append(f"[STUB_NO_CHECKPOINT] {rule_id}: uses {{ true }} without CHECKPOINT-STUB marker")

        # Check for identical triggers in else-chain
        if prev_cond and norm_cond and block["is_else"]:
            if prev_cond == norm_cond and norm_cond != "true":
                issues.append(f"[IDENTICAL_TRIGGER] {rule_id}: same trigger as previous rule. This is dead code in else-chain.")

        # Check if { true } makes subsequent rules unreachable
        if prev_cond == "true" and block["is_else"]:
            issues.append(f"[UNREACHABLE] {rule_id}: unreachable — preceded by {{ true }} rule")

        prev_cond = norm_cond

    return issues


def main():
    rules_dir = JDG_ROOT / "rules"
    all_issues = {}

    for fp in sorted(rules_dir.glob("**/*.rego")):
        rel = str(fp.relative_to(JDG_ROOT))
        issues = analyze_else_chain(fp)
        if issues:
            all_issues[rel] = issues

    total = sum(len(v) for v in all_issues.values())
    if total == 0:
        print("✅ Else-Chain Dead Code Detector — brak martwego kodu")
        return 0

    print(f"🔴 Else-Chain Dead Code Detector — {total} issues w {len(all_issues)} plikach:\n")
    stub_count = 0
    identical_count = 0
    unreachable_count = 0

    for fpath, issues in sorted(all_issues.items()):
        print(f"  📄 {fpath}:")
        for iss in issues:
            print(f"     {iss}")
            if "STUB_NO_CHECKPOINT" in iss:
                stub_count += 1
            elif "IDENTICAL_TRIGGER" in iss:
                identical_count += 1
            elif "UNREACHABLE" in iss:
                unreachable_count += 1

    print(f"\n📊 Podsumowanie: {stub_count} stubów bez CHECKPOINT, {identical_count} identycznych triggerów, {unreachable_count} nieosiągalnych reguł")
    return 1


if __name__ == "__main__":
    sys.exit(main())
