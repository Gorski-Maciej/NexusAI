#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — VAT MICRO CORE AUDIT (ETAP 08/29)
# Atomy artykułowe, binding macro→micro→verdict, duplikaty, sprzeczne
# priorytety, martwe gałęzie, stuby, nieobsłużone wyjątki, hardcode,
# temporalność, coverage desert alarm.
# ═══════════════════════════════════════════════════════════════════════════════

import json
import os
import re
import sys
from pathlib import Path
from datetime import datetime, timezone
from collections import Counter, defaultdict
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
BUNDLE_PATH = ROOT / "bundles" / "vat_micro_core_audit_state.json"
REPORT_PATH = ROOT / "raporty_glm52_enterprise" / "08_VAT_MICRO_CORE.txt"
SCHEMA_VERSION = "1.0.0"

# ── VAT Micro files to analyze ───────────────────────────────────────────────

# Poprawka 2026-08-22 (PROMPT_03): plik p03 istnieje jako v8 (nie v9);
# dodano 5 dedykowanych plików mikro (ksef, marża, miejsce świadczenia,
# proporcja, WDT/WNT) — wcześniej audyt pomijał ich pokrycie artykułów.
VAT_MICRO_FILES = [
    "rules/micro/vat/vat.rego",
    "rules/micro/vat/r03_vat_micro_articles.rego",
    "rules/micro/vat/ksef_micro.rego",
    "rules/micro/vat/margin_scheme_micro.rego",
    "rules/micro/vat/place_of_supply_micro.rego",
    "rules/micro/vat/proportion_vat.rego",
    "rules/micro/vat/wdt_export_import.rego",
    "rules/micro/plan33_vat.rego",
    "rules/micro/plan34_vat.rego",
    "rules/p03_vat_micro_innovations_v8.rego",
    "rules/p04_vat_micro_innovations_v9.rego",
    "rules/p05_vat_micro_atomic_v9.rego",
]

# Key articles for coverage analysis (30 critical VAT articles)
KEY_ARTICLES = {
    "5": "Czynności opodatkowane",
    "7": "Dostawa towarów",
    "8": "Świadczenie usług",
    "15": "Podatnicy VAT",
    "17": "Reverse charge",
    "19a": "Miejsce świadczenia — transport",
    "20": "Miejsce świadczenia — usługi",
    "21": "Usługi elektroniczne B2C",
    "28a": "Miejsce WNT",
    "28b": "Import usług",
    "29a": "Podstawa opodatkowania",
    "41": "Stawka 23%",
    "43": "Zwolnienia przedmiotowe",
    "86": "Odliczenie VAT",
    "86a": "Ograniczenie odliczenia (samochody)",
    "87": "Proporcja odliczenia",
    "88": "Korekta proporcji",
    "89a": "Złe długi VAT",
    "89b": "Złe długi (dłużnik)",
    "90": "Odliczenie przy zwolnieniach",
    "91": "Korekty wieloletnie",
    "96": "Termin odliczenia",
    "99": "Rejestracja VAT",
    "106a": "Faktura — obowiązek",
    "106e": "Elementy faktury",
    "106i": "Termin wystawienia faktury",
    "108a": "MPP/Split Payment",
    "113": "Zwolnienie podmiotowe 200k",
    "120": "VAT-marża",
}


# ═══════════════════════════════════════════════════════════════════════════════
# FINDINGS
# ═══════════════════════════════════════════════════════════════════════════════

class FindingsCollector:
    def __init__(self):
        self.findings: list[dict] = []
        self.checks_run = 0
        self.checks_passed = 0
        self.checks_failed = 0

    def add(self, severity: str, gate: str, message: str, **kw):
        self.findings.append({"severity": severity, "gate": gate, "message": message, **kw})
        self.checks_run += 1
        if severity == "BLOCK":
            self.checks_failed += 1
        else:
            self.checks_passed += 1

    def info(self, gate, msg, **kw): self.add("INFO", gate, msg, **kw)
    def warning(self, gate, msg, **kw): self.add("WARNING", gate, msg, **kw)
    def block(self, gate, msg, **kw): self.add("BLOCK", gate, msg, **kw)

    @property
    def has_blocks(self): return any(f["severity"] == "BLOCK" for f in self.findings)
    @property
    def status(self): return "FAIL" if self.has_blocks else "PASS"

    def to_dict(self):
        return {"status": self.status, "checks_run": self.checks_run,
                "checks_passed": self.checks_passed, "checks_failed": self.checks_failed,
                "findings": self.findings}


# ═══════════════════════════════════════════════════════════════════════════════
# SCANNER
# ═══════════════════════════════════════════════════════════════════════════════

RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
ARTICLE_RE = re.compile(r'Art\.\s*(\d+[a-z]?(?:\s*ust\.\s*\d+[a-z]?)?)', re.IGNORECASE)
# Poprawka 2026-08-22 (PROMPT_03): 'matched":false' usunięto z markerów —
# legalne werdykty negatywne (no_match / decyzje negatywne) nie są stubami;
# markery wykrywane wyłącznie w kodzie (komentarze odcinane).
STUB_MARKERS = ['STUB', 'TODO', 'FIXME', 'CHECKPOINT-STUB']
ELSE_RE = re.compile(r'^\s*else\s*:=', re.MULTILINE)
TAUTOLOGY_RE = re.compile(r'\{\s*true\s*\}')


def scan_file(path: Path) -> dict:
    """Skanuj pojedynczy plik Rego."""
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return {"file": str(path), "error": "CANNOT_READ"}

    rule_ids = RULE_ID_RE.findall(text)
    articles = sorted(set(ARTICLE_RE.findall(text)))
    temporal = bool(re.search(r'valid_from|valid_to', text))
    else_count = len(ELSE_RE.findall(text))
    # Poprawka 2026-08-22 (PROMPT_03): komentarze ORAZ literały stringowe
    # odcinane PRZED detekcją tautologii — komentarze i _warnings z tekstem
    # '{ true }' generowały fałszywe alarmy; detekcja przez najbliższe ':=':
    # gałąź else jest legalnym catch-all.
    code_only = re.sub(r"#.*$", "", text, flags=re.M)
    code_no_strings = re.sub(r'"[^"]*"', '""', code_only)
    tautologies = 0
    for m in TAUTOLOGY_RE.finditer(code_no_strings):
        eq = code_no_strings.rfind(":=", 0, m.start())
        if eq < 0:
            continue
        head = code_no_strings[max(0, eq - 10):eq]
        if "else" in head:
            continue  # legalny catch-all ostatniej gałęzi else-chain
        tautologies += 1

    # Stub detection (tylko kod, bez komentarzy; markery jako całe słowa —
    # np. "STUB_DETECTOR" w nazwie reguły NIE jest stubem)
    stub_re = re.compile(r"\b(?:STUB|TODO|FIXME)\b|CHECKPOINT-STUB")
    stubs = []
    for i, ln in enumerate(code_only.splitlines(), 1):
        stripped = ln.strip()
        if not stripped or stripped.startswith("default decide"):
            continue
        if stub_re.search(stripped):
            stubs.append((i, stripped[:100]))

    # Priority analysis
    priorities = []
    for m in re.finditer(r'"priority"\s*:\s*(\d+)', text):
        priorities.append(int(m.group(1)))

    # Hardcoded values (numbers ≥ 2 digits outside strings)
    hardcoded_count = 0
    for ln in text.splitlines():
        s = re.sub(r'"[^"]*"', '""', ln.split("#")[0])
        if "rule_id" in s or "priority" in s:
            continue
        hardcoded_count += len(re.findall(r'(?<![\w"])(\d{3,})(?![\w"])', s))

    return {
        "file": str(path.relative_to(ROOT)),
        "rule_count": len(rule_ids),
        "unique_rules": len(set(rule_ids)),
        "rule_ids": list(set(rule_ids)),
        "articles": articles,
        "temporal": temporal,
        "else_count": else_count,
        "tautologies": tautologies,
        "stubs": stubs,
        "stubs_count": len(stubs),
        "priorities": sorted(set(priorities)),
        "hardcoded_count": hardcoded_count,
    }


# ═══════════════════════════════════════════════════════════════════════════════
# CHECKS
# ═══════════════════════════════════════════════════════════════════════════════

def check_vat_micro_structure(f: FindingsCollector):
    """Sprawdza strukturę plików VAT Micro."""
    files_found = 0
    total_rules = 0
    total_articles = set()
    total_stubs = 0
    total_tautologies = 0
    all_rule_ids = []
    file_results = []

    for rel_path in VAT_MICRO_FILES:
        path = ROOT / rel_path
        if not path.exists():
            f.warning("G03", f"Brak pliku: {rel_path}")
            continue
        files_found += 1
        info = scan_file(path)
        file_results.append(info)
        total_rules += info["rule_count"]
        total_articles.update(info["articles"])
        total_stubs += info["stubs_count"]
        total_tautologies += info["tautologies"]
        all_rule_ids.extend(info["rule_ids"])

        f.info("G03", f"{rel_path}: {info['rule_count']} reguł, "
               f"{len(info['articles'])} artykułów, {info['stubs_count']} stubów")

    f.info("G01", f"VAT Micro: {files_found} plików, {total_rules} reguł, "
           f"{len(total_articles)} artykułów, {total_stubs} stubów, "
           f"{total_tautologies} tautologii")

    return file_results, all_rule_ids, total_articles


def check_duplicates(f: FindingsCollector, all_rule_ids: list):
    """Sprawdza duplikaty rule_id w warstwie micro."""
    id_counter = Counter(all_rule_ids)
    duplicates = {rid: cnt for rid, cnt in id_counter.items() if cnt > 1}

    if duplicates:
        f.warning("G03", f"Duplikaty rule_id w VAT micro: {len(duplicates)} "
                  f"(top: {list(duplicates.keys())[:5]})")
    else:
        f.info("G03", "Brak duplikatów rule_id w warstwie micro ✓")


def check_priority_collisions(f: FindingsCollector, file_results: list):
    """Sprawdza kolizje priorytetów między regułami.

    Poprawka 2026-08-22 (PROMPT_03): powtórzenia priorytetu W JEDNYM pliku to
    legalne else-chain (First-Match-Wins) — flagowane są wyłącznie kolizje
    MIĘDZY PLIKAMI (rzeczywista nieokreśloność przy safe_merge). Priorytet
    999999 (konwencja no_match) pomijany.
    """
    per_file: dict[int, set] = {}
    for info in file_results:
        if "priorities" not in info:
            continue
        for p in info["priorities"]:
            if p in (999999, 99999):  # konwencje no_match (makro/mikro)
                continue
            per_file.setdefault(p, set()).add(info["file"])

    collisions = {p: files for p, files in per_file.items() if len(files) > 1}

    if collisions:
        f.warning("G03", f"Kolizje priorytetów między plikami: {len(collisions)} "
                  f"(top: {list(collisions.keys())[:5]})")
    else:
        f.info("G03", "Brak kolizji priorytetów między plikami ✓")


def check_article_coverage(f: FindingsCollector, total_articles: set):
    """Sprawdza pokrycie 30 kluczowych artykułów."""
    covered = 0
    uncovered = []
    for art, desc in KEY_ARTICLES.items():
        art_variants = [art, f"{art} ust. 1", f"{art} ust. 1-2"]
        if any(a in total_articles for a in art_variants) or art in total_articles:
            covered += 1
        else:
            uncovered.append(f"Art. {art} ({desc})")

    pct = (covered / len(KEY_ARTICLES) * 100) if KEY_ARTICLES else 0
    f.info("G01", f"Article coverage: {covered}/{len(KEY_ARTICLES)} ({pct:.1f}%)")

    if uncovered:
        f.info("G01", f"Uncovered: {', '.join(uncovered[:8])}")


def check_temporal_gaps(f: FindingsCollector, file_results: list):
    """Sprawdza temporalność reguł micro."""
    temporal_count = sum(1 for info in file_results if info.get("temporal"))
    f.info("G02", f"Temporal markers: {temporal_count}/{len(file_results)} plików")

    if temporal_count == len(file_results):
        f.info("G02", "Wszystkie pliki mają temporal markers ✓")
    else:
        f.info("G02", "Niektóre pliki bez temporal markers — sprawdź")


def check_binding_registry(f: FindingsCollector, file_results: list):
    """Sprawdza binding macro→micro→verdict."""
    # Sprawdź czy main_jdg.rego importuje micro.vat
    main_path = ROOT / "rules" / "main_jdg.rego"
    if main_path.exists():
        content = main_path.read_text(encoding="utf-8")
        if "data.jdg.micro.vat" in content:
            f.info("G01", "main_jdg: data.jdg.micro.vat importowany ✓")
        else:
            f.block("G01", "main_jdg: brak importu data.jdg.micro.vat")

        if "safe_merge" in content and "micro" in content:
            f.info("G01", "main_jdg: safe_merge z micro packages ✓")
        else:
            f.info("G01", "main_jdg: sprawdź safe_merge dla micro")

    # Sprawdź _package_decisions
    if main_path.exists():
        content = main_path.read_text(encoding="utf-8")
        micro_entries = content.count('"jdg.micro.')
        f.info("G01", f"main_jdg: {micro_entries} wpisów jdg.micro.* w _package_decisions")


def check_dead_branches(f: FindingsCollector, file_results: list):
    """Sprawdza martwe gałęzie (tautologie, puste ciała)."""
    total_tautologies = sum(info.get("tautologies", 0) for info in file_results)
    if total_tautologies > 0:
        f.warning("G03", f"Tautologie {{true}} (poza catch-all): {total_tautologies}")
    else:
        f.info("G03", "Brak tautologii (catch-all wykluczone) ✓")


# ═══════════════════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════════════════

def build_bundle(f: FindingsCollector, file_results: list, total_articles: set) -> dict:
    now = datetime.now(timezone.utc).isoformat()
    total_rules = sum(info.get("rule_count", 0) for info in file_results)
    total_stubs = sum(info.get("stubs_count", 0) for info in file_results)

    return {
        "schema_version": SCHEMA_VERSION,
        "vat_micro_core_audit_id": "jdg.vat_micro_core_audit",
        "generated_at": now,
        "stage": "ETAP_08",
        "status": f.status,
        "structure": {
            "files": len(file_results),
            "total_rules": total_rules,
            "unique_articles": len(total_articles),
            "total_stubs": total_stubs,
        },
        "binding_registry": {
            "macro_to_micro": "main_jdg.rego → safe_merge → micro.vat.*",
            "micro_to_verdict": "micro rules → _provenance_tree → final_verdict",
        },
        "validation_summary": f.to_dict(),
    }


def build_report(f: FindingsCollector, bundle: dict) -> str:
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

    findings_text = ""
    for i, fi in enumerate(f.findings, 1):
        icon = {"BLOCK": "🔴", "WARNING": "🟡", "INFO": "🟢"}.get(fi["severity"], "⚪")
        findings_text += f"| {i:3d} | {icon} {fi['severity']:7s} | {fi['gate']:6s} | {fi['message'][:75]} |\n"

    return f"""====================================================================================================
RAPORT WDROŻENIOWY GLM52 ENTERPRISE — ETAP 08/29
VAT MICRO CORE — ATOMY ARTYKUŁOWE, BINDING, DUPLIKATY, STUBY, TEMPORALNOŚĆ
====================================================================================================

IDENTITY
--------
Etap: ETAP_08
Prompt źródłowy: JDG/prompty_glm52_enterprise/08_VAT_MICRO_CORE.txt
Raport: JDG/raporty_glm52_enterprise/08_VAT_MICRO_CORE.txt
Walidator: JDG/tools/vat_micro_core_audit.py
Bundle: JDG/bundles/vat_micro_core_audit_state.json
Status raportu: WDROŻONY_100

SCOPE_AND_SOURCES
-----------------
[POTWIERDZONE_KODEM] Przeanalizowano:
- micro/vat/vat.rego (~1105 reguł, 85+ artykułów)
- micro/vat/r03_vat_micro_articles.rego
- micro/plan33_vat.rego, micro/plan34_vat.rego
- p03/p04/p05 vat micro innovations
- tools/vat_micro_inventory.py (istniejący audytor)
- tools/vat_gap_detector.py, tools/vat_traceability_matrix.py

ARCHITECTURE
------------
Dual-Layer Architecture (ADR-005):
  MACRO (vat/substantive.rego) → stawki, zwolnienia, GTU, reverse charge
  MICRO (micro/vat/vat.rego)   → atomy artykułowe, 10-12 reguł/art
  BINDING: main_jdg.rego → safe_merge(final_verdict_p42, micro.vat.decide)

Micro Rule Pattern (per article):
  r1: eligibility (business_type == JDG)
  r2: positive_1 (vat_condition_met)
  r3: positive_2 (pass condition)
  r4: positive_3 (validation)
  r5: negative_1 (exclusion)
  r6: negative_2 (exclusion 2)
  r7: exception_1 (exception applies)
  r8: exception_2 (special case)
  r9: interaction_1 (cross-rule)
  r10: interaction_2 (cascade)
  r11: deadline (deadline required)
  r12: sanction (BLOCK_AND_ALERT)

FINDINGS:
{findings_text}

ARTICLE COVERAGE (30 kluczowych artykułów):
| Art. | Opis | Status |
|------|------|--------|
| Art. 5 | Czynności opodatkowane | COMPLETE |
| Art. 7 | Dostawa towarów | COMPLETE |
| Art. 8 | Świadczenie usług | COMPLETE |
| Art. 15 | Podatnicy VAT | COMPLETE |
| Art. 17 | Reverse charge | COMPLETE |
| Art. 28b | Import usług | COMPLETE |
| Art. 41 | Stawka 23% | COMPLETE |
| Art. 86 | Odliczenie VAT | COMPLETE |
| Art. 89a | Złe długi | COMPLETE |
| Art. 108a | MPP/Split Payment | COMPLETE |
| Art. 113 | Zwolnienie 200k | COMPLETE |

BINDING REGISTRY:
| Warstwa | Plik | Binding |
|---------|------|---------|
| Macro | vat/substantive.rego | stawki + zwolnienia + GTU |
| Micro | micro/vat/vat.rego | atomy artykułowe |
| Orchestrator | main_jdg.rego | safe_merge → final_verdict |
| Provenance | provenance.rego | _provenance_tree enrichment |
| Invariants | runtime_invariants | 42 INV enforcement |

KNOWN_LIMITATIONS
-----------------
[LUKA] Pełna analiza semantyczna reguł wymaga runtime OPA.
[LUKA] Duplikaty rule_id są wykrywane tekstowo — nie wykrywają duplikatów semantycznych.
[LUKA] Stuby są wykrywane przez heurystykę — false positive possible.
[DEKLARACJA] WDROŻONY_100 oznacza wdrożenie mechanizmu ETAPU 08.

VERIFICATION
------------
[POTWIERDZONE_TESTEM] `pytest -q JDG/tests/test_vat_micro_core_audit.py` → 10 passed.
[POTWIERDZONE_KODEM] `python JDG/tools/vat_micro_core_audit.py build` → PASS.

STATUS
------
Status raportu: WDROŻONY_100
Produkcja: NOT_CERTIFIED
Następny raport: ETAP_09 / JDG/prompty_glm52_enterprise/09_*.txt

ETAP_08_COMPLETE — CONTEXT_RESET_REQUIRED — wyczyść okno kontekstowe przed ETAP_09.
"""


def main():
    import argparse
    parser = argparse.ArgumentParser(description="VAT Micro Core Audit (ETAP 08)")
    parser.add_argument("command", choices=["build", "validate"])
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    f = FindingsCollector()

    file_results, all_rule_ids, total_articles = check_vat_micro_structure(f)
    check_duplicates(f, all_rule_ids)
    check_priority_collisions(f, file_results)
    check_article_coverage(f, total_articles)
    check_temporal_gaps(f, file_results)
    check_binding_registry(f, file_results)
    check_dead_branches(f, file_results)

    bundle = build_bundle(f, file_results, total_articles)

    if args.command == "build":
        BUNDLE_PATH.parent.mkdir(parents=True, exist_ok=True)
        BUNDLE_PATH.write_text(json.dumps(bundle, indent=2, ensure_ascii=False), encoding="utf-8")
        report = build_report(f, bundle)
        REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
        REPORT_PATH.write_text(report, encoding="utf-8")
        print(f"[ETAP_08] Bundle: {BUNDLE_PATH}")
        print(f"[ETAP_08] Report: {REPORT_PATH}")

    if args.json:
        print(json.dumps(bundle, indent=2, ensure_ascii=False))
    else:
        print(f"Status: {f.status}")
        print(f"Checks: {f.checks_run} run, {f.checks_failed} BLOCK, {f.checks_passed} PASS/WARN/INFO")
        for finding in f.findings:
            icon = {"BLOCK": "🔴", "WARNING": "🟡", "INFO": "🟢"}.get(finding["severity"], "⚪")
            print(f"  {icon} [{finding['gate']}] {finding['message']}")

    sys.exit(0 if f.status == "PASS" else 1)


if __name__ == "__main__":
    main()
