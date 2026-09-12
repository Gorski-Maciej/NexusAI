#!/usr/bin/env python3
"""NexusAI JDG — V3-P51-I11 DESERT→VACANCY MAPPING — połączenie pustyni z
rejestrem stubów P45: reguła-fasada (stub, { true }) jest pustynią prawdziwą
(brak treści) — jeden rejestr ryzyka.

Mechanizm: wpisy P45 (v3_p45_stub_register.json → metrics.by_layer,
stub_register.json szczegóły) mapowane per domena na pustynie klasy
rule_no_test/no_rule z I01; wspólny risk_index = stubs + deserts. Wynik:
jeden ranking ryzyka „fasada lub brak" dla P37/P68.
"""
from __future__ import annotations

from collections import Counter

from v3_p51_common import (P45_STUB_REGISTER, P45_STUB_SUMMARY, read_json,
                           write_p51_bundle)


def _stub_domains() -> Counter:
    c = Counter()
    detail = read_json(P45_STUB_REGISTER) or {}
    entries = detail.get("stubs") or detail.get("entries") or []
    for s in entries:
        rid = s.get("rule_id", "") if isinstance(s, dict) else ""
        dom = rid.split(".")[1] if rid.count(".") >= 2 else "other"
        c[dom] += 1
    return c


def main() -> int:
    reg = read_json(_entries_path()) or {}
    entries = reg.get("evidence", {}).get("entries", [])
    summary = read_json(P45_STUB_SUMMARY) or {}
    stub_total = (summary.get("metrics") or {}).get("total_stubs", 0)
    stub_dom = _stub_domains()
    rows, joined = [], 0
    for e in entries:
        sd = stub_dom.get(e["domain"], 0)
        if sd:
            joined += 1
        rows.append({"legal_node_id": e["legal_node_id"],
                     "domain": e["domain"], "desert_class": e["desert_class"],
                     "risk_score": e["risk_score"],
                     "stubs_in_domain": sd,
                     "combined_risk_index": e["risk_score"] + sd * 5,
                     "source": "desert+stub"})
    rows.sort(key=lambda r: -r["combined_risk_index"])
    metrics = {
        "analysis": "vacancy_bridge",
        "routing": "TRIAGE_QUEUE" if stub_total > 0 else "AUTO_FILE",
        "deserts": len(entries),
        "stubs_total": stub_total,
        "domains_with_both": joined,
        "combined_register_rows": len(rows),
    }
    write_p51_bundle("vacancy_bridge", "V3-P51-I11", metrics, {
        "top20": rows[:20],
        "stub_domains": dict(stub_dom),
        "contract": "P45-I01 (rejestr stubów) + P51-I01 (rejestr pustyni) = "
                    "jeden rejestr ryzyka dla P37/P68.",
    })
    return 0


def _entries_path():
    from v3_p51_common import BUNDLES_DIR
    return BUNDLES_DIR / "v3_p51_desert_entries.json"


if __name__ == "__main__":
    raise SystemExit(main())
