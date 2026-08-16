#!/usr/bin/env python3
"""
NexusAI JDG — Rego Rules Validator (v7.0 Enterprise)
Sprawdza jakość i spójność reguł Rego w katalogu JDG/rules/.

Walidacje (9 — rozszerzone z 6):
1. Wszystkie reguły mają matched:true lub matched:false
2. Wszystkie reguły mają _legal_basis
3. Wszystkie reguły mają _routing (BLOCK_AND_ALERT, TRIAGE_QUEUE, lub "")
4. Brak zakodowanych wartości liczbowych (progi, stawki)
5. Spójność else-chain (kolejność priorytetów)
6. Unikalność rule_id
7. [v7.0] Cross-package consistency — wykrywanie konfliktów między pakietami
8. [v7.0] Dead rules detection — reguły z matched:true nigdy nieosiągalne
9. [v7.0] Priority gap detection — luki w numeracji priorytetów

Usage: python validate_rules.py [--strict] [--json]
  --strict  Traktuje ostrzeżenia jako błędy
  --json    Output w formacie JSON
"""

import json
import os
import re
import sys
from pathlib import Path
from collections import defaultdict

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"

# Wzorce do wykrywania hardcoded values
HARDCODED_PATTERNS = [
    (r'(?<!")\b\d{4,}\b(?!\s*")', "Liczba >= 1000 (możliwy próg)"),
    (r'(?<!")\b\d+\.\d{2}\b(?!\s*")', "Kwota PLN (np. 15000.00)"),
    (r'"0\.\d{2,3}"', "Stawka podatkowa (np. 0.23)"),
    (r'\b20\d{2}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])\b', "Data ISO (np. 2026-01-01)"),
]


class Violation:
    def __init__(self, file: str, line: int, rule_id: str, message: str, severity: str = "ERROR"):
        self.file = file
        self.line = line
        self.rule_id = rule_id
        self.message = message
        self.severity = severity

    def to_dict(self):
        return {
            "file": self.file, "line": self.line,
            "rule_id": self.rule_id, "message": self.message,
            "severity": self.severity
        }

    def __str__(self):
        return f"[{self.severity}] {self.file}:{self.line} ({self.rule_id}) — {self.message}"


def find_hardcoded_values(filepath: Path) -> list[Violation]:
    violations = []
    content = filepath.read_text(encoding="utf-8")
    lines = content.split("\n")
    for i, line in enumerate(lines, 1):
        if line.strip().startswith("#") or line.strip().startswith(("package ", "import ")):
            continue
        for pattern, desc in HARDCODED_PATTERNS:
            if re.search(pattern, line):
                violations.append(Violation(
                    str(filepath.relative_to(RULES_DIR)), i,
                    "—", f"Hardcoded value: {desc}", "WARNING"
                ))
                break
    return violations


def _extract_balanced_block(content: str, start: int) -> str | None:
    """Zwraca zbalansowany blok `{...}` zaczynający się od `{` na pozycji `start`.

    Reguły Rego mogą zawierać zagnieżdżone obiekty (np. ``"what_if": {...}``,
    ``"kup_limits": {...}``) — naiwny regex ``[^}]*`` ucinał obiekt na pierwszym
    zamykającym nawiasie. Ta funkcja liczy nawiasy z uwzględnieniem literałów
    łańcuchowych (z escape'ami) oraz komentarzy ``#`` (P05 GLM52 fix)."""
    brace = content.find("{", start)
    if brace == -1:
        return None
    depth = 0
    i = brace
    in_string = False
    while i < len(content):
        ch = content[i]
        if in_string:
            if ch == "\\":
                i += 2
                continue
            if ch == '"':
                in_string = False
        elif ch == '"':
            in_string = True
        elif ch == "#":
            nl = content.find("\n", i)
            if nl == -1:
                break
            i = nl
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return content[brace:i + 1]
        i += 1
    return None


def validate_rule_structure(filepath: Path) -> list[Violation]:
    violations = []
    content = filepath.read_text(encoding="utf-8")
    rel_path = str(filepath.relative_to(RULES_DIR))
    # DUPLICATE rule_id — liczone per ŁAŃCUCH reguły (decide + else-chain to JEDNA reguła).
    # Powtórzenie rule_id jest legalne tylko w gałęziach else-chain o TYM SAMYM priorytecie
    # (alternatywne warunki jednej decyzji — np. statute_of_limitations OP.04a/b/c).
    # Prawdziwy duplikat: (a) ten sam rule_id w dwóch RÓŻNYCH łańcuchach, albo
    # (b) ten sam rule_id w jednym łańcuchu z RÓŻNYMI priorytetami (martwa gałąź).
    chain_id = 0
    chain_owner = {}   # rule_id -> (numer łańcucha, set priorytetów w tym łańcuchu)
    # Deklaracje reguł pakietu stoją na wcięciu 0-2 (np. 'decide := {', 'else := {');
    # lokalne przypisania w warunkach bloków (np. 'tax_gap := ...') mają wcięcie >= 4
    # i NIE otwierają nowego łańcucha (P01 v9.x fix).
    chain_pattern = re.compile(r'^\s{0,2}(else\s+)?([a-zA-Z_][\w]*)?\s*:=')
    for i, line in enumerate(content.split("\n"), 1):
        m = chain_pattern.match(line)
        if m and not m.group(1):
            chain_id += 1  # nowa reguła (decide/override/...) — nowy łańcuch
        for rid in re.findall(r'"rule_id"\s*:\s*"([^"]+)"', line):
            prio_m = re.search(r'"priority"\s*:\s*(\d+)', line)
            prio = int(prio_m.group(1)) if prio_m else None
            if rid in chain_owner:
                own_chain, prios = chain_owner[rid]
                if own_chain != chain_id or (prio is not None and prios and prio not in prios and own_chain == chain_id and len(prios) > 0):
                    violations.append(Violation(rel_path, i, rid, "DUPLICATE rule_id!", "ERROR"))
                prios.add(prio) if prio is not None else None
            else:
                chain_owner[rid] = (chain_id, {prio} if prio is not None else set())
    # Zbalansowane dopasowanie bloków reguł (`decide := {` / `else := {`).
    # Naiwny regex [^}]* ucinał obiekt na pierwszym zamykającym nawiasie
    # (zagnieżdżone obiekty) i fałszywie raportował brak _legal_basis (P05 GLM52).
    for block_start in re.finditer(r':=\s*\{', content):
        block_text = _extract_balanced_block(content, block_start.start())
        if block_text is None:
            continue
        if not re.search(r'"matched"\s*:\s*true', block_text):
            continue
        m_rid = re.search(r'"rule_id"\s*:\s*"([^"]+)"', block_text)
        if not m_rid:
            continue
        rule_id = m_rid.group(1)
        if '"_legal_basis"' not in block_text:
            violations.append(Violation(rel_path, 0, rule_id, "Brak _legal_basis", "ERROR"))
        if '"_routing"' not in block_text:
            violations.append(Violation(rel_path, 0, rule_id, "Brak _routing", "WARNING"))
        if '"_warnings"' not in block_text:
            violations.append(Violation(rel_path, 0, rule_id, "Brak _warnings", "WARNING"))
    return violations


# ═══════════════════════════════════════════════════════════════════════════════
# NOWE WALIDACJE v7.0 Enterprise
# ═══════════════════════════════════════════════════════════════════════════════

def detect_dead_rules(all_files_data: dict) -> list[Violation]:
    """
    [v7.0] Wykrywa martwe reguły — reguły z matched:true, które są nieosiągalne
    ze względu na else-chain lub nadpisywanie przez reguły o wyższym priorytecie.
    """
    violations = []
    rule_priorities = defaultdict(list)

    for filepath, rules in all_files_data.items():
        for rule in rules:
            pkg = rule["rule_id"].split(".")[1] if "." in rule["rule_id"] else "unknown"
            rule_priorities[pkg].append(rule)

    for pkg, rules in rule_priorities.items():
        priorities = sorted(set(r["priority"] for r in rules if r["priority"] > 0))
        if len(priorities) < 2:
            continue
        # Wykryj reguły z tym samym priorytetem w tym samym pakiecie
        pkg_rules_by_priority = defaultdict(list)
        for r in rules:
            pkg_rules_by_priority[r["priority"]].append(r)
        for prio, prules in pkg_rules_by_priority.items():
            if len(prules) > 1:
                for r in prules:
                    violations.append(Violation(
                        r["file"], 0, r["rule_id"],
                        f"Potencjalnie martwa reguła — ten sam priorytet {prio} "
                        f"co {prules[0]['rule_id'] if prules[0]['rule_id'] != r['rule_id'] else prules[1]['rule_id']}",
                        "WARNING"
                    ))
    return violations


def detect_priority_gaps(all_files_data: dict) -> list[Violation]:
    """
    [v7.0] Wykrywa luki w numeracji priorytetów — duże odstępy między
    kolejnymi priorytetami w ramach pakietu.
    """
    violations = []
    rule_priorities = defaultdict(list)

    for filepath, rules in all_files_data.items():
        for rule in rules:
            pkg = rule["rule_id"].split(".")[1] if "." in rule["rule_id"] else "unknown"
            rule_priorities[pkg].append((rule["priority"], rule))

    for pkg, prio_rules in rule_priorities.items():
        priorities = sorted(set(p for p, _ in prio_rules if p > 0))
        if len(priorities) < 3:
            continue
        for i in range(1, len(priorities)):
            gap = priorities[i] - priorities[i - 1]
            if gap > 50:
                violations.append(Violation(
                    f"package:{pkg}", 0, pkg,
                    f"Priority gap {gap} między {priorities[i-1]} a {priorities[i]} — "
                    f"rozważ wypełnienie lub dokumentację luki", "INFO"
                ))
    return violations


def detect_cross_package_conflicts(all_files_data: dict) -> list[Violation]:
    """
    [v7.0] Wykrywa potencjalne konflikty między pakietami — reguły z różnych
    pakietów, które mogą wydać sprzeczne decyzje dla tych samych danych.
    """
    violations = []
    # Zbierz reguły z _routing = BLOCK_AND_ALERT
    block_rules = []
    for filepath, rules in all_files_data.items():
        for rule in rules:
            if "BLOCK" in rule.get("routing", "").upper():
                block_rules.append(rule)

    # Szukaj potencjalnych konfliktów na podstawie legal_basis
    legal_basis_groups = defaultdict(list)
    for rule in block_rules:
        basis = rule.get("legal_basis", "")
        if basis:
            # Ekstrakcja artykułu
            art_match = re.search(r'Art\.\s*(\d+[a-z]*)', basis, re.IGNORECASE)
            if art_match:
                key = f"{art_match.group(1)}_{basis.split(',')[0][:50]}"
                legal_basis_groups[key].append(rule)

    for key, rules in legal_basis_groups.items():
        if len(rules) >= 3:
            violations.append(Violation(
                rules[0]["file"], 0, rules[0]["rule_id"],
                f"Potencjalny konflikt: {len(rules)} reguł BLOCK_AND_ALERT "
                f"cytuje tę samą podstawę prawną ({key}) — zweryfikuj spójność",
                "WARNING"
            ))

    return violations


# ═══════════════════════════════════════════════════════════════════════════════
# NOWA WALIDACJA v8.0: Globalna deduplikacja rule_id (Section 6.2)
# ═══════════════════════════════════════════════════════════════════════════════

def detect_global_duplicates(all_files_data: dict) -> list[Violation]:
    """
    [v8.0] Wykrywa globalne duplikaty rule_id — ten sam rule_id w różnych plikach.
    Poprzednia walidacja sprawdzała tylko per plik; ta sprawdza globalnie.
    """
    violations = []
    id_to_files = defaultdict(list)
    
    for filepath, rules in all_files_data.items():
        for rule in rules:
            id_to_files[rule["rule_id"]].append(filepath)
    
    for rid, files in id_to_files.items():
        unique_files = set(files)
        if len(unique_files) > 1:
            violations.append(Violation(
                list(unique_files)[0], 0, rid,
                f"GLOBALNY DUPLIKAT rule_id: występuje w {len(unique_files)} plikach: "
                f"{', '.join(sorted(unique_files)[:3])}",
                "ERROR"
            ))
    
    return violations


def extract_all_rules() -> dict:
    """Ekstrahuje wszystkie reguły ze wszystkimi metadanymi."""
    all_data = {}
    for filepath in sorted(RULES_DIR.rglob("*.rego")):
        rel_path = str(filepath.relative_to(RULES_DIR))
        content = filepath.read_text(encoding="utf-8")
        rules = []
        rule_blocks = re.finditer(
            r'"matched"\s*:\s*true[^}]*"rule_id"\s*:\s*"([^"]+)"[^}]*'
            r'(?:"priority"\s*:\s*(\d+))?[^}]*'
            r'(?:"_legal_basis"\s*:\s*"([^"]*)")?[^}]*'
            r'(?:"_routing"\s*:\s*"([^"]*)")?',
            content, re.DOTALL
        )
        for block in rule_blocks:
            rule_id = block.group(1)
            priority = int(block.group(2)) if block.group(2) else 0
            legal_basis = block.group(3) or ""
            routing = block.group(4) or ""
            rules.append({
                "rule_id": rule_id, "priority": priority,
                "legal_basis": legal_basis, "routing": routing,
                "file": rel_path,
            })
        if rules:
            all_data[rel_path] = rules
    return all_data


def main():
    strict = "--strict" in sys.argv
    json_output = "--json" in sys.argv
    all_violations = []
    total_rules = 0
    total_files = 0

    # Zbierz wszystkie dane reguł (dla nowych walidacji)
    all_rules_data = extract_all_rules()
    for rules in all_rules_data.values():
        total_rules += len(rules)
    total_files = len(all_rules_data)

    # Standardowe walidacje
    for filepath in sorted(RULES_DIR.rglob("*.rego")):
        all_violations.extend(validate_rule_structure(filepath))
        all_violations.extend(find_hardcoded_values(filepath))

    # NOWE walidacje v7.0
    all_violations.extend(detect_dead_rules(all_rules_data))
    all_violations.extend(detect_priority_gaps(all_rules_data))
    all_violations.extend(detect_cross_package_conflicts(all_rules_data))

    # NOWA walidacja v8.0: globalna deduplikacja (Section 6.2)
    all_violations.extend(detect_global_duplicates(all_rules_data))

    errors = [v for v in all_violations if v.severity == "ERROR"]
    warnings = [v for v in all_violations if v.severity == "WARNING"]
    infos = [v for v in all_violations if v.severity == "INFO"]

    if json_output:
        report = {
            "status": "FAIL" if (errors or (strict and warnings)) else "PASS",
            "summary": {
                "total_files": total_files, "total_rules": total_rules,
                "errors": len(errors), "warnings": len(warnings), "info": len(infos)
            },
            "violations": [v.to_dict() for v in all_violations[:100]]
        }
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        print(f"📋 JDG Rules Validator v7.0 (Enterprise)")
        print(f"   Plików: {total_files}")
        print(f"   Reguł:  {total_rules}")
        print(f"   Błędów: {len(errors)}")
        print(f"   Ostrzeżeń: {len(warnings)}")
        print(f"   Info (priority gaps): {len(infos)}")
        print()
        if errors:
            print("🔴 BŁĘDY:")
            for v in errors:
                print(f"   {v}")
        if warnings:
            print("🟡 OSTRZEŻENIA (pierwsze 10):")
            for v in warnings[:10]:
                print(f"   {v}")
            if len(warnings) > 10:
                print(f"   ... i {len(warnings) - 10} więcej")

    exit_code = 1 if (errors or (strict and warnings)) else 0
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
