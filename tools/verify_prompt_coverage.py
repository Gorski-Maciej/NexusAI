#!/usr/bin/env python3
"""
Skrypt weryfikujący 100% pokrycia plików .rego w promptach GLM 5.2.

Sprawdza, czy każdy plik .rego z katalogu JDG/rules/ pojawia się
w przynajmniej jednym pliku promptu w prompts_glm52/.
"""

import os
import re
from pathlib import Path
from collections import defaultdict

PROJECT_ROOT = Path("/data/data/com.termux/files/home/NexusAI")
JDG_RULES = PROJECT_ROOT / "JDG" / "rules"
PROMPTS_DIR = PROJECT_ROOT / "prompts_glm52"

def extract_rego_files() -> set:
    """Zwraca zbiór wszystkich plików .rego w JDG/rules/ (ścieżki względem PROJECT_ROOT)."""
    rego_files = set()
    for rego_file in JDG_RULES.rglob("*.rego"):
        rel_path = rego_file.relative_to(PROJECT_ROOT)
        rego_files.add(str(rel_path))
    return rego_files

def extract_linked_rego_files(prompt_path: Path) -> set:
    """Ekstrahuje wszystkie odwołania do plików .rego z promptu.
    Szuka wzorców URL GitHub zawierających JDG/rules/..."""
    linked_files = set()
    try:
        with open(prompt_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception:
        return linked_files
    
    # Wzorzec: github.com/.../blob/main/JDG/rules/...rego
    # Wyłapuje zarówno pełne URL jak i ścieżki względne
    pattern = r'(?:github\.com/[^/\s]+/[^/\s]+/blob/main/)?(JDG/rules/[^\s\)\"]+\.rego)'
    matches = re.findall(pattern, content)
    
    for match in matches:
        # Normalizacja ścieżki
        path = match.strip()
        # Usuń ewentualne fragmenty URL
        if '#' in path:
            path = path.split('#')[0]
        linked_files.add(path)
    
    return linked_files

def main():
    print("=" * 70)
    print("🔍 WERYFIKACJA 100% POKRYCIA PLIKÓW .rego W PROMPTACH GLM 5.2")
    print("=" * 70)
    
    # Krok 1: Pobierz wszystkie pliki .rego
    print("\n📂 [1/4] Ekstrakcja plików .rego z JDG/rules/...")
    rego_files = extract_rego_files()
    print(f"   ✅ Znaleziono {len(rego_files)} plików .rego")
    
    # Krok 2: Pobierz wszystkie prompty
    print(f"\n📂 [2/4] Ekstrakcja promptów z {PROMPTS_DIR}...")
    prompt_files = sorted([f for f in PROMPTS_DIR.glob("*.md") if f.name != "INDEX.md"])
    print(f"   ✅ Znaleziono {len(prompt_files)} plików promptów")
    
    # Krok 3: Dla każdego promptu, ekstrahuj linki do .rego
    print("\n🔗 [3/4] Analiza linków w promptach...")
    file_to_prompts = defaultdict(list)
    total_links = 0
    
    for prompt_file in prompt_files:
        linked = extract_linked_rego_files(prompt_file)
        if linked:
            print(f"   📄 {prompt_file.name}: {len(linked)} linków do .rego")
            for lf in linked:
                file_to_prompts[lf].append(prompt_file.name)
            total_links += len(linked)
        else:
            print(f"   ⚠️  {prompt_file.name}: BRAK linków do .rego!")
    
    print(f"\n   Łącznie znaleziono {total_links} odwołań do plików .rego")
    
    # Krok 4: Cross-reference
    print(f"\n🔍 [4/4] Cross-reference: .rego vs Prompty...")
    
    covered = set()
    uncovered = []
    multi_covered = []
    
    for rf in sorted(rego_files):
        if rf in file_to_prompts:
            covered.add(rf)
            prompts = file_to_prompts[rf]
            if len(prompts) > 1:
                multi_covered.append((rf, prompts))
        else:
            uncovered.append(rf)
    
    # Wyniki
    print("\n" + "=" * 70)
    print("📊 WYNIKI WERYFIKACJI")
    print("=" * 70)
    
    coverage_pct = (len(covered) / len(rego_files)) * 100 if rego_files else 0
    
    print(f"\n   Plików .rego łącznie:     {len(rego_files)}")
    print(f"   ✅ Pokrytych:               {len(covered)} ({coverage_pct:.1f}%)")
    print(f"   ❌ NIE pokrytych:           {len(uncovered)}")
    print(f"   🔄 Pokrytych wielokrotnie:  {len(multi_covered)}")
    
    if uncovered:
        print("\n" + "=" * 70)
        print("❌ BRAKUJĄCE PLIKI .rego (nie pojawiają się w żadnym prompcie):")
        print("=" * 70)
        for i, uf in enumerate(sorted(uncovered), 1):
            print(f"   {i:3d}. {uf}")
    
    if multi_covered:
        print(f"\n🔄 Pliki z wielokrotnym pokryciem (pojawiają się w ≥2 promptach): {len(multi_covered)}")
    
    # Top 10 najczęściej linkowanych
    print("\n📈 TOP 10 NAJCZĘŚCIEJ LINKOWANYCH PLIKÓW:")
    sorted_by_count = sorted(file_to_prompts.items(), key=lambda x: len(x[1]), reverse=True)
    for i, (fpath, prompts) in enumerate(sorted_by_count[:10], 1):
        print(f"   {i:2d}. {fpath} → {len(prompts)} promptów: {', '.join(prompts[:3])}...")
    
    # Podsumowanie promptów bez linków
    prompts_without_links = []
    for prompt_file in prompt_files:
        linked = extract_linked_rego_files(prompt_file)
        if not linked:
            prompts_without_links.append(prompt_file.name)
    
    if prompts_without_links:
        print(f"\n⚠️  Promptów BEZ linków do .rego: {len(prompts_without_links)}")
        for p in prompts_without_links:
            print(f"   - {p}")
    
    print("\n" + "=" * 70)
    if len(uncovered) == 0:
        print("🎉 SUKCES! 100% plików .rego jest pokrytych w promptach!")
    else:
        print(f"⚠️  BRAKUJE {len(uncovered)} plików. Potrzebna korekta.")
    print("=" * 70)
    
    return len(uncovered) == 0

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
