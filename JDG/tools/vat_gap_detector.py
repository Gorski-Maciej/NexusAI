# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — VAT Gap Auto-Detector (P29 Innovation #2)
# ═══════════════════════════════════════════════════════════════════════════════
# Porównuje listę artykułów ustawy VAT z regułami Rego, raportuje ❌/⚠️/✅.
# Uruchom: python JDG/tools/vat_gap_detector.py [directory]
# ═══════════════════════════════════════════════════════════════════════════════

import re
import sys
from pathlib import Path
from collections import defaultdict

# Pełna lista artykułów VAT wymagających pokrycia
VAT_ARTICLES_EXPECTED = {
    "Art. 5":  {"status": "REQUIRED", "desc": "Zakres opodatkowania"},
    "Art. 7":  {"status": "REQUIRED", "desc": "Dostawa towarów"},
    "Art. 8":  {"status": "REQUIRED", "desc": "Świadczenie usług"},
    "Art. 9":  {"status": "REQUIRED", "desc": "WNT"},
    "Art. 11": {"status": "REQUIRED", "desc": "Import towarów"},
    "Art. 13": {"status": "REQUIRED", "desc": "WDT"},
    "Art. 17": {"status": "REQUIRED", "desc": "Odwrotne obciążenie"},
    "Art. 19a":{"status": "REQUIRED", "desc": "Obowiązek podatkowy"},
    "Art. 28b":{"status": "REQUIRED", "desc": "Miejsce B2B"},
    "Art. 28c":{"status": "REQUIRED", "desc": "Miejsce B2C"},
    "Art. 28d":{"status": "REQUIRED", "desc": "Miejsce pośrednictwo"},
    "Art. 28e":{"status": "REQUIRED", "desc": "Miejsce nieruchomości"},
    "Art. 28i":{"status": "REQUIRED", "desc": "Miejsce kultura/sport"},
    "Art. 28j":{"status": "REQUIRED", "desc": "Miejsce restauracje"},
    "Art. 28k":{"status": "REQUIRED", "desc": "Miejsce wynajem"},
    "Art. 28l":{"status": "REQUIRED", "desc": "Miejsce e-usługi"},
    "Art. 28o":{"status": "REQUIRED", "desc": "Podwójne opodatkowanie"},
    "Art. 29a":{"status": "REQUIRED", "desc": "Podstawa opodatkowania"},
    "Art. 41": {"status": "REQUIRED", "desc": "Stawki"},
    "Art. 42": {"status": "REQUIRED", "desc": "WDT 0%"},
    "Art. 43": {"status": "REQUIRED", "desc": "Zwolnienia"},
    "Art. 86": {"status": "REQUIRED", "desc": "Odliczenia"},
    "Art. 86a":{"status": "REQUIRED", "desc": "Limit aut"},
    "Art. 87": {"status": "REQUIRED", "desc": "Zwrot"},
    "Art. 89a":{"status": "REQUIRED", "desc": "Złe długi"},
    "Art. 90": {"status": "REQUIRED", "desc": "Proporcja"},
    "Art. 91": {"status": "REQUIRED", "desc": "Korekta roczna"},
    "Art. 96": {"status": "REQUIRED", "desc": "Rejestracja"},
    "Art. 106e":{"status": "REQUIRED", "desc": "Faktury"},
    "Art. 108a":{"status": "REQUIRED", "desc": "MPP"},
    "Art. 113": {"status": "REQUIRED", "desc": "Zwolnienie podmiotowe"},
    "Art. 115": {"status": "REQUIRED", "desc": "VAT RR"},
    "Art. 120": {"status": "REQUIRED", "desc": "Marża"},
    "Art. 3":  {"status": "OPTIONAL", "desc": "Wyłączenia (uchylony)"},
}

def detect_gaps(root_dir: str) -> dict:
    """Detect VAT gaps by scanning rego files for legal_basis references"""
    found_articles = defaultdict(set)

    for rego_file in Path(root_dir).rglob("*.rego"):
        if 'vat' not in str(rego_file).lower():
            continue
        try:
            content = rego_file.read_text(encoding='utf-8')
        except Exception:
            continue

        for match in re.finditer(r'"_legal_basis":\s*"([^"]*)"', content):
            legal_basis = match.group(1)
            for art_key in VAT_ARTICLES_EXPECTED:
                art_num = art_key.replace("Art. ", "")
                if art_num in legal_basis:
                    found_articles[art_key].add(str(rego_file.relative_to(root_dir)))

    return dict(found_articles)

if __name__ == '__main__':
    root = sys.argv[1] if len(sys.argv) > 1 else "JDG/rules"
    gaps = detect_gaps(root)

    print("=" * 70)
    print("VAT GAP AUTO-DETECTOR (P29 Innovation #2)")
    print("=" * 70)

    complete, partial, missing = 0, 0, 0

    for art_key, info in VAT_ARTICLES_EXPECTED.items():
        files = gaps.get(art_key, set())
        if len(files) > 2:
            status_icon = "✅"
            complete += 1
        elif len(files) > 0:
            status_icon = "⚠️"
            partial += 1
        else:
            status_icon = "❌"
            if info["status"] == "REQUIRED":
                missing += 1

        print(f"  {status_icon} {art_key:12s} {info['desc']:30s} ({len(files)} plików)")
        if files and len(files) <= 3:
            for f in sorted(files):
                print(f"       └─ {f}")

    print(f"\nPODSUMOWANIE: {complete} ✅ / {partial} ⚠️ / {missing} ❌ ({len(VAT_ARTICLES_EXPECTED)} artykułów)")
