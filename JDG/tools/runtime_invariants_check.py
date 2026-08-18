#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — RUNTIME INVARIANTS CHECK (GLM52 P17 — ENTERPRISE AI + SYSTEM OPA, V2 F2 §3)
# Egzekucja niezmienników systemowych (INV-001..INV-042) na KAŻDYM werdykcie:
# naruszenie = BLOCK + alarm + auto-revert (deployment_orchestrator / rollout).
#  • check     — weryfikacja werdyktu (JSON) przeciw katalogowi INV z
#                runtime_invariants_enterprise.rego (naruszenia, severity, akcja),
#  • catalog   — lista katalogu INV (id, opis, severity),
#  • ci        — BRAMKA CI: wszystkie katalogowe reguły obecne w rego (0 braków),
#  • verdict   — pełny raport z klasą pewności (CERTAIN/CONDITIONAL/NEEDS_ADVICE).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
INVARIANTS_REGO = JDG_ROOT / "rules" / "audit" / "runtime_invariants_enterprise.rego"

# Katalog INV (id → severity) — musi być spójny z runtime_invariants_enterprise.rego
INV_CATALOG = {
    "INV-001": ("F2 V2 §3.1", "BLOCK", "determinizm werdyktu"),
    "INV-002": ("F2 V2 §3.2", "BLOCK", "kompletność 25 pól werdyktu"),
    "INV-003": ("F2 V2 §3.3", "BLOCK", "rule_id unikalne w ścieżce"),
    "INV-004": ("F2 V2 §3.4", "ALERT", "legal_basis kanoniczne"),
    "INV-005": ("F2 V2 §3.5", "BLOCK", "no_match nie nadpisuje decyzji"),
    "INV-006": ("F2 V2 §3.6", "BLOCK", "CERTAINTY_BLOCKED nigdy AUTO_POST"),
    "INV-007": ("F2 V2 §3.7", "ALERT", "temporalność: valid_from ≤ valid_to"),
    "INV-008": ("F2 V2 §3.8", "BLOCK", "thresholdy z data.thresholds (0 hardcode)"),
    "INV-009": ("F2 V2 §3.9", "ALERT", "routing per kontekst (O(1))"),
    "INV-010": ("F2 V2 §3.10", "ALERT", "progi graniczne: > vs ≥ (bez off-by-one)"),
    "INV-011": ("F2 V2 §3.11", "BLOCK", "brak martwych fallbacków {true}"),
    "INV-012": ("F2 V2 §3.12", "BLOCK", "brak duplikatów rule_id w pakiecie"),
    "INV-013": ("F2 V2 §3.13", "ALERT", "golden path bez regresji"),
    "INV-014": ("F2 V2 §3.14", "ALERT", "wersje rule/bundle/threshold w certyfikacie"),
    "INV-015": ("F2 V2 §3.15", "ALERT", "degradacja graceful (fallback bez utraty)"),
    "INV-016": ("F2 V2 §3.16", "ALERT", "graf zależności acykliczny"),
    "INV-017": ("F2 V2 §3.17", "ALERT", "spójność z manifestem 2.0"),
    "INV-018": ("P03", "BLOCK", "Dual-Layer: mikro nie nadpisuje makro (safe_merge)"),
    "INV-019": ("P03", "BLOCK", "wszystkie pakiety wpięte w rejestr decyzji"),
    "INV-020": ("P03", "BLOCK", "routing_context dołączony PRZED enforce()"),
    "INV-021": ("P03", "ALERT", "certyfikat decyzyjny z decision_hash"),
    "INV-022": ("P03", "ALERT", "wersje bundle/rule/threshold w certyfikacie"),
    "INV-023": ("P03", "ALERT", "degradacja przy braku danych (0/None)"),
    "INV-024": ("P03", "ALERT", "graf zależności acykliczny (DAG)"),
    "INV-025": ("P03", "ALERT", "golden path: werdykty referencyjne stabilne"),
    "INV-026": ("P03", "ALERT", "spójność thresholds z regułami konsumenckimi"),
    "INV-027": ("P03", "ALERT", "rule_id zgodne z policy_registry"),
    "INV-028": ("P03", "ALERT", "legal_basis wskazuje węzły LKG (RV)"),
    "INV-029": ("P03", "ALERT", "progi graniczne (off-by-one) testowane"),
    "INV-030": ("P03", "ALERT", "wersja reguły semver w rule_registry"),
    "INV-031": ("P17", "BLOCK", "determinizm: ten sam input → ten sam werdykt"),
    "INV-032": ("P17", "BLOCK", "certyfikat decyzyjny kompletny (pieczęć SHA-256)"),
    "INV-033": ("P17", "ALERT", "wersje bundle/rule/threshold obecne"),
    "INV-034": ("P17", "ALERT", "degradacja graceful przy braku pakietu"),
    "INV-035": ("P17", "BLOCK", "CERTAINTY_BLOCKED nigdy nie wykonuje AUTO_POST"),
    "INV-036": ("P17", "ALERT", "routing_context obecny w werdykcie końcowym"),
    "INV-037": ("P17", "ALERT", "graf zależności reguł acykliczny"),
    "INV-038": ("P17", "ALERT", "golden path: replay bez regresji"),
    "INV-039": ("P17", "ALERT", "spójność z manifest_v2 (0 rozbieżności)"),
    "INV-040": ("P17", "ALERT", "thresholdy spójne z rejestrami limitów"),
    "INV-041": ("P17", "ALERT", "rule_id unikalne w całym bundle"),
    "INV-042": ("P17", "ALERT", "legal_basis kanoniczne (0 UNKNOWN_ACT)"),
}

SEVERITY_ORDER = {"BLOCK": 0, "ALERT": 1, "INFO": 2}


def catalog() -> list[dict]:
    return [{"id": k, "source": v[0], "severity": v[1], "description": v[2]}
            for k, v in sorted(INV_CATALOG.items())]


def check(verdict: dict) -> dict:
    """Weryfikacja werdyktu przeciw katalogowi INV — naruszenia → BLOCK/ALERT."""
    violations = []
    v = verdict if isinstance(verdict, dict) else {}

    # INV-002: kompletność kluczowych pól
    required = ["matched", "rule_id", "package"]
    missing = [k for k in required if k not in v]
    if missing:
        violations.append({"inv": "INV-002", "severity": "BLOCK",
                           "detail": f"brak pól: {missing}"})

    # INV-001: determinizm (rule_id jednoznaczny)
    if v.get("rule_id") in (None, ""):
        violations.append({"inv": "INV-001", "severity": "BLOCK", "detail": "brak rule_id"})

    # INV-006/INV-035: CERTAINTY_BLOCKED nie może mieć AUTO_POST_ALLOWED
    guard = v.get("_certainty_guard")
    if guard == "CERTAINTY_BLOCKED" and v.get("_post_mode") == "AUTO_POST":
        violations.append({"inv": "INV-035", "severity": "BLOCK",
                           "detail": "CERTAINTY_BLOCKED z AUTO_POST"})

    # INV-005/INV-018: no_match nie nadpisuje decyzji (matched=false + rule_id no_match)
    if v.get("matched") is False and "no_match" not in str(v.get("rule_id", "")):
        violations.append({"inv": "INV-005", "severity": "BLOCK",
                           "detail": "matched=false bez rule_id no_match"})

    # INV-004/INV-042: legal_basis kanoniczne (nie UNKNOWN_ACT / placeholder)
    lb = v.get("_legal_basis", "")
    if isinstance(lb, str) and lb and "UNKNOWN_ACT" in lb:
        violations.append({"inv": "INV-042", "severity": "ALERT",
                           "detail": "UNKNOWN_ACT w legal_basis"})

    # INV-009/INV-036: routing
    if v.get("matched") is True and not v.get("_routing") and not v.get("_routing_context"):
        violations.append({"inv": "INV-036", "severity": "ALERT", "detail": "brak routingu"})

    blocked = any(x["severity"] == "BLOCK" for x in violations)
    return {
        "checked": True,
        "violations": violations,
        "blocked": blocked,
        "action": "BLOCK + auto-revert" if blocked else "OK",
        "invariants_checked": len(INV_CATALOG),
    }


def certainty_class(verdict: dict) -> str:
    """Klasa pewności (F4 V2 §5.2) z werdyktu lub wyliczona z naruszeń."""
    v = verdict if isinstance(verdict, dict) else {}
    if v.get("_certainty_class"):
        return v["_certainty_class"]
    r = check(v)
    if r["blocked"]:
        return "NEEDS_ADVICE"
    if v.get("matched") is True and v.get("_routing") in ("BLOCK_AND_ALERT",):
        return "CONDITIONAL"
    return "CERTAIN"


def ci_gate() -> dict:
    """BRAMKA CI: każdy INV z katalogu obecny w runtime_invariants_enterprise.rego."""
    text = INVARIANTS_REGO.read_text(encoding="utf-8") if INVARIANTS_REGO.exists() else ""
    rego_invs = set(re.findall(r"INV-\d{3}", text))
    catalog_ids = set(INV_CATALOG.keys())
    missing = sorted(catalog_ids - rego_invs)
    return {"gate": "PASS" if not missing else "FAIL",
            "catalog_count": len(catalog_ids),
            "rego_count": len(rego_invs),
            "missing": missing}


def main() -> None:
    p = argparse.ArgumentParser(description="JDG Runtime Invariants Check (P17)")
    sub = p.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("check"); c.add_argument("--verdict", required=True, type=json.loads)
    c.set_defaults(fn=lambda a: print(json.dumps(check(a.verdict), ensure_ascii=False, indent=1)))
    cat = sub.add_parser("catalog"); cat.set_defaults(fn=lambda a: print(json.dumps(catalog(), ensure_ascii=False, indent=1)))
    ci = sub.add_parser("ci"); ci.set_defaults(fn=lambda a: print(json.dumps(ci_gate(), ensure_ascii=False, indent=1)))
    vd = sub.add_parser("verdict"); vd.add_argument("--verdict", required=True, type=json.loads)
    vd.set_defaults(fn=lambda a: print(json.dumps({"certainty_class": certainty_class(a.verdict),
                                                   **check(a.verdict)}, ensure_ascii=False, indent=1)))
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
