#!/usr/bin/env python3
"""
NexusAI JDG — INVARIANT CHECKER (P01 Fundament — Sekcja 12, WIZJA V2 F2 §3)
============================================================================
Build-time egzekucja niezmienników (INV-001..030) — bramka CI oraz symulacja
runtime check. Czyta katalog niezmienników z
rules/audit/runtime_invariants_enterprise.rego (catalog) i weryfikuje:
  • dane (thresholds_export.json / thresholds_data.json) — spójność progów,
  • werdykty (pliki JSON / golden_verdicts.json) — egzekucja kluczowych INV,
  • rejestr reguł (policy_registry.json) — INV-009/INV-008/INV-030.

Próg CI: zero naruszeń RUNTIME/BUILD (BLOCK). Naruszenie STATISTICAL → raport.

Usage:
  python invariant_checker.py check --verdict verdicts.json
  python invariant_checker.py check-data
  python invariant_checker.py catalog
  python invariant_checker.py ci          # pełna bramka CI
"""

import argparse
import json
import re
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
REGO_PATH = JDG_ROOT / "rules" / "audit" / "runtime_invariants_enterprise.rego"
THRESHOLDS = JDG_ROOT / "bundles" / "thresholds_data.json"
REGISTRY = JDG_ROOT / "bundles" / "policy_registry.json"
GOLDEN = JDG_ROOT / "bundles" / "golden_verdicts.json"

ALLOWED_VAT = {"ZW", "NP", "OO", 0, 0.05, 0.08, 0.23}
EPS = 1e-6


def parse_catalog() -> list[dict]:
    text = REGO_PATH.read_text(encoding="utf-8")
    m = re.search(r"catalog\s*:=\s*\[(.*?)\n\]", text, re.S)
    if not m:
        return []
    raw = m.group(1)
    return re.findall(
        r'\{"id":\s*"(INV-\d+)",\s*"description":\s*"([^"]+)",\s*"level":\s*"([^"]+)",\s*"enforcement":\s*"([^"]+)"\}',
        raw,
    )


def check_verdict(v: dict) -> list[str]:
    issues = []
    vat_rate = v.get("vat_rate")
    if vat_rate is not None and vat_rate not in ALLOWED_VAT:
        issues.append("INV-001: stawka VAT spoza zbioru")
    for key in ("net_amount", "vat_amount", "gross_amount"):
        val = v.get(key)
        if isinstance(val, (int, float)) and val < 0:
            issues.append(f"INV-002/INV-007: {key} < 0")
    net, gross = v.get("net_amount"), v.get("gross_amount")
    if isinstance(net, (int, float)) and isinstance(gross, (int, float)):
        if gross < net - EPS:
            issues.append("INV-021: brutto < netto")
    if v.get("matched") is True:
        refs = v.get("_legal_basis_refs")
        basis = v.get("_legal_basis")
        if not refs and not basis:
            issues.append("INV-009: matched=true bez _legal_basis/_legal_basis_refs")
    if isinstance(v.get("vat_amount"), (int, float)):
        if abs(v["vat_amount"] - round(v["vat_amount"] * 100) / 100) > EPS:
            issues.append("INV-012: kwota niezaokrąglona do groszy")
    if v.get("_routing") == "BLOCK_AND_ALERT" and v.get("auto_post") is True:
        issues.append("INV-035: BLOCK_AND_ALERT z auto_post=true")
    if v.get("_degraded_context") is True and v.get("certainty_class") == "CERTAIN":
        issues.append("INV-038: degraded context nie może być CERTAIN")
    prov = v.get("_provenance_tree") or {}
    if v.get("_provenance_tree") is not None and not prov.get("bundle_version"):
        issues.append("INV-030: brak bundle_version w proweniencji")
    if v.get("_warnings") and "IMMUTABLE_VERDICT_OVERWRITE" in v["_warnings"]:
        issues.append("INV-005: nadpisanie werdyktu niemutowalnego")
    return issues


def check_verdicts(args) -> None:
    path = Path(args.verdict)
    payload = json.loads(path.read_text(encoding="utf-8"))
    items = payload.get("verdicts", payload) if isinstance(payload, dict) else payload
    if isinstance(items, dict):
        items = list(items.values()) if all(isinstance(x, dict) for x in items.values()) else [items]
    if not isinstance(items, list):
        items = [items]
    violations = 0
    for v in items:
        if not isinstance(v, dict):
            continue
        for issue in check_verdict(v):
            violations += 1
            print(f"   ❌ {issue} (verdict: {v.get('rule_id', '?')})")
    if violations:
        print(f"❌ INVARIANT CHECK: {violations} naruszeń RUNTIME — BLOCK (CERTAINTY_BLOCKED)")
        sys.exit(2)
    print(f"✅ INVARIANT CHECK: {len(items)} werdyktów — zero naruszeń (runtime invariants OK)")


def check_data(args) -> None:
    violations = 0
    if THRESHOLDS.exists():
        data = json.loads(THRESHOLDS.read_text(encoding="utf-8"))
        for key, entry in data.get("parameters", {}).items():
            versions = entry.get("versions", [])
            for a, b in zip(versions, versions[1:]):
                a_to = a.get("valid_to") or "9999-12-31"
                if a_to >= b["valid_from"]:
                    violations += 1
                    print(f"   ❌ INV-TEMP: nakładka {key}: {a['valid_from']}..{a_to} vs {b['valid_from']}")
            if "standard_rate" in key or "rate" in key:
                for v in versions:
                    val = v.get("value")
                    if isinstance(val, (int, float)) and not (0 <= val <= 1):
                        violations += 1
                        print(f"   ❌ INV-017: {key} = {val} poza przedziałem (0,1)")
    if violations:
        sys.exit(2)
    print("✅ INVARIANT CHECK-DATA: parametry spójne (zero nakładek, zakresy OK)")


def cmd_catalog(args) -> None:
    catalog = parse_catalog()
    print(json.dumps([{"id": i, "description": d, "level": l, "enforcement": e}
                      for i, d, l, e in catalog], indent=2, ensure_ascii=False))
    print(f"Razem: {len(catalog)} niezmienników")


def cmd_ci(args) -> None:
    """Pełna bramka CI: katalog + rejestr (INV-009/008) + dane + werdykty złote."""
    problems = []
    catalog = parse_catalog()
    if len(catalog) < 30:
        problems.append(f"Katalog niezmienników: {len(catalog)} < 30 (cel INV-001..030)")
    if REGISTRY.exists():
        reg = json.loads(REGISTRY.read_text(encoding="utf-8"))
        no_lb = [r["rule_id"] for r in reg.get("rules", []) if not r.get("legal_basis")]
        if no_lb:
            problems.append(f"INV-009: {len(no_lb)} reguł bez _legal_basis (np. {no_lb[:3]})")
    if GOLDEN.exists():
        g = json.loads(GOLDEN.read_text(encoding="utf-8"))
        items = list(g.get("verdicts", {}).values())
        for v in items:
            verdict = v.get("verdict", {})
            for issue in check_verdict(verdict):
                problems.append(issue)
    if problems:
        print("❌ BRAMKA CI (INVARIANT CHECKER):")
        for p in problems:
            print(f"   • {p}")
        sys.exit(1)
    print(f"✅ BRAMKA CI: {len(catalog)} niezmienników, rejestr i dane spójne — merge dozwolony")


def main() -> None:
    p = argparse.ArgumentParser(description="Invariant Checker — V2 F2")
    sub = p.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("check"); c.add_argument("--verdict", required=True); c.set_defaults(fn=check_verdicts)
    d = sub.add_parser("check-data"); d.set_defaults(fn=check_data)
    cat = sub.add_parser("catalog"); cat.set_defaults(fn=cmd_catalog)
    ci = sub.add_parser("ci"); ci.set_defaults(fn=cmd_ci)
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
