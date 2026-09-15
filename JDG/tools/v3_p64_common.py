#!/usr/bin/env python3
"""
NexusAI JDG — V3-P64 SWEEP LUK REZYDUALNYCH — COMMON (konwencja P51–P63).
Pomocnicze: czytniki PRAWDZIWYCH źródeł sweep: ledger kampanii
(bundles/v3_campaign_ledger.json — statusy + luki per część), rejestry luk
raportów (JDG/raporty_glm52_v3/RAPORT_V3_P*_*.txt — sekcja REJESTR LUK /
9.06), narzędzia detekcji (tools/dead_rule_detector.py,
cross_package_conflict_detector.py, migration_impact_analyzer.py,
else_chain_dead_code_detector.py, doc_consistency_validator.py,
rule_impact_simulator.py, crossref_plan50.py, legal_coverage_heatmap.py),
kanon pokrycia (bundles/coverage_canon.json, coverage_deserts.json),
rejestr mediacji (bundles/v3_p47_mediation_workflow.json),
rules/main_jdg.rego (ścieżka decyzyjna), rules/thresholds_jdg.rego (okna
parametrów), docs/ (KATALOG_NARZEDZI.md, INWENTARYZACJA_PLIKOW.md,
KATALOG_REGUL.md) + odczyt progów ADR-002 z thresholds_jdg.rego (jedno
źródło prawdy — silniki czytają TE SAME klucze co Rego P64; parser
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
MIGRATIONS_DIR = JDG_ROOT / "migrations"
REPORTS_DIR = JDG_ROOT / "raporty_glm52_v3"
PROMPTS_DIR = JDG_ROOT / "prompty_v3"
THRESHOLDS_REGO = RULES_DIR / "thresholds_jdg.rego"
MAIN_JDG_REGO = RULES_DIR / "main_jdg.rego"

# PRAWDZIWE artefakty sweep (rozszerzane, nie dublowane):
LEDGER = BUNDLES / "v3_campaign_ledger.json"
COVERAGE_CANON = BUNDLES / "coverage_canon.json"
COVERAGE_DESERTS = BUNDLES / "coverage_deserts.json"
P47_MEDIATION = BUNDLES / "v3_p47_mediation_workflow.json"
P47_TICKETS = BUNDLES / "v3_p47_mediation_tickets.json"
DEAD_RULE = TOOLS_DIR / "dead_rule_detector.py"
ELSE_CHAIN = TOOLS_DIR / "else_chain_dead_code_detector.py"
CONFLICT_DETECTOR = TOOLS_DIR / "cross_package_conflict_detector.py"
DOC_CONSISTENCY = TOOLS_DIR / "doc_consistency_validator.py"
IMPACT_SIM = TOOLS_DIR / "rule_impact_simulator.py"
CROSSREF_P50 = TOOLS_DIR / "crossref_plan50.py"
LEGAL_HEATMAP = TOOLS_DIR / "legal_coverage_heatmap.py"
MIGRATION_ANALYZER = TOOLS_DIR / "migration_impact_analyzer.py"
COVERAGE_REPORT = JDG_ROOT / "COVERAGE_REPORT.md"
KATALOG_NARZEDZI = DOCS_DIR / "KATALOG_NARZEDZI.md"
KATALOG_REGUL = DOCS_DIR / "KATALOG_REGUL.md"
INWENTARYZACJA = DOCS_DIR / "INWENTARYZACJA_PLIKOW.md"
PROMPTS_STATUS = JDG_ROOT / "prompts_status.yaml"
SWEEP_TOOL = TOOLS_DIR / "v3_p64_sweep_engine.py"
SWEEP_BUNDLE = BUNDLES / "v3_p64_sweep_register.json"

# Katalogi meta-kontroli I11 (sweep of sweeps — min 8 z promptu P64):
SWEEP_DIRS = ["rules", "tools", "bundles", "migrations", "tests",
              "docs", "api", "policies"]

# Wagi klas luk dla ryzyka rezydualnego I07 (rejestr jako decyzja projektowa
# P64 — spójne z krytycznością P0..P3 z promptów serii V3):
RISK_WEIGHTS = {"p0": 10, "p1": 5, "p2": 2, "p3": 1}

# Priorytety raportów (odczyt z nazw RAPORT_V3_P*_*.txt)
_RE_PART = re.compile(r"^RAPORT_V3_(P\d+)_", re.IGNORECASE)


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
    """Progi ADR-002 z thresholds_jdg.rego — to samo źródło co Rego P64.
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


def bundle_gate(path: Path) -> str | None:
    """Bramka z bundla (gate top-level lub result.gate — konwencja P54–P63)."""
    d = read_json(path)
    if isinstance(d, dict):
        if isinstance(d.get("gate"), str):
            return d["gate"]
        res = d.get("result")
        if isinstance(res, dict) and isinstance(res.get("gate"), str):
            return res["gate"]
    return None


def bundle_metrics(path: Path) -> dict:
    """Metryki z bundla konwencji P32/P40/P42 (metrics/checks) lub P54+ (result)."""
    d = read_json(path) or {}
    return d.get("metrics", d.get("result", d))


def ledger_parts() -> dict:
    d = read_json(LEDGER) or {}
    return d.get("parts", {}) or {}


def report_parts() -> dict:
    """Mapa Pxx → ścieżka raportu z raporty_glm52_v3/RAPORT_V3_P*.txt."""
    out = {}
    if not REPORTS_DIR.exists():
        return out
    for p in sorted(REPORTS_DIR.glob("RAPORT_V3_P*.txt")):
        m = _RE_PART.match(p.name)
        if m:
            out[m.group(1).upper()] = p
    return out


def risk_score(luki: dict, weights: dict | None = None) -> int:
    w = weights or RISK_WEIGHTS
    return sum(int(luki.get(k, 0) or 0) * v for k, v in w.items())


def audit_header(analyses: dict) -> dict:
    return {
        "schema": "jdg.v3_p64.sweep.audit.v1",
        "part": "P64",
        "slug": "LUKA_SWEEP",
        "generated_at": None,
        "analyses": analyses,
    }
