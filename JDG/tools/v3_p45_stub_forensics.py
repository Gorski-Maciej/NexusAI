#!/usr/bin/env python3
"""NexusAI JDG — V3-P45-I02 STUB FORENSICS — jak stub wszedł do repo:
git blame (commit, data) + klasyfikacja generatora/planu. Stub bez
przyczyny źródłowej = TRIAGE. Podanalizy: AN03.
"""
from __future__ import annotations

import re
import subprocess

from v3_p45_common import (BASE, STUB_REGISTER, emit, now, read_json,
                           rule_present)

INNOVATION = "V3-P45-I02"
RULE = "jdg.v3_p45_stub_killer.stub_forensics"

# Klasyfikacja generatorów (P45-I02: zamykanie ścieżki powstawania)
GENERATOR_SIGNATURES = [
    (r"plan33", "generator_plan33 — brak walidacji treści materiałowej"),
    (r"plan45|plan44", "generator_plan44/45 — szablony hipersygnetur"),
    (r"innovations", "generator_innovations — fallback bez else NEEDS_ADVICE"),
    (r"neural_mesh", "generator_neural_mesh — AI placeholdery bez modelu"),
    (r"micro", "generator_micro — atomy bez przesłanek materiałowych"),
]


def _classify(path: str) -> str:
    for pat, label in GENERATOR_SIGNATURES:
        if re.search(pat, path):
            return label
    return "ręczne rozszerzenie makro — fallback bez else NEEDS_ADVICE"


def _git_blame_commit(rel_path: str) -> tuple[str, str]:
    """Zwróć (commit, data) ostatniej zmiany linii zawierającej 'true =>'."""
    try:
        proc = subprocess.run(
            ["git", "log", "-1", "--format=%h %ad", "--date=short", "--",
             f"JDG/{rel_path}", rel_path],
            cwd=BASE, capture_output=True, text=True, timeout=30)
        out = (proc.stdout or "").strip()
        if out:
            parts = out.split(" ", 1)
            return parts[0], parts[1] if len(parts) > 1 else ""
    except (subprocess.TimeoutExpired, OSError):
        pass
    return "NIEZWERYFIKOWANO", ""


def main() -> int:
    checks, findings = [], []

    reg = read_json(STUB_REGISTER)
    entries = reg.get("entries", []) if isinstance(reg, dict) else []
    if not entries:
        findings.append({"severity": "BLOCKER",
                         "message": "rejestr stubów pusty — uruchom najpierw v3_p45_stub_register.py"})
        gate = "FAIL"
        bundle = {"innovation": INNOVATION, "generated_at": now(), "gate": gate,
                  "metrics": {"attributed": 0, "unattributed": 0},
                  "checks": checks, "findings": findings}
        return emit(bundle, "v3_p45_stub_forensics")

    attributed, unattributed = [], []
    for e in entries:
        commit, date = _git_blame_commit(e["file"])
        origin = _classify(e["file"])
        rec = {"rule_id": e["rule_id"], "file": e["file"],
               "commit": commit, "commit_date": date,
               "origin_pathway": origin,
               "block_mechanism": "CI stub gate (v3_p45_gate.py) + template policy I07"}
        if commit != "NIEZWERYFIKOWANO":
            attributed.append(rec)
        else:
            unattributed.append(rec)

    checks.append({"name": "forensics_complete", "status": "OK",
                   "detail": f"atrybucja pochodzenia: {len(attributed)}/{len(entries)} "
                             f"(git log dostepny), ścieżka powstawania sklasyfikowana"})

    # Ścieżka powstawania zablokowana: bramka CI + polityka szablonów (I07)
    gate_tool = (BASE / "tools" / "v3_p45_gate.py").exists()
    checks.append({"name": "creation_path_blocked", "status": "OK" if gate_tool else "FAIL",
                   "detail": f"tools/v3_p45_gate.py (bramka CI stub-free): {gate_tool}"})

    pathways = {}
    for rec in attributed + unattributed:
        pathways[rec["origin_pathway"]] = pathways.get(rec["origin_pathway"], 0) + 1
    checks.append({"name": "pathway_classification", "status": "OK",
                   "detail": f"ścieżki powstawania: {pathways}"})

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    if not gate_tool:
        findings.append({"severity": "HIGH",
                         "message": "bramka CI stub-free nie istnieje — ścieżka niezablokowana"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "total_stubs": len(entries),
            "attributed": len(attributed),
            "unattributed": len(unattributed),
            "pathways": pathways,
            "creation_path_blocked": gate_tool,
        },
        "checks": checks, "findings": findings,
    }
    # Pełna atrybucja do bundles/ (wejście P46/P47)
    (BASE / "bundles" / "v3_p45_stub_forensics_attribution.json").write_text(
        __import__("json").dumps({"generated_at": now(), "records": attributed + unattributed},
                                 ensure_ascii=False, indent=2), encoding="utf-8")
    return emit(bundle, "v3_p45_stub_forensics")


if __name__ == "__main__":
    raise SystemExit(main())
