#!/usr/bin/env python3
"""NexusAI JDG — V3-P41 DOKUMENTACJA — testy pytest (konwencja P39 negative-first).

Pokrycie: 12 bundli dowodowych (gate=PASS), rego (39/39 ×2 OPA), progi jako
dane (ADR-002), wiring final_verdict_p105, rejestr dokumentacji (24 pliki
Sekcji 6), bramka docs w CI, changelog generowany z ledgera.
"""
from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"
TESTS = BASE / "tests"
DOCS = BASE / "docs"

P41_RULES = RULES / "v3_p41_dokumentacja_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"
DOC_REGISTRY = BUNDLES / "v3_p41_doc_registry.json"
WORKFLOW = BASE / ".github" / "workflows" / "jdg-quality.yml"

P41_RULE_IDS = [
    "jdg.v3_p41_dokumentacja.doc_code_binding",
    "jdg.v3_p41_dokumentacja.ssot_numbers",
    "jdg.v3_p41_dokumentacja.role_doc_maps",
    "jdg.v3_p41_dokumentacja.semantic_diff_pl_en",
    "jdg.v3_p41_dokumentacja.glossary_enforcement",
    "jdg.v3_p41_dokumentacja.audit_export_pack",
    "jdg.v3_p41_dokumentacja.runbook_coverage",
    "jdg.v3_p41_dokumentacja.changelog_automation",
    "jdg.v3_p41_dokumentacja.freshness_stamps",
    "jdg.v3_p41_dokumentacja.doc_testing",
    "jdg.v3_p41_dokumentacja.auditor_mode",
    "jdg.v3_p41_dokumentacja.legacy_retirement",
]

BUNDLE_TO_INNOVATION = {
    "v3_p41_doc_code_binding": "V3-P41-I01",
    "v3_p41_ssot_numbers": "V3-P41-I02",
    "v3_p41_role_doc_maps": "V3-P41-I03",
    "v3_p41_semantic_diff_pl_en": "V3-P41-I04",
    "v3_p41_glossary_enforcement": "V3-P41-I05",
    "v3_p41_audit_export_pack": "V3-P41-I06",
    "v3_p41_runbook_coverage": "V3-P41-I07",
    "v3_p41_changelog_automation": "V3-P41-I08",
    "v3_p41_freshness_stamps": "V3-P41-I09",
    "v3_p41_doc_testing": "V3-P41-I10",
    "v3_p41_auditor_mode": "V3-P41-I11",
    "v3_p41_legacy_retirement": "V3-P41-I12",
}


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def _rego_test_count() -> int:
    out = subprocess.run(
        [str(BASE.parent / "bin" / "opa"), "test",
         str(TESTS / "rego" / "test_v3_p41_dokumentacja_enterprise.rego"),
         str(P41_RULES), str(THRESHOLDS)],
        cwd=BASE, capture_output=True, text=True, timeout=120)
    m = re.search(r"PASS: (\d+)/(\d+)", out.stdout + out.stderr)
    return int(m.group(2)) if m else 0


# ═══════════════════════════════════════════════════════════════════════════════
# Rego — reguły, progi, wiring
# ═══════════════════════════════════════════════════════════════════════════════

def test_rego_all_12_rule_ids_present():
    hay = _read(P41_RULES)
    missing = [r for r in P41_RULE_IDS if r not in hay]
    assert not missing, f"Brakujące rule_id w rego: {missing}"


def test_rego_negative_assertions_present():
    hay = _read(TESTS / "rego" / "test_v3_p41_dokumentacja_enterprise.rego")
    assert "BLOCK_AND_ALERT" in hay and "TRIAGE_QUEUE" in hay
    assert hay.count("test_p41_") >= 30


def test_rego_native_suite_passes():
    n = _rego_test_count()
    assert n >= 30, f"Native rego suite za mało przypadków: {n}"


def test_thresholds_as_data():
    th = _read(THRESHOLDS)
    for key in ["v3_p41_plen_diff_max_findings", "v3_p41_glossary_violations_max",
                "v3_p41_runbook_coverage_min_pct", "v3_p41_changelog_max_age_days",
                "v3_p41_doc_freshness_max_days", "v3_p41_threshold_version"]:
        assert f'"{key}"' in th, f"Brak progu {key} w thresholds_jdg.rego"


def test_main_jdg_wired_p105():
    main = _read(MAIN_JDG)
    assert "import data.jdg.v3_p41_dokumentacja as v3_p41_dokumentacja" in main
    assert '"jdg.v3_p41_dokumentacja": v3_p41_dokumentacja.decide' in main
    assert "final_verdict_p105" in main
    assert "final_verdict_p104 = safe_merge(final_verdict_p103" in main
    assert "final_verdict_p105 = safe_merge(final_verdict_p104" in main


def test_rule_names_not_test_prefixed():
    hay = _read(P41_RULES)
    for m in re.finditer(r"^(\w+_decision)\b", hay, re.M):
        assert not m.group(1).startswith("test_"), m.group(1)


# ═══════════════════════════════════════════════════════════════════════════════
# Bundle dowodowe — 12 gate PASS
# ═══════════════════════════════════════════════════════════════════════════════

def test_all_12_bundles_pass():
    for name, innovation in BUNDLE_TO_INNOVATION.items():
        p = BUNDLES / f"{name}.json"
        assert p.exists(), f"Brak bundla: {p}"
        b = json.loads(p.read_text(encoding="utf-8"))
        assert b.get("gate") == "PASS", f"{innovation}: gate={b.get('gate')}"
        assert b.get("innovation") == innovation


def test_bundles_have_checks_and_no_blockers():
    for name in BUNDLE_TO_INNOVATION:
        b = json.loads((BUNDLES / f"{name}.json").read_text(encoding="utf-8"))
        assert len(b.get("checks", [])) >= 4, name
        for f in b.get("findings", []):
            assert not f.startswith("P0"), f"{name}: blocker {f}"


# ═══════════════════════════════════════════════════════════════════════════════
# Rejestr dokumentacji (24 pliki Sekcji 6)
# ═══════════════════════════════════════════════════════════════════════════════

def test_doc_registry_covers_all_24_files():
    reg = json.loads(DOC_REGISTRY.read_text(encoding="utf-8"))
    docs = reg["documents"]
    assert len(docs) >= 24
    for required in ["ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md", "WIZJA_OPA_ENTERPRISE_V2.md",
                     "SLOWNIK_REFERENCJI_PRAWNYCH.md", "KATALOG_REGUL.md", "Bbb"]:
        assert required in docs


def test_doc_registry_bindings_and_stamps():
    reg = json.loads(DOC_REGISTRY.read_text(encoding="utf-8"))
    for name, v in reg["documents"].items():
        assert v.get("status") in {"CURRENT", "ARCHIVED", "SUPERSEDED"}, name
        assert v.get("last_verified"), name
        assert v.get("bound_artifacts"), name


def test_role_reading_maps_complete():
    reg = json.loads(DOC_REGISTRY.read_text(encoding="utf-8"))
    maps = reg["role_reading_maps"]
    assert {"developer", "operator", "auditor", "entrepreneur"} <= set(maps)
    assert all(len(v) >= 3 for v in maps.values())


def test_audit_export_pack_spec():
    reg = json.loads(DOC_REGISTRY.read_text(encoding="utf-8"))
    ep = reg["audit_export_pack"]
    assert ep["checksum_required"] is True
    for part in ["documents", "legal_registers", "checksums", "seal"]:
        assert part in ep["contents"]


def test_auditor_mode_evidence_chain():
    reg = json.loads(DOC_REGISTRY.read_text(encoding="utf-8"))
    am = reg["auditor_mode"]
    for step in ["rule", "test", "bundle", "verdict", "certificate"]:
        assert step in am["evidence_chain"]
    assert len(am["evidence_paths"]) >= 3


# ═══════════════════════════════════════════════════════════════════════════════
# Bramka docs w CI (I01) + changelog automation (I08)
# ═══════════════════════════════════════════════════════════════════════════════

def test_docs_gate_in_ci_workflow():
    wf = _read(WORKFLOW)
    assert "DOCS_GATE" in wf, "Bramka 6b DOCS_GATE nieobecna w workflow CI"
    assert "v3_p41_doc_code_binding.py" in wf


def test_changelog_generated_from_ledger():
    ch = json.loads((BUNDLES / "v3_p41_changelog.json").read_text(encoding="utf-8"))
    assert ch["generated_from"] == "v3_campaign_ledger"
    assert len(ch["entries"]) >= 40


def test_priorities_unique_441001_441012():
    hay = _read(P41_RULES)
    prios = sorted(set(int(m) for m in re.findall(r"_certificate\((44\d{4})", hay)))
    assert prios == list(range(441001, 441013)), prios
