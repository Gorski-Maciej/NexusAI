# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P27 (CFC, EXIT TAX, MDR I PRZEPŁYWY MIĘDZYJURYSDYKCYJNE)
— kampania V3 FORTRESS.

Weryfikuje:
  * reguły OPA w rules/v3_p27_cfc_exit_mdr_enterprise.rego (13 innowacji I01-I13),
  * parametry-as-data w rules/thresholds_jdg.rego (blok crossborder27, ADR-002),
  * 13 narzędzi dowodowych tools/v3_p27_*.py i 13 bundle bundles/v3_p27_*.json,
  * wiring w rules/main_jdg.rego (final_verdict_p91),
  * naprawy legacy: stub AP01 (exit_tax.r6), hardcode AP02 (cfc_auto_classifier,
    exit_tax_cfc_complete), poprawka excise_wine_per_hl (klucz wraca do danych),
  * granice: 2M/4M exit tax, 30 dni MDR, human review MDR, NEEDS_ADVICE CFC.
"""
from __future__ import annotations

import re
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"

P27_REGO = RULES / "v3_p27_cfc_exit_mdr_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"
LEGACY_EXIT_TAX = RULES / "crossborder" / "exit_tax_cfc_complete.rego"
LEGACY_CFC = RULES / "cfc_auto_classifier.rego"

INNOVATIONS = {
    "I01": "jdg.v3_p27_cfc_exit_mdr.architecture_decision_register",
    "I02": "jdg.v3_p27_cfc_exit_mdr.exit_tax_signal_monitor",
    "I03": "jdg.v3_p27_cfc_exit_mdr.exit_tax_threshold_verifier",
    "I04": "jdg.v3_p27_cfc_exit_mdr.mdr_hallmark_scorer_v2",
    "I05": "jdg.v3_p27_cfc_exit_mdr.mdr_30day_gate",
    "I06": "jdg.v3_p27_cfc_exit_mdr.mdr_auxiliary_function",
    "I07": "jdg.v3_p27_cfc_exit_mdr.cfc_signal_detector",
    "I08": "jdg.v3_p27_cfc_exit_mdr.international_invariants_pack",
    "I09": "jdg.v3_p27_cfc_exit_mdr.exit_tax_documentation",
    "I10": "jdg.v3_p27_cfc_exit_mdr.ruling_path_advisor",
    "I11": "jdg.v3_p27_cfc_exit_mdr.international_golden_set",
    "I12": "jdg.v3_p27_cfc_exit_mdr.international_stress_lab",
    "I13": "jdg.v3_p27_cfc_exit_mdr.cross_domain_flow_gate",
}

ANALYSES = [
    "architecture_decision_register", "exit_tax_signal_monitor",
    "exit_tax_threshold_verifier", "mdr_hallmark_scorer_v2", "mdr_30day_gate",
    "mdr_auxiliary_function", "cfc_signal_detector",
    "international_invariants_pack", "exit_tax_documentation",
    "ruling_path_advisor", "golden_international_set",
    "international_stress_lab", "cross_domain_flow_gate",
]

TOOLS_EXPECTED = {
    "v3_p27_architecture_register.py", "v3_p27_exit_tax_signal_monitor.py",
    "v3_p27_exit_tax_threshold_verifier.py", "v3_p27_mdr_hallmark_scorer.py",
    "v3_p27_mdr_30day_gate.py", "v3_p27_mdr_auxiliary_function.py",
    "v3_p27_cfc_signal_detector.py", "v3_p27_invariants.py",
    "v3_p27_exit_tax_documentation.py", "v3_p27_ruling_path_advisor.py",
    "v3_p27_golden_set.py", "v3_p27_stress_lab.py",
    "v3_p27_cross_domain_flow_gate.py",
}

THRESHOLD_KEYS_CROSSBORDER27 = [
    "v3_p27_threshold_version", "legal_basis_version", "valid_from",
    "v3_p27_exit_tax_property_threshold_pln",
    "v3_p27_exit_tax_reinvestment_lock_years",
    "v3_p27_exit_tax_installments_eea", "v3_p27_exit_tax_signal_deadline",
    "v3_p27_verifier_version", "v3_p27_verifier_drift_pln",
    "v3_p27_mdr_human_review_score", "v3_p27_mdr_warn_days",
    "v3_p27_mdr_weekend_shift", "v3_p27_mdr_zero_silence",
    "v3_p27_mdr_qualified_beneficiary_eur", "v3_p27_mdr_arrangement_value_eur",
    "v3_p27_mdr_auxiliary_excludes", "v3_p27_cfc_ownership_min_pct",
    "v3_p27_cfc_passive_signal_pct", "v3_p27_cfc_de_minimis_eur",
    "v3_p27_valuation_methods", "v3_p27_golden_version",
    "v3_p27_golden_tolerance", "v3_p27_stress_required_scenarios",
    "v3_p27_invariants_active", "v3_p27_mdr_human_only",
    "v3_p27_exit_tax_advisor_only", "v3_p27_cfc_needs_advice_only",
]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


# ── Pakiet V3-P27 ─────────────────────────────────────────────────────────────

def test_p27_rego_exists_and_structured():
    src = _read(P27_REGO)
    assert src, "brak rules/v3_p27_cfc_exit_mdr_enterprise.rego"
    assert "package jdg.v3_p27_cfc_exit_mdr" in src
    assert src.count("{") == src.count("}"), "nierównoważne nawiasy"
    rule_ids = re.findall(r'"rule_id": "([^"]+)"', src)
    assert len(rule_ids) == len(set(rule_ids)), "duplikaty rule_id w pakiecie P27"


def test_p27_all_13_innovations_present():
    src = _read(P27_REGO)
    for iid, rid in INNOVATIONS.items():
        assert rid in src, f"brak reguły {iid}: {rid}"


def test_p27_decide_chain_covers_all_analyses():
    src = _read(P27_REGO)
    chain = src.split("decide := fail_closed_decision")[1]
    for analysis in ANALYSES:
        assert analysis in chain or analysis in src, f"brak analizy {analysis}"
    assert chain.count("else :=") >= len(ANALYSES), "niekompletny else-chain decide"


def test_p27_fail_closed_no_silent_auto_post():
    src = _read(P27_REGO)
    assert "fail_closed_decision" in src
    assert "_snapshot_ok" in src
    assert '"_routing": "BLOCK_AND_ALERT"' in src
    assert "no_match" in src
    # AP01: zabroniony jest samodzielny stub (head reguły z body `true`),
    # NIE zaś fallback `else = <wartość> { true }` (dopełnienie łańcucha —
    # konwencja P26; deterministyczna totalność funkcji).
    for m in re.finditer(r"\{\s*true\s*\}", src):
        prefix = src[:m.start()].rstrip().splitlines()[-1]
        assert "else" in prefix, (
            f"AP01: samodzielny stub bez else w P27 (kontekst: {prefix!r})")


# ── Parametry jako dane (ADR-002/P06) + okno temporalne (P05) ─────────────────

def test_crossborder27_block_complete():
    src = _read(THRESHOLDS)
    assert "crossborder27 := {" in src
    i = src.find("crossborder27 := {")
    depth, end = 0, -1
    for j in range(i, len(src)):
        if src[j] == "{":
            depth += 1
        elif src[j] == "}":
            depth -= 1
            if depth == 0:
                end = j
                break
    block = src[i:end]
    for key in THRESHOLD_KEYS_CROSSBORDER27:
        assert f'"{key}"' in block, f"brak klucza {key} w crossborder27"
    assert '"valid_from"' in block, "brak okna temporalnego (P05)"


def test_exit_tax_core_thresholds_in_crossborder():
    src = _read(THRESHOLDS)
    assert '"exit_tax_threshold_pln": 4000000' in src
    assert '"mdr_deadline_days": 30' in src
    assert '"residency_days": 183' in src
    # naprawa AP02: klucz excise_wine_per_hl z powrotem jako dane (P19 fix)
    assert re.search(r'^\s*"excise_wine_per_hl":\s*185', src, re.M)


# ── Wiring main_jdg ────────────────────────────────────────────────────────────

def test_main_jdg_wired_p91():
    src = _read(MAIN_JDG)
    assert "import data.jdg.v3_p27_cfc_exit_mdr as v3_p27_cfc_exit_mdr" in src
    assert '"jdg.v3_p27_cfc_exit_mdr": v3_p27_cfc_exit_mdr.decide' in src
    assert "final_verdict_p91 = safe_merge(final_verdict_p90" in src
    assert "final_verdict_post_merge = safe_merge(" in src
    assert 'final_verdict_p91\n)' in src


# ── Naprawy legacy (AP01/AP02) ─────────────────────────────────────────────────

def test_legacy_exit_tax_stub_removed_and_chain_reordered():
    src = _read(LEGACY_EXIT_TAX)
    assert not re.search(r"\{\s*true\s*\}", src), "stub AP01 nadal obecny"
    rule_ids = re.findall(r'"rule_id": "([^"]+)"', src)
    assert len(rule_ids) == len(set(rule_ids)), "duplikaty rule_id w legacy"
    assert "jdg.exit_tax_cfc.exit_tax.r3" in rule_ids
    assert "jdg.exit_tax_cfc.cfc.r1" in rule_ids
    assert src.count("{") == src.count("}")
    # wyłączenie <4M przed transferem (r3 jako pierwsza reguła łańcucha)
    assert rule_ids[0] == "jdg.exit_tax_cfc.exit_tax.r3"
    # próg z danych (ADR-002), nie hardcode
    assert 'data.jdg.thresholds, "crossborder"' in src


def test_legacy_cfc_classifier_parameters_from_data():
    src = _read(LEGACY_CFC)
    assert "v3_p27_cfc_passive_signal_pct" in src
    assert "v3_p27_cfc_de_minimis_eur" in src
    assert 'threshold := 33.0' not in src
    assert 'scale := 4.5' not in src
    assert "needs_tax_advisor" in src, "brak etykiety NEEDS_ADVICE (I07)"
    assert src.count("{") == src.count("}")
    assert not re.search(r"\{\s*true\s*\}", src)


# ── Narzędzia dowodowe i bundle ───────────────────────────────────────────────

def test_p27_tools_present():
    for name in TOOLS_EXPECTED:
        assert (TOOLS / name).exists(), f"brak tools/{name}"


def test_p27_bundles_all_pass():
    for name in TOOLS_EXPECTED:
        bundle = BUNDLES / (name.replace(".py", ".json"))
        assert bundle.exists(), f"brak bundles/{bundle.name}"
        data = _read(bundle)
        assert '"gate": "PASS"' in data, f"gate FAIL: {bundle.name}"


# ── Granice progowe (merge-blocking) ──────────────────────────────────────────

def test_exit_tax_property_threshold_is_2m():
    src = _read(THRESHOLDS)
    assert '"v3_p27_exit_tax_property_threshold_pln": 2000000' in src


def test_mdr_human_review_constants():
    src = _read(P27_REGO)
    assert "mdr_auto_report_attempt" in src
    assert "exit_tax_auto_declaration_attempt" in src
    assert "cfc_auto_tax_calculation_attempt" in src
    assert "INV-X01_MDR_HUMAN_ONLY" in src
    assert "INV-X02_EXIT_TAX_ADVISOR_ONLY" in src
    assert "INV-X03_CFC_NEEDS_ADVICE_ONLY" in src
    assert "INV-X04_NO_SILENT_AUTO_POST" in src


def test_architecture_register_decisions():
    src = _read(P27_REGO)
    assert "IN_SCOPE_JDG_AS_SIGNAL" in src          # CFC
    assert "IN_SCOPE_JDG_AS_MONITORING" in src      # exit tax
    assert "OUT_OF_SCOPE_JDG" in src                # PAiN
    assert "IN_SCOPE_JDG_AS_ADVISORY_PATH" in src   # rulingi
    assert "IN_SCOPE_JDG_AS_CHECKLIST_HUMAN_REVIEW" in src  # MDR


def test_p27_regiester_in_rego_matches_expected_rule_count():
    src = _read(P27_REGO)
    rule_ids = re.findall(r'"rule_id": "jdg\.v3_p27_cfc_exit_mdr\.[a-z_]+"', src)
    assert len(rule_ids) >= 13, "za mało reguł publicznych w pakiecie"
