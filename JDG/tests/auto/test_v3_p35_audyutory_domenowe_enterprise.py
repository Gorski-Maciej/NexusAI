# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P35 (AUDYTORY DOMENOWE — ZAUFANIE DOMEN JAKO GOVERNANCE)
— kampania V3 FORTRESS.

Weryfikuje:
  * reguły OPA w rules/v3_p35_audyutory_domenowe_enterprise.rego (12 analiz I01-I12),
  * parametry-as-data w rules/thresholds_jdg.rego (blok v3_p35, ADR-002/P06, P05),
  * wiring w rules/main_jdg.rego (final_verdict_p99),
  * 12 narzędzi dowodowych tools/v3_p35_*.py i 12 bundli bundles/v3_p35_*.json,
  * spójność z legacy: audytory domen z sekcji 6.1-6.3 promptu (istnienie),
    kontrakty P03/P04 (werdykt, invarianty), P10 (golden registry), P31
    (unified schema), P33 (trust score telemetria), P37 (dashboardy),
  * granice: trust floor 70 / drop 10, golden replay 30 dni, feedback 14 dni,
    SLA 4 h, law freshness 7 dni, inverse min 3.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"

P35_REGO = RULES / "v3_p35_audyutory_domenowe_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"

INNOVATIONS = {
    "I01": "jdg.v3_p35_audyutory_domenowe.domain_trust_score",
    "I02": "jdg.v3_p35_audyutory_domenowe.auditor_as_data",
    "I03": "jdg.v3_p35_audyutory_domenowe.golden_case_registry",
    "I04": "jdg.v3_p35_audyutory_domenowe.unified_audit_report",
    "I05": "jdg.v3_p35_audyutory_domenowe.drill_down_evidence",
    "I06": "jdg.v3_p35_audyutory_domenowe.skew_detection",
    "I07": "jdg.v3_p35_audyutory_domenowe.dashboards_as_data",
    "I08": "jdg.v3_p35_audyutory_domenowe.continuous_vs_per_pr",
    "I09": "jdg.v3_p35_audyutory_domenowe.operator_feedback",
    "I10": "jdg.v3_p35_audyutory_domenowe.alert_routing",
    "I11": "jdg.v3_p35_audyutory_domenowe.legal_freshness_stamp",
    "I12": "jdg.v3_p35_audyutory_domenowe.inverse_audit",
}

ANALYSES = [
    "domain_trust_score", "auditor_as_data", "golden_case_registry",
    "unified_audit_report", "drill_down_evidence", "skew_detection",
    "dashboards_as_data", "continuous_vs_per_pr", "operator_feedback",
    "alert_routing", "legal_freshness_stamp", "inverse_audit",
]

TOOLS_EXPECTED = {
    "v3_p35_domain_trust_score.py", "v3_p35_auditor_as_data.py",
    "v3_p35_golden_case_registry.py", "v3_p35_unified_audit_report.py",
    "v3_p35_drill_down_evidence.py", "v3_p35_skew_detection.py",
    "v3_p35_dashboards_as_data.py", "v3_p35_continuous_vs_per_pr.py",
    "v3_p35_operator_feedback.py", "v3_p35_alert_routing.py",
    "v3_p35_legal_freshness_stamp.py", "v3_p35_inverse_audit.py",
}

# Audytory domen z sekcji 6.1-6.3 promptu P35 (istnienie = dowód)
CORE_AUDITOR_TOOLS = [
    "vat_macro_audit.py", "vat_micro_auditor.py", "vat_micro_core_audit.py",
    "vat_micro_special_audit.py", "vat_micro_inventory.py",
    "vat_innovation_tools.py", "vat_gap_detector.py",
    "zus_macro_auditor.py", "zus_micro_auditor.py", "zus_micro_inventory.py",
    "zus_micro_quality.py", "ksef_jpk_edeklaracje_auditor.py",
    "enterprise_dashboard.py", "confidence_dashboard.py", "drift_dashboard.py",
]

CORE_AUDITOR_TESTS = [
    "test_vat_macro_audit.py", "test_vat_micro_core_audit.py",
    "test_vat_micro_special_audit.py", "test_pit_macro_audit.py",
    "test_pit_micro_reliefs_audit.py", "test_zus_core_etap12_audit.py",
    "test_zus_micro_etap13_audit.py", "test_ksef_jpk_etap20_audit.py",
]

CORE_AUDITOR_DOCS = [
    "PEWNOSC_DASHBOARD.md", "ZGODNOSC_PRAWNA.md", "LEGAL_COVERAGE.md",
    "LEGAL_COVERAGE_GAP_RAPORT.md", "PIT_AUDYT_R04.md", "VAT_AUDYT_R03.md",
]

THRESHOLD_KEYS_V3P35 = [
    "v3_p35_threshold_version", "legal_basis_version", "valid_from",
    "v3_p35_trust_score_floor", "v3_p35_trust_drop_triage",
    "v3_p35_missing_controls_max", "v3_p35_golden_cases_min_per_domain",
    "v3_p35_golden_replay_max_age_days", "v3_p35_nightly_missed_max_days",
    "v3_p35_feedback_max_age_days", "v3_p35_alert_sla_hours",
    "v3_p35_law_freshness_max_days", "v3_p35_inverse_cases_min",
]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def _thresholds_block() -> str:
    src = _read(THRESHOLDS)
    i = src.find("v3_p35 := {")
    assert i >= 0, "brak bloku v3_p35 w thresholds_jdg.rego"
    depth, end = 0, -1
    for j in range(i, len(src)):
        if src[j] == "{":
            depth += 1
        elif src[j] == "}":
            depth -= 1
            if depth == 0:
                end = j
                break
    return src[i:end]


# ── Pakiet V3-P35 ─────────────────────────────────────────────────────────────

def test_p35_rego_exists_and_structured():
    src = _read(P35_REGO)
    assert src, "brak rules/v3_p35_audyutory_domenowe_enterprise.rego"
    assert "package jdg.v3_p35_audyutory_domenowe" in src
    assert src.count("{") == src.count("}"), "nierównoważne nawiasy"
    rule_ids = re.findall(r'"rule_id": "([^"]+)"', src)
    assert len(rule_ids) == len(set(rule_ids)), "duplikaty rule_id w pakiecie P35"


def test_p35_all_12_innovations_present():
    src = _read(P35_REGO)
    for iid, rid in INNOVATIONS.items():
        assert rid in src, f"brak reguły {iid}: {rid}"


def test_p35_decide_chain_covers_all_analyses():
    src = _read(P35_REGO)
    chain = src.split("decide := fail_closed_decision")[1]
    for iid, rid in INNOVATIONS.items():
        rule_name = rid.rsplit(".", 1)[1]
        assert f"{rule_name}_decision" in chain, f"brak reguły {iid} w łańcuchu decide"
    assert chain.count("else :=") >= len(ANALYSES), "niekompletny else-chain decide"


def test_p35_fail_closed_no_silent_auto_post():
    src = _read(P35_REGO)
    assert "fail_closed_decision" in src
    assert "_snapshot_ok" in src
    assert '"_routing": "BLOCK_AND_ALERT"' in src
    assert "no_match" in src
    for m in re.finditer(r"\{\s*true\s*\}", src):
        prefix = src[:m.start()].rstrip().splitlines()[-1]
        assert "else" in prefix, (
            f"AP01: samodzielny stub bez else w P35 (kontekst: {prefix!r})")


def test_p35_public_rule_count():
    src = _read(P35_REGO)
    rule_ids = re.findall(
        r'"rule_id": "jdg\.v3_p35_audyutory_domenowe\.[a-z_]+"', src)
    assert len(rule_ids) >= 12, "za mało reguł publicznych w pakiecie"


# ── Parametry jako dane (ADR-002/P06) + okno temporalne (P05) ─────────────────

def test_v3p35_block_complete():
    block = _thresholds_block()
    for key in THRESHOLD_KEYS_V3P35:
        assert f'"{key}"' in block, f"brak klucza {key} v3_p35"
    assert '"valid_from"' in block, "brak okna temporalnego (P05)"


def test_v3p35_governance_limits():
    block = _thresholds_block()
    assert '"v3_p35_trust_score_floor": 70' in block, "trust floor 70 (I01)"
    assert '"v3_p35_trust_drop_triage": 10' in block, "spadek trust 10 (I01)"
    assert '"v3_p35_golden_replay_max_age_days": 30' in block, "replay 30 dni (I03)"
    assert '"v3_p35_feedback_max_age_days": 14' in block, "feedback 14 dni (I09)"
    assert '"v3_p35_alert_sla_hours": 4' in block, "SLA 4 h (I10)"
    assert '"v3_p35_law_freshness_max_days": 7' in block, "freshness 7 dni (I11)"
    assert '"v3_p35_inverse_cases_min": 3' in block, "inverse min 3 (I12)"


# ── Wiring main_jdg ───────────────────────────────────────────────────────────

def test_main_jdg_wired_p99():
    src = _read(MAIN_JDG)
    assert "import data.jdg.v3_p35_audyutory_domenowe as v3_p35_audyutory_domenowe" in src
    assert '"jdg.v3_p35_audyutory_domenowe": v3_p35_audyutory_domenowe.decide' in src
    assert "final_verdict_p99 = safe_merge(final_verdict_p98" in src
    assert "final_verdict_post_merge = safe_merge(" in src
    assert "final_verdict_p99\n)" in src or "safe_merge(final_verdict_p99," in src


# ── Spójność z legacy (audytory rdzenia, kontrakty P03/P04/P10/P31/P33/P37) ───

def test_p35_threshold_version_consistency():
    rego = _read(P35_REGO)
    assert "data.jdg.thresholds.v3_p35" in rego, \
        "pakiet P35 nie podpięty pod snapshot progów"
    assert "v3_p35_threshold_version" in rego, \
        "brak odczytu threshold_version w pakiecie P35"


def test_legacy_contracts_honored():
    src = _read(P35_REGO)
    assert "P10" in src                          # golden registry (I03/I09)
    assert "P31" in src                          # unified schema (I02/I04)
    assert "P37" in src                          # dashboardy/alerty (I07/I10)
    assert "telemetri" in src.lower()            # trust score = telemetria (P33-I06)
    assert "NEEDS_ADVICE" in src or "TRIAGE" in src  # fail-closed P04


def test_core_auditor_tools_exist():
    missing = [t for t in CORE_AUDITOR_TOOLS if not (TOOLS / t).exists()]
    assert not missing, f"brak audytorów rdzenia: {missing}"


def test_core_auditor_tests_exist():
    missing = [t for t in CORE_AUDITOR_TESTS if not (BASE / "tests" / t).exists()]
    assert not missing, f"brak testów audytorów rdzenia: {missing}"


def test_core_auditor_docs_exist():
    missing = [d for d in CORE_AUDITOR_DOCS if not (BASE / "docs" / d).exists()]
    assert not missing, f"brak dokumentów audytów: {missing}"


# ── Narzędzia dowodowe i bundle ───────────────────────────────────────────────

def test_p35_tools_present():
    for name in sorted(TOOLS_EXPECTED):
        assert (TOOLS / name).exists(), f"brak tools/{name}"


def test_p35_bundles_all_pass():
    for name in sorted(TOOLS_EXPECTED):
        bundle = BUNDLES / (name.replace(".py", ".json"))
        assert bundle.exists(), f"brak bundles/{bundle.name}"
        data = _read(bundle)
        assert '"gate": "PASS"' in data, f"gate FAIL: {bundle.name}"


def test_p35_bundle_innovations_match_tools():
    for name in sorted(TOOLS_EXPECTED):
        bpath = BUNDLES / (name.replace(".py", ".json"))
        data = json.loads(_read(bpath))
        iid = data["innovation"]
        assert re.fullmatch(r"V3-P35-I\d{2}", iid), f"błędny ID innowacji: {iid}"
        assert iid in _read(P35_REGO), f"{iid} nie ma reguły w pakiecie"
