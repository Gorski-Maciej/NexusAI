#!/usr/bin/env python3
"""
NexusAI JDG — MANIFEST 2.0 (P01 Fundament Święty — Sekcja 2/8, V2 §8)
=====================================================================
Jedno autorytatywne źródło prawdy dla metryk modułu JDG (rozwiązanie luki L2:
„439 vs 383 vs 176 plików Rego", „11 452 vs 10 878 vs 10 827 rule_id",
„57 vs 98 vs 130 narzędzi"). Manifest 2.0 jest REGENEROWANY w CI z
rzeczywistej zawartości katalogów — każda rozbieżność między dokumentami
a manifestem = BLOKADA (bramka), nie alert.

Współpracuje z:
  • generate_manifest.py (v8.0) — parser strukturalny bloków reguł
  • bundles/manifest.json  — manifest bundle OPA
  • unified_plan_progress.yaml — tracker postępu

Usage:
  python manifest_v2.py                    # generuje manifest_v2.json + docs/MANIFEST_2_0.md
  python manifest_v2.py --check            # bramka CI: FAIL przy rozbieżności względem deklaracji
  python manifest_v2.py --json             # tylko JSON na stdout
  python manifest_v2.py --gate-tools N     # próg liczby narzędzi (bramka)
"""

import argparse
import hashlib
import json
import re
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"
TOOLS_DIR = JDG_ROOT / "tools"
TESTS_DIR = JDG_ROOT / "tests"
BUNDLES_DIR = JDG_ROOT / "bundles"
DOCS_DIR = JDG_ROOT / "docs"
OUT_JSON = BUNDLES_DIR / "manifest_v2.json"
OUT_MD = DOCS_DIR / "MANIFEST_2_0.md"

# Metryki deklarowane w dokumentach (źródła rozbieżności L2) — bramka porównuje
# stan faktyczny z tymi wartościami i sygnalizuje, które dokumenty są nieaktualne.
DECLARED = {
    "rego_files": {"README.md": 439, "MANIFEST.md": 383, "COVERAGE_REPORT.md": 176},
    "rule_ids": {"README.md": 11452, "bundles/manifest.json": 10878, "unified_plan_v8.yaml": 10827},
    "tools": {"README.md": 57, "OPA_JAKO_SYSTEM_P21.md": 98, "KATALOG_NARZEDZI.md": 130},
}


def rule_blocks(content: str):
    """Generator pozycji bloków reguł — spójny z parserem strukturalnym v8.0."""
    pattern = re.compile(r"(?:default\s+)?(?:else\s+)?:=\s*\{")
    for match in pattern.finditer(content):
        yield match.start()


def extract_metadata(block: str) -> dict:
    """Ekstrakcja metadanych rule_id / matched / legal_basis z bloku reguły."""
    meta = {"matched": None, "rule_id": None, "legal_basis": None}
    m = re.search(r'"matched"\s*:\s*(true|false)', block)
    if m:
        meta["matched"] = m.group(1) == "true"
    m = re.search(r'"rule_id"\s*:\s*"([^"]+)"', block)
    if m:
        meta["rule_id"] = m.group(1)
    m = re.search(r'"_?legal_basis"\s*:\s*"([^"]+)"', block)
    if m:
        meta["legal_basis"] = m.group(1)
    return meta


def is_stub_block(block: str) -> bool:
    """Detekcja stubu { true } (ADR-015: CHECKPOINT-STUB dopuszczalny tylko z adnotacją)."""
    stripped = re.sub(r"\s+", "", block)
    if re.match(r'.*\{\s*true\s*\}', stripped):
        return "CHECKPOINT-STUB" not in block
    return False


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    h.update(path.read_bytes())
    return h.hexdigest()


def scan_rules() -> dict:
    """Pełna inwentaryzacja rules/ — metryki autorytatywne MANIFEST 2.0."""
    total_files = 0
    total_blocks = 0
    matched = 0
    unique_ids = set()
    dup_counter = defaultdict(int)
    stubs = []
    files_checksum = {}
    per_file = []
    for path in sorted(RULES_DIR.rglob("*.rego")):
        total_files += 1
        files_checksum[str(path.relative_to(JDG_ROOT))] = sha256(path)
        try:
            content = path.read_text(encoding="utf-8")
        except Exception:
            continue
        file_rules = 0
        for pos in rule_blocks(content):
            block = content[pos:]
            # ogranicz blok do 4000 znaków (metadane zawsze na początku)
            meta = extract_metadata(block[:4000])
            total_blocks += 1
            if meta["matched"] is True:
                matched += 1
            if meta["rule_id"]:
                file_rules += 1
                unique_ids.add(meta["rule_id"])
                dup_counter[meta["rule_id"]] += 1
            if is_stub_block(block[:4000]):
                stubs.append({"file": str(path.relative_to(JDG_ROOT)), "block": pos})
        per_file.append({"file": str(path.relative_to(JDG_ROOT)), "blocks": file_rules})
    duplicates = [rid for rid, cnt in dup_counter.items() if cnt > 1]
    return {
        "rego_files": total_files,
        "rule_blocks": total_blocks,
        "matched_blocks": matched,
        "unique_rule_ids": len(unique_ids),
        "duplicate_rule_ids": len(duplicates),
        "duplicates_sample": sorted(duplicates)[:50],
        "stub_count": len(stubs),
        "stubs_sample": stubs[:20],
        "files_checksum": files_checksum,
        "per_file_blocks": per_file,
    }


def scan_tools() -> dict:
    tools = sorted(p.name for p in TOOLS_DIR.glob("*.py"))
    native_tests = sorted(p.name for p in TESTS_DIR.rglob("test_native_*.rego"))
    pytest_files = sorted(p.name for p in TESTS_DIR.glob("test_*.py"))
    return {
        "python_tools": len(tools),
        "tools_list": tools,
        "native_rego_tests": len(native_tests),
        "native_test_files": native_tests[:100],
        "pytest_files": len(pytest_files),
    }


def compute_manifest() -> dict:
    rules = scan_rules()
    tools = scan_tools()
    completeness = 100
    if rules["duplicate_rule_ids"] > 0:
        completeness -= min(30, rules["duplicate_rule_ids"])
    if rules["stub_count"] > 0:
        completeness -= min(20, rules["stub_count"] // 10)
    manifest = {
        "manifest_version": "2.0",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "generator": "manifest_v2.py",
        "source": "realne skanowanie katalogów (rules/, tools/, tests/) — JEDNO ŹRÓDŁO PRAWDY",
        "rules": rules,
        "tools": tools,
        "completeness_score": max(0, completeness),
        "declared_sources": DECLARED,
        "slo_targets": {
            "duplicates": 0,
            "stubs": 0,
            "hardcoded_values": 0,
            "lci": 99,
            "tcl": 100,
            "rv": 100,
            "uvr": 0,
        },
    }
    return manifest


def check_gate(manifest: dict) -> int:
    """Bramka CI — FAIL przy niezgodności stanu z deklaracjami oraz naruszeniu SLO."""
    problems = []
    rules = manifest["rules"]
    if rules["duplicate_rule_ids"] > 0:
        problems.append(f"SLO NARUSZONE: {rules['duplicate_rule_ids']} duplikatów rule_id (cel: 0)")
    if rules["stub_count"] > 0:
        problems.append(f"SLO NARUSZONE: {rules['stub_count']} stubów {{ true }} (cel: 0)")
    # Rozstrzygnięcie L2: wskaż, które dokumenty są NIEZGODNE ze stanem faktycznym
    for source, declared in DECLARED["rego_files"].items():
        if declared != rules["rego_files"]:
            problems.append(
                f"L2: {source} deklaruje {declared} plików Rego, stan faktyczny: {rules['rego_files']}"
            )
    for source, declared in DECLARED["rule_ids"].items():
        if declared != rules["unique_rule_ids"]:
            problems.append(
                f"L2: {source} deklaruje {declared} rule_id, stan faktyczny (unikalne): {rules['unique_rule_ids']}"
            )
    for source, declared in DECLARED["tools"].items():
        if declared != manifest["tools"]["python_tools"]:
            problems.append(
                f"L2: {source} deklaruje {declared} narzędzi, stan faktyczny: {manifest['tools']['python_tools']}"
            )
    if problems:
        print("❌ MANIFEST 2.0 — BRAMKA NIEZDANA (rozbieżności dokumentacyjne = blokada CI):")
        for p in problems:
            print(f"   • {p}")
        print("   → Zaktualizuj dokumenty źródłowe lub regenuj manifest: python manifest_v2.py")
        return 1
    print("✅ MANIFEST 2.0 — spójność potwierdzona: dokumentacja = stan faktyczny")
    return 0


def write_md(manifest: dict) -> None:
    r = manifest["rules"]
    t = manifest["tools"]
    lines = [
        "# 📋 MANIFEST 2.0 — JEDNO ŹRÓDŁO PRAWDY METRYK JDG (P01 Fundament)",
        "",
        f"> Wygenerowano: {manifest['generated_at']} · generator: `manifest_v2.py`",
        "> **Zasada:** manifest jest regenerowany w CI ze skanu katalogów; każda rozbieżność",
        "> między dokumentami a tym plikiem = blokada merge (bramka `--check`).",
        "",
        "## Metryki autorytatywne (stan faktyczny)",
        "",
        "| Metryka | Wartość | SLO |",
        "|---|---|---|",
        f"| Pliki Rego (rules/) | {r['rego_files']} | — |",
        f"| Bloki reguł | {r['rule_blocks']} | — |",
        f"| Bloki matched=true | {r['matched_blocks']} | — |",
        f"| Unikalne rule_id | {r['unique_rule_ids']} | — |",
        f"| Duplikaty rule_id | {r['duplicate_rule_ids']} | **0** |",
        f"| Stuby {{ true }} | {r['stub_count']} | **0** |",
        f"| Narzędzia Python (tools/) | {t['python_tools']} | — |",
        f"| Natywne testy Rego | {t['native_rego_tests']} | ≥ 95% pakietów |",
        f"| Pliki testów pytest | {t['pytest_files']} | — |",
        f"| Completeness Score | {manifest['completeness_score']}/100 | → 100 |",
        "",
        "## Rozstrzygnięcie luk dokumentacyjnych (L2)",
        "",
        "| Metryka | README.md | MANIFEST.md | COVERAGE_REPORT.md | STAN FAKTYCZNY (2.0) |",
        "|---|---|---|---|---|",
        f"| Pliki Rego | {DECLARED['rego_files']['README.md']} | {DECLARED['rego_files']['MANIFEST.md']} | {DECLARED['rego_files']['COVERAGE_REPORT.md']} | **{r['rego_files']}** |",
        f"| rule_id | {DECLARED['rule_ids']['README.md']} | {DECLARED['rule_ids']['bundles/manifest.json']} | {DECLARED['rule_ids']['unified_plan_v8.yaml']} | **{r['unique_rule_ids']}** (unikalne) |",
        f"| Narzędzia | {DECLARED['tools']['README.md']} | {DECLARED['tools']['OPA_JAKO_SYSTEM_P21.md']} | {DECLARED['tools']['KATALOG_NARZEDZI.md']} | **{t['python_tools']}** |",
        "",
        "## SLO docelowe (V1 §0 / V2 §11)",
        "",
        "| Metryka | Cel |",
        "|---|---|",
        "| Duplikaty / stuby | 0 (blokada CI) |",
        "| LCI (pokrycie prawa) | ≥ 99% |",
        "| TCL (ciągłość czasowa prawa) | 100% |",
        "| RV (reguła–prawo weryfikacja) | 100% |",
        "| UVR (nieuzasadnione zmiany werdyktów) | 0 |",
        "| Hardcoded wartości w regułach (ADR-002) | 0 |",
        "",
        "## Semantyka parsera (ważne — nie „poprawiać” liczb)",
        "",
        "- Liczniki pochodzą z `manifest_v2.py` (scan katalogów w CI) i mogą",
        "  różnić się od starszych deklaracji (README/MANIFEST.md): parser liczy",
        "  WSZYSTKIE bloki `:= {` z metadanymi rule_id (w tym duplikaty i bloki",
        "  `else`), a nie tylko bloki `matched: true` jak generate_manifest.py.",
        "- Rozbieżność dokumentów ze stanem faktycznym = BLOKADA CI (bramka",
        "  `--check`), a nie alert — to zamierzone działanie MANIFEST 2.0.",
        "- Właściwy proces: `python manifest_v2.py` → zaktualizuj dokumenty",
        "  źródłowe do liczb z manifestu → bramka zielona.",
        "",
        "*Zgodny z: ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md (V1), WIZJA_OPA_ENTERPRISE_V2.md (V2 §8), UNIFIED_PLAN.md.*",
        "",
    ]
    DOCS_DIR.mkdir(parents=True, exist_ok=True)
    OUT_MD.write_text("\n".join(lines), encoding="utf-8")
    print(f"✅ Raport: {OUT_MD.relative_to(JDG_ROOT)}")


def main() -> None:
    p = argparse.ArgumentParser(description="MANIFEST 2.0 — jedno źródło prawdy metryk JDG")
    p.add_argument("--check", action="store_true", help="bramka CI (FAIL przy rozbieżności)")
    p.add_argument("--json", action="store_true", help="JSON na stdout")
    p.add_argument("--gate-tools", type=int, default=0, help="minimalna liczba narzędzi (bramka)")
    args = p.parse_args()

    manifest = compute_manifest()
    BUNDLES_DIR.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")

    if args.json:
        print(json.dumps(manifest, indent=2, ensure_ascii=False))
        return

    print(f"📦 MANIFEST 2.0 — pliki Rego: {manifest['rules']['rego_files']}, "
          f"unikalne rule_id: {manifest['rules']['unique_rule_ids']}, "
          f"duplikaty: {manifest['rules']['duplicate_rule_ids']}, "
          f"stuby: {manifest['rules']['stub_count']}, "
          f"narzędzia: {manifest['tools']['python_tools']}")
    write_md(manifest)

    rc = check_gate(manifest)
    if args.gate_tools and manifest["tools"]["python_tools"] < args.gate_tools:
        print(f"❌ Bramka narzędzi: {manifest['tools']['python_tools']} < {args.gate_tools}")
        rc = 1
    sys.exit(rc)


if __name__ == "__main__":
    main()
