#!/usr/bin/env python3
"""
NexusAI JDG — V3-P10-I10 RETRO-DELTA EXPLORER
===============================================
Przeglądarka delt historycznych: każda zmiana werdyktu w czasie to wpis
z uzasadnieniem (autojustify), wersją bundle i wyrokiem. Sprawdza, czy
istnieje historia delt (replay/annotations) i czy da się ją przeglądać.

Usage:
  python tools/v3_p10_retro_delta_explorer.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    # artefakty historii GOLDEN (nie mirror/shadow — to nie są delty oracle):
    # annotacje golden_replay, delta log golden, sesje replay, historia werdyktów
    # historia = osobny artefakt DELT/ANNOTACJI (nie sam golden set, nie tmp, nie
    # artefakty innych części o nazwie golden_*):
    history_files = sorted(
        p.name for p in BUNDLES.glob("*.json")
        if any(k in p.name for k in ("replay", "annot", "delta_history", "delta_log",
                                     "oracle_history"))
        and "golden_verdicts" not in p.name and "tmp" not in p.name
        and not p.name.startswith("v3_p10_") and "mirror" not in p.name
        and "shadow" not in p.name)
    golden = BUNDLES / "golden_verdicts.json"
    verdicts = json.loads(golden.read_text(encoding="utf-8")).get("verdicts", {}) if golden.exists() else {}

    # źródło prawdy historii: bundle_version + recorded_at w rekordach
    versions = {}
    for rec in verdicts.values():
        v = rec.get("bundle_version", "?")
        versions.setdefault(v, 0)
        versions[v] += 1

    # rekordy z adnotacją intentional/manual = ślad decyzji o zmianie (golden_replay annotate)
    # adnotacje golden_replay (annotate) zapisywane są w samej strukturze werdyktu
    annotated = [k for k, rec in verdicts.items()
                 if rec.get("annotation") or rec.get("manual_note")
                 or rec.get("annotations")]
    has_history_artifact = bool(history_files) or bool(annotated)
    multi_version_history = len(versions) >= 2

    checks.append({"name": "history_artifacts", "status": "OK" if has_history_artifact else "FAIL",
                   "detail": f"artefakty historii GOLDEN w bundles/: {history_files} "
                             f"| rekordy z adnotacją: {len(annotated)}"})
    checks.append({"name": "versioned_history", "status": "OK" if multi_version_history else "FAIL",
                   "detail": f"rekordy w {len(versions)} wersjach bundle — podstawa przeglądania "
                             f"delt między wersjami"})

    if not has_history_artifact:
        findings.append({"id": "V3-P10-L10", "severity": "P2",
                         "evidence": "brak artefaktu historii delt (annotacje golden_replay / delta "
                                     "log / sesje) — delta między wersjami bundle nie jest "
                                     "przeglądalna ani ucząca (P10-AN09, P67 self-learning)",
                         "fix": "I10: retro-delta explorer — zapis delt przy każdym replay + "
                                "przeglądarka z uzasadnieniami (web/JSON) i eksportem do P67"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P10-I10",
        "name": "Retro-Delta Explorer — historia delt z uzasadnieniami",
        "generated_at": now(),
        "gate": gate,
        "metrics": {"history_artifacts": history_files,
                    "annotated_records": len(annotated),
                    "bundle_versions_in_set": list(versions),
                    "version_count": len(versions)},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P67 (self-learning), P37, P44",
                     "rule": "każda delta historyczna ma wpis: stary hash, nowy hash, uzasadnienie, "
                             "wyrok, wersje bundle"}}
    (BUNDLES / "v3_p10_retro_delta_explorer.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P10-I10] gate={gate} history={history_files} annotated={len(annotated)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
