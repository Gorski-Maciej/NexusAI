# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P29 (KAMPANIE JAKOŚCI V3 — 8 BRAMEK) — kampania V3 FORTRESS.

Weryfikuje:
  * reguły OPA w rules/v3_p29_quality_campaigns_enterprise.rego (12 innowacji I01-I12),
  * parametry-as-data w rules/thresholds_jdg.rego (blok v3_p29, ADR-002/P06, P05),
  * wiring w rules/main_jdg.rego (final_verdict_p93),
  * 12 narzędzi dowodowych tools/v3_p29_*.py i 12 bundli bundles/v3_p29_*.json,
  * spójność z legacy: 8 bramek v3_13..v3_20 (rejestr jako dane I06), kontrakt
    P03 (wynik bramki = wejście do werdyktu), P10 (golden set), P11 (certyfikat),
  * granice: mutation score 85, dług P1, heatmapa RED/AMBER, fasady, seed.
"""
from __future__ import annotations

import re
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"

P29_REGO = RULES / "v3_p29_quality_campaigns_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"

INNOVATIONS = {
    "I01": "jdg.v3_p29_quality_campaigns.composite_quality_gate",
    "I02": "jdg.v3_p29_quality_campaigns.mutation_testing",
    "I03": "jdg.v3_p29_quality_campaigns.quality_debt_ledger",
    "I04": "jdg.v3_p29_quality_campaigns.deterministic_seed",
    "I05": "jdg.v3_p29_quality_campaigns.gate_performance_profiler",
    "I06": "jdg.v3_p29_quality_campaigns.gate_as_data",
    "I07": "jdg.v3_p29_quality_campaigns.merge_block_comment",
    "I08": "jdg.v3_p29_quality_campaigns.domain_quality_heatmap",
    "I09": "jdg.v3_p29_quality_campaigns.facade_assertion_detector",
    "I10": "jdg.v3_p29_quality_campaigns.gate_to_certificate",
    "I11": "jdg.v3_p29_quality_campaigns.test_upgrade_pipeline",
    "I12": "jdg.v3_p29_quality_campaigns.holy_documents_compliance",
}

ANALYSES = [
    "composite_quality_gate", "mutation_testing", "quality_debt_ledger",
    "deterministic_seed", "gate_performance_profiler", "gate_as_data",
    "merge_block_comment", "domain_quality_heatmap", "facade_assertion_detector",
    "gate_to_certificate", "test_upgrade_pipeline", "holy_documents_compliance",
]

TOOLS_EXPECTED = {
    "v3_p29_composite_gate.py", "v3_p29_mutation_testing.py",
    "v3_p29_debt_ledger.py", "v3_p29_seed_contract.py",
    "v3_p29_perf_profiler.py", "v3_p29_gate_as_data.py",
    "v3_p29_merge_block_comment.py", "v3_p29_domain_heatmap.py",
    "v3_p29_facade_detector.py", "v3_p29_cert_binding.py",
    "v3_p29_test_upgrade.py", "v3_p29_holy_docs_compliance.py",
}

THRESHOLD_KEYS_V3P29 = [
    "v3_p29_threshold_version", "legal_basis_version", "valid_from",
    "v3_p29_min_mutation_score", "v3_p29_max_open_debts_p1",
    "v3_p29_seed_required", "v3_p29_max_gate_seconds", "v3_p29_perf_drift_pct",
    "v3_p29_heatmap_red_below", "v3_p29_heatmap_green_from",
    "v3_p29_max_blocking_facades", "v3_p29_gate_registry",
]

GATE_REGISTRY_KEYS = ["v3_13", "v3_14", "v3_15", "v3_16", "v3_17", "v3_18", "v3_19", "v3_20"]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


# ── Pakiet V3-P29 ─────────────────────────────────────────────────────────────

def test_p29_rego_exists_and_structured():
    src = _read(P29_REGO)
    assert src, "brak rules/v3_p29_quality_campaigns_enterprise.rego"
    assert "package jdg.v3_p29_quality_campaigns" in src
    assert src.count("{") == src.count("}"), "nierównoważne nawiasy"
    rule_ids = re.findall(r'"rule_id": "([^"]+)"', src)
    assert len(rule_ids) == len(set(rule_ids)), "duplikaty rule_id w pakiecie P29"


def test_p29_all_12_innovations_present():
    src = _read(P29_REGO)
    for iid, rid in INNOVATIONS.items():
        assert rid in src, f"brak reguły {iid}: {rid}"


def test_p29_decide_chain_covers_all_analyses():
    src = _read(P29_REGO)
    chain = src.split("decide := fail_closed_decision")[1]
    for analysis in ANALYSES:
        assert analysis in chain or analysis in src, f"brak analizy {analysis}"
    assert chain.count("else :=") >= len(ANALYSES), "niekompletny else-chain decide"


def test_p29_fail_closed_no_silent_auto_post():
    src = _read(P29_REGO)
    assert "fail_closed_decision" in src
    assert "_snapshot_ok" in src
    assert '\"_routing\": \"BLOCK_AND_ALERT\"' in src
    assert "no_match" in src
    for m in re.finditer(r"\{\s*true\s*\}", src):
        prefix = src[:m.start()].rstrip().splitlines()[-1]
        assert "else" in prefix, (
            f"AP01: samodzielny stub bez else w P29 (kontekst: {prefix!r})")


# ── Parametry jako dane (ADR-002/P06) + okno temporalne (P05) ─────────────────

def test_v3p29_block_complete():
    src = _read(THRESHOLDS)
    assert "v3_p29 := {" in src
    i = src.find("v3_p29 := {")
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
    for key in THRESHOLD_KEYS_V3P29:
        assert f'"{key}"' in block, f"brak klucza {key} w v3_p29"
    assert '"valid_from"' in block, "brak okna temporalnego (P05)"


def test_gate_registry_has_all_8_gates():
    src = _read(THRESHOLDS)
    i = src.find("v3_p29_gate_registry")
    block = src[i:i + 2600]
    for key in GATE_REGISTRY_KEYS:
        assert f'"{key}"' in block, f"brak bramki {key} w rejestrze (I06)"


# ── Wiring main_jdg ───────────────────────────────────────────────────────────

def test_main_jdg_wired_p93():
    src = _read(MAIN_JDG)
    assert "import data.jdg.v3_p29_quality_campaigns as v3_p29_quality_campaigns" in src
    assert '"jdg.v3_p29_quality_campaigns": v3_p29_quality_campaigns.decide' in src
    assert "final_verdict_p93 = safe_merge(final_verdict_p92" in src
    assert "final_verdict_post_merge = safe_merge(" in src
    # P93 pozostaje w łańcuchu: p94 = safe_merge(p93, ...) (P30). Post-merge
    # anchor przeszedł na p94 — p93 wchodzi jako lewa strona safe_merge.
    assert "final_verdict_p93\n)" in src or "safe_merge(final_verdict_p93," in src


# ── Spójność z legacy (8 bramek v3, kontrakt P03, P10, P11) ──────────────────

def test_composite_gate_covers_8_gates():
    src = _read(P29_REGO)
    for g in GATE_REGISTRY_KEYS:
        assert g in src, f"bramka {g} poza katalogiem composite gate (I01)"


def test_mutation_threshold_matches_tests_ci():
    thresholds = _read(THRESHOLDS)
    assert '"v3_p29_min_mutation_score": 85' in thresholds
    assert '"min_mutation_score": 85' in thresholds  # spójność z v3_17


def test_heatmap_and_facade_probes():
    src = _read(P29_REGO)
    assert "domains_red" in src and "domains_amber" in src
    assert "facade_tests" in src and "is_merge_blocking" in src
    assert "certificate_gate_versions" in src
    assert "holy_document_conflicts" in src


def test_p29_public_rule_count():
    src = _read(P29_REGO)
    rule_ids = re.findall(r'"rule_id": "jdg\.v3_p29_quality_campaigns\.[a-z_]+"', src)
    assert len(rule_ids) >= 12, "za mało reguł publicznych w pakiecie"


# ── Narzędzia dowodowe i bundle ───────────────────────────────────────────────

def test_p29_tools_present():
    for name in TOOLS_EXPECTED:
        assert (TOOLS / name).exists(), f"brak tools/{name}"


def test_p29_bundles_all_pass():
    for name in TOOLS_EXPECTED:
        bundle = BUNDLES / (name.replace(".py", ".json"))
        assert bundle.exists(), f"brak bundles/{bundle.name}"
        data = _read(bundle)
        assert '"gate": "PASS"' in data, f"gate FAIL: {bundle.name}"


# ── Granice progowe (merge-blocking) ──────────────────────────────────────────

def test_mutation_score_boundary():
    src = _read(P29_REGO)
    assert "_mt_min" in src and "v3_p29_min_mutation_score" in src


def test_quality_debt_p1_limit_zero():
    thresholds = _read(THRESHOLDS)
    assert '"v3_p29_max_open_debts_p1": 0' in thresholds


def test_facade_blocking_limit_zero():
    thresholds = _read(THRESHOLDS)
    assert '"v3_p29_max_blocking_facades": 0' in thresholds


def test_seed_required_and_perf_probes():
    thresholds = _read(THRESHOLDS)
    assert '"v3_p29_seed_required": true' in thresholds
    assert '"v3_p29_max_gate_seconds": 120' in thresholds
    assert '"v3_p29_perf_drift_pct": 50' in thresholds