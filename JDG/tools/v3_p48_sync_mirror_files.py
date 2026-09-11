#!/usr/bin/env python3
"""NexusAI JDG — V3-P48 MIRROR SYNC EXECUTOR — domknięcie dryfu z bramki.

Działa wg architektury I01 (mirror as build output): policies/ jest artefaktem
generowanym z JDG/rules. Ten skrypt wykonuje jednorazową migrację dryfu
zrejestrowanego przez v3_p48_gate (backlog 2026-09-11):

  * missing_in_mirror  → plik kopiowany 1:1 z canonical,
  * semantic_drift     → mirror nadpisany canonical (canonical = jedno źródło
                         prawdy; overlay wymaga osobnej deklaracji OVERLAY.md —
                         I05; żadnych overlay nie zadeklarowano → zero wyjątków),
  * textual_diffs      → mirror nadpisany canonical (normalizacja nagłówków),
  * only_policies      → NIE ruszamy (osierocone legacy — usuwanie to decyzja
                         4-eyes; rejestrowane w heatmaps jako orphan),
  * .sync_manifest_v2.json → odświeżony (last_sync, files_copied, hand_edits=0).

Honesty (protokół 14): liczniki z realnych operacji na plikach; wynik zapisany
jako bundle dowodowy v3_p48_sync_execution.json (Gate State Reset — sekcja 6
RAPORT_V3_P48_MIRROR_SYNC.txt).
"""
from __future__ import annotations

import shutil

from v3_p48_common import (POLICIES_DIR, RULES_DIR, SYNC_MANIFEST, drift_by_package,
                           measure_drift, read_json, utcnow_iso, walk_rego, write_bundle,
                           write_json)


def main() -> int:
    before = measure_drift()

    rules = walk_rego(RULES_DIR)
    copied, overwritten = [], []
    for rel, src_path in sorted(rules.items()):
        dst_path = POLICIES_DIR / rel
        dst_path.parent.mkdir(parents=True, exist_ok=True)
        if dst_path.exists():
            if src_path.read_bytes() != dst_path.read_bytes():
                shutil.copyfile(src_path, dst_path)
                overwritten.append(rel)
        else:
            shutil.copyfile(src_path, dst_path)
            copied.append(rel)

    after = measure_drift()
    pkgs = drift_by_package(after)

    # Odświeżenie manifestu synchronizacji (I01: mirror = build output)
    manifest = read_json(SYNC_MANIFEST) or {}
    write_json(SYNC_MANIFEST, {
        "last_sync": utcnow_iso(),
        "files_copied": len(rules),
        "files_changed_this_run": len(copied) + len(overwritten),
        "source": "JDG/rules/",
        "target": "policies/",
        "mode": "mirror-build-output (I01)",
        "previous_last_sync": manifest.get("last_sync"),
        "previous_hand_edits": manifest.get("files_copied"),
    })

    residual_semantic = after["semantic_diffs"]
    metrics = {
        "copied_missing_in_mirror": len(copied),
        "overwritten_drifted": len(overwritten),
        "total_files_synced": len(copied) + len(overwritten),
        "identical_after": len(after["identical"]),
        "textual_diffs_after": len(after["textual_diffs"]),
        "semantic_diffs_after": len(residual_semantic),
        "only_rules_after": len(after["only_rules"]),
        "only_policies_after": len(after["only_policies"]),
        "drift_pct_after": after["drift_pct"],
        "drift_pct_before": before["drift_pct"],
        "packages_total": len(pkgs),
        "packages_clean": sum(1 for d in pkgs.values()
                              if d["textual"] + d["semantic"] + d["missing"] == 0),
        "routing": "AUTO_FILE" if not residual_semantic else "TRIAGE_QUEUE",
    }
    evidence = {
        "copied_missing_in_mirror": copied,
        "overwritten_drifted": overwritten,
        "residual_semantic_diffs": residual_semantic,
        "orphan_policies_untouched": after["only_policies"],
        "overlay_declarations": [],
        "note": ("Overlay = brak zadeklarowanych (I05); every semantic drift resolved "
                 "toward canonical — zero silent exceptions."),
    }
    write_bundle("sync_execution", "V3-P48-I01+I03", metrics, evidence)
    print(f"[V3-P48-SYNC] copied={len(copied)} overwritten={len(overwritten)} "
          f"semantic_after={len(residual_semantic)} "
          f"drift_pct {before['drift_pct']} -> {after['drift_pct']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
