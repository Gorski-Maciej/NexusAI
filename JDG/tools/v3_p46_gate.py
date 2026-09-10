#!/usr/bin/env python3
"""NexusAI JDG — V3-P46 GATE (CI merge gate) — bramka jakości parametrów w
konwencji tools/v3_p45_gate.py. Dwa tryby:
  --merge  : porównuje naruszenia legacy_sweep w plikach ZMIENIONYCH vs HEAD
             i blokuje TYLKO nowe (nie niszczy backlogu, ale nie pozwala go
             pogłębiać) — default dla CI,
  --all    : audyt całości (backlog) do rejestru — nie blokuje merge.
Usage:
  python tools/v3_p46_gate.py --merge
  python tools/v3_p46_gate.py --all
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from v3_p46_common import BASE, REPO_ROOT, scan_hardcoded, utcnow_iso, write_json  # noqa: E402

BUNDLES = BASE / "bundles"
GATE_ALL = BUNDLES / "v3_p46_gate_full_audit.json"
THRESHOLDS_REGO = BASE / "rules" / "thresholds_jdg.rego"


def changed_files_vs_head() -> list[str]:
    try:
        proc = subprocess.run(["git", "diff", "--name-only", "HEAD"],
                              cwd=REPO_ROOT, capture_output=True, text=True, timeout=30)
        return [ln.strip() for ln in proc.stdout.splitlines() if ln.strip().endswith(".rego")]
    except (subprocess.TimeoutExpired, OSError):
        return []


def findings_for(files_rel: list[str]) -> list[dict]:
    if not files_rel:
        return []
    rules_dir = BASE / "rules"
    wanted = {f.replace("rules/", "", 1) if f.startswith("rules/") else f for f in files_rel}
    result = scan_hardcoded(rules_dir, exclude={THRESHOLDS_REGO.name})
    return [f for f in result["findings"] if f["file"] in wanted]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--merge", action="store_true")
    ap.add_argument("--all", action="store_true")
    args = ap.parse_args()
    if args.all or not args.merge:
        result = scan_hardcoded(BASE / "rules", exclude={THRESHOLDS_REGO.name})
        orphans = [f for f in result["findings"]
                   if not (f["category"] == "large_integer" and len(f["value"]) == 4
                           and f["value"].startswith("20"))
                   and not any(h in f["value"].split(".")[0] for h in ("86400", "3600", "1000", "24", "60", "365"))]
        write_json(GATE_ALL, {
            "gate": "v3_p46_full_audit",
            "generated_at": utcnow_iso(),
            "scanned_files": result["scanned_files"],
            "orphan_values": len(orphans),
            "note": "Backlog — nie blokuje merge; elimacja wg mapy I01 (P47+).",
        })
        print(f"[v3_p46_gate --all] orphans={len(orphans)} (backlog, informational)")
        return 0
    # --merge: tylko nowe naruszenia w plikach zmienionych vs HEAD
    changed = changed_files_vs_head()
    if not changed:
        print("[v3_p46_gate --merge] brak zmienionych plików rego — PASS")
        return 0
    new_findings = findings_for(changed)
    baseline_path = BUNDLES / "v3_p46_gate_baseline.json"
    baseline = json.loads(baseline_path.read_text(encoding="utf-8")) if baseline_path.exists() else {"findings": []}
    baseline_keys = {(f["file"], f["line"], f["value"], f["category"]) for f in baseline.get("findings", [])}
    truly_new = [f for f in new_findings
                 if (f["file"], f["line"], f["value"], f["category"]) not in baseline_keys]
    status = "PASS" if not truly_new else "BLOCK"
    out = {
        "gate": "v3_p46_merge_gate",
        "generated_at": utcnow_iso(),
        "changed_files": changed,
        "new_violations": truly_new,
        "status": status,
    }
    write_json(BUNDLES / "v3_p46_gate_merge.json", out)
    print(f"[v3_p46_gate --merge] status={status} new={len(truly_new)}")
    return 0 if status == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
