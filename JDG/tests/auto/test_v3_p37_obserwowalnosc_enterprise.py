# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P37 (OBSERWOWALNOŚĆ — DECYZJE Z TELEMETRIĄ JAK KOD Z
COVERAGE) — kampania V3 FORTRESS.

Weryfikuje:
  * reguły OPA w rules/v3_p37_obserwowalnosc_enterprise.rego (12 analiz I01-I12),
  * parametry-as-data w rules/thresholds_jdg.rego (blok v3_p37, ADR-002/P06, P05),
  * wiring w rules/main_jdg.rego (final_verdict_p101),
  * 12 narzędzi dowodowych tools/v3_p37_*.py i 12 bundli bundles/v3_p37_*.json,
  * katalog SLO jako dane (bundles/v3_p37_slo_catalog.json, 6 SLO kompletnych),
  * runbook-as-code (docs/runbooks/RB01-RB06) + powiązanie z SLO,
  * benchmark baseline ZMIERZONY (.benchmarks/eval_baseline.json) + gate PASS,
  * spójność z legacy: metrics_generator/pewnosc_metrics (LCI/TCL/RV/UVR),
    health_tier_engine = domena ZUS (nie SRE — bez duplikacji), kontrakty
    P03/P10/P11/P02/P08/P30/P33/P35/P36/P39.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"
DOCS = BASE / "docs"

P37_REGO = RULES / "v3_p37_obserwowalnosc_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"
SLO_CATALOG = BUNDLES / "v3_p37_slo_catalog.json"
BENCHMARKS = BASE / ".benchmarks" / "eval_baseline.json"

INNOVATIONS = {
    "I01": "jdg.v3_p37_obserwowalnosc.decision_slo",
    "I02": "jdg.v3_p37_obserwowalnosc.law_freshness_sla",
    "I03": "jdg.v3_p37_obserwowalnosc.needs_advice_radar",
    "I04": "jdg.v3_p37_obserwowalnosc.latency_budget",
    "I05": "jdg.v3_p37_obserwowalnosc.certificate_telemetry",
    "I06": "jdg.v3_p37_obserwowalnosc.error_budget_freeze",
    "I07": "jdg.v3_p37_obserwowalnosc.anomaly_detection",
    "I08": "jdg.v3_p37_obserwowalnosc.golden_drift_watch",
    "I09": "jdg.v3_p37_obserwowalnosc.runbook_as_code",
    "I10": "jdg.v3_p37_obserwowalnosc.status_page",
    "I11": "jdg.v3_p37_obserwowalnosc.decision_cost",
    "I12": "jdg.v3_p37_obserwowalnosc.benchmark_regression",
}

ANALYSES = [
    "decision_slo", "law_freshness_sla", "needs_advice_radar", "latency_budget",
    "certificate_telemetry", "error_budget_freeze", "anomaly_detection",
    "golden_drift_watch", "runbook_as_code", "status_page", "decision_cost",
    "benchmark_regression",
]

TOOLS_EXPECTED = {
    "v3_p37_decision_slo.py", "v3_p37_law_freshness_sla.py",
    "v3_p37_needs_advice_radar.py", "v3_p37_latency_budget.py",
    "v3_p37_certificate_telemetry.py", "v3_p37_error_budget_freeze.py",
    "v3_p37_anomaly_detection.py", "v3_p37_golden_drift_watch.py",
    "v3_p37_runbook_as_code.py", "v3_p37_status_page.py",
    "v3_p37_decision_cost.py", "v3_p37_benchmark_regression.py",
}

RUNBOOKS_EXPECTED = {
    "RB01_dostepnosc_silnika.md", "RB02_latencja_p95.md", "RB03_golden_drift.md",
    "RB04_swiezosc_prawa.md", "RB05_na_bez_powodu.md", "RB06_regresja_benchmarku.md",
}

# Legacy obserwowalność z sekcji 6.1 promptu P37 (istnienie = dowód)
LEGACY_OBS_TOOLS = [
    "metrics_generator.py", "pewnosc_metrics.py", "health_tier_engine.py",
    "health_tier_recalculator.py", "health_reconciliation_micro.py",
    "enterprise_dashboard.py", "confidence_dashboard.py", "drift_dashboard.py",
    "holographic_viz.py",
]

LEGACY_BUNDLES = [
    "metrics_pewnosci.json", "healthy_versions.json", "control_plane_state.json",
    "deployments.json", "bundle_catalog.json",
]

CONTRACT_MENTIONS = ["P10", "P11", "P02", "P08", "P30", "P33", "P39"]

THRESHOLD_KEYS_V3P37 = [
    "v3_p37_threshold_version", "legal_basis_version", "valid_from",
    "v3_p37_law_freshness_sla_days", "v3_p37_na_spike_ratio",
    "v3_p37_latency_p95_max_ms", "v3_p37_error_budget_min_pct",
    "v3_p37_golden_drift_max", "v3_p37_alert_without_runbook_max",
    "v3_p37_status_page_max_stale_days", "v3_p37_ai_cost_limit_per_decision",
    "v3_p37_benchmark_regression_max_pct",
]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def _thresholds_block() -> str:
    src = _read(THRESHOLDS)
    i = src.find("v3_p37 := {")
    assert i >= 0, "brak bloku v3_p37 w thresholds_jdg.rego"
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


# ── Pakiet V3-P37 ─────────────────────────────────────────────────────────────

def test_p37_rego_exists_and_structured():
    src = _read(P37_REGO)
    assert src, "brak rules/v3_p37_obserwowalnosc_enterprise.rego"
    assert "package jdg.v3_p37_obserwowalnosc" in src
    assert src.count("{") == src.count("}"), "nierównoważne nawiasy"
    rule_ids = re.findall(r'"rule_id": "([^"]+)"', src)
    assert len(rule_ids) == len(set(rule_ids)), "duplikaty rule_id w pakiecie P37"


def test_p37_all_12_innovations_present():
    src = _read(P37_REGO)
    for iid, rid in INNOVATIONS.items():
        assert rid in src, f"brak reguły {iid}: {rid}"


def test_p37_decide_chain_covers_all_analyses():
    src = _read(P37_REGO)
    chain = src.split("decide := fail_closed_decision")[1]
    for iid, rid in INNOVATIONS.items():
        rule_name = rid.rsplit(".", 1)[1]
        assert f"{rule_name}_decision" in chain, f"brak reguły {iid} w łańcuchu decide"
    assert chain.count("else :=") >= len(ANALYSES), "niekompletny else-chain decide"


def test_p37_fail_closed_no_silent_auto_post():
    src = _read(P37_REGO)
    assert "fail_closed_decision" in src
    assert "_snapshot_ok" in src
    assert '"_routing": "BLOCK_AND_ALERT"' in src
    assert "no_match" in src
    for m in re.finditer(r"\{\s*true\s*\}", src):
        prefix = src[:m.start()].rstrip().splitlines()[-1]
        assert "else" in prefix, (
            f"AP01: samodzielny stub bez else w P37 (kontekst: {prefix!r})")


def test_p37_public_rule_count():
    src = _read(P37_REGO)
    rule_ids = re.findall(
        r'"rule_id": "jdg\.v3_p37_obserwowalnosc\.[a-z_]+"', src)
    assert len(rule_ids) >= 12, "za mało reguł publicznych w pakiecie"


def test_p37_innovation_ids_in_header():
    src = _read(P37_REGO)
    for i in range(1, 13):
        assert f"V3-P37-I{i:02d}" in src, f"brak ID V3-P37-I{i:02d} w nagłówku pakietu"


# ── Parametry jako dane (ADR-002/P06) + okno temporalne (P05) ─────────────────

def test_v3p37_block_complete():
    block = _thresholds_block()
    for key in THRESHOLD_KEYS_V3P37:
        assert f'"{key}"' in block, f"brak klucza {key} v3_p37"
    assert '"valid_from"' in block, "brak okna temporalnego (P05)"


def test_v3p37_governance_limits():
    block = _thresholds_block()
    assert '"v3_p37_law_freshness_sla_days": 7' in block, "SLA świeżości 7 dni (I02)"
    assert '"v3_p37_latency_p95_max_ms": 500' in block, "budżet latencji 500 ms (I04)"
    assert '"v3_p37_golden_drift_max": 0' in block, "zero dryfu z golden (I08)"
    assert '"v3_p37_alert_without_runbook_max": 0' in block, "zero alarmów bez runbooka (I09)"
    assert '"v3_p37_benchmark_regression_max_pct": 10' in block, "regresja max 10% (I12)"
    assert '"no_auto_post": true' in block, "fail-closed P04"


# ── Katalog SLO jako dane (I01) ───────────────────────────────────────────────

def test_slo_catalog_complete():
    catalog = json.loads(_read(SLO_CATALOG))
    slos = catalog.get("slos", [])
    assert len(slos) >= 6, "za mało SLO w katalogu"
    for slo in slos:
        for key in ("metric", "target", "window_days", "action", "runbook"):
            assert key in slo, f"SLO {slo.get('id')} bez pola {key} (I01 BLOCK)"


def test_slo_catalog_error_budget_policy():
    catalog = json.loads(_read(SLO_CATALOG))
    policy = catalog.get("error_budget_policy", {})
    assert "freeze_below_pct" in policy, "brak polityki freeze (I06)"
    assert policy.get("window_days") == 30, "okno budżetu 30 dni"


# ── Runbook-as-code (I09) ─────────────────────────────────────────────────────

def test_runbooks_exist():
    missing = [rb for rb in RUNBOOKS_EXPECTED
               if not (DOCS / "runbooks" / rb).exists()]
    assert not missing, f"brak runbooków: {missing}"


def test_runbooks_link_slos():
    catalog = json.loads(_read(SLO_CATALOG))
    existing = {p.name for p in (DOCS / "runbooks").glob("*.md")}
    for slo in catalog.get("slos", []):
        rb_name = slo["runbook"].split("/")[-1]
        assert rb_name in existing, f"SLO {slo['id']} wskazuje nieistniejący runbook {rb_name}"


# ── Benchmark baseline zmierzony + gate (I12) ────────────────────────────────

def test_benchmark_baseline_measured():
    baseline = json.loads(_read(BENCHMARKS))
    assert baseline.get("runs") == 60, "baseline nie z 60 przebiegów (zmierzony)"
    assert baseline.get("p95_ms", 0) > 0, "p95 baseline = 0"
    assert baseline.get("p50_ms", 0) > 0
    assert "regression_gate" in baseline, "brak konfiguracji gate"


def test_gate_tool_present():
    assert (TOOLS / "v3_p37_benchmark_gate.py").exists(), "brak tools/v3_p37_benchmark_gate.py"


# ── Wiring main_jdg ───────────────────────────────────────────────────────────

def test_main_jdg_wired_p101():
    src = _read(MAIN_JDG)
    assert "import data.jdg.v3_p37_obserwowalnosc as v3_p37_obserwowalnosc" in src
    assert '"jdg.v3_p37_obserwowalnosc": v3_p37_obserwowalnosc.decide' in src
    assert "final_verdict_p101 = safe_merge(final_verdict_p100" in src
    assert "final_verdict_post_merge = safe_merge(" in src
    assert "final_verdict_p101\n)" in src or "safe_merge(final_verdict_p101," in src


# ── Spójność z legacy (obserwowalność rdzenia, kontrakty) ────────────────────

def test_p37_threshold_version_consistency():
    rego = _read(P37_REGO)
    assert "data.jdg.thresholds.v3_p37" in rego, \
        "pakiet P37 nie podpięty pod snapshot progów"
    assert "v3_p37_threshold_version" in rego, \
        "brak odczytu threshold_version w pakiecie P37"


def test_legacy_contracts_honored():
    src = _read(P37_REGO)
    for contract in CONTRACT_MENTIONS:
        assert contract in src, f"brak odwołania do kontraktu {contract} w pakiecie P37"
    assert "NEEDS_ADVICE" in src or "TRIAGE" in src  # fail-closed P04


def test_legacy_obs_tools_exist():
    missing = [t for t in LEGACY_OBS_TOOLS if not (TOOLS / t).exists()]
    assert not missing, f"brak narzędzi obserwowalności rdzenia: {missing}"


def test_legacy_obs_bundles_exist():
    missing = [b for b in LEGACY_BUNDLES if not (BUNDLES / b).exists()]
    assert not missing, f"brak bundli metryk rdzenia: {missing}"


def test_health_tier_is_zus_domain_not_sre():
    """Audyt 9.04: health_tier_engine to tiery ZUS (przychód), nie SRE —
    P37 NIE duplikuje jego logiki (AP04/AP12)."""
    src = _read(TOOLS / "health_tier_engine.py")
    assert "TIER_LIMITS" in src and "przychód" in src.lower()
    assert "jdg.v3_p37" not in src, "P37 nie może dublować tierów ZUS"


# ── Narzędzia dowodowe i bundle ───────────────────────────────────────────────

def test_p37_tools_present():
    for name in sorted(TOOLS_EXPECTED):
        assert (TOOLS / name).exists(), f"brak tools/{name}"


def test_p37_bundles_all_pass():
    for name in sorted(TOOLS_EXPECTED):
        bundle = BUNDLES / (name.replace(".py", ".json"))
        assert bundle.exists(), f"brak bundles/{bundle.name}"
        data = _read(bundle)
        assert '"gate": "PASS"' in data, f"gate FAIL: {bundle.name}"


def test_p37_bundle_innovations_match_tools():
    for name in sorted(TOOLS_EXPECTED):
        bpath = BUNDLES / (name.replace(".py", ".json"))
        data = json.loads(_read(bpath))
        iid = data["innovation"]
        assert re.fullmatch(r"V3-P37-I\d{2}", iid), f"błędny ID innowacji: {iid}"
        assert iid in _read(P37_REGO), f"{iid} nie ma reguły w pakiecie"
