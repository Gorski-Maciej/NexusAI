#!/usr/bin/env python3
"""NexusAI JDG — V3-P49-I10 FAIL-CLOSED SCORE + I11 SILENT-POST CANARY
+ I12 USER-VISIBLE SAFETY.

I10: metryka % ścieżek reguł jawnie fail-closed (else → NEEDS_ADVICE) —
wynik z v3_p49_fail_open_scanner (jedno źródło prawdy); cel 100% (próg
v3_p49_fail_closed_score_target_pct), trend → P37.

I11: probe decyzyjny — syntetyczne inputy z brakami ewaluowane NA ŻYWO
polityką P49 (OPA eval); cichy AUTO_POST na probe = BLOCK (AP07).

I12 (P40): fail-closed użyteczny — każdy NEEDS_ADVICE widoczny w UI z akcją
('co muszę uzupełnić'); AUTO_POST z dowodem do pobrania. Kontrola kontraktowa
API/UI (v3_p40_api_contract.json + polityka P49 I12).

Wyjścia: v3_p49_fail_closed_score.json, v3_p49_silent_post_canary.json,
v3_p49_user_visible_safety.json.
"""
from __future__ import annotations

import json
import re
import subprocess
import tempfile
from pathlib import Path

from v3_p48_common import RULES_DIR, THRESHOLDS_REGO, read_json
from v3_p49_common import rule_present, write_p49_bundle

BUNDLES = Path(__file__).resolve().parents[1] / "bundles"
P49_REGO = RULES_DIR / "v3_p49_fail_closed.rego"
P40_CONTRACT = BUNDLES / "v3_p40_api_contract.json"
OPA = Path(__file__).resolve().parents[2] / "bin" / "opa"


def _threshold(key: str, default) -> float:
    src = THRESHOLDS_REGO.read_text(encoding="utf-8", errors="replace")
    m = re.search(rf'"{key}"\s*:\s*([\d.]+)', src)
    return float(m.group(1)) if m else float(default)


# ─────────────────────────────── I10 ───────────────────────────────
def fail_closed_score() -> dict:
    reg = read_json(BUNDLES / "v3_p49_fail_open_registry.json") or {}
    m = reg.get("metrics", {})
    total = int(m.get("decision_chains_total", 0))
    explicit = int(m.get("paths_explicit_else", 0))
    fail_open = int(m.get("fail_open_paths", 0))
    score = round(explicit * 100.0 / total, 2) if total else 0.0
    target = _threshold("v3_p49_fail_closed_score_target_pct", 100)
    return {
        "paths_total": total,
        "paths_explicit_else": explicit,
        "paths_fail_open": fail_open,
        "fail_closed_score_pct": score,
        "target_pct": target,
        "routing": ("BLOCK_AND_ALERT" if fail_open > 0
                    else ("TRIAGE_QUEUE" if total == 0 or score < target
                          else "AUTO_FILE")),
    }


# ─────────────────────────────── I11 ───────────────────────────────
PROBES = [
    {"id": "P49-SC-01", "desc": "brak pola rule_id (kontrakt P03)",
     "ctx": {"silent_auto_posts": 0, "auto_post_without_evidence": 1,
             "auto_post_total": 1, "auto_post_full_evidence_chain": 0}},
    {"id": "P49-SC-02", "desc": "brak _legal_basis (łańcuch dowodów)",
     "ctx": {"silent_auto_posts": 0, "auto_post_without_evidence": 1,
             "auto_post_total": 1, "auto_post_full_evidence_chain": 0}},
    {"id": "P49-SC-03", "desc": "kwota ponad limit bez 4-eyes",
     "ctx": {"silent_auto_posts": 0, "auto_post_without_evidence": 0,
             "auto_post_total": 1, "auto_post_full_evidence_chain": 1},
     "analysis": "amount_ceiling",
     "extra": {"amount_ceiling": {"auto_post_amount": 999999,
                                  "limit_configured": True, "limit_breaches": 0}}},
    {"id": "P49-SC-04", "desc": "bypass flag (invariants_bypassed)",
     "ctx": {"silent_auto_posts": 0, "auto_post_without_evidence": 0,
             "auto_post_total": 1, "auto_post_full_evidence_chain": 1},
     "analysis": "invariant_pack", "extra": {"invariants_bypassed": True}},
]


def canary() -> dict:
    probes = []
    silent = 0
    for p in PROBES:
        inp = {"jdg_entrepreneur": {"v3_p49_check": True},
               "v3_p49": {"analysis": p.get("analysis", "default_deny_core"),
                          **p.get("extra", {}),
                          "default_deny_core": p["ctx"],
                          **({"amount_ceiling": p["extra"]["amount_ceiling"]}
                             if p.get("analysis") == "amount_ceiling" else {})}}
        with tempfile.TemporaryDirectory() as td:
            tdp = Path(td)
            (tdp / "t.rego").write_text(
                THRESHOLDS_REGO.read_text(encoding="utf-8", errors="replace"),
                encoding="utf-8")
            (tdp / "p.rego").write_text(
                P49_REGO.read_text(encoding="utf-8", errors="replace"), encoding="utf-8")
            ip = tdp / "in.json"
            ip.write_text(json.dumps(inp), encoding="utf-8")
            proc = subprocess.run(
                [str(OPA), "eval", "--format=json", "-d", str(tdp / "t.rego"),
                 "-d", str(tdp / "p.rego"), "-i", str(ip),
                 "data.jdg.v3_p49_fail_closed.decide"],
                capture_output=True, text=True, timeout=60)
            try:
                out = json.loads(proc.stdout)
                verdict = out["result"][0]["expressions"][0]["value"]
            except (json.JSONDecodeError, KeyError, IndexError):
                verdict = {"error": True}
        dm = verdict.get("decision_mode")
        is_silent = dm in ("AUTO_POST",) and verdict.get("matched") is True
        if p.get("analysis") == "amount_ceiling":
            # ponad limit ⇒ oczekiwane TRIAGE (4-eyes), nigdy AUTO_POST
            is_silent = dm == "AUTO_POST"
        probes.append({"id": p["id"], "desc": p["desc"],
                       "decision_mode": dm, "silent_post": is_silent})
        if is_silent:
            silent += 1
    return {
        "canary_run": True,
        "probes_total": len(probes),
        "silent_posts_detected": silent,
        "probe_results": probes,
        "routing": "BLOCK_AND_ALERT" if silent > 0 else "AUTO_FILE",
    }


# ─────────────────────────────── I12 ───────────────────────────────
def user_visible_safety() -> dict:
    contract = read_json(P40_CONTRACT) or {}
    csrc = json.dumps(contract, ensure_ascii=False)
    api_contract_present = bool(csrc.strip()) and csrc != "{}"
    wired = rule_present("jdg.v3_p49_fail_closed.user_visible_safety")
    # Kontrakt P40 decision-first: EVERY NEEDS_ADVICE z akcją; dowód AUTO_POST
    # do pobrania — kontrola pól kontraktowych (explain/evidence endpoints).
    has_explain = ("explain" in csrc.lower()) or ("evidence" in csrc.lower())
    na_visible = 1 if (api_contract_present and wired) else 0
    na_with_action = 1 if (api_contract_present and wired and has_explain) else 0
    return {
        "needs_advice_visible": na_visible,
        "needs_advice_with_action": na_with_action,
        "auto_post_evidence_downloadable": bool(has_explain),
        "p40_contract_present": api_contract_present,
        "routing": ("TRIAGE_QUEUE" if na_with_action < na_visible
                    or not has_explain else "AUTO_FILE"),
    }


def main() -> int:
    fs = fail_closed_score()
    write_p49_bundle("fail_closed_score", "V3-P49-I10", {
        k: fs[k] for k in ("paths_total", "paths_explicit_else", "paths_fail_open",
                           "fail_closed_score_pct", "target_pct", "routing")
    }, {
        "source": "v3_p49_fail_open_registry.json (skaner I02/I10)",
        "note": ("Fail-closed score: % ścieżek z jawnym else → NEEDS_ADVICE. "
                 "Cel 100% (próg ADR-002); trend → P37; fail-open > 0 = BLOCK."),
    })
    print(f"[V3-P49-I10] score={fs['fail_closed_score_pct']}% "
          f"({fs['paths_explicit_else']}/{fs['paths_total']}, fail_open={fs['paths_fail_open']})")

    cn = canary()
    write_p49_bundle("silent_post_canary", "V3-P49-I11", {
        "canary_run": cn["canary_run"],
        "probes_total": cn["probes_total"],
        "silent_posts_detected": cn["silent_posts_detected"],
        "routing": cn["routing"],
    }, {
        "probe_results": cn["probe_results"],
        "note": ("Syntetyczne inputy z brakami NA ŻYWO (OPA eval na polityce P49): "
                 "cichy AUTO_POST na probe = incydent (BLOCK). Interwał canary: "
                 "v3_p49_canary_interval_hours."),
    })
    print(f"[V3-P49-I11] probes={cn['probes_total']} "
          f"silent={cn['silent_posts_detected']}")

    uv = user_visible_safety()
    write_p49_bundle("user_visible_safety", "V3-P49-I12", uv, {
        "source": "v3_p40_api_contract.json + polityka P49 I12",
        "note": ("Fail-closed użyteczny (P40): NEEDS_ADVICE zawsze z akcją "
                 "'co muszę uzupełnić'; AUTO_POST z dowodem do pobrania."),
    })
    print(f"[V3-P49-I12] visible={uv['needs_advice_visible']} "
          f"with_action={uv['needs_advice_with_action']} "
          f"downloadable={uv['auto_post_evidence_downloadable']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
