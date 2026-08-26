# Legal Twin Traceability — ETAP 03

> Generator: `JDG/tools/legal_twin_traceability.py` · schema `1.0.0`

| Metric | Value |
|---|---:|
| LCI | 81.77% |
| TCL | 100.0% |
| RV | 34.51% |
| UVR | 61.23% |

- Reguły: 12280
- Węzły LKG: 181
- Pustynie pokrycia: 33
- Bramka strukturalna: **PASS**

Traceability jest dwukierunkowe: `legal_node → rule_ids` oraz `rule → legal_node_ids`.
Brak źródła, niejednoznaczne mapowanie i brak dowodu temporalnego blokują publikację.

## Łańcuch nowelizacji (amendment chain) — V3-20

Auto-trace pełnym łańcuchem zmiany prawnej (spójny z Control Plane, ETAP 04
oraz częścią kampanii V3-18/V3-19/V3-20):

```
amendment_id → issue_id → PR → change_id → bundle_version → verdict_ids
     ↑                                                                ↑
legal_node (LKG)  →  rule_id  →  test (golden/pytest/rego T0x)
```

- `amendment_id` — identyfikator nowelizacji z Law Radar (Dz.U./ISAP,
  SHA-256 w LEGAL_SOURCE_REGISTRY);
- każdy `rule_id` ma co najmniej jeden test chroniący (golden replay /
  pytest / natywny Rego) — auto-trace artykul→regula→test;
- brak któregokolwiek ogniwa blokuje granicę dokumentacji
  (`jdg.docs.quality_v3_20.documentation_certification_contract`,
  niezmiennik `legal_twin_ok`, evidence `bundles/docs_v3_audit_20.json`).
