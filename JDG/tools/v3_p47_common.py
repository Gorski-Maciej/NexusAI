#!/usr/bin/env python3
"""NexusAI JDG — V3-P47 COMMON — wspólny szkielet narzędzi dowodowych
weryfikacji podstaw prawnych (zero fikcji, każdy cytat w ISAP).

Konwencje (honoruje kontrakty P45/P46/P39/P37):
  * każdy silnik I01–I12 pisze JEDEN bundle: bundles/v3_p47_<nazwa>.json,
  * bundle: {"innovation": "V3-P47-Ixx", "generated_at": ISO-8601 UTC,
             "gate": "PASS", "metrics": {...}, "evidence": {...}},
  * gate=PASS oznacza: narzędzie URUCHOMIONE i dowód ZAPISANY (spójny),
    nie "zero problemów" — decyzja TRIAGE/BLOCK jest w metrics.routing,
  * liczniki z realnych plików repozytorium (honesty: zero fantazji liczb);
    wszystkie podstawy prawne do czasu stempla 4-eyes = [NIEZWERYFIKOWANE].
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]
RULES_DIR = BASE / "rules"
BUNDLES_DIR = BASE / "bundles"
DOCS_DIR = BASE / "docs"

# ── Źródła dowodowe (jedno źródło prawdy; P47 rozszerza, nie duplikuje) ────────
LB_V2_REPORT = BUNDLES_DIR / "legal_basis_v2_report.json"
LSR_REGISTRY = BUNDLES_DIR / "legal_source_registry.json"
CANON = BUNDLES_DIR / "legal_reference_canon.json"
COVERAGE_GAPS = BUNDLES_DIR / "legal_coverage_gaps.json"
CHANGE_CALENDAR = BUNDLES_DIR / "legal_change_calendar.json"
P45_MEDIATION = BUNDLES_DIR / "v3_p45_isap_mediation_register.json"
P46_DRIFT_TRACKER = BUNDLES_DIR / "v3_p46_isap_drift_tracker.json"
P46_ORPHAN_HISTORY = BUNDLES_DIR / "v3_p46_orphan_history.json"
THRESHOLDS_REGO = RULES_DIR / "thresholds_jdg.rego"
P47_REGO = RULES_DIR / "v3_p47_legal_basis_weryfikacja_enterprise.rego"
P47_RULE = "jdg.v3_p47_legal_basis_weryfikacja_enterprise"

# Kanon cytowań (kontrakt wyjściowy P47 → P41/P36):
#   akt wprost (pełna nazwa), jednostki redakcyjne art./ust./pkt/§, publikator
#   Dz.U. RRRR poz. N, albo jawny tag [NIEZWERYFIKOWANE]/[BŁĄD_PODSTAWY_PRAWNEJ?].
CANON_TAGS = ("NIEZWERYFIKOWANE", "BŁĄD_PODSTAWY_PRAWNEJ?")
# Wewnętrzne referencje innowacji (provenance P47) — nie są cytowaniami prawnymi
INTERNAL_REF = re.compile(r"^(P\d+-I\d+|V3-P\d+|ADR-\d+)")
CANON_PATTERNS = [
    re.compile(r"art\.?\s*\d+[a-z]*(?:\s*(?:ust|§|pkt)\.?|\s*i\s*nast)?", re.IGNORECASE),
    # Format współczesny: Dz.U. 2024 poz. 1557; format historyczny (przed 2002):
    # Dz.U. 2005 nr 12 poz. 90 — oba są autentycznymi formatami publikatora.
    re.compile(r"Dz\.?\s*U\.?\s*\d{4}\s*(?:nr\s*\d+\s*)?poz\.?\s*\d+", re.IGNORECASE),
    re.compile(r"rozporządzen\w+", re.IGNORECASE),
    re.compile(r"ustawa", re.IGNORECASE),
]


def utcnow_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def sla_due_iso(generated_at: str, sla_days: int) -> str:
    dt = datetime.fromisoformat(generated_at)
    return (dt.replace(microsecond=0)).isoformat() if sla_days <= 0 else (
        datetime.fromtimestamp(dt.timestamp() + sla_days * 86400, tz=timezone.utc).isoformat()
    )


def read_json(path: Path, default=None):
    if not path.exists():
        return default
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return default


def write_json(path: Path, data) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n",
                    encoding="utf-8")


def write_bundle(name: str, innovation: str, metrics: dict, evidence: dict) -> Path:
    """Zapisz bundle dowodowy v3_p47_<name>.json z gate=PASS (dowód zapisany)."""
    bundle = {
        "innovation": innovation,
        "generated_at": utcnow_iso(),
        "gate": "PASS",
        "metrics": metrics,
        "evidence": evidence,
    }
    out = BUNDLES_DIR / f"v3_p47_{name}.json"
    write_json(out, bundle)
    return out


def scan_legal_basis() -> dict:
    """Spis _legal_basis w rego (comment-aware): wystąpienia, pliki, cytowania."""
    occurrences = 0
    files_with = 0
    citations = []
    for path in sorted(RULES_DIR.rglob("*.rego")):
        try:
            content = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        file_hits = 0
        for line in content.splitlines():
            stripped = line.strip()
            if stripped.startswith("#") or stripped.startswith("//"):
                continue
            if "_legal_basis" in line:
                occurrences += 1
                file_hits += 1
                m = re.search(r'"([^"]+)"', line)
                if m:
                    citations.append(m.group(1))
        if file_hits:
            files_with += 1
    return {"occurrences": occurrences, "files_with": files_with,
            "citations": citations}


def citation_in_canon(citation: str) -> bool:
    """Cytowanie zgodne z kanonem: jednostka redakcyjna / Dz.U. (współczesny lub
    historyczny format) / jawnie oznaczone [NIEZWERYFIKOWANE]/[BŁĄD_PODSTAWY_PRAWNEJ?].
    Wewnętrzne referencje innowacji (P47-I03, ADR-002) nie są cytowaniami."""
    if not citation:
        return False
    if INTERNAL_REF.match(citation.strip()):
        return True
    if any(tag in citation for tag in CANON_TAGS):
        return True
    return any(p.search(citation) for p in CANON_PATTERNS)


def extract_threshold_block(block_name: str) -> str | None:
    """Wydziel blok <nazwa> := { ... } z thresholds_jdg.rego.

    Reużyte z v3_p46_common (konwencja P46): skaner string-aware ORAZ
    comment-aware (komentarze rego mogą zawierać cudzysłowy).
    """
    if not THRESHOLDS_REGO.exists():
        return None
    src = THRESHOLDS_REGO.read_text(encoding="utf-8", errors="replace")
    m = re.search(rf"^{block_name}\s*:=\s*\{{", src, re.MULTILINE)
    if not m:
        return None
    start = m.end() - 1
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


def rule_present(rule_id: str) -> bool:
    if not P47_REGO.exists():
        return False
    return rule_id in P47_REGO.read_text(encoding="utf-8", errors="replace")
