#!/usr/bin/env python3
"""NexusAI JDG — V3-P49-I04 CHAOS INPUT SUITE (property-based fail-closed).

12 scenariuszy mutacji input (kryterium 20 raportu: min. 10) — każda mutacja
jest ewaluowana na polityce P49 (OPA eval) z asercją: NIGDY cichy AUTO_POST
na ścieżce niepewności (AP07). Klasy mutacji:
  braki pól kontraktu P03 · złe typy · skrajne wartości · konflikty pakietów ·
  wartości spoza zakresu · niepewność prawna (brak wersji progów).

Uruchomienie: wymaga ./bin/opa (konwencja R21 — dowód = wynik uruchomienia,
nie deklaracja). Wyjście: v3_p49_chaos_input.json.
"""
from __future__ import annotations

import json
import subprocess
import tempfile
from pathlib import Path

from v3_p48_common import RULES_DIR, THRESHOLDS_REGO, read_json, utcnow_iso
from v3_p49_common import write_p49_bundle

BUNDLES = Path(__file__).resolve().parents[1] / "bundles"
P49_REGO = RULES_DIR / "v3_p49_fail_closed.rego"
OPA = Path(__file__).resolve().parents[2] / "bin" / "opa"

FAIL_CLOSED_MODES = {"NEEDS_ADVICE", "MANUAL_REVIEW", "BLOCK", "TRIAGE"}

# ── 12 scenariuszy chaos (każdy: nazwa, mutacja inputu P49, oczekiwany tryb) ──
BASE_CTX = {
    "analysis": "default_deny_core",
    "default_deny_core": {"silent_auto_posts": 0, "auto_post_without_evidence": 0,
                          "auto_post_total": 4, "auto_post_full_evidence_chain": 4},
}
SCENARIOS = [
    {"id": "CH01-missing-analysis", "expect": "no_match_or_safe",
     "mut": lambda inp: inp["v3_p49"].pop("analysis")},
    {"id": "CH02-null-analysis", "expect": "no_match_or_safe",
     "mut": lambda inp: inp["v3_p49"].update({"analysis": None})},
    {"id": "CH03-empty-analysis", "expect": "no_match_or_safe",
     "mut": lambda inp: inp["v3_p49"].update({"analysis": ""})},
    {"id": "CH04-missing-context", "expect": "no_match_or_safe",
     "mut": lambda inp: inp.pop("v3_p49")},
    {"id": "CH05-silent-auto-post", "expect": "fail_closed_mode",
     "mut": lambda inp: inp["v3_p49"].update({
         "analysis": "default_deny_core",
         "default_deny_core": {"silent_auto_posts": 1, "auto_post_without_evidence": 0,
                               "auto_post_total": 4, "auto_post_full_evidence_chain": 4}})},
    {"id": "CH06-partial-evidence", "expect": "fail_closed_mode",
     "mut": lambda inp: inp["v3_p49"].update({
         "analysis": "default_deny_core",
         "default_deny_core": {"silent_auto_posts": 0, "auto_post_without_evidence": 1,
                               "auto_post_total": 4, "auto_post_full_evidence_chain": 3}})},
    {"id": "CH07-negative-counts", "expect": "no_match_or_safe",
     "mut": lambda inp: inp["v3_p49"].update({
         "analysis": "default_deny_core",
         "default_deny_core": {"silent_auto_posts": -5, "auto_post_without_evidence": -5,
                               "auto_post_total": -5, "auto_post_full_evidence_chain": -5}})},
    {"id": "CH08-wrong-types", "expect": "no_match_or_safe",
     "mut": lambda inp: inp["v3_p49"].update({
         "analysis": "default_deny_core",
         "default_deny_core": {"silent_auto_posts": "many", "auto_post_without_evidence": True,
                               "auto_post_total": None, "auto_post_full_evidence_chain": []}})},
    {"id": "CH09-extreme-values", "expect": "fail_closed_mode",
     "mut": lambda inp: inp["v3_p49"].update({
         "analysis": "default_deny_core",
         "default_deny_core": {"silent_auto_posts": 10**9, "auto_post_without_evidence": 10**9,
                               "auto_post_total": 10**9, "auto_post_full_evidence_chain": 0}})},
    {"id": "CH10-thresholds-conflict", "expect": "fail_closed_mode",
     "mut": lambda inp: inp.update({"__drop_thresholds__": True})},
    {"id": "CH11-bypass-flag", "expect": "fail_closed_mode",
     "mut": lambda inp: inp["v3_p49"].update({"default_deny_bypassed": True})},
    {"id": "CH12-amount-ceiling-breach", "expect": "fail_closed_mode",
     "mut": lambda inp: inp["v3_p49"].update({
         "analysis": "amount_ceiling",
         "amount_ceiling": {"auto_post_amount": 999999, "limit_configured": True,
                            "limit_breaches": 0}})},
]


def _drop_thresholds() -> str:
    """Wariant data bez bloku v3_p49 (symulacja konfliktu/braku snapshotu)."""
    src = THRESHOLDS_REGO.read_text(encoding="utf-8", errors="replace")
    lines = src.splitlines(keepends=True)
    out, skipping = [], False
    for ln in lines:
        if ln.startswith("v3_p49 := {"):
            skipping = True
            continue
        if skipping:
            if ln.startswith("}"):
                skipping = False
            continue
        out.append(ln)
    return "".join(out)


def _eval(input_obj: dict, thresholds_src: str | None = None) -> dict:
    with tempfile.TemporaryDirectory() as td:
        tdp = Path(td)
        (tdp / "thresholds.rego").write_text(
            thresholds_src or THRESHOLDS_REGO.read_text(encoding="utf-8", errors="replace"),
            encoding="utf-8")
        (tdp / "policy.rego").write_text(
            P49_REGO.read_text(encoding="utf-8", errors="replace"), encoding="utf-8")
        ipath = tdp / "input.json"
        ipath.write_text(json.dumps(input_obj), encoding="utf-8")
        proc = subprocess.run(
            [str(OPA), "eval", "--format=json", "-d", str(tdp / "thresholds.rego"),
             "-d", str(tdp / "policy.rego"), "-i", str(ipath),
             "data.jdg.v3_p49_fail_closed.decide"],
            capture_output=True, text=True, timeout=60)
        if proc.returncode != 0:
            return {"error": proc.stderr[:300]}
        try:
            res = json.loads(proc.stdout)
            return res["result"][0]["expressions"][0]["value"]
        except (json.JSONDecodeError, KeyError, IndexError):
            return {"error": "eval_parse_failed"}


def run_suite() -> list[dict]:
    results = []
    for sc in SCENARIOS:
        inp = {"jdg_entrepreneur": {"v3_p49_check": True},
               "v3_p49": json.loads(json.dumps(BASE_CTX))}
        sc["mut"](inp)
        drop = inp.pop("__drop_thresholds__", False)
        verdict = _eval(inp, _drop_thresholds() if drop else None)
        dm = verdict.get("decision_mode")
        rid = verdict.get("rule_id", "")
        if "error" in verdict:
            status = "ERROR"
            fail_closed = False
        elif dm in FAIL_CLOSED_MODES:
            status = "PASS"
            fail_closed = True
        elif verdict.get("matched") is False:
            status = "PASS"
            fail_closed = True  # no_match = brak aktywacji ścieżki = brak cichego posta
        else:
            status = "FAIL_CLOSED_VIOLATION"
            fail_closed = False
        results.append({
            "id": sc["id"], "status": status, "fail_closed": fail_closed,
            "rule_id": rid, "decision_mode": dm,
        })
    return results


def main() -> int:
    results = run_suite()
    violations = sum(1 for r in results if not r["fail_closed"])
    errors = sum(1 for r in results if r["status"] == "ERROR")
    metrics = {
        "cases_total": len(results),
        "fail_closed_violations": violations,
        "eval_errors": errors,
        "suite_run": True,
        "routing": ("BLOCK_AND_ALERT" if violations > 0
                    else ("TRIAGE_QUEUE" if errors > 0 else "AUTO_FILE")),
    }
    evidence = {
        "results": results,
        "scenarios": [s["id"] for s in SCENARIOS],
        "note": ("Asercja chaos: każda mutacja (braki, złe typy, skrajne wartości, "
                 "konflikt progów, bypass) kończy się NEEDS_ADVICE/MANUAL_REVIEW/"
                 "BLOCK/TRIAGE albo no_match — nigdy cichym AUTO_POST (AP07)."),
        "evaluated_at": utcnow_iso(),
    }
    write_p49_bundle("chaos_input", "V3-P49-I04", metrics, evidence)
    print(f"[V3-P49-I04] cases={len(results)} violations={violations} errors={errors}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
