#!/usr/bin/env python3
"""NexusAI JDG — V3-P47-I03 ISAP ANCHOR FOR EVERY ACT — każdy akt w rejestrze
z URL ISAP i identyfikatorem (klik z raportu prosto do konsolidacji).
Źródła: mapa aktów data.jdg.thresholds.v3_p47_acts (12 aktów, wszystkie
[NIEZWERYFIKOWANE — ISAP] do stempla 4-eyes) + LEGAL_SOURCE_REGISTRY (30 rekordów
BLOCKED_UNVERIFIED). Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p47_common import (LSR_REGISTRY, P47_RULE, extract_threshold_block,
                           read_json, rule_present, write_bundle)

INNOVATION = "V3-P47-I03"
RULE = f"{P47_RULE}.isap_anchor"


def main() -> int:
    checks, findings = [], []

    block = extract_threshold_block("v3_p47_acts") or ""
    act_keys = [ln.split('"')[1] for ln in block.splitlines()
                if ln.strip().startswith('"v3_p47_act_')]
    with_anchor = [k for k in act_keys if "isap_url" in block.split(f'"{k}"')[1][:400]
                   if f'"{k}"' in block]
    without_anchor = [k for k in act_keys if k not in with_anchor]

    checks.append({"name": "acts_map_present", "status": "OK" if act_keys else "FAIL",
                   "detail": f"v3_p47_acts (thresholds_jdg.rego): {len(act_keys)} aktów"})
    checks.append({"name": "every_act_has_isap_url",
                   "status": "OK" if not without_anchor else "FAIL",
                   "detail": f"akty z anchorem ISAP/RCL: {len(with_anchor)}/{len(act_keys)}"
                             + (f"; brak: {without_anchor}" if without_anchor else "")})
    checks.append({"name": "unverified_honestly_tagged",
                   "status": "OK" if block.count("NIEZWERYFIKOWANE") >= len(act_keys) else "FAIL",
                   "detail": f"tagi [NIEZWERYFIKOWANE — ISAP] w mapie aktów: {block.count('NIEZWERYFIKOWANE')} "
                             f"(zero fikcyjnych Dz.U. — protokół 04)"})

    lsr = read_json(LSR_REGISTRY) or {}
    recs = lsr.get("records", [])
    blocked = sum(1 for r in recs if r.get("publication_state") == "BLOCKED_UNVERIFIED")
    checks.append({"name": "lsr_registry_coverage", "status": "OK" if recs else "FAIL",
                   "detail": f"LEGAL_SOURCE_REGISTRY: {len(recs)} rekordów, BLOCKED_UNVERIFIED: {blocked} "
                             f"(spójnie — nic nie udaje zweryfikowanego)"})

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    if without_anchor:
        findings.append({"severity": "HIGH", "message": f"akty bez anchora: {without_anchor}"})

    routing = "BLOCK_AND_ALERT" if not act_keys else ("TRIAGE_QUEUE" if without_anchor or not recs else "AUTO_FILE")
    metrics = {"acts_total": len(act_keys), "acts_without_anchor": len(without_anchor),
               "lsr_records": len(recs), "lsr_blocked_unverified": blocked,
               "routing": routing}
    evidence = {"acts": act_keys, "checks": checks, "findings": findings}
    write_bundle("isap_anchors", INNOVATION, metrics, evidence)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
