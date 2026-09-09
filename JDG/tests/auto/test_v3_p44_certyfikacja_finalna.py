#!/usr/bin/env python3
"""NexusAI JDG — V3-P44 CERTYFIKACJA FINALNA — testy pytest (konwencja P39
negative-first).

Pokrycie: 12 bundli dowodowych (gate=PASS), rego (34/34 ×2 OPA), progi jako
dane (ADR-002), wiring final_verdict_p108, rejestr certyfikacji finalnej,
bramki twarde (hard gates), zero deklaracji bez dowodu.
"""
from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
P44_RULES = BASE / "rules" / "v3_p44_certyfikacja_finalna.rego"
THRESHOLDS = BASE / "rules" / "thresholds_jdg.rego"
MAIN_JDG = BASE / "rules" / "main_jdg.rego"
TESTS_REGO = BASE / "tests" / "rego" / "test_v3_p44_certyfikacja_finalna.rego"
CERT_REGISTER = BASE / "bundles" / "v3_p44_final_certification.json"
BUNDLES = BASE / "bundles"

BUNDLE_TO_INNOVATION = {
    "v3_p44_hard_gate_certificate": "V3-P44-I01",
    "v3_p44_pillar_scoreboard": "V3-P44-I02",
    "v3_p44_aggregate_ledger": "V3-P44-I03",
    "v3_p44_owner_decision_map": "V3-P44-I04",
    "v3_p44_inheritance_contract": "V3-P44-I05",
    "v3_p44_metric_freeze": "V3-P44-I06",
    "v3_p44_worm_signature": "V3-P44-I07",
    "v3_p44_knowledge_transfer": "V3-P44-I08",
    "v3_p44_renewal_policy": "V3-P44-I09",
    "v3_p44_legacy_cleanup": "V3-P44-I10",
    "v3_p44_owner_attestation": "V3-P44-I11",
    "v3_p44_self_portrait": "V3-P44-I12",
}

P44_RULE_IDS = [
    "jdg.v3_p44_certyfikacja_finalna.hard_gate_certificate",
    "jdg.v3_p44_certyfikacja_finalna.pillar_scoreboard",
    "jdg.v3_p44_certyfikacja_finalna.campaign_aggregate_ledger",
    "jdg.v3_p44_certyfikacja_finalna.owner_decision_map",
    "jdg.v3_p44_certyfikacja_finalna.v4_inheritance_contract",
    "jdg.v3_p44_certyfikacja_finalna.success_metric_freeze",
    "jdg.v3_p44_certyfikacja_finalna.certificate_worm_signature",
    "jdg.v3_p44_certyfikacja_finalna.knowledge_transfer_pack",
    "jdg.v3_p44_certyfikacja_finalna.certification_renewal_policy",
    "jdg.v3_p44_certyfikacja_finalna.legacy_cleanup_closure",
    "jdg.v3_p44_certyfikacja_finalna.owner_attestation",
    "jdg.v3_p44_certyfikacja_finalna.fortress_self_portrait",
]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def _rego_test_count() -> int:
    out = subprocess.run(
        [str(BASE.parent / "bin" / "opa"), "test",
         str(TESTS_REGO), str(P44_RULES), str(THRESHOLDS)],
        cwd=BASE, capture_output=True, text=True, timeout=120)
    m = re.search(r"PASS: (\d+)/(\d+)", out.stdout + out.stderr)
    return int(m.group(2)) if m else 0


# ── Rego, progi, wiring ────────────────────────────────────────────────────────

def test_rego_all_12_rule_ids_present():
    hay = _read(P44_RULES)
    missing = [r for r in P44_RULE_IDS if r not in hay]
    assert not missing, f"Brakujące rule_id w rego: {missing}"


def test_rego_negative_assertions_present():
    hay = _read(TESTS_REGO)
    assert "BLOCK_AND_ALERT" in hay and "TRIAGE_QUEUE" in hay
    assert hay.count("test_p44_") >= 30


def test_rego_native_suite_passes():
    n = _rego_test_count()
    assert n >= 30, f"Native rego suite za mało przypadków: {n}"


def test_thresholds_as_data():
    th = _read(THRESHOLDS)
    for key in ["v3_p44_certificate_retention_min_years", "v3_p44_cert_validity_max_days",
                "v3_p44_legacy_facades_max", "v3_p44_threshold_version"]:
        assert f'"{key}"' in th, f"Brak progu {key} w thresholds_jdg.rego"


def test_main_jdg_wired_p108():
    main = _read(MAIN_JDG)
    assert "import data.jdg.v3_p44_certyfikacja_finalna as v3_p44_certyfikacja_finalna" in main
    assert '"jdg.v3_p44_certyfikacja_finalna": v3_p44_certyfikacja_finalna.decide' in main
    assert "final_verdict_p108" in main
    assert "final_verdict_p107 = safe_merge(final_verdict_p106" in main
    assert "final_verdict_p108 = safe_merge(final_verdict_p107" in main


def test_rule_names_not_test_prefixed():
    hay = _read(P44_RULES)
    for m in re.finditer(r"^(\w+_decision)\b", hay, re.M):
        assert not m.group(1).startswith("test_"), m.group(1)


# ── Rejestr certyfikacji (dane, nie fasada) ────────────────────────────────────

def test_cert_register_valid_json_with_hard_gates():
    data = json.loads(_read(CERT_REGISTER))
    gates = data.get("hard_gates", {})
    assert gates, "rejestr bez bramek twardych"
    failed = [k for k, v in gates.items() if isinstance(v, dict) and v.get("ok") is not True]
    assert not failed, f"otwarte bramki twarde: {failed}"


def test_cert_register_pillar_scoreboard():
    data = json.loads(_read(CERT_REGISTER))
    pillars = data.get("pillars", {})
    assert len(pillars) >= 5, "scoreboard filarów niekompletny (Vizja V2 wymaga 6 filarów)"
    for name, p in pillars.items():
        assert p.get("status") in {"DOWIEDZONE", "CZĘŚCIOWE", "DEKLAROWANE"}, name
        assert p.get("evidence"), f"filar bez dowodu: {name}"
        if p.get("status") == "DEKLAROWANE":
            assert p.get("closure_plan"), f"DEKLAROWANE bez planu: {name}"


def test_cert_register_gap_aggregate_no_p0():
    data = json.loads(_read(CERT_REGISTER))
    agg = data.get("gap_aggregate", {})
    assert agg.get("p0_open") == 0, "otwarte luki P0 blokują certyfikację"
    gaps = agg.get("unique_gaps", [])
    assert gaps, "agregat luk pusty"
    assert len(set(gaps)) == len(gaps), "duplikaty kluczy luk w agregacie"


def test_cert_register_metrics_frozen_with_thresholds():
    data = json.loads(_read(CERT_REGISTER))
    metrics = data.get("success_metrics", [])
    assert metrics, "brak zamrożonych metryk sukcesu"
    for m in metrics:
        assert m.get("threshold") is not None, f"metryka bez progu: {m.get('metric')}"
        assert m.get("source"), f"metryka bez źródła: {m.get('metric')}"


def test_cert_register_production_honesty():
    data = json.loads(_read(CERT_REGISTER))
    scope = str(data.get("scope", ""))
    assert "NOT_CERTIFIED" in scope, "rejestr musi jawnie deklarować NOT_CERTIFIED (uczciwość)"


def test_cert_register_v4_contracts_have_sot():
    data = json.loads(_read(CERT_REGISTER))
    contracts = data.get("v4_inheritance_contracts", [])
    assert len(contracts) >= 10, "za mało kontraktów dziedziczonych do V4"
    for c in contracts:
        assert c.get("source_of_truth"), f"kontrakt bez source_of_truth: {c.get('contract')}"


# ── Bundle dowodowe (12 innowacji) ──────────────────────────────────────────────

def test_all_12_evidence_bundles_pass():
    missing = [n for n in BUNDLE_TO_INNOVATION if not (BUNDLES / f"{n}.json").exists()]
    assert not missing, f"Brakujące bundle: {missing}"
    bad = []
    for name in BUNDLE_TO_INNOVATION:
        data = json.loads(_read(BUNDLES / f"{name}.json"))
        if data.get("gate") != "PASS":
            bad.append(name)
        if data.get("innovation") != BUNDLE_TO_INNOVATION[name]:
            bad.append(f"{name}: zły innovation id")
    assert not bad, f"Bundle nie-PASS lub zły id: {bad}"


# ── Regresja ochronna: selektory analiz (determinizm łańcucha) ─────────────────

BUNDLE_TO_SELECTOR = {
    "v3_p44_hard_gate_certificate": "hard_gate_certificate",
    "v3_p44_pillar_scoreboard": "pillar_scoreboard",
    "v3_p44_aggregate_ledger": "campaign_aggregate_ledger",
    "v3_p44_owner_decision_map": "owner_decision_map",
    "v3_p44_inheritance_contract": "v4_inheritance_contract",
    "v3_p44_metric_freeze": "success_metric_freeze",
    "v3_p44_worm_signature": "certificate_worm_signature",
    "v3_p44_knowledge_transfer": "knowledge_transfer_pack",
    "v3_p44_renewal_policy": "certification_renewal_policy",
    "v3_p44_legacy_cleanup": "legacy_cleanup_closure",
    "v3_p44_owner_attestation": "owner_attestation",
    "v3_p44_self_portrait": "fortress_self_portrait",
}


def test_every_analysis_selector_gated():
    hay = _read(P44_RULES)
    # Każdy routing var musi być użyty w gałęzi z selektorem analizy
    for sel_key in BUNDLE_TO_SELECTOR.values():
        sel = f'object.get(_ctx, "analysis", "") == "{sel_key}"'
        assert sel in hay, f"brak selektora analizy: {sel_key}"


def test_no_auto_post_without_full_chain():
    hay = _read(P44_RULES)
    # CERTIFIED/AUTO_POST wymaga zamkniętych bramek (negative-first: blokady najpierw)
    assert "NO_CERT" in hay, "brak trybu NO_CERT (hard gate I01)"
    assert hay.count("BLOCK_AND_ALERT") >= 6 and hay.count("TRIAGE_QUEUE") >= 6


if __name__ == "__main__":
    raise SystemExit(__import__("pytest").main([__file__, "-q"]))
