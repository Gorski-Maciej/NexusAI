#!/usr/bin/env python3
"""NexusAI JDG — V3-P42-I05 PROVENANCE QUERY — DNA reguły zapytywalne:
akt→nowela→art→reguła→test→bundle→certyfikat (K09). Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p42_common import (LEGAL_GRAPH, SYSTEM_REGISTER, emit,
                           main_jdg_wired, now, read_json, rule_present)

INNOVATION = "V3-P42-I05"
RULE = "jdg.v3_p42_enterprise_reszta.provenance_query"
DNA_CHAIN = ["act", "amendment", "article", "rule", "test", "bundle", "certificate"]


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # Graf prawny (zalążek LKG) — dane DNA
    graph = read_json(LEGAL_GRAPH)
    nodes = graph.get("nodes", []) if isinstance(graph, dict) else []
    graph_ok = len(nodes) > 0
    checks.append({"name": "legal_graph_has_nodes", "status": "OK" if graph_ok else "FAIL",
                   "detail": f"legal_graph.json: {len(nodes)} węzłów (zalążek LKG)"})

    # Schemat DNA (pełny łańcuch) w rejestrze
    reg = read_json(SYSTEM_REGISTER)
    dna_schema = reg.get("provenance_dna_chain", [])
    schema_ok = all(step in dna_schema for step in DNA_CHAIN)
    checks.append({"name": "dna_chain_schema_complete", "status": "OK" if schema_ok else "FAIL",
                   "detail": f"łańcuch DNA w rejestrze: {dna_schema}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p106"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "legal_graph_nodes": len(nodes),
            "dna_chain_schema_complete": schema_ok,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p42_provenance_query")


if __name__ == "__main__":
    raise SystemExit(main())
