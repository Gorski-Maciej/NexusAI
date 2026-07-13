#!/usr/bin/env python3
"""Cross-reference: Plan OPA 50 legal points vs existing JDG rule_ids."""
import re, os, sys

# Collect existing rule_ids
existing = set()
for root, dirs, files in os.walk("JDG/rules"):
    for f in files:
        if f.endswith(".rego"):
            path = os.path.join(root, f)
            with open(path) as fh:
                content = fh.read()
                ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', content)
                existing.update(ids)

print(f"=== STAN OBECNY ===")
print(f"Unikalne rule_id w JDG/rules/: {len(existing)}")

# Read Plan OPA 50
with open("Plan OPA/50_JDG_BRAKUJACE_PUNKTY_PRAWNE.md") as f:
    plan50 = f.read()

# Extract Micro IDs: jdg.<ustawa>.<art>.r<n>
micro_ids = set(re.findall(r'`(jdg\.[a-z_]+\.[a-z0-9_]+\.r\d+)`', plan50))
# Extract Macro IDs: P<number> or R<number>
macro_ids = set(re.findall(r'\(Macro:\s*(P\d+[a-z_]*)\)', plan50))
macro_ids.update(re.findall(r'\(Macro:\s*(R\d+[a-z_]*)\)', plan50))

print(f"\n=== PLAN OPA 50 ===")
print(f"Micro ID (jdg.*) znalezione: {len(micro_ids)}")
print(f"Macro ID (P/R) znalezione: {len(macro_ids)}")

# Cross-reference
plan_micro = set()
for mid in micro_ids:
    # Normalize: remove backticks, keep as-is
    plan_micro.add(mid.strip('`'))

missing_micro = plan_micro - existing
covered_micro = plan_micro & existing

print(f"\n=== POKRYCIE ===")
print(f"Micro pokryte: {len(covered_micro)}")
print(f"Micro BRAKUJĄCE: {len(missing_micro)}")
print(f"Pokrycie Micro: {100*len(covered_micro)/max(1,len(plan_micro)):.1f}%")

# Show first 30 missing
print("\n=== PIERWSZE 30 BRAKUJĄCYCH Micro ID ===")
for mid in sorted(missing_micro)[:30]:
    print(f"  {mid}")

# Also extract section counts from file 50
sections = {
    "I. VAT": len(re.findall(r'#### V\.\d+\.', plan50)),
    "II. PIT": len(re.findall(r'#### P\.\d+\.', plan50)),
    "III. Ordynacja": len(re.findall(r'#### OP\.\d+\.', plan50)),
    "IV. KKS": len(re.findall(r'#### K\.\d+\.', plan50)),
    "V. SUS/ZUS": len(re.findall(r'#### Z\.\d+\.', plan50)),
    "VI. Ryczałt": len(re.findall(r'#### R\.\d+\.', plan50)),
    "VII. Prawo Przeds.": len(re.findall(r'#### PP\.\d+\.', plan50)),
    "VIII. UoR": len(re.findall(r'#### U\.\d+\.', plan50)),
    "IX. PCC+podatki": len(re.findall(r'#### Pcc\.\d+\.', plan50)),
    "X. Cross-border": len(re.findall(r'#### CB\.\d+\.', plan50)),
    "XI. CEIDG/Sukcesja": len(re.findall(r'#### Suk\.\d+\.', plan50)),
    "XII. Zdrowotna": len(re.findall(r'#### Zdr\.\d+\.', plan50)),
    "XIII. AML/RODO/BDO": len(re.findall(r'#### AML\.\d+\.', plan50)),
}

print("\n=== PUNKTY PRAWNE WG SEKCJI (file 50) ===")
total_points = 0
for sec, count in sections.items():
    print(f"  {sec}: {count}")
    total_points += count
print(f"  ŁĄCZNIE (klasa A): {total_points}")

# Also count Class B points (V.060+ style)
class_b = len(re.findall(r'#### V\.\d{3}\.\s+Art\.', plan50))
print(f"  Klasa B (V.060+): {class_b}")
print(f"  Szacunkowo wszystkie: {total_points + class_b}")
