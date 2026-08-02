# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — plan34_vat Legal Basis Auto-Filler (P29 N4)
# ═══════════════════════════════════════════════════════════════════════════════
# Auto-generowany skrypt do wypełnienia 179 pustych _legal_basis w plan34_vat.rego
# Na podstawie P29 Legal Audit VAT Article-by-Article.
# Uruchom: python JDG/tools/fix_plan34_legal_basis.py
# ═══════════════════════════════════════════════════════════════════════════════

import re
import sys

# Mapa article_number → legal_basis z audytu P29
LEGAL_BASIS_MAP = {
    # DZIAŁ II — ZAKRES OPODATKOWANIA (Art. 5-14)
    "a5": "Art. 5 ust. 1 pkt 1-3 VAT",
    "a7": "Art. 7 ust. 1-8 VAT",
    "a8": "Art. 8 ust. 1-6 VAT",
    "a9": "Art. 9-9a VAT (WNT)",
    "a10": "Art. 10 VAT",
    "a11": "Art. 11 ust. 1-4 VAT (import)",
    "a12": "Art. 12 VAT",
    "a13": "Art. 13 VAT (WDT)",
    "a14": "Art. 14 VAT",

    # DZIAŁ III — PODATNICY (Art. 15-18)
    "a15": "Art. 15 ust. 1-9 VAT",
    "a16": "Art. 16 VAT (mały podatnik)",
    "a17": "Art. 17 VAT (odwrotne obciążenie)",
    "a18": "Art. 18 VAT (rolnik ryczałtowy)",

    # DZIAŁ IV — OBOWIĄZEK PODATKOWY (Art. 19a-21)
    "a19a": "Art. 19a ust. 1-8 VAT",
    "a20": "Art. 20 VAT",
    "a21": "Art. 21 VAT",

    # DZIAŁ V — MIEJSCE ŚWIADCZENIA (Art. 22-28o)
    "a28a": "Art. 28a VAT",
    "a28b": "Art. 28b VAT",
    "a28c": "Art. 28c VAT",
    "a28d": "Art. 28d VAT",
    "a28e": "Art. 28e VAT",
    "a28f": "Art. 28f VAT",
    "a28g": "Art. 28g VAT",
    "a28h": "Art. 28h VAT",
    "a28i": "Art. 28i VAT",
    "a28j": "Art. 28j VAT",
    "a28k": "Art. 28k VAT",
    "a28l": "Art. 28l VAT",
    "a28m": "Art. 28m VAT",
    "a28n": "Art. 28n VAT",
    "a28o": "Art. 28o VAT",

    # DZIAŁ VI — PODSTAWA OPODATKOWANIA (Art. 29a-32)
    "a29a": "Art. 29a ust. 1-15 VAT",
    "a30a": "Art. 30a VAT",
    "a31": "Art. 31 VAT",
    "a32": "Art. 32 VAT",

    # DZIAŁ VII — ZASADY WYMIARU (Art. 41-85, 86-96)
    "a41": "Art. 41 ust. 1-15 VAT",
    "a42": "Art. 42 ust. 1-14 VAT (WDT 0%)",
    "a43": "Art. 43 ust. 1 pkt 1-38 VAT",
    "a83": "Art. 83 VAT",
    "a86": "Art. 86 ust. 1-10 VAT (odliczenia)",
    "a86a": "Art. 86a VAT (limit aut)",
    "a87": "Art. 87 VAT (zwrot)",
    "a88": "Art. 88 VAT",
    "a89a": "Art. 89a VAT (złe długi)",
    "a89b": "Art. 89b VAT",
    "a90": "Art. 90 VAT (proporcja)",
    "a91": "Art. 91 VAT (korekta roczna)",
    "a96": "Art. 96 VAT (rejestracja)",

    # DZIAŁ VIII — PROCEDURY SZCZEGÓLNE (Art. 106a-120)
    "a106a": "Art. 106a VAT",
    "a106b": "Art. 106b VAT",
    "a106c": "Art. 106c VAT",
    "a106d": "Art. 106d VAT",
    "a106e": "Art. 106e VAT (elementy faktury)",
    "a107": "Art. 107 VAT (VAT RR)",
    "a108": "Art. 108 VAT",
    "a108a": "Art. 108a VAT (MPP)",
    "a109": "Art. 109 VAT",
    "a113": "Art. 113 VAT (zwolnienie podmiotowe)",
    "a115": "Art. 115 VAT (VAT RR)",
    "a116": "Art. 116 VAT (VAT RR)",
    "a119": "Art. 119 VAT (biura podróży)",
    "a120": "Art. 120 VAT (procedura marży)",
}

def extract_article(rule_id: str) -> str | None:
    """Extract article key from rule_id like jdg.vat.a5.r1 → a5"""
    m = re.search(r'jdg\.vat\.(a\d+[a-z]*)\.', rule_id)
    return m.group(1) if m else None

def get_legal_basis(article_key: str) -> str:
    """Get legal_basis for a given article key"""
    return LEGAL_BASIS_MAP.get(article_key, "")

def fix_plan34_legal_basis(filepath: str) -> tuple[int, int]:
    """Fix empty _legal_basis fields in plan34_vat.rego"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    fixed_count = 0
    total_empty = 0

    # Find all rules with empty legal_basis
    lines = content.split('\n')
    new_lines = []
    current_rule_id = None

    for line in lines:
        # Track current rule_id
        m = re.search(r'"rule_id":"(jdg\.vat\.a\d+[a-z]*\.r\d+)"', line)
        if m:
            current_rule_id = m.group(1)

        # Fix empty legal_basis
        if '"_legal_basis":""' in line and current_rule_id:
            total_empty += 1
            article_key = extract_article(current_rule_id)
            if article_key:
                legal_basis = get_legal_basis(article_key)
                if legal_basis:
                    line = line.replace('"_legal_basis":""', f'"_legal_basis":"{legal_basis}"')
                    fixed_count += 1

            # Reset current_rule_id after each rule block
            if '}' in line and current_rule_id:
                # Only reset at end of rule body, not inside nested objects
                if line.strip().startswith('}'):
                    pass  # Keep tracking until end of rule

        # Detect end of rule entry
        if current_rule_id and line.strip() == '}':
            current_rule_id = None

        new_lines.append(line)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write('\n'.join(new_lines))

    return fixed_count, total_empty

if __name__ == '__main__':
    filepath = sys.argv[1] if len(sys.argv) > 1 else 'JDG/rules/micro/plan34_vat.rego'
    fixed, total = fix_plan34_legal_basis(filepath)
    print(f"Fixed {fixed}/{total} empty _legal_basis fields in {filepath}")
