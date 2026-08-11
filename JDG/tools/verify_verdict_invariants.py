#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
VERIFY VERDICT INVARIANTS — Decision Certificate / Runtime Invariants (V2/F2)
================================================================================
Cel (raport 01, P0-1 + raport 00, P0-4): statyczna weryfikacja, że każdy werdykt
finalny silnika JDG spełnia runtime invariants filaru V2/F2:

  1. DECISION CERTIFICATE — obecność pól wersjonowania w każdym werdykcie:
     bundle_version / rule_version / threshold_version (+ hash provenance).
  2. WERDYKT 25-POLOWY — wymagane pola werdyktu (decyzja, priorytet, ścieżka...).
  3. IMMUTABILITY — safe_merge z immutable_verdict_allowlist (ZUS chroniony).
  4. BLOCK_AND_ALERT GATE — gated_abort_verdict aktywny przy ryzyku P0.

Tryby:
  --static   skanuje main_jdg.rego pod kątem definicji pól i invariants (default)
  --json     wypisuje wynik w formacie JSON (do CI / metrics_pewnosci.json)

Uruchomienie:  python3 JDG/tools/verify_verdict_invariants.py [--json]
"""
import json
import os
import re
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RULES = os.path.join(REPO_ROOT, "JDG", "rules")

# Pola wymagane w werdykcie 25-polowym (wg dokumentacji V1/V2 + main_jdg.rego)
WYMAGANE_POLA = [
    "decision", "priority", "matched_rule", "rule_id", "confidence",
    "reason", "risk_level", "action", "tax_type", "tax_period",
    "amount", "base", "rate", "due_date", "status",
    "blocked", "message", "legal_basis", "source", "package",
    "created_at", "trace", "bundle_version", "rule_version", "threshold_version",
]

# Pola certyfikatu decyzji (V2/F2) — MUSZĄ być obecne łącznie
POLA_CERTYFIKATU = ["bundle_version", "rule_version", "threshold_version"]

# Allowlista immutable (safe_merge) — pakiety chronione przed nadpisaniem
IMMUTABLE_PKG = ["zus", "risk", "security"]


def skanuj_rdzen():
    """Czyta main_jdg.rego + runtime_invariants_enterprise.rego (Decision Certificate
    jest egzekwowany przez runtime_invariants.enforce() — plik audit/)."""
    pliki = [
        "main_jdg.rego",
        os.path.join("audit", "runtime_invariants_enterprise.rego"),
        "provenance.rego",
    ]
    teksty = []
    for rel in pliki:
        sciezka = os.path.join(RULES, rel)
        if os.path.isfile(sciezka):
            with open(sciezka, encoding="utf-8") as f:
                teksty.append(f.read())
    if not teksty:
        return None, "brak main_jdg.rego"
    return "\n".join(teksty), None


def analizuj():
    t, err = skanuj_rdzen()
    if err:
        return {"ok": False, "error": err, "raport": "01_ORKIESTRATOR_RDZEN"}
    wyniki = {}
    wyniki["_skanowane_pliki"] = [
        "main_jdg.rego",
        "audit/runtime_invariants_enterprise.rego",
        "provenance.rego",
    ]

    # 1. Decision Certificate: wersje w werdykcie (V1 §9.3 / V2 F4)
    for pole in POLA_CERTYFIKATU:
        wyniki[f"pole_{pole}"] = bool(re.search(r"\b" + re.escape(pole) + r"\b", t))
    ma_bundle = wyniki["pole_bundle_version"]
    ma_rule = wyniki["pole_rule_version"]
    ma_thr = wyniki["pole_threshold_version"]
    cert_kompletny = ma_bundle and ma_rule and ma_thr
    # 1b. Decision Certificate — mechanizm enforce (F2/F4 V2)
    wyniki["enforce_post_merge"] = "enforce" in t and "post_merge" in t
    wyniki["decision_certificate"] = "_decision_certificate" in t
    wyniki["decision_hash"] = "decision_hash" in t
    wyniki["certainty_guard"] = "_certainty_guard" in t

    # 2. Werdykt 25-polowy: policz pokrycie wymaganych pól
    pokryte = sum(1 for p in WYMAGANE_POLA
                  if re.search(r"\b" + re.escape(p) + r"\b", t))
    wyniki["pola_wymagane_pokryte"] = f"{pokryte}/{len(WYMAGANE_POLA)}"

    # 3. Immutability (safe_merge + allowlista)
    wyniki["safe_merge"] = "safe_merge" in t
    wyniki["immutable_allowlist"] = "immutable_verdict_allowlist" in t
    wyniki["immutable_pkg_zus"] = any(re.search(r"\b" + p + r"\b", t) for p in
                                      ["zus", "immutable_verdict"])
    # 4. BLOCK_AND_ALERT GATE
    wyniki["gate_block_and_alert"] = "BLOCK_AND_ALERT" in t or "block_and_alert" in t
    wyniki["gated_abort"] = "gated_abort_verdict" in t

    # 5. Provenance (enrich_verdict)
    wyniki["provenance_enrich"] = "enrich_verdict" in t or "provenance" in t
    # Dopuszczamy białe znaki i łamanie linii, ale wymagamy dokładnych
    # identyfikatorów kontraktu, aby komentarz nie mógł dać fałszywego PASS.
    provenance_integration = re.search(
        r"final_verdict_with_provenance\s*=\s*"
        r"provenance\.enrich_verdict\s*\(\s*"
        r"final_verdict_enriched\s*,\s*_provenance_context\s*\)",
        t,
    )
    wyniki["provenance_integration"] = bool(provenance_integration)
    wyniki["provenance_to_p01"] = bool(re.search(
        r"final_verdict_p01\s*=\s*safe_merge\s*\(\s*"
        r"final_verdict_with_provenance\s*,",
        t,
    ))
    wyniki["public_enforced_verdict"] = bool(re.search(
        r"final_verdict\s*=\s*final_verdict_enforced\b", t
    ))

    # 6. Trace / determinizm (A1 provenance, raport 01 P0-3).
    # Sam komentarz lub nazwa pola `trace` nie jest dowodem. Wymagamy
    # konkretnego łańcucha integracji enrichmentu z publicznym werdyktem,
    # budowy ścieżki oraz niepustej ścieżki egzekwowanej przez invariants.
    trace_contract = (
        wyniki["provenance_integration"]
        and wyniki["provenance_to_p01"]
        and wyniki["public_enforced_verdict"]
        and "build_decision_path" in t
        and "_provenance_tree" in t
        and "count(c._provenance_tree.path) < 1" in t
    )
    wyniki["trace_sciezki"] = trace_contract

    # Werdykt końcowy: wszystkie invariants spełnione
    inv_spełnione = (
        cert_kompletny
        and wyniki.get("enforce_post_merge", False)
        and wyniki.get("decision_certificate", False)
        and wyniki.get("decision_hash", False)
        and wyniki.get("certainty_guard", False)
        and wyniki["safe_merge"]
        and wyniki["immutable_allowlist"]
        and wyniki["gate_block_and_alert"]
        and wyniki["gated_abort"]
        and wyniki["provenance_enrich"]
        and wyniki["provenance_integration"]
        and wyniki["provenance_to_p01"]
        and wyniki["public_enforced_verdict"]
        and wyniki["trace_sciezki"]
    )
    wyniki_zbiorcze = {
        "ok": inv_spełnione,
        "certyfikat_kompletny": cert_kompletny,
        "raport": "01_ORKIESTRATOR_RDZEN",
        "szczegoly": wyniki,
    }
    return wyniki_zbiorcze


def main():
    wynik = analizuj()
    if "--json" in sys.argv:
        print(json.dumps(wynik, ensure_ascii=False, indent=2))
    else:
        s = wynik.get("szczegoly", {})
        print("=" * 62)
        print("VERIFY VERDICT INVARIANTS — Decision Certificate (raport 01, P0-1)")
        print("=" * 62)
        print(f"Decision Certificate (bundle/rule/threshold): "
              f"{'KOMPLETNY ✅' if wynik.get('certyfikat_kompletny') else 'NIEKOMPLETNY ❌'}")
        print(f"  bundle_version:     {s.get('pole_bundle_version')}")
        print(f"  rule_version:       {s.get('pole_rule_version')}")
        print(f"  threshold_version:  {s.get('pole_threshold_version')}")
        print(f"  enforce POST-MERGE: {s.get('enforce_post_merge')} (F2 V2)")
        print(f"  _decision_certificate: {s.get('decision_certificate')} (F4 V2)")
        print(f"  decision_hash:      {s.get('decision_hash')} (F3 V2)")
        print(f"  _certainty_guard:   {s.get('certainty_guard')}")
        print(f"Werdykt 25-polowy (pola pokryte): {s.get('pola_wymagane_pokryte')}")
        print(f"safe_merge:          {s.get('safe_merge')}")
        print(f"immutable allowlist: {s.get('immutable_allowlist')}")
        print(f"BLOCK_AND_ALERT gate:{s.get('gate_block_and_alert')}")
        print(f"gated_abort_verdict: {s.get('gated_abort')}")
        print(f"provenance enrich:   {s.get('provenance_enrich')}")
        print(f"provenance integration: {s.get('provenance_integration')}")
        print(f"provenance → P01:    {s.get('provenance_to_p01')}")
        print(f"public enforced verdict: {s.get('public_enforced_verdict')}")
        print(f"trace ścieżki:       {s.get('trace_sciezki')} (provenance path contract)")
        print("-" * 62)
        print("WERDYKT: " + ("INVARIANTS SPEŁNIONE ✅" if wynik.get("ok")
                             else "WYMAGA DOMKNIĘCIA ⚠️ (patrz RAPORT_01: P0-1/P0-3)"))
    sys.exit(0 if wynik.get("ok") else 1)



if __name__ == "__main__":
    main()
