#!/usr/bin/env python3
"""
NexusAI JDG — Walidacja statyczna testów Rego P64 (OPA CLI niedostępny w
tym środowisku — konwencja P63): nawiasy, klucze Rego↔testy 1:1, priorytety,
fail-closed (zero AUTO_POST), else-chain routera.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

JDG = Path(__file__).resolve().parent.parent
RULE = JDG / "rules" / "v3_p64_luka_sweep.rego"
TEST = JDG / "tests" / "rego" / "test_v3_p64_luka_sweep.rego"
THRESH = JDG / "rules" / "thresholds_jdg.rego"


def main() -> int:
    rule = RULE.read_text(encoding="utf-8")
    test = TEST.read_text(encoding="utf-8")
    ok = True

    # 1. Balans nawiasów
    for name, t in (("rego", rule), ("test", test)):
        if t.count("{") != t.count("}"):
            print(f"FAIL: nawiasy klamrowe {name}: {t.count('{')} vs {t.count('}')}")
            ok = False
        if t.count("(") != t.count(")"):
            print(f"FAIL: nawiasy okrągłe {name}")
            ok = False

    # 2. Priorytety I01–I12
    for n in range(1, 13):
        if f"4640{n:02d}" not in rule:
            print(f"FAIL: brak priorytetu I{n:02d}")
            ok = False

    # 3. Fail-closed
    if '"AUTO_POST"' in rule:
        print("FAIL: rega P64 zawiera AUTO_POST")
        ok = False
    for needle in ("NEEDS_ADVICE", "NO_MATCH", "v3_p64_check"):
        if needle not in rule:
            print(f"FAIL: brak {needle} w rego")
            ok = False

    # 4. Klucze ADR-002: każdy klucz v3_p64_* w rego istnieje w thresholds
    th = THRESH.read_text(encoding="utf-8")
    for k in set(re.findall(r'"(v3_p64_[a-z_]+)"', rule)):
        if k not in th:
            print(f"FAIL: klucz {k} użyty w rego, brak w thresholds")
            ok = False

    # 5. Klucze Rego↔testy 1:1 (konteksty I01_..–I12_..)
    rule_keys = set(re.findall(r'"(I\d{2}_[a-z_]+)"', rule))
    test_keys = set(re.findall(r'"(I\d{2}_[a-z_]+)"', test))
    missing_in_test = rule_keys - test_keys
    missing_in_rule = test_keys - rule_keys
    if missing_in_test:
        print(f"FAIL: klucze rego bez testów: {sorted(missing_in_test)}")
        ok = False
    if missing_in_rule:
        print(f"FAIL: klucze testów bez rego: {sorted(missing_in_rule)}")
        ok = False

    # 6. Testy: każdy test_* ma asercję decision/rule_id
    n_tests = len(re.findall(r"^test_\w+", test, re.M))
    n_blocks = test.count("decide :=")
    if n_tests < 17 or n_blocks < n_tests:
        print(f"FAIL: testy={n_tests}, bloków decide={n_blocks}")
        ok = False

    # 7. Else-chain routera: kolejność BLOCK → NEEDS_ADVICE → PASS
    i_block = rule.index('i01_register.decision == "BLOCK"')
    i_advice = rule.index('i03_blindspots.decision == "NEEDS_ADVICE"')
    i_pass = rule.index("all_green_pass {")
    if not (i_block < i_advice < i_pass):
        print("FAIL: kolejność else-chain routera")
        ok = False

    print("P64-REGO-STATIC:", "PASS" if ok else "FAIL",
          f"(testy={n_tests}, klucze rego={len(rule_keys)}, klucze testów={len(test_keys)})")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
