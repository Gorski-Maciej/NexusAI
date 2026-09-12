#!/usr/bin/env python3
"""NexusAI JDG — V3-P51-I04 COVERAGE CHAIN METRIC — % aktów z pełnym łańcuchem
akt→art→reguła→test (definition of done kampanii).

Liczy łańcuch per węzeł ARTICLE: akt (legal_graph) → artykuł → ≥1 reguła
kanoniczna → ≥1 reguła z natywnym testem Rego. Rozszerza coverage_unifier
(LCI liczy tylko regułę, bez nogi testowej) — nie duplikuje go: LCI podajemy
obok jako kontekst. Wynik = metryka CCR (Chain Coverage Rate) dla kampanii
(cel kwantyfikowany) + rozkład braków per noga łańcucha.
"""
from __future__ import annotations

from v3_p51_common import read_json, write_p51_bundle

C = None


def _load_register():
    global C
    if C is None:
        from pathlib import Path
        from v3_p51_common import BUNDLES_DIR
        C = read_json(BUNDLES_DIR / "v3_p51_desert_entries.json") or {}
    return C


def main() -> int:
    reg = _load_register()
    metrics_in = reg.get("metrics", {})
    art_total = metrics_in.get("article_nodes", 0)
    no_rule = metrics_in.get("no_rule", 0)
    rule_no_test = metrics_in.get("rule_no_test", 0)
    # test leg needs rule_ids that ARE tested; recompute per node:
    chain_ok = art_total - no_rule - rule_no_test
    ccr = round(chain_ok * 100.0 / art_total, 2) if art_total else 0.0
    metrics = {
        "analysis": "chain_metric",
        "routing": "TRIAGE_QUEUE" if ccr < 90.0 else "AUTO_FILE",
        "article_nodes": art_total,
        "chain_complete": chain_ok,
        "missing_rule_leg": no_rule,
        "missing_test_leg": rule_no_test,
        "missing_act_leg": 0,  # węzły bez aktu nie istnieją w LKG
        "CCR_pct": ccr,
        "LCI_context_pct": None,  # kontekst z canon (nie porównywać wprost)
    }
    canon = read_json(v3_p51_common__CANON()) or {}
    metrics["LCI_context_pct"] = (canon.get("metrics") or {}).get("LCI")
    write_p51_bundle("chain_metric", "V3-P51-I04", metrics, {
        "definition": "CCR = węzły ARTICLE z ≥1 regułą kanoniczną ORAZ ≥1 "
                      "regułą z natywnym testem Rego / wszystkie węzły ARTICLE.",
        "campaign_target_pct": 90.0,
        "campaign_target_source": "prompt P51 Sekcja 5.4 (cel kwantyfikowany "
                                  "kampanii; do potwierdzenia 4-eyes Q02)",
        "note": "LCI (coverage_unifier) liczy tylko nogę reguły; CCR wymaga "
                "nogi testowej — cel kampanii liczony CCR, nie LCI.",
        "entries_total": reg.get("evidence", {}).get("entries_total"),
    })
    return 0


def v3_p51_common__CANON():
    from v3_p51_common import COVERAGE_CANON
    return COVERAGE_CANON


if __name__ == "__main__":
    raise SystemExit(main())
