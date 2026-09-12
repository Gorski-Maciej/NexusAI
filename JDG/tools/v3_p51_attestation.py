#!/usr/bin/env python3
"""NexusAI JDG — V3-P51-I12 LEGAL COVERAGE ATTESTATION — deklaracja pokrycia
z liczbami i licznikiem zastrzeżeń dla certyfikatu P68.

Atestacja: CCR/LCI/UVR z licznikami (kontrolowana suma klas pustyni),
rejestr zastrzeżeń (reconciliation drift z I01, NIEZWERYFIKOWANE podstawy,
brak przepływów kwot), wersja danych i progów. Certyfikat bez zastrzeżeń
= tylko gdy wszystkie liczniki spójne i routing=AUTO_FILE wszędzie.
"""
from __future__ import annotations

from datetime import date

from v3_p51_common import (BUNDLES_DIR, read_json, utcnow_iso,
                           write_p51_bundle)


def main() -> int:
    reg = read_json(BUNDLES_DIR / "v3_p51_desert_register.json") or {}
    chain = read_json(BUNDLES_DIR / "v3_p51_chain_metric.json") or {}
    sweep = read_json(BUNDLES_DIR / "v3_p51_testless_sweep.json") or {}
    radar = read_json(BUNDLES_DIR / "v3_p51_law_radar_block.json") or {}

    rm = reg.get("metrics", {})
    cm = chain.get("metrics", {})
    sm = sweep.get("metrics", {})
    km = radar.get("metrics", {})

    # Kontrola sum: no_rule + rule_no_test + test_no_rule = desert_nodes
    parts = (rm.get("no_rule", 0) + rm.get("rule_no_test", 0)
             + rm.get("test_no_rule", 0))
    counter_consistent = parts == rm.get("desert_nodes", 0)

    caveats = []
    recon = (reg.get("evidence") or {}).get("reconciliation", {})
    flags = recon.get("drift_flags", {})
    if flags.get("canon_lci_100_vs_graph_7143"):
        caveats.append("LCI canon=100% (mianownik 70) vs legal_graph "
                       "covered<nodes — dryf mianowników (V3-P51-L02).")
    if flags.get("snapshot_stale_vs_fresh"):
        caveats.append("coverage_deserts.json starszy niż bieżący skan "
                       "(snapshot archiwalny; liczby z I01).")
    if rm.get("ghost_rule_refs", 0) > 0:
        caveats.append(f"ghost rule_refs w LKG: {rm.get('ghost_rule_refs')} "
                       "(rule_ids nieobecne w canonical).")
    if sm.get("ghost_tests", 0) > 0:
        caveats.append(f"ghost testy (rule_id bez reguły): "
                       f"{sm.get('ghost_tests')}.")
    if km.get("changes_without_rule_plan", 0) > 0:
        caveats.append("zmiany Law Radar bez planu reguły (I07).")
    if not counter_consistent:
        caveats.append("liczniki klas pustyni niespójne — atestacja "
                       "zablokowana (fail-closed).")

    attestation = {
        "generated_at": utcnow_iso(),
        "data_version": "legal_graph 2026-08-30 + canon 2026-08-30",
        "threshold_version": "v3_p51 (data.jdg.thresholds.v3_p51)",
        "metrics": {
            "CCR_pct": cm.get("CCR_pct"),
            "LCI_context_pct": cm.get("LCI_context_pct"),
            "UVR_context": sm.get("uvr_canon_context"),
            "desert_nodes": rm.get("desert_nodes"),
            "p0": rm.get("p0_count"), "p1": rm.get("p1_count"),
            "p2": rm.get("p2_count"), "p3": rm.get("p3_count"),
        },
        "counter_consistency": counter_consistent,
        "attested": bool(counter_consistent and not caveats),
        "caveats": caveats,
        "consumer": "P68 final certification (I12: enterprises widzą "
                    "dokładnie, co silnik wie).",
        "campaign_target_date": date.today().isoformat(),
    }
    metrics = {
        "analysis": "coverage_attestation",
        "routing": "AUTO_FILE" if attestation["attested"] else "TRIAGE_QUEUE",
        "attested": attestation["attested"],
        "caveats_count": len(caveats),
        "counter_consistent": counter_consistent,
        "CCR_pct": cm.get("CCR_pct"),
    }
    write_p51_bundle("coverage_attestation", "V3-P51-I12", metrics,
                     {"attestation": attestation})
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
