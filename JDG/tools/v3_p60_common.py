#!/usr/bin/env python3
"""
NexusAI JDG — V3-P60 DOKUMENTACJA DOMKNIĘCIE — COMMON (konwencja P51–P59).
Pomocnicze: czytniki PRAWDZIWYCH źródeł dokumentacji (docs/, bundles/
rule_registry.json, bundles/manifest_v2.json, bundles/v3_campaign_ledger.json,
docs/SLOWNIK_REFERENCJI_PRAWNYCH.md) + parser front-matter dokumentów + odczyt
progów ADR-002 z thresholds_jdg.rego (jedno źródło prawdy — silniki czytają TE
SAME klucze co Rego).
"""
from __future__ import annotations

import hashlib
import json
import re
from datetime import date, datetime
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
BUNDLES = JDG_ROOT / "bundles"
DOCS_DIR = JDG_ROOT / "docs"
TOOLS_DIR = JDG_ROOT / "tools"
RULES_DIR = JDG_ROOT / "rules"
THRESHOLDS_REGO = RULES_DIR / "thresholds_jdg.rego"

RULE_REGISTRY = BUNDLES / "rule_registry.json"
MANIFEST_V2 = BUNDLES / "manifest_v2.json"
CAMPAIGN_LEDGER = BUNDLES / "v3_campaign_ledger.json"
KATALOG_REGUL = DOCS_DIR / "KATALOG_REGUL.md"
KATALOG_NARZEDZI = DOCS_DIR / "KATALOG_NARZEDZI.md"
MANIFEST_2_0_DOC = DOCS_DIR / "MANIFEST_2_0.md"
ROLE_MAPS = DOCS_DIR / "ROLE_MAPS.md"
DOC_STANDARD = DOCS_DIR / "DOC_STANDARD_P60.md"
GLOSSARY = DOCS_DIR / "SLOWNIK_REFERENCJI_PRAWNYCH.md"
AUDIT_EXPORT = BUNDLES / "v3_p60_audit_export.json"

# Dokumenty rdzenia objęte bindingiem front-matter (I03) — kontrakt P60.
CORE_DOCS = [
    "docs/FAQ.md",
    "docs/DEVELOPER_GUIDE.md",
    "docs/API_REFERENCJA.md",
    "docs/LOGIKA_BIZNESOWA.md",
    "docs/KATALOG_NARZEDZI.md",
    "docs/KATALOG_REGUL.md",
    "docs/SLOWNIK_REFERENCJI_PRAWNYCH.md",
    "docs/ARCHITEKTURA.md",
    "docs/ARCHITECTURE.md",
    "docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md",
    "docs/WIZJA_OPA_ENTERPRISE_V2.md",
    "docs/MANIFEST_2_0.md",
    "docs/ROLE_MAPS.md",
    "docs/DOC_STANDARD_P60.md",
]

# Dokumenty święte (I08) — nadrzędne, zmiana tylko z ADR + review prawne.
HOLY_DOCS = [
    "docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md",
    "docs/WIZJA_OPA_ENTERPRISE_V2.md",
]

REQUIRED_FM_FIELDS = ["artifacts", "status", "owner", "verify_cmd"]


def read_text(path: Path) -> str:
    try:
        return Path(path).read_text(encoding="utf-8")
    except Exception:
        return ""


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


def now_iso() -> str:
    return datetime.now().astimezone().isoformat()


def sha256_file(path: Path) -> str:
    try:
        return hashlib.sha256(Path(path).read_bytes()).hexdigest()
    except Exception:
        return "UNAVAILABLE"


def read_threshold(key: str):
    m = re.search(rf'"{key}":\s*(\d+)', read_text(THRESHOLDS_REGO))
    if m:
        return int(m.group(1))
    m = re.search(rf'"{key}":\s*\[([^\]]*)\]', read_text(THRESHOLDS_REGO))
    if m:
        return [x.strip().strip('"') for x in m.group(1).split(",") if x.strip()]
    return None


# ── Front-matter (I03): blok HTML-comment na początku dokumentu ────────────────
FM_BLOCK_RE = re.compile(r"<!--\s*\n(.*?)-->", re.S)


def parse_front_matter(text: str) -> dict:
    """Parsuj front-matter dokumentu: klucz: wartość (artifacts jako lista [])."""
    m = FM_BLOCK_RE.search(text[:2000])
    if not m:
        return {}
    fm: dict = {}
    for line in m.group(1).splitlines():
        if ":" not in line:
            continue
        key, _, val = line.partition(":")
        key = key.strip().lstrip("*").strip()
        val = val.strip()
        if not key or not val:
            continue
        if val.startswith("[") and val.endswith("]"):
            fm[key] = [x.strip().strip('"').strip("'") for x in val[1:-1].split(",") if x.strip()]
        else:
            fm[key] = val
    return fm


def doc_path(rel: str) -> Path:
    """Ścieżka dokumentu względem JDG_ROOT ('docs/X.md') lub repo root."""
    p = JDG_ROOT / rel
    return p if p.exists() else JDG_ROOT.parent / rel


def core_docs_audit() -> dict:
    """Jedno źródło faktów dla I03/I04/I07/I08/I09: front-matter dokumentów rdzenia."""
    required_fields = read_threshold("v3_p60_frontmatter_required_fields") or REQUIRED_FM_FIELDS
    max_age = read_threshold("v3_p60_doc_freshness_max_days") or 90
    today = date.today()
    docs_with_fm, fm_missing, ghosts, stale, unprotected, verify_cmds = 0, [], [], [], [], []
    for rel in CORE_DOCS:
        p = doc_path(rel)
        text = read_text(p)
        fm = parse_front_matter(text)
        if not fm:
            fm_missing.append(rel)
            continue
        missing_fields = [f for f in required_fields if f not in fm]
        if missing_fields:
            fm_missing.append(f"{rel} (brak: {','.join(missing_fields)})")
            continue
        docs_with_fm += 1
        # I04: artefakty z bindingu muszą istnieć (widmo = opis nieistniejącego)
        for art in fm.get("artifacts", []) if isinstance(fm.get("artifacts"), list) else [fm.get("artifacts")]:
            if art and not (JDG_ROOT / str(art)).exists() and not (JDG_ROOT.parent / str(art)).exists():
                ghosts.append(f"{rel} -> {art}")
        # I07: świeżość — pole verified (data ostatniej weryfikacji prawdy)
        verified = fm.get("verified", "")
        try:
            vdate = date.fromisoformat(str(verified)[:10])
            if (today - vdate).days > max_age:
                stale.append(f"{rel} (verified {verified})")
        except ValueError:
            stale.append(f"{rel} (brak pola verified)")
        # I08: dokumenty święte — ochrona = owner legal/core + verify_cmd
        if rel in HOLY_DOCS:
            if str(fm.get("owner", "")) not in ("legal", "core") or not fm.get("verify_cmd"):
                unprotected.append(rel)
        # I09: verify_cmd = przykład-as-test (uruchamialny dowód prawdy)
        vc = fm.get("verify_cmd")
        if vc:
            verify_cmds.append((rel, str(vc)))
    return {"docs_with_fm": docs_with_fm, "fm_missing": fm_missing, "ghosts": ghosts,
            "stale": stale, "unprotected": unprotected, "verify_cmds": verify_cmds}


def glossary_terms() -> list:
    """Kanoniczne nazwy aktów z SLOWNIK_REFERENCJI_PRAWNYCH.md (jedno źródło)."""
    terms = []
    for line in read_text(GLOSSARY).splitlines():
        m = re.match(r"^\|\s*`([^`]+)`\s*\|", line)
        if m:
            terms.append(m.group(1).strip())
    return terms


def audit_header(analyses: dict) -> dict:
    return {
        "schema": "jdg.v3_p60.documentation.audit.v1",
        "part": "P60",
        "slug": "DOKUMENTACJA_DOMKNIECIE",
        "generated_at": None,
        "analyses": analyses,
    }
