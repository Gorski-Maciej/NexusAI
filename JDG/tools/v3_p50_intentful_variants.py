#!/usr/bin/env python3
"""NexusAI JDG — V3-P50-I10 INTENTFUL VARIANTS — celowe warianty jako overlaye.

Celowo różne warianty tej samej reguły (temporalne: ryczałt 2025 vs 2026;
domenowe: micro vs enterprise) przestają być duplikatami, gdy mają JAWNĄ
deklarację overlay (P48-I05): manifest z type (MODIFY/ADD), powodem
(description) i oknem temporalnym (effective_from/to) — prompt P50
Sekcja 10 I10; AP04; P05 temporalność.

Detekcja (dowód z plików, nie deklaracja):
  * ten sam rule_id w WIELU plikach canonical (warianty bez overlaya —
    rejestrowane przez I04 jako unregistered_variant),
  * deklaracje overlay: policies/jdg/bundles/overlays/*/manifest.json —
    changes[].rule + type + description (+ effective_from/to),
  * undeclared_variants = rule_id wielo-plikowe BEZ wpisu overlay.

routing: undeclared>0 → TRIAGE (zadeklarować overlay albo skonsolidować);
zero wariantów wielo-plikowych → AUTO_FILE.
Wyjście: bundles/v3_p50_intentful_variants.json.
"""
from __future__ import annotations

import json
import re
from collections import defaultdict
from pathlib import Path

from v3_p48_common import POLICIES_DIR, walk_rego
from v3_p50_common import RULES_DIR, write_p50_bundle
from v3_p49_common import utcnow_iso

RULE_ID_RE = re.compile(r'"rule_id"\s*[:=]\s*"([a-zA-Z0-9_.]+)"')
_BOILER = (".no_match", ".fallback", ".thresholds_missing",
           ".packages_missing", ".default")
OVERLAYS_DIR = POLICIES_DIR / "jdg" / "bundles" / "overlays"


def main() -> int:
    # warianty wielo-plikowe w canonical
    by_id: dict[str, set[str]] = defaultdict(set)
    for rel, path in walk_rego(RULES_DIR).items():
        src = path.read_text(encoding="utf-8", errors="replace")
        for rid in RULE_ID_RE.findall(src):
            if not rid.endswith(_BOILER):
                by_id[rid].add(rel)
    multi = {rid: files for rid, files in by_id.items() if len(files) > 1}

    # deklaracje overlay (celowe warianty)
    declared: dict[str, list[dict]] = defaultdict(list)
    n_overlays = 0
    if OVERLAYS_DIR.exists():
        for mf in sorted(OVERLAYS_DIR.rglob("manifest.json")):
            n_overlays += 1
            try:
                data = json.loads(mf.read_text(encoding="utf-8"))
            except json.JSONDecodeError:
                continue
            for ch in data.get("changes", []):
                rid = str(ch.get("rule", ""))
                if rid:
                    declared[rid].append({
                        "overlay": mf.name,
                        "type": ch.get("type"),
                        "reason": ch.get("description"),
                        "effective_from": data.get("effective_from"),
                        "effective_to": data.get("effective_to"),
                    })

    declared_variants = sum(1 for rid in multi if rid in declared)
    undeclared = sorted(set(multi) - set(declared))
    routing = ("TRIAGE_QUEUE" if undeclared else "AUTO_FILE")
    metrics = {
        "multi_file_rule_ids": len(multi),
        "declared_variants": declared_variants,
        "undeclared_variants": len(undeclared),
        "overlays_scanned": n_overlays,
        "routing": routing,
    }
    evidence = {
        "undeclared_sample": [
            {"rule_id": rid, "files": sorted(multi[rid])[:4]}
            for rid in undeclared[:60]],
        "declared_sample": [
            {"rule_id": rid, **declared[rid][0]}
            for rid in sorted(set(multi) & set(declared))[:40]],
        "note": ("I10: warianty celowe (temporalne/domenowe) z deklaracją "
                 "overlay P48 = architektura, nie duplikaty. Undeclared = "
                 "zadeklarować (overlay z powodem + oknem) albo skonsolidować "
                 "(I09 z golden replay). Anty-FP: boilerplate no_match/"
                 "thresholds_missing wykluczony."),
        "scanned_at": utcnow_iso(),
    }
    write_p50_bundle("intentful_variants", "V3-P50-I10", metrics, evidence)
    print(f"[V3-P50-I10] multi={len(multi)} declared={declared_variants} "
          f"undeclared={len(undeclared)} routing={routing}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
