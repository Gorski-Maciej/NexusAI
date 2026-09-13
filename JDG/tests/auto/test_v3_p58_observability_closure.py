#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY PYTEST V3-P58 OBSERWOWALNOŚĆ DOMKNIĘCIE (konwencja
# P51–P57): dowody z bundli (uruchomienia, nie deklaracje), bramki gate=PASS,
# granice progów na poziomie silników, spójność engines↔Rego↔thresholds,
# hash-parity mirrora.
# Uruchomienie: python3 -m pytest JDG/tests/auto/test_v3_p58_observability_closure.py -q
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

JDG = Path(__file__).resolve().parent.parent.parent
BUNDLES = JDG / "bundles"
TOOLS = JDG / "tools"
RULE = JDG / "rules" / "v3_p58_observability_closure.rego"
THRESH = JDG / "rules" / "thresholds_jdg.rego"

EXPECTED_BUNDLES = [
    "v3_p58_legal_freshness", "v3_p58_coverage_regression", "v3_p58_advice_spread",
    "v3_p58_penny_drift", "v3_p58_telemetry_registry", "v3_p58_error_budget",
    "v3_p58_runbook_contract", "v3_p58_postmortem", "v3_p58_escalation",
    "v3_p58_risk_mining", "v3_p58_privacy", "v3_p58_slo_domains",
]


def _load(name: str) -> dict:
    p = BUNDLES / f"{name}.json"
    assert p.exists(), f"brak bundla: {p}"
    return json.loads(p.read_text(encoding="utf-8"))


# ═══ 1. Run_all: 12/12 silników, gate=PASS ═══
def test_run_all_gate_pass():
    d = _load("v3_p58_run_all")
    assert d["gate"] == "PASS"
    assert d["engines_run"] == 12
    assert d["failures"] == []


# ═══ 2. Każdy bundel istnieje i ma gate=PASS ═══
def test_all_bundles_pass():
    for name in EXPECTED_BUNDLES:
        d = _load(name)
        assert d["result"]["gate"] == "PASS", f"{name}: gate={d['result']['gate']}"


# ═══ 3. I01: metryka świeżości z PRAWDZIWEGO kalendarza P25 ═══
def test_i01_freshness_from_calendar():
    r = _load("v3_p58_legal_freshness")["result"]
    assert r["acts_total"] == 6
    assert r["sla_days"] == 1
    assert r["calendar_rows"] >= 1
    assert r["acts_unverified"] == []
    assert r["runbook"] == "RB-P58-01"
    assert all("age_days" in a for a in r["acts_beyond_sla"])


# ═══ 4. I02: pokrycie z metrics.json (P37), spadek ≤ próg ═══
def test_i02_coverage_from_metrics():
    r = _load("v3_p58_coverage_regression")["result"]
    assert r["coverage_current"] > 0
    assert r["coverage_baseline"] > 0
    assert r["drop_pp"] <= r["threshold_pp"]
    assert "metrics.json" in r["source"]


# ═══ 5. I03: radar z certyfikatów P11 — granica silnika (15.0 nie-hot) ═══
def test_i03_engine_boundary():
    sys.path.insert(0, str(TOOLS))
    from v3_p58_engines import _spread_audit
    from v3_p58_common import read_threshold_int
    max_pct = read_threshold_int("v3_p58_advice_spread_max_pct") or 15
    r = _spread_audit()
    # każdy hot ma spread ściśle powyżej progu (granica: 15.0 → nie-hot)
    for h in r["domains_hot"]:
        assert h["spread_pct"] > max_pct
    # sumy spójne
    assert r["events_total"] >= 1


# ═══ 6. I04: drift z v3_p52_drift_telemetry (kontrakt P52-I10: trend do 0) ═══
def test_i04_drift_trend_to_zero():
    r = _load("v3_p58_penny_drift")["result"]
    assert r["target"] == 0
    assert r["trend"] in ("zero", "flat", "rising")
    assert "v3_p52_drift_telemetry" in r["source"]


# ═══ 7. I05: telemetria z certyfikatów P11 (jedno źródło, wymagane pola) ═══
def test_i05_single_source_telemetry():
    r = _load("v3_p58_telemetry_registry")["result"]
    assert r["certs_total"] >= 1
    assert len(r["required_fields"]) == 5
    assert set(r["required_fields"]) == {"domain", "amount_gr", "certainty", "legal_epoch", "bundle_hash"}
    assert r["single_source"].endswith("decision_certificates.json")


# ═══ 8. I06: budżet z golden replay (P37) + freeze z deployments (P38) ═══
def test_i06_budget_consistency():
    r = _load("v3_p58_error_budget")["result"]
    assert r["budget_pct"] == round(max(0.0, 100.0 - r["golden_uver_pct"]), 1)
    assert r["min_pct"] == 20
    assert isinstance(r["freeze_active"], bool)


# ═══ 9. I07: kontrakt runbook — 12/12 alarmów z RB-P58-xx ═══
def test_i07_runbook_contract():
    r = _load("v3_p58_runbook_contract")["result"]
    assert r["alarms_total"] == 12
    assert r["without_runbook"] == []
    assert all(rb.startswith("RB-P58-") for rb in r["runbooks"])


# ═══ 10. I08: rejestr post-mortem jawny ═══
def test_i08_postmortem_registry():
    r = _load("v3_p58_postmortem")["result"]
    assert r["max_age_days"] == 30
    assert "registry_present" in r
    assert r["pending_postmortem"] == []


# ═══ 11. I09: macierz eskalacji jako dane (3 poziomy, SLA) ═══
def test_i09_escalation_matrix():
    r = _load("v3_p58_escalation")["result"]
    assert r["levels_total"] == 3
    assert r["levels_incomplete"] == []
    roles = [e["role"] for e in r["matrix"]]
    assert any("SRE" in x for x in roles) and any("prawnik" in x for x in roles) and any("właściciel" in x for x in roles)
    assert all(e["sla_min"] > 0 for e in r["matrix"])


# ═══ 12. I10: mining z telemetrii P11 — koncentracja policzona ═══
def test_i10_risk_mining():
    r = _load("v3_p58_risk_mining")["result"]
    assert r["events_total"] >= 1
    assert r["concentration_threshold_pct"] == 25
    for p in r["patterns_high_risk"]:
        assert p["concentration_pct"] > 25


# ═══ 13. I11: prywatność — zero PII, tryb zgodny z ADR-002 ═══
def test_i11_privacy_clean():
    r = _load("v3_p58_privacy")["result"]
    assert r["pii_hits"] == []
    assert r["privacy_mode"] == "pseudonymized" == r["required_mode"]
    assert r["records_scanned"] >= 1


# ═══ 14. I12: SLO dziedziczone globalnie z P37, 6 domen ═══
def test_i12_slo_domains():
    r = _load("v3_p58_slo_domains")["result"]
    assert r["domains_total"] >= 6
    assert r["slo_inherited_global"] is True
    assert r["domains_missing_slo"] == []
    assert "metrics.json" in r["slo_source"]


# ═══ 15. Rego: struktura — 12 analiz + router + brak AUTO_POST ═══
def test_rego_rule_structure():
    hay = RULE.read_text(encoding="utf-8")
    assert "package jdg.v3_p58_observability_closure" in hay
    for rid in ["legal_freshness_sla", "coverage_regression_alarm", "advice_spread_radar",
                "penny_drift_telemetry", "decision_telemetry_registry", "error_budget_freeze",
                "runbook_per_alarm", "postmortem_registry", "escalation_matrix",
                "risk_pattern_mining", "telemetry_privacy_guard", "slo_per_domain"]:
        assert rid in hay, f"brak analizy: {rid}"
    assert "all_green" in hay and "NO_MATCH" in hay


# ═══ 16. ADR-002: klucze v3_p58 z oknem valid_from ═══
def test_thresholds_adr002():
    hay = THRESH.read_text(encoding="utf-8")
    for key in ["v3_p58_isap_freshness_sla_days", "v3_p58_coverage_drop_max_pp",
                "v3_p58_advice_spread_max_pct", "v3_p58_penny_drift_max_gr",
                "v3_p58_error_budget_min_pct", "v3_p58_privacy_mode",
                "v3_p58_slo_domains_min", "v3_p58_coverage_baseline_pct"]:
        assert f'"{key}"' in hay, f"brak klucza: {key}"
    blk = hay[hay.index("v3_p58 := {"):]
    blk = blk[:blk.index("\n}")]
    assert '"valid_from"' in blk and '"valid_to"' in blk


# ═══ 17. main_jdg: wiring final_verdict_p122 ═══
def test_wiring_main_jdg():
    main = (JDG / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.v3_p58_observability_closure as v3_p58_observability_closure" in main
    assert "final_verdict_p122 = safe_merge(final_verdict_p121" in main
    assert "v3_p58_observability_closure.decide" in main
    post = main[main.index("final_verdict_post_merge = safe_merge("):]
    assert "final_verdict_p122" in post[:300]


# ═══ 18. Mirror: hash-parity policies/ ═══
def _sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def test_mirror_hash_parity():
    for name in ["v3_p58_observability_closure", "thresholds_jdg", "main_jdg"]:
        canonical = JDG / "rules" / f"{name}.rego"
        mirror = JDG.parent / "policies" / f"{name}.rego"
        assert mirror.exists(), f"brak mirrora: {mirror}"
        assert _sha(canonical) == _sha(mirror), f"mirror drift: {name}"


# ═══ 19. Rego czyta progi z ADR-002 (brak hardcode) ═══
def test_no_hardcoded_thresholds():
    hay = RULE.read_text(encoding="utf-8")
    for k in ["v3_p58_isap_freshness_sla_days", "v3_p58_advice_spread_max_pct",
              "v3_p58_penny_drift_max_gr", "v3_p58_error_budget_min_pct",
              "v3_p58_privacy_mode", "v3_p58_escalation_min_levels",
              "v3_p58_slo_domains_min", "v3_p58_risk_concentration_max_pct",
              "v3_p58_postmortem_max_age_days", "v3_p58_coverage_drop_max_pp"]:
        assert f'_th("{k}"' in hay, f"reguła nie czyta progu: {k}"


# ═══ 20. Katalog metryk prawnych: 12 alarmów z akcją i runbookiem (13.19) ═══
def test_legal_metrics_catalog():
    sys.path.insert(0, str(TOOLS))
    from v3_p58_engines import LEGAL_METRICS_CATALOG
    assert len(LEGAL_METRICS_CATALOG) == 12
    for a in LEGAL_METRICS_CATALOG:
        assert a["metric"] and a["threshold"] and a["action"] and a["runbook"]


# ═══ 21. Nagłówki bundli spójne ═══
def test_bundle_headers():
    for name in EXPECTED_BUNDLES:
        h = _load(name)["header"]
        assert h["schema"] == "jdg.v3_p58.observability.audit.v1"
        assert h["part"] == "P58"
        assert h["generated_at"]
