#!/usr/bin/env python3
"""NexusAI JDG — V3-P50-I04 SINGLE-SOURCE-OF-TRUTH REGISTER (zapytywalny).

Rejestr: zasada prawna (legal principle) → pakiet źródłowy → rule_id →
warianty jawne z powodem (prompt P50 Sekcja 10 I04; AP04; kontrakt P00
„jedno źródło prawdy per zasada").

Źródła rejestru (rozszerzanie, nie duplikacja — protokół 08):
  * overlaye celowe P48: policies/jdg/bundles/overlays/*/manifest.json
    (changes[] z rule + description) → warianty DEKLAROWANE (I10),
  * canonical: JDG/rules/** — rule_id jako kandydaci źródeł prawdy,
  * mirror policies/** — para 1:1 (P48-I02) nie jest wariantem.

Klasyfikacja per zasada:
  single_source        — rule_id występuje dokładnie raz w canonical,
  declared_variant     — rule_id jest obiektem zmiany overlay P48
                         (celowy wariant z powodem i oknem temporalnym),
  unregistered_variant — rule_id w wielu plikach canonical bez deklaracji
                         (rejestr duplikatów do decyzji per para I09).

Wyjście: bundles/v3_p50_single_source_register.json (gate=PASS; decyzja w
metrics.routing; zapytywalność: JSON kluczowany rule_id → source/variants).
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


def _declared_overlays() -> dict[str, list[dict]]:
    """rule_id → wpisy overlay (celowe warianty z powodem, P48-I05/I10)."""
    declared: dict[str, list[dict]] = defaultdict(list)
    if not OVERLAYS_DIR.exists():
        return declared
    for mf in sorted(OVERLAYS_DIR.rglob("manifest.json")):
        try:
            data = json.loads(mf.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        for ch in data.get("changes", []):
            rid = str(ch.get("rule", ""))
            if rid:
                declared[rid].append({
                    "overlay": str(mf.relative_to(OVERLAYS_DIR.parent)),
                    "type": ch.get("type"),
                    "reason": ch.get("description"),
                })
    return declared


def main() -> int:
    canon: dict[str, set[str]] = defaultdict(set)
    for rel, path in walk_rego(RULES_DIR).items():
        src = path.read_text(encoding="utf-8", errors="replace")
        for rid in RULE_ID_RE.findall(src):
            if not rid.endswith(_BOILER):
                canon[rid].add(rel)
    declared = _declared_overlays()

    register: dict[str, dict] = {}
    single = declared_v = unreg = 0
    for rid, files in sorted(canon.items()):
        n_files = len(files)
        n_decl = len(declared.get(rid, []))
        if n_files == 1 and n_decl == 0:
            klass = "single_source"
            single += 1
        elif n_decl > 0:
            klass = "declared_variant"
            declared_v += 1
        else:
            klass = "unregistered_variant"
            unreg += 1
        register[rid] = {
            "class": klass,
            "source_files": sorted(files),
            "declared_overlays": declared.get(rid, []),
        }

    total = single + declared_v + unreg
    routing = ("BLOCK_AND_ALERT" if total == 0
               else ("TRIAGE_QUEUE" if unreg > 0 else "AUTO_FILE"))
    metrics = {
        "principles_total": total,
        "principles_single_source": single,
        "principles_declared_variants": declared_v,
        "principles_unregistered_variants": unreg,
        "overlays_scanned": len(list(OVERLAYS_DIR.rglob("manifest.json")))
        if OVERLAYS_DIR.exists() else 0,
        "routing": routing,
    }
    evidence = {
        "unregistered_sample": [rid for rid, v in register.items()
                                if v["class"] == "unregistered_variant"][:80],
        "declared_sample": [
            {"rule_id": rid, **v["declared_overlays"][0]}
            for rid, v in register.items()
            if v["class"] == "declared_variant"][:40],
        "note": ("I04: zasada → pakiet → rule_id → warianty jawne z powodem; "
                 "overlaye P48 (celowe warianty temporalne/domenowe) = "
                 "deklaracje I10, nie duplikaty; unregistered_variant = "
                 "rejestr do decyzji per para (konsoliduj/usuń/deklaruj). "
                 "Zapytywalny: JSON kluczowany rule_id."),
        "generated_at": utcnow_iso(),
    }
    write_p50_bundle("single_source_register", "V3-P50-I04", metrics, evidence)
    # Zapytywalny rejestr pełny — osobny artefakt (I04 jest rejestrem)
    out = Path(__file__).resolve().parents[1] / "bundles" / \
        "v3_p50_source_of_truth_index.json"
    out.write_text(json.dumps(register, ensure_ascii=False, indent=2) + "\n",
                   encoding="utf-8")
    print(f"[V3-P50-I04] principles={total} single={single} "
          f"declared={declared_v} unregistered={unreg} routing={routing}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
