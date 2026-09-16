"""Testy pytest V3-P65 NOWE NARZĘDZIA FORTECY (konwencja P51–P64).

Pokrywają: 12 silników I01–I12 vs bundla (jedno źródło), narzędzia P65
(kontrakt, semantic diff, generator testów, WORM tamper, adoption, docs),
progi z ADR-002 (brak hardcode), wiring main_jdg p129, mirror hash-parity,
fail-closed (zero AUTO_POST), kompozycja z P37/P42/P49/P51/P53/P62/P63/P64.
"""
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from pathlib import Path

JDG = Path(__file__).resolve().parents[2]
BUNDLES = JDG / "bundles"
RULES = JDG / "rules"
RULE = RULES / "v3_p65_tool_forge.rego"
TOOLS = JDG / "tools"


def _load(name: str) -> dict:
    return json.loads((BUNDLES / f"{name}.json").read_text(encoding="utf-8"))


def _run(script: str, *args: str) -> subprocess.CompletedProcess:
    return subprocess.run([sys.executable, str(TOOLS / script), *args],
                          capture_output=True, text=True, timeout=60)


# ═══ 1. Run-all gate ═══
def test_run_all_gate_pass():
    d = _load("v3_p65_run_all")
    assert d["gate"] == "PASS", d["failures"]
    assert d["engines_run"] == 12
    assert d["tools_run"] == 6
    assert d["failures"] == []


# ═══ 2. I01: wspólny kontrakt narzędzi ═══
def test_i01_tool_contract():
    r = _load("v3_p65_i01_engine")["result"]
    e = _load("v3_p65_i01_contract")["result"]
    assert e["status"] == "PASS"
    assert e["registry_total"] >= 9
    assert e["registry_missing_tools"] == []
    assert set(r["contract_fields_missing"]) == set()
    assert r["dry_run_supported"] is True
    assert set(e["exit_code_semantics"]) == {"0", "1", "2"}
    # dry-run: oblicza bez zapisu — exit 0
    proc = _run("v3_p65_tool_contract.py", "--dry-run", "--json")
    assert proc.returncode == 0


# ═══ 3. I02: semantic diff Rego (3 klasy) ═══
def test_i02_semantic_diff():
    r = _load("v3_p65_i02_engine")["result"]
    assert len(r["classes_present"]) >= 3  # cosmetic/threshold/semantic
    assert r["self_test_pass"] is True
    e = _load("v3_p65_i02_semantic_diff")["result"]
    assert e["all_classes_covered"] is True
    assert e["diff"]["total_changes"] >= 1  # realne porównanie reguł


# ═══ 4. I03: generator testów z przepisu ═══
def test_i03_rule_to_tests():
    r = _load("v3_p65_i03_engine")["result"]
    assert set(r["edge_case_classes_missing"]) == set()
    assert len(r["edge_case_classes_present"]) >= 4  # dates/thresholds/currencies/rounding
    assert r["skeleton_cases"] >= 4
    e = _load("v3_p65_i03_rule_to_tests")["result"]
    assert "v3_p51_desert_cards" in e["evidence"]  # kompozycja z P51


# ═══ 5. I04: cashflow simulator (kompozycja P62) ═══
def test_i04_cashflow():
    r = _load("v3_p65_i04_engine")["result"]
    assert r["p62_engines_present"] is True
    assert r["p62_gate_pass"] is True  # bundles/v3_p62_run_all.json gate=PASS
    assert len(r["scenarios_present"]) >= 3


# ═══ 6. I05: temporal simulator (kompozycja P53) ═══
def test_i05_temporal():
    r = _load("v3_p65_i05_engine")["result"]
    assert r["p53_engines_present"] is True
    assert len(r["transitions_present"]) >= 2


# ═══ 7. I06: RBAC validator (kompozycja P63) ═══
def test_i06_rbac():
    r = _load("v3_p65_i06_engine")["result"]
    assert r["roles_total"] >= 4  # 4 role z P63 I01_rbac_as_data
    assert all("field_map" in v for v in r["roles_matrix"].values())
    assert "v3_p63_i01_rbac.json" in r["source_bundle"]


# ═══ 8. I07: eval benchmark (kompozycja P37) ═══
def test_i07_benchmark():
    r = _load("v3_p65_i07_engine")["result"]
    assert r["tool_p95_support"] is True  # v3_p37_benchmark_gate.py mierzy p95
    assert r["tool_regression_support"] is True
    assert r["reduction_plan_registered"] is True  # bramka P37 w CI


# ═══ 9. I08: WORM tamper tester ═══
def test_i08_worm():
    r = _load("v3_p65_i08_engine")["result"]
    e = _load("v3_p65_i08_worm")["result"]
    assert e["status"] == "PASS"
    assert e["tamper_probes"] >= 5
    assert e["all_detected"] is True  # 5/5 prób naruszenia wykrytych
    assert r["tampering_detected"] == r["tamper_probes"]
    assert "v3_p42_worm_hash_chain" in r["composes"]


# ═══ 10. I09: legal chaos suite (kompozycja P49) ═══
def test_i09_chaos():
    r = _load("v3_p65_i09_engine")["result"]
    assert r["mutations"] >= 10
    assert r["fail_closed_breaches"] == 0
    assert r["auto_post_hits_in_chaos_tools"] == 0  # narzędzia P49 bez AUTO_POST
    assert len(r["chaos_tools_found"]) >= 3


# ═══ 11. I10: composition-first ═══
def test_i10_composition():
    r = _load("v3_p65_i10_engine")["result"]
    assert r["composition_analysis_present"] is True
    assert r["tools_with_composition_map"] >= 3
    assert len(r["real_sources_scanned"]) >= 6  # P42/P49/P51/P53/P62/P64


# ═══ 12. I11: tool adoption metrics ═══
def test_i11_adoption():
    r = _load("v3_p65_i11_engine")["result"]
    assert r["unused_tools_without_decision"] == 0
    assert r["tools_used"] == r["tools_total"] == 6
    assert r["cycle"] == "weekly"
    e = _load("v3_p65_i11_adoption")["result"]
    assert all(row["exists"] for row in e["rows"])


# ═══ 13. I12: tool documentation generator ═══
def test_i12_docs():
    r = _load("v3_p65_i12_engine")["result"]
    assert r["doc_binding_present"] is True
    assert r["drift_detected"] is False
    assert r["tools_documented"] == 5
    doc = JDG / "docs" / "TOOLS_P65_GENERATED.md"
    assert doc.exists() and "WYGENEROWANE" in doc.read_text(encoding="utf-8")
    # --check po zapisie: zero dryfu
    proc = _run("v3_p65_doc_generator.py", "--check")
    assert proc.returncode == 0


# ═══ 14. Progi z ADR-002 (zero hardcode) ═══
def test_no_hardcoded_thresholds():
    hay = RULE.read_text(encoding="utf-8")
    for k in ["v3_p65_tool_contract_fields_min", "v3_p65_tool_contract_required_fields",
              "v3_p65_semantic_diff_classes_min", "v3_p65_edge_case_classes_min",
              "v3_p65_cashflow_scenarios_min", "v3_p65_temporal_transitions_min",
              "v3_p65_rbac_matrix_roles_min", "v3_p65_eval_p95_ms_max",
              "v3_p65_worm_tamper_probes_min", "v3_p65_chaos_mutations_min",
              "v3_p65_composition_first_required", "v3_p65_adoption_cycle",
              "v3_p65_doc_binding_required"]:
        assert k in hay, f"brak klucza ADR-002: {k}"
    th = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    assert '"v3_p65_threshold_version": "tool-forge-v3p65-2026.09"' in th
    assert th.count('"v3_p65_') >= 14  # threshold_version + 13 kluczy I01–I12


def test_thresholds_temporal_window():
    th = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    blk = th[th.index("v3_p65 := {"):]
    assert '"valid_from": "2026-01-01"' in blk and '"valid_to": null' in blk


# ═══ 15. Wiring main_jdg p129 ═══
def test_wiring_main_jdg():
    main = (RULES / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.v3_p65_tool_forge as v3_p65_tool_forge" in main
    assert "final_verdict_p129 = safe_merge(final_verdict_p128" in main
    assert "v3_p65_tool_forge.decide" in main
    post = main[main.index("final_verdict_post_merge = safe_merge("):]
    # Kotwica POST-MERGE przesunięta na p131 (wiring P67, kampania V3).
    assert "final_verdict_p131" in post[:400]


# ═══ 16. Mirror: hash-parity policies/ ═══
def _sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def test_mirror_hash_parity():
    for name in ["v3_p65_tool_forge", "v3_p64_luka_sweep", "thresholds_jdg", "main_jdg"]:
        canonical = JDG / "rules" / f"{name}.rego"
        mirror = JDG.parent / "policies" / f"{name}.rego"
        assert mirror.exists(), f"brak mirrora: {mirror}"
        assert _sha(canonical) == _sha(mirror), f"mirror drift: {name}"


# ═══ 17. Fail-closed statycznie: router nie ma ścieżki AUTO_POST ═══
def test_fail_closed_static():
    hay = RULE.read_text(encoding="utf-8")
    assert hay.count('"AUTO_POST"') == 0
    assert "NO_MATCH" in hay and "NEEDS_ADVICE" in hay
    # final_verdict_p129 tylko w komentarzu nagłówka (konwencja P59–P64) —
    # rega P65 nie wykonuje host-wiringu.
    assert hay.count("final_verdict_p129") == 1


# ═══ 18. Rego struktura: pakiety, priorytety, unikalność ═══
def test_rego_structure():
    t = RULE.read_text(encoding="utf-8")
    assert t.count("{") == t.count("}")
    assert "package jdg.v3_p65_tool_forge" in t
    for n in range(1, 13):
        assert f"4650{n:02d}" in t, f"brak priorytetu I{n:02d}"


# ═══ 19. Narzędzia P65: determinizm (dry-run identyczny) ═══
def test_tools_deterministic():
    p1 = _run("v3_p65_tool_contract.py", "--dry-run", "--json")
    p2 = _run("v3_p65_tool_contract.py", "--dry-run", "--json")
    assert p1.returncode == p2.returncode == 0
    a, b = json.loads(p1.stdout), json.loads(p2.stdout)
    a.pop("generated_at", None), b.pop("generated_at", None)
    assert a == b  # drugi przebieg = identyczny wynik


# ═══ 20. Źródła PRAWDA: kompozycja, nie duplikacja ═══
def test_no_duplication_of_earlier_engines():
    hay = ((TOOLS / "v3_p65_engines.py").read_text(encoding="utf-8")
           + (TOOLS / "v3_p65_common.py").read_text(encoding="utf-8"))
    for src in ["v3_p62_engines.py", "v3_p53_engines.py", "v3_p63_i01_rbac.json",
                "v3_p37_benchmark_gate.py", "v3_p49_chaos_input.py",
                "v3_p42_worm_hash_chain.py", "v3_p51_desert_cards.py",
                "v3_p64_sweep_engine.py", "ROLE_MAPS.md", "KATALOG_NARZEDZI.md"]:
        assert src in hay, f"brak powiązania z prawdziwym źródłem: {src}"
