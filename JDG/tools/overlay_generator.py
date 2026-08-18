#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — OVERLAY GENERATOR (GLM52 P19 — POLICIES MIRROR + OVERLAYS)
# Generator manifestów overlayów v20XX z Legal Knowledge Graph (LKG):
#   • skan reguł rules/ → katalog zmian (rule_id + legal_basis + status),
#   • kandydaci na overlay: reguły oznaczone PLANNED/PROJEKT, zmiany limitów
#     (thresholds), przepisy z valid_to w przyszłości,
#   • generuje/aktualizuje manifests/overlays/v20XX/manifest.json (tylko delta),
#   • bramka spójności: overlay musi być podzbiorem reguł base (zero reguł
#     „duchów" — reguł nieistniejących w base),
#   • spójność z overlay_engine.py (algebra interwałów — TCL 100%, ADR-011).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import date
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"
POLICIES_ROOT = JDG_ROOT.parent / "policies"
OVERLAYS_DIR = POLICIES_ROOT / "jdg" / "bundles" / "overlays"
BASE_MANIFEST = POLICIES_ROOT / "jdg" / "bundles" / "base" / "manifest.json"
LKG_PATH = JDG_ROOT / "bundles" / "legal_graph.json"

# ── Zmiany znane — kandydaci na overlay (PLANNED / PROJEKT / przyszłe) ────────
KNOWN_CANDIDATES: list[dict] = [
    {
        "type": "MODIFY", "rule": "jdg.pit.forms.scale",
        "description": "Próg podatkowy 120000 → 130000 PLN (propozycja MF)",
        "status": "PLANNED", "legal_basis": "Projekt ustawy o PIT 2026",
        "tax_year": 2026,
    },
    {
        "type": "MODIFY", "rule": "jdg.zus.health_contribution_rate_matrix",
        "description": "Składka zdrowotna 9% → 8.5% (propozycja)",
        "status": "PLANNED", "legal_basis": "Projekt ustawy zdrowotnej 2026",
        "tax_year": 2026,
    },
    {
        "type": "MODIFY", "rule": "jdg.business.unregistered_activity_limit_exceeded",
        "description": "Limit nieewidencjonowanej: 50% → 75% min. wynagrodzenia",
        "status": "PLANNED", "legal_basis": "Nowelizacja Prawa przedsiębiorców",
        "tax_year": 2026,
    },
]


def scan_rules() -> list[dict]:
    """Skan reguł rules/ — wykryj rule_id + legal_basis per plik (katalog zmian)."""
    catalog = []
    rule_re = re.compile(r'"rule_id"\s*[:=]\s*"([^"]+)"')
    basis_re = re.compile(r'legal_basis\s*=\s*"([^"]+)"')
    for p in sorted(RULES_DIR.rglob("*.rego")):
        text = p.read_text(encoding="utf-8", errors="replace")
        rules = rule_re.findall(text)
        bases = basis_re.findall(text)
        rel = p.relative_to(RULES_DIR)
        for rid in rules:
            catalog.append({"rule": rid, "file": str(rel),
                            "legal_basis": bases[0] if bases else None})
    return catalog


def load_lkg() -> dict | None:
    if not LKG_PATH.exists():
        return None
    return json.loads(LKG_PATH.read_text(encoding="utf-8"))


def candidate_changes(year: int, catalog: list[dict]) -> list[dict]:
    """Kandydaci na overlay dla roku: znane + reguły z legal_basis zawierającą rok."""
    changes: list[dict] = []
    seen = set()
    for cand in KNOWN_CANDIDATES:
        if cand["tax_year"] != year:
            continue
        key = (cand["rule"], cand["type"])
        if key in seen:
            continue
        seen.add(key)
        changes.append({k: v for k, v in cand.items() if k != "tax_year"})
    # reguły z legal_basis wskazującym przyszły rok (np. „2027")
    for r in catalog:
        basis = r.get("legal_basis") or ""
        if str(year) in basis and ("202" in basis):
            key = (r["rule"], "MODIFY")
            if key in seen:
                continue
            seen.add(key)
            changes.append({
                "type": "MODIFY", "rule": r["rule"],
                "description": f"Reguła dot. zmian {year} (legal_basis: {basis[:60]})",
                "status": "PLANNED", "legal_basis": basis,
            })
    return changes


def ghosts(changes: list[dict], catalog_rules: set[str]) -> list[dict]:
    """Reguły „duchy" — zadeklarowane w overlay, ale nieistniejące w base rules/."""
    return [c for c in changes if c.get("rule") not in catalog_rules]


def generate(year: int, dry_run: bool = False) -> dict:
    catalog = scan_rules()
    catalog_rules = {r["rule"] for r in catalog}
    lkg = load_lkg()

    changes = candidate_changes(year, catalog)
    # overlay zawiera tylko reguły istniejące w base (zero duchów) — P1617
    real = [c for c in changes if c["rule"] in catalog_rules]
    gh = ghosts(changes, catalog_rules)

    ov_dir = OVERLAYS_DIR / f"v{year}"
    ov_dir.mkdir(parents=True, exist_ok=True)
    mf_path = ov_dir / "manifest.json"

    existing = {}
    if mf_path.exists():
        existing = json.loads(mf_path.read_text(encoding="utf-8"))

    # zachowaj istniejące zmiany (TYLKO nie-duchy — reguły istniejące w base)
    # + scal nowe (deduplikacja po rule+type). Stare wpisy z błędnymi rule_id
    # są automatycznie usuwane (P1617 — zero duchów).
    merged = {}
    for c in existing.get("changes", []):
        if c.get("rule") in catalog_rules:
            merged[f"{c['rule']}|{c['type']}"] = c
    for c in real:
        merged[f"{c['rule']}|{c['type']}"] = c
    merged_changes = sorted(merged.values(), key=lambda c: c["rule"])

    manifest = {
        "name": f"jdg-overlay-v{year}",
        "version": existing.get("version", date.today().isoformat()),
        "overlays_version": f"base-{existing.get('version', date.today().isoformat())}",
        "tax_year": year,
        "effective_from": f"{year}-01-01",
        "effective_to": f"{year}-12-31",
        "description": f"Overlay JDG dla roku podatkowego {year} — tylko zmienione reguły.",
        "changes": merged_changes,
        "files": [],
        "generated_by": "overlay_generator.py",
        "generated_at": date.today().isoformat(),
        "lkg": {"acts": (lkg or {}).get("acts_count"),
                "covered_nodes": (lkg or {}).get("covered_nodes")},
    }
    if not dry_run:
        mf_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
                           encoding="utf-8")
    return {
        "year": year, "changes_total": len(merged_changes),
        "changes_new": len(real), "ghosts": gh,
        "ghost_count": len(gh), "lkg_loaded": lkg is not None,
        "gate": "PASS" if not gh else "FAIL",
        "manifest": str(mf_path.relative_to(POLICIES_ROOT)) if not dry_run else None,
    }


def verify(year: int) -> dict:
    """Weryfikacja: zero duchów + zmiany ∈ base + TCL (interwały) z overlay_engine."""
    from overlay_engine import check_intervals, load_overlays
    catalog = scan_rules()
    catalog_rules = {r["rule"] for r in catalog}
    intervals = check_intervals()
    mf_path = OVERLAYS_DIR / f"v{year}" / "manifest.json"
    if not mf_path.exists():
        return {"year": year, "ok": False, "error": "manifest missing"}
    mf = json.loads(mf_path.read_text(encoding="utf-8"))
    gh = ghosts(mf.get("changes", []), catalog_rules)
    return {
        "year": year, "changes": len(mf.get("changes", [])),
        "ghost_count": len(gh), "ghosts": gh,
        "tcl_100": intervals.get("tcl_100"),
        "overlays": intervals.get("overlays"),
        "gate": "PASS" if not gh and intervals.get("tcl_100") else "FAIL",
    }


def main() -> None:
    p = argparse.ArgumentParser(description="JDG Overlay Generator (P19)")
    sub = p.add_subparsers(dest="cmd", required=True)
    g = sub.add_parser("generate"); g.add_argument("--year", type=int, default=2026)
    g.add_argument("--dry-run", action="store_true")
    g.set_defaults(fn=lambda a: print(json.dumps(generate(a.year, a.dry_run), ensure_ascii=False, indent=1)))
    v = sub.add_parser("verify"); v.add_argument("--year", type=int, default=2026)
    v.set_defaults(fn=lambda a: print(json.dumps(verify(a.year), ensure_ascii=False, indent=1)))
    s = sub.add_parser("scan"); s.set_defaults(fn=lambda a: print(json.dumps(
        {"rules": len(scan_rules())}, ensure_ascii=False, indent=1)))
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
