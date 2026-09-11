#!/usr/bin/env python3
"""NexusAI JDG — V3-P48 RULE REGISTRY REGISTER — rejestr 12 reguł P48
(rule_registry.json, konwencja lifecycle P07; status CANDIDATE — wzorzec
P45/P46/P47). Idempotentny: istniejący wpisy nie są nadpisywane.

Wpis (spójny z jdg.v3_p47_*):
  { "suspend_reason": null, "versions": [ { domain, error_rate, impact_rules,
    legal_basis, owner, registered_at, rollout_pct, rule_id, severity, status,
    supersedes, tests, thresholds, title, valid_from, valid_to, version } ] }
"""
from __future__ import annotations

import json
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]
REGISTRY = BASE / "bundles" / "rule_registry.json"
PKG = "jdg.v3_p48_mirror_sync"
OWNER = "P48-campaign"
REGISTERED_AT = "2026-09-11"

INNOVATIONS = [
    ("mirror_build_output", 1, "I01: mirror as build output"),
    ("semantic_ast_diff", 2, "I02: semantic AST diff gate"),
    ("sync_in_pr", 3, "I03: sync-in-PR rule"),
    ("drift_heatmap", 4, "I04: drift heatmap"),
    ("overlay_declaration", 5, "I05: overlay declaration file"),
    ("mirror_test_parity", 6, "I06: mirror test parity"),
    ("golden_replay_mirror", 7, "I07: golden replay on mirror"),
    ("mirror_ownership", 8, "I08: mirror ownership register"),
    ("post_deploy_check", 9, "I09: post-deploy mirror check"),
    ("case_study", 10, "I10: case-study template"),
    ("lifecycle_alignment", 11, "I11: mirror lifecycle alignment"),
    ("one_truth_attestation", 12, "I12: one-truth attestation"),
]

TESTS = [
    "tests/rego/test_v3_p48_mirror_sync.rego",
    "tests/auto/test_v3_p48_mirror_sync.py",
]
THRESHOLDS = ["v3_p48", "v3_p48_packages"]


def entry(rule: str, num: int, title: str) -> dict:
    return {
        rule: {
            "suspend_reason": None,
            "versions": [{
                "domain": "compliance",
                "error_rate": 0.0,
                "impact_rules": [],
                "legal_basis": ("[NIEZWERYFIKOWANE — ISAP] weryfikacja 4-eyes wg "
                                "P47-I10; P48-I05 overlay deklaracja"),
                "owner": OWNER,
                "registered_at": REGISTERED_AT,
                "rollout_pct": 10,
                "rule_id": rule,
                "severity": "BLOCKER",
                "status": "CANDIDATE",
                "supersedes": None,
                "tests": TESTS,
                "thresholds": THRESHOLDS,
                "title": f"V3-P48 {title}",
                "valid_from": "2026-01-01",
                "valid_to": None,
                "version": f"3.48.{num}",
            }],
        }
    }


def main() -> int:
    registry = json.loads(REGISTRY.read_text(encoding="utf-8"))
    added, present = 0, 0
    for rule_name, num, title in INNOVATIONS:
        rule = f"{PKG}.{rule_name}"
        if rule in registry:
            present += 1
            continue
        registry.update(entry(rule, num, title))
        added += 1
    REGISTRY.write_text(json.dumps(registry, ensure_ascii=False, indent=2) + "\n",
                        encoding="utf-8")
    total_p48 = sum(1 for k in registry if k.startswith(PKG))
    print(f"[V3-P48-REGISTRY] added={added} already_present={present} "
          f"p48_rules_total={total_p48}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
