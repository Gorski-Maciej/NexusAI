#!/usr/bin/env python3
"""NexusAI JDG — V3-P48-I03 SYNC-IN-PR RULE — zmiana canonical bez
synchronicznego mirror = odrzucenie PR (podanalizy AN02). Weryfikuje spójność
zmian w tym samym PR (symulacja na stanie git: canonical dirty vs mirror dirty)
i integrity manifestu sync (sync poza PR = dryf czasowy).
"""
from __future__ import annotations

import subprocess

from v3_p48_common import (POLICIES_DIR, RULES_DIR, rule_present,
                           sync_manifest_age_days, utcnow_iso, write_bundle)

INNOVATION = "V3-P48-I03"
RULE = "jdg.v3_p48_mirror_sync.sync_in_pr"


def _git_dirty(path: str) -> int:
    """Liczba zmienionych plików *.rego pod ścieżką (git status porcelain)."""
    try:
        out = subprocess.run(
            ["git", "status", "--porcelain", "--", path],
            capture_output=True, text=True, timeout=30, check=False)
        return sum(1 for ln in out.stdout.splitlines()
                   if ln.strip() and ln.strip().endswith(".rego"))
    except (OSError, subprocess.TimeoutExpired):
        return 0


def main() -> int:
    checks, findings = [], []

    canonical_changed = _git_dirty(str(RULES_DIR))
    mirror_changed = _git_dirty(str(POLICIES_DIR))
    # Sync poza PR: mirror czysty (brak zmian w PR), a manifest sync świeży
    # mimo zmian canonical → sync wykonany poza transakcją PR (dryf czasowy).
    manifest_present, age_days = sync_manifest_age_days()
    out_of_pr_sync = 1 if (canonical_changed > 0 and mirror_changed == 0
                           and manifest_present) else 0

    checks.append({
        "name": "canonical_dirty_rego",
        "status": "OK",
        "detail": f"zmienione pliki rego w JDG/rules (stan roboczy PR): {canonical_changed}",
    })
    checks.append({
        "name": "mirror_dirty_rego",
        "status": "OK",
        "detail": f"zmienione pliki rego w policies/ (stan roboczy PR): {mirror_changed}",
    })
    coherent = not (canonical_changed > 0 and mirror_changed == 0)
    checks.append({
        "name": "sync_in_pr_coherent",
        "status": "OK" if coherent else "BLOCK",
        "detail": "zmiana canonical i mirror w tej samej PR" if coherent else
                  "canonical zmieniony bez synchronicznego mirror — PR odrzucona (I03)",
    })
    checks.append({
        "name": "no_out_of_pr_sync",
        "status": "OK" if out_of_pr_sync == 0 else "BLOCK",
        "detail": f"sync poza PR wykryty: {out_of_pr_sync} (manifest świeży przy niespójnym PR)",
    })
    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    if not coherent:
        findings.append({"severity": "HIGH",
                         "message": "sync-in-PR: dołóż mirror do tej samej PR albo deklarację OVERLAY.md"})
    if out_of_pr_sync:
        findings.append({"severity": "HIGH",
                         "message": "dryf czasowy: sync wykonany poza PR ze zmianą canonical"})

    routing = "BLOCK_AND_ALERT" if (not coherent or out_of_pr_sync > 0) else "AUTO_FILE"
    metrics = {
        "canonical_changed": canonical_changed,
        "mirror_changed": mirror_changed,
        "out_of_pr_sync": out_of_pr_sync,
        "sync_age_days": age_days,
        "routing": routing,
    }
    evidence = {"checks": checks, "findings": findings}
    write_bundle("sync_in_pr", INNOVATION, metrics, evidence)
    print(f"[{INNOVATION}] routing={routing} canonical_changed={canonical_changed} "
          f"mirror_changed={mirror_changed}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
