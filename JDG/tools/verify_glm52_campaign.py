#!/usr/bin/env python3
"""Weryfikacja kompletności kampanii GLM52 (P01-P20).

Sprawdza: 20/20 promptów z markerem STATUS WDROŻONY, 20/20 raportów
z statusem WDROŻONY, unified_plan_progress.yaml 20/20 WDROZONY_100 oraz
istnienie artefaktów wymienionych w YAML (z obsługą wildcardów, adnotacji
w nawiasach i ścieżek względnych po '+').
"""
from __future__ import annotations

import pathlib
import re
import sys

import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent
PROMPTS = ROOT / "prompty_glm52"
REPORTS = ROOT / "raporty_glm52"
YAML_PATH = ROOT / "unified_plan_progress.yaml"

KNOWN_PREFIXES = ("rules/", "tools/", "docs/", "tests/", "migrations/", "bundles/")
WDROZONY = re.compile(r"WDROŻONY|WDROZONY", re.IGNORECASE)
STATUS_LINE = re.compile(r"STATUS", re.IGNORECASE)

# Token ścieżki: znaki ścieżki + kropka + znane rozszerzenie (obsługuje wildcardy)
PATH_TOKEN = re.compile(r"([A-Za-z0-9_./*\-]+/)?[A-Za-z0-9_*\-]+\.[A-Za-z0-9*]+")
KNOWN_EXTS = {"rego", "py", "md", "json", "sql", "sh", "yaml", "yml", "txt", "html"}


def extract_paths(entry: str) -> list[str]:
    """Zwraca tokeny ścieżek z wpisu artefaktu (obsługuje '+', '=', nawiasy).

    Odrzuca tokeny, które nie są ścieżkami (np. 'future.keywords.if' z adnotacji).
    """
    tokens = []
    for part in re.split(r"\s*[+=]\s*", entry):
        part = part.split("(")[0].split("=")[0].strip()
        if not part:
            continue
        for m in PATH_TOKEN.finditer(part):
            tok = m.group(0)
            ext = tok.rsplit(".", 1)[-1].rstrip("*").lower()
            if ext in KNOWN_EXTS:
                tokens.append(tok)
    return tokens


def candidate_paths(tokens: list[str], idx: int) -> list[str]:
    """Kandydaci na ścieżki JDG/ dla tokenu.

    Token z prefiksem (rules/...) używany wprost. Token bez prefiksu
    (konwencja YAML: względem rules/ LUB katalogu ostatniego tokenu
    z prefiksem, np. 'tools/' po 'tools/policy_registry_api.py').
    """
    tok = tokens[idx]
    cands = []
    if tok.startswith(KNOWN_PREFIXES):
        cands.append(tok)
    else:
        cands.append(f"rules/{tok}")
        # base = katalog ostatniego wcześniejszego tokenu z prefiksem
        base = None
        for j in range(idx - 1, -1, -1):
            if tokens[j].startswith(KNOWN_PREFIXES):
                base = str(pathlib.PurePosixPath(tokens[j]).parent)
                break
        if base:
            cands.append(f"{base}/{tok}")
    return list(dict.fromkeys(cands))


def artifact_exists(rel: str) -> bool:
    """Sprawdza istnienie artefaktu względem JDG/, obsługując wildcardy."""
    if "*" in rel:
        return len(list(ROOT.glob(rel))) > 0
    return (ROOT / rel).exists()


def check_prompts() -> list[str]:
    issues = []
    for i in range(1, 21):
        files = sorted(PROMPTS.glob(f"{i:02d}_*.txt"))
        if not files:
            issues.append(f"P{i:02d}: BRAK pliku promptu")
            continue
        lines = files[0].read_text(encoding="utf-8").splitlines()
        status_lines = [l for l in lines if STATUS_LINE.search(l)]
        if not status_lines or not any(WDROZONY.search(l) for l in status_lines):
            issues.append(f"P{i:02d}: {files[0].name} BRAK statusu WDROŻONY w linii STATUS")
    return issues


def check_reports() -> list[str]:
    issues = []
    for i in range(1, 21):
        f = REPORTS / f"raport_enterprise_P{i:02d}.txt"
        if not f.exists():
            issues.append(f"P{i:02d}: BRAK raportu")
            continue
        text = f.read_text(encoding="utf-8")
        if not WDROZONY.search(text):
            issues.append(f"P{i:02d}: raport BRAK statusu WDROŻONY")
    return issues


def check_yaml() -> tuple[list[str], int, list[str]]:
    issues: list[str] = []
    unverified: list[str] = []
    checked = 0
    d = yaml.safe_load(YAML_PATH.read_text(encoding="utf-8"))
    reports = d.get("campaign_glm52", {}).get("reports", [])
    if len(reports) != 20:
        issues.append(f"YAML: {len(reports)}/20 raportów")
    for r in reports:
        if r.get("status") != "WDROZONY_100":
            issues.append(f"YAML: {r['id']} status={r.get('status')}")
        for a in r.get("artifacts", []):
            tokens = extract_paths(a)
            for idx in range(len(tokens)):
                cands = candidate_paths(tokens, idx)
                found = any(artifact_exists(c) for c in cands)
                checked += 1
                if not found:
                    issues.append(f"YAML {r['id']}: brak artefaktu {cands[0]}")
    return issues, checked, unverified


def main() -> int:
    all_issues = []
    all_issues += [f"[PROMPTY] {i}" for i in check_prompts()]
    all_issues += [f"[RAPORTY] {i}" for i in check_reports()]
    yaml_issues, checked, unverified = check_yaml()
    all_issues += [f"[YAML] {i}" for i in yaml_issues]
    if all_issues:
        print("\n".join(all_issues))
        print(f"\nISSUES: {len(all_issues)} (artefaktów sprawdzonych: {checked})")
        return 1
    if unverified:
        print(f"OK (ale {len(unverified)} tokenów NIEZWERYFIKOWANYCH — "
              f"nie dało się rozwiązać ścieżki):")
        for u in unverified:
            print(f"  - {u}")
        return 2
    print(f"OK: 20/20 promptów WDROŻONY | 20/20 raportów WDROŻONY | "
          f"YAML 20/20 WDROZONY_100 | artefakty istnieją ({checked} sprawdzonych)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
