# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P31 (ETAPY AUDYTÓW 12-28 — ujednolicony schemat audytu)
— kampania V3 FORTRESS.

Weryfikuje:
  * reguły OPA w rules/v3_p31_audit_stages_enterprise.rego (12 analiz I01-I12),
  * parametry-as-data w rules/thresholds_jdg.rego (blok v3_p31, ADR-002/P06, P05),
  * wiring w rules/main_jdg.rego (final_verdict_p95),
  * 12 narzędzi dowodowych tools/v3_p31_*.py i 12 bundli bundles/v3_p31_*.json,
  * spójność z legacy: 17 etapów 12-28, kontrakt P30 (p30_feed), kanon P00,
  * granice: red team min 10, risk-of-fortress 30, dowód wygasły 90 dni.
"""
from __future__ import annotations

import re
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"

P31_REGO = RULES / "v3_p31_audit_stages_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"

INNOVATIONS = {
    "I01": "jdg.v3_p31_audit_stages.unified_audit_schema",
    "I02": "jdg.v3_p31_audit_stages.cross_etap_conflict_detector",
    "I03": "jdg.v3_p31_audit_stages.red_team_pack",
    "I04": "jdg.v3_p31_audit_stages.risk_of_fortress_score",
    "I05": "jdg.v3_p31_audit_stages.stages_as_data",
    "I06": "jdg.v3_p31_audit_stages.auto_rerun_after_amendment",
    "I07": "jdg.v3_p31_audit_stages.worm_audit_trail",
    "I08": "jdg.v3_p31_audit_stages.frontier_matrix",
    "I09": "jdg.v3_p31_audit_stages.conflict_resolution",
    "I10": "jdg.v3_p31_audit_stages.certification_pack_generator",
    "I11": "jdg.v3_p31_audit_stages.stage_closure_campaign",
    "I12": "jdg.v3_p31_audit_stages.p30_feed",
}

ANALYSES = [
    "unified_audit_schema", "cross_etap_conflict_detector", "red_team_pack",
    "risk_of_fortress_score", "stages_as_data", "auto_rerun_after_amendment",
    "worm_audit_trail", "frontier_matrix", "conflict_resolution",
    "certification_pack_generator", "stage_closure_campaign", "p30_feed",
]

TOOLS_EXPECTED = {
    "v3_p31_unified_schema.py", "v3_p31_conflict_detector.py",
    "v3_p31_red_team_pack.py", "v3_p31_risk_score.py",
    "v3_p31_stages_as_data.py", "v3_p31_auto_rerun.py",
    "v3_p31_worm_trail.py", "v3_p31_frontier_matrix.py",
    "v3_p31_conflict_resolution.py", "v3_p31_certpack.py",
    "v3_p31_closure_campaign.py", "v3_p31_p30_feed.py",
}

THRESHOLD_KEYS_V3P31 = [
    "v3_p31_threshold_version", "legal_basis_version", "valid_from",
    "v3_p31_min_red_team_attacks", "v3_p31_max_risk_of_fortress",
    "v3_p31_evidence_stale_days", "v3_p31_max_stages_without_evidence",
    "v3_p31_stage_registry",
]

# 17 etapów audytu 12-28 (rejestr jako dane)
STAGES_12_28 = [f"etap{n}" for n in range(12, 29)]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


# ── Pakiet V3-P31 ─────────────────────────────────────────────────────────────

def test_p31_rego_exists_and_structured():
    src = _read(P31_REGO)
    assert src, "brak rules/v3_p31_audit_stages_enterprise.rego"
    assert "package jdg.v3_p31_audit_stages" in src
    assert src.count("{") == src.count("}"), "nierównoważne nawiasy"
    rule_ids = re.findall(r'"rule_id": "([^"]+)"', src)
    assert len(rule_ids) == len(set(rule_ids)), "duplikaty rule_id w pakiecie P31"


def test_p31_all_12_innovations_present():
    src = _read(P31_REGO)
    for iid, rid in INNOVATIONS.items():
        assert rid in src, f"brak reguły {iid}: {rid}"


def test_p31_decide_chain_covers_all_analyses():
    src = _read(P31_REGO)
    for analysis in ANALYSES:
        assert analysis in src, f"brak analizy {analysis}"
    # decide jako łańcuch else (fail-closed na końcu)
    assert "decide" in src and "no_match" in src


def test_p31_fail_closed_no_silent_auto_post():
    src = _read(P31_REGO)
    assert "fail_closed" in src or "fail_closed_decision" in src
    assert "_snapshot_ok" in src
    assert '"_routing": "BLOCK_AND_ALERT"' in src
    assert "no_match" in src
    for m in re.finditer(r"\{\s*true\s*\}", src):
        prefix = src[:m.start()].rstrip().splitlines()[-1]
        assert "else" in prefix, (
            f"AP01: samodzielny stub bez else w P31 (kontekst: {prefix!r})")


# ── Parametry jako dane (ADR-002/P06) + okno temporalne (P05) ─────────────────

def _thresholds_block() -> str:
    src = _read(THRESHOLDS)
    i = src.find("v3_p31 := {")
    assert i >= 0, "brak bloku v3_p31 w thresholds_jdg.rego"
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


def test_v3p31_block_complete():
    block = _thresholds_block()
    for key in THRESHOLD_KEYS_V3P31:
        assert f'"{key}"' in block, f"brak klucza {key} w v3_p31"
    assert '"valid_from"' in block, "brak okna temporalnego (P05)"


def test_v3p31_stage_registry_covers_17_stages():
    block = _thresholds_block()
    for stage in STAGES_12_28:
        assert f'"{stage}"' in block, f"brak etapu {stage} w v3_p31_stage_registry"


# ── Wiring main_jdg ───────────────────────────────────────────────────────────

def test_main_jdg_wired_p95():
    src = _read(MAIN_JDG)
    assert "import data.jdg.v3_p31_audit_stages as v3_p31_audit_stages" in src
    assert '"jdg.v3_p31_audit_stages": v3_p31_audit_stages.decide' in src
    assert "final_verdict_p95 = safe_merge(final_verdict_p94" in src
    assert "final_verdict_post_merge = safe_merge(" in src
    assert "final_verdict_p95\n)" in src or "safe_merge(final_verdict_p95," in src


# ── Spójność z legacy (17 etapów, kontrakt P30, kanon P00) ────────────────────

def test_p31_public_rule_count():
    src = _read(P31_REGO)
    rule_ids = re.findall(r'"rule_id": "jdg\.v3_p31_audit_stages\.[a-z_]+"', src)
    assert len(rule_ids) >= 12, "za mało reguł publicznych w pakiecie"


def test_legacy_contracts_honored():
    src = _read(P31_REGO)
    assert "p30_feed" in src      # kontrakt P30 (pętla wdrożeniowa)
    assert "unified_audit_schema" in src  # kanon P00 (dowód = kod/test/artefakt)
    assert "worm" in src.lower()  # WORM — no-rewrite audit trail


def test_p31_threshold_version_consistency():
    rego = _read(P31_REGO)
    thresholds = _thresholds_block()
    m1 = re.search(r'"v3_p31_threshold_version":\s*"([^"]+)"', thresholds)
    assert m1, "brak v3_p31_threshold_version"
    # pakiet P31 czyta threshold_version z snapshotu progów (params-as-data, ADR-002)
    assert "data.jdg.thresholds.v3_p31" in rego, (
        "pakiet P31 nie podpięty pod snapshot progów")
    assert 'v3_p31_threshold_version' in rego, (
        "brak odczytu threshold_version w pakiecie P31")


# ── Narzędzia dowodowe i bundle ───────────────────────────────────────────────

def test_p31_tools_present():
    for name in sorted(TOOLS_EXPECTED):
        assert (TOOLS / name).exists(), f"brak tools/{name}"


def test_p31_bundles_all_pass():
    for name in sorted(TOOLS_EXPECTED):
        bundle = BUNDLES / (name.replace(".py", ".json"))
        assert bundle.exists(), f"brak bundles/{bundle.name}"
        data = _read(bundle)
        assert '"gate": "PASS"' in data, f"gate FAIL: {bundle.name}"


# ── Granice progowe (merge-blocking) ──────────────────────────────────────────

def test_red_team_minimum_attacks():
    thresholds = _read(THRESHOLDS)
    assert '"v3_p31_min_red_team_attacks": 10' in thresholds


def test_risk_of_fortress_cap():
    thresholds = _read(THRESHOLDS)
    assert '"v3_p31_max_risk_of_fortress": 30' in thresholds


def test_evidence_staleness_window():
    thresholds = _read(THRESHOLDS)
    assert '"v3_p31_evidence_stale_days": 90' in thresholds


def test_no_evidence_stages_limit():
    thresholds = _read(THRESHOLDS)
    assert '"v3_p31_max_stages_without_evidence": 0' in thresholds
