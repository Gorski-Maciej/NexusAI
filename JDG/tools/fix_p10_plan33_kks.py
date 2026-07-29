#!/usr/bin/env python3
"""
P10 plan33_kks.rego — Critical Bug Fix Script
Fixes all bugs identified in RAPORT_P10_JDG_KKS_MICRO_SANCTIONS_v7.0.txt:
  1. Art. 55 rules → Art. 62 (wrong _legal_basis for empty invoices)
  2. Old legal citation Dz.U. 1999 → Dz.U. 2024
  3. "zbrodnia" → "przestępstwo skarbowe" (KKS terminology)
  4. a54.r1 misattribution (non-filing → Art. 77 not Art. 54)
  5. Naming: jdg.kks.aXX → jdg.micro.kks.aXX
"""
import re
from pathlib import Path

PLAN33_PATH = Path(__file__).resolve().parent.parent / "rules" / "micro" / "plan33_kks.rego"

with open(PLAN33_PATH) as f:
    content = f.read()

original = content
fixes_applied = 0

# ── FIX 1: Art.55 → Art.62 (empty invoices have wrong _legal_basis) ──
# a55.r6 → a62.r6 etc.
art55_replacements = {
    '"Art. 55 par. 1 KKS"': '"Art. 62 par. 2 KKS"',  # wystawianie pustych faktur
    '"Art. 55 par. 2 KKS"': '"Art. 62 par. 2 KKS"',  # używanie pustej faktury  
    '"Art. 55 par. 3 KKS"': '"Art. 62 par. 2 KKS"',  # VAT > 1M PLN
    '"Art. 55 par. 4 KKS"': '"Art. 62 par. 2 KKS"',  # VAT < 10k
    '"Art. 55 par. 5 KKS"': '"Art. 62 par. 2 KKS"',  # recydywa
    '"Art. 55 par. 6 KKS"': '"Art. 62 par. 2 KKS"',  # ujawnienie przed US
}
for old, new in art55_replacements.items():
    if old in content:
        content = content.replace(old, new)
        fixes_applied += 1
        print(f"  ✅ FIX: {old} → {new}")

# Also fix the rule_id from jdg.kks.a55.rX to jdg.micro.kks.a62.rX
art55_ruleid_map = {
    '"jdg.kks.a55.r10"': '"jdg.micro.kks.a62.r10"',
    '"jdg.kks.a55.r11"': '"jdg.micro.kks.a62.r11"',
    '"jdg.kks.a55.r6"': '"jdg.micro.kks.a62.r6"',
    '"jdg.kks.a55.r7"': '"jdg.micro.kks.a62.r7"',
    '"jdg.kks.a55.r8"': '"jdg.micro.kks.a62.r8"',
    '"jdg.kks.a55.r9"': '"jdg.micro.kks.a62.r9"',
}
for old, new in art55_ruleid_map.items():
    if old in content:
        content = content.replace(old, new)
        fixes_applied += 1
        print(f"  ✅ FIX rule_id: {old} → {new}")

# ── FIX 2: Old legal citation → current ──
OLD_CITATION = '"Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)"'
NEW_CITATION = '"Dz.U. 2024 poz. 628 t.j. KKS"'
count_old = content.count(OLD_CITATION)
if count_old > 0:
    content = content.replace(OLD_CITATION, NEW_CITATION)
    fixes_applied += count_old
    print(f"  ✅ FIX: Old citation → New citation ({count_old} occurrences)")

# ── FIX 3: "zbrodnia" → "przestępstwo skarbowe" ──
# In comments (not in _legal_basis)
zbrodnia_fixes = {
    '(zbrodnia)': '(przestępstwo skarbowe)',
    '(zbrodnia VAT)': '(przestępstwo skarbowe VAT)',
    '-> zbrodnia skarbowa': '-> przestępstwo skarbowe',
    '-> zbrodnia skarbowa': '-> przestępstwo skarbowe',
}
for old, new in zbrodnia_fixes.items():
    cnt = content.count(old)
    if cnt > 0:
        content = content.replace(old, new)
        fixes_applied += cnt
        print(f"  ✅ FIX: '{old}' → '{new}' ({cnt}x)")

# Also fix in _routing_reason and _warnings fields
routing_reason_fixes = {
    '"VAT > 10M PLN -> zbrodnia skarbowa"': '"VAT > 10M PLN -> przestępstwo skarbowe"',
    '"zbrodnia VAT"': '"przestępstwo skarbowe VAT"',
}
for old, new in routing_reason_fixes.items():
    if old in content:
        content = content.replace(old, new)
        fixes_applied += 1
        print(f"  ✅ FIX routing: '{old}' → '{new}'")

# Fix warnings
warning_fixes = {
    '"\\\\[MICRO\\\\] VAT > 10M PLN -> zbrodnia skarbowa"': '"[MICRO] VAT > 10M PLN -> przestępstwo skarbowe"',
}
for old, new in warning_fixes.items():
    if old in content:
        content = content.replace(old, new)
        fixes_applied += 1
        print(f"  ✅ FIX warning: '{old}' → '{new}'")

# ── FIX 4: a54.r1 misattribution ──
# The rule describes non-filing of declarations → Art. 77, not Art. 54
a54r1_legal = '"Art. 54 KKS"'
a77_legal = '"Art. 77 KKS"'
if a54r1_legal in content:
    content = content.replace(a54r1_legal, a77_legal, 1)  # Only first occurrence (a54.r1)
    fixes_applied += 1
    print(f"  ✅ FIX: a54.r1 _legal_basis: {a54r1_legal} → {a77_legal}")

# ── FIX 5: Naming consistency ──
# Change all rule_id from "jdg.kks.aXX.rY" to "jdg.micro.kks.aXX.rY"
# Only for the article rules (a54-a80), not for mit/pen
rule_id_pattern = re.compile(r'"rule_id":"jdg\.kks\.(a\d+\.r\d+)"')
def fix_rule_id(m):
    fixes_applied = 0  # can't use nonlocal easily in lambda, so do post-count
    return f'"rule_id":"jdg.micro.kks.{m.group(1)}"'

matches = list(rule_id_pattern.finditer(content))
if matches:
    content = rule_id_pattern.sub(r'"rule_id":"jdg.micro.kks.\1"', content)
    fixes_applied += len(matches)
    print(f"  ✅ FIX: Naming jdg.kks.aXX → jdg.micro.kks.aXX ({len(matches)} occurrences)")

# Also fix the header comment naming pattern
content = content.replace('# jdg.kks.a', '# jdg.micro.kks.a')

# ── FIX 6: a54.r8 "zbrodnia" in comment ──
content = content.replace('Kara do 25 lat pozbawienia wolności (zbrodnia)', 
                           'Kara do 25 lat pozbawienia wolności (przestępstwo skarbowe)')
content = content.replace('Kara do 25 lat (zbrodnia)',
                           'Kara do 25 lat (przestępstwo skarbowe)')

# ── Write back ──
with open(PLAN33_PATH, 'w') as f:
    f.write(content)

print(f"\n  📊 TOTAL FIXES APPLIED: {fixes_applied}")
print(f"  📄 Written to: {PLAN33_PATH}")

# ── Verify ──
with open(PLAN33_PATH) as f:
    verify = f.read()

old_art55 = sum(1 for l in verify.split('\n') if 'Art. 55 par.' in l and '_legal_basis' in l)
old_citation = verify.count('Dz.U. 1999')
zbrodnia_left = sum(1 for l in verify.split('\n') if 'zbrodnia' in l.lower() and '_legal_basis' not in l)
jdg_kks_without_micro = len(re.findall(r'"rule_id":"jdg\.kks\.a\d+', verify))

print(f"\n  🔍 POST-FIX VERIFICATION:")
print(f"     Remaining 'Art. 55 par.' in _legal_basis: {old_art55} (should be 0)")
print(f"     Remaining 'Dz.U. 1999': {old_citation} (should be 0)")
print(f"     Remaining 'zbrodnia': {zbrodnia_left} (should be 0)")
print(f"     Remaining 'jdg.kks.aXX' rule_ids: {jdg_kks_without_micro} (should be 0)")
print(f"     ✅ All good!" if old_art55 == 0 and old_citation == 0 and jdg_kks_without_micro == 0 else "     ⚠️  Some issues remain!")
