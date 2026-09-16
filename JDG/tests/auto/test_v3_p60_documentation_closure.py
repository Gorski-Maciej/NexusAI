"""Testy pytest V3-P60 DOKUMENTACJA DOMKNIĘCIE (konwencja P51–P59).

Pokrywają: 12 silników I01–I12 vs bundla (jedno źródło), progi z ADR-002
(brak hardcode), wiring main_jdg p124, mirror hash-parity, fail-closed.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

import pytest

JDG = Path(__file__).resolve().parents[2]
BUNDLES = JDG / "bundles"
RULES = JDG / "rules"
RULE = RULES / "v3_p60_documentation_closure.rego"


def _load(name: str) -> dict:
    return json.loads((BUNDLES / f"{name}.json").read_text(encoding="utf-8"))


# ═══ 1. Run-all gate ═══
def test_run_all_gate_pass():
    d = _load("v3_p60_run_all")
    assert d["gate"] == "PASS", d["failures"]
    assert d["engines_run"] == 12
    assert d["failures"] == []


def test_all_bundles_pass():
    for name in ["v3_p60_doc_truth", "v3_p60_snippets_gate", "v3_p60_frontmatter",
                 "v3_p60_ghosts", "v3_p60_role_maps", "v3_p60_audit_export_gate",
                 "v3_p60_freshness", "v3_p60_holy_docs", "v3_p60_examples",
                 "v3_p60_glossary", "v3_p60_plen_parity", "v3_p60_role_coverage"]:
        r = _load(name)["result"]
        assert r["gate"] == "PASS", f"{name}: {r['gate']}"


# ═══ 2. I01: zgodność dokument↔rejestr ═══
def test_i01_doc_truth():
    r = _load("v3_p60_doc_truth")["result"]
    assert r["mismatches"] == []
    assert r["pct"] >= r["min_pct"]
    assert r["min_pct"] == 95  # ADR-002 v3_p60_doc_truth_min_pct


# ═══ 3. I02: snippety z rejestrów ═══
def test_i02_registry_snippets():
    r = _load("v3_p60_snippets_gate")["result"]
    assert r["snippets_total"] >= r["min_snippets"] == 6
    sn = json.loads((BUNDLES / "v3_p60_snippets.json").read_text(encoding="utf-8"))
    ids = [s["id"] for s in sn["result"]["snippets"]]
    assert len(set(ids)) == len(ids) == 6
    for s in sn["result"]["snippets"]:
        assert s["source"], "snippet bez provenance"


# ═══ 4. I03: front-matter dokumentów rdzenia ═══
def test_i03_frontmatter_binding():
    r = _load("v3_p60_frontmatter")["result"]
    assert r["fm_missing"] == []
    assert r["docs_with_fm"] == 14


# ═══ 5. I04: zero dokumentów-widm ═══
def test_i04_no_ghosts():
    r = _load("v3_p60_ghosts")["result"]
    assert r["ghosts"] == []


# ═══ 6. I05/I12: mapy rolowe 4 role, pokrycie 100% ═══
def test_i05_i12_role_maps():
    r5 = _load("v3_p60_role_maps")["result"]
    r12 = _load("v3_p60_role_coverage")["result"]
    assert r5["missing_roles"] == []
    assert set(r5["maps"]) == {"developer", "operator", "auditor", "entrepreneur"}
    assert r12["coverage_pct"] == 100


# ═══ 7. I06: eksport audytowy z checksumami ═══
def test_i06_audit_export():
    r = _load("v3_p60_audit_export_gate")["result"]
    assert r["export_present"] is True
    assert r["retention_days"] == 1825
    ex = json.loads((BUNDLES / "v3_p60_audit_export.json").read_text(encoding="utf-8"))
    assert ex["schema"] == "jdg.v3_p60.audit_export.v1"
    assert len(ex["docs"]) >= 10 and len(ex["registries"]) >= 4
    for doc in ex["docs"].values():
        assert len(doc["sha256"]) == 64


# ═══ 8. I07: świeżość dokumentów ═══
def test_i07_freshness():
    r = _load("v3_p60_freshness")["result"]
    assert r["stale"] == []


# ═══ 9. I08: dokumenty święte chronione ═══
def test_i08_holy_docs():
    r = _load("v3_p60_holy_docs")["result"]
    assert r["unprotected"] == []
    assert r["total"] == 2


# ═══ 10. I09: przykłady-as-test (verify_cmd wskazuje istniejące narzędzia) ═══
def test_i09_examples_as_test():
    r = _load("v3_p60_examples")["result"]
    assert r["untested_cmds"] == []
    assert len(r["verify_cmds"]) >= 8


# ═══ 11. I10: glosariusz 30 terminów, zero naruszeń ═══
def test_i10_glossary():
    r = _load("v3_p60_glossary")["result"]
    assert r["terms_checked"] >= r["min_terms"] == 12
    assert r["violations"] == []


# ═══ 12. I11: paroliść PL/EN ═══
def test_i11_plen_parity():
    r = _load("v3_p60_plen_parity")["result"]
    assert r["parity_pct"] >= r["min_pct"] == 80
    assert r["mismatched"] == []  # dryf ADR-016..022 naprawiony w P60


# ═══ 13. Progi z ADR-002 (zero hardcode) ═══
def test_no_hardcoded_thresholds():
    hay = RULE.read_text(encoding="utf-8")
    for k in ["v3_p60_doc_truth_min_pct", "v3_p60_generated_snippets_min",
              "v3_p60_ghost_documents_max", "v3_p60_role_coverage_min_pct",
              "v3_p60_plen_parity_min_pct", "v3_p60_audit_export_retention_days"]:
        assert k in hay, f"brak klucza ADR-002: {k}"
    th = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    assert '"v3_p60_threshold_version": "documentation-closure-v3p60-2026.09"' in th
    assert th.count('"v3_p60_') >= 12


def test_thresholds_temporal_window():
    th = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    blk = th[th.index("v3_p60 := {"):]
    assert '"valid_from": "2026-01-01"' in blk and '"valid_to": null' in blk


# ═══ 14. Wiring main_jdg p124 ═══
def test_wiring_main_jdg():
    main = (RULES / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.v3_p60_documentation_closure as v3_p60_documentation_closure" in main
    assert "final_verdict_p124 = safe_merge(final_verdict_p123" in main
    assert "v3_p60_documentation_closure.decide" in main
    post = main[main.index("final_verdict_post_merge = safe_merge("):]
    # Kotwica POST-MERGE przesunięta na p128: łańcuch urósł o P64
    # (wiring final_verdict_p130, kampania V3 — P66 CHAOS_ODPORNOSC).
    assert "final_verdict_p131" in post[:400]


# ═══ 15. Mirror: hash-parity policies/ ═══
def _sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def test_mirror_hash_parity():
    for name in ["v3_p60_documentation_closure", "v3_p59_security_closure",
                 "thresholds_jdg", "main_jdg"]:
        canonical = JDG / "rules" / f"{name}.rego"
        mirror = JDG.parent / "policies" / f"{name}.rego"
        assert mirror.exists(), f"brak mirrora: {mirror}"
        assert _sha(canonical) == _sha(mirror), f"mirror drift: {name}"


# ═══ 16. Fail-closed statycznie: router nie ma ścieżki AUTO_POST ═══
def test_fail_closed_static():
    hay = RULE.read_text(encoding="utf-8")
    assert hay.count('"AUTO_POST"') == 0
    assert "NO_MATCH" in hay and "NEEDS_ADVICE" in hay
    # final_verdict_p124 tylko w komentarzu nagłówka (konwencja P59) —
    # rega P60 nie wykonuje host-wiringu.
    assert hay.count("final_verdict_p124") == 1


# ═══ 17. Rego struktura: pakiety, priorytety, unikalność ═══
def test_rego_structure():
    t = RULE.read_text(encoding="utf-8")
    assert t.count("{") == t.count("}")
    assert "package jdg.v3_p60_documentation_closure" in t
    for n in range(1, 13):
        assert f"4600{n:02d}" in t, f"brak priorytetu I{n:02d}"
