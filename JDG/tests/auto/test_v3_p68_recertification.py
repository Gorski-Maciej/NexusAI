"""Testy pytest V3-P68 RE-CERTYFIKACJA (konwencja P51–P67).

Pokrywają: 12 silników I01–I12 vs bundla (jedno źródło), rozliczenie 23
rejestrów P45–P67 (settlement jako DANE), hard gates z pomiaru (P49/P50/mirror/
ADR-002), scoreboard 9 filarów z statusami dowodowymi, politykę odnowienia,
progi z ADR-002 (brak hardcode), wiring main_jdg p132, mirror hash-parity,
fail-closed (zero AUTO_POST), post-mortem kampanii, truth-first (production
NOT_CERTIFIED jawne), determinizm silników (2 przebiegi identyczne).
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
RULE = RULES / "v3_p68_recertification_final.rego"
TOOLS = JDG / "tools"
SETTLEMENT = TOOLS / "v3_p68_settlement.json"


def _load(name: str) -> dict:
    return json.loads((BUNDLES / f"{name}.json").read_text(encoding="utf-8"))


def _run(script: str, *args: str) -> subprocess.CompletedProcess:
    return subprocess.run([sys.executable, str(TOOLS / script), *args],
                          capture_output=True, text=True, timeout=120)


# ═══ 1. Run-all gate ═══
def test_run_all_gate_pass():
    d = _load("v3_p68_run_all")
    assert d["gate"] == "PASS", d["failures"]
    assert d["engines_run"] == 12
    assert d["failures"] == []
    assert d["rego_gate"] == "PASS"  # natywne testy OPA (kontrakt C2 z P65)
    assert d["static_gate"] == "PASS"


# ═══ 2. Hard gate I01: decision PASS, zero AUTO_POST zmierzone ═══
def test_i01_hard_gates_pass():
    r = _load("v3_p68_i01_engine")
    assert r["decision"] == "PASS", r["metrics"]
    assert r["metrics"]["violated"] == 0
    p49 = json.loads((BUNDLES / "v3_p49_fail_open_registry.json").read_text(encoding="utf-8"))
    assert p49["metrics"]["silent_auto_post_max"] == 0  # pomiar, nie deklaracja


# ═══ 3. Rozliczenie 23 rejestrów (settlement jako DANE) ═══
def test_i02_settlement_complete():
    st = json.loads(SETTLEMENT.read_text(encoding="utf-8"))
    assert len(st["registers"]) == 23  # P45–P67
    parts = {p["part"] for p in st["registers"]}
    assert parts == {f"P{n}" for n in range(45, 68)}
    for r in st["registers"]:
        assert r["status"] in ("DOMKNIETY", "CZESCIOWY"), r["part"]
        assert r["dowod"] and r["trend"] and r["cel"], r["part"]
        assert "residual_v4" in r  # mapa V4 per rejestr (I04)
    led = json.loads((BUNDLES / "v3_campaign_ledger.json").read_text(encoding="utf-8"))
    for r in st["registers"]:
        assert led["parts"][r["part"]]["status"] == "WDROŻONY_100", r["part"]


def test_i02_engine_matches_ledger():
    r = _load("v3_p68_i02_engine")
    assert r["gate"] == "PASS"
    assert r["metrics"]["registers_settled"] >= 23
    assert r["metrics"]["registers_missing"] == []


# ═══ 4. Scoreboard 9 filarów (statusy dowodowe) ═══
def test_i03_pillar_scoreboard():
    r = _load("v3_p68_i03_engine")
    assert r["gate"] == "PASS"
    assert r["metrics"]["pillars_scored"] == 9
    assert r["metrics"]["invalid_statuses"] == []
    assert r["metrics"]["dowiedzone"] + r["metrics"]["czesciowe"] == 9
    # truth-first: produkcja pozostaje jawna
    ev = json.loads((BUNDLES / "final_certification_v4_evidence.json").read_text(encoding="utf-8"))
    assert ev["production_status"] == "NOT_CERTIFIED"


# ═══ 5. Mapa rezyduum → V4 ═══
def test_i04_residual_map():
    r = _load("v3_p68_i04_engine")
    assert r["gate"] == "PASS"
    assert r["metrics"]["v4_map_present"] is True
    assert r["metrics"]["unmapped_registers"] == []
    assert r["metrics"]["residual_items"] > 0  # rezyduum zinwentaryzowane


# ═══ 6. Definicja sukcesu zamrożona ═══
def test_i05_metric_freeze():
    r = _load("v3_p68_i05_engine")
    assert r["gate"] == "PASS"
    assert r["metrics"]["frozen_metrics"] >= 5


# ═══ 7. Certyfikat WORM + podpis ═══
def test_i06_worm():
    r = _load("v3_p68_i06_engine")
    assert r["gate"] == "PASS"
    assert r["metrics"]["worm_archived"] is True
    assert (TOOLS / "worm_storage.py").exists()


# ═══ 8. Polityka odnowienia ═══
def test_i07_renewal_policy():
    r = _load("v3_p68_i07_engine")
    assert r["gate"] == "PASS"
    assert r["metrics"]["policy_max_days"] > 0
    assert r["metrics"]["policy_on_epoch_change"] is True
    assert r["metrics"]["policy_on_critical_deploy"] is True


# ═══ 9. Akceptacja właściciela (slot, fail-closed procesowo) ═══
def test_i08_owner_attestation():
    r = _load("v3_p68_i08_engine")
    assert r["gate"] == "PASS"
    assert r["metrics"]["required"] is True
    assert r["metrics"]["present"] is False  # czeka na Q01 — jawne


# ═══ 10. Knowledge transfer pack ═══
def test_i09_kt_pack():
    r = _load("v3_p68_i09_engine")
    assert r["gate"] == "PASS"
    assert r["metrics"]["sections"] >= 5


# ═══ 11. Auto-portret fortecy ═══
def test_i10_self_portrait():
    r = _load("v3_p68_i10_engine")
    assert r["gate"] == "PASS"
    assert r["metrics"]["diagram_present"] is True
    assert r["metrics"]["components_table_present"] is True
    assert r["metrics"]["passes"] >= 20  # pasów safe_merge w main_jdg


# ═══ 12. Truth-first: DEKLAROWANE ≠ DOWIEDZONE ═══
def test_i11_truth_first():
    r = _load("v3_p68_i11_engine")
    assert r["decision"] == "PASS"
    assert r["metrics"]["misreported_as_evidenced"] == []
    assert r["metrics"]["production_status"] == "NOT_CERTIFIED"


# ═══ 13. Post-mortem kampanii ═══
def test_i12_post_mortem():
    r = _load("v3_p68_i12_engine")
    assert r["gate"] == "PASS"
    assert r["metrics"]["sections"] == 3
    assert r["metrics"]["change_in_v4_items"] >= 3


# ═══ 14. Progi z ADR-002 (brak hardcode) ═══
def test_thresholds_adr002():
    th = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    assert "v3_p68 := {" in th
    blk = th[th.index("v3_p68 := {"):]
    blk = blk[:blk.index("\n}") + 2]
    for key in ["v3_p68_threshold_version", "v3_p68_hard_gates_required",
                "v3_p68_registers_total", "v3_p68_pillars_total",
                "v3_p68_success_metrics_min", "v3_p68_renewal_max_days",
                "v3_p68_kt_pack_sections_min"]:
        assert f'"{key}"' in blk, f"brak progu {key}"
    assert '"valid_from": "2026-01-01"' in blk and '"valid_to": null' in blk


# ═══ 15. Wiring main_jdg p132 ═══
def test_wiring_main_jdg():
    main = (RULES / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.v3_p68_recertification_final as v3_p68_recertification_final" in main
    assert "final_verdict_p132 = safe_merge(final_verdict_p131" in main
    assert "v3_p68_recertification_final.decide" in main
    post = main[main.index("final_verdict_post_merge = safe_merge("):]
    assert "final_verdict_p132" in post[:400]  # kotwica POST-MERGE p132


# ═══ 16. Mirror: hash-parity policies/ ═══
def _sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def test_mirror_hash_parity():
    for name in ["v3_p68_recertification_final", "v3_p67_self_learning",
                 "thresholds_jdg", "main_jdg"]:
        canonical = JDG / "rules" / f"{name}.rego"
        mirror = JDG.parent / "policies" / f"{name}.rego"
        assert mirror.exists(), f"brak mirrora: {mirror}"
        assert _sha(canonical) == _sha(mirror), f"mirror drift: {name}"


# ═══ 17. Fail-closed statycznie ═══
def test_fail_closed_static():
    hay = RULE.read_text(encoding="utf-8")
    assert hay.count('"AUTO_POST"') == 0
    assert "NO_MATCH" in hay and "NEEDS_ADVICE" in hay and "BLOCK" in hay
    assert hay.count("final_verdict_p132") == 1  # tylko komentarz nagłówka


# ═══ 18. Struktura Rego: pakiety, priorytety ═══
def test_rego_structure():
    t = RULE.read_text(encoding="utf-8")
    assert t.count("{") == t.count("}")
    assert "package jdg.v3_p68_recertification_final" in t
    for n in range(1, 13):
        assert f"4680{n:02d}" in t, f"brak priorytetu I{n:02d}"


# ═══ 19. Natywne testy OPA obecne ═══
def test_native_opa_tests_present():
    t = (JDG / "tests" / "rego" / "test_v3_p68_recertification_final.rego").read_text(encoding="utf-8")
    assert t.count("test_p68_") >= 19


# ═══ 20. Silniki czytają PRAWDZIWE źródła ═══
def test_engines_real_sources():
    hay = ((TOOLS / "v3_p68_engines.py").read_text(encoding="utf-8")
           + (TOOLS / "v3_p68_common.py").read_text(encoding="utf-8"))
    for src in ["v3_campaign_ledger.json", "final_certification_v4_evidence.json",
                "rule_registry.json", "thresholds_data.json", "coverage_deserts.json",
                "golden_verdicts.json", "deployments.json", "healthy_versions.json",
                "enterprise_operating_contract.json", "v3_p64_sweep_register.json",
                "v3_p53_epoch_registry.json", "v3_p67_learning_data.json",
                "worm_storage.py", "v3_p49_fail_open_registry.json",
                "v3_p50_semantic_duplicates.json", "v3_p68_settlement.json",
                "final_certification_v4_gate.py", "zero_defect_certification.py"]:
        assert src in hay, f"brak powiązania z prawdziwym źródłem: {src}"


# ═══ 21. Silniki: determinizm (2 przebiegi I03 identyczne) ═══
def test_engines_deterministic():
    p1 = _run("v3_p68_engines.py", "I03")
    p2 = _run("v3_p68_engines.py", "I03")
    assert p1.returncode == p2.returncode == 0
    a, b = json.loads(p1.stdout), json.loads(p2.stdout)
    assert a == b  # drugi przebieg = identyczny wynik


# ═══ 22. Konwencja P65–P67: zero duplikacji (kompozycja) ═══
def test_no_duplication():
    # P68 czyta bundle bramek P66/P67 i rejestry poprzedników — nie przelicza ponownie
    hay = (TOOLS / "v3_p68_engines.py").read_text(encoding="utf-8")
    for reuse in ["v3_p66_run_all.json", "v3_p67_run_all.json",
                  "v3_p49_fail_open_registry.json", "v3_p64_sweep_register.json"]:
        assert reuse in hay, f"P68 ma czytać z istniejącego rejestru: {reuse}"
