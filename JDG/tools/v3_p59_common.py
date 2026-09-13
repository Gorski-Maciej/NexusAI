#!/usr/bin/env python3
"""
NexusAI JDG — V3-P59 BEZPIECZEŃSTWO DOMKNIĘCIE — COMMON (konwencja P51–P58).
Pomocnicze: czytniki PRAWDZIWYCH źródeł security (.github/workflows/
jdg-quality.yml — permissions/fork isolation; worm_storage — hash chain +
verify_chain; deployments.json — P38 attestation/canary/soak;
v3_p52_rate_provenance — hardcode stawek; chaos_runner — eksperymenty P43;
skan sekretów w repo) + odczyt progów ADR-002 z thresholds_jdg.rego (jedno
źródło prawdy — silniki czytają TE SAME klucze co Rego).
"""
from __future__ import annotations

import importlib.util
import json
import re
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
BUNDLES = JDG_ROOT / "bundles"
RULES_DIR = JDG_ROOT / "rules"
DOCS_DIR = JDG_ROOT / "docs"
TOOLS_DIR = JDG_ROOT / "tools"
REPO_ROOT = JDG_ROOT.parent

WORKFLOW_YML = JDG_ROOT / ".github" / "workflows" / "jdg-quality.yml"
WORM_STORAGE = TOOLS_DIR / "worm_storage.py"
DEPLOYMENTS_JSON = BUNDLES / "deployments.json"
P52_RATE_PROVENANCE = BUNDLES / "v3_p52_rate_provenance.json"
CHAOS_RUNNER = TOOLS_DIR / "chaos_runner.py"
RODO_AML_DOC = DOCS_DIR / "RODO_AML_BEZPIECZENSTWO_P16.md"
P44_SIGNATURE = TOOLS_DIR / "v3_p44_worm_signature.py"
THRESHOLDS_REGO = RULES_DIR / "thresholds_jdg.rego"


def read_json(path: Path):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except Exception:
        return None


def write_json(path: Path, payload) -> bool:
    try:
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        Path(path).write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
        return True
    except Exception:
        return False


def read_text(path: Path) -> str:
    try:
        return Path(path).read_text(encoding="utf-8")
    except Exception:
        return ""


def now_iso() -> str:
    from datetime import datetime, timezone
    return datetime.now(timezone.utc).isoformat()


def load_tool_module(name: str, path: Path):
    """Załaduj istniejące narzędzie jako moduł (kontrakt: rozszerzaj, nie kopiuj)."""
    if not path.exists():
        return None
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(mod)
        return mod
    except Exception:
        return None


# ── Odczyt progów ADR-002 z thresholds_jdg.rego (jedno źródło prawdy) ─────────
def read_threshold_str(key: str) -> str | None:
    m = re.search(rf'"{key}":\s*"([^"]+)"', read_text(THRESHOLDS_REGO))
    return m.group(1) if m else None


def read_threshold_int(key: str) -> int | None:
    m = re.search(rf'"{key}":\s*(\d+)', read_text(THRESHOLDS_REGO))
    return int(m.group(1)) if m else None


# ── Skan sekretów w repo (wzorce: klucz prywatny, AWS, hasła, tokeny) ─────────
SECRET_PATTERNS = [
    ("private_key", re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
    ("aws_key", re.compile(r"AKIA[A-Z0-9]{16}")),
    ("password_literal", re.compile(r"""password\s*=\s*["'][^"']{8,}["']""", re.I)),
    ("api_token", re.compile(r"""(api[_-]?token|secret[_-]?key)\s*=\s*["'][A-Za-z0-9]{16,}["']""", re.I)),
]


def scan_repo_secrets() -> list:
    """Skan katalogów z kodem (tools, .github, tests) — NIGDY bundli/danych."""
    hits = []
    scan_roots = [TOOLS_DIR, JDG_ROOT / ".github", JDG_ROOT / "tests"]
    for root in scan_roots:
        if not root.exists():
            continue
        for p in root.rglob("*.py"):
            text = read_text(p)
            for name, rx in SECRET_PATTERNS:
                if rx.search(text):
                    hits.append(f"{p.relative_to(JDG_ROOT)}:{name}")
    return hits


def audit_header(analyses: dict) -> dict:
    return {
        "schema": "jdg.v3_p59.security.audit.v1",
        "part": "P59",
        "slug": "SECURITY_DOMKNIECIE",
        "generated_at": None,  # wypełnia silnik
        "analyses": analyses,
    }
