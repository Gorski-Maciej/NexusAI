#!/usr/bin/env python3
"""
NexusAI JDG — V3-P65 NOWE NARZĘDZIA FORTECY — COMMON (konwencja P51–P64).
Pomocnicze: czytniki PRAWDZIWYCH źródeł narzędziowych: kontrakt narzędzi
(tools/v3_p65_tool_contract.py — I01), narzędzia P65 (semantic diff, generator
testów, WORM tamper, adoption, docs generator), narzędzia komponowane
(tools/v3_p62_*.py cashflow P62, tools/v3_p53_*.py temporal P53,
tools/v3_p63_*.py RBAC P63, tools/v3_p37_benchmark_*.py eval P37,
tools/v3_p49_*.py chaos P49, tools/v3_p42_worm_hash_chain.py WORM P42),
bundles/v3_p63_i01_rbac.json (role z mapą pól), docs/ROLE_MAPS.md,
docs/KATALOG_NARZEDZI.md + odczyt progów ADR-002 z thresholds_jdg.rego
(jedno źródło prawdy — silniki czytają TE SAME klucze co Rego P65; parser
obsługuje listy/stringi/bool/int/float — lekcja z P62).
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
BUNDLES = JDG_ROOT / "bundles"
DOCS_DIR = JDG_ROOT / "docs"
TOOLS_DIR = JDG_ROOT / "tools"
RULES_DIR = JDG_ROOT / "rules"
TESTS_AUTO = JDG_ROOT / "tests" / "auto"
TESTS_REGO = JDG_ROOT / "tests" / "rego"
REPORTS_DIR = JDG_ROOT / "raporty_glm52_v3"
THRESHOLDS_REGO = RULES_DIR / "thresholds_jdg.rego"
MAIN_JDG_REGO = RULES_DIR / "main_jdg.rego"

# ── PRAWDZIWE źródła komponowane (rozszerzane, nie dublowane — protokół 08) ──
TOOL_CONTRACT = TOOLS_DIR / "v3_p65_tool_contract.py"
SEMANTIC_DIFF = TOOLS_DIR / "v3_p65_semantic_diff.py"
RULE_TO_TESTS = TOOLS_DIR / "v3_p65_rule_to_tests.py"
WORM_TAMPER = TOOLS_DIR / "v3_p65_worm_tamper_test.py"
ADOPTION = TOOLS_DIR / "v3_p65_adoption_metrics.py"
DOC_GENERATOR = TOOLS_DIR / "v3_p65_doc_generator.py"
P62_ENGINES = TOOLS_DIR / "v3_p62_engines.py"
P62_RUN_ALL = BUNDLES / "v3_p62_run_all.json"
P53_ENGINES = TOOLS_DIR / "v3_p53_engines.py"
P63_I01_RBAC = BUNDLES / "v3_p63_i01_rbac.json"
ROLE_MAPS = DOCS_DIR / "ROLE_MAPS.md"
P37_BENCH_GATE = TOOLS_DIR / "v3_p37_benchmark_gate.py"
P37_BENCH_REG = TOOLS_DIR / "v3_p37_benchmark_regression.py"
P49_CHAOS_INPUT = TOOLS_DIR / "v3_p49_chaos_input.py"
P49_MISSING_FIELD = TOOLS_DIR / "v3_p49_missing_field_generator.py"
P49_FAIL_OPEN = TOOLS_DIR / "v3_p49_fail_open_scanner.py"
P42_WORM_CHAIN = TOOLS_DIR / "v3_p42_worm_hash_chain.py"
P51_CARDS = TOOLS_DIR / "v3_p51_desert_cards.py"
KATALOG_NARZEDZI = DOCS_DIR / "KATALOG_NARZEDZI.md"
P64_SWEEP = TOOLS_DIR / "v3_p64_sweep_engine.py"
DOCS_GENERATED = DOCS_DIR / "TOOLS_P65_GENERATED.md"
WORKFLOWS = JDG_ROOT.parent / ".github" / "workflows"


def read_text(path: Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8", errors="replace")


def read_json(path: Path):
    if not path.exists():
        return None
    try:
        return json.loads(read_text(path))
    except json.JSONDecodeError:
        return None


def write_json(path: Path, payload) -> bool:
    try:
        path.write_text(json.dumps(payload, ensure_ascii=False, indent=2),
                        encoding="utf-8")
        return True
    except OSError:
        return False


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def read_threshold(key: str):
    """Progi ADR-002 z thresholds_jdg.rego — to samo źródło co Rego P65.
    Obsługuje: listy stringów, stringi, bool, int, float (lekcja z P62)."""
    src = read_text(THRESHOLDS_REGO)
    m = re.search(
        rf'"{key}"\s*:\s*(\[[^\]]*\]|"(?:[^"\\]|\\.)*"|true|false|-?\d+(?:\.\d+)?)',
        src)
    if not m:
        return None
    raw = m.group(1)
    if raw.startswith("["):
        items = re.findall(r'"([^"]+)"', raw)
        return items if items else None
    if raw.startswith('"'):
        return raw[1:-1]
    if raw == "true":
        return True
    if raw == "false":
        return False
    return float(raw) if "." in raw else int(raw)


def audit_header(analyses: dict) -> dict:
    return {
        "schema": "jdg.v3_p65.toolforge.audit.v1",
        "part": "P65",
        "slug": "NOWE_NARZEDZIA",
        "generated_at": None,
        "analyses": analyses,
    }


def keyword_scan(paths, keywords: list[str]) -> list[str]:
    """Deterministyczny skan: które słowa kluczowe występują w źródłach
    (kompozycja — wykrywanie pokrycia scenariuszy w istniejących silnikach)."""
    hay = "\n".join(read_text(Path(p)) for p in paths)
    return [k for k in keywords if re.search(k, hay, re.IGNORECASE)]
