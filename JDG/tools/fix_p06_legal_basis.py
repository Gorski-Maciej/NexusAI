#!/usr/bin/env python3
"""P06 Batch Fix: Fill empty _legal_basis in plan34_pit.rego (265 rules).

Maps each rule_id prefix to the correct Art. XX PIT legal basis.
Run: python JDG/tools/fix_p06_legal_basis.py
"""

import re
import sys

LEGAL_BASIS_MAP = {
    "p580": "Art. 21 ust. 1 pkt 148 PIT — Ulga dla młodych (do 26 lat)",
    "p582": "Art. 21 ust. 1 pkt 152 PIT — Ulga na powrót",
    "p584": "Art. 21 ust. 1 pkt 153 PIT — Ulga 4+",
    "p586": "Art. 21 ust. 1 pkt 154 PIT — Ulga dla pracujących seniorów",
    "p0limit": "Art. 21 ust. 1 pkt 148-154 PIT — Wspólny limit 85 528 PLN",
    "a9a": "Art. 9a PIT — Formy opodatkowania",
    "a10": "Art. 10 PIT — Źródła przychodów",
    "a14": "Art. 14 PIT — Przychody z działalności gospodarczej",
    "a14c": "Art. 14c PIT — Różnice kursowe",
    "a22a": "Art. 22a PIT — Środki trwałe, wartości niematerialne i prawne",
    "a22d": "Art. 22d PIT — Metody amortyzacji (liniowa, degresywna)",
    "a22e": "Art. 22e PIT — Mała wartość (jednorazowa amortyzacja)",
    "a22f": "Art. 22f PIT — Używane środki trwałe",
    "a22g": "Art. 22g PIT — Budynki, budowle, maszyny (stawki amortyzacji)",
    "a22i": "Art. 22i PIT — Moment rozpoczęcia/zakończenia amortyzacji",
    "a22j": "Art. 22j PIT — Ulepszenia środków trwałych",
    "a22k": "Art. 22k PIT — Sprzedaż i likwidacja środków trwałych",
    "a22l": "Art. 22l PIT — Wartości niematerialne i prawne",
    "a22m": "Art. 22m PIT — Samochody osobowe (limit 150k/225k)",
    "a22": "Art. 22 PIT — Koszty uzyskania przychodów",
    "a23": "Art. 23 PIT — Wydatki nieuznawane za koszty uzyskania przychodów (NKUP)",
    "a24": "Art. 24 PIT — Dochód",
    "a26b": "Art. 26b PIT — Ulga B+R (koszty kwalifikowane)",
    "a26e": "Art. 26e PIT — Ulga B+R (100-200% kosztów)",
    "a26eb": "Art. 26eb PIT — Ulga na prototyp (30% kosztów)",
    "a26ec": "Art. 26ec PIT — Ulga na ekspansję (do 1M PLN)",
    "a26gb": "Art. 26gb PIT — Ulga na robotyzację (50% kosztów)",
    "a26h": "Art. 26h PIT — Ulga termomodernizacyjna (do 53 000 PLN)",
    "a26ha": "Art. 26ha PIT — Ulga termomodernizacyjna (rozszerzona)",
    "a26hd": "Art. 26hd PIT — Ulga podatkowa",
    "a26i": "Art. 26i PIT — Ulga podatkowa",
    "a26": "Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)",
    "a27a": "Art. 27a PIT — Ulga na dzieci",
    "a27g": "Art. 27g PIT — Ulga podatkowa",
    "a27": "Art. 27 PIT — Skala podatkowa (12%/32%, kwota wolna 30 000 PLN)",
    "a30a": "Art. 30a PIT — Ryczałt od przychodów ewidencjonowanych",
    "a30b": "Art. 30b PIT — Ryczałt (szczegółowe przepisy)",
    "a30ca": "Art. 30ca PIT — IP Box (5% stawka dla kwalifikowanych IP)",
    "a31": "Art. 31 PIT — Przepisy zbiorcze",
    "a32": "Art. 32 PIT — Informacje i zeznania innych podmiotów",
    "a45": "Art. 45 PIT — Zeznania roczne (PIT-36, PIT-36L, PIT-28)",
}


def fix_plan34(filepath: str) -> int:
    """Replace empty _legal_basis with correct values based on rule_id prefix."""
    with open(filepath, "r") as f:
        content = f.read()

    lines = content.split("\n")
    fixed = 0
    current_prefix = None

    for i, line in enumerate(lines):
        # Detect rule_id prefix: "jdg.pit.XXX.rN"
        m = re.search(r'"rule_id":"jdg\.pit\.([a-z0-9]+)\.r\d+"', line)
        if m:
            current_prefix = m.group(1)

        # Replace empty _legal_basis (may be on same line as rule_id or next line)
        if '"_legal_basis":""' in line and current_prefix and current_prefix in LEGAL_BASIS_MAP:
            basis = LEGAL_BASIS_MAP[current_prefix]
            lines[i] = line.replace('"_legal_basis":""', f'"_legal_basis":"{basis}"')
            fixed += 1

    with open(filepath, "w") as f:
        f.write("\n".join(lines))

    return fixed


def fix_pit_rate(filepath: str) -> int:
    """Add pit_rate values to pit.rego based on article prefix."""
    with open(filepath, "r") as f:
        content = f.read()

    lines = content.split("\n")
    fixed = 0
    current_prefix = None

    # Map article prefixes to tax rates
    rate_map = {
        "a27": '12%',    # Skala — domyślnie 12% (32% w bracket)
        "a30c": '19%',   # Liniowy
        "a30ca": '5%',   # IP Box
        "a30da": '19%',  # Exit Tax
    }

    for i, line in enumerate(lines):
        # Detect rule_id for micro PIT (handles both compact and spaced JSON formats)
        m = re.search(r'"rule_id"\s*:\s*"jdg\.micro\.pit\.(a\d+[a-z]*)\.r\d+"', line)
        if m:
            current_prefix = m.group(1)

        if current_prefix and current_prefix in rate_map:
            if '"pit_rate": ""' in line:
                lines[i] = line.replace('"pit_rate": ""', f'"pit_rate": "{rate_map[current_prefix]}"')
                fixed += 1
            elif '"pit_rate":""' in line:
                lines[i] = line.replace('"pit_rate":""', f'"pit_rate":"{rate_map[current_prefix]}"')
                fixed += 1

    with open(filepath, "w") as f:
        f.write("\n".join(lines))

    return fixed


if __name__ == "__main__":
    plan34_path = "JDG/rules/micro/plan34_pit.rego"
    print(f"Fixing _legal_basis in {plan34_path}...")
    n = fix_plan34(plan34_path)
    print(f"✅ Fixed {n} empty _legal_basis entries in plan34_pit.rego")

    pit_path = "JDG/rules/micro/pit/pit.rego"
    print(f"\nAdding pit_rate in {pit_path}...")
    m = fix_pit_rate(pit_path)
    print(f"✅ Fixed {m} empty pit_rate entries in pit.rego")

    print("\nDone! Run 'opa check' or pytest to verify.")
