"""Testy pytest V3-P64 SWEEP LUK REZYDUALNYCH (konwencja P51–P63).

Pokrywają: 12 silników I01–I12 vs bundla (jedno źródło), progi z ADR-002
(brak hardcode), wiring main_jdg p128, mirror hash-parity, fail-closed,
automat sweep (deterministyczny), 7 kontroli krzyżowych z licznikami.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

JDG = Path(__file__).resolve().parents[2]
BUNDLES = JDG / "bundles"
RULES = JDG / "rules"
RULE = RULES / "v3_p64_luka_sweep.rego"


def _load(name: str) -> dict:
    return json.loads((BUNDLES / f"{name}.json").read_text(encoding="utf-8"))


# ═══ 1. Run-all gate ═══
def test_run_all_gate_pass():
    d = _load("v3_p64_run_all")
    assert d["gate"] == "PASS", d["failures"]
    assert d["engines_run"] == 12
    assert d["failures"] == []


def test_all_bundles_pass():
    for name in ["v3_p64_i01_register", "v3_p64_i02_cross_checks",
                 "v3_p64_i03_blindspots", "v3_p64_i04_ownerless",
                 "v3_p64_i05_second_pass", "v3_p64_i06_declarations",
                 "v3_p64_i07_risk", "v3_p64_i08_dashboard",
                 "v3_p64_i09_automation", "v3_p64_i10_handover",
                 "v3_p64_i11_meta", "v3_p64_i12_report"]:
        r = _load(name)["result"]
        assert r["gate"] == "PASS" if "gate" in r else True
        assert "provenance" in r or "evidence" in r, f"{name}: brak provenance/evidence"


# ═══ 2. I01: rejestr rezydualny z planem SLA ═══
def test_i01_register():
    r = _load("v3_p64_i01_register")["result"]
    assert r["open_items_total"] >= 1  # luki rezydualne z ledgera (P45–P63)
    assert r["sla_plan_registered"] is True
    assert sum(r["open_items_by_class"].values()) >= r["open_items_total"]
    assert "v3_campaign_ledger.json" in r["evidence"]


# ═══ 3. I02: seven cross-checks z licznikami ═══
def test_i02_cross_checks():
    r = _load("v3_p64_i02_cross_checks")["result"]
    required = r["checks_required"]
    assert len(required) == 7  # (a)–(g) z promptu P64 5.2
    assert r["missing_checks"] == []
    assert set(r["checks_present"]) == set(required)
    c = r["counters_per_check"]
    assert c["integration_contract"] == 0  # cross_package_conflict_detector obecny
    assert c["fail_closed"] == 0  # main_jdg: NEEDS_ADVICE + CERTAINTY_BLOCKED
    assert c["param_window"] == 0  # thresholds: valid_from obecne


# ═══ 4. I03: taksonomia ślepych plam (min 5 klas) ═══
def test_i03_blindspots():
    r = _load("v3_p64_i03_blindspots")["result"]
    assert len(r["classes"]) >= r["min_classes"] >= 5
    detail = r["classes_detail"]
    assert all(c["kontrola"] for c in detail)  # każda klasa z kontrolą strukturalną
    assert any("hotfix" in c["klasa"] for c in detail)
    assert any("deklaracja bez dowodu" in c["klasa"] for c in detail)


# ═══ 5. I04: ownerless artifacts z decyzją ═══
def test_i04_ownerless():
    r = _load("v3_p64_i04_ownerless")["result"]
    assert r["orphans_total"] >= 1  # realny wynik sweep (212 @ 2026-09-15)
    assert r["decisions_registered"] is True
    assert "przypisz" in r["decision_rule"] or "usuń" in r["decision_rule"]
    assert all(o.startswith("rules/") for o in r["orphans"])


# ═══ 6. I05: drugi przebieg stabilny ═══
def test_i05_second_pass():
    r = _load("v3_p64_i05_second_pass")["result"]
    assert r["executed"] is True
    assert r["stable"] is True
    assert r["new_items"] == 0
    assert r["first_pass"] == r["second_pass"]


# ═══ 7. I06: deklaracje bez dowodu (P11/P12) ═══
def test_i06_declarations():
    r = _load("v3_p64_i06_declarations")["result"]
    parts = [c["part"] for c in r["undocumented_claims"]]
    assert "P11" in parts and "P12" in parts  # innovations==0 przy WDROŻONY_100
    assert r["evidence_plan_registered"] is True


# ═══ 8. I07: ryzyko rezydualne (luki×wagi z ledgera) ═══
def test_i07_risk():
    r = _load("v3_p64_i07_risk")["result"]
    assert r["risk_score"] == 1165  # policzone z ledgera (wagi P0=10/P1=5/P2=2/P3=1)
    assert r["reduction_plan_registered"] is True
    assert r["trend_by_part"]["P63"] == 11  # 1×P1 + 2×P2 + 2×P3 = 5+4+2
    assert r["trend_by_part"]["P45"] == 19


# ═══ 9. I08: dashboard kanały ═══
def test_i08_dashboard():
    r = _load("v3_p64_i08_dashboard")["result"]
    assert r["missing"] == []
    assert set(r["channels_present"]) == set(r["channels_required"])
    assert "v3_p64_sweep_register.json" in r["data_source"]


# ═══ 10. I09: automat sweep ═══
def test_i09_automation():
    r = _load("v3_p64_i09_automation")["result"]
    assert r["cyclic_sweep_present"] is True
    assert "v3_p64_sweep_engine.py" in r["tool"]
    assert r["workflow_present"] is True


# ═══ 11. I10: handover V4 (kontrakty) ═══
def test_i10_handover():
    r = _load("v3_p64_i10_handover")["result"]
    assert set(r["handover_contracts"]) == {"C1", "C2", "C3", "C4"}
    detail = r["contracts_detail"]
    assert any("P68" in c["odbiorca"] for c in detail)
    assert any("P39" in c["odbiorca"] for c in detail)


# ═══ 12. I11: sweep of sweeps ═══
def test_i11_meta():
    r = _load("v3_p64_i11_meta")["result"]
    assert len(r["swept_dirs"]) >= r["min_dirs"] >= 8
    assert r["unswept_dirs"] == []
    assert r["coverage_tools_present"] is True  # 8 detektorów z sekcji 6.2 promptu


# ═══ 13. I12: standard raportu rezydualnego ═══
def test_i12_report():
    r = _load("v3_p64_i12_report")["result"]
    assert r["missing"] == []
    assert set(r["sections_present"]) == set(r["sections_required"])


# ═══ 14. Progi z ADR-002 (zero hardcode) ═══
def test_no_hardcoded_thresholds():
    hay = RULE.read_text(encoding="utf-8")
    for k in ["v3_p64_residual_register_max", "v3_p64_cross_checks_required",
              "v3_p64_blindspot_classes_min", "v3_p64_ownerless_max",
              "v3_p64_second_pass_required", "v3_p64_undocumented_claims_max",
              "v3_p64_residual_risk_max", "v3_p64_dashboard_channels",
              "v3_p64_cyclic_sweep_required", "v3_p64_v4_handover_required",
              "v3_p64_sweep_of_sweeps_min", "v3_p64_residual_report_sections"]:
        assert k in hay, f"brak klucza ADR-002: {k}"
    th = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    assert '"v3_p64_threshold_version": "luka-sweep-v3p64-2026.09"' in th
    assert th.count('"v3_p64_') >= 13  # threshold_version + 12 kluczy I01–I12


def test_thresholds_temporal_window():
    th = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    blk = th[th.index("v3_p64 := {"):]
    assert '"valid_from": "2026-01-01"' in blk and '"valid_to": null' in blk


# ═══ 15. Wiring main_jdg p128 ═══
def test_wiring_main_jdg():
    main = (RULES / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.v3_p64_luka_sweep as v3_p64_luka_sweep" in main
    assert "final_verdict_p128 = safe_merge(final_verdict_p127" in main
    assert "v3_p64_luka_sweep.decide" in main
    post = main[main.index("final_verdict_post_merge = safe_merge("):]
    # Kotwica POST-MERGE przesunięta na p128 (wiring P64, kampania V3).
    assert "final_verdict_p128" in post[:400]


# ═══ 16. Mirror: hash-parity policies/ ═══
def _sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def test_mirror_hash_parity():
    for name in ["v3_p64_luka_sweep", "v3_p63_rbac_multitenant_closure",
                 "v3_p62_cashflow_closure", "thresholds_jdg", "main_jdg"]:
        canonical = JDG / "rules" / f"{name}.rego"
        mirror = JDG.parent / "policies" / f"{name}.rego"
        assert mirror.exists(), f"brak mirrora: {mirror}"
        assert _sha(canonical) == _sha(mirror), f"mirror drift: {name}"


# ═══ 17. Fail-closed statycznie: router nie ma ścieżki AUTO_POST ═══
def test_fail_closed_static():
    hay = RULE.read_text(encoding="utf-8")
    assert hay.count('"AUTO_POST"') == 0
    assert "NO_MATCH" in hay and "NEEDS_ADVICE" in hay
    # final_verdict_p128 tylko w komentarzu nagłówka (konwencja P59–P63) —
    # rega P64 nie wykonuje host-wiringu.
    assert hay.count("final_verdict_p128") == 1


# ═══ 18. Rego struktura: pakiety, priorytety, unikalność ═══
def test_rego_structure():
    t = RULE.read_text(encoding="utf-8")
    assert t.count("{") == t.count("}")
    assert "package jdg.v3_p64_luka_sweep" in t
    for n in range(1, 13):
        assert f"4640{n:02d}" in t, f"brak priorytetu I{n:02d}"


# ═══ 19. Automat sweep: deterministyczny ═══
def test_sweep_engine_deterministic():
    import subprocess
    import sys
    proc1 = subprocess.run([sys.executable, str(JDG / "tools" / "v3_p64_sweep_engine.py")],
                           capture_output=True, text=True)
    proc2 = subprocess.run([sys.executable, str(JDG / "tools" / "v3_p64_sweep_engine.py")],
                           capture_output=True, text=True)
    assert proc1.returncode == 0 and proc2.returncode == 0
    assert proc1.stdout == proc2.stdout  # drugi przebieg = zero nowych pozycji


# ═══ 20. Źródła PRAWDA: detektory 6.2 używane, nie dublowane ═══
def test_no_duplication_of_earlier_engines():
    hay = ((JDG / "tools" / "v3_p64_engines.py").read_text(encoding="utf-8")
           + (JDG / "tools" / "v3_p64_common.py").read_text(encoding="utf-8"))
    for src in ["dead_rule_detector", "cross_package_conflict_detector",
                "migration_impact_analyzer", "else_chain_dead_code_detector",
                "doc_consistency_validator", "rule_impact_simulator",
                "crossref_plan50", "legal_coverage_heatmap",
                "v3_campaign_ledger.json", "coverage_canon.json"]:
        assert src in hay, f"brak powiązania z prawdziwym źródłem: {src}"
