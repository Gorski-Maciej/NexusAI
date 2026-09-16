"""Testy pytest V3-P61 INTEGRACJE DOMKNIĘCIE (konwencja P51–P60).

Pokrywają: 12 silników I01–I12 vs bundla (jedno źródło), progi z ADR-002
(brak hardcode), wiring main_jdg p125, mirror hash-parity, fail-closed.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

JDG = Path(__file__).resolve().parents[2]
BUNDLES = JDG / "bundles"
RULES = JDG / "rules"
RULE = RULES / "v3_p61_integrations_closure.rego"


def _load(name: str) -> dict:
    return json.loads((BUNDLES / f"{name}.json").read_text(encoding="utf-8"))


# ═══ 1. Run-all gate ═══
def test_run_all_gate_pass():
    d = _load("v3_p61_run_all")
    assert d["gate"] == "PASS", d["failures"]
    assert d["engines_run"] == 12
    assert d["failures"] == []


def test_all_bundles_pass():
    for name in ["v3_p61_i01_contract", "v3_p61_circuit_breaker",
                 "v3_p61_reference_provenance", "v3_p61_sandbox_replay",
                 "v3_p61_i05_cache", "v3_p61_bank_recon",
                 "v3_p61_holiday_rate_path", "v3_p61_registry_gate",
                 "v3_p61_degradation_ladder", "v3_p61_outbox",
                 "v3_p61_external_sla", "v3_p61_attestation"]:
        r = _load(name)["result"]
        assert r["gate"] == "PASS", f"{name}: {r['gate']}"


# ═══ 2. I01: kontrakt integracji (4 integracje × 5 elementów) ═══
def test_i01_contract():
    r = _load("v3_p61_i01_contract")["result"]
    assert r["integrations_total"] == 4
    assert r["contract_violators"] == []
    assert set(r["elements_required"]) == {
        "health", "status", "degradation", "metrics", "runbook"}


# ═══ 3. I02: circuit breaker (P49 + chaos drill) ═══
def test_i02_breaker():
    r = _load("v3_p61_circuit_breaker")["result"]
    assert r["mechanism_present"] is True
    assert r["breaker_threshold"] == 20  # ADR-002 v3_p49_breaker_threshold (żywy skan)
    assert r["chaos_drill_gate"] == "PASS"


# ═══ 4. I03: provenance danych referencyjnych ═══
def test_i03_provenance():
    r = _load("v3_p61_reference_provenance")["result"]
    assert r["incomplete"] == []
    assert r["fx_entries"] >= 4
    assert r["acts_registered"] >= 4
    reg = _load("v3_p61_reference_provenance")
    for entry in reg["result"]["augmented_registry"]:
        assert entry.get("checksum"), "brak checksumy provenance"


# ═══ 5. I04: sandbox replay CI ═══
def test_i04_sandbox():
    r = _load("v3_p61_sandbox_replay")["result"]
    assert r["missing_replay"] == []
    assert r["live_calls_in_ci"] is False


# ═══ 6. I05: cache manifest z TTL ═══
def test_i05_cache():
    r = _load("v3_p61_i05_cache")["result"]
    assert r["cache_manifest_present"] is True
    assert r["stale_entries"] == []
    assert r["ttl_seconds"] == 3600 and r["max_age_days"] == 7  # ADR-002
    m = _load("v3_p61_cache_manifest")
    assert m["schema"] == "jdg.v3_p61.cache_manifest.v1"


# ═══ 7. I06: bank reconciliation (zero cichych rozjazdów) ═══
def test_i06_bank_recon():
    r = _load("v3_p61_bank_recon")["result"]
    assert r["unmatched_without_path_pct"] == 0.0
    assert r["conflicts_without_candidates"] == []
    assert r["unmatched_with_candidates"] == 3  # TX-098/099/100 z dowodu P57


# ═══ 8. I07: art. 31a — ścieżka ostatniej tabeli NBP ═══
def test_i07_holiday_path():
    r = _load("v3_p61_holiday_rate_path")["result"]
    assert r["path_present"] is True
    assert r["lookback_days"] == 7  # ADR-002 v3_p61_holiday_lookback_days
    assert "NIEZWERYFIKOWANE" in r["legal_basis"]


# ═══ 9. I08: rejestr integracji (statusy dozwolone) ═══
def test_i08_registry():
    r = _load("v3_p61_registry_gate")["result"]
    assert r["invalid_statuses"] == []
    assert len(r["entries"]) == 4
    assert all(e["status"] == "REAL" for e in r["entries"])
    assert all(e["contract_complete"] for e in r["entries"])


# ═══ 10. I09: drabina degradacji ≥3 szczebli ═══
def test_i09_ladder():
    r = _load("v3_p61_degradation_ladder")["result"]
    assert r["ladder_too_short"] == []
    assert min(r["ladders"].values()) >= 3


# ═══ 11. I10: outbox idempotentny (P54) ═══
def test_i10_outbox():
    r = _load("v3_p61_outbox")["result"]
    assert r["idempotent"] is True
    assert r["aged_entries"] == []
    assert r["duplicates_undetected"] == 0


# ═══ 12. I11: SLA zewnętrzne ═══
def test_i11_sla():
    r = _load("v3_p61_external_sla")["result"]
    assert r["over_threshold"] == []
    assert r["slo_domains_gate"] == "PASS"
    assert r["max_latency_ms"] == 5000  # ADR-002 v3_p61_external_sla_latency_ms


# ═══ 13. I12: attestation integracji z wersjami danych ═══
def test_i12_attestation():
    r = _load("v3_p61_attestation")["result"]
    assert r["attestation_age_days"] <= r["max_age_days"] == 90
    assert r["reference_data_versions"] is True
    assert r["fx_data_versions"] and r["isap_act_versions"] >= 4


# ═══ 14. Progi z ADR-002 (zero hardcode) ═══
def test_no_hardcoded_thresholds():
    hay = RULE.read_text(encoding="utf-8")
    for k in ["v3_p61_contract_elements_required", "v3_p61_breaker_open_threshold",
              "v3_p61_provenance_fields", "v3_p61_cache_ttl_seconds",
              "v3_p61_bank_unmatched_max_pct", "v3_p61_holiday_lookback_days",
              "v3_p61_integration_statuses", "v3_p61_degradation_ladder_min",
              "v3_p61_outbox_max_age_days", "v3_p61_external_sla_latency_ms",
              "v3_p61_attestation_max_age_days"]:
        assert k in hay, f"brak klucza ADR-002: {k}"
    th = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    assert '"v3_p61_threshold_version": "integrations-closure-v3p61-2026.09"' in th
    assert th.count('"v3_p61_') >= 12


def test_thresholds_temporal_window():
    th = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    blk = th[th.index("v3_p61 := {"):]
    assert '"valid_from": "2026-01-01"' in blk and '"valid_to": null' in blk


# ═══ 15. Wiring main_jdg p125 ═══
def test_wiring_main_jdg():
    main = (RULES / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.v3_p61_integrations_closure as v3_p61_integrations_closure" in main
    assert "final_verdict_p125 = safe_merge(final_verdict_p124" in main
    assert "v3_p61_integrations_closure.decide" in main
    post = main[main.index("final_verdict_post_merge = safe_merge("):]
    # Kotwica POST-MERGE przesunięta na p128: łańcuch urósł o P64
    # (wiring final_verdict_p130, kampania V3 — P66 CHAOS_ODPORNOSC).
    assert "final_verdict_p131" in post[:400]


# ═══ 16. Mirror: hash-parity policies/ ═══
def _sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def test_mirror_hash_parity():
    for name in ["v3_p61_integrations_closure", "v3_p60_documentation_closure",
                 "v3_p59_security_closure", "thresholds_jdg", "main_jdg"]:
        canonical = JDG / "rules" / f"{name}.rego"
        mirror = JDG.parent / "policies" / f"{name}.rego"
        assert mirror.exists(), f"brak mirrora: {mirror}"
        assert _sha(canonical) == _sha(mirror), f"mirror drift: {name}"


# ═══ 17. Fail-closed statycznie: router nie ma ścieżki AUTO_POST ═══
def test_fail_closed_static():
    hay = RULE.read_text(encoding="utf-8")
    assert hay.count('"AUTO_POST"') == 0
    assert "NO_MATCH" in hay and "NEEDS_ADVICE" in hay
    # final_verdict_p125 tylko w komentarzu nagłówka (konwencja P59–P60) —
    # rega P61 nie wykonuje host-wiringu.
    assert hay.count("final_verdict_p125") == 1


# ═══ 18. Rego struktura: pakiety, priorytety, unikalność ═══
def test_rego_structure():
    t = RULE.read_text(encoding="utf-8")
    assert t.count("{") == t.count("}")
    assert "package jdg.v3_p61_integrations_closure" in t
    for n in range(1, 13):
        assert f"4610{n:02d}" in t, f"brak priorytetu I{n:02d}"


# ═══ 19. Rejestr integracji jako bundle (schema + provenance) ═══
def test_registry_bundle_shape():
    reg = _load("v3_p61_integration_registry")
    assert reg["schema"] == "jdg.v3_p61.integration_registry.v1"
    ids = [e["id"] for e in reg["entries"]]
    assert set(ids) == {"ksef-mf", "nbp-fx", "isap", "banki"}
    for e in reg["entries"]:
        assert set(e["contract"]) == {
            "health", "status", "degradation", "metrics", "runbook"}
        assert e["status"] in ("REAL", "PLANNED", "FACADE")
        assert e["evidence"], "integracja bez dowodów"
