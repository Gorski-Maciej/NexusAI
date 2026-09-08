# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P28 (HYPERKONTEKSTY PLAN44/45 I KRYTYCZNE ŚCIEŻKI)
— kampania V3 FORTRESS.

Weryfikuje:
  * reguły OPA w rules/v3_p28_hyper_plan45_enterprise.rego (12 innowacji I01-I12),
  * parametry-as-data w rules/thresholds_jdg.rego (blok hyper45, ADR-002),
  * 12 narzędzi dowodowych tools/v3_p28_*.py i 12 bundle bundles/v3_p28_*.json,
  * wiring w rules/main_jdg.rego (final_verdict_p92),
  * spójność z legacy: mapa hiperkontekst→domena (I01), duplikaty fx/limits
    (I02 — AP04), pustynie testowe domen marginalnych (I11),
  * granice: siła wyższa max dni, sanctions human review, próg podpisu
    kwalifikowanego, crisis drill zero-ciszy.
"""
from __future__ import annotations

import re
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"

P28_REGO = RULES / "v3_p28_hyper_plan45_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"

INNOVATIONS = {
    "I01": "jdg.v3_p28_hyper_plan45.hyper_context_map",
    "I02": "jdg.v3_p28_hyper_plan45.duplicate_detector",
    "I03": "jdg.v3_p28_hyper_plan45.force_majeure_framework",
    "I04": "jdg.v3_p28_hyper_plan45.sanctions_gate",
    "I05": "jdg.v3_p28_hyper_plan45.marginal_domain_register",
    "I06": "jdg.v3_p28_hyper_plan45.esig_contract_layer",
    "I07": "jdg.v3_p28_hyper_plan45.crisis_drill",
    "I08": "jdg.v3_p28_hyper_plan45.network_consistency_gate",
    "I09": "jdg.v3_p28_hyper_plan45.hyper_invariants_pack",
    "I10": "jdg.v3_p28_hyper_plan45.hyper_golden_set",
    "I11": "jdg.v3_p28_hyper_plan45.marginal_cleanup_plan",
    "I12": "jdg.v3_p28_hyper_plan45.hyper_explanation_engine",
}

ANALYSES = [
    "hyper_context_map", "duplicate_detector", "force_majeure_framework",
    "sanctions_gate", "marginal_domain_register", "esig_contract_layer",
    "crisis_drill", "network_consistency_gate", "hyper_invariants_pack",
    "golden_hyper_set", "marginal_cleanup_plan", "hyper_explanation_engine",
]

TOOLS_EXPECTED = {
    "v3_p28_hyper_context_map.py", "v3_p28_duplicate_detector.py",
    "v3_p28_force_majeure.py", "v3_p28_sanctions_gate.py",
    "v3_p28_marginal_register.py", "v3_p28_esig_contract.py",
    "v3_p28_crisis_drill.py", "v3_p28_network_gate.py",
    "v3_p28_invariants.py", "v3_p28_golden_set.py",
    "v3_p28_cleanup_plan.py", "v3_p28_explanation_engine.py",
}

THRESHOLD_KEYS_HYPER45 = [
    "v3_p28_threshold_version", "legal_basis_version", "valid_from",
    "v3_p28_force_majeure_max_days", "v3_p28_force_majeure_calendar_p25_linked",
    "v3_p28_force_majeure_degradation", "v3_p28_sanctions_list_version",
    "v3_p28_sanctions_human_review_required", "v3_p28_sanctions_aml_p22_linked",
    "v3_p28_marginal_register_version", "v3_p28_esig_qualified_threshold_pln",
    "v3_p28_esig_contract_p11_p16", "v3_p28_crisis_required_scenarios",
    "v3_p28_crisis_zero_silence", "v3_p28_network_expected_contexts",
    "v3_p28_network_gap_blocker", "v3_p28_invariants_active",
    "v3_p28_sanctions_human_only", "v3_p28_fm_calendar_only",
    "v3_p28_fx_single_engine", "v3_p28_hyper_no_silent_auto_post",
    "v3_p28_golden_version", "v3_p28_golden_tolerance",
    "v3_p28_cleanup_max_untested", "v3_p28_context_map_version",
]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


# ── Pakiet V3-P28 ─────────────────────────────────────────────────────────────

def test_p28_rego_exists_and_structured():
    src = _read(P28_REGO)
    assert src, "brak rules/v3_p28_hyper_plan45_enterprise.rego"
    assert "package jdg.v3_p28_hyper_plan45" in src
    assert src.count("{") == src.count("}"), "nierównoważne nawiasy"
    rule_ids = re.findall(r'"rule_id": "([^"]+)"', src)
    assert len(rule_ids) == len(set(rule_ids)), "duplikaty rule_id w pakiecie P28"


def test_p28_all_12_innovations_present():
    src = _read(P28_REGO)
    for iid, rid in INNOVATIONS.items():
        assert rid in src, f"brak reguły {iid}: {rid}"


def test_p28_decide_chain_covers_all_analyses():
    src = _read(P28_REGO)
    chain = src.split("decide := fail_closed_decision")[1]
    for analysis in ANALYSES:
        assert analysis in chain or analysis in src, f"brak analizy {analysis}"
    assert chain.count("else :=") >= len(ANALYSES), "niekompletny else-chain decide"


def test_p28_fail_closed_no_silent_auto_post():
    src = _read(P28_REGO)
    assert "fail_closed_decision" in src
    assert "_snapshot_ok" in src
    assert '"_routing": "BLOCK_AND_ALERT"' in src
    assert "no_match" in src
    # AP01: zabroniony jest samodzielny stub (head reguły z body `true`),
    # NIE zaś fallback `else = <wartość> { true }` (dopełnienie łańcucha —
    # konwencja P26/P27; deterministyczna totalność funkcji).
    for m in re.finditer(r"\{\s*true\s*\}", src):
        prefix = src[:m.start()].rstrip().splitlines()[-1]
        assert "else" in prefix, (
            f"AP01: samodzielny stub bez else w P28 (kontekst: {prefix!r})")


# ── Parametry jako dane (ADR-002/P06) + okno temporalne (P05) ─────────────────

def test_hyper45_block_complete():
    src = _read(THRESHOLDS)
    assert "hyper45 := {" in src
    i = src.find("hyper45 := {")
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
    for key in THRESHOLD_KEYS_HYPER45:
        assert f'"{key}"' in block, f"brak klucza {key} w hyper45"
    assert '"valid_from"' in block, "brak okna temporalnego (P05)"


def test_hyper_core_thresholds_in_hyper():
    src = _read(THRESHOLDS)
    assert '"qualified_signature_value_threshold": 10000' in src
    assert '"mdr_deadline_days": 30' in src
    assert '"deadline_alert_7"' in src and '"deadline_alert_3"' in src \
        and '"deadline_alert_1"' in src


# ── Wiring main_jdg ────────────────────────────────────────────────────────────

def test_main_jdg_wired_p92():
    src = _read(MAIN_JDG)
    assert "import data.jdg.v3_p28_hyper_plan45 as v3_p28_hyper_plan45" in src
    assert '"jdg.v3_p28_hyper_plan45": v3_p28_hyper_plan45.decide' in src
    assert "final_verdict_p92 = safe_merge(final_verdict_p91" in src
    assert "final_verdict_post_merge = safe_merge(" in src
    # P92 pozostaje w łańcuchu: p93 = safe_merge(p92, ...) i p92 wchodzi do
    # safe_merge(final_verdict_p91, ...). Post-merge anchor przeszedł na p93 (P29).
    assert "final_verdict_p92\n)" in src or "safe_merge(final_verdict_p92," in src


# ── Spójność z legacy (mapa I01, duplikaty I02, pustynie I11) ──────────────────

def test_hyper_context_map_contracts():
    src = _read(P28_REGO)
    # kontrakty z domenami: P15 (fx), P22 (AML/sanctions), P25 (kalendarz/FM)
    assert "fx_single_engine" in src
    assert "sanctions_human_review" in src
    assert "deadline_suspension" in src
    assert "P15_FX" in src and "P22_AML" in src and "P25_CALENDAR" in src


def test_duplicate_consolidation_decisions():
    src = _read(P28_REGO)
    # decyzja konsolidacji: fx = P15 jedyne źródło kursów; limits = P06
    assert "jdg.v3_p28_hyper_plan45.duplicate_detector" in src
    assert "fx" in src and "limits" in src
    assert "_dup_expected" in src


def test_marginal_domains_have_native_tests():
    # I11: pustynie testowe — domeny marginalne mają testy natywne w repo
    for name in ["esig", "force_majeure", "fx", "taxfree", "seasonal",
                 "advertising"]:
        assert (RULES / "tests" / f"test_native_jdg_{name}.rego").exists() or \
            (BASE / "tests" / "rego" / f"test_native_jdg_{name}.rego").exists(), \
            f"brak testu natywnego dla domeny {name}"


# ── Narzędzia dowodowe i bundle ───────────────────────────────────────────────

def test_p28_tools_present():
    for name in TOOLS_EXPECTED:
        assert (TOOLS / name).exists(), f"brak tools/{name}"


def test_p28_bundles_all_pass():
    for name in TOOLS_EXPECTED:
        bundle = BUNDLES / (name.replace(".py", ".json"))
        assert bundle.exists(), f"brak bundles/{bundle.name}"
        data = _read(bundle)
        assert '"gate": "PASS"' in data, f"gate FAIL: {bundle.name}"


# ── Granice progowe (merge-blocking) ──────────────────────────────────────────

def test_force_majeure_max_days_90():
    src = _read(THRESHOLDS)
    assert '"v3_p28_force_majeure_max_days": 90' in src


def test_sanctions_human_review_constants():
    src = _read(P28_REGO)
    assert "sanctions_auto_transaction_attempt" in src
    assert "force_majeure_auto_extension_attempt" in src
    assert "fx_duplicate_engine_attempt" in src
    assert "hyper_auto_post_attempt" in src
    assert "INV-H01_SANCTIONS_HUMAN_ONLY" in src
    assert "INV-H02_FM_CALENDAR_ONLY" in src
    assert "INV-H03_FX_SINGLE_ENGINE" in src
    assert "INV-H04_NO_SILENT_AUTO_POST" in src


def test_marginal_register_decisions():
    src = _read(P28_REGO)
    assert "IN_SCOPE_JDG_AS_INFO" in src          # taxfree
    assert "IN_SCOPE_JDG_AS_DATA" in src          # seasonal
    assert "IN_SCOPE_JDG_AS_COST" in src          # insurance/advertising
    assert "OUT_OF_SCOPE_JDG" in src              # regulated/procurement
    assert "IN_SCOPE_JDG_AS_CONTRACT" in src      # esig


def test_esig_qualified_threshold_is_10k():
    src = _read(THRESHOLDS)
    assert '"v3_p28_esig_qualified_threshold_pln": 10000' in src


def test_p28_public_rule_count():
    src = _read(P28_REGO)
    rule_ids = re.findall(r'"rule_id": "jdg\.v3_p28_hyper_plan45\.[a-z_]+"', src)
    assert len(rule_ids) >= 12, "za mało reguł publicznych w pakiecie"
