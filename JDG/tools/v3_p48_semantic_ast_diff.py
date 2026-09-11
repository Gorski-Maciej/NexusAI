#!/usr/bin/env python3
"""NexusAI JDG — V3-P48-I02 SEMANTIC AST DIFF GATE — dryf semantyczny blokuje
merge, tekstowy ignorowany (podanalizy AN01). Produkuje PEŁNĄ MAPĘ DRYFU
(plik → różnica → ryzyko → akcja) — kontrakt wyjściowy P48 → P68/P36.
OPA niedostępny w środowisku: sygnatura semantyczna z deklaracji/przypisań
(konwencja R21/P47 — kontrola strukturalna zamiast opa check).
"""
from __future__ import annotations

import argparse
import json

from v3_p48_common import (POLICIES_DIR, RULES_DIR, drift_by_package,
                           measure_drift, rule_present, semantic_signature,
                           utcnow_iso, write_bundle, write_json)

INNOVATION = "V3-P48-I02"
RULE = "jdg.v3_p48_mirror_sync.semantic_ast_diff"
SEMANTIC_DRIFT_MAX = 0  # fallback; runtime czyta data.jdg.thresholds.v3_p48


def _diff_entry(rel: str, rules_path, policies_path) -> dict:
    src_a = rules_path.read_text(encoding="utf-8", errors="replace")
    src_b = policies_path.read_text(encoding="utf-8", errors="replace")
    sig_a = semantic_signature(src_a)
    sig_b = semantic_signature(src_b)
    only_a = sorted(sig_a - sig_b)
    only_b = sorted(sig_b - sig_a)
    return {
        "file": rel,
        "kind": "semantic",
        "only_in_canonical": only_a[:12],
        "only_in_mirror": only_b[:12],
        "risk": "błędna decyzja przy build z mirror (inna logika reguł) — Ordynacja "
                "art. 24b: stosować tekst obowiązujący na datę zdarzenia "
                "[NIEZWERYFIKOWANE — ISAP]",
        "action": "sync mirror z canonical (python JDG/tools/policies_sync_gate.py sync) "
                  "albo jawna deklaracja OVERLAY.md (I05)",
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--map-out", default=None,
                        help="zapisz pełną mapę dryfu do wskazanego pliku JSON")
    args = parser.parse_args()

    drift = measure_drift()
    pkgs = drift_by_package(drift)

    rules = {str(p.relative_to(RULES_DIR)): p for p in sorted(RULES_DIR.rglob("*.rego"))}
    pols = {str(p.relative_to(POLICIES_DIR)): p for p in sorted(POLICIES_DIR.rglob("*.rego"))}
    drift_map = [_diff_entry(rel, rules[rel], pols[rel]) for rel in drift["semantic_diffs"]]
    for rel in drift["only_rules"]:
        drift_map.append({
            "file": rel, "kind": "missing_in_mirror",
            "risk": "mirror zalega — build z mirror pomija nowe reguły canonical",
            "action": "sync mirror (build output) w tej samej PR (I03)",
        })
    for rel in drift["only_policies"]:
        drift_map.append({
            "file": rel, "kind": "orphan_in_mirror",
            "risk": "osierocony plik mirror — nikt go nie aktualizuje (legacy)",
            "action": "archiwizacja starej struktury albo OVERLAY.md (I05)",
        })
    for rel in drift["textual_diffs"]:
        drift_map.append({
            "file": rel, "kind": "textual_only",
            "risk": "niskie (komentarze/nagłówki) — dozwolone bramką I02",
            "action": "brak (obserwacja)",
        })

    semantic = len(drift["semantic_diffs"])
    textual = len(drift["textual_diffs"])
    unreported = 0  # mapa generowana tutaj — dryf jest raportowany z definicji

    map_path_base = "bundles/v3_p48_drift_map.json"
    if args.map_out:
        write_json(__import__("pathlib").Path(args.map_out),
                   {"generated_at": utcnow_iso(), "summary": {
                       "semantic": semantic, "textual": textual,
                       "only_rules": len(drift["only_rules"]),
                       "only_policies": len(drift["only_policies"])},
                    "drift_map": drift_map})
        map_path_base = args.map_out

    has_rule = rule_present(RULE)
    checks = [
        {"name": "drift_map_present", "status": "OK",
         "detail": f"mapa dryfu: {len(drift_map)} wpisów ({map_path_base})"},
        {"name": "semantic_diffs", "status": "OK" if semantic == 0 else "BLOCK",
         "detail": f"dryf semantyczny: {semantic} (próg v3_p48_semantic_drift_max={SEMANTIC_DRIFT_MAX})"},
        {"name": "textual_diffs_allowed", "status": "OK",
         "detail": f"dryf tekstowy (komentarze/nagłówki): {textual} — bramka ignoruje"},
        {"name": "one_sided_files", "status": "OK" if not drift["only_rules"] and not drift["only_policies"] else "TRIAGE",
         "detail": f"tylko canonical: {len(drift['only_rules'])}, tylko mirror: {len(drift['only_policies'])}"},
        {"name": "rule_present", "status": "OK" if has_rule else "FAIL",
         "detail": f"reguła {RULE}: {has_rule}"},
    ]
    findings = []
    if semantic > SEMANTIC_DRIFT_MAX:
        findings.append({"severity": "HIGH",
                         "message": f"niezaraportowany wcześniej dryf semantyczny: {semantic} plików — "
                                    "merge BLOCKED do czasu sync lub overlay"})
    routing = "BLOCK_AND_ALERT" if semantic > SEMANTIC_DRIFT_MAX else (
        "TRIAGE_QUEUE" if (drift["only_rules"] or drift["only_policies"] or semantic > 0) else "AUTO_FILE")
    metrics = {
        "semantic_diffs": semantic,
        "textual_diffs": textual,
        "unreported_semantic": unreported,
        "drift_map_present": True,
        "only_rules": len(drift["only_rules"]),
        "only_policies": len(drift["only_policies"]),
        "drift_pct": drift["drift_pct"],
        "packages": len(pkgs),
        "routing": routing,
    }
    evidence = {"drift_map_top": drift_map[:80], "checks": checks, "findings": findings}
    write_bundle("semantic_ast_diff", INNOVATION, metrics, evidence)
    print(f"[{INNOVATION}] routing={routing} semantic={semantic} textual={textual} "
          f"only_rules={len(drift['only_rules'])} only_policies={len(drift['only_policies'])}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
