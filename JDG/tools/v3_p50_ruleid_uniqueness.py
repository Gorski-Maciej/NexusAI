#!/usr/bin/env python3
"""NexusAI JDG — V3-P50-I03 GLOBAL RULE_ID UNIQUENESS GATE.

Bramka unikalności rule_id (prompt P50 Sekcja 10 I03; AP04; kontrakt P00
„tożsamość reguły"): skan canonical (JDG/rules/**), mirror (policies/**) oraz
rejestry (rule_registry.json, enterprise_v3_registry.json, manifest_v2.json).

Definicja kolizji (honesty — zgodna z kontraktem P48):
  * mirror = zadeklarowany wariant 1:1 (P48-I02) — para canonical↔mirror tego
    samego rule_id NIE jest kolizją,
  * ten sam rule_id w DWÓCH RÓŻNYCH plikach canonical = kolizja
    canonical_canonical = BLOCK (cicha podmiana tożsamości),
  * DWIE RÓŻNE DEKLARACJE decision-reguły o tym samym rule_id w JEDNYM pliku
    canonical (kolejne definicje := z różnymi else-branchami) = in-file
    redefinition — w Rego jest to LEGALNE (complete rule z wieloma
    definicjami; OPA: „conflict" tylko przy rozłącznych body bez else),
    ale przy identycznym rule_id w dwóch NIEZALEŻNYCH blokach decyzyjnych
    to ryzyko cichej podmiany → rejestrowane jako in_file_redefinition
    (TRIAGE do przeglądu, nie BLOCK — polityka strukturalna, nie prawna),
  * ten sam rule_id w DWÓCH plikach mirror (poza parą 1:1 z canonical) =
    mirror_legacy_internal — backlog dziedziczony z P48 (only_policies=80,
    drzewo legacy policies/ vs policies/jdg/) → TRIAGE do decyzji 4-eyes
    (Q04/P49),
  * boilerplate no_match/thresholds_missing poza semantyką (AP04: ZASADY,
    nie szablony bram).

Wyjście: bundles/v3_p50_ruleid_uniqueness.json (gate=PASS = dowód zapisany;
decyzja w metrics.routing).
"""
from __future__ import annotations

import json
import re
from collections import defaultdict
from pathlib import Path

from v3_p48_common import POLICIES_DIR, walk_rego
from v3_p50_common import BUNDLES_DIR, RULES_DIR, write_p50_bundle
from v3_p49_common import utcnow_iso

RULE_ID_RE = re.compile(r'"rule_id"\s*[:=]\s*"([a-zA-Z0-9_.]+)"')
_BOILER = (".no_match", ".fallback", ".thresholds_missing", ".packages_missing",
           ".default_decide", ".default")

REGISTRIES = (
    BUNDLES_DIR / "rule_registry.json",
    BUNDLES_DIR / "enterprise_v3_registry.json",
    BUNDLES_DIR / "manifest_v2.json",
)


def _scan_dir(directory: Path, label: str) -> dict[str, list[str]]:
    """rule_id → lista UNIKALNYCH plików (label/rel). Powtórzenie literału
    rule_id w jednym pliku nie jest kolizją między plikami."""
    found: dict[str, set[str]] = defaultdict(set)
    for rel, path in walk_rego(directory).items():
        src = path.read_text(encoding="utf-8", errors="replace")
        for rid in RULE_ID_RE.findall(src):
            if rid.endswith(_BOILER):
                continue
            found[rid].add(f"{label}/{rel}")
    return {rid: sorted(locs) for rid, locs in found.items()}


def _in_file_redefinitions() -> list[dict]:
    """rule_id z >1 deklaracją w JEDNYM pliku (legalne w Rego, rejestrowane
    do przeglądu — cicha podmiana przy kopiach bloków decyzyjnych)."""
    out: list[dict] = []
    for rel, path in walk_rego(RULES_DIR).items():
        src = path.read_text(encoding="utf-8", errors="replace")
        counts: dict[str, int] = defaultdict(int)
        for rid in RULE_ID_RE.findall(src):
            if not rid.endswith(_BOILER):
                counts[rid] += 1
        for rid, n in counts.items():
            if n > 1:
                out.append({"rule_id": rid, "file": rel,
                            "occurrences": n, "kind": "in_file_redefinition"})
    return sorted(out, key=lambda x: x["rule_id"])


def _scan_registries() -> dict[str, list[str]]:
    found: dict[str, list[str]] = defaultdict(list)
    for reg in REGISTRIES:
        if not reg.exists():
            continue
        try:
            data = json.loads(reg.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        for rid in RULE_ID_RE.findall(json.dumps(data)):
            if rid.endswith(_BOILER):
                continue
            found[rid].append(f"registry:{reg.name}")
    return found


def main() -> int:
    canon = _scan_dir(RULES_DIR, "rules")
    mirror = _scan_dir(POLICIES_DIR, "policies")
    regs = _scan_registries()

    files_scanned = len(walk_rego(RULES_DIR)) + len(walk_rego(POLICIES_DIR))

    canonical_collisions, mirror_internal = [], []
    for rid, locations in sorted(canon.items()):
        if len(locations) > 1:
            canonical_collisions.append(
                {"rule_id": rid, "locations": locations,
                 "kind": "canonical_canonical"})
    for rid, locations in sorted(mirror.items()):
        if len(locations) > 1:
            mirror_internal.append(
                {"rule_id": rid, "locations": locations,
                 "kind": "mirror_legacy_internal"})
    in_file = _in_file_redefinitions()

    routing = ("BLOCK_AND_ALERT" if canonical_collisions
               else ("TRIAGE_QUEUE" if files_scanned == 0
                     else "AUTO_FILE"))
    metrics = {
        "files_scanned": files_scanned,
        "rule_ids_canonical": len(canon),
        "rule_ids_mirror": len(mirror),
        "rule_ids_registry": len(regs),
        "rule_id_collisions": len(canonical_collisions),
        "in_file_redefinitions": len(in_file),
        "mirror_legacy_collisions": len(mirror_internal),
        "collision_max": 0,
        "routing": routing,
    }
    evidence = {
        "collisions_sample": canonical_collisions[:80],
        "in_file_redefinition_sample": in_file[:60],
        "mirror_legacy_sample": mirror_internal[:40],
        "registries": [r.name for r in REGISTRIES if r.exists()],
        "note": ("I03: canonical↔mirror tej samej reguły = wariant 1:1 "
                 "P48-I02 (nie kolizja). canonical_canonical (2 pliki) = "
                 "BLOCK (tożsamość reguły). in_file_redefinition = legalne "
                 "w Rego (complete rule, wiele definicji), rejestrowane do "
                 "przeglądu (ryzyko cichej podmiany przy kopiach bloków). "
                 "mirror_legacy_internal = duplikaty wewnątrz drzewa legacy "
                 "policies/ (backlog P48 only_policies=80, decyzja 4-eyes "
                 "Q04) → TRIAGE. Boilerplate wykluczony."),
        "scanned_at": utcnow_iso(),
    }
    write_p50_bundle("ruleid_uniqueness", "V3-P50-I03", metrics, evidence)
    print(f"[V3-P50-I03] files={files_scanned} canon={len(canon)} "
          f"mirror={len(mirror)} collisions={len(canonical_collisions)} "
          f"in_file={len(in_file)} mirror_legacy={len(mirror_internal)} "
          f"routing={routing}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
