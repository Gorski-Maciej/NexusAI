#!/usr/bin/env python3
"""NexusAI JDG — V3-P46 COMMON — wspólny szkielet narzędzi dowodowych
eliminacji hardcode (ADR-002 parametry-as-data).

Konwencje (honoruje kontrakty P45/P39/P37):
  * każdy silnik I01–I12 pisze JEDEN bundle: bundles/v3_p46_<nazwa>.json,
  * bundle: {"innovation": "V3-P46-Ixx", "generated_at": ISO-8601 UTC,
             "gate": "PASS", "metrics": {...}, "evidence": {...}},
  * gate=PASS oznacza: narzędzie URUCHOMIONE i dowód ZAPISANY (spójny),
    nie "zero problemów" — decyzja TRIAGE/BLOCK jest w metrics.routing,
  * liczniki z realnych skanów repozytorium (honesty: zero fantazji liczb).
"""
from __future__ import annotations

import hashlib
import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]
RULES_DIR = BASE / "rules"
BUNDLES_DIR = BASE / "bundles"
DOCS_DIR = BASE / "docs"
REPO_ROOT = BASE.parent
OPA = REPO_ROOT / "bin" / "opa"
OPA19 = REPO_ROOT / "bin" / "opa19"

THRESHOLDS_REGO = RULES_DIR / "thresholds_jdg.rego"
THRESHOLDS_DATA = BUNDLES_DIR / "thresholds_data.json"
MAIN_JDG = RULES_DIR / "main_jdg.rego"
P46_REGO = RULES_DIR / "v3_p46_hardcode_eliminacja_enterprise.rego"

# Wzorce audytu hardcode — identyczne z tools/hardcoded_audit.py (jedno źródło
# prawdy wzorca; P46 nie duplikuje definicji, tylko je wywołuje spójnie).
HARDCODED_PATTERNS = [
    (r'(?<!thresholds\.jdg\.)(?<!thresholds\.)(?<!")(?<![\w.])(\d{4,})(?![\w.])(?!\s*//)', "large_integer"),
    (r'(?<!thresholds\.jdg\.)(?<!thresholds\.)\b0\.\d{2,3}\b(?!\s*//)', "decimal_rate"),
    (r'(?<!")(?<![\w/])(\d{2,3})\s*(?:dni|days|miesięcy|months|lat|years)(?![\w/])', "time_period"),
]


def utcnow_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def write_json(path: Path, data) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n",
                    encoding="utf-8")


def read_json(path: Path, default=None):
    if not path.exists():
        return default
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return default


def write_bundle(name: str, innovation: str, metrics: dict, evidence: dict) -> Path:
    """Zapisz bundle dowodowy v3_p46_<name>.json z gate=PASS (dowód zapisany)."""
    bundle = {
        "innovation": innovation,
        "generated_at": utcnow_iso(),
        "gate": "PASS",
        "metrics": metrics,
        "evidence": evidence,
    }
    out = BUNDLES_DIR / f"v3_p46_{name}.json"
    write_json(out, bundle)
    return out


def scan_hardcoded(directory: Path | None = None, exclude: set[str] | None = None) -> dict:
    """Policz hardcoded wartości wzorcami hardcoded_audit.py (spójny licznik)."""
    directory = directory or RULES_DIR
    exclude = exclude or set()
    findings = []
    scanned = 0
    for path in sorted(directory.rglob("*.rego")):
        rel = str(path.relative_to(directory))
        if rel in exclude or path.name in exclude:
            continue
        scanned += 1
        try:
            content = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for line_no, line in enumerate(content.splitlines(), start=1):
            stripped = line.strip()
            if stripped.startswith("#") or stripped.startswith("//"):
                continue
            for pattern, category in HARDCODED_PATTERNS:
                for m in re.finditer(pattern, line):
                    findings.append({
                        "file": rel,
                        "line": line_no,
                        "value": m.group(0).strip(),
                        "category": category,
                    })
    return {"scanned_files": scanned, "findings": findings}


def extract_threshold_block(block_name: str) -> str | None:
    """Wydziel blok <nazwa> := { ... } z thresholds_jdg.rego.

    String-aware ORAZ comment-aware (OPA ignoruje `#` do końca linii —
    skaner musi też; w komentarzach zdarzają się cudzysłowy typograficzne
    zamykane ASCII, np. „osieroconych\"").
    """
    if not THRESHOLDS_REGO.exists():
        return None
    src = THRESHOLDS_REGO.read_text(encoding="utf-8", errors="replace")
    m = re.search(rf"^{block_name}\s*:=\s*\{{", src, re.MULTILINE)
    if not m:
        return None
    start = m.end() - 1  # pozycja '{'
    depth = 0
    instr = False
    esc = False
    i = start
    while i < len(src):
        c = src[i]
        if instr:
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                instr = False
        elif c == '"':
            instr = True
        elif c == "#":
            j = src.find("\n", i)
            i = j if j != -1 else len(src)
            continue
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return src[start:i + 1]
        i += 1
    return None


def threshold_keys(block_name: str) -> list[str]:
    """Lista kluczy progowych z bloku thresholds (bez komentarzy)."""
    block = extract_threshold_block(block_name)
    if not block:
        return []
    return re.findall(r'"([A-Za-z0-9_.]+)"\s*:', block)


def thresholds_value(block_name: str, key: str, default=None):
    block = extract_threshold_block(block_name) or ""
    m = re.search(rf'"{re.escape(key)}"\s*:\s*([^,\n}}]+)', block)
    if not m:
        return default
    raw = m.group(1).strip()
    if raw.startswith("["):
        inner = re.findall(r'"([^"]+)"', raw)
        return inner if inner else default
    if raw.startswith('"'):
        return raw.strip('"')
    try:
        return int(raw)
    except ValueError:
        pass
    try:
        return float(raw)
    except ValueError:
        return raw


def routing_of(block_name: str, rules: list[tuple[bool, str]], default: str = "AUTO_FILE") -> str:
    """Odtwórz routing rego w Pythonie (dowód spójności rego↔evidence)."""
    for condition, routing in rules:
        if condition:
            return routing
    return default
