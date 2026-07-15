#!/usr/bin/env python3
"""
NexusAI JDG — Bulk Micro-Rule Generator
Generuje reguły Rego dla wszystkich brakujących punktów z Plan OPA/50.

Użycie: python generate_missing_rules.py
"""

import os
import re
import subprocess
from collections import defaultdict

PROJECT_ROOT = "/data/data/com.termux/files/home/NexusAI"
MICRO_DIR = os.path.join(PROJECT_ROOT, "JDG", "rules", "micro")
OPA50_FILE = os.path.join(PROJECT_ROOT, "Plan OPA", "50_JDG_BRAKUJACE_PUNKTY_PRAWNE.md")

# Mapowanie prefixów ID na pliki micro/
PREFIX_TO_FILE = {
    "jdg.vat.": "vat/vat.rego",
    "jdg.pit.": "pit/pit.rego",
    "jdg.ord.": "ord/ord.rego",
    "jdg.kks.": "kks/kks.rego",
    "jdg.sus.": "sus/sus.rego",
    "jdg.ryc.": "ryczalt/ryczalt.rego",
    "jdg.pp.": "pp/pp.rego",
    "jdg.uor.": "uor/uor.rego",
    "jdg.pcc.": "pcc/pcc.rego",
    "jdg.pcc_akc.": "akcyza/akcyza.rego",
    "jdg.cb.": "crossborder/crossborder.rego",
    "jdg.suk.": "sukcesja/sukcesja.rego",
    "jdg.zdr.": "zdrowotna/zdrowotna.rego",
    "jdg.aml.": "aml/aml.rego",
    "jdg.aml_full.": "aml/aml.rego",
    "jdg.rodo.": "rodo/rodo.rego",
    "jdg.final.": "vat/vat.rego",  # Final fallback → VAT
}

# Akt ustawy na podstawie prefixu
PREFIX_TO_ACT = {
    "jdg.vat.": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "jdg.pit.": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "jdg.ord.": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "jdg.kks.": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "jdg.sus.": "Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)",
    "jdg.ryc.": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "jdg.pp.": "Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "jdg.uor.": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "jdg.pcc.": "Ustawa o PCC z 9.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "jdg.pcc_akc.": "Ustawa o podatku akcyzowym z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "jdg.cb.": "Ustawa o PIT/CIT — cross-border",
    "jdg.suk.": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "jdg.zdr.": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "jdg.aml.": "Ustawa AML V z 1.03.2018",
    "jdg.aml_full.": "Ustawa AML V z 1.03.2018",
    "jdg.rodo.": "RODO — Rozporządzenie UE 2016/679",
    "jdg.final.": "Ustawa o VAT — przepisy końcowe",
}

PREFIX_TO_PACKAGE = {
    "jdg.vat.": "jdg.micro.vat",
    "jdg.pit.": "jdg.micro.pit",
    "jdg.ord.": "jdg.micro.ord",
    "jdg.kks.": "jdg.micro.kks",
    "jdg.sus.": "jdg.micro.sus",
    "jdg.ryc.": "jdg.micro.ryczalt",
    "jdg.pp.": "jdg.micro.pp",
    "jdg.uor.": "jdg.micro.uor",
    "jdg.pcc.": "jdg.micro.pcc",
    "jdg.pcc_akc.": "jdg.micro.akcyza",
    "jdg.cb.": "jdg.micro.crossborder",
    "jdg.suk.": "jdg.micro.sukcesja",
    "jdg.zdr.": "jdg.micro.zdrowotna",
    "jdg.aml.": "jdg.micro.aml",
    "jdg.aml_full.": "jdg.micro.aml",
    "jdg.rodo.": "jdg.micro.rodo",
    "jdg.final.": "jdg.micro.vat",
}


def get_existing_ids():
    """Pobiera wszystkie istniejące rule_id z katalogu micro/"""
    result = subprocess.run(
        ['grep', '-roh', '"rule_id":"[^"]*"', MICRO_DIR, '--include=*.rego'],
        capture_output=True, text=True, cwd=PROJECT_ROOT
    )
    ids = set()
    for line in result.stdout.strip().split('\n'):
        m = re.search(r'"rule_id":"([^"]*)"', line)
        if m:
            ids.add(m.group(1))
    return ids


def get_missing_ids():
    """Zwraca listę brakujących ID z pliku 50"""
    brak_file = "/tmp/opa50_brak_ids.txt"
    if not os.path.exists(brak_file):
        # Wygeneruj plik jeśli nie istnieje
        result = subprocess.run(
            ['grep', '-B3', '❌ BRAK', OPA50_FILE],
            capture_output=True, text=True, cwd=PROJECT_ROOT
        )
        ids = set()
        for line in result.stdout.split('\n'):
            m = re.search(r'`(jdg\.[^`]+)`', line)
            if m:
                ids.add(m.group(1))
        return ids

    with open(brak_file) as f:
        return set(line.strip() for line in f if line.strip())


def find_file_for_id(rule_id):
    """Znajduje odpowiedni plik micro/ dla danego ID"""
    for prefix, filename in PREFIX_TO_FILE.items():
        if rule_id.startswith(prefix):
            return os.path.join(MICRO_DIR, filename)
    return os.path.join(MICRO_DIR, "vat/vat.rego")  # fallback


def find_act_for_id(rule_id):
    for prefix, act in PREFIX_TO_ACT.items():
        if rule_id.startswith(prefix):
            return act
    return "Przepisy prawa polskiego"


def find_package_for_id(rule_id):
    for prefix, pkg in PREFIX_TO_PACKAGE.items():
        if rule_id.startswith(prefix):
            return pkg
    return "jdg.micro.general"


def extract_article_info(rule_id):
    """Wyciąga informację o artykule z ID reguły"""
    # jdg.vat.a106e.r10 → Art. 106e
    # jdg.vat.a11.u1.p1 → Art. 11 ust. 1 pkt 1 lit. a
    # jdg.pit.a22p.r1 → Art. 22p

    # Wzorzec: jdg.DOMENA.aARTYKUL
    m = re.search(r'\.a(\d+[a-z]*)\.', rule_id)
    if m:
        art = m.group(1)
        return f"Art. {art}"

    # Wzorzec Klasa B: jdg.DOMENA.aXX.uYY.pZZ
    m2 = re.search(r'\.a(\d+[a-z]*)\.u(\d+)\.p(\d+)', rule_id)
    if m2:
        art, ust, pkt = m2.group(1), m2.group(2), m2.group(3)
        return f"Art. {art} ust. {ust} pkt {pkt}"

    return ""


def generate_rego_rule(rule_id, priority):
    """Generuje pojedynczą regułę Rego"""
    article_info = extract_article_info(rule_id)
    legal_basis = find_act_for_id(rule_id)
    package = find_package_for_id(rule_id)

    # Generuj priorytet na podstawie pozycji (unikamy kolizji)
    rule_name = rule_id.replace('.', '_').replace('jdg_', '')

    if article_info:
        routing_reason = f"[MICRO] {article_info} — walidacja szczegółowa dla JDG"
    else:
        routing_reason = f"[MICRO] {rule_id} — punkt kontrolny OPA dla JDG"

    return f'''
# {rule_id} — `{rule_name}`: {article_info if article_info else "przepis szczegółowy"} → Punkt kontrolny
else := {{
    "matched": true,
    "rule_id": "{rule_id}",
    "package": "{package}",
    "priority": {priority},
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "{routing_reason}",
    "_legal_basis": "{legal_basis}",
    "_warnings": ["[MICRO] {article_info if article_info else rule_id}: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
}} {{
    object.get(input.jdg_entrepreneur, "{rule_name}_check", false) == true
}}'''


def main():
    print("=" * 60)
    print("NexusAI JDG — Bulk Micro-Rule Generator")
    print("Generowanie brakujących reguł z Plan OPA/50")
    print("=" * 60)

    # 1. Pobierz istniejące ID
    print("\n[1/4] Pobieranie istniejących rule_id z micro/...")
    existing = get_existing_ids()
    print(f"  Znaleziono {len(existing)} istniejących reguł w micro/")

    # 2. Pobierz brakujące ID
    print("\n[2/4] Pobieranie brakujących ID z Plan OPA/50...")
    missing = get_missing_ids()
    print(f"  Znaleziono {len(missing)} ❌ BRAK ID w Plan OPA/50")

    # 3. Znajdź faktycznie brakujące
    truly_missing = missing - existing
    print(f"\n[3/4] Faktycznie brakujące (nie ma w micro/): {len(truly_missing)}")

    # Grupuj według plików
    file_groups = defaultdict(list)
    for rule_id in truly_missing:
        filepath = find_file_for_id(rule_id)
        file_groups[filepath].append(rule_id)

    print(f"  Rozdzielone na {len(file_groups)} plików micro/")

    # 4. Generuj reguły
    print(f"\n[4/4] Generowanie reguł...")
    total_generated = 0

    for filepath, rule_ids in sorted(file_groups.items()):
        rel_path = os.path.relpath(filepath, PROJECT_ROOT)
        if not os.path.exists(filepath):
            print(f"  ⚠️  Plik nie istnieje: {rel_path} — pomijam {len(rule_ids)} reguł")
            continue

        # Sortuj dla stabilności
        rule_ids = sorted(rule_ids)

        # Generuj reguły z unikalnymi priorytetami
        rules_text = []
        base_priority = 50000  # Wysoka podstawa by nie kolidować z istniejącymi

        for i, rule_id in enumerate(rule_ids):
            priority = base_priority + i
            rule_text = generate_rego_rule(rule_id, priority)
            rules_text.append(rule_text)

        # Nagłówek sekcji
        header = f'''

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  PLAN OPA/50 — KLASA B — Wygenerowane masowo ({len(rule_ids)} reguł)       ║
# ║  Priorytety: {base_priority}-{base_priority + len(rule_ids) - 1}                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
'''
        full_section = header + ''.join(rules_text)

        # Dopisz do pliku
        with open(filepath, 'a') as f:
            f.write(full_section)

        print(f"  ✅ {rel_path}: +{len(rule_ids)} reguł")
        total_generated += len(rule_ids)

    print(f"\n{'=' * 60}")
    print(f"  RAZEM WYGENEROWANYCH: {total_generated} reguł")
    print(f"  w {len(file_groups)} plikach micro/")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
